---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIPVEFrameSkin
local pveFrameSkin = EXUI:GetModule('skin-PVEFrame')

---@class EXUIPVEFrameSearchEntrySkin
local searchEntrySkin = EXUI:GetModule('skin-PVEFrame-searchEntry')

---@class EXUIPVEFrameFiltersSkin
local filtersSkin = EXUI:GetModule('skin-PVEFrame-filters')

local TITLE_SIZE = 13
local PANEL_BG_ALPHA = 0.95
local HEADER_HEIGHT = 26
local ROW_HIGHLIGHT_ALPHA = 0.5

local SIDEBAR_LEFT = 6
local SIDEBAR_WIDTH = 213
local SIDEBAR_TOP_GAP = 5

local NAV_ART_HEIGHT = 60
local NAV_ART_WIDTH = NAV_ART_HEIGHT * 3
-- Group buttons sit at x=10; pull the art flush with the sidebar panel edge.
local NAV_ART_X = SIDEBAR_LEFT - 10
-- Sprite padding is authored against a 78px tall border.
local NAV_ART_UNIT = NAV_ART_HEIGHT / 78
local NAV_NAME_SIZE = 15
local NAV_NAME_PAD = 8
local NAV_GLOW_HOVER_ALPHA = 0.35
local NAV_DISABLED_SHADE = 0.5

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
    'TLCorner', 'TRCorner', 'BLCorner', 'BRCorner',
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

-- Panel art is authored at the left sidebar size (306px wide art for SIDEBAR_WIDTH).
local PANEL_ART_SCALE = SIDEBAR_WIDTH / 306
local PANEL_BG_MARGIN = 12
local PANEL_BORDER_MARGIN = 20
-- Border art extends 8.5px past the background art on each side.
local PANEL_BORDER_OUTSET = 8.5 * PANEL_ART_SCALE
-- Above the Group Finder nav buttons and panel content.
local PANEL_BORDER_LEVEL_OFFSET = 20

---Nine-sliced panel border around `target`, on its own frame above `owner`'s content.
local function CreatePanelBorder(owner, target)
    local borderFrame = CreateFrame('Frame', nil, owner)
    borderFrame:SetAllPoints(target)
    borderFrame:SetFrameLevel(owner:GetFrameLevel() + PANEL_BORDER_LEVEL_OFFSET)
    local border = searchEntrySkin.CreateSpriteNineSlice(borderFrame, 'panelBorder', PANEL_BORDER_MARGIN,
        PANEL_ART_SCALE, 'OVERLAY')
    border:SetPoints(target, PANEL_BORDER_OUTSET)
    return borderFrame
end

---Nine-sliced panel background + border over `target`. A texture target is alpha-hidden and followed for visibility.
local function ApplyPanelArt(target, layer, subLevel)
    if (target.exuiPanelArt) then return end

    local isTexture = target:IsObjectType('Texture')
    local owner = isTexture and target:GetParent() or target

    local bg = searchEntrySkin.CreateSpriteNineSlice(owner, 'panelBg', PANEL_BG_MARGIN, PANEL_ART_SCALE, layer, subLevel)
    bg:SetPoints(target, 0)

    local borderFrame = CreatePanelBorder(owner, target)

    target.exuiPanelArt = { bg = bg, border = borderFrame }
    if (not isTexture) then return end

    target:SetAlpha(0)
    local function Sync(shown)
        bg:SetShown(shown)
        borderFrame:SetShown(shown)
    end
    Sync(target:IsShown())
    hooksecurefunc(target, 'Show', function() Sync(true) end)
    hooksecurefunc(target, 'Hide', function() Sync(false) end)
    hooksecurefunc(target, 'SetShown', function(_, shown) Sync(shown) end)
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

local function GetPVEFrameBlueBg(frame)
    if (not frame) then return nil end
    return frame.BlueBg or _G[(frame:GetName() or '') .. 'BlueBg']
end

local function StylePVEFrameBlueBg(frame)
    local blueBg = GetPVEFrameBlueBg(frame)
    if (not blueBg) then return end

    blueBg:ClearAllPoints()
    blueBg:SetPoint('TOPLEFT', frame, 'TOPLEFT', SIDEBAR_LEFT, -(HEADER_HEIGHT + 1 + SIDEBAR_TOP_GAP))
    blueBg:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', SIDEBAR_LEFT, SIDEBAR_LEFT)
    blueBg:SetWidth(SIDEBAR_WIDTH)
    blueBg:Show()
    ApplyPanelArt(blueBg, 'BORDER', -1)
end

local function StripBlizzardSidebarTextures(frame)
    for _, key in ipairs(BLIZZARD_SIDEBAR_TEXTURES) do
        local region = frame[key] or _G[(frame:GetName() or '') .. key]
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

local function SkinLeftSidebar(frame)
    StripBlizzardSidebarTextures(frame)
    StylePVEFrameBlueBg(frame)
end

-- ---------------------------------------------------------------------------
-- Side nav buttons (Group Finder + PvP category buttons)
-- ---------------------------------------------------------------------------

local function IsGroupFinderNavSelected(button)
    local gf = GroupFinderFrame
    if (not gf) then return false end
    return gf.selectionIndex == button:GetID()
end

local function IsPvPNavSelected(button)
    local bg = button.Background
    if (not bg or not bg.GetTexCoord) then return false end
    local left, _, _, bottom = bg:GetTexCoord()
    -- PVPQueueFrame_SelectButton marks the selected button with bottom texcoord 0.66992188.
    return math.abs(bottom - 0.66992188) < 0.001 and math.abs(left - 0.00390625) < 0.001
end

---Button ids shift when the Scenario button (timerunning) is shown; it reuses the dungeon art.
local function GetGroupNavArtKey(button)
    local id = button:GetID()
    if (PVEFrame.ScenariosEnabled and PVEFrame:ScenariosEnabled()) then
        id = id > 1 and id - 1 or id
    end
    if (id == 2) then return 'navRaid' end
    if (id == 3) then return 'navPremade' end
    return 'navDungeon'
end

-- Quick Match, Rated, Premade Groups, Training Grounds; Plunderstorm reuses Quick Match.
local PVP_NAV_ART_KEYS = { 'navQuickMatch', 'navRated', 'navPremade', 'navTraining' }

local function GetPvPNavArtKey(button)
    return PVP_NAV_ART_KEYS[button:GetID()] or 'navQuickMatch'
end

local GROUP_NAV_OPTIONS = {
    keys = { name = 'name', icon = 'icon', ring = 'ring', bg = 'bg' },
    getArtKey = GetGroupNavArtKey,
    isSelected = IsGroupFinderNavSelected,
}

local PVP_NAV_OPTIONS = {
    keys = { name = 'Name', icon = 'Icon', ring = 'Ring', bg = 'Background' },
    getArtKey = GetPvPNavArtKey,
    isSelected = IsPvPNavSelected,
}

local function ApplyNavButtonState(button)
    local options = button and button.exuiNavOptions
    if (not options) then return end

    local th = GetTheme()
    local enabled = button:IsEnabled()
    local selected = enabled and options.isSelected(button)
    local hovered = enabled and button:IsMouseOver()
    local key = options.getArtKey(button)
    local shade = enabled and 1 or NAV_DISABLED_SHADE

    for suffix, texture in pairs({ Border = button.exuiNavArtBorder, Bg = button.exuiNavArtBg }) do
        searchEntrySkin.ApplySprite(texture, key .. suffix)
        texture:SetDesaturated(not enabled)
        texture:SetVertexColor(shade, shade, shade)
    end

    local glow = button.exuiNavArtGlow
    searchEntrySkin.ApplySprite(glow, key .. 'Glow')
    glow:SetAlpha(selected and 1 or NAV_GLOW_HOVER_ALPHA)
    glow:SetShown(selected or hovered)

    local name = button[options.keys.name]
    if (name) then
        name:SetFont(EXUI.const.fonts.DEFAULT, NAV_NAME_SIZE, 'OUTLINE')
        name:SetShadowColor(0, 0, 0, 0)
        name:SetTextColor(unpack(enabled and th.white or th.textMuted))
    end
end

local function SkinNavButton(button, options)
    if (not button or button.exuiNavOptions) then return end
    button.exuiNavOptions = options

    local keys = options.keys
    StripButtonTextures(button)
    if (button[keys.bg]) then skins:StripTexture(button[keys.bg]) end
    if (button[keys.icon]) then button[keys.icon]:SetAlpha(0) end
    if (button[keys.ring]) then button[keys.ring]:SetAlpha(0) end

    local unit = NAV_ART_UNIT
    local border = button:CreateTexture(nil, 'BORDER')
    border:SetPoint('TOPLEFT', button, 'TOPLEFT', NAV_ART_X, 0)
    border:SetSize(NAV_ART_WIDTH, NAV_ART_HEIGHT)
    button.exuiNavArtBorder = border

    local bg = button:CreateTexture(nil, 'BACKGROUND', nil, 0)
    bg:SetPoint('TOPLEFT', border, 'TOPLEFT', -7 * unit, 7 * unit)
    bg:SetPoint('BOTTOMRIGHT', border, 'BOTTOMRIGHT', 7 * unit, -7 * unit)
    button.exuiNavArtBg = bg

    local glow = button:CreateTexture(nil, 'BACKGROUND', nil, -8)
    glow:SetPoint('TOPLEFT', border, 'TOPLEFT', 0, 35 * unit)
    glow:SetPoint('BOTTOMRIGHT', border, 'BOTTOMRIGHT', 38 * unit, -37 * unit)
    button.exuiNavArtGlow = glow

    local name = button[keys.name]
    if (name) then
        name:ClearAllPoints()
        name:SetPoint('RIGHT', border, 'RIGHT', -NAV_NAME_PAD, 0)
        name:SetWidth(NAV_ART_WIDTH - NAV_NAME_PAD * 2)
        name:SetJustifyH('RIGHT')
    end

    button:SetHitRectInsets(0, math.max(0, button:GetWidth() - NAV_ART_X - NAV_ART_WIDTH), 0, 0)

    button:HookScript('OnEnter', ApplyNavButtonState)
    button:HookScript('OnLeave', ApplyNavButtonState)
end

function pveFrameSkin:RefreshGroupNavButtons()
    local gf = GroupFinderFrame
    if (not gf) then return end

    for i = 1, 4 do
        local button = gf['groupButton' .. i]
        if (button and button:IsShown()) then
            ApplyNavButtonState(button)
        end
    end
end

function pveFrameSkin:RefreshPvPNavButtons()
    local queue = PVPQueueFrame
    if (not queue or not queue.CategoryButtons) then return end

    for _, button in ipairs(queue.CategoryButtons) do
        if (button:IsShown()) then
            ApplyNavButtonState(button)
        end
    end
end

local function SkinGroupFinderNavButtons()
    local gf = GroupFinderFrame
    if (not gf) then return end

    for i = 1, 4 do
        SkinNavButton(gf['groupButton' .. i], GROUP_NAV_OPTIONS)
    end
    pveFrameSkin:RefreshGroupNavButtons()
end

local function SkinPvPCategoryButtons()
    local queue = PVPQueueFrame
    if (not queue or not queue.CategoryButtons) then return end

    for _, button in ipairs(queue.CategoryButtons) do
        SkinNavButton(button, PVP_NAV_OPTIONS)
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

---Strip Blizzard inset chrome. With options.chrome, replace with flat PP backdrop + 1px border.
---@param options? { chrome?: boolean, backdropAlpha?: number }
local function SkinInsetFrame(inset, options)
    if (not inset or inset.exuiSkinned) then return end
    options = options or {}

    skins:StripNineSlice(inset)
    skins:StripRegions(inset, { 'Bg' })
    if (inset.CustomBG) then skins:StripTexture(inset.CustomBG) end

    if (options.chrome) then
        skins:ApplyFlatChrome(inset, {
            color = GetTheme().backgroundDeep,
            alpha = options.backdropAlpha or 0.55,
        })
    else
        inset.exuiSkinned = true
    end
end

-- ResultsInset sits at y=26 while magic buttons are 22px tall at y=4, so they kiss the border.
local SEARCH_RESULTS_INSET_BOTTOM = 34
-- Matches the Dungeon Finder panel's distance from the sidebar.
local SEARCH_RESULTS_INSET_LEFT = 4
local SEARCH_RESULTS_INSET_RIGHT = -6
local SEARCH_RESULTS_PAD = 6
local SEARCH_RESULTS_SCROLLBAR_SPACE = 14
local SEARCH_SCROLLBAR_GAP = 4
local SEARCH_BOTTOM_BUTTON_Y = 6

local TOOLBAR_RIGHT = -8
local TOOLBAR_TOP = -55
local TOOLBAR_GAP = 4
local SEARCH_BOX_GAP = 8
local CATEGORY_NAME_TOP = -33
local SEARCH_BOX_LEFT = 8
local SEARCH_BOX_TOP = -58
local REFRESH_SIZE = 24
local REFRESH_ICON_SIZE = 18

-- Centered between the header (27px) and the first category button (TOP y=-77).
local CATEGORY_LABEL_X = -3
local CATEGORY_LABEL_Y = -(HEADER_HEIGHT + 1 + 77) / 2

-- CategorySelection Start/Find Group default to x=-3 (flush with the window edge).
local CATEGORY_BOTTOM_BUTTON_X = 6
local CATEGORY_BOTTOM_BUTTON_Y = 6

local function LayoutCategorySelectionButtons(panel)
    if (not panel or panel.exuiCategoryLayoutAdjusted) then return end
    if (not panel.StartGroupButton or not panel.FindGroupButton) then return end
    panel.exuiCategoryLayoutAdjusted = true

    panel.StartGroupButton:ClearAllPoints()
    panel.StartGroupButton:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', CATEGORY_BOTTOM_BUTTON_X, CATEGORY_BOTTOM_BUTTON_Y)

    panel.FindGroupButton:ClearAllPoints()
    panel.FindGroupButton:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -CATEGORY_BOTTOM_BUTTON_X,
        CATEGORY_BOTTOM_BUTTON_Y)
end

local function LayoutSearchPanelButtons(panel)
    if (not panel or panel.exuiSearchLayoutAdjusted) then return end
    panel.exuiSearchLayoutAdjusted = true

    local inset = panel.ResultsInset
    if (inset) then
        inset:ClearAllPoints()
        inset:SetPoint('TOPLEFT', panel, 'TOPLEFT', SEARCH_RESULTS_INSET_LEFT, -86)
        inset:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', SEARCH_RESULTS_INSET_RIGHT, SEARCH_RESULTS_INSET_BOTTOM)

        if (panel.ScrollBox) then
            panel.ScrollBox:ClearAllPoints()
            panel.ScrollBox:SetPoint('TOPLEFT', inset, 'TOPLEFT', SEARCH_RESULTS_PAD, -SEARCH_RESULTS_PAD)
            panel.ScrollBox:SetPoint('BOTTOMRIGHT', inset, 'BOTTOMRIGHT', -SEARCH_RESULTS_SCROLLBAR_SPACE,
                SEARCH_RESULTS_PAD)
        end
        if (panel.ScrollBar and panel.ScrollBox) then
            panel.ScrollBar:ClearAllPoints()
            panel.ScrollBar:SetPoint('TOPLEFT', panel.ScrollBox, 'TOPRIGHT', SEARCH_SCROLLBAR_GAP, 0)
            panel.ScrollBar:SetPoint('BOTTOMLEFT', panel.ScrollBox, 'BOTTOMRIGHT', SEARCH_SCROLLBAR_GAP, 0)
        end
    end

    for _, key in ipairs({ 'BackButton', 'BackToGroupButton' }) do
        local button = panel[key]
        if (button) then
            button:ClearAllPoints()
            button:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', SEARCH_RESULTS_INSET_LEFT, SEARCH_BOTTOM_BUTTON_Y)
        end
    end

    if (panel.SignUpButton) then
        panel.SignUpButton:ClearAllPoints()
        panel.SignUpButton:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', SEARCH_RESULTS_INSET_RIGHT, SEARCH_BOTTOM_BUTTON_Y)
    end
end

local function SkinResultsInset(inset)
    if (inset.exuiPanelArt) then return end
    SkinInsetFrame(inset)
    ApplyPanelArt(inset, 'BACKGROUND')
end

---Blizzard's filter dropdown is replaced by our filter side panel button.
local function SkinSearchToolbar(panel)
    if (panel.exuiToolbarSkinned) then return end
    panel.exuiToolbarSkinned = true

    panel.FilterButton:SetAlpha(0)
    panel.FilterButton:EnableMouse(false)

    local filterButton = filtersSkin:CreateButton(panel)
    filterButton:ClearAllPoints()
    filterButton:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', TOOLBAR_RIGHT, TOOLBAR_TOP)

    local refresh = panel.RefreshButton
    if (refresh) then
        StripButtonTextures(refresh)
        refresh:SetSize(REFRESH_SIZE, REFRESH_SIZE)
        refresh:ClearAllPoints()
        refresh:SetPoint('RIGHT', filterButton, 'LEFT', -TOOLBAR_GAP, 0)
        if (refresh.Icon) then
            searchEntrySkin.ApplySprite(refresh.Icon, 'refresh')
            searchEntrySkin.SetSpriteHeight(refresh.Icon, 'refresh', REFRESH_ICON_SIZE)
        end
    end

    if (panel.CategoryName) then
        panel.CategoryName:ClearAllPoints()
        panel.CategoryName:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', TOOLBAR_RIGHT, CATEGORY_NAME_TOP)
        panel.CategoryName:SetJustifyH('RIGHT')
    end

    local searchBox = panel.SearchBox
    searchBox:ClearAllPoints()
    searchBox:SetPoint('TOPLEFT', panel, 'TOPLEFT', SEARCH_BOX_LEFT, SEARCH_BOX_TOP)
    searchBox:SetPoint('RIGHT', refresh or filterButton, 'LEFT', -SEARCH_BOX_GAP, 0)
end

local function ResolveNamedChild(parent, suffix)
    if (not parent) then return nil end
    return parent[suffix] or _G[(parent:GetName() or '') .. suffix]
end

local function ResolveQueueBackground(queueFrame)
    if (not queueFrame) then return nil end
    return queueFrame.Background
        or queueFrame.Bg
        or ResolveNamedChild(queueFrame, 'Background')
end

-- Content fill starts just under the type dropdown; leave room above Find Group / Find Raid.
local QUEUE_BG_LEFT = 4
local QUEUE_BG_RIGHT = -6
local QUEUE_BG_BOTTOM = 36
local QUEUE_BG_DROPDOWN_GAP = -7
local QUEUE_BG_FALLBACK_TOP = -144

local function ResolveQueueTypeDropdown(queueFrame)
    return queueFrame.TypeDropdown
        or queueFrame.SelectionDropdown
        or ResolveNamedChild(queueFrame, 'TypeDropdown')
        or ResolveNamedChild(queueFrame, 'SelectionDropdown')
end

local QUEUE_SCROLL_PAD_TOP = -8
local QUEUE_SCROLL_PAD_LEFT = 4
local QUEUE_SCROLL_PAD_RIGHT = -26
local QUEUE_SCROLL_PAD_BOTTOM = 4

local function LayoutQueueBackground(queueFrame, texture)
    if (not texture or not queueFrame) then return end

    local left = EXUI:ScalePixel(QUEUE_BG_LEFT, queueFrame, 1)
    local right = -EXUI:ScalePixel(-QUEUE_BG_RIGHT, queueFrame, 1)
    local bottom = EXUI:ScalePixel(QUEUE_BG_BOTTOM, queueFrame, 1)
    local dropdownGap = -EXUI:ScalePixel(-QUEUE_BG_DROPDOWN_GAP, queueFrame, 1)
    local fallbackTop = -EXUI:ScalePixel(-QUEUE_BG_FALLBACK_TOP, queueFrame, 1)

    texture:ClearAllPoints()
    local dropdown = ResolveQueueTypeDropdown(queueFrame)
    if (dropdown) then
        -- Top edge sits under the dropdown; left/right/bottom stay on the content panel.
        texture:SetPoint('TOP', dropdown, 'BOTTOM', 0, dropdownGap)
        texture:SetPoint('LEFT', queueFrame, 'LEFT', left, 0)
        texture:SetPoint('BOTTOMRIGHT', queueFrame, 'BOTTOMRIGHT', right, bottom)
    else
        texture:SetPoint('TOPLEFT', queueFrame, 'TOPLEFT', left, fallbackTop)
        texture:SetPoint('BOTTOMRIGHT', queueFrame, 'BOTTOMRIGHT', right, bottom)
    end
end

---Keep Specific Dungeons list inset inside the bordered background (esp. top padding).
---Follower keeps Blizzard's lower top anchor so title/description stay clear.
local function LayoutQueueScrollBoxes(queueFrame, background)
    if (not queueFrame or not background) then return end

    local scrollBox = queueFrame.Specific and queueFrame.Specific.ScrollBox
    if (not scrollBox) then return end

    scrollBox:ClearAllPoints()
    scrollBox:SetPoint('TOPLEFT', background, 'TOPLEFT', QUEUE_SCROLL_PAD_LEFT, QUEUE_SCROLL_PAD_TOP)
    scrollBox:SetPoint('BOTTOMRIGHT', background, 'BOTTOMRIGHT', QUEUE_SCROLL_PAD_RIGHT, QUEUE_SCROLL_PAD_BOTTOM)
end

local dungeonListCheckHookInstalled = false

local function HookDungeonListCheckButtons()
    if (dungeonListCheckHookInstalled) then return end
    if (not LFGDungeonListButton_SetDungeon) then return end
    dungeonListCheckHookInstalled = true

    hooksecurefunc('LFGDungeonListButton_SetDungeon', function(button)
        if (button and button.enableButton) then
            skins:SkinCheckButton(button.enableButton)
        end
    end)
end

local function SkinQueueFrame(queueFrame, options)
    if (not queueFrame) then return end
    options = options or {}

    local background = ResolveQueueBackground(queueFrame)
    if (background) then
        ApplyPanelArt(background, 'BORDER')
        LayoutQueueBackground(queueFrame, background)
        LayoutQueueScrollBoxes(queueFrame, background)
    end
    if (queueFrame.Bg and queueFrame.Bg ~= background) then
        ApplyPanelArt(queueFrame.Bg, 'BORDER')
    end

    local findGroup = ResolveNamedChild(queueFrame, 'FindGroupButton')
    local findRaid = ResolveNamedChild(queueFrame, 'FindRaidButton')
    if (findGroup) then skins:SkinPanelButton(findGroup) end
    if (findRaid) then skins:SkinPanelButton(findRaid) end

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

    HookDungeonListCheckButtons()
end

local function SkinLFGContentPanel(frame)
    if (not frame or frame.exuiContentSkinned) then return end
    frame.exuiContentSkinned = true

    StripPanelRootTextures(frame)

    if (frame.Inset) then SkinInsetFrame(frame.Inset) end
    if (frame.RoleInset) then SkinInsetFrame(frame.RoleInset) end
    -- RaidFinder BottomInset is named-only (no parentKey).
    local bottomInset = frame.BottomInset or ResolveNamedChild(frame, 'BottomInset')
    if (bottomInset) then SkinInsetFrame(bottomInset) end

    -- Fixed-size role header art also overhangs (512px wide).
    local roleBackground = ResolveNamedChild(frame, 'RoleBackground')
    if (roleBackground) then
        skins:StripTexture(roleBackground)
    end

    if (frame.Queue) then
        SkinQueueFrame(frame.Queue, { dropdown = true })
    end
    if (frame.queue) then
        SkinQueueFrame(frame.queue, { dropdown = true })
    end

    if (LFDQueueFrame and frame == LFDParentFrame) then
        SkinQueueFrame(LFDQueueFrame, { typeDropdown = true })
        -- Find Group lives on LFDQueueFrame as a named global, not parentKey.
        local findGroup = ResolveNamedChild(LFDQueueFrame, 'FindGroupButton')
        if (findGroup) then skins:SkinPanelButton(findGroup) end
    end
    if (RaidFinderQueueFrame and frame == RaidFinderFrame) then
        SkinQueueFrame(RaidFinderQueueFrame, { selectionDropdown = true })
        local findRaid = ResolveNamedChild(frame, 'FindRaidButton')
        if (findRaid) then skins:SkinPanelButton(findRaid) end
    end
end

local function SkinThemeFontString(fontString, size)
    if (not fontString or fontString.exuiSkinned) then return end
    fontString.exuiSkinned = true
    fontString:SetFont(EXUI.const.fonts.DEFAULT, size or 13, 'OUTLINE')
    fontString:SetTextColor(unpack(GetTheme().text))
    fontString:SetShadowColor(0, 0, 0, 0)
end

local function SkinSearchPanelStartGroupButtons(panel)
    if (not panel or not panel.ScrollBox) then return end

    if (panel.ScrollBox.StartGroupButton) then
        skins:SkinPanelButton(panel.ScrollBox.StartGroupButton)
    end

    -- LFGStartGroupButtonListTemplate rows: unnamed UIPanelButton child.
    if (panel.ScrollBox.EnumerateFrames) then
        for _, frame in panel.ScrollBox:EnumerateFrames() do
            for _, child in ipairs({ frame:GetChildren() }) do
                if (child:IsObjectType('Button') and child.Left) then
                    skins:SkinPanelButton(child)
                end
            end
        end
    end
end

---CheckButton:IsMouseOver() ignores HitRectInsets; label clicks sit in that extended rect.
local function IsMouseOverCheckButton(checkButton)
    if (not checkButton) then return false end
    if (checkButton:IsMouseOver()) then return true end
    local left, right, top, bottom = checkButton:GetHitRectInsets()
    -- Positive IsMouseOver offsets enlarge; HitRectInsets use the opposite sign.
    return checkButton:IsMouseOver(-top, -bottom, -left, -right)
end

local function SkinLFGRequirementRow(row)
    if (not row or row.exuiRequirementSkinned) then return end
    row.exuiRequirementSkinned = true

    if (row.CheckButton) then
        skins:SkinModernCheckButton(row.CheckButton)
    end
    if (row.Label) then
        SkinThemeFontString(row.Label, 11)
    end
    if (row.EditBox) then
        skins:SkinEditBox(row.EditBox, { fontSize = 11 })

        -- Blizzard OnEditFocusLost unchecks when empty and not IsMouseOver(square).
        -- Label clicks clear focus first (outside the 22px square), which unchecks
        -- early; the pending CheckButton click then toggles it back on.
        row.EditBox:SetScript('OnEditFocusLost', function(self)
            local checkButton = self:GetParent().CheckButton
            if (self:GetText() == '' and not IsMouseOverCheckButton(checkButton)) then
                checkButton:SetChecked(false)
            end
        end)
    end
end

local function SkinLFGOptionCheck(row)
    if (not row or row.exuiOptionSkinned) then return end
    row.exuiOptionSkinned = true

    if (row.CheckButton) then
        skins:SkinModernCheckButton(row.CheckButton)
    end
    if (row.Label) then
        SkinThemeFontString(row.Label, 11)
    end
end

local function SkinEntryCreationActivityFinder(finder)
    if (not finder or finder.exuiSkinned) then return end
    finder.exuiSkinned = true

    if (finder.Background) then
        skins:StripTexture(finder.Background)
        skins:AddBackdrop(finder, { color = GetTheme().backgroundDeep, alpha = 0.85 })
    end

    local dialog = finder.Dialog
    if (not dialog) then return end

    if (dialog.Bg) then skins:StripTexture(dialog.Bg) end
    if (dialog.Border) then skins:StripNineSlice(dialog.Border) end
    skins:AddBackdrop(dialog, { color = GetTheme().backgroundDeep, alpha = 0.95 })
    skins:AddBorder(dialog)

    if (dialog.EntryBox) then skins:SkinEditBox(dialog.EntryBox) end
    if (dialog.SelectButton) then skins:SkinPanelButton(dialog.SelectButton) end
    if (dialog.CancelButton) then skins:SkinPanelButton(dialog.CancelButton) end
    if (dialog.ScrollBar) then skins:SkinMinimalScrollBar(dialog.ScrollBar) end
    if (dialog.BorderFrame) then
        skins:StripNineSlice(dialog.BorderFrame)
        skins:StripRegions(dialog.BorderFrame, { 'TopLeftCorner', 'TopRightCorner', 'BottomLeftCorner', 'BottomRightCorner', 'TopEdge', 'BottomEdge', 'LeftEdge', 'RightEdge', 'Center' })
        skins:AddBorder(dialog.BorderFrame)
    end
end

-- Inset matches the search results panel; every input shares one inner padding.
-- LFGListFrame's XML width, used if the panel has not been laid out yet.
local ENTRY_PANEL_WIDTH = 338
local ENTRY_INSET_TOP = -61
local ENTRY_INSET_BOTTOM = 36
local ENTRY_CONTENT_PAD = 16
local ENTRY_DROPDOWN_TOP = -15
local ENTRY_DROPDOWN_GAP = 12
-- Blizzard anchors requirement rows 1px left of the playstyle dropdown.
local ENTRY_ROW_NUDGE = 1
-- InputScrollFrame_OnLoad sizes the inner EditBox to the frame width minus 18.
local ENTRY_DESCRIPTION_EDIT_INSET = 18
local ENTRY_ROW_KEYS = { 'ItemLevel', 'PvpItemLevel', 'PVPRating', 'MythicPlusRating', 'VoiceChat', 'CrossFactionGroup' }

local function LayoutEntryCreation(panel)
    if (not panel or panel.exuiEntryLayoutAdjusted) then return end
    panel.exuiEntryLayoutAdjusted = true

    local inset = panel.Inset
    inset:ClearAllPoints()
    inset:SetPoint('TOPLEFT', panel, 'TOPLEFT', SEARCH_RESULTS_INSET_LEFT, ENTRY_INSET_TOP)
    inset:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', SEARCH_RESULTS_INSET_RIGHT, ENTRY_INSET_BOTTOM)

    local panelWidth = panel:GetWidth()
    if (panelWidth <= 1) then panelWidth = ENTRY_PANEL_WIDTH end
    local innerWidth = panelWidth - SEARCH_RESULTS_INSET_LEFT + SEARCH_RESULTS_INSET_RIGHT - ENTRY_CONTENT_PAD * 2
    local halfWidth = (innerWidth - ENTRY_DROPDOWN_GAP) / 2

    panel.GroupDropdown:ClearAllPoints()
    panel.GroupDropdown:SetPoint('TOPLEFT', inset, 'TOPLEFT', ENTRY_CONTENT_PAD, ENTRY_DROPDOWN_TOP)
    panel.GroupDropdown:SetWidth(halfWidth)
    panel.ActivityDropdown:ClearAllPoints()
    panel.ActivityDropdown:SetPoint('LEFT', panel.GroupDropdown, 'RIGHT', ENTRY_DROPDOWN_GAP, 0)
    panel.ActivityDropdown:SetWidth(halfWidth)

    -- Labels already sit at the inner padding (x=20); inputs line up under them.
    panel.Name:ClearAllPoints()
    panel.Name:SetPoint('TOPLEFT', panel.NameLabel, 'BOTTOMLEFT', 0, -5)
    panel.Name:SetWidth(innerWidth)

    local description = panel.Description
    description:ClearAllPoints()
    description:SetPoint('TOPLEFT', panel.DescriptionLabel, 'BOTTOMLEFT', 0, -10)
    description:SetWidth(innerWidth)
    if (description.EditBox) then
        description.EditBox:SetWidth(innerWidth - ENTRY_DESCRIPTION_EDIT_INSET)
    end

    panel.PlayStyleDropdown:ClearAllPoints()
    panel.PlayStyleDropdown:SetPoint('TOPLEFT', description, 'BOTTOMLEFT', 0, -20)
    panel.PlayStyleDropdown:SetPoint('TOPRIGHT', description, 'BOTTOMRIGHT', 0, -20)

    for _, key in ipairs(ENTRY_ROW_KEYS) do
        local row = panel[key]
        if (row) then
            row:SetWidth(innerWidth + ENTRY_ROW_NUDGE)
            if (row.EditBox) then
                row.EditBox:ClearAllPoints()
                row.EditBox:SetPoint('RIGHT', row, 'RIGHT', 0, 0)
            end
        end
    end

    if (panel.CancelButton) then
        panel.CancelButton:ClearAllPoints()
        panel.CancelButton:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', SEARCH_RESULTS_INSET_LEFT, CATEGORY_BOTTOM_BUTTON_Y)
    end
    if (panel.ListGroupButton) then
        panel.ListGroupButton:ClearAllPoints()
        panel.ListGroupButton:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', SEARCH_RESULTS_INSET_RIGHT,
            CATEGORY_BOTTOM_BUTTON_Y)
    end
end

local function SkinEntryCreation(panel)
    if (not panel or panel.exuiEntrySkinned) then return end
    panel.exuiEntrySkinned = true

    if (panel.Inset) then
        SkinInsetFrame(panel.Inset)
        ApplyPanelArt(panel.Inset, 'BACKGROUND')
    end

    if (panel.Label) then SkinThemeFontString(panel.Label, 14) end
    if (panel.NameLabel) then SkinThemeFontString(panel.NameLabel, 12) end
    if (panel.DescriptionLabel) then SkinThemeFontString(panel.DescriptionLabel, 12) end

    if (panel.Name) then skins:SkinEditBox(panel.Name) end
    if (panel.Description) then skins:SkinInputScrollFrame(panel.Description) end

    for _, key in ipairs({ 'GroupDropdown', 'ActivityDropdown', 'PlayStyleDropdown' }) do
        if (panel[key]) then
            skins:SkinModernDropdown(panel[key], { fontSize = 11 })
        end
    end

    for _, key in ipairs({
        'ItemLevel', 'PvpItemLevel', 'PVPRating', 'MythicPlusRating', 'VoiceChat',
    }) do
        SkinLFGRequirementRow(panel[key])
    end

    SkinLFGOptionCheck(panel.CrossFactionGroup)
    SkinLFGOptionCheck(panel.PrivateGroup)

    if (panel.ListGroupButton) then skins:SkinPanelButton(panel.ListGroupButton) end
    if (panel.CancelButton) then skins:SkinPanelButton(panel.CancelButton) end

    LayoutEntryCreation(panel)
    SkinEntryCreationActivityFinder(panel.ActivityFinder)
end

local function SkinLFGListPanel(panel)
    if (not panel) then return end

    local isEntryCreation = panel.Name and panel.Description
    if (isEntryCreation) then
        SkinEntryCreation(panel)
        return
    end

    if (panel.Inset) then SkinInsetFrame(panel.Inset) end
    if (panel.ResultsInset) then SkinResultsInset(panel.ResultsInset) end

    if (panel.Label and panel.Label.SetFont) then
        SkinThemeFontString(panel.Label, 14)
        if (LFGListFrame and panel == LFGListFrame.CategorySelection) then
            panel.Label:ClearAllPoints()
            panel.Label:SetPoint('CENTER', panel, 'TOP', CATEGORY_LABEL_X, CATEGORY_LABEL_Y)
        end
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
    if (panel.FilterButton and panel.SearchBox) then SkinSearchToolbar(panel) end

    if (panel.AutoAcceptButton) then
        skins:SkinCheckButton(panel.AutoAcceptButton)
        if (panel.AutoAcceptButton.Label) then
            SkinThemeFontString(panel.AutoAcceptButton.Label, 11)
        end
    end

    if (panel.ScrollBar) then skins:SkinSlimScrollBar(panel.ScrollBar) end

    LayoutCategorySelectionButtons(panel)

    if (panel.ResultsInset) then
        LayoutSearchPanelButtons(panel)
        SkinSearchPanelStartGroupButtons(panel)
    end
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

-- Left edge matches the Dungeon Finder panel (x=228); the right edge leaves room for both
-- borders against the Honor sidebar. Bottom offsets are from the window bottom, since the
-- content frames differ in height; the Join button matches the Premade Groups padding.
local PVP_FRAME_TOP = -22
local PVP_INSET_LEFT = 8
local PVP_INSET_TOP = -79
local PVP_INSET_RIGHT = -15
local PVP_INSET_BOTTOM = 37
local PVP_JOIN_BUTTON_BOTTOM = SEARCH_BOTTOM_BUTTON_Y
-- Role list and type dropdown sit on the inset's top edge, under the panel border.
local PVP_INSET_HEADER_LIFT = 5

local function LayoutPvPInset(frame)
    local frameBottom = PVEFrame:GetHeight() + PVP_FRAME_TOP - frame:GetHeight()

    local inset = frame.Inset
    inset:ClearAllPoints()
    inset:SetPoint('TOPLEFT', frame, 'TOPLEFT', PVP_INSET_LEFT, PVP_INSET_TOP)
    inset:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', PVP_INSET_RIGHT, PVP_INSET_BOTTOM - frameBottom)

    local joinButton = frame.QueueButton or frame.JoinButton
    if (joinButton) then
        joinButton:ClearAllPoints()
        joinButton:SetPoint('BOTTOM', frame, 'BOTTOM', 0, PVP_JOIN_BUTTON_BOTTOM - frameBottom)
    end

    if (frame.RoleList) then
        frame.RoleList:ClearAllPoints()
        frame.RoleList:SetPoint('BOTTOMLEFT', inset, 'TOPLEFT', 5, 2 + PVP_INSET_HEADER_LIFT)
    end
    if (frame.TypeDropdown) then
        frame.TypeDropdown:ClearAllPoints()
        frame.TypeDropdown:SetPoint('BOTTOMRIGHT', inset, 'TOPRIGHT', -6, 4 + PVP_INSET_HEADER_LIFT)
    end
    -- Blizzard anchors this to the frame edge; keep it inside the narrowed inset.
    if (frame.SpecificScrollBar) then
        frame.SpecificScrollBar:ClearAllPoints()
        frame.SpecificScrollBar:SetPoint('TOPLEFT', inset, 'TOPRIGHT', -17, -7)
        frame.SpecificScrollBar:SetPoint('BOTTOMLEFT', inset, 'BOTTOMRIGHT', -17, 5)
    end
end

local function SkinPvPContentFrame(frame)
    if (not frame or frame.exuiContentSkinned) then return end
    frame.exuiContentSkinned = true

    StripPanelRootTextures(frame)

    if (frame.Inset) then
        SkinInsetFrame(frame.Inset)
        -- Plunderstorm keeps its full-panel event art.
        if (frame ~= PlunderstormFrame) then
            ApplyPanelArt(frame.Inset, 'BACKGROUND')
            LayoutPvPInset(frame)
        end
    end
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

    -- Casual / Training Grounds: QueueButton; Rated: JoinButton; Plunderstorm: StartQueue
    if (frame.QueueButton) then skins:SkinPanelButton(frame.QueueButton) end
    if (frame.JoinButton) then skins:SkinPanelButton(frame.JoinButton) end
    if (frame.StartQueue) then skins:SkinPanelButton(frame.StartQueue) end
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

---Right-hand Honor / Conquest sidebar; Blizzard anchors it at y=-22, under our taller header.
local function SkinHonorInset(inset)
    if (not inset or inset.exuiPanelArt) then return end

    SkinInsetFrame(inset)
    if (inset.Background) then inset.Background:SetAlpha(0) end

    inset:ClearAllPoints()
    inset:SetPoint('TOPRIGHT', PVEFrame, 'TOPRIGHT', -SIDEBAR_LEFT, -(HEADER_HEIGHT + 1 + SIDEBAR_TOP_GAP))
    inset:SetPoint('BOTTOMRIGHT', PVEFrame, 'BOTTOMRIGHT', -SIDEBAR_LEFT, SIDEBAR_LEFT)

    ApplyPanelArt(inset, 'BACKGROUND')
end

function pveFrameSkin:SkinPvPTab()
    if (not PVPUIFrame) then return end

    SkinPvPCategoryButtons()

    SkinHonorInset(PVPQueueFrame and PVPQueueFrame.HonorInset)

    if (PVPQueueFrame and PVPQueueFrame.PrestigePortrait) then
        local portrait = PVPQueueFrame.PrestigePortrait
        skins:StripRegions(portrait, { 'PortraitBackground', 'SmallWreath', 'LaurelBackground' })
    end

    for _, frameName in ipairs({
        'HonorFrame', 'ConquestFrame', 'TrainingGroundsFrame', 'PlunderstormFrame',
    }) do
        SkinPvPContentFrame(_G[frameName])
    end

    if (LFGListFrame) then
        SkinLFGListFrame()
    end
end

local CHALLENGES_WEEKLY_INFO_X = 6
-- Blizzard places WeeklyInfo at y=-12; drop it with the inset so "This Week" clears the border.
local CHALLENGES_WEEKLY_INFO_Y = -22
local CHALLENGES_ICON_PAD = 8
-- Room for both icons' border outsets between neighbours.
local CHALLENGES_ICON_GAP = 10
local CHALLENGES_TEXT_PAD = 5
local CHALLENGES_LEVEL_SIZE = 12
local CHALLENGES_SCORE_SIZE = 15
local CHALLENGES_TEXT_LEVEL_OFFSET = 25

local function GetChallengesInset()
    return ChallengesFrameInset
end

---Season best icon: our border, rounded icon, level above a slightly larger dungeon score (bottom left).
local function SkinChallengeIcon(icon)
    if (icon.exuiChallengeSkinned) then return end
    icon.exuiChallengeSkinned = true

    for _, region in ipairs({ icon:GetRegions() }) do
        if (region:IsObjectType('Texture') and region:GetAtlas() == 'ChallengeMode-DungeonIconFrame') then
            region:SetAlpha(0)
        end
    end

    local mask = icon:CreateMaskTexture()
    mask:SetAllPoints(icon.Icon)
    mask:SetTexture(EXUI.const.textures.skins.lfgSpecMask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon.Icon:AddMaskTexture(mask)

    CreatePanelBorder(icon, icon)

    -- Text sits above the border frame so its inner shadow does not darken it.
    local textFrame = CreateFrame('Frame', nil, icon)
    textFrame:SetAllPoints()
    textFrame:SetFrameLevel(icon:GetFrameLevel() + CHALLENGES_TEXT_LEVEL_OFFSET)

    local score = textFrame:CreateFontString(nil, 'OVERLAY')
    score:SetFont(EXUI.const.fonts.DEFAULT, CHALLENGES_SCORE_SIZE, 'OUTLINE')
    score:SetShadowColor(0, 0, 0, 0)
    score:SetJustifyH('LEFT')
    score:SetPoint('BOTTOMLEFT', textFrame, 'BOTTOMLEFT', CHALLENGES_TEXT_PAD, CHALLENGES_TEXT_PAD)
    icon.exuiScore = score

    local level = icon.HighestLevel
    level:SetParent(textFrame)
    level:SetFont(EXUI.const.fonts.DEFAULT, CHALLENGES_LEVEL_SIZE, 'OUTLINE')
    level:SetShadowColor(0, 0, 0, 0)
    level:SetJustifyH('LEFT')
    level:ClearAllPoints()
    level:SetPoint('BOTTOMLEFT', score, 'TOPLEFT', 0, 0)
end

local function UpdateChallengeIconText(icon)
    local score = icon.exuiScore
    local _, overallScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(icon.mapID)
    if (not icon.HighestLevel:IsShown() or not overallScore) then
        score:Hide()
        return
    end

    local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(overallScore) or HIGHLIGHT_FONT_COLOR
    score:SetText(overallScore)
    score:SetTextColor(color.r, color.g, color.b)
    score:Show()
    icon.HighestLevel:SetTextColor(unpack(GetTheme().white))
end

---BigWigs adds its own score string at the icon's bottom; it would sit on top of ours.
local function HideForeignIconScores(frame)
    for _, icon in ipairs(frame.DungeonIcons or {}) do
        for _, region in ipairs({ icon:GetRegions() }) do
            if (region:IsObjectType('FontString') and region ~= icon.HighestLevel) then
                local point, relativeTo = region:GetPoint(1)
                if (point == 'BOTTOM' and (relativeTo == nil or relativeTo == icon)) then
                    region:SetAlpha(0)
                end
            end
        end
    end
end

local function LayoutChallengeIcons(frame)
    local inset = GetChallengesInset()
    local icons = frame.DungeonIcons
    if (not inset or not icons) then return end

    local count = 0
    for i = 1, #icons do
        if (icons[i]:IsShown()) then count = i end
    end
    local width = inset:GetWidth() - CHALLENGES_ICON_PAD * 2
    if (count == 0 or width <= 1) then return end

    local size = (width - CHALLENGES_ICON_GAP * (count - 1)) / count
    for i = 1, count do
        local icon = icons[i]
        SkinChallengeIcon(icon)
        icon:SetSize(size, size)
        icon.Icon:SetSize(size, size)
        icon:ClearAllPoints()
        if (i == 1) then
            icon:SetPoint('BOTTOMLEFT', inset, 'BOTTOMLEFT', CHALLENGES_ICON_PAD, CHALLENGES_ICON_PAD)
        else
            icon:SetPoint('LEFT', icons[i - 1], 'RIGHT', CHALLENGES_ICON_GAP, 0)
        end
        UpdateChallengeIconText(icon)
    end

    HideForeignIconScores(frame)
end

function pveFrameSkin:SkinChallengesTab()
    local frame = ChallengesFrame
    if (not frame or frame.exuiChallengesSkinned) then return end
    frame.exuiChallengesSkinned = true

    local inset = GetChallengesInset()
    if (inset) then
        SkinInsetFrame(inset)
        inset:ClearAllPoints()
        inset:SetPoint('TOPLEFT', frame, 'TOPLEFT', SIDEBAR_LEFT, -(HEADER_HEIGHT + 1 + SIDEBAR_TOP_GAP))
        inset:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -SIDEBAR_LEFT, SIDEBAR_LEFT)
        -- One level under the frame so Blizzard's faded dungeon art always draws over our panel.
        inset:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
        ApplyPanelArt(inset, 'BACKGROUND')
    end

    if (frame.WeeklyInfo) then
        frame.WeeklyInfo:ClearAllPoints()
        frame.WeeklyInfo:SetPoint('TOPLEFT', frame, 'TOPLEFT', CHALLENGES_WEEKLY_INFO_X, CHALLENGES_WEEKLY_INFO_Y)
    end

    for _, region in ipairs({ frame:GetRegions() }) do
        if (region:IsObjectType('Texture') and region.GetAtlas and region:GetAtlas() == 'insetshadow') then
            skins:StripTexture(region)
        end
    end

    if (frame.WeeklyInfo and frame.WeeklyInfo.Child) then
        SkinChallengesWeeklyInfo(frame.WeeklyInfo.Child)
    end

    if (frame:IsShown()) then
        LayoutChallengeIcons(frame)
    end
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
    local frame = ChallengesFrame
    if (not frame) then return end
    self.challengesHooksInstalled = true

    -- The frame already carries its mixin methods, so hook the instance rather than the mixin.
    hooksecurefunc(frame, 'Update', LayoutChallengeIcons)
    -- BigWigs adds its icon strings from its own OnShow hook; catch them once both have run.
    frame:HookScript('OnShow', function(self)
        C_Timer.After(0, function() HideForeignIconScores(self) end)
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

    if (type(LFGListCategorySelection_UpdateCategoryButtons) == 'function') then
        hooksecurefunc('LFGListCategorySelection_UpdateCategoryButtons', function()
            pveFrameSkin:RestyleLFGListCategoryRows()
        end)
    end

    if (type(LFGListSearchPanel_UpdateResults) == 'function') then
        hooksecurefunc('LFGListSearchPanel_UpdateResults', function(panel)
            SkinSearchPanelStartGroupButtons(panel)
        end)
    end

    searchEntrySkin:Install()
    filtersSkin:Install()
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
    if (not skins:IsEnabled('PVEFrame')) then return end

    if (PVEFrame) then
        self:Install()
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-PVEFrame', function(_, addon)
        self:OnAddonLoaded(addon)
    end)
end
