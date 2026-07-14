---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUIResourceDisplaysRunes
local runes = EXUI:GetModule('resource-displays-runes')

local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')

runes.CreateSingleRune = function(self, parent)
    local frame = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    EXUI:SetSize(frame, 30, 16)

    local statusBar = CreateFrame('StatusBar', nil, frame)
    statusBarElement:ApplyInsets(statusBar, frame)
    statusBar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(0)
    statusBar:SetStatusBarColor(1, 0, 0, 1)

    local elementFrame = CreateFrame('Frame', nil, frame)
    elementFrame:SetAllPoints()
    elementFrame:SetFrameLevel(statusBar:GetFrameLevel() + 1)
    frame.ElementFrame = elementFrame

    local glow = frame:CreateTexture(nil, 'OVERLAY')
    glow:SetAllPoints()
    glow:SetTexture(EXUI.const.masque.rectangle.highlight)
    glow:SetBlendMode('ADD')
    glow:SetAlpha(0.6)
    glow:Hide()
    frame.ReadyGlow = glow

    local text = elementFrame:CreateFontString(nil, 'OVERLAY')
    frame.Text = text
    text:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    text:SetText('')
    text:Hide()

    frame.OnUpdate = function(self, elapsed)
        if not self.DurationObject then
            return
        end
        local parentFrame = self:GetParent()
        local db = parentFrame and parentFrame.db
        if not db or not db.runeShowText then
            return
        end
        local remaining = self.DurationObject:GetRemainingDuration()
        local threshold = db.runeCDTextThreshold or 0
        if threshold > 0 and remaining > threshold then
            self.Text:SetText('')
            return
        end
        self.Text:SetText(helpers:FormatCooldownText(db.runeCDTextFormat, remaining))
    end

    frame.StatusBar = statusBar

    return frame
end

runes.ApplyPreview = function(self, frame)
    local readyCount = preview:GetMockValue('DK Runes')
    local now = GetTime()

    for runeIndex = 1, 6 do
        local runeFrame = frame.ActiveFrames[runeIndex]
        if not runeFrame then
            -- skip
        elseif runeIndex <= readyCount then
            runeFrame.DurationObject = nil
            runeFrame.StatusBar:SetMinMaxValues(0, 1)
            runeFrame.StatusBar:SetValue(1)
            runeFrame.StatusBar:SetStatusBarColor(
                frame.RuneColor.r,
                frame.RuneColor.g,
                frame.RuneColor.b,
                frame.RuneColor.a
            )
            runeFrame.Text:SetText('')
            runeFrame:SetScript('OnUpdate', nil)
            if frame.db.runeReadyGlow and runeFrame.ReadyGlow then
                runeFrame.ReadyGlow:Show()
            elseif runeFrame.ReadyGlow then
                runeFrame.ReadyGlow:Hide()
            end
        else
            local durationObject = C_DurationUtil.CreateDuration()
            local mockDuration = 10
            local mockStart = now - (2 + (runeIndex - readyCount))
            durationObject:SetTimeFromStart(mockStart, mockDuration)
            runeFrame.DurationObject = durationObject
            if frame.db.runeShowText and not runeFrame:GetScript('OnUpdate') then
                runeFrame:SetScript('OnUpdate', runeFrame.OnUpdate)
            elseif not frame.db.runeShowText and runeFrame:GetScript('OnUpdate') then
                runeFrame:SetScript('OnUpdate', nil)
            end
            runeFrame.StatusBar:SetMinMaxValues(0, 1)
            runeFrame.StatusBar:SetTimerDuration(durationObject, Enum.StatusBarInterpolation.ExponentialEaseOut)
            runeFrame.StatusBar:SetStatusBarColor(
                frame.RuneOnCDColor.r,
                frame.RuneOnCDColor.g,
                frame.RuneOnCDColor.b,
                frame.RuneOnCDColor.a
            )
            if runeFrame.ReadyGlow then
                runeFrame.ReadyGlow:Hide()
            end
        end
    end
end

runes.Create = function(self, frame)
    frame.IsActive = function(self) return runes:IsActive(self) end
    frame.ActiveFrames = {}

    frame.OnEvent = function(self)
        if preview:ShouldUsePreview(self) then
            runes:ApplyPreview(self)
            return
        end

        for runeIndex = 1, 6 do
            local runeFrame = self.ActiveFrames[runeIndex]
            if runeFrame then
                local startTime, duration, isRuneReady = GetRuneCooldown(runeIndex)
                if isRuneReady then
                    runeFrame.StatusBar:SetValue(1)
                    runeFrame.StatusBar:SetStatusBarColor(
                        self.RuneColor.r,
                        self.RuneColor.g,
                        self.RuneColor.b,
                        self.RuneColor.a
                    )
                    runeFrame.Text:SetText('')
                    if runeFrame:GetScript('OnUpdate') then
                        runeFrame:SetScript('OnUpdate', nil)
                    end
                    if self.db.runeReadyGlow and runeFrame.ReadyGlow then
                        runeFrame.ReadyGlow:Show()
                    elseif runeFrame.ReadyGlow then
                        runeFrame.ReadyGlow:Hide()
                    end
                else
                    if not startTime or not duration or duration <= 0 then
                        runeFrame.DurationObject = nil
                        runeFrame.StatusBar:SetMinMaxValues(0, 1)
                        runeFrame.StatusBar:SetValue(0)
                        runeFrame.Text:SetText('')
                        runeFrame:SetScript('OnUpdate', nil)
                        if runeFrame.ReadyGlow then
                            runeFrame.ReadyGlow:Hide()
                        end
                    else
                        local durationObject = C_DurationUtil.CreateDuration()
                        durationObject:SetTimeFromStart(startTime, duration)
                        runeFrame.DurationObject = durationObject
                        if self.db.runeShowText and not runeFrame:GetScript('OnUpdate') then
                            runeFrame:SetScript('OnUpdate', runeFrame.OnUpdate)
                        elseif not self.db.runeShowText and runeFrame:GetScript('OnUpdate') then
                            runeFrame:SetScript('OnUpdate', nil)
                        end
                        runeFrame.StatusBar:SetTimerDuration(durationObject,
                            Enum.StatusBarInterpolation.ExponentialEaseOut)
                        runeFrame.StatusBar:SetStatusBarColor(
                            self.RuneOnCDColor.r,
                            self.RuneOnCDColor.g,
                            self.RuneOnCDColor.b,
                            self.RuneOnCDColor.a
                        )
                        if runeFrame.ReadyGlow then
                            runeFrame.ReadyGlow:Hide()
                        end
                    end
                end
            end
        end
    end

    frame.Enable = function(self)
        self:RegisterEvent('RUNE_POWER_UPDATE')
        self:RegisterEvent('TRAIT_CONFIG_UPDATED')
        self:SetScript('OnEvent', function(f, ...)
            f:OnEvent(...)
        end)
        self:OnEvent()
    end

    frame.Disable = function(self)
        self:UnregisterAllEvents()
        self:SetScript('OnEvent', nil)
        for _, runeFrame in ipairs(self.ActiveFrames) do
            runeFrame:SetScript('OnUpdate', nil)
        end
    end
end

runes.Update = function(frame)
    local db = frame.db

    for i = 1, 6 do
        local runeFrame = frame.ActiveFrames[i]
        if not runeFrame then
            runeFrame = runes:CreateSingleRune(frame)
            frame.ActiveFrames[i] = runeFrame
        end
        frame.RuneColor = db.runeColor
        frame.RuneOnCDColor = db.runeOnCDColor
        EXUI:SetSize(runeFrame, db.runeWidth, db.runeHeight)
        runeFrame.StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', db.runeBarTexture))
        runeFrame.StatusBar:SetStatusBarColor(db.runeColor.r, db.runeColor.g, db.runeColor.b, db.runeColor.a)
        core:ApplySegmentChrome(runeFrame, db.runeBackgroundColor, db.runeBorderColor)
        runeFrame.Text:SetFont(LSM:Fetch('font', db.runeFont), db.runeFontSize, db.runeFontFlag)
        runeFrame.Text:SetVertexColor(db.runeTextColor.r, db.runeTextColor.g, db.runeTextColor.b, db.runeTextColor.a)
        runeFrame.Text:ClearAllPoints()
        runeFrame.Text:SetPoint(db.runeTextAnchorPoint, runeFrame, db.runeTextRelativeAnchorPoint, db.runeTextXOff,
            db.runeTextYOff)
        if db.runeShowText then
            runeFrame.Text:Show()
        else
            runeFrame.Text:Hide()
            runeFrame:SetScript('OnUpdate', nil)
        end
        if runeFrame.ReadyGlow then
            if db.runeReadyGlow then
                runeFrame.ReadyGlow:SetVertexColor(db.runeColor.r, db.runeColor.g, db.runeColor.b, 1)
            else
                runeFrame.ReadyGlow:Hide()
            end
        end
    end

    local groupWidth, groupHeight = helpers:LayoutSegments(frame, frame.ActiveFrames, db, 'runeWidth', 'runeHeight',
        'runeSpacing')
    EXUI:SetSize(frame, groupWidth, groupHeight)
    if preview:ShouldUsePreview(frame) then
        runes:ApplyPreview(frame)
        return
    end
    frame:OnEvent()
end

runes.IsActive = function(self, frame)
    local db = frame.db
    local _, class = UnitClass('player')
    return db.enable and class == 'DEATHKNIGHT'
end

runes.GetOptions = function(self, displayID)
    local options = {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Runes',
        },
        {
            type = 'range',
            label = 'Width',
            name = 'runeWidth',
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
            end,
        },
        {
            type = 'range',
            label = 'Height',
            name = 'runeHeight',
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
            end,
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
            end,
        },
        {
            type = 'dropdown',
            label = 'Layout',
            name = 'segmentLayout',
            getOptions = function()
                return {
                    horizontal = 'Horizontal',
                    vertical = 'Vertical',
                }
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'segmentLayout') or 'horizontal'
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'segmentLayout', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'toggle',
            label = 'Reverse Order',
            name = 'segmentReverse',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'segmentReverse')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'segmentReverse', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'Bar Texture',
            name = 'runeBarTexture',
            getOptions = function()
                local list = LSM:List('statusbar')
                local textureOptions = {}
                for _, texture in pairs(list) do
                    textureOptions[texture] = texture
                end
                return textureOptions
            end,
            isTextureDropdown = true,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeBarTexture')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeBarTexture', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 40,
        },
        {
            type = 'spacer',
            width = 60,
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
            width = 16,
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
            width = 18,
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
            width = 24,
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
            width = 16,
        },
        {
            type = 'toggle',
            label = 'Ready Glow',
            name = 'runeReadyGlow',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeReadyGlow')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeReadyGlow', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
        {
            type = 'title',
            size = 12,
            width = 100,
            label = 'Rune Countdown Text',
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
                optionsFields:RefreshOptionsDelayed()
            end,
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'CD Text Format',
            name = 'runeCDTextFormat',
            getOptions = function()
                return {
                    decimal = 'Decimal (1.5)',
                    seconds = 'Seconds (2)',
                }
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeCDTextFormat') or 'decimal'
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeCDTextFormat', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'range',
            label = 'CD Text Threshold',
            name = 'runeCDTextThreshold',
            min = 0,
            max = 60,
            step = 1,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeCDTextThreshold') or 0
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeCDTextThreshold', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'spacer',
            width = 50,
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = 'runeFont',
            getOptions = function()
                local fonts = LSM:List('font')
                local fontOptions = {}
                for _, font in ipairs(fonts) do
                    fontOptions[font] = font
                end
                return fontOptions
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
            width = 25,
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
            width = 25,
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
            width = 25,
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
            width = 25,
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'runeTextAnchorPoint',
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
            width = 25,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'runeTextRelativeAnchorPoint',
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
            width = 25,
        },
        {
            type = 'spacer',
            width = 50,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'runeTextXOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 25,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeTextXOff')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeTextXOff', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'runeTextYOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 25,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'runeShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'runeTextYOff')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'runeTextYOff', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
        },
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
        runeReadyGlow = false,
        runeCDTextFormat = 'decimal',
        runeCDTextThreshold = 0,
        runeFont = 'DMSans',
        runeFontSize = 12,
        runeFontFlag = 'OUTLINE',
        runeTextAnchorPoint = 'CENTER',
        runeTextRelativeAnchorPoint = 'CENTER',
        runeTextXOff = 0,
        runeTextYOff = 0,
        runeTextColor = { r = 1, g = 1, b = 1, a = 1 },
        runeShowText = false,
        runeBarTexture = 'ExalityUI Status Bar',
    })
end

core:RegisterPowerType({
    name = 'DK Runes',
    control = runes,
    selfControlledSize = true,
})
