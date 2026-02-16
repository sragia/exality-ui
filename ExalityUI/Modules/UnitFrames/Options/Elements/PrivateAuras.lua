---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsCore
local optionsCore = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesOptionsPrivateAuras
local privateAuras = EXUI:GetModule('uf-options-private-auras')

privateAuras.GetOptions = function(self, unit)
    return {
        {
            type = 'title',
            width = 100,
            label = 'Aura Configuration',
        },
        {
            type = 'range',
            label = 'Maximum Auras',
            name = 'privateAurasMaxNum',
            min = 1,
            max = 10,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasMaxNum')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasMaxNum', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Maximum Columns',
            name = 'privateAurasMaxCols',
            tooltip = {
                text = 'Maximum number of private aura columns before wrapping to a new row'
            },
            min = 1,
            max = 10,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasMaxCols')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasMaxCols', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'spacer',
            width = 60
        },
        {
            type = 'range',
            label = 'Icon Width',
            name = 'privateAurasIconWidth',
            min = 1,
            max = 100,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasIconWidth')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasIconWidth', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Icon Height',
            name = 'privateAurasIconHeight',
            min = 1,
            max = 100,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasIconHeight')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasIconHeight', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'toggle',
            label = 'Disable Border',
            name = 'privateAurasDisableBorder',
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasDisableBorder')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasDisableBorder', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 100
        },
        {
            type = 'toggle',
            label = 'Disable Tooltip',
            name = 'privateAurasDisableTooltip',
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasDisableTooltip')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasDisableTooltip', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 100
        },
        {
            type = 'range',
            label = 'Spacing X',
            name = 'privateAurasSpacingX',
            min = -3,
            max = 100,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasSpacingX')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasSpacingX', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Spacing Y',
            name = 'privateAurasSpacingY',
            min = -3,
            max = 100,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasSpacingY')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasSpacingY', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'dropdown',
            label = 'X Growth Direction',
            name = 'privateAurasGrowthX',
            getOptions = function()
                return {
                    ['RIGHT'] = 'Right',
                    ['LEFT'] = 'Left',
                }
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasGrowthX')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasGrowthX', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },

        {
            type = 'dropdown',
            label = 'Y Growth Direction',
            name = 'privateAurasGrowthY',
            getOptions = function()
                return {
                    ['UP'] = 'Up',
                    ['DOWN'] = 'Down',
                }
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasGrowthY')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasGrowthY', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'spacer',
            width = 20
        },
        {
            type = 'toggle',
            label = 'Disable Cooldown Spiral',
            name = 'privateAurasDisableCooldownSpiral',
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasDisableCooldownSpiral')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasDisableCooldownSpiral', value)
                core:UpdateFrameForUnit(unit)
                optionsCore:RefreshCurrentView()
            end,
            width = 100
        },
        {
            type = 'toggle',
            label = 'Disable Cooldown Text',
            name = 'privateAurasDisableCooldownText',
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasDisableCooldownText')
            end,
            depends = function()
                return not core:GetValueForUnit(unit, 'privateAurasDisableCooldownSpiral')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasDisableCooldownText', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 100
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
            name = 'privateAurasAnchorPoint',
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasAnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'privateAurasRelativeAnchorPoint',
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasRelativeAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasRelativeAnchorPoint', value)
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
            name = 'privateAurasXOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasXOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasXOff', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'privateAurasYOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, 'privateAurasYOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'privateAurasYOff', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        }
    }
end
