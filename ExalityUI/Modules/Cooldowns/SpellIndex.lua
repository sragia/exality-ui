---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICooldownsSpellIndex
local spellIndex = EXUI:GetModule('cooldowns-spell-index')

local MIN_SEARCH_LENGTH = 2
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
    self.indexByID = self.indexByID or {}
    self.built = false

    if not self.eventFrame then
        self.eventFrame = CreateFrame('Frame')
        self.eventFrame:RegisterEvent('SPELLS_CHANGED')
        self.eventFrame:SetScript('OnEvent', function()
            spellIndex:InvalidateIndex()
        end)
    end
end

function spellIndex:InvalidateIndex()
    self.built = false
    wipe(self.indexByID)
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

function spellIndex:RegisterSpell(spellID, name, icon)
    if not spellID or not name or name == '' or isSecret(spellID) or isSecret(name) then
        return
    end

    self.indexByID[spellID] = {
        spellID = spellID,
        name = name,
        icon = icon,
        nameLower = string.lower(name),
    }
end

function spellIndex:RegisterSpellID(spellID)
    local info = self:GetSpellInfo(spellID)
    if not info or not info.name then
        return
    end
    self:RegisterSpell(spellID, info.name, info.iconID or info.originalIconID)
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
end

function spellIndex:CollectFromSavedConfigs()
    local cooldowns = EXUI:GetModule('cooldowns')
    if not cooldowns or not cooldowns.GetBaseDB then
        return
    end

    local db = cooldowns:GetBaseDB()
    for key, entry in pairs(db) do
        if type(entry) == 'table' and type(key) == 'string' and key:sub(1, 2) ~= '__' then
            local source = entry.cooldownSource or (entry.isItem and 'item' or 'spell')
            if source == 'spell' then
                local spellID = tonumber(entry.spellID)
                if spellID then
                    self:RegisterSpellID(spellID)
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

function spellIndex:ResolveInput(text)
    text = trim(text)
    if text == '' then
        return nil
    end

    local numeric = tonumber(text)
    if numeric then
        return numeric
    end

    if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
        local resolved = C_Spell.GetSpellIDForSpellIdentifier(text)
        if resolved then
            return resolved
        end
    end

    self:EnsureIndex()
    local lowered = string.lower(text)
    for spellID, entry in pairs(self.indexByID) do
        if entry.nameLower == lowered then
            return spellID
        end
    end

    return nil
end

function spellIndex:GetEntry(spellID)
    if not spellID then
        return nil
    end
    self:RegisterSpellID(spellID)
    local entry = self.indexByID[spellID]
    if entry then
        return entry
    end
    return {
        spellID = spellID,
        name = tostring(spellID),
        icon = nil,
        nameLower = tostring(spellID),
    }
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

    local resolved = self:ResolveInput(text)
    if resolved then
        local direct = self:GetEntry(resolved)
        if direct then
            table.insert(results, direct)
            seen[resolved] = true
        end
    end

    local query = string.lower(text)
    if #query >= MIN_SEARCH_LENGTH then
        local exact, prefix, contains = {}, {}, {}
        for spellID, entry in pairs(self.indexByID) do
            if not seen[spellID] then
                local nameLower = entry.nameLower
                if nameLower == query then
                    table.insert(exact, entry)
                elseif nameLower:sub(1, #query) == query then
                    table.insert(prefix, entry)
                elseif nameLower:find(query, 1, true) then
                    table.insert(contains, entry)
                end
            end
        end

        local function sortByName(a, b)
            return a.name < b.name
        end
        table.sort(exact, sortByName)
        table.sort(prefix, sortByName)
        table.sort(contains, sortByName)

        for _, bucket in ipairs({ exact, prefix, contains }) do
            for _, entry in ipairs(bucket) do
                table.insert(results, entry)
                if #results >= maxResults then
                    return results
                end
            end
        end
    end

    return results
end

function spellIndex:BuildSearchMenuEntries(results, onSelect)
    local entries = {}
    for _, entry in ipairs(results) do
        table.insert(entries, {
            text = string.format('%s (%d)', entry.name, entry.spellID),
            icon = entry.icon,
            onClick = function()
                if onSelect then
                    onSelect(entry.spellID)
                end
            end,
        })
    end
    return entries
end
