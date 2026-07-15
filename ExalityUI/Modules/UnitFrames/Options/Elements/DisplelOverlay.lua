---@class ExalityUI
local EXUI = select(2, ...)

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
                if unit == 'party' or unit == 'raid' then
                    EXUI:GetModule('uf-auras-apply'):EnsureHeaderContainers(unit)
                end
                UFCore:UpdateFrameForUnit(unit)
            end,
            currentValue = function()
                return UFCore:GetValueForUnit(unit, 'dispelOverlayEnable')
            end,
            width = 100
        },
        {
            type = 'dropdown',
            label = 'Show When',
            name = 'dispelOverlayFilter',
            getOptions = function()
                return {
                    RAID = 'I can dispel',
                    RAID_PLAYER_DISPELLABLE = 'Anyone in Raid can dispel',
                    DISPELLABLE = 'Has dispellable debuff',
                }
            end,
            currentValue = function()
                return UFCore:GetValueForUnit(unit, 'dispelOverlayFilter') or 'RAID'
            end,
            depends = function()
                return UFCore:GetValueForUnit(unit, 'dispelOverlayEnable')
            end,
            onChange = function(value)
                UFCore:UpdateValueForUnit(unit, 'dispelOverlayFilter', value)
                UFCore:UpdateFrameForUnit(unit)
            end,
            width = 50
        },
        {
            type = 'spacer',
            width = 50
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
