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

---@class EXUIActionBarsStateDriver
local stateDriver = EXUI:GetModule('action-bars-state-driver')

---@class EXUIActionBarsStyle
local barStyle = EXUI:GetModule('action-bars-style')

---@class EXUIActionBarsKeybind
local keybind = EXUI:GetModule('action-bars-keybind')

---@class EXUIActionBarsMicroMenu
local microMenu = EXUI:GetModule('action-bars-micro-menu')

---@class EXUIActionBarsExtraAbilities
local extraAbilities = EXUI:GetModule('action-bars-extra-abilities')

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

    local db = EXUI:GetModule('action-bars'):EnsureDB()
    for _, barId in ipairs(definitions.ALL_BAR_IDS) do
        if barId ~= 'extra' then
            if not barMod:Get(barId) then
                barMod:Create(barId, db)
            else
                barMod:Configure(barMod:Get(barId), db)
            end
        end
    end

    stateController:Init()
    stateController:UpdateAll()
    stateDriver:Init()
    stateDriver:RefreshBar1()
    extraAbilities:Apply(db)
    extraAbilities:SetupHover()
    microMenu:Apply(db)
    microMenu:SetupHover(db)
    keybind:ReassignBindings()
end

manager.RefreshBar = function(self, barId)
    if barId == 'extra' then
        extraAbilities:Apply(self:GetDB())
        return
    end
    local frame = barMod:Get(barId)
    if frame then
        barMod:Configure(frame, self:GetDB())
        if barId == 'stance' then
            stateController:UpdateStanceBar()
        elseif barMod:IsStateControlledBar(barId) and not barMod:IsBarEditorActive(frame) then
            if barId == 'pet' then
                stateController:UpdatePetBar()
            elseif barId == 'override' then
                stateController:UpdateOverrideBar()
            end
        end
    end
end

manager.ApplyMicroMenu = function(self)
    microMenu:Apply(self:GetDB())
end

manager.RefreshAll = function(self)
    local db = EXUI:GetModule('action-bars'):EnsureDB()
    for barId, frame in pairs(barMod.instances) do
        barMod:Configure(frame, db)
    end
    stateController:UpdateAll()
    extraAbilities:Apply(db)
    self:ApplyMicroMenu()
end

manager.Enable = function(self)
    if self.enabled then return end
    self.enabled = true
    suppress:Enable()
    keybind:Init()
    extraAbilities:Init()
    microMenu:Init()
    self:CreateBars()
end

manager.Disable = function(self)
    if not self.enabled then return end
    self.enabled = false
    local spellPicker = EXUI:GetModule('action-bars-spell-picker')
    if spellPicker and spellPicker.Hide then
        spellPicker:Hide()
    end
    stateController:Shutdown()
    stateDriver:Shutdown()
    for barId in pairs(barMod.instances) do
        barMod:Destroy(barId)
    end
    barStyle:ReleaseMasqueGroups()
    keybind:Clear()
    extraAbilities:Disable()
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
