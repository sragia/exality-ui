---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIDamageMetersModule
local meters = EXUI:GetModule('damage-meters')

---@class EXUIDamageMetersViews
local views = EXUI:GetModule('damage-meters-views')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIDamageMetersGeneralOptions
local generalOptions = EXUI:GetModule('damage-meters-general-options')

function generalOptions:GetModuleOptions()
    return {
        {
            type = 'title',
            label = 'Damage Meters',
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'moduleEnable',
            width = 100,
            currentValue = function()
                return meters:GetModuleValue('enable')
            end,
            onChange = function(value)
                meters:SetModuleValue('enable', value)
                if value then
                    meters:Enable()
                else
                    meters:Disable()
                end
                optionsFields:RefreshOptions()
            end,
        },
        {
            type = 'toggle',
            label = 'Hide Blizzard Meter',
            name = 'hideBlizzard',
            width = 100,
            depends = function()
                return meters:GetModuleValue('enable')
            end,
            currentValue = function()
                return meters:GetModuleValue('hideBlizzard')
            end,
            onChange = function(value)
                meters:SetModuleValue('hideBlizzard', value)
                EXUI:GetModule('damage-meters-data'):UpdateBlizzardVisibility()
            end,
        },
    }
end

function generalOptions:GetOptions(windowID)
    local function windowEnabled()
        return meters:GetModuleValue('enable') and meters:GetValue(windowID, 'enable')
    end

    local options = self:GetModuleOptions()
    local windowOptions = {
        {
            type = 'title',
            label = 'Window',
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Enable Window',
            name = 'enable',
            width = 100,
            depends = function()
                return meters:GetModuleValue('enable')
            end,
            currentValue = function()
                return meters:GetValue(windowID, 'enable')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'enable', value)
                meters:UpdateById(windowID)
                optionsFields:RefreshOptions()
            end,
        },
        {
            type = 'button',
            label = meters:IsShowingTestBars(windowID) and 'Hide Test Bars' or 'Show Test Bars',
            name = 'showTestBars',
            width = 100,
            depends = windowEnabled,
            onClick = function()
                meters:SetShowTestBars(windowID, not meters:IsShowingTestBars(windowID))
                optionsFields:RefreshOptions()
            end,
        },
        {
            type = 'edit-box',
            label = 'Name',
            name = 'name',
            width = 50,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'name')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'name', value)
                meters:UpdateById(windowID)
                optionsFields:RefreshItemList()
            end,
        },
        {
            type = 'dropdown',
            label = 'View',
            name = 'damageMeterType',
            width = 50,
            depends = windowEnabled,
            getOptions = function()
                local optionsByType = {}
                for _, category in ipairs(views:GetCategories()) do
                    for _, meterType in ipairs(category.types) do
                        optionsByType[tostring(meterType)] = views:GetTypeName(meterType)
                    end
                end
                return optionsByType
            end,
            currentValue = function()
                return tostring(meters:GetValue(windowID, 'damageMeterType'))
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'damageMeterType', tonumber(value))
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Visibility',
            name = 'visibility',
            width = 50,
            depends = windowEnabled,
            getOptions = function()
                return {
                    always = 'Always',
                    combat = 'In Combat',
                    group = 'In Group',
                }
            end,
            currentValue = function()
                return meters:GetValue(windowID, 'visibility')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'visibility', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'toggle',
            label = 'Lock Position',
            name = 'locked',
            width = 100,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'locked')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'locked', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'toggle',
            label = 'Click Through',
            name = 'clickThrough',
            width = 100,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'clickThrough')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'clickThrough', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'toggle',
            label = 'Always Show Myself',
            name = 'alwaysShowSelf',
            width = 100,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'alwaysShowSelf')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'alwaysShowSelf', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Update Interval',
            name = 'updateInterval',
            min = 0.1,
            max = 5,
            step = 0.1,
            width = 50,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'updateInterval')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'updateInterval', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Width',
            name = 'width',
            min = 140,
            max = 500,
            step = 1,
            width = 50,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'width')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'width', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Height',
            name = 'height',
            min = 80,
            max = 600,
            step = 1,
            width = 50,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'height')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'height', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'anchorPoint',
            width = 50,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'anchorPoint')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'anchorPoint', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'relativePoint',
            width = 50,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'relativePoint')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'relativePoint', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'XOff',
            min = -2000,
            max = 2000,
            step = 1,
            width = 50,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'XOff')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'XOff', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'YOff',
            min = -2000,
            max = 2000,
            step = 1,
            width = 50,
            depends = windowEnabled,
            currentValue = function()
                return meters:GetValue(windowID, 'YOff')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'YOff', value)
                meters:UpdateById(windowID)
            end,
        },
    }

    for _, option in ipairs(windowOptions) do
        table.insert(options, option)
    end
    return options
end
