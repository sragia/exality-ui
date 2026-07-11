---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesPanelFrame
local panel = EXFrames:GetFrame('panel-frame')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIProfiles
local profiles = EXUI:GetModule('profiles')

local WINDOW_SIZE = { 980, 660 }
local COLUMN_GAP = 10
local PANEL_INSET = 10

profiles.window = nil
profiles.copyFromCurrent = false
profiles.newProfileName = ''
profiles.importInput = nil
profiles.exportInput = nil
profiles.profileSelector = nil
profiles.profileLabel = nil
profiles.exportModules = {}
profiles.moduleCheckboxes = {}
profiles.selectAllCheckbox = nil
profiles.cachedExportModules = nil

profiles.Init = function(self)
end

profiles.SetCheckboxValue = function(self, cb, value)
    if not cb or not cb.SetValue then
        return
    end
    local onChange = cb.onChange
    cb.onChange = nil
    cb:SetValue('value', value and true or false)
    cb.onChange = onChange
end

profiles.CreateImportInput = function(self, container)
    local input = CreateFrame('EditBox', nil, container, 'BackdropTemplate')
    input:SetMultiLine(true)
    input:SetClipsChildren(true)
    input:SetAutoFocus(false)
    input:SetBackdrop(EXUI.const.backdrop.DEFAULT)
    input:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    input:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    input:SetFont(EXUI.const.fonts.DEFAULT, 8, 'OUTLINE')
    input:SetTextInsets(10, 10, 10, 10)
    input:SetScript('OnEscapePressed', function(editBox) editBox:ClearFocus() end)

    return input
end

profiles.CreateSectionTitle = function(self, parent, text)
    local title = parent:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 16, 'OUTLINE')
    title:SetTextColor(1, 1, 1, 1)
    title:SetText(text)
    title:SetPoint('TOPLEFT', parent, 'TOPLEFT', PANEL_INSET, -PANEL_INSET)
    return title
end

profiles.GetExportModuleList = function(self)
    if not self.cachedExportModules then
        self.cachedExportModules = optionsController:GetProfileExportModules()
    end
    return self.cachedExportModules
end

profiles.InitExportModuleState = function(self)
    self.exportModules = {}
    for _, mod in ipairs(self:GetExportModuleList()) do
        self.exportModules[mod.id] = true
    end
end

profiles.IsAllModulesSelected = function(self)
    for _, mod in ipairs(self:GetExportModuleList()) do
        if not self.exportModules[mod.id] then
            return false
        end
    end
    return true
end

profiles.GetSelectedExportModules = function(self)
    local selected = {}
    for _, mod in ipairs(self:GetExportModuleList()) do
        if self.exportModules[mod.id] then
            table.insert(selected, mod)
        end
    end
    return selected
end

profiles.SyncModuleCheckboxStates = function(self)
    for _, mod in ipairs(self:GetExportModuleList()) do
        self:SetCheckboxValue(self.moduleCheckboxes[mod.id], self.exportModules[mod.id])
    end
    self:SetCheckboxValue(self.selectAllCheckbox, self:IsAllModulesSelected())
end

profiles.SetAllModulesChecked = function(self, checked)
    for _, mod in ipairs(self:GetExportModuleList()) do
        self.exportModules[mod.id] = checked
    end
    self:SyncModuleCheckboxStates()
end

profiles.RefreshProfileSelector = function(self)
    if not self.profileSelectorContainer then
        return
    end

    if self.profileSelector then
        self.profileSelector:Hide()
        self.profileSelector = nil
    end

    local dropdown = EXFrames:GetFrame('dropdown')
    self.profileSelector = dropdown:Create({
        initial = data:GetCurrentProfile(),
        onChange = function(value)
            data:SetCurrentProfile(value)
            ReloadUI()
        end,
        options = data:GetAllProfiles(),
        label = 'Profile',
        height = 40,
    }, self.profileSelectorContainer)
    self.profileSelector:SetPoint('TOPLEFT')
    self.profileSelector:SetPoint('TOPRIGHT')
end

profiles.SetupExportCheckboxes = function(self, container)
    self.moduleCheckboxes = {}

    local selectAll = EXFrames:GetFrame('checkbox'):Create()
    selectAll:SetParent(container)
    selectAll:SetOptionData({
        label = 'Select all',
        name = 'select-all',
        width = 100,
        currentValue = function()
            return self:IsAllModulesSelected()
        end,
        onChange = function(value)
            self:SetAllModulesChecked(value)
        end,
    })
    self.selectAllCheckbox = selectAll
    selectAll:SetPoint('TOPLEFT', container, 'TOPLEFT', 0, 0)
    selectAll:SetPoint('TOPRIGHT', container, 'TOPRIGHT', 0, 0)

    local gridItems = {}
    for _, mod in ipairs(self:GetExportModuleList()) do
        local cb = EXFrames:GetFrame('checkbox'):Create()
        cb:SetParent(container)
        cb:SetOptionData({
            label = mod.name,
            name = mod.id,
            width = 50,
            currentValue = function()
                return self.exportModules[mod.id]
            end,
            onChange = function(value)
                self.exportModules[mod.id] = value
                self:SetCheckboxValue(self.selectAllCheckbox, self:IsAllModulesSelected())
            end,
        })
        self.moduleCheckboxes[mod.id] = cb
        table.insert(gridItems, cb)
    end

    local gridContainer = CreateFrame('Frame', nil, container)
    gridContainer:SetPoint('TOPLEFT', selectAll, 'BOTTOMLEFT', 0, -8)
    gridContainer:SetPoint('TOPRIGHT', selectAll, 'BOTTOMRIGHT', 0, -8)
    gridContainer:SetPoint('BOTTOMRIGHT', container, 'BOTTOMRIGHT')

    EXUI.utils.organizeFramesInGrid('profiles-export-modules', gridItems, 6, gridContainer, 0, 0)
end

profiles.SetupWindow = function(self)
    local window = EXFrames:GetFrame('window-frame'):Create({
        size = WINDOW_SIZE,
        title = 'Profiles'
    })

    local leftColumn = CreateFrame('Frame', nil, window.container)
    leftColumn:SetPoint('TOPLEFT', window.container, 'TOPLEFT', COLUMN_GAP, -COLUMN_GAP)
    leftColumn:SetPoint('BOTTOMLEFT', window.container, 'BOTTOMLEFT', COLUMN_GAP, COLUMN_GAP)
    leftColumn:SetPoint('RIGHT', window.container, 'CENTER', -COLUMN_GAP / 2, 0)

    local rightColumn = CreateFrame('Frame', nil, window.container)
    rightColumn:SetPoint('TOPRIGHT', window.container, 'TOPRIGHT', -COLUMN_GAP, -COLUMN_GAP)
    rightColumn:SetPoint('BOTTOMRIGHT', window.container, 'BOTTOMRIGHT', -COLUMN_GAP, COLUMN_GAP)
    rightColumn:SetPoint('LEFT', window.container, 'CENTER', COLUMN_GAP / 2, 0)

    -- Left column: profile + create
    local profilePanel = panel:Create()
    profilePanel:SetParent(leftColumn)
    profilePanel:SetPoint('TOPLEFT')
    profilePanel:SetPoint('TOPRIGHT')
    profilePanel:SetHeight(225)

    self:CreateSectionTitle(profilePanel, 'Active Profile')

    local profileLabel = profilePanel:CreateFontString(nil, 'OVERLAY')
    profileLabel:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    profileLabel:SetTextColor(0.85, 0.85, 0.85, 1)
    profileLabel:SetPoint('TOPLEFT', profilePanel, 'TOPLEFT', PANEL_INSET, -36)
    profileLabel:SetPoint('TOPRIGHT', profilePanel, 'TOPRIGHT', -PANEL_INSET, -36)
    self.profileLabel = profileLabel

    local profileSelectorContainer = CreateFrame('Frame', nil, profilePanel)
    profileSelectorContainer:SetHeight(40)
    profileSelectorContainer:SetPoint('TOPLEFT', profileLabel, 'BOTTOMLEFT', 0, -8)
    profileSelectorContainer:SetPoint('TOPRIGHT', profileLabel, 'BOTTOMRIGHT', 0, -8)
    self.profileSelectorContainer = profileSelectorContainer

    local createTitle = profilePanel:CreateFontString(nil, 'OVERLAY')
    createTitle:SetFont(EXUI.const.fonts.DEFAULT, 16, 'OUTLINE')
    createTitle:SetTextColor(1, 1, 1, 1)
    createTitle:SetText('Create New Profile')
    createTitle:SetPoint('TOPLEFT', profileSelectorContainer, 'BOTTOMLEFT', 0, -16)
    createTitle:SetPoint('TOPRIGHT', profileSelectorContainer, 'BOTTOMRIGHT', 0, -16)

    local createInput = EXFrames:GetFrame('edit-box-input'):Create({
        label = 'Profile Name',
        onChange = function(value)
            self.newProfileName = value
        end
    })
    createInput:SetHeight(40)
    createInput:SetParent(profilePanel)
    createInput:SetPoint('TOPLEFT', createTitle, 'BOTTOMLEFT', 0, -8)
    createInput:SetPoint('TOPRIGHT', createTitle, 'BOTTOMRIGHT', 0, -8)

    local createButton = EXFrames:GetFrame('button'):Create({
        text = 'Create',
        onClick = function()
            if (self.newProfileName and self.newProfileName ~= '') then
                data:CreateProfile(self.newProfileName, self.copyFromCurrent)
                data:SetCurrentProfile(self.newProfileName)
                ReloadUI()
            end
        end,
        color = { 0, 130 / 255, 9 / 255, 1 },
        size = { 80, 27 }
    })
    createButton:SetParent(profilePanel)
    createButton:SetPoint('TOPLEFT', createInput, 'BOTTOMLEFT', 0, -10)

    local shouldCopyToggle = EXFrames:GetFrame('toggle'):Create({
        text = 'Duplicate from current profile',
        value = false
    })
    shouldCopyToggle:Observe('value', function(value)
        self.copyFromCurrent = value
    end)
    shouldCopyToggle:SetParent(profilePanel)
    shouldCopyToggle:SetPoint('LEFT', createButton, 'RIGHT', 15, 0)
    shouldCopyToggle:SetPoint('TOP', createButton, 'TOP', 0, 0)

    -- Left column: import
    local importPanel = panel:Create()
    importPanel:SetParent(leftColumn)
    importPanel:SetPoint('TOPLEFT', profilePanel, 'BOTTOMLEFT', 0, -COLUMN_GAP)
    importPanel:SetPoint('BOTTOMRIGHT')

    self:CreateSectionTitle(importPanel, 'Import Profile')

    local importButton = EXFrames:GetFrame('button'):Create({
        text = 'Import',
        onClick = function()
            self:OnImport()
        end,
        color = { 0, 130 / 255, 9 / 255, 1 },
    })
    importButton:SetParent(importPanel)
    importButton:SetHeight(27)
    importButton:SetPoint('BOTTOMLEFT', importPanel, 'BOTTOMLEFT', PANEL_INSET, PANEL_INSET)
    importButton:SetPoint('BOTTOMRIGHT', importPanel, 'BOTTOMRIGHT', -PANEL_INSET, PANEL_INSET)

    local importInput = self:CreateImportInput(importPanel)
    importInput:SetPoint('TOPLEFT', importPanel, 'TOPLEFT', PANEL_INSET, -40)
    importInput:SetPoint('TOPRIGHT', importPanel, 'TOPRIGHT', -PANEL_INSET, -40)
    importInput:SetPoint('BOTTOMLEFT', importButton, 'TOPLEFT', 0, 8)
    importInput:SetPoint('BOTTOMRIGHT', importButton, 'TOPRIGHT', 0, 8)
    self.importInput = importInput

    -- Right column: export
    local exportPanel = panel:Create()
    exportPanel:SetParent(rightColumn)
    exportPanel:SetAllPoints()

    self:CreateSectionTitle(exportPanel, 'Export Profile')

    local exportModulesLabel = exportPanel:CreateFontString(nil, 'OVERLAY')
    exportModulesLabel:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    exportModulesLabel:SetTextColor(0.75, 0.75, 0.75, 1)
    exportModulesLabel:SetText('Select modules to include:')
    exportModulesLabel:SetPoint('TOPLEFT', exportPanel, 'TOPLEFT', PANEL_INSET, -36)
    exportModulesLabel:SetPoint('TOPRIGHT', exportPanel, 'TOPRIGHT', -PANEL_INSET, -36)

    local exportBottom = CreateFrame('Frame', nil, exportPanel)
    exportBottom:SetPoint('BOTTOMLEFT', exportPanel, 'BOTTOMLEFT', PANEL_INSET, PANEL_INSET)
    exportBottom:SetPoint('BOTTOMRIGHT', exportPanel, 'BOTTOMRIGHT', -PANEL_INSET, PANEL_INSET)
    exportBottom:SetHeight(300)

    local exportButton = EXFrames:GetFrame('button'):Create({
        text = 'Export',
        onClick = function()
            self:GenerateExportString()
        end,
        color = { 237 / 255, 138 / 255, 0, 1 },
    })
    exportButton:SetParent(exportBottom)
    exportButton:SetHeight(27)
    exportButton:SetPoint('BOTTOMLEFT', exportBottom, 'BOTTOMLEFT', 0, 0)
    exportButton:SetPoint('BOTTOMRIGHT', exportBottom, 'BOTTOMRIGHT', 0, 0)

    local exportInput = self:CreateImportInput(exportBottom)
    exportInput:SetPoint('TOPLEFT', exportBottom, 'TOPLEFT', 0, 0)
    exportInput:SetPoint('TOPRIGHT', exportBottom, 'TOPRIGHT', 0, 0)
    exportInput:SetPoint('BOTTOMLEFT', exportButton, 'TOPLEFT', 0, 8)
    exportInput:SetPoint('BOTTOMRIGHT', exportButton, 'TOPRIGHT', 0, 8)
    self.exportInput = exportInput

    local checkboxContainer = CreateFrame('Frame', nil, exportPanel)
    checkboxContainer:SetPoint('TOPLEFT', exportModulesLabel, 'BOTTOMLEFT', 0, -8)
    checkboxContainer:SetPoint('TOPRIGHT', exportModulesLabel, 'BOTTOMRIGHT', 0, -8)
    checkboxContainer:SetPoint('BOTTOMLEFT', exportBottom, 'TOPLEFT', 0, -8)
    checkboxContainer:SetPoint('BOTTOMRIGHT', exportBottom, 'TOPRIGHT', 0, -8)

    self:InitExportModuleState()
    self:SetupExportCheckboxes(checkboxContainer)

    self.window = window
    self:RefreshProfileSelector()
end

profiles.Show = function(self)
    if (not self.window) then
        self:SetupWindow()
    end

    self:InitExportModuleState()
    self:SyncModuleCheckboxStates()

    if self.profileLabel then
        self.profileLabel:SetText(string.format('Current profile: |cfff96109%s|r', data:GetCurrentProfile()))
    end

    self:RefreshProfileSelector()
    self.window:ShowWindow()
end

profiles.GenerateExportString = function(self)
    local selectedModules = self:GetSelectedExportModules()
    if #selectedModules == 0 then
        EXUI.utils.printOut('Select at least one module to export.')
        return
    end

    local allModules = self:GetExportModuleList()
    local isFullExport = #selectedModules == #allModules

    local exportData
    if isFullExport then
        exportData = {
            name = data:GetCurrentProfile(),
            data = data:GetData()
        }
    else
        local keys = {}
        local moduleIds = {}
        for _, mod in ipairs(selectedModules) do
            table.insert(moduleIds, mod.id)
            for _, key in ipairs(mod.keys) do
                keys[key] = true
            end
        end

        local keyList = {}
        for key in pairs(keys) do
            table.insert(keyList, key)
        end

        exportData = {
            name = data:GetCurrentProfile(),
            partial = true,
            modules = moduleIds,
            data = data:ExtractProfileKeys(keyList)
        }
    end

    local serialized = C_EncodingUtil.SerializeCBOR(exportData)
    local compressed = C_EncodingUtil.CompressString(serialized)
    local exportString = C_EncodingUtil.EncodeBase64(compressed)

    self.exportInput:SetText(exportString)
end

profiles.OnImport = function(self)
    local importString = self.importInput:GetText()
    if not importString or importString:match('^%s*$') then
        EXUI.utils.printOut('Paste a profile export string to import.')
        return
    end

    local ok, profileData = pcall(function()
        local decoded = C_EncodingUtil.DecodeBase64(importString)
        local decompressed = C_EncodingUtil.DecompressString(decoded)
        return C_EncodingUtil.DeserializeCBOR(decompressed)
    end)

    if not ok or not profileData then
        EXUI.utils.printOut('Invalid profile data.')
        return
    end

    local valid = self:Validate(profileData)
    if not valid then
        return
    end

    if profileData.partial then
        data:MergeProfileData(profileData.data)
        local moduleList = profileData.modules and table.concat(profileData.modules, ', ') or 'unknown'
        EXUI.utils.printOut(string.format(
            'Imported partial profile data (%s) into |cfff96109%s|r.',
            moduleList,
            data:GetCurrentProfile()
        ))
        ReloadUI()
        return
    end

    if (data:HasProfile(profileData.name)) then
        local dialog = EXFrames:GetFrame('dialog-frame'):Create()
        dialog:SetText('Profile already exists. Overwrite?')
        dialog:SetButtons({
            {
                text = 'Overwrite',
                onClick = function()
                    data:CreateProfileFromData(profileData.name, profileData.data)
                    data:SetCurrentProfile(profileData.name)
                    ReloadUI()
                end,
                color = { 235 / 255, 162 / 255, 52 / 255, 1 }
            },
            {
                text = 'Duplicate',
                onClick = function()
                    local newName = data:GetDuplicateProfileName(profileData.name)
                    data:CreateProfileFromData(newName, profileData.data)
                    data:SetCurrentProfile(newName)
                    ReloadUI()
                end,
                color = { 235 / 255, 162 / 255, 52 / 255, 1 }
            },
            {
                text = 'Cancel',
                onClick = function()
                    dialog:HideDialog()
                    return
                end,
                color = { 235 / 255, 52 / 255, 52 / 255, 1 }
            }
        })

        dialog:ShowDialog()
        return
    end

    data:CreateProfileFromData(profileData.name, profileData.data)
    data:SetCurrentProfile(profileData.name)
    ReloadUI()
end

profiles.Validate = function(self, importData)
    if (not importData) then
        EXUI.utils.printOut('Invalid profile data')
        return false
    end
    if (not importData.name or not importData.data) then
        EXUI.utils.printOut('Invalid profile data')
        return false
    end

    return true
end
