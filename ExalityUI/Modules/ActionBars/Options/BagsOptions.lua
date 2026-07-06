---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsGlobalOptions
local globalOptions = EXUI:GetModule('action-bars-global-options')

---@class EXUIActionBarsBarOptions
local barOptions = EXUI:GetModule('action-bars-bar-options')

---@class EXUIActionBarsBagsOptions
local bagsOptions = EXUI:GetModule('action-bars-bags-options')

bagsOptions.GetOptions = function(self, mod)
    local db = mod.Data:GetDB()

    local fields = {
        { type = 'title', label = 'Bag Bar', width = 100 },
        {
            type = 'toggle',
            label = 'Show Bags',
            name = 'bags_enable',
            width = 100,
            currentValue = function() return db.bags.enable end,
            onChange = function(v) db.bags.enable = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
        },
    }

    for _, field in ipairs(barOptions:GetPositionFields(mod, db, db.bags, function()
        mod:RefreshMicroMenu()
    end)) do
        table.insert(fields, field)
    end

    table.insert(fields, {
        type = 'dropdown',
        label = 'Visibility',
        name = 'bags_visibility',
        width = 50,
        getOptions = function() return globalOptions:GetVisibilityOptions() end,
        currentValue = function() return db.bags.visibility end,
        onChange = function(v) db.bags.visibility = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
    })
    table.insert(fields, {
        type = 'range',
        label = 'Scale',
        name = 'bags_scale',
        width = 50,
        min = 0.5,
        max = 2,
        step = 0.05,
        currentValue = function() return db.bags.scale end,
        onChange = function(v) db.bags.scale = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
    })

    return fields
end
