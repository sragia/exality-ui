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
            onObserve = function(value, oldValue)
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
            onObserve = function(value, oldValue)
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
            onChange = function(f, value)
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
            onChange = function(f, value)
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
            onChange = function(f, value)
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
            onChange = function(f, value)
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
            onChange = function(f, value)
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
            onChange = function(f, value)
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
            onChange = function(f, value)
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
            onObserve = function(value, oldValue)
                core:UpdateValueForUnit(unit, prefix .. 'OnlyShowPlayer', value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'OnlyShowPlayer')
            end,
            width = 100
        },
    }
end