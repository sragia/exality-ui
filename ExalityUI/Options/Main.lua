---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIData
local data = EXUI:GetModule('data')

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

---@class EXUIChangelog
local changelog = EXUI:GetModule('changelog')

---@class EXUICopyLinkDialog
local copyLinkDialog = EXUI:GetModule('copy-link-dialog')

----------------

---@class EXUIOptionsMain
local optionsMain = EXUI:GetModule('options-main')

local ASSETS = {
    topBar = [[Interface/Addons/ExalityUI/Options/Assets/top-bar.png]],
    mainBg = [[Interface/Addons/ExalityUI/Options/Assets/main-bg_2.png]],
    sidebarBg = [[Interface/Addons/ExalityUI/Options/Assets/sidebar-bg.png]],
    expandBg = [[Interface/Addons/ExalityUI/Options/Assets/expand-bg.png]],
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
local NAV_TOGGLE_WIDTH = 17
local NAV_TOGGLE_HEIGHT = 71
local NAV_TOGGLE_ICON_SIZE = 14
local SIDEBAR_GAP = 0
local SIDEBAR_VERTICAL_INSET = 30
local DISCORD_INVITE_URL = 'https://discord.gg/F8bhZUvQfz'

local HEADER_ICON_SIZE = 18

local HEADER_BUTTON = {
    close = { 0.34, 0.08, 0.08, 1 },
    profiles = {
        color = { 0.11, 0.13, 0.20, 1 },
        hover = { 0.15, 0.18, 0.28, 1 },
    },
    editMode = {
        color = { 0.20, 0.13, 0.09, 1 },
        hover = { 0.28, 0.18, 0.11, 1 },
    },
}

optionsMain.window = nil
optionsMain.sidebar = nil
optionsMain.isNavCompact = false
optionsMain.LAYOUT = LAYOUT
optionsMain.ASSETS = ASSETS

optionsMain.ApplyHeaderButtonChrome = function(self, window)
    if not window or not window.close or not window.close.bg then
        return
    end
    local closeBg = window.close.bg
    if window.close.icon then
        window.close.icon:SetSize(HEADER_ICON_SIZE, HEADER_ICON_SIZE)
    end
    closeBg:SetVertexColor(unpack(HEADER_BUTTON.close))
    window.close:SetScript('OnEnter', function()
        closeBg:SetVertexColor(unpack(EXFrames.Theme.dangerHover))
    end)
    window.close:SetScript('OnLeave', function()
        closeBg:SetVertexColor(unpack(HEADER_BUTTON.close))
    end)
end

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
        self.navToggleIcon:SetRotation(math.rad(180))
    else
        self.navToggleIcon:SetRotation(0)
    end
end

optionsMain.UpdateNavToggleLayout = function(self)
    if not self.navToggle or not self.menuScroll or not self.sidebar then
        return
    end

    self.navToggle:ClearAllPoints()
    self.navToggle:SetSize(NAV_TOGGLE_WIDTH, NAV_TOGGLE_HEIGHT)
    self.navToggle:SetPoint('RIGHT', self.sidebar, 'LEFT', 0, 0)

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

    local finish = function()
        if self.menuScroll then
            self.menuScroll:SetScrollbarSuppressed(false)
        end
        self:ApplySidebarLayout(toWidth)
        self:UpdateNavToggleLayout()
        if compact then
            optionsModuleSelector:Relayout()
        end
        optionsModuleSelector:UpdateScroll()
    end

    if not animate or not self.sidebar then
        optionsModuleSelector:SetCompactMode(compact)
        finish()
        return
    end

    optionsModuleSelector:SetCompactMode(compact)
    if self.menuScroll then
        self.menuScroll:SetScrollbarSuppressed(true)
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
    bg:SetVertexColor(1, 1, 1, 1)
    bg:SetTexCoord(0, 1, 0, 1)
    bg:SetTextureSliceMargins(16, 16, 16, 16)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetAllPoints()
    sidebar.bg = bg

    local menuScroll = EXFrames:GetFrame('smooth-scroll-frame'):Create(sidebar)
    local navToggle = CreateFrame('Button', nil, sidebar)
    navToggle:SetSize(NAV_TOGGLE_WIDTH, NAV_TOGGLE_HEIGHT)
    navToggle:SetFrameLevel(sidebar:GetFrameLevel() + 5)

    local toggleBg = navToggle:CreateTexture(nil, 'BACKGROUND')
    toggleBg:SetTexture(ASSETS.expandBg)
    toggleBg:SetAllPoints()

    local toggleIcon = navToggle:CreateTexture(nil, 'OVERLAY')
    toggleIcon:SetTexture(ASSETS.iconChevron)
    toggleIcon:SetSize(NAV_TOGGLE_ICON_SIZE, NAV_TOGGLE_ICON_SIZE)
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
        versionBottom = true,
        onVersionClick = function()
            changelog:Show()
        end,
        discordLink = {
            label = 'Discord',
            url = DISCORD_INVITE_URL,
            onClick = function(url)
                copyLinkDialog:Show(url, 'Discord')
            end,
        },
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
        icon = { texture = ASSETS.iconProfiles, width = HEADER_ICON_SIZE, height = HEADER_ICON_SIZE },
        color = HEADER_BUTTON.profiles.color,
        hoverColor = HEADER_BUTTON.profiles.hover,
    })
    window:AddHeaderButton({
        onClick = function()
            editor:EnableEditor()
            self.window:HideWindow()
        end,
        icon = { texture = ASSETS.iconEditMode, width = HEADER_ICON_SIZE, height = HEADER_ICON_SIZE },
        color = HEADER_BUTTON.editMode.color,
        hoverColor = HEADER_BUTTON.editMode.hover,
    })

    self:ApplyHeaderButtonChrome(window)

    self:CreateSidebar(window)
    self:ApplySidebarLayout(navWidth)
    self:UpdateNavToggleLayout()
    self:ApplyScale()

    optionsModuleSelector:Create(self.menuScroll, window)
    if isCompact then
        optionsModuleSelector:SetCompactMode(true)
    end

    optionsFields:Create(window.container)

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
