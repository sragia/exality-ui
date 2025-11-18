---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIModuleItem
local moduleItem = EXUI:GetModule('module-item')

----------------

---@class EXUIOptionsModuleSelector
local optionsModuleSelector = EXUI:GetModule('options-module-selector')

optionsModuleSelector.container = nil
optionsModuleSelector.buttons = {}

optionsModuleSelector.Init = function(self)
    EXUI.utils.addObserver(self)
    optionsController:Observe('selectedModule', function(value)
        for _, button in pairs(self.buttons) do
            button:SetSelected(button.data:GetName() == value)
        end
    end)
end

optionsModuleSelector.Create = function(self, container)
    self.container = container

    self:Populate()
end

optionsModuleSelector.Populate = function(self)
    local modules = optionsController:GetAllModules()

    for _, module in EXUI.utils.spairs(modules, function(t, a, b) return t[a].module:GetOrder() < t[b].module:GetOrder() end) do
        local item = moduleItem:Create({
            onClick = function(self)
                optionsController:SetSelectedModule(self.data:GetName())
            end
        }, self.container)
        item:SetModule(module.module)
        item:SetSelected(module.module:GetName() == optionsController.selectedModule)
        table.insert(self.buttons, item)
    end

    EXUI.utils.organizeFramesInList(self.buttons, 5, self.container)
end