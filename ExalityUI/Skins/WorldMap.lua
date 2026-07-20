---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIWorldMapSkin
local worldMapSkin = EXUI:GetModule('skin-WorldMap')

local TITLE_SIZE = 13
local MAP_BG_ALPHA = 0.95
local NAV_TEXT_SIZE = 12

local function GetTheme()
    return EXUI.const.theme
end

local function StripButtonTextures(button)
    skins:StripTexture(button:GetNormalTexture())
    skins:StripTexture(button:GetPushedTexture())
    if (button.GetDisabledTexture) then skins:StripTexture(button:GetDisabledTexture()) end
    if (button.GetHighlightTexture) then skins:StripTexture(button:GetHighlightTexture()) end
end

---Maximize/minimize use custom fullscreen icons tinted to match the title bar.
local MAX_MIN_ICON_SIZE = 14

local function SkinMaxMinButton(button, mode)
    if (not button or button.exuiSkinned) then return end
    button.exuiSkinned = true

    StripButtonTextures(button)
    local th = GetTheme()

    local iconPath = mode == 'maximize'
        and EXUI.const.textures.frame.icons.fullscreen
        or EXUI.const.textures.frame.icons.minimize

    local icon = button:CreateTexture(nil, 'OVERLAY')
    icon:SetTexture(iconPath)
    icon:SetPoint('CENTER')
    icon:SetSize(MAX_MIN_ICON_SIZE, MAX_MIN_ICON_SIZE)
    icon:SetVertexColor(unpack(th.textMuted))

    local setGlyphColor = function(color)
        icon:SetVertexColor(unpack(color))
    end

    button:HookScript('OnEnter', function()
        setGlyphColor(GetTheme().accentLight)
    end)
    button:HookScript('OnLeave', function()
        setGlyphColor(GetTheme().textMuted)
    end)
end

local NAV_CRUMB_SPACING = 2
local NAV_CHIP_PAD_H = 8
local NAV_CHIP_PAD_V = 2
local NAV_MENU_GAP = 3
local NAV_MENU_SIZE = 10

local function GetNavChevronTexture()
    return EXUI.const.textures.frame.inputs.chevronDown
end

local function ApplyNavButtonTextColor(button, text)
    local th = GetTheme()
    if (not button:IsEnabled()) then
        text:SetTextColor(unpack(th.white))
    else
        text:SetTextColor(unpack(th.gray))
    end
end

local function ApplyNavMenuChevronColor(button, color)
    if (button.exuiMenuChevron) then
        button.exuiMenuChevron:SetVertexColor(unpack(color))
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

local function SkinMenuArrowButton(menuArrow)
    if (not menuArrow or menuArrow.exuiSkinned) then return end
    menuArrow.exuiSkinned = true

    skins:StripTexture(menuArrow:GetNormalTexture())
    skins:StripTexture(menuArrow:GetPushedTexture())
    skins:StripTexture(menuArrow:GetHighlightTexture())
    if (menuArrow.Art) then menuArrow.Art:Hide() end

    menuArrow:HookScript('OnEnter', function()
        local parent = menuArrow:GetParent()
        if (parent) then ApplyNavMenuChevronColor(parent, GetTheme().white) end
    end)
    menuArrow:HookScript('OnLeave', function()
        local parent = menuArrow:GetParent()
        if (parent) then ApplyNavMenuChevronColor(parent, GetTheme().gray) end
    end)
end

local function UpdateNavButtonLayout(button)
    local text = button.text or (button.GetFontString and button:GetFontString())
    if (not text) then return end

    if (button.exuiSep) then button.exuiSep:Hide() end

    local width = NAV_CHIP_PAD_H + text:GetStringWidth()

    local menuArrow = button.MenuArrowButton
    local hasMenu = menuArrow and menuArrow:IsShown()
    if (hasMenu) then
        menuArrow:Show()
        if (not button.exuiMenuChevron) then
            button.exuiMenuChevron = button:CreateTexture(nil, 'OVERLAY')
            button.exuiMenuChevron:SetTexture(GetNavChevronTexture())
            button.exuiMenuChevron:SetSize(NAV_MENU_SIZE, NAV_MENU_SIZE)
        end
        button.exuiMenuChevron:ClearAllPoints()
        button.exuiMenuChevron:SetPoint('LEFT', text, 'RIGHT', NAV_MENU_GAP, 0)
        button.exuiMenuChevron:Show()
        ApplyNavMenuChevronColor(button, GetTheme().gray)

        menuArrow:ClearAllPoints()
        menuArrow:SetSize(NAV_MENU_SIZE + 6, NAV_MENU_SIZE + 6)
        menuArrow:SetPoint('CENTER', button.exuiMenuChevron, 'CENTER')
        menuArrow:SetFrameLevel(button:GetFrameLevel() + 2)

        width = width + NAV_MENU_GAP + NAV_MENU_SIZE + NAV_CHIP_PAD_H
    else
        if (button.exuiMenuChevron) then button.exuiMenuChevron:Hide() end
        width = width + NAV_CHIP_PAD_H
    end

    button:SetWidth(math.ceil(width))
    ApplyNavCrumbBackground(button, false)
end

local function SkinNavButton(button)
    if (not button or button.exuiSkinned) then return end
    button.exuiSkinned = true

    StripButtonTextures(button)
    skins:StripRegions(button, { 'arrowUp', 'arrowDown', 'selected' })

    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if (highlight) then skins:StripTexture(highlight) end

    local homeName = button:GetName()
    if (homeName) then
        local leftShadow = _G[homeName .. 'Left']
        if (leftShadow) then skins:StripTexture(leftShadow) end
    end

    if (not button.exuiCrumbBg) then
        local bg = button:CreateTexture(nil, 'BACKGROUND', nil, 0)
        bg:SetTexture(EXUI.const.textures.frame.solidBg)
        bg:SetPoint('TOPLEFT', button, 'TOPLEFT', 0, -NAV_CHIP_PAD_V)
        bg:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 0, NAV_CHIP_PAD_V)
        button.exuiCrumbBg = bg
    end
    ApplyNavCrumbBackground(button, false)

    if (button.MenuArrowButton) then
        SkinMenuArrowButton(button.MenuArrowButton)
    end

    local text = button.text or (button.GetFontString and button:GetFontString())
    if (text) then
        text:SetFont(EXUI.const.fonts.DEFAULT, NAV_TEXT_SIZE, '')
        text:ClearAllPoints()
        text:SetPoint('LEFT', button, 'LEFT', NAV_CHIP_PAD_H, 0)
        ApplyNavButtonTextColor(button, text)

        button:HookScript('OnEnter', function(btn)
            if (not btn:IsEnabled()) then return end
            text:SetTextColor(unpack(GetTheme().white))
            ApplyNavMenuChevronColor(btn, GetTheme().white)
            ApplyNavCrumbBackground(btn, true)
        end)
        button:HookScript('OnLeave', function(btn)
            ApplyNavButtonTextColor(btn, text)
            ApplyNavMenuChevronColor(btn, GetTheme().gray)
            ApplyNavCrumbBackground(btn, false)
        end)
        button:HookScript('OnDisable', function(btn)
            ApplyNavButtonTextColor(btn, text)
            ApplyNavCrumbBackground(btn, false)
        end)
        button:HookScript('OnEnable', function(btn)
            ApplyNavButtonTextColor(btn, text)
            ApplyNavCrumbBackground(btn, false)
        end)
    end

    UpdateNavButtonLayout(button)
end

local function ApplyNavCrumbSpacing(navBar)
    for _, button in ipairs(navBar.navList or {}) do
        button.xoffset = NAV_CRUMB_SPACING
    end
    if (navBar.overflow) then
        navBar.overflow.xoffset = NAV_CRUMB_SPACING
    end
end

local function SkinNavBar(navBar)
    if (not navBar or navBar.exuiSkinned) then return end
    navBar.exuiSkinned = true
    local th = GetTheme()

    -- Direct regions cover the tiled CS_HelpTextures background and the InsetBorder* pieces.
    skins:StripAllTextures(navBar)
    if (navBar.overlay) then
        skins:StripAllTextures(navBar.overlay)
    end

    skins:AddBackdrop(navBar, { color = th.background, alpha = 0.85 })

    ApplyNavCrumbSpacing(navBar)

    for _, button in ipairs(navBar.navList or {}) do
        SkinNavButton(button)
        UpdateNavButtonLayout(button)
    end
    if (navBar.overflow) then
        skins:SkinIconButton(navBar.overflow, { strip = { 'HighlightTexture' } })
    end

    if (type(NavBar_CheckLength) == 'function') then
        NavBar_CheckLength(navBar)
    end
end

local SIDE_PANEL_TOGGLE_SIZE = 32
local SIDE_PANEL_ICON_SIZE = 18

local function GetSidePanelChevronTexture(direction)
    local icons = EXUI.const.textures.frame.icons
    if (direction == 'left') then
        return icons.chevronLeft
    end
    return icons.chevronRight
end

local function EnsureSidePanelToggleBackground(button)
    if (not button.exuiBg) then
        local bg = button:CreateTexture(nil, 'BACKGROUND')
        bg:SetTexture(EXUI.const.textures.frame.whiteTextured)
        bg:SetAllPoints()
        button.exuiBg = bg
    end
end

local function ApplySidePanelToggleBackground(button, hovered)
    EnsureSidePanelToggleBackground(button)
    local th = GetTheme()
    if (hovered) then
        button.exuiBg:SetVertexColor(unpack(th.backgroundLight))
    else
        button.exuiBg:SetVertexColor(unpack(th.backgroundDeep))
    end
    button.exuiBg:Show()
end

local function SkinSidePanelToggleButton(button, direction)
    if (not button or button.exuiSkinned) then return end
    button.exuiSkinned = true
    local th = GetTheme()

    StripButtonTextures(button)
    skins:StripAtlasRegions(button, 'MapCornerShadow-Right')

    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if (highlight) then skins:StripTexture(highlight) end

    button:SetSize(SIDE_PANEL_TOGGLE_SIZE, SIDE_PANEL_TOGGLE_SIZE)
    ApplySidePanelToggleBackground(button, false)
    skins:AddBorder(button)

    local icon = button:CreateTexture(nil, 'OVERLAY')
    icon:SetTexture(GetSidePanelChevronTexture(direction))
    icon:SetSize(SIDE_PANEL_ICON_SIZE, SIDE_PANEL_ICON_SIZE)
    icon:SetPoint('CENTER')
    icon:SetVertexColor(unpack(th.textMuted))
    button.exuiIcon = icon

    button:HookScript('OnEnter', function(btn)
        btn.exuiIcon:SetVertexColor(unpack(GetTheme().accentLight))
        ApplySidePanelToggleBackground(btn, true)
    end)
    button:HookScript('OnLeave', function(btn)
        btn.exuiIcon:SetVertexColor(unpack(GetTheme().textMuted))
        ApplySidePanelToggleBackground(btn, false)
    end)
end

local function SkinSidePanelToggle(toggle)
    if (not toggle) then return end

    local map = toggle:GetParent()
    local canvas = map and map.ScrollContainer
    if (canvas) then
        toggle:SetFrameLevel(canvas:GetFrameLevel() + 5)
    end

    toggle:SetSize(SIDE_PANEL_TOGGLE_SIZE, SIDE_PANEL_TOGGLE_SIZE)
    -- Open: panel hidden, chevron points left to expand. Close: panel shown, chevron right to collapse.
    SkinSidePanelToggleButton(toggle.OpenButton, 'right')
    SkinSidePanelToggleButton(toggle.CloseButton, 'left')
end

---With the portrait hidden, close the gaps Blizzard leaves to clear the circle:
---the minimized nav bar is indented 64px and the tutorial ring floats at the old spot.
local NAV_BAR_LEFT_OFFSET = 8
local NAV_BAR_TOP_OFFSET = -22
local NAV_BAR_BOTTOM_OFFSET = 2

local function AdjustTitleBarLayout(map)
    local navBar = map.NavBar
    local spacer = map.TitleCanvasSpacerFrame
    if (navBar and spacer) then
        navBar:ClearAllPoints()
        navBar:SetPoint('TOPLEFT', spacer, 'TOPLEFT', NAV_BAR_LEFT_OFFSET, NAV_BAR_TOP_OFFSET)
        navBar:SetPoint('BOTTOMRIGHT', spacer, 'BOTTOMRIGHT', -4, NAV_BAR_BOTTOM_OFFSET)
    end

    local tutorial = map.BorderFrame.Tutorial
    if (tutorial and not tutorial.exuiAdjusted) then
        tutorial.exuiAdjusted = true
        tutorial:SetScale(0.55)
        tutorial:ClearAllPoints()
        tutorial:SetPoint('TOPLEFT', map.BorderFrame, 'TOPLEFT', 10, -6)
    end
end

function worldMapSkin:SkinFrame()
    local map = WorldMapFrame
    if (not map or not map.BorderFrame) then return end

    skins:SkinPanelFrame(map.BorderFrame, {
        hidePortrait = true,
        titleSize = TITLE_SIZE,
        -- Backdrop lives on WorldMapFrame (level 0) so it stays behind the map canvas;
        -- the border stays on BorderFrame (HIGH strata) so it draws above everything.
        backdropAnchor = map,
        backdropAlpha = MAP_BG_ALPHA,
    })

    local maxMin = map.BorderFrame.MaximizeMinimizeFrame
    if (maxMin) then
        SkinMaxMinButton(maxMin.MaximizeButton, 'maximize')
        SkinMaxMinButton(maxMin.MinimizeButton, 'minimize')
    end

    SkinNavBar(map.NavBar)
    SkinSidePanelToggle(map.SidePanelToggle)
    AdjustTitleBarLayout(map)
end

function worldMapSkin:InstallHooks()
    if (self.hooksInstalled) then return end
    self.hooksInstalled = true

    -- Maximize/Minimize re-apply a NineSlice layout (auto re-stripped via the shared
    -- ApplyLayout hook), re-show the portrait, and re-indent the nav bar. Hook the
    -- frame methods (not the WorldMapMaximized/Minimized events, which fire before
    -- the layout changes) so the skin re-applies after Blizzard is done.
    hooksecurefunc(WorldMapFrame, 'Minimize', function()
        self:SkinFrame()
    end)
    hooksecurefunc(WorldMapFrame, 'Maximize', function()
        self:SkinFrame()
    end)

    -- Breadcrumb buttons are created/reused dynamically as the shown map changes.
    if (type(NavBar_AddButton) == 'function') then
        hooksecurefunc('NavBar_AddButton', function(navBar)
            if (not navBar.exuiSkinned) then return end
            ApplyNavCrumbSpacing(navBar)
            local button = navBar.navList and navBar.navList[#navBar.navList]
            SkinNavButton(button)
            UpdateNavButtonLayout(button)
            if (type(NavBar_CheckLength) == 'function') then
                NavBar_CheckLength(navBar)
            end
        end)
    end
end

function worldMapSkin:Install()
    if (self.installed or not WorldMapFrame) then return end
    self.installed = true

    self:InstallHooks()
    self:SkinFrame()
end

worldMapSkin.Init = function(self)
    if (not skins:IsEnabled('WorldMap')) then return end

    if (WorldMapFrame) then
        self:Install()
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-WorldMap', function(_, addon)
        if (addon ~= 'Blizzard_WorldMap') then return end
        self:Install()
    end)
end
