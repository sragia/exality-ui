---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

-------------

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

optionsFields.baseContainer = nil
optionsFields.container = nil
optionsFields.splitView = nil
optionsFields.tabs = nil
optionsFields.currTabID = nil
optionsFields.currItemID = nil
optionsFields.fields = {}

optionsFields.Init = function(self)
    EXUI.utils.addObserver(self)

    optionsController:Observe('selectedModule', function(value)
        self:Refresh()
    end)
end

optionsFields.Create = function(self, container)
    self.container = container
    self.baseContainer = container

    self:Refresh()
end

optionsFields.AddSplitView = function(self, module)
    self.splitView = EXUI:GetModule('split-options-frame'):Create()
    if (self.tabs) then
        self.splitView:SetParent(self.tabs.container)
        self.splitView:SetAllPoints()
    else
        self.splitView:SetParent(self.baseContainer)
        self.splitView:SetAllPoints()
    end
    self.splitView:UpdateScroll()

    if (module.splitViewExtraButton) then
        self.splitView:AddExtraButton(module.splitViewExtraButton)
    else
        self.splitView:DisableExtraButton()
    end
    local items = module.GetSplitViewItems()
    self.splitView:AddItems(items)
    self.splitView:SetOnItemChange(function(id) 
        self.currItemID = id
        self:RefreshFields()
    end)
    self.splitView:onItemClick(items[1].ID)

    self.container = self.splitView.container
end

optionsFields.AddTabs = function(self, module)
    self.tabs = EXUI:GetModule('tabs-frame'):Create()
    self.tabs:SetParent(self.baseContainer)
    self.tabs:SetAllPoints()
    self.container = self.tabs.container

    -- TODO Finish implementing this when I need this somewhere...
end

optionsFields.Refresh = function(self)
    local module = optionsController:GetSelectedModule()

    for _, field in pairs(self.fields) do
        field:Destroy()
    end
    for _, module in pairs(optionsController:GetAllModules()) do
        if (module.optionHandler) then
            module.optionHandler(self.container, true)
        end
    end
    if (self.splitView) then
        self.splitView:Destroy()
        self.splitView = nil
    end

    if (self.tabs) then
        self.tabs:Destroy()
        self.tabs = nil
    end

    self.container = self.baseContainer
    self.fields = {}
    
    if (module.optionHandler) then
        module.optionHandler(self.container)
        return;
    end
    local currentModule = module.module
    
    if (currentModule) then
        if (currentModule.useTabs) then
            self:AddTabs(currentModule)
            -- TODO: How to handle after this
        end
    
        if (currentModule.useSplitView) then
            self:AddSplitView(currentModule)
        end
    end

    self:RefreshFields()
end

optionsFields.RefreshFields = function(self)
    local module = optionsController:GetSelectedModule()
    local currentModule = module.module

    for _, field in pairs(self.fields) do
        field:Destroy()
    end
    self.fields = {}

    local fields = currentModule:GetOptions(self.currTabID, self.currItemID)
    for _, field in ipairs(fields) do
        local fieldFrame = self:GetField(field)
        if (fieldFrame) then
            fieldFrame:SetOptionData(field)
            fieldFrame:SetParent(self.container)
            table.insert(self.fields, fieldFrame)
        end
    end
    
    EXUI.utils.organizeFramesInGrid('fields', self.fields, 10, self.container, 10, 10)
end

optionsFields.GetField = function(self, field)
    return EXUI.utils.switch(field.type, {
        ['editbox'] = function()
            local f = EXUI:GetModule('edit-box-input'):Create({
                label = 'Edit Box',
                onChange = field.onChange,
                initial = field.currentValue and field.currentValue() or nil,
            })
            f:SetHeight(40)
            return f
        end,
        ['range'] = function()
            local f = EXUI:GetModule('range-input'):Create()
            f:SetOnChange(field.onChange)
            return f
        end,
        ['button'] = function()
            local f = EXUI:GetModule('button'):Create()
            return f
        end,
        ['toggle'] = function()
            local f = EXUI:GetModule('toggle'):Create({
                text = field.label,
                value = field.currentValue and field.currentValue() or false,
            })
            f:Observe('value', field.onObserve)
            return f
        end,
        ['dropdown'] = function()
            local f = EXUI:GetModule('dropdown'):Create({})
            return f
        end,
        ['spacer'] = function()
            local f = EXUI:GetModule('spacer'):Create()
            return f
        end,
        ['color-picker'] = function()
            local f = EXUI:GetModule('color-picker'):Create()
            return f
        end,
        ['title'] = function()
            local f = EXUI:GetModule('title'):Create()
            return f
        end,
        ['description'] = function()
            local f = EXUI:GetModule('description'):Create()
            return f
        end,
        ['edit-box'] = function()
            local f = EXUI:GetModule('edit-box-input'):Create({})
            f:SetHeight(40)
            return f
        end,
        default = function()
            EXUI.utils.printOut('Unknown Field Type: ' .. field.type)    
        end
    })
end
