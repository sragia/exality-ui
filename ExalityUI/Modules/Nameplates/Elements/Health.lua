---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUINameplatesElementHealth
local health = EXUI:GetModule('np-element-health')

local CLASSIFICATION_COLORS = {
    elite = 'classificationElite',
    rare = 'classificationRare',
    rareelite = 'classificationRareElite',
    worldboss = 'classificationWorldBoss',
    minus = 'classificationMinus',
    trivial = 'classificationTrivial',
}

local function isPetUnit(unit)
    if UnitIsPlayer(unit) then
        return false
    end
    if UnitIsOtherPlayersPet and UnitIsOtherPlayersPet(unit) then
        return true
    end
    return UnitPlayerControlled(unit)
end

local function isCasting(unit)
    return UnitCastingInfo(unit) or UnitChannelInfo(unit)
end

local function unitHasMana(unit)
    return UnitPowerType(unit) == Enum.PowerType.Mana
end

local function classColor(unit)
    local _, class = UnitClass(unit)
    if class and C_ClassColor and C_ClassColor.GetClassColor then
        return C_ClassColor.GetClassColor(class)
    end
    return nil
end

health.Create = function(self, frame)
    local bar = CreateFrame('StatusBar', '$parent_Health', frame.HealthHost or frame, 'BackdropTemplate')
    bar:SetAllPoints()
    bar:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    bar.PostUpdateColor = self.PostUpdateColor
    bar.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut

    -- Blocks the inset border fill from showing through the empty portion of the bar.
    local occlude = bar:CreateTexture(nil, 'BACKGROUND', nil, -8)
    occlude:SetAllPoints()
    occlude:SetColorTexture(0, 0, 0, 1)
    bar.occlude = occlude

    local background = bar:CreateTexture(nil, 'BACKGROUND')
    background:SetAllPoints()
    background.multiplier = 1
    bar.bg = background

    return bar
end

local function applyBackdrop(bar, db)
    local backdrop = db and db.healthBackdropColor
    local r, g, b, a = 0, 0, 0, 1
    if backdrop then
        r, g, b, a = backdrop.r or 0, backdrop.g or 0, backdrop.b or 0, backdrop.a or 1
    end
    if bar.occlude then
        bar.occlude:SetColorTexture(r, g, b, 1)
        bar.occlude:Show()
    end
    if bar.bg then
        bar.bg:SetVertexColor(r, g, b, a)
    end
end

local function applyColor(bar, c)
    if not c then return false end
    if c.GetRGB then
        bar:SetStatusBarColor(c:GetRGB())
        return true
    end
    if c.r then
        bar:SetStatusBarColor(c.r, c.g, c.b, c.a or 1)
        return true
    end
    return false
end

health.PostUpdateColor = function(self, unit)
    local db = self.__owner and self.__owner.db
    unit = unit or (self.__owner and (self.__owner.unit or self.__owner.__unit))
    if not db or not unit then return end

    local applied = false

    if db.colorTapped and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
        applied = applyColor(self, db.tappedColor)
    end

    if not applied and db.colorQuest and (
        UnitIsQuestBoss(unit)
        or (C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest and C_QuestLog.UnitIsRelatedToActiveQuest(unit))
    ) then
        applied = applyColor(self, db.questColor)
    end

    if not applied and db.colorEnemyPlayer and UnitIsPlayer(unit) then
        if db.enemyPlayerUseClassColor then
            applied = applyColor(self, classColor(unit) or db.enemyPlayerColor)
        else
            applied = applyColor(self, db.enemyPlayerColor)
        end
    end

    if not applied and db.colorPet and isPetUnit(unit) then
        applied = applyColor(self, db.petColor)
    end

    if not applied and db.colorEncounterBoss and UnitIsBossMob and UnitIsBossMob(unit) then
        applied = applyColor(self, db.encounterBossColor)
    end

    if not applied and db.colorMana and unitHasMana(unit) then
        applied = applyColor(self, db.manaUnitColor)
    end

    if not applied and db.colorThreat and not UnitPlayerControlled(unit) then
        local playerStatus = UnitThreatSituation('player', unit)
        local coTank = db.colorCoTank and EXUI:GetModule('np-core'):GetCoTankUnit()
        local coTankStatus = coTank and UnitThreatSituation(coTank, unit)
        if coTankStatus == 3 and playerStatus ~= 3 then
            applied = applyColor(self, db.threatCoTank)
        elseif playerStatus == 3 then
            applied = applyColor(self, db.threatHaveAggro)
        elseif playerStatus ~= nil then
            applied = applyColor(self, db.threatNoAggro)
        end
    end

    if not applied and db.colorCasting and isCasting(unit) then
        applied = applyColor(self, db.castingColor)
    end

    if not applied and db.colorClassification then
        local classification = UnitClassification(unit)
        local key = CLASSIFICATION_COLORS[classification]
        if key then
            applied = applyColor(self, db[key])
        end
    end

    if not applied then
        if db.healthColorMode == 'reaction' then
            local reaction = UnitReaction(unit, 'player')
            local colors = self.__owner.colors and self.__owner.colors.reaction
            if reaction and colors and colors[reaction] then
                applied = applyColor(self, colors[reaction])
            end
        elseif db.healthColorMode == 'curve' then
            if self.values and self.values.EvaluateCurrentHealthPercent then
                local curveValues = {}
                for breakpoint, point in pairs(db.healthCurve or {}) do
                    curveValues[breakpoint] = CreateColor(point.r, point.g, point.b, point.a)
                end
                local c = self.values:EvaluateCurrentHealthPercent(curveValues)
                applied = applyColor(self, c)
            end
        end
        if not applied then
            applyColor(self, db.customHealthColor)
        end
    end

    applyBackdrop(self, db)
end

health.Update = function(self, frame)
    local db = frame.db
    local bar = frame.Health
    if frame.isFriendly then
        frame:DisableElement('Health')
        bar:Hide()
        if bar.bg then
            bar.bg:Hide()
        end
        if bar.occlude then
            bar.occlude:Hide()
        end
        EXUI:GetModule('np-core'):ApplyHealthChrome(frame)
        return
    end

    frame:EnableElement('Health')
    bar:Show()
    if bar.bg then
        bar.bg:Show()
    end
    applyBackdrop(bar, db)
    EXUI:GetModule('np-core'):ApplyHealthChrome(frame)
    bar.colorTapping = db.colorTapped
    bar.colorThreat = db.colorThreat
    bar.colorClass = false
    bar.colorReaction = false
    bar.colorSmooth = db.healthColorMode == 'curve'
    bar.colorHealth = true

    local texture = LSM:Fetch('statusbar', db.statusBarTexture or 'ExalityUI Status Bar')
    bar:SetStatusBarTexture(texture)
    bar.bg:SetTexture(texture)
end
