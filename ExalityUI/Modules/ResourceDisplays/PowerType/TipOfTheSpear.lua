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

local tipOfTheSpear = EXUI:GetModule('resource-displays-tip-of-the-spear')
local RDCore = EXUI:GetModule('resource-displays-core')

local TIP_SPELL_ID = 260286

local SEGMENT_CONFIG = {
    prefix = 'tip',
    label = 'Tip of the Spear',
    poolKey = 'TipFrames',
    widthKey = 'tipWidth',
    heightKey = 'tipHeight',
    spacingKey = 'tipSpacing',
    textureKey = 'tipBarTexture',
    colorKey = 'tipColor',
    colorsKey = 'tipColors',
    backgroundKey = 'tipBackgroundColor',
    borderKey = 'tipBorderColor',
    capColorKey = 'tipCapColor',
    individualColorCount = 5,
}

tipOfTheSpear.Create = function(self, frame)
    frame.IsActive = function(self) return tipOfTheSpear:IsActive(self) end
    frame.TipFrames = {}
    frame.ActiveFrames = {}

    frame._segmentOnEvent = function(self)
        if preview:ApplySegmentPreview(self, 'Tip of the Spear', SEGMENT_CONFIG) then
            return
        end
        local maxStacks = C_Spell.GetSpellMaxCumulativeAuraApplications(TIP_SPELL_ID) or 5
        if maxStacks ~= #self.ActiveFrames then
            self:Update()
            return
        end
        local curr = 0
        local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(TIP_SPELL_ID)
        if auraInfo then
            curr = auraInfo.applications or 0
        end
        segmentBase:SetSegmentValues(self.ActiveFrames, curr, nil, self.db, SEGMENT_CONFIG)
    end

    frame.OnEvent = frame._segmentOnEvent
    helpers:WireSegmentEnableDisable(frame, { 'UNIT_AURA', 'PLAYER_ENTERING_WORLD', 'TRAIT_CONFIG_UPDATED' })
    frame:SetScript('OnEvent', function(self)
        self:OnEvent()
    end)
end

tipOfTheSpear.Update = function(frame)
    if preview:ApplySegmentPreview(frame, 'Tip of the Spear', SEGMENT_CONFIG) then
        return
    end
    segmentBase:UpdateSegmentRow(frame, SEGMENT_CONFIG, function()
        return C_Spell.GetSpellMaxCumulativeAuraApplications(TIP_SPELL_ID) or 5
    end, nil, function(f)
        local curr = 0
        local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(TIP_SPELL_ID)
        if auraInfo then
            curr = auraInfo.applications or 0
        end
        segmentBase:SetSegmentValues(f.ActiveFrames, curr, nil, f.db, SEGMENT_CONFIG)
    end)
end

tipOfTheSpear.IsActive = function(self, frame)
    local db = frame.db
    if not db.enable then
        return false
    end
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    return specId == 255
end

tipOfTheSpear.GetOptions = function(self, displayID)
    return segmentBase:GetCommonOptions(displayID, SEGMENT_CONFIG, RDCore)
end

tipOfTheSpear.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        tipWidth = 30,
        tipHeight = 16,
        tipSpacing = 2,
        tipColor = { r = 0.8, g = 0.5, b = 0.1, a = 1 },
        tipCapColor = { r = 1, g = 0.8, b = 0.2, a = 1 },
        tipBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        tipBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        fillAnimation = false,
        tipBarTexture = 'ExalityUI Status Bar',
    })
end

core:RegisterPowerType({
    name = 'Tip of the Spear',
    control = tipOfTheSpear,
    selfControlledSize = true,
    class = 'HUNTER',
})
