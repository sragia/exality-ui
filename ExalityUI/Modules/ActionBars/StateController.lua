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

state.PET_VISIBILITY_EVENTS = {
    PET_BAR_UPDATE = true,
    PET_UI_UPDATE = true,
    UNIT_PET = true,
    UPDATE_VEHICLE_ACTIONBAR = true,
}

-- Secure visibility: Show/Hide on a parent of protected pet buttons is blocked in combat.
state.PET_VISIBILITY_DRIVER = '[overridebar]hide;[vehicleui]hide;[possessbar]hide;[petbattle]hide;[pet]show;hide'

state.pendingUpdate = false
state.pendingVisibility = false
state.pendingSlots = false
state.pendingPetDriver = false

-- Blizzard shows OverrideActionBar only for skinned vehicle/override UIs.
state.IsSkinnedOverrideBarActive = function(self)
    return (C_ActionBar.HasVehicleActionBar() and UnitVehicleSkin('player') and UnitVehicleSkin('player') ~= '')
        or (C_ActionBar.HasOverrideActionBar() and C_ActionBar.GetOverrideBarSkin() and C_ActionBar.GetOverrideBarSkin() ~= 0)
end

-- Prefer bar1 paging when "Possess / Vehicle Pages" is enabled (default).
state.ShouldPageBar1ForPossess = function(self, db)
    db = db or actionBars:GetDB()
    local bar1 = db.bars and db.bars.bar1
    local states = bar1 and bar1.states
    return not states or states.possess ~= false
end

state.GetOverrideActionPage = function(self)
    if C_ActionBar.HasVehicleActionBar() then
        return C_ActionBar.GetVehicleBarIndex()
    end
    if C_ActionBar.HasOverrideActionBar() then
        return C_ActionBar.GetOverrideBarIndex()
    end
    return nil
end

state.IsOverrideBarActive = function(self)
    return self:IsSkinnedOverrideBarActive()
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

    if self:IsSkinnedOverrideBarActive() and not self:ShouldPageBar1ForPossess(db) then
        local overrideConfig = configResolver:GetBarConfig(db, 'override')
        if overrideConfig.enable then
            self:TrySetFrameShown(frame, false)
            return
        end
    end

    self:TrySetFrameShown(frame, true)
end

state.UpdateOverrideBar = function(self, db)
    local frame = barMod:Get('override')
    if not frame then
        return
    end

    db = db or actionBars:GetDB()

    if self:ShouldPageBar1ForPossess(db)
        or not self:IsSkinnedOverrideBarActive()
        or C_PetBattles.IsInBattle() then
        self:TrySetFrameShown(frame, false)
        return
    end

    local page = self:GetOverrideActionPage()
    if not page then
        self:TrySetFrameShown(frame, false)
        return
    end

    for i, button in ipairs(frame.buttons) do
        local slot = (page - 1) * 12 + i
        buttonMod:SetActionSlot(button, slot)
    end

    local config = configResolver:GetBarConfig(db, 'override')
    if config.enable then
        self:TrySetFrameShown(frame, true)
    else
        self:TrySetFrameShown(frame, false)
    end
end

state.UpdateStanceBar = function(self, db)
    local frame = barMod:Get('stance')
    if not frame then
        return
    end

    db = db or actionBars:GetDB()
    local config = configResolver:GetBarConfig(db, 'stance')
    if self.stanceUpdatePending then
        self.pendingStanceConfig = config
        return
    end

    self.stanceUpdatePending = true
    self.pendingStanceConfig = config
    C_Timer.After(0, function()
        self.stanceUpdatePending = false
        local pendingConfig = self.pendingStanceConfig
        self.pendingStanceConfig = nil
        local stanceFrame = barMod:Get('stance')
        if stanceFrame and pendingConfig then
            specialButton:UpdateStanceButtons(stanceFrame, pendingConfig)
        end
    end)
end

state.ApplyPetVisibilityDriver = function(self, frame, config)
    if not frame then
        return
    end

    local shouldDrive = config and config.enable and config.visibility ~= 'hidden' and not barMod:IsBarEditorActive(frame)
    if InCombatLockdown() then
        self.pendingPetDriver = true
        return
    end

    self.pendingPetDriver = false
    if shouldDrive then
        RegisterStateDriver(frame, 'visibility', self.PET_VISIBILITY_DRIVER)
        frame.exuiHasVisibilityDriver = true
        return
    end

    UnregisterStateDriver(frame, 'visibility')
    frame.exuiHasVisibilityDriver = nil
    if barMod:IsBarEditorActive(frame) and config and config.enable and config.visibility ~= 'hidden' then
        frame:Show()
    else
        frame:Hide()
    end
end

state.UpdatePetBar = function(self, db)
    local frame = barMod:Get('pet')
    if not frame then
        return
    end

    db = db or actionBars:GetDB()
    local config = configResolver:GetBarConfig(db, 'pet')
    self:ApplyPetVisibilityDriver(frame, config)
    specialButton:UpdateAll(frame)

    if not config.enable or config.visibility == 'hidden' then
        return
    end

    if barMod:IsBarEditorActive(frame) then
        frame:SetAlpha(1)
    else
        barMod:UpdateVisibilityAlpha(frame, config, frame.isHovering)
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
    if InCombatLockdown() and frame:IsProtected() then
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
end

state.UpdateAll = function(self, event, ...)
    if event == 'UNIT_PET' and ... ~= 'player' then
        return
    end

    if InCombatLockdown() then
        local barId = event and self.COOLDOWN_ONLY_EVENTS[event]
        if barId then
            self:RefreshBarCooldowns(barId)
            return
        end
        if event and self.PET_VISIBILITY_EVENTS[event] then
            self:UpdatePetBar()
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
    if self.pendingPetDriver then
        local petFrame = barMod:Get('pet')
        if petFrame then
            self:ApplyPetVisibilityDriver(petFrame, configResolver:GetBarConfig(actionBars:GetDB(), 'pet'))
        end
    end
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
    self.eventFrame:SetScript('OnEvent', function(_, event, ...)
        if event == 'PLAYER_REGEN_ENABLED' then
            state:OnRegenEnabled()
            return
        end
        state:UpdateAll(event, ...)
    end)
end

state.Shutdown = function(self)
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame = nil
    end
    self.initialized = false
end
