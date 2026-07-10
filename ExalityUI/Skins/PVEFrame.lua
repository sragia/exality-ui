---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIPVEFrameSkin
local pveFrameSkin = EXUI:GetModule('skin-PVEFrame')

local TITLE_SIZE = 13
local PANEL_BG_ALPHA = 0.95
local HEADER_HEIGHT = 26
local ROW_HIGHLIGHT_ALPHA = 0.5

local NAV_TEXT_SIZE = 13
local NAV_SLICE = 6

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
local TAB_TEXT_TOP_Y = -10

local PANEL_TAB_TEXTURE_KEYS = {
    'Left', 'Middle', 'Right',
    'LeftActive', 'MiddleActive', 'RightActive',
    'LeftHighlight', 'MiddleHighlight', 'RightHighlight',
}

local BOTTOM_TAB_KEYS = { 'tab1', 'tab2', 'tab3' }

local BLIZZARD_SIDEBAR_TEXTURES = {
    'BlueBg', 'TLCorner', 'TRCorner', 'BLCorner', 'BRCorner',
    'LLVert', 'RLVert', 'TopLine', 'BottomLine', 'TopFiligree', 'BottomFiligree',
}

local GROUP_FINDER_PANELS = {
    'LFDParentFrame',
    'ScenarioFinderFrame',
    'RaidFinderFrame',
}

local function GetTheme()
    return EXUI.const.theme
end

local function StripButtonTextures(button)
    skins:StripTexture(button:GetNormalTexture())
    skins:StripTexture(button:GetPushedTexture())
    if (button.GetDisabledTexture) then skins:StripTexture(button:GetDisabledTexture()) end
    if (button.GetHighlightTexture) then skins:StripTexture(button:GetHighlightTexture()) end
end

-- ---------------------------------------------------------------------------
-- Bottom tabs (adapted from EncounterJournal)
-- ---------------------------------------------------------------------------

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
    text:SetPoint('TOP', tab, 'TOP', 0, TAB_TEXT_TOP_Y)
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

function pveFrameSkin:RefreshBottomTabs()
    local frame = PVEFrame
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
end

local function SkinBottomTabs(frame)
    for _, key in ipairs(BOTTOM_TAB_KEYS) do
        SkinBottomTab(frame[key])
    end
    pveFrameSkin:RefreshBottomTabs()
end

-- ---------------------------------------------------------------------------
-- Shell
-- ---------------------------------------------------------------------------

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
end

local function StripBlizzardSidebarTextures(frame)
    for _, key in ipairs(BLIZZARD_SIDEBAR_TEXTURES) do
        local region = frame[key]
        if (region and region.SetTexture) then
            skins:StripTexture(region)
        end
    end

    if (frame.shadows) then
        skins:StripAllTextures(frame.shadows)
    end

    if (frame.Inset) then
        skins:StripNineSlice(frame.Inset)
        skins:StripRegions(frame.Inset, { 'Bg' })
    end

    if (frame.TopTileStreaks) then
        skins:StripTexture(frame.TopTileStreaks)
    end
end

local function EnsureLeftSidebarChrome(frame)
    if (frame.exuiSidebar) then return end
    local th = GetTheme()

    local sidebar = CreateFrame('Frame', nil, frame)
    sidebar:SetFrameLevel(1)
    sidebar:SetPoint('TOPLEFT', frame, 'TOPLEFT', 4, -24)
    sidebar:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 4, 4)
    sidebar:SetWidth(217)
    frame.exuiSidebar = sidebar

    skins:AddBackdrop(sidebar, { color = th.backgroundPanel, alpha = PANEL_BG_ALPHA })

    local divider = sidebar:CreateTexture(nil, 'OVERLAY')
    divider:SetTexture(EXUI.const.textures.frame.solidBg)
    divider:SetPoint('TOPRIGHT', sidebar, 'TOPRIGHT')
    divider:SetPoint('BOTTOMRIGHT', sidebar, 'BOTTOMRIGHT')
    divider:SetWidth(EXUI:ScalePixel(1, sidebar, 1))
    divider:SetVertexColor(unpack(th.border))
    sidebar.exuiDivider = divider
end

function pveFrameSkin:SetLeftSidebarShown(shown)
    local frame = PVEFrame
    if (not frame or not frame.exuiSidebar) then return end

    if (shown) then
        frame.exuiSidebar:Show()
    else
        frame.exuiSidebar:Hide()
    end
end

local function SkinLeftSidebar(frame)
    StripBlizzardSidebarTextures(frame)
    EnsureLeftSidebarChrome(frame)
    pveFrameSkin:SetLeftSidebarShown(true)
end

-- ---------------------------------------------------------------------------
-- Side nav buttons (Group Finder + PvP category buttons)
-- ---------------------------------------------------------------------------

local function EnsureNavButtonBg(button)
    if (button.exuiNavBg) then return end

    local bg = button:CreateTexture(nil, 'BACKGROUND', nil, 0)
    bg:SetTexture(EXUI.const.textures.frame.whiteTextured)
    bg:SetTextureSliceMargins(NAV_SLICE, NAV_SLICE, NAV_SLICE, NAV_SLICE)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAllPoints()
    button.exuiNavBg = bg
end

local function GetNavButtonName(button, nameKey)
    return button[nameKey] or button.name or button.Name
end

local function IsGroupFinderNavSelected(button)
    local gf = GroupFinderFrame
    if (not gf) then return false end
    return gf.selectionIndex == button:GetID()
end

local function IsPvPNavSelected(button)
    local queue = PVPQueueFrame
    if (not queue or not queue.CategoryButtons) then return false end
    for i, categoryButton in ipairs(queue.CategoryButtons) do
        if (categoryButton == button) then
            local bg = button.Background or button.bg
            if (not bg or not bg.GetTexCoord) then return false end
            local left, _, _, bottom = bg:GetTexCoord()
            -- Selected texcoords use bottom near 0.66992188
            return math.abs(bottom - 0.66992188) < 0.001 and math.abs(left - 0.00390625) < 0.001
        end
    end
    return false
end

local function ApplySideNavButtonState(button, options)
    if (not button or not button.exuiNavSkinned) then return end

    options = options or {}
    local th = GetTheme()
    local nameKey = options.nameKey or 'name'
    local ringKey = options.ringKey or 'ring'
    local bgKey = options.bgKey or 'bg'
    local isSelectedFn = options.isSelectedFn

    EnsureNavButtonBg(button)

    local selected = isSelectedFn and isSelectedFn(button) or false
    local enabled = button:IsEnabled()

    if (selected) then
        button.exuiNavBg:SetVertexColor(unpack(th.backgroundLight))
    else
        button.exuiNavBg:SetVertexColor(unpack(th.backgroundDeep))
    end
    button.exuiNavBg:Show()

    local blizBg = button[bgKey] or button.Background or button.bg
    if (blizBg) then skins:StripTexture(blizBg) end

    local ring = button[ringKey] or button.Ring or button.ring
    if (ring) then
        if (not enabled) then
            ring:SetDesaturated(true)
        end
    end

    local name = GetNavButtonName(button, nameKey)
    if (name) then
        name:SetFont(EXUI.const.fonts.DEFAULT, NAV_TEXT_SIZE, '')
        if (not enabled) then
            name:SetTextColor(unpack(th.textMuted))
        elseif (selected) then
            name:SetTextColor(unpack(th.white))
        elseif (button:IsMouseOver()) then
            name:SetTextColor(unpack(th.white))
        else
            name:SetTextColor(unpack(th.gray))
        end
    end
end

local function SkinSideNavButton(button, options)
    if (not button or button.exuiNavSkinned) then return end
    button.exuiNavSkinned = true

    options = options or {}
    local bgKey = options.bgKey or 'bg'
    local ringKey = options.ringKey or 'ring'

    StripButtonTextures(button)
    if (button[bgKey]) then skins:StripTexture(button[bgKey]) end
    if (button.Background) then skins:StripTexture(button.Background) end

    EnsureNavButtonBg(button)
    ApplySideNavButtonState(button, options)

    button:HookScript('OnEnter', function(btn)
        ApplySideNavButtonState(btn, options)
    end)
    button:HookScript('OnLeave', function(btn)
        ApplySideNavButtonState(btn, options)
    end)
end

function pveFrameSkin:RefreshGroupNavButtons()
    local gf = GroupFinderFrame
    if (not gf) then return end

    for i = 1, 4 do
        local button = gf['groupButton' .. i]
        if (button and button.exuiNavSkinned and button:IsShown()) then
            ApplySideNavButtonState(button, {
                nameKey = 'name',
                bgKey = 'bg',
                ringKey = 'ring',
                isSelectedFn = IsGroupFinderNavSelected,
            })
        end
    end
end

function pveFrameSkin:RefreshPvPNavButtons()
    local queue = PVPQueueFrame
    if (not queue or not queue.CategoryButtons) then return end

    for _, button in ipairs(queue.CategoryButtons) do
        if (button.exuiNavSkinned and button:IsShown()) then
            ApplySideNavButtonState(button, {
                nameKey = 'Name',
                bgKey = 'Background',
                ringKey = 'Ring',
                isSelectedFn = IsPvPNavSelected,
            })
        end
    end
end

local function SkinGroupFinderNavButtons()
    local gf = GroupFinderFrame
    if (not gf) then return end

    for i = 1, 4 do
        SkinSideNavButton(gf['groupButton' .. i], {
            nameKey = 'name',
            bgKey = 'bg',
            ringKey = 'ring',
            isSelectedFn = IsGroupFinderNavSelected,
        })
    end
    pveFrameSkin:RefreshGroupNavButtons()
end

local function SkinPvPCategoryButtons()
    local queue = PVPQueueFrame
    if (not queue or not queue.CategoryButtons) then return end

    for _, button in ipairs(queue.CategoryButtons) do
        SkinSideNavButton(button, {
            nameKey = 'Name',
            bgKey = 'Background',
            ringKey = 'Ring',
            isSelectedFn = IsPvPNavSelected,
        })
    end
    pveFrameSkin:RefreshPvPNavButtons()
end

-- ---------------------------------------------------------------------------
-- LFG / queue content panels
-- ---------------------------------------------------------------------------

local function StripPanelRootTextures(frame)
    if (not frame or not frame.GetRegions) then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if (region:IsObjectType('Texture')) then
            skins:StripTexture(region)
        end
    end
end

local function SkinInsetFrame(inset)
    if (not inset or inset.exuiSkinned) then return end
    inset.exuiSkinned = true

    skins:StripNineSlice(inset)
    skins:StripRegions(inset, { 'Bg' })
    if (inset.CustomBG) then skins:StripTexture(inset.CustomBG) end
end

local function SkinQueueFrame(queueFrame, options)
    if (not queueFrame) then return end
    options = options or {}

    if (queueFrame.Background) then skins:StripTexture(queueFrame.Background) end
    if (queueFrame.Bg) then skins:StripTexture(queueFrame.Bg) end

    if (queueFrame.FindGroupButton) then skins:SkinPanelButton(queueFrame.FindGroupButton) end
    if (queueFrame.FindRaidButton) then skins:SkinPanelButton(queueFrame.FindRaidButton) end

    if (options.typeDropdown and queueFrame.TypeDropdown) then
        skins:SkinModernDropdown(queueFrame.TypeDropdown)
    end
    if (options.selectionDropdown and queueFrame.SelectionDropdown) then
        skins:SkinModernDropdown(queueFrame.SelectionDropdown)
    end
    if (options.dropdown and queueFrame.Dropdown) then
        skins:SkinModernDropdown(queueFrame.Dropdown)
    end

    if (queueFrame.Specific and queueFrame.Specific.ScrollBar) then
        skins:SkinMinimalScrollBar(queueFrame.Specific.ScrollBar)
    end
    if (queueFrame.Follower and queueFrame.Follower.ScrollBar) then
        skins:SkinMinimalScrollBar(queueFrame.Follower.ScrollBar)
    end

    local randomScroll = queueFrame.Random and queueFrame.Random.ScrollFrame
    if (randomScroll and randomScroll.ScrollBar) then
        skins:SkinMinimalScrollBar(randomScroll.ScrollBar)
    end
end

local function SkinLFGContentPanel(frame)
    if (not frame or frame.exuiContentSkinned) then return end
    frame.exuiContentSkinned = true

    StripPanelRootTextures(frame)

    if (frame.Inset) then SkinInsetFrame(frame.Inset) end
    if (frame.RoleInset) then SkinInsetFrame(frame.RoleInset) end
    if (frame.BottomInset) then SkinInsetFrame(frame.BottomInset) end

    if (frame.Queue) then
        SkinQueueFrame(frame.Queue, { dropdown = true })
    end
    if (frame.queue) then
        SkinQueueFrame(frame.queue, { dropdown = true })
    end

    if (LFDQueueFrame and frame == LFDParentFrame) then
        SkinQueueFrame(LFDQueueFrame, { typeDropdown = true })
    end
    if (RaidFinderQueueFrame and frame == RaidFinderFrame) then
        SkinQueueFrame(RaidFinderQueueFrame, { selectionDropdown = true })
    end
end

local function SkinThemeFontString(fontString, size)
    if (not fontString or fontString.exuiSkinned) then return end
    fontString.exuiSkinned = true
    fontString:SetFont(EXUI.const.fonts.DEFAULT, size or 13, 'OUTLINE')
    fontString:SetTextColor(unpack(GetTheme().text))
    fontString:SetShadowColor(0, 0, 0, 0)
end

local function SkinLFGListPanel(panel)
    if (not panel) then return end

    if (panel.Inset) then SkinInsetFrame(panel.Inset) end

    if (panel.Label and panel.Label.SetFont) then
        SkinThemeFontString(panel.Label, 14)
    end
    if (panel.CategoryName) then
        SkinThemeFontString(panel.CategoryName, 14)
    end

    if (panel.FindGroupButton) then skins:SkinPanelButton(panel.FindGroupButton) end
    if (panel.StartGroupButton) then skins:SkinPanelButton(panel.StartGroupButton) end
    if (panel.BackButton) then skins:SkinPanelButton(panel.BackButton) end
    if (panel.BackToGroupButton) then skins:SkinPanelButton(panel.BackToGroupButton) end
    if (panel.SignUpButton) then skins:SkinPanelButton(panel.SignUpButton) end
    if (panel.CancelButton) then skins:SkinPanelButton(panel.CancelButton) end

    if (panel.SearchBox) then skins:SkinSearchBox(panel.SearchBox) end
    if (panel.FilterButton) then skins:SkinModernDropdown(panel.FilterButton) end

    if (panel.ScrollBar) then skins:SkinMinimalScrollBar(panel.ScrollBar) end
end

local function SkinLFGListCategoryButton(button)
    if (not button or button.exuiCategorySkinned) then return end
    button.exuiCategorySkinned = true

    if (button.Cover) then skins:StripTexture(button.Cover) end
    if (button.HighlightTexture) then skins:StripTexture(button.HighlightTexture) end

    if (button.Label) then
        button.Label:SetFont(EXUI.const.fonts.DEFAULT, 12, '')
        button.Label:SetTextColor(unpack(GetTheme().text))
    end
end

function pveFrameSkin:RestyleLFGListCategoryRows()
    local lfgList = LFGListFrame
    local categorySelection = lfgList and lfgList.CategorySelection
    if (not categorySelection or not categorySelection.CategoryButtons) then return end

    local th = GetTheme()
    for _, button in ipairs(categorySelection.CategoryButtons) do
        SkinLFGListCategoryButton(button)

        if (button.SelectedTexture and not button.exuiSelectedStyled) then
            button.exuiSelectedStyled = true
            button.SelectedTexture:SetDesaturated(true)
        end
        if (button.SelectedTexture and button.SelectedTexture:IsShown()) then
            button.SelectedTexture:SetVertexColor(th.accent[1], th.accent[2], th.accent[3], ROW_HIGHLIGHT_ALPHA)
        end
    end
end

local function SkinLFGListFrame()
    local lfgList = LFGListFrame
    if (not lfgList or lfgList.exuiSkinned) then return end
    lfgList.exuiSkinned = true

    for _, key in ipairs({
        'CategorySelection', 'NothingAvailable', 'SearchPanel',
        'ApplicationViewer', 'EntryCreation',
    }) do
        SkinLFGListPanel(lfgList[key])
    end

    pveFrameSkin:RestyleLFGListCategoryRows()
end

local function SkinPvPContentFrame(frame)
    if (not frame or frame.exuiContentSkinned) then return end
    frame.exuiContentSkinned = true

    StripPanelRootTextures(frame)

    if (frame.Inset) then SkinInsetFrame(frame.Inset) end
    if (frame.Background) then skins:StripTexture(frame.Background) end
    if (frame.Bg) then skins:StripTexture(frame.Bg) end

    if (frame.TypeDropdown) then skins:SkinModernDropdown(frame.TypeDropdown) end

    if (frame.SpecificScrollBar) then
        skins:SkinMinimalScrollBar(frame.SpecificScrollBar)
    end

    if (frame.ConquestBar and frame.ConquestBar.Background) then
        skins:StripTexture(frame.ConquestBar.Background)
    end

    if (frame.BonusFrame and frame.BonusFrame.WorldBattlesTexture) then
        skins:StripTexture(frame.BonusFrame.WorldBattlesTexture)
    end

    if (frame.TrainingGroundsPanel and frame.TrainingGroundsPanel.Background) then
        skins:StripTexture(frame.TrainingGroundsPanel.Background)
    end
end

local function SkinChallengesWeeklyInfo(child)
    if (not child or child.exuiWeeklySkinned) then return end
    child.exuiWeeklySkinned = true

    for _, key in ipairs({ 'RuneBG', 'RunesLarge', 'RunesSmall', 'LargeRuneGlow', 'SmallRuneGlow' }) do
        if (child[key]) then skins:StripTexture(child[key]) end
    end

    if (child.ThisWeekLabel) then SkinThemeFontString(child.ThisWeekLabel, 16) end
    if (child.SeasonBest) then SkinThemeFontString(child.SeasonBest, 12) end
    if (child.Description) then SkinThemeFontString(child.Description, 12) end
end

function pveFrameSkin:RestyleChallengesDungeonIcons()
    local frame = ChallengesFrame
    if (not frame or not frame.DungeonIcons) then return end

    local th = GetTheme()
    for _, iconFrame in ipairs(frame.DungeonIcons) do
        if (iconFrame.Highlight and not iconFrame.exuiHighlightStyled) then
            iconFrame.exuiHighlightStyled = true
            iconFrame.Highlight:SetDesaturated(true)
            iconFrame.Highlight:SetVertexColor(th.accent[1], th.accent[2], th.accent[3], ROW_HIGHLIGHT_ALPHA)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Tab installers
-- ---------------------------------------------------------------------------

function pveFrameSkin:SkinGroupFinderTab()
    SkinGroupFinderNavButtons()

    for _, panelName in ipairs(GROUP_FINDER_PANELS) do
        SkinLFGContentPanel(_G[panelName])
    end

    SkinLFGListFrame()
end

function pveFrameSkin:SkinPvPTab()
    if (not PVPUIFrame) then return end

    SkinPvPCategoryButtons()

    if (PVPQueueFrame and PVPQueueFrame.PrestigePortrait) then
        local portrait = PVPQueueFrame.PrestigePortrait
        skins:StripRegions(portrait, { 'PortraitBackground', 'SmallWreath', 'LaurelBackground' })
    end

    for _, frameName in ipairs({
        'HonorFrame', 'ConquestFrame', 'TrainingGroundsFrame',
    }) do
        SkinPvPContentFrame(_G[frameName])
    end

    if (LFGListFrame) then
        SkinLFGListFrame()
    end
end

function pveFrameSkin:SkinChallengesTab()
    local frame = ChallengesFrame
    if (not frame or frame.exuiChallengesSkinned) then return end
    frame.exuiChallengesSkinned = true

    if (frame.Inset) then SkinInsetFrame(frame.Inset) end

    if (frame.Background) then
        skins:StripTexture(frame.Background)
    end

    for _, region in ipairs({ frame:GetRegions() }) do
        if (region:IsObjectType('Texture') and region.GetAtlas and region:GetAtlas() == 'insetshadow') then
            skins:StripTexture(region)
        end
    end

    if (frame.WeeklyInfo and frame.WeeklyInfo.Child) then
        SkinChallengesWeeklyInfo(frame.WeeklyInfo.Child)
    end

    pveFrameSkin:RestyleChallengesDungeonIcons()
end

function pveFrameSkin:SkinLazyPanels()
    if (PVPUIFrame) then
        self:InstallPvPNavHooks()
        self:SkinPvPTab()
    end
    if (ChallengesFrame) then
        self:InstallChallengesHooks()
        self:SkinChallengesTab()
    end
end

function pveFrameSkin:SkinFrame()
    local frame = PVEFrame
    if (not frame or frame.exuiSkinned) then return end
    frame.exuiSkinned = true

    skins:SkinPanelFrame(frame, {
        hidePortrait = true,
        titleSize = TITLE_SIZE,
        backdropAlpha = PANEL_BG_ALPHA,
    })

    SkinHeaderBackdrop(frame)
    AdjustTitleBarLayout(frame)
    SkinLeftSidebar(frame)
    SkinBottomTabs(frame)

    self:SkinGroupFinderTab()
    self:SkinLazyPanels()
end

-- ---------------------------------------------------------------------------
-- Hooks
-- ---------------------------------------------------------------------------

function pveFrameSkin:InstallTabHooks()
    if (self.tabHooksInstalled) then return end
    self.tabHooksInstalled = true

    hooksecurefunc('PanelTemplates_UpdateTabs', function(tabFrame)
        if (tabFrame ~= PVEFrame) then return end
        pveFrameSkin:RefreshBottomTabs()
    end)

    hooksecurefunc('PanelTemplates_AnchorTabs', function(tabFrame)
        if (tabFrame ~= PVEFrame) then return end
        ApplyBottomTabAnchors(PVEFrame)
    end)

    hooksecurefunc('PanelTemplates_TabResize', function(tab)
        if (not tab.exuiTabSkinned) then return end
        UpdateBottomTabWidth(tab)
        ApplyBottomTabTextLayout(tab, IsPanelTabSelected(tab))
    end)
end

function pveFrameSkin:InstallGroupFinderNavHooks()
    if (self.groupNavHooksInstalled) then return end
    self.groupNavHooksInstalled = true

    hooksecurefunc('GroupFinderFrame_SelectGroupButton', function()
        pveFrameSkin:RefreshGroupNavButtons()
    end)

    hooksecurefunc('GroupFinderFrameButton_SetEnabled', function()
        pveFrameSkin:RefreshGroupNavButtons()
    end)

    hooksecurefunc('GroupFinderFrame_EvaluateButtonVisibility', function()
        SkinGroupFinderNavButtons()
    end)

    hooksecurefunc('GroupFinderFrame_ShowGroupFrame', function()
        for _, panelName in ipairs(GROUP_FINDER_PANELS) do
            SkinLFGContentPanel(_G[panelName])
        end
        SkinLFGListFrame()
    end)
end

function pveFrameSkin:InstallPvPNavHooks()
    if (self.pvpNavHooksInstalled) then return end
    if (type(PVPQueueFrame_SelectButton) ~= 'function') then return end
    self.pvpNavHooksInstalled = true

    hooksecurefunc('PVPQueueFrame_SelectButton', function()
        pveFrameSkin:RefreshPvPNavButtons()
    end)

    hooksecurefunc('PVPQueueFrame_SetCategoryButtonState', function()
        pveFrameSkin:RefreshPvPNavButtons()
    end)

    hooksecurefunc('PVPQueueFrame_ShowFrame', function()
        pveFrameSkin:SkinPvPTab()
    end)
end

function pveFrameSkin:InstallChallengesHooks()
    if (self.challengesHooksInstalled) then return end
    if (not ChallengesFrameMixin) then return end
    self.challengesHooksInstalled = true

    hooksecurefunc(ChallengesFrameMixin, 'Update', function(frame)
        if (frame.Background) then
            skins:StripTexture(frame.Background)
        end
        pveFrameSkin:RestyleChallengesDungeonIcons()
    end)
end

function pveFrameSkin:InstallNavHooks()
    self:InstallGroupFinderNavHooks()
    self:InstallPvPNavHooks()
end

function pveFrameSkin:InstallContentHooks()
    if (self.contentHooksInstalled) then return end
    self.contentHooksInstalled = true

    hooksecurefunc('PVEFrame_ShowFrame', function()
        pveFrameSkin:SkinLazyPanels()
        pveFrameSkin:RefreshBottomTabs()
    end)

    hooksecurefunc('PVEFrame_HideLeftInset', function()
        pveFrameSkin:SetLeftSidebarShown(false)
    end)

    hooksecurefunc('PVEFrame_ShowLeftInset', function()
        pveFrameSkin:SetLeftSidebarShown(true)
    end)

    if (type(LFGListCategorySelection_UpdateCategoryButtons) == 'function') then
        hooksecurefunc('LFGListCategorySelection_UpdateCategoryButtons', function()
            pveFrameSkin:RestyleLFGListCategoryRows()
        end)
    end

    self:InstallChallengesHooks()
end

function pveFrameSkin:InstallHooks()
    if (self.hooksInstalled) then return end
    self.hooksInstalled = true

    self:InstallTabHooks()
    self:InstallNavHooks()
    self:InstallContentHooks()

    if (PVEFrame) then
        hooksecurefunc(PVEFrame, 'OnShow', function()
            pveFrameSkin:RefreshBottomTabs()
        end)
    end
end

function pveFrameSkin:Install()
    if (self.installed or not PVEFrame) then return end
    self.installed = true

    self:InstallHooks()
    self:SkinFrame()
end

function pveFrameSkin:OnAddonLoaded(addon)
    if (addon == 'Blizzard_GroupFinder') then
        self:Install()
    elseif (addon == 'Blizzard_PVPUI') then
        self:InstallPvPNavHooks()
        self:SkinPvPTab()
    elseif (addon == 'Blizzard_ChallengesUI') then
        self:InstallChallengesHooks()
        self:SkinChallengesTab()
    end
end

pveFrameSkin.Init = function(self)
    if (PVEFrame) then
        self:Install()
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-PVEFrame', function(_, addon)
        self:OnAddonLoaded(addon)
    end)
end
