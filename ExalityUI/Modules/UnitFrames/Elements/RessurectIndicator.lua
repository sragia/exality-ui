---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local resurrectIndicator = EXUI:GetModule('uf-element-ressurect-indicator')

resurrectIndicator.Create = function(self, frame)
    local ResurrectIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    EXUI:SetSize(ResurrectIndicator, 24, 24)
    ResurrectIndicator:SetPoint('CENTER')

    return ResurrectIndicator
end

resurrectIndicator.Update = function(self, frame)
    local db = frame.db
    local ResurrectIndicator = frame.ResurrectIndicator

    if (not db.ressurectEnable) then
        core:DisableElementForFrame(frame, 'ResurrectIndicator')
    end
    core:EnableElementForFrame(frame, 'ResurrectIndicator')

    EXUI:SetSize(ResurrectIndicator, 24 * db.ressurectScale, 24 * db.ressurectScale)
    ResurrectIndicator:ClearAllPoints()
    EXUI:SetPoint(ResurrectIndicator, db.ressurectAnchorPoint, frame.ElementFrame, db.ressurectRelativeAnchorPoint,
        db.ressurectXOff, db.ressurectYOff)

    if (frame:IsElementPreviewEnabled('resurrectindicator') and not ResurrectIndicator:IsShown()) then
        ResurrectIndicator.PostUpdate = function(self)
            self:Show()
        end
        ResurrectIndicator:Show()
        ResurrectIndicator.isPreview = true
    elseif (not frame:IsElementPreviewEnabled('resurrectindicator') and ResurrectIndicator.isPreview) then
        ResurrectIndicator.PostUpdate = nil
        ResurrectIndicator.isPreview = false
    end
end
