---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

---@class EXUIResourceDisplaysDefaults
local defaults = EXUI:GetModule('resource-displays-defaults')

local statusBar = EXUI:GetModule('resource-displays-elements-status-bar')

statusBar.ApplyInsets = function(self, statusBarFrame, parent)
    local inset = EXUI:ScalePixels(1, parent)
    statusBarFrame:ClearAllPoints()
    statusBarFrame:SetPoint('TOPLEFT', parent, 'TOPLEFT', inset, -inset)
    statusBarFrame:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', -inset, 0)
end

statusBar.Create = function(self, frame)
    local bar = CreateFrame('StatusBar', nil, frame)
    bar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    self:ApplyInsets(bar, frame)
    frame.TickLines = frame.TickLines or {}
    return bar
end

statusBar.UpdateTickMarks = function(self, frame)
    local db = frame.db
    local bar = frame.StatusBar
    if not bar then
        return
    end

    for _, line in ipairs(frame.TickLines or {}) do
        line:Hide()
    end
    wipe(frame.TickLines)

    if not db.tickMarksEnabled or not db.tickMarks then
        return
    end

    local _, max = bar:GetMinMaxValues()
    for i, threshold in ipairs(db.tickMarks) do
        local value = threshold.value or threshold
        local isPercent = threshold.isPercent
        local position = isPercent and (max * (value / 100)) or value
        if max > 0 and position > 0 and position < max then
            local line = frame.TickLines[i] or bar:CreateTexture(nil, 'OVERLAY')
            frame.TickLines[i] = line
            line:SetColorTexture(1, 1, 1, 0.6)
            line:SetSize(1, bar:GetHeight() or 16)
            local ratio = position / max
            local width = bar:GetWidth() or 100
            line:ClearAllPoints()
            line:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', width * ratio, 0)
            line:Show()
        end
    end
end

statusBar.ApplyBaseColor = function(self, frame)
    local db = frame.db
    local bar = frame.StatusBar
    if not bar or self.NOCOLOR then
        return
    end

    if db.resourceColorCurveEnabled and #helpers:GetResourceColorCurvePoints(db) > 0 then
        return
    end

    if db.useClassColor then
        local _, class = UnitClass('player')
        local color = RAID_CLASS_COLORS[class]
        if color then
            bar:SetStatusBarColor(color.r, color.g, color.b, 1)
        end
    elseif db.barColor then
        bar:SetStatusBarColor(db.barColor.r, db.barColor.g, db.barColor.b, db.barColor.a)
    end
end

statusBar.Update = function(self, frame)
    local db = frame.db
    local bar = frame.StatusBar
    if not bar then
        return
    end

    self:ApplyInsets(bar, frame)

    if db.barTexture then
        bar:SetStatusBarTexture(LSM:Fetch('statusbar', db.barTexture))
    end

    helpers:ApplyReverseFill(bar, db.reverseFill)

    helpers:ClearResourceBarColorCurve(bar)

    self:ApplyBaseColor(frame)

    self:UpdateTickMarks(frame)
end

statusBar.ApplyPowerValue = function(self, frame, current, max)
    local db = frame.db
    local bar = frame.StatusBar
    if not bar then
        return
    end

    max = max or 0
    current = current or 0
    bar:SetMinMaxValues(0, max)
    bar:SetValue(current, helpers:GetInterpolation(db.smoothFill))

    if not self.NOCOLOR then
        if not helpers:ApplyBarThresholdColor(bar, db, current, max, frame.powerType) then
            self:ApplyBaseColor(frame)
        end
    end
end

statusBar.GetOptions = function(self, displayID)
    return {
        {
            type = 'title',
            label = 'Bar Style',
            size = 14,
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'Bar Texture',
            name = 'barTexture',
            getOptions = function()
                local list = LSM:List('statusbar')
                local options = {}
                for _, texture in pairs(list) do
                    options[texture] = texture
                end
                return options
            end,
            isTextureDropdown = true,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'barTexture')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'barTexture', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 40,
        },
        {
            type = 'toggle',
            label = 'Use Class Color',
            name = 'useClassColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'useClassColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'useClassColor', value)
                RDCore:RefreshDisplayByID(displayID)
                optionsFields:RefreshOptionsDelayed()
            end,
            width = 100,
        },
        {
            type = 'color-picker',
            label = 'Bar Color',
            name = 'barColor',
            depends = function()
                return not RDCore:GetValueForDisplay(displayID, 'useClassColor')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'barColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'barColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16,
        },
        {
            type = 'toggle',
            label = 'Resource Color Curve',
            name = 'resourceColorCurveEnabled',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'resourceColorCurveEnabled')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'resourceColorCurveEnabled', value)
                if value then
                    local display = RDCore:GetDBByDisplayID(displayID)
                    local curve = defaults:EnsureResourceColorCurve(display and display.resourceColorCurve, display)
                    RDCore:UpdateValueForDisplay(displayID, 'resourceColorCurve', curve)
                end
                RDCore:RefreshDisplayByID(displayID)
                optionsFields:RefreshOptionsDelayed()
            end,
            width = 100,
        },
        {
            type = 'resource-color-curve',
            name = 'resourceColorCurve',
            width = 100,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'resourceColorCurveEnabled')
            end,
            currentValue = function()
                local display = RDCore:GetDBByDisplayID(displayID)
                return defaults:EnsureResourceColorCurve(display and display.resourceColorCurve, display)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'resourceColorCurve', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
        },
        {
            type = 'toggle',
            label = 'Reverse Fill',
            name = 'reverseFill',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'reverseFill')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'reverseFill', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Smooth Fill',
            name = 'smoothFill',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'smoothFill') ~= false
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'smoothFill', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
    }
end
