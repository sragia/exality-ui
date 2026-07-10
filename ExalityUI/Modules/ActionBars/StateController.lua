---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsButton
local buttonMod = EXUI:GetModule('action-bars-button')

---@class EXUIActionBarsBar
local barMod = EXUI:GetModule('action-bars-bar')

---@class EXUIActionBarsSpecialButton
local specialButton = EXUI:GetModule('action-bars-special-button')

---@class EXUIActionBarsStateController
local state = EXUI:GetModule('action-bars-state')

---@class EXUIActionBarsModule
local actionBars = EXUI:GetModule('action-bars')

---@class EXUIActionBarsConfigResolver
local configResolver = EXUI:GetModule('action-bars-config-resolver')

state.EVENTS = {
    'PLAYER_ENTERING_WORLD',
    'ACTIONBAR_PAGE_CHANGED',
    'UPDATE_BONUS_ACTIONBAR',
    'UPDATE_VEHICLE_ACTIONBAR',
    'UPDATE_OVERRIDE_ACTIONBAR',
    'UPDATE_SHAPESHIFT_FORM',
    'UPDATE_SHAPESHIFT_FORMS',
    'UPDATE_SHAPESHIFT_COOLDOWN',
    'UPDATE_POSSESS_BAR',
    'PET_BATTLE_OPENING_START',
    'PET_BATTLE_CLOSE',
    'PET_BAR_UPDATE',
    'PET_BAR_UPDATE_COOLDOWN',
    'PET_UI_UPDATE',
    'UNIT_PET',
}

state.COOLDOWN_ONLY_EVENTS = {
    UPDATE_SHAPESHIFT_COOLDOWN = 'stance',
    PET_BAR_UPDATE_COOLDOWN = 'pet',
}

state.pendingUpdate = false
state.pendingVisibility = false
state.pendingSlots = false

state.IsOverrideBarActive = function(self)
    return (C_ActionBar.HasVehicleActionBar() and UnitVehicleSkin('player') and UnitVehicleSkin('player') ~= '')
        or (C_ActionBar.HasOverrideActionBar() and C_ActionBar.GetOverrideBarSkin() and C_ActionBar.GetOverrideBarSkin() ~= 0)
end

state.UpdateBar1Visibility = function(self, db)
    local frame = barMod:Get('bar1')
    if not frame then
        return
    end

    db = db or actionBars:GetDB()
    local config = configResolver:GetBarConfig(db, 'bar1')

    if not config.enable or config.visibility == 'hidden' then
        self:TrySetFrameShown(frame, false)
        return
    end

    if self:IsOverrideBarActive() then
        self:TrySetFrameShown(frame, false)
        return
    end

    self:TrySetFrameShown(frame, true)
end

state.UpdateOverrideBar = function(self, db)
    local frame = barMod:Get('override')
    if not frame then
        return
    end

    local showOverride = self:IsOverrideBarActive()

    if not showOverride or C_PetBattles.IsInBattle() then
        self:TrySetFrameShown(frame, false)
        return
    end

    local page = C_ActionBar.GetOverrideBarIndex()
    for i, button in ipairs(frame.buttons) do
        local slot = (page - 1) * 12 + i
        buttonMod:SetActionSlot(button, slot)
    end

    db = db or actionBars:GetDB()
    local config = configResolver:GetBarConfig(db, 'override')
    if config.enable then
        self:TrySetFrameShown(frame, true)
    end
end

state.UpdateStanceBar = function(self, db)
    local frame = barMod:Get('stance')
    if not frame then
        return
    end

    db = db or actionBars:GetDB()
    local config = configResolver:GetBarConfig(db, 'stance')
    specialButton:UpdateStanceButtons(frame, config)
end

state.UpdatePetBar = function(self, db)
    local frame = barMod:Get('pet')
    if not frame then
        return
    end

    local shouldShow = PetHasActionBar and PetHasActionBar()
    if shouldShow then
        specialButton:UpdateAll(frame)
        db = db or actionBars:GetDB()
        local config = configResolver:GetBarConfig(db, 'pet')
        if config.enable then
            self:TrySetFrameShown(frame, true)
        end
    else
        self:TrySetFrameShown(frame, false)
    end
end

state.UpdatePossessBar = function(self, db)
    local frame = barMod:Get('possess')
    if not frame then
        return
    end

    if C_ActionBar.IsPossessBarVisible() then
        specialButton:UpdateAll(frame)
        db = db or actionBars:GetDB()
        local config = configResolver:GetBarConfig(db, 'possess')
        if config.enable then
            self:TrySetFrameShown(frame, true)
        end
    else
        self:TrySetFrameShown(frame, false)
    end
end

state.RefreshBarCooldowns = function(self, barId)
    local frame = barMod:Get(barId)
    if frame then
        specialButton:RefreshBarCooldowns(frame)
    end
end

state.TrySetFrameShown = function(self, frame, shouldShow)
    if not frame then
        return
    end
    if InCombatLockdown() then
        frame.exuiPendingShown = shouldShow
        self.pendingVisibility = true
        return
    end
    frame.exuiPendingShown = nil
    if shouldShow then
        frame:Show()
    else
        frame:Hide()
    end
end

state.ApplyPendingVisibility = function(self)
    if InCombatLockdown() or not self.pendingVisibility then
        return
    end
    self.pendingVisibility = false
    for _, frame in pairs(barMod.instances) do
        local pending = frame.exuiPendingShown
        if pending ~= nil then
            if pending then
                frame:Show()
            else
                frame:Hide()
            end
            frame.exuiPendingShown = nil
        end
    end
end

state.ApplyPendingSlots = function(self)
    if InCombatLockdown() then
        return
    end
    for _, frame in pairs(barMod.instances) do
        for _, button in ipairs(frame.buttons or {}) do
            if button.exuiPendingSlot then
                local slot = button.exuiPendingSlot
                button.exuiPendingSlot = nil
                buttonMod:SetActionSlot(button, slot)
            end
        end
    end
    self.pendingSlots = false
end

state.ApplyAll = function(self, db)
    db = db or actionBars:GetDB()
    self:UpdateBar1Visibility(db)
    self:UpdateOverrideBar(db)
    self:UpdateStanceBar(db)
    self:UpdatePetBar(db)
    self:UpdatePossessBar(db)
end

state.UpdateAll = function(self, event)
    if InCombatLockdown() then
        local barId = event and self.COOLDOWN_ONLY_EVENTS[event]
        if barId then
            self:RefreshBarCooldowns(barId)
            return
        end
        self.pendingUpdate = true
        return
    end
    self.pendingUpdate = false
    self:ApplyAll()
end

state.OnRegenEnabled = function(self)
    self:ApplyPendingVisibility()
    buttonMod:ApplyPendingStateSetup()
    self:ApplyPendingSlots()
    if self.pendingUpdate or self.pendingSlots then
        self.pendingUpdate = false
        self:ApplyAll()
    end
end

state.Init = function(self)
    if self.initialized then
        return
    end
    self.initialized = true
    self.eventFrame = CreateFrame('Frame')
    self.eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
    for _, event in ipairs(self.EVENTS) do
        self.eventFrame:RegisterEvent(event)
    end
    self.eventFrame:SetScript('OnEvent', function(_, event)
        if event == 'PLAYER_REGEN_ENABLED' then
            state:OnRegenEnabled()
            return
        end
        state:UpdateAll(event)
    end)
end

state.Shutdown = function(self)
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame = nil
    end
    self.initialized = false
end
