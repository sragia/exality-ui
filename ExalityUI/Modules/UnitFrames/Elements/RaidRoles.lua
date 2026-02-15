---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

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
        core:DisableElementForFrame(frame, 'RaidRoles')
        core:DisableElementForFrame(frame, 'LeaderIndicator')
        core:DisableElementForFrame(frame, 'AssistantIndicator')
        return
    end

    core:EnableElementForFrame(frame, 'RaidRoles')
    core:EnableElementForFrame(frame, 'LeaderIndicator')
    core:EnableElementForFrame(frame, 'AssistantIndicator')

    anchor:SetPoint(db.raidRolesAnchorPoint, frame.ElementFrame, db.raidRolesRelativeAnchorPoint, db.raidRolesXOff,
        db.raidRolesYOff)

    local size = (db.raidRolesScale or 1) * 14
    anchor:SetSize(size, size)
    frame.LeaderIndicator:SetSize(size, size)
    frame.AssistantIndicator:SetSize(size, size)

    if (frame:IsElementPreviewEnabled('raidroles') and not frame.LeaderIndicator:IsShown()) then
        frame.LeaderIndicator.PostUpdate = function(self)
            self:Show()
            self:SetAtlas('UI-HUD-UnitFrame-Player-Group-LeaderIcon')
        end
        frame.LeaderIndicator.isPreview = true
    elseif (not frame:IsElementPreviewEnabled('raidroles') and frame.LeaderIndicator.isPreview) then
        frame.LeaderIndicator.PostUpdate = nil
        frame.LeaderIndicator.isPreview = false
    end
end
