---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUICharacterFrameEdgeToggle
local edgeToggle = EXUI:GetModule('character-frame-edge-toggle')

---@class EXUICharacterFrameCurrencies
local currencies = EXUI:GetModule('character-frame-currencies')

---@class EXUICharacterFrameReputation
local reputation = EXUI:GetModule('character-frame-reputation')

-- Forever only, Retail has no skill lines
---@class EXUICharacterFrameSkills
local skills = EXUI:GetModule('character-frame-skills')

skills.panel = nil
skills.toggle = nil
skills.scrollFrame = nil
skills.scrollChild = nil
skills.headerRows = {}
skills.skillRows = {}
skills.isOpen = false
skills.useAnimation = true

local PANEL_WIDTH = 320
local PANEL_GAP = 6
local BUTTON_OFFSET_Y = -128
local TITLE_HEIGHT = 28
local ROW_HEIGHT = 26
local HEADER_HEIGHT = 22
local ROW_GAP = 2
local CONTENT_PAD = 10
local BAR_WIDTH = 120
local BAR_HEIGHT = 16
local ANIM_DURATION = 0.18
local HEADER_GOLD = { 235 / 255, 183 / 255, 52 / 255, 1 } -- #ebb734
local BAR_COLOR = { 0.25, 0.5, 0.9 }
local TOGGLE_ICON = { 90 / 255, 160 / 255, 255 / 255, 1 }
local TOGGLE_ICON_HOVER = { 140 / 255, 195 / 255, 255 / 255, 1 }

-- Same filtering as Blizzard's SkillsFrame
local HIDDEN_CATEGORIES = { [7] = true }
local DEFENSE_SKILL_ID = 95

local function ShouldShow(info)
    if info.parentSkillLineID ~= 0 then
        return false
    end
    if info.isHeader then
        return not HIDDEN_CATEGORIES[info.skillID]
    end
    return not HIDDEN_CATEGORIES[info.skillLineCategoryID]
end

local function RankText(info)
    if info.modifier == 0 then
        return info.rank .. ' / ' .. info.maxRank
    end
    local sign = info.modifier > 0 and '+' or ''
    return string.format('%d |cff20ff20(%s%d)|r / %d', info.rank, sign, info.modifier, info.maxRank)
end

local function ApplyRowVisual(button, hovered)
    local theme = EXUI.const.theme
    if hovered then
        button.border:SetBorderColor(0.55, 0.55, 0.55, 1)
        button.bg:SetVertexColor(0.2, 0.2, 0.2, 0.7)
    else
        button.border:SetBorderColor(unpack(theme.border))
        button.bg:SetVertexColor(0, 0, 0, 0.55)
    end
end

local function ApplyHeaderVisual(button, hovered)
    local theme = EXUI.const.theme
    local alpha = hovered and 0.85 or 0.55
    button.bg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], alpha)
end

local function ShowSkillTooltip(button)
    local info = button.info
    if not info then
        return
    end
    GameTooltip:SetOwner(button, 'ANCHOR_RIGHT', 2, 2)
    GameTooltip:SetText(info.name or '', HEADER_GOLD[1], HEADER_GOLD[2], HEADER_GOLD[3])
    GameTooltip:AddLine(RankText(info), 1, 1, 1)
    if info.description and info.description ~= '' then
        GameTooltip:AddLine(info.description, 1, 1, 1, true)
    end
    GameTooltip:Show()
end

skills.CreateHeaderRow = function(self, parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(HEADER_HEIGHT)

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    button.bg:SetAllPoints()

    button.Collapse = button:CreateTexture(nil, 'OVERLAY')
    button.Collapse:SetTexture(EXUI.const.textures.frame.icons.chevronRight)
    button.Collapse:SetSize(10, 10)
    button.Collapse:SetPoint('LEFT', 6, 0)
    button.Collapse:SetVertexColor(HEADER_GOLD[1], HEADER_GOLD[2], HEADER_GOLD[3], 0.95)

    button.Text = button:CreateFontString(nil, 'OVERLAY')
    button.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Text:SetPoint('LEFT', button.Collapse, 'RIGHT', 4, 0)
    button.Text:SetPoint('RIGHT', -8, 0)
    button.Text:SetJustifyH('LEFT')
    button.Text:SetWordWrap(false)
    button.Text:SetTextColor(unpack(HEADER_GOLD))

    button:SetScript('OnEnter', function(btn)
        ApplyHeaderVisual(btn, true)
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyHeaderVisual(btn, false)
    end)
    button:SetScript('OnClick', function(btn)
        if not btn.skillIndex then
            return
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        if btn.isCollapsed then
            C_SkillInfo.ExpandSkillHeader(btn.skillIndex)
        else
            C_SkillInfo.CollapseSkillHeader(btn.skillIndex)
        end
        skills:Update()
    end)

    return button
end

skills.CreateSkillRow = function(self, parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(ROW_HEIGHT)

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    button.bg:SetAllPoints()

    button.border = EXUI:AddPixelPerfectBorder(button, 1, { register = false, outwardBottom = false })
    button.border:SetBorderColor(unpack(EXUI.const.theme.border))

    local bar = CreateFrame('StatusBar', nil, button)
    bar:SetSize(BAR_WIDTH, BAR_HEIGHT)
    bar:SetPoint('RIGHT', -8, 0)
    bar:SetStatusBarTexture([[Interface/Addons/ExalityUI/Assets/Images/StatusBar/noisy]])
    bar:SetStatusBarColor(BAR_COLOR[1], BAR_COLOR[2], BAR_COLOR[3], 1)
    button.Bar = bar

    local barBg = bar:CreateTexture(nil, 'BACKGROUND')
    barBg:SetTexture(EXUI.const.textures.frame.solidBg)
    barBg:SetAllPoints()
    barBg:SetVertexColor(0, 0, 0, 0.65)

    button.Rank = bar:CreateFontString(nil, 'OVERLAY')
    button.Rank:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    button.Rank:SetPoint('CENTER')
    button.Rank:SetWordWrap(false)
    button.Rank:SetTextColor(1, 1, 1, 1)

    button.Text = button:CreateFontString(nil, 'OVERLAY')
    button.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Text:SetPoint('LEFT', 8, 0)
    button.Text:SetPoint('RIGHT', bar, 'LEFT', -8, 0)
    button.Text:SetJustifyH('LEFT')
    button.Text:SetWordWrap(false)
    button.Text:SetTextColor(unpack(EXUI.const.theme.text))

    button:SetScript('OnEnter', function(btn)
        ApplyRowVisual(btn, true)
        ShowSkillTooltip(btn)
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyRowVisual(btn, false)
        GameTooltip:Hide()
    end)

    ApplyRowVisual(button, false)
    return button
end

local function Acquire(pool, index, create)
    local row = pool[index]
    if not row then
        row = create(skills, skills.scrollChild)
        pool[index] = row
    end
    return row
end

skills.Update = function(self)
    if not self.panel or not self.isOpen then
        return
    end

    local content = self.scrollChild
    local y = -2
    local headerCount = 0
    local skillCount = 0

    for index = 1, C_SkillInfo.GetNumSkillLines() do
        local info = C_SkillInfo.GetSkillLineInfo(index)
        if info and ShouldShow(info) then
            if info.isHeader then
                headerCount = headerCount + 1
                local row = Acquire(self.headerRows, headerCount, self.CreateHeaderRow)
                row:ClearAllPoints()
                row:SetPoint('TOPLEFT', content, 'TOPLEFT', 2, y)
                row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -2, y)
                row.skillIndex = index
                row.isCollapsed = info.isCollapsed
                row.Text:SetText(info.name or '')
                row.Collapse:SetRotation(info.isCollapsed and 0 or math.rad(-90))
                ApplyHeaderVisual(row, false)
                row:Show()
                y = y - HEADER_HEIGHT - ROW_GAP
            else
                if info.skillID == DEFENSE_SKILL_ID and UnitDefenseSkill then
                    info.modifier = select(2, UnitDefenseSkill('player')) or info.modifier
                end
                skillCount = skillCount + 1
                local row = Acquire(self.skillRows, skillCount, self.CreateSkillRow)
                local xPad = EXUI:ScalePixel(8, row)
                local yPos = EXUI:ScalePixel(y, row)
                row:ClearAllPoints()
                row:SetPoint('TOPLEFT', content, 'TOPLEFT', xPad, yPos)
                row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -EXUI:ScalePixel(2, row), yPos)
                row.info = info
                row.Text:SetText(info.name or '')
                row.Bar:SetMinMaxValues(0, math.max(info.maxRank, 1))
                row.Bar:SetValue(info.rank)
                row.Rank:SetText(RankText(info))
                row:Show()
                if row:IsMouseOver() then
                    ShowSkillTooltip(row)
                end
                y = y - ROW_HEIGHT - ROW_GAP
            end
        end
    end

    for i = headerCount + 1, #self.headerRows do
        self.headerRows[i]:Hide()
    end
    for i = skillCount + 1, #self.skillRows do
        self.skillRows[i]:Hide()
        self.skillRows[i].info = nil
    end

    content:SetHeight(math.max((-y) + 4, 1))
    self.scrollFrame:UpdateScrollChild(math.max(1, self.scrollFrame:GetWidth()), math.max(1, content:GetHeight()))
end

skills.StopAnimations = function(self)
    if self.panel then
        self.panel.fadeIn:Stop()
        self.panel.fadeOut:Stop()
    end
    if self.toggle and self.toggle.fadeIn then
        self.toggle.fadeIn:Stop()
    end
end

skills.HideToggle = function(self)
    local toggle = self.toggle
    if not toggle then
        return
    end
    if toggle.fadeIn then
        toggle.fadeIn:Stop()
    end
    if toggle.stopWindowAnims then
        toggle.stopWindowAnims()
    end
    toggle.edgeHidden = true
    toggle:SetAlpha(1)
    toggle:Hide()
end

skills.RevealToggle = function(self, animated)
    local toggle = self.toggle
    if not toggle then
        return
    end
    toggle.edgeHidden = false
    if toggle.stopWindowAnims then
        toggle.stopWindowAnims()
    end
    edgeToggle:ApplyVisual(toggle, false)
    if animated and self.useAnimation and toggle.fadeIn then
        toggle:SetAlpha(0)
        toggle:Show()
        toggle.fadeIn:Play()
    else
        toggle:SetAlpha(1)
        toggle:Show()
    end
end

local function HideEdgeToggles()
    for _, side in ipairs({ currencies, reputation }) do
        local toggle = side.toggle
        if toggle then
            if toggle.fadeIn then
                toggle.fadeIn:Stop()
            end
            if toggle.stopWindowAnims then
                toggle.stopWindowAnims()
            end
            toggle.edgeHidden = true
            toggle:SetAlpha(1)
            toggle:Hide()
        end
    end
    skills:HideToggle()
end

local function RevealEdgeToggles(animated)
    if currencies.isOpen or reputation.isOpen or skills.isOpen then
        return
    end
    currencies:RevealToggle(animated)
    reputation:RevealToggle(animated)
    skills:RevealToggle(animated)
end

skills.ShowPanel = function(self)
    if not self.panel then
        return
    end

    self.isOpen = true
    if currencies.isOpen then
        currencies:HidePanel(true)
    end
    if reputation.isOpen then
        reputation:HidePanel(true)
    end

    self:StopAnimations()
    HideEdgeToggles()
    self.panel:Show()
    self:Update()

    if self.useAnimation then
        self.panel:SetAlpha(0)
        self.panel.fadeIn:Play()
    else
        self.panel:SetAlpha(1)
    end
end

skills.HidePanel = function(self, immediate)
    if not self.panel then
        return
    end

    self.isOpen = false
    self:StopAnimations()

    if immediate or not self.useAnimation then
        self.panel:SetAlpha(1)
        self.panel:Hide()
        RevealEdgeToggles(false)
        return
    end

    self.panel.fadeOut:SetScript('OnFinished', function()
        self.panel:Hide()
        self.panel:SetAlpha(1)
        RevealEdgeToggles(true)
    end)
    self.panel.fadeOut:Play()
end

skills.CreateToggle = function(self, window)
    self.toggle = edgeToggle:Create(window, {
        icon = EXUI.const.textures.characterFrame.skills,
        offsetY = BUTTON_OFFSET_Y,
        tooltip = SKILLS or 'Skills',
        iconColor = TOGGLE_ICON,
        iconHoverColor = TOGGLE_ICON_HOVER,
        onClick = function()
            skills:ShowPanel()
        end,
    })
end

skills.CreateCloseButton = function(self, panel)
    local theme = EXUI.const.theme
    local close = CreateFrame('Button', nil, panel)
    close:SetSize(28, 22)
    close:SetPoint('TOPRIGHT', -8, -6)
    close:SetFrameLevel(panel:GetFrameLevel() + 5)

    local bg = close:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    bg:SetTextureSliceMargins(20, 20, 20, 20)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetVertexColor(unpack(theme.faded))
    bg:SetAllPoints()

    local icon = close:CreateTexture(nil, 'OVERLAY')
    icon:SetTexture(EXUI.const.textures.frame.closeIcon)
    icon:SetSize(12, 12)
    icon:SetPoint('CENTER')

    close:SetScript('OnEnter', function()
        bg:SetVertexColor(unpack(theme.dangerHover))
    end)
    close:SetScript('OnLeave', function()
        bg:SetVertexColor(unpack(theme.faded))
    end)
    close:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        skills:HidePanel()
    end)

    panel.close = close
end

skills.CreatePanel = function(self, window)
    local theme = EXUI.const.theme
    local panel = CreateFrame('Frame', nil, window)
    panel:SetWidth(PANEL_WIDTH)
    panel:SetPoint('TOPLEFT', window, 'TOPRIGHT', PANEL_GAP, 0)
    panel:SetPoint('BOTTOMLEFT', window, 'BOTTOMRIGHT', PANEL_GAP, 0)
    panel:SetFrameLevel(window:GetFrameLevel() + 5)
    panel:Hide()

    local bg = panel:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXFrames.assets.textures.ui.panelBg)
    bg:SetVertexColor(unpack(theme.backgroundDeep))
    bg:SetTextureSliceMargins(8, 8, 8, 8)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAllPoints()

    local border = panel:CreateTexture(nil, 'OVERLAY', nil, 1)
    border:SetTexture(EXFrames.assets.textures.ui.panelBorder)
    border:SetVertexColor(unpack(theme.border))
    border:SetTextureSliceMargins(8, 8, 8, 8)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    border:SetAllPoints()

    self:CreateCloseButton(panel)

    local title = panel:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    title:SetPoint('TOPLEFT', CONTENT_PAD, -10)
    title:SetPoint('TOPRIGHT', panel.close, 'TOPLEFT', -6, -2)
    title:SetJustifyH('LEFT')
    title:SetText(SKILLS or 'Skills')
    title:SetTextColor(unpack(theme.text))

    local scrollFrame = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scrollFrame:SetParent(panel)
    scrollFrame:SetPoint('TOPLEFT', CONTENT_PAD, -(TITLE_HEIGHT + 4))
    scrollFrame:SetPoint('BOTTOMRIGHT', -CONTENT_PAD, CONTENT_PAD)
    self.scrollFrame = scrollFrame
    self.scrollChild = scrollFrame.child

    scrollFrame:HookScript('OnSizeChanged', function()
        skills:Update()
    end)

    panel.fadeIn = EXUI.utils.animation.fade(panel, ANIM_DURATION, 0, 1)
    panel.fadeOut = EXUI.utils.animation.fade(panel, ANIM_DURATION, 1, 0)

    panel:SetScript('OnShow', function(frame)
        frame:RegisterEvent('SKILL_LINES_CHANGED')
    end)
    panel:SetScript('OnHide', function(frame)
        frame:UnregisterEvent('SKILL_LINES_CHANGED')
    end)
    panel:SetScript('OnEvent', function()
        skills:Update()
    end)

    self.panel = panel
end

skills.Create = function(self, window)
    if not EXUI.IsForever() then
        return
    end
    self:CreateToggle(window)
    self:CreatePanel(window)
end

skills.Hide = function(self)
    self.isOpen = false
    if not self.panel then
        return
    end
    self:StopAnimations()
    self.panel:SetAlpha(1)
    self.panel:Hide()
    if self.toggle then
        -- Keep visible so window close animation can fade it out with the frame.
        self.toggle.edgeHidden = false
    end
end
