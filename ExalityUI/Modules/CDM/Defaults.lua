---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICDMDefaults
local defaults = EXUI:GetModule('cdm-defaults')

defaults.SCHEMA_VERSION = 10

defaults.QUESTION_MARK_ICON = 134400

defaults.POSITION = {
    anchorPoint = 'CENTER',
    relativePoint = 'CENTER',
    XOff = 0,
    YOff = 0,
}

defaults.ICON = {
    width = 40,
    height = 40,
    zoom = 8,
    style = 'default',
    borderSize = 1,
    borderColor = { r = 0, g = 0, b = 0, a = 1 },
    backgroundColor = { r = 0, g = 0, b = 0, a = 0.4 },
    showSwipe = true,
    swipeColor = { r = 0, g = 0, b = 0, a = 0.7 },
    reverseSwipe = false,
    showEdge = false,
    showBling = false,
    desaturateOnCooldown = false,
    rangeTint = false,
    rangeColor = { r = 1, g = 0.35, b = 0.35, a = 1 },
    procGlow = false,
    procGlowKind = 'style',
    procGlowColor = { r = 1, g = 0.82, b = 0, a = 1 },
}

defaults.BAR = {
    width = 180,
    height = 22,
    orientation = 'horizontal',
    iconPosition = 'start',
    gap = 0,
    zoom = 8,
    texture = 'ExalityUI Status Bar',
    color = { r = 0.25, g = 0.55, b = 1, a = 1 },
    backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
    fillWhenReady = true,
    reverseFill = false,
    style = 'default',
    borderSize = 1,
    borderColor = { r = 0, g = 0, b = 0, a = 1 },
    showSwipe = false,
    swipeColor = { r = 0, g = 0, b = 0, a = 0.7 },
    desaturateOnCooldown = false,
    rangeTint = false,
    rangeColor = { r = 1, g = 0.35, b = 0.35, a = 1 },
    procGlow = false,
    procGlowKind = 'style',
    procGlowColor = { r = 1, g = 0.82, b = 0, a = 1 },
}

defaults.TEXT = {
    kind = 'cooldown',
    enable = true,
    text = '',
    font = 'DMSans',
    fontSize = 12,
    fontFlag = 'OUTLINE',
    color = { r = 1, g = 1, b = 1, a = 1 },
    anchorPoint = 'CENTER',
    relativePoint = 'CENTER',
    XOff = 0,
    YOff = 0,
    justify = 'CENTER',
    format = 'mmss',
    updateInterval = 0.1,
    textShadow = false,
    urgentSeconds = 0,
    urgentColor = { r = 1, g = 0.2, b = 0.2, a = 1 },
}

-- Remaining time and count read from the aura for aura sources and linked auras.
defaults.TEXT_KINDS = {
    cooldown = { label = 'Remaining Time', order = 1 },
    charges = { label = 'Charges / Stacks', order = 2 },
    name = { label = 'Name', order = 3 },
    custom = { label = 'Custom Text', order = 4 },
}

defaults.LINKED_AURA = {
    input = '',
    spellIDs = {},
    unit = 'player',
    filter = 'HELPFUL',
    onlyMine = true,
    glow = true,
    glowKind = 'style',
    glowColor = { r = 1, g = 0.82, b = 0, a = 1 },
    glowSize = 10,
    glowPulse = false,
    border = false,
    borderColor = { r = 1, g = 0.82, b = 0, a = 1 },
    borderSize = 2,
    icon = 'none',
    swipe = false,
    swipeColor = { r = 1, g = 0.82, b = 0, a = 0.35 },
    reverseSwipe = true,
    missingEffect = 'none',
    pandemic = false,
    pandemicColor = { r = 1, g = 0.3, b = 0.1, a = 1 },
    pandemicPulse = true,
    texts = {
        { kind = 'cooldown', anchorPoint = 'TOP', relativePoint = 'TOP', YOff = -2, color = { r = 1, g = 0.82, b = 0, a = 1 } },
    },
}

defaults.VISIBILITY = {
    combat = 'any',
    cooldownState = 'any',
    auraState = 'always',
    threshold = 3,
    hiddenAlpha = 0,
}

defaults.LOAD = {
    hasLoadConditions = false,
    onlyLoadOnPlayer = '',
    dontLoadOnPlayer = '',
    loadClasses = {},
    loadSpecs = {},
    loadInstances = {},
    loadRoles = {},
}

defaults.LAYOUT = {
    mode = 'row',
    direction = 'horizontal',
    growX = 'RIGHT',
    growY = 'DOWN',
    perLine = 8,
    spacingX = 4,
    spacingY = 4,
    align = 'start',
    collapse = false,
    flowUnit = 'player',
}

defaults.GROUP = {
    kind = 'group',
    name = 'New Group',
    icon = defaults.QUESTION_MARK_ICON,
    enable = true,
    layout = defaults.LAYOUT,
    position = defaults.POSITION,
    frameStrata = 'LOW',
    frameLevel = 10,
    iconAppearance = defaults.ICON,
    barAppearance = defaults.BAR,
    texts = {
        { kind = 'cooldown' },
        { kind = 'charges', anchorPoint = 'BOTTOMRIGHT', relativePoint = 'BOTTOMRIGHT', XOff = -2, YOff = 2 },
    },
    visibility = defaults.VISIBILITY,
    load = defaults.LOAD,
}

defaults.ITEM = {
    kind = 'item',
    name = 'New Cooldown',
    enable = true,
    display = 'icon',
    source = {
        type = 'spell',
        spellID = nil,
        itemID = nil,
        slot = 13,
        ignoreGCD = true,
        input = '',
        spellIDs = {},
        unit = 'player',
        filter = 'HELPFUL',
        onlyMine = true,
        missingAlpha = 0.4,
        glow = false,
        glowKind = 'style',
        glowColor = { r = 1, g = 0.82, b = 0, a = 1 },
        glowSize = 10,
        glowPulse = false,
        border = false,
        borderColor = { r = 1, g = 0.82, b = 0, a = 1 },
        borderSize = 2,
        pandemic = false,
        pandemicColor = { r = 1, g = 0.3, b = 0.1, a = 1 },
        pandemicPulse = true,
    },
    position = defaults.POSITION,
    frameStrata = 'LOW',
    frameLevel = 10,
    override = {
        size = false,
        icon = false,
        bar = false,
        texts = false,
    },
    iconAppearance = defaults.ICON,
    barAppearance = defaults.BAR,
    texts = {
        { kind = 'cooldown' },
        { kind = 'charges', anchorPoint = 'BOTTOMRIGHT', relativePoint = 'BOTTOMRIGHT', XOff = -2, YOff = 2 },
    },
    linkedAuras = {},
    visibility = defaults.VISIBILITY,
    load = defaults.LOAD,
}

defaults.SCOPE_MODES = {
    character = { label = 'This Character', order = 1 },
    class = { label = 'My Class', order = 2 },
    all = { label = 'All Characters', order = 3 },
}

function defaults:CopyTable(value)
    return EXUI.utils.deepCloneTable(value)
end

function defaults:IsMetadataKey(key)
    return type(key) == 'string' and key:sub(1, 2) == '__'
end

local function mergeMissing(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = type(value) == 'table' and EXUI.utils.deepCloneTable(value) or value
        elseif type(value) == 'table' and type(target[key]) == 'table' and #value == 0 and next(value) then
            mergeMissing(target[key], value)
        end
    end
end

function defaults:MergeText(text)
    mergeMissing(text, self.TEXT)
    text.id = text.id or EXUI.utils.generateRandomString(6)
end

function defaults:MergeLinkedAura(aura)
    mergeMissing(aura, self.LINKED_AURA)
    aura.id = aura.id or EXUI.utils.generateRandomString(6)
    for _, text in ipairs(aura.texts) do
        self:MergeText(text)
    end
end

function defaults:MergeNode(node)
    mergeMissing(node, node.kind == 'group' and self.GROUP or self.ITEM)
    for _, text in ipairs(node.texts) do
        self:MergeText(text)
    end
    for _, aura in ipairs(node.linkedAuras or {}) do
        self:MergeLinkedAura(aura)
    end
end

function defaults:BuildNode(kind)
    local node = self:CopyTable(kind == 'group' and self.GROUP or self.ITEM)
    node.createdAt = time()
    self:MergeNode(node)
    return node
end
