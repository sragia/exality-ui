---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsGlobalOptions
local globalOptions = EXUI:GetModule('action-bars-global-options')

---@class EXUIActionBarsBarOptions
local barOptions = EXUI:GetModule('action-bars-bar-options')

---@class EXUIActionBarsMicroMenuOptions
local microMenuOptions = EXUI:GetModule('action-bars-micro-menu-options')

microMenuOptions.GetOptions = function(self, mod, section)
    local db = mod.Data:GetDB()
    section = section or 'menu'

    if section == 'menu' then
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

    if section == 'bags' then
        return {
            { type = 'title', label = 'Bag Bar', width = 100 },
            {
                type = 'toggle',
                label = 'Show Bags',
                name = 'bags_enable',
                width = 100,
                currentValue = function() return db.bags.enable end,
                onChange = function(v) db.bags.enable = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
            },
            {
                type = 'dropdown',
                label = 'Bag Visibility',
                name = 'bags_visibility',
                width = 50,
                getOptions = function() return globalOptions:GetVisibilityOptions() end,
                currentValue = function() return db.bags.visibility end,
                onChange = function(v) db.bags.visibility = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
            },
            {
                type = 'range',
                label = 'Bag Scale',
                name = 'bags_scale',
                width = 50,
                min = 0.5,
                max = 2,
                step = 0.05,
                currentValue = function() return db.bags.scale end,
                onChange = function(v) db.bags.scale = v; mod.Data:SetDB(db); mod:RefreshMicroMenu() end,
            },
        }
    end

    return {}
end
