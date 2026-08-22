---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesElementRaidTarget
local raidTarget = EXUI:GetModule('np-element-raid-target')

raidTarget.Create = function(self, frame)
    local texture = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    texture:SetSize(16, 16)
    return texture
end

raidTarget.Update = function(self, frame)
    local db = frame.db
    local indicator = frame.RaidTargetIndicator
    if frame.isFriendly or not db.raidTargetIndicatorEnable then
        frame:DisableElement('RaidTargetIndicator')
        indicator:Hide()
        return
    end

    frame:EnableElement('RaidTargetIndicator')
    local size = (db.raidTargetIndicatorScale or 1) * 16
    indicator:ClearAllPoints()
    indicator:SetPoint(
        db.raidTargetIndicatorAnchorPoint,
        frame.ElementFrame,
        db.raidTargetIndicatorRelativeAnchorPoint,
        db.raidTargetIndicatorXOff,
        db.raidTargetIndicatorYOff
    )
    indicator:SetSize(size, size)
end
