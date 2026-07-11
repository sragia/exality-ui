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

local chi = EXUI:GetModule('resource-displays-chi')
local RDCore = EXUI:GetModule('resource-displays-core')

local SEGMENT_CONFIG = {
    prefix = 'chi',
    label = 'Chi',
    poolKey = 'ChiFrames',
    widthKey = 'chiWidth',
    heightKey = 'chiHeight',
    spacingKey = 'chiSpacing',
    textureKey = 'chiBarTexture',
    colorKey = 'chiColor',
    colorsKey = 'chiColors',
    backgroundKey = 'chiBackgroundColor',
    borderKey = 'chiBorderColor',
    individualColorCount = 6,
}

chi.Create = function(self, frame)
    frame.IsActive = function(self) return chi:IsActive(self) end
    frame.ChiFrames = {}
    frame.ActiveFrames = {}

    frame._segmentOnEvent = function(self, event, unit, powerType)
        if preview:ApplySegmentPreview(self, 'Chi', SEGMENT_CONFIG) then
            return
        end
        if (unit == 'player' and powerType == 'CHI') or event == 'TRAIT_CONFIG_UPDATED' then
            local maxChi = UnitPowerMax('player', Enum.PowerType.Chi)
            if maxChi ~= #self.ActiveFrames then
                self:Update()
                return
            end
            segmentBase:SetSegmentValues(self.ActiveFrames, UnitPower('player', Enum.PowerType.Chi), nil, self.db, SEGMENT_CONFIG)
        end
    end

    frame.OnEvent = frame._segmentOnEvent
    helpers:WireSegmentEnableDisable(frame, { 'UNIT_POWER_UPDATE', 'TRAIT_CONFIG_UPDATED', 'PLAYER_ENTERING_WORLD' })
    frame:SetScript('OnEvent', function(self, event, unit, powerType)
        self:OnEvent(event, unit, powerType)
    end)
end

chi.Update = function(frame)
    if preview:ApplySegmentPreview(frame, 'Chi', SEGMENT_CONFIG) then
        return
    end
    segmentBase:UpdateSegmentRow(frame, SEGMENT_CONFIG, function()
        return UnitPowerMax('player', Enum.PowerType.Chi)
    end, Enum.PowerType.Chi, function(f)
        segmentBase:SetSegmentValues(f.ActiveFrames, UnitPower('player', Enum.PowerType.Chi), nil, f.db, SEGMENT_CONFIG)
    end)
end

chi.IsActive = function(self, frame)
    local db = frame.db
    if not db.enable then
        return false
    end
    if not db.showOverride then
        local specIndex = C_SpecializationInfo.GetSpecialization()
        local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
        if specId ~= 269 then
            return false
        end
    end
    return UnitPowerMax('player', Enum.PowerType.Chi) > 0
end

chi.GetOptions = function(self, displayID)
    return segmentBase:GetCommonOptions(displayID, SEGMENT_CONFIG, RDCore)
end

chi.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        chiWidth = 30,
        chiHeight = 16,
        chiSpacing = 2,
        chiColor = { r = 0, g = 1, b = 145 / 255, a = 1 },
        chiBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        chiBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        fillAnimation = false,
        chiBarTexture = 'ExalityUI Status Bar',
    })
end

core:RegisterPowerType({
    name = 'Chi',
    control = chi,
    selfControlledSize = true,
    class = 'MONK',
})
