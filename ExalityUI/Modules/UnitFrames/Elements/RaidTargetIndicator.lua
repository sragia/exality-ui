---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local raidTargetIndicator = EXUI:GetModule('uf-element-raid-target-indicator')

raidTargetIndicator.Create = function(self, frame)
    local holder = core:CreateElementHolder(frame)
    local raidTargetIndicator = holder:CreateTexture(nil, 'OVERLAY')
    raidTargetIndicator.holder = holder
    raidTargetIndicator:SetSize(16, 16)
    raidTargetIndicator:SetPoint('CENTER', frame.ElementFrame, 'CENTER', 0, 0)

    return raidTargetIndicator
end

raidTargetIndicator.Update = function(self, frame)
    local db = frame.db
    local RaidTargetIndicator = frame.RaidTargetIndicator
    if (not db.raidTargetIndicatorEnable) then
        core:DisableElementForFrame(frame, 'RaidTargetIndicator')
        return
    end
    core:ApplyElementFrameLevel(frame, RaidTargetIndicator.holder, db.raidTargetIndicatorFrameLevel or 0)

    if (frame:IsElementPreviewEnabled('markericon') and not RaidTargetIndicator:IsShown()) then
        RaidTargetIndicator.PostUpdate = function(self, index)
            self:Show()
            SetRaidTargetIconTexture(self, 1)
        end
        RaidTargetIndicator.isPreview = true
    elseif (not frame:IsElementPreviewEnabled('markericon') and RaidTargetIndicator.isPreview) then
        RaidTargetIndicator.PostUpdate = nil
        RaidTargetIndicator.isPreview = false
    end

    core:EnableElementForFrame(frame, 'RaidTargetIndicator')
    local size = (db.raidTargetIndicatorScale or 1) * 16
    RaidTargetIndicator:ClearAllPoints()
    RaidTargetIndicator:SetPoint(
        db.raidTargetIndicatorAnchorPoint,
        frame.ElementFrame,
        db.raidTargetIndicatorRelativeAnchorPoint,
        db.raidTargetIndicatorXOff,
        db.raidTargetIndicatorYOff
    )
    RaidTargetIndicator:SetSize(size, size)
end
