---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsGenericPosition
local genericPosition = EXUI:GetModule('uf-options-generic-position')

genericPosition.GetOptions = function(self, unit, prefix)
    return {
        {
            type = 'title',
            width = 100,
            label = 'Position',
            size = 18
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = prefix .. 'AnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'AnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'AnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 22
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = prefix .. 'RelativeAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'RelativeAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'RelativeAnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 22
        },
        {
            type = 'range',
            label = 'X Offset',
            name = prefix .. 'XOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'XOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'XOff', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = prefix .. 'YOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'YOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'YOff', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        }
    }
end
