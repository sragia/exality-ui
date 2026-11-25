---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUILootTracker
local tracker = EXUI:GetModule('loot-tracker')

tracker.rolls = {}
tracker.boundDrops = {}
tracker.users = {}
tracker.listeners = {}
tracker.ticker = nil

local EVENT_ID = 'loot-tracker'
local EVENTS = {
    'START_LOOT_ROLL',
    'CANCEL_LOOT_ROLL',
    'CANCEL_ALL_LOOT_ROLLS',
    'LOOT_HISTORY_UPDATE_DROP',
    'LOOT_HISTORY_UPDATE_ENCOUNTER',
    'LOOT_HISTORY_GO_TO_ENCOUNTER',
    'LOOT_HISTORY_CLEAR_HISTORY',
    'CHAT_MSG_LOOT',
}
local EXPIRE_GRACE = 3
local PURGE_AFTER = 60

-- Enum.EncounterLootDropRollState
local STATE_BY_ENUM = {
    [0] = 'need',
    [1] = 'need',
    [2] = 'transmog',
    [3] = 'greed',
    [4] = 'waiting',
    [5] = 'pass',
}

tracker.STATES = { 'need', 'greed', 'transmog', 'pass' }

local function DropKey(encounterID, listID)
    return encounterID .. ':' .. listID
end

local function GetListID(dropInfo)
    return dropInfo.lootListID or dropInfo.lootListKey
end

local function GetItemID(link)
    return link and C_Item.GetItemInfoInstant(link)
end

local function LinksMatch(a, b)
    if (not a or not b) then return false end
    return a == b or GetItemID(a) == GetItemID(b)
end

local function ShortName(name)
    return name and Ambiguate(name, 'none')
end

------------------------------------------------------------------
-- Roster

local function ForEachGroupMember(func)
    if (IsInRaid()) then
        for i = 1, GetNumGroupMembers() do
            func('raid' .. i)
        end
    else
        func('player')
        for i = 1, GetNumSubgroupMembers() do
            func('party' .. i)
        end
    end
end

local function GetClassForName(name)
    local found
    ForEachGroupMember(function(unit)
        if (not found and UnitName(unit) == name) then
            found = select(2, UnitClass(unit))
        end
    end)
    return found
end

------------------------------------------------------------------
-- Listeners

tracker.AddListener = function(self, id, func)
    self.listeners[id] = func
end

tracker.RemoveListener = function(self, id)
    self.listeners[id] = nil
end

tracker.Notify = function(self, kind, value)
    for _, func in pairs(self.listeners) do
        func(kind, value)
    end
end

------------------------------------------------------------------
-- History

local function ApplyDrop(roll, dropInfo)
    roll.fromHistory = true
    roll.players = {}
    for index, info in ipairs(dropInfo.rollInfos or {}) do
        roll.players[info.playerName] = {
            name = info.playerName,
            class = info.playerClass,
            state = STATE_BY_ENUM[info.state] or 'waiting',
            roll = info.roll,
            order = index,
        }
    end

    local myState = STATE_BY_ENUM[dropInfo.playerRollState]
    if (myState and myState ~= 'waiting') then
        roll.myState = myState
    end

    if (dropInfo.winner) then
        roll.winner = {
            name = dropInfo.winner.playerName,
            class = dropInfo.winner.playerClass,
            state = STATE_BY_ENUM[dropInfo.winner.state],
        }
    end
    roll.allPassed = dropInfo.allPassed
    if ((roll.winner or roll.allPassed) and not roll.finishedAt) then
        roll.finishedAt = GetTime()
    end
end

tracker.ApplyDrop = function(self, target, dropInfo)
    ApplyDrop(target, dropInfo)
end

tracker.HasPendingBinds = function(self)
    for _, roll in pairs(self.rolls) do
        if (not roll.drop and not roll.finishedAt) then
            return true
        end
    end
    return false
end

tracker.BindPending = function(self)
    local pending = {}
    for _, roll in pairs(self.rolls) do
        if (not roll.drop and not roll.finishedAt) then
            table.insert(pending, roll)
        end
    end
    if (#pending == 0) then return end
    table.sort(pending, function(a, b) return a.rollID < b.rollID end)

    local candidates = {}
    for _, encounter in ipairs(C_LootHistory.GetAllEncounterInfos() or {}) do
        for _, drop in ipairs(C_LootHistory.GetSortedDropsForEncounter(encounter.encounterID) or {}) do
            local listID = GetListID(drop)
            local key = DropKey(encounter.encounterID, listID)
            if (not self.boundDrops[key] and not drop.winner and not drop.allPassed) then
                table.insert(candidates, { encounterID = encounter.encounterID, listID = listID, info = drop })
            end
        end
    end
    table.sort(candidates, function(a, b)
        if (a.info.startTime ~= b.info.startTime) then
            return a.info.startTime < b.info.startTime
        end
        return a.listID < b.listID
    end)

    for _, roll in ipairs(pending) do
        for index, candidate in ipairs(candidates) do
            if (LinksMatch(roll.link, candidate.info.itemHyperlink)) then
                roll.drop = { encounterID = candidate.encounterID, listID = candidate.listID }
                self.boundDrops[DropKey(candidate.encounterID, candidate.listID)] = roll.rollID
                ApplyDrop(roll, candidate.info)
                table.remove(candidates, index)
                self:Notify('roll', roll)
                break
            end
        end
    end
end

tracker.RefreshDrop = function(self, roll)
    if (not roll.drop) then return end
    local info = C_LootHistory.GetSortedInfoForDrop(roll.drop.encounterID, roll.drop.listID)
    if (info) then
        ApplyDrop(roll, info)
    end
end

tracker.GetRollForDrop = function(self, encounterID, listID)
    local rollID = self.boundDrops[DropKey(encounterID, listID)]
    return rollID and self.rolls[rollID]
end

------------------------------------------------------------------
-- Chat fallback

local CHAT_GLOBALS = {
    { 'LOOT_ROLL_NEED_SELF', 'need', true },
    { 'LOOT_ROLL_GREED_SELF', 'greed', true },
    { 'LOOT_ROLL_TRANSMOG_SELF', 'transmog', true },
    { 'LOOT_ROLL_PASSED_SELF_AUTO', 'pass', true },
    { 'LOOT_ROLL_PASSED_SELF', 'pass', true },
    { 'LOOT_ROLL_YOU_WON', 'won', true },
    { 'LOOT_ROLL_ALL_PASSED', 'allPassed', true },
    { 'LOOT_ROLL_PASSED_AUTO_FEMALE', 'pass' },
    { 'LOOT_ROLL_PASSED_AUTO', 'pass' },
    { 'LOOT_ROLL_NEED', 'need' },
    { 'LOOT_ROLL_GREED', 'greed' },
    { 'LOOT_ROLL_TRANSMOG', 'transmog' },
    { 'LOOT_ROLL_PASSED', 'pass' },
    { 'LOOT_ROLL_WON', 'won' },
}

local chatPatterns

local function ToPattern(format)
    local pattern = format:gsub('%%%d%$s', '\001'):gsub('%%s', '\001')
    pattern = pattern:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0')
    return '^' .. pattern:gsub('\001', '(.+)') .. '$'
end

local function GetChatPatterns()
    if (chatPatterns) then return chatPatterns end
    chatPatterns = {}
    for _, entry in ipairs(CHAT_GLOBALS) do
        local format = _G[entry[1]]
        if (type(format) == 'string') then
            table.insert(chatPatterns, { pattern = ToPattern(format), kind = entry[2], isSelf = entry[3] })
        end
    end
    return chatPatterns
end

local function FindChatRoll(link, name)
    local fallback
    for _, roll in EXUI.utils.spairs(tracker.rolls) do
        if (not roll.fromHistory and not roll.finishedAt and LinksMatch(roll.link, link)) then
            if (not name or not roll.players[name]) then
                return roll
            end
            fallback = fallback or roll
        end
    end
    return fallback
end

tracker.OnChatMessage = function(self, message)
    if (issecretvalue and issecretvalue(message)) then return end

    for _, entry in ipairs(GetChatPatterns()) do
        local first, second = message:match(entry.pattern)
        if (first) then
            local name, link
            if (entry.isSelf) then
                name, link = UnitName('player'), first
            elseif (first:find('|H', 1, true)) then
                name, link = second, first
            else
                name, link = first, second
            end
            name = ShortName(name)

            local roll = FindChatRoll(link, entry.kind ~= 'won' and entry.kind ~= 'allPassed' and name or nil)
            if (not roll) then return end

            if (entry.kind == 'won') then
                local picked = roll.players[name]
                roll.winner = { name = name, class = GetClassForName(name), state = picked and picked.state }
                roll.finishedAt = GetTime()
            elseif (entry.kind == 'allPassed') then
                roll.allPassed = true
                roll.finishedAt = GetTime()
            else
                roll.players[name] = { name = name, class = GetClassForName(name), state = entry.kind }
            end
            self:Notify('roll', roll)
            return
        end
    end
end

------------------------------------------------------------------
-- Rolls

tracker.AddRoll = function(self, rollID, timeLeftMs)
    local texture, name, count, quality, bindOnPickUp, canNeed, canGreed, _, _, _, _, _, canTransmog =
        GetLootRollItemInfo(rollID)
    if (not name) then return end

    local timeLeft = (timeLeftMs or 0) / 1000
    local duration = C_Loot.GetLootRollDuration and C_Loot.GetLootRollDuration(rollID)
    local roll = {
        rollID = rollID,
        link = GetLootRollItemLink(rollID),
        texture = texture,
        name = name,
        count = count,
        quality = quality,
        bindOnPickUp = bindOnPickUp,
        canNeed = canNeed,
        canGreed = canGreed,
        canTransmog = canTransmog,
        duration = duration and duration / 1000 or timeLeft,
        expires = GetTime() + timeLeft,
        players = {},
    }
    self.rolls[rollID] = roll
    self:BindPending()
    self:Notify('roll', roll)
    self:EnsureTicker()
end

tracker.Rehydrate = function(self)
    if (not GetActiveLootRollIDs) then return end
    for _, rollID in ipairs(GetActiveLootRollIDs()) do
        if (not self.rolls[rollID]) then
            self:AddRoll(rollID, GetLootRollTimeLeft(rollID))
        end
    end
end

tracker.GetRolls = function(self)
    local list = {}
    for _, roll in pairs(self.rolls) do
        table.insert(list, roll)
    end
    table.sort(list, function(a, b) return a.rollID < b.rollID end)
    return list
end

tracker.GetTimeLeft = function(self, roll)
    return math.max(0, roll.expires - GetTime())
end

tracker.SetMyChoice = function(self, rollID, state)
    local roll = self.rolls[rollID]
    if (not roll) then return end
    roll.myState = state
    self:Notify('roll', roll)
end

tracker.GetRoster = function(self)
    local roster = {}
    ForEachGroupMember(function(unit)
        local name = UnitName(unit)
        if (name) then
            table.insert(roster, { name = name, class = select(2, UnitClass(unit)) })
        end
    end)
    return roster
end

local function SortByName(a, b)
    return a.name < b.name
end

-- Players per state. Without history data, waiting is guessed from the group roster.
tracker.GetCounts = function(self, roll)
    local counts = { need = {}, greed = {}, transmog = {}, pass = {}, waiting = {} }
    for _, player in pairs(roll.players) do
        table.insert(counts[player.state], player)
    end

    if (not roll.fromHistory and not roll.finishedAt and not roll.isPreview) then
        for _, member in ipairs(self:GetRoster()) do
            if (not roll.players[member.name]) then
                table.insert(counts.waiting, member)
            end
        end
    end

    for _, list in pairs(counts) do
        table.sort(list, SortByName)
    end
    return counts
end

------------------------------------------------------------------
-- Ticker

tracker.Tick = function(self)
    local now = GetTime()
    local hasRolls = false

    if (self:HasPendingBinds()) then
        self:BindPending()
    end

    for rollID, roll in pairs(self.rolls) do
        if (roll.finishedAt) then
            if (now - roll.finishedAt > PURGE_AFTER) then
                if (roll.drop) then
                    self.boundDrops[DropKey(roll.drop.encounterID, roll.drop.listID)] = nil
                end
                self.rolls[rollID] = nil
            else
                hasRolls = true
            end
        else
            hasRolls = true
            self:RefreshDrop(roll)
            if (not roll.finishedAt and now > roll.expires + EXPIRE_GRACE) then
                roll.finishedAt = now
            end
            self:Notify('roll', roll)
        end
    end

    if (not hasRolls) then
        self.ticker:Cancel()
        self.ticker = nil
    end
end

tracker.EnsureTicker = function(self)
    if (self.ticker) then return end
    self.ticker = C_Timer.NewTicker(1, function() self:Tick() end)
end

------------------------------------------------------------------
-- Lifecycle

tracker.OnEvent = function(self, event, ...)
    if (event == 'START_LOOT_ROLL') then
        local rollID, rollTime = ...
        self:AddRoll(rollID, rollTime)
    elseif (event == 'CANCEL_LOOT_ROLL') then
        local roll = self.rolls[...]
        if (roll) then
            roll.closed = true
            self:Notify('roll', roll)
        end
    elseif (event == 'CANCEL_ALL_LOOT_ROLLS') then
        for _, roll in pairs(self.rolls) do
            roll.closed = true
            self:Notify('roll', roll)
        end
    elseif (event == 'LOOT_HISTORY_UPDATE_DROP') then
        local encounterID, listID = ...
        local roll = self:GetRollForDrop(encounterID, listID)
        if (roll) then
            self:RefreshDrop(roll)
            self:Notify('roll', roll)
        else
            self:BindPending()
        end
        self:Notify('history', encounterID)
    elseif (event == 'LOOT_HISTORY_UPDATE_ENCOUNTER') then
        self:BindPending()
        self:Notify('history', ...)
    elseif (event == 'LOOT_HISTORY_GO_TO_ENCOUNTER') then
        self:Notify('goToEncounter', ...)
    elseif (event == 'LOOT_HISTORY_CLEAR_HISTORY') then
        self.boundDrops = {}
        for _, roll in pairs(self.rolls) do
            roll.drop = nil
        end
        self:Notify('clear')
    elseif (event == 'CHAT_MSG_LOOT') then
        self:OnChatMessage(...)
    end
end

tracker.Acquire = function(self, userID)
    local wasActive = next(self.users) ~= nil
    self.users[userID] = true
    if (wasActive) then return end

    EXUI:RegisterEventHandler(EVENTS, EVENT_ID, function(event, ...)
        self:OnEvent(event, ...)
    end)
    self:Rehydrate()
end

tracker.Release = function(self, userID)
    self.users[userID] = nil
    self.listeners[userID] = nil
    if (next(self.users)) then return end

    EXUI:UnregisterEventHandler(EVENTS, EVENT_ID)
    if (self.ticker) then
        self.ticker:Cancel()
        self.ticker = nil
    end
    self.rolls = {}
    self.boundDrops = {}
end
