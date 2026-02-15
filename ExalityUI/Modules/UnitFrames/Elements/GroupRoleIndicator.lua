---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local groupRoleIndicator = EXUI:GetModule('uf-element-group-role-indicator')

local atlases = {
    'UI-LFG-RoleIcon-Tank-Micro-Raid',
    'UI-LFG-RoleIcon-Healer-Micro-Raid',
    'UI-LFG-RoleIcon-DPS-Micro-Raid',
}

groupRoleIndicator.Create = function(self, frame)
    local groupRoleIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    EXUI:SetSize(groupRoleIndicator, 16, 16)
    groupRoleIndicator:SetPoint('CENTER')

    groupRoleIndicator.PostUpdate = function(self, role)
        if (not role) then return end
        if (self.hideTank and role == 'TANK') then
            self:Hide()
            return
        end
        if (self.hideHealer and role == 'HEALER') then
            self:Hide()
            return
        end
        if (self.hideDamager and role == 'DAMAGER') then
            self:Hide()
            return
        end

        self:Show()
    end

    return groupRoleIndicator
end

groupRoleIndicator.Update = function(self, frame)
    local db = frame.db
    local GroupRoleIndicator = frame.GroupRoleIndicator

    if (not db.groupRoleIndicatorEnable) then
        core:DisableElementForFrame(frame, 'GroupRoleIndicator')
        return
    end

    GroupRoleIndicator.hideTank = db.groupRoleIndicatorHideTank
    GroupRoleIndicator.hideHealer = db.groupRoleIndicatorHideHealer
    GroupRoleIndicator.hideDamager = db.groupRoleIndicatorHideDamager

    core:EnableElementForFrame(frame, 'GroupRoleIndicator')

    EXUI:SetSize(GroupRoleIndicator, 16 * db.groupRoleIndicatorScale, 16 * db.groupRoleIndicatorScale)
    GroupRoleIndicator:ClearAllPoints()
    EXUI:SetPoint(GroupRoleIndicator, db.groupRoleIndicatorAnchorPoint, frame.ElementFrame,
        db.groupRoleIndicatorRelativeAnchorPoint,
        db.groupRoleIndicatorXOff, db.groupRoleIndicatorYOff)

    if (frame:IsElementPreviewEnabled('grouproleindicator') and not GroupRoleIndicator:IsShown()) then
        GroupRoleIndicator.PostUpdate = function(self, role)
            self:SetAtlas(atlases[math.random(1, 3)])
            self:Show()
        end
        GroupRoleIndicator:Show()
        GroupRoleIndicator.isPreview = true
    elseif (not frame:IsElementPreviewEnabled('grouproleindicator') and GroupRoleIndicator.isPreview) then
        GroupRoleIndicator.PostUpdate = nil
        GroupRoleIndicator.isPreview = false
    end
end
