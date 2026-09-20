---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIData
local data = EXUI:GetModule('data')

---@class ExalityFramesPanelFrame
local panel = EXFrames:GetFrame('panel-frame')

---@class EXUIOptionsModuleSelector
local optionsModuleSelector = EXUI:GetModule('options-module-selector')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIEditor
local editor = EXUI:GetModule('editor')

---@class EXUIProfiles
local profiles = EXUI:GetModule('profiles')

----------------

---@class EXUIOptionsMain
local optionsMain = EXUI:GetModule('options-main')

local ASSETS = {
    topBar = [[Interface/Addons/ExalityUI/Options/Assets/top-bar.png]],
    mainBg = [[Interface/Addons/ExalityUI/Options/Assets/main-bg_2.png]],
    sidebarBg = [[Interface/Addons/ExalityUI/Options/Assets/sidebar-bg.png]],
    btnBg = [[Interface/Addons/ExalityUI/Options/Assets/btn-bg.png]],
    iconClose = [[Interface/Addons/ExalityUI/Options/Assets/icon-close.png]],
    iconProfiles = [[Interface/Addons/ExalityUI/Options/Assets/icon-profiles.png]],
    iconEditMode = [[Interface/Addons/ExalityUI/Options/Assets/icon-editmode.png]],
    iconChevron = [[Interface/Addons/ExalityUI/Options/Assets/icon-chevron-right.png]],
}

local LAYOUT = {
    window = { 980, 755 },
    expanded = { nav = 180 },
    compact = { nav = 36 },
}

local NAV_ANIM_DURATION = 0.2
local NAV_PANEL_INSET = 8
local NAV_TOGGLE_SIZE = 22
local SIDEBAR_GAP = 0
local SIDEBAR_VERTICAL_INSET = 30

optionsMain.window = nil
optionsMain.sidebar = nil
optionsMain.isNavCompact = false
optionsMain.LAYOUT = LAYOUT
optionsMain.ASSETS = ASSETS

optionsMain.ApplySidebarLayout = function(self, navWidth)
    if not self.sidebar or not self.window then
        return
    end
    self.sidebar:SetWidth(navWidth)
    self.sidebar:ClearAllPoints()
    self.sidebar:SetPoint('TOPRIGHT', self.window, 'TOPLEFT', -SIDEBAR_GAP, -SIDEBAR_VERTICAL_INSET)
    self.sidebar:SetPoint('BOTTOMRIGHT', self.window, 'BOTTOMLEFT', -SIDEBAR_GAP, SIDEBAR_VERTICAL_INSET)
end

optionsMain.UpdateNavToggleIcon = function(self)
    if not self.navToggleIcon then
        return
    end
    if self.isNavCompact then
        self.navToggleIcon:SetRotation(0)
    else
        self.navToggleIcon:SetRotation(math.rad(180))
    end
end

optionsMain.UpdateNavToggleLayout = function(self)
    if not self.navToggle or not self.menuScroll or not self.sidebar then
        return
    end

    self.navToggle:ClearAllPoints()
    self.navToggle:SetSize(NAV_TOGGLE_SIZE, NAV_TOGGLE_SIZE)
    self.navToggle:SetPoint('LEFT', self.sidebar, 'LEFT', -NAV_TOGGLE_SIZE / 2, 0)

    self.menuScroll:ClearAllPoints()
    self.menuScroll:SetPoint('TOPLEFT', NAV_PANEL_INSET, -NAV_PANEL_INSET)
    self.menuScroll:SetPoint('BOTTOMRIGHT', -NAV_PANEL_INSET, NAV_PANEL_INSET)

    self:UpdateNavToggleIcon()
end

optionsMain.SetPageTitle = function(self, title)
    if self.window then
        self.window:SetTitle(title or '')
    end
end

optionsMain.GetScale = function(self)
    local scale = ExalityUICharData and ExalityUICharData.optionsWindowScale
    if type(scale) ~= 'number' then
        return 1
    end
    return math.max(0.6, math.min(1.4, scale))
end

optionsMain.ApplyScale = function(self, scale)
    scale = scale or self:GetScale()
    if self.window then
        self.window:SetScale(scale)
    end
end

optionsMain.SetScale = function(self, scale)
    scale = math.max(0.6, math.min(1.4, scale or 1))
    ExalityUICharData.optionsWindowScale = scale
    data:Save()
    self:ApplyScale(scale)
end

optionsMain.SetNavCompact = function(self, compact, animate)
    if self.isNavCompact == compact then
        return
    end
    self.isNavCompact = compact

    ExalityUICharData.optionsNavCompact = compact
    data:Save()

    local fromWidth = compact and LAYOUT.expanded.nav or LAYOUT.compact.nav
    local toWidth = compact and LAYOUT.compact.nav or LAYOUT.expanded.nav

    optionsModuleSelector:HideFlyout()
    optionsModuleSelector:SetCompactMode(compact)

    local finish = function()
        self:ApplySidebarLayout(toWidth)
        self:UpdateNavToggleLayout()
        if compact then
            optionsModuleSelector:Relayout()
        end
        optionsModuleSelector:UpdateScroll()
    end

    if not animate or not self.sidebar then
        finish()
        return
    end

    local elapsed = 0
    self.sidebar:SetScript('OnUpdate', function(sidebar, dt)
        elapsed = elapsed + dt
        local t = math.min(elapsed / NAV_ANIM_DURATION, 1)
        local width = fromWidth + (toWidth - fromWidth) * t
        self:ApplySidebarLayout(width)
        if t >= 1 then
            sidebar:SetScript('OnUpdate', nil)
            finish()
        end
    end)
end

optionsMain.CreateSidebar = function(self, window)
    local sidebar = CreateFrame('Frame', nil, window)
    sidebar:SetFrameLevel(window:GetFrameLevel() + 1)

    local bg = sidebar:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(ASSETS.sidebarBg)
    bg:SetAllPoints()
    bg:SetTextureSliceMargins(16, 16, 16, 16)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    sidebar.bg = bg

    local menuScroll = EXFrames:GetFrame('smooth-scroll-frame'):Create(sidebar)
    local navToggle = CreateFrame('Button', nil, sidebar)
    navToggle:SetSize(NAV_TOGGLE_SIZE, NAV_TOGGLE_SIZE)
    navToggle:SetFrameLevel(sidebar:GetFrameLevel() + 5)

    local toggleBg = navToggle:CreateTexture(nil, 'BACKGROUND')
    toggleBg:SetTexture(ASSETS.btnBg)
    toggleBg:SetAllPoints()
    toggleBg:SetTextureSliceMargins(8, 8, 8, 8)
    toggleBg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    toggleBg:SetVertexColor(0.08, 0.08, 0.08, 1)

    local toggleIcon = navToggle:CreateTexture(nil, 'OVERLAY')
    toggleIcon:SetTexture(ASSETS.iconChevron)
    toggleIcon:SetSize(10, 10)
    toggleIcon:SetPoint('CENTER')
    self.navToggleIcon = toggleIcon

    navToggle:SetScript('OnClick', function()
        self:SetNavCompact(not self.isNavCompact, true)
    end)

    self.sidebar = sidebar
    self.menuScroll = menuScroll
    self.menuContainer = menuScroll.child
    self.navToggle = navToggle

    window:HookScript('OnHide', function()
        optionsModuleSelector:HideFlyout()
    end)

    return sidebar
end

optionsMain.CreateWindow = function(self)
    local isCompact = ExalityUICharData.optionsNavCompact or false
    local navWidth = isCompact and LAYOUT.compact.nav or LAYOUT.expanded.nav

    local window = EXFrames:GetFrame('window-frame'):Create({
        size = LAYOUT.window,
        title = optionsController:GetSelectedModuleName() or 'General',
        hideVersion = true,
        onClose = function()
            if not editor:IsEditorEnabled() then
                EXUI:GetModule('uf-core'):UnforceAll()
            end
            optionsModuleSelector:HideFlyout()
        end,
        headerTexture = ASSETS.topBar,
        backgroundTexture = ASSETS.mainBg,
        closeIcon = ASSETS.iconClose,
        headerInset = 5,
        headerButtonGap = 5,
    })

    self.isNavCompact = isCompact
    self.window = window
    window:SetClipsChildren(false)

    window:AddHeaderButton({
        onClick = function()
            profiles:Show()
        end,
        icon = { texture = ASSETS.iconProfiles, width = 16, height = 16 },
        color = { 0.12, 0.12, 0.12, 1 },
    })
    window:AddHeaderButton({
        onClick = function()
            editor:EnableEditor()
            self.window:HideWindow()
        end,
        icon = { texture = ASSETS.iconEditMode, width = 16, height = 16 },
        color = { 0.12, 0.12, 0.12, 1 },
    })

    self:CreateSidebar(window)
    self:ApplySidebarLayout(navWidth)
    self:UpdateNavToggleLayout()
    self:ApplyScale()

    optionsModuleSelector:Create(self.menuScroll, window)
    if isCompact then
        optionsModuleSelector:SetCompactMode(true)
    end

    local configPanel = panel:Create(window.container)
    configPanel:SetAllPoints()
    configPanel:SetSubtleChrome()
    configPanel:Show()
    optionsFields:Create(configPanel)
    self.configPanel = configPanel

    editor.onExitEditMode = function()
        optionsMain:Show()
        optionsController:SetSelectedModule(optionsController:GetSelectedModuleName())
    end

    optionsController:Observe('selectedModule', function(value)
        optionsMain:SetPageTitle(value)
    end)

    return window
end

optionsMain.Show = function(self)
    if InCombatLockdown() then
        EXUI.utils.printOut('You cannot open options during combat.')
        return
    end
    if not self.window then
        self.window = self:CreateWindow()
    end
    self:SetPageTitle(optionsController:GetSelectedModuleName())
    self.window:ShowWindow()
    optionsFields:RefreshFields()
    C_Timer.After(0, function()
        if self.window and self.window:IsShown() then
            if self.isNavCompact then
                optionsModuleSelector:Relayout()
            end
            optionsModuleSelector:UpdateScroll()
            optionsFields:RefreshFields()
        end
    end)
end
