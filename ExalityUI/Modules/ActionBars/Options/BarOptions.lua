---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsGlobalOptions
local globalOptions = EXUI:GetModule('action-bars-global-options')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIActionBarsBarOptions
local barOptions = EXUI:GetModule('action-bars-bar-options')

local function appendFields(target, source)
    for _, field in ipairs(source) do
        table.insert(target, field)
    end
    return target
end

barOptions.GetPositionFields = function(self, mod, db, scope, onRefresh)
    local function save(refresh)
        mod.Data:SetDB(db)
        if refresh and onRefresh then
            onRefresh()
        end
    end

    return {
        { type = 'title', label = 'Position', width = 100 },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'anchorPoint',
            width = 23,
            currentValue = function() return scope.anchorPoint end,
            onChange = function(v)
                scope.anchorPoint = v
                save(true)
            end,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'relativeAnchor',
            width = 23,
            currentValue = function() return scope.relativeAnchor end,
            onChange = function(v)
                scope.relativeAnchor = v
                save(true)
            end,
        },
        { type = 'spacer', width = 54 },
        {
            type = 'range',
            label = 'X Offset',
            name = 'xOffset',
            width = 23,
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function() return scope.xOffset or 0 end,
            onChange = function(v)
                scope.xOffset = v
                save(true)
            end,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'yOffset',
            width = 23,
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function() return scope.yOffset or 0 end,
            onChange = function(v)
                scope.yOffset = v
                save(true)
            end,
        },
    }
end

barOptions.GetPageOptions = function()
    local options = {}
    for i = 0, 18 do
        options[i] = {
            label = i == 0 and 'Main Bar' or ('Page ' .. i),
            order = i,
        }
    end
    return options
end

barOptions.GetSectionTabs = function(barId)
    if barId == 'extra' then
        return {
            { ID = 'layout', label = 'Layout' },
            { ID = 'appearance', label = 'Appearance' },
            { ID = 'text', label = 'Text' },
            { ID = 'visibility', label = 'Visibility' },
        }
    end
    return {
        { ID = 'layout', label = 'Layout' },
        { ID = 'appearance', label = 'Appearance' },
        { ID = 'text', label = 'Text' },
        { ID = 'visibility', label = 'Visibility' },
    }
end

barOptions.GetBarOptions = function(self, mod, barId, section)
    local db = mod.Data:GetDB()
    local bar = db.bars[barId]
    if not bar then return {} end

    section = section or 'layout'
    local fields = {}

    if section == 'layout' then
        appendFields(fields, {
            {
                type = 'toggle',
                label = 'Enabled',
                name = 'enable',
                width = 100,
                currentValue = function() return bar.enable end,
                onChange = function(v) bar.enable = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
        })
        if barId == 'bar1' then
            if not bar.states then
                bar.states = EXUI.utils.deepCloneTable(EXUI:GetModule('action-bars-defaults').BAR1_STATES)
            end
            appendFields(fields, {
                { type = 'title', label = 'Paging', width = 100 },
                {
                    type = 'toggle',
                    label = 'Enable State Paging',
                    name = 'statesEnabled',
                    width = 100,
                    currentValue = function() return bar.states.enabled ~= false end,
                    onChange = function(v)
                        bar.states.enabled = v
                        mod.Data:SetDB(db)
                        mod:RefreshBar(barId)
                    end,
                },
                {
                    type = 'toggle',
                    label = 'Possess / Vehicle Pages',
                    name = 'statesPossess',
                    width = 100,
                    currentValue = function() return bar.states.possess ~= false end,
                    onChange = function(v)
                        bar.states.possess = v
                        mod.Data:SetDB(db)
                        mod:RefreshBar(barId)
                    end,
                },
                {
                    type = 'toggle',
                    label = 'Blizzard Bar Paging',
                    name = 'statesActionbar',
                    width = 100,
                    currentValue = function() return bar.states.actionbar == true end,
                    onChange = function(v)
                        bar.states.actionbar = v
                        mod.Data:SetDB(db)
                        mod:RefreshBar(barId)
                    end,
                },
                {
                    type = 'dropdown',
                    label = 'Default Page',
                    name = 'statesDefault',
                    width = 100,
                    getOptions = function() return barOptions:GetPageOptions() end,
                    currentValue = function() return bar.states.default or 0 end,
                    onChange = function(v)
                        bar.states.default = v
                        mod.Data:SetDB(db)
                        mod:RefreshBar(barId)
                    end,
                },
            })
            local playerClass = select(2, UnitClass('player'))
            local classStances = bar.states.stance and bar.states.stance[playerClass]
            if classStances then
                appendFields(fields, { { type = 'title', label = 'Stance Pages (' .. playerClass .. ')', width = 100 } })
                for stanceId in pairs(classStances) do
                    local capturedStanceId = stanceId
                    appendFields(fields, {
                        {
                            type = 'range',
                            label = capturedStanceId,
                            name = 'stance_' .. capturedStanceId,
                            width = 50,
                            min = 0,
                            max = 18,
                            step = 1,
                            currentValue = function()
                                return classStances[capturedStanceId] or 0
                            end,
                            onChange = function(v)
                                classStances[capturedStanceId] = v
                                mod.Data:SetDB(db)
                                mod:RefreshBar(barId)
                            end,
                        },
                    })
                end
            end
        end
        appendFields(fields, self:GetPositionFields(mod, db, bar, function()
            mod:RefreshBar(barId)
        end))
        if barId == 'extra' then
            appendFields(fields, {
                {
                    type = 'title',
                    label = 'Encounter extra actions and zone abilities share this anchor.',
                    width = 100,
                    size = 12,
                    color = EXUI.const.theme.textMuted,
                },
            })
            return fields
        end
        appendFields(fields, {
            { type = 'title', label = 'Layout', width = 100 },
            {
                type = 'dropdown',
                label = 'Orientation',
                name = 'orientation',
                width = 50,
                getOptions = function() return globalOptions:GetOrientationOptions() end,
                currentValue = function() return bar.orientation end,
                onChange = function(v) bar.orientation = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'range',
                label = 'Buttons Shown',
                name = 'numButtons',
                width = 50,
                min = 1,
                max = definitions:Get(barId).numButtons or 12,
                depends = function()
                    local def = definitions:Get(barId)
                    if def and def.barType == 'stance' then
                        return false
                    end
                    return (def.numButtons or 12) > 1
                end,
                currentValue = function() return bar.numButtons end,
                onChange = function(v) bar.numButtons = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'range',
                label = 'Buttons Per Row',
                name = 'buttonsPerRow',
                width = 50,
                min = 1,
                max = definitions:Get(barId).numButtons or 12,
                depends = function()
                    local def = definitions:Get(barId)
                    if def and def.barType == 'stance' then
                        return false
                    end
                    return (def.numButtons or 12) > 1
                end,
                currentValue = function() return bar.buttonsPerRow end,
                onChange = function(v) bar.buttonsPerRow = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'range',
                label = 'Horizontal Padding',
                name = 'paddingX',
                width = 50,
                min = -3,
                max = 20,
                currentValue = function() return bar.paddingX end,
                onChange = function(v) bar.paddingX = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'range',
                label = 'Vertical Padding',
                name = 'paddingY',
                width = 50,
                min = -3,
                max = 20,
                currentValue = function() return bar.paddingY end,
                onChange = function(v) bar.paddingY = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'dropdown',
                label = 'Grow Horizontal',
                name = 'growHorizontal',
                width = 50,
                getOptions = function() return { right = 'Right', left = 'Left' } end,
                currentValue = function() return bar.growHorizontal end,
                onChange = function(v) bar.growHorizontal = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'dropdown',
                label = 'Grow Vertical',
                name = 'growVertical',
                width = 50,
                getOptions = function() return { up = 'Up', down = 'Down' } end,
                currentValue = function() return bar.growVertical end,
                onChange = function(v) bar.growVertical = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
        })
    elseif section == 'appearance' then
        appendFields(fields, {
            { type = 'title', label = 'Appearance Overrides', width = 100 },
        })
        if barId == 'extra' then
            appendFields(fields, {
                {
                    type = 'toggle',
                    label = 'Show Blizzard Artwork',
                    name = 'showBlizzardArtwork',
                    width = 100,
                    currentValue = function() return bar.showBlizzardArtwork == true end,
                    onChange = function(v)
                        bar.showBlizzardArtwork = v
                        mod.Data:SetDB(db)
                        mod:RefreshBar(barId)
                    end,
                },
            })
        end
        appendFields(fields, {
            {
                type = 'toggle',
                label = 'Use Global Size',
                name = 'useGlobalSize',
                width = 100,
                currentValue = function() return bar.useGlobalSize ~= false end,
                onChange = function(v)
                    bar.useGlobalSize = v
                    mod.Data:SetDB(db)
                    mod:RefreshBar(barId)
                    optionsFields:RefreshOptions()
                end,
            },
            {
                type = 'toggle',
                label = 'Use Global Appearance',
                name = 'useGlobalAppearance',
                width = 100,
                currentValue = function() return bar.useGlobalAppearance ~= false end,
                onChange = function(v)
                    bar.useGlobalAppearance = v
                    mod.Data:SetDB(db)
                    mod:RefreshBar(barId)
                    optionsFields:RefreshOptions()
                end,
            },
            {
                type = 'range',
                label = 'Width',
                name = 'width',
                width = 50,
                depends = function() return bar.useGlobalSize == false end,
                currentValue = function() return bar.width end,
                onChange = function(v) bar.width = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
                min = 16,
                max = 80,
            },
            {
                type = 'range',
                label = 'Height',
                name = 'height',
                width = 50,
                depends = function() return bar.useGlobalSize == false end,
                currentValue = function() return bar.height end,
                onChange = function(v) bar.height = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
                min = 16,
                max = 80,
            },
            {
                type = 'range',
                label = 'Icon Zoom',
                name = 'zoom',
                width = 50,
                depends = function() return bar.useGlobalSize == false end,
                currentValue = function() return bar.zoom end,
                onChange = function(v) bar.zoom = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
                min = 0,
                max = 30,
            },
            {
                type = 'toggle',
                label = 'Show Border',
                name = 'showBorder',
                width = 100,
                depends = function() return bar.useGlobalAppearance == false end,
                currentValue = function() return bar.showBorder end,
                onChange = function(v) bar.showBorder = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'toggle',
                label = 'Show Empty Slots',
                name = 'showBackdrop',
                width = 100,
                depends = function() return bar.useGlobalAppearance == false end,
                currentValue = function() return bar.showBackdrop end,
                onChange = function(v) bar.showBackdrop = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'toggle',
                label = 'Use Masque',
                name = 'useMasque',
                width = 100,
                depends = function()
                    return bar.useGlobalAppearance == false and globalOptions:IsMasqueAvailable()
                end,
                currentValue = function() return bar.useMasque end,
                onChange = function(v) bar.useMasque = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'dropdown',
                label = 'Masque Skin',
                name = 'masqueSkin',
                width = 50,
                depends = function()
                    return bar.useGlobalAppearance == false and globalOptions:IsMasqueAvailable()
                end,
                getOptions = function() return globalOptions:GetMasqueSkins() end,
                currentValue = function() return bar.masqueSkin end,
                onChange = function(v) bar.masqueSkin = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'toggle',
                label = 'Cooldown Swipe',
                name = 'showCooldownSwipe',
                width = 100,
                depends = function() return bar.useGlobalAppearance == false end,
                currentValue = function() return bar.showCooldownSwipe end,
                onChange = function(v) bar.showCooldownSwipe = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
            {
                type = 'toggle',
                label = 'Cooldown Text',
                name = 'showCooldownText',
                width = 100,
                depends = function() return bar.useGlobalAppearance == false end,
                currentValue = function() return bar.showCooldownText end,
                onChange = function(v) bar.showCooldownText = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
        })
    elseif section == 'text' then
        appendFields(fields, globalOptions:BuildTextFields(mod, barId, 'hotkey', 'Hotkey Text'))
        appendFields(fields, { { type = 'spacer', width = 100 } })
        appendFields(fields, globalOptions:BuildTextFields(mod, barId, 'count', 'Stack Text'))
        if barId ~= 'extra' then
            appendFields(fields, { { type = 'spacer', width = 100 } })
            appendFields(fields, globalOptions:BuildTextFields(mod, barId, 'macro', 'Macro Text'))
        end
        appendFields(fields, { { type = 'spacer', width = 100 } })
        appendFields(fields, globalOptions:BuildTextFields(mod, barId, 'cooldown', 'Cooldown Text'))
    elseif section == 'visibility' then
        appendFields(fields, {
            {
                type = 'dropdown',
                label = 'Visibility',
                name = 'visibility',
                width = 50,
                getOptions = function() return globalOptions:GetVisibilityOptions() end,
                currentValue = function() return bar.visibility end,
                onChange = function(v) bar.visibility = v; mod.Data:SetDB(db); mod:RefreshBar(barId) end,
            },
        })
    end

    return fields
end
