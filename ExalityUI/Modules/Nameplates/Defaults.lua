---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesDefaults
local defaults = EXUI:GetModule('np-defaults')

defaults.SCHEMA_VERSION = 1

local function color(r, g, b, a)
    return { r = r, g = g, b = b, a = a or 1 }
end

defaults.PLATE = {
    enable = false,
    sizeWidth = 260,
    sizeHeight = 30,
    statusBarTexture = 'ExalityUI Status Bar',
    -- Inset fill, not a 1px line. Thickness is physical pixels.
    borderThickness = 1,
    borderColor = color(0, 0, 0, 1),

    -- Health coloring
    healthColorMode = 'custom', -- custom | reaction | curve
    customHealthColor = color(0.82, 0.2, 0.2),
    healthBackdropColor = color(0.12, 0.12, 0.12, 1),
    healthCurve = {
        [0] = color(217 / 255, 0, 22 / 255),
        [0.25] = color(217 / 255, 87 / 255, 0),
        [0.5] = color(217 / 255, 152 / 255, 0),
        [0.75] = color(94 / 255, 79 / 255, 0),
        [1] = color(0.15, 0.7, 0.15),
    },
    colorTapped = true,
    tappedColor = color(0.6, 0.6, 0.6),
    colorQuest = true,
    questColor = color(1, 0.7, 0),
    colorThreat = true,
    threatHaveAggro = color(0.49, 0.18, 0.85),
    threatAggroLow = color(1, 0.92, 0.2),
    threatNoAggro = color(0.82, 0.2, 0.2),
    colorCoTank = true,
    threatCoTank = color(0, 0.77, 0.4),
    threatPullingTank = color(1, 0.62, 0.15),
    rankOverThreatInDungeon = false,
    colorMiniboss = true,
    minibossColor = color(0.9, 0, 0.71),
    colorClassification = false,
    classificationElite = color(1, 0.52, 0),
    classificationRare = color(0.4, 0.7, 1),
    classificationRareElite = color(0.7, 0.45, 1),
    classificationWorldBoss = color(1, 0.45, 0.15),
    classificationMinus = color(0.55, 0.55, 0.55),
    classificationTrivial = color(0.48, 0.5, 0.36),
    colorEncounterBoss = true,
    encounterBossColor = color(0.78, 0.28, 0.22),
    colorEnemyPlayer = true,
    enemyPlayerUseClassColor = true,
    enemyPlayerColor = color(0.22, 0.68, 0.62),
    colorPet = false,
    petColor = color(0.68, 0.4, 0.48),
    colorNeutral = true,
    neutralColor = color(0.9, 0.7, 0),
    unfriendlyColor = color(0.75, 0.27, 0),
    colorCasting = false,
    castingColor = color(0.92, 0.58, 0.22),
    colorCaster = true,
    casterColor = color(0.25, 0.48, 0.86),
    friendlyNpcColor = color(0.3, 1, 0.3),

    -- Absorbs
    damageAbsorbEnable = true,
    damageAbsorbShowOverIndicator = true,
    damageAbsorbShowAt = 'AS_EXTENSION',
    damageAbsorbTexture = 'ExalityUI Absorb Bar',
    damageAbsorbColor = color(0.39, 0.89, 1),
    healAbsorbEnable = true,
    healAbsorbShowOverIndicator = true,
    healAbsorbTexture = 'ExalityUI Status Bar',
    healAbsorbColor = color(100 / 255, 100 / 255, 100 / 255, 0.8),

    -- Name
    nameEnable = true,
    nameFont = 'DMSans',
    nameFontSize = 13,
    nameFontFlag = 'OUTLINE',
    nameFontColor = color(1, 1, 1),
    nameAnchorPoint = 'LEFT',
    nameRelativeAnchorPoint = 'LEFT',
    nameXOffset = 3,
    nameYOffset = 0,
    nameMaxWidth = 70,
    nameTag = '[name]',

    -- Health text
    healthEnable = true,
    healthFont = 'DMSans',
    healthFontSize = 11,
    healthFontFlag = 'OUTLINE',
    healthFontColor = color(1, 1, 1),
    healthAnchorPoint = 'RIGHT',
    healthRelativeAnchorPoint = 'BOTTOMRIGHT',
    healthXOffset = -2,
    healthYOffset = -2,
    healthTag = '[curhp:formatted]',

    -- Health percent
    healthpercEnable = true,
    healthpercFont = 'DMSans',
    healthpercFontSize = 16,
    healthpercFontFlag = 'OUTLINE',
    healthpercFontColor = color(1, 1, 1),
    healthpercAnchorPoint = 'RIGHT',
    healthpercRelativeAnchorPoint = 'RIGHT',
    healthpercXOffset = -2,
    healthpercYOffset = 0,
    healthpercTag = '[perhp:1]%',

    -- Cast bar
    castbarEnable = true,
    castbarHeight = 23,
    castbarYOff = 0,
    castbarShowIcon = true,
    castbarIconWidth = 32,
    castbarShowName = true,
    castbarShowTime = true,
    castbarFont = 'DMSans',
    castbarFontFlag = 'OUTLINE',
    castbarFontColor = color(1, 1, 1),
    castbarNameFontSize = 12,
    castbarNameAnchorPoint = 'LEFT',
    castbarNameRelativeAnchorPoint = 'LEFT',
    castbarNameXOffset = 2,
    castbarNameYOffset = 0,
    castbarTimeFontSize = 15,
    castbarTimeAnchorPoint = 'RIGHT',
    castbarTimeRelativeAnchorPoint = 'BOTTOMRIGHT',
    castbarTimeXOffset = -2,
    castbarTimeYOffset = 0,
    castbarShowTarget = true,
    castbarTargetFontSize = 12,
    castbarTargetAnchorPoint = 'TOPLEFT',
    castbarTargetRelativeAnchorPoint = 'BOTTOMLEFT',
    castbarTargetXOffset = 0,
    castbarTargetYOffset = 0,
    castbarShowInterrupt = true,
    castbarInterruptHold = 1,
    castbarInterruptColor = color(1, 1, 1),
    castbarInterruptFont = 'DMSans',
    castbarInterruptFontFlag = 'OUTLINE',
    castbarInterruptFontSize = 13,
    castbarInterruptAnchorPoint = 'BOTTOMRIGHT',
    castbarInterruptRelativeAnchorPoint = 'BOTTOMRIGHT',
    castbarInterruptXOffset = -2,
    castbarInterruptYOffset = 0,
    castbarForegroundColor = color(1, 0.5, 0),
    castbarUninterruptibleColor = color(0.38, 0.37, 0.37),
    castbarBackgroundColor = color(0, 0, 0, 0.5),
    castbarSparkColor = color(1, 1, 1),
    castbarSparkWidth = 1,

    -- Raid target
    raidTargetIndicatorEnable = true,
    raidTargetIndicatorScale = 1.5,
    raidTargetIndicatorAnchorPoint = 'CENTER',
    raidTargetIndicatorRelativeAnchorPoint = 'BOTTOM',
    raidTargetIndicatorXOff = 0,
    raidTargetIndicatorYOff = 0,
    raidTargetIndicatorFrameStrata = 'MEDIUM',
    raidTargetIndicatorFrameLevel = 14,

    mouseoverHighlightEnable = true,
    mouseoverHighlightColor = color(0.51, 0.51, 0.51, 1),
    mouseoverLightenHealth = true,
    mouseoverLightenAmount = 0.15,

    targetHighlightEnable = true,
    targetHighlightStyle = 'borderglow', -- border | glow | borderglow
    targetHighlightColor = color(1, 0, 0.3, 1),
    targetHighlightDimOthers = false,
    targetHighlightDimAlpha = 0.55,

    stackEnemies = true,
    stackFriendlies = false,
    overlapH = 0.5,
    overlapV = 0.95,
    showAll = true,
    showEnemies = true,
    showEnemyMinions = true,
    showEnemyMinus = true,
    showEnemyPets = true,
    showEnemyGuardians = true,
    showEnemyTotems = true,
    showFriendlyPlayers = true,
    showFriendlyPlayerMinions = false,
    showFriendlyNpcs = false,
    showOffscreen = false,
    targetRadialPosition = 1,
    targetBehindMaxDistance = 30,
    maxDistance = 100,
    playerMaxDistance = 100,
    selectedScale = 1.2,
    minScale = 1,
    maxScale = 1,
    occludedAlphaMult = 1,

    customTexts = {},
}

function defaults:CopyTable(source)
    return EXUI.utils.deepCloneTable(source)
end

function defaults:BuildFullDefaults()
    local db = self:CopyTable(self.PLATE)
    db.__exuiDefaultsVersion = self.SCHEMA_VERSION
    db.auraDisplays = {
        displays = {},
        __exuiDefaultsVersion = 1,
    }
    return db
end

local function mergeMissingKeys(target, template)
    for key, value in pairs(template) do
        if target[key] == nil then
            target[key] = type(value) == 'table' and EXUI.utils.deepCloneTable(value) or value
        elseif type(value) == 'table' and type(target[key]) == 'table' and key == 'customTexts' then
            -- leave existing custom texts
        elseif type(value) == 'table' and type(target[key]) == 'table' and key ~= 'customTexts' and key ~= 'auraDisplays' and key ~= 'healthCurve' then
            mergeMissingKeys(target[key], value)
        end
    end
end

function defaults:MergeIntoDB(db)
    if db.colorCaster == nil and db.colorMana ~= nil then
        db.colorCaster = db.colorMana
    end
    if db.casterColor == nil and db.manaUnitColor then
        db.casterColor = EXUI.utils.deepCloneTable(db.manaUnitColor)
    end
    if db.targetHighlightStyle == 'arrows' then
        db.targetHighlightStyle = 'glow'
    end

    local cvars = EXUI:GetModule('np-cvars')
    if cvars and cvars.SeedMissing then
        cvars:SeedMissing(db)
    end

    if db.__exuiDefaultsVersion == self.SCHEMA_VERSION then
        mergeMissingKeys(db, self.PLATE)
        db.auraDisplays = db.auraDisplays or { displays = {}, __exuiDefaultsVersion = 1 }
        db.__exuiDefaultsVersion = self.SCHEMA_VERSION
        return db
    end

    mergeMissingKeys(db, self.PLATE)
    db.auraDisplays = db.auraDisplays or { displays = {}, __exuiDefaultsVersion = 1 }
    db.__exuiDefaultsVersion = self.SCHEMA_VERSION
    return db
end
