---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class ExalityFramesModuleItem
local moduleItem = EXFrames:GetFrame('module-item')

----------------

---@class EXUIOptionsModuleSelector
local optionsModuleSelector = EXUI:GetModule('options-module-selector')

optionsModuleSelector.container = nil
optionsModuleSelector.buttons = {}

local categoryItems = {
    {
        name = 'Quality of Life',
        order = 60
    }
}

optionsModuleSelector.Init = function(self)
    EXUI.utils.addObserver(self)
    optionsController:Observe('selectedModule', function(value)
        for _, button in pairs(self.buttons) do
            button:SetSelected(value)
        end
    end)
end

optionsModuleSelector.Create = function(self, container)
    self.container = container

    self:Populate()
end

optionsModuleSelector.Populate = function(self)
    local tree = self:BuildTree()

    for _, module in EXUI.utils.spairs(tree, function(t, a, b) return t[a].order < t[b].order end) do
        local item = EXFrames:GetFrame('menu-item'):Create(self.container)

        if (module.subMenu) then
            item:SetSubMenuItems(module.subMenu)
            item:SetExpandable(true)
            item:SetText(module.name)
            item:SetSelected(false)
        else
            item:SetExpandable(false)
            item:SetOnClick(module.onClick)
            item:SetData(module.data)
            item:SetText(module.name)
            item:SetSelected(optionsController.selectedModule)
        end

        table.insert(self.buttons, item)
    end

    EXUI.utils.organizeFramesInList(self.buttons, 5, self.container, 3)
end

optionsModuleSelector.BuildTree = function(self)
    local tree = {}
    for _, category in pairs(categoryItems) do
        tree[category.name] = {
            order = category.order,
            name = category.name,
            isExpandable = true,
            onClick = nil,
            subMenu = {}
        }
    end
    local modules = optionsController:GetAllModules()
    for _, module in pairs(modules) do
        if (module.module.GetCategory) then
            local category = module.module:GetCategory()
            if (tree[category]) then
                table.insert(tree[category].subMenu, {
                    order = module.module:GetOrder(),
                    name = module.module:GetName(),
                    isExpandable = false,
                    data = module.module,
                    onClick = function(self)
                        optionsController:SetSelectedModule(self.data:GetName())
                    end
                })
            end
        else
            tree[module.module:GetName()] = {
                order = module.module:GetOrder(),
                name = module.module:GetName(),
                isExpandable = false,
                data = module.module,
                onClick = function(self)
                    optionsController:SetSelectedModule(self.data:GetName())
                end
            }
        end
    end

    return tree
end
