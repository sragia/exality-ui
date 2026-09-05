---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsStyle
local barStyle = EXUI:GetModule('action-bars-style')

---@class EXUIActionBarsLayout
local barLayout = EXUI:GetModule('action-bars-layout')

---@class EXUIActionBarsButton
local buttonMod = EXUI:GetModule('action-bars-button')

---@class EXUIActionBarsBar
local barMod = EXUI:GetModule('action-bars-bar')

---@class EXUIActionBarsPing
local ping = EXUI:GetModule('action-bars-ping')

---@class EXUIActionBarsSpecialButton
local special = EXUI:GetModule('action-bars-special-button')

local function bindTemplateChildren(button)
    local name = button:GetName()
    button.icon = button.icon or _G[name .. 'Icon']
    button.cooldown = button.cooldown or _G[name .. 'Cooldown']
end

special.BAR_EVENTS = {
    stance = {
        'PLAYER_ENTERING_WORLD',
        'UPDATE_BONUS_ACTIONBAR',
        'ACTIONBAR_PAGE_CHANGED',
        'UPDATE_SHAPESHIFT_FORM',
        'UPDATE_SHAPESHIFT_FORMS',
        'UPDATE_SHAPESHIFT_USABLE',
        'UPDATE_SHAPESHIFT_COOLDOWN',
        'UPDATE_VEHICLE_ACTIONBAR',
        'UPDATE_OVERRIDE_ACTIONBAR',
        'UPDATE_POSSESS_BAR',
        'PLAYER_REGEN_ENABLED',
    },
    pet = {
        'PLAYER_ENTERING_WORLD',
        'PLAYER_CONTROL_LOST',
        'PLAYER_CONTROL_GAINED',
        'PLAYER_FARSIGHT_FOCUS_CHANGED',
        'UNIT_PET',
        'UNIT_FLAGS',
        'PET_BAR_UPDATE',
        'PET_BAR_UPDATE_COOLDOWN',
        'PET_BAR_UPDATE_USABLE',
        'PET_UI_UPDATE',
        'PLAYER_TARGET_CHANGED',
        'UPDATE_VEHICLE_ACTIONBAR',
        'PLAYER_MOUNT_DISPLAY_CHANGED',
        'PLAYER_REGEN_ENABLED',
    },
}

special.COOLDOWN_ONLY_EVENTS = {
    UPDATE_SHAPESHIFT_COOLDOWN = true,
    PET_BAR_UPDATE_COOLDOWN = true,
}

special.PET_VISIBILITY_EVENTS = {
    PET_BAR_UPDATE = true,
    PET_UI_UPDATE = true,
    UNIT_PET = true,
    UPDATE_VEHICLE_ACTIONBAR = true,
}

special.CreateStanceButton = function(self, barId, index, parent, barConfig)
    local name = 'EXUIActionBar_' .. barId .. '_' .. index
    local button = CreateFrame('CheckButton', name, parent, 'StanceButtonTemplate')
    button:SetID(index)
    button.index = index
    button.id = index
    button.exuiBarId = barId
    button.commandName = definitions:GetCommandName(barId, index)
    bindTemplateChildren(button)

    button.UpdateCooldownOnly = function(self)
        if not self.cooldown then
            return
        end
        local id = self:GetID()
        local start, duration, enable = GetShapeshiftFormCooldown(id)
        CooldownFrame_Set(self.cooldown, start, duration, enable)
    end

    button.HasAction = function(self)
        return GetShapeshiftFormInfo(self:GetID())
    end

    button.Update = function(self)
        local id = self:GetID()
        local texture, isActive, isCastable = GetShapeshiftFormInfo(id)
        local inCombat = InCombatLockdown()

        if not texture then
            if not inCombat then
                self:Hide()
            end
            ping:RefreshAttributes(self)
            return
        end

        if inCombat then
            if not self:IsShown() then
                return
            end
        else
            self:Show()
        end

        if self.icon then
            self.icon:SetTexture(texture)
            self.icon:Show()
        end

        if self.cooldown then
            self.cooldown:Show()
            self:UpdateCooldownOnly()
        end

        self:SetChecked(isActive and true or false)

        if self.icon then
            if isCastable then
                self.icon:SetVertexColor(1.0, 1.0, 1.0)
            else
                self.icon:SetVertexColor(0.4, 0.4, 0.4)
            end
        end

        ping:RefreshAttributes(self)
    end
    button.UpdateAction = button.Update

    EXUI:SetSize(button, barConfig.width, barConfig.height)
    special:ApplyStyle(button, barId, barConfig)
    return button
end

special.CreatePetButton = function(self, barId, index, header, barConfig)
    local name = 'EXUIActionBar_' .. barId .. '_' .. index
    local button = CreateFrame('CheckButton', name, header, 'PetActionButtonTemplate')
    button:SetID(index)
    button.index = index
    button.id = index
    button.exuiBarId = barId
    button.commandName = definitions:GetCommandName(barId, index)
    bindTemplateChildren(button)

    button.UpdateCooldownOnly = function(self)
        if not self.cooldown then
            return
        end
        local id = self:GetID()
        local start, duration, enable = GetPetActionCooldown(id)
        CooldownFrame_Set(self.cooldown, start, duration, enable)
    end

    button.Update = function(self)
        local id = self:GetID()
        local petName, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(id)

        if self.icon then
            if not isToken and texture then
                self.icon:SetTexture(texture)
                self.icon:Show()
            elseif isToken and texture then
                self.icon:SetTexture(_G[texture])
                self.icon:Show()
            else
                self.icon:Hide()
            end

            if texture and GetPetActionSlotUsable(id) then
                self.icon:SetVertexColor(1.0, 1.0, 1.0)
            elseif texture then
                self.icon:SetVertexColor(0.4, 0.4, 0.4)
            end
        end

        if isActive then
            self:SetChecked(true)
        else
            self:SetChecked(false)
        end

        if self.AutoCastOverlay then
            self.AutoCastOverlay:SetShown(autoCastAllowed)
            if autoCastAllowed and self.AutoCastOverlay.ShowAutoCastEnabled then
                self.AutoCastOverlay:ShowAutoCastEnabled(autoCastEnabled)
            end
        end

        self:UpdateCooldownOnly()
        ping:RefreshAttributes(self)
    end
    button.UpdateAction = button.Update

    EXUI:SetSize(button, barConfig.width, barConfig.height)
    special:ApplyStyle(button, barId, barConfig)
    return button
end

special.ApplyStyle = function(self, button, barId, barConfig)
    button.exuiBarConfig = barConfig
    if barStyle:ShouldUseMasque(barConfig) then
        local group = barStyle:GetMasqueGroup(barId, barConfig.masqueSkin)
        if group and not button.MasqueSkinned then
            group:AddButton(button, nil, 'Action')
            button.MasqueSkinned = true
        end
    end
    barStyle:HookButtonUpdates(button, barId)
    barStyle:ApplyIconTexCoords(button, barConfig.width, barConfig.height, barConfig.zoom)
    barStyle:OnButtonUpdated(button, barConfig)
end

special.RefreshBarCooldowns = function(self, barFrame)
    if not barFrame or not barFrame.buttons then
        return
    end
    for _, button in ipairs(barFrame.buttons) do
        if button.UpdateCooldownOnly then
            button:UpdateCooldownOnly()
        end
    end
end

special.ShouldShowStanceBar = function(self, frame)
    if frame and frame.editor and frame.editor:IsShown() then
        return true
    end
    if GetNumShapeshiftForms() == 0 then
        return false
    end
    if C_ActionBar.IsPossessBarVisible() then
        return false
    end
    if ActionBarController_GetCurrentActionBarState
        and ActionBarController_GetCurrentActionBarState() == LE_ACTIONBAR_STATE_OVERRIDE then
        return false
    end
    if ActionBarBusy and ActionBarBusy() then
        return false
    end
    return true
end

special.ApplyStanceBarVisibility = function(self, frame, barConfig)
    if not frame or not barConfig then
        return
    end
    if not barConfig.enable or barConfig.visibility == 'hidden' then
        frame:Hide()
        return
    end
    if not self:ShouldShowStanceBar(frame) then
        frame:Hide()
        return
    end
    frame:Show()
    if frame.editor and frame.editor:IsShown() then
        frame:SetAlpha(1)
    else
        barMod:UpdateVisibilityAlpha(frame, barConfig, frame.isHovering)
    end
end

special.UpdateStanceButtons = function(self, frame, barConfig)
    if not frame or not frame.buttons then
        return
    end

    barConfig = barConfig or frame.exuiLastConfig
    if not barConfig then
        return
    end
    frame.exuiLastConfig = barConfig

    local def = definitions:Get('stance')
    local maxButtons = def and def.numButtons or 10
    local numForms = math.min(GetNumShapeshiftForms(), maxButtons)

    if InCombatLockdown() then
        frame.exuiStanceLayoutOnCombatLeave = true
        for i = 1, math.min(numForms, #frame.buttons) do
            local button = frame.buttons[i]
            if button.UpdateCooldownOnly then
                button:UpdateCooldownOnly()
            elseif button.Update and button:IsShown() then
                button:Update()
            end
        end
        return
    end

    while #frame.buttons < numForms do
        local index = #frame.buttons + 1
        local button = self:CreateStanceButton('stance', index, frame.header, barConfig)
        buttonMod:RegisterWithKeybind(button)
        table.insert(frame.buttons, button)
    end

    for i, button in ipairs(frame.buttons) do
        if i > numForms then
            button:Hide()
        end
    end

    if numForms == 0 then
        frame:SetSize(0.01, 0.01)
        self:ApplyStanceBarVisibility(frame, barConfig)
        return
    end

    local layoutConfig = {}
    for key, value in pairs(barConfig) do
        layoutConfig[key] = value
    end
    layoutConfig.numButtons = numForms
    layoutConfig.buttonsPerRow = math.min(barConfig.buttonsPerRow or numForms, numForms)
    barLayout:Apply(frame, layoutConfig, frame.buttons)

    for i = 1, numForms do
        local button = frame.buttons[i]
        if button then
            EXUI:SetSize(button, barConfig.width, barConfig.height)
            self:ApplyStyle(button, 'stance', barConfig)
            if button.Update then
                button:Update()
            end
        end
    end
    for i = numForms + 1, #frame.buttons do
        frame.buttons[i]:Hide()
    end

    self:ApplyStanceBarVisibility(frame, barConfig)
    if frame.exuiLastStanceCount ~= numForms then
        frame.exuiLastStanceCount = numForms
        EXUI:GetModule('action-bars-keybind'):ScheduleReassignBindings()
    end
end

special.UpdateAll = function(self, barFrame)
    if not barFrame or not barFrame.buttons then
        return
    end
    for _, button in ipairs(barFrame.buttons) do
        if button.Update then
            button:Update()
        elseif button.UpdateAction then
            button:UpdateAction()
        end
    end
end

special.SchedulePetActionRetry = function(self, frame)
    if not frame or frame.exuiPetActionRetryPending then
        return
    end
    frame.exuiPetActionRetryPending = true
    C_Timer.After(0, function()
        frame.exuiPetActionRetryPending = nil
        if not (PetHasActionBar and PetHasActionBar()) then
            return
        end
        self:UpdateAll(frame)
    end)
end

special.OnBarEvent = function(self, frame, event, ...)
    if frame.barType == 'stance' then
        if event == 'PLAYER_REGEN_ENABLED' then
            frame.exuiUpdateStateOnCombatLeave = nil
            frame.exuiStanceLayoutOnCombatLeave = nil
            self:UpdateStanceButtons(frame, frame.exuiLastConfig)
            return
        end

        if self.COOLDOWN_ONLY_EVENTS[event] then
            self:RefreshBarCooldowns(frame)
            return
        end

        if InCombatLockdown() then
            frame.exuiStanceLayoutOnCombatLeave = true
            self:UpdateAll(frame)
        else
            self:UpdateStanceButtons(frame, frame.exuiLastConfig)
        end
        return
    end

    if event == 'UNIT_PET' and ... ~= 'player' then
        return
    end

    if event == 'PLAYER_REGEN_ENABLED' then
        frame.exuiUpdateStateOnCombatLeave = nil
        self:UpdateAll(frame)
        return
    end

    if self.COOLDOWN_ONLY_EVENTS[event] then
        self:RefreshBarCooldowns(frame)
        return
    end

    if InCombatLockdown() then
        frame.exuiUpdateStateOnCombatLeave = true
        self:UpdateAll(frame)
    else
        self:UpdateAll(frame)
    end

    if self.PET_VISIBILITY_EVENTS[event]
        and PetHasActionBar and PetHasActionBar()
        and not GetPetActionInfo(1) then
        self:SchedulePetActionRetry(frame)
    end
end

special.InitBarEvents = function(self, frame, barType)
    if frame.eventHooked then
        return
    end
    frame.eventHooked = true
    frame.barType = barType

    local events = self.BAR_EVENTS[barType]
    if not events then
        return
    end

    for _, event in ipairs(events) do
        frame:RegisterEvent(event)
    end

    frame:SetScript('OnEvent', function(f, event, ...)
        special:OnBarEvent(f, event, ...)
    end)

    if barType == 'pet' then
        frame:HookScript('OnShow', function(f)
            special:UpdateAll(f)
            if PetHasActionBar and PetHasActionBar() and not GetPetActionInfo(1) then
                special:SchedulePetActionRetry(f)
            end
        end)
    end
end
