---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUINameplatesElementCastBar
local castBar = EXUI:GetModule('np-element-cast-bar')

local INTERRUPTED = _G.INTERRUPTED or 'Interrupted'

local function applyDrawLayers(bar)
    local texture = bar:GetStatusBarTexture()
    if texture then
        texture:SetDrawLayer('BORDER', 0)
    end
end

local function updatePips(element, stages)
    local elementSize = element.layoutSize
    if not stages or not elementSize then
        return
    end

    local reverseFill = element:GetReverseFill()
    local lastOffset = 0
    element.Pips = element.Pips or {}
    for stage, stageSection in next, stages do
        local offset = lastOffset + (elementSize * stageSection)
        lastOffset = offset

        local pip = element.Pips[stage]
        if not pip then
            pip = element:CreatePip(stage)
            element.Pips[stage] = pip
        end

        pip:ClearAllPoints()
        pip:Show()
        if reverseFill then
            pip:SetPoint('TOP', element, 'TOPRIGHT', -offset, 0)
            pip:SetPoint('BOTTOM', element, 'BOTTOMRIGHT', -offset, 0)
        else
            pip:SetPoint('TOP', element, 'TOPLEFT', offset, 0)
            pip:SetPoint('BOTTOM', element, 'BOTTOMLEFT', offset, 0)
        end
    end

    if element.PostUpdatePips then
        element:PostUpdatePips(stages)
    end
end

local function showContainer(element)
    if element.container then
        element.container:Show()
    end
end

local function plateDB(element)
    local owner = element and element.__owner
    return owner and owner.db
end

local function classColor(class)
    if class and C_ClassColor and C_ClassColor.GetClassColor then
        return C_ClassColor.GetClassColor(class)
    end
    return nil
end

local function setTimeBindingEnabled(element, enabled)
    local time = element.Time
    if time and time.binding then
        time.binding:SetEnabled(enabled)
    end
    if time and not enabled then
        time:SetText('')
    end
end

local function setUninterruptibleShown(element, shown)
    if element.Uninterruptible then
        element.Uninterruptible:SetAlphaFromBoolean(shown, 1, 0)
    end
end

local function restoreCastVisuals(element)
    local db = plateDB(element)
    element.interruptHold = nil
    element.interruptClassColor = nil
    element:SetAlpha(1)
    if element.chrome then
        element.chrome:SetAlpha(1)
    end
    if element.Icon then
        element.Icon:SetAlpha(1)
    end
    setUninterruptibleShown(element, false)
    if element.InterruptText then
        element.InterruptText:Hide()
    end
    if element.Text then
        element.Text:SetShown(not db or db.castbarShowName)
    end
    if element.Time then
        element.Time:SetShown(not db or db.castbarShowTime)
        setTimeBindingEnabled(element, true)
    end
end

local function applyInterruptTextColor(element, db)
    local interruptText = element.InterruptText
    if not interruptText then
        return
    end
    local color = element.interruptClassColor
    if not color then
        color = db and db.castbarInterruptColor or { r = 1, g = 1, b = 1, a = 1 }
    end
    interruptText:SetVertexColor(color.r, color.g, color.b, 1)
end

local function updateTargetText(element, unit)
    local target = element.TargetText
    if not target then
        return
    end
    local db = plateDB(element)
    if not db or not db.castbarShowTarget or element.interruptHold then
        target:Hide()
        return
    end
    if not unit or not UnitShouldDisplaySpellTargetName or not UnitShouldDisplaySpellTargetName(unit) then
        target:SetText('')
        target:Hide()
        return
    end
    target:SetText(UnitSpellTargetName(unit))
    local color = classColor(UnitSpellTargetClass and UnitSpellTargetClass(unit))
    if color then
        target:SetVertexColor(color.r, color.g, color.b, color.a or 1)
    else
        local fontColor = db.castbarFontColor
        target:SetVertexColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)
    end
    target:Show()
end

local function applyInterruptHold(element, interruptedBy)
    local db = plateDB(element)
    if not db or not db.castbarShowInterrupt then
        restoreCastVisuals(element)
        return
    end

    element.interruptHold = true
    if C_DurationUtil and C_DurationUtil.CreateDuration and element.SetTimerDuration then
        local finished = C_DurationUtil.CreateDuration()
        element:SetTimerDuration(finished, Enum.StatusBarInterpolation.Immediate)
    end
    element:SetMinMaxValues(0, 1)
    element:SetValue(1)
    if element.SetToTargetValue then
        element:SetToTargetValue()
    end
    if element.Spark then
        element.Spark:Hide()
    end
    if element.Text then
        element.Text:SetText(INTERRUPTED)
        element.Text:SetShown(db.castbarShowName)
    end
    setTimeBindingEnabled(element, false)
    if element.Time then
        element.Time:SetShown(db.castbarShowTime)
    end
    if element.TargetText then
        element.TargetText:Hide()
    end
    setUninterruptibleShown(element, true)

    local interruptText = element.InterruptText
    if not interruptText then
        return
    end
    local name
    if interruptedBy and UnitNameFromGUID then
        name = UnitNameFromGUID(interruptedBy)
    end
    if name then
        interruptText:SetText(name)
    else
        interruptText:SetText(INTERRUPTED)
    end
    element.interruptClassColor = nil
    if interruptedBy and UnitClassFromGUID then
        local _, classFilename = UnitClassFromGUID(interruptedBy)
        element.interruptClassColor = classColor(classFilename)
    end
    applyInterruptTextColor(element, db)
    interruptText:Show()
end

local function syncUninterruptible(element, _, _, notInterruptible)
    showContainer(element)
    if not element.Uninterruptible then
        return
    end
    if notInterruptible == nil then
        return
    end
    element.Uninterruptible:SetAlphaFromBoolean(notInterruptible, 1, 0)
end

local function onCastStart(element, unit, spellID, notInterruptible)
    restoreCastVisuals(element)
    syncUninterruptible(element, unit, spellID, notInterruptible)
    updateTargetText(element, unit)
end

castBar.Create = function(self, frame)
    local container = CreateFrame('Frame', '$parent_CastBar', frame)
    local chrome = CreateFrame('Frame', nil, container)
    local bar = CreateFrame('StatusBar', nil, chrome)
    bar.container = container
    bar.chrome = chrome
    chrome.BorderFill = chrome:CreateTexture(nil, 'BACKGROUND')
    chrome.BorderFill:SetAllPoints()
    chrome.BorderFill:SetColorTexture(0, 0, 0, 1)

    bar:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    applyDrawLayers(bar)

    local background = bar:CreateTexture(nil, 'BACKGROUND')
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.5)
    bar.bg = background

    local uninterruptible = bar:CreateTexture(nil, 'ARTWORK', nil, 1)
    uninterruptible:SetAllPoints(bar:GetStatusBarTexture())
    uninterruptible:SetTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    uninterruptible:SetAlpha(0)
    bar.Uninterruptible = uninterruptible

    local spark = bar:CreateTexture(nil, 'OVERLAY')
    spark:SetSize(1, 12)
    spark:SetBlendMode('ADD')
    spark:SetTexture(EXUI.const.textures.frame.solidBg)
    spark:SetPoint('CENTER', bar:GetStatusBarTexture(), 'RIGHT', 0, 0)
    bar.Spark = spark

    local time = bar:CreateFontString(nil, 'OVERLAY')
    time:SetPoint('RIGHT', -2, 0)
    time:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    bar.Time = time

    local spellText = bar:CreateFontString(nil, 'OVERLAY')
    spellText:SetPoint('LEFT', 2, 0)
    spellText:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    spellText:SetJustifyH('LEFT')
    bar.Text = spellText

    local targetText = bar:CreateFontString(nil, 'OVERLAY')
    targetText:SetPoint('RIGHT', -2, 0)
    targetText:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    targetText:SetJustifyH('RIGHT')
    targetText:Hide()
    bar.TargetText = targetText

    local interruptText = bar:CreateFontString(nil, 'OVERLAY')
    interruptText:SetPoint('RIGHT', bar, 'RIGHT', -2, 0)
    interruptText:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    interruptText:SetJustifyH('RIGHT')
    interruptText:Hide()
    bar.InterruptText = interruptText

    local icon = container:CreateTexture(nil, 'OVERLAY')
    icon:SetSize(12, 12)
    icon:SetPoint('TOPLEFT', container, 'TOPLEFT', 0, 0)
    icon:SetTexCoord(EXUI.utils.getTexCoords(1, 1, 30))
    bar.Icon = icon

    chrome:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', 0, 0)
    chrome:SetPoint('TOPRIGHT')
    bar:SetAllPoints(chrome)

    bar:HookScript('OnShow', function(selfBar)
        showContainer(selfBar)
        if selfBar.Uninterruptible then
            selfBar.Uninterruptible:ClearAllPoints()
            selfBar.Uninterruptible:SetAllPoints(selfBar:GetStatusBarTexture())
        end
        syncUninterruptible(selfBar)
    end)
    bar:HookScript('OnHide', function(selfBar)
        restoreCastVisuals(selfBar)
        if selfBar.container then
            selfBar.container:Hide()
        end
    end)

    bar.CreatePip = function(self)
        local db = plateDB(self)
        local pip = CreateFrame('Frame', nil, self)
        pip:SetWidth(db and db.castbarSparkWidth or 1)
        local line = pip:CreateTexture(nil, 'OVERLAY')
        line:SetAllPoints()
        line:SetBlendMode('ADD')
        line:SetTexture(EXUI.const.textures.frame.solidBg)
        local color = db and db.castbarSparkColor or { r = 1, g = 1, b = 1, a = 1 }
        line:SetVertexColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        pip.line = line
        return pip
    end
    bar.UpdatePips = updatePips
    bar.layoutSize = 140

    bar.ShouldShow = function(element, unit)
        local owner = element.__owner
        local ownerUnit = owner and (owner.__unit or owner.unit)
        if not unit or not ownerUnit then
            return false
        end
        return unit == ownerUnit or UnitIsUnit(unit, ownerUnit)
    end

    bar.PostCastStart = onCastStart
    bar.PostChannelStart = onCastStart
    bar.PostCastInterruptible = syncUninterruptible
    bar.PostCastNotInterruptible = syncUninterruptible
    bar.PostCastInterrupted = function(element, _, _, interruptedBy)
        applyInterruptHold(element, interruptedBy)
    end
    bar.PostCastFail = function(element)
        restoreCastVisuals(element)
    end
    bar.PostCastUpdate = function(element, unit)
        updateTargetText(element, unit)
    end

    bar:Hide()
    container:Hide()
    return bar
end

castBar.Update = function(self, frame)
    local db = frame.db
    local bar = frame.Castbar
    local container = bar.container

    if frame.isFriendly or not db.castbarEnable then
        frame:DisableElement('Castbar')
        restoreCastVisuals(bar)
        container:Hide()
        return
    end

    frame:EnableElement('Castbar')
    bar.timeToHold = db.castbarShowInterrupt and (db.castbarInterruptHold or 1) or 0

    local barHeight = db.castbarHeight or 12
    local iconWidth = db.castbarShowIcon and (db.castbarIconWidth or barHeight) or 0
    local width = db.sizeWidth
    local chrome = bar.chrome
    container:SetSize(width, barHeight)
    if db.castbarShowIcon then
        bar.Icon:Show()
        bar.Icon:ClearAllPoints()
        bar.Icon:SetPoint('TOPLEFT', container, 'TOPLEFT', 0, 0)
        bar.Icon:SetPoint('BOTTOMLEFT', container, 'BOTTOMLEFT', 0, 0)
        bar.Icon:SetWidth(iconWidth)
        bar.Icon:SetTexCoord(EXUI.utils.getTexCoords(iconWidth, barHeight, 30))
        chrome:ClearAllPoints()
        chrome:SetPoint('BOTTOMLEFT', bar.Icon, 'BOTTOMRIGHT', 0, 0)
        chrome:SetPoint('TOPRIGHT')
    else
        bar.Icon:Hide()
        chrome:ClearAllPoints()
        chrome:SetAllPoints(container)
    end
    local npCore = EXUI:GetModule('np-core')
    npCore:ApplyCastChrome(bar, db)
    local inset = npCore:GetChromeInset(npCore:GetBorderThickness(db), barHeight)
    bar.layoutSize = math.max(1, width - iconWidth - inset * 2)

    local font = LSM:Fetch('font', db.castbarFont)
    local fontColor = db.castbarFontColor
    local nameSize = db.castbarNameFontSize or db.castbarFontSize or 10
    local timeSize = db.castbarTimeFontSize or db.castbarFontSize or 10
    local targetSize = db.castbarTargetFontSize or 10
    local interruptSize = db.castbarInterruptFontSize or 10
    local holding = bar.interruptHold

    bar.Text:SetFont(font, nameSize, db.castbarFontFlag)
    bar.Text:SetVertexColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)
    bar.Text:ClearAllPoints()
    bar.Text:SetPoint(
        db.castbarNameAnchorPoint or 'LEFT',
        bar,
        db.castbarNameRelativeAnchorPoint or 'LEFT',
        db.castbarNameXOffset or 2,
        db.castbarNameYOffset or 0
    )
    bar.Text:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(db.castbarNameAnchorPoint or 'LEFT'))
    bar.Text:SetWidth(math.max(20, width - (db.castbarShowIcon and iconWidth or 0) - 40))
    bar.Text:SetHeight(nameSize + nameSize / 2)
    bar.Text:SetShown(db.castbarShowName)
    if holding then
        bar.Text:SetText(INTERRUPTED)
    end

    bar.Time:SetFont(font, timeSize, db.castbarFontFlag)
    bar.Time:SetVertexColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)
    bar.Time:ClearAllPoints()
    bar.Time:SetPoint(
        db.castbarTimeAnchorPoint or 'RIGHT',
        bar,
        db.castbarTimeRelativeAnchorPoint or 'RIGHT',
        db.castbarTimeXOffset or -2,
        db.castbarTimeYOffset or 0
    )
    bar.Time:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(db.castbarTimeAnchorPoint or 'RIGHT'))
    bar.Time:SetShown(db.castbarShowTime)
    if holding then
        setTimeBindingEnabled(bar, false)
    end

    bar.TargetText:SetFont(font, targetSize, db.castbarFontFlag)
    bar.TargetText:ClearAllPoints()
    bar.TargetText:SetPoint(
        db.castbarTargetAnchorPoint or 'RIGHT',
        bar,
        db.castbarTargetRelativeAnchorPoint or 'RIGHT',
        db.castbarTargetXOffset or -2,
        db.castbarTargetYOffset or 0
    )
    bar.TargetText:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(db.castbarTargetAnchorPoint or 'RIGHT'))
    bar.TargetText:SetHeight(targetSize + targetSize / 2)
    if not holding then
        local ownerUnit = frame.unit or frame.__unit
        if ownerUnit then
            updateTargetText(bar, ownerUnit)
        elseif not db.castbarShowTarget then
            bar.TargetText:Hide()
        end
    else
        bar.TargetText:Hide()
    end

    local interruptFont = LSM:Fetch('font', db.castbarInterruptFont or db.castbarFont)
    bar.InterruptText:SetFont(interruptFont, interruptSize, db.castbarInterruptFontFlag or db.castbarFontFlag)
    bar.InterruptText:ClearAllPoints()
    bar.InterruptText:SetPoint(
        db.castbarInterruptAnchorPoint or 'RIGHT',
        bar,
        db.castbarInterruptRelativeAnchorPoint or 'RIGHT',
        db.castbarInterruptXOffset or -2,
        db.castbarInterruptYOffset or 0
    )
    bar.InterruptText:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(db.castbarInterruptAnchorPoint or 'RIGHT'))
    bar.InterruptText:SetHeight(interruptSize + interruptSize / 2)
    if holding then
        applyInterruptTextColor(bar, db)
        bar.InterruptText:Show()
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(1)
        setUninterruptibleShown(bar, true)
    else
        bar.InterruptText:Hide()
    end

    bar.Spark:SetVertexColor(db.castbarSparkColor.r, db.castbarSparkColor.g, db.castbarSparkColor.b, db.castbarSparkColor.a)
    bar.Spark:SetWidth(db.castbarSparkWidth or 1)
    bar.Spark:SetHeight(barHeight)

    for _, pip in pairs(bar.Pips or {}) do
        pip:SetWidth(db.castbarSparkWidth or 1)
        if pip.line then
            pip.line:SetVertexColor(db.castbarSparkColor.r, db.castbarSparkColor.g, db.castbarSparkColor.b, db.castbarSparkColor.a)
        end
    end

    bar.bg:SetColorTexture(db.castbarBackgroundColor.r, db.castbarBackgroundColor.g, db.castbarBackgroundColor.b, db.castbarBackgroundColor.a)
    bar:SetStatusBarColor(db.castbarForegroundColor.r, db.castbarForegroundColor.g, db.castbarForegroundColor.b, db.castbarForegroundColor.a)

    local texture = LSM:Fetch('statusbar', db.statusBarTexture or 'ExalityUI Status Bar')
    bar:SetStatusBarTexture(texture)
    applyDrawLayers(bar)
    bar.Uninterruptible:SetTexture(texture)
    bar.Uninterruptible:SetVertexColor(
        db.castbarUninterruptibleColor.r,
        db.castbarUninterruptibleColor.g,
        db.castbarUninterruptibleColor.b,
        db.castbarUninterruptibleColor.a or 1
    )

    local anchor = frame.HealthHost or frame
    container:ClearAllPoints()
    container:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, db.castbarYOff or -1)
    container:SetPoint('TOPRIGHT', anchor, 'BOTTOMRIGHT', 0, db.castbarYOff or -1)
end
