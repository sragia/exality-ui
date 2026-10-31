---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUIUnitFramesElementsShape
local ufShape = EXUI:GetModule('uf-element-shape')

---@class EXUINameplatesElementShape
local shape = EXUI:GetModule('np-element-shape')

shape.Create = function(self, frame)
    local host = frame.HealthHost
    local mask = host:CreateMaskTexture()
    mask:SetAllPoints(host)

    local border = frame.ElementFrame:CreateTexture(nil, 'BORDER', nil, 1)
    border:SetAllPoints(host)
    border:Hide()

    return { Mask = mask, Border = border, masked = {} }
end

shape.IsShaped = function(self, frame)
    local db = frame.db or npCore:GetDB()
    return ufShape:IsStyle(db.frameStyle) and not npCore:IsFriendlyNameOnly(frame)
end

shape.GetStyleSize = function(self, frame)
    if not self:IsShaped(frame) then
        return nil
    end
    return ufShape:GetStyleSize((frame.db or npCore:GetDB()).frameStyle)
end

shape.IsCastbarShaped = function(self, db)
    return ufShape:IsStyle(db and db.castbarStyle)
end

shape.SetBorderColor = function(self, frame, color)
    frame.FrameShape.Border:SetVertexColor(color.r or 0, color.g or 0, color.b or 0, color.a or 1)
end

-- Created the first time a plate is hovered
shape.MaskOverlay = function(self, frame, texture)
    local state = frame.FrameShape
    ufShape:SetMasked(state, texture, state.enabled == true)
end

shape.Update = function(self, frame)
    local db = frame.db
    local state = frame.FrameShape
    ufShape:SelectStyle(state, db.frameStyle)
    local enabled = self:IsShaped(frame)
    state.enabled = enabled

    local health = frame.Health
    ufShape:SetBarMasked(state, health, enabled)
    ufShape:SetMasked(state, health.occlude, enabled)
    ufShape:SetMasked(state, health._exuiHoverLight, enabled)

    local absorbs = frame.HealthPrediction
    if absorbs then
        ufShape:SetBarMasked(state, absorbs.DamageAbsorbOriginal, enabled)
        ufShape:SetBarMasked(state, absorbs.HealAbsorbOriginal, enabled)
        ufShape:SetMasked(state, absorbs.OverDamageAbsorbIndicatorOriginal, enabled)
    end

    state.Border:SetShown(enabled and npCore:GetBorderThickness(db) > 0)
end
