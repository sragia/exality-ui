---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysEncounterJournal
local journal = EXUI:GetModule('aura-displays-encounter-journal')

local MAX_DUNGEONS = 40
local MAX_BOSSES = 40
local DEFAULT_BOSS_IMAGE = 'Interface\\EncounterJournal\\UI-EJ-BOSS-Default'
-- Journal boss art is shown at 128x64. The dropdown center-crops that to a square.
local BOSS_IMAGE_SIZE = { w = 128, h = 64 }

journal.pick = {}

function journal:GetPick(owner)
    local pick = self.pick[owner]
    if not pick then
        pick = {}
        self.pick[owner] = pick
    end
    return pick
end

function journal:FormatList(list)
    if not list then
        return ''
    end
    local parts = {}
    for _, encounterID in ipairs(list) do
        local id = tonumber(encounterID)
        if id and id > 0 then
            parts[#parts + 1] = tostring(id)
        end
    end
    return table.concat(parts, ', ')
end

function journal:ParseList(text)
    local list = {}
    local seen = {}
    for token in string.gmatch(text or '', '[^,]+') do
        local id = tonumber(strtrim(token))
        if id and id > 0 and not seen[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end
    return list
end

function journal:RestoreSelection(instanceID, difficultyID)
    pcall(function()
        if instanceID and instanceID ~= 0 and EJ_SelectInstance then
            EJ_SelectInstance(instanceID)
        end
        if difficultyID and EJ_SetDifficulty then
            EJ_SetDifficulty(difficultyID)
        end
    end)
end

function journal:CollectSeasonNames()
    local names = {}
    if not C_ChallengeMode or not C_ChallengeMode.GetMapTable or not C_ChallengeMode.GetMapUIInfo then
        return names
    end
    local maps = C_ChallengeMode.GetMapTable()
    if not maps then
        return names
    end
    for _, challengeID in ipairs(maps) do
        local name = C_ChallengeMode.GetMapUIInfo(challengeID)
        if name and name ~= '' then
            names[name] = true
        end
    end
    return names
end

function journal:ReadBossImage(journalEncounterID)
    if not EJ_GetCreatureInfo or not journalEncounterID then
        return nil
    end
    local ok, iconImage = pcall(function()
        return select(5, EJ_GetCreatureInfo(1, journalEncounterID))
    end)
    if not ok or not iconImage or iconImage == '' or iconImage == 0 then
        iconImage = DEFAULT_BOSS_IMAGE
    end
    return {
        texture = iconImage,
        imageSize = BOSS_IMAGE_SIZE,
    }
end

function journal:ReadBosses(instanceID, instanceName, startOrder)
    local bosses = {}
    local order = startOrder
    if EJ_SelectInstance then
        EJ_SelectInstance(instanceID)
    end
    for bossIndex = 1, MAX_BOSSES do
        local bossName, _, journalEncounterID = EJ_GetEncounterInfoByIndex(bossIndex)
        if not journalEncounterID or journalEncounterID <= 0 then
            break
        end
        local encounterID = journalEncounterID
        if EJ_GetEncounterInfo then
            local infoOk, dungeonEncounterID = pcall(function()
                return select(7, EJ_GetEncounterInfo(journalEncounterID))
            end)
            dungeonEncounterID = infoOk and tonumber(dungeonEncounterID) or nil
            if dungeonEncounterID and dungeonEncounterID > 0 then
                encounterID = dungeonEncounterID
            end
        end
        if encounterID and encounterID > 0 then
            order = order + 1
            local label = instanceName and (instanceName .. ' - ' .. (bossName or tostring(encounterID)))
                or (bossName or tostring(encounterID))
            bosses[#bosses + 1] = {
                id = encounterID,
                label = label,
                order = order,
                icon = self:ReadBossImage(journalEncounterID),
            }
        end
    end
    return bosses, order
end

function journal:EnsureCache()
    if self.ready then
        return
    end
    self.encounters = {}

    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn('Blizzard_EncounterJournal')
    end
    if type(EJ_GetInstanceByIndex) ~= 'function' or type(EJ_GetEncounterInfoByIndex) ~= 'function' then
        return
    end

    local prevInstance = EJ_GetCurrentInstance and EJ_GetCurrentInstance()
    local prevDifficulty = EJ_GetDifficulty and EJ_GetDifficulty()

    local encounters = {}
    pcall(function()
        if C_EncounterJournal and C_EncounterJournal.InitalizeSelectedTier then
            C_EncounterJournal.InitalizeSelectedTier()
        end
        local tier = EJ_GetCurrentTier and EJ_GetCurrentTier()
        if tier and tier > 0 and EJ_SelectTier then
            EJ_SelectTier(tier)
        end

        local seasonNames = self:CollectSeasonNames()
        local instances = {}
        local seen = {}
        local function addInstance(instanceID, name)
            if not instanceID or seen[instanceID] then
                return
            end
            seen[instanceID] = true
            instances[#instances + 1] = { id = instanceID, name = name }
        end

        for index = 1, MAX_DUNGEONS do
            local instanceID, name = EJ_GetInstanceByIndex(index, true)
            if not instanceID then
                break
            end
            addInstance(instanceID, name)
        end

        local tierDungeons = {}
        for index = 1, MAX_DUNGEONS do
            local instanceID, name = EJ_GetInstanceByIndex(index, false)
            if not instanceID then
                break
            end
            tierDungeons[#tierDungeons + 1] = { id = instanceID, name = name }
        end

        local matched = 0
        for _, dungeon in ipairs(tierDungeons) do
            if dungeon.name and seasonNames[dungeon.name] then
                addInstance(dungeon.id, dungeon.name)
                matched = matched + 1
            end
        end
        if matched == 0 then
            for _, dungeon in ipairs(tierDungeons) do
                addInstance(dungeon.id, dungeon.name)
            end
        end

        local order = 0
        local used = {}
        for _, instance in ipairs(instances) do
            local bossesOk, bosses, nextOrder = pcall(self.ReadBosses, self, instance.id, instance.name, order)
            if bossesOk and bosses then
                order = nextOrder or order
                for _, boss in ipairs(bosses) do
                    if not used[boss.id] then
                        used[boss.id] = true
                        encounters[#encounters + 1] = boss
                    end
                end
            end
        end
    end)

    self:RestoreSelection(prevInstance, prevDifficulty)
    if #encounters > 0 then
        self.encounters = encounters
        self.ready = true
    end
end

function journal:GetEncounterOptions()
    self:EnsureCache()
    local options = {}
    for _, encounter in ipairs(self.encounters or {}) do
        options[encounter.id] = {
            label = encounter.label,
            order = encounter.order,
            icon = encounter.icon,
        }
    end
    return options
end

function journal:GetOptionFields(api)
    local pick = self:GetPick(api.owner)
    local depends = api.depends
    local encounters = api.getList and api.getList() or nil
    local encounterExpanded = type(encounters) == 'table' and #encounters > 0
    local fields = {
        { type = 'title', label = 'Encounter', width = 100, expanded = encounterExpanded },
    }
    if not EXUI.IsForever() then
        fields[#fields + 1] = {
            type = 'dropdown',
            label = 'Encounter',
            name = 'encounterPick',
            width = 70,
            depends = depends,
            getOptions = function()
                return self:GetEncounterOptions()
            end,
            currentValue = function()
                return pick.encounterID
            end,
            onChange = function(value)
                pick.encounterID = tonumber(value)
            end,
        }
        fields[#fields + 1] = {
            type = 'button',
            label = 'Add',
            name = 'addEncounter',
            width = 30,
            depends = depends,
            onClick = function()
                local encounterID = tonumber(pick.encounterID)
                if not encounterID then
                    return
                end
                local list = api.getList() or {}
                if not tContains(list, encounterID) then
                    table.insert(list, encounterID)
                    api.setList(list)
                end
                if api.onChanged then
                    api.onChanged()
                end
            end,
        }
    end
    fields[#fields + 1] = {
        type = 'edit-box',
        label = 'Encounter IDs',
        name = 'loadEncounters',
        width = 100,
        tooltip = {
            text = EXUI.IsForever() and 'Comma separated encounter IDs.'
                or 'Comma separated encounter IDs. Add a current season boss above, or type an ID.',
        },
        depends = depends,
        currentValue = function()
            return self:FormatList(api.getList())
        end,
        onChange = function(value)
            api.setList(self:ParseList(value))
            if api.refreshDisplay then
                api.refreshDisplay()
            end
        end,
    }
    return fields
end
