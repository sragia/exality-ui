---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysSpellIndex
local spellIndex = EXUI:GetModule('aura-displays-spell-index')

local MIN_SEARCH_LENGTH = 3
local MAX_SEARCH_RESULTS = 10

local function trim(text)
    if not text then
        return ''
    end
    return (text:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function isSecret(value)
    return issecretvalue and issecretvalue(value)
end

function spellIndex:Init()
    self.indexByID = {}
    self.built = false

    if not self.eventFrame then
        self.eventFrame = CreateFrame('Frame')
        self.eventFrame:RegisterEvent('SPELLS_CHANGED')
        self.eventFrame:SetScript('OnEvent', function()
            spellIndex:InvalidateIndex()
        end)
    end
end

function spellIndex:GetSpellInfo(spellID)
    if not spellID then
        return nil
    end
    if C_Spell and C_Spell.GetSpellInfo then
        return C_Spell.GetSpellInfo(spellID)
    end
    local name, _, icon = GetSpellInfo(spellID)
    if not name then
        return nil
    end
    return { name = name, iconID = icon, spellID = spellID }
end

function spellIndex:ResolveToken(token)
    token = trim(token)
    if token == '' then
        return nil
    end

    local spellID = tonumber(token)
    if spellID then
        return spellID
    end

    if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
        spellID = C_Spell.GetSpellIDForSpellIdentifier(token)
        if spellID then
            return spellID
        end
    end

    return nil
end

function spellIndex:RegisterSpell(spellID, name, icon)
    if not spellID or not name or name == '' or isSecret(spellID) or isSecret(name) then
        return
    end

    local entry = self.indexByID[spellID]
    if not entry then
        entry = {
            spellID = spellID,
            name = name,
            nameLower = string.lower(name),
            icon = icon,
        }
        self.indexByID[spellID] = entry
    else
        entry.name = name
        entry.nameLower = string.lower(name)
        if icon then
            entry.icon = icon
        end
    end
end

function spellIndex:RegisterSpellID(spellID)
    if not spellID then
        return
    end
    local info = self:GetSpellInfo(spellID)
    if info and info.name then
        self:RegisterSpell(spellID, info.name, info.iconID)
    end
end

function spellIndex:AddSpellBookSlot(slotIndex, spellBank)
    if not C_SpellBook or not C_SpellBook.GetSpellBookItemInfo then
        return
    end

    local itemInfo = C_SpellBook.GetSpellBookItemInfo(slotIndex, spellBank)
    if not itemInfo then
        return
    end

    local spellID = itemInfo.spellID or itemInfo.actionID
    if spellID and itemInfo.name then
        self:RegisterSpell(spellID, itemInfo.name, itemInfo.iconID)
    end
end

function spellIndex:CollectFromSpellBook()
    if not C_SpellBook or not C_SpellBook.GetNumSpellBookSkillLines then
        return
    end

    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for skillLineIndex = 1, numLines do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
        if skillLineInfo and not skillLineInfo.shouldHide then
            for i = 1, skillLineInfo.numSpellBookItems do
                self:AddSpellBookSlot(i + skillLineInfo.itemIndexOffset, Enum.SpellBookSpellBank.Player)
            end
        end
    end

    if C_SpellBook.HasPetSpells then
        local numPetSpells = select(1, C_SpellBook.HasPetSpells())
        if numPetSpells and numPetSpells > 0 then
            for slotIndex = 1, numPetSpells do
                self:AddSpellBookSlot(slotIndex, Enum.SpellBookSpellBank.Pet)
            end
        end
    end
end

function spellIndex:CollectFromSavedConfigs()
    local auraDisplays = EXUI:GetModule('aura-displays')
    if not auraDisplays or not auraDisplays.GetDB then
        return
    end

    local db = auraDisplays:GetDB()
    for _, display in pairs(db.displays or {}) do
        for _, group in pairs(display.groups or {}) do
            local conditions = group.conditions
            if conditions then
                for _, text in ipairs({ conditions.includeSpellIDs, conditions.excludeSpellIDs }) do
                    if text and text ~= '' then
                        for token in string.gmatch(text, '[^,]+') do
                            local spellID = tonumber(trim(token))
                            if spellID then
                                self:RegisterSpellID(spellID)
                            end
                        end
                    end
                end
            end
        end
    end
end

function spellIndex:EnsureIndex()
    if self.built then
        return
    end
    self.built = true
    self:CollectFromSpellBook()
    self:CollectFromSavedConfigs()
end

function spellIndex:InvalidateIndex()
    self.built = false
    wipe(self.indexByID)
end

function spellIndex:FormatSpellIDList(ids)
    if not ids or #ids == 0 then
        return ''
    end
    return table.concat(ids, ', ')
end

function spellIndex:ParseSpellIDList(text)
    local ids = {}
    local seen = {}
    if not text or text == '' then
        return ids
    end
    for token in string.gmatch(text, '[^,]+') do
        local spellID = self:ResolveToken(token)
        if spellID and not seen[spellID] then
            seen[spellID] = true
            table.insert(ids, spellID)
            self:RegisterSpellID(spellID)
        end
    end
    return ids
end

function spellIndex:ResolveInput(text)
    return self:ResolveToken(text)
end

function spellIndex:GetSpellEntry(spellID)
    if not spellID then
        return nil
    end
    local info = self:GetSpellInfo(spellID)
    if info and info.name then
        local icon = info.iconID or info.originalIconID
        self:RegisterSpell(spellID, info.name, icon)
        return {
            spellID = spellID,
            name = info.name,
            icon = icon,
        }
    end
    return {
        spellID = spellID,
        name = tostring(spellID),
        icon = nil,
    }
end

function spellIndex:NormalizeSpellIDListText(text)
    return self:FormatSpellIDList(self:ParseSpellIDList(text))
end

function spellIndex:FormatSpellIDListDisplay(text)
    if not text or text == '' then
        return ''
    end

    local parts = {}
    for token in string.gmatch(text, '[^,]+') do
        local spellID = tonumber(trim(token))
        if spellID then
            local info = self:GetSpellInfo(spellID)
            if info and info.name then
                table.insert(parts, string.format('%s (%d)', info.name, spellID))
                self:RegisterSpell(spellID, info.name, info.iconID)
            else
                table.insert(parts, tostring(spellID))
            end
        end
    end

    return table.concat(parts, ', ')
end

function spellIndex:Search(query, maxResults)
    self:EnsureIndex()
    query = string.lower(trim(query))
    if #query < MIN_SEARCH_LENGTH then
        return {}
    end

    maxResults = maxResults or MAX_SEARCH_RESULTS
    local exact, prefix, contains = {}, {}, {}

    for _, entry in pairs(self.indexByID) do
        local nameLower = entry.nameLower
        if nameLower == query then
            table.insert(exact, entry)
        elseif nameLower:sub(1, #query) == query then
            table.insert(prefix, entry)
        elseif nameLower:find(query, 1, true) then
            table.insert(contains, entry)
        end
    end

    local function sortByName(a, b)
        return a.name < b.name
    end
    table.sort(exact, sortByName)
    table.sort(prefix, sortByName)
    table.sort(contains, sortByName)

    local results = {}
    for _, bucket in ipairs({ exact, prefix, contains }) do
        for _, entry in ipairs(bucket) do
            table.insert(results, entry)
            if #results >= maxResults then
                return results
            end
        end
    end

    return results
end

function spellIndex:GetAutocompleteResults(text, maxResults)
    self:EnsureIndex()
    text = trim(text)
    if text == '' then
        return {}
    end

    maxResults = maxResults or MAX_SEARCH_RESULTS
    local results = {}
    local seen = {}

    local function pushEntry(entry)
        if entry and entry.spellID and not seen[entry.spellID] then
            seen[entry.spellID] = true
            table.insert(results, entry)
        end
    end

    local resolvedID = self:ResolveInput(text)
    if resolvedID and self:GetSpellInfo(resolvedID) then
        pushEntry(self:GetSpellEntry(resolvedID))
    end

    for _, entry in ipairs(self:Search(text, maxResults)) do
        pushEntry(entry)
        if #results >= maxResults then
            break
        end
    end

    return results
end

function spellIndex:GetCurrentSearchToken(text)
    if not text or text == '' then
        return ''
    end
    local token = text:match(',([^,]*)$')
    if token then
        return trim(token)
    end
    return trim(text)
end

function spellIndex:ReplaceCurrentSearchToken(text, replacement)
    text = text or ''
    local prefix = text:match('^(.*),')
    if prefix then
        prefix = trim(prefix)
        if prefix == '' then
            return replacement
        end
        return prefix .. ', ' .. replacement
    end
    return replacement
end

function spellIndex:AppendSpellID(text, spellID)
    local normalized = self:NormalizeSpellIDListText(text)
    local idText = tostring(spellID)
    if normalized == '' then
        return idText
    end
    for token in string.gmatch(normalized, '[^,]+') do
        if tonumber(trim(token)) == spellID then
            return normalized
        end
    end
    return normalized .. ', ' .. idText
end

function spellIndex:CanReadUnitAuras(unit)
    if not unit or unit == '' or not UnitExists(unit) then
        return false, 'Unit not available.'
    end
    if not C_UnitAuras or not C_UnitAuras.GetUnitAuras then
        return false, 'Aura API unavailable.'
    end
    return true
end

function spellIndex:GetUnitAuraEntries(unit, filterString)
    local ok, reason = self:CanReadUnitAuras(unit)
    if not ok then
        return {}, reason
    end

    filterString = filterString or 'HELPFUL|HARMFUL'
    local okCall, auras = pcall(C_UnitAuras.GetUnitAuras, unit, filterString)
    if not okCall or not auras then
        return {}, 'Unable to read auras on this unit.'
    end

    local entries = {}
    local seen = {}
    for _, aura in ipairs(auras) do
        local spellID = aura and aura.spellId
        local name = aura and aura.name
        if spellID and name and not isSecret(spellID) and not isSecret(name) and not seen[spellID] then
            seen[spellID] = true
            local icon = aura.icon
            self:RegisterSpell(spellID, name, icon)
            table.insert(entries, {
                spellID = spellID,
                name = name,
                icon = icon,
            })
        end
    end

    table.sort(entries, function(a, b)
        return a.name < b.name
    end)

    if #entries == 0 then
        return entries, 'No readable auras found on this unit.'
    end
    return entries
end

function spellIndex:BuildPickerMenuEntries(auraEntries, onSelect)
    local menuEntries = {}
    for _, entry in ipairs(auraEntries) do
        table.insert(menuEntries, {
            text = string.format('%s (%d)', entry.name, entry.spellID),
            icon = entry.icon,
            onClick = function()
                if onSelect then
                    onSelect(entry.spellID, entry.name, entry.icon)
                end
            end,
        })
    end
    return menuEntries
end

function spellIndex:BuildSearchMenuEntries(results, onSelect)
    local menuEntries = {}
    for _, entry in ipairs(results) do
        table.insert(menuEntries, {
            text = string.format('%s (%d)', entry.name, entry.spellID),
            icon = entry.icon,
            onClick = function()
                if onSelect then
                    onSelect(entry.spellID, entry.name, entry.icon)
                end
            end,
        })
    end
    return menuEntries
end
