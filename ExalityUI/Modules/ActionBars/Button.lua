---@class ExalityUI
local EXUI = select(2, ...)

local LAB = LibStub('LibActionButton-1.0')

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsStyle
local barStyle = EXUI:GetModule('action-bars-style')

---@class EXUIActionBarsButton
local buttonMod = EXUI:GetModule('action-bars-button')

buttonMod.CreateActionButton = function(self, barId, index, header, barConfig)
    local name = 'EXUIActionBar_' .. barId .. '_' .. index
    local commandName = definitions:GetCommandName(barId, index)
    local button = LAB:CreateButton(index, name, header, barStyle:BuildLABConfig(barConfig, commandName))

    button.commandName = commandName
    button.exuiBarId = barId

    barStyle:ApplyToButton(button, barId, barConfig, commandName)
    return button
end

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
    barStyle:SyncActionCooldown(button)
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
