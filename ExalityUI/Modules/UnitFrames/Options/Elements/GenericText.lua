---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIUnitFramesOptionsGenericText
local genericText = EXUI:GetModule('uf-options-generic-text')

genericText.GetOptions = function(self, unit, prefix)
    return {
        {
            type = 'title',
            width = 100,
            label = 'Font Style',
            size = 18
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = prefix .. 'Font',
            getOptions = function()
                local fonts = LSM:List('font')
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'Font')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'Font', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = prefix .. 'FontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'FontFlag')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'FontFlag', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'Size',
            name = prefix .. 'FontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'FontSize')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'FontSize', value)
                core:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'color-picker',
            label = 'Color',
            name = prefix .. 'FontColor',
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'FontColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'FontColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'title',
            width = 100,
            label = 'Position',
            size = 18
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = prefix .. 'AnchorPoint',
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'AnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'AnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = prefix .. 'RelativeAnchorPoint',
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'RelativeAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'RelativeAnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'spacer',
            width = 54
        },
        {
            type = 'range',
            label = 'X Offset',
            name = prefix .. 'XOffset',
            min = -1000,
            max = 1000,
            step = 1,
            width = 23,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'XOffset')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'XOffset', value)
                core:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = prefix .. 'YOffset',
            min = -1000,
            max = 1000,
            step = 1,
            width = 23,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'YOffset')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'YOffset', value)
                core:UpdateFrameForUnit(unit)
            end
        }
    }
end
