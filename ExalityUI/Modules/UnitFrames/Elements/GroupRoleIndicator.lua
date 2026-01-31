---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local groupRoleIndicator = EXUI:GetModule('uf-element-group-role-indicator')

-- File 64x32
local function GetTexCoordsForRoleSmallCircle(role)
    if (role == 'TANK') then
        return 36 / 64, 54 / 64, 0, 18 / 32
    elseif (role == 'HEALER') then
        return 18 / 64, 36 / 64, 0, 18 / 32
    elseif (role == 'DAMAGER') then
        return 0, 18 / 64, 0, 18 / 32
    end
end

groupRoleIndicator.Create = function(self, frame)
    local groupRoleIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    EXUI:SetSize(groupRoleIndicator, 16, 16)
    groupRoleIndicator:SetTexture([[interface\lfgframe\roleicons]])
    groupRoleIndicator:SetPoint('CENTER')

    groupRoleIndicator.PostUpdate = function(self, role)
        self:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
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
end
