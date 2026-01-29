---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local UFCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesCustomTexts
local customTexts = EXUI:GetModule('uf-custom-texts')

local DEFAULTS = {
    ['enable'] = true,
    ['font'] = 'DMSans',
    ['fontSize'] = 12,
    ['fontFlag'] = 'OUTLINE',
    ['fontColor'] = { r = 1, g = 1, b = 1, a = 1 },
    ['anchorPoint'] = 'CENTER',
    ['tag'] = '[name]',
    ['relativeAnchorPoint'] = 'CENTER',
    ['XOffset'] = 0,
    ['YOffset'] = 0,
    ['maxWidth'] = 100,
    ['frameStrata'] = 'LOW',
    ['frameLevel'] = 1,
}

customTexts.Create = function(self, unit)
    local id = EXUI.utils.generateRandomString(10)
    local db = UFCore:GetValueForUnit(unit, 'customTexts') or {}
    db[id] = EXUI.utils.deepCloneTable(DEFAULTS)
    UFCore:UpdateValueForUnit(unit, 'customTexts', db)

    return id
end

customTexts.Delete = function(self, unit, id)
    local db = UFCore:GetValueForUnit(unit, 'customTexts')
    if (not db) then return end
    db[id] = nil
    UFCore:UpdateValueForUnit(unit, 'customTexts', db)
end

customTexts.GetValue = function(self, unit, id, key)
    local db = UFCore:GetValueForUnit(unit, 'customTexts')
    if (not db) then return end
    return db[id][key]
end

customTexts.UpdateValue = function(self, unit, id, key, value)
    local db = UFCore:GetValueForUnit(unit, 'customTexts')
    if (not db) then return end
    db[id][key] = value
    UFCore:UpdateValueForUnit(unit, 'customTexts', db)
end

customTexts.List = function(self, unit)
    return UFCore:GetValueForUnit(unit, 'customTexts') or {}
end

customTexts.Get = function(self, unit, id)
    local db = UFCore:GetValueForUnit(unit, 'customTexts')
    if (not db) then return end
    return db[id]
end
