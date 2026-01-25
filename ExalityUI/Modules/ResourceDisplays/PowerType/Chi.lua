---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

local chi = EXUI:GetModule('resource-displays-chi')

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

chi.CreateSinglePower = function(self, parent)
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

chi.Create = function(self, frame)
    frame.IsActive = function(self) return chi:IsActive(self) end

    frame.ChiFrames = {}
    frame.ActiveFrames = {}

    frame:RegisterUnitEvent('UNIT_POWER_UPDATE', 'player')
    frame:RegisterEvent('TRAIT_CONFIG_UPDATED')
    frame:RegisterEvent('PLAYER_ENTERING_WORLD')

    frame.OnEvent = function(self, event, unit, powerType)
        if ((unit == 'player' and powerType == 'CHI') or event == 'TRAIT_CONFIG_UPDATED') then
            local maxChi = UnitPowerMax('player', Enum.PowerType.Chi)
            if (maxChi ~= #self.ActiveFrames) then
                if (self.Update) then
                    self:Update()
                end
                return;
            end
            local chiCount = UnitPower('player', Enum.PowerType.Chi)
            for _, powerFrame in ipairs_reverse(frame.ActiveFrames) do
                local value = powerFrame.index <= chiCount and 1 or 0
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

chi.Update = function(frame)
    local maxChi = UnitPowerMax('player', Enum.PowerType.Chi)
    local db = frame.db

    for _, chiFrame in pairs(frame.ChiFrames) do
        chiFrame:Hide()
    end

    wipe(frame.ActiveFrames)
    for i = 1, maxChi do
        local powerFrame = frame.ChiFrames[i]
        -- Create frames
        if (not powerFrame) then
            powerFrame = chi:CreateSinglePower(frame)
            frame.ChiFrames[i] = powerFrame
        end
        powerFrame.index = i
        table.insert(frame.ActiveFrames, powerFrame)
        powerFrame:Show()
        EXUI:SetSize(powerFrame, db.chiWidth, db.chiHeight)
        powerFrame.StatusBar:SetStatusBarColor(db.chiColor.r, db.chiColor.g, db.chiColor.b,
            db.chiColor.a)
        powerFrame.StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', db.chiBarTexture))
        powerFrame:SetBackdropColor(db.chiBackgroundColor.r, db.chiBackgroundColor.g,
            db.chiBackgroundColor.b,
            db.chiBackgroundColor.a)
        powerFrame:SetBackdropBorderColor(db.chiBorderColor.r, db.chiBorderColor.g,
            db.chiBorderColor.b, db.chiBorderColor.a)
        powerFrame.FillAnimation = db.fillAnimation
    end

    local prev = nil
    for _, activeFrame in ipairs(frame.ActiveFrames) do
        activeFrame:ClearAllPoints()
        if (prev) then
            EXUI:SetPoint(activeFrame, 'LEFT', prev, 'RIGHT', db.chiSpacing, 0)
        else
            EXUI:SetPoint(activeFrame, 'LEFT', frame, 'LEFT', 0, 0)
        end
        prev = activeFrame
    end

    frame:SetSize(db.chiWidth * #frame.ActiveFrames + 2 * #frame.ActiveFrames - 2, db.chiHeight)

    frame:OnEvent('UNIT_POWER_UPDATE', 'player', 'CHI') -- Trigger Update
end

chi.IsActive = function(self, frame)
    local db = frame.db
    local enabled = db.enable

    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    local isWW = specId == 269
    return enabled and UnitPowerMax('player', Enum.PowerType.Chi) > 0 and isWW
end

chi.GetOptions = function(self, displayID)
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
            name = 'chiWidth',
            min = 1,
            max = 300,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'chiWidth')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'chiWidth', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Height',
            name = 'chiHeight',
            min = 1,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'chiHeight')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'chiHeight', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Spacing',
            name = 'chiSpacing',
            min = -3,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'chiSpacing')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'chiSpacing', value)
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
            name = 'chiBarTexture',
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
                return RDCore:GetValueForDisplay(displayID, 'chiBarTexture')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'chiBarTexture', value)
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
            name = 'chiColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'chiColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'chiColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 10
        },
        {
            type = 'color-picker',
            label = 'Background Color',
            name = 'chiBackgroundColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'chiBackgroundColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'chiBackgroundColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = 'chiBorderColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'chiBorderColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'chiBorderColor', value)
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

chi.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        chiWidth = 30,
        chiHeight = 16,
        chiSpacing = 2,
        chiColor = { r = 0, g = 1, b = 145 / 255, a = 1 },
        chiBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        chiBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        fillAnimation = false,
        chiBarTexture = 'ExalityUI Status Bar'
    })
end

core:RegisterPowerType({
    name = 'Chi',
    control = chi,
    selfControlledSize = true
})
