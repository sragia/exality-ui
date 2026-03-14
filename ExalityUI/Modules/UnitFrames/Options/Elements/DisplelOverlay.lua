---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')


---@class EXUIUnitFramesOptionsCore
local optionsCore = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local UFCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsDispelOverlay
local dispelOverlay = EXUI:GetModule('uf-options-dispel-overlay')

dispelOverlay.GetOptions = function(self, unit)
    return {
        {
            type = 'description',
            label = 'Shows colored overlay for dispellable harmful auras.',
            width = 100
        },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'dispelOverlayEnable',
            onChange = function(value)
                UFCore:UpdateValueForUnit(unit, 'dispelOverlayEnable', value)
                UFCore:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return UFCore:GetValueForUnit(unit, 'dispelOverlayEnable')
            end,
            width = 100
        },
        {
            type = 'range',
            label = 'Alpha',
            name = 'dispelOverlayAlpha',
            min = 0,
            max = 1,
            step = 0.1,
            currentValue = function()
                return UFCore:GetValueForUnit(unit, 'dispelOverlayAlpha')
            end,
            onChange = function(value)
                UFCore:UpdateValueForUnit(unit, 'dispelOverlayAlpha', value)
                UFCore:UpdateFrameForUnit(unit)
            end,
            width = 30
        }
    }
end
