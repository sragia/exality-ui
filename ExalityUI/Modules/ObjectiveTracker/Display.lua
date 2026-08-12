---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIObjectiveTrackerModule
local objectiveTracker = EXUI:GetModule('objective-tracker')

---@class EXUIObjectiveTrackerDefaults
local defaults = EXUI:GetModule('objective-tracker-defaults')

---@class EXUIObjectiveTrackerData
local trackerData = EXUI:GetModule('objective-tracker-data')

local LSM = LibStub('LibSharedMedia-3.0', true)

---@class EXUIObjectiveTrackerDisplay
local display = EXUI:GetModule('objective-tracker-display')

display.frame = nil
display.chipButtons = {}
display.categoryFrames = {}
display.blockFrames = {}
display.lineFrames = {}
display.progressBarFrames = {}
display.challengeModeBlockFrames = {}
display.scenarioHeaderTimerFrames = {}
display.SCENARIO_CATEGORY_ID = 'scenario'
display.inEncounter = false

display.categoryPool = CreateFramePool('Frame', UIParent, 'BackdropTemplate')
display.blockPool = CreateFramePool('Frame', UIParent, 'BackdropTemplate')
display.linePool = CreateFramePool('Frame', UIParent)
display.progressBarPool = CreateFramePool('Frame', UIParent)
display.poiPool = nil
display.scrollTarget = nil
display.updateScheduled = false

display.POI_TEMPLATE = 'ObjectiveTrackerPOIButtonTemplate'
display.POI_ICON_OFFSET = 22
display.POI_EDGE_INSET = 4
display.SCROLL_LEFT_INSET = 12
display.SCROLL_RIGHT_INSET = 12
display.PROGRESS_BAR_TEXTURE = 'ExalityUI Noisy'
display.FRAME_EDGE_INSET = 4
display.PANEL_CONTENT_INSET = 4

display.COLLAPSE_ICON_MINUS = [[Interface/Addons/ExalityUI/Assets/Images/ObjectiveTracker/minus.png]]
display.COLLAPSE_ICON_PLUS = [[Interface/Addons/ExalityUI/Assets/Images/ObjectiveTracker/plus.png]]
display.COLLAPSE_BUTTON_SIZE = 16
display.COLLAPSE_ICON_SIZE = 10
display.COLLAPSE_BUTTON_RIGHT_INSET = 2
display.SCROLL_WHEEL_STEP = 48
display.SCROLL_SMOOTH_SPEED = 18

display.EVENTS = {
    'PLAYER_ENTERING_WORLD',
    'ZONE_CHANGED',
    'ZONE_CHANGED_NEW_AREA',
    'QUEST_LOG_UPDATE',
    'QUEST_WATCH_LIST_CHANGED',
    'QUEST_ACCEPTED',
    'QUEST_TURNED_IN',
    'QUEST_REMOVED',
    'QUEST_POI_UPDATE',
    'TASK_PROGRESS_UPDATE',
    'CONTENT_TRACKING_UPDATE',
    'TRACKED_ACHIEVEMENT_LIST_CHANGED',
    'TRACKED_ACHIEVEMENT_UPDATE',
    'TRACKED_RECIPE_UPDATE',
    'BAG_UPDATE_DELAYED',
    'CURRENCY_DISPLAY_UPDATE',
    'SCENARIO_UPDATE',
    'SCENARIO_CRITERIA_UPDATE',
    'CHALLENGE_MODE_START',
    'CHALLENGE_MODE_COMPLETED',
    'CHALLENGE_MODE_RESET',
    'WORLD_STATE_TIMER_START',
    'WORLD_STATE_TIMER_STOP',
    'PERKS_ACTIVITIES_TRACKED_LIST_CHANGED',
    'PERKS_ACTIVITIES_TRACKED_UPDATED',
    'SUPER_TRACKING_CHANGED',
    'SUPER_TRACKING_PATH_UPDATED',
    'ENCOUNTER_START',
    'ENCOUNTER_END',
}

function display:OpenBlockDetails(blockData)
    if not blockData then
        return
    end

    if blockData.untrackType == 'quest' and blockData.untrackId then
        if ChatFrameUtil and ChatFrameUtil.TryInsertQuestLinkForQuestID then
            if ChatFrameUtil.TryInsertQuestLinkForQuestID(blockData.untrackId) then
                return
            end
        end
        if QuestMapFrame_OpenToQuestDetails then
            QuestMapFrame_OpenToQuestDetails(blockData.untrackId)
        end
        return
    end

    if blockData.untrackType == 'achievement' and blockData.untrackId then
        if not AchievementFrame then
            AchievementFrame_LoadUI()
        end
        if AchievementFrame_SelectAchievement then
            AchievementFrame_SelectAchievement(blockData.untrackId)
            AchievementFrame:Show()
        end
    end
end

function display:HandleBlockTitleClick(blockData, mouseButton)
    if not blockData then
        return
    end

    if mouseButton == 'MiddleButton' then
        if blockData.canUntrack then
            trackerData:UntrackBlock(blockData)
            objectiveTracker:Update()
        end
        return
    end

    if blockData.untrackType ~= 'quest' and blockData.untrackType ~= 'achievement' then
        return
    end

    if InCombatLockdown() then
        return
    end

    self:OpenBlockDetails(blockData)
end

function display:GetTextAlign(db)
    if db.textAlign == 'RIGHT' then
        return 'RIGHT'
    end
    return 'LEFT'
end

function display:ApplyHeaderTitleLayout(title, header, db, padX, padY, minimizeButton, hideCollapseButton)
    local align = self:GetTextAlign(db)
    title:ClearAllPoints()
    title:SetPoint('TOP', header, 'TOP', 0, -padY)
    title:SetPoint('BOTTOM', header, 'BOTTOM', 0, padY)
    title:SetPoint('LEFT', header, 'LEFT', padX, 0)
    if hideCollapseButton or not minimizeButton or not minimizeButton:IsShown() then
        title:SetPoint('RIGHT', header, 'RIGHT', -padX, 0)
    else
        title:SetPoint('RIGHT', minimizeButton, 'LEFT', -4, 0)
    end
    title:SetJustifyH(align)
end

function display:GetCategoryCollapseButtonRightInset(db, padX)
    if db.customHeaderStyle then
        return padX
    end
    return self.COLLAPSE_BUTTON_RIGHT_INSET
end

function display:GetMaxScroll()
    if not self.frame then
        return 0
    end
    local scroll = self.frame.scroll
    local content = self.frame.content
    return math.max(0, content:GetHeight() - scroll:GetHeight())
end

function display:ClampScroll(value)
    return math.max(0, math.min(self:GetMaxScroll(), value or 0))
end

function display:GetScrollPosition()
    if not self.frame then
        return 0
    end
    return self.frame.scroll:GetVerticalScroll()
end

function display:StopSmoothScroll()
    if self.frame and self.frame.scroll then
        self.frame.scroll:SetScript('OnUpdate', nil)
    end
end

function display:StartSmoothScroll()
    local scroll = self.frame.scroll
    if scroll:GetScript('OnUpdate') then
        return
    end
    scroll:SetScript('OnUpdate', function(_, elapsed)
        display:UpdateSmoothScroll(elapsed)
    end)
end

function display:UpdateSmoothScroll(elapsed)
    local scroll = self.frame.scroll
    local target = self:ClampScroll(self.scrollTarget)
    self.scrollTarget = target
    local current = scroll:GetVerticalScroll()
    if math.abs(current - target) < 0.5 then
        scroll:SetVerticalScroll(target)
        self:StopSmoothScroll()
        return
    end
    scroll:SetVerticalScroll(current + (target - current) * math.min(1, elapsed * self.SCROLL_SMOOTH_SPEED))
end

function display:SetScrollPosition(value, immediate)
    if not self.frame then
        return
    end
    local scroll = self.frame.scroll
    local target = self:ClampScroll(value)
    self.scrollTarget = target
    if immediate or math.abs(scroll:GetVerticalScroll() - target) < 0.5 then
        scroll:SetVerticalScroll(target)
        self:StopSmoothScroll()
        return
    end
    self:StartSmoothScroll()
end

function display:ScrollBy(delta)
    local current = self.scrollTarget
    if current == nil then
        current = self:GetScrollPosition()
    end
    self:SetScrollPosition(current + delta)
end

function display:BindScrollWheel(frame)
    frame:EnableMouseWheel(true)
    frame:SetScript('OnMouseWheel', function(_, delta)
        display:ScrollBy(-delta * display.SCROLL_WHEEL_STEP)
    end)
end

function display:GetFont(name, size, flag)
    local path = LSM and LSM:Fetch('font', name) or ''
    return path, size, flag
end

function display:GetSpacing(db)
    return defaults.SPACING_DEFAULTS
end

function display:GetCategorySpacing(db)
    local spacing = db.categorySpacing
    if spacing ~= nil then
        return spacing
    end
    return self:GetSpacing(db).moduleSpacing
end

function display:GetCategoryHeaderHeight(db, fontSize, fontFlag)
    local spacing = self:GetSpacing(db)
    local padY = spacing.headerPaddingY or 2
    local outlineExtra = fontFlag and fontFlag:find('OUTLINE', 1, true) and 2 or 0
    return math.max(spacing.headerHeight, fontSize + padY * 2 + outlineExtra)
end

function display:GetColor(db, key)
    local colors = db.colors or defaults.DEFAULT_COLORS
    local color = colors[key]
    if not color then
        if key == 'CategoryHeader' or key == 'BlockHeader' then
            color = colors.Header
        elseif key == 'CategoryHeaderHighlight' or key == 'BlockHeaderHighlight' then
            color = colors.HeaderHighlight
        end
    end
    return color or defaults.DEFAULT_COLORS[key] or defaults.DEFAULT_COLORS.Normal
end

function display:ReleaseLayout()
    self:StopChallengeModeTimerWatch()
    self:StopScenarioHeaderTimerWatch()

    for _, frame in ipairs(self.progressBarFrames) do
        self.progressBarPool:Release(frame)
    end
    for _, frame in ipairs(self.lineFrames) do
        self.linePool:Release(frame)
    end
    for _, frame in ipairs(self.blockFrames) do
        frame.challengeModeTimer = nil
        frame.scenarioHeaderTimer = nil
        self:ReleaseBlockPOI(frame)
        self.blockPool:Release(frame)
    end
    for _, frame in ipairs(self.categoryFrames) do
        self.categoryPool:Release(frame)
    end
    wipe(self.lineFrames)
    wipe(self.progressBarFrames)
    wipe(self.blockFrames)
    wipe(self.categoryFrames)
    wipe(self.challengeModeBlockFrames)
    wipe(self.scenarioHeaderTimerFrames)
end

function display:EnsurePOIPool()
    if self.poiPool then
        return
    end
    local template = self.POI_TEMPLATE
    if C_XMLUtil and C_XMLUtil.GetTemplateInfo and not C_XMLUtil.GetTemplateInfo(template) then
        template = 'POIButtonTemplate'
    end
    self.poiPool = CreateFramePool('Button', UIParent, template)
end

function display:ShouldShowQuestPOI(db)
    if db.hideQuestPOI then
        return false
    end
    return GetCVarBool('questPOI')
end

function display:ReleaseBlockPOI(frame)
    if frame.poiButton and self.poiPool then
        self.poiPool:Release(frame.poiButton)
        frame.poiButton = nil
    end
end

function display:GetQuestPOIStyle(block)
    if block.isWorldQuest then
        return POIButtonUtil.Style.WorldQuest
    elseif block.isComplete then
        return POIButtonUtil.Style.QuestComplete
    end
    return POIButtonUtil.Style.QuestInProgress
end

function display:AttachQuestPOI(frame, block, db)
    self:ReleaseBlockPOI(frame)
    if block.untrackType ~= 'quest' or not self:ShouldShowQuestPOI(db) then
        return 0
    end
    if not POIButtonUtil then
        return 0
    end
    self:EnsurePOIPool()
    local poiButton = self.poiPool:Acquire()
    poiButton:SetParent(frame)
    poiButton:SetFrameLevel(frame:GetFrameLevel() + 2)
    poiButton:SetQuestID(block.untrackId)
    poiButton:SetStyle(self:GetQuestPOIStyle(block))
    poiButton:SetSelected(block.isSuperTracked)
    if block.isWorldQuest and poiButton.SetPingWorldMap then
        poiButton:SetPingWorldMap(true)
    end
    poiButton:UpdateButtonStyle()
    poiButton:Show()
    frame.poiButton = poiButton
    return self.POI_ICON_OFFSET
end

function display:GetBlockTitleColor(block, db)
    if block.isSuperTracked then
        return db.superTrackColor
    end
    return self:GetColor(db, 'BlockHeader')
end

function display:SetBlockTitleColor(frame, block, db)
    local color = self:GetBlockTitleColor(block, db)
    frame.title:SetTextColor(color.r, color.g, color.b)
end

function display:GetProgressBarTexture()
    if LSM then
        return LSM:Fetch('statusbar', self.PROGRESS_BAR_TEXTURE) or EXUI.const.textures.frame.solidBg
    end
    return [[Interface/Addons/ExalityUI/Assets/Images/StatusBar/noisy.tga]]
end

function display:GetDefaultProgressBarColors()
    local theme = EXUI.const.theme
    return {
        fillColor = {
            r = theme.accent[1],
            g = theme.accent[2],
            b = theme.accent[3],
            a = theme.accent[4] or 1,
        },
        backgroundColor = {
            r = theme.backgroundDeep[1],
            g = theme.backgroundDeep[2],
            b = theme.backgroundDeep[3],
            a = theme.backgroundDeep[4] or 1,
        },
        borderColor = {
            r = theme.border[1],
            g = theme.border[2],
            b = theme.border[3],
            a = theme.border[4] or 1,
        },
    }
end

function display:GetProgressBarSettings(db)
    local themeColors = self:GetDefaultProgressBarColors()
    return {
        height = db.progressBarHeight or 12,
        borderThickness = db.progressBarBorderThickness or 1,
        fillColor = db.progressBarFillColor or themeColors.fillColor,
        backgroundColor = db.progressBarBackgroundColor or themeColors.backgroundColor,
        borderColor = db.progressBarBorderColor or themeColors.borderColor,
    }
end

function display:GetProgressBarFrameHeight(db, region)
    local settings = self:GetProgressBarSettings(db)
    local borderThickness = math.max(0, settings.borderThickness)
    return EXUI:ScalePixels(settings.height + borderThickness * 2, region)
end

function display:ApplyProgressBarContentInsets(progressFrame, db)
    local settings = self:GetProgressBarSettings(db)
    local border = progressFrame.border
    local borderThickness = math.max(0, settings.borderThickness)
    local contentInset = borderThickness > 0 and EXUI:GetBorderInset(border, borderThickness) or 0

    progressFrame.bar:ClearAllPoints()
    progressFrame.bar:SetPoint('TOPLEFT', border, 'TOPLEFT', contentInset, -contentInset)
    progressFrame.bar:SetPoint('BOTTOMRIGHT', border, 'BOTTOMRIGHT', -contentInset, 0)
end

function display:FinalizeProgressBarLayout(progressFrame, db)
    if not progressFrame.border then
        return
    end

    local settings = self:GetProgressBarSettings(db)
    local borderThickness = math.max(0, settings.borderThickness)

    EXUI:SnapFrameToPixels(progressFrame)
    EXUI:SnapFrameToPixels(progressFrame.border)

    if progressFrame.border.PPBorder and borderThickness > 0 then
        progressFrame.border.PPBorder:SetBorderThickness(borderThickness)
    end

    self:ApplyProgressBarContentInsets(progressFrame, db)
end

function display:GetQuestProgressPercent(questID)
    if not questID then
        return 0
    end
    if GetQuestProgressBarPercent then
        return GetQuestProgressBarPercent(questID) or 0
    end
    if C_TaskQuest and C_TaskQuest.GetQuestProgressBarInfo then
        local progress = C_TaskQuest.GetQuestProgressBarInfo(questID)
        if progress then
            if progress <= 1 then
                return progress * 100
            end
            return progress
        end
    end
    return 0
end

function display:AcquireProgressBar(parent, width, indent, isRightAlign, db)
    local settings = self:GetProgressBarSettings(db)
    local borderThickness = math.max(0, settings.borderThickness)
    local totalLogicalHeight = settings.height + borderThickness * 2

    local frame = self.progressBarPool:Acquire()
    frame:SetParent(parent)
    frame:Show()
    frame:SetWidth(width)
    EXUI:SetHeight(frame, totalLogicalHeight)

    if not frame.border then
        frame.border = CreateFrame('Frame', nil, frame)
        frame.border.bg = frame.border:CreateTexture(nil, 'BACKGROUND')
        frame.border.bg:SetTexture(EXUI.const.textures.frame.solidBg)
        frame.border.bg:SetAllPoints()
    end
    frame.border:SetParent(frame)
    frame.border:ClearAllPoints()
    if isRightAlign then
        EXUI:SetPoint(frame.border, 'TOPLEFT', frame, 'TOPLEFT', 0, 0)
        EXUI:SetPoint(frame.border, 'BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -indent, 0)
    else
        EXUI:SetPoint(frame.border, 'TOPLEFT', frame, 'TOPLEFT', indent, 0)
        EXUI:SetPoint(frame.border, 'BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
    end

    local bg = settings.backgroundColor
    frame.border.bg:SetVertexColor(bg.r, bg.g, bg.b, bg.a or 1)

    if borderThickness > 0 then
        if not frame.border.PPBorder then
            frame.border.PPBorder = EXUI:AddPixelPerfectBorder(frame.border, borderThickness, { register = false })
        end
        local borderColor = settings.borderColor
        frame.border.PPBorder:SetBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        frame.border.PPBorder.Top:Show()
        frame.border.PPBorder.Bottom:Show()
        frame.border.PPBorder.Left:Show()
        frame.border.PPBorder.Right:Show()
    elseif frame.border.PPBorder then
        frame.border.PPBorder.Top:Hide()
        frame.border.PPBorder.Bottom:Hide()
        frame.border.PPBorder.Left:Hide()
        frame.border.PPBorder.Right:Hide()
    end

    frame.bar = frame.bar or CreateFrame('StatusBar', nil, frame.border)
    frame.bar:SetParent(frame.border)
    frame.bar:SetMinMaxValues(0, 100)
    frame.bar:SetStatusBarTexture(self:GetProgressBarTexture())
    local fill = settings.fillColor
    frame.bar:SetStatusBarColor(fill.r, fill.g, fill.b, fill.a or 1)

    frame.label = frame.label or frame.bar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    frame.label:SetParent(frame.bar)
    frame.label:ClearAllPoints()
    local align = self:GetTextAlign(db)
    local labelPad = EXUI:ScalePixel(4, frame.border)
    frame.label:SetJustifyH(align)
    frame.label:SetPoint('TOP', frame.bar, 'TOP', 0, 0)
    frame.label:SetPoint('BOTTOM', frame.bar, 'BOTTOM', 0, 0)
    frame.label:SetPoint('LEFT', frame.bar, 'LEFT', labelPad, 0)
    frame.label:SetPoint('RIGHT', frame.bar, 'RIGHT', -labelPad, 0)
    local lineFontPath, lineFontSize, lineFontFlag = self:GetFont(db.lineFont, db.lineFontSize, db.lineFontFlag)
    frame.label:SetFont(lineFontPath, lineFontSize, lineFontFlag)
    local labelColor = self:GetColor(db, 'Normal')
    frame.label:SetTextColor(labelColor.r, labelColor.g, labelColor.b)

    return frame
end

function display:SetProgressBarPercent(progressFrame, percent, labelText)
    percent = math.max(0, math.min(100, percent or 0))
    progressFrame.bar:SetValue(percent)
    if labelText then
        progressFrame.label:SetText(labelText)
    else
        progressFrame.label:SetFormattedText(PERCENTAGE_STRING or '%d%%', percent)
    end
end

function display:AppendBlockRow(frame, element, blockHeight, spacing, db)
    element:ClearAllPoints()
    local yOffset = blockHeight + spacing.lineSpacing
    EXUI:SetPoint(element, 'TOPLEFT', frame, 'TOPLEFT', 0, -yOffset)
    EXUI:SetPoint(element, 'TOPRIGHT', frame, 'TOPRIGHT', 0, -yOffset)
    EXUI:SnapFrameToPixels(element)

    if element.border and element.bar and db then
        self:FinalizeProgressBarLayout(element, db)
    end

    return blockHeight + spacing.lineSpacing + element:GetHeight()
end

function display:FormatColorCode(color)
    return CreateColor(color.r, color.g, color.b, color.a or 1)
end

function display:GetScenarioHeaderTimeRemaining(headerTimer)
    if not headerTimer or not headerTimer.widgetID
        or not C_UIWidgetManager
        or not C_UIWidgetManager.GetScenarioHeaderTimerWidgetVisualizationInfo
        or not Enum
        or not Enum.WidgetShownState then
        return nil
    end

    local info = C_UIWidgetManager.GetScenarioHeaderTimerWidgetVisualizationInfo(headerTimer.widgetID)
    if not info or info.shownState == Enum.WidgetShownState.Hidden then
        return nil
    end

    local timerValue = math.max(info.timerMin, math.min(info.timerMax, info.timerValue))
    return math.max(0, timerValue - info.timerMin)
end

function display:SetScenarioStageLineText(stageLine, stageLabel, timeRemaining, db)
    if not stageLine or not stageLine.text then
        return
    end

    local stageColor = self:GetColor(db, 'BlockHeader')
    if timeRemaining == nil then
        stageLine.text:SetText(stageLabel or '')
        stageLine.text:SetTextColor(stageColor.r, stageColor.g, stageColor.b)
        return
    end

    local timerColor = self:GetColor(db, 'NormalHighlight')
    local timerText = SecondsToClock(timeRemaining)
    if stageLabel and stageLabel ~= '' then
        stageLine.text:SetText(self:FormatColorCode(timerColor):WrapTextInColorCode(timerText)
            .. ' '
            .. self:FormatColorCode(stageColor):WrapTextInColorCode(stageLabel))
    else
        stageLine.text:SetText(self:FormatColorCode(timerColor):WrapTextInColorCode(timerText))
    end
    stageLine.text:SetTextColor(1, 1, 1)
end

function display:AppendScenarioStage(frame, block, db, blockHeight, blockWidth, lineIndent, spacing)
    local stage = block.stage
    if not stage then
        return blockHeight
    end

    local showStage = stage.total and stage.total > 1
    local headerTimer = stage.headerTimer
    local timeRemaining = headerTimer and (headerTimer.timeRemaining or self:GetScenarioHeaderTimeRemaining(headerTimer))
    local hasTimer = timeRemaining ~= nil
    if not showStage and not hasTimer then
        return blockHeight
    end

    local align = self:GetTextAlign(db)
    local isRightAlign = align == 'RIGHT'
    local lineTextWidth = blockWidth - lineIndent

    local headerFontPath, headerFontSize, headerFontFlag = self:GetFont(db.blockHeaderFont, db.blockHeaderFontSize, db.blockHeaderFontFlag)
    local lineFontPath, lineFontSize, lineFontFlag = self:GetFont(db.lineFont, db.lineFontSize, db.lineFontFlag)

    local stageLabel
    if showStage then
        stageLabel = string.format('%s %d/%d', STAGE or 'Stage', stage.current or 0, stage.total)
    end

    if showStage or hasTimer then
        local stageLine = self.linePool:Acquire()
        stageLine:SetParent(frame)
        stageLine:Show()
        stageLine:SetWidth(blockWidth)
        stageLine.text = stageLine.text or stageLine:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        stageLine.text:SetParent(stageLine)
        stageLine.text:ClearAllPoints()
        if isRightAlign then
            stageLine.text:SetPoint('TOPLEFT', stageLine, 'TOPLEFT', 0, 0)
            stageLine.text:SetPoint('TOPRIGHT', stageLine, 'TOPRIGHT', -lineIndent, 0)
        else
            stageLine.text:SetPoint('TOPLEFT', stageLine, 'TOPLEFT', lineIndent, 0)
            stageLine.text:SetPoint('TOPRIGHT', stageLine, 'TOPRIGHT', 0, 0)
        end
        stageLine.text:SetJustifyH(align)
        stageLine.text:SetWordWrap(true)
        stageLine.text:SetMaxLines(0)
        stageLine.text:SetNonSpaceWrap(false)
        stageLine.text:SetFont(headerFontPath, headerFontSize, headerFontFlag)
        self:SetScenarioStageLineText(stageLine, stageLabel, hasTimer and timeRemaining or nil, db)

        local stageHeight = self:MeasureFontString(stageLine.text, headerFontSize, lineTextWidth, headerFontFlag)
        stageLine:SetHeight(stageHeight)
        blockHeight = self:AppendBlockRow(frame, stageLine, blockHeight, spacing)
        self.lineFrames[#self.lineFrames + 1] = stageLine

        if hasTimer and headerTimer and headerTimer.widgetID then
            frame.scenarioHeaderTimer = {
                widgetID = headerTimer.widgetID,
                stageLabel = stageLabel,
                stageLine = stageLine,
            }
            self.scenarioHeaderTimerFrames[#self.scenarioHeaderTimerFrames + 1] = frame.scenarioHeaderTimer
        end
    end

    local description = stage.description
    if description and description ~= '' then
        local descLine = self.linePool:Acquire()
        descLine:SetParent(frame)
        descLine:Show()
        descLine:SetWidth(blockWidth)
        descLine.text = descLine.text or descLine:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
        descLine.text:SetParent(descLine)
        descLine.text:ClearAllPoints()
        if isRightAlign then
            descLine.text:SetPoint('TOPLEFT', descLine, 'TOPLEFT', 0, 0)
            descLine.text:SetPoint('TOPRIGHT', descLine, 'TOPRIGHT', -lineIndent, 0)
        else
            descLine.text:SetPoint('TOPLEFT', descLine, 'TOPLEFT', lineIndent, 0)
            descLine.text:SetPoint('TOPRIGHT', descLine, 'TOPRIGHT', 0, 0)
        end
        descLine.text:SetJustifyH(align)
        descLine.text:SetWordWrap(true)
        descLine.text:SetMaxLines(0)
        descLine.text:SetNonSpaceWrap(false)
        descLine.text:SetFont(lineFontPath, lineFontSize, lineFontFlag)
        descLine.text:SetText(description)
        local descColor = self:GetColor(db, 'Normal')
        descLine.text:SetTextColor(descColor.r, descColor.g, descColor.b)

        local descHeight = self:MeasureFontString(descLine.text, lineFontSize, lineTextWidth, lineFontFlag)
        descLine:SetHeight(descHeight)
        blockHeight = self:AppendBlockRow(frame, descLine, blockHeight, spacing)
        self.lineFrames[#self.lineFrames + 1] = descLine
    end

    if stage.weightedProgress ~= nil then
        local progressFrame = self:AcquireProgressBar(frame, blockWidth, lineIndent, isRightAlign, db)
        self:SetProgressBarPercent(progressFrame, stage.weightedProgress)
        blockHeight = self:AppendBlockRow(frame, progressFrame, blockHeight, spacing, db)
        self.progressBarFrames[#self.progressBarFrames + 1] = progressFrame
    end

    return blockHeight
end

function display:UpdateScenarioHeaderTimers()
    local db = objectiveTracker.Data:GetDB()
    local needsRebuild = false

    for _, timer in ipairs(self.scenarioHeaderTimerFrames) do
        local timeRemaining = self:GetScenarioHeaderTimeRemaining(timer)
        if timeRemaining == nil then
            needsRebuild = true
        else
            self:SetScenarioStageLineText(timer.stageLine, timer.stageLabel, timeRemaining, db)
        end
    end

    if needsRebuild then
        self:RequestUpdate()
    end
end

function display:StartScenarioHeaderTimerWatch()
    if #self.scenarioHeaderTimerFrames == 0 then
        self:StopScenarioHeaderTimerWatch()
        return
    end

    if self.scenarioHeaderTimerTicker then
        self:UpdateScenarioHeaderTimers()
        return
    end

    self.scenarioHeaderTimerTicker = C_Timer.NewTicker(0.1, function()
        display:UpdateScenarioHeaderTimers()
    end)
    self:UpdateScenarioHeaderTimers()
end

function display:StopScenarioHeaderTimerWatch()
    if self.scenarioHeaderTimerTicker then
        self.scenarioHeaderTimerTicker:Cancel()
        self.scenarioHeaderTimerTicker = nil
    end
end

function display:GetChallengeModeTimeLeft(challengeMode)
    if not challengeMode or not challengeMode.timerID or not challengeMode.timeLimit then
        return nil
    end

    local _, elapsedTime = GetWorldElapsedTime(challengeMode.timerID)
    elapsedTime = elapsedTime or 0
    return math.max(0, challengeMode.timeLimit - math.floor(elapsedTime))
end

function display:UpdateChallengeModeTimerLabel(progressFrame, timeLeft, db)
    if not progressFrame or not progressFrame.label then
        return
    end

    timeLeft = timeLeft or 0
    progressFrame.label:SetText(SecondsToClock(timeLeft))
    local colorKey = (timeLeft == 0) and 'TimeLeft' or 'NormalHighlight'
    local color = self:GetColor(db, colorKey)
    progressFrame.label:SetTextColor(color.r, color.g, color.b)
end

function display:UpdateChallengeModeTimers()
    local db = objectiveTracker.Data:GetDB()

    for _, blockFrame in ipairs(self.challengeModeBlockFrames) do
        local timer = blockFrame.challengeModeTimer
        if timer and timer.progressFrame then
            local timeLeft = self:GetChallengeModeTimeLeft(timer)
            if timeLeft ~= nil then
                if timer.timeLimit and timer.timeLimit > 0 then
                    timer.progressFrame.bar:SetValue((timeLeft / timer.timeLimit) * 100)
                end
                self:UpdateChallengeModeTimerLabel(timer.progressFrame, timeLeft, db)
            end
        end
    end
end

function display:StartChallengeModeTimerWatch()
    if #self.challengeModeBlockFrames == 0 then
        self:StopChallengeModeTimerWatch()
        return
    end

    if self.challengeModeTicker then
        self:UpdateChallengeModeTimers()
        return
    end

    self.challengeModeTicker = C_Timer.NewTicker(0.1, function()
        display:UpdateChallengeModeTimers()
    end)
    self:UpdateChallengeModeTimers()
end

function display:StopChallengeModeTimerWatch()
    if self.challengeModeTicker then
        self.challengeModeTicker:Cancel()
        self.challengeModeTicker = nil
    end
end

function display:AppendChallengeModeSection(frame, block, db, blockHeight, blockWidth, lineIndent, spacing)
    local challengeMode = block.challengeMode
    if not challengeMode then
        return blockHeight
    end

    local align = self:GetTextAlign(db)
    local isRightAlign = align == 'RIGHT'
    local lineTextWidth = blockWidth - lineIndent
    local headerFontPath, headerFontSize, headerFontFlag = self:GetFont(db.blockHeaderFont, db.blockHeaderFontSize, db.blockHeaderFontFlag)
    local lineTextWidth = blockWidth - lineIndent

    local levelLine = self.linePool:Acquire()
    levelLine:SetParent(frame)
    levelLine:Show()
    levelLine:SetWidth(blockWidth)
    levelLine.text = levelLine.text or levelLine:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    levelLine.text:SetParent(levelLine)
    levelLine.text:ClearAllPoints()
    if isRightAlign then
        levelLine.text:SetPoint('TOPLEFT', levelLine, 'TOPLEFT', 0, 0)
        levelLine.text:SetPoint('TOPRIGHT', levelLine, 'TOPRIGHT', -lineIndent, 0)
    else
        levelLine.text:SetPoint('TOPLEFT', levelLine, 'TOPLEFT', lineIndent, 0)
        levelLine.text:SetPoint('TOPRIGHT', levelLine, 'TOPRIGHT', 0, 0)
    end
    levelLine.text:SetJustifyH(align)
    levelLine.text:SetWordWrap(false)
    levelLine.text:SetFont(headerFontPath, headerFontSize, headerFontFlag)
    levelLine.text:SetText(challengeMode.levelText or '')
    local levelColor = self:GetColor(db, 'BlockHeader')
    levelLine.text:SetTextColor(levelColor.r, levelColor.g, levelColor.b)

    local levelHeight = self:MeasureFontString(levelLine.text, headerFontSize, lineTextWidth, headerFontFlag)
    levelLine:SetHeight(levelHeight)
    blockHeight = self:AppendBlockRow(frame, levelLine, blockHeight, spacing)
    self.lineFrames[#self.lineFrames + 1] = levelLine

    local progressFrame
    if challengeMode.timeLimit and challengeMode.timeLimit > 0 then
        local timeLeft = self:GetChallengeModeTimeLeft(challengeMode)
        local displayTime = timeLeft or challengeMode.timeLimit
        progressFrame = self:AcquireProgressBar(frame, blockWidth, lineIndent, isRightAlign, db)
        progressFrame.bar:SetValue((displayTime / challengeMode.timeLimit) * 100)
        self:UpdateChallengeModeTimerLabel(progressFrame, displayTime, db)
        blockHeight = self:AppendBlockRow(frame, progressFrame, blockHeight, spacing, db)
        self.progressBarFrames[#self.progressBarFrames + 1] = progressFrame
    end

    frame.challengeModeTimer = {
        timerID = challengeMode.timerID,
        timeLimit = challengeMode.timeLimit,
        progressFrame = progressFrame,
    }
    self.challengeModeBlockFrames[#self.challengeModeBlockFrames + 1] = frame

    return blockHeight
end

function display:ApplyCollapseButtonStyle(button)
    local bg = EXUI.const.theme.backgroundLight
    local border = EXUI.const.theme.border
    button:SetBackdropColor(bg[1], bg[2], bg[3], 0.9)
    button:SetBackdropBorderColor(border[1], border[2], border[3], 1)
end

function display:StyleCollapseButtonIcon(icon)
    icon:SetTexCoord(0, 1, 0, 1)
    local white = EXUI.const.theme.white
    icon:SetVertexColor(white[1], white[2], white[3], 1)
end

function display:CreateMinimizeButton(parent)
    local button = CreateFrame('Button', nil, parent, 'BackdropTemplate')
    button:RegisterForClicks('LeftButtonUp')
    button:SetSize(self.COLLAPSE_BUTTON_SIZE, self.COLLAPSE_BUTTON_SIZE)
    button:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    self:ApplyCollapseButtonStyle(button)

    button.iconMinus = button:CreateTexture(nil, 'ARTWORK')
    button.iconMinus:SetTexture(self.COLLAPSE_ICON_MINUS)
    button.iconMinus:SetSize(self.COLLAPSE_ICON_SIZE, self.COLLAPSE_ICON_SIZE)
    button.iconMinus:SetPoint('CENTER')
    self:StyleCollapseButtonIcon(button.iconMinus)

    button.iconPlus = button:CreateTexture(nil, 'ARTWORK')
    button.iconPlus:SetTexture(self.COLLAPSE_ICON_PLUS)
    button.iconPlus:SetSize(self.COLLAPSE_ICON_SIZE, self.COLLAPSE_ICON_SIZE)
    button.iconPlus:SetPoint('CENTER')
    self:StyleCollapseButtonIcon(button.iconPlus)
    button.iconPlus:Hide()

    function button:SetCollapsedState(collapsed)
        self.iconMinus:SetShown(not collapsed)
        self.iconPlus:SetShown(collapsed)
    end

    button:SetScript('OnEnter', function(btn)
        local hover = EXUI.const.theme.accentLight
        btn:SetBackdropColor(hover[1], hover[2], hover[3], 0.85)
    end)
    button:SetScript('OnLeave', function(btn)
        display:ApplyCollapseButtonStyle(btn)
    end)
    button:SetScript('OnMouseDown', function(btn)
        local pressed = EXUI.const.theme.backgroundDeep
        btn:SetBackdropColor(pressed[1], pressed[2], pressed[3], 0.9)
    end)
    button:SetScript('OnMouseUp', function(btn)
        if btn:IsMouseOver() then
            local hover = EXUI.const.theme.accentLight
            btn:SetBackdropColor(hover[1], hover[2], hover[3], 0.85)
        else
            display:ApplyCollapseButtonStyle(btn)
        end
    end)

    return button
end

function display:IsCategoryCollapsed(categoryId, db)
    return db.collapsedModules and db.collapsedModules[categoryId] == true
end

function display:ToggleCategoryCollapsed(categoryId)
    if not categoryId then
        return
    end
    local db = objectiveTracker.Data:GetDB()
    local collapsedModules = EXUI.utils.deepCloneTable(db.collapsedModules or {})
    if collapsedModules[categoryId] then
        collapsedModules[categoryId] = nil
    else
        collapsedModules[categoryId] = true
    end
    objectiveTracker.Data:SetValue('collapsedModules', collapsedModules)
    if PlaySound then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    objectiveTracker:Update()
end

function display:ToggleContainerCollapsed()
    local db = objectiveTracker.Data:GetDB()
    objectiveTracker.Data:SetValue('containerCollapsed', not db.containerCollapsed)
    if PlaySound then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    objectiveTracker:Update()
end

function display:GetCollapsedFrameHeight(db)
    if db then
        local _, fontSize, fontFlag = self:GetFont(db.containerFont, db.containerFontSize, db.containerFontFlag)
        return self:GetCategoryHeaderHeight(db, fontSize, fontFlag)
            + (self.FRAME_EDGE_INSET + self.PANEL_CONTENT_INSET) * 2
    end
    return 32
end

function display:ApplyFramePositionAndSize(db, frameHeight)
    local frame = self.frame
    if not frame then
        return
    end

    local prevTop = frame:GetTop()
    local scaledHeight = EXUI:ScalePixel(frameHeight, frame)
    local previousHeight = frame:GetHeight()
    local heightChanged = not previousHeight or math.abs(previousHeight - scaledHeight) > 0.01

    EXUI:SetSize(frame, db.width, frameHeight)
    EXUI:SetPoint(frame, db.anchorPoint, UIParent, db.relativeAnchor, db.xOffset, db.yOffset)

    if heightChanged and prevTop then
        local newTop = frame:GetTop()
        if newTop then
            local deltaY = prevTop - newTop
            if math.abs(deltaY) > 0.01 then
                local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
                yOfs = (yOfs or 0) + deltaY
                frame:ClearAllPoints()
                EXUI:SetPoint(frame, point, relativeTo or UIParent, relativePoint or point, xOfs, yOfs)
                if not objectiveTracker.editorShowing then
                    objectiveTracker.Data:SetValue('anchorPoint', point)
                    objectiveTracker.Data:SetValue('relativeAnchor', relativePoint)
                    objectiveTracker.Data:SetValue('xOffset', xOfs)
                    objectiveTracker.Data:SetValue('yOffset', yOfs)
                end
            end
        end
    end
end

function display:CreateMainFrame()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame('Frame', 'EXUIObjectiveTrackerFrame', UIParent, 'BackdropTemplate')
    frame:SetFrameStrata('LOW')

    frame.background = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    frame.background:SetFrameLevel(0)
    self:ApplyBackgroundPoints(frame)

    frame.header = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    frame.header:SetHeight(24)

    frame.title = frame.header:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.title:SetPoint('LEFT', frame.header, 'LEFT', 4, 0)
    frame.title:SetJustifyH('LEFT')

    frame.minimizeButton = self:CreateMinimizeButton(frame.header)
    frame.minimizeButton:SetPoint('RIGHT', frame.header, 'RIGHT', -self.COLLAPSE_BUTTON_RIGHT_INSET, 0)
    frame.minimizeButton:SetPoint('TOP', frame.header, 'TOP', 0, 0)
    frame.minimizeButton:SetScript('OnClick', function()
        display:ToggleContainerCollapsed()
    end)
    frame.title:SetPoint('RIGHT', frame.minimizeButton, 'LEFT', -4, 0)

    frame.chipBar = CreateFrame('Frame', nil, frame)
    frame.chipBar:SetHeight(18)

    frame.scroll = CreateFrame('ScrollFrame', nil, frame, 'BackdropTemplate')
    frame.scroll:SetClipsChildren(true)

    frame.content = CreateFrame('Frame', nil, frame.scroll)
    frame.scroll:SetScrollChild(frame.content)

    self:BindScrollWheel(frame)
    self:BindScrollWheel(frame.scroll)

    self.frame = frame
    return frame
end

function display:EnsureChipButtons()
    if self.chipButtons.all then
        return
    end

    local function createChip(parent, label, filterId, width, fullLabel)
        local button = CreateFrame('Button', nil, parent, 'BackdropTemplate')
        button:SetSize(width or 28, 16)
        button.fullLabel = fullLabel or label
        button.filterId = filterId
        button.text = button:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        button.text:SetPoint('CENTER')
        button.text:SetText(label)
        button:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
        })
        button:SetScript('OnClick', function()
            objectiveTracker.Data:SetValue('activeFilter', filterId)
            display:RefreshChipStates()
            objectiveTracker:Update()
        end)
        button:SetScript('OnEnter', function(btn)
            GameTooltip:SetOwner(btn, 'ANCHOR_BOTTOM')
            GameTooltip:SetText(btn.fullLabel or label, 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript('OnLeave', function()
            GameTooltip:Hide()
        end)
        return button
    end

    local bar = self.frame.chipBar
    self.chipButtons.all = createChip(bar, 'All', defaults.FILTER_ALL, 28, 'All Categories')
    self.chipButtons.all:SetPoint('LEFT', bar, 'LEFT', 0, 0)

    local prev = self.chipButtons.all
    for _, entry in ipairs(defaults.MODULE_ENTRIES) do
        local button = createChip(bar, entry.shortLabel or entry.label, entry.id,
            math.max(28, (#(entry.shortLabel or entry.label) * 7) + 10), entry.label)
        button:SetPoint('LEFT', prev, 'RIGHT', 2, 0)
        self.chipButtons[entry.id] = button
        prev = button
    end
end

function display:RefreshChipStates()
    local db = objectiveTracker.Data:GetDB()
    if not self.frame then
        return
    end

    self:EnsureChipButtons()

    if self:ShouldHideOnEncounter(db) then
        for _, button in pairs(self.chipButtons) do
            button:Hide()
        end
        if not db.containerCollapsed then
            local frame = self.frame
            local leftInset, rightInset = self:GetFrameContentInsets()
            frame.chipBar:Hide()
            if db.hideContainerHeader then
                frame.scroll:ClearAllPoints()
                frame.scroll:SetPoint('TOPLEFT', frame, 'TOPLEFT', leftInset, -leftInset)
                frame.scroll:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -rightInset, rightInset)
            else
                self:ApplyScrollPoints(frame, frame.header)
            end
        end
        return
    end

    if db.showCategoryChips == false then
        if db.activeFilter ~= defaults.FILTER_ALL then
            objectiveTracker.Data:SetValue('activeFilter', defaults.FILTER_ALL)
            db = objectiveTracker.Data:GetDB()
        end
        for _, button in pairs(self.chipButtons) do
            button:Hide()
        end
        if db.containerCollapsed then
            return
        end
        local frame = self.frame
        local leftInset, rightInset = self:GetFrameContentInsets()
        frame.chipBar:Hide()
        if db.hideContainerHeader then
            frame.scroll:ClearAllPoints()
            frame.scroll:SetPoint('TOPLEFT', frame, 'TOPLEFT', leftInset, -leftInset)
            frame.scroll:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -rightInset, rightInset)
        else
            self:ApplyScrollPoints(frame, frame.header)
        end
        return
    end

    local present, presentCount = trackerData:GetPresentCategoryIds()
    if db.activeFilter ~= defaults.FILTER_ALL and not present[db.activeFilter] then
        objectiveTracker.Data:SetValue('activeFilter', defaults.FILTER_ALL)
        db = objectiveTracker.Data:GetDB()
    end

    local visibleChips = {}
    if presentCount > 1 then
        local order = { defaults.FILTER_ALL }
        for _, entry in ipairs(defaults.MODULE_ENTRIES) do
            order[#order + 1] = entry.id
        end

        for _, filterId in ipairs(order) do
            local button = self.chipButtons[filterId]
            if button then
                local showChip = false
                if filterId == defaults.FILTER_ALL then
                    showChip = true
                else
                    showChip = present[filterId] and db.chipEnabled[filterId] ~= false
                end

                if showChip then
                    button:Show()
                    visibleChips[#visibleChips + 1] = button

                    local active = db.activeFilter == filterId
                    local accent = EXUI.const.theme.accent
                    local bg = EXUI.const.theme.backgroundLight
                    if active then
                        button:SetBackdropColor(accent[1], accent[2], accent[3], 0.85)
                        button:SetBackdropBorderColor(accent[1], accent[2], accent[3], 1)
                    else
                        button:SetBackdropColor(bg[1], bg[2], bg[3], 0.9)
                        button:SetBackdropBorderColor(EXUI.const.theme.border[1], EXUI.const.theme.border[2], EXUI.const.theme.border[3], 1)
                    end
                else
                    button:Hide()
                end
            end
        end

        local isRightAlign = self:GetTextAlign(db) == 'RIGHT'
        local chipBar = self.frame.chipBar
        for _, button in pairs(self.chipButtons) do
            button:ClearAllPoints()
        end
        if isRightAlign then
            for index = #visibleChips, 1, -1 do
                local button = visibleChips[index]
                if index == #visibleChips then
                    button:SetPoint('RIGHT', chipBar, 'RIGHT', 0, 0)
                else
                    button:SetPoint('RIGHT', visibleChips[index + 1], 'LEFT', -2, 0)
                end
            end
        else
            for index, button in ipairs(visibleChips) do
                if index == 1 then
                    button:SetPoint('LEFT', chipBar, 'LEFT', 0, 0)
                else
                    button:SetPoint('LEFT', visibleChips[index - 1], 'RIGHT', 2, 0)
                end
            end
        end
    else
        for _, button in pairs(self.chipButtons) do
            button:Hide()
        end
    end

    if db.containerCollapsed then
        return
    end

    local frame = self.frame
    local leftInset, rightInset = self:GetFrameContentInsets()
    if #visibleChips > 0 then
        frame.chipBar:Show()
        frame.chipBar:ClearAllPoints()
        if db.hideContainerHeader then
            frame.chipBar:SetPoint('TOPLEFT', frame, 'TOPLEFT', leftInset, -leftInset)
            frame.chipBar:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -rightInset, -leftInset)
        else
            frame.chipBar:SetPoint('TOPLEFT', frame.header, 'BOTTOMLEFT', 0, -2)
            frame.chipBar:SetPoint('TOPRIGHT', frame.header, 'BOTTOMRIGHT', 0, -2)
        end
        self:ApplyScrollPoints(frame, frame.chipBar)
    else
        frame.chipBar:Hide()
        if db.hideContainerHeader then
            frame.scroll:ClearAllPoints()
            frame.scroll:SetPoint('TOPLEFT', frame, 'TOPLEFT', leftInset, -leftInset)
            frame.scroll:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -rightInset, rightInset)
        else
            self:ApplyScrollPoints(frame, frame.header)
        end
    end
end

function display:GetFrameContentInsets()
    local inset = self.FRAME_EDGE_INSET + self.PANEL_CONTENT_INSET
    return inset, inset
end

function display:ApplyBackgroundPoints(frame)
    local edge = self.FRAME_EDGE_INSET
    frame.background:ClearAllPoints()
    frame.background:SetPoint('TOPLEFT', frame, 'TOPLEFT', edge, -edge)
    frame.background:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -edge, edge)
end

function display:ApplyPanelBackground(frame, db)
    self:ApplyBackgroundPoints(frame)

    if not db.showBackground then
        frame.background:Hide()
        return
    end

    frame.background:Show()

    local bg = db.panelBackgroundColor or { r = 0, g = 0, b = 0, a = 1 }
    local border = db.panelBorderColor or {
        r = EXUI.const.theme.border[1],
        g = EXUI.const.theme.border[2],
        b = EXUI.const.theme.border[3],
        a = 1,
    }
    local thickness = db.panelBorderThickness or 1
    local opacity = (db.backgroundOpacity or 85) / 100

    if thickness > 0 then
        frame.background:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = thickness,
        })
        frame.background:SetBackdropBorderColor(border.r, border.g, border.b, border.a or 1)
    else
        frame.background:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]],
        })
    end
    frame.background:SetBackdropColor(bg.r, bg.g, bg.b, (bg.a or 1) * opacity)
end

function display:ApplyContainerHeaderPoints(header, parent)
    local leftInset, rightInset = self:GetFrameContentInsets()
    header:ClearAllPoints()
    header:SetPoint('TOPLEFT', parent, 'TOPLEFT', leftInset, -leftInset)
    header:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', -rightInset, -leftInset)
end

function display:ApplyScrollPoints(frame, topAnchor)
    local _, rightInset = self:GetFrameContentInsets()
    frame.scroll:ClearAllPoints()
    frame.scroll:SetPoint('TOPLEFT', topAnchor, 'BOTTOMLEFT', 0, -4)
    frame.scroll:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -rightInset, rightInset)
end

function display:GetBlockSideInsets(db)
    local spacing = self:GetSpacing(db)
    local sideInset = self.SCROLL_LEFT_INSET
    if self:GetTextAlign(db) == 'RIGHT' then
        sideInset = self.SCROLL_RIGHT_INSET
    end
    return spacing.blockOffsetX, sideInset
end

function display:GetLayoutWidths(db)
    local leftInset, rightInset = self:GetFrameContentInsets()
    local contentWidth = db.width - leftInset - rightInset
    local categoryWidth = contentWidth
    local blockOffsetX, sideInset = self:GetBlockSideInsets(db)
    local blockWidth = categoryWidth - blockOffsetX - sideInset
    return contentWidth, categoryWidth, blockWidth, 0, 0
end

function display:MeasureFontString(fontString, fallbackHeight, textWidth, fontFlag)
    if textWidth and textWidth > 0 then
        fontString:SetWidth(textWidth)
    end
    fontString:SetHeight(0)
    local height = fontString:GetStringHeight()
    if not height or height <= 0 then
        height = fontString:GetHeight()
    end
    if not height or height <= 0 then
        height = fallbackHeight
    end
    local padding = EXUI:ScalePixel(1, self.frame or fontString)
    if fontFlag and fontFlag:find('OUTLINE', 1, true) then
        padding = padding + EXUI:ScalePixel(1, self.frame or fontString)
    end
    return height + padding
end

function display:GetCategoryHeaderLineHeight(db)
    if not db.showCategoryHeaderLine then
        return 0
    end
    local thickness = db.categoryHeaderLineThickness or 1
    return EXUI:ScalePixel(thickness, self.frame or UIParent)
end

function display:ApplyCategoryHeaderLine(frame, db)
    local lineHeight = self:GetCategoryHeaderLineHeight(db)
    if lineHeight <= 0 then
        if frame.headerLine then
            frame.headerLine:Hide()
        end
        return lineHeight, frame.header
    end

    frame.headerLine = frame.headerLine or frame:CreateTexture(nil, 'ARTWORK')
    frame.headerLine:SetParent(frame)
    frame.headerLine:Show()
    frame.headerLine:SetHeight(lineHeight)
    frame.headerLine:ClearAllPoints()
    frame.headerLine:SetPoint('TOPLEFT', frame.header, 'BOTTOMLEFT', 0, 0)
    frame.headerLine:SetPoint('TOPRIGHT', frame.header, 'BOTTOMRIGHT', 0, 0)

    local color = db.categoryHeaderLineColor or {
        r = EXUI.const.theme.accent[1],
        g = EXUI.const.theme.accent[2],
        b = EXUI.const.theme.accent[3],
        a = 1,
    }
    frame.headerLine:SetColorTexture(color.r, color.g, color.b, color.a or 1)

    return lineHeight, frame.headerLine
end

function display:CreateCategoryFrame(parent, category, db, categoryWidth)
    local spacing = self:GetSpacing(db)
    local frame = self.categoryPool:Acquire()
    frame:SetParent(parent)
    frame:Show()
    frame.categoryId = category.id
    frame:SetWidth(categoryWidth)

    frame.header = frame.header or CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    frame.header:SetParent(frame)
    frame.header:ClearAllPoints()
    frame.header:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    frame.header:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0)

    local padX = spacing.headerPaddingX or 4
    local padY = spacing.headerPaddingY or 2
    local fontPath, fontSize, fontFlag = self:GetFont(db.moduleHeaderFont, db.moduleHeaderFontSize, db.moduleHeaderFontFlag)
    local categoryHeaderHeight = self:GetCategoryHeaderHeight(db, fontSize, fontFlag)
    frame.header:SetHeight(categoryHeaderHeight)
    frame.categoryHeaderHeight = categoryHeaderHeight

    if db.customHeaderStyle then
        local bg = db.headerBackgroundColor
        local border = db.headerBorderColor
        local thickness = db.headerBorderThickness or 0
        if thickness > 0 then
            frame.header:SetBackdrop({
                bgFile = [[Interface\Buttons\WHITE8x8]],
                edgeFile = [[Interface\Buttons\WHITE8x8]],
                edgeSize = thickness,
            })
            frame.header:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
        else
            frame.header:SetBackdrop({
                bgFile = [[Interface\Buttons\WHITE8x8]],
            })
        end
        frame.header:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
    else
        frame.header:SetBackdrop(nil)
    end

    if not frame.headerClick then
        frame.headerClick = CreateFrame('Button', nil, frame.header)
        frame.headerClick:SetFrameLevel(frame.header:GetFrameLevel() + 5)
        frame.headerClick:RegisterForClicks('LeftButtonUp')
        frame.headerClick:EnableMouse(true)
        frame.headerClick:SetScript('OnClick', function(btn)
            if btn.categoryId then
                display:ToggleCategoryCollapsed(btn.categoryId)
            end
        end)
    end
    frame.headerClick:SetFrameLevel(frame.header:GetFrameLevel() + 5)
    frame.headerClick:ClearAllPoints()
    frame.headerClick:SetAllPoints(frame.header)
    frame.headerClick.categoryId = category.id
    frame.headerClick:Show()

    if not frame.minimizeButton then
        frame.minimizeButton = self:CreateMinimizeButton(frame.header)
    end
    frame.minimizeButton:SetScript('OnClick', function(btn)
        if btn.categoryId then
            display:ToggleCategoryCollapsed(btn.categoryId)
        end
    end)
    frame.minimizeButton:SetFrameLevel(frame.headerClick:GetFrameLevel() + 2)
    frame.minimizeButton:ClearAllPoints()
    local collapseRightInset = self:GetCategoryCollapseButtonRightInset(db, padX)
    frame.minimizeButton:SetPoint('RIGHT', frame.header, 'RIGHT', -collapseRightInset, 0)
    frame.minimizeButton:SetPoint('CENTER', frame.header, 'RIGHT', -(collapseRightInset + self.COLLAPSE_BUTTON_SIZE / 2), 0)
    frame.minimizeButton.categoryId = category.id

    frame.title = frame.title or frame.header:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.title:SetParent(frame.header)
    if db.hideModuleMinimizeButtons then
        frame.minimizeButton:Hide()
    else
        frame.minimizeButton:Show()
    end
    self:ApplyHeaderTitleLayout(frame.title, frame.header, db, padX, padY, frame.minimizeButton, db.hideModuleMinimizeButtons)
    frame.title:SetText(category.label)

    frame.title:SetFont(fontPath, fontSize, fontFlag)
    local headerColor = self:GetColor(db, 'CategoryHeader')
    frame.title:SetTextColor(headerColor.r, headerColor.g, headerColor.b)

    local collapsed = self:IsCategoryCollapsed(category.id, db)
    frame.minimizeButton:SetCollapsedState(collapsed)

    local lineHeight, blocksAnchor = self:ApplyCategoryHeaderLine(frame, db)

    frame.blocksContainer = frame.blocksContainer or CreateFrame('Frame', nil, frame)
    frame.blocksContainer:SetParent(frame)
    frame.blocksContainer:ClearAllPoints()
    local blockOffsetX, sideInset = self:GetBlockSideInsets(db)
    local isRightAlign = self:GetTextAlign(db) == 'RIGHT'
    local blockLeft = blockOffsetX + (isRightAlign and 0 or sideInset)
    local blockRight = blockOffsetX + (isRightAlign and sideInset or 0)
    frame.blocksContainer:SetPoint('TOPLEFT', blocksAnchor, 'BOTTOMLEFT', blockLeft, spacing.fromHeaderOffsetY)
    frame.blocksContainer:SetPoint('TOPRIGHT', blocksAnchor, 'BOTTOMRIGHT', -blockRight, spacing.fromHeaderOffsetY)
    frame.categoryHeaderLineHeight = lineHeight
    if collapsed then
        frame.blocksContainer:Hide()
    else
        frame.blocksContainer:Show()
    end

    self.categoryFrames[#self.categoryFrames + 1] = frame
    return frame
end

function display:CreateBlockFrame(parent, block, db, blockWidth)
    local spacing = self:GetSpacing(db)
    local frame = self.blockPool:Acquire()
    frame:SetParent(parent)
    frame:Show()
    frame.blockData = block
    frame:SetWidth(blockWidth)

    local align = self:GetTextAlign(db)
    local isRightAlign = align == 'RIGHT'
    local poiOffset = self:AttachQuestPOI(frame, block, db)
    local poiEdgeInset = frame.poiButton and self.POI_EDGE_INSET or 0
    local poiGutter = poiOffset + poiEdgeInset
    local titleWidth = blockWidth - poiGutter

    frame.title = frame.title or frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.title:SetParent(frame)
    frame.title:ClearAllPoints()
    if isRightAlign then
        frame.title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
        frame.title:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -poiGutter, 0)
    else
        frame.title:SetPoint('TOPLEFT', frame, 'TOPLEFT', poiGutter, 0)
        frame.title:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0)
    end
    frame.title:SetJustifyH(align)
    frame.title:SetWordWrap(true)
    frame.title:SetMaxLines(0)

    local fontPath, fontSize, fontFlag = self:GetFont(db.blockHeaderFont, db.blockHeaderFontSize, db.blockHeaderFontFlag)
    frame.title:SetFont(fontPath, fontSize, fontFlag)
    frame.title:SetText(block.title)
    self:SetBlockTitleColor(frame, block, db)

    if frame.poiButton then
        frame.poiButton:ClearAllPoints()
        if isRightAlign then
            frame.poiButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -poiEdgeInset, 0)
        else
            frame.poiButton:SetPoint('TOPLEFT', frame, 'TOPLEFT', poiEdgeInset, 0)
        end
    end

    if frame.untrack then
        frame.untrack:Hide()
    end

    frame.titleButton = frame.titleButton or CreateFrame('Button', nil, frame)
    frame.titleButton:SetParent(frame)
    frame.titleButton:ClearAllPoints()
    frame.titleButton:SetPoint('TOPLEFT', frame.title, 'TOPLEFT', -2, 2)
    frame.titleButton:SetPoint('BOTTOMRIGHT', frame.title, 'BOTTOMRIGHT', 2, -2)
    frame.titleButton:RegisterForClicks('LeftButtonUp', 'MiddleButtonUp')
    frame.titleButton:SetScript('OnEnter', function()
        local currentDb = objectiveTracker.Data:GetDB()
        local hover = display:GetColor(currentDb, 'BlockHeaderHighlight')
        frame.title:SetTextColor(hover.r, hover.g, hover.b)
    end)
    frame.titleButton:SetScript('OnLeave', function()
        display:SetBlockTitleColor(frame, frame.blockData, objectiveTracker.Data:GetDB())
    end)
    frame.titleButton:SetScript('OnClick', function(_, mouseButton)
        display:HandleBlockTitleClick(frame.blockData, mouseButton)
    end)

    local lineFontPath, lineFontSize, lineFontFlag = self:GetFont(db.lineFont, db.lineFontSize, db.lineFontFlag)
    local blockHeight = self:MeasureFontString(frame.title, fontSize, titleWidth, fontFlag)
    local lineIndent = poiGutter
    local lineTextWidth = blockWidth - lineIndent
    local questID = block.untrackId or block.id

    blockHeight = self:AppendChallengeModeSection(frame, block, db, blockHeight, blockWidth, lineIndent, spacing)
    blockHeight = self:AppendScenarioStage(frame, block, db, blockHeight, blockWidth, lineIndent, spacing)

    for lineIndex, objective in ipairs(block.objectives or {}) do
        if objective.text and objective.text ~= '' then
            local lineFrame = self.linePool:Acquire()
            lineFrame:SetParent(frame)
            lineFrame:Show()
            lineFrame:SetWidth(blockWidth)

            lineFrame.text = lineFrame.text or lineFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
            lineFrame.text:SetParent(lineFrame)
            lineFrame.text:ClearAllPoints()
            if isRightAlign then
                lineFrame.text:SetPoint('TOPLEFT', lineFrame, 'TOPLEFT', 0, 0)
                lineFrame.text:SetPoint('TOPRIGHT', lineFrame, 'TOPRIGHT', -lineIndent, 0)
            else
                lineFrame.text:SetPoint('TOPLEFT', lineFrame, 'TOPLEFT', lineIndent, 0)
                lineFrame.text:SetPoint('TOPRIGHT', lineFrame, 'TOPRIGHT', 0, 0)
            end
            lineFrame.text:SetJustifyH(align)
            lineFrame.text:SetWordWrap(true)
            lineFrame.text:SetMaxLines(0)
            lineFrame.text:SetNonSpaceWrap(false)
            lineFrame.text:SetFont(lineFontPath, lineFontSize, lineFontFlag)
            lineFrame.text:SetText(objective.text)

            local colorKey = objective.failed and 'Failed' or (objective.finished and 'Complete' or 'Normal')
            local color = self:GetColor(db, colorKey)
            lineFrame.text:SetTextColor(color.r, color.g, color.b)

            local lineHeight = self:MeasureFontString(lineFrame.text, lineFontSize, lineTextWidth, lineFontFlag)
            lineFrame:SetHeight(lineHeight)
            blockHeight = self:AppendBlockRow(frame, lineFrame, blockHeight, spacing)
            self.lineFrames[#self.lineFrames + 1] = lineFrame
        end

        if objective.showProgressBar then
            local progressFrame = self:AcquireProgressBar(frame, blockWidth, lineIndent, isRightAlign, db)
            local percent = objective.progressPercent
            if percent == nil and questID then
                percent = self:GetQuestProgressPercent(questID)
            end
            self:SetProgressBarPercent(progressFrame, percent or 0)
            blockHeight = self:AppendBlockRow(frame, progressFrame, blockHeight, spacing, db)
            self.progressBarFrames[#self.progressBarFrames + 1] = progressFrame
        end
    end

    frame:SetHeight(blockHeight)
    self.blockFrames[#self.blockFrames + 1] = frame
    return frame, blockHeight
end

function display:LayoutCategories(categories, db)
    local spacing = self:GetSpacing(db)
    local content = self.frame.content
    local scroll = self.frame.scroll
    local contentWidth, categoryWidth, blockWidth, leftInset = self:GetLayoutWidths(db)
    local previousScroll = scroll:GetVerticalScroll()

    content:SetWidth(contentWidth)
    self:ReleaseLayout()

    local yOffset = 0
    for _, category in ipairs(categories) do
        local categoryFrame = self:CreateCategoryFrame(content, category, db, categoryWidth)
        categoryFrame:ClearAllPoints()
        categoryFrame:SetPoint('TOPLEFT', content, 'TOPLEFT', leftInset, -yOffset)

        local collapsed = self:IsCategoryCollapsed(category.id, db)
        local headerHeight = categoryFrame.categoryHeaderHeight or spacing.headerHeight
        local lineHeight = categoryFrame.categoryHeaderLineHeight or self:GetCategoryHeaderLineHeight(db)
        local categoryHeight = headerHeight + lineHeight
        if not collapsed then
            local blocksContainer = categoryFrame.blocksContainer
            blocksContainer:SetWidth(blockWidth)
            local blockYOffset = 0
            for _, block in ipairs(category.blocks) do
                local blockFrame, blockHeight = self:CreateBlockFrame(blocksContainer, block, db, blockWidth)
                blockFrame:ClearAllPoints()
                blockFrame:SetPoint('TOPLEFT', blocksContainer, 'TOPLEFT', 0, -blockYOffset)
                blockFrame:SetPoint('TOPRIGHT', blocksContainer, 'TOPRIGHT', 0, -blockYOffset)
                blockYOffset = blockYOffset + blockHeight + spacing.fromBlockOffsetY * -1
            end

            blocksContainer:SetHeight(math.max(1, blockYOffset))
            categoryHeight = headerHeight + lineHeight + spacing.fromHeaderOffsetY * -1 + blockYOffset
        end

        categoryFrame:SetHeight(categoryHeight)
        yOffset = yOffset + categoryHeight + self:GetCategorySpacing(db)
    end

    content:SetHeight(math.max(1, yOffset))
    local maxScroll = self:GetMaxScroll()
    self:SetScrollPosition(math.min(previousScroll, maxScroll), true)
end

function display:ApplyFrameSettings(db)
    local frame = self.frame
    if not frame then
        return
    end

    local frameHeight = db.maxHeight
    if not db.hideContainerHeader and db.containerCollapsed then
        frameHeight = self:GetCollapsedFrameHeight(db)
    end
    self:ApplyFramePositionAndSize(db, frameHeight)

    self:ApplyPanelBackground(frame, db)

    local title = db.containerTitle
    if not title or title == '' then
        title = TRACKER_ALL_OBJECTIVES or 'Objectives'
    end
    frame.title:SetText(title)
    local fontPath, fontSize, fontFlag = self:GetFont(db.containerFont, db.containerFontSize, db.containerFontFlag)
    frame.title:SetFont(fontPath, fontSize, fontFlag)

    local spacing = self:GetSpacing(db)
    local padX = spacing.headerPaddingX or 4
    local padY = spacing.headerPaddingY or 2
    local containerHeaderHeight = self:GetCategoryHeaderHeight(db, fontSize, fontFlag)
    frame.header:SetHeight(containerHeaderHeight)

    frame.title:ClearAllPoints()
    if db.hideCollapseButtons then
        frame.minimizeButton:Hide()
        self:ApplyHeaderTitleLayout(frame.title, frame.header, db, padX, padY, frame.minimizeButton, true)
    else
        frame.minimizeButton:Show()
        frame.minimizeButton:ClearAllPoints()
        frame.minimizeButton:SetPoint('RIGHT', frame.header, 'RIGHT', -self.COLLAPSE_BUTTON_RIGHT_INSET, 0)
        frame.minimizeButton:SetPoint('TOP', frame.header, 'TOP', 0, -padY)
        frame.minimizeButton:SetPoint('BOTTOM', frame.header, 'BOTTOM', 0, padY)
        self:ApplyHeaderTitleLayout(frame.title, frame.header, db, padX, padY, frame.minimizeButton, false)
        frame.minimizeButton:SetCollapsedState(db.containerCollapsed)
    end

    if db.hideContainerHeader then
        frame.header:Hide()
        frame.scroll:Show()
    elseif db.containerCollapsed then
        frame.header:Show()
        frame.chipBar:Hide()
        frame.scroll:Hide()
        self:ApplyContainerHeaderPoints(frame.header, frame)
    else
        frame.header:Show()
        frame.scroll:Show()
        self:ApplyContainerHeaderPoints(frame.header, frame)
    end

    self:RefreshChipStates()
end

function display:SyncEncounterState()
    if C_InstanceEncounter and C_InstanceEncounter.IsEncounterInProgress then
        self.inEncounter = C_InstanceEncounter.IsEncounterInProgress()
    else
        self.inEncounter = false
    end
end

function display:ShouldHideInMythicPlus(db)
    return db.hideInMythicPlus and trackerData:IsInMythicPlus() and not objectiveTracker.editorShowing
end

function display:ShouldHideOnEncounter(db)
    local hideOnEncounter = db.hideOnEncounter
    if hideOnEncounter == nil then
        hideOnEncounter = db.hideInCombat
    end
    return hideOnEncounter and self.inEncounter and not objectiveTracker.editorShowing
end

function display:FilterCategoriesForEncounter(categories, db)
    if not self:ShouldHideOnEncounter(db) then
        return categories
    end

    for _, entry in ipairs(defaults.MODULE_ENTRIES) do
        if entry.id == self.SCENARIO_CATEGORY_ID then
            local blocks = trackerData:CollectScenarioBlocks()
            if #blocks > 0 then
                return {
                    {
                        id = entry.id,
                        label = trackerData:GetCategoryTitle(entry, db),
                        blocks = blocks,
                    },
                }
            end
            return {}
        end
    end

    return {}
end

function display:IsSuppressedByMythicPlusTimer()
    local mythicPlusTimer = EXUI:GetModule('mythic-plus-timer')
    if mythicPlusTimer and mythicPlusTimer.ShouldSuppressObjectiveTracker then
        return mythicPlusTimer:ShouldSuppressObjectiveTracker()
    end
    return false
end

function display:ApplyTrackerVisibility(db, categories)
    if not self.frame then
        return
    end

    self.frame:SetAlpha(1)

    if self:IsSuppressedByMythicPlusTimer() then
        self.frame:Hide()
        return
    end

    if self:ShouldHideInMythicPlus(db) then
        self.frame:Hide()
        return
    end

    if categories and #categories == 0 and db.autoHideWhenEmpty and not objectiveTracker.editorShowing then
        self.frame:Hide()
        return
    end

    self.frame:Show()
end

function display:CancelPendingUpdate()
    self.updateScheduled = false
end

function display:RequestUpdate()
    if not objectiveTracker.enabled then
        return
    end
    trackerData:InvalidateCategoryCache()
    if self.updateScheduled then
        return
    end
    self.updateScheduled = true
    EXUI.utils.nextFrame(function()
        display.updateScheduled = false
        if not objectiveTracker.enabled then
            return
        end
        display:Update()
    end)
end

function display:Update()
    if not objectiveTracker.enabled or not self.frame then
        return
    end

    trackerData:InvalidateCategoryCache()
    local db = objectiveTracker.Data:GetDB()

    if self:IsSuppressedByMythicPlusTimer() then
        self.frame:Hide()
        self:StopChallengeModeTimerWatch()
        self:StopScenarioHeaderTimerWatch()
        return
    end

    if self:ShouldHideInMythicPlus(db) then
        self.frame:Hide()
        self:StopChallengeModeTimerWatch()
        self:StopScenarioHeaderTimerWatch()
        return
    end

    self:ApplyFrameSettings(db)

    local categories = trackerData:GetCategories(db)
    categories = self:FilterCategoriesForEncounter(categories, db)

    if db.containerCollapsed then
        self:ApplyTrackerVisibility(db, categories)
        self:StopChallengeModeTimerWatch()
        self:StopScenarioHeaderTimerWatch()
        return
    end

    if #categories == 0 and db.autoHideWhenEmpty and not objectiveTracker.editorShowing then
        self.frame:Hide()
        self:StopChallengeModeTimerWatch()
        self:StopScenarioHeaderTimerWatch()
        return
    end

    self.frame:Show()
    self:LayoutCategories(categories, db)
    self:StartChallengeModeTimerWatch()
    self:StartScenarioHeaderTimerWatch()
end

function display:Show()
    self:CreateMainFrame()
    self.frame:Show()
    self:Update()
end

function display:Hide()
    self:CancelPendingUpdate()
    self:StopChallengeModeTimerWatch()
    self:StopScenarioHeaderTimerWatch()
    self:StopSmoothScroll()
    self.scrollTarget = nil
    if self.frame then
        self.frame:Hide()
    end
    self:ReleaseLayout()
end

function display:CanSafelyUpdateBlizzardTracker()
    return not canaccesssecrets or canaccesssecrets()
end

function display:GetBlizzardOrderedModules()
    return {
        ScenarioObjectiveTracker,
        UIWidgetObjectiveTracker,
        CampaignQuestObjectiveTracker,
        QuestObjectiveTracker,
        AdventureObjectiveTracker,
        AchievementObjectiveTracker,
        MonthlyActivitiesObjectiveTracker,
        InitiativeTasksObjectiveTracker,
        ProfessionsRecipeTracker,
        BonusObjectiveTracker,
        WorldQuestObjectiveTracker,
    }
end

function display:SuppressBlizzardModules()
    if not ObjectiveTrackerManager then
        return
    end
    ObjectiveTrackerManager:SetCanAddModules(false)
    ObjectiveTrackerManager:RemoveAllModules()
end

function display:RestoreBlizzardModules()
    if not ObjectiveTrackerManager or not ObjectiveTrackerFrame then
        return
    end

    ObjectiveTrackerManager:SetCanAddModules(true)

    local orderedModules = self:GetBlizzardOrderedModules()
    ObjectiveTrackerManager:AssignModulesOrder(orderedModules)
    for _, module in ipairs(orderedModules) do
        if module then
            ObjectiveTrackerManager:SetModuleContainer(module, ObjectiveTrackerFrame)
        end
    end
end

function display:RegisterEvents()
    if self.eventFrame then
        return
    end
    self:SyncEncounterState()
    self.eventFrame = CreateFrame('Frame')
    for _, event in ipairs(self.EVENTS) do
        self.eventFrame:RegisterEvent(event)
    end
    self.eventFrame:SetScript('OnEvent', function(_, event)
        if not objectiveTracker.enabled then
            return
        end
        if event == 'ENCOUNTER_START' then
            display.inEncounter = true
        elseif event == 'ENCOUNTER_END' then
            display.inEncounter = false
        elseif event == 'ZONE_CHANGED' or event == 'ZONE_CHANGED_NEW_AREA' or event == 'PLAYER_ENTERING_WORLD' then
            display:SyncEncounterState()
        end
        display:RequestUpdate()
    end)
end

function display:UnregisterEvents()
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame:SetScript('OnEvent', nil)
        self.eventFrame = nil
    end
end

function display:HideBlizzardTracker()
    if not ObjectiveTrackerFrame then
        return
    end
    if not self.blizzardShowHooked then
        self.blizzardShowHooked = true
        hooksecurefunc(ObjectiveTrackerFrame, 'Show', function()
            if objectiveTracker.enabled then
                ObjectiveTrackerFrame:Hide()
            end
        end)
    end
    self:SuppressBlizzardModules()
    ObjectiveTrackerFrame:Hide()
end

function display:ShowBlizzardTracker()
    self:RestoreBlizzardModules()
    if ObjectiveTrackerFrame then
        ObjectiveTrackerFrame:Show()
        if ObjectiveTrackerManager and self:CanSafelyUpdateBlizzardTracker() then
            ObjectiveTrackerManager:UpdateAll()
        end
    end
end

function display:Enable()
    local db = objectiveTracker.Data:GetDB()
    if not db.rememberCollapsedModules then
        objectiveTracker.Data:SetValue('collapsedModules', {})
        objectiveTracker.Data:SetValue('containerCollapsed', false)
    end

    self:CreateMainFrame()
    self:RegisterEvents()
    self:HideBlizzardTracker()
    self:Show()
end

function display:Disable()
    self:CancelPendingUpdate()
    self:UnregisterEvents()
    self:Hide()
    self:ShowBlizzardTracker()
end
