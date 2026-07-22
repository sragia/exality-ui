---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysDefaults
local adDefaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUIUnitFramesAurasDefaults
local defaults = EXUI:GetModule('uf-auras-defaults')

defaults.SCHEMA_VERSION = 3

defaults.UNIT_OPTIONS = {
    player = 'Player',
    target = 'Target',
    targettarget = 'Target Target',
    focus = 'Focus',
    pet = 'Pet',
    party = 'Party',
    raid = 'Raid',
    boss = 'Boss',
    arena = 'Arena',
}

defaults.UNIT_ORDER = {
    'player',
    'target',
    'targettarget',
    'focus',
    'pet',
    'party',
    'raid',
    'boss',
    'arena',
}

function defaults:CopyTable(source)
    return EXUI.utils.deepCloneTable(source)
end

function defaults:BuildNewGroup()
    return adDefaults:BuildNewGroup()
end

function defaults:BuildNewDisplay(contextUnit)
    local displayID, display = adDefaults:BuildNewDisplay()
    display.name = 'New Unit Frame Aura'
    display.anchorPoint = 'BOTTOMLEFT'
    display.relativePoint = 'TOPLEFT'
    display.XOff = 0
    display.YOff = 2
    display.containerAnchorPoint = 'BOTTOMLEFT'
    display.horizontalGrowth = 'RIGHT'
    display.verticalGrowth = 'UP'
    -- Offset above ElementFrame (border lives there at unit frame level + 100).
    display.frameStrata = 'LOW'
    display.frameLevel = 10
    display.rowWidth = 200
    display.matchUnitFrameWidth = true
    display.units = {}
    if contextUnit then
        display.units[contextUnit] = true
    end
    -- Drop free-floating unit tracker; UF uses display.units instead.
    if display.container then
        display.container.unit = nil
        display.container.unitCustom = nil
    end
    return displayID, display
end

function defaults:MergeGroupDefaults(group)
    adDefaults:MergeGroupDefaults(group)
end

function defaults:MergeIntoDB(db)
    local oldVersion = db.__exuiDefaultsVersion or 0
    if not db.displays then
        db.displays = {}
    end
    for _, display in pairs(db.displays) do
        if display.enable == nil then
            display.enable = true
        end
        if not display.name then
            display.name = 'Unit Frame Aura'
        end
        if not display.units then
            display.units = {}
        end
        if display.anchorPoint == nil then
            display.anchorPoint = 'BOTTOMLEFT'
        end
        if display.relativePoint == nil then
            display.relativePoint = 'TOPLEFT'
        end
        if display.XOff == nil then
            display.XOff = 0
        end
        if display.YOff == nil then
            display.YOff = 2
        end
        if display.frameStrata == nil then
            display.frameStrata = 'LOW'
        end
        if display.frameLevel == nil then
            display.frameLevel = 10
        end
        if display.containerAnchorPoint == nil then
            display.containerAnchorPoint = 'BOTTOMLEFT'
        end
        if display.horizontalGrowth == nil then
            display.horizontalGrowth = 'RIGHT'
        end
        if display.verticalGrowth == nil then
            display.verticalGrowth = 'UP'
        end
        if display.paddingLeft == nil then
            display.paddingLeft = 0
        end
        if display.paddingRight == nil then
            display.paddingRight = 0
        end
        if display.paddingTop == nil then
            display.paddingTop = 0
        end
        if display.paddingBottom == nil then
            display.paddingBottom = 0
        end
        if display.rowWidth == nil then
            display.rowWidth = 200
        end
        if display.matchUnitFrameWidth == nil then
            display.matchUnitFrameWidth = true
        end
        if not display.container then
            display.container = self:CopyTable(adDefaults.CONTAINER)
            display.container.unit = nil
            display.container.unitCustom = nil
        else
            for key, value in pairs(adDefaults.CONTAINER) do
                if key ~= 'unit' and key ~= 'unitCustom' and display.container[key] == nil then
                    display.container[key] = EXUI.utils.deepCloneTable(value)
                end
            end
        end
        if not display.groupOrder then
            display.groupOrder = {}
        end
        if not display.groups then
            display.groups = {}
        end
        for _, groupID in ipairs(display.groupOrder) do
            local group = display.groups[groupID]
            if group then
                self:MergeGroupDefaults(group)
                if oldVersion < 3 then
                    adDefaults:MigrateBoolConditionFlags(group.conditions)
                end
            end
        end
    end
    db.__exuiDefaultsVersion = self.SCHEMA_VERSION
end

function defaults:GetGroupKey(displayID, groupID)
    return string.format('exui_uf_%s_%s', displayID, groupID)
end

function defaults:FormatUnitsSubtitle(units)
    local labels = {}
    for _, unitKey in ipairs(self.UNIT_ORDER) do
        if units and units[unitKey] then
            table.insert(labels, self.UNIT_OPTIONS[unitKey] or unitKey)
        end
    end
    if #labels == 0 then
        return 'No units'
    end
    return table.concat(labels, ', ')
end
