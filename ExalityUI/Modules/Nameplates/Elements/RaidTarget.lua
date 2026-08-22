---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesElementRaidTarget
local raidTarget = EXUI:GetModule('np-element-raid-target')

raidTarget.Create = function(self, frame)
    local host = CreateFrame('Frame', '$parent_RaidTarget', frame)
    host:SetSize(16, 16)
    local texture = host:CreateTexture(nil, 'OVERLAY')
    texture:SetAllPoints()
    texture:SetSize(16, 16)
    texture.PostUpdate = function(element, index)
        local parent = element:GetParent()
        if parent then
            parent:SetShown(index ~= nil)
        end
    end
    frame.RaidTargetHost = host
    return texture
end

raidTarget.Update = function(self, frame)
    local db = frame.db
    local indicator = frame.RaidTargetIndicator
    local host = frame.RaidTargetHost or indicator:GetParent()
    if frame.isFriendly or not db.raidTargetIndicatorEnable then
        frame:DisableElement('RaidTargetIndicator')
        indicator:Hide()
        if host then
            host:Hide()
        end
        return
    end

    frame:EnableElement('RaidTargetIndicator')
    local size = (db.raidTargetIndicatorScale or 1) * 16
    host:ClearAllPoints()
    host:SetPoint(
        db.raidTargetIndicatorAnchorPoint,
        frame.ElementFrame or frame,
        db.raidTargetIndicatorRelativeAnchorPoint,
        db.raidTargetIndicatorXOff,
        db.raidTargetIndicatorYOff
    )
    host:SetSize(size, size)
    host:SetFrameStrata(db.raidTargetIndicatorFrameStrata or 'MEDIUM')
    local base = (frame.ElementFrame and frame.ElementFrame:GetFrameLevel()) or frame:GetFrameLevel()
    host:SetFrameLevel(base + (db.raidTargetIndicatorFrameLevel or 0))
    if frame.isPreview then
        host:Show()
    end
end
