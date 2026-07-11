---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

---@class EXUIResourceDisplaysSegmentBase
local segmentBase = EXUI:GetModule('resource-displays-segment-base')

local holyPower = EXUI:GetModule('resource-displays-holy-power')
local RDCore = EXUI:GetModule('resource-displays-core')

local SEGMENT_CONFIG = {
    prefix = 'hp',
    label = 'Holy Power',
    poolKey = 'HolyPowerFrames',
    widthKey = 'hpWidth',
    heightKey = 'hpHeight',
    spacingKey = 'hpSpacing',
    textureKey = 'hpBarTexture',
    colorKey = 'hpColor',
    colorsKey = 'hpColors',
    backgroundKey = 'hpBackgroundColor',
    borderKey = 'hpBorderColor',
    capColorKey = 'hpCapColor',
    individualColorCount = 5,
}

holyPower.Create = function(self, frame)
    frame.IsActive = function(self) return holyPower:IsActive(self) end
    frame.HolyPowerFrames = {}
    frame.ActiveFrames = {}

    frame._segmentOnEvent = function(self, event, unit, powerType)
        if preview:ApplySegmentPreview(self, 'Holy Power', SEGMENT_CONFIG) then
            return
        end
        if (unit == 'player' and powerType == 'HOLY_POWER') or event == 'TRAIT_CONFIG_UPDATED' then
            local maxHP = UnitPowerMax('player', Enum.PowerType.HolyPower)
            if maxHP ~= #self.ActiveFrames then
                self:Update()
                return
            end
            local count = UnitPower('player', Enum.PowerType.HolyPower)
            segmentBase:SetSegmentValues(self.ActiveFrames, count, nil, self.db, SEGMENT_CONFIG)
        end
    end

    frame.OnEvent = frame._segmentOnEvent
    helpers:WireSegmentEnableDisable(frame, { 'UNIT_POWER_UPDATE', 'TRAIT_CONFIG_UPDATED', 'PLAYER_ENTERING_WORLD' })
    frame:SetScript('OnEvent', function(self, event, unit, powerType)
        self:OnEvent(event, unit, powerType)
    end)
end

holyPower.Update = function(frame)
    if preview:ApplySegmentPreview(frame, 'Holy Power', SEGMENT_CONFIG) then
        return
    end

    segmentBase:UpdateSegmentRow(frame, SEGMENT_CONFIG, function()
        return UnitPowerMax('player', Enum.PowerType.HolyPower)
    end, Enum.PowerType.HolyPower, function(f)
        local count = UnitPower('player', Enum.PowerType.HolyPower)
        segmentBase:SetSegmentValues(f.ActiveFrames, count, nil, f.db, SEGMENT_CONFIG)
    end)
end

holyPower.IsActive = function(self, frame)
    local db = frame.db
    return db.enable and UnitPowerMax('player', Enum.PowerType.HolyPower) > 0
end

holyPower.GetOptions = function(self, displayID)
    local options = segmentBase:GetCommonOptions(displayID, SEGMENT_CONFIG, RDCore)
    table.insert(options, {
        type = 'color-picker',
        label = 'Cap Color',
        name = 'hpCapColor',
        currentValue = function()
            return RDCore:GetValueForDisplay(displayID, 'hpCapColor')
        end,
        onChange = function(value)
            RDCore:UpdateValueForDisplay(displayID, 'hpCapColor', value)
            RDCore:RefreshDisplayByID(displayID)
        end,
        width = 16,
    })
    return options
end

holyPower.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        hpWidth = 30,
        hpHeight = 16,
        hpSpacing = 2,
        hpColor = { r = 1, g = 204 / 255, b = 0, a = 1 },
        hpCapColor = { r = 1, g = 0.8, b = 0, a = 1 },
        hpBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        hpBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        fillAnimation = false,
        hpBarTexture = 'ExalityUI Status Bar',
    })
end

core:RegisterPowerType({
    name = 'Holy Power',
    control = holyPower,
    selfControlledSize = true,
    class = 'PALADIN',
})
