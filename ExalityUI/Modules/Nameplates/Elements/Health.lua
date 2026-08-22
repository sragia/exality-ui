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

local function isMiniboss(unit)
    if UnitIsPlayer(unit) or UnitPlayerControlled(unit) then
        return false
    end
    if UnitIsBossMob and UnitIsBossMob(unit) then
        return true
    end
    if UnitIsLieutenant and UnitIsLieutenant(unit) then
        return true
    end
    local unitLevel = UnitEffectiveLevel(unit)
    local playerLevel = UnitEffectiveLevel('player')
    if issecretvalue and (issecretvalue(unitLevel) or issecretvalue(playerLevel)) then
        return false
    end
    return unitLevel > 0 and unitLevel == playerLevel + 1
end

local function unitHasMana(unit)
    return UnitPowerType(unit) == Enum.PowerType.Mana
end

local function inDungeonOrRaid()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == 'party' or instanceType == 'raid')
end

local function inDungeon()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == 'party'
end

local function playerIsTank()
    if IsInGroup() then
        local role = UnitGroupRolesAssigned('player')
        if role ~= 'NONE' then
            return role == 'TANK'
        end
    end
    local spec = GetSpecialization and GetSpecialization()
    return spec and GetSpecializationRole and GetSpecializationRole(spec) == 'TANK'
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

local function applyThreatColor(bar, db, unit)
    if UnitPlayerControlled(unit) then
        return false
    end
    local playerStatus = UnitThreatSituation('player', unit)
    if playerStatus == nil then
        return false
    end
    local tankAggro = db.colorCoTank and EXUI:GetModule('np-core'):OtherTankHasAggro(unit)
    if playerStatus == 3 then
        return applyColor(bar, db.threatHaveAggro)
    end
    if playerStatus == 2 then
        return applyColor(bar, db.threatAggroLow or db.threatHaveAggro)
    end
    if playerStatus == 1 then
        if tankAggro then
            return applyColor(bar, db.threatPullingTank or db.threatNoAggro)
        end
        return applyColor(bar, db.threatNoAggro)
    end
    if tankAggro then
        return applyColor(bar, db.threatCoTank)
    end
    return applyColor(bar, db.threatNoAggro)
end

local function applyCasterColor(bar, db, unit)
    if not db.colorCaster or not inDungeonOrRaid() or not unitHasMana(unit) then
        return false
    end
    return applyColor(bar, db.casterColor or db.manaUnitColor)
end

local function applyMinibossColor(bar, db, unit)
    if not db.colorMiniboss or not isMiniboss(unit) then
        return false
    end
    return applyColor(bar, db.minibossColor)
end

health.PostUpdateColor = function(self, unit)
    local db = self.__owner and self.__owner.db
    unit = unit or (self.__owner and (self.__owner.unit or self.__owner.__unit))
    if not db or not unit then return end

    local applied = false

    if db.colorTapped and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
        applied = applyColor(self, db.tappedColor)
    end

    local rankOverThreat = db.rankOverThreatInDungeon and playerIsTank() and inDungeon()
    if not applied and rankOverThreat then
        applied = applyCasterColor(self, db, unit)
        if not applied then
            applied = applyMinibossColor(self, db, unit)
        end
    end

    if not applied and db.colorThreat then
        applied = applyThreatColor(self, db, unit)
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

    if not applied and db.colorNeutral then
        local reaction = UnitReaction(unit, 'player')
        if reaction == 4 then
            applied = applyColor(self, db.neutralColor)
        elseif reaction == 3 then
            applied = applyColor(self, db.unfriendlyColor or db.neutralColor)
        end
    end

    if not applied then
        applied = applyCasterColor(self, db, unit)
    end

    if not applied and db.colorCasting and isCasting(unit) then
        applied = applyColor(self, db.castingColor)
    end

    if not applied then
        applied = applyMinibossColor(self, db, unit)
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
    EXUI:GetModule('np-element-target-highlight'):ApplyHealthLighten(self.__owner, self)
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
