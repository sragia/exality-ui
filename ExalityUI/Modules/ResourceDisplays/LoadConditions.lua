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

function loadConditions:GetParsedPlayerLists(display)
    local key = (display.onlyLoadOnPlayer or '') .. '\0' .. (display.dontLoadOnPlayer or '')
    if display._loadParseKey ~= key then
        display._loadParseKey = key
        display._onlyLoadList = self:ParseCSVList(display.onlyLoadOnPlayer)
        display._dontLoadList = self:ParseCSVList(display.dontLoadOnPlayer)
    end
    return display._onlyLoadList, display._dontLoadList
end

function loadConditions:ShouldLoad(display)
    if not display or not display.hasLoadConditions then
        return true
    end

    local playerName = UnitName('player')
    local onlyLoad, dontLoad = self:GetParsedPlayerLists(display)
    if #onlyLoad > 0 and not tContains(onlyLoad, playerName) then
        return false
    end

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
