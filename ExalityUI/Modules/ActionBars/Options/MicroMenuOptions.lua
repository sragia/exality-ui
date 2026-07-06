---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsGlobalOptions
local globalOptions = EXUI:GetModule('action-bars-global-options')

---@class EXUIActionBarsBarOptions
local barOptions = EXUI:GetModule('action-bars-bar-options')

---@class EXUIActionBarsMicroMenuOptions
local microMenuOptions = EXUI:GetModule('action-bars-micro-menu-options')

local ORDER = {
    default = 'Default',
    reverse = 'Reverse',
}

microMenuOptions.GetOrderOptions = function()
    return ORDER
end

microMenuOptions.GetOptions = function(self, mod)
    local db = mod.Data:GetDB()

    local fields = {
        { type = 'title', label = 'Micro Menu', width = 100 },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'micro_enable',
            width = 100,
            currentValue = function() return db.microMenu.enable end,
            onChange = function(v) db.microMenu.enable = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
        },
    }

    for _, field in ipairs(barOptions:GetPositionFields(mod, db, db.microMenu, function()
        mod:RefreshMicroMenu()
    end)) do
        table.insert(fields, field)
    end

    table.insert(fields, {
        type = 'dropdown',
        label = 'Orientation',
        name = 'micro_orientation',
        width = 50,
        getOptions = function() return globalOptions:GetOrientationOptions() end,
        currentValue = function() return db.microMenu.orientation end,
        onChange = function(v) db.microMenu.orientation = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
    })
    table.insert(fields, {
        type = 'dropdown',
        label = 'Button Order',
        name = 'micro_order',
        width = 50,
        getOptions = function() return self:GetOrderOptions() end,
        currentValue = function() return db.microMenu.order end,
        onChange = function(v) db.microMenu.order = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
    })
    table.insert(fields, {
        type = 'dropdown',
        label = 'Visibility',
        name = 'micro_visibility',
        width = 50,
        getOptions = function() return globalOptions:GetVisibilityOptions() end,
        currentValue = function() return db.microMenu.visibility end,
        onChange = function(v) db.microMenu.visibility = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
    })
    table.insert(fields, {
        type = 'range',
        label = 'Scale',
        name = 'micro_scale',
        width = 50,
        min = 0.5,
        max = 2,
        step = 0.05,
        currentValue = function() return db.microMenu.scale end,
        onChange = function(v) db.microMenu.scale = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
    })

    return fields
end
