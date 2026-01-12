---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

local stagger = EXUI:GetModule('resource-displays-stagger')

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

stagger.Create = function(self, frame)
    frame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:SetBackdropColor(0, 0, 0, 0.5)
    frame.IsActive = function(self) return stagger:IsActive(self) end
    frame.StatusBar = EXUI:GetModule('resource-displays-elements-status-bar'):Create(frame)
    frame.StatusBar.NOCOLOR = true
    frame.Text = EXUI:GetModule('resource-displays-elements-text'):Create(frame)

    frame:RegisterUnitEvent('UNIT_ABSORB_AMOUNT_CHANGED', 'player')
    frame:RegisterEvent('PLAYER_DEAD')
    frame.OnChange = function(self, event)
        if (event == 'UNIT_ABSORB_AMOUNT_CHANGED' or event == 'PLAYER_DEAD') then
            local stagger = UnitStagger('player')
            self.StatusBar:SetMinMaxValues(0, UnitHealthMax('player'))
            self.StatusBar:SetValue(stagger, Enum.StatusBarInterpolation.ExponentialEaseOut)
            self.Text:SetText(AbbreviateNumbers(stagger))

            if (stagger == 0 and self.db.hideWhenZero) then
                self:SetAlpha(0)
            else
                self:SetAlpha(1)
            end
            local perc = stagger / UnitHealthMax('player')
            if (perc < 0.3) then
                self.StatusBar:SetStatusBarColor(self.db.lightStaggerColor.r, self.db.lightStaggerColor.g,
                    self.db.lightStaggerColor.b, self.db.lightStaggerColor.a)
            elseif (perc < 0.6) then
                self.StatusBar:SetStatusBarColor(self.db.moderateStaggerColor.r, self.db.moderateStaggerColor.g,
                    self.db.moderateStaggerColor.b, self.db.moderateStaggerColor.a)
            else
                self.StatusBar:SetStatusBarColor(self.db.heavyStaggerColor.r, self.db.heavyStaggerColor.g,
                    self.db.heavyStaggerColor.b, self.db.heavyStaggerColor.a)
            end
        end
    end
    frame.Text:SetText('0')
    frame:SetScript('OnEvent', frame.OnChange)
end

stagger.Update = function(frame)
    frame.StatusBar:SetMinMaxValues(0, 100)
    frame:OnChange('UNIT_ABSORB_AMOUNT_CHANGED') -- Fake event to update
end

stagger.IsActive = function(self, frame)
    local db = frame.db
    local enabled = db.enable
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)

    -- Only show for Brewmaster
    if (specId == 268) then -- Brewmaster
        return enabled
    end

    return false
end

stagger.GetOptions = function(self, displayID)
    local options = {}

    tAppendAll(options, EXUI:GetModule('resource-displays-elements-status-bar'):GetOptions(displayID))
    tAppendAll(options, EXUI:GetModule('resource-displays-elements-text'):GetOptions(displayID))
    tAppendAll(options, {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Stagger'
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
            width = 16
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
            width = 16
        },


    })
    return options
end

stagger.UpdateDefault = function(self, displayID)
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
        hideWhenZero = true,
        lightStaggerColor = { r = 0, g = 155 / 255, b = 22 / 255, a = 1 },
        moderateStaggerColor = { r = 204 / 255, g = 153 / 255, b = 0, a = 1 },
        heavyStaggerColor = { r = 186 / 255, g = 0, b = 28 / 255, a = 1 },
    })
end

core:RegisterPowerType({
    name = 'Stagger',
    control = stagger
})
