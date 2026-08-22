---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUINameplatesDriver
local driver = EXUI:GetModule('np-driver')

---@class EXUINameplatesOptions
local npOptions = EXUI:GetModule('np-options')

---@class EXUINameplatesModule
local nameplates = EXUI:GetModule('nameplates')

nameplates.enabled = false

nameplates.Init = function(self)
    npCore:EnsureDB()
    EXUI:GetModule('np-element-custom-texts'):Init()
    EXUI:GetModule('np-auras'):Init()
    EXUI:GetModule('np-preview'):Init()
    optionsController:RegisterModule(self, npOptions.OptionHandler)

    if npCore:GetValue('enable') then
        self:Enable()
    end
end

nameplates.GetName = function()
    return 'Nameplates'
end

nameplates.GetOrder = function()
    return 25
end

nameplates.GetIcon = function()
    return [[Interface/Addons/ExalityUI/Assets/Images/Menu/nameplates.png]]
end

nameplates.GetProfileExportSpec = function()
    return { id = 'nameplates', keys = { 'nameplates' } }
end

nameplates.HandleOptions = function(self)
    npOptions:HandleOptions()
end

nameplates.RefreshCurrentView = function(self)
    npOptions:RefreshCurrentView()
end

nameplates.TeardownOptionsChrome = function(self)
    EXUI:GetModule('np-preview'):Hide()
end

nameplates.Enable = function(self)
    if self.enabled then
        return
    end
    self.enabled = true
    npCore:UpdateHealthCurve()
    EXUI:GetModule('np-cvars'):ApplyAll(npCore:GetDB())
    EXUI:GetModule('np-auras-apply'):Init()
    driver:Enable()
end
