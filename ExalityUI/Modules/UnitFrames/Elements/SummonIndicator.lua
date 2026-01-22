---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local summonIndicator = EXUI:GetModule('uf-element-summon-indicator')

summonIndicator.Create = function(self, frame)
    local SummonIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    EXUI:SetSize(SummonIndicator, 24, 24)
    SummonIndicator:SetPoint('CENTER')

    return SummonIndicator
end

summonIndicator.Update = function(self, frame)
    local db = frame.db
    local SummonIndicator = frame.SummonIndicator

    if (not db.summonEnable) then
        core:DisableElementForFrame(frame, 'SummonIndicator')
    end
    core:EnableElementForFrame(frame, 'SummonIndicator')

    EXUI:SetSize(SummonIndicator, 24 * db.summonScale, 24 * db.summonScale)
    SummonIndicator:ClearAllPoints()
    EXUI:SetPoint(SummonIndicator, db.summonAnchorPoint, frame.ElementFrame, db.summonRelativeAnchorPoint,
        db.summonXOff, db.summonYOff)
end
