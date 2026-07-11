---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

local stagger = EXUI:GetModule('resource-displays-stagger')
local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')
local textElement = EXUI:GetModule('resource-displays-elements-text')
local RDCore = EXUI:GetModule('resource-displays-core')

stagger.Create = function(self, frame)
    frame.IsActive = function(self) return stagger:IsActive(self) end
    frame.StatusBar = statusBarElement:Create(frame)
    frame.StatusBar.NOCOLOR = true
    frame.Text = textElement:Create(frame)

    frame.OnChange = function(self, event)
        if preview:ApplyBarPreview(self, 'Stagger') then
            return
        end
        if event == 'UNIT_ABSORB_AMOUNT_CHANGED' or event == 'PLAYER_DEAD' then
            local amount = UnitStagger('player')
            local maxHealth = UnitHealthMax('player')
            local lightThreshold = (self.db.staggerLightThreshold or 30) / 100
            local heavyThreshold = (self.db.staggerHeavyThreshold or 60) / 100
            local perc = maxHealth > 0 and amount / maxHealth or 0

            if self.db.staggerShowPercent then
                self.StatusBar:SetMinMaxValues(0, 100)
                self.StatusBar:SetValue(perc * 100, helpers:GetInterpolation(self.db.smoothFill))
            else
                self.StatusBar:SetMinMaxValues(0, maxHealth)
                self.StatusBar:SetValue(amount, helpers:GetInterpolation(self.db.smoothFill))
            end

            if amount == 0 and self.db.hideWhenZero then
                self:SetAlpha(0)
            else
                self:SetAlpha(1)
            end

            if perc < lightThreshold then
                self.StatusBar:SetStatusBarColor(self.db.lightStaggerColor.r, self.db.lightStaggerColor.g, self.db.lightStaggerColor.b, self.db.lightStaggerColor.a)
            elseif perc < heavyThreshold then
                self.StatusBar:SetStatusBarColor(self.db.moderateStaggerColor.r, self.db.moderateStaggerColor.g, self.db.moderateStaggerColor.b, self.db.moderateStaggerColor.a)
            else
                self.StatusBar:SetStatusBarColor(self.db.heavyStaggerColor.r, self.db.heavyStaggerColor.g, self.db.heavyStaggerColor.b, self.db.heavyStaggerColor.a)
            end

            if self.db.showText then
                if self.db.staggerShowPercent then
                    textElement:SetPowerText(self, perc * 100, 100)
                else
                    textElement:SetPowerText(self, amount, maxHealth)
                end
            end
        end
    end

    frame.Enable = function(self)
        self:RegisterUnitEvent('UNIT_ABSORB_AMOUNT_CHANGED', 'player')
        self:RegisterEvent('PLAYER_DEAD')
        self:SetScript('OnEvent', self.OnChange)
        self:OnChange('UNIT_ABSORB_AMOUNT_CHANGED')
    end

    frame.Disable = function(self)
        self:UnregisterAllEvents()
        self:SetScript('OnEvent', nil)
    end
end

stagger.Update = function(frame)
    frame:OnChange('UNIT_ABSORB_AMOUNT_CHANGED')
end

stagger.IsActive = function(self, frame)
    local db = frame.db
    if not db.enable then
        return false
    end
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    return specId == 268
end

stagger.GetOptions = function(self, displayID)
    local options = {}
    tAppendAll(options, statusBarElement:GetOptions(displayID))
    tAppendAll(options, textElement:GetOptions(displayID))
    tAppendAll(options, {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Stagger',
        },
        {
            type = 'toggle',
            label = 'Hide When No Stagger',
            name = 'hideWhenZero',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'hideWhenZero')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'hideWhenZero', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Show As Percent',
            name = 'staggerShowPercent',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'staggerShowPercent')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'staggerShowPercent', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
        {
            type = 'range',
            label = 'Light Threshold %',
            name = 'staggerLightThreshold',
            min = 1,
            max = 99,
            step = 1,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'staggerLightThreshold') or 30
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'staggerLightThreshold', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'range',
            label = 'Heavy Threshold %',
            name = 'staggerHeavyThreshold',
            min = 1,
            max = 99,
            step = 1,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'staggerHeavyThreshold') or 60
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'staggerHeavyThreshold', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'color-picker',
            label = 'Light Stagger',
            name = 'lightStaggerColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'lightStaggerColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'lightStaggerColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16,
        },
        {
            type = 'color-picker',
            label = 'Moderate Stagger',
            name = 'moderateStaggerColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'moderateStaggerColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'moderateStaggerColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16,
        },
        {
            type = 'color-picker',
            label = 'Heavy Stagger',
            name = 'heavyStaggerColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'heavyStaggerColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'heavyStaggerColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16,
        },
    })
    return options
end

stagger.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        barTexture = 'ExalityUI Status Bar',
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
        hideWhenZero = true,
        staggerShowPercent = false,
        staggerLightThreshold = 30,
        staggerHeavyThreshold = 60,
        lightStaggerColor = { r = 0, g = 155 / 255, b = 22 / 255, a = 1 },
        moderateStaggerColor = { r = 204 / 255, g = 153 / 255, b = 0, a = 1 },
        heavyStaggerColor = { r = 186 / 255, g = 0, b = 28 / 255, a = 1 },
    })
end

core:RegisterPowerType({
    name = 'Stagger',
    control = stagger,
    class = 'MONK',
})
