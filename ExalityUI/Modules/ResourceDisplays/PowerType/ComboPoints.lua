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

local comboPoints = EXUI:GetModule('resource-displays-combo-points')
local RDCore = EXUI:GetModule('resource-displays-core')

local SEGMENT_CONFIG = {
    prefix = 'comboPoints',
    label = 'Combo Points',
    poolKey = 'ComboPointsFrames',
    widthKey = 'comboPointsWidth',
    heightKey = 'comboPointsHeight',
    spacingKey = 'comboPointsSpacing',
    textureKey = 'comboPointsBarTexture',
    colorKey = 'comboPointsColor',
    colorsKey = 'comboPointsColors',
    backgroundKey = 'comboPointsBackgroundColor',
    borderKey = 'comboPointsBorderColor',
    chargedColorKey = 'chargedColor',
    individualColorCount = 7,
}

comboPoints.Create = function(self, frame)
    frame.IsActive = function(self) return comboPoints:IsActive(self) end
    frame.ComboPointsFrames = {}
    frame.ActiveFrames = {}

    frame._segmentOnEvent = function(self, event, unit, powerType)
        if preview:ApplySegmentPreview(self, 'Combo Points', SEGMENT_CONFIG) then
            return
        end
        if (unit == 'player' and powerType == 'COMBO_POINTS') or event == 'TRAIT_CONFIG_UPDATED' or event == 'UNIT_POWER_POINT_CHARGE' then
            local maxComboPoints = UnitPowerMax('player', Enum.PowerType.ComboPoints)
            if maxComboPoints ~= #self.ActiveFrames then
                self:Update()
                return
            end
            local count = UnitPower('player', Enum.PowerType.ComboPoints)
            local charged = helpers:GetChargedPowerPoints()
            segmentBase:SetSegmentValues(self.ActiveFrames, count, charged, self.db, SEGMENT_CONFIG)
            if self.db.showSegmentText and self.SegmentText then
                self.SegmentText:SetText(helpers:FormatPowerText(self.db.segmentTextFormat or 'current/max', count, maxComboPoints))
            end
        end
    end

    frame.OnEvent = frame._segmentOnEvent

    helpers:WireSegmentEnableDisable(frame, { 'UNIT_POWER_UPDATE', 'UNIT_POWER_POINT_CHARGE', 'TRAIT_CONFIG_UPDATED', 'PLAYER_ENTERING_WORLD' })
    frame:SetScript('OnEvent', function(self, event, unit, powerType)
        self:OnEvent(event, unit, powerType)
    end)

    if not frame.SegmentText then
        frame.SegmentText = frame:CreateFontString(nil, 'OVERLAY')
        frame.SegmentText:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
        frame.SegmentText:SetPoint('TOP', frame, 'BOTTOM', 0, -2)
    end
end

comboPoints.Update = function(frame)
    local db = frame.db
    if preview:ApplySegmentPreview(frame, 'Combo Points', SEGMENT_CONFIG) then
        return
    end

    segmentBase:UpdateSegmentRow(frame, SEGMENT_CONFIG, function()
        return UnitPowerMax('player', Enum.PowerType.ComboPoints)
    end, Enum.PowerType.ComboPoints, function(f)
        local count = UnitPower('player', Enum.PowerType.ComboPoints)
        segmentBase:SetSegmentValues(f.ActiveFrames, count, helpers:GetChargedPowerPoints(), f.db, SEGMENT_CONFIG)
    end)

    if db.showSegmentText then
        frame.SegmentText:Show()
        frame.SegmentText:SetText(helpers:FormatPowerText(db.segmentTextFormat or 'current/max', UnitPower('player', Enum.PowerType.ComboPoints), UnitPowerMax('player', Enum.PowerType.ComboPoints)))
    elseif frame.SegmentText then
        frame.SegmentText:Hide()
    end
end

comboPoints.IsActive = function(self, frame)
    local db = frame.db
    if not db.enable then
        return false
    end
    if db.catFormOnly then
        local _, class = UnitClass('player')
        if class == 'DRUID' and not helpers:IsDruidInCatForm() then
            return false
        end
    end
    return UnitPowerMax('player', Enum.PowerType.ComboPoints) > 0
end

comboPoints.GetOptions = function(self, displayID)
    local options = segmentBase:GetCommonOptions(displayID, SEGMENT_CONFIG, RDCore)
    table.insert(options, {
        type = 'toggle',
        label = 'Cat Form Only (Druid)',
        name = 'catFormOnly',
        currentValue = function()
            return RDCore:GetValueForDisplay(displayID, 'catFormOnly')
        end,
        onChange = function(value)
            RDCore:UpdateValueForDisplay(displayID, 'catFormOnly', value)
            RDCore:RefreshDisplayByID(displayID)
        end,
        width = 100,
    })
    table.insert(options, {
        type = 'toggle',
        label = 'Show Segment Text',
        name = 'showSegmentText',
        currentValue = function()
            return RDCore:GetValueForDisplay(displayID, 'showSegmentText')
        end,
        onChange = function(value)
            RDCore:UpdateValueForDisplay(displayID, 'showSegmentText', value)
            RDCore:RefreshDisplayByID(displayID)
        end,
        width = 100,
    })
    return options
end

comboPoints.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        comboPointsWidth = 30,
        comboPointsHeight = 16,
        comboPointsSpacing = 2,
        comboPointsColor = { r = 1, g = 204 / 255, b = 0, a = 1 },
        comboPointsBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        comboPointsBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        chargedColor = { r = 0.2, g = 0.6, b = 1, a = 1 },
        fillAnimation = false,
        comboPointsBarTexture = 'ExalityUI Status Bar',
        catFormOnly = false,
        showSegmentText = false,
        segmentTextFormat = 'current/max',
    })
end

core:RegisterPowerType({
    name = 'Combo Points',
    control = comboPoints,
    selfControlledSize = true,
    class = 'ROGUE',
})
