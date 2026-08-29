---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysDefaults
local adDefaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUINameplatesAurasDefaults
local defaults = EXUI:GetModule('np-auras-defaults')

defaults.SCHEMA_VERSION = 1
defaults.UNIT_ORDER = {}
defaults.UNIT_OPTIONS = {}

function defaults:CopyTable(source)
    return EXUI.utils.deepCloneTable(source)
end

function defaults:BuildNewGroup()
    return adDefaults:BuildNewGroup()
end

function defaults:BuildNewDisplay()
    local displayID, display = adDefaults:BuildNewDisplay()
    display.name = 'New Nameplate Aura'
    display.anchorPoint = 'BOTTOMLEFT'
    display.relativePoint = 'TOPLEFT'
    display.XOff = 0
    display.YOff = 2
    display.containerAnchorPoint = 'BOTTOMLEFT'
    display.horizontalGrowth = 'RIGHT'
    display.verticalGrowth = 'UP'
    display.frameStrata = 'MEDIUM'
    display.frameLevel = 10
    display.rowWidth = 140
    display.matchUnitFrameWidth = true
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
    if not db.displays then
        db.displays = {}
    end
    for _, display in pairs(db.displays) do
        if display.enable == nil then
            display.enable = true
        end
        if not display.name then
            display.name = 'Nameplate Aura'
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
            display.frameStrata = 'MEDIUM'
        end
        if display.frameLevel == nil then
            display.frameLevel = 10
        end
        if display.containerAnchorPoint == nil then
            display.containerAnchorPoint = 'BOTTOMLEFT'
        end
        if display.flowLayoutAxis == nil then
            display.flowLayoutAxis = 'Rows'
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
            display.rowWidth = 140
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
            end
        end
    end
    db.__exuiDefaultsVersion = self.SCHEMA_VERSION
end

function defaults:GetGroupKey(displayID, groupID)
    return string.format('exui_np_%s_%s', displayID, groupID)
end
