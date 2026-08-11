---@class ExalityUI
local EXUI = select(2, ...)

local LAB = LibStub('LibActionButton-1.0')

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsStyle
local barStyle = EXUI:GetModule('action-bars-style')

---@class EXUIActionBarsSpellPicker
local spellPicker = EXUI:GetModule('action-bars-spell-picker')

---@class EXUIActionBarsButton
local buttonMod = EXUI:GetModule('action-bars-button')

buttonMod.RETAIL_PAGES = 18

buttonMod.SetupActionStates = function(self, button, barId, buttonIndex, buttonOffset)
    if not button or not barId or not buttonIndex then
        return
    end

    buttonOffset = buttonOffset or 0
    local def = definitions:Get(barId)
    local offsetId = (buttonIndex + buttonOffset - 1) % 12 + 1

    for page = 1, self.RETAIL_PAGES do
        button:SetState(page, 'action', (page - 1) * 12 + offsetId)
    end

    if def and def.baseSlot then
        button:SetState(0, 'action', def.baseSlot + buttonIndex - 1)
    elseif barId == 'bar1' then
        button:SetState(0, 'action', buttonIndex)
    end
end

buttonMod.CreateActionButton = function(self, barId, index, header, barConfig)
    local name = 'EXUIActionBar_' .. barId .. '_' .. index
    local commandName = definitions:GetCommandName(barId, index)
    local button = LAB:CreateButton(index, name, header, barStyle:BuildLABConfig(barConfig, commandName))

    button.commandName = commandName
    button.exuiBarId = barId

    if not InCombatLockdown() then
        self:SetupActionStates(button, barId, index, 0)
    else
        button.exuiPendingStateSetup = { barId, index, 0 }
    end

    barStyle:ApplyToButton(button, barId, barConfig, commandName)
    spellPicker:RegisterButton(button)

    if not InCombatLockdown() and button.UpdateAction then
        button:UpdateAction()
    end

    return button
end

-- Dynamic slot assignment for override/extra bars only.
buttonMod.SetActionSlot = function(self, button, actionSlot)
    if not button or not actionSlot then
        return
    end
    if InCombatLockdown() then
        button.exuiPendingSlot = actionSlot
        local stateController = EXUI:GetModule('action-bars-state')
        stateController.pendingSlots = true
        return
    end
    button.exuiPendingSlot = nil
    button:SetState(0, 'action', actionSlot)
    if button.UpdateAction then
        button:UpdateAction()
    end
end

buttonMod.ApplyPendingStateSetup = function(self)
    if InCombatLockdown() then
        return
    end
    local barMod = EXUI:GetModule('action-bars-bar')
    for _, frame in pairs(barMod.instances) do
        for _, button in ipairs(frame.buttons or {}) do
            if button.exuiPendingStateSetup then
                local barId, index, offset = unpack(button.exuiPendingStateSetup)
                button.exuiPendingStateSetup = nil
                self:SetupActionStates(button, barId, index, offset)
                if button.UpdateAction then
                    button:UpdateAction()
                end
            end
        end
    end
end

buttonMod.RefreshBar = function(self, barFrame, barConfig)
    if not barFrame or not barFrame.buttons then return end
    for _, button in ipairs(barFrame.buttons) do
        if barConfig then
            button.exuiBarConfig = barConfig
        end
        barStyle:OnButtonUpdated(button, barConfig or button.exuiBarConfig)
    end
end

buttonMod.RefreshAll = function(self)
    local barMod = EXUI:GetModule('action-bars-bar')
    local resolver = EXUI:GetModule('action-bars-config-resolver')
    local db = EXUI:GetModule('action-bars'):GetDB()
    for _, barId in ipairs(EXUI:GetModule('action-bars-definitions').ALL_BAR_IDS) do
        local frame = barMod:Get(barId)
        if frame then
            local config = resolver:GetBarConfig(db, barId)
            self:RefreshBar(frame, config)
        end
    end
end

buttonMod.Refresh = function(self, button, barId, barConfig)
    local index = button.id
    local commandName = definitions:GetCommandName(barId, index)
    barStyle:ApplyToButton(button, barId, barConfig, commandName)
end

buttonMod.RegisterWithKeybind = function(self, button)
    local keybind = EXUI:GetModule('action-bars-keybind')
    if keybind then
        keybind:RegisterButton(button)
    end
end
