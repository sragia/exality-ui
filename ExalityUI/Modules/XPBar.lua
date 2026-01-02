---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

-----------------------------------

---@class EXUIXPBarModule
local xpBar = EXUI:GetModule('xp-bar')

xpBar.frame = nil
xpBar.EVENTS = {
    'PLAYER_ENTERING_WORLD',
    'QUEST_LOG_UPDATE',
    'UNIT_QUEST_LOG_CHANGED',
    'PLAYER_XP_UPDATE',
    'PLAYER_LEVEL_UP',
    'UPDATE_EXHAUSTION',
    'UPDATE_EXPANSION_LEVEL',
    'TIME_PLAYED_MSG',
    'ENABLE_XP_GAIN',
    'DISABLE_XP_GAIN'
}

xpBar.ticker = nil
xpBar.maxLevel = 0
xpBar.startTime = time()
xpBar.timePlayedThisLevelReq = 0
xpBar.values = {
    currentXP = UnitXP('player'),
    maxXP = UnitXPMax('player'),
    currentLevel = UnitLevel('player'),
    gainedXP = 0,
    xpPerHour = 0,
    timePlayedThisLevel = 0,
    completedQuestXP = 0,
    restedXP = GetXPExhaustion() or 0,
}

xpBar.Init = function(self)
    self.Data:UpdateDefaults({
        enable = false,
        width = 400,
        height = 30,
        anchorPoint = 'CENTER',
        relativeAnchor = 'CENTER',
        xOffset = 0,
        yOffset = 0,
        font = 'DMSans',
        fontSize = 12,
        fontFlag = 'OUTLINE',
        showAtMaxLevel = false,
        xpBarColor = { r = 1, g = 210 / 255, b = 0, a = 1 },
        restedBarColor = { r = 0, g = 162 / 255, b = 1, a = 0.2 },
        completedQuestBarColor = { r = 1, g = 72 / 255, b = 0, a = 1 }
    })
    optionsController:RegisterModule(self)
    if (self.Data:GetValue('enable')) then
        self:Enable()
    else
        self:Disable()
    end
    self.maxLevel = GetMaxLevelForExpansionLevel(GetExpansionLevel())
end

xpBar.GetName = function(self)
    return 'XP Bar'
end

xpBar.GetOrder = function(self)
    return 999
end

xpBar.GetOptions = function(self)
    return {
        {
            type = 'title',
            label = 'XP Bar'
        },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            onObserve = function(value)
                self.Data:SetValue('enable', value)
                optionsFields:RefreshOptions()
                if (value) then
                    self:Enable()
                else
                    self:Disable()
                end
            end,
            currentValue = function()
                return self.Data:GetValue('enable')
            end,
            width = 100
        },
        {
            type = 'toggle',
            label = 'Show At Max Level',
            name = 'showAtMaxLevel',
            onObserve = function(value)
                self.Data:SetValue('showAtMaxLevel', value)
                self:HandleVisibility()
            end,
            currentValue = function()
                return self.Data:GetValue('showAtMaxLevel')
            end,
            width = 100
        },
        {
            type = 'range',
            label = 'Width',
            name = 'width',
            min = 1,
            max = 1000,
            step = 1,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('width')
            end,
            onChange = function(f, value)
                self.Data:SetValue('width', value)
                self:Configure()
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Height',
            name = 'height',
            min = 1,
            max = 100,
            step = 1,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('height')
            end,
            onChange = function(f, value)
                self.Data:SetValue('height', value)
                self:Configure()
            end,
            width = 20
        },
        {
            type = 'spacer',
            width = 60,
            depends = function()
                return self.Data:GetValue('enable')
            end,
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = 'anchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('anchorPoint')
            end,
            onChange = function(value)
                self.Data:SetValue('anchorPoint', value)
                self:Configure()
            end,
            width = 25
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'relativeAnchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('relativeAnchor')
            end,
            onChange = function(value)
                self.Data:SetValue('relativeAnchor', value)
                self:Configure()
            end,
            width = 25
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'xOffset',
            min = -1000,
            max = 1000,
            step = 1,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('xOffset')
            end,
            onChange = function(f, value)
                self.Data:SetValue('xOffset', value)
                self:Configure()
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'yOffset',
            min = -1000,
            max = 1000,
            step = 1,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('yOffset')
            end,
            onChange = function(f, value)
                self.Data:SetValue('yOffset', value)
                self:Configure()
            end,
            width = 20
        },
        {
            type = 'spacer',
            width = 10,
            depends = function()
                return self.Data:GetValue('enable')
            end,
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = 'font',
            getOptions = function()
                local fonts = LSM:List('font')
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('font')
            end,
            onChange = function(value)
                self.Data:SetValue('font', value)
                self:Configure()
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Font Size',
            name = 'fontSize',
            min = 1,
            max = 40,
            step = 1,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('fontSize')
            end,
            onChange = function(f, value)
                self.Data:SetValue('fontSize', value)
                self:Configure()
            end,
            width = 20
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'fontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('fontFlag')
            end,
            onChange = function(value)
                self.Data:SetValue('fontFlag', value)
                self:Configure()
            end,
            width = 20
        },
        {
            type = 'spacer',
            width = 40,
            depends = function()
                return self.Data:GetValue('enable')
            end,
        },
        {
            type = 'color-picker',
            name = 'xpBarColor',
            label = 'XP Bar Color',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('xpBarColor')
            end,
            onChange = function(value)
                self.Data:SetValue('xpBarColor', value)
                self:Configure()
            end,
            width = 16
        },
        {
            type = 'color-picker',
            name = 'restedBarColor',
            label = 'Rested Bar Color',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('restedBarColor')
            end,
            onChange = function(value)
                self.Data:SetValue('restedBarColor', value)
                self:Configure()
            end,
            width = 16
        },
        {
            type = 'color-picker',
            name = 'completedQuestBarColor',
            label = 'Completed Quest Bar Color',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('completedQuestBarColor')
            end,
            onChange = function(value)
                self.Data:SetValue('completedQuestBarColor', value)
                self:Configure()
            end,
            width = 16
        },
    }
end

xpBar.CreateFrame = function(self)
    self.frame = CreateFrame('Frame', 'ExalityUI_XPBar', UIParent, 'BackdropTemplate')

    self.frame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    self.frame:SetBackdropBorderColor(0, 0, 0, 1)
    self.frame:SetBackdropColor(0, 0, 0, 0.5)
    -- Containers
    local statusBarFrame = CreateFrame('Frame', nil, self.frame)
    EXUI:SetPoint(statusBarFrame, 'TOPLEFT', 1, -0.5)
    EXUI:SetPoint(statusBarFrame, 'BOTTOMRIGHT', -1, 1)
    statusBarFrame:SetClipsChildren(true)
    self.frame.StatusBarContainer = statusBarFrame

    local elementFrame = CreateFrame('Frame', nil, self.frame)
    elementFrame:SetAllPoints()

    --- Bars
    local statusBar = CreateFrame('StatusBar', nil, statusBarFrame)
    statusBar:SetAllPoints()
    statusBar:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    self.frame.XPBar = statusBar

    local spark = statusBar:CreateTexture(nil, 'OVERLAY')
    spark:SetWidth(2)
    spark:SetPoint('TOP', statusBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
    spark:SetPoint('BOTTOM', statusBar:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
    spark:SetTexture(EXUI.const.textures.frame.solidBg)
    spark:SetVertexColor(1, 1, 1, 1)
    self.frame.Spark = spark

    local restedBar = CreateFrame('StatusBar', nil, statusBarFrame)
    restedBar:SetPoint('TOPLEFT', statusBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
    restedBar:SetPoint('BOTTOMLEFT', statusBar:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
    restedBar:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    restedBar:SetWidth(100) -- Temp until it gets updated from config
    self.frame.RestedBar = restedBar

    local completedQuestBar = CreateFrame('StatusBar', nil, statusBarFrame)
    completedQuestBar:SetPoint('TOPLEFT', statusBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
    completedQuestBar:SetPoint('BOTTOMLEFT', statusBar:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
    completedQuestBar:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    completedQuestBar:SetWidth(100) -- Temp until it gets updated from config
    self.frame.CompletedQuestBar = completedQuestBar

    -- Texts
    self.frame.Texts = {}

    local levelText = elementFrame:CreateFontString(nil, 'OVERLAY')
    levelText:SetFont(LSM:Fetch('font', self.Data:GetValue('font')), self.Data:GetValue('fontSize'),
        self.Data:GetValue('fontFlag'))
    levelText:SetPoint('LEFT', elementFrame, 'TOPLEFT', 3, 0)
    levelText:SetText('Level 67')
    levelText:SetJustifyH('LEFT')
    self.frame.Texts.Level = levelText

    local currentXPText = elementFrame:CreateFontString(nil, 'OVERLAY')
    currentXPText:SetFont(LSM:Fetch('font', self.Data:GetValue('font')), self.Data:GetValue('fontSize'),
        self.Data:GetValue('fontFlag'))
    currentXPText:SetPoint('CENTER', elementFrame, 'TOP', 0, 0)
    currentXPText:SetText('100/1000')
    self.frame.Texts.CurrentXP = currentXPText

    local currentXPPercentText = elementFrame:CreateFontString(nil, 'OVERLAY')
    currentXPPercentText:SetFont(LSM:Fetch('font', self.Data:GetValue('font')), self.Data:GetValue('fontSize'),
        self.Data:GetValue('fontFlag'))
    currentXPPercentText:SetPoint('RIGHT', elementFrame, 'TOPRIGHT', -3, 0)
    currentXPPercentText:SetText('10% (20%)')
    currentXPPercentText:SetJustifyH('RIGHT')
    self.frame.Texts.CurrentXPPercent = currentXPPercentText

    local thisLevelText = elementFrame:CreateFontString(nil, 'OVERLAY')
    thisLevelText:SetFont(LSM:Fetch('font', self.Data:GetValue('font')), self.Data:GetValue('fontSize'),
        self.Data:GetValue('fontFlag'))
    thisLevelText:SetPoint('LEFT', elementFrame, 'BOTTOMLEFT', 3, 0)
    thisLevelText:SetText('This Level: 1h 15m')
    thisLevelText:SetJustifyH('LEFT')
    self.frame.Texts.ThisLevel = thisLevelText

    local predictionText = elementFrame:CreateFontString(nil, 'OVERLAY')
    predictionText:SetFont(LSM:Fetch('font', self.Data:GetValue('font')), self.Data:GetValue('fontSize'),
        self.Data:GetValue('fontFlag'))
    predictionText:SetPoint('CENTER', elementFrame, 'BOTTOM', 0, 0)
    predictionText:SetText('15m - 100.2K XP/h')
    self.frame.Texts.Prediction = predictionText

    self:SetLogic(self.frame)

    editor:RegisterFrameForEditor(self.frame, 'XP Bar', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        self.Data:SetValue('anchorPoint', point)
        self.Data:SetValue('relativeAnchor', relativePoint)
        self.Data:SetValue('xOffset', xOfs)
        self.Data:SetValue('yOffset', yOfs)
        self:Configure()
    end)
end

xpBar.Configure = function(self)
    if (not self.frame) then return end

    local db = self.Data:GetDB()
    EXUI:SetSize(self.frame, db.width, db.height)
    EXUI:SetPoint(self.frame, db.anchorPoint, UIParent, db.relativeAnchor, db.xOffset, db.yOffset)
    self.frame.RestedBar:SetWidth(db.width)
    self.frame.CompletedQuestBar:SetWidth(db.width)
    self.frame.Texts.Level:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)
    self.frame.Texts.CurrentXP:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)
    self.frame.Texts.CurrentXPPercent:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)
    self.frame.Texts.ThisLevel:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)
    self.frame.Texts.Prediction:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)

    self.frame.XPBar:SetStatusBarColor(db.xpBarColor.r, db.xpBarColor.g, db.xpBarColor.b, db.xpBarColor.a)
    self.frame.RestedBar:SetStatusBarColor(db.restedBarColor.r, db.restedBarColor.g, db.restedBarColor.b,
        db.restedBarColor.a)
    self.frame.CompletedQuestBar:SetStatusBarColor(db.completedQuestBarColor.r, db.completedQuestBarColor.g,
        db.completedQuestBarColor.b, db.completedQuestBarColor.a)
end

xpBar.HandleVisibility = function(self)
    if (self.maxLevel > UnitLevel('player') or self.Data:GetValue('showAtMaxLevel')) then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

xpBar.SetLogic = function(self, frame)
    frame:SetScript('OnShow', function(self)
        xpBar:Update('FORCE')
    end)
    frame:SetScript('OnEvent', function(self, event, ...)
        xpBar:Update(event, ...)
    end)
end

xpBar.UpdateValues = function(self)
    if (not self.values.maxXP or self.values.maxXP == 0) then return end
    local now = time()

    local timePlayed = now - (self.timePlayedThisLevelReq - self.values.timePlayedThisLevel)

    self.frame.Texts.Level:SetText('Level ' .. self.values.currentLevel)
    self.frame.Texts.CurrentXP:SetText(EXUI.utils.formatNumberWithCommas(self.values.currentXP) ..
        '/' .. EXUI.utils.formatNumberWithCommas(self.values.maxXP))
    local percentXP = self.values.currentXP / self.values.maxXP * 100
    if (self.values.completedQuestXP > 0) then
        local percentXPWithCompletedQuest = (self.values.currentXP +
            self.values.completedQuestXP) / self.values.maxXP * 100
        self.frame.Texts.CurrentXPPercent:SetText(string.format('%.1f%% (%.1f%%)', percentXP, percentXPWithCompletedQuest))
    else
        self.frame.Texts.CurrentXPPercent:SetText(string.format('%.1f%%', percentXP))
    end
    self.frame.Texts.ThisLevel:SetText('This Level: ' .. EXUI.utils.formatTime(timePlayed, true))

    local remainingXP = self.values.maxXP - self.values.currentXP
    if (self.values.xpPerHour > 0) then
        local remainingTime = remainingXP / self.values.xpPerHour -- time to reach max XP in hours
        local seconds = math.floor(remainingTime * 3600)
        self.frame.Texts.Prediction:SetText(string.format('%s - %s XP/h',
            EXUI.utils.formatTime(seconds, true),
            EXUI.utils.formatNumber(self.values.xpPerHour)))
    else
        self.frame.Texts.Prediction:SetText('N/A XP/h')
    end


    self.frame.XPBar:SetMinMaxValues(0, self.values.maxXP)
    self.frame.XPBar:SetValue(self.values.currentXP, Enum.StatusBarInterpolation.ExponentialEaseOut)
    self.frame.RestedBar:SetMinMaxValues(0, self.values.maxXP)
    self.frame.RestedBar:SetValue(self.values.restedXP, Enum.StatusBarInterpolation.ExponentialEaseOut)
    self.frame.CompletedQuestBar:SetMinMaxValues(0, self.values.maxXP)
    self.frame.CompletedQuestBar:SetValue(self.values.completedQuestXP, Enum.StatusBarInterpolation.ExponentialEaseOut)
end

xpBar.GetCompletedQuestXP = function(self)
    local numQuests = C_QuestLog.GetNumQuestLogEntries()
    local completedQuestXP = 0

    for i = 1, numQuests do
        local questId = C_QuestLog.GetQuestIDForLogIndex(i)

        if (questId > 0) then
            local rewardXP = GetQuestLogRewardXP(questId) or 0
            if (rewardXP > 0) then
                if (C_QuestLog.IsComplete(questId) or C_QuestLog.ReadyForTurnIn(questId)) then
                    completedQuestXP = completedQuestXP + rewardXP
                end
            end
        end
    end

    self.values.completedQuestXP = completedQuestXP
end

xpBar.UpdatePerHourXP = function(self)
    local now = time()
    local timePassed = now - self.startTime
    local xpPerHour = 0
    if (timePassed > 0) then
        xpPerHour = self.values.gainedXP / (timePassed / 3600)
    end
    self.values.xpPerHour = xpPerHour
end

xpBar.Update = function(self, event, ...)
    local now = time()
    if (event == 'PLAYER_ENTERING_WORLD') then
        RequestTimePlayed()
    elseif (event == 'UPDATE_EXPANSION_LEVEL') then -- Expansion Launch
        local arg1, arg2, arg3, arg4 = ...
        local maxExpLevel = max(arg1, arg2, arg3, arg4)
        self.maxLevel = GetMaxLevelForExpansionLevel(maxExpLevel)
        self.startTime = time() -- Restart start time
        self:HandleVisibility()
    elseif (event == 'PLAYER_LEVEL_UP') then
        self:HandleVisibility() -- Check if we need to hide cause we reached max level
    elseif (event == 'TIME_PLAYED_MSG') then
        local _, timePlayedThisLevel = ...
        self.timePlayedThisLevelReq = now
        self.values.timePlayedThisLevel = timePlayedThisLevel
    elseif (event == 'QUEST_LOG_UPDATE' or (event == 'UNIT_QUEST_LOG_CHANGED' and ... == 'player')) then
        self:GetCompletedQuestXP()
    end

    local currentXP = UnitXP('player')
    local maxXP = UnitXPMax('player')

    local gainedXP = currentXP - self.values.currentXP

    if (gainedXP < 0) then
        -- Leveled up
        gainedXP = self.values.maxXP - self.values.currentXP + currentXP
    end

    self.values.currentXP = currentXP
    self.values.maxXP = maxXP
    self.values.gainedXP = self.values.gainedXP + gainedXP

    self:UpdatePerHourXP()

    self.values.restedXP = GetXPExhaustion() or 0
    self.values.currentLevel = UnitLevel('player')

    self:UpdateValues()
end

xpBar.Enable = function(self)
    if (not self.frame) then
        self:CreateFrame()
    end
    self:Configure()

    self.frame:Show()
    FrameUtil.RegisterFrameForEvents(self.frame, self.EVENTS)
    self:GetCompletedQuestXP() -- Event where this is requested will not be called on Update here
    self:Update()
    self:HandleVisibility()
    self.ticker = C_Timer.NewTicker(5, function()
        self:UpdatePerHourXP()
        self:UpdateValues()
    end)
end

xpBar.Disable = function(self)
    if (self.frame) then
        self.frame:Hide()
        self.frame:UnregisterAllEvents()
        self.ticker:Cancel()
        self.ticker = nil
    end
end

xpBar.Data = data:GetControlsForKey('xpBar')
