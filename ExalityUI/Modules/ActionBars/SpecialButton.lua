---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsStyle
local barStyle = EXUI:GetModule('action-bars-style')

---@class EXUIActionBarsSpecialButton
local special = EXUI:GetModule('action-bars-special-button')

special.CreateStanceButton = function(self, barId, index, parent, barConfig)
    local name = 'EXUIActionBar_' .. barId .. '_' .. index
    local button = CreateFrame('CheckButton', name, parent, 'SecureActionButtonTemplate, ActionButtonTemplate')
    button:SetAttribute('type', 'spell')
    button:RegisterForClicks('AnyUp', 'AnyDown')
    button.id = index
    button.exuiBarId = barId
    button.commandName = definitions:GetCommandName(barId, index)
    button.UpdateCooldownOnly = function(self)
        local _, _, _, spellID = GetShapeshiftFormInfo(self.id)
        if spellID then
            self.spellID = spellID
            barStyle:ApplySpellCooldownDuration(self.cooldown, spellID)
        end
    end
    button.UpdateAction = function(self)
        if InCombatLockdown() then
            self:UpdateCooldownOnly()
            return
        end
        local texture, isActive, isCastable, spellID = GetShapeshiftFormInfo(self.id)
        if spellID then
            self:SetAttribute('spell', spellID)
        end
        if texture then
            self.icon:SetTexture(texture)
            self.icon:Show()
        else
            self.icon:Hide()
        end
        if isActive then
            self:SetChecked(true)
        else
            self:SetChecked(false)
        end
        self:UpdateCooldownOnly()
    end
    EXUI:SetSize(button, barConfig.width, barConfig.height)
    special:ApplyStyle(button, barId, barConfig)
    return button
end

special.CreatePetButton = function(self, barId, index, header, barConfig)
    local name = 'EXUIActionBar_' .. barId .. '_' .. index
    local button = CreateFrame('CheckButton', name, header, 'SecureActionButtonTemplate, ActionButtonTemplate')
    button:SetAttribute('type', 'petaction')
    button:SetAttribute('action', index)
    button:RegisterForClicks('AnyUp', 'AnyDown')
    button.id = index
    button.exuiBarId = barId
    button.commandName = definitions:GetCommandName(barId, index)
    button.UpdateCooldownOnly = function(self)
        local _, _, _, _, _, _, spellID = GetPetActionInfo(self.id)
        if spellID then
            barStyle:ApplySpellCooldownDuration(self.cooldown, spellID)
        end
    end
    button.UpdateAction = function(self)
        local name, _, icon = GetPetActionInfo(self.id)
        if icon then
            self.icon:SetTexture(icon)
            self.icon:Show()
        else
            self.icon:Hide()
        end
        self:UpdateCooldownOnly()
    end
    EXUI:SetSize(button, barConfig.width, barConfig.height)
    special:ApplyStyle(button, barId, barConfig)
    return button
end

special.CreatePossessButton = function(self, barId, index, header, barConfig)
    local name = 'EXUIActionBar_' .. barId .. '_' .. index
    local button = CreateFrame('CheckButton', name, header, 'SecureActionButtonTemplate, ActionButtonTemplate')
    button:SetAttribute('type', 'spell')
    button:RegisterForClicks('AnyUp', 'AnyDown')
    button.id = index
    button.exuiBarId = barId
    button.commandName = definitions:GetCommandName(barId, index)
    button.UpdateCooldownOnly = function(self)
        local _, spellID = GetPossessInfo(self.id)
        if spellID then
            barStyle:ApplySpellCooldownDuration(self.cooldown, spellID)
        end
    end
    button.UpdateAction = function(self)
        if InCombatLockdown() then
            self:UpdateCooldownOnly()
            return
        end
        local texture, spellID = GetPossessInfo(self.id)
        if spellID then
            self:SetAttribute('spell', spellID)
        end
        if texture then
            self.icon:SetTexture(texture)
            self.icon:Show()
        else
            self.icon:Hide()
        end
        self:UpdateCooldownOnly()
    end
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
    if not barFrame or not barFrame.buttons then return end
    for _, button in ipairs(barFrame.buttons) do
        if button.UpdateCooldownOnly then
            button:UpdateCooldownOnly()
        end
    end
end

special.UpdateAll = function(self, barFrame)
    if not barFrame or not barFrame.buttons then return end
    for _, button in ipairs(barFrame.buttons) do
        if button.UpdateAction then
            button:UpdateAction()
        end
    end
end
