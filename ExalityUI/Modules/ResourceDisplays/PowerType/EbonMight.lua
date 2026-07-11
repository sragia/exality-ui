---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

local ebonMight = EXUI:GetModule('resource-displays-ebon-might')
local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')
local textElement = EXUI:GetModule('resource-displays-elements-text')

local EBON_SPELL_ID = 395152

ebonMight.Create = function(self, frame)
    frame.IsActive = function(self) return ebonMight:IsActive(self) end
    frame.StatusBar = statusBarElement:Create(frame)
    frame.Text = textElement:Create(frame)

    frame.OnChange = function(self, event)
        if preview:ApplyBarPreview(self, 'Ebon Might') then
            return
        end
        if event == 'UNIT_AURA' then
            local curr, max = 0, 100
            local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(EBON_SPELL_ID)
            if auraInfo then
                curr = auraInfo.applications or 0
                max = auraInfo.maxCharges or 100
            end
            statusBarElement:ApplyPowerValue(self, curr, max)
            textElement:SetPowerText(self, curr, max)
        end
        if event == 'PLAYER_ENTERING_WORLD' then
            C_Timer.After(0.1, function()
                if self.OnChange then
                    self:OnChange('UNIT_AURA')
                end
            end)
        end
    end

    frame.Enable = function(self)
        self:RegisterUnitEvent('UNIT_AURA', 'player')
        self:RegisterEvent('PLAYER_ENTERING_WORLD')
        self:SetScript('OnEvent', self.OnChange)
        self:OnChange('UNIT_AURA')
    end

    frame.Disable = function(self)
        self:UnregisterAllEvents()
        self:SetScript('OnEvent', nil)
    end
end

ebonMight.Update = function(frame)
    frame:OnChange('UNIT_AURA')
end

ebonMight.IsActive = function(self, frame)
    local db = frame.db
    if not db.enable then
        return false
    end
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    return specId == 1473
end

ebonMight.GetOptions = function(self, displayID)
    local options = {}
    tAppendAll(options, statusBarElement:GetOptions(displayID))
    tAppendAll(options, textElement:GetOptions(displayID))
    return options
end

ebonMight.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        barTexture = 'ExalityUI Status Bar',
        barColor = { r = 0.2, g = 0.8, b = 0.4, a = 1 },
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
    name = 'Ebon Might',
    control = ebonMight,
    class = 'EVOKER',
})
