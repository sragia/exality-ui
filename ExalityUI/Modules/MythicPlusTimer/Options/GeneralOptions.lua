---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIMythicPlusTimerModule
local mythicPlusTimer = EXUI:GetModule('mythic-plus-timer')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIMythicPlusTimerGeneralOptions
local generalOptions = EXUI:GetModule('mythic-plus-timer-general-options')

function generalOptions:GetOptions()
    local selfModule = mythicPlusTimer
    return {
        {
            type = 'title',
            label = 'M+ Timer',
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
            label = 'Custom Mythic+ timer with enemy forces, upgrade breakpoints, and boss tracking. Use Edit Mode to reposition when enabled.',
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
            type = 'dropdown',
            label = 'Frame Strata',
            name = 'frameStrata',
            getOptions = function()
                return EXUI.const.frameStrata
            end,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('frameStrata')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('frameStrata', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'range',
            label = 'Frame Level',
            name = 'frameLevel',
            min = 1,
            max = 100,
            step = 1,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('frameLevel')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('frameLevel', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'title',
            label = 'Visibility',
            size = 14,
            width = 100,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
        },
        {
            type = 'toggle',
            label = 'Hide Objective Tracker During M+',
            name = 'hideObjectiveTracker',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('hideObjectiveTracker', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('hideObjectiveTracker')
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Show Death Counter',
            name = 'showDeathCounter',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('showDeathCounter', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('showDeathCounter')
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Show Max Timer',
            name = 'showMaxTimer',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('showMaxTimer', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('showMaxTimer')
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Show Boss Names',
            name = 'showBossNames',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('showBossNames', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('showBossNames')
            end,
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'Boss Name Alignment',
            name = 'bossAlign',
            getOptions = function()
                return {
                    RIGHT = 'Right',
                    LEFT = 'Left',
                }
            end,
            depends = function()
                return selfModule.Data:GetValue('enable') and selfModule.Data:GetValue('showBossNames')
            end,
            currentValue = function()
                return selfModule.Data:GetValue('bossAlign')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('bossAlign', value)
                selfModule:Configure()
            end,
            width = 50,
        },
        {
            type = 'title',
            label = 'Splits',
            size = 14,
            width = 100,
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
        },
        {
            type = 'toggle',
            label = 'Show Split Comparison',
            name = 'showSplitComparison',
            depends = function()
                return selfModule.Data:GetValue('enable')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('showSplitComparison', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('showSplitComparison')
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Also use previous key level (−1) when this level has no times',
            name = 'comparePreviousKeyLevel',
            depends = function()
                return selfModule.Data:GetValue('enable') and selfModule.Data:GetValue('showSplitComparison')
            end,
            onChange = function(value)
                selfModule.Data:SetValue('comparePreviousKeyLevel', value)
                selfModule:Configure()
            end,
            currentValue = function()
                return selfModule.Data:GetValue('comparePreviousKeyLevel')
            end,
            width = 100,
        },
    }
end
