---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

local totem = EXUI:GetModule('resource-displays-totem')
local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')
local textElement = EXUI:GetModule('resource-displays-elements-text')
local RDCore = EXUI:GetModule('resource-displays-core')

local DEFAULT_TOTEM_SLOT = 1

local ZERO_DURATION
if C_DurationUtil and C_DurationUtil.CreateDuration then
    ZERO_DURATION = C_DurationUtil.CreateDuration()
    ZERO_DURATION:SetTimeSpan(0, 0)
end

local function getConfiguredSlot(db)
    return tonumber(db and db.totemSlot) or DEFAULT_TOTEM_SLOT
end

local function getSlotCount()
    if GetNumTotemSlots then
        return GetNumTotemSlots() or MAX_TOTEMS or 4
    end
    return MAX_TOTEMS or 4
end

local function getTotemDuration(slot)
    local duration = GetTotemDuration and GetTotemDuration(slot)
    if duration == nil then
        return ZERO_DURATION
    end
    return duration
end

local function configureTextBinding(frame)
    local binding = frame.DurationTextBinding
    if not binding then
        return
    end

    binding:SetFontString(frame.Text)
    binding:SetExpiredText('')
    binding:SetZeroDurationText('')

    local formatter = durationFormat and durationFormat.GetFormatter and durationFormat:GetFormatter('mmss')
    local showCurrentMax = frame.db.textFormat == 'current/max'
    if showCurrentMax and formatter and Enum and Enum.DurationTextBindingProperty and binding.SetTextFormat then
        binding:SetTextFormat('{}/{}', {
            { property = Enum.DurationTextBindingProperty.RemainingDuration, formatter = formatter },
            { property = Enum.DurationTextBindingProperty.TotalDuration, formatter = formatter },
        })
    elseif formatter and binding.SetFormatter then
        binding:SetFormatter(formatter)
    end

    if binding.SetUpdateInterval then
        binding:SetUpdateInterval(0.05)
    end
    binding:SetEnabled(frame.db.showText == true)
end

local function applyVisibility(frame, haveTotem)
    if preview:ShouldUsePreview(frame) or frame.db.hideWhenZero == false then
        frame:SetAlpha(1)
        return
    end
    if haveTotem == nil then
        frame:SetAlpha(0)
        return
    end
    if frame.SetAlphaFromBoolean then
        frame:SetAlphaFromBoolean(haveTotem, 1, 0)
    end
end

local function applyTotemSlot(frame, slot)
    local bar = frame.StatusBar
    if not bar then
        return
    end

    local haveTotem = GetTotemInfo(slot)
    local duration = getTotemDuration(slot)
    frame.DurationObject = duration
    frame.TotemSlot = slot

    bar:SetMinMaxValues(0, 1)
    if bar.SetTimerDuration and duration and Enum and Enum.StatusBarTimerDirection then
        local interpolation = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate
        bar:SetTimerDuration(duration, interpolation, Enum.StatusBarTimerDirection.RemainingTime)
    end

    if not helpers:ApplyDurationBarColor(bar, frame.db, duration) then
        statusBarElement:Update(frame)
    end

    if frame.DurationTextBinding then
        frame.DurationTextBinding:SetDuration(duration or ZERO_DURATION)
        configureTextBinding(frame)
    end

    applyVisibility(frame, haveTotem)
end

totem.Create = function(self, frame)
    frame.IsActive = function(self) return totem:IsActive(self) end
    frame.StatusBar = statusBarElement:Create(frame)
    frame.Text = textElement:Create(frame)

    if C_DurationUtil and C_DurationUtil.CreateDurationTextBinding then
        frame.DurationTextBinding = C_DurationUtil.CreateDurationTextBinding()
        frame.DurationTextBinding:SetFontString(frame.Text)
        frame.DurationTextBinding:SetExpiredText('')
        frame.DurationTextBinding:SetZeroDurationText('')
        frame.DurationTextBinding:SetDuration(ZERO_DURATION)
        frame.DurationTextBinding:SetEnabled(false)
    end

    frame.OnChange = function(self, event, updatedSlot)
        if preview:ShouldUsePreview(self) then
            self:SetScript('OnUpdate', nil)
            self:SetAlpha(1)
            if self.DurationTextBinding then
                self.DurationTextBinding:SetEnabled(false)
            end
            local current = preview:GetMockValue('Totem')
            local max = preview:GetMockMax('Totem')
            statusBarElement:ApplyPowerValue(self, current, max)
            textElement:SetPowerText(self, current, max)
            return
        end

        if event ~= 'PLAYER_TOTEM_UPDATE' and event ~= 'PLAYER_ENTERING_WORLD' then
            return
        end

        local slot = getConfiguredSlot(self.db)
        if event == 'PLAYER_TOTEM_UPDATE' and updatedSlot ~= nil and updatedSlot ~= slot then
            return
        end

        applyTotemSlot(self, slot)

        self:SetScript('OnUpdate', function(selfRef)
            local activeSlot = getConfiguredSlot(selfRef.db)
            local haveTotem = GetTotemInfo(activeSlot)
            applyVisibility(selfRef, haveTotem)
            helpers:ApplyDurationBarColor(selfRef.StatusBar, selfRef.db, selfRef.DurationObject)
        end)
    end

    frame.Enable = function(self)
        self:RegisterEvent('PLAYER_TOTEM_UPDATE')
        self:RegisterEvent('PLAYER_ENTERING_WORLD')
        self:SetScript('OnEvent', self.OnChange)
        self:OnChange('PLAYER_TOTEM_UPDATE')
    end

    frame.Disable = function(self)
        self:UnregisterAllEvents()
        self:SetScript('OnEvent', nil)
        self:SetScript('OnUpdate', nil)
        if self.DurationTextBinding then
            self.DurationTextBinding:SetEnabled(false)
        end
    end
end

totem.Update = function(frame)
    frame:OnChange('PLAYER_TOTEM_UPDATE')
end

totem.IsActive = function(self, frame)
    local db = frame.db
    return db and db.enable
end

totem.GetOptions = function(self, displayID)
    local options = {}
    tAppendAll(options, statusBarElement:GetOptions(displayID))
    tAppendAll(options, textElement:GetOptions(displayID))
    tAppendAll(options, {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Totem',
        },
        {
            type = 'dropdown',
            label = 'Totem Slot',
            name = 'totemSlot',
            getOptions = function()
                local slots = {
                    ['1'] = '1 (Fire / Consecration)',
                    ['2'] = '2 (Earth)',
                    ['3'] = '3 (Water)',
                    ['4'] = '4 (Air)',
                }
                local count = getSlotCount()
                if count >= 5 then
                    slots['5'] = '5'
                end
                return slots
            end,
            currentValue = function()
                return tostring(RDCore:GetValueForDisplay(displayID, 'totemSlot') or DEFAULT_TOTEM_SLOT)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'totemSlot', tonumber(value) or DEFAULT_TOTEM_SLOT)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 50,
        },
        {
            type = 'toggle',
            label = 'Hide When Inactive',
            name = 'hideWhenZero',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'hideWhenZero') ~= false
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'hideWhenZero', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
    })
    return options
end

totem.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        barTexture = 'ExalityUI Status Bar',
        barColor = { r = 0.95, g = 0.78, b = 0.25, a = 1 },
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
        textJustify = 'CENTER',
        smoothFill = false,
        hideWhenZero = true,
        totemSlot = DEFAULT_TOTEM_SLOT,
    })
end

core:RegisterPowerType({
    name = 'Totem',
    control = totem,
})
