---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

local castBar = EXUI:GetModule('uf-element-cast-bar')

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')
---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

castBar.Create = function(self, frame, unit)
    local castBarContainer = CreateFrame('Frame', '$parent_CastBar', frame)
    local castBar = CreateFrame('StatusBar', nil, castBarContainer)
    castBar.container = castBarContainer
    castBar:SetSize(200, 20)
    castBar:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    castBar.PPBorder = EXUI:AddPixelPerfectBorder(castBar)

    -- Background
    local background = castBar:CreateTexture(nil, 'BACKGROUND')
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.5)
    castBar.bg = background

    -- Spark
    local spark = castBar:CreateTexture(nil, 'OVERLAY')
    spark:SetSize(1, 20)
    spark:SetBlendMode('ADD')
    spark:SetTexture(EXUI.const.textures.frame.solidBg)
    spark:SetVertexColor(1, 1, 1, 1)
    spark:SetPoint('CENTER', castBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
    castBar.Spark = spark

    -- Time
    local time = castBar:CreateFontString(nil, 'OVERLAY')
    time:SetPoint('RIGHT', -2, 0)
    time:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    castBar.Time = time

    -- Spell Text
    local spellText = castBar:CreateFontString(nil, 'OVERLAY')
    spellText:SetPoint('LEFT', 2, 0)
    spellText:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    spellText:SetWidth(300)
    spellText:SetHeight(20)
    spellText:SetJustifyH('LEFT')
    castBar.Text = spellText

    -- Icon
    local icon = castBar:CreateTexture(nil, 'OVERLAY')
    icon:SetSize(20, 20)
    icon:SetPoint('TOPLEFT', castBarContainer, 'TOPLEFT', 0, 0)
    icon:SetTexCoord(EXUI.utils.getTexCoords(1, 1, 30))
    castBar.Icon = icon


    if (frame.db.castbarAnchorToFrame) then
        castBarContainer:SetPoint(
            frame.db.castbarAnchorPoint,
            frame,
            frame.db.castbarRelativeAnchorPoint,
            frame.db.castbarXOff,
            frame.db.castbarYOff
        )
    else
        castBarContainer:SetPoint(
            frame.db.castbarAnchorPointUIParent,
            UIParent,
            frame.db.castbarRelativeAnchorPointUIParent,
            frame.db.castbarXOffUIParent,
            frame.db.castbarYOffUIParent
        )
    end
    castBar:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', 0, 0)
    castBar:SetPoint('TOPRIGHT')

    castBar.CreatePip = function(self)
        local db = self.__owner.db
        local pip = CreateFrame('Frame', nil, self)
        pip:SetWidth(db.castbarEmpoweredStageWidth or 1)
        local line = pip:CreateTexture(nil, 'OVERLAY')
        line:SetAllPoints()
        line:SetBlendMode('ADD')
        line:SetTexture(EXUI.const.textures.frame.solidBg)
        line:SetVertexColor(db.castbarEmpoweredStageColor.r or 1, db.castbarEmpoweredStageColor.g or 1,
            db.castbarEmpoweredStageColor.b or 1, db.castbarEmpoweredStageColor.a or 1)
        pip.line = line

        return pip
    end

    return castBar
end

castBar.Update = function(self, frame)
    local db = frame.db
    local generalDB = frame.generalDB
    local Castbar = frame.Castbar
    local container = Castbar.container

    if (not db.castbarEnable) then
        frame:DisableElement('Castbar')
        return
    end

    frame:EnableElement('Castbar')

    local iconSize = db.castbarHeight
    if (db.castbarMatchFrameWidth) then
        local frameWidth = db.sizeWidth
        EXUI:SetSize(container, frameWidth, db.castbarHeight)
    else
        EXUI:SetSize(container, db.castbarWidth, db.castbarHeight)
    end
    EXUI:SetSize(Castbar.Icon, iconSize, iconSize)
    Castbar.Time:SetFont(LSM:Fetch('font', db.castbarFont), db.castbarFontSize, db.castbarFontFlag)
    Castbar.Time:SetVertexColor(db.castbarFontColor.r, db.castbarFontColor.g, db.castbarFontColor.b,
        db.castbarFontColor.a)
    Castbar.Text:SetFont(LSM:Fetch('font', db.castbarFont), db.castbarFontSize, db.castbarFontFlag)
    Castbar.Text:SetVertexColor(db.castbarFontColor.r, db.castbarFontColor.g, db.castbarFontColor.b,
        db.castbarFontColor.a)
    Castbar.Text:SetWidth(container:GetWidth() - 50)
    Castbar.Text:SetHeight(db.castbarHeight)

    for _, pip in pairs(Castbar.Pips or {}) do
        pip:SetWidth(db.castbarEmpoweredStageWidth or 1)
        pip.line:SetVertexColor(db.castbarEmpoweredStageColor.r or 1, db.castbarEmpoweredStageColor.g or 1,
            db.castbarEmpoweredStageColor.b or 1, db.castbarEmpoweredStageColor.a or 1)
    end

    Castbar.Spark:SetVertexColor(db.castbarSparkColor.r or 1, db.castbarSparkColor.g or 1,
        db.castbarSparkColor.b or 1, db.castbarSparkColor.a or 1)
    EXUI:SetWidth(Castbar.Spark, db.castbarSparkWidth or 1)
    EXUI:SetHeight(Castbar.Spark, db.castbarHeight)

    Castbar.bg:SetColorTexture(db.castbarBackgroundColor.r, db.castbarBackgroundColor.g, db.castbarBackgroundColor.b,
        db.castbarBackgroundColor.a)
    Castbar.PPBorder:SetBorderColor(
        db.castbarBackgroundBorderColor.r,
        db.castbarBackgroundBorderColor.g,
        db.castbarBackgroundBorderColor.b,
        db.castbarBackgroundBorderColor.a
    )
    Castbar:SetStatusBarColor(
        db.castbarForegroundColor.r,
        db.castbarForegroundColor.g,
        db.castbarForegroundColor.b,
        db.castbarForegroundColor.a
    )

    local statusBarTexture = db.overrideStatusBarTexture ~= '' and db.overrideStatusBarTexture or
        generalDB.statusBarTexture

    Castbar:SetStatusBarTexture(LSM:Fetch('statusbar', statusBarTexture))

    container:ClearAllPoints()
    if (db.castbarAnchorToFrame) then
        EXUI:SetPoint(container,
            db.castbarAnchorPoint,
            frame,
            db.castbarRelativeAnchorPoint,
            db.castbarXOff,
            db.castbarYOff)
    else
        EXUI:SetPoint(container,
            db.castbarAnchorPointUIParent,
            UIParent,
            db.castbarRelativeAnchorPointUIParent,
            db.castbarXOffUIParent,
            db.castbarYOffUIParent
        )
    end

    self:UpdateMover(frame)

    if (frame:IsElementPreviewEnabled('castbar') and not Castbar:IsShown()) then
        local dur = C_DurationUtil.CreateDuration()
        dur:SetTimeFromStart(GetTime(), 12)
        Castbar.isPreview = true
        if (not Castbar.BAKOnUpdate) then
            Castbar.BAKOnUpdate = Castbar:GetScript('OnUpdate')
            Castbar:SetScript('OnUpdate', function(self, elapsed)
                local durationObject = self:GetTimerDuration() -- can be nil
                if (durationObject) then
                    self.Time:SetFormattedText('%.1f', durationObject:GetRemainingDuration())
                end
            end)
        end
        Castbar:SetTimerDuration(dur, Castbar.smoothing or Enum.StatusBarInterpolation.Immediate,
            Enum.StatusBarTimerDirection.ElapsedTime)
        Castbar.Text:SetText('Preview Spell')
        Castbar.Icon:SetTexture(656176)
        Castbar:Show()
    elseif (not frame:IsElementPreviewEnabled('castbar') and Castbar.isPreview) then
        Castbar:Hide()
        Castbar:SetScript('OnUpdate', Castbar.BAKOnUpdate)
        Castbar.BAKOnUpdate = nil
        Castbar.isPreview = false
    end
end

castBar.UpdateMover = function(self, baseFrame)
    local container = baseFrame.Castbar.container
    if (not baseFrame.db.castbarEnable) then
        if (editor:IsFrameRegistered(container)) then
            editor:UnregisterFrameForEditor(container)
        end
        return
    end

    if (not editor:IsFrameRegistered(container) and not baseFrame.db.castbarAnchorToFrame) then
        local label = EXUI.utils.capitalize(baseFrame.unit)

        editor:RegisterFrameForEditor(container, label .. ' Cast Bar', function(frame)
            local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
            core:UpdateValueForUnit(baseFrame.unit, 'castbarAnchorPointUIParent', point)
            core:UpdateValueForUnit(baseFrame.unit, 'castbarRelativeAnchorPointUIParent', relativePoint)
            core:UpdateValueForUnit(baseFrame.unit, 'castbarXOffUIParent', xOfs)
            core:UpdateValueForUnit(baseFrame.unit, 'castbarYOffUIParent', yOfs)
            core:UpdateFrameForUnit(baseFrame.unit)
        end)
    elseif (editor:IsFrameRegistered(container) and baseFrame.db.castbarAnchorToFrame) then
        editor:UnregisterFrameForEditor(container)
    end
end
