---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsData
local data = EXUI:GetModule('ab-data')

---@class EXUIActionBarsBar
local bar = EXUI:GetModule('ab-bar')

---------------------

---@class EXUIActionBarsManager
local manager = EXUI:GetModule('ab-manager')

manager.bars = {}
manager.hidden = CreateFrame('Frame')
manager.hidden:Hide()

manager.Init = function(self)
    if (data:GetValueByKey('enabled')) then
        self:DisableBlizzardBars()
    end
end

manager.barConfig = {
    {}
}

manager.InitBars = function(self)
    for _, config in ipairs(self.barConfig) do

    end
end

----- Hide Blizzard Bars -----
-- Credit to Bartender4 for the frames that need to be hidden
-- and any keys/events that need to be removed

manager.HideFrame = function(self, frame, removeEvents)
    if (frame) then
        if (removeEvents) then
            frame:UnregisterAllEvents()
        end

        if (frame.system) then
            frame.isShownExternal = nil
        end

        if frame.HideBase then
            frame:HideBase()
        else
            frame:Hide()
        end

        frame:SetParent(manager.hidden)
    end
end

manager.DisableBlizzardBars = function(self)
    self:HideFrame(MainActionBar, false)
    self:HideFrame(MultiBarBottomLeft, true)
    self:HideFrame(MultiBarBottomRight, true)
    self:HideFrame(MultiBarLeft, true)
    self:HideFrame(MultiBarRight, true)
    self:HideFrame(MultiBar5, true)
    self:HideFrame(MultiBar6, true)
    self:HideFrame(MultiBar7, true)
    self:HideFrame(MainStatusTrackingBarContainer, true)
end
