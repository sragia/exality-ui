---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIDamageMetersViews
local views = EXUI:GetModule('damage-meters-views')

---@class EXUIDamageMetersDefaults
local defaults = EXUI:GetModule('damage-meters-defaults')

defaults.SCHEMA_VERSION = 7
defaults.BAR_TEXTURE = 'ExalityUI Status Bar'
defaults.FAVORITE_SLOT_COUNT = 10

defaults.MODULE = {
    enable = false,
    hideBlizzard = true,
    favoriteViews = {},
}

local function textColor(alpha)
    local text = EXUI.const.theme.text
    return { r = text[1], g = text[2], b = text[3], a = alpha or 1 }
end

local function textLayout(anchorPoint, relativePoint, xOff, yOff, width, show, alpha)
    return {
        show = show ~= false,
        useDefaultFont = true,
        font = 'DMSans',
        fontSize = 11,
        fontFlag = 'OUTLINE',
        color = textColor(alpha),
        anchorPoint = anchorPoint,
        relativePoint = relativePoint,
        XOff = xOff,
        YOff = yOff,
        width = width,
    }
end

defaults.WINDOW = {
    enable = true,
    name = 'Damage Meter',
    damageMeterType = views.Type.DamageDone,
    sessionType = views.Session.Current,
    sessionID = nil,
    visibility = 'always',
    locked = false,
    clickThrough = false,
    alwaysShowSelf = true,
    updateInterval = 0.2,
    barTexture = defaults.BAR_TEXTURE,
    barHeight = 18,
    barSpacing = 1,
    useClassColor = true,
    classColorName = true,
    customBarColor = { r = 0.8, g = 0.15, b = 0.15, a = 1 },
    showRank = true,
    valueDecimals = 1,
    font = 'DMSans',
    fontSize = 11,
    fontFlag = 'OUTLINE',
    width = 240,
    height = 180,
    showTitle = true,
    showTimer = true,
    borderColor = { r = 61 / 255, g = 53 / 255, b = 48 / 255, a = 1 },
    backdropColor = { r = 0.05, g = 0.04, b = 0.03, a = 0.75 },
    headerHeight = 22,
    anchorPoint = 'TOPLEFT',
    relativePoint = 'TOPLEFT',
    XOff = 200,
    YOff = -240,
    texts = {
        name = textLayout('LEFT', 'LEFT', 38, 0, 0, true, 1),
        value = textLayout('RIGHT', 'RIGHT', -4, 0, 0, true, 1),
        secondary = textLayout('RIGHT', 'RIGHT', -52, 0, 0, true, 0.75),
        percent = textLayout('RIGHT', 'RIGHT', -96, 0, 0, false, 0.8),
    },
    icon = {
        show = true,
        width = 16,
        height = 16,
        zoom = 8,
        anchorPoint = 'LEFT',
        relativePoint = 'LEFT',
        XOff = 1,
        YOff = 0,
    },
}

function defaults:CopyTable(value)
    return EXUI.utils.deepCloneTable(value)
end

function defaults:IsMetadataKey(key)
    return type(key) == 'string' and key:sub(1, 2) == '__'
end

function defaults:MergeNestedDefaults(dest, source)
    if type(dest) ~= 'table' or type(source) ~= 'table' then
        return
    end

    for key, value in pairs(source) do
        if dest[key] == nil then
            dest[key] = self:CopyTable(value)
        elseif type(value) == 'table' and type(dest[key]) == 'table' then
            self:MergeNestedDefaults(dest[key], value)
        end
    end
end

function defaults:MergeWindowDefaults(entry)
    if type(entry) ~= 'table' then
        return
    end

    if entry.height == nil then
        local maxBars = tonumber(entry.maxBars) or 8
        local barHeight = entry.barHeight or self.WINDOW.barHeight
        local spacing = entry.barSpacing or self.WINDOW.barSpacing
        local headerHeight = entry.headerHeight or self.WINDOW.headerHeight
        entry.height = headerHeight + 5 + maxBars * barHeight + math.max(0, maxBars - 1) * spacing
    end

    if entry.backdropColor == nil then
        local alpha = entry.bgAlpha
        if type(alpha) ~= 'number' then
            alpha = self.WINDOW.backdropColor.a
        end
        entry.backdropColor = {
            r = self.WINDOW.backdropColor.r,
            g = self.WINDOW.backdropColor.g,
            b = self.WINDOW.backdropColor.b,
            a = alpha,
        }
    end

    if entry.icon == nil then
        entry.icon = self:CopyTable(self.WINDOW.icon)
        if entry.showIcon == false then
            entry.icon.show = false
        end
    end

    if type(entry.texts) == 'table' then
        local mode = entry.numberMode
        local function ensureShow(key, show)
            entry.texts[key] = entry.texts[key] or {}
            if entry.texts[key].show == nil then
                entry.texts[key].show = show
            end
        end
        ensureShow('name', true)
        ensureShow('value', true)
        ensureShow('secondary', mode ~= 'value')
        ensureShow('percent', mode == 'complete')
    end

    for key, value in pairs(self.WINDOW) do
        if entry[key] == nil then
            if key == 'sessionType' and entry.sessionID ~= nil then
                -- Historic sessions use a nil type plus a session ID.
            else
                entry[key] = self:CopyTable(value)
            end
        end
    end

    self:MergeNestedDefaults(entry.texts, self.WINDOW.texts)
    self:MergeNestedDefaults(entry.icon, self.WINDOW.icon)
end

function defaults:BuildDefaultFavoriteSlots()
    local slots = {}
    for i = 1, self.FAVORITE_SLOT_COUNT do
        slots[i] = false
    end
    slots[1] = views.Type.Dps
    slots[2] = views.Type.Hps
    return slots
end

function defaults:MigrateFavoriteSlots(db)
    if type(db) ~= 'table' or db.__favoriteSlots ~= nil then
        return
    end

    local slots = self:BuildDefaultFavoriteSlots()
    local old = db.__favoriteViews
    if type(old) == 'table' then
        local used = {
            [slots[1]] = true,
            [slots[2]] = true,
        }
        local index = 3
        for _, category in ipairs(views:GetCategories()) do
            for _, meterType in ipairs(category.types) do
                if old[meterType] and not used[meterType] and index <= self.FAVORITE_SLOT_COUNT then
                    slots[index] = meterType
                    used[meterType] = true
                    index = index + 1
                end
            end
        end
    end
    db.__favoriteSlots = slots
end

function defaults:MergeModuleDefaults(db)
    if type(db) ~= 'table' then
        return
    end

    self:MigrateFavoriteSlots(db)

    for key, value in pairs(self.MODULE) do
        local storedKey = '__' .. key
        if db[storedKey] == nil then
            db[storedKey] = self:CopyTable(value)
        end
    end
end

function defaults:MergeIntoDB(db)
    if type(db) ~= 'table' then
        return
    end

    local previousVersion = db.__exuiDefaultsVersion
    self:MergeModuleDefaults(db)
    for key, entry in pairs(db) do
        if not self:IsMetadataKey(key) and type(entry) == 'table' then
            self:MergeWindowDefaults(entry)
        end
    end

    if previousVersion == 1 then
        db.__enable = false
    end

    if type(previousVersion) == 'number' and previousVersion < 7 then
        for key, entry in pairs(db) do
            if not self:IsMetadataKey(key) and type(entry) == 'table' and type(entry.texts) == 'table' then
                for _, textKey in ipairs({ 'name', 'value', 'secondary', 'percent' }) do
                    if type(entry.texts[textKey]) == 'table' then
                        entry.texts[textKey].width = 0
                    end
                end
            end
        end
    end

    db.__exuiDefaultsVersion = self.SCHEMA_VERSION
end

function defaults:CountWindows(db)
    local count = 0
    if type(db) ~= 'table' then
        return count
    end
    for key, entry in pairs(db) do
        if not self:IsMetadataKey(key) and type(entry) == 'table' then
            count = count + 1
        end
    end
    return count
end

function defaults:BuildNewWindow(db)
    local window = self:CopyTable(self.WINDOW)
    window.ID = EXUI.utils.generateRandomString(10)
    window.createdAt = time()
    local index = self:CountWindows(db)
    window.XOff = (self.WINDOW.XOff or 200) + (index * 40)
    window.YOff = (self.WINDOW.YOff or -240) + (index * -40)
    if index == 0 then
        window.name = 'Damage'
    else
        window.name = 'Meter ' .. (index + 1)
    end
    return window
end
