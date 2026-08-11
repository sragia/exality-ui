---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICooldownsItemIndex
local itemIndex = EXUI:GetModule('cooldowns-item-index')

local MIN_SEARCH_LENGTH = 2
local MAX_SEARCH_RESULTS = 10

local EQUIPMENT_SLOTS = {
    1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19,
}

local function trim(text)
    if not text then
        return ''
    end
    return (text:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function getBagIndices()
    local bags = { 0 }
    local maxBags = NUM_BAG_SLOTS or 4
    for bag = 1, maxBags do
        table.insert(bags, bag)
    end
    return bags
end

function itemIndex:Init()
    self.indexByID = self.indexByID or {}
    self.built = false

    if not self.eventFrame then
        self.eventFrame = CreateFrame('Frame')
        self.eventFrame:RegisterEvent('BAG_UPDATE')
        self.eventFrame:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
        self.eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
        self.eventFrame:SetScript('OnEvent', function()
            itemIndex:InvalidateIndex()
        end)
    end
end

function itemIndex:InvalidateIndex()
    self.built = false
    wipe(self.indexByID)
end

function itemIndex:GetItemInfo(itemID)
    if not itemID then
        return nil
    end

    local name, _, _, _, _, _, _, _, _, texture = C_Item.GetItemInfo(itemID)
    if name then
        return {
            itemID = itemID,
            name = name,
            icon = texture,
        }
    end

    if C_Item.GetItemInfoInstant then
        local _, _, _, _, _, _, _, _, _, instantIcon = C_Item.GetItemInfoInstant(itemID)
        if instantIcon then
            return {
                itemID = itemID,
                name = tostring(itemID),
                icon = instantIcon,
            }
        end
    end

    if C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end

    return nil
end

function itemIndex:RegisterItemID(itemID)
    if not itemID then
        return
    end

    local info = self:GetItemInfo(itemID)
    if not info then
        return
    end

    local existing = self.indexByID[itemID]
    if existing then
        existing.name = info.name or existing.name
        existing.icon = info.icon or existing.icon
        existing.nameLower = string.lower(existing.name or tostring(itemID))
        return
    end

    self.indexByID[itemID] = {
        itemID = itemID,
        name = info.name or tostring(itemID),
        icon = info.icon,
        nameLower = string.lower(info.name or tostring(itemID)),
    }
end

function itemIndex:CollectFromEquipped()
    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local itemID = GetInventoryItemID('player', slot)
        if itemID then
            self:RegisterItemID(itemID)
        end
    end
end

function itemIndex:CollectFromBags()
    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemID then
        return
    end

    for _, bag in ipairs(getBagIndices()) do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                self:RegisterItemID(itemID)
            end
        end
    end
end

function itemIndex:CollectFromSavedConfigs()
    local cooldowns = EXUI:GetModule('cooldowns')
    if not cooldowns or not cooldowns.GetBaseDB then
        return
    end

    local db = cooldowns:GetBaseDB()
    for key, entry in pairs(db) do
        if type(entry) == 'table' and type(key) == 'string' and key:sub(1, 2) ~= '__' then
            local source = entry.cooldownSource or (entry.isItem and 'item' or 'spell')
            if source == 'item' then
                local itemID = tonumber(entry.itemID)
                if itemID then
                    self:RegisterItemID(itemID)
                end
            end
        end
    end
end

function itemIndex:EnsureIndex()
    if self.built then
        return
    end
    self.built = true
    self:CollectFromEquipped()
    self:CollectFromBags()
    self:CollectFromSavedConfigs()
end

function itemIndex:ResolveInput(text)
    text = trim(text)
    if text == '' then
        return nil
    end

    local numeric = tonumber(text)
    if numeric then
        return numeric
    end

    local linkedItemID = tonumber(string.match(text, 'item:(%d+)'))
    if linkedItemID then
        return linkedItemID
    end

    self:EnsureIndex()
    local lowered = string.lower(text)
    for itemID, entry in pairs(self.indexByID) do
        if entry.nameLower == lowered then
            return itemID
        end
    end

    return nil
end

function itemIndex:GetEntry(itemID)
    if not itemID then
        return nil
    end
    self:RegisterItemID(itemID)
    local entry = self.indexByID[itemID]
    if entry then
        return entry
    end
    return {
        itemID = itemID,
        name = tostring(itemID),
        icon = nil,
        nameLower = tostring(itemID),
    }
end

function itemIndex:GetAutocompleteResults(text, maxResults)
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
        local entry = self:GetEntry(resolved)
        if entry then
            table.insert(results, entry)
            seen[resolved] = true
        end
    end

    local query = string.lower(text)
    if #query >= MIN_SEARCH_LENGTH then
        local exact, prefix, contains = {}, {}, {}
        for itemID, entry in pairs(self.indexByID) do
            if not seen[itemID] then
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

function itemIndex:BuildSearchMenuEntries(results, onSelect)
    local entries = {}
    for _, entry in ipairs(results) do
        table.insert(entries, {
            text = string.format('%s (%d)', entry.name, entry.itemID),
            icon = entry.icon,
            onClick = function()
                if onSelect then
                    onSelect(entry.itemID)
                end
            end,
        })
    end
    return entries
end
