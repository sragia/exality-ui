---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysDefaults
local defaults = EXUI:GetModule('aura-displays-defaults')

defaults.SCHEMA_VERSION = 3

defaults.FILTER_TOKENS = {
    'HELPFUL',
    'HARMFUL',
    'RAID',
    'PLAYER',
    'CANCELABLE',
    'INCLUDE_NAME_PLATE_ONLY',
    'MAW',
    'EXTERNAL_DEFENSIVE',
    'CROWD_CONTROL',
    'RAID_IN_COMBAT',
    'RAID_PLAYER_DISPELLABLE',
    'BIG_DEFENSIVE',
    'IMPORTANT',
    'DISPELLABLE',
}

defaults.FILTER_TOKEN_TOOLTIPS = {
    HELPFUL = 'Include only helpful auras (buffs).',
    HARMFUL = 'Include only harmful auras (debuffs).',
    RAID = 'Include only helpful auras the player can apply and harmful auras the player can dispel.',
    PLAYER = 'Include only auras cast by the player, pet, or vehicle.',
    CANCELABLE = 'Include only auras the player can cancel.',
    INCLUDE_NAME_PLATE_ONLY = 'When set, nameplate-only auras are included. When unset, they are filtered out. Not negatable.',
    MAW = 'When set, only Torghast auras are returned. When unset, Torghast auras are filtered out. Not negatable.',
    EXTERNAL_DEFENSIVE = 'Include only external defensive auras.',
    CROWD_CONTROL = 'Include only crowd control auras (stun, fear, etc.).',
    RAID_IN_COMBAT = 'Include only auras flagged for raid frames in combat. Combine with PLAYER and HELPFUL for self-cast HoTs.',
    RAID_PLAYER_DISPELLABLE = 'Include only auras someone in the player\'s raid can dispel, including helpful auras on enemies that are dispellable or stealable by a raid member.',
    BIG_DEFENSIVE = 'Include only big defensive auras.',
    IMPORTANT = 'Include only auras flagged as important (helpful auras on enemy nameplates even if non-stealable).',
    DISPELLABLE = 'Include only auras with any dispel type, regardless of whether the raid can dispel them.',
}

defaults.DISPEL_TYPES = { 'Magic', 'Curse', 'Disease', 'Poison', 'Bleed', 'None' }

defaults.SORT_METHODS = {
    Default = 'Default',
    BigDefensive = 'Big Defensive',
    UnitFrameDebuff = 'Unit Frame Debuff',
    ImportantOnly = 'Important Only',
    Expiration = 'Expiration',
    ExpirationOnly = 'Expiration Only',
    Name = 'Name',
    NameOnly = 'Name Only',
}

defaults.UNIT_OPTIONS = {
    player = 'Player',
    target = 'Target',
    focus = 'Focus',
    pet = 'Pet',
    targettarget = 'Target Target',
    mouseover = 'Mouseover',
    coTank = 'Co-Tank',
    custom = 'Custom',
}

defaults.GROUP_LOAD = {
    hasLoadConditions = false,
    onlyLoadOnPlayer = '',
    dontLoadOnPlayer = '',
    loadClasses = {},
    loadSpecs = {},
    loadInstances = {},
    loadInCombat = nil,
    loadOutOfCombat = nil,
    loadRoles = {},
}

defaults.GROUP_CONDITIONS = {
    enable = true,
    groupType = 'group',
    filterTokens = {
        { token = 'HELPFUL', negated = false },
    },
    maxFrameCount = 10,
    sortMethod = 'Default',
    sortDirection = 'Normal',
    includeSpellIDs = '',
    excludeSpellIDs = '',
    includeDispelTypes = {},
    excludeDispelTypes = {},
    maxDuration = 0,
    processedAuraType = nil,
    isFromPlayerOrPlayerPet = false,
    isRoleAura = false,
    isPriorityAura = false,
    isStealable = false,
    nameplateShowAll = false,
    nameplateShowPersonal = false,
    canApplyAura = false,
    isBossAura = false,
    isBossOrRoleAura = false,
}

defaults.GROUP_VISUAL = {
    displayStyle = 'icon',
    barWidth = 160,
    barHeight = 20,
    barColor = { r = 0.2, g = 0.6, b = 1, a = 1 },
    barBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
    barBorderColor = { r = 0, g = 0, b = 0, a = 1 },
    barBorderThickness = 1,
    barTexture = 'ExalityUI Status Bar',
    barTimerDirection = 'RemainingTime',
    showBarIcon = true,
    barIconPosition = 'LEFT',
    barIconGap = 0,
    iconWidth = 32,
    iconHeight = 32,
    iconZoom = 0,
    showIconBorder = true,
    iconBorderColor = { r = 0, g = 0, b = 0, a = 1 },
    iconBorderThickness = 1,
    iconBorderColorByAuraType = false,
    elementSpacingX = 2,
    elementSpacingY = 2,
    gapX = 0,
    gapY = 0,
    forceNewRow = false,
    elementWidth = 0,
    elementHeight = 0,
    slotAnchorPoint = 'CENTER',
    slotRelativePoint = 'CENTER',
    slotXOff = 0,
    slotYOff = 0,
    showStacks = true,
    stackFont = 'DMSans',
    stackFontSize = 12,
    stackFontFlag = 'OUTLINE',
    stackColor = { r = 1, g = 1, b = 1, a = 1 },
    stackAnchorPoint = 'BOTTOMRIGHT',
    stackRelativePoint = 'BOTTOMRIGHT',
    stackXOff = -2,
    stackYOff = 2,
    showDurationText = true,
    durationFormat = 'mmss',
    durationFont = 'DMSans',
    durationFontSize = 12,
    durationFontFlag = 'OUTLINE',
    durationColor = { r = 1, g = 1, b = 1, a = 1 },
    durationAnchorPoint = 'CENTER',
    durationRelativePoint = 'CENTER',
    durationXOff = 0,
    durationYOff = 0,
    durationExpiredText = '',
    durationZeroText = '',
    durationUpdateInterval = 0,
    showDurationCooldown = true,
    showSpellName = false,
    spellNameFont = 'DMSans',
    spellNameFontSize = 10,
    spellNameFontFlag = 'OUTLINE',
    spellNameColor = { r = 1, g = 1, b = 1, a = 1 },
    spellNameAnchorPoint = 'BOTTOM',
    spellNameRelativePoint = 'TOP',
    spellNameXOff = 0,
    spellNameYOff = -2,
    showDispelBorder = true,
    dispelBorderStyle = 'Atlas',
    dispelBorderShowIcon = true,
    dispelBorderHarmful = true,
    dispelBorderHelpful = false,
    -- Mouse/tooltips default off (standalone Aura Displays stay click-through).
    enableMouse = false,
    tooltipAnchor = 'ANCHOR_BOTTOMLEFT',
}

defaults.CONTAINER = {
    unit = 'player',
    unitCustom = '',
    processAuraOptions = {
        displayOnlyDispellableDebuffs = false,
        ignoreBuffs = false,
        ignoreDebuffs = false,
        ignoreDispelDebuffs = false,
    },
    itemEnchantEnable = false,
    itemEnchantHidePermanent = false,
    itemEnchantPlacement = 'BeforeAuraGroups',
    itemEnchantMainHand = false,
    itemEnchantOffHand = false,
    itemEnchantRanged = false,
    itemEnchantSpacingX = 2,
    itemEnchantSpacingY = 2,
    itemEnchantGapX = 0,
    itemEnchantGapY = 0,
    itemEnchantWidth = 0,
    itemEnchantHeight = 0,
}

defaults.DISPLAY = {
    enable = true,
    name = 'New Aura Display',
    anchorPoint = 'CENTER',
    relativePoint = 'CENTER',
    XOff = 0,
    YOff = 0,
    frameStrata = 'LOW',
    frameLevel = 10,
    containerAnchorPoint = 'TOPLEFT',
    horizontalGrowth = 'RIGHT',
    verticalGrowth = 'DOWN',
    paddingLeft = 0,
    paddingRight = 0,
    paddingTop = 0,
    paddingBottom = 0,
    rowWidth = 1000,
}

function defaults:CopyTable(source)
    return EXUI.utils.deepCloneTable(source)
end

function defaults:BuildNewGroup()
    return {
        enable = true,
        visual = self:CopyTable(self.GROUP_VISUAL),
        conditions = self:CopyTable(self.GROUP_CONDITIONS),
        load = self:CopyTable(self.GROUP_LOAD),
    }
end

function defaults:BuildNewDisplay()
    local displayID = EXUI.utils.generateRandomString(12)
    local groupID = EXUI.utils.generateRandomString(12)
    local display = self:CopyTable(self.DISPLAY)
    display.container = self:CopyTable(self.CONTAINER)
    display.groupOrder = { groupID }
    display.groups = {
        [groupID] = self:BuildNewGroup(),
    }
    display.createdAt = time()
    return displayID, display
end

function defaults:MergeGroupDefaults(group)
    if not group.visual then group.visual = self:CopyTable(self.GROUP_VISUAL) end
    if not group.conditions then group.conditions = self:CopyTable(self.GROUP_CONDITIONS) end
    if not group.load then group.load = self:CopyTable(self.GROUP_LOAD) end
    for key, value in pairs(self.GROUP_VISUAL) do
        if group.visual[key] == nil then group.visual[key] = value end
    end
    for key, value in pairs(self.GROUP_CONDITIONS) do
        if group.conditions[key] == nil then group.conditions[key] = value end
    end
    for key, value in pairs(self.GROUP_LOAD) do
        if group.load[key] == nil then group.load[key] = value end
    end
end

function defaults:MergeIntoDB(db)
    if not db.displays then db.displays = {} end
    for _, display in pairs(db.displays) do
        for key, value in pairs(self.DISPLAY) do
            if key ~= 'name' and display[key] == nil then
                display[key] = EXUI.utils.deepCloneTable(value)
            end
        end
        if not display.container then
            display.container = self:CopyTable(self.CONTAINER)
        else
            for key, value in pairs(self.CONTAINER) do
                if display.container[key] == nil then
                    display.container[key] = EXUI.utils.deepCloneTable(value)
                end
            end
        end
        if not display.groupOrder then display.groupOrder = {} end
        if not display.groups then display.groups = {} end
        for _, groupID in ipairs(display.groupOrder) do
            local group = display.groups[groupID]
            if group then
                self:MergeGroupDefaults(group)
            end
        end
    end
    db.__exuiDefaultsVersion = self.SCHEMA_VERSION
end

function defaults:GetGroupKey(displayID, groupID)
    return string.format('exui_%s_%s', displayID, groupID)
end
