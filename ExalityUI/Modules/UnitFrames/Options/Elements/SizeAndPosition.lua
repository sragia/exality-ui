---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsSizeAndPosition
local sizeAndPosition = EXUI:GetModule('uf-options-size-and-position')

sizeAndPosition.GetOptions = function(self, unit)
    return {
        {
            type = 'title',
            width = 100,
            label = 'Size',
            size = 18
        },
        {
            type = 'range',
            label = 'Width',
            name = 'sizeWidth',
            min = 1,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForUnit(unit, 'sizeWidth')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'sizeWidth', value)
                core:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'range',
            label = 'Height',
            name = 'sizeHeight',
            min = 1,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForUnit(unit, 'sizeHeight')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'sizeHeight', value)
                core:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'title',
            width = 100,
            label = 'Position',
            size = 18
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = 'positionAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'positionAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'positionAnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 22
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'positionRelativePoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'positionRelativePoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'positionRelativePoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 22
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'positionXOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, 'positionXOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'positionXOff', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'positionYOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, 'positionYOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'positionYOff', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        }
    }
end
