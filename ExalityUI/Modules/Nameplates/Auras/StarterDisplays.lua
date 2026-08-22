---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysDefaults
local adDefaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUINameplatesAurasDefaults
local defaults = EXUI:GetModule('np-auras-defaults')

local function makeDebuffs()
    local displayID, display = defaults:BuildNewDisplay()
    display.name = 'My Debuffs'
    display.anchorPoint = 'BOTTOMLEFT'
    display.relativePoint = 'TOPLEFT'
    display.XOff = 0
    display.YOff = 2
    display.horizontalGrowth = 'RIGHT'
    display.verticalGrowth = 'UP'
    display.matchUnitFrameWidth = true
    local groupID = display.groupOrder[1]
    local group = display.groups[groupID]
    group.conditions.filterTokens = {
        { token = 'HARMFUL', negated = false },
        { token = 'PLAYER', negated = false },
    }
    group.conditions.maxFrameCount = 6
    group.visual.iconWidth = 20
    group.visual.iconHeight = 20
    group.visual.elementSpacingX = 1
    group.visual.elementSpacingY = 1
    return displayID, display
end

local function makeCrowdControl()
    local displayID, display = defaults:BuildNewDisplay()
    display.name = 'Crowd Control'
    display.anchorPoint = 'LEFT'
    display.relativePoint = 'RIGHT'
    display.XOff = 4
    display.YOff = 0
    display.containerAnchorPoint = 'LEFT'
    display.horizontalGrowth = 'RIGHT'
    display.verticalGrowth = 'DOWN'
    display.matchUnitFrameWidth = false
    display.rowWidth = 80
    local groupID = display.groupOrder[1]
    local group = display.groups[groupID]
    group.conditions.filterTokens = {
        { token = 'HARMFUL', negated = false },
        { token = 'CROWD_CONTROL', negated = false },
    }
    group.conditions.maxFrameCount = 4
    group.visual.iconWidth = 24
    group.visual.iconHeight = 24
    group.visual.elementSpacingX = 1
    return displayID, display
end

function defaults:SeedStarterDisplays(db)
    if not db or db.__exuiStarterDisplaysSeeded then
        return false
    end
    db.displays = db.displays or {}

    local debuffID, debuffs = makeDebuffs()
    local ccID, cc = makeCrowdControl()
    if not db.displays[debuffID] then
        db.displays[debuffID] = debuffs
    end
    if not db.displays[ccID] then
        db.displays[ccID] = cc
    end

    db.__exuiStarterDisplaysSeeded = true
    return true
end
