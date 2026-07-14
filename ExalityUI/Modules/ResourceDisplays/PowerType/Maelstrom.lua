---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

local maelstrom = EXUI:GetModule('resource-displays-maelstrom')
local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')
local textElement = EXUI:GetModule('resource-displays-elements-text')
local RDCore = EXUI:GetModule('resource-displays-core')

local MAELSTROM_SPELL_ID = 344179

local function applyMaelstromValues(frame, curr, max)
    frame.StatusBar:SetMinMaxValues(0, max)
    frame.StatusBar:SetValue(curr, helpers:GetInterpolation(frame.db.smoothFill))
    if not helpers:ApplyBarThresholdColor(frame.StatusBar, frame.db, curr, max) then
        if not helpers:ApplyStackBarColor(frame.StatusBar, frame.db, curr, max) then
            statusBarElement:Update(frame)
        end
    end
    textElement:SetPowerText(frame, curr, max)
end

maelstrom.Create = function(self, frame)
    frame.IsActive = function(self) return maelstrom:IsActive(self) end
    frame.StatusBar = statusBarElement:Create(frame)
    frame.Text = textElement:Create(frame)

    frame.OnChange = function(self, event)
        if preview:ApplyBarPreview(self, 'Maelstrom') then
            local current = preview:GetMockValue('Maelstrom')
            local max = preview:GetMockMax('Maelstrom')
            if not helpers:ApplyBarThresholdColor(self.StatusBar, self.db, current, max) then
                if not helpers:ApplyStackBarColor(self.StatusBar, self.db, current, max) then
                    statusBarElement:Update(self)
                end
            end
            return
        end
        if event == 'UNIT_AURA' then
            local curr, max = 0, 1
            local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(MAELSTROM_SPELL_ID)
            if auraInfo then
                curr = auraInfo.applications
            end
            max = C_Spell.GetSpellMaxCumulativeAuraApplications(MAELSTROM_SPELL_ID)
            applyMaelstromValues(self, curr, max)
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

maelstrom.Update = function(frame)
    frame:OnChange('UNIT_AURA')
end

maelstrom.IsActive = function(self, frame)
    local db = frame.db
    if not db.enable then
        return false
    end
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    return specId == 263
end

maelstrom.GetOptions = function(self, displayID)
    local options = {}
    tAppendAll(options, statusBarElement:GetOptions(displayID))
    tAppendAll(options, textElement:GetOptions(displayID))
    tAppendAll(options, {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Maelstrom',
        },
        {
            type = 'color-picker',
            label = 'Cap Highlight Color',
            name = 'capHighlightColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'capHighlightColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'capHighlightColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'color-picker',
            label = 'Stack Threshold Color',
            name = 'stackThresholdColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'stackThresholdColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'stackThresholdColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'range',
            label = 'Stack Threshold',
            name = 'stackThreshold',
            min = 0,
            max = 10,
            step = 1,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'stackThreshold') or 0
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'stackThreshold', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
    })
    return options
end

maelstrom.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        barTexture = 'ExalityUI Status Bar',
        barColor = { r = 0, g = 0.5, b = 1, a = 1 },
        capHighlightColor = { r = 0.2, g = 0.8, b = 1, a = 1 },
        stackThreshold = 0,
        stackThresholdColor = { r = 0.4, g = 0.7, b = 1, a = 1 },
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
    name = 'Maelstrom',
    control = maelstrom,
})
