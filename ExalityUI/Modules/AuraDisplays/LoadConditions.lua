---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysLoadConditions
local loadConditions = EXUI:GetModule('aura-displays-load-conditions')

local INSTANCE_MAP = {
    ['Open World'] = 'none',
    Dungeon = 'party',
    Raid = 'raid',
    Battleground = 'pvp',
    Arena = 'arena',
    ['Mythic+'] = 'mythicplus',
    Scenario = 'scenario',
}

local CLASS_FILE_MAP = {
    WARRIOR = 'Warrior',
    PALADIN = 'Paladin',
    HUNTER = 'Hunter',
    ROGUE = 'Rogue',
    PRIEST = 'Priest',
    DEATHKNIGHT = 'Death Knight',
    SHAMAN = 'Shaman',
    MAGE = 'Mage',
    WARLOCK = 'Warlock',
    MONK = 'Monk',
    DRUID = 'Druid',
    DEMONHUNTER = 'Demon Hunter',
    EVOKER = 'Evoker',
}

local ROLE_LABELS = { TANK = 'Tank', HEALER = 'Healer', DAMAGER = 'DPS' }

local STATIC_REFRESH_EVENTS = {
    'PLAYER_ENTERING_WORLD',
    'ZONE_CHANGED_NEW_AREA',
    'CHALLENGE_MODE_START',
    'CHALLENGE_MODE_COMPLETED',
    'GROUP_ROSTER_UPDATE',
    'PLAYER_ROLES_ASSIGNED',
    'PLAYER_SPECIALIZATION_CHANGED',
}

function loadConditions:ParseCSVList(text)
    local list = {}
    if not text or text == '' then
        return list
    end
    for name in string.gmatch(text, '[^,]+') do
        name = strtrim(name)
        if name ~= '' then
            table.insert(list, name)
        end
    end
    return list
end

function loadConditions:ListContains(list, value)
    if not list or #list == 0 then
        return true
    end
    return tContains(list, value)
end

function loadConditions:GetCurrentInstanceType()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return 'none'
    end
    if instanceType == 'party'
        and C_ChallengeMode
        and C_ChallengeMode.IsChallengeModeActive
        and C_ChallengeMode.IsChallengeModeActive()
    then
        return 'mythicplus'
    end
    return instanceType
end

function loadConditions:MatchesInstance(loadInstances)
    if not loadInstances or #loadInstances == 0 then
        return true
    end
    local current = self:GetCurrentInstanceType()
    for _, instance in ipairs(loadInstances) do
        if INSTANCE_MAP[instance] == current then
            return true
        end
    end
    return false
end

function loadConditions:MatchesClass(loadClasses)
    if not loadClasses or #loadClasses == 0 then
        return true
    end
    local _, classFile = UnitClass('player')
    local className = CLASS_FILE_MAP[classFile]
    return className and tContains(loadClasses, className)
end

local function getPlayerSpecInfo()
    local getSpec = GetSpecialization
    local getSpecInfo = GetSpecializationInfo
    if not getSpec and C_SpecializationInfo then
        getSpec = C_SpecializationInfo.GetSpecialization
        getSpecInfo = C_SpecializationInfo.GetSpecializationInfo
    end
    if not getSpec or not getSpecInfo then
        return nil
    end
    local specIndex = getSpec()
    if not specIndex then
        return nil
    end
    return getSpecInfo(specIndex)
end

function loadConditions:MatchesSpec(loadSpecs)
    if not loadSpecs or #loadSpecs == 0 then
        return true
    end
    local _, specName = getPlayerSpecInfo()
    return specName and tContains(loadSpecs, specName)
end

function loadConditions:GetPlayerRole()
    local role = UnitGroupRolesAssigned('player')
    if role and role ~= 'NONE' then
        return role
    end
    return select(5, getPlayerSpecInfo())
end

function loadConditions:MatchesRole(loadRoles)
    if not loadRoles or #loadRoles == 0 then
        return true
    end
    local label = ROLE_LABELS[self:GetPlayerRole()]
    return label and tContains(loadRoles, label)
end

function loadConditions:MatchesStatic(load)
    local playerName = UnitName('player')
    local onlyLoad = self:ParseCSVList(load.onlyLoadOnPlayer)
    if #onlyLoad > 0 and not tContains(onlyLoad, playerName) then
        return false
    end

    local dontLoad = self:ParseCSVList(load.dontLoadOnPlayer)
    if #dontLoad > 0 and tContains(dontLoad, playerName) then
        return false
    end

    if not self:MatchesClass(load.loadClasses) then
        return false
    end
    if not self:MatchesSpec(load.loadSpecs) then
        return false
    end
    if not self:MatchesInstance(load.loadInstances) then
        return false
    end
    if not self:MatchesRole(load.loadRoles) then
        return false
    end

    return true
end

function loadConditions:HasEncounterList(load)
    return load and load.loadEncounters and #load.loadEncounters > 0
end

function loadConditions:ShouldIncludeGroup(load)
    if not load or not load.hasLoadConditions then
        return true
    end
    if self:HasEncounterList(load) then
        return false
    end
    return self:MatchesStatic(load)
end

function loadConditions:ShouldIncludeEncounterGroup(load, encounterID)
    if not load or not load.hasLoadConditions or not encounterID then
        return false
    end
    if not self:HasEncounterList(load) or not tContains(load.loadEncounters, encounterID) then
        return false
    end
    if not self:MatchesStatic(load) then
        return false
    end
    return self:MatchesCombat(load)
end

function loadConditions:DisplayHasEncounterGroups(display, encounterID)
    if not display or not display.groups or not encounterID then
        return false
    end
    for _, groupID in ipairs(display.groupOrder or {}) do
        local group = display.groups[groupID]
        if group and group.conditions and group.conditions.enable
            and self:ShouldIncludeEncounterGroup(group.load, encounterID) then
            return true
        end
    end
    return false
end

function loadConditions:GetActiveEncounter()
    return self.activeEncounterID
end

function loadConditions:MatchesCombat(load)
    if not load or not load.hasLoadConditions then
        return true
    end
    if load.loadInCombat and not UnitAffectingCombat('player') then
        return false
    end
    if load.loadOutOfCombat and UnitAffectingCombat('player') then
        return false
    end
    return true
end

function loadConditions:ShouldLoad(load)
    return self:ShouldIncludeGroup(load) and self:MatchesCombat(load)
end

function loadConditions:ApplyCombatState()
    local containerModule = EXUI:GetModule('aura-displays-container')
    if containerModule.ApplyCombatState then
        containerModule:ApplyCombatState()
    end
    local ufApply = EXUI:GetModule('uf-auras-apply')
    if ufApply.ApplyCombatState then
        ufApply:ApplyCombatState()
    end
    local npApply = EXUI:GetModule('np-auras-apply')
    if npApply.ApplyCombatState then
        npApply:ApplyCombatState()
    end
end

function loadConditions:RefreshStatic()
    if InCombatLockdown() then
        self.pendingStaticRefresh = true
        return
    end
    if self.staticRefreshQueued then
        return
    end
    self.staticRefreshQueued = true
    C_Timer.After(0, function()
        self.staticRefreshQueued = false
        if InCombatLockdown() then
            self.pendingStaticRefresh = true
            return
        end
        local auraDisplays = EXUI:GetModule('aura-displays')
        if auraDisplays.RefreshAll then
            auraDisplays:RefreshAll()
        end
        local ufAuras = EXUI:GetModule('uf-auras')
        if ufAuras.RefreshAll then
            ufAuras:RefreshAll()
        end
        local npAuras = EXUI:GetModule('np-auras')
        if npAuras.RefreshAll then
            npAuras:RefreshAll()
        end
    end)
end

local ENCOUNTER_APPLIERS = {
    'aura-displays-container',
    'uf-auras-apply',
    'np-auras-apply',
}

function loadConditions:ForEachEncounterApplier(method, ...)
    for _, name in ipairs(ENCOUNTER_APPLIERS) do
        local module = EXUI:GetModule(name)
        if module and module[method] then
            module[method](module, ...)
        end
    end
end

function loadConditions:OnEncounterStart(encounterID)
    encounterID = tonumber(encounterID)
    if not encounterID then
        return
    end
    self.activeEncounterID = encounterID
    self.pendingEncounterRelease = nil
    self:ForEachEncounterApplier('OnEncounterStart', encounterID)
end

function loadConditions:OnEncounterEnd(encounterID, success)
    local killed = success == 1 or success == true
    encounterID = tonumber(encounterID)
    if not killed then
        if self.activeEncounterID == encounterID then
            self.activeEncounterID = nil
        end
        self:ForEachEncounterApplier('HideKeptEncounterContainers')
        return
    end
    if self.activeEncounterID == encounterID then
        self.activeEncounterID = nil
    end
    self.pendingEncounterRelease = true
    if not InCombatLockdown() then
        self:ForEachEncounterApplier('ReleaseAllEncounterContainers')
        self.pendingEncounterRelease = nil
        return
    end
end

function loadConditions:OnZoneChanged()
    self.activeEncounterID = nil
    self.pendingEncounterRelease = true
    if InCombatLockdown() then
        self:ForEachEncounterApplier('DisableAllEncounterContainers')
        return
    end
    self:ForEachEncounterApplier('ReleaseAllEncounterContainers')
    self.pendingEncounterRelease = nil
end

function loadConditions:ReleasePendingEncounterContainers()
    if InCombatLockdown() then
        return
    end
    if self.pendingEncounterRelease then
        self:ForEachEncounterApplier('ReleaseAllEncounterContainers')
        self.pendingEncounterRelease = nil
        return
    end
    self:ForEachEncounterApplier('ReleaseStaleEncounterContainers')
end

function loadConditions:Init()
    if self.eventFrame then
        return
    end
    self.eventFrame = CreateFrame('Frame')
    self.eventFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
    self.eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
    self.eventFrame:RegisterEvent('ENCOUNTER_START')
    self.eventFrame:RegisterEvent('ENCOUNTER_END')
    for _, event in ipairs(STATIC_REFRESH_EVENTS) do
        self.eventFrame:RegisterEvent(event)
    end
    self.eventFrame:SetScript('OnEvent', function(_, event, ...)
        if event == 'ENCOUNTER_START' then
            loadConditions:OnEncounterStart(...)
            return
        end
        if event == 'ENCOUNTER_END' then
            local encounterID, _, _, _, success = ...
            loadConditions:OnEncounterEnd(encounterID, success)
            return
        end
        if event == 'PLAYER_REGEN_DISABLED' or event == 'PLAYER_REGEN_ENABLED' then
            loadConditions:ApplyCombatState()
            if event == 'PLAYER_REGEN_ENABLED' then
                loadConditions:ReleasePendingEncounterContainers()
                if loadConditions.pendingStaticRefresh then
                    loadConditions.pendingStaticRefresh = nil
                    loadConditions:RefreshStatic()
                end
            end
            return
        end
        if event == 'PLAYER_ENTERING_WORLD' or event == 'ZONE_CHANGED_NEW_AREA' then
            loadConditions:OnZoneChanged()
        end
        loadConditions:RefreshStatic()
    end)
end
