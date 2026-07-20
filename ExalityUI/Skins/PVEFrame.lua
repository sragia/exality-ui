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
local NAV_BG_ALPHA_SELECTED = 1
local NAV_BG_ALPHA_HOVER = 0.7
local NAV_BG_ALPHA_NORMAL = 0.35
local NAV_BG_ALPHA_DISABLED = 0.2

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

    blueBg:SetTexture(EXUI.const.textures.skins.lfgLeftBg)
    blueBg:SetTexCoord(0, 1, 0, 1)
    blueBg:SetVertexColor(1, 1, 1, 1)
    blueBg:SetAlpha(1)
    blueBg:Show()
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

local function EnsureLeftSidebarChrome(frame)
    if (frame.exuiSidebar) then return end
    local th = GetTheme()

    -- Divider only; left fill comes from PVEFrameBlueBg art.
    local sidebar = CreateFrame('Frame', nil, frame)
    sidebar:SetFrameLevel(1)
    sidebar:SetPoint('TOPLEFT', frame, 'TOPLEFT', 4, -24)
    sidebar:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 4, 4)
    sidebar:SetWidth(217)
    frame.exuiSidebar = sidebar

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
        StylePVEFrameBlueBg(frame)
    else
        frame.exuiSidebar:Hide()
    end
end

local function SkinLeftSidebar(frame)
    StripBlizzardSidebarTextures(frame)
    StylePVEFrameBlueBg(frame)
    EnsureLeftSidebarChrome(frame)
    pveFrameSkin:SetLeftSidebarShown(true)
end

-- ---------------------------------------------------------------------------
-- Side nav buttons (Group Finder + PvP category buttons)
-- ---------------------------------------------------------------------------

local function EnsureNavButtonBg(button)
    if (not button.exuiNavBg) then
        local bg = button:CreateTexture(nil, 'BACKGROUND', nil, 0)
        bg:SetAllPoints()
        button.exuiNavBg = bg
    end

    local bg = button.exuiNavBg
    bg:SetTexture(EXUI.const.textures.skins.lfgLeftBtnBg)
    bg:SetTexCoord(0, 1, 0, 1)
    bg:SetVertexColor(1, 1, 1, 1)
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
    local alpha = NAV_BG_ALPHA_NORMAL
    if (not enabled) then
        alpha = NAV_BG_ALPHA_DISABLED
    elseif (selected) then
        alpha = NAV_BG_ALPHA_SELECTED
    elseif (button:IsMouseOver()) then
        alpha = NAV_BG_ALPHA_HOVER
    end

    button.exuiNavBg:SetAlpha(alpha)
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
local SEARCH_BOTTOM_BUTTON_Y = 6
local SEARCH_BOTTOM_BUTTON_X = 2

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
        inset:SetPoint('TOPLEFT', panel, 'TOPLEFT', 0, -86)
        inset:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -25, SEARCH_RESULTS_INSET_BOTTOM)
    end

    for _, key in ipairs({ 'BackButton', 'BackToGroupButton' }) do
        local button = panel[key]
        if (button) then
            button:ClearAllPoints()
            button:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', SEARCH_BOTTOM_BUTTON_X, SEARCH_BOTTOM_BUTTON_Y)
        end
    end

    if (panel.SignUpButton) then
        panel.SignUpButton:ClearAllPoints()
        panel.SignUpButton:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -SEARCH_BOTTOM_BUTTON_X, SEARCH_BOTTOM_BUTTON_Y)
    end
end

---Named `$parentBackground` textures (e.g. LFDQueueFrameBackground) get dungeon art
---reapplied by Blizzard; lock them to a solid theme fill.
local function StyleLockedSolidBackground(texture)
    if (not texture or texture.exuiSolidLocked) then return end
    texture.exuiSolidLocked = true

    local solid = EXUI.const.textures.frame.solidBg
    local applying = false
    local function Apply()
        if (applying) then return end
        applying = true
        local th = GetTheme()
        texture:SetTexture(solid)
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetVertexColor(th.backgroundDeep[1], th.backgroundDeep[2], th.backgroundDeep[3], 1)
        texture:SetAlpha(0.9)
        applying = false
    end

    Apply()
    hooksecurefunc(texture, 'SetTexture', Apply)
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
local QUEUE_BG_BORDER_THICKNESS = 1

local function RefreshQueueBackgroundBorder(chrome)
    local border = chrome and chrome.exuiBorder
    if (not border) then return end

    -- Match PixelPerfect applyBorderThickness: left/right flush (no outward nudge).
    -- Outward left was fighting the Group Finder sidebar edge.
    border:SetBorderThickness(QUEUE_BG_BORDER_THICKNESS)
    border:SetBorderColor(unpack(GetTheme().border))
end

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

    local chrome = queueFrame.exuiQueueBgChrome
    if (not chrome) then
        chrome = CreateFrame('Frame', nil, queueFrame)
        chrome:EnableMouse(false)
        chrome.exuiBorder = EXUI:AddPixelPerfectBorder(chrome, QUEUE_BG_BORDER_THICKNESS, {
            register = true,
            layer = 'OVERLAY',
        })
        queueFrame.exuiQueueBgChrome = chrome

        chrome:HookScript('OnShow', function(self)
            RefreshQueueBackgroundBorder(self)
        end)
        chrome:HookScript('OnSizeChanged', function(self)
            RefreshQueueBackgroundBorder(self)
        end)
    end

    chrome:ClearAllPoints()
    chrome:SetPoint('TOPLEFT', texture, 'TOPLEFT')
    chrome:SetPoint('BOTTOMRIGHT', texture, 'BOTTOMRIGHT')
    -- Sit above ScrollBox / list siblings so all four edges stay visible.
    chrome:SetFrameLevel((queueFrame:GetFrameLevel() or 1) + 100)

    chrome:Show()
    RefreshQueueBackgroundBorder(chrome)
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
        StyleLockedSolidBackground(background)
        LayoutQueueBackground(queueFrame, background)
        LayoutQueueScrollBoxes(queueFrame, background)
    end
    if (queueFrame.Bg and queueFrame.Bg ~= background) then
        StyleLockedSolidBackground(queueFrame.Bg)
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
        skins:SkinCheckButton(row.CheckButton)
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
        skins:SkinCheckButton(row.CheckButton)
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

-- EntryCreation Inset defaults to y=26; buttons are 22px at y=6 and collide with the border.
local ENTRY_INSET_BOTTOM = 36
local ENTRY_INSET_TOPLEFT = { 0, -61 }
local ENTRY_INSET_RIGHT = -5

local function LayoutEntryCreationButtons(panel)
    if (not panel or panel.exuiEntryLayoutAdjusted) then return end
    panel.exuiEntryLayoutAdjusted = true

    if (panel.Inset) then
        panel.Inset:ClearAllPoints()
        panel.Inset:SetPoint('TOPLEFT', panel, 'TOPLEFT', ENTRY_INSET_TOPLEFT[1], ENTRY_INSET_TOPLEFT[2])
        panel.Inset:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', ENTRY_INSET_RIGHT, ENTRY_INSET_BOTTOM)
    end

    if (panel.CancelButton) then
        panel.CancelButton:ClearAllPoints()
        panel.CancelButton:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', CATEGORY_BOTTOM_BUTTON_X, CATEGORY_BOTTOM_BUTTON_Y)
    end
    if (panel.ListGroupButton) then
        panel.ListGroupButton:ClearAllPoints()
        panel.ListGroupButton:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -CATEGORY_BOTTOM_BUTTON_X, CATEGORY_BOTTOM_BUTTON_Y)
    end
end

local function SkinEntryCreation(panel)
    if (not panel or panel.exuiEntrySkinned) then return end
    panel.exuiEntrySkinned = true

    if (panel.Inset) then
        SkinInsetFrame(panel.Inset, { chrome = true, backdropAlpha = 0.55 })
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

    LayoutEntryCreationButtons(panel)
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
    if (panel.ResultsInset) then
        SkinInsetFrame(panel.ResultsInset, { chrome = true })
    end

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
    if (panel.FilterButton) then
        skins:SkinModernDropdown(panel.FilterButton, { fontSize = 11 })
    end

    if (panel.AutoAcceptButton) then
        skins:SkinCheckButton(panel.AutoAcceptButton)
        if (panel.AutoAcceptButton.Label) then
            SkinThemeFontString(panel.AutoAcceptButton.Label, 11)
        end
    end

    if (panel.ScrollBar) then skins:SkinMinimalScrollBar(panel.ScrollBar) end

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

function pveFrameSkin:SkinPvPTab()
    if (not PVPUIFrame) then return end

    SkinPvPCategoryButtons()

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

    if (type(LFGListSearchPanel_UpdateResults) == 'function') then
        hooksecurefunc('LFGListSearchPanel_UpdateResults', function(panel)
            SkinSearchPanelStartGroupButtons(panel)
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
    if (not skins:IsEnabled('PVEFrame')) then return end

    if (PVEFrame) then
        self:Install()
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-PVEFrame', function(_, addon)
        self:OnAddonLoaded(addon)
    end)
end
