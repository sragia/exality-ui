---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local CoreData = EXUI:GetModule('data')

---@class EXUIActionBarsData
local data = EXUI:GetModule('ab-data')

data.Controls = CoreData:GetControlsForKey('action-bars')

data.Init = function(self)
    data.Controls:UpdateDefaults({
        enabled = false,
        bar1 = {
            enabled = true,
        },
        bar2 = {
            enabled = true,
        },
        bar3 = {
            enabled = true,
        },
        bar4 = {
            enabled = true,
        },
        bar5 = {
            enabled = false,
        },
        bar6 = {
            enabled = false,
        },
        bar7 = {
            enabled = false,
        },
        bar8 = {
            enabled = false,
        },
    })
end

data.GetValueByKey = function(self, key)
    return data.Controls:GetValue(key)
end

data.SetValueByKey = function(self, key, value)
    data.Controls:SetValue(key, value)
end

data.GetValueForBar = function(self, barId, key)
    local bar = self:GetValueByKey('bar' .. barId)
    return bar[key]
end

data.SetValueForBar = function(self, barId, key, value)
    local bar = self:GetValueByKey('bar' .. barId)
    bar[key] = value
    self:SetValueByKey('bar' .. barId, bar)
end
