---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsBar
local barMod = EXUI:GetModule('action-bars-bar')

---@class EXUIActionBarsManager
local manager = EXUI:GetModule('action-bars-manager')

---@class EXUIActionBarsKeybind
local keybind = EXUI:GetModule('action-bars-keybind')

keybind.buttons = {}
keybind.hooked = false
keybind.pendingReassign = false
keybind.inHousing = false

local function getBindingKeys(commandName)
    local keys = {}
    if not commandName then
        return keys
    end
    local a, b, c, d, e, f = GetBindingKey(commandName)
    local values = { a, b, c, d, e, f }
    for i = 1, #values do
        local key = values[i]
        if key and key ~= '' then
            keys[#keys + 1] = key
        end
    end
    return keys
end

keybind.SetButtonQuickKeybindMode = function(self, button, enabled)
    if not button then
        return
    end

    if enabled then
        if button.EnableMouseWheel then
            if button._exuiMouseWheelEnabled == nil then
                local wasEnabled = false
                if button.IsMouseWheelEnabled then
                    wasEnabled = button:IsMouseWheelEnabled()
                end
                button._exuiMouseWheelEnabled = wasEnabled
            end
            button:EnableMouseWheel(true)
        end
        if button.UpdateMouseWheelHandler then
            button:UpdateMouseWheelHandler()
        end
    else
        if button.EnableMouseWheel and button._exuiMouseWheelEnabled ~= nil then
            button:EnableMouseWheel(button._exuiMouseWheelEnabled)
            button._exuiMouseWheelEnabled = nil
        end
        if button.UpdateMouseWheelHandler then
            button:UpdateMouseWheelHandler()
        end
    end
end

keybind.RegisterButton = function(self, button)
    if not button or self.buttons[button] then return end
    self.buttons[button] = true
    self:EnsureQuickKeybindTexture(button)
end

keybind.EnsureQuickKeybindTexture = function(self, button)
    if button.QuickKeybindHighlightTexture then return end
    local tex = button:CreateTexture(nil, 'OVERLAY')
    tex:SetAtlas('UI-HUD-ActionBar-IconFrame-Mouseover')
    if tex.SetBlendMode then
        tex:SetBlendMode('ADD')
    end
    tex:SetAlpha(0)
    tex:SetAllPoints()
    button.QuickKeybindHighlightTexture = tex

    if QuickKeybindButtonTemplateMixin then
        button.QuickKeybindButtonOnEnter = QuickKeybindButtonTemplateMixin.QuickKeybindButtonOnEnter
        button.QuickKeybindButtonOnLeave = QuickKeybindButtonTemplateMixin.QuickKeybindButtonOnLeave
        button.QuickKeybindButtonOnClick = QuickKeybindButtonTemplateMixin.QuickKeybindButtonOnClick
        button.QuickKeybindButtonSetTooltip = QuickKeybindButtonTemplateMixin.QuickKeybindButtonSetTooltip
        button.DoModeChange = QuickKeybindButtonTemplateMixin.DoModeChange
        button.UpdateMouseWheelHandler = QuickKeybindButtonTemplateMixin.UpdateMouseWheelHandler
    end

    button:HookScript('OnEnter', function(self)
        if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then
            if self.QuickKeybindButtonOnEnter then
                self:QuickKeybindButtonOnEnter()
            end
        end
    end)
    button:HookScript('OnLeave', function(self)
        if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then
            if self.QuickKeybindButtonOnLeave then
                self:QuickKeybindButtonOnLeave()
            end
        end
    end)
    button:HookScript('OnClick', function(self, clickButton)
        if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then
            if self.QuickKeybindButtonOnClick then
                self:QuickKeybindButtonOnClick(clickButton)
            end
        end
    end)
    button:HookScript('OnMouseWheel', function(self, delta)
        if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then
            if self.QuickKeybindButtonOnMouseWheel then
                self:QuickKeybindButtonOnMouseWheel(delta)
            elseif QuickKeybindFrame then
                QuickKeybindFrame:OnMouseWheel(delta)
            end
        end
    end)

    if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then
        keybind:SetButtonQuickKeybindMode(button, true)
    end
end

keybind.SetAllHighlights = function(self, show)
    for button in pairs(self.buttons) do
        if button.QuickKeybindHighlightTexture then
            if show then
                button.QuickKeybindHighlightTexture:Show()
                button.QuickKeybindHighlightTexture:SetAlpha(0.5)
            else
                button.QuickKeybindHighlightTexture:Hide()
            end
        end
        if button.DoModeChange then
            button:DoModeChange(show)
        end
        self:SetButtonQuickKeybindMode(button, show)
    end
end

keybind.ClearOverrides = function(self)
    for _, frame in pairs(barMod.instances) do
        if frame.header then
            ClearOverrideBindings(frame.header)
        end
    end
end

-- The housing editor uses its own binding context; our overrides would shadow it
keybind.HousingStateChanged = function(self, active)
    active = not not active
    if active == self.inHousing then
        return
    end
    self.inHousing = active
    if active then
        self:ClearOverrides()
    else
        self:ReassignBindings()
    end
end

keybind.ScheduleReassignBindings = function(self)
    if self.reassignScheduled then
        return
    end
    self.reassignScheduled = true
    C_Timer.After(0, function()
        keybind.reassignScheduled = false
        keybind:ReassignBindings()
    end)
end

keybind.ReassignBindings = function(self)
    if not manager.enabled or self.inHousing then
        return
    end
    if InCombatLockdown() then
        self.pendingReassign = true
        return
    end
    self.pendingReassign = false

    for barId, frame in pairs(barMod.instances) do
        local header = frame.header
        if header then
            ClearOverrideBindings(header)
            for index, button in ipairs(frame.buttons or {}) do
                local commandName = button.commandName or definitions:GetCommandName(barId, button.id or index)
                if commandName then
                    button.commandName = commandName
                    local buttonName = button:GetName()
                    for _, key in ipairs(getBindingKeys(commandName)) do
                        SetOverrideBindingClick(header, false, key, buttonName, 'Keybind')
                    end
                end
            end
        end
    end
end

keybind.HookActionButtonUtil = function(self)
    if self.hooked or not ActionButtonUtil then return end
    self.hooked = true

    ActionButtonUtil.SetAllQuickKeybindButtonHighlights = function(show)
        keybind:SetAllHighlights(show)
    end
end

keybind.HookBindingEvents = function(self)
    if self.bindingEventsHooked then
        return
    end
    self.bindingEventsHooked = true

    if not self.eventFrame then
        self.eventFrame = CreateFrame('Frame')
        self.eventFrame:RegisterEvent('UPDATE_BINDINGS')
        self.eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
        self.eventFrame:SetScript('OnEvent', function(_, event)
            if event == 'UPDATE_BINDINGS' then
                keybind:ScheduleReassignBindings()
            elseif event == 'PLAYER_REGEN_ENABLED' and keybind.pendingReassign then
                keybind:ScheduleReassignBindings()
            end
        end)
    end

    if EventRegistry then
        EventRegistry:RegisterCallback('KeybindListener.RebindSuccess', function()
            keybind:ScheduleReassignBindings()
        end, keybind)
        EventRegistry:RegisterCallback('HouseEditor.StateUpdated', function(_, active)
            keybind:HousingStateChanged(active)
        end, keybind)
    end
end

keybind.EnterQuickKeybindMode = function(self)
    self:HookActionButtonUtil()
    self:HookBindingEvents()
    if KeybindFrames_ToggleQuickKeybindMode then
        KeybindFrames_ToggleQuickKeybindMode()
    elseif QuickKeybindFrame then
        QuickKeybindFrame:Show()
    end
end

keybind.Init = function(self)
    self:HookActionButtonUtil()
    self:HookBindingEvents()
    if C_HouseEditor and C_HouseEditor.IsHouseEditorActive then
        self.inHousing = C_HouseEditor.IsHouseEditorActive()
    end
    self:ReassignBindings()
end

keybind.Clear = function(self)
    self:ClearOverrides()
    wipe(self.buttons)
    self.pendingReassign = false
    if EventRegistry and self.bindingEventsHooked then
        EventRegistry:UnregisterCallback('KeybindListener.RebindSuccess', keybind)
        EventRegistry:UnregisterCallback('HouseEditor.StateUpdated', keybind)
    end
    self.bindingEventsHooked = false
end
