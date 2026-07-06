---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsDefaults
local barDefaults = EXUI:GetModule('action-bars-defaults')

---@class EXUIActionBarsConfigResolver
local resolver = EXUI:GetModule('action-bars-config-resolver')

local function resolveField(globalValue, barValue, useGlobalKey, barConfig)
    if barConfig[useGlobalKey] ~= false and barConfig[useGlobalKey] ~= nil then
        if barConfig[useGlobalKey] then
            return globalValue
        end
    elseif barConfig.useGlobalText or barConfig.useGlobalAppearance or barConfig.useGlobalSize then
        -- fall through to per-field check below
    end
    if type(barValue) == 'table' and barValue.useGlobal then
        return globalValue
    end
    if barValue ~= nil then
        return barValue
    end
    return globalValue
end

local function resolveTextBlock(globalBlock, barBlock)
    barBlock = barBlock or {}
    local useGlobal = barBlock.useGlobal ~= false
    local source = useGlobal and globalBlock or barBlock
    source = source or globalBlock
    return {
        enabled = source.enabled ~= false,
        font = source.font or 'DMSans',
        fontSize = source.fontSize or 12,
        fontFlag = source.fontFlag or 'OUTLINE',
        anchorPoint = source.anchorPoint or 'CENTER',
        relativePoint = source.relativePoint or source.anchorPoint or 'CENTER',
        xOffset = source.xOffset or 0,
        yOffset = source.yOffset or 0,
        color = source.color or { r = 1, g = 1, b = 1, a = 1 },
    }
end

resolver.GetBarConfig = function(self, db, barId)
    local global = db.global or barDefaults.GLOBAL
    local bar = db.bars and db.bars[barId] or barDefaults:BuildBarDefaults(barId)

    local useGlobalSize = bar.useGlobalSize ~= false
    local useGlobalAppearance = bar.useGlobalAppearance ~= false

    local resolved = {
        enable = bar.enable ~= false,
        name = bar.name or barId,
        width = useGlobalSize and global.width or bar.width,
        height = useGlobalSize and global.height or bar.height,
        zoom = useGlobalSize and global.zoom or bar.zoom,
        showBorder = useGlobalAppearance and global.showBorder or bar.showBorder,
        useMasque = useGlobalAppearance and global.useMasque or bar.useMasque,
        masqueSkin = useGlobalAppearance and global.masqueSkin or bar.masqueSkin,
        showCooldownSwipe = useGlobalAppearance and global.showCooldownSwipe or bar.showCooldownSwipe,
        showCooldownText = useGlobalAppearance and global.showCooldownText or bar.showCooldownText,
        visibility = bar.visibility or global.visibility or 'always',
        anchorPoint = bar.anchorPoint or 'BOTTOM',
        relativeAnchor = bar.relativeAnchor or 'BOTTOM',
        xOffset = bar.xOffset or 0,
        yOffset = bar.yOffset or 0,
        orientation = bar.orientation or 'horizontal',
        numButtons = bar.numButtons or 12,
        buttonsPerRow = bar.buttonsPerRow or 12,
        paddingX = bar.paddingX ~= nil and bar.paddingX or 2,
        paddingY = bar.paddingY ~= nil and bar.paddingY or 2,
        growHorizontal = bar.growHorizontal or 'right',
        growVertical = bar.growVertical or 'up',
        showBackdrop = useGlobalAppearance and (global.showBackdrop ~= false) or (bar.showBackdrop ~= false),
        showBlizzardArtwork = bar.showBlizzardArtwork == true,
        backdropColor = useGlobalAppearance and global.backdropColor or bar.backdropColor or { r = 0, g = 0, b = 0, a = 0.5 },
        hotkey = resolveTextBlock(global.hotkey, bar.hotkey),
        count = resolveTextBlock(global.count, bar.count),
        macro = resolveTextBlock(global.macro, bar.macro),
        cooldown = resolveTextBlock(global.cooldown, bar.cooldown),
    }

    if barId == 'bar1' and bar.states then
        resolved.states = bar.states
    end

    return resolved
end

resolver.GetGlobalConfig = function(self, db)
    return db.global or barDefaults.GLOBAL
end
