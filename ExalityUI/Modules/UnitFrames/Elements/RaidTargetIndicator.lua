---@class ExalityUI
local EXUI = select(2, ...)

local raidTargetIndicator = EXUI:GetModule('uf-element-raid-target-indicator')

raidTargetIndicator.Create = function(self, frame)
    local raidTargetIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    raidTargetIndicator:SetSize(16, 16)
    raidTargetIndicator:SetPoint('CENTER', frame.ElementFrame, 'CENTER', 0, 0)

    return raidTargetIndicator
end

raidTargetIndicator.Update = function(self, frame)
    local db = frame.db
    local raidTargetIndicator = frame.RaidTargetIndicator
    if (not db.raidTargetIndicatorEnable) then
        frame:DisableElement('RaidTargetIndicator')
        return
    end

    frame:EnableElement('RaidTargetIndicator')
    local size = (db.raidTargetIndicatorScale or 1) * 16
    raidTargetIndicator:SetPoint(
        db.raidTargetIndicatorAnchorPoint, 
        frame.ElementFrame, 
        db.raidTargetIndicatorRelativeAnchorPoint, 
        db.raidTargetIndicatorXOff, 
        db.raidTargetIndicatorYOff
    )
    raidTargetIndicator:SetSize(size, size)
end