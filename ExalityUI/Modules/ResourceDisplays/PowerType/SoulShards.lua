---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

local soulShards = EXUI:GetModule('resource-displays-soul-shards')

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

soulShards.CreateSinglePower = function(self, parent)
    local frame = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    EXUI:SetSize(frame, 30, 16)

    frame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:SetBackdropColor(0, 0, 0, 0.5)

    local statusBar = CreateFrame('StatusBar', nil, frame)
    EXUI:SetPoint(statusBar, 'TOPLEFT', 1, -1)
    EXUI:SetPoint(statusBar, 'BOTTOMRIGHT', -1, 1)
    statusBar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
    statusBar:SetMinMaxValues(0, 10)
    statusBar:SetValue(0)
    statusBar:SetStatusBarColor(1, 0, 0, 1)

    frame.StatusBar = statusBar

    return frame
end

soulShards.Create = function(self, frame)
    frame.IsActive = function(self) return soulShards:IsActive(self) end

    frame.SoulShardsFrames = {}
    frame.ActiveFrames = {}

    frame:RegisterUnitEvent('UNIT_POWER_UPDATE', 'player')
    frame:RegisterEvent('PLAYER_ENTERING_WORLD')
    frame:RegisterEvent('TRAIT_CONFIG_UPDATED')

    frame.Text = EXUI:GetModule('resource-displays-elements-text'):Create(frame)

    frame.OnEvent = function(self, event, unit, powerType)
        if ((unit == 'player' and powerType == 'SOUL_SHARDS') or event == 'TRAIT_CONFIG_UPDATED') then
            local maxSoulShards = UnitPowerMax('player', Enum.PowerType.SoulShards, true)
            if (maxSoulShards / 10 ~= #self.ActiveFrames) then
                self:Update()
                return;
            end
            local ssCount = UnitPower('player', Enum.PowerType.SoulShards, true)
            local ssFullCount = math.floor(ssCount / 10)
            local ssRemainingCount = ssCount % 10
            for _, powerFrame in ipairs_reverse(frame.ActiveFrames) do
                local value = 0
                if (powerFrame.index <= ssFullCount) then
                    value = 10
                elseif (powerFrame.index - 1 == ssFullCount) then
                    value = ssRemainingCount
                end
                local isChanging = powerFrame.StatusBar:GetValue() ~= value
                if (isChanging) then
                    powerFrame.StatusBar:SetValue(value,
                        powerFrame.FillAnimation and Enum.StatusBarInterpolation.ExponentialEaseOut or
                        Enum.StatusBarInterpolation.Immediate)
                    local color = value >= 10 and self.db.ssColor or self.db.ssPartialColor
                    powerFrame.StatusBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
                end
            end
            if (self.db.showText) then
                self.Text:SetText(ssCount / 10)
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

soulShards.Update = function(frame)
    local maxSoulShards = UnitPowerMax('player', Enum.PowerType.SoulShards, true)
    local db = frame.db

    for _, soulShardsFrame in pairs(frame.SoulShardsFrames) do
        soulShardsFrame:Hide()
    end

    wipe(frame.ActiveFrames)
    for i = 1, maxSoulShards / 10 do
        local powerFrame = frame.SoulShardsFrames[i]
        -- Create frames
        if (not powerFrame) then
            powerFrame = soulShards:CreateSinglePower(frame)
            frame.SoulShardsFrames[i] = powerFrame
        end
        powerFrame.index = i
        table.insert(frame.ActiveFrames, powerFrame)
        powerFrame:Show()
        EXUI:SetSize(powerFrame, db.ssWidth, db.ssHeight)
        powerFrame.StatusBar:SetStatusBarColor(db.ssColor.r, db.ssColor.g, db.ssColor.b, db.ssColor.a)
        powerFrame.StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', db.ssBarTexture))
        powerFrame:SetBackdropColor(db.ssBackgroundColor.r, db.ssBackgroundColor.g, db.ssBackgroundColor.b,
            db.ssBackgroundColor.a)
        powerFrame:SetBackdropBorderColor(db.ssBorderColor.r, db.ssBorderColor.g, db.ssBorderColor.b, db.ssBorderColor.a)
        powerFrame.FillAnimation = db.fillAnimation
    end

    local prev = nil
    for _, activeFrame in ipairs(frame.ActiveFrames) do
        activeFrame:ClearAllPoints()
        if (prev) then
            EXUI:SetPoint(activeFrame, 'LEFT', prev, 'RIGHT', db.ssSpacing, 0)
        else
            EXUI:SetPoint(activeFrame, 'LEFT', frame, 'LEFT', 0, 0)
        end
        prev = activeFrame
    end

    frame:SetSize(db.ssWidth * #frame.ActiveFrames + 2 * #frame.ActiveFrames - 2, db.ssHeight)

    frame:OnEvent('UNIT_POWER_UPDATE', 'player', 'SOUL_SHARDS') -- Trigger Update
end

soulShards.IsActive = function(self, frame)
    local db = frame.db
    local enabled = db.enable
    return enabled and UnitPowerMax('player', Enum.PowerType.SoulShards, true) > 0
end

soulShards.GetOptions = function(self, displayID)
    local options = {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Soul Shards'
        },
        {
            type = 'range',
            label = 'Width',
            name = 'ssWidth',
            min = 1,
            max = 300,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'ssWidth')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'ssWidth', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Height',
            name = 'ssHeight',
            min = 1,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'ssHeight')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'ssHeight', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Spacing',
            name = 'ssSpacing',
            min = -3,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'ssSpacing')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'ssSpacing', value)
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
            name = 'ssBarTexture',
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
                return RDCore:GetValueForDisplay(displayID, 'ssBarTexture')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'ssBarTexture', value)
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
            label = 'Color (Full)',
            name = 'ssColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'ssColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'ssColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },

        {
            type = 'color-picker',
            label = 'Color (Partial)',
            name = 'ssPartialColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'ssPartialColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'ssPartialColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'color-picker',
            label = 'Background Color',
            name = 'ssBackgroundColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'ssBackgroundColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'ssBackgroundColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = 'ssBorderColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'ssBorderColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'ssBorderColor', value)
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
        },
    }

    tAppendAll(options, EXUI:GetModule('resource-displays-elements-text'):GetOptions(displayID))
    return options
end

soulShards.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        ssWidth = 30,
        ssHeight = 16,
        ssSpacing = -1,
        ssColor = { r = 140 / 255, g = 3 / 255, b = 252 / 255, a = 1 },
        ssPartialColor = { r = 83 / 255, g = 0, b = 150 / 255, a = 1 },
        ssBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        ssBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        fillAnimation = false,
        textAnchorPoint = 'CENTER',
        textRelativeAnchorPoint = 'CENTER',
        textXOff = 0,
        textYOff = 0,
        textColor = { r = 1, g = 1, b = 1, a = 1 },
        showText = false,
        font = 'DMSans',
        fontSize = 12,
        fontFlag = 'OUTLINE',
        ssBarTexture = 'ExalityUI Status Bar'
    })
end

core:RegisterPowerType({
    name = 'Soul Shards',
    control = soulShards,
    selfControlledSize = true
})
