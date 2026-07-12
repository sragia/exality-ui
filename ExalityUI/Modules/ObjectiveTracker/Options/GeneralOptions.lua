---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIObjectiveTrackerModule
local objectiveTracker = EXUI:GetModule('objective-tracker')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIObjectiveTrackerGeneralOptions
local generalOptions = EXUI:GetModule('objective-tracker-general-options')

---@class EXUIObjectiveTrackerDefaults
local defaults = EXUI:GetModule('objective-tracker-defaults')

function generalOptions:GetOptions()
    local selfModule = objectiveTracker
    return {
        {
            type = 'title',
            label = 'Objective Tracker',
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            onChange = function(value)
                selfModule.Data:SetValue('enable', value)
                optionsFields:RefreshOptions()
                if value then
                    selfModule:Enable()
                else
                    selfModule:Disable()
                end
            end,
            currentValue = function()
                return selfModule.Data:GetValue('enable')
            end,
            width = 100,
        },
        {
            type = 'description',
            width = 100,
            label =
            'Replaces the default Objective Tracker with a custom ExalityUI tracker. Use Edit Mode to move it when enabled.',
        },
        {
            type = 'title',
            label = 'Layout',
            size = 14,
            width = 100,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
        },
        {
            type = 'range',
            label = 'Max Height',
            name = 'maxHeight',
            min = 200,
            max = 1200,
            step = 10,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('maxHeight')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('maxHeight', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'range',
            label = 'Width',
            name = 'width',
            min = 180,
            max = 400,
            step = 1,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('width')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('width', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'range',
            label = 'Category Spacing',
            name = 'categorySpacing',
            min = 0,
            max = 40,
            step = 1,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('categorySpacing')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('categorySpacing', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'title',
            label = 'Position',
            size = 14,
            width = 100,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'anchorPoint',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('anchorPoint')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('anchorPoint', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor',
            name = 'relativeAnchor',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('relativeAnchor')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('relativeAnchor', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'xOffset',
            min = -2000,
            max = 2000,
            step = 1,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('xOffset')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('xOffset', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'yOffset',
            min = -2000,
            max = 2000,
            step = 1,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('yOffset')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('yOffset', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'title',
            label = 'Visibility & Behavior',
            size = 14,
            width = 100,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
        },
        {
            type = 'toggle',
            label = 'Hide Objectives Header',
            name = 'hideContainerHeader',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('hideContainerHeader', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('hideContainerHeader')
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Show Category Filter Chips',
            name = 'showCategoryChips',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('showCategoryChips', value)
                if not value then
                    selfModule.Data:SetValue('activeFilter', defaults.FILTER_ALL)
                end
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('showCategoryChips')
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Hide Collapse-All Button',
            name = 'hideCollapseButtons',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('hideCollapseButtons', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('hideCollapseButtons')
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Hide Category Minimize Buttons',
            name = 'hideModuleMinimizeButtons',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('hideModuleMinimizeButtons', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('hideModuleMinimizeButtons')
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Show Background Panel',
            name = 'showBackground',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('showBackground', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('showBackground')
            end,
            width = 100,
        },
        {
            type = 'range',
            label = 'Background Opacity',
            name = 'backgroundOpacity',
            min = 0,
            max = 100,
            step = 1,
            depends = function()
                return selfModule.Data:GetValue('enable')
                    and selfModule.Data:GetValue('showBackground')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('backgroundOpacity')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('backgroundOpacity', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'color-picker',
            label = 'Panel Background Color',
            name = 'panelBackgroundColor',
            depends = function()
                return selfModule.Data:GetValue('enable')
                    and selfModule.Data:GetValue('showBackground')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('panelBackgroundColor')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('panelBackgroundColor', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'range',
            label = 'Panel Border Thickness',
            name = 'panelBorderThickness',
            min = 0,
            max = 3,
            step = 1,
            depends = function()
                return selfModule.Data:GetValue('enable')
                    and selfModule.Data:GetValue('showBackground')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('panelBorderThickness')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('panelBorderThickness', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'color-picker',
            label = 'Panel Border Color',
            name = 'panelBorderColor',
            depends = function()
                return selfModule.Data:GetValue('enable')
                    and selfModule.Data:GetValue('showBackground')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('panelBorderColor')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('panelBorderColor', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'toggle',
            label = 'Auto-Hide When Empty',
            name = 'autoHideWhenEmpty',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('autoHideWhenEmpty', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('autoHideWhenEmpty')
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Hide On Encounter',
            name = 'hideOnEncounter',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('hideOnEncounter', value)
                selfModule:Configure()
            end,
            currentValue = function()
                local value = selfModule.Data:GetValue('hideOnEncounter')
                if value == nil then
                    return selfModule.Data:GetValue('hideInCombat')
                end
                return value
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Hide In Mythic+',
            name = 'hideInMythicPlus',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('hideInMythicPlus', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('hideInMythicPlus')
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Hide Quest POI Buttons',
            name = 'hideQuestPOI',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('hideQuestPOI', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('hideQuestPOI')
            end,
            width = 100,
        },
    }
end
