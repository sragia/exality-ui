---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

local balanceEclipse = EXUI:GetModule('resource-displays-balance-eclipse')
local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')
local textElement = EXUI:GetModule('resource-displays-elements-text')

balanceEclipse.Create = function(self, frame)
    frame.IsActive = function(self) return balanceEclipse:IsActive(self) end
    frame.StatusBar = statusBarElement:Create(frame)
    frame.StatusBar.NOCOLOR = true
    frame.Text = textElement:Create(frame)

    frame.OnChange = function(self, event)
        if preview:ApplyBarPreview(self, 'Balance Eclipse') then
            return
        end
        if event == 'UNIT_POWER_FREQUENT' or event == 'UNIT_MAXPOWER' or event == 'TRAIT_CONFIG_UPDATED' then
            local power = UnitPower('player', Enum.PowerType.Balance)
            local maxPower = UnitPowerMax('player', Enum.PowerType.Balance)
            self.StatusBar:SetMinMaxValues(0, maxPower)
            self.StatusBar:SetValue(power)
            if power < 0 then
                self.StatusBar:SetStatusBarColor(self.db.eclipseLunarColor.r, self.db.eclipseLunarColor.g, self.db.eclipseLunarColor.b, self.db.eclipseLunarColor.a)
            elseif power > 0 then
                self.StatusBar:SetStatusBarColor(self.db.eclipseSolarColor.r, self.db.eclipseSolarColor.g, self.db.eclipseSolarColor.b, self.db.eclipseSolarColor.a)
            else
                self.StatusBar:SetStatusBarColor(self.db.eclipseNeutralColor.r, self.db.eclipseNeutralColor.g, self.db.eclipseNeutralColor.b, self.db.eclipseNeutralColor.a)
            end
            textElement:SetPowerText(self, math.abs(power), maxPower)
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
        self:RegisterUnitEvent('UNIT_MAXPOWER', 'player')
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

balanceEclipse.Update = function(frame)
    frame:OnChange('UNIT_POWER_FREQUENT')
end

balanceEclipse.IsActive = function(self, frame)
    local db = frame.db
    if not db.enable then
        return false
    end
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    return specId == 102 and UnitPowerMax('player', Enum.PowerType.Balance) > 0
end

balanceEclipse.GetOptions = function(self, displayID)
    local RDCore = EXUI:GetModule('resource-displays-core')
    local options = {}
    tAppendAll(options, textElement:GetOptions(displayID))
    tAppendAll(options, {
        {
            type = 'title',
            label = 'Eclipse Colors',
            size = 14,
            width = 100,
        },
        {
            type = 'color-picker',
            label = 'Lunar',
            name = 'eclipseLunarColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'eclipseLunarColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'eclipseLunarColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16,
        },
        {
            type = 'color-picker',
            label = 'Solar',
            name = 'eclipseSolarColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'eclipseSolarColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'eclipseSolarColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16,
        },
        {
            type = 'color-picker',
            label = 'Neutral',
            name = 'eclipseNeutralColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'eclipseNeutralColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'eclipseNeutralColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16,
        },
    })
    return options
end

balanceEclipse.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        eclipseLunarColor = { r = 0.2, g = 0.4, b = 1, a = 1 },
        eclipseSolarColor = { r = 1, g = 0.6, b = 0.1, a = 1 },
        eclipseNeutralColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
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
    })
end

core:RegisterPowerType({
    name = 'Balance Eclipse',
    control = balanceEclipse,
    class = 'DRUID',
})
