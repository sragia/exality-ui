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

local function PostUpdate(self, role)
    if (role == nil) then return end
    if (self.hideTank and role == Enum.LFGRole.Tank) then
        self:Hide()
        return
    end
    if (self.hideHealer and role == Enum.LFGRole.Healer) then
        self:Hide()
        return
    end
    if (self.hideDamager and role == Enum.LFGRole.Damage) then
        self:Hide()
        return
    end

    self:Show()
end

groupRoleIndicator.Create = function(self, frame)
    local groupRoleIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    EXUI:SetSize(groupRoleIndicator, 16, 16)
    groupRoleIndicator:SetPoint('CENTER')

    groupRoleIndicator.PostUpdate = PostUpdate

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

    if (frame:IsElementPreviewEnabled('grouproleindicator') and not GroupRoleIndicator.isPreview) then
        GroupRoleIndicator.PostUpdate = function(self, role)
            self:SetAtlas(atlases[math.random(1, 3)])
            self:Show()
        end
        GroupRoleIndicator:Show()
        GroupRoleIndicator.isPreview = true
    elseif (not frame:IsElementPreviewEnabled('grouproleindicator') and GroupRoleIndicator.isPreview) then
        GroupRoleIndicator.PostUpdate = PostUpdate
        GroupRoleIndicator.isPreview = false
    end
end
