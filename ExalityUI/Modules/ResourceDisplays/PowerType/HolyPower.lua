---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

local holyPower = EXUI:GetModule('resource-displays-holy-power')

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

holyPower.CreateSinglePower = function(self, parent)
    local frame = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    EXUI:SetSize(frame, 30, 16)

    frame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:SetBackdropColor(0, 0, 0, 0.5)

    local statusBar = CreateFrame('StatusBar', nil, frame)
    EXUI:SetPoint(statusBar, 'TOPLEFT', 1, -1)
    EXUI:SetPoint(statusBar, 'BOTTOMRIGHT', -1, 1)
    statusBar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(0)
    statusBar:SetStatusBarColor(1, 0, 0, 1)

    frame.StatusBar = statusBar

    return frame
end

holyPower.Create = function(self, frame)
    frame.IsActive = function(self) return holyPower:IsActive(self) end

    frame.HolyPowerFrames = {}
    frame.ActiveFrames = {}

    frame:RegisterUnitEvent('UNIT_POWER_UPDATE', 'player')

    frame.OnEvent = function(self, event, unit, powerType)
        if (unit == 'player' and powerType == 'HOLY_POWER') then
            local hpCount = UnitPower('player', Enum.PowerType.HolyPower)
            local i = 0
            for _, powerFrame in ipairs_reverse(frame.ActiveFrames) do
                local value = powerFrame.index <= hpCount and 1 or 0
                local isChanging = powerFrame.StatusBar:GetValue() ~= value
                if (isChanging) then
                    powerFrame.StatusBar:SetValue(value,
                        powerFrame.FillAnimation and Enum.StatusBarInterpolation.ExponentialEaseOut or
                        Enum.StatusBarInterpolation.Immediate)
                end
            end
        end
    end
    frame:SetScript('OnEvent', function(self, event, unit, powerType)
        self:OnEvent(event, unit, powerType)
    end)
end

holyPower.Update = function(frame)
    local maxHolyPower = UnitPowerMax('player', Enum.PowerType.HolyPower)
    local db = frame.db

    for _, holyPowerFrame in pairs(frame.HolyPowerFrames) do
        holyPowerFrame:Hide()
    end

    wipe(frame.ActiveFrames)
    for i = 1, maxHolyPower do
        local powerFrame = frame.HolyPowerFrames[i]
        -- Create frames
        if (not powerFrame) then
            powerFrame = holyPower:CreateSinglePower(frame)
            frame.HolyPowerFrames[i] = powerFrame
        end
        powerFrame.index = i
        table.insert(frame.ActiveFrames, powerFrame)
        powerFrame:Show()
        EXUI:SetSize(powerFrame, db.hpWidth, db.hpHeight)
        powerFrame.StatusBar:SetStatusBarColor(db.hpColor.r, db.hpColor.g, db.hpColor.b, db.hpColor.a)
        powerFrame:SetBackdropColor(db.hpBackgroundColor.r, db.hpBackgroundColor.g, db.hpBackgroundColor.b,
            db.hpBackgroundColor.a)
        powerFrame:SetBackdropBorderColor(db.hpBorderColor.r, db.hpBorderColor.g, db.hpBorderColor.b, db.hpBorderColor.a)
        powerFrame.FillAnimation = db.fillAnimation
    end

    local prev = nil
    for _, activeFrame in ipairs(frame.ActiveFrames) do
        activeFrame:ClearAllPoints()
        if (prev) then
            EXUI:SetPoint(activeFrame, 'LEFT', prev, 'RIGHT', db.hpSpacing, 0)
        else
            EXUI:SetPoint(activeFrame, 'LEFT', frame, 'LEFT', 0, 0)
        end
        prev = activeFrame
    end

    frame:SetSize(db.hpWidth * #frame.ActiveFrames + 2 * #frame.ActiveFrames - 2, db.hpHeight)

    frame:OnEvent('UNIT_POWER_UPDATE', 'player', 'HOLY_POWER') -- Trigger Update
end

holyPower.IsActive = function(self, frame)
    local db = frame.db
    local enabled = db.enable
    return enabled and UnitPowerMax('player', Enum.PowerType.HolyPower) > 0
end

holyPower.GetOptions = function(self, displayID)
    local options = {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Holy Power'
        },
        {
            type = 'range',
            label = 'Width',
            name = 'hpWidth',
            min = 1,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'hpWidth')
            end,
            onChange = function(f, value)
                RDCore:UpdateValueForDisplay(displayID, 'hpWidth', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Height',
            name = 'hpHeight',
            min = 1,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'hpHeight')
            end,
            onChange = function(f, value)
                RDCore:UpdateValueForDisplay(displayID, 'hpHeight', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Spacing',
            name = 'hpSpacing',
            min = -3,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'hpSpacing')
            end,
            onChange = function(f, value)
                RDCore:UpdateValueForDisplay(displayID, 'hpSpacing', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'color-picker',
            label = 'Color',
            name = 'hpColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'hpColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'hpColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'spacer',
            width = 24
        },
        {
            type = 'color-picker',
            label = 'Background Color',
            name = 'hpBackgroundColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'hpBackgroundColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'hpBackgroundColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = 'hpBorderColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'hpBorderColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'hpBorderColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'toggle',
            label = 'Use Fill Animation',
            name = 'fillAnimation',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'fillAnimation')
            end,
            onObserve = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'fillAnimation', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100
        }
    }

    return options
end

holyPower.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        hpWidth = 30,
        hpHeight = 16,
        hpSpacing = 2,
        hpColor = { r = 1, g = 204 / 255, b = 0, a = 1 },
        hpBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        hpBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        fillAnimation = false
    })
end

core:RegisterPowerType({
    name = 'Holy Power',
    control = holyPower,
    selfControlledSize = true
})
