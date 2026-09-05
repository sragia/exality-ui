---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIMythicPlusTimerModule
local mythicPlusTimer = EXUI:GetModule('mythic-plus-timer')

---@class EXUIMythicPlusTimerDefaults
local defaults = EXUI:GetModule('mythic-plus-timer-defaults')

---@class EXUIMythicPlusTimerData
local timerData = EXUI:GetModule('mythic-plus-timer-data')

---@class EXUIMythicPlusTimerPreview
local preview = EXUI:GetModule('mythic-plus-timer-preview')

---@class EXUIObjectiveTrackerModule
local objectiveTracker = EXUI:GetModule('objective-tracker')

---@class EXUIObjectiveTrackerDisplay
local objectiveTrackerDisplay = EXUI:GetModule('objective-tracker-display')

local LSM = LibStub('LibSharedMedia-3.0', true)

---@class EXUIMythicPlusTimerDisplay
local display = EXUI:GetModule('mythic-plus-timer-display')

display.frame = nil
display.bossLines = {}
display.lastShouldSuppressObjectiveTracker = nil
display.suppressionTarget = nil
display.blizzardShowHooked = false
display._lastRender = nil

function display:GetFont(fontKey, sizeKey, flagKey, db)
    local fontName = db[fontKey] or 'DMSans'
    local fontPath = (LSM and LSM:Fetch('font', fontName)) or EXUI.EXFrames.assets.font.default()
    local fontSize = db[sizeKey] or 12
    local fontFlag = db[flagKey] or 'OUTLINE'
    return fontPath, fontSize, fontFlag
end

function display:GetBarTexture(db)
    local textureName = (db and db.barTexture) or defaults.BAR_TEXTURE
    if LSM and LSM:Fetch('statusbar', textureName) then
        return LSM:Fetch('statusbar', textureName)
    end
    return [[Interface/Addons/ExalityUI/Assets/Images/StatusBar/noisy.tga]]
end

function display:FormatClock(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    if SecondsToClock then
        return SecondsToClock(seconds)
    end
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format('%d:%02d', minutes, secs)
end

function display:FormatPenalty(seconds)
    return '+' .. self:FormatClock(seconds)
end

function display:FormatPercent(value)
    return string.format('%.2f%%', value or 0)
end

function display:FormatDelta(seconds)
    local rounded = math.floor((seconds or 0) + 0.5)
    local sign = rounded < 0 and '-' or '+'
    return sign .. self:FormatClock(math.abs(rounded))
end

function display:FormatForcesCount(current, total)
    current = current or 0
    total = total or 0
    return string.format('%d/%d (+%d)', current, total, math.max(0, total - current))
end

local function colorToHex(color)
    if not color then
        return 'ffffff'
    end
    return string.format(
        '%02x%02x%02x',
        math.floor((color.r or 1) * 255 + 0.5),
        math.floor((color.g or 1) * 255 + 0.5),
        math.floor((color.b or 1) * 255 + 0.5)
    )
end

function display:GetSplitColor(db, delta)
    if delta < 0 then
        return db.splitAheadColor or db.bossKilledColor
    end
    if delta > 0 then
        return db.splitBehindColor or db.elapsedColor
    end
    return db.elapsedColor
end

function display:ColorizeDelta(db, delta)
    local color = self:GetSplitColor(db, delta)
    return string.format('|cff%s%s|r', colorToHex(color), self:FormatDelta(delta))
end

function display:ApplyFontString(text, fontKey, sizeKey, flagKey, db, color, verticalAlign)
    local fontPath, fontSize, fontFlag = self:GetFont(fontKey, sizeKey, flagKey, db)
    text:SetFont(fontPath, fontSize, fontFlag)
    if color then
        text:SetTextColor(color.r, color.g, color.b, color.a or 1)
    end
    if verticalAlign == 'bottom' then
        EXUI:SetHeight(text, fontSize)
        text:SetJustifyV('BOTTOM')
    elseif verticalAlign == 'top' then
        EXUI:SetHeight(text, fontSize)
        text:SetJustifyV('TOP')
    else
        text:SetHeight(0)
    end
end

function display:CreateBar(parent, name)
    local barFrame = CreateFrame('Frame', nil, parent)
    barFrame:SetFrameLevel(1)
    barFrame.border = CreateFrame('Frame', nil, barFrame, 'BackdropTemplate')
    barFrame.border.bg = barFrame.border:CreateTexture(nil, 'BACKGROUND')
    barFrame.border.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    barFrame.border.bg:SetAllPoints()

    barFrame.bar = CreateFrame('StatusBar', nil, barFrame.border)
    barFrame.bar:SetMinMaxValues(0, 100)
    barFrame.bar:SetStatusBarTexture(self:GetBarTexture())

    barFrame.spark1 = barFrame.border:CreateTexture(nil, 'OVERLAY')
    barFrame.spark2 = barFrame.border:CreateTexture(nil, 'OVERLAY')
    barFrame.spark1:SetColorTexture(1, 1, 1, 1)
    barFrame.spark2:SetColorTexture(1, 1, 1, 1)

    return barFrame
end

function display:GetTimerBarHeight(db)
    return db.timerBarHeight or db.barHeight or 20
end

function display:GetForcesBarHeight(db)
    return db.forcesBarHeight or db.barHeight or 15
end

function display:GetBarOuterHeight(db, barHeight)
    return barHeight + (db.barBorderThickness or 1) * 2
end

function display:ApplyBarContentInsets(barFrame, borderThickness)
    local border = barFrame.border
    borderThickness = math.max(0, borderThickness or 0)
    local contentInset = borderThickness > 0 and EXUI:GetBorderInset(border, borderThickness) or 0

    barFrame.bar:ClearAllPoints()
    barFrame.bar:SetPoint('TOPLEFT', border, 'TOPLEFT', contentInset, -contentInset)
    barFrame.bar:SetPoint('BOTTOMRIGHT', border, 'BOTTOMRIGHT', -contentInset, 0)
end

function display:ApplyBarStyle(barFrame, settings, db, barHeight)
    local borderThickness = math.max(0, db.barBorderThickness or 1)
    local barWidth = db.barWidth or 220
    local totalHeight = self:GetBarOuterHeight(db, barHeight)

    EXUI:SetSize(barFrame, barWidth, totalHeight)
    barFrame.border:ClearAllPoints()
    barFrame.border:SetAllPoints()

    local bg = settings.background
    barFrame.border.bg:SetVertexColor(bg.r, bg.g, bg.b, bg.a or 1)

    if borderThickness > 0 then
        if not barFrame.border.PPBorder then
            barFrame.border.PPBorder = EXUI:AddPixelPerfectBorder(barFrame.border, borderThickness, { register = false })
        end
        local borderColor = settings.border
        barFrame.border.PPBorder:SetBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        barFrame.border.PPBorder.Top:Show()
        barFrame.border.PPBorder.Bottom:Show()
        barFrame.border.PPBorder.Left:Show()
        barFrame.border.PPBorder.Right:Show()
    elseif barFrame.border.PPBorder then
        barFrame.border.PPBorder.Top:Hide()
        barFrame.border.PPBorder.Bottom:Hide()
        barFrame.border.PPBorder.Left:Hide()
        barFrame.border.PPBorder.Right:Hide()
    end

    EXUI:SnapFrameToPixels(barFrame)
    EXUI:SnapFrameToPixels(barFrame.border)

    if barFrame.border.PPBorder and borderThickness > 0 then
        barFrame.border.PPBorder:SetBorderThickness(borderThickness)
    end

    self:ApplyBarContentInsets(barFrame, borderThickness)

    local fill = settings.fill
    barFrame.bar:SetStatusBarColor(fill.r, fill.g, fill.b, fill.a or 1)
    barFrame.bar:SetStatusBarTexture(self:GetBarTexture(db))
end

function display:PositionSparks(barFrame, db, elapsedPercent, forceLayout)
    local thresholds = defaults.UPGRADE_THRESHOLDS

    local function updateSpark(spark, fraction, laidOutKey)
        if not spark then
            return
        end
        if elapsedPercent and elapsedPercent >= fraction then
            if spark:IsShown() then
                spark:Hide()
            end
            return
        end
        if forceLayout or not spark[laidOutKey] then
            local sparkWidth = EXUI:ScalePixel(defaults.SPARK_WIDTH, barFrame.border)
            local barWidth = barFrame.border:GetWidth()
            local x = barWidth * fraction - (sparkWidth / 2)
            spark:ClearAllPoints()
            spark:SetPoint('TOPLEFT', barFrame.border, 'TOPLEFT', x, 0)
            spark:SetPoint('BOTTOMLEFT', barFrame.border, 'BOTTOMLEFT', x, 0)
            EXUI:SetWidth(spark, sparkWidth)
            spark[laidOutKey] = true
        end
        if not spark:IsShown() then
            spark:Show()
        end
    end

    updateSpark(barFrame.spark1, thresholds.plus3, '_exuiSparkLaidOut')
    updateSpark(barFrame.spark2, thresholds.plus2, '_exuiSparkLaidOut')
end

function display:EnsureTextLayer(section)
    if not section.textLayer then
        section.textLayer = CreateFrame('Frame', nil, section)
        section.textLayer:SetAllPoints(section)
    end
    section.textLayer:SetFrameLevel(10)
    return section.textLayer
end

function display:ApplyTextLayer(section, bar, texts)
    local textLayer = self:EnsureTextLayer(section)
    bar:SetFrameLevel(1)
    for _, text in ipairs(texts) do
        if text and text:GetParent() ~= textLayer then
            text:SetParent(textLayer)
        end
    end
    return textLayer
end

function display:CreateMainFrame()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame('Frame', 'EXUIMythicPlusTimerFrame', UIParent, 'BackdropTemplate')
    frame:SetClampedToScreen(true)

    frame.deathRow = CreateFrame('Frame', nil, frame)
    frame.deathCount = frame.deathRow:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.deathSkull = frame.deathRow:CreateTexture(nil, 'ARTWORK')
    frame.deathSkull:SetTexture(defaults.SKULL_TEXTURE)

    frame.timerSection = CreateFrame('Frame', nil, frame)
    frame.timerBar = self:CreateBar(frame.timerSection, 'timer')
    local timerTextLayer = self:EnsureTextLayer(frame.timerSection)
    frame.maxTimer = timerTextLayer:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.elapsed = timerTextLayer:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.deathPenalty = timerTextLayer:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.keyLevel = timerTextLayer:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.milestoneTimer = timerTextLayer:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')

    frame.forcesSection = CreateFrame('Frame', nil, frame)
    frame.forcesBar = self:CreateBar(frame.forcesSection, 'forces')
    local forcesTextLayer = self:EnsureTextLayer(frame.forcesSection)
    frame.forcesPercent = forcesTextLayer:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.forcesDelta = forcesTextLayer:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.forcesRaw = forcesTextLayer:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')

    frame.bossSection = CreateFrame('Frame', nil, frame)
    frame.bossSection.lines = {}

    self.frame = frame
    return frame
end

function display:GetBossLine(index)
    if not self.frame then
        return nil
    end

    local lines = self.frame.bossSection.lines
    if not lines[index] then
        lines[index] = self.frame.bossSection:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    end
    return lines[index]
end

function display:HideExtraBossLines(visibleCount)
    if not self.frame then
        return
    end

    for index = visibleCount + 1, #self.frame.bossSection.lines do
        self.frame.bossSection.lines[index]:Hide()
    end
end

function display:GetTimerTopTextHeight(db)
    local height = db.elapsedFontSize
    if db.showMaxTimer then
        height = height + db.maxTimerFontSize + 2
    end
    return height
end

function display:GetTimerSectionHeight(db)
    local milestoneBelowBar = math.ceil((db.milestoneFontSize or 11) / 2)
    return self:GetTimerTopTextHeight(db)
        + self:GetBarOuterHeight(db, self:GetTimerBarHeight(db))
        + milestoneBelowBar
end

function display:GetForcesSectionHeight(db)
    local labelHeight = math.max(db.forcesPercentFontSize, db.forcesRawFontSize)
    return self:GetBarOuterHeight(db, self:GetForcesBarHeight(db))
        + labelHeight
end

function display:ApplyLayout(db)
    local frame = self.frame
    if not frame then
        return
    end

    local spacing = defaults.SPACING
    local barWidth = db.barWidth or 220
    local isRight = db.bossAlign == 'RIGHT'

    frame:ClearAllPoints()
    EXUI:SetPoint(frame, db.anchorPoint, UIParent, db.relativeAnchor, db.xOffset, db.yOffset)
    frame:SetFrameStrata(db.frameStrata or 'MEDIUM')
    frame:SetFrameLevel(db.frameLevel or 10)
    EXUI:SetWidth(frame, barWidth)

    local yOffset = 0

    local function stackRow(rowFrame, height, gap)
        rowFrame:ClearAllPoints()
        rowFrame:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, yOffset)
        rowFrame:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, yOffset)
        EXUI:SetHeight(rowFrame, height)
        yOffset = yOffset - height - (gap or spacing.section)
    end

    if db.showDeathCounter then
        local deathHeight = db.deathFontSize + 2
        stackRow(frame.deathRow, deathHeight)
        frame.deathCount:ClearAllPoints()
        frame.deathSkull:ClearAllPoints()
        frame.deathCount:SetPoint('BOTTOMRIGHT', frame.deathSkull, 'BOTTOMLEFT', -2, 0)
        frame.deathSkull:SetPoint('BOTTOMRIGHT', frame.deathRow, 'BOTTOMRIGHT', 0, 0)
        local skullSize = EXUI:ScalePixel(db.deathFontSize + 2, frame.deathRow)
        frame.deathSkull:SetSize(skullSize, skullSize)
        frame.deathRow:Show()
    else
        frame.deathRow:Hide()
    end

    local topTextHeight = self:GetTimerTopTextHeight(db)
    stackRow(frame.timerSection, self:GetTimerSectionHeight(db), spacing.bar)

    self:ApplyTextLayer(frame.timerSection, frame.timerBar, {
        frame.maxTimer,
        frame.elapsed,
        frame.deathPenalty,
        frame.keyLevel,
        frame.milestoneTimer,
    })
    self:ApplyTextLayer(frame.forcesSection, frame.forcesBar, {
        frame.forcesPercent,
        frame.forcesDelta,
        frame.forcesRaw,
    })

    frame.timerBar:ClearAllPoints()
    frame.timerBar:SetPoint('TOPLEFT', frame.timerSection, 'TOPLEFT', 0, -topTextHeight)
    frame.timerBar:SetPoint('TOPRIGHT', frame.timerSection, 'TOPRIGHT', 0, -topTextHeight)

    frame.elapsed:ClearAllPoints()
    frame.elapsed:SetPoint('BOTTOMRIGHT', frame.timerBar, 'TOPRIGHT', 0, 0)
    frame.elapsed:SetJustifyH('RIGHT')

    frame.keyLevel:ClearAllPoints()
    frame.keyLevel:SetPoint('LEFT', frame.timerBar, 'TOPLEFT', 2, 0)
    frame.keyLevel:SetJustifyH('LEFT')

    frame.deathPenalty:ClearAllPoints()
    frame.deathPenalty:SetPoint('BOTTOMRIGHT', frame.elapsed, 'BOTTOMLEFT', -2, 2)
    frame.deathPenalty:SetJustifyH('RIGHT')

    if db.showMaxTimer then
        frame.maxTimer:ClearAllPoints()
        frame.maxTimer:SetPoint('BOTTOMRIGHT', frame.elapsed, 'TOPRIGHT', 0, 2)
        frame.maxTimer:SetJustifyH('RIGHT')
        frame.maxTimer:Show()
    else
        frame.maxTimer:Hide()
    end

    frame.milestoneTimer:ClearAllPoints()
    frame.milestoneTimer:SetJustifyH('CENTER')

    stackRow(frame.forcesSection, self:GetForcesSectionHeight(db), spacing.bar)

    frame.forcesBar:ClearAllPoints()
    frame.forcesBar:SetPoint('TOPLEFT', frame.forcesSection, 'TOPLEFT', 0, 0)
    frame.forcesBar:SetPoint('TOPRIGHT', frame.forcesSection, 'TOPRIGHT', 0, 0)

    frame.forcesPercent:ClearAllPoints()
    frame.forcesPercent:SetPoint('LEFT', frame.forcesBar, 'BOTTOMLEFT', 2, 0)
    frame.forcesPercent:SetJustifyH('LEFT')

    frame.forcesDelta:ClearAllPoints()
    frame.forcesDelta:SetPoint('LEFT', frame.forcesPercent, 'RIGHT', 4, 0)
    frame.forcesDelta:SetJustifyH('LEFT')

    frame.forcesRaw:ClearAllPoints()
    frame.forcesRaw:SetPoint('RIGHT', frame.forcesBar, 'BOTTOMRIGHT', -2, 0)
    frame.forcesRaw:SetJustifyH('RIGHT')

    if db.showBossNames then
        frame.bossSection:ClearAllPoints()
        frame.bossSection:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, yOffset)
        frame.bossSection:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, yOffset)
        frame.bossSection:Show()
    else
        frame.bossSection:Hide()
    end
end

function display:ApplyStyles(db)
    local frame = self.frame
    if not frame then
        return
    end

    local danger = EXUI.const.theme.danger

    self:ApplyFontString(frame.deathCount, 'deathFont', 'deathFontSize', 'deathFontFlag', db, {
        r = danger[1], g = danger[2], b = danger[3], a = danger[4] or 1,
    })
    frame.deathSkull:SetVertexColor(danger[1], danger[2], danger[3], danger[4] or 1)

    self:ApplyFontString(frame.maxTimer, 'maxTimerFont', 'maxTimerFontSize', 'maxTimerFontFlag', db, db.maxTimerColor,
        'bottom')
    self:ApplyFontString(frame.deathPenalty, 'deathPenaltyFont', 'deathPenaltyFontSize', 'deathPenaltyFontFlag', db, {
        r = danger[1], g = danger[2], b = danger[3], a = danger[4] or 1,
    }, 'bottom')
    self:ApplyFontString(frame.elapsed, 'elapsedFont', 'elapsedFontSize', 'elapsedFontFlag', db, db.elapsedColor,
        'bottom')
    self:ApplyFontString(frame.keyLevel, 'keyLevelFont', 'keyLevelFontSize', 'keyLevelFontFlag', db, db.elapsedColor)
    self:ApplyFontString(frame.milestoneTimer, 'milestoneFont', 'milestoneFontSize', 'milestoneFontFlag', db,
        db.elapsedColor)
    self:ApplyFontString(frame.forcesPercent, 'forcesPercentFont', 'forcesPercentFontSize', 'forcesPercentFontFlag', db,
        db.elapsedColor)
    self:ApplyFontString(frame.forcesDelta, 'forcesPercentFont', 'forcesPercentFontSize', 'forcesPercentFontFlag', db,
        db.elapsedColor)
    self:ApplyFontString(frame.forcesRaw, 'forcesRawFont', 'forcesRawFontSize', 'forcesRawFontFlag', db, db.elapsedColor)

    self:ApplyBarStyle(frame.timerBar, db.timerBar, db, self:GetTimerBarHeight(db))
    self:ApplyBarStyle(frame.forcesBar, db.forcesBar, db, self:GetForcesBarHeight(db))
    self:PositionSparks(frame.timerBar, db)
end

function display:UpdateBossList(snapshot, db)
    if not self.frame or not db.showBossNames then
        return 0
    end

    local bosses = snapshot and snapshot.bosses or {}
    local isRight = db.bossAlign == 'RIGHT'
    local lineSpacing = defaults.SPACING.bossLine
    local lineHeight = db.bossFontSize + lineSpacing
    local y = 0
    local applyFonts = not self._stylesApplied

    for index, boss in ipairs(bosses) do
        local line = self:GetBossLine(index)
        if line then
            if not line._exuiBossLaidOut then
                line:ClearAllPoints()
                line:SetPoint('TOPRIGHT', self.frame.bossSection, 'TOPRIGHT', 0, y)
                line:SetPoint('TOPLEFT', self.frame.bossSection, 'TOPLEFT', 0, y)
                line:SetJustifyH(isRight and 'RIGHT' or 'LEFT')
                line._exuiBossLaidOut = true
                applyFonts = true
            end
            if applyFonts or not line._exuiBossStyled then
                self:ApplyFontString(line, 'bossFont', 'bossFontSize', 'bossFontFlag', db)
                line._exuiBossStyled = true
            end

            local historic = db.showSplitComparison ~= false
                and snapshot.comparison
                and snapshot.comparison.bosses
                and snapshot.comparison.bosses[boss.order or index]
            local text
            if boss.killTime then
                line:SetTextColor(db.bossKilledColor.r, db.bossKilledColor.g, db.bossKilledColor.b,
                    db.bossKilledColor.a or 1)
                text = string.format('%s %s', boss.name, self:FormatClock(boss.killTime))
                if historic then
                    text = text .. ' ' .. self:ColorizeDelta(db, boss.killTime - historic)
                end
            else
                line:SetTextColor(db.bossPendingColor.r, db.bossPendingColor.g, db.bossPendingColor.b,
                    db.bossPendingColor.a or 1)
                if historic then
                    text = string.format('%s %s', boss.name, self:FormatClock(historic))
                else
                    text = boss.name
                end
            end
            if line._exuiBossText ~= text then
                line._exuiBossText = text
                line:SetText(text)
            end
            line:Show()
            y = y - lineHeight
        end
    end

    self:HideExtraBossLines(#bosses)
    return math.abs(y)
end

function display:PositionMilestoneTimer(barFrame, milestoneIndex, db, force)
    local timerText = self.frame and self.frame.milestoneTimer
    if not timerText then
        return
    end

    if not milestoneIndex then
        if timerText:IsShown() then
            timerText:Hide()
        end
        timerText._exuiMilestoneIndex = nil
        return
    end

    if not force and timerText._exuiMilestoneIndex == milestoneIndex and timerText:IsShown() then
        return
    end

    local barWidth = barFrame.border:GetWidth()
    local thresholds = defaults.UPGRADE_THRESHOLDS
    local fractions = { thresholds.plus3, thresholds.plus2, thresholds.plus1 }
    local fraction = fractions[milestoneIndex] or thresholds.plus1

    timerText:ClearAllPoints()
    if milestoneIndex == 3 then
        timerText:SetPoint('RIGHT', barFrame, 'BOTTOMRIGHT', -2, 0)
        timerText:SetJustifyH('RIGHT')
    else
        timerText:SetPoint('CENTER', barFrame, 'BOTTOM', (fraction - 0.5) * barWidth, 0)
        timerText:SetJustifyH('CENTER')
    end
    timerText._exuiMilestoneIndex = milestoneIndex
    timerText:Show()
end

local function setTextIfChanged(fontString, text)
    if fontString._exuiText == text then
        return
    end
    fontString._exuiText = text
    fontString:SetText(text)
end

function display:UpdateForcesDelta(snapshot, db)
    local frame = self.frame
    if not frame or not frame.forcesDelta then
        return
    end

    local deltaText = ''
    local color = db.elapsedColor
    local forcesPercent = snapshot.forces and snapshot.forces.percent or 0
    if db.showSplitComparison ~= false
        and snapshot.comparison
        and snapshot.comparison.forcesHistoric
        and forcesPercent > 0 then
        local delta = (snapshot.elapsed or 0) - snapshot.comparison.forcesHistoric
        deltaText = self:FormatDelta(delta)
        color = self:GetSplitColor(db, delta)
    end

    setTextIfChanged(frame.forcesDelta, deltaText)
    if color and frame.forcesDelta._exuiDeltaColor ~= color then
        frame.forcesDelta._exuiDeltaColor = color
        frame.forcesDelta:SetTextColor(color.r, color.g, color.b, color.a or 1)
    end
end

function display:RenderTickerSnapshot(snapshot, db)
    local frame = self.frame
    if not frame or not snapshot then
        return
    end

    local last = self._lastRender
    if not last then
        last = {}
        self._lastRender = last
    end

    local elapsedText = self:FormatClock(snapshot.elapsed)
    setTextIfChanged(frame.elapsed, elapsedText)

    local elapsedPercent = (snapshot.elapsedPercent or 0) * 100
    if last.elapsedPercent ~= elapsedPercent then
        last.elapsedPercent = elapsedPercent
        frame.timerBar.bar:SetValue(math.min(100, elapsedPercent))
    end
    self:PositionSparks(frame.timerBar, db, snapshot.elapsedPercent, false)

    if snapshot.milestoneIndex and snapshot.milestoneRemaining then
        setTextIfChanged(frame.milestoneTimer, self:FormatClock(snapshot.milestoneRemaining))
        self:PositionMilestoneTimer(frame.timerBar, snapshot.milestoneIndex, db, false)
    elseif frame.milestoneTimer:IsShown() then
        frame.milestoneTimer:Hide()
        frame.milestoneTimer._exuiMilestoneIndex = nil
        frame.milestoneTimer._exuiText = nil
    end
end

function display:RenderSnapshot(snapshot, db)
    local frame = self.frame
    if not frame or not snapshot then
        return
    end

    local last = self._lastRender
    if not last then
        last = {}
        self._lastRender = last
    end

    if db.showDeathCounter then
        setTextIfChanged(frame.deathCount, tostring(snapshot.deathCount or 0))
    end

    if db.showMaxTimer then
        setTextIfChanged(frame.maxTimer, self:FormatClock(snapshot.timeLimit))
    end

    if snapshot.showDeathPenalty then
        setTextIfChanged(frame.deathPenalty, self:FormatPenalty(snapshot.timeLost))
        if not frame.deathPenalty:IsShown() then
            frame.deathPenalty:Show()
        end
    elseif frame.deathPenalty:IsShown() then
        frame.deathPenalty:Hide()
    end

    setTextIfChanged(frame.elapsed, self:FormatClock(snapshot.elapsed))
    setTextIfChanged(frame.keyLevel, snapshot.levelText or '')

    local elapsedPercent = (snapshot.elapsedPercent or 0) * 100
    frame.timerBar.bar:SetValue(math.min(100, elapsedPercent))
    last.elapsedPercent = elapsedPercent
    self:PositionSparks(frame.timerBar, db, snapshot.elapsedPercent, true)

    if snapshot.milestoneIndex and snapshot.milestoneRemaining then
        setTextIfChanged(frame.milestoneTimer, self:FormatClock(snapshot.milestoneRemaining))
        self:PositionMilestoneTimer(frame.timerBar, snapshot.milestoneIndex, db, true)
    else
        frame.milestoneTimer:Hide()
        frame.milestoneTimer._exuiMilestoneIndex = nil
        frame.milestoneTimer._exuiText = nil
    end

    local forces = snapshot.forces
    if forces then
        frame.forcesBar.bar:SetValue(forces.percent or 0)
        setTextIfChanged(frame.forcesPercent, self:FormatPercent(forces.percent))
        setTextIfChanged(frame.forcesRaw, self:FormatForcesCount(forces.current, forces.total))
    else
        frame.forcesBar.bar:SetValue(0)
        setTextIfChanged(frame.forcesPercent, '0.00%')
        setTextIfChanged(frame.forcesRaw, self:FormatForcesCount(0, 0))
    end
    self:UpdateForcesDelta(snapshot, db)

    local bosses = snapshot.bosses or {}
    if frame.bossSection and frame.bossSection.lines then
        for _, line in ipairs(frame.bossSection.lines) do
            line._exuiBossLaidOut = nil
            line._exuiBossStyled = nil
        end
    end

    local bossHeight = self:UpdateBossList(snapshot, db)
    if db.showBossNames and bossHeight > 0 then
        EXUI:SetHeight(frame.bossSection, bossHeight)
    end
    local totalHeight = self:CalculateTotalHeight(db, #bosses, bossHeight)
    if last.totalHeight ~= totalHeight then
        last.totalHeight = totalHeight
        EXUI:SetHeight(frame, totalHeight)
    end
end

function display:CalculateTotalHeight(db, bossCount, bossSectionHeight)
    local spacing = defaults.SPACING
    local height = 0

    if db.showDeathCounter then
        height = height + db.deathFontSize + 2 + spacing.section
    end

    height = height + self:GetTimerSectionHeight(db) + spacing.bar
    height = height + self:GetForcesSectionHeight(db) + spacing.bar

    if db.showBossNames and bossCount > 0 then
        height = height + (bossSectionHeight or 0)
    end

    return math.max(height, 20)
end

function display:ShouldShow()
    if not mythicPlusTimer.enabled then
        return false
    end
    if preview:IsActive() then
        return true
    end
    return timerData:ShouldDisplay()
end

function display:ForceRestoreObjectiveTracker()
    if not self.lastShouldSuppressObjectiveTracker then
        return
    end

    local target = self.suppressionTarget
    self.lastShouldSuppressObjectiveTracker = false
    self.suppressionTarget = nil

    if target == 'exality' then
        objectiveTracker:Update()
    elseif target == 'blizzard' then
        self:ShowBlizzardTracker()
    end
end

function display:SyncObjectiveTrackerSuppression()
    local shouldSuppress = mythicPlusTimer:ShouldSuppressObjectiveTracker()
    if shouldSuppress == self.lastShouldSuppressObjectiveTracker then
        return
    end

    local wasSuppressing = self.lastShouldSuppressObjectiveTracker == true
    self.lastShouldSuppressObjectiveTracker = shouldSuppress

    if shouldSuppress then
        if objectiveTracker.enabled and objectiveTrackerDisplay.frame then
            self.suppressionTarget = 'exality'
            objectiveTrackerDisplay.frame:Hide()
        else
            self.suppressionTarget = 'blizzard'
            self:HideBlizzardTracker()
        end
        return
    end

    if wasSuppressing then
        local target = self.suppressionTarget
        self.suppressionTarget = nil
        if target == 'exality' then
            objectiveTracker:Update()
        elseif target == 'blizzard' then
            self:ShowBlizzardTracker()
        end
    end
end

function display:HideBlizzardTracker()
    if not ObjectiveTrackerFrame then
        return
    end

    if not self.blizzardShowHooked then
        self.blizzardShowHooked = true
        hooksecurefunc(ObjectiveTrackerFrame, 'Show', function()
            if mythicPlusTimer:ShouldSuppressObjectiveTracker() then
                ObjectiveTrackerFrame:Hide()
            end
        end)
    end

    ObjectiveTrackerFrame:Hide()
end

function display:ShowBlizzardTracker()
    if ObjectiveTrackerFrame then
        ObjectiveTrackerFrame:Show()
        if ObjectiveTrackerManager and (not canaccesssecrets or canaccesssecrets()) then
            ObjectiveTrackerManager:UpdateAll()
        end
    end
end

function display:InvalidateStyleCache()
    self._stylesApplied = false
    self._layoutApplied = false
    self._lastRender = nil
    if self.frame and self.frame.bossSection and self.frame.bossSection.lines then
        for _, line in ipairs(self.frame.bossSection.lines) do
            line._exuiBossLaidOut = nil
            line._exuiBossStyled = nil
            line._exuiBossText = nil
        end
    end
    if self.frame then
        if self.frame.timerBar then
            if self.frame.timerBar.spark1 then
                self.frame.timerBar.spark1._exuiSparkLaidOut = nil
            end
            if self.frame.timerBar.spark2 then
                self.frame.timerBar.spark2._exuiSparkLaidOut = nil
            end
        end
        if self.frame.milestoneTimer then
            self.frame.milestoneTimer._exuiMilestoneIndex = nil
            self.frame.milestoneTimer._exuiText = nil
        end
        if self.frame.forcesDelta then
            self.frame.forcesDelta._exuiText = nil
            self.frame.forcesDelta._exuiDeltaColor = nil
        end
    end
end

function display:Update(opts)
    opts = opts or {}
    local db = mythicPlusTimer.Data:GetDB()
    local isTicker = opts.ticker == true

    self:CreateMainFrame()

    -- Layout/styles only when cache is cold (options/configure) or first show.
    if not self._layoutApplied or not self._stylesApplied then
        self:ApplyLayout(db)
        self:ApplyStyles(db)
        self:SyncObjectiveTrackerSuppression()
        self._layoutApplied = true
        self._stylesApplied = true
    elseif not isTicker then
        -- Event-driven updates may still need OT suppression sync.
        self:SyncObjectiveTrackerSuppression()
    end

    if not self:ShouldShow() then
        self.frame:Hide()
        return
    end

    local snapshot = preview:GetSnapshot()
    if not snapshot then
        snapshot = timerData:GetDisplaySnapshot(isTicker)
    end

    if not snapshot then
        self.frame:Hide()
        return
    end

    if isTicker and not preview:IsActive() then
        self:RenderTickerSnapshot(snapshot, db)
    else
        self:RenderSnapshot(snapshot, db)
    end
    self.frame:Show()
end

function display:Enable()
    self:CreateMainFrame()
    self:InvalidateStyleCache()
    timerData:RegisterEvents(function()
        display:Update()
    end)
    timerData:StartTicker(function()
        if display:ShouldShow() then
            display:Update({ ticker = true })
        end
    end)
    if timerData:IsActive() then
        timerData:OnChallengeActivated()
    end
    self:Update()
end

function display:Disable()
    timerData:StopTicker()
    timerData:UnregisterEvents()
    self:ForceRestoreObjectiveTracker()
    if self.frame then
        self.frame:Hide()
    end
end

function display:Show()
    self:Update()
end

function display:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
