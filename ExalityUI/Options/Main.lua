---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIData
local data = EXUI:GetModule('data')

---@class ExalityFramesPanelFrame
local panel = EXFrames:GetFrame('panel-frame')

---@class ExalityFramesSlimDropdownInput
local slimDropdown = EXFrames:GetFrame('slim-dropdown-input')

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

optionsMain.window = nil
optionsMain.profileSwitcher = nil
optionsMain.editModeDialog = nil

optionsMain.CreateWindow = function(self)
    local window = EXFrames:GetFrame('window-frame'):Create({
        size = { 1300, 900 },
        title = 'ExalityUI',
        onClose = function()
            EXUI:GetModule('uf-core'):UnforceAll()
        end
    })

    -- Profile Selector
    local profilePanel = panel:Create()
    profilePanel:SetWidth(236)
    profilePanel:SetParent(window)
    profilePanel:SetPoint('TOPRIGHT', window.close, 'TOPLEFT', -5, 0)
    profilePanel:SetPoint('BOTTOMRIGHT', window.close, 'BOTTOMLEFT', -5, 0)
    profilePanel:Show()

    local profileLabel = profilePanel:CreateFontString(nil, 'OVERLAY')
    profileLabel:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    profileLabel:SetPoint('LEFT', 5, 0)
    profileLabel:SetWidth(0)
    profileLabel:SetText('Profile:')
    profileLabel:Show()

    local profileSelector = slimDropdown:Create({
        initial = data:GetCurrentProfile(),
        onChange = function(value)
            data:SetCurrentProfile(value)
            ReloadUI()
        end,
        height = 25,
        width = 150,
        options = data:GetAllProfiles()
    }, profilePanel)
    profileSelector:SetPoint('LEFT', profileLabel, 'RIGHT', 5, 0)

    local profileSettingsButton = button:Create({
        text = '',
        onClick = function()
            profiles:Show()
        end,
        color = { 0.19, 0.19, 0.19, 1 },
        size = { 25, 25 },
        icon = {
            texture = EXUI.const.textures.frame.settingsIcon,
            width = 18,
            height = 18
        }
    }, profilePanel)
    profileSettingsButton:SetPoint('LEFT', profileSelector, 'RIGHT', 5, 0)

    local modulesPanel = panel:Create()
    modulesPanel:SetParent(window.container)
    modulesPanel:SetPoint('TOPLEFT')
    modulesPanel:SetPoint('BOTTOMRIGHT', window.container, 'BOTTOMLEFT', 200, 80)
    modulesPanel:Show()

    local infoPanel = panel:Create()
    infoPanel:SetParent(window.container)
    infoPanel:SetPoint('TOPLEFT', modulesPanel, 'BOTTOMLEFT', 0, -5)
    infoPanel:SetPoint('BOTTOMRIGHT', modulesPanel, 'BOTTOMRIGHT', 0, 0)
    infoPanel:SetPoint('BOTTOM')
    infoPanel:Show()

    local discordInput = EXFrames:GetFrame('edit-box-input'):Create({
        label = 'Discord',
        initial = 'discord.gg/F8bhZUvQfz',
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


    optionsModuleSelector:Create(modulesPanel)

    local configPanel = panel:Create()
    configPanel:SetParent(window.container)
    configPanel:SetPoint('TOPLEFT', modulesPanel, 'TOPRIGHT', 10, 0)
    configPanel:SetPoint('BOTTOMRIGHT')
    configPanel:Show()
    optionsFields:Create(configPanel)

    self.editModeDialog = EXFrames:GetFrame('dialog-frame'):Create()
    self.editModeDialog:SetText(
        'You are now in edit mode. You can now edit the UI by dragging and dropping elements. Exit edit mode to save your changes.')
    self.editModeDialog:SetButtons({
        {
            text = 'Exit Edit Mode',
            onClick = function()
                editor:DisableEditor()
                self.editModeDialog:HideDialog()
                self:Show()
                local optionsController = EXUI:GetModule('options-controller')
                optionsController:SetSelectedModule(optionsController:GetSelectedModuleName())
            end,
            color = { 158 / 255, 0, 32 / 255, 1 }
        }
    })

    local editModeBtn = button:Create({
        text = 'Edit Mode',
        onClick = function()
            editor:EnableEditor()
            self.editModeDialog:ShowDialog()
            self.window:HideWindow()
        end,
        size = { 100, 25 },
        color = { 219 / 255, 73 / 255, 0, 1 }
    }, configPanel)
    editModeBtn:SetPoint('RIGHT', profilePanel, 'LEFT', -5, 0)

    return window
end

optionsMain.Show = function(self)
    if (not self.window) then
        self.window = self:CreateWindow()
    end
    self.window:ShowWindow()
end
