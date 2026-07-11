---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

local soulFragments = EXUI:GetModule('resource-displays-soul-fragments')
local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')
local textElement = EXUI:GetModule('resource-displays-elements-text')
local RDCore = EXUI:GetModule('resource-displays-core')

local META_SPELL_ID = 1217607
local META_FRAGMENT_SPELL_ID = 1227702
local NORMAL_FRAGMENT_SPELL_ID = 1225789

local function getSoulFragmentValues()
    local inMeta = C_UnitAuras.GetPlayerAuraBySpellID(META_SPELL_ID)
    local curr, max = 0, 1
    if inMeta then
        local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(META_FRAGMENT_SPELL_ID)
        if auraInfo then
            max = GetCollapsingStarCost()
            curr = auraInfo.applications
        end
    else
        local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(NORMAL_FRAGMENT_SPELL_ID)
        if auraInfo then
            curr = auraInfo.applications
            max = C_Spell.GetSpellMaxCumulativeAuraApplications(NORMAL_FRAGMENT_SPELL_ID)
        end
    end
    return curr, max
end

local function applySoulFragmentValues(frame, curr, max)
    frame.StatusBar:SetMinMaxValues(0, max)
    frame.StatusBar:SetValue(curr, helpers:GetInterpolation(frame.db.smoothFill))
    if not helpers:ApplyBarThresholdColor(frame.StatusBar, frame.db, curr, max) then
        if not helpers:ApplyStackBarColor(frame.StatusBar, frame.db, curr, max) then
            statusBarElement:Update(frame)
        end
    end
    textElement:SetPowerText(frame, curr, max)
end

soulFragments.Create = function(self, frame)
    frame.IsActive = function(self) return soulFragments:IsActive(self) end
    frame.StatusBar = statusBarElement:Create(frame)
    frame.Text = textElement:Create(frame)

    frame.OnChange = function(self, event)
        if preview:ApplyBarPreview(self, 'Soul Fragments') then
            local current = preview:GetMockValue('Soul Fragments')
            local max = preview:GetMockMax('Soul Fragments')
            if not helpers:ApplyBarThresholdColor(self.StatusBar, self.db, current, max) then
                if not helpers:ApplyStackBarColor(self.StatusBar, self.db, current, max) then
                    statusBarElement:Update(self)
                end
            end
            return
        end
        if event == 'UNIT_AURA' then
            local curr, max = getSoulFragmentValues()
            applySoulFragmentValues(self, curr, max)
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

soulFragments.Update = function(frame)
    frame:OnChange('UNIT_AURA')
end

soulFragments.IsActive = function(self, frame)
    local db = frame.db
    if not db.enable then
        return false
    end
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    return specId == 1480
end

soulFragments.GetOptions = function(self, displayID)
    local options = {}
    tAppendAll(options, statusBarElement:GetOptions(displayID))
    tAppendAll(options, textElement:GetOptions(displayID))
    tAppendAll(options, {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Soul Fragments',
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
            width = 16,
        },
        {
            type = 'range',
            label = 'Stack Threshold',
            name = 'stackThreshold',
            min = 0,
            max = 50,
            step = 1,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'stackThreshold') or 0
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'stackThreshold', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 20,
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
            width = 16,
        },
    })
    return options
end

soulFragments.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        barTexture = 'ExalityUI Status Bar',
        barColor = { r = 0, g = 0.5, b = 1, a = 1 },
        capHighlightColor = { r = 0.6, g = 0.2, b = 1, a = 1 },
        stackThreshold = 0,
        stackThresholdColor = { r = 0.4, g = 0.2, b = 0.8, a = 1 },
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
    name = 'Soul Fragments (Devourer)',
    control = soulFragments,
})
