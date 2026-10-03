---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')

---@class EXUITalentsTree
local tree = EXUI:GetModule('talents-tree')

---@class EXUITalentsSpellBook
local spellBook = EXUI:GetModule('talents-spellbook')

---@class EXUITalentsBuilds
local builds = EXUI:GetModule('talents-builds')

---@class EXUITalentsPvP
local pvp = EXUI:GetModule('talents-pvp')

---@class EXUITalentsWindow
local talents = EXUI:GetModule('talents-window')

talents.enabled = false
talents.override = false
talents.suppressHook = false
talents.isCreated = false
talents.window = nil
talents.activeTab = 'talents'
talents.refreshQueued = false

local ICON_SIZE = 40
local BORDER_SIZE = ICON_SIZE * (96 / 82)
local SPEC_GAP = 18
local TAB_WIDTH = 110
local TAB_HEIGHT = 26
local UNPICKED_COLOR = 0.4
local BG_CROP_TOP = 0.05
local BG_CROP_BOTTOM = 0.04
local WINDOW_BG = [[Interface/Addons/ExalityUI/Options/Assets/main-bg_2.png]]
local WINDOW_CORNER = 24

local TEX = {
    selected = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-selected.png]],
    unselected = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-unselected.png]],
    mask = [[Interface/Addons/ExalityUI/Assets/Images/Talents/talent-mask.png]],
    hover = [[Interface/Addons/ExalityUI/Assets/Images/Talents/hover-glow.png]],
    tabActive = [[Interface/Addons/ExalityUI/Assets/Images/Talents/tab-active.png]],
    tabInactive = [[Interface/Addons/ExalityUI/Assets/Images/Talents/tab-inactive.png]],
}
local WINDOW_TAB_FONT = 12
local WINDOW_TAB_PAD_X = 36
local WINDOW_TAB_PAD_Y = 24
local WINDOW_TAB_SLICE = 6
local SEARCH_TEX = [[Interface/Addons/ExalityUI/Assets/Images/Talents/search-icon.png]]
local SEARCH_ICON = 22
local SEARCH_BOX_WIDTH = 140
local SEARCH_GAP = 6
local SEARCH_COLLAPSED = SEARCH_ICON
local SEARCH_EXPANDED = SEARCH_ICON + SEARCH_GAP + SEARCH_BOX_WIDTH

local HOVER_FADE = 0.12

local function PrepareHover(highlight)
    highlight:SetAlpha(0)
    highlight:Show()
    local group = highlight:CreateAnimationGroup()
    local anim = group:CreateAnimation('Alpha')
    anim:SetDuration(HOVER_FADE)
    group:SetScript('OnFinished', function()
        highlight:SetAlpha(highlight.hoverTarget or 0)
    end)
    highlight.hoverTarget = 0
    highlight.HoverGroup = group
    highlight.HoverAnim = anim
end

local function SetHover(highlight, shown)
    local target = shown and 1 or 0
    local group = highlight.HoverGroup
    local anim = highlight.HoverAnim
    local from = highlight:GetAlpha()
    if (group:IsPlaying()) then
        local progress = group:GetProgress() or 0
        from = anim:GetFromAlpha() + (anim:GetToAlpha() - anim:GetFromAlpha()) * progress
        group:Stop()
    end
    highlight.hoverTarget = target
    if (math.abs(from - target) < 0.01) then
        highlight:SetAlpha(target)
        return
    end
    highlight:SetAlpha(from)
    anim:SetFromAlpha(from)
    anim:SetToAlpha(target)
    anim:SetSmoothing(shown and 'IN' or 'OUT')
    group:Play()
end

local function ApplyTabVisual(button, active, hovered)
    local theme = EXUI.const.theme
    button.tabActive = active
    local textColor = theme.textMuted
    local lineColor = theme.border
    if (active) then
        textColor = theme.text
        lineColor = hovered and theme.accentLight or theme.accent
    elseif (hovered) then
        textColor = theme.text
        lineColor = theme.accentLight
    end
    button.Text:SetTextColor(textColor[1], textColor[2], textColor[3], 1)
    if (button.Background) then
        button.Background:SetTexture(active and TEX.tabActive or TEX.tabInactive)
        button.Background:SetTextureSliceMargins(WINDOW_TAB_SLICE, WINDOW_TAB_SLICE, WINDOW_TAB_SLICE, WINDOW_TAB_SLICE)
        button.Background:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        button.Background:SetAlpha(0.8)
        return
    end
    button.Underline:SetColorTexture(lineColor[1], lineColor[2], lineColor[3], 1)
    button.Glow:SetVertexColor(lineColor[1], lineColor[2], lineColor[3], 1)
    button.Glow:SetShown(active or hovered or button.alwaysGlow)
end

local function SetActionEnabled(button, enabled)
    button:SetEnabled(enabled)
    button:SetAlpha(enabled and 1 or 0.45)
end

local function TabForSuggested(suggestedTab)
    if (suggestedTab == PlayerSpellsUtil.FrameTabs.SpellBook) then
        return 'spellbook'
    end
    return 'talents'
end

local function SuggestedForTab(tab)
    if (tab == 'spellbook') then
        return PlayerSpellsUtil.FrameTabs.SpellBook
    end
    return PlayerSpellsUtil.FrameTabs.ClassTalents
end

talents.SetTab = function(self, tab)
    self.activeTab = tab
    if (self.talentsPanel) then
        self.talentsPanel:SetShown(tab == 'talents')
        self.spellBookPanel:SetShown(tab == 'spellbook')
    end
    if (self.tabButtons) then
        for id, button in pairs(self.tabButtons) do
            ApplyTabVisual(button, id == tab, button:IsMouseOver())
        end
    end
    self:Refresh()
end

talents.RefreshSpecs = function(self, specIndex)
    local classID = select(3, UnitClass('player'))
    local numSpecs = classID and C_SpecializationInfo.GetNumSpecializationsForClassID(classID) or 0
    local shown = {}

    for index, button in ipairs(self.specButtons) do
        if (index > numSpecs) then
            button:Hide()
        else
            local specID, _, _, icon = C_SpecializationInfo.GetSpecializationInfo(index)
            button.specIndex = index
            button.specID = specID
            button.Icon:SetTexture(icon)
            local active = index == specIndex
            button.Border:SetTexture(active and TEX.selected or TEX.unselected)
            button.Icon:SetDesaturated(false)
            if (active) then
                button.Icon:SetVertexColor(1, 1, 1)
            else
                button.Icon:SetVertexColor(UNPICKED_COLOR, UNPICKED_COLOR, UNPICKED_COLOR)
            end
            button:Show()
            shown[#shown + 1] = button
        end
    end

    local x = 0
    for _, button in ipairs(shown) do
        button:ClearAllPoints()
        button:SetPoint('LEFT', x, 0)
        x = x + BORDER_SIZE + SPEC_GAP
    end
    self.specRow:SetWidth(math.max(x - SPEC_GAP, 1))
end

talents.RefreshHero = function(self, configID, specID)
    local options = tree:GetHeroOptions(configID, specID)
    local shown = {}

    for index, button in ipairs(self.heroButtons) do
        local option = options[index]
        if (not option) then
            button:Hide()
        else
            shown[#shown + 1] = button
            button.nodeID = option.nodeID
            button.entryID = option.entryID
            button.configID = configID
            button.subTreeID = option.subTreeID
            button.heroActive = option.isActive
            button.Text:SetText(option.name or 'Hero')
            button:SetWidth(math.max(80, button.Text:GetStringWidth() + 24))
            ApplyTabVisual(button, option.isActive, button:IsMouseOver())
            button:SetEnabled(option.nodeID ~= nil and option.entryID ~= nil)
            button:Show()
        end
    end

    local gap = 8
    local x = 0
    for _, button in ipairs(shown) do
        button:ClearAllPoints()
        button:SetPoint('LEFT', x, 0)
        x = x + button:GetWidth() + gap
    end

    self.heroRow:SetHeight(#shown > 0 and 24 or 1)
    self.heroRow:SetShown(#shown > 0)
    self:PlaceSearch(shown)
    self:ApplyHeroSearch()
end

talents.PlaceSearch = function(self, shown)
    local search = self.searchFrame
    if (not search) then
        return
    end
    search:ClearAllPoints()
    local anchor = shown and shown[#shown]
    if (anchor) then
        search:SetPoint('LEFT', anchor, 'RIGHT', 10, 0)
    else
        search:SetPoint('LEFT', self.specRow, 'RIGHT', 16, 0)
    end
end

talents.ApplyHeroSearch = function(self)
    if (not self.heroButtons) then
        return
    end
    local matched = tree.matchedSubTrees or {}
    local searching = tree.searchText ~= nil
    for _, button in ipairs(self.heroButtons) do
        if (button:IsShown()) then
            local active = button.heroActive
            if (searching and button.subTreeID and matched[button.subTreeID]) then
                active = true
            end
            ApplyTabVisual(button, active, button:IsMouseOver())
        end
    end
end

talents.AnimateSearch = function(self, expand)
    local search = self.searchFrame
    if (not search) then
        return
    end
    search.expanded = expand
    search.animFrom = search:GetWidth()
    search.animTo = expand and SEARCH_EXPANDED or SEARCH_COLLAPSED
    search.animTime = 0
    if (expand) then
        self.searchBox:Show()
    end
    search:SetScript('OnUpdate', function(frame, elapsed)
        frame.animTime = frame.animTime + elapsed
        local t = math.min(frame.animTime / 0.18, 1)
        frame:SetWidth(frame.animFrom + (frame.animTo - frame.animFrom) * t)
        if (t >= 1) then
            frame:SetScript('OnUpdate', nil)
            frame:SetWidth(frame.animTo)
            if (not frame.expanded) then
                talents.searchBox:Hide()
            else
                talents.searchBox:SetFocus()
            end
        end
    end)
end

talents.CollapseSearch = function(self)
    local search = self.searchFrame
    if (not search or not self.searchBox) then
        return
    end
    search.expanded = false
    self.searchBox:ClearFocus()
    if (self.searchBox:GetText() ~= '') then
        self.searchBox:SetText('')
    else
        tree:SetSearchText('')
    end
    search:SetScript('OnUpdate', nil)
    if (search:GetWidth() > SEARCH_COLLAPSED + 0.5) then
        self:AnimateSearch(false)
    else
        search:SetWidth(SEARCH_COLLAPSED)
        self.searchBox:Hide()
    end
end

local function CurrencyQuantity(currencies, traitCurrencyID)
    if (not currencies or not traitCurrencyID) then
        return 0
    end
    for _, info in ipairs(currencies) do
        if (info.traitCurrencyID == traitCurrencyID) then
            return info.quantity or 0
        end
    end
    return 0
end

local function UnspentPoints(configID, treeID, specID)
    local currencies = C_Traits.GetTreeCurrencyInfo(configID, treeID, false)
    if (not currencies) then
        return 0
    end

    local classInfo = currencies[1]
    local specInfo = currencies[2]
    local unspent = (classInfo and classInfo.quantity or 0) + (specInfo and specInfo.quantity or 0)
    local heroSpecs = specID and C_ClassTalents.GetHeroTalentSpecsForClassSpec(configID, specID)
    if (heroSpecs) then
        for _, subTreeID in ipairs(heroSpecs) do
            local subTree = C_Traits.GetSubTreeInfo(configID, subTreeID)
            if (subTree and subTree.isActive and subTree.traitCurrencyID) then
                local currencyID = subTree.traitCurrencyID
                local alreadyCounted = (classInfo and classInfo.traitCurrencyID == currencyID) or
                    (specInfo and specInfo.traitCurrencyID == currencyID)
                if (not alreadyCounted) then
                    unspent = unspent + CurrencyQuantity(currencies, currencyID)
                end
                break
            end
        end
    end
    return unspent
end

talents.RefreshActions = function(self, configID, treeID, specID)
    local unspent = 0
    if (configID and treeID) then
        unspent = UnspentPoints(configID, treeID, specID)
    end
    self.pointsText:SetText('Unspent ' .. unspent)
    self.pointsText:SetShown(unspent > 0)

    local canEdit, editError = C_ClassTalents.CanEditTalents()
    local canChange, _, changeError = C_ClassTalents.CanChangeTalents()
    local purchases, refunds, swaps = nil, nil, nil
    if (configID) then
        purchases, refunds, swaps = C_Traits.GetStagedChanges(configID)
    end
    local hasStaged = (purchases and #purchases > 0) or (refunds and #refunds > 0) or (swaps and #swaps > 0)

    SetActionEnabled(self.applyButton, hasStaged and canChange and true or false)
    self.resetButton:SetShown(hasStaged and true or false)

    if (not configID) then
        self.statusText:SetText('Talents are not available yet.')
    elseif (not canEdit and editError and editError ~= '') then
        self.statusText:SetText(editError)
    elseif (hasStaged and not canChange and changeError and changeError ~= '') then
        self.statusText:SetText(changeError)
    else
        self.statusText:SetText('')
    end
end

talents.FitBackground = function(self)
    local texture = self.talentArt
    local atlas = self.backgroundAtlas
    if (not texture or not atlas) then
        return
    end
    local info = C_Texture.GetAtlasInfo(atlas)
    local file = info and (info.file or info.filename)
    if (not info or not file) then
        texture:SetAtlas(atlas, true)
        texture:ClearAllPoints()
        texture:SetPoint('BOTTOM')
        return
    end

    local parent = texture:GetParent()
    local frameWidth = parent:GetWidth()
    local frameHeight = parent:GetHeight()
    if (frameWidth <= 1 or frameHeight <= 1) then
        return
    end

    local left, right = info.leftTexCoord, info.rightTexCoord
    local top, bottom = info.topTexCoord, info.bottomTexCoord
    local vSpan = bottom - top
    top = top + vSpan * BG_CROP_TOP
    bottom = bottom - vSpan * BG_CROP_BOTTOM

    local artWidth = info.width
    local artHeight = info.height * (1 - BG_CROP_TOP - BG_CROP_BOTTOM)
    local frameAspect = frameWidth / frameHeight
    local artAspect = artWidth / artHeight
    if (artWidth > 0 and artHeight > 0) then
        if (artAspect > frameAspect) then
            local keep = frameAspect / artAspect
            local trim = (1 - keep) / 2
            local uSpan = right - left
            left = left + uSpan * trim
            right = right - uSpan * trim
        else
            local keep = artAspect / frameAspect
            local trim = (1 - keep) / 2
            vSpan = bottom - top
            top = top + vSpan * trim
            bottom = bottom - vSpan * trim
        end
    end

    texture:ClearAllPoints()
    texture:SetSize(frameWidth, frameHeight)
    texture:SetPoint('CENTER')
    texture:SetTexture(file)
    texture:SetTexCoord(left, right, top, bottom)
    texture:SetVertexColor(1, 1, 1, 1)
end

talents.UpdateBackground = function(self, specID)
    if (not self.talentArt) then
        return
    end
    local visuals = specID and ClassTalentUtil and ClassTalentUtil.GetVisualsForSpecID and
        ClassTalentUtil.GetVisualsForSpecID(specID)
    local atlas = visuals and visuals.background
    if (not atlas or not C_Texture.GetAtlasInfo(atlas)) then
        return
    end
    self.backgroundAtlas = atlas
    self:FitBackground()
end

talents.Refresh = function(self)
    if (not self.window or not self.window:IsShown()) then
        return
    end
    builds:UpdateCurrentBorder()
    pvp:UpdateButton()
    if (pvp.sidebar and pvp.sidebar:IsShown()) then
        pvp:Refresh()
    end

    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specID = specIndex and select(1, C_SpecializationInfo.GetSpecializationInfo(specIndex)) or nil
    self:UpdateBackground(specID)

    if (self.activeTab == 'spellbook') then
        spellBook:Refresh()
        return
    end

    local configID = C_ClassTalents.GetActiveConfigID()
    local treeID = specID and C_ClassTalents.GetTraitTreeForSpec(specID) or nil

    self:RefreshSpecs(specIndex)
    tree:Refresh(configID, treeID, specID)
    self:RefreshHero(configID, specID)
    self:RefreshActions(configID, treeID, specID)
end

talents.QueueRefresh = function(self)
    if (not self.window or not self.window:IsShown() or self.refreshQueued) then
        return
    end
    self.refreshQueued = true
    C_Timer.After(0, function()
        talents.refreshQueued = false
        talents:Refresh()
    end)
end

talents.HandleIntercept = function(self, suggestedTab)
    local tab = TabForSuggested(suggestedTab)
    if (self.window and self.window:IsShown()) then
        if (self.activeTab == tab) then
            self.window:HideWindow()
        else
            self:SetTab(tab)
        end
        return
    end
    self:Show(tab)
end

talents.OpenDefault = function(self)
    if (not self.window) then
        return
    end
    local suggested = SuggestedForTab(self.activeTab)
    self.window:HideWindow()
    self.override = true
    PlayerSpellsUtil.TogglePlayerSpellsFrame(suggested)
    self.override = false
end

local function CreateTabButton(parent, label, flipped)
    local theme = EXUI.const.theme
    local button = CreateFrame('Button', nil, parent)
    button:SetSize(flipped and 48 or TAB_WIDTH, flipped and (WINDOW_TAB_FONT + WINDOW_TAB_PAD_Y) or TAB_HEIGHT)
    local text
    if (flipped) then
        text = button:CreateFontString(nil, 'OVERLAY')
        text:SetFont(EXUI.const.fonts.DEFAULT, WINDOW_TAB_FONT, 'OUTLINE')
        text:SetShadowColor(0, 0, 0, 0)
        text:SetShadowOffset(0, 0)
    else
        text = button:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    end
    text:SetPoint('CENTER', 0, flipped and 0 or 2)
    text:SetText(label)
    text:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    button.Text = text
    if (flipped) then
        local background = button:CreateTexture(nil, 'BACKGROUND')
        background:SetAllPoints()
        button.Background = background
        local textWidth = text:GetStringWidth()
        local textHeight = text:GetStringHeight()
        if (type(textWidth) ~= 'number' or textWidth < 8) then
            textWidth = #label * 7
        end
        if (type(textHeight) ~= 'number' or textHeight < 8) then
            textHeight = WINDOW_TAB_FONT
        end
        button:SetSize(textWidth + WINDOW_TAB_PAD_X, textHeight + WINDOW_TAB_PAD_Y)
        ApplyTabVisual(button, false, false)
        button:SetScript('OnEnter', function(self)
            ApplyTabVisual(self, self.tabActive, true)
        end)
        button:SetScript('OnLeave', function(self)
            ApplyTabVisual(self, self.tabActive, false)
        end)
        return button
    end
    local underline = button:CreateTexture(nil, 'OVERLAY')
    underline:SetHeight(2)
    underline:SetPoint('BOTTOMLEFT', 8, 0)
    underline:SetPoint('BOTTOMRIGHT', -8, 0)
    underline:SetColorTexture(theme.border[1], theme.border[2], theme.border[3], 1)
    button.Underline = underline
    local glow = button:CreateTexture(nil, 'ARTWORK')
    glow:SetTexture(EXUI.const.textures.characterFrame.tabGlow)
    glow:SetHeight(20)
    glow:SetPoint('BOTTOMLEFT', underline, 'TOPLEFT', 0, 0)
    glow:SetPoint('BOTTOMRIGHT', underline, 'TOPRIGHT', 0, 0)
    glow:Hide()
    button.Glow = glow
    button.alwaysGlow = flipped and true or false
    button:SetScript('OnEnter', function(self)
        ApplyTabVisual(self, self.tabActive, true)
    end)
    button:SetScript('OnLeave', function(self)
        ApplyTabVisual(self, self.tabActive, false)
    end)
    return button
end

local function CreateSpecButton(parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetSize(BORDER_SIZE, BORDER_SIZE)

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint('CENTER')
    button.Icon = icon

    local mask = button:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)

    local border = button:CreateTexture(nil, 'OVERLAY')
    border:SetSize(BORDER_SIZE, BORDER_SIZE)
    border:SetPoint('CENTER')
    border:SetTexture(TEX.unselected)
    button.Border = border
    local highlight = button:CreateTexture(nil, 'ARTWORK', nil, 1)
    highlight:SetAllPoints(icon)
    highlight:SetTexture(TEX.hover)
    highlight:SetBlendMode('ADD')
    highlight:AddMaskTexture(mask)
    PrepareHover(highlight)
    button.Highlight = highlight
    button:SetScript('OnClick', function(self)
        local current = C_SpecializationInfo.GetSpecialization()
        if (self.specIndex and self.specIndex ~= current) then
            C_SpecializationInfo.SetSpecialization(self.specIndex)
        end
    end)
    button:SetScript('OnEnter', function(self)
        SetHover(self.Highlight, true)
        if (not self.specIndex) then
            return
        end
        local _, specName, description = C_SpecializationInfo.GetSpecializationInfo(self.specIndex)
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetText(specName or '')
        if (description and description ~= '') then
            GameTooltip:AddLine(description, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function(self)
        SetHover(self.Highlight, false)
        GameTooltip:Hide()
    end)
    return button
end

talents.Create = function(self)
    local window = EXFrames:GetFrame('window-frame'):Create({
        size = { 1580, 900 },
        title = '',
        disableResize = true,
        disableLogoAndVersion = true,
        legacyChrome = {
            hideHeaderBar = true,
            close = {
                width = 38,
                height = 28,
                inset = { 8, 5 },
                buttonBg = EXUI.const.textures.characterFrame.input.buttonBg,
                closeIcon = EXUI.const.textures.frame.closeIcon,
                iconSize = 14,
                normalColor = EXUI.const.theme.faded,
                hoverColor = EXUI.const.theme.dangerHover,
            },
        },
    })
    self.window = window
    window.skipShowAnimation = true
    window.onClose = function()
        builds:HideDialogs()
        talents:CollapseSearch()
    end
    builds:Create(window)
    pvp:Create(window)
    window.Texture:Hide()
    window.title:Hide()
    window.headerContentGap = 0
    window:SetHeaderInset(0)
    window:SetHeaderHeight(0)

    local container = window.container
    container:SetClipsChildren(true)
    container:SetFrameLevel(window:GetFrameLevel() + 5)
    window.header:SetFrameLevel(window:GetFrameLevel() + 10)

    local talentArt = window:CreateTexture(nil, 'BACKGROUND', nil, 1)
    talentArt:SetPoint('CENTER')
    self.talentArt = talentArt
    local cornerMask = window:CreateMaskTexture()
    cornerMask:SetAllPoints()
    cornerMask:SetTexture(WINDOW_BG, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    cornerMask:SetTextureSliceMargins(WINDOW_CORNER, WINDOW_CORNER, WINDOW_CORNER, WINDOW_CORNER)
    cornerMask:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    talentArt:AddMaskTexture(cornerMask)
    window:HookScript('OnSizeChanged', function()
        talents:FitBackground()
    end)
    local tabBar = CreateFrame('Frame', nil, window)
    tabBar:SetSize(200, WINDOW_TAB_FONT + WINDOW_TAB_PAD_Y)
    tabBar:SetPoint('TOPLEFT', window, 'BOTTOMLEFT', 22, WINDOW_TAB_SLICE)
    tabBar:SetFrameLevel(window:GetFrameLevel() + 30)
    tabBar:SetClipsChildren(false)
    self.tabBar = tabBar

    local talentsTab = CreateTabButton(tabBar, 'Talents', true)
    talentsTab:SetPoint('LEFT', 0, 0)
    talentsTab:SetScript('OnClick', function()
        talents:SetTab('talents')
    end)
    local spellTab = CreateTabButton(tabBar, 'Spellbook', true)
    spellTab:SetPoint('LEFT', talentsTab, 'RIGHT', 4, 0)
    spellTab:SetScript('OnClick', function()
        talents:SetTab('spellbook')
    end)
    self.tabButtons = {
        talents = talentsTab,
        spellbook = spellTab,
    }
    tabBar:SetSize(talentsTab:GetWidth() + spellTab:GetWidth() + 4, talentsTab:GetHeight())

    local defaultButton = CreateFrame('Button', nil, window)
    defaultButton:SetSize(38, 28)
    defaultButton:SetPoint('TOPRIGHT', window.close, 'TOPLEFT', -5, 0)
    defaultButton:SetFrameLevel(window.header:GetFrameLevel() + 1)
    local defaultBg = defaultButton:CreateTexture(nil, 'BACKGROUND')
    defaultBg:SetTexture(EXUI.const.textures.frame.inputs.buttonBg)
    defaultBg:SetTextureSliceMargins(20, 20, 20, 20)
    defaultBg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    defaultBg:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
    defaultBg:SetAllPoints()
    local defaultIcon = defaultButton:CreateTexture(nil, 'OVERLAY')
    defaultIcon:SetTexture(EXUI.const.textures.characterFrame.toBlizzIcon)
    defaultIcon:SetSize(17, 12)
    defaultIcon:SetPoint('CENTER')
    defaultButton:SetScript('OnClick', function()
        talents:OpenDefault()
    end)
    defaultButton.Tooltip = tooltip:Get({
        text = 'Open Default Talents',
    }, defaultButton)
    defaultButton:SetScript('OnEnter', function(self)
        defaultBg:SetVertexColor(60 / 255, 60 / 255, 60 / 255, 1)
        self.Tooltip:ShowTooltip()
    end)
    defaultButton:SetScript('OnLeave', function(self)
        defaultBg:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
        self.Tooltip:HideTooltip()
    end)

    local talentsPanel = CreateFrame('Frame', nil, container)
    talentsPanel:SetPoint('TOPLEFT', 0, -86)
    talentsPanel:SetPoint('BOTTOMRIGHT')
    self.talentsPanel = talentsPanel

    local spellBookPanel = CreateFrame('Frame', nil, container)
    spellBookPanel:SetPoint('TOPLEFT', 12, -12)
    spellBookPanel:SetPoint('BOTTOMRIGHT', -8, 12)
    spellBookPanel:Hide()
    self.spellBookPanel = spellBookPanel

    local bottomBar = CreateFrame('Frame', nil, talentsPanel)
    bottomBar:SetPoint('BOTTOMLEFT', 8, 8)
    bottomBar:SetPoint('BOTTOMRIGHT', -8, 8)
    bottomBar:SetHeight(BORDER_SIZE)

    local specRow = CreateFrame('Frame', nil, bottomBar)
    specRow:SetPoint('BOTTOMLEFT')
    specRow:SetSize(1, BORDER_SIZE)
    self.specRow = specRow
    self.specButtons = {}
    for index = 1, 4 do
        local button = CreateSpecButton(specRow)
        button:SetPoint('LEFT', (index - 1) * (BORDER_SIZE + SPEC_GAP), 0)
        self.specButtons[index] = button
    end

    local heroRow = CreateFrame('Frame', nil, bottomBar)
    heroRow:SetPoint('LEFT', specRow, 'RIGHT', 16, 0)
    heroRow:SetPoint('RIGHT', bottomBar, 'CENTER', -90, 0)
    heroRow:SetHeight(TAB_HEIGHT)
    self.heroRow = heroRow
    self.heroButtons = {}
    for index = 1, 3 do
        local button = CreateTabButton(heroRow, '')
        button:SetWidth(160)
        button:SetPoint('LEFT', (index - 1) * 168, 0)
        button:SetScript('OnClick', function(self)
            if (self.configID and self.nodeID and self.entryID) then
                local canEdit = C_ClassTalents.CanEditTalents()
                if (canEdit) then
                    C_Traits.SetSelection(self.configID, self.nodeID, self.entryID)
                end
            end
        end)
        self.heroButtons[index] = button
    end

    local search = CreateFrame('Frame', nil, bottomBar)
    search:SetSize(SEARCH_COLLAPSED, SEARCH_ICON)
    search:SetClipsChildren(true)
    search:SetFrameLevel(bottomBar:GetFrameLevel() + 5)
    self.searchFrame = search

    local searchBox = CreateFrame('EditBox', nil, search)
    searchBox:SetAutoFocus(false)
    searchBox:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    searchBox:SetTextColor(1, 1, 1, 1)
    searchBox:SetSize(SEARCH_BOX_WIDTH, SEARCH_ICON)
    searchBox:SetPoint('RIGHT', -(SEARCH_ICON + SEARCH_GAP), 0)
    searchBox:SetTextInsets(6, 6, 0, 0)
    searchBox:SetMaxLetters(50)
    searchBox:Hide()
    local searchBg = searchBox:CreateTexture(nil, 'BACKGROUND')
    searchBg:SetAllPoints()
    searchBg:SetColorTexture(0, 0, 0, 0.15)
    local searchMask = searchBox:CreateMaskTexture()
    searchMask:SetAllPoints()
    searchMask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    searchMask:SetTextureSliceMargins(10, 10, 10, 10)
    searchMask:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    searchBg:AddMaskTexture(searchMask)
    searchBox:SetScript('OnTextChanged', function(box)
        tree:SetSearchText(box:GetText())
    end)
    searchBox:SetScript('OnEscapePressed', function()
        talents:CollapseSearch()
    end)
    searchBox:SetScript('OnEnterPressed', function(box)
        box:ClearFocus()
    end)
    self.searchBox = searchBox

    local searchButton = CreateFrame('Button', nil, search)
    searchButton:SetSize(SEARCH_ICON, SEARCH_ICON)
    searchButton:SetPoint('RIGHT', 0, 0)
    local searchIcon = searchButton:CreateTexture(nil, 'ARTWORK')
    searchIcon:SetAllPoints()
    searchIcon:SetTexture(SEARCH_TEX)
    searchIcon:SetAlpha(0.85)
    searchButton:SetScript('OnEnter', function()
        searchIcon:SetAlpha(1)
    end)
    searchButton:SetScript('OnLeave', function()
        searchIcon:SetAlpha(0.85)
    end)
    searchButton:SetScript('OnClick', function()
        if (search.expanded) then
            talents:CollapseSearch()
        else
            talents:AnimateSearch(true)
        end
    end)

    local applyButton = EXFrames:GetFrame('simple-button'):Create(bottomBar)
    applyButton:SetPoint('CENTER')
    applyButton:SetText('Apply Changes')
    EXUI:SetSize(applyButton, applyButton.text:GetStringWidth() + 20, 24)
    if (applyButton.PPBorder) then
        applyButton.PPBorder:SetBorderThickness(1)
    end
    applyButton:SetOnClick(function()
        local importString = builds:CurrentImportString()
        local success = C_ClassTalents.CommitConfig()
        if (success) then
            builds:RecordApplied(importString)
            builds:ConsumePendingConfig()
        end
    end)
    self.applyButton = applyButton

    local resetButton = CreateFrame('Button', nil, bottomBar)
    resetButton:SetSize(24, 28)
    resetButton:SetPoint('LEFT', applyButton, 'RIGHT', 8, 0)
    resetButton:Hide()
    local resetIcon = resetButton:CreateTexture(nil, 'ARTWORK')
    resetIcon:SetAllPoints()
    resetIcon:SetTexture([[Interface/Addons/ExalityUI/Assets/Images/Talents/reset-icon.png]])
    resetButton:SetScript('OnClick', function()
        local configID = C_ClassTalents.GetActiveConfigID()
        if (configID) then
            C_Traits.RollbackConfig(configID)
        end
        builds:ConsumePendingConfig()
    end)
    resetButton:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Reset')
        GameTooltip:Show()
    end)
    resetButton:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    self.resetButton = resetButton

    local points = bottomBar:CreateFontString(nil, 'OVERLAY')
    points:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    points:SetPoint('RIGHT', applyButton, 'LEFT', -16, 0)
    points:SetText('Unspent 0')
    points:Hide()
    self.pointsText = points

    local sidebarButton = CreateFrame('Button', nil, bottomBar)
    sidebarButton:SetSize(27, 23)
    sidebarButton:SetPoint('RIGHT', -8, 0)
    local sidebarIcon = sidebarButton:CreateTexture(nil, 'ARTWORK')
    sidebarIcon:SetTexture([[Interface/Addons/ExalityUI/Assets/Images/Talents/open-sidebar.png]])
    sidebarIcon:SetAllPoints()
    sidebarButton.Tooltip = tooltip:Get({
        text = 'Builds',
    }, sidebarButton)
    sidebarButton:SetScript('OnClick', function()
        builds:Toggle()
    end)
    sidebarButton:SetScript('OnEnter', function(self)
        sidebarIcon:SetAlpha(1)
        self.Tooltip:ShowTooltip()
    end)
    sidebarButton:SetScript('OnLeave', function(self)
        sidebarIcon:SetAlpha(0.85)
        self.Tooltip:HideTooltip()
    end)
    sidebarIcon:SetAlpha(0.85)

    local importButton = CreateFrame('Button', nil, bottomBar)
    importButton:SetHeight(25)
    importButton:SetPoint('RIGHT', sidebarButton, 'LEFT', -16, 0)
    local importText = importButton:CreateFontString(nil, 'OVERLAY')
    importText:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    importText:SetPoint('LEFT', 0, 0)
    importText:SetText('Import')
    importText:SetTextColor(unpack(EXUI.const.theme.text))
    local importIcon = importButton:CreateTexture(nil, 'ARTWORK')
    importIcon:SetTexture([[Interface/Addons/ExalityUI/Assets/Images/Talents/import-icon.png]])
    importIcon:SetSize(29, 25)
    importIcon:SetPoint('LEFT', importText, 'RIGHT', 6, 0)
    local textWidth = importText:GetStringWidth()
    if (textWidth < 20) then
        textWidth = 42
    end
    importButton:SetWidth(textWidth + 35)
    importButton:SetScript('OnClick', function()
        builds:ShowImport()
    end)
    importButton:SetScript('OnEnter', function()
        importText:SetTextColor(1, 1, 1, 1)
        importIcon:SetAlpha(1)
    end)
    importButton:SetScript('OnLeave', function()
        importText:SetTextColor(unpack(EXUI.const.theme.text))
        importIcon:SetAlpha(0.85)
    end)
    importIcon:SetAlpha(0.85)
    self.importButton = importButton

    local pvpButton = CreateFrame('Button', nil, bottomBar)
    pvpButton:SetHeight(25)
    pvpButton:SetPoint('RIGHT', importButton, 'LEFT', -16, 0)
    local pvpText = pvpButton:CreateFontString(nil, 'OVERLAY')
    pvpText:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    pvpText:SetPoint('LEFT', 0, 0)
    pvpText:SetText('PvP')
    pvpText:SetTextColor(unpack(EXUI.const.theme.text))
    local pvpIcon = pvpButton:CreateTexture(nil, 'ARTWORK')
    pvpIcon:SetTexture([[Interface/Addons/ExalityUI/Assets/Images/Talents/pvp-icon.png]])
    pvpIcon:SetSize(22, 22)
    pvpIcon:SetPoint('LEFT', pvpText, 'RIGHT', 6, 0)
    local pvpWidth = pvpText:GetStringWidth()
    if (pvpWidth < 20) then
        pvpWidth = 24
    end
    pvpButton:SetWidth(pvpWidth + 28)
    pvpButton.Text = pvpText
    pvpButton.Icon = pvpIcon
    pvpButton:SetScript('OnClick', function()
        pvp:Toggle()
    end)
    pvpButton:SetScript('OnEnter', function(self)
        self.Text:SetTextColor(1, 1, 1, 1)
        self.Icon:SetAlpha(1)
    end)
    pvpButton:SetScript('OnLeave', function(self)
        if (self.isOpen) then
            self.Text:SetTextColor(1, 1, 1, 1)
            self.Icon:SetAlpha(1)
        else
            self.Text:SetTextColor(unpack(EXUI.const.theme.text))
            self.Icon:SetAlpha(0.85)
        end
    end)
    pvpIcon:SetAlpha(0.85)
    self.pvpButton = pvpButton
    pvp.button = pvpButton
    pvp.importButton = importButton

    local status = bottomBar:CreateFontString(nil, 'OVERLAY')
    status:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')
    status:SetPoint('LEFT', resetButton, 'RIGHT', 16, 0)
    status:SetPoint('RIGHT', pvpButton, 'LEFT', -8, 0)
    status:SetJustifyH('LEFT')
    status:SetTextColor(EXUI.const.theme.textMuted[1], EXUI.const.theme.textMuted[2], EXUI.const.theme.textMuted[3], 1)
    self.statusText = status
    pvp:UpdateButton()

    local clip = tree:Create(talentsPanel)
    clip:SetPoint('TOPLEFT', 8, 0)
    clip:SetPoint('BOTTOMRIGHT', bottomBar, 'TOPRIGHT', 0, 8)

    spellBook:Create(spellBookPanel)

    local escapeHandler = CreateFrame('Button', nil, container)
    escapeHandler:EnableKeyboard(true)
    escapeHandler:SetScript('OnKeyDown', function(handler, key)
        if (key == 'ESCAPE') then
            if (not InCombatLockdown()) then
                handler:SetPropagateKeyboardInput(false)
            end
            window:HideWindow()
            return
        end
        if (not InCombatLockdown()) then
            handler:SetPropagateKeyboardInput(true)
        end
    end)
end

talents.Show = function(self, tab)
    if (not self.isCreated) then
        self:Create()
        self.isCreated = true
    end
    if (not self.window:IsShown()) then
        self.window:ShowWindow()
    end
    if (self.tabBar) then
        self.tabBar:SetFrameLevel(self.window:GetFrameLevel() + 30)
    end
    self:SetTab(tab or self.activeTab or 'talents')
end

talents.Enable = function(self)
    self.enabled = true
end

talents.Disable = function(self)
    self.enabled = false
    if (self.window and self.window:IsShown()) then
        self.window:HideWindow()
    end
end

talents.Init = function(self)
    if (PlayerSpellsUtil) then
        hooksecurefunc(PlayerSpellsUtil, 'TogglePlayerSpellsFrame', function(suggestedTab, inspectUnit)
            if (talents.suppressHook or InCombatLockdown() or not talents.enabled or talents.override or inspectUnit) then
                return
            end
            if (not PlayerSpellsFrame or not PlayerSpellsFrame:IsShown()) then
                return
            end
            talents.suppressHook = true
            PlayerSpellsUtil.TogglePlayerSpellsFrame(suggestedTab, inspectUnit)
            talents.suppressHook = false
            talents:HandleIntercept(suggestedTab)
        end)

        hooksecurefunc(PlayerSpellsUtil, 'ToggleSpellBookFrame', function(spellBookCategory)
            if (talents.suppressHook or InCombatLockdown() or not talents.enabled or talents.override) then
                return
            end
            if (not PlayerSpellsFrame or not PlayerSpellsFrame:IsShown()) then
                return
            end
            talents.suppressHook = true
            PlayerSpellsUtil.ToggleSpellBookFrame(spellBookCategory)
            talents.suppressHook = false
            talents:HandleIntercept(PlayerSpellsUtil.FrameTabs.SpellBook)
        end)
    end

    if (customWindows.Data:GetValue('TalentsEnabled') == true) then
        self:Enable()
    end
end

EXUI:RegisterEventHandler('PLAYER_REGEN_DISABLED', 'talents-window-hide', function()
    if (talents.window and talents.window:IsShown()) then
        talents.window:HideWindowImmediate()
    end
end)

EXUI:RegisterEventHandler({
    'TRAIT_CONFIG_UPDATED',
    'TRAIT_NODE_CHANGED',
    'TRAIT_NODE_CHANGED_PARTIAL',
    'TRAIT_TREE_CURRENCY_INFO_UPDATED',
    'TRAIT_SUB_TREE_CHANGED',
    'TRAIT_TREE_CHANGED',
    'ACTIVE_PLAYER_SPECIALIZATION_CHANGED',
    'PLAYER_TALENT_UPDATE',
    'SPELLS_CHANGED',
}, 'talents-window-refresh', function()
    talents:QueueRefresh()
end)
