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

nameplates.ApplyCVars = function(self)
    if not self.enabled then
        return
    end
    EXUI:GetModule('np-cvars'):ApplyAll(npCore:GetDB())
end

nameplates.Init = function(self)
    npCore:EnsureDB()
    EXUI:GetModule('np-element-custom-texts'):Init()
    EXUI:GetModule('np-auras'):Init()
    EXUI:GetModule('np-preview'):Init()
    optionsController:RegisterModule(self)

    if npCore:GetValue('enable') then
        self:Enable()
    end

    C_Timer.After(1, function()
        nameplates:ApplyCVars()
    end)
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

nameplates.useTabs = true
nameplates.useSplitView = true

nameplates.GetTabs = function(self)
    return npOptions:GetTabs()
end

nameplates.GetSplitViewItems = function(self)
    return npOptions:GetSplitViewItems()
end

nameplates.GetOptions = function(self, tabId, itemId)
    return npOptions:GetOptions(tabId, itemId)
end

nameplates.HandleOptions = function(self)
    EXUI:GetModule('options-fields'):RefreshOptions()
end

nameplates.RefreshCurrentView = function(self)
    EXUI:GetModule('options-fields'):RefreshOptionsDelayed()
end

nameplates.UpdateOptionsChrome = function(self)
    EXUI:GetModule('np-preview'):Show()
    EXUI:GetModule('np-preview'):Refresh()
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
    self:ApplyCVars()
    EXUI:GetModule('np-auras-apply'):Init()
    driver:Enable()
end
