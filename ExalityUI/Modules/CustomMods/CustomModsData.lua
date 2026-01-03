---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUICustomModsData
local customModsData = EXUI:GetModule('custom-mods-data')

customModsData.Controls = data:GetControlsForKey('custom-mods')

customModsData.DEFAULTS = {
    name = 'New Custom Mod',
    enabled = true,
    display = {
        width = 64,
        height = 64,
        anchorPoint = 'CENTER',
        relativeAnchorPoint = 'CENTER',
        XOff = 0,
        YOff = 0,
        backdrop = {
            borderColor = { r = 0, g = 0, b = 0, a = 1 },
            borderSize = 1,
            bgColor = { r = 0, g = 0, b = 0, a = 0.8 },
        },
        text = {
            font = 'DMSans',
            fontSize = 12,
            fontFlag = 'OUTLINE',
            fontAnchorPoint = 'CENTER',
            fontRelativePoint = 'CENTER',
            fontXOff = 0,
            fontYOff = 0,
        }
    },
    logic = {
        events = {},
        func = ''
    }
}

customModsData.Init = function(self)

end

customModsData.Create = function(self)
    local id = EXUI.utils.generateRandomString(10)
    customModsData.Data:UpdateDefaultsForId(id)
    return id
end

customModsData.GetItems = function(self)
    local items = {}
    local db = customModsData.Controls:GetDB()
    for id, db in pairs(db) do
        table.insert(items, {
            label = db.name,
            ID = id
        })
    end
    return items
end

customModsData.Data = {
    UpdateDefaultsForId = function(self, id)
        local db = customModsData.Controls:GetValue(id) or {}
        db.createdAt = time()
        for key, value in pairs(customModsData.DEFAULTS) do
            if (db[key] == nil) then
                db[key] = value
            end
        end
        customModsData.Controls:SetValue(id, db)
    end,
    GetById = function(self, id)
        return customModsData.Controls:GetValue(id)
    end,
    SetValueForId = function(self, id, key, value)
        local db = customModsData.Controls:GetValue(id)
        db[key] = value
        customModsData.Controls:SetValue(id, db)
    end,
    GetValueForId = function(self, id, key)
        local db = customModsData.Controls:GetValue(id)
        return db[key]
    end
}
