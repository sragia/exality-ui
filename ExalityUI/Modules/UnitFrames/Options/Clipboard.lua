---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsCore
local optionsCore = EXUI:GetModule('uf-options-core')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIUnitFramesOptionsClipboard
local clipboard = EXUI:GetModule('uf-options-clipboard')

local ALL = 'all'

local function ToSet(keys)
    local set = {}
    for _, key in ipairs(keys) do
        set[key] = true
    end
    return set
end

-- Keyed by menu item id. Auras are shared displays, not per unit settings.
local ELEMENTS = {
    general = {
        keys = ToSet({
            'fadeOutOfRange', 'overrideFrameStyle', 'overrideFrameBorderColor', 'frameBorderColor',
            'frameBorderClassColor',
            'overrideStatusBarTexture', 'overrideBackgroundTexture', 'overrideDamageAbsorbTexture',
            'overrideHealAbsorbTexture',
            'overrideHealthColor', 'useCustomHealthColor', 'useSmoothHealthColor', 'customHealthColor',
            'useClassColoredBackdrop', 'useCustomBackdropColor', 'customBackdropColor',
            'useCustomHealthAbsorbsColor', 'damageAbsorbColor', 'healAbsorbColor',
            'targetBorderEnable', 'targetBorderColor', 'mouseoverBorderEnable', 'mouseoverBorderColor',
        }),
    },
    sizeposition = {
        keys = ToSet({
            'sizeWidth', 'sizeHeight', 'positionAnchorPoint', 'positionRelativePoint', 'positionXOff',
            'positionYOff', 'spacing', 'spacingX', 'spacingY', 'groupDirection',
        }),
    },
    absorbs = {
        keys = ToSet({
            'damageAbsorbEnable', 'damageAbsorbShowAt', 'damageAbsorbShowOverIndicator', 'healAbsorbEnable',
            'healAbsorbShowOverIndicator',
        }),
    },
    customtexts = { keys = ToSet({ 'customTexts' }) },
    name = { prefix = 'name' },
    health = { prefix = 'health' },
    healthperc = { prefix = 'healthperc' },
    power = { prefix = 'power' },
    portrait = { prefix = 'portrait' },
    castbar = { prefix = 'castbar' },
    markericon = { prefix = 'raidTargetIndicator' },
    raidroles = { prefix = 'raidRoles' },
    combatindicator = { prefix = 'combatIndicator' },
    offline = { prefix = 'offline' },
    resurrectindicator = { prefix = 'ressurect' },
    summonindicator = { prefix = 'summon' },
    phaseindicator = { prefix = 'phaseIndicator' },
    grouproleindicator = { prefix = 'groupRoleIndicator' },
    dispeloverlay = { prefix = 'dispelOverlay' },
}

-- Copying a whole unit keeps it enabled as it was and where it was.
local EXCLUDED_FROM_ALL = ToSet({
    'enable', 'showBlizzardFrame', 'positionAnchorPoint', 'positionRelativePoint', 'positionXOff', 'positionYOff',
    'castbarAnchorPointUIParent', 'castbarRelativeAnchorPointUIParent', 'castbarXOffUIParent', 'castbarYOffUIParent',
})

local function ShouldCopy(elementID, key)
    if elementID == ALL then
        return not EXCLUDED_FROM_ALL[key]
    end
    local element = ELEMENTS[elementID]
    if element.keys then
        return element.keys[key]
    end
    return key:match('^' .. element.prefix .. '%u') ~= nil
end

-- Keys like frame levels have no default, so a missing key doesn't mean the unit can't use it
local function CanPasteKey(unit, key)
    if ufCore:GetValueForUnit(unit, key) ~= nil then
        return true
    end
    local _, tab = FindInTableIf(optionsCore.options, function(option) return option.id == unit end)
    local _, item = FindInTableIf(tab.menu, function(menuItem)
        return ELEMENTS[menuItem.id] ~= nil and ShouldCopy(menuItem.id, key)
    end)
    return item ~= nil
end

local function CloneValue(value)
    if type(value) == 'table' then
        return EXUI.utils.deepCloneTable(value)
    end
    return value
end

clipboard.Copy = function(self, unit, unitName, elementID)
    local values = {}
    for key, value in pairs(ufCore:GetDBForUnit(unit)) do
        if ShouldCopy(elementID, key) then
            values[key] = CloneValue(value)
        end
    end
    -- Absent until the first text is made, pasting that should clear the target's texts
    if elementID == ALL or elementID == 'customtexts' then
        values.customTexts = values.customTexts or {}
    end
    self.copied = { unit = unit, unitName = unitName, elementID = elementID, values = values }
end

clipboard.CanPaste = function(self, unit, elementID)
    local copied = self.copied
    return copied ~= nil and copied.elementID == elementID and copied.unit ~= unit
end

clipboard.Paste = function(self, unit)
    for key, value in pairs(self.copied.values) do
        if CanPasteKey(unit, key) then
            ufCore:UpdateValueForUnit(unit, key, CloneValue(value))
        end
    end
    ufCore:UpdateFrameForUnit(unit)

    -- Pasted unit might not be the one on screen, every cached view could be stale
    optionsFields:InvalidateFieldCache()
    optionsFields:RefreshFields()
end

local function BuildMenu(unit, unitName, elementID, copyLabel, pasteLabel)
    return {
        {
            label = copyLabel,
            onClick = function()
                clipboard:Copy(unit, unitName, elementID)
            end,
        },
        {
            getLabel = function()
                return string.format('%s from %s', pasteLabel, clipboard.copied.unitName)
            end,
            isVisible = function()
                return clipboard:CanPaste(unit, elementID)
            end,
            onClick = function()
                clipboard:Paste(unit)
            end,
        },
    }
end

clipboard.GetTabMenu = function(self, tab)
    if tab.id == 'general' then
        return nil
    end
    return BuildMenu(tab.id, tab.name, ALL, 'Copy All Settings', 'Paste All Settings')
end

clipboard.GetItemMenu = function(self, tab, item)
    if tab.id == 'general' or not ELEMENTS[item.id] then
        return nil
    end
    return BuildMenu(tab.id, tab.name, item.id, 'Copy ' .. item.name, 'Paste ' .. item.name)
end
