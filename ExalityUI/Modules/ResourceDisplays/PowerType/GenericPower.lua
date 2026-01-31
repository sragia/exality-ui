---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

local genericPower = EXUI:GetModule('resource-displays-generic-power')

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
    frame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:SetBackdropColor(0, 0, 0, 0.5)
    frame.IsActive = function(self) return genericPower:IsActive(self) end
    frame.StatusBar = EXUI:GetModule('resource-displays-elements-status-bar'):Create(frame)
    frame.Text = EXUI:GetModule('resource-displays-elements-text'):Create(frame)

    frame:RegisterUnitEvent('UNIT_POWER_FREQUENT', 'player')
    frame:RegisterEvent('PLAYER_ENTERING_WORLD')
    frame:RegisterEvent('TRAIT_CONFIG_UPDATED')
    frame.OnChange = function(self, event)
        if (self.powerType == '') then
            self.powerType = nil
        end
        if (event == 'UNIT_POWER_FREQUENT' or event == 'TRAIT_CONFIG_UPDATED') then
            local power = UnitPower('player', self.powerType)
            self.StatusBar:SetValue(power, Enum.StatusBarInterpolation.ExponentialEaseOut)
            self.StatusBar:SetMinMaxValues(0, UnitPowerMax('player', self.powerType))
            self.Text:SetText(AbbreviateNumbers(power))
        end

        if (event == 'PLAYER_ENTERING_WORLD') then
            C_Timer.After(0.1, function()
                self:OnChange('UNIT_POWER_FREQUENT') -- fake event with small delay
            end)
        end
    end
    frame:SetScript('OnEvent', frame.OnChange)
    frame:OnChange('UNIT_POWER_FREQUENT')
end

genericPower.Update = function(frame)
    local db = frame.db
    frame.powerType = genericPower.Types[db.resourceType]
    frame.StatusBar:SetMinMaxValues(0, UnitPowerMax('player', frame.powerType))
    frame:OnChange('UNIT_POWER_FREQUENT') -- Fake event to update
end

genericPower.IsActive = function(self, frame)
    local db = frame.db
    local enabled = db.enable
    local powerType = self.Types[db.resourceType]
    if not powerType then
        return false
    end
    local unitPowerType = UnitPowerType('player')
    local isPrimaryResource = unitPowerType == powerType or powerType == Enum.PowerType.ArcaneCharges

    local maxPower = UnitPowerMax('player', powerType)
    return enabled and maxPower > 0 and (isPrimaryResource or db.showOverride)
end

genericPower.GetOptions = function(self, displayID)
    local options = {}

    tAppendAll(options, EXUI:GetModule('resource-displays-elements-status-bar'):GetOptions(displayID))
    tAppendAll(options, EXUI:GetModule('resource-displays-elements-text'):GetOptions(displayID))
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
    })
end

core:RegisterPowerType({
    name = 'Energy',
    control = genericPower
})
core:RegisterPowerType({
    name = 'Mana',
    control = genericPower
})
core:RegisterPowerType({
    name = 'Rage',
    control = genericPower
})
core:RegisterPowerType({
    name = 'Focus',
    control = genericPower
})
core:RegisterPowerType({
    name = 'Runic Power',
    control = genericPower
})
core:RegisterPowerType({
    name = 'Fury',
    control = genericPower
})
core:RegisterPowerType({
    name = 'Insanity',
    control = genericPower
})
core:RegisterPowerType({
    name = 'Astral Power',
    control = genericPower
})
core:RegisterPowerType({
    name = 'Arcane Charges',
    control = genericPower
})
