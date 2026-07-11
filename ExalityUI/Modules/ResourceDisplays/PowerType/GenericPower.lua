---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

local genericPower = EXUI:GetModule('resource-displays-generic-power')
local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')
local textElement = EXUI:GetModule('resource-displays-elements-text')

genericPower.Types = {
    ['Energy'] = Enum.PowerType.Energy,
    ['Mana'] = Enum.PowerType.Mana,
    ['Rage'] = Enum.PowerType.Rage,
    ['Focus'] = Enum.PowerType.Focus,
    ['Runic Power'] = Enum.PowerType.RunicPower,
    ['Fury'] = Enum.PowerType.Fury,
    ['Insanity'] = Enum.PowerType.Insanity,
    ['Astral Power'] = Enum.PowerType.LunarPower,
    ['Arcane Charges'] = Enum.PowerType.ArcaneCharges,
}

genericPower.Create = function(self, frame)
    frame.IsActive = function(self) return genericPower:IsActive(self) end
    frame.StatusBar = statusBarElement:Create(frame)
    frame.Text = textElement:Create(frame)

    frame.OnChange = function(self, event)
        if preview:ApplyBarPreview(self, self.db.resourceType) then
            return
        end
        if self.powerType == '' then
            self.powerType = nil
        end
        if event == 'UNIT_POWER_FREQUENT' or event == 'TRAIT_CONFIG_UPDATED' or event == 'UNIT_DISPLAYPOWER' then
            local power = UnitPower('player', self.powerType)
            local maxPower = UnitPowerMax('player', self.powerType)
            statusBarElement:ApplyPowerValue(self, power, maxPower)
            textElement:SetPowerText(self, power, maxPower)
        end
        if event == 'PLAYER_ENTERING_WORLD' then
            C_Timer.After(0.1, function()
                if self.OnChange then
                    self:OnChange('UNIT_POWER_FREQUENT')
                end
            end)
        end
    end

    frame.Enable = function(self)
        self:RegisterUnitEvent('UNIT_POWER_FREQUENT', 'player')
        self:RegisterUnitEvent('UNIT_DISPLAYPOWER', 'player')
        self:RegisterEvent('PLAYER_ENTERING_WORLD')
        self:RegisterEvent('TRAIT_CONFIG_UPDATED')
        self:SetScript('OnEvent', self.OnChange)
        self:OnChange('UNIT_POWER_FREQUENT')
    end

    frame.Disable = function(self)
        self:UnregisterAllEvents()
        self:SetScript('OnEvent', nil)
    end
end

genericPower.Update = function(frame)
    local db = frame.db
    frame.powerType = genericPower.Types[db.resourceType]
    if preview:ApplyBarPreview(frame, db.resourceType) then
        return
    end
    local maxPower = UnitPowerMax('player', frame.powerType)
    statusBarElement:ApplyPowerValue(frame, UnitPower('player', frame.powerType), maxPower)
    textElement:SetPowerText(frame, UnitPower('player', frame.powerType), maxPower)
end

genericPower.IsActive = function(self, frame)
    local db = frame.db
    if not db.enable then
        return false
    end
    local powerType = self.Types[db.resourceType]
    if not powerType then
        return false
    end
    local unitPowerType = UnitPowerType('player')
    local isPrimaryResource = unitPowerType == powerType or powerType == Enum.PowerType.ArcaneCharges
    local maxPower = UnitPowerMax('player', powerType)
    return maxPower > 0 and (isPrimaryResource or db.showOverride)
end

genericPower.GetOptions = function(self, displayID)
    local options = {}
    tAppendAll(options, statusBarElement:GetOptions(displayID))
    tAppendAll(options, textElement:GetOptions(displayID))
    return options
end

genericPower.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        barTexture = 'ExalityUI Status Bar',
        barColor = { r = 0, g = 0.5, b = 1, a = 1 },
        font = 'DMSans',
        fontSize = 12,
        fontFlag = 'OUTLINE',
        textAnchorPoint = 'CENTER',
        textRelativeAnchorPoint = 'CENTER',
        textXOff = 0,
        textYOff = 0,
        textColor = { r = 1, g = 1, b = 1, a = 1 },
        showText = true,
        textFormat = 'current',
        textJustify = 'CENTER',
        smoothFill = true,
    })
end

local genericTypes = {
    'Energy', 'Mana', 'Rage', 'Focus', 'Runic Power', 'Fury', 'Insanity', 'Astral Power', 'Arcane Charges',
}
for _, name in ipairs(genericTypes) do
    core:RegisterPowerType({ name = name, control = genericPower, class = 'ANY' })
end
