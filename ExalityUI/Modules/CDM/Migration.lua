---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local profileData = EXUI:GetModule('data')

---@class EXUICDMDefaults
local defaults = EXUI:GetModule('cdm-defaults')

---@class EXUICDMData
local data = EXUI:GetModule('cdm-data')

---@class EXUICDMMigration
local migration = EXUI:GetModule('cdm-migration')

local function legacySource(entry)
    local source = entry.cooldownSource
    if source == 'spell' or source == 'item' or source == 'equipment' then
        return source
    end
    return entry.isItem and 'item' or 'spell'
end

local function color(value, fallback)
    return value and EXUI.utils.deepCloneTable(value) or fallback
end

local function convertTexts(entry)
    local texts = {}
    if entry.showCooldownText ~= false then
        texts[#texts + 1] = {
            kind = 'cooldown',
            font = entry.font,
            fontSize = entry.fontSize,
            fontFlag = entry.fontFlag,
            anchorPoint = entry.fontAnchorPoint,
            relativePoint = entry.fontRelativePoint,
            XOff = entry.fontXOff,
            YOff = entry.fontYOff,
            format = entry.cooldownTextFormat,
            updateInterval = entry.cooldownTextUpdateInterval,
        }
    end
    if entry.showStacks and legacySource(entry) ~= 'equipment' then
        texts[#texts + 1] = {
            kind = 'charges',
            font = entry.chargeFont,
            fontSize = entry.chargeFontSize,
            fontFlag = entry.chargeFontFlag,
            anchorPoint = entry.chargeFontAnchorPoint,
            relativePoint = entry.chargeFontRelativePoint,
            XOff = entry.chargeFontXOff,
            YOff = entry.chargeFontYOff,
        }
    end
    return texts
end

local function convertItem(entry, parentID)
    return {
        kind = 'item',
        name = entry.name,
        enable = entry.enable ~= false,
        order = entry.order,
        createdAt = entry.createdAt,
        parentID = parentID,
        scope = not parentID and { mode = 'all' } or nil,
        display = 'icon',
        source = {
            type = legacySource(entry),
            spellID = tonumber(entry.spellID),
            itemID = tonumber(entry.itemID),
            slot = tonumber(entry.equipmentSlot) or 13,
            ignoreGCD = entry.ignoreGlobalCooldown ~= false,
        },
        position = {
            anchorPoint = entry.anchorPoint,
            relativePoint = entry.relativePoint,
            XOff = entry.XOff,
            YOff = entry.YOff,
        },
        frameStrata = entry.frameStrata,
        frameLevel = entry.frameLevel,
        override = { size = true, icon = true, texts = true },
        iconAppearance = {
            width = entry.width,
            height = entry.height,
            zoom = entry.zoom or 0,
            borderColor = color(entry.borderColor),
            backgroundColor = { r = 0, g = 0, b = 0, a = 0 },
            desaturateOnCooldown = entry.desaturateOnCooldown and true or false,
        },
        texts = convertTexts(entry),
        load = {
            hasLoadConditions = entry.hasLoadConditions and true or false,
            onlyLoadOnPlayer = entry.onlyLoadOnPlayer or '',
            dontLoadOnPlayer = entry.dontLoadOnPlayer or '',
        },
    }
end

local function convertGroup(group, parentID)
    return {
        kind = 'group',
        name = group.name,
        icon = group.icon,
        enable = group.enable ~= false,
        order = group.order,
        createdAt = group.createdAt,
        parentID = parentID,
        scope = not parentID and { mode = 'all' } or nil,
        layout = { mode = 'free' },
    }
end

-- Old folders become free-layout groups, so every icon keeps its position.
function migration:ConvertLegacy(legacyDB, insert)
    local groups = legacyDB.__groups or {}
    local function validParent(parentID)
        return parentID and groups[parentID] and parentID or nil
    end
    for groupID, group in pairs(groups) do
        if type(group) == 'table' then
            insert(groupID, convertGroup(group, validParent(group.parentID)))
        end
    end
    for id, entry in pairs(legacyDB) do
        if not defaults:IsMetadataKey(id) and type(entry) == 'table' then
            insert(id, convertItem(entry, validParent(entry.groupID)))
        end
    end
end

-- Old Cooldowns share strings (module 'cooldowns') become CDM payloads; items used groupID as parent.
function migration:ConvertSharePayload(payload)
    if payload.module ~= 'cooldowns' then
        return nil
    end
    local converted = { v = payload.v, module = 'cdm', kind = payload.kind, rootID = payload.rootID }
    if payload.kind == 'item' then
        converted.item = type(payload.item) == 'table' and convertItem(payload.item, nil) or nil
        return converted
    end
    converted.groups, converted.items = {}, {}
    for id, group in pairs(payload.groups or {}) do
        if type(group) == 'table' then
            converted.groups[id] = convertGroup(group, group.parentID)
        end
    end
    for id, entry in pairs(payload.items or {}) do
        if type(entry) == 'table' then
            converted.items[id] = convertItem(entry, entry.groupID)
        end
    end
    return converted
end

function migration:Run()
    if data:GetModuleValue('migratedFromCooldowns') then
        return
    end
    local legacyDB = profileData:GetDataByKey('cooldowns')
    if type(legacyDB) == 'table' then
        self:ConvertLegacy(legacyDB, function(id, node)
            if not data:GetNode(id) then
                data:Insert(id, node)
            end
        end)
    end
    data:SetModuleValue('migratedFromCooldowns', true)
end
