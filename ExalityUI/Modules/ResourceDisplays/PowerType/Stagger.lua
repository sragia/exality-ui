---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

local stagger = EXUI:GetModule('resource-displays-stagger')

stagger.Create = function(self, frame)
    frame.IsActive = function(self) return stagger:IsActive(self) end
    frame.StatusBar = EXUI:GetModule('resource-displays-elements-status-bar'):Create(frame)
    frame.Text = EXUI:GetModule('resource-displays-elements-text'):Create(frame)

    frame:RegisterUnitEvent('UNIT_ABSORB_AMOUNT_CHANGED', 'player')
    frame:RegisterEvent('PLAYER_DEAD')
    frame.OnChange = function(self, event)
        if (event == 'UNIT_ABSORB_AMOUNT_CHANGED' or event == 'PLAYER_DEAD') then
            local stagger = UnitStagger('player')
            self.StatusBar:SetMinMaxValues(0, UnitHealthMax('player'))
            self.StatusBar:SetValue(stagger)
            self.Text:SetText(AbbreviateNumbers(stagger))
        end
    end
    frame.Text:SetText('0')
    frame:SetScript('OnEvent', frame.OnChange)
end

stagger.Update = function(frame)
    local db = frame.db
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
    })
end

core:RegisterPowerType({
    name = 'Stagger',
    control = stagger
})
