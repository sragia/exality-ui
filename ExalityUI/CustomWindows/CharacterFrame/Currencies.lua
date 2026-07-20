---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

---@class EXUICharacterFrameCurrencies
local currencies = EXUI:GetModule('character-frame-currencies')

currencies.panel = nil
currencies.toggle = nil
currencies.scrollFrame = nil
currencies.scrollChild = nil
currencies.headerRows = {}
currencies.currencyRows = {}
currencies.isOpen = false
currencies.useAnimation = true

local PANEL_WIDTH = 290
local PANEL_GAP = 6
local BUTTON_SIZE = 30
local BUTTON_OUTSET_X = 0
local BUTTON_OFFSET_Y = -60
local TITLE_HEIGHT = 28
local ROW_HEIGHT = 24
local HEADER_HEIGHT = 22
local ROW_GAP = 2
local CONTENT_PAD = 10
local ANIM_DURATION = 0.18
local HEADER_GOLD = { 235 / 255, 183 / 255, 52 / 255, 1 } -- #ebb734
local TOGGLE_BG = { 112 / 255, 80 / 255, 0, 1 }           -- #705000
local TOGGLE_BG_HOVER = { 140 / 255, 100 / 255, 0, 1 }

local function ApplyRowVisual(button, hovered)
    local theme = EXUI.const.theme
    if hovered then
        button.border:SetBorderColor(0.55, 0.55, 0.55, 1)
        button.border:SetBorderThickness(1)
        button.bg:SetVertexColor(0.2, 0.2, 0.2, 0.7)
    else
        button.border:SetBorderColor(unpack(theme.border))
        button.border:SetBorderThickness(1)
        button.bg:SetVertexColor(0, 0, 0, 0.55)
    end
end

local function ApplyHeaderVisual(button, hovered)
    local theme = EXUI.const.theme
    if hovered then
        button.bg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 0.85)
    else
        button.bg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 0.55)
    end
end

local function ApplyToggleVisual(button, hovered)
    if hovered then
        button.bg:SetVertexColor(unpack(TOGGLE_BG_HOVER))
    else
        button.bg:SetVertexColor(unpack(TOGGLE_BG))
    end
end

local function SetHeaderTextColor(button, depth)
    if depth == 0 then
        button.Text:SetTextColor(unpack(HEADER_GOLD))
        button.Collapse:SetVertexColor(HEADER_GOLD[1], HEADER_GOLD[2], HEADER_GOLD[3], 0.95)
    else
        button.Text:SetTextColor(unpack(EXUI.const.theme.textMuted))
        button.Collapse:SetVertexColor(1, 1, 1, 0.85)
    end
end

currencies.CreateHeaderRow = function(self, parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(HEADER_HEIGHT)
    button.isHeader = true

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    button.bg:SetAllPoints()

    button.Collapse = button:CreateTexture(nil, 'OVERLAY')
    button.Collapse:SetTexture(EXUI.const.textures.frame.icons.chevronRight)
    button.Collapse:SetSize(10, 10)
    button.Collapse:SetPoint('LEFT', 6, 0)
    button.Collapse:SetVertexColor(1, 1, 1, 0.85)

    button.Text = button:CreateFontString(nil, 'OVERLAY')
    button.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Text:SetPoint('LEFT', button.Collapse, 'RIGHT', 4, 0)
    button.Text:SetPoint('RIGHT', -8, 0)
    button.Text:SetJustifyH('LEFT')
    button.Text:SetWordWrap(false)

    button:SetScript('OnEnter', function(btn)
        ApplyHeaderVisual(btn, true)
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyHeaderVisual(btn, false)
    end)
    button:SetScript('OnClick', function(btn)
        if not btn.currencyIndex then
            return
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        local expand = not btn.isExpanded
        C_CurrencyInfo.ExpandCurrencyList(btn.currencyIndex, expand)
        currencies:Update()
    end)

    return button
end

currencies.CreateCurrencyRow = function(self, parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(ROW_HEIGHT)
    button.isHeader = false

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    button.bg:SetAllPoints()

    button.border = EXUI:AddPixelPerfectBorder(button, 1, { register = false, outwardBottom = false })
    button.border:SetBorderColor(unpack(EXUI.const.theme.border))

    button.Icon = button:CreateTexture(nil, 'ARTWORK')
    button.Icon:SetSize(18, 18)
    button.Icon:SetPoint('LEFT', 6, 0)
    button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.Text = button:CreateFontString(nil, 'OVERLAY')
    button.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Text:SetPoint('LEFT', button.Icon, 'RIGHT', 6, 0)
    button.Text:SetPoint('RIGHT', button, 'RIGHT', -56, 0)
    button.Text:SetJustifyH('LEFT')
    button.Text:SetWordWrap(false)
    button.Text:SetTextColor(unpack(EXUI.const.theme.text))

    button.Count = button:CreateFontString(nil, 'OVERLAY')
    button.Count:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Count:SetPoint('RIGHT', -8, 0)
    button.Count:SetWidth(48)
    button.Count:SetJustifyH('RIGHT')
    button.Count:SetTextColor(unpack(EXUI.const.theme.text))

    button:SetScript('OnEnter', function(btn)
        ApplyRowVisual(btn, true)
        if btn.currencyID then
            GameTooltip:SetOwner(btn, 'ANCHOR_RIGHT', 2, 2)
            GameTooltip:SetCurrencyByID(btn.currencyID)
            GameTooltip:Show()
        end
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyRowVisual(btn, false)
        GameTooltip:Hide()
    end)

    return button
end

currencies.AcquireHeaderRow = function(self, index)
    local row = self.headerRows[index]
    if not row then
        row = self:CreateHeaderRow(self.scrollChild)
        self.headerRows[index] = row
    end
    return row
end

currencies.AcquireCurrencyRow = function(self, index)
    local row = self.currencyRows[index]
    if not row then
        row = self:CreateCurrencyRow(self.scrollChild)
        self.currencyRows[index] = row
    end
    return row
end

currencies.UpdateScroll = function(self)
    if not self.scrollFrame then
        return
    end
    local width = math.max(1, self.scrollFrame:GetWidth())
    local height = math.max(1, self.scrollChild:GetHeight())
    self.scrollFrame:UpdateScrollChild(width, height)
end

currencies.Update = function(self)
    if not self.panel or not self.isOpen then
        return
    end

    local content = self.scrollChild
    local y = -2
    local headerIndex = 0
    local currencyIndex = 0
    local listSize = C_CurrencyInfo.GetCurrencyListSize()

    for i = 1, listSize do
        local info = C_CurrencyInfo.GetCurrencyListInfo(i)
        if info then
            local depth = info.currencyListDepth or 0

            if info.isHeader then
                headerIndex = headerIndex + 1
                local row = self:AcquireHeaderRow(headerIndex)
                local indent = depth > 0 and 8 or 0

                row:ClearAllPoints()
                row:SetPoint('TOPLEFT', content, 'TOPLEFT', 2 + indent, y)
                row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -2, y)
                row:Show()

                row.currencyIndex = i
                row.isExpanded = info.isHeaderExpanded
                row.depth = depth
                row.Text:SetText(info.name or '')
                row.Collapse:SetTexture(EXUI.const.textures.frame.icons.chevronRight)
                if info.isHeaderExpanded then
                    row.Collapse:SetRotation(math.rad(-90))
                else
                    row.Collapse:SetRotation(0)
                end
                SetHeaderTextColor(row, depth)
                ApplyHeaderVisual(row, false)
                y = y - HEADER_HEIGHT - ROW_GAP
            else
                currencyIndex = currencyIndex + 1
                local row = self:AcquireCurrencyRow(currencyIndex)
                local indent = EXUI:ScalePixel(6 + depth * 10, row)
                local xPad = EXUI:ScalePixel(2, row)
                local yPos = EXUI:ScalePixel(y, row)

                row:ClearAllPoints()
                row:SetPoint('TOPLEFT', content, 'TOPLEFT', xPad + indent, yPos)
                row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -xPad, yPos)
                row:Show()

                row.currencyIndex = i
                row.currencyID = info.currencyID
                row.Icon:SetTexture(info.iconFileID)
                row.Text:SetText(info.name or '')
                row.Count:SetText(BreakUpLargeNumbers(info.quantity or 0))
                ApplyRowVisual(row, false)
                y = y - ROW_HEIGHT - ROW_GAP
            end
        end
    end

    for i = headerIndex + 1, #self.headerRows do
        self.headerRows[i]:Hide()
    end
    for i = currencyIndex + 1, #self.currencyRows do
        self.currencyRows[i]:Hide()
    end

    content:SetHeight(math.max((-y) + 4, 1))
    self:UpdateScroll()
end

currencies.StopAnimations = function(self)
    if self.panel and self.panel.fadeIn then
        self.panel.fadeIn:Stop()
    end
    if self.panel and self.panel.fadeOut then
        self.panel.fadeOut:Stop()
    end
    if self.toggle and self.toggle.fadeIn then
        self.toggle.fadeIn:Stop()
    end
end

currencies.RevealToggle = function(self, animated)
    if not self.toggle then
        return
    end
    ApplyToggleVisual(self.toggle, false)
    if animated and self.useAnimation and self.toggle.fadeIn then
        self.toggle:SetAlpha(0)
        self.toggle:Show()
        self.toggle.fadeIn:Play()
    else
        self.toggle:SetAlpha(1)
        self.toggle:Show()
    end
end

currencies.ShowPanel = function(self)
    if not self.panel then
        return
    end

    self.isOpen = true
    self:StopAnimations()
    if self.toggle then
        self.toggle:SetAlpha(1)
        self.toggle:Hide()
    end
    self.panel:Show()
    self:Update()

    if self.useAnimation and self.panel.fadeIn then
        self.panel:SetAlpha(0)
        self.panel.fadeIn:Play()
    else
        self.panel:SetAlpha(1)
    end
end

currencies.HidePanel = function(self, immediate)
    if not self.panel then
        return
    end

    self.isOpen = false
    self:StopAnimations()

    if immediate or not self.useAnimation or not self.panel.fadeOut then
        self.panel:SetAlpha(1)
        self.panel:Hide()
        self:RevealToggle(false)
        return
    end

    self.panel.fadeOut:SetScript('OnFinished', function()
        self.panel:Hide()
        self.panel:SetAlpha(1)
        self:RevealToggle(true)
    end)
    self.panel.fadeOut:Play()
end

currencies.Toggle = function(self)
    if self.isOpen then
        self:HidePanel()
    else
        self:ShowPanel()
    end
end

currencies.CreateToggle = function(self, window)
    local button = CreateFrame('Button', nil, window)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetPoint('TOPLEFT', window, 'TOPRIGHT', BUTTON_OUTSET_X, BUTTON_OFFSET_Y)
    button:SetFrameLevel(window:GetFrameLevel() + 20)

    local bg = button:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    bg:SetTextureSliceMargins(20, 20, 20, 20)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetAllPoints()
    button.bg = bg

    local icon = button:CreateTexture(nil, 'OVERLAY')
    icon:SetTexture(EXUI.const.textures.characterFrame.coins)
    icon:SetSize(18, 18)
    icon:SetPoint('CENTER')
    icon:SetVertexColor(1, 1, 1, 1)
    button.icon = icon

    button.Tooltip = tooltip:Get({
        text = 'Currencies'
    }, button)

    button:SetScript('OnEnter', function(btn)
        ApplyToggleVisual(btn, true)
        btn.Tooltip:ShowTooltip()
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyToggleVisual(btn, false)
        btn.Tooltip:HideTooltip()
    end)
    button:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        currencies:ShowPanel()
    end)

    button.fadeIn = EXUI.utils.animation.fade(button, ANIM_DURATION, 0, 1)

    ApplyToggleVisual(button, false)
    self.toggle = button
    return button
end

currencies.CreateCloseButton = function(self, panel)
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
    icon:SetVertexColor(1, 1, 1, 1)

    close:SetScript('OnEnter', function()
        bg:SetVertexColor(unpack(theme.dangerHover))
    end)
    close:SetScript('OnLeave', function()
        bg:SetVertexColor(unpack(theme.faded))
    end)
    close:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        currencies:HidePanel()
    end)

    panel.close = close
    return close
end

currencies.CreatePanel = function(self, window)
    local theme = EXUI.const.theme
    local panel = CreateFrame('Frame', nil, window)
    panel:SetWidth(PANEL_WIDTH)
    panel:SetPoint('TOPLEFT', window, 'TOPRIGHT', PANEL_GAP, 0)
    panel:SetPoint('BOTTOMLEFT', window, 'BOTTOMRIGHT', PANEL_GAP, 0)
    panel:SetFrameLevel(window:GetFrameLevel() + 5)
    panel:Hide()
    panel:SetAlpha(1)

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
    title:SetText(CURRENCY or 'Currencies')
    title:SetTextColor(unpack(theme.text))
    panel.Title = title

    local scrollFrame = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scrollFrame:SetParent(panel)
    scrollFrame:SetPoint('TOPLEFT', CONTENT_PAD, -(TITLE_HEIGHT + 4))
    scrollFrame:SetPoint('BOTTOMRIGHT', -CONTENT_PAD, CONTENT_PAD)
    self.scrollFrame = scrollFrame
    self.scrollChild = scrollFrame.child

    scrollFrame:HookScript('OnSizeChanged', function()
        if currencies.isOpen then
            currencies:Update()
        end
    end)

    -- Fade animation; horizontal diveIn tends to fight static anchors — fade only.
    panel.fadeIn = EXUI.utils.animation.fade(panel, ANIM_DURATION, 0, 1)
    panel.fadeOut = EXUI.utils.animation.fade(panel, ANIM_DURATION, 1, 0)

    panel:RegisterEvent('CURRENCY_DISPLAY_UPDATE')
    panel:SetScript('OnEvent', function()
        if currencies.isOpen then
            currencies:Update()
        end
    end)

    self.panel = panel
    return panel
end

currencies.Create = function(self, window)
    self:CreateToggle(window)
    self:CreatePanel(window)
end

currencies.Hide = function(self)
    self:HidePanel(true)
end
