---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIUnitFramesOptionsGenericAuras
local genericAuras = EXUI:GetModule('uf-options-generic-auras')

genericAuras.GetOptions = function(self, unit, prefix, isBuffs)
    return {
        {
            type = 'toggle',
            label = 'Enable',
            name = prefix .. 'Enable',
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'Enable', value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'Enable')
            end,
            width = 100
        },
        {
            type = 'title',
            label = 'Position & Size',
            width = 100
        },
        {
            type = 'toggle',
            label = isBuffs and 'Anchor To Debuffs' or 'Anchor To Buffs',
            name = prefix .. 'AnchorTo' .. (isBuffs and 'Debuffs' or 'Buffs'),
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'AnchorTo' .. (isBuffs and 'Debuffs' or 'Buffs'), value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'AnchorTo' .. (isBuffs and 'Debuffs' or 'Buffs'))
            end,
            width = 100
        },
        {
            type = 'range',
            label = 'Icon Width',
            name = prefix .. 'IconWidth',
            min = 5,
            max = 100,
            step = 1,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'IconWidth', value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'IconWidth')
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Icon Height',
            name = prefix .. 'IconHeight',
            min = 5,
            max = 100,
            step = 1,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'IconHeight', value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'IconHeight')
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Spacing',
            name = prefix .. 'Spacing',
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'Spacing', value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'Spacing')
            end,
            width = 20
        },
        {
            type = 'spacer',
            width = 40
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
        },
        {
            type = 'title',
            label = 'Adjustments',
            width = 100
        },
        {
            type = 'range',
            label = 'Number of Auras',
            name = prefix .. 'Num',
            min = 1,
            max = 100,
            step = 1,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'Num', value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'Num')
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Number of Columns',
            name = prefix .. 'ColNum',
            min = 1,
            max = 100,
            step = 1,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'ColNum', value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'ColNum')
            end,
            width = 20
        },
        {
            type = 'spacer',
            width = 60
        },
        {
            type = 'toggle',
            label = 'Only Show Player Auras',
            name = prefix .. 'OnlyShowPlayer',
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'OnlyShowPlayer', value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'OnlyShowPlayer')
            end,
            width = 100
        },
        {
            type = 'title',
            label = 'Texts',
            width = 100
        },
        {
            type = 'title',
            label = 'Count',
            width = 100,
            size = 14
        },
        {
            type = 'title',
            width = 100,
            label = 'Font Style',
            size = 12
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = prefix .. 'CountFont',
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
                return core:GetValueForUnit(unit, prefix .. 'CountFont')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'CountFont', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = prefix .. 'CountFontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'CountFontFlag')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'CountFontFlag', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'Size',
            name = prefix .. 'CountFontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'CountFontSize')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'CountFontSize', value)
                core:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'color-picker',
            label = 'Color',
            name = prefix .. 'CountFontColor',
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'CountFontColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'CountFontColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'title',
            width = 100,
            label = 'Position',
            size = 12
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = prefix .. 'CountAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'CountAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'CountAnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = prefix .. 'CountRelativeAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'CountRelativeAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'CountRelativeAnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'X Offset',
            name = prefix .. 'CountXOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'CountXOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'CountXOff', value)
                core:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = prefix .. 'CountYOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'CountYOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'CountYOff', value)
                core:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'title',
            label = 'Duration',
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = prefix .. 'DurationFont',
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
                return core:GetValueForUnit(unit, prefix .. 'DurationFont')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'DurationFont', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = prefix .. 'DurationFontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'DurationFontFlag')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'DurationFontFlag', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'Size',
            name = prefix .. 'DurationFontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'DurationFontSize')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'DurationFontSize', value)
                core:UpdateFrameForUnit(unit)
            end
        },
    }
end
