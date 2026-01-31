---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIProfiles
local profiles = EXUI:GetModule('profiles')

profiles.window = nil
profiles.copyFromCurrent = false
profiles.newProfileName = ''
profiles.importInput = nil
profiles.exportInput = nil

profiles.Init = function(self)
end

profiles.CreateImportInput = function(self, container)
    local input = CreateFrame('EditBox', nil, container, 'BackdropTemplate')
    input:SetMultiLine(true)
    input:SetClipsChildren(true)
    input:SetAutoFocus(false)
    input:SetHeight(150)
    input:SetBackdrop(EXUI.const.backdrop.DEFAULT)
    input:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    input:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    input:SetFont(EXUI.const.fonts.DEFAULT, 8, 'OUTLINE')
    input:SetTextInsets(10, 10, 10, 10)
    input:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)

    return input
end

profiles.SetupWindow = function(self)
    local window = EXFrames:GetFrame('window-frame'):Create({
        size = { 500, 630 },
        title = 'Profiles'
    })

    local currentContainer = EXFrames:GetFrame('panel-frame'):Create()
    currentContainer:SetParent(window.container)
    currentContainer:SetPoint('TOPLEFT')
    currentContainer:SetPoint('BOTTOMRIGHT', window.container, 'TOPRIGHT', 0, -30)

    local currentText = currentContainer:CreateFontString(nil, 'OVERLAY')
    currentText:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    currentText:SetPoint('LEFT', 10, 0)
    currentText:SetText(string.format('Current Profile: |cfff96109%s|r', data:GetCurrentProfile()))

    local createContainer = EXFrames:GetFrame('panel-frame'):Create()
    createContainer:SetParent(window.container)
    createContainer:SetPoint('TOPLEFT', currentContainer, 'BOTTOMLEFT', 0, -10)
    createContainer:SetPoint('BOTTOMRIGHT', currentContainer, 'BOTTOMRIGHT', 0, -140)

    local createLabel = createContainer:CreateFontString(nil, 'OVERLAY')
    createLabel:SetFont(EXUI.const.fonts.DEFAULT, 16, 'OUTLINE')
    createLabel:SetPoint('TOPLEFT', createContainer, 'TOPLEFT', 10, -10)
    createLabel:SetText('Create New Profile')

    local createInput = EXFrames:GetFrame('edit-box-input'):Create({
        label = 'Profile Name',
        onChange = function(value)
            self.newProfileName = value
        end
    })
    createInput:SetHeight(40)
    createInput:SetParent(createContainer)
    createInput:SetPoint('TOPLEFT', createLabel, 'BOTTOMLEFT', 0, -10)
    createInput:SetPoint('RIGHT', createContainer, 'CENTER', 60, 0);

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
        size = { 60, 27 }
    })
    createButton:SetParent(createContainer)
    createButton:SetPoint('BOTTOMLEFT', createInput, 'BOTTOMRIGHT', 10, 0)
    createButton:SetPoint('RIGHT', createContainer, 'RIGHT', -10, 0);

    local shouldCopyToggle = EXFrames:GetFrame('toggle'):Create({
        text = 'Duplicate from current profile',
        value = false
    })
    shouldCopyToggle:Observe('value', function(value)
        self.copyFromCurrent = value
    end)
    shouldCopyToggle:SetParent(createContainer)
    shouldCopyToggle:SetPoint('TOPLEFT', createInput, 'BOTTOMLEFT', 0, -15)

    local importContainer = EXFrames:GetFrame('panel-frame'):Create()
    importContainer:SetParent(window.container)
    importContainer:SetPoint('TOPLEFT', createContainer, 'BOTTOMLEFT', 0, -10)
    importContainer:SetPoint('BOTTOMRIGHT', createContainer, 'BOTTOMRIGHT', 0, -200)

    local importLabel = importContainer:CreateFontString(nil, 'OVERLAY')
    importLabel:SetFont(EXUI.const.fonts.DEFAULT, 16, 'OUTLINE')
    importLabel:SetPoint('TOPLEFT', importContainer, 'TOPLEFT', 10, -10)
    importLabel:SetText('Import Profile')

    local importInput = self:CreateImportInput(importContainer)
    importInput:SetPoint('TOPLEFT', importLabel, 'BOTTOMLEFT', 0, -10)
    importInput:SetPoint('TOPRIGHT', importContainer, 'TOPRIGHT', -10, 0);
    importInput:SetPoint('BOTTOM', importContainer, 'BOTTOM', 0, 40);
    self.importInput = importInput

    local importButton = EXFrames:GetFrame('button'):Create({
        text = 'Import',
        onClick = function()
            self:OnImport()
        end,
        color = { 0, 130 / 255, 9 / 255, 1 },
        size = { 60, 27 }
    })
    importButton:SetParent(importContainer)
    importButton:SetPoint('TOPLEFT', importInput, 'BOTTOMLEFT', 0, -5)
    importButton:SetPoint('TOPRIGHT', importInput, 'BOTTOMRIGHT', 0, -5);

    local exportContainer = EXFrames:GetFrame('panel-frame'):Create()
    exportContainer:SetParent(window.container)
    exportContainer:SetPoint('TOPLEFT', importContainer, 'BOTTOMLEFT', 0, -10)
    exportContainer:SetPoint('BOTTOMRIGHT', importContainer, 'BOTTOMRIGHT', 0, -200)

    local exportLabel = exportContainer:CreateFontString(nil, 'OVERLAY')
    exportLabel:SetFont(EXUI.const.fonts.DEFAULT, 16, 'OUTLINE')
    exportLabel:SetPoint('TOPLEFT', exportContainer, 'TOPLEFT', 10, -10)
    exportLabel:SetText('Export Profile')

    local exportInput = self:CreateImportInput(exportContainer)
    exportInput:SetPoint('TOPLEFT', exportLabel, 'BOTTOMLEFT', 0, -10)
    exportInput:SetPoint('TOPRIGHT', exportContainer, 'TOPRIGHT', -10, 0);
    exportInput:SetPoint('BOTTOM', exportContainer, 'BOTTOM', 0, 40);
    self.exportInput = exportInput

    local exportButton = EXFrames:GetFrame('button'):Create({
        text = 'Export',
        onClick = function()
            self:GenerateExportString()
        end,
        color = { 237 / 255, 138 / 255, 0, 1 },
        size = { 60, 27 }
    })
    exportButton:SetParent(exportContainer)
    exportButton:SetPoint('TOPLEFT', exportInput, 'BOTTOMLEFT', 0, -5)
    exportButton:SetPoint('TOPRIGHT', exportInput, 'BOTTOMRIGHT', 0, -5);

    self.window = window
end

profiles.Show = function(self)
    if (not self.window) then
        self:SetupWindow()
    end

    self.window:ShowWindow()
end

profiles.GenerateExportString = function(self)
    local profileData = data:GetData()

    local exportData = {
        name = data:GetCurrentProfile(),
        data = profileData
    }

    local serialized = C_EncodingUtil.SerializeCBOR(exportData)
    local compressed = C_EncodingUtil.CompressString(serialized)
    local exportString = C_EncodingUtil.EncodeBase64(compressed)

    self.exportInput:SetText(exportString)
end

profiles.OnImport = function(self)
    local importString = self.importInput:GetText()

    local decoded = C_EncodingUtil.DecodeBase64(importString)
    local decompressed = C_EncodingUtil.DecompressString(decoded)
    local profileData = C_EncodingUtil.DeserializeCBOR(decompressed)

    local valid = self:Validate(profileData)
    if (not valid or not profileData) then
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
        return;
    end

    data:CreateProfileFromData(profileData.name, profileData.data)
    data:SetCurrentProfile(profileData.name)
    ReloadUI()
end

profiles.Validate = function(self, data)
    if (not data) then
        EXUI.utils.printOut('Invalid profile data')
        return false
    end
    if (not data.name or not data.data) then
        EXUI.utils.printOut('Invalid profile data')
        return false
    end

    return true
end
