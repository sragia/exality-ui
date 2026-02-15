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
    local PhaseIndicator = frame.PhaseIndicator

    if (not db.phaseIndicatorEnable) then
        core:DisableElementForFrame(frame, 'PhaseIndicator')
        return
    end

    core:EnableElementForFrame(frame, 'PhaseIndicator')

    EXUI:SetSize(PhaseIndicator, 24 * db.phaseIndicatorScale, 24 * db.phaseIndicatorScale)
    PhaseIndicator:ClearAllPoints()
    EXUI:SetPoint(PhaseIndicator, db.phaseIndicatorAnchorPoint, frame.ElementFrame, db.phaseIndicatorRelativeAnchorPoint,
        db.phaseIndicatorXOff, db.phaseIndicatorYOff)

    if (frame:IsElementPreviewEnabled('phaseindicator') and not PhaseIndicator:IsShown()) then
        PhaseIndicator.PostUpdate = function(self)
            self:Show()
        end
        PhaseIndicator:Show()
        PhaseIndicator.isPreview = true
    elseif (not frame:IsElementPreviewEnabled('phaseindicator') and PhaseIndicator.isPreview) then
        PhaseIndicator.PostUpdate = nil
        PhaseIndicator.isPreview = false
    end
end
