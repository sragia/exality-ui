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

---@class EXUIResourceDisplaysEssence
local essence = EXUI:GetModule('resource-displays-essence')

essence.cache = { {}, {}, {}, {}, {}, {} }
essence.handler = nil
essence.EnableUpdates = function(self, frame)
    if (not self.handler) then
        self.handler = CreateFrame('Frame')
        self.handler.frames = {}
        self.handler.lastTime = 0
        self.handler.lastFullValue = 0

        -- Credit to WeakAuras team for this cuz Evokers stupid and I dont wanna figure this out
        self.handler.OnEvent = function(self, event, unit, powerType)
            if (powerType and powerType ~= 'ESSENCE') then
                return
            end

            local now = GetTime()
            if self.lastTime == now then
                return
            end
            local power = UnitPower("player", Enum.PowerType.Essence)
            local total = UnitPowerMax("player", Enum.PowerType.Essence)
            local peace = GetPowerRegenForPowerType(Enum.PowerType.Essence)
            if peace == nil or peace == 0 then
                peace = 0.2
            end
            local duration = 1 / peace
            local partial = UnitPartialPower("player", Enum.PowerType.Essence) / 1000

            if (partial == 0) then
                self.lastFullValue = now
            elseif power ~= total then
                -- UnitPartialPower is a rather poor api, which returns incorrect values
                -- This almost mirrors what the default ui does, in that the default ui
                -- starts an animation and only uses UnitPartialPower when that animation's
                -- progress differs from UnitPartialPower by 0.1
                -- This here uses a similar logic. We sync whenever partial is 0
                -- and then estimate based on that. And as long as that
                -- estimate is within 0.1 of UnitPartialPower we prefer the estimate
                local estimatedPartial = (now - self.lastFullValue) / duration
                estimatedPartial = estimatedPartial - floor(estimatedPartial)
                if abs(estimatedPartial - partial) < 0.1 then
                    partial = estimatedPartial
                end
            end

            for i = 1, 6 do
                local essence = essence.cache[i]
                if (essence) then
                    if power >= i then
                        -- Is full essence
                        essence.isFull = true
                    elseif power + 1 == i then
                        -- Recharging essence
                        essence.duration = duration
                        essence.expirationTime = GetTime() + (1 - partial) * duration
                        essence.isFull = false
                        essence.isEmpty = false
                    else
                        -- Not recharging right now - empty
                        essence.isEmpty = true
                        essence.isFull = false
                    end
                end
            end
            self.lastTime = now

            for _, f in ipairs(self.frames) do
                if (f.OnEvent) then
                    f:OnEvent()
                end
            end
        end
        self.handler:SetScript('OnEvent', self.handler.OnEvent)
    end

    local found = false
    for _, f in ipairs(self.handler.frames) do
        if (frame == f) then
            found = true
            break
        end
    end
    if (not found) then
        table.insert(self.handler.frames, frame)
    end
    if (not self.handler.enabled) then
        -- Register Events
        self.handler:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
        self.handler:RegisterUnitEvent("UNIT_MAXPOWER", "player")
        self.handler:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.handler:RegisterEvent("PLAYER_LEAVING_WORLD")
    end

    self.enabled = true
    self.handler:OnEvent()
end

essence.DisableUpdates = function(self, frame)
    if (self.handler and self.handler.frames) then
        for i, f in ipairs(self.handler.frames) do
            if (frame == f) then
                table.remove(self.handler.frames, i)
                break
            end
        end

        if (#self.handler.frames == 0) then
            self.handler:UnregisterAllEvents()
            self.handler.enabled = false
        end
    end
end

essence.CreateSingleEssence = function(self, parent)
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

essence.Create = function(self, frame)
    frame.IsActive = function(self) return essence:IsActive(self) end

    frame.ActiveFrames = {}
    frame.EssenceFrames = {}

    frame.OnEvent = function(self, event)
        if (event == 'TRAIT_CONFIG_UPDATED') then
            local maxEssence = UnitPowerMax('player', Enum.PowerType.Essence)
            if (maxEssence ~= #self.ActiveFrames) then
                self:Update()
                return;
            end
        end
        for i = 1, UnitPowerMax('player', Enum.PowerType.Essence) do
            local essenceFrame = frame.ActiveFrames[i]
            local cache = essence.cache[i]
            if (essenceFrame and cache) then
                if (cache.isFull) then
                    essenceFrame.StatusBar:SetValue(1)
                    essenceFrame.StatusBar:SetMinMaxValues(0, 1)
                    essenceFrame.StatusBar:SetStatusBarColor(
                        frame.EssenceColor.r,
                        frame.EssenceColor.g,
                        frame.EssenceColor.b,
                        frame.EssenceColor.a
                    )
                    essenceFrame.Text:SetText('')
                    if (essenceFrame:GetScript('OnUpdate')) then
                        essenceFrame:SetScript('OnUpdate', nil)
                    end
                elseif (cache.isEmpty) then
                    essenceFrame.StatusBar:SetValue(0)
                    essenceFrame.StatusBar:SetMinMaxValues(0, 1)
                    essenceFrame.Text:SetText('')
                    if (essenceFrame:GetScript('OnUpdate')) then
                        essenceFrame:SetScript('OnUpdate', nil)
                    end
                elseif (cache.duration) then
                    local durationObject = essenceFrame.DurationObject or C_DurationUtil.CreateDuration()
                    durationObject:SetTimeFromEnd(cache.expirationTime, cache.duration)
                    essenceFrame.DurationObject = durationObject
                    if (self.db.essenceShowText and not essenceFrame:GetScript('OnUpdate')) then
                        essenceFrame:SetScript('OnUpdate', essenceFrame.OnUpdate)
                    end
                    essenceFrame.StatusBar:SetTimerDuration(durationObject,
                        Enum.StatusBarInterpolation.ExponentialEaseOut)
                    essenceFrame.StatusBar:SetStatusBarColor(
                        frame.EssenceOnCDColor.r,
                        frame.EssenceOnCDColor.g,
                        frame.EssenceOnCDColor.b,
                        frame.EssenceOnCDColor.a
                    )
                end
            end
        end
    end
    frame:SetScript('OnEvent', function(self, ...)
        self:OnEvent(...)
    end)

    frame.Enable = function(self)
        self:RegisterUnitEvent('UNIT_POWER_FREQUENT', 'player')
        self:RegisterEvent('TRAIT_CONFIG_UPDATED')
        essence:EnableUpdates(self)
    end

    frame.Disable = function(self)
        self:UnregisterAllEvents()
        essence:DisableUpdates(self)
    end
end

essence.Update = function(frame)
    local db = frame.db

    for _, essenceFrame in pairs(frame.EssenceFrames) do
        essenceFrame:ClearAllPoints()
        essenceFrame:Hide()
    end
    wipe(frame.ActiveFrames)

    for i = 1, UnitPowerMax('player', Enum.PowerType.Essence) do
        local essenceFrame = frame.EssenceFrames[i]
        if (not essenceFrame) then
            essenceFrame = essence:CreateSingleEssence(frame)
            frame.EssenceFrames[i] = essenceFrame
            frame.EssenceIndex = i
        end
        frame.EssenceColor = db.essenceColor
        frame.EssenceOnCDColor = db.essenceOnCDColor
        table.insert(frame.ActiveFrames, essenceFrame)
        EXUI:SetSize(essenceFrame, db.essenceWidth, db.essenceHeight)
        essenceFrame.StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', db.essenceBarTexture))
        essenceFrame.StatusBar:SetStatusBarColor(db.essenceColor.r, db.essenceColor.g, db.essenceColor.b,
            db.essenceColor.a)
        essenceFrame:SetBackdropColor(db.essenceBackgroundColor.r, db.essenceBackgroundColor.g,
            db.essenceBackgroundColor.b,
            db.essenceBackgroundColor.a)
        essenceFrame:SetBackdropBorderColor(db.essenceBorderColor.r, db.essenceBorderColor.g, db.essenceBorderColor.b,
            db.essenceBorderColor.a)
        essenceFrame.Text:SetFont(LSM:Fetch('font', db.essenceFont), db.essenceFontSize, db.essenceFontFlag)
        essenceFrame.Text:SetVertexColor(db.essenceTextColor.r, db.essenceTextColor.g, db.essenceTextColor.b,
            db.essenceTextColor.a)
        essenceFrame.Text:ClearAllPoints()
        essenceFrame.Text:SetPoint(db.essenceTextAnchorPoint, essenceFrame, db.essenceTextRelativeAnchorPoint,
            db.essenceTextXOff,
            db.essenceTextYOff)
    end

    local prev = nil
    for _, activeFrame in ipairs(frame.ActiveFrames) do
        activeFrame:ClearAllPoints()
        if (prev) then
            EXUI:SetPoint(activeFrame, 'LEFT', prev, 'RIGHT', db.essenceSpacing, 0)
        else
            EXUI:SetPoint(activeFrame, 'LEFT', frame, 'LEFT', 0, 0)
        end
        activeFrame:Show()
        prev = activeFrame
    end

    frame:SetSize(db.essenceWidth * #frame.ActiveFrames + 2 * #frame.ActiveFrames - 2, db.essenceHeight)
    frame:OnEvent()
end

essence.IsActive = function(self, frame)
    local db = frame.db
    local enabled = db.enable
    local _, class = UnitClass('player')
    return enabled and class == 'EVOKER'
end

essence.GetOptions = function(self, displayID)
    local options = {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = 'Essence'
        },
        {
            type = 'range',
            label = 'Width',
            name = 'essenceWidth',
            min = 1,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceWidth')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceWidth', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Height',
            name = 'essenceHeight',
            min = 1,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceHeight')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceHeight', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Spacing',
            name = 'essenceSpacing',
            min = -3,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceSpacing')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceSpacing', value)
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
            name = 'essenceBarTexture',
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
                return RDCore:GetValueForDisplay(displayID, 'essenceBarTexture')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceBarTexture', value)
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
            name = 'essenceColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'color-picker',
            label = 'On CD Color',
            name = 'essenceOnCDColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceOnCDColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceOnCDColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'color-picker',
            label = 'Background Color',
            name = 'essenceBackgroundColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceBackgroundColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceBackgroundColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = 'essenceBorderColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceBorderColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceBorderColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'title',
            size = 12,
            width = 100,
            label = 'Essence Countdown Text'
        },
        {
            type = 'toggle',
            label = 'Show',
            name = 'essenceShowText',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceShowText')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceShowText', value)
                RDCore:RefreshDisplayByID(displayID)
                optionsFields:RefreshOptions()
            end,
            width = 100
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = 'essenceFont',
            getOptions = function()
                local fonts = LSM:List('font')
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceShowText')
            end,
            isFontDropdown = true,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceFont')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceFont', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'essenceFontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceFontFlag')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceFontFlag', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25
        },
        {
            type = 'range',
            label = 'Font Size',
            name = 'essenceFontSize',
            min = 1,
            max = 100,
            step = 1,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceFontSize')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceFontSize', value)
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
            name = 'essenceTextAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceTextAnchorPoint')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceTextAnchorPoint', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 22
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'essenceTextRelativeAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceTextRelativeAnchorPoint')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceTextRelativeAnchorPoint', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 22
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'essenceTextXOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 20,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceTextXOff')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceTextXOff', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'essenceTextYOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 20,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceTextYOff')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceTextYOff', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'color-picker',
            label = 'Text Color',
            name = 'essenceTextColor',
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceShowText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'essenceTextColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'essenceTextColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        }
    }

    return options
end

essence.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        essenceWidth = 30,
        essenceHeight = 16,
        essenceSpacing = 2,
        essenceColor = { r = 1, g = 0, b = 0, a = 1 },
        essenceBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        essenceBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        essenceOnCDColor = { r = 1, g = 0, b = 0, a = 1 },
        essenceFont = 'DMSans',
        essenceFontSize = 12,
        essenceFontFlag = 'OUTLINE',
        essenceTextAnchorPoint = 'CENTER',
        essenceTextRelativeAnchorPoint = 'CENTER',
        essenceTextXOff = 0,
        essenceTextYOff = 0,
        essenceTextColor = { r = 1, g = 1, b = 1, a = 1 },
        essenceShowText = false,
        essenceBarTexture = 'ExalityUI Status Bar'
    })
end

core:RegisterPowerType({
    name = 'Essence',
    control = essence,
    selfControlledSize = true
})
