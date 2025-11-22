---@class ExalityUI
local EXUI = select(2, ...)

local raidRoles = EXUI:GetModule('uf-element-raid-roles')

raidRoles.Create = function(self, frame)
    local roleContainer = CreateFrame('Frame', nil, frame.ElementFrame)
    frame.LeaderIndicator = roleContainer:CreateTexture(nil, 'OVERLAY')
    frame.AssistantIndicator = roleContainer:CreateTexture(nil, 'OVERLAY')

    roleContainer:SetSize(14, 14)
    roleContainer:SetFrameLevel(frame.ElementFrame:GetFrameLevel() + 1)
    
    frame.LeaderIndicator:SetSize(14, 14)
    frame.AssistantIndicator:SetSize(14, 14)
    frame.LeaderIndicator:SetPoint('CENTER')
    frame.AssistantIndicator:SetPoint('CENTER')
    return roleContainer
end

raidRoles.Update = function(self, frame)
    local db = frame.db
    local anchor = frame.RaidRoles

    if (not db.raidRolesEnable) then
        frame:DisableElement('RaidRoles')
        frame:DisableElement('LeaderIndicator')
        frame:DisableElement('AssistantIndicator')
        return
    end

    frame:EnableElement('RaidRoles')
    frame:EnableElement('LeaderIndicator')
    frame:EnableElement('AssistantIndicator')
    
    anchor:SetPoint(db.raidRolesAnchorPoint, frame.ElementFrame, db.raidRolesRelativeAnchorPoint, db.raidRolesXOff, db.raidRolesYOff)

    local size = (db.raidRolesScale or 1) * 14
    anchor:SetSize(size, size)
    frame.LeaderIndicator:SetSize(size, size)
    frame.AssistantIndicator:SetSize(size, size)
end