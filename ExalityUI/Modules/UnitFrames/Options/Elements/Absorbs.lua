---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsCore
local optionsCore = EXUI:GetModule('uf-options-core')


---@class EXUIUnitFramesOptionsAbsorbs
local absorbs = EXUI:GetModule('uf-options-absorbs')

absorbs.GetOptions = function(self, unit)
    return {
        {
            type = 'title',
            label = 'Damage Absorb',
            width = 100
        },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'damageAbsorbEnable',
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'damageAbsorbEnable', value)
                core:UpdateFrameForUnit(unit)
                optionsCore:RefreshCurrentView()
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'damageAbsorbEnable')
            end,
            width = 100
        },
        {
            type = 'dropdown',
            label = 'Show Damage Absorb:',
            name = 'damageAbsorbShowAt',
            getOptions = function()
                return {
                    ['AS_EXTENSION'] = 'As Extension of Health',
                    ['AT_END'] = 'At the End of the Health Bar',
                    ['AT_START'] = 'At the Start of the Health Bar',
                }
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'damageAbsorbShowAt')
            end,
            depends = function()
                return core:GetValueForUnit(unit, 'damageAbsorbEnable')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'damageAbsorbShowAt', value)
                core:UpdateFrameForUnit(unit)
                optionsCore:RefreshCurrentView()
            end,
            width = 50
        },
        {
            type = 'toggle',
            label = 'Show Over Damage Absorb Indicator',
            name = 'damageAbsorbShowOverIndicator',
            depends = function()
                return core:GetValueForUnit(unit, 'damageAbsorbEnable') and
                    core:GetValueForUnit(unit, 'damageAbsorbShowAt') == 'AS_EXTENSION'
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'damageAbsorbShowOverIndicator', value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'damageAbsorbShowOverIndicator')
            end,
            width = 100
        },
        {
            type = 'title',
            label = 'Heal Absorb',
            width = 100
        },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'healAbsorbEnable',
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'healAbsorbEnable', value)
                core:UpdateFrameForUnit(unit)
                optionsCore:RefreshCurrentView()
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'healAbsorbEnable')
            end,
            width = 100
        },
        {
            type = 'toggle',
            label = 'Show Over Heal Absorb Indicator',
            name = 'healAbsorbShowOverIndicator',
            depends = function()
                return core:GetValueForUnit(unit, 'healAbsorbEnable')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'healAbsorbShowOverIndicator', value)
                core:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'healAbsorbShowOverIndicator')
            end,
            width = 100
        },
    }
end
