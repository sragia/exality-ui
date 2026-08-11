---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIObjectiveTrackerModule
local objectiveTracker = EXUI:GetModule('objective-tracker')

---@class EXUIObjectiveTrackerStyleOptions
local styleOptions = EXUI:GetModule('objective-tracker-style-options')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

local LSM = LibStub('LibSharedMedia-3.0', true)

local function customHeaderStyleEnabled()
    return objectiveTracker.Data:GetValue('enable')
        and objectiveTracker.Data:GetValue('customHeaderStyle')
end

local COLOR_KEYS = {
    { key = 'CategoryHeader', label = 'Category Title' },
    { key = 'BlockHeader', label = 'Quest Title' },
    { key = 'Normal', label = 'Normal Text' },
    { key = 'Complete', label = 'Complete' },
    { key = 'Failed', label = 'Failed' },
    { key = 'TimeLeft', label = 'Time Left' },
}

local function fontFields(prefix, label)
    return {
        {
            type = 'dropdown',
            label = label .. ' Font',
            name = prefix .. 'Font',
            getOptions = function()
                local fonts = LSM and LSM:List('font') or { 'DMSans' }
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            depends = function()
                return objectiveTracker.Data:GetValue('enable')
            end,
            currentValue = function()
                return objectiveTracker.Data:GetValue(prefix .. 'Font')
            end,
            onChange = function(value)
                objectiveTracker.Data:SetValue(prefix .. 'Font', value)
                objectiveTracker:Configure()
            end,
            width = 50,
        },
        {
            type = 'dropdown',
            label = label .. ' Font Flag',
            name = prefix .. 'FontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            depends = function()
                return objectiveTracker.Data:GetValue('enable')
            end,
            currentValue = function()
                return objectiveTracker.Data:GetValue(prefix .. 'FontFlag')
            end,
            onChange = function(value)
                objectiveTracker.Data:SetValue(prefix .. 'FontFlag', value)
                objectiveTracker:Configure()
            end,
            width = 25,
        },
        {
            type = 'range',
            label = label .. ' Font Size',
            name = prefix .. 'FontSize',
            min = 8,
            max = 24,
            step = 1,
            depends = function()
                return objectiveTracker.Data:GetValue('enable')
            end,
            currentValue = function()
                return objectiveTracker.Data:GetValue(prefix .. 'FontSize')
            end,
            onChange = function(value)
                objectiveTracker.Data:SetValue(prefix .. 'FontSize', value)
                objectiveTracker:Configure()
            end,
            width = 25,
        },
    }
end

function styleOptions:GetOptions()
    local options = {
        {
            type = 'title',
            label = 'Fonts',
            width = 100,
            depends = function()
                return objectiveTracker.Data:GetValue('enable')
            end,
        },
    }

    for _, field in ipairs(fontFields('container', 'Container Title')) do
        table.insert(options, field)
    end
    for _, field in ipairs(fontFields('moduleHeader', 'Category Header')) do
        table.insert(options, field)
    end
    for _, field in ipairs(fontFields('blockHeader', 'Block Title')) do
        table.insert(options, field)
    end
    for _, field in ipairs(fontFields('line', 'Objective Line')) do
        table.insert(options, field)
    end

    table.insert(options, {
        type = 'dropdown',
        label = 'Text Alignment',
        name = 'textAlign',
        getOptions = function()
            return {
                LEFT = 'Left',
                RIGHT = 'Right',
            }
        end,
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('textAlign')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('textAlign', value)
            objectiveTracker:Configure()
        end,
        width = 50,
    })

    table.insert(options, {
        type = 'title',
        label = 'Progress Bar',
        size = 14,
        width = 100,
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
    })
    table.insert(options, {
        type = 'range',
        label = 'Bar Height',
        name = 'progressBarHeight',
        min = 6,
        max = 24,
        step = 1,
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('progressBarHeight')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('progressBarHeight', value)
            objectiveTracker:Configure()
        end,
        width = 50,
    })
    table.insert(options, {
        type = 'range',
        label = 'Border Thickness',
        name = 'progressBarBorderThickness',
        min = 0,
        max = 3,
        step = 1,
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('progressBarBorderThickness')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('progressBarBorderThickness', value)
            objectiveTracker:Configure()
        end,
        width = 50,
    })
    table.insert(options, {
        type = 'color-picker',
        label = 'Fill Color',
        name = 'progressBarFillColor',
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('progressBarFillColor')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('progressBarFillColor', value)
            objectiveTracker:Configure()
        end,
        width = 33,
    })
    table.insert(options, {
        type = 'color-picker',
        label = 'Background Color',
        name = 'progressBarBackgroundColor',
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('progressBarBackgroundColor')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('progressBarBackgroundColor', value)
            objectiveTracker:Configure()
        end,
        width = 33,
    })
    table.insert(options, {
        type = 'color-picker',
        label = 'Border Color',
        name = 'progressBarBorderColor',
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('progressBarBorderColor')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('progressBarBorderColor', value)
            objectiveTracker:Configure()
        end,
        width = 34,
    })

    table.insert(options, {
        type = 'title',
        label = 'Colors',
        size = 14,
        width = 100,
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
    })

    for _, colorDef in ipairs(COLOR_KEYS) do
        table.insert(options, {
            type = 'color-picker',
            label = colorDef.label,
            name = 'color_' .. colorDef.key,
            depends = function()
                return objectiveTracker.Data:GetValue('enable')
            end,
            currentValue = function()
                local colors = objectiveTracker.Data:GetValue('colors')
                return colors[colorDef.key]
            end,
            onChange = function(value)
                local colors = objectiveTracker.Data:GetValue('colors')
                colors[colorDef.key] = value
                objectiveTracker.Data:SetValue('colors', colors)
                objectiveTracker:Configure()
            end,
            width = 50,
        })
    end

    table.insert(options, {
        type = 'color-picker',
        label = 'Super-Track Highlight',
        name = 'superTrackColor',
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('superTrackColor')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('superTrackColor', value)
            objectiveTracker:Configure()
        end,
        width = 50,
    })

    table.insert(options, {
        type = 'title',
        label = 'Header Styling',
        size = 14,
        width = 100,
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
    })
    table.insert(options, {
        type = 'toggle',
        label = 'Custom Category Header Style',
        name = 'customHeaderStyle',
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('customHeaderStyle', value)
            objectiveTracker:Configure()
            optionsFields:RefreshOptionsDelayed()
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('customHeaderStyle')
        end,
        width = 100,
    })
    table.insert(options, {
        type = 'color-picker',
        label = 'Header Background',
        name = 'headerBackgroundColor',
        depends = function()
            return customHeaderStyleEnabled()
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('headerBackgroundColor')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('headerBackgroundColor', value)
            objectiveTracker:Configure()
        end,
        width = 50,
    })
    table.insert(options, {
        type = 'color-picker',
        label = 'Header Border',
        name = 'headerBorderColor',
        depends = function()
            return customHeaderStyleEnabled()
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('headerBorderColor')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('headerBorderColor', value)
            objectiveTracker:Configure()
        end,
        width = 50,
    })
    table.insert(options, {
        type = 'range',
        label = 'Header Border Thickness',
        name = 'headerBorderThickness',
        min = 0,
        max = 3,
        step = 1,
        depends = function()
            return customHeaderStyleEnabled()
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('headerBorderThickness')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('headerBorderThickness', value)
            objectiveTracker:Configure()
        end,
        width = 50,
    })
    table.insert(options, {
        type = 'toggle',
        label = 'Category Header Underline',
        name = 'showCategoryHeaderLine',
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('showCategoryHeaderLine', value)
            objectiveTracker:Configure()
            optionsFields:RefreshOptionsDelayed()
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('showCategoryHeaderLine')
        end,
        width = 100,
    })
    table.insert(options, {
        type = 'color-picker',
        label = 'Category Header Underline Color',
        name = 'categoryHeaderLineColor',
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
                and objectiveTracker.Data:GetValue('showCategoryHeaderLine')
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('categoryHeaderLineColor')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('categoryHeaderLineColor', value)
            objectiveTracker:Configure()
        end,
        width = 50,
    })
    table.insert(options, {
        type = 'range',
        label = 'Category Header Underline Thickness',
        name = 'categoryHeaderLineThickness',
        min = 1,
        max = 4,
        step = 1,
        depends = function()
            return objectiveTracker.Data:GetValue('enable')
                and objectiveTracker.Data:GetValue('showCategoryHeaderLine')
        end,
        currentValue = function()
            return objectiveTracker.Data:GetValue('categoryHeaderLineThickness')
        end,
        onChange = function(value)
            objectiveTracker.Data:SetValue('categoryHeaderLineThickness', value)
            objectiveTracker:Configure()
        end,
        width = 50,
    })

    return options
end
