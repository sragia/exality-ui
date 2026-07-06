---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsDefaults
local defaults = EXUI:GetModule('action-bars-defaults')

local function textDefaults()
    return {
        useGlobal = true,
        enabled = true,
        font = 'DMSans',
        fontSize = 12,
        fontFlag = 'OUTLINE',
        anchorPoint = 'BOTTOMRIGHT',
        relativePoint = 'BOTTOMRIGHT',
        xOffset = -2,
        yOffset = 2,
        color = { r = 1, g = 1, b = 1, a = 1 },
    }
end

defaults.GLOBAL = {
    width = 36,
    height = 36,
    zoom = 15,
    showBorder = true,
    showBackdrop = true,
    backdropColor = { r = 0, g = 0, b = 0, a = 0.5 },
    useMasque = false,
    masqueSkin = 'ExalityUI Square',
    showCooldownSwipe = true,
    showCooldownText = true,
    visibility = 'always',
    hotkey = textDefaults(),
    count = {
        useGlobal = true,
        enabled = true,
        font = 'DMSans',
        fontSize = 14,
        fontFlag = 'OUTLINE',
        anchorPoint = 'TOPRIGHT',
        relativePoint = 'TOPRIGHT',
        xOffset = -2,
        yOffset = -2,
        color = { r = 1, g = 1, b = 1, a = 1 },
    },
    macro = {
        useGlobal = true,
        enabled = false,
        font = 'DMSans',
        fontSize = 10,
        fontFlag = 'OUTLINE',
        anchorPoint = 'BOTTOM',
        relativePoint = 'BOTTOM',
        xOffset = 0,
        yOffset = 2,
        color = { r = 1, g = 1, b = 1, a = 1 },
    },
    cooldown = {
        useGlobal = true,
        enabled = true,
        font = 'DMSans',
        fontSize = 16,
        fontFlag = 'OUTLINE',
        anchorPoint = 'CENTER',
        relativePoint = 'CENTER',
        xOffset = 0,
        yOffset = 0,
        color = { r = 1, g = 1, b = 1, a = 1 },
    },
}

defaults.BAR1_STATES = {
    enabled = true,
    possess = true,
    actionbar = false,
    default = 0,
    ctrl = 0,
    alt = 0,
    shift = 0,
    stance = {
        DRUID = { bear = 9, cat = 7, prowl = 8 },
        ROGUE = { stealth = 7 },
        EVOKER = { soar = 7 },
    },
}

defaults.BAR = {
    useGlobalSize = true,
    useGlobalAppearance = true,
    useGlobalText = true,
    enable = true,
    name = 'Bar',
    width = 36,
    height = 36,
    zoom = 15,
    showBorder = true,
    useMasque = false,
    masqueSkin = 'ExalityUI Square',
    showCooldownSwipe = true,
    showCooldownText = true,
    visibility = 'always',
    anchorPoint = 'BOTTOM',
    relativeAnchor = 'BOTTOM',
    xOffset = 0,
    yOffset = 0,
    orientation = 'horizontal',
    numButtons = 12,
    buttonsPerRow = 12,
    paddingX = 2,
    paddingY = 2,
    growHorizontal = 'right',
    growVertical = 'up',
    showBackdrop = true,
    backdropColor = { r = 0, g = 0, b = 0, a = 0.5 },
    hotkey = textDefaults(),
    count = defaults.GLOBAL.count,
    macro = defaults.GLOBAL.macro,
    cooldown = defaults.GLOBAL.cooldown,
}

defaults.MICRO_MENU = {
    enable = true,
    anchorPoint = 'BOTTOMRIGHT',
    relativeAnchor = 'BOTTOMRIGHT',
    xOffset = -4,
    yOffset = 4,
    orientation = 'horizontal',
    order = 'default',
    visibility = 'always',
    scale = 1,
}

defaults.BAGS = {
    enable = true,
    anchorPoint = 'BOTTOMRIGHT',
    relativeAnchor = 'BOTTOMRIGHT',
    xOffset = -6,
    yOffset = 39,
    visibility = 'always',
    scale = 1,
}

defaults.BuildBarDefaults = function(self, barId)
    local def = definitions:Get(barId)
    local bar = EXUI.utils.deepCloneTable(self.BAR)
    bar.name = def and def.label or barId
    bar.enable = def and def.defaultEnabled or false
    bar.numButtons = def and def.numButtons or 12
    bar.buttonsPerRow = def and def.numButtons or 12
    if def and def.defaultAnchor then
        bar.anchorPoint = def.defaultAnchor.point
        bar.relativeAnchor = def.defaultAnchor.relativePoint
        bar.xOffset = def.defaultAnchor.x
        bar.yOffset = def.defaultAnchor.y
    end
    if barId == 'extra' then
        bar.showBlizzardArtwork = false
    end
    if barId == 'bar1' then
        bar.states = EXUI.utils.deepCloneTable(self.BAR1_STATES)
    end
    bar.hotkey = EXUI.utils.deepCloneTable(self.GLOBAL.hotkey)
    bar.count = EXUI.utils.deepCloneTable(self.GLOBAL.count)
    bar.macro = EXUI.utils.deepCloneTable(self.GLOBAL.macro)
    bar.cooldown = EXUI.utils.deepCloneTable(self.GLOBAL.cooldown)
    return bar
end

defaults.BuildFullDefaults = function(self)
    local db = {
        enable = false,
        global = EXUI.utils.deepCloneTable(self.GLOBAL),
        bars = {},
        microMenu = EXUI.utils.deepCloneTable(self.MICRO_MENU),
        bags = EXUI.utils.deepCloneTable(self.BAGS),
    }
    for _, barId in ipairs(definitions.ALL_BAR_IDS) do
        db.bars[barId] = self:BuildBarDefaults(barId)
    end
    return db
end

defaults.MergeIntoDB = function(self, db)
    local template = self:BuildFullDefaults()
    if not db.global then
        db.global = template.global
    else
        for key, value in pairs(template.global) do
            if db.global[key] == nil then
                db.global[key] = type(value) == 'table' and EXUI.utils.deepCloneTable(value) or value
            end
        end
    end
    db.bars = db.bars or {}
    for _, barId in ipairs(definitions.ALL_BAR_IDS) do
        if not db.bars[barId] then
            db.bars[barId] = self:BuildBarDefaults(barId)
        else
            local templateBar = self:BuildBarDefaults(barId)
            for key, value in pairs(templateBar) do
                if db.bars[barId][key] == nil then
                    db.bars[barId][key] = type(value) == 'table' and EXUI.utils.deepCloneTable(value) or value
                end
            end
            if barId == 'bar1' and not db.bars[barId].states then
                db.bars[barId].states = EXUI.utils.deepCloneTable(self.BAR1_STATES)
            end
            if barId == 'extra' and db.bars[barId].showBlizzardArtwork == nil then
                db.bars[barId].showBlizzardArtwork = false
            end
        end
    end
    if not db.microMenu then
        db.microMenu = template.microMenu
    else
        for key, value in pairs(template.microMenu) do
            if db.microMenu[key] == nil then
                db.microMenu[key] = type(value) == 'table' and EXUI.utils.deepCloneTable(value) or value
            end
        end
    end
    if not db.bags then
        db.bags = template.bags
    else
        for key, value in pairs(template.bags) do
            if db.bags[key] == nil then
                db.bags[key] = type(value) == 'table' and EXUI.utils.deepCloneTable(value) or value
            end
        end
    end
    return db
end
