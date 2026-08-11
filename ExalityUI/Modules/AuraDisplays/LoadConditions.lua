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
    ['Mythic+'] = 'scenario',
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
    if instanceType == 'scenario' and C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
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
        local mapped = INSTANCE_MAP[instance]
        if mapped == current then
            return true
        end
        if instance == 'Mythic+' and current == 'mythicplus' then
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

function loadConditions:MatchesSpec(loadSpecs)
    if not loadSpecs or #loadSpecs == 0 then
        return true
    end
    local specIndex = GetSpecialization()
    if not specIndex then
        return false
    end
    local _, specName = GetSpecializationInfo(specIndex)
    return specName and tContains(loadSpecs, specName)
end

function loadConditions:MatchesRole(loadRoles)
    if not loadRoles or #loadRoles == 0 then
        return true
    end
    local role = UnitGroupRolesAssigned('player')
    if role == 'NONE' then
        return false
    end
    local roleMap = { TANK = 'Tank', HEALER = 'Healer', DAMAGER = 'DPS' }
    return tContains(loadRoles, roleMap[role])
end

function loadConditions:ShouldLoad(load)
    if not load or not load.hasLoadConditions then
        return true
    end

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

    if load.loadInCombat and not UnitAffectingCombat('player') then
        return false
    end
    if load.loadOutOfCombat and UnitAffectingCombat('player') then
        return false
    end

    return true
end
