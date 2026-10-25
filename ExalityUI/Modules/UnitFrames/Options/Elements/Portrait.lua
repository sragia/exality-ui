---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local UFCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsPortrait
local portraitOptions = EXUI:GetModule('uf-options-portrait')

---@class EXUIUnitFramesOptionsGenericPosition
local genericPosition = EXUI:GetModule('uf-options-generic-position')

local append = EXUI.utils.append

local function GetValue(unit, key)
    return UFCore:GetValueForUnit(unit, key)
end

local function SetValue(unit, key, value, refreshOptions)
    UFCore:UpdateValueForUnit(unit, key, value)
    UFCore:UpdateFrameForUnit(unit)
    if refreshOptions then
        EXUI:GetModule('options-fields'):RefreshOptions()
    end
end

portraitOptions.GetOptions = function(self, unit)
    local fields = {
        {
            type = 'toggle',
            label = 'Enable',
            name = 'portraitEnable',
            currentValue = function()
                return GetValue(unit, 'portraitEnable')
            end,
            onChange = function(value)
                SetValue(unit, 'portraitEnable', value, true)
            end,
            width = 100
        },
    }

    if not GetValue(unit, 'portraitEnable') then
        return fields
    end

    local style = GetValue(unit, 'portraitStyle')
    local supportsModel = EXUI:GetModule('uf-element-portrait'):SupportsModel(style)
    local isModel = supportsModel and GetValue(unit, 'portraitType') == 'model'

    if style == 'attached' then
        append(fields, {
            {
                type = 'dropdown',
                label = 'Side',
                name = 'portraitAttachedSide',
                getOptions = function()
                    return {
                        LEFT = 'Left',
                        RIGHT = 'Right',
                    }
                end,
                currentValue = function()
                    return GetValue(unit, 'portraitAttachedSide')
                end,
                onChange = function(value)
                    SetValue(unit, 'portraitAttachedSide', value)
                end,
                width = 33
            },
            {
                type = 'range',
                label = 'Width',
                name = 'portraitAttachedWidth',
                min = 4,
                max = 200,
                step = 1,
                currentValue = function()
                    return GetValue(unit, 'portraitAttachedWidth')
                end,
                onChange = function(value)
                    SetValue(unit, 'portraitAttachedWidth', value)
                end,
                width = 33
            },
        })
    else
        append(fields, {
            {
                type = 'range',
                label = 'Size',
                name = 'portraitSize',
                min = 8,
                max = 256,
                step = 1,
                currentValue = function()
                    return GetValue(unit, 'portraitSize')
                end,
                onChange = function(value)
                    SetValue(unit, 'portraitSize', value)
                end,
                width = 33
            },
        })
    end

    append(fields, {
        {
            type = 'spacer',
            width = style == 'attached' and 34 or 67
        },
    })

    append(fields, {
        {
            type = 'dropdown',
            label = 'Style',
            name = 'portraitStyle',
            getOptions = function()
                return {
                    circle = 'Circle',
                    hexagon = 'Hexagon',
                    square = 'Square',
                    attached = 'Attached',
                }
            end,
            currentValue = function()
                return GetValue(unit, 'portraitStyle')
            end,
            onChange = function(value)
                SetValue(unit, 'portraitStyle', value, true)
            end,
            width = 33
        },
    })

    if supportsModel then
        append(fields, {
            {
                type = 'dropdown',
                label = 'Type',
                name = 'portraitType',
                getOptions = function()
                    return {
                        static = 'Static',
                        model = 'Model',
                    }
                end,
                currentValue = function()
                    return GetValue(unit, 'portraitType')
                end,
                onChange = function(value)
                    SetValue(unit, 'portraitType', value, true)
                end,
                width = 33
            },
        })
    end

    if not isModel then
        append(fields, {
            {
                type = 'toggle',
                label = 'Class Icon',
                name = 'portraitClassIcon',
                currentValue = function()
                    return GetValue(unit, 'portraitClassIcon')
                end,
                onChange = function(value)
                    SetValue(unit, 'portraitClassIcon', value)
                end,
                width = 33
            },
        })
    end

    append(fields, {
        {
            type = 'title',
            width = 100,
            label = 'Border',
            size = 18
        },
    })

    append(fields, {
        {
            type = 'toggle',
            label = 'Use Class Color',
            name = 'portraitBorderClassColor',
            currentValue = function()
                return GetValue(unit, 'portraitBorderClassColor')
            end,
            onChange = function(value)
                SetValue(unit, 'portraitBorderClassColor', value, true)
            end,
            width = 33
        },
    })

    if not GetValue(unit, 'portraitBorderClassColor') then
        append(fields, {
            {
                type = 'color-picker',
                label = 'Border Color',
                name = 'portraitBorderColor',
                currentValue = function()
                    return GetValue(unit, 'portraitBorderColor')
                end,
                onChange = function(value)
                    SetValue(unit, 'portraitBorderColor', value)
                end,
                width = 33
            },
        })
    end

    if style ~= 'attached' then
        append(fields, genericPosition:GetOptions(unit, 'portrait'))
    end

    return fields
end
