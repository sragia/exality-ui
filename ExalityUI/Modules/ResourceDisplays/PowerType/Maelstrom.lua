---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

local maelstrom = EXUI:GetModule('resource-displays-maelstrom')

maelstrom.Create = function(self, frame)
    frame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:SetBackdropColor(0, 0, 0, 0.5)
    frame.IsActive = function(self) return maelstrom:IsActive(self) end
    frame.StatusBar = EXUI:GetModule('resource-displays-elements-status-bar'):Create(frame)
    frame.Text = EXUI:GetModule('resource-displays-elements-text'):Create(frame)

    frame.OnChange = function(self, event)
        if (event == 'UNIT_AURA') then
            local curr, max = 0, 1
            local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(344179)
            if (auraInfo) then
                curr = auraInfo.applications
            end
            max = C_Spell.GetSpellMaxCumulativeAuraApplications(344179)

            self.StatusBar:SetValue(curr, Enum.StatusBarInterpolation.ExponentialEaseOut)
            self.StatusBar:SetMinMaxValues(0, max)
            self.Text:SetText(AbbreviateNumbers(curr))
        end

        if (event == 'PLAYER_ENTERING_WORLD') then
            C_Timer.After(0.1, function()
                self:OnChange('UNIT_AURA') -- fake event with small delay
            end)
        end
    end
    frame:SetScript('OnEvent', frame.OnChange)
    frame:OnChange('UNIT_AURA')

    frame.Disable = function(self)
        self:UnregisterAllEvents()
    end

    frame.Enable = function(self)
        self:RegisterUnitEvent('UNIT_AURA', 'player')
        self:RegisterEvent('PLAYER_ENTERING_WORLD')
    end
end

maelstrom.Update = function(frame)
    frame.StatusBar:SetMinMaxValues(0, 1)
    frame:OnChange('UNIT_AURA') -- Fake event to update
end

maelstrom.IsActive = function(self, frame)
    local db = frame.db
    local enabled = db.enable

    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    local isDDH = specId == 263

    return enabled and isDDH
end

maelstrom.GetOptions = function(self, displayID)
    local options = {}

    tAppendAll(options, EXUI:GetModule('resource-displays-elements-status-bar'):GetOptions(displayID))
    tAppendAll(options, EXUI:GetModule('resource-displays-elements-text'):GetOptions(displayID))
    return options
end

maelstrom.UpdateDefault = function(self, displayID)
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
    name = 'Maelstrom',
    control = maelstrom
})
