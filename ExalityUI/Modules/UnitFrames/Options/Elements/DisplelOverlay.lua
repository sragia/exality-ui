---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local UFCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsDispelOverlay
local dispelOverlay = EXUI:GetModule('uf-options-dispel-overlay')

---@class EXUIUnitFramesOptionsGenericPosition
local genericPosition = EXUI:GetModule('uf-options-generic-position')

local append = EXUI.utils.append

local function refreshUnit(unit)
    if unit == 'party' or unit == 'raid' then
        EXUI:GetModule('uf-auras-apply'):EnsureHeaderContainers(unit)
    end
    UFCore:UpdateFrameForUnit(unit)
end

local function IsEnabled(unit)
    return UFCore:GetValueForUnit(unit, 'dispelOverlayEnable')
end

local function ShowOverlay(unit)
    local value = UFCore:GetValueForUnit(unit, 'dispelOverlayShowOverlay')
    if value ~= nil then
        return value
    end
    return (UFCore:GetValueForUnit(unit, 'dispelOverlayStyle') or 'Overlay') ~= 'Icon'
end

local function ShowIcon(unit)
    local value = UFCore:GetValueForUnit(unit, 'dispelOverlayShowIcon')
    if value ~= nil then
        return value
    end
    return UFCore:GetValueForUnit(unit, 'dispelOverlayStyle') == 'Icon'
end

dispelOverlay.GetOptions = function(self, unit)
    local fields = {
        {
            type = 'description',
            label = 'Show indicator for dispellable auras',
            width = 100
        },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'dispelOverlayEnable',
            onChange = function(value)
                UFCore:UpdateValueForUnit(unit, 'dispelOverlayEnable', value)
                refreshUnit(unit)
                EXUI:GetModule('options-fields'):RefreshOptions()
            end,
            currentValue = function()
                return IsEnabled(unit)
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
                return IsEnabled(unit)
            end,
            onChange = function(value)
                UFCore:UpdateValueForUnit(unit, 'dispelOverlayFilter', value)
                refreshUnit(unit)
            end,
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
            depends = function()
                return IsEnabled(unit)
            end,
            onChange = function(value)
                UFCore:UpdateValueForUnit(unit, 'dispelOverlayAlpha', value)
                refreshUnit(unit)
            end,
            width = 50
        },
        {
            type = 'title',
            label = 'Display',
            width = 100,
            depends = function()
                return IsEnabled(unit)
            end,
        },
        {
            type = 'toggle',
            label = 'Overlay',
            name = 'dispelOverlayShowOverlay',
            currentValue = function()
                return ShowOverlay(unit)
            end,
            depends = function()
                return IsEnabled(unit)
            end,
            onChange = function(value)
                UFCore:UpdateValueForUnit(unit, 'dispelOverlayShowOverlay', value and true or false)
                refreshUnit(unit)
                EXUI:GetModule('options-fields'):RefreshOptions()
            end,
            width = 100
        },
        {
            type = 'toggle',
            label = 'Icon',
            name = 'dispelOverlayShowIcon',
            currentValue = function()
                return ShowIcon(unit)
            end,
            depends = function()
                return IsEnabled(unit)
            end,
            onChange = function(value)
                UFCore:UpdateValueForUnit(unit, 'dispelOverlayShowIcon', value and true or false)
                refreshUnit(unit)
                EXUI:GetModule('options-fields'):RefreshOptions()
            end,
            width = 100
        },
    }

    if IsEnabled(unit) and ShowIcon(unit) then
        append(fields, {
            {
                type = 'range',
                label = 'Icon Size',
                name = 'dispelOverlayIconSize',
                min = 8,
                max = 64,
                step = 1,
                currentValue = function()
                    return UFCore:GetValueForUnit(unit, 'dispelOverlayIconSize') or 16
                end,
                onChange = function(value)
                    UFCore:UpdateValueForUnit(unit, 'dispelOverlayIconSize', value)
                    refreshUnit(unit)
                end,
                width = 50
            },
        })
        append(fields, genericPosition:GetOptions(unit, 'dispelOverlay'))
    end

    return fields
end
