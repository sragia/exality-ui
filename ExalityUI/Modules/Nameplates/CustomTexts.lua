---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUINameplatesCustomTexts
local customTexts = EXUI:GetModule('np-custom-texts')

local DEFAULTS = {
    enable = true,
    font = 'DMSans',
    fontSize = 12,
    fontFlag = 'OUTLINE',
    fontColor = { r = 1, g = 1, b = 1, a = 1 },
    anchorPoint = 'CENTER',
    tag = '[name]',
    relativeAnchorPoint = 'CENTER',
    XOffset = 0,
    YOffset = 0,
    maxWidth = 100,
}

customTexts.Create = function(self)
    local id = EXUI.utils.generateRandomString(10)
    local db = npCore:GetValue('customTexts') or {}
    db[id] = EXUI.utils.deepCloneTable(DEFAULTS)
    npCore:SetValue('customTexts', db)
    return id
end

customTexts.Delete = function(self, id)
    local db = npCore:GetValue('customTexts')
    if not db then return end
    db[id] = nil
    npCore:SetValue('customTexts', db)
end

customTexts.GetValue = function(self, id, key)
    local db = npCore:GetValue('customTexts')
    if not db or not db[id] then return end
    return db[id][key]
end

customTexts.UpdateValue = function(self, id, key, value)
    local db = npCore:GetValue('customTexts')
    if not db or not db[id] then return end
    db[id][key] = value
    npCore:SetValue('customTexts', db)
end

customTexts.List = function(self)
    return npCore:GetValue('customTexts') or {}
end

customTexts.Get = function(self, id)
    local db = npCore:GetValue('customTexts')
    if not db then return end
    return db[id]
end
