---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIUnitFramesOptionsGenericEnable
local genericEnable = EXUI:GetModule('uf-options-generic-enable')

genericEnable.GetOptions = function(self, unit, prefix)
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
    }
end