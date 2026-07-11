---@class ExalityUI
local EXUI = select(2, ...)

---------

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

optionsController.modules = {}
optionsController.selectedModule = 'General'

optionsController.Init = function(self)
    EXUI.utils.addObserver(self)
end

optionsController.GetSelectedModule = function(self)
    return self.modules[self.selectedModule]
end

optionsController.GetSelectedModuleName = function(self)
    return self.selectedModule
end

optionsController.SetSelectedModule = function(self, moduleName)
    self:SetValue('selectedModule', moduleName)
end

optionsController.RegisterModule = function(self, module, optionHandler)
    self.modules[module:GetName()] = {
        module = module,
        optionHandler = optionHandler
    }
end

optionsController.GetAllModules = function(self)
    return self.modules
end

optionsController.GetProfileExportModules = function(self)
    local list = {}
    for _, entry in EXUI.utils.spairs(self.modules, function(t, a, b)
        local modA = t[a].module
        local modB = t[b].module
        local orderA = modA.GetOrder and modA:GetOrder() or 999
        local orderB = modB.GetOrder and modB:GetOrder() or 999
        return orderA < orderB or (orderA == orderB and a < b)
    end) do
        local mod = entry.module
        if mod.GetProfileExportSpec then
            local spec = mod:GetProfileExportSpec()
            table.insert(list, {
                id = spec.id,
                name = mod:GetName(),
                keys = spec.keys,
                category = mod.GetCategory and mod:GetCategory() or nil,
            })
        end
    end
    return list
end