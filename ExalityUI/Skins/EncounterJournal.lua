---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIEncounterJournalSkin
local encounterJournalSkin = EXUI:GetModule('skin-EncounterJournal')

local TITLE_SIZE = 13
local PANEL_BG_ALPHA = 0.95
local HEADER_HEIGHT = 26

local TAB_TEXT_SIZE = 11
local TAB_HEIGHT = 28
local TAB_ACTIVE_EXTRA = 4
local TAB_TEXT_PADDING = 20
local TAB_INSET = 1
local TAB_GRADIENT_HEIGHT = 18
local TAB_SLICE = 6
local BOTTOM_TAB_FIRST_X = 11
local BOTTOM_TAB_FIRST_Y = 2
local BOTTOM_TAB_SPACING = 3
local TAB_TEXT_TOP_Y_INACTIVE = -10
local TAB_TEXT_TOP_Y_ACTIVE = -10

local NAV_CRUMB_SPACING = 2
local EXPANSION_DROPDOWN_X_ADJUST = 0
local EXPANSION_DROPDOWN_Y_ADJUST = -3

local PANEL_TAB_TEXTURE_KEYS = {
    'Left', 'Middle', 'Right',
    'LeftActive', 'MiddleActive', 'RightActive',
    'LeftHighlight', 'MiddleHighlight', 'RightHighlight',
}

local BOTTOM_TAB_KEYS = {
    'JourneysTab',
    'MonthlyActivitiesTab',
    'suggestTab',
    'dungeonsTab',
    'raidsTab',
    'LootJournalTab',
    'TutorialsTab',
}

local ENCOUNTER_TAB_KEYS = { 'overviewTab', 'lootTab', 'bossTab', 'modelTab' }
local ENCOUNTER_OVERVIEW_TAB_X = 8
local ENCOUNTER_OVERVIEW_TAB_Y = -35
local ENCOUNTER_SIDE_TAB_ICON_X = -2

local INFO_BG_COLOR = { 179 / 255, 179 / 255, 179 / 255, 1 }
local DESCRIPTION_TEXT_COLOR = { 205 / 255, 198 / 255, 190 / 255, 1 }
local DESCRIPTION_TEXT_SIZE = 12
local DESCRIPTION_HTML_TEXT_TYPE = 'p'
local DESCRIPTION_BG_COLOR = { 0.3, 0.3, 0.3, 1 }
local DESCRIPTION_SHADOW_COLOR = { 0, 0, 0, 0.75 }
local DESCRIPTION_SHADOW_OFFSET_X = 1
local DESCRIPTION_SHADOW_OFFSET_Y = -1
local DESCRIPTION_LINK_COLOR_CODES = {
    '|cff66bbff', -- encounter journal ability links
    '|cff66BBFF',
    '|cff0070dd', -- generic hyperlink blue
    '|cff71d5ff',
}

local hookedDescriptionTextWidgets = {}

local function GetTheme()
    return EXUI.const.theme
end

local function GetDescriptionLinkColorCode()
    local accent = GetTheme().accent
    return string.format(
        '|cff%02x%02x%02x',
        math.floor(accent[1] * 255 + 0.5),
        math.floor(accent[2] * 255 + 0.5),
        math.floor(accent[3] * 255 + 0.5)
    )
end

local function GetDescriptionHyperlinkFormat()
    local accent = GetTheme().accent
    local hex = string.format(
        '%02x%02x%02x',
        math.floor(accent[1] * 255 + 0.5),
        math.floor(accent[2] * 255 + 0.5),
        math.floor(accent[3] * 255 + 0.5)
    )
    return '|cff' .. hex .. '|H%s|h[%s]|h|r'
end

local function RecolorDescriptionLinks(text)
    if (not text or text == '') then return text end

    local linkColor = GetDescriptionLinkColorCode()

    for _, colorCode in ipairs(DESCRIPTION_LINK_COLOR_CODES) do
        text = text:gsub(colorCode, linkColor)
    end

    -- Strip named or hex color wrappers around hyperlinks, then apply accent.
    text = text:gsub('|cn[^:]-:(|H[^|]+|h.-|h)|r', '%1')
    text = text:gsub('|c[fF][fF]%x%x%x%x%x%x(|H[^|]+|h.-|h)|r', '%1')
    text = text:gsub('(|H[^|]+|h.-|h)', linkColor .. '%1|r')

    return text
end

local function HookDescriptionSetText(widget)
    if (not widget or hookedDescriptionTextWidgets[widget]) then return end
    hookedDescriptionTextWidgets[widget] = true

    local originalSetText = widget.SetText
    if (type(originalSetText) ~= 'function') then return end

    widget.SetText = function(self, text, ...)
        if (type(text) == 'string' and text ~= '') then
            self.exuiDescriptionRawText = text
            text = RecolorDescriptionLinks(text)
        end
        return originalSetText(self, text, ...)
    end
end

local function RefreshDescriptionText(widget)
    if (not widget) then return end

    HookDescriptionSetText(widget)

    if (widget.exuiDescriptionRawText) then
        widget:SetText(widget.exuiDescriptionRawText)
    end
end

local function HookInfoHeaderDescriptionWidgets(header)
    if (not header) then return end

    if (header.description) then
        HookDescriptionSetText(header.description)
    end
    if (header.overviewDescription and header.overviewDescription.Text) then
        HookDescriptionSetText(header.overviewDescription.Text)
    end
    for _, bullet in ipairs(header.Bullets or {}) do
        if (bullet.Text) then
            HookDescriptionSetText(bullet.Text)
        end
    end
end

local function HookEncounterDescriptionWidgets(encounter)
    if (not encounter) then return end

    if (encounter.infoFrame and encounter.infoFrame.description) then
        HookDescriptionSetText(encounter.infoFrame.description)
    end

    local overviewFrame = encounter.overviewFrame
    if (overviewFrame) then
        if (overviewFrame.loreDescription) then
            HookDescriptionSetText(overviewFrame.loreDescription)
        end
        if (overviewFrame.overviewDescription and overviewFrame.overviewDescription.Text) then
            HookDescriptionSetText(overviewFrame.overviewDescription.Text)
        end
        for _, bullet in ipairs(overviewFrame.Bullets or {}) do
            if (bullet.Text) then
                HookDescriptionSetText(bullet.Text)
            end
        end
        for _, overview in ipairs(overviewFrame.overviews or {}) do
            HookInfoHeaderDescriptionWidgets(overview)
        end
    end

    for _, header in ipairs(encounter.usedHeaders or {}) do
        HookInfoHeaderDescriptionWidgets(header)
    end
end

local function RefreshBossHeaderDescriptionLinks(encounter)
    if (not encounter or not C_EncounterJournal or not C_EncounterJournal.GetSectionInfo) then return end

    for _, infoHeader in ipairs(encounter.usedHeaders or {}) do
        if (infoHeader.isOverview or not infoHeader.myID or not infoHeader.description) then
            if (infoHeader.overviewDescription and not infoHeader.isOverview) then
                infoHeader.overviewDescription:Hide()
            end
        else
            HookDescriptionSetText(infoHeader.description)
            if (infoHeader.overviewDescription) then
                infoHeader.overviewDescription:Hide()
            end

            local sectionInfo = C_EncounterJournal.GetSectionInfo(infoHeader.myID)
            if (sectionInfo and sectionInfo.description) then
                local description = sectionInfo.description:gsub('|cffffffff(.-)|r', '%1')
                local descriptionWasShown = infoHeader.description:IsShown()
                infoHeader.description:SetText(description)
                if (not descriptionWasShown) then
                    infoHeader.description:Hide()
                end
            end
        end
    end
end

local function SetDescriptionWidgetText(widget, text)
    if (not widget or type(text) ~= 'string') then return end
    HookDescriptionSetText(widget)
    widget:SetText(text)
end

local function ApplyBulletDescriptionSource(parent, description)
    if (not parent or type(description) ~= 'string' or description == '') then return end

    local overviewDescription = parent.overviewDescription
    if (not string.find(description, '$bullet;')) then
        if (overviewDescription) then
            overviewDescription.textString = description
            SetDescriptionWidgetText(overviewDescription.Text, description)
        end
        return
    end

    local desc = strtrim(string.match(description, '(.-)$bullet;') or '')
    if (overviewDescription) then
        overviewDescription.textString = desc
        SetDescriptionWidgetText(overviewDescription.Text, desc)
    end

    local index = 1
    for chunk in string.gmatch(description, '$bullet;([^$]+)') do
        local text = strtrim(chunk) .. '|n|n'
        local bullet = parent.Bullets and parent.Bullets[index]
        if (bullet and bullet.Text) then
            SetDescriptionWidgetText(bullet.Text, text)
        end
        index = index + 1
    end
end

local function GetSimpleHTMLSourceText(simpleHtml)
    if (not simpleHtml) then return end

    if (simpleHtml.exuiDescriptionRawText) then
        return simpleHtml.exuiDescriptionRawText
    end

    local parent = simpleHtml:GetParent()
    if (parent and parent.textString) then
        return parent.textString
    end

    if (simpleHtml.GetText) then
        return simpleHtml:GetText()
    end
end

local function StripButtonTextures(button)
    skins:StripTexture(button:GetNormalTexture())
    skins:StripTexture(button:GetPushedTexture())
    if (button.GetDisabledTexture) then skins:StripTexture(button:GetDisabledTexture()) end
    if (button.GetHighlightTexture) then skins:StripTexture(button:GetHighlightTexture()) end
end

local function IsPanelTabSelected(tab)
    if (tab.isDisabled) then return false end
    return not tab:IsEnabled()
end

local function ConfigureTabBackgroundTexture(bg)
    bg:SetTexture(EXUI.const.textures.frame.whiteTextured)
    bg:SetTextureSliceMargins(TAB_SLICE, TAB_SLICE, TAB_SLICE, TAB_SLICE)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAlpha(1)
end

local function EnsureBottomTabChrome(tab)
    if (not tab.exuiTabBg) then
        local bg = tab:CreateTexture(nil, 'BACKGROUND', nil, 0)
        ConfigureTabBackgroundTexture(bg)
        tab.exuiTabBg = bg
    else
        ConfigureTabBackgroundTexture(tab.exuiTabBg)
    end

    if (not tab.exuiTabGlow) then
        local glow = tab:CreateTexture(nil, 'ARTWORK', nil, 1)
        glow:SetTexture(EXUI.const.textures.frame.gradientBottom)
        glow:SetBlendMode('BLEND')
        tab.exuiTabGlow = glow
    end
end

local function GetBottomTabs(frame)
    local tabs = {}
    for _, key in ipairs(BOTTOM_TAB_KEYS) do
        local tab = frame[key]
        if (tab and tab:IsShown()) then
            tabs[#tabs + 1] = tab
        end
    end
    return tabs
end

local function ApplyBottomTabAnchors(frame)
    if (not frame) then return end

    local tabs = GetBottomTabs(frame)
    for i, tab in ipairs(tabs) do
        tab:ClearAllPoints()
        if (i == 1) then
            tab:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', BOTTOM_TAB_FIRST_X, BOTTOM_TAB_FIRST_Y)
        else
            tab:SetPoint('TOPLEFT', tabs[i - 1], 'TOPRIGHT', BOTTOM_TAB_SPACING, 0)
        end
    end
end

local function ApplyBottomTabLayout(tab, bg, glow, selected)
    bg:ClearAllPoints()
    bg:SetPoint('TOPLEFT', tab, 'TOPLEFT', TAB_INSET, -TAB_INSET)
    bg:SetPoint('BOTTOMRIGHT', tab, 'BOTTOMRIGHT', -TAB_INSET, TAB_INSET)

    glow:ClearAllPoints()
    if (selected) then
        local glowHeight = EXUI:ScalePixel(TAB_GRADIENT_HEIGHT, tab, 1)
        glow:SetPoint('BOTTOMLEFT', bg, 'BOTTOMLEFT')
        glow:SetPoint('BOTTOMRIGHT', bg, 'BOTTOMRIGHT')
        glow:SetPoint('TOPLEFT', bg, 'BOTTOMLEFT', 0, glowHeight)
        glow:SetPoint('TOPRIGHT', bg, 'BOTTOMRIGHT', 0, glowHeight)
        glow:SetVertexColor(unpack(GetTheme().accent))
        glow:SetAlpha(1)
        glow:Show()
    else
        glow:Hide()
    end
end

local function ApplyBottomTabTextLayout(tab, selected)
    local text = tab.Text
    if (not text) then return end

    text:SetDrawLayer('OVERLAY', 7)
    text:Show()
    text:SetAlpha(1)
    text:SetFont(EXUI.const.fonts.DEFAULT, TAB_TEXT_SIZE, 'OUTLINE')
    text:ClearAllPoints()
    text:SetPoint('TOP', tab, 'TOP', 0, selected and TAB_TEXT_TOP_Y_ACTIVE or TAB_TEXT_TOP_Y_INACTIVE)
end

local function ApplyBottomTabTextColor(tab)
    local th = GetTheme()
    local text = tab.Text
    if (not text) then return end

    if (IsPanelTabSelected(tab)) then
        text:SetTextColor(unpack(th.white))
    elseif (tab.isDisabled) then
        text:SetTextColor(unpack(th.textMuted))
    elseif (tab:IsMouseOver()) then
        text:SetTextColor(unpack(th.white))
    else
        text:SetTextColor(unpack(th.gray))
    end
    text:SetAlpha(1)
end

local function UpdateBottomTabWidth(tab)
    local text = tab.Text
    if (not text) then return end

    local width = (text:GetStringWidth() or 0) + TAB_TEXT_PADDING
    local textWidth = math.max(0, width - TAB_TEXT_PADDING)
    if (textWidth > 0) then
        text:SetWidth(textWidth)
    end
    tab:SetWidth(width)
end

local function ApplyBottomTabVisualState(tab)
    if (not tab.exuiTabSkinned) then return end

    EnsureBottomTabChrome(tab)
    local th = GetTheme()
    local selected = IsPanelTabSelected(tab)
    local bg = tab.exuiTabBg
    local glow = tab.exuiTabGlow

    tab:SetHeight(selected and (TAB_HEIGHT + TAB_ACTIVE_EXTRA) or TAB_HEIGHT)

    if (selected) then
        bg:SetVertexColor(unpack(th.backgroundLight))
    else
        bg:SetVertexColor(unpack(th.backgroundDeep))
    end
    bg:Show()

    ApplyBottomTabLayout(tab, bg, glow, selected)
    ApplyBottomTabTextLayout(tab, selected)
    ApplyBottomTabTextColor(tab)
    UpdateBottomTabWidth(tab)
end

local function SkinBottomTab(tab)
    if (not tab or tab.exuiTabSkinned) then return end
    tab.exuiTabSkinned = true

    for _, key in ipairs(PANEL_TAB_TEXTURE_KEYS) do
        local region = tab[key]
        if (region) then skins:StripTexture(region) end
    end

    if (tab.TabTextures) then
        for _, region in ipairs(tab.TabTextures) do
            skins:StripTexture(region)
        end
    end

    EnsureBottomTabChrome(tab)
    ApplyBottomTabVisualState(tab)

    tab:HookScript('OnEnter', function(btn)
        if (IsPanelTabSelected(btn)) then return end
        ApplyBottomTabTextColor(btn)
    end)
    tab:HookScript('OnLeave', function(btn)
        if (IsPanelTabSelected(btn)) then return end
        ApplyBottomTabTextColor(btn)
    end)
end

local function RefreshBottomTabs(frame)
    if (not frame) then return end

    ApplyBottomTabAnchors(frame)

    for _, key in ipairs(BOTTOM_TAB_KEYS) do
        local tab = frame[key]
        if (tab and tab.exuiTabSkinned) then
            if (IsPanelTabSelected(tab)) then
                tab:Disable()
            end
            ApplyBottomTabVisualState(tab)
        end
    end

    for _, tab in ipairs(frame.Tabs or {}) do
        if (tab.exuiTabSkinned) then
            if (IsPanelTabSelected(tab)) then
                tab:Disable()
            end
            ApplyBottomTabVisualState(tab)
        end
    end
end

local function SkinBottomTabs(frame)
    for _, key in ipairs(BOTTOM_TAB_KEYS) do
        SkinBottomTab(frame[key])
    end
    for _, tab in ipairs(frame.Tabs or {}) do
        SkinBottomTab(tab)
    end
    RefreshBottomTabs(frame)
end

local function IsEncounterSideTabSelected(tab)
    return tab.selected and tab.selected:IsShown()
end

local function ApplyEncounterSideTabState(tab)
    if (not tab or not tab.exuiSideTabSkinned) then return end
    local th = GetTheme()
    local selected = IsEncounterSideTabSelected(tab)
    local enabled = tab:IsEnabled()
    local desaturated = not enabled

    if (selected) then
        tab.exuiSideTabBg:SetVertexColor(unpack(th.backgroundLight))
    else
        tab.exuiSideTabBg:SetVertexColor(unpack(th.backgroundDeep))
    end

    if (tab.selected) then
        tab.selected:SetDesaturated(desaturated)
        if (desaturated) then
            tab.selected:SetVertexColor(unpack(th.gray))
        else
            tab.selected:SetVertexColor(1, 1, 1, 1)
        end
    end
    if (tab.unselected) then
        tab.unselected:SetDesaturated(desaturated)
        tab.unselected:SetVertexColor(unpack(th.gray))
    end
end

local function ApplyEncounterSideTabIconLayout(tab)
    if (not tab) then return end

    if (tab.unselected) then
        tab.unselected:ClearAllPoints()
        tab.unselected:SetPoint('CENTER', tab, 'CENTER', ENCOUNTER_SIDE_TAB_ICON_X, 0)
    end
    if (tab.selected) then
        tab.selected:ClearAllPoints()
        tab.selected:SetPoint('CENTER', tab, 'CENTER', ENCOUNTER_SIDE_TAB_ICON_X, 0)
    end
end

local function SkinEncounterSideTab(tab)
    if (not tab or tab.exuiSideTabSkinned) then return end
    tab.exuiSideTabSkinned = true

    StripButtonTextures(tab)
    ApplyEncounterSideTabIconLayout(tab)

    if (not tab.exuiSideTabBg) then
        local bg = tab:CreateTexture(nil, 'BACKGROUND', nil, 0)
        bg:SetTexture(EXUI.const.textures.frame.whiteTextured)
        bg:SetTextureSliceMargins(TAB_SLICE, TAB_SLICE, TAB_SLICE, TAB_SLICE)
        bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
        bg:SetAllPoints()
        tab.exuiSideTabBg = bg
    end

    skins:AddBorder(tab, { thickness = 1, level = 600 })

    ApplyEncounterSideTabState(tab)
end

local function ApplyDescriptionFontString(fontString)
    if (not fontString) then return end

    HookDescriptionSetText(fontString)

    local alpha = fontString:GetAlpha()
    fontString:SetFont(EXUI.const.fonts.DEFAULT, DESCRIPTION_TEXT_SIZE, '')
    fontString:SetTextColor(unpack(DESCRIPTION_TEXT_COLOR))
    fontString:SetShadowColor(unpack(DESCRIPTION_SHADOW_COLOR))
    fontString:SetShadowOffset(DESCRIPTION_SHADOW_OFFSET_X, DESCRIPTION_SHADOW_OFFSET_Y)
    RefreshDescriptionText(fontString)
    fontString:SetAlpha(alpha)
end

local function ApplyDescriptionSimpleHTML(simpleHtml)
    if (not simpleHtml) then return end

    HookDescriptionSetText(simpleHtml)

    if (simpleHtml.SetHyperlinkFormat) then
        simpleHtml:SetHyperlinkFormat(GetDescriptionHyperlinkFormat())
    end
    if (simpleHtml.SetFont) then
        simpleHtml:SetFont(DESCRIPTION_HTML_TEXT_TYPE, EXUI.const.fonts.DEFAULT, DESCRIPTION_TEXT_SIZE, '')
    end
    if (simpleHtml.SetTextColor) then
        simpleHtml:SetTextColor(DESCRIPTION_HTML_TEXT_TYPE, unpack(DESCRIPTION_TEXT_COLOR))
    end
    if (simpleHtml.SetShadowColor) then
        simpleHtml:SetShadowColor(DESCRIPTION_HTML_TEXT_TYPE, unpack(DESCRIPTION_SHADOW_COLOR))
        simpleHtml:SetShadowOffset(DESCRIPTION_HTML_TEXT_TYPE, DESCRIPTION_SHADOW_OFFSET_X, DESCRIPTION_SHADOW_OFFSET_Y)
    end

    local text = GetSimpleHTMLSourceText(simpleHtml)
    if (text and text ~= '' and simpleHtml.SetText) then
        simpleHtml:SetText(text)
    end
end

local function ApplyDescriptionBullets(bullets)
    if (not bullets) then return end

    for _, bullet in ipairs(bullets) do
        ApplyDescriptionSimpleHTML(bullet.Text)
    end
end

local function ApplyInfoHeaderDescriptions(header)
    if (not header) then return end

    if (header.descriptionBG) then
        header.descriptionBG:SetVertexColor(unpack(DESCRIPTION_BG_COLOR))
    end

    ApplyDescriptionFontString(header.description)
    if (header.overviewDescription) then
        ApplyDescriptionSimpleHTML(header.overviewDescription.Text)
        if (not header.isOverview) then
            header.overviewDescription:Hide()
        end
    end
    ApplyDescriptionBullets(header.Bullets)
end

local function ApplyOverviewFrameDescriptions(overviewFrame)
    if (not overviewFrame) then return end

    ApplyDescriptionFontString(overviewFrame.loreDescription)
    if (overviewFrame.overviewDescription) then
        ApplyDescriptionSimpleHTML(overviewFrame.overviewDescription.Text)
    end
    ApplyDescriptionBullets(overviewFrame.Bullets)

    for _, overview in ipairs(overviewFrame.overviews or {}) do
        ApplyInfoHeaderDescriptions(overview)
    end
end

local function RefreshOverviewDescriptionLinks(encounter)
    if (not encounter) then return end

    local overviewFrame = encounter.overviewFrame
    if (not overviewFrame) then return end

    HookEncounterDescriptionWidgets(encounter)

    if (encounter.infoFrame and encounter.infoFrame.encounterID and overviewFrame.loreDescription) then
        local _, description = EJ_GetEncounterInfo(encounter.infoFrame.encounterID)
        if (description) then
            SetDescriptionWidgetText(overviewFrame.loreDescription, description)
        end
    end

    if (overviewFrame.rootOverviewSectionID and C_EncounterJournal) then
        local sectionInfo = C_EncounterJournal.GetSectionInfo(overviewFrame.rootOverviewSectionID)
        if (sectionInfo and sectionInfo.description) then
            ApplyBulletDescriptionSource(overviewFrame, sectionInfo.description)
        end
    end

    for _, overview in ipairs(overviewFrame.overviews or {}) do
        if (overview.sectionID and C_EncounterJournal) then
            local sectionInfo = C_EncounterJournal.GetSectionInfo(overview.sectionID)
            if (sectionInfo and sectionInfo.description) then
                ApplyBulletDescriptionSource(overview, sectionInfo.description)
            end
        end
    end

    ApplyOverviewFrameDescriptions(overviewFrame)
end

local function ApplyInstanceLoreDescription(instance)
    if (not instance or not instance.LoreScrollingFont) then return end

    local fontString = instance.LoreScrollingFont:GetFontString()
    ApplyDescriptionFontString(fontString)
end

local function ApplyEncounterContentDescriptions(encounter)
    if (not encounter) then return end

    ApplyOverviewFrameDescriptions(encounter.overviewFrame)
    ApplyInstanceLoreDescription(encounter.instance)

    if (encounter.infoFrame) then
        ApplyDescriptionFontString(encounter.infoFrame.description)
    end

    for _, header in ipairs(encounter.usedHeaders or {}) do
        ApplyInfoHeaderDescriptions(header)
    end
end

local function TintInfoBackground(texture)
    if (not texture) then return end
    texture:SetVertexColor(unpack(INFO_BG_COLOR))
end

local function ApplyEncounterInfoBackgrounds(info)
    if (not info) then return end

    TintInfoBackground(_G[info:GetName() .. 'BG'])

    local model = info.model
    if (model) then
        TintInfoBackground(model.dungeonBG)
    end
end

local function SkinEncounterInfoFrame(info)
    if (not info or info.exuiInfoBgSkinned) then return end
    info.exuiInfoBgSkinned = true

    if (info.leftShadow) then skins:StripTexture(info.leftShadow) end
    if (info.rightShadow) then skins:StripTexture(info.rightShadow) end

    ApplyEncounterInfoBackgrounds(info)
    HookEncounterDescriptionWidgets(EncounterJournal and EncounterJournal.encounter)
    ApplyEncounterContentDescriptions(EncounterJournal and EncounterJournal.encounter)
end

local function ApplyEncounterSideTabLayout(info)
    if (not info or not info.overviewTab or info.exuiSideTabsAnchored) then return end
    info.exuiSideTabsAnchored = true

    local overviewTab = info.overviewTab
    overviewTab:ClearAllPoints()
    overviewTab:SetPoint('TOPLEFT', info, 'TOPRIGHT', ENCOUNTER_OVERVIEW_TAB_X, ENCOUNTER_OVERVIEW_TAB_Y)
end

local function SkinEncounterSideTabs(info)
    if (not info) then return end

    ApplyEncounterSideTabLayout(info)

    for _, key in ipairs(ENCOUNTER_TAB_KEYS) do
        SkinEncounterSideTab(info[key])
    end
end

local function RefreshEncounterSideTabs(info)
    if (not info) then return end

    for _, key in ipairs(ENCOUNTER_TAB_KEYS) do
        ApplyEncounterSideTabState(info[key])
    end
end

local function SkinHeaderBackdrop(frame)
    if (frame.exuiHeaderBackdrop) then return end
    local th = GetTheme()

    local header = CreateFrame('Frame', nil, frame)
    header:EnableMouse(false)
    header:SetFrameLevel(2)
    header:SetPoint('TOPLEFT', frame, 'TOPLEFT', 1, -1)
    header:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -1, -1)
    header:SetHeight(HEADER_HEIGHT)
    frame.exuiHeaderBackdrop = header

    skins:AddBackdrop(header, { color = th.background, alpha = 1 })
end

local function AdjustTitleBarLayout(frame)
    local titleContainer = frame.TitleContainer
    if (titleContainer and not titleContainer.exuiAdjusted) then
        titleContainer.exuiAdjusted = true
        titleContainer:ClearAllPoints()
        titleContainer:SetPoint('TOPLEFT', frame, 'TOPLEFT', 16, -1)
        titleContainer:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -48, -1)
    end

    local navBar = frame.navBar
    if (navBar and not navBar.exuiNavAdjusted) then
        navBar.exuiNavAdjusted = true
        navBar:ClearAllPoints()
        navBar:SetPoint('TOPLEFT', frame, 'TOPLEFT', 8, -26)
        navBar:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -120, -26)
    end
end

local function ApplyNavButtonTextColor(button, text)
    local th = GetTheme()
    if (not button:IsEnabled()) then
        text:SetTextColor(unpack(th.white))
    else
        text:SetTextColor(unpack(th.gray))
    end
end

local function ApplyNavCrumbBackground(button, hovered)
    if (not button.exuiCrumbBg) then return end
    local th = GetTheme()
    if (hovered and button:IsEnabled()) then
        local panel = th.backgroundPanel
        button.exuiCrumbBg:SetVertexColor(panel[1], panel[2], panel[3], 0.65)
    else
        button.exuiCrumbBg:SetVertexColor(unpack(th.backgroundLight))
    end
end

local function SkinNavButton(button)
    if (not button or button.exuiSkinned) then return end
    button.exuiSkinned = true
    local th = GetTheme()

    skins:StripTexture(button:GetNormalTexture())
    skins:StripTexture(button:GetPushedTexture())
    skins:StripTexture(button:GetHighlightTexture())

    if (not button.exuiCrumbBg) then
        local bg = button:CreateTexture(nil, 'BACKGROUND', nil, 0)
        bg:SetTexture(EXUI.const.textures.frame.whiteTextured)
        bg:SetTextureSliceMargins(4, 4, 4, 4)
        bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
        bg:SetPoint('TOPLEFT', 0, 0)
        bg:SetPoint('BOTTOMRIGHT', 0, 0)
        button.exuiCrumbBg = bg
    end
    ApplyNavCrumbBackground(button, false)

    local text = button.text or (button.GetFontString and button:GetFontString())
    if (text) then
        text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        ApplyNavButtonTextColor(button, text)
    end

    button:HookScript('OnEnter', function(btn)
        ApplyNavCrumbBackground(btn, true)
        local label = btn.text or (btn.GetFontString and btn:GetFontString())
        if (label and btn:IsEnabled()) then label:SetTextColor(unpack(GetTheme().white)) end
    end)
    button:HookScript('OnLeave', function(btn)
        ApplyNavCrumbBackground(btn, false)
        local label = btn.text or (btn.GetFontString and btn:GetFontString())
        if (label) then ApplyNavButtonTextColor(btn, label) end
    end)
end

local function SkinNavBar(navBar)
    if (not navBar) then return end

    if (not navBar.exuiEJNav) then
        navBar.exuiEJNav = true
        local th = GetTheme()

        skins:StripAllTextures(navBar)
        if (navBar.overlay) then
            skins:StripAllTextures(navBar.overlay)
        end
        for _, key in ipairs({ 'InsetBorderBottomLeft', 'InsetBorderBottomRight', 'InsetBorderBottom', 'InsetBorderLeft', 'InsetBorderRight' }) do
            if (navBar[key]) then skins:StripTexture(navBar[key]) end
        end

        skins:AddBackdrop(navBar, { color = th.background, alpha = 0.85 })
    end

    for _, button in ipairs(navBar.navList or {}) do
        button.xoffset = NAV_CRUMB_SPACING
        SkinNavButton(button)
    end
    if (navBar.overflow) then
        navBar.overflow.xoffset = NAV_CRUMB_SPACING
        skins:SkinIconButton(navBar.overflow, { strip = { 'HighlightTexture' } })
    end
end

local function SkinInset(frame)
    local inset = frame.inset
    if (not inset or inset.exuiSkinned) then return end
    inset.exuiSkinned = true

    skins:StripNineSlice(inset)
    skins:StripRegions(inset, { 'Bg' })
end

local function ApplyExpansionDropdownAnchor()
    local dropdown = EncounterJournal and EncounterJournal.instanceSelect and
        EncounterJournal.instanceSelect.ExpansionDropdown
    if (not dropdown) then return end

    local point, relativeTo, relativePoint, xOfs, yOfs = dropdown:GetPoint(1)
    if (not point) then return end

    dropdown:ClearAllPoints()
    dropdown:SetPoint(
        point,
        relativeTo,
        relativePoint,
        (xOfs or 0) + EXPANSION_DROPDOWN_X_ADJUST,
        (yOfs or 0) + EXPANSION_DROPDOWN_Y_ADJUST
    )
end

local function SkinDropdowns(frame)
    if (frame.LootJournalViewDropdown) then
        skins:SkinModernDropdown(frame.LootJournalViewDropdown)
    end

    local expansionDropdown = frame.instanceSelect and frame.instanceSelect.ExpansionDropdown
    if (expansionDropdown) then
        skins:SkinModernDropdown(expansionDropdown)
        ApplyExpansionDropdownAnchor()
    end

    local difficulty = frame.encounter and frame.encounter.info and frame.encounter.info.difficulty
    if (difficulty) then
        skins:SkinModernDropdown(difficulty)
    end

    local lootContainer = frame.encounter and frame.encounter.info and frame.encounter.info.LootContainer
    if (lootContainer) then
        if (lootContainer.filter) then
            skins:SkinModernDropdown(lootContainer.filter)
        end
        if (lootContainer.slotFilter) then
            skins:SkinModernDropdown(lootContainer.slotFilter)
        end
    end
end

local function SkinScrollBars(frame)
    local scrollBar = frame.instanceSelect and frame.instanceSelect.ScrollBar
    if (scrollBar) then skins:SkinMinimalScrollBar(scrollBar) end

    local loreScrollBar = frame.encounter and frame.encounter.instance and frame.encounter.instance.LoreScrollBar
    if (loreScrollBar) then skins:SkinMinimalScrollBar(loreScrollBar) end
end

function encounterJournalSkin:InstallDescriptionHooks()
    if (self.descriptionHooksInstalled) then return end
    self.descriptionHooksInstalled = true

    HookEncounterDescriptionWidgets(EncounterJournal and EncounterJournal.encounter)

    hooksecurefunc('EncounterJournal_SetBullets', function(object, description)
        if (not object) then return end

        local parent = object.GetParent and object:GetParent()
        if (parent and type(description) == 'string') then
            ApplyBulletDescriptionSource(parent, description)
        elseif (object.Text and type(description) == 'string' and description ~= '') then
            SetDescriptionWidgetText(object.Text, object.textString or description)
        end

        ApplyDescriptionSimpleHTML(object.Text)
        ApplyDescriptionBullets(parent and parent.Bullets)
    end)

    hooksecurefunc('EncounterJournal_SetDescriptionWithBullets', function(infoHeader)
        HookInfoHeaderDescriptionWidgets(infoHeader)
        ApplyInfoHeaderDescriptions(infoHeader)
    end)

    hooksecurefunc('EncounterJournal_SetUpOverview', function(_, _, index)
        local encounter = EncounterJournal and EncounterJournal.encounter
        local overview = encounter and encounter.overviewFrame and encounter.overviewFrame.overviews[index]
        if (overview) then
            HookInfoHeaderDescriptionWidgets(overview)
            ApplyInfoHeaderDescriptions(overview)
        end
    end)

    hooksecurefunc('EncounterJournal_ToggleHeaders', function(header)
        HookInfoHeaderDescriptionWidgets(header)
        ApplyInfoHeaderDescriptions(header)

        local encounter = EncounterJournal and EncounterJournal.encounter
        if (not encounter) then return end

        if (header.isOverview and not header.overviewIndex) then
            RefreshOverviewDescriptionLinks(encounter)
        elseif (not header.isOverview) then
            RefreshBossHeaderDescriptionLinks(encounter)
        end
    end)

    hooksecurefunc('EncounterJournal_DisplayEncounter', function()
        local encounter = EncounterJournal and EncounterJournal.encounter
        ApplyEncounterContentDescriptions(encounter)

        if (encounter and encounter.infoFrame and encounter.infoFrame.description and encounter.infoFrame.encounterID) then
            local _, description = EJ_GetEncounterInfo(encounter.infoFrame.encounterID)
            if (description) then
                HookDescriptionSetText(encounter.infoFrame.description)
                encounter.infoFrame.description:SetText(description)
            end
        end

        RefreshOverviewDescriptionLinks(encounter)
        RefreshBossHeaderDescriptionLinks(encounter)
    end)

    hooksecurefunc('EncounterJournal_DisplayInstance', function()
        local encounter = EncounterJournal and EncounterJournal.encounter
        if (not encounter) then return end
        ApplyEncounterInfoBackgrounds(encounter.info)
        ApplyEncounterContentDescriptions(encounter)
        SkinNavBar(EncounterJournal.navBar)
    end)
end

function encounterJournalSkin:InstallTabHooks()
    if (self.tabHooksInstalled) then return end
    self.tabHooksInstalled = true

    hooksecurefunc('PanelTemplates_UpdateTabs', function(frame)
        if (frame ~= EncounterJournal) then return end
        RefreshBottomTabs(frame)
    end)

    hooksecurefunc('PanelTemplates_AnchorTabs', function(frame)
        if (frame ~= EncounterJournal) then return end
        ApplyBottomTabAnchors(frame)
    end)

    hooksecurefunc('PanelTemplates_TabResize', function(tab)
        if (not tab.exuiTabSkinned) then return end
        UpdateBottomTabWidth(tab)
        ApplyBottomTabTextLayout(tab, IsPanelTabSelected(tab))
    end)

    hooksecurefunc('EncounterJournal_SetTab', function()
        local info = EncounterJournal and EncounterJournal.encounter and EncounterJournal.encounter.info
        RefreshEncounterSideTabs(info)
    end)

    hooksecurefunc('EncounterJournal_SetTabEnabled', function(tab)
        ApplyEncounterSideTabState(tab)
    end)

    hooksecurefunc('EncounterJournal_OnShow', function()
        local frame = EncounterJournal
        if (not frame) then return end
        RefreshBottomTabs(frame)
        RefreshEncounterSideTabs(frame.encounter and frame.encounter.info)
    end)

    if (type(EncounterJournal_AnchorExpansionDropdown) == 'function') then
        hooksecurefunc('EncounterJournal_AnchorExpansionDropdown', function()
            ApplyExpansionDropdownAnchor()
        end)
    end

end

function encounterJournalSkin:SkinFrame()
    local frame = EncounterJournal
    if (not frame) then return end

    skins:SkinPanelFrame(frame, {
        hidePortrait = true,
        titleSize = TITLE_SIZE,
        backdropAlpha = PANEL_BG_ALPHA,
    })

    SkinHeaderBackdrop(frame)
    AdjustTitleBarLayout(frame)
    SkinInset(frame)
    SkinNavBar(frame.navBar)
    SkinBottomTabs(frame)

    if (frame.searchBox) then
        skins:SkinSearchBox(frame.searchBox)
        local point, relativeTo, relativePoint, xOfs, yOfs = frame.searchBox:GetPoint(1)
        frame.searchBox:ClearAllPoints()
        frame.searchBox:SetPoint(point, relativeTo, relativePoint, xOfs, -35)
    end

    SkinDropdowns(frame)
    SkinScrollBars(frame)

    local info = frame.encounter and frame.encounter.info
    if (info) then
        SkinEncounterInfoFrame(info)
        SkinEncounterSideTabs(info)
        RefreshEncounterSideTabs(info)
    end
end

function encounterJournalSkin:Install()
    if (self.installed or not EncounterJournal) then return end
    self.installed = true

    self:InstallDescriptionHooks()
    self:InstallTabHooks()
    self:SkinFrame()
end

encounterJournalSkin.Init = function(self)
    if (not skins:IsEnabled('EncounterJournal')) then return end

    if (EncounterJournal) then
        self:Install()
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-EncounterJournal', function(_, addon)
        if (addon ~= 'Blizzard_EncounterJournal') then return end
        self:Install()
    end)
end
