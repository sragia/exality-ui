---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

local comboPoints = EXUI:GetModule('resource-displays-combo-points')

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)
local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')

comboPoints.CreateSinglePower = function(self, parent)
    local frame = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    EXUI:SetSize(frame, 30, 16)

    local statusBar = CreateFrame('StatusBar', nil, frame)
    statusBarElement:ApplyInsets(statusBar, frame)
    statusBar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(0)
    statusBar:SetStatusBarColor(1, 0, 0, 1)

    frame.StatusBar = statusBar

    return frame
end

comboPoints.Create = function(self, frame)
    frame.IsActive = function(self) return comboPoints:IsActive(self) end

    frame.ComboPointsFrames = {}
    frame.ActiveFrames = {}

    frame:RegisterUnitEvent('UNIT_POWER_UPDATE', 'player')
    frame:RegisterEvent('TRAIT_CONFIG_UPDATED')
    frame:RegisterEvent('PLAYER_ENTERING_WORLD')

    frame.OnEvent = function(self, event, unit, powerType)
        if (not frame:IsActive()) then
            return;
        end
        if ((unit == 'player' and powerType == 'COMBO_POINTS') or event == 'TRAIT_CONFIG_UPDATED') then
            local maxComboPoints = UnitPowerMax('player', Enum.PowerType.ComboPoints)
            if (maxComboPoints ~= #self.ActiveFrames) then
                if (self.Update) then
                    self:Update()
                end
                return;
            end
            local comboPointsCount = UnitPower('player', Enum.PowerType.ComboPoints)
            for _, powerFrame in ipairs_reverse(frame.ActiveFrames) do
                local value = powerFrame.index <= comboPointsCount and 1 or 0
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

    C_Timer.After(0.5, function()
        if (frame:IsActive() and frame.Update) then
            frame:Update()
        end
    end)
end

comboPoints.Update = function(frame)
    local maxComboPoints = UnitPowerMax('player', Enum.PowerType.ComboPoints)
    local db = frame.db

    for _, comboPointsFrame in pairs(frame.ComboPointsFrames) do
        comboPointsFrame:Hide()
    end

    wipe(frame.ActiveFrames)
    for i = 1, maxComboPoints do
        local powerFrame = frame.ComboPointsFrames[i]
        -- Create frames
        if (not powerFrame) then
            powerFrame = comboPoints:CreateSinglePower(frame)
            frame.ComboPointsFrames[i] = powerFrame
        end
        powerFrame.index = i
        table.insert(frame.ActiveFrames, powerFrame)
        powerFrame:Show()
        EXUI:SetSize(powerFrame, db.comboPointsWidth, db.comboPointsHeight)
        powerFrame.StatusBar:SetStatusBarColor(db.comboPointsColor.r, db.comboPointsColor.g, db.comboPointsColor.b,
            db.comboPointsColor.a)
        powerFrame.StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', db.comboPointsBarTexture))
        core:ApplySegmentChrome(powerFrame, db.comboPointsBackgroundColor, db.comboPointsBorderColor)
        powerFrame.FillAnimation = db.fillAnimation
    end

    local prev = nil
    for _, activeFrame in ipairs(frame.ActiveFrames) do
        activeFrame:ClearAllPoints()
        if (prev) then
            EXUI:SetPoint(activeFrame, 'LEFT', prev, 'RIGHT', db.comboPointsSpacing, 0)
        else
            EXUI:SetPoint(activeFrame, 'LEFT', frame, 'LEFT', 0, 0)
        end
        prev = activeFrame
    end

    local groupWidth, groupHeight = core:GetSegmentGroupSize(db.comboPointsWidth, db.comboPointsHeight, #frame.ActiveFrames, db.comboPointsSpacing)
    EXUI:SetSize(frame, groupWidth, groupHeight)

    frame:OnEvent('UNIT_POWER_UPDATE', 'player', 'COMBO_POINTS') -- Trigger Update
end

comboPoints.IsActive = function(self, frame)
    local db = frame.db
    local enabled = db.enable
    return enabled and UnitPowerMax('player', Enum.PowerType.ComboPoints) > 0
end

comboPoints.GetOptions = function(self, displayID)
    local options = {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Combo Points'
        },
        {
            type = 'range',
            label = 'Width',
            name = 'comboPointsWidth',
            min = 1,
            max = 300,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'comboPointsWidth')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'comboPointsWidth', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Height',
            name = 'comboPointsHeight',
            min = 1,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'comboPointsHeight')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'comboPointsHeight', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Spacing',
            name = 'comboPointsSpacing',
            min = -3,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'comboPointsSpacing')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'comboPointsSpacing', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'spacer',
            width = 40
        },
        {
            type = 'dropdown',
            label = 'Bar Texture',
            name = 'comboPointsBarTexture',
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
                return RDCore:GetValueForDisplay(displayID, 'comboPointsBarTexture')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'comboPointsBarTexture', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 40
        },
        {
            type = 'spacer',
            width = 60
        },
        {
            type = 'color-picker',
            label = 'Color',
            name = 'comboPointsColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'comboPointsColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'comboPointsColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 10
        },
        {
            type = 'color-picker',
            label = 'Background Color',
            name = 'comboPointsBackgroundColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'comboPointsBackgroundColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'comboPointsBackgroundColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = 'comboPointsBorderColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'comboPointsBorderColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'comboPointsBorderColor', value)
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
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'fillAnimation', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100
        }
    }

    return options
end

comboPoints.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        comboPointsWidth = 30,
        comboPointsHeight = 16,
        comboPointsSpacing = 2,
        comboPointsColor = { r = 1, g = 204 / 255, b = 0, a = 1 },
        comboPointsBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        comboPointsBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        fillAnimation = false,
        comboPointsBarTexture = 'ExalityUI Status Bar'
    })
end

core:RegisterPowerType({
    name = 'Combo Points',
    control = comboPoints,
    selfControlledSize = true
})
