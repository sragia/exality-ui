---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIPanelFrame
local panel = EXUI:GetModule('panel-frame')

---@class EXUISlimDropdownInput
local slimDropdown = EXUI:GetModule('slim-dropdown-input')

---@class EXUIButton
local button = EXUI:GetModule('button')

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
    local window = EXUI:GetModule('window-frame'):Create({
        size = {1300, 900},
        title = 'ExalityUI'
    })

    -- Profile Selector
    local profilePanel = EXUI:GetModule('panel-frame'):Create()
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
        color = {0.19, 0.19, 0.19, 1},
        size = {25, 25},
    }, profilePanel)
    local icon = profileSettingsButton:CreateTexture(nil, 'BACKGROUND')
    icon:SetTexture(EXUI.const.textures.frame.settingsIcon)
    icon:SetSize(18, 18)
    icon:SetPoint('CENTER', profileSettingsButton, 'CENTER')
    profileSettingsButton:SetPoint('LEFT', profileSelector, 'RIGHT', 5, 0)

    local modulesPanel = EXUI:GetModule('panel-frame'):Create()
    modulesPanel:SetParent(window.container)
    modulesPanel:SetPoint('TOPLEFT')
    modulesPanel:SetPoint('BOTTOMRIGHT', window.container, 'BOTTOMLEFT', 200, 0)
    modulesPanel:Show()

    optionsModuleSelector:Create(modulesPanel)

    local configPanel = EXUI:GetModule('panel-frame'):Create()
    configPanel:SetParent(window.container)
    configPanel:SetPoint('TOPLEFT', modulesPanel, 'TOPRIGHT', 10, 0)
    configPanel:SetPoint('BOTTOMRIGHT')
    configPanel:Show()
    optionsFields:Create(configPanel)

    self.editModeDialog = EXUI:GetModule('dialog-frame'):Create()
    self.editModeDialog:SetText('You are now in edit mode. You can now edit the UI by dragging and dropping elements. Exit edit mode to save your changes.')
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
            color = {158/255, 0, 32/255, 1}
        }
    })
    
    local editModeBtn = button:Create({
        text = 'Edit Mode',
        onClick = function()
            editor:EnableEditor()
            self.editModeDialog:ShowDialog()
            self.window:HideWindow()
        end,
        size = {100, 25},
        color = {219/255, 73/255, 0 , 1}
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