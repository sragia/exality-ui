---@class ExalityUI
local EXUI = select(2, ...)

local LAB = LibStub('LibActionButton-1.0')

---@class EXUIActionBarsPing
local ping = EXUI:GetModule('action-bars-ping')

ping.initialized = false

-- LAB UpdateState runs this securely on paging, so ping-receiver can change in combat.
local ON_STATE_CHANGED = [[
    local _, type, action = ...
    if type == "spell" or type == "item" then
        self:SetAttribute("ping-receiver", true)
    elseif type == "action" and action and HasAction(action) then
        self:SetAttribute("ping-receiver", true)
    else
        self:SetAttribute("ping-receiver", nil)
    end
]]

local function GetLABActionButtonInfo(self)
    local stateType = self._state_type
    local action = self._state_action
    if stateType == 'action' and action then
        local actionType, id, subType = GetActionInfo(action)
        local isUsable, notEnoughMana
        if C_ActionBar and C_ActionBar.IsUsableAction then
            isUsable, notEnoughMana = C_ActionBar.IsUsableAction(action)
        end
        return {
            id = id,
            actionType = actionType,
            subType = subType,
            isUsable = isUsable,
            notEnoughMana = notEnoughMana,
        }
    end
    if (stateType == 'spell' or stateType == 'item') and action then
        return {
            id = action,
            actionType = stateType,
        }
    end
end

ping.RefreshAttributes = function(self, button)
    if not button or not button.UpdatePingAttributes or InCombatLockdown() then
        return
    end
    button:UpdatePingAttributes()
end

ping.InstallLABButton = function(self, button)
    if not button or button.exuiPingInstalled or not button.UpdatePingAttributes then
        return
    end

    button.exuiPingInstalled = true
    button.GetActionButtonInfo = GetLABActionButtonInfo

    if not InCombatLockdown() then
        if not button:GetAttribute('OnStateChanged') then
            button:SetAttribute('OnStateChanged', ON_STATE_CHANGED)
        end
        button:UpdatePingAttributes()
    end
end

ping.Init = function(self)
    if self.initialized then
        return
    end
    self.initialized = true

    LAB.RegisterCallback(self, 'OnButtonCreated', function(_, button)
        self:InstallLABButton(button)
    end)
end
