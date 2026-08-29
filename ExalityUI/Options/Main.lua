---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIData
local data = EXUI:GetModule('data')

---@class ExalityFramesPanelFrame
local panel = EXFrames:GetFrame('panel-frame')

---@class ExalityFramesButton
local button = EXFrames:GetFrame('button')

---@class EXUIOptionsModuleSelector
local optionsModuleSelector = EXUI:GetModule('options-module-selector')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIEditor
local editor = EXUI:GetModule('editor')

---@class EXUIProfiles
local profiles = EXUI:GetModule('profiles')

----------------

---@class EXUIOptionsMain
local optionsMain = EXUI:GetModule('options-main')

local LAYOUT = {
    expanded = { window = { 980, 755 }, nav = 160, info = 80 },
    compact = { window = { 856, 755 }, nav = 36, info = 0 },
}

local NAV_ANIM_DURATION = 0.2
local NAV_PANEL_INSET = 5
local NAV_TOGGLE_HEIGHT = 26
local DISCORD_LINK = 'discord.gg/F8bhZUvQfz'

local menuItemFrame = EXFrames:GetFrame('menu-item')

optionsMain.window = nil
optionsMain.profileSwitcher = nil
optionsMain.isNavCompact = false
optionsMain.LAYOUT = LAYOUT

optionsMain.ApplyPanelLayout = function(self, nav, info)
    self.modulesPanel:ClearAllPoints()
    self.modulesPanel:SetPoint('TOPLEFT', self.window.container, 'TOPLEFT')
    self.modulesPanel:SetPoint('BOTTOMRIGHT', self.window.container, 'BOTTOMLEFT', nav, info)

    self.infoPanel:ClearAllPoints()
    self.infoPanel:SetPoint('TOPLEFT', self.modulesPanel, 'BOTTOMLEFT', 0, -5)
    self.infoPanel:SetPoint('BOTTOMRIGHT', self.window.container, 'BOTTOMLEFT', nav, 0)
end

optionsMain.SetInfoPanelCompact = function(self, compact)
    self.infoPanel:SetShown(not compact)
end

optionsMain.UpdateNavToggleIcon = function(self)
    if (not self.navToggle) then
        return
    end
    local icon = self.navToggle.main.icon
    if (self.isNavCompact) then
        icon:SetRotation(math.rad(90))
    else
        icon:SetRotation(math.rad(-90))
    end
end

optionsMain.UpdateNavToggleLayout = function(self)
    if (not self.navToggle or not self.menuScroll or not self.modulesPanel) then
        return
    end

    local chevron = EXFrames.assets.textures.icon.chevronDown
    local toggleHeight = NAV_TOGGLE_HEIGHT

    self.navToggle:SetCompact(true)
    self.navToggle:SetIcon(chevron)
    self.navToggle.main.icon:SetSize(10, 10)
    self.navToggle.main.icon:ClearAllPoints()
    self.navToggle.main.icon:SetPoint('CENTER')
    self.navToggle:ClearAllPoints()

    if (self.isNavCompact) then
        self.navToggle:SetText('Expand navigation')
        self.navToggle:SetSize(toggleHeight, toggleHeight)
        self.navToggle:SetPoint('BOTTOM', self.modulesPanel, 'BOTTOM', 0, NAV_PANEL_INSET)
    else
        self.navToggle.main.text:SetText('')
        self.navToggle.tooltipText = nil
        self.navToggle:SetHeight(toggleHeight)
        self.navToggle:SetPoint('BOTTOMLEFT', self.modulesPanel, 'BOTTOMLEFT', NAV_PANEL_INSET, NAV_PANEL_INSET)
        self.navToggle:SetPoint('BOTTOMRIGHT', self.modulesPanel, 'BOTTOMRIGHT', -NAV_PANEL_INSET, NAV_PANEL_INSET)
    end

    self.menuScroll:ClearAllPoints()
    self.menuScroll:SetPoint('TOPLEFT', NAV_PANEL_INSET, -NAV_PANEL_INSET)
    self.menuScroll:SetPoint('TOPRIGHT', -NAV_PANEL_INSET, -NAV_PANEL_INSET)
    self.menuScroll:SetPoint('BOTTOM', self.modulesPanel, 'BOTTOM', 0, toggleHeight + NAV_PANEL_INSET)

    self:UpdateNavToggleIcon()
end

optionsMain.SetNavCompact = function(self, compact, animate)
    if (self.isNavCompact == compact) then
        return
    end
    self.isNavCompact = compact

    ExalityUICharData.optionsNavCompact = compact
    data:Save()

    local layout = compact and LAYOUT.compact or LAYOUT.expanded
    local fromLayout = compact and LAYOUT.expanded or LAYOUT.compact
    local targetW, targetH = layout.window[1], layout.window[2]
    local fromNav, fromInfo = fromLayout.nav, fromLayout.info
    local toNav, toInfo = layout.nav, layout.info

    optionsModuleSelector:HideFlyout()
    optionsModuleSelector:SetCompactMode(compact)
    self:SetInfoPanelCompact(compact)

    local applyPanels = function(nav, info)
        self:ApplyPanelLayout(nav, info)
    end

    local finish = function()
        self.window:SetSize(targetW, targetH)
        applyPanels(toNav, toInfo)
        self:UpdateNavToggleLayout()
        self.window.resizeBtn:Init(self.window, targetW, targetH, targetW, targetH + 1000)
        if (compact) then
            optionsModuleSelector:Relayout()
        end
        optionsModuleSelector:UpdateScroll()
        optionsFields:RefreshFields()
    end

    if (not animate) then
        finish()
        return
    end

    local startW = self.window:GetWidth()
    local startH = self.window:GetHeight()

    EXFrames.utils.animation.lerpSize(self.window, NAV_ANIM_DURATION, targetW, targetH, finish, function(_, w, h)
        local t = (targetW ~= startW) and ((w - startW) / (targetW - startW)) or 1
        local nav = fromNav + (toNav - fromNav) * t
        local info = fromInfo + (toInfo - fromInfo) * t
        applyPanels(nav, info)
    end)
end

optionsMain.CreateWindow = function(self)
    local isCompact = ExalityUICharData.optionsNavCompact or false
    local layout = isCompact and LAYOUT.compact or LAYOUT.expanded

    local window = EXFrames:GetFrame('window-frame'):Create({
        size = layout.window,
        title = '',
        onClose = function()
            if not editor:IsEditorEnabled() then
                EXUI:GetModule('uf-core'):UnforceAll()
            end
            optionsModuleSelector:HideFlyout()
        end
    })

    self.isNavCompact = isCompact

    -- Profiles (gear opens Profiles window)
    local profileSettingsButton = button:Create({
        text = '',
        onClick = function()
            profiles:Show()
        end,
        color = { 0.19, 0.19, 0.19, 1 },
        size = { 28, 28 },
        icon = {
            texture = EXUI.const.textures.frame.settingsIcon,
            width = 18,
            height = 18
        }
    }, window)
    profileSettingsButton:SetPoint('TOPRIGHT', window.close, 'TOPLEFT', -5, 0)

    local modulesPanel = panel:Create()
    modulesPanel:SetParent(window.container)
    modulesPanel:Show()

    local menuScroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    menuScroll:SetParent(modulesPanel)
    local menuContainer = menuScroll.child

    local infoPanel = panel:Create()
    infoPanel:SetParent(window.container)
    infoPanel:Show()

    local discordInput = EXFrames:GetFrame('edit-box-input'):Create({
        label = 'Discord',
        initial = DISCORD_LINK,
        onChange = function() end
    }, infoPanel)
    discordInput:SetPoint('TOPLEFT', 5, -5)
    discordInput:SetPoint('TOPRIGHT', -5, -5)
    discordInput:SetHeight(35)

    local changelogBtn = button:Create({
        text = 'Changelog',
        onClick = function()
            EXUI:GetModule('changelog'):Show()
        end,
        color = { 0.2, 0.2, 0.2, 1 }
    }, infoPanel)
    changelogBtn:SetPoint('TOPLEFT', discordInput, 'BOTTOMLEFT', 0, -5)
    changelogBtn:SetPoint('BOTTOMRIGHT', infoPanel, 'BOTTOMRIGHT', -5, 5)

    local navToggle = menuItemFrame:Create(modulesPanel)
    navToggle:SetOnClick(function()
        self:SetNavCompact(not self.isNavCompact, true)
    end)

    self.window = window
    self.modulesPanel = modulesPanel
    self.menuScroll = menuScroll
    self.menuContainer = menuContainer
    self.infoPanel = infoPanel
    self.discordInput = discordInput
    self.changelogBtn = changelogBtn
    self.navToggle = navToggle

    self:ApplyPanelLayout(layout.nav, layout.info)
    self:SetInfoPanelCompact(isCompact)
    self:UpdateNavToggleLayout()

    optionsModuleSelector:Create(menuScroll, window.container)

    local configPanel = panel:Create()
    configPanel:SetParent(window.container)
    configPanel:SetPoint('TOPLEFT', modulesPanel, 'TOPRIGHT', 5, 0)
    configPanel:SetPoint('BOTTOMRIGHT')
    configPanel:Show()
    configPanel:SetFrameLevel(navToggle:GetFrameLevel() - 1)
    navToggle:SetFrameLevel(configPanel:GetFrameLevel() + 5)
    optionsFields:Create(configPanel)
    self.configPanel = configPanel

    if (isCompact) then
        optionsModuleSelector:SetCompactMode(true)
    end

    editor.onExitEditMode = function()
        optionsMain:Show()
        local optionsController = EXUI:GetModule('options-controller')
        optionsController:SetSelectedModule(optionsController:GetSelectedModuleName())
    end

    local editModeBtn = button:Create({
        text = 'Edit Mode',
        onClick = function()
            editor:EnableEditor()
            self.window:HideWindow()
        end,
        size = { 86, 28 },
        color = EXUI.const.theme.faded
    }, configPanel)
    editModeBtn:SetPoint('RIGHT', profileSettingsButton, 'LEFT', -5, 0)

    return window
end

optionsMain.Show = function(self)
    if InCombatLockdown() then
        EXUI.utils.printOut('You cannot open options during combat.')
        return
    end
    if (not self.window) then
        self.window = self:CreateWindow()
    end
    self.window:ShowWindow()
    optionsFields:RefreshFields()
    C_Timer.After(0, function()
        if (self.window and self.window:IsShown()) then
            if (self.isNavCompact) then
                optionsModuleSelector:Relayout()
            end
            optionsModuleSelector:UpdateScroll()
            optionsFields:RefreshFields()
        end
    end)
end
