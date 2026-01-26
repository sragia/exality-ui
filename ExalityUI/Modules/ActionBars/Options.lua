---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsData
local data = EXUI:GetModule('ab-data')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIOptionsReloadDialog
local optionsReloadDialog = EXUI:GetModule('options-reload-dialog')

---------------------

---@class EXUIActionBarsOptions
local options = EXUI:GetModule('ab-options')

options.useTabs = true
options.useSplitView = true

options.Init = function(self)
    optionsController:RegisterModule(self)
end

options.GetName = function(self)
    return 'Action Bars'
end

options.GetOrder = function(self)
    return 55
end

options.GetSplitViewItems = function(self, currTabID)
    if (currTabID == 'general' or currTabID == nil) then
        return {
            {
                ID = 'general',
                label = 'General'
            }
        }
    end
    return {
        {
            ID = 'hello-test',
            label = 'Hello Test',
        }
    }
end

options.GetTabs = function(self)
    return {
        {
            ID = 'general',
            label = 'General',
        },
        {
            ID = 'bar1',
            label = 'Bar 1',
        },
        {
            ID = 'bar2',
            label = 'Bar 2',
        },
        {
            ID = 'bar3',
            label = 'Bar 3',
        },
        {
            ID = 'bar4',
            label = 'Bar 4',
        },
        {
            ID = 'bar5',
            label = 'Bar 5',
        },
        {
            ID = 'bar6',
            label = 'Bar 6',
        },
        {
            ID = 'bar7',
            label = 'Bar 7',
        },
        {
            ID = 'bar8',
            label = 'Bar 8',
        }
    }
end

options.GetOptions = function(self, currTabID, currItemID)
    if (currTabID == 'general' and currItemID == 'general' or currItemID == nil) then
        return {
            {
                type = 'toggle',
                name = 'enabled',
                label = 'Enabled',
                onChange = function(value)
                    data:SetValueByKey('enabled', value)
                    optionsReloadDialog:ShowDialog()
                end,
                currentValue = function()
                    return data:GetValueByKey('enabled')
                end,
                width = 100
            }
        }
    end
    return {}
end
