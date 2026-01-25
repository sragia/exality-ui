---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local phaseIndicator = EXUI:GetModule('uf-element-phase-indicator')

phaseIndicator.Create = function(self, frame)
    local phaseIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    EXUI:SetSize(phaseIndicator, 24, 24)
    phaseIndicator:SetPoint('CENTER')

    return phaseIndicator
end

phaseIndicator.Update = function(self, frame)
    local db = frame.db

    if (not db.phaseIndicatorEnable) then
        core:DisableElementForFrame(frame, 'PhaseIndicator')
        return
    end

    core:EnableElementForFrame(frame, 'PhaseIndicator')

    EXUI:SetSize(phaseIndicator, 24 * db.phaseIndicatorScale, 24 * db.phaseIndicatorScale)
    phaseIndicator:ClearAllPoints()
    EXUI:SetPoint(phaseIndicator, db.phaseIndicatorAnchorPoint, frame.ElementFrame, db.phaseIndicatorRelativeAnchorPoint,
        db.phaseIndicatorXOff, db.phaseIndicatorYOff)
end
