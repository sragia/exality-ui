---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICooldownsDefaults
local defaults = EXUI:GetModule('cooldowns-defaults')

defaults.SCHEMA_VERSION = 3

defaults.DISPLAY = {
    enable = true,
    name = 'New Cooldown',
    showStacks = false,
    cooldownSource = 'spell',
    isItem = false, -- legacy compatibility
    spellID = nil,
    itemID = nil,
    equipmentSlot = 13,
    hasLoadConditions = false,
    onlyLoadOnPlayer = '',
    dontLoadOnPlayer = '',
    width = 80,
    height = 80,
    zoom = 0,
    borderColor = { r = 0, g = 0, b = 0, a = 1 },
    anchorPoint = 'CENTER',
    relativePoint = 'CENTER',
    XOff = 0,
    YOff = 0,
    frameStrata = 'LOW',
    frameLevel = 10,
    font = 'DMSans',
    fontSize = 12,
    fontFlag = 'OUTLINE',
    fontAnchorPoint = 'CENTER',
    fontRelativePoint = 'CENTER',
    fontXOff = 0,
    fontYOff = 0,
    showCooldownText = true,
    cooldownTextFormat = 'mmss',
    cooldownTextUpdateInterval = 0.05,
    readyPollInterval = 1,
    chargeFont = 'DMSans',
    chargeFontSize = 12,
    chargeFontFlag = 'OUTLINE',
    chargeFontAnchorPoint = 'CENTER',
    chargeFontRelativePoint = 'CENTER',
    chargeFontXOff = 0,
    chargeFontYOff = 0,
}

function defaults:CopyTable(value)
    return EXUI.utils.deepCloneTable(value)
end

function defaults:IsMetadataKey(key)
    return type(key) == 'string' and key:sub(1, 2) == '__'
end

function defaults:NormalizeCooldownSource(entry)
    local source = entry.cooldownSource
    if source ~= 'spell' and source ~= 'item' and source ~= 'equipment' then
        source = entry.isItem and 'item' or 'spell'
    end
    entry.cooldownSource = source
    entry.isItem = source == 'item'
end

function defaults:NormalizeIDs(entry)
    local spellID = tonumber(entry.spellID)
    local itemID = tonumber(entry.itemID)
    local equipmentSlot = tonumber(entry.equipmentSlot)
    entry.spellID = spellID
    entry.itemID = itemID
    if equipmentSlot and equipmentSlot >= 1 then
        entry.equipmentSlot = equipmentSlot
    elseif entry.equipmentSlot == nil then
        entry.equipmentSlot = self.DISPLAY.equipmentSlot
    else
        entry.equipmentSlot = nil
    end
end

function defaults:MergeDisplayDefaults(entry)
    if type(entry) ~= 'table' then
        return
    end

    for key, value in pairs(self.DISPLAY) do
        if entry[key] == nil then
            entry[key] = self:CopyTable(value)
        end
    end

    self:NormalizeCooldownSource(entry)
    self:NormalizeIDs(entry)
end

function defaults:MergeIntoDB(db)
    if type(db) ~= 'table' then
        return
    end

    for key, entry in pairs(db) do
        if not self:IsMetadataKey(key) and type(entry) == 'table' then
            self:MergeDisplayDefaults(entry)
        end
    end

    db.__exuiDefaultsVersion = self.SCHEMA_VERSION
end

function defaults:BuildNewDisplay()
    local display = self:CopyTable(self.DISPLAY)
    display.ID = EXUI.utils.generateRandomString(10)
    display.createdAt = time()
    return display
end
