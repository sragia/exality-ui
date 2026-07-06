---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsDefaults
local barDefaults = EXUI:GetModule('action-bars-defaults')

---@class EXUIActionBarsBar
local barMod = EXUI:GetModule('action-bars-bar')

---@class EXUIActionBarsBlizzardSuppress
local suppress = EXUI:GetModule('action-bars-blizzard-suppress')

---@class EXUIActionBarsStateController
local stateController = EXUI:GetModule('action-bars-state')

---@class EXUIActionBarsStyle
local barStyle = EXUI:GetModule('action-bars-style')

---@class EXUIActionBarsKeybind
local keybind = EXUI:GetModule('action-bars-keybind')

---@class EXUIActionBarsMicroMenu
local microMenu = EXUI:GetModule('action-bars-micro-menu')

---@class EXUIActionBarsManager
local manager = EXUI:GetModule('action-bars-manager')

manager.enabled = false
manager.pendingInit = false

manager.GetDB = function(self)
    return EXUI:GetModule('action-bars'):GetDB()
end

manager.CreateBars = function(self)
    if InCombatLockdown() then
        self.pendingInit = true
        return
    end

    local db = self:GetDB()
    for _, barId in ipairs(definitions.ALL_BAR_IDS) do
        if not barMod:Get(barId) then
            barMod:Create(barId, db)
        else
            barMod:Configure(barMod:Get(barId), db)
        end
    end

    stateController:Init()
    stateController:UpdateAll()
    microMenu:Apply(db)
    microMenu:SetupHover(db)
end

manager.RefreshBar = function(self, barId)
    local frame = barMod:Get(barId)
    if frame then
        barMod:Configure(frame, self:GetDB())
    end
end

manager.ApplyMicroMenu = function(self)
    microMenu:Apply(self:GetDB())
end

manager.RefreshAll = function(self)
    local db = self:GetDB()
    for barId, frame in pairs(barMod.instances) do
        barMod:Configure(frame, db)
    end
    stateController:UpdateAll()
    self:ApplyMicroMenu()
end

manager.Enable = function(self)
    if self.enabled then return end
    self.enabled = true
    suppress:Enable()
    keybind:Init()
    microMenu:Init()
    self:CreateBars()
end

manager.Disable = function(self)
    if not self.enabled then return end
    self.enabled = false
    stateController:Shutdown()
    for barId in pairs(barMod.instances) do
        barMod:Destroy(barId)
    end
    barStyle:ReleaseMasqueGroups()
    keybind:Clear()
    suppress:Disable()
end

manager.OnCombatLeave = function(self)
    if self.pendingInit then
        self.pendingInit = false
        self:CreateBars()
    end
end

manager.Init = function(self)
    EXUI:RegisterEventHandler('PLAYER_REGEN_ENABLED', 'action-bars-manager', function()
        manager:OnCombatLeave()
    end)
end
