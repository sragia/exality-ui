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
    'UPDATE_EXTRA_ACTIONBAR',
    'PET_BATTLE_OPENING_START',
    'PET_BATTLE_CLOSE',
    'PET_BAR_UPDATE',
    'PET_BAR_UPDATE_COOLDOWN',
    'PET_UI_UPDATE',
    'UNIT_PET',
}

state.GetEffectiveMainBarPage = function(self)
    if (C_ActionBar.HasVehicleActionBar() and UnitVehicleSkin('player') and UnitVehicleSkin('player') ~= '')
        or (C_ActionBar.HasOverrideActionBar() and C_ActionBar.GetOverrideBarSkin() and C_ActionBar.GetOverrideBarSkin() ~= 0) then
        return nil -- override bar handles this
    end
    if C_ActionBar.HasVehicleActionBar() then
        return C_ActionBar.GetVehicleBarIndex()
    end
    if C_ActionBar.HasOverrideActionBar() then
        return C_ActionBar.GetOverrideBarIndex()
    end
    if C_ActionBar.HasTempShapeshiftActionBar() then
        return C_ActionBar.GetTempShapeshiftBarIndex()
    end
    if C_ActionBar.HasBonusActionBar() and C_ActionBar.GetActionBarPage() == 1 then
        return C_ActionBar.GetBonusBarIndex()
    end
    return C_ActionBar.GetActionBarPage()
end

state.UpdateBar1 = function(self)
    local frame = barMod:Get('bar1')
    if not frame then return end

    local page = self:GetEffectiveMainBarPage()
    if not page then
        self:TrySetFrameShown(frame, false)
        return
    end

    local db = EXUI:GetModule('action-bars'):GetDB()
    local config = EXUI:GetModule('action-bars-config-resolver'):GetBarConfig(db, 'bar1')
    if config.enable and config.visibility ~= 'hidden' then
        self:TrySetFrameShown(frame, true)
    end

    for i, button in ipairs(frame.buttons) do
        local slot = definitions:GetActionSlot('bar1', i, page)
        buttonMod:SetActionSlot(button, slot)
    end
end

state.UpdateFixedPlayerBars = function(self)
    for _, barId in ipairs(definitions.PLAYER_BAR_IDS) do
        local def = definitions:Get(barId)
        if def and not def.dynamicPage then
            local frame = barMod:Get(barId)
            if frame then
                for i, button in ipairs(frame.buttons) do
                    local slot = definitions:GetActionSlot(barId, i)
                    if slot then
                        buttonMod:SetActionSlot(button, slot)
                    end
                end
            end
        end
    end
end

state.UpdateOverrideBar = function(self)
    local frame = barMod:Get('override')
    if not frame then return end

    local showOverride = (C_ActionBar.HasVehicleActionBar() and UnitVehicleSkin('player') and UnitVehicleSkin('player') ~= '')
        or (C_ActionBar.HasOverrideActionBar() and C_ActionBar.GetOverrideBarSkin() and C_ActionBar.GetOverrideBarSkin() ~= 0)

    if not showOverride or C_PetBattles.IsInBattle() then
        self:TrySetFrameShown(frame, false)
        return
    end

    local page = C_ActionBar.GetOverrideBarIndex()
    for i, button in ipairs(frame.buttons) do
        local slot = (page - 1) * 12 + i
        buttonMod:SetActionSlot(button, slot)
    end

    local db = EXUI:GetModule('action-bars'):GetDB()
    local config = EXUI:GetModule('action-bars-config-resolver'):GetBarConfig(db, 'override')
    if config.enable then
        self:TrySetFrameShown(frame, true)
    end
end

state.UpdateExtraBar = function(self)
    local frame = barMod:Get('extra')
    if not frame or not frame.buttons[1] then return end

    if C_ActionBar.HasExtraActionBar() then
        local page = C_ActionBar.GetExtraBarIndex()
        local slot = (page - 1) * 12 + 1
        buttonMod:SetActionSlot(frame.buttons[1], slot)
        local db = EXUI:GetModule('action-bars'):GetDB()
        local config = EXUI:GetModule('action-bars-config-resolver'):GetBarConfig(db, 'extra')
        if config.enable then
            self:TrySetFrameShown(frame, true)
        end
    else
        if not KeybindFrames_InQuickKeybindMode or not KeybindFrames_InQuickKeybindMode() then
            self:TrySetFrameShown(frame, false)
        end
    end
end

state.UpdateStanceBar = function(self)
    local frame = barMod:Get('stance')
    if not frame then return end

    local numForms = GetNumShapeshiftForms()
    local shouldShow = numForms > 0
        and not C_ActionBar.IsPossessBarVisible()
        and (not ActionBarController_GetCurrentActionBarState or ActionBarController_GetCurrentActionBarState() ~= LE_ACTIONBAR_STATE_OVERRIDE)

    if shouldShow and (not ActionBarBusy or not ActionBarBusy()) then
        specialButton:UpdateAll(frame)
        local db = EXUI:GetModule('action-bars'):GetDB()
        local config = EXUI:GetModule('action-bars-config-resolver'):GetBarConfig(db, 'stance')
        if config.enable then
            self:TrySetFrameShown(frame, true)
        end
    else
        self:TrySetFrameShown(frame, false)
    end
end

state.UpdatePetBar = function(self)
    local frame = barMod:Get('pet')
    if not frame then return end

    local shouldShow = PetHasActionBar and PetHasActionBar()
    if shouldShow then
        specialButton:UpdateAll(frame)
        local db = EXUI:GetModule('action-bars'):GetDB()
        local config = EXUI:GetModule('action-bars-config-resolver'):GetBarConfig(db, 'pet')
        if config.enable then
            self:TrySetFrameShown(frame, true)
        end
    else
        self:TrySetFrameShown(frame, false)
    end
end

state.UpdatePossessBar = function(self)
    local frame = barMod:Get('possess')
    if not frame then return end

    if C_ActionBar.IsPossessBarVisible() then
        specialButton:UpdateAll(frame)
        local db = EXUI:GetModule('action-bars'):GetDB()
        local config = EXUI:GetModule('action-bars-config-resolver'):GetBarConfig(db, 'possess')
        if config.enable then
            self:TrySetFrameShown(frame, true)
        end
    else
        self:TrySetFrameShown(frame, false)
    end
end

state.COOLDOWN_ONLY_EVENTS = {
    UPDATE_SHAPESHIFT_COOLDOWN = 'stance',
    PET_BAR_UPDATE_COOLDOWN = 'pet',
}

state.RefreshBarCooldowns = function(self, barId)
    local frame = barMod:Get(barId)
    if frame then
        specialButton:RefreshBarCooldowns(frame)
    end
end

state.pendingUpdate = false
state.pendingVisibility = false
state.pendingSlots = false

state.TrySetFrameShown = function(self, frame, shouldShow)
    if not frame then return end
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

state.ApplyAll = function(self)
    self:UpdateBar1()
    self:UpdateFixedPlayerBars()
    self:UpdateOverrideBar()
    self:UpdateExtraBar()
    self:UpdateStanceBar()
    self:UpdatePetBar()
    self:UpdatePossessBar()
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
    if self.pendingUpdate or self.pendingSlots then
        self.pendingUpdate = false
        self.pendingSlots = false
        self:ApplyAll()
    end
end

state.Init = function(self)
    if self.initialized then return end
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
    end
end
