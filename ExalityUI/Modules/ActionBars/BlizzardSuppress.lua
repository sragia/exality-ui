---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsBlizzardSuppress
local suppress = EXUI:GetModule('action-bars-blizzard-suppress')

-- Credit to Bartender4 for the frames that need to be hidden
suppress.FRAMES_TO_HIDE = {
    { frame = 'MainActionBar', removeEvents = false },
    { frame = 'MultiBarBottomLeft', removeEvents = true },
    { frame = 'MultiBarBottomRight', removeEvents = true },
    { frame = 'MultiBarLeft', removeEvents = true },
    { frame = 'MultiBarRight', removeEvents = true },
    { frame = 'MultiBar5', removeEvents = true },
    { frame = 'MultiBar6', removeEvents = true },
    { frame = 'MultiBar7', removeEvents = true },
    { frame = 'StanceBar', removeEvents = true },
    { frame = 'PetActionBar', removeEvents = true },
    { frame = 'PossessActionBar', removeEvents = true },
    { frame = 'OverrideActionBar', removeEvents = true },
    { frame = 'MainMenuBarVehicleLeaveButton', removeEvents = false },
    { frame = 'MainStatusTrackingBarContainer', removeEvents = true },
}

suppress.hiddenParent = nil
suppress.savedParents = {}

suppress.Init = function(self)
    self.hiddenParent = CreateFrame('Frame')
    self.hiddenParent:Hide()
end

suppress.HideFrame = function(self, frame, removeEvents)
    if not frame then return end
    if not self.savedParents[frame] then
        self.savedParents[frame] = {
            parent = frame:GetParent(),
            shown = frame:IsShown(),
        }
    end
    if removeEvents then
        frame:UnregisterAllEvents()
    end
    if frame.system then
        frame.isShownExternal = nil
    end
    if frame.HideBase then
        frame:HideBase()
    else
        frame:Hide()
    end
    frame:SetParent(self.hiddenParent)
end

suppress.ShowFrame = function(self, frame)
    if not frame then return end
    local saved = self.savedParents[frame]
    if saved then
        frame:SetParent(saved.parent or UIParent)
        if saved.shown then
            frame:Show()
        end
        self.savedParents[frame] = nil
    end
end

suppress.Enable = function(self)
    if not self.hiddenParent then
        self:Init()
    end
    for _, entry in ipairs(self.FRAMES_TO_HIDE) do
        self:HideFrame(_G[entry.frame], entry.removeEvents)
    end
    if MicroMenuContainer and MicroMenu then
        if not self.savedMicroParent then
            self.savedMicroParent = MicroMenu:GetParent()
        end
    end
end

suppress.Disable = function(self)
    for _, entry in ipairs(self.FRAMES_TO_HIDE) do
        self:ShowFrame(_G[entry.frame])
    end
    self.savedParents = {}
end
