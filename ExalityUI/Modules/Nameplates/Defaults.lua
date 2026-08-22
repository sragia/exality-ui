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
    sizeWidth = 140,
    sizeHeight = 16,
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
    questColor = color(1, 0.82, 0.2),
    colorThreat = true,
    threatHaveAggro = color(0.58, 0.22, 0.82),
    threatAggroLow = color(1, 0.92, 0.2),
    threatNoAggro = color(0.85, 0.18, 0.18),
    colorCoTank = true,
    threatCoTank = color(0.15, 0.82, 0.68),
    threatPullingTank = color(1, 0.62, 0.15),
    colorMiniboss = true,
    minibossColor = color(0.88, 0.38, 0.55),
    colorClassification = false,
    classificationElite = color(1, 0.85, 0.2),
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
    damageAbsorbTexture = 'ExalityUI Status Bar',
    damageAbsorbColor = color(0, 133 / 255, 163 / 255, 1),
    healAbsorbEnable = true,
    healAbsorbShowOverIndicator = true,
    healAbsorbTexture = 'ExalityUI Status Bar',
    healAbsorbColor = color(100 / 255, 100 / 255, 100 / 255, 0.8),

    -- Name
    nameEnable = true,
    nameFont = 'DMSans',
    nameFontSize = 11,
    nameFontFlag = 'OUTLINE',
    nameFontColor = color(1, 1, 1),
    nameAnchorPoint = 'BOTTOM',
    nameRelativeAnchorPoint = 'TOP',
    nameXOffset = 0,
    nameYOffset = 2,
    nameMaxWidth = 100,
    nameTag = '[name]',

    -- Health text
    healthEnable = false,
    healthFont = 'DMSans',
    healthFontSize = 10,
    healthFontFlag = 'OUTLINE',
    healthFontColor = color(1, 1, 1),
    healthAnchorPoint = 'RIGHT',
    healthRelativeAnchorPoint = 'RIGHT',
    healthXOffset = -2,
    healthYOffset = 0,
    healthTag = '[curhp:formatted]',

    -- Health percent
    healthpercEnable = true,
    healthpercFont = 'DMSans',
    healthpercFontSize = 10,
    healthpercFontFlag = 'OUTLINE',
    healthpercFontColor = color(1, 1, 1),
    healthpercAnchorPoint = 'LEFT',
    healthpercRelativeAnchorPoint = 'LEFT',
    healthpercXOffset = 2,
    healthpercYOffset = 0,
    healthpercTag = '[perhp]%',

    -- Cast bar
    castbarEnable = true,
    castbarHeight = 12,
    castbarYOff = -1,
    castbarShowIcon = true,
    castbarIconWidth = 12,
    castbarShowName = true,
    castbarShowTime = true,
    castbarFont = 'DMSans',
    castbarFontFlag = 'OUTLINE',
    castbarFontColor = color(1, 1, 1),
    castbarNameFontSize = 10,
    castbarNameAnchorPoint = 'LEFT',
    castbarNameRelativeAnchorPoint = 'LEFT',
    castbarNameXOffset = 2,
    castbarNameYOffset = 0,
    castbarTimeFontSize = 10,
    castbarTimeAnchorPoint = 'RIGHT',
    castbarTimeRelativeAnchorPoint = 'RIGHT',
    castbarTimeXOffset = -2,
    castbarTimeYOffset = 0,
    castbarShowTarget = true,
    castbarTargetFontSize = 10,
    castbarTargetAnchorPoint = 'RIGHT',
    castbarTargetRelativeAnchorPoint = 'RIGHT',
    castbarTargetXOffset = -2,
    castbarTargetYOffset = 0,
    castbarShowInterrupt = true,
    castbarInterruptHold = 1,
    castbarInterruptColor = color(1, 1, 1),
    castbarInterruptFontSize = 10,
    castbarForegroundColor = color(0.85, 0.7, 0.2),
    castbarUninterruptibleColor = color(0.55, 0.55, 0.55),
    castbarBackgroundColor = color(0, 0, 0, 0.5),
    castbarSparkColor = color(1, 1, 1),
    castbarSparkWidth = 1,

    -- Raid target
    raidTargetIndicatorEnable = true,
    raidTargetIndicatorScale = 1,
    raidTargetIndicatorAnchorPoint = 'RIGHT',
    raidTargetIndicatorRelativeAnchorPoint = 'LEFT',
    raidTargetIndicatorXOff = -2,
    raidTargetIndicatorYOff = 0,
    raidTargetIndicatorFrameStrata = 'MEDIUM',
    raidTargetIndicatorFrameLevel = 0,

    mouseoverHighlightEnable = true,
    mouseoverHighlightColor = color(1, 1, 1, 1),
    mouseoverLightenHealth = false,
    mouseoverLightenAmount = 0.25,

    targetHighlightEnable = true,
    targetHighlightStyle = 'glow', -- border | glow | arrows
    targetHighlightColor = color(1, 0.82, 0.2, 1),
    targetHighlightDimOthers = false,
    targetHighlightDimAlpha = 0.45,

    stackEnemies = true,
    stackFriendlies = false,
    showAll = true,
    showEnemies = true,
    showEnemyMinions = true,
    showEnemyMinus = true,
    showEnemyPets = true,
    showEnemyGuardians = true,
    showEnemyTotems = true,
    showFriendlyPlayers = false,
    showFriendlyPlayerMinions = false,
    showFriendlyNpcs = false,
    showOffscreen = false,
    targetRadialPosition = 0,
    targetBehindMaxDistance = 15,
    maxDistance = 60,
    playerMaxDistance = 60,
    selectedScale = 1.2,
    minScale = 0.8,
    maxScale = 1,
    occludedAlphaMult = 0.4,

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
