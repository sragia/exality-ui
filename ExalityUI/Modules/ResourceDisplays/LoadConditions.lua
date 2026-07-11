---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysLoadConditions
local loadConditions = EXUI:GetModule('resource-displays-load-conditions')

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

function loadConditions:ShouldLoad(display)
    if not display or not display.hasLoadConditions then
        return true
    end

    local playerName = UnitName('player')
    local onlyLoad = self:ParseCSVList(display.onlyLoadOnPlayer)
    if #onlyLoad > 0 and not tContains(onlyLoad, playerName) then
        return false
    end

    local dontLoad = self:ParseCSVList(display.dontLoadOnPlayer)
    if #dontLoad > 0 and tContains(dontLoad, playerName) then
        return false
    end

    if not self:MatchesClass(display.loadClasses) then
        return false
    end
    if not self:MatchesSpec(display.loadSpecs) then
        return false
    end

    return true
end
