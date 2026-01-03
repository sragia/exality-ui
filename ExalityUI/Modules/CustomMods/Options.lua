---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICustomModsData
local customData = EXUI:GetModule('custom-mods-data')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---------------------

---@class EXUICustomModsOptions
local options = EXUI:GetModule('custom-mods-options')

options.TABS = {
    GENERAL = 'general',
    DISPLAY = 'display',
    LOGIC = 'logic',
}

options.tabFrame = nil
options.splitFrame = nil
options.currTabId = options.TABS.GENERAL
options.currItemId = nil
options.fields = {}

options.Init = function(self)
    optionsController:RegisterModule(self, self.OptionHandler)
end

options.GetName = function(self)
    return 'Custom Mods'
end

options.GetOrder = function(self)
    return 100
end

options.CreateLayout = function(self, container)
    if (not self.splitFrame) then
        self.splitFrame = EXUI:GetModule('split-options-frame'):Create()
        self.splitFrame:SetParent(container)
        self.splitFrame:SetAllPoints()
        self.splitFrame:UpdateScroll()

        self.splitFrame:SetOnItemChange(function(id) self:OnItemChange(id) end)
        self.splitFrame:AddExtraButton({
            text = 'Create New',
            color = { 249 / 255, 95 / 255, 9 / 255, 1 },
            onClick = function()
                local id = customData:Create()
                options:Refresh()
                options.splitFrame:SetActiveItem(id)
            end
        })
    end

    if (not self.tabFrame) then
        self.tabFrame = EXUI:GetModule('tabs-frame'):Create()
        self.tabFrame:SetParent(self.splitFrame.container)
        self.tabFrame:SetAllPoints()

        self.tabFrame:SetOnTabChange(function(id) self:OnTabChange(id) end)
    end
end

options.OptionHandler = function(container, shouldHide)
    if (shouldHide) then
        if (options.splitFrame) then
            options.splitFrame:Destroy()
            options.splitFrame = nil
        end
        if (options.tabFrame) then
            options.tabFrame:Destroy()
            options.tabFrame = nil
        end
        for _, field in pairs(options.fields) do
            field:Destroy()
        end
        wipe(options.fields)
        return;
    end

    options:CreateLayout(container)
    options:Refresh()
end

options.Refresh = function(self)
    self:RefreshItems()
    self:RefreshFields()
end

options.GetOptions = function(self, tabId, itemId)
    if (tabId == options.TABS.GENERAL) then
        return self:GetGeneralOptions(itemId)
    elseif (tabId == options.TABS.DISPLAY) then
        return self:GetDisplayOptions(itemId)
    elseif (tabId == options.TABS.LOGIC) then
        return self:GetLogicOptions(itemId)
    end
    return {}
end

options.GetGeneralOptions = function(self, itemId)
    return {
        {
            type = 'toggle',
            label = 'Enabled',
            name = 'enabled',
            onObserve = function(value, oldValue)
                customData.Data:SetValueForId(itemId, 'enabled', value)
            end,
            currentValue = function()
                return customData.Data:GetValueForId(itemId, 'enabled')
            end,
            width = 100
        },
        {
            type = 'edit-box',
            label = 'Name',
            name = 'name',
            currentValue = function()
                return customData.Data:GetValueForId(itemId, 'name')
            end,
            onChange = function(f, value)
                customData.Data:SetValueForId(itemId, 'name', value)
                self:RefreshItems()
            end,
            width = 50
        }
    }
end

options.GetDisplayOptions = function(self, itemId)
    return {
        {
            type = 'title',
            label = 'Display Options WIP',
            width = 100
        },
    }
end

options.GetLogicOptions = function(self, itemId)
    return {
        {
            type = 'title',
            label = 'Logic Options WIP',
            width = 100
        },
    }
end

options.RefreshFields = function(self)
    local itemId = self.currItemId
    local tabId = self.currTabId

    for _, field in pairs(self.fields) do
        field:Destroy()
    end
    wipe(self.fields)

    if (not tabId or not itemId) then
        return;
    end

    local fields = self:GetOptions(tabId, itemId)

    for _, field in ipairs(fields) do
        if (type(field) == 'function') then
            local funcFields = field()
            if (funcFields) then
                for _, funcField in ipairs(funcFields) do
                    local fieldFrame = optionsFields:GetField(funcField)
                    optionsFields:CreateOrUpdateTooltip(fieldFrame, funcField.tooltip)
                    if (fieldFrame) then
                        fieldFrame:SetOptionData(funcField)
                        fieldFrame:SetParent(self.tabFrame.container)
                        table.insert(self.fields, fieldFrame)
                    end
                end
            end
        elseif (not field.depends or field.depends()) then
            local fieldFrame = optionsFields:GetField(field)
            optionsFields:CreateOrUpdateTooltip(fieldFrame, field.tooltip)
            if (fieldFrame) then
                fieldFrame:SetOptionData(field)
                fieldFrame:SetParent(self.tabFrame.container)
                table.insert(self.fields, fieldFrame)
            end
        end
    end

    EXUI.utils.organizeFramesInGrid('cm-fields', self.fields, 10, self.tabFrame.container, 10, 10)
end

options.RefreshItems = function(self)
    local items = customData:GetItems()
    self.splitFrame:AddItems(items)
end

options.OnTabChange = function(self, id)
    self.currTabId = id
    self:RefreshFields()
end

options.SetTabs = function(self)
    local tabs = {
        {
            ID = options.TABS.GENERAL,
            label = 'General',
        },
        {
            ID = options.TABS.DISPLAY,
            label = 'Display',
        },
        {
            ID = options.TABS.LOGIC,
            label = 'Logic',
        },
    }
    self.tabFrame:AddTabs(tabs)
    self.tabFrame:SetActiveTab(options.TABS.GENERAL)
end

options.OnItemChange = function(self, id)
    self.currItemId = id
    self:SetTabs()
end
