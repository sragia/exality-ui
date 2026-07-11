---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

local devourerFury = EXUI:GetModule('resource-displays-devourer-fury')
local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')
local textElement = EXUI:GetModule('resource-displays-elements-text')

devourerFury.Create = function(self, frame)
    frame.IsActive = function(self) return devourerFury:IsActive(self) end
    frame.StatusBar = statusBarElement:Create(frame)
    frame.Text = textElement:Create(frame)

    frame.OnChange = function(self, event)
        if preview:ApplyBarPreview(self, 'Devourer Fury') then
            return
        end
        if event == 'UNIT_POWER_FREQUENT' or event == 'TRAIT_CONFIG_UPDATED' then
            local power = UnitPower('player', Enum.PowerType.Fury)
            local maxPower = UnitPowerMax('player', Enum.PowerType.Fury)
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

devourerFury.Update = function(frame)
    frame:OnChange('UNIT_POWER_FREQUENT')
end

devourerFury.IsActive = function(self, frame)
    local db = frame.db
    if not db.enable then
        return false
    end
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    return specId == 1480 and UnitPowerMax('player', Enum.PowerType.Fury) > 0
end

devourerFury.GetOptions = function(self, displayID)
    local options = {}
    tAppendAll(options, statusBarElement:GetOptions(displayID))
    tAppendAll(options, textElement:GetOptions(displayID))
    return options
end

devourerFury.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        barTexture = 'ExalityUI Status Bar',
        barColor = { r = 0.5, g = 0.1, b = 0.8, a = 1 },
        font = 'DMSans',
        fontSize = 12,
        fontFlag = 'OUTLINE',
        textAnchorPoint = 'CENTER',
        textRelativeAnchorPoint = 'CENTER',
        textXOff = 0,
        textYOff = 0,
        textColor = { r = 1, g = 1, b = 1, a = 1 },
        showText = true,
        textFormat = 'current/max',
    })
end

core:RegisterPowerType({
    name = 'Devourer Fury',
    control = devourerFury,
    class = 'DEMONHUNTER',
})
