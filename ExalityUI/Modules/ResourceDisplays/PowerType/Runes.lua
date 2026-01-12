---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

------------------

---@class EXUIResourceDisplaysRunes
local runes = EXUI:GetModule('resource-displays-runes')

runes.CreateSingleRune = function(self, parent)
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

    local elementFrame = CreateFrame('Frame', nil, frame)
    elementFrame:SetAllPoints()
    elementFrame:SetFrameLevel(statusBar:GetFrameLevel() + 1)
    frame.ElementFrame = elementFrame

    local text = elementFrame:CreateFontString(nil, 'OVERLAY')
    frame.Text = text
    text:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    text:SetText('')
    text:Hide()

    frame.OnUpdate = function(self, elapsed)
        if (self.DurationObject) then
            self.Text:SetText(string.format('%.1f', self.DurationObject:GetRemainingDuration()))
        end
    end

    frame.StatusBar = statusBar

    return frame
end

runes.Create = function(self, frame)
    frame.IsActive = function(self) return runes:IsActive(self) end

    frame.ActiveFrames = {}

    frame:RegisterEvent('RUNE_POWER_UPDATE')

    frame.OnEvent = function(self)
        for runeIndex = 1, 6 do
            local runeFrame = frame.ActiveFrames[runeIndex]
            if (runeFrame) then
                local startTime, duration, isRuneReady = GetRuneCooldown(runeIndex)
                if (isRuneReady) then
                    runeFrame.StatusBar:SetValue(1)
                    runeFrame.StatusBar:SetStatusBarColor(
                        self.RuneColor.r,
                        self.RuneColor.g,
                        self.RuneColor.b,
                        self.RuneColor.a
                    )
                    runeFrame.Text:SetText('')
                    if (runeFrame:GetScript('OnUpdate')) then
                        runeFrame:SetScript('OnUpdate', nil)
                    end
                else
                    local durationObject = C_DurationUtil.CreateDuration()
                    durationObject:SetTimeFromStart(startTime, duration)
                    runeFrame.DurationObject = durationObject
                    if (self.db.runeShowText and not frame:GetScript('OnUpdate')) then
                        runeFrame:SetScript('OnUpdate', runeFrame.OnUpdate)
                    end
                    runeFrame.StatusBar:SetTimerDuration(durationObject, Enum.StatusBarInterpolation.ExponentialEaseOut)
                    runeFrame.StatusBar:SetStatusBarColor(
                        self.RuneOnCDColor.r,
                        self.RuneOnCDColor.g,
                        self.RuneOnCDColor.b,
                        self.RuneOnCDColor.a
                    )
                end
            end
        end
    end
    frame:SetScript('OnEvent', function(self, ...)
        self:OnEvent(...)
    end)
end

runes.Update = function(frame)
    local db = frame.db

    for i = 1, 6 do
        local runeFrame = frame.ActiveFrames[i]
        if (not runeFrame) then
            runeFrame = runes:CreateSingleRune(frame)
            frame.ActiveFrames[i] = runeFrame
            frame.RuneIndex = i
        end
        frame.RuneColor = db.runeColor
        frame.RuneOnCDColor = db.runeOnCDColor
        EXUI:SetSize(runeFrame, db.runeWidth, db.runeHeight)
        runeFrame.StatusBar:SetStatusBarColor(db.runeColor.r, db.runeColor.g, db.runeColor.b, db.runeColor.a)
        runeFrame:SetBackdropColor(db.runeBackgroundColor.r, db.runeBackgroundColor.g, db.runeBackgroundColor.b,
            db.runeBackgroundColor.a)
        runeFrame:SetBackdropBorderColor(db.runeBorderColor.r, db.runeBorderColor.g, db.runeBorderColor.b,
            db.runeBorderColor.a)
        runeFrame.Text:SetFont(LSM:Fetch('font', db.runeFont), db.runeFontSize, db.runeFontFlag)
        runeFrame.Text:SetVertexColor(db.runeTextColor.r, db.runeTextColor.g, db.runeTextColor.b, db.runeTextColor.a)
        runeFrame.Text:ClearAllPoints()
        runeFrame.Text:SetPoint(db.runeTextAnchorPoint, runeFrame, db.runeTextRelativeAnchorPoint, db.runeTextXOff,
            db.runeTextYOff)
        if (db.runeShowText) then
            runeFrame.Text:Show()
        else
            runeFrame.Text:Hide()
        end
    end

    local prev = nil
    for _, activeFrame in ipairs(frame.ActiveFrames) do
        activeFrame:ClearAllPoints()
        if (prev) then
            EXUI:SetPoint(activeFrame, 'LEFT', prev, 'RIGHT', db.runeSpacing, 0)
        else
            EXUI:SetPoint(activeFrame, 'LEFT', frame, 'LEFT', 0, 0)
        end
        prev = activeFrame
    end

    frame:SetSize(db.runeWidth * #frame.ActiveFrames + 2 * #frame.ActiveFrames - 2, db.runeHeight)
    frame:OnEvent()
end

runes.IsActive = function(self, frame)
    local db = frame.db
    local enabled = db.enable
    local _, class = UnitClass('player')
    return enabled and class == 'DEATHKNIGHT'
end

runes.GetOptions = function(self, displayID)
    local options = {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Runes'
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
                return RDCore:GetValueForDisplay(displayID, 'runeWidth')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeWidth', value)
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
                return RDCore:GetValueForDisplay(displayID, 'runeHeight')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeHeight', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Spacing',
            name = 'runeSpacing',
            min = -3,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeSpacing')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeSpacing', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'color-picker',
            label = 'Color',
            name = 'runeColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'color-picker',
            label = 'On CD Color',
            name = 'runeOnCDColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeOnCDColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeOnCDColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'spacer',
            width = 12
        },
        {
            type = 'color-picker',
            label = 'Background Color',
            name = 'runeBackgroundColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeBackgroundColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeBackgroundColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = 'runeBorderColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeBorderColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeBorderColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'title',
            size = 12,
            width = 100,
            label = 'Rune Countdown Text'
        },
        {
            type = 'toggle',
            label = 'Show',
            name = 'runeShowText',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeShowText', value)
                RDCore:RefreshDisplayByID(displayID)
                optionsFields:RefreshOptions()
            end,
            width = 100
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = 'runeFont',
            getOptions = function()
                local fonts = LSM:List('font')
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            isFontDropdown = true,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeFont')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeFont', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'runeFontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeFontFlag')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeFontFlag', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25
        },
        {
            type = 'range',
            label = 'Font Size',
            name = 'runeFontSize',
            min = 1,
            max = 100,
            step = 1,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeFontSize')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeFontSize', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 20
        },
        {
            type = 'spacer',
            width = 30
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = 'runeTextAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeTextAnchorPoint')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeTextAnchorPoint', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 22
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'runeTextRelativeAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeTextRelativeAnchorPoint')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeTextRelativeAnchorPoint', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 22
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'runeTextXOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 20,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeTextXOff')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeTextXOff', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'runeTextYOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 20,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeTextYOff')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeTextYOff', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'color-picker',
            label = 'Text Color',
            name = 'runeTextColor',
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeTextColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeTextColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        }
    }

    return options
end

runes.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        runeWidth = 30,
        runeHeight = 16,
        runeSpacing = 2,
        runeColor = { r = 1, g = 0, b = 0, a = 1 },
        runeBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        runeBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        runeOnCDColor = { r = 1, g = 0, b = 0, a = 1 },
        runeFont = 'DMSans',
        runeFontSize = 12,
        runeFontFlag = 'OUTLINE',
        runeTextAnchorPoint = 'CENTER',
        runeTextRelativeAnchorPoint = 'CENTER',
        runeTextXOff = 0,
        runeTextYOff = 0,
        runeTextColor = { r = 1, g = 1, b = 1, a = 1 },
        runeShowText = false,
    })
end

core:RegisterPowerType({
    name = 'DK Runes',
    control = runes,
    selfControlledSize = true
})
