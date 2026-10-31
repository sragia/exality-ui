---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local summonIndicator = EXUI:GetModule('uf-element-summon-indicator')

summonIndicator.Create = function(self, frame)
    local holder = core:CreateElementHolder(frame)
    local SummonIndicator = holder:CreateTexture(nil, 'OVERLAY')
    SummonIndicator.holder = holder
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
    core:ApplyElementFrameLevel(frame, SummonIndicator.holder, db.summonFrameLevel or 0)

    EXUI:SetSize(SummonIndicator, 24 * db.summonScale, 24 * db.summonScale)
    SummonIndicator:ClearAllPoints()
    EXUI:SetPoint(SummonIndicator, db.summonAnchorPoint, frame.ElementFrame, db.summonRelativeAnchorPoint,
        db.summonXOff, db.summonYOff)

    if (frame:IsElementPreviewEnabled('summonindicator') and not SummonIndicator:IsShown()) then
        SummonIndicator.PostUpdate = function(self)
            self:SetAtlas('RaidFrame-Icon-SummonPending')
            self:Show()
        end
        SummonIndicator:Show()
        SummonIndicator.isPreview = true
    elseif (not frame:IsElementPreviewEnabled('summonindicator') and SummonIndicator.isPreview) then
        SummonIndicator.PostUpdate = nil
        SummonIndicator.isPreview = false
    end
end
