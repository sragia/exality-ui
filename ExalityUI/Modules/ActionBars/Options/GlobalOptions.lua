---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0', true)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIActionBarsGlobalOptions
local globalOptions = EXUI:GetModule('action-bars-global-options')

local VISIBILITY = {
    always = 'Always',
    hover = 'On Hover',
    hidden = 'Hidden',
}

local ORIENTATION = {
    horizontal = 'Horizontal',
    vertical = 'Vertical',
}

local function appendFields(target, source)
    for _, field in ipairs(source) do
        table.insert(target, field)
    end
    return target
end

globalOptions.GetVisibilityOptions = function()
    return VISIBILITY
end

globalOptions.GetOrientationOptions = function()
    return ORIENTATION
end

globalOptions.GetFontOptions = function()
    local fonts = {}
    if LSM then
        for _, font in ipairs(LSM:List('font')) do
            fonts[font] = font
        end
    end
    return fonts
end

globalOptions.GetMasqueSkins = function()
    return {
        ['ExalityUI Square'] = 'ExalityUI Square',
        ['ExalityUI Square w/ Backdrop'] = 'ExalityUI Square w/ Backdrop',
        ['ExalityUI Rectangle'] = 'ExalityUI Rectangle',
    }
end

globalOptions.IsMasqueAvailable = function()
    if not C_AddOns.DoesAddOnExist('Masque') then
        return false
    end
    return C_AddOns.GetAddOnEnableState('Masque', UnitGUID('player')) > Enum.AddOnEnableState.None
end

globalOptions.BuildTextFields = function(self, mod, scope, textKey, label)
    local isGlobal = scope == 'global'
    local getText = function()
        local db = mod.Data:GetDB()
        if isGlobal then
            return db.global[textKey]
        end
        return db.bars[scope][textKey]
    end
    local setText = function(key, value)
        local db = mod.Data:GetDB()
        local target = isGlobal and db.global[textKey] or db.bars[scope][textKey]
        target[key] = value
        mod.Data:SetDB(db)
    end

    local fields = {
        { type = 'title', label = label, width = 100 },
    }

    local depends = not isGlobal and function()
        return getText().useGlobal == false
    end or nil

    if not isGlobal then
        table.insert(fields, {
            type = 'toggle',
            label = 'Use Global ' .. label,
            name = textKey .. '_useGlobal',
            width = 100,
            currentValue = function()
                return getText().useGlobal ~= false
            end,
            onChange = function(value)
                setText('useGlobal', value)
                mod:RefreshBars()
                optionsFields:RefreshOptions()
            end,
        })
    end

    table.insert(fields, {
        type = 'toggle',
        label = 'Show',
        name = textKey .. '_enabled',
        width = 100,
        depends = depends,
        currentValue = function() return getText().enabled ~= false end,
        onChange = function(v) setText('enabled', v); mod:RefreshBars() end,
    })
    table.insert(fields, {
        type = 'dropdown',
        label = 'Font',
        name = textKey .. '_font',
        width = 50,
        isFontDropdown = true,
        depends = depends,
        getOptions = function() return self:GetFontOptions() end,
        currentValue = function() return getText().font end,
        onChange = function(v) setText('font', v); mod:RefreshBars() end,
    })
    table.insert(fields, {
        type = 'range',
        label = 'Font Size',
        name = textKey .. '_fontSize',
        width = 50,
        min = 6,
        max = 32,
        depends = depends,
        currentValue = function() return getText().fontSize end,
        onChange = function(v) setText('fontSize', v); mod:RefreshBars() end,
    })
    table.insert(fields, {
        type = 'dropdown',
        label = 'Font Flag',
        name = textKey .. '_fontFlag',
        width = 50,
        depends = depends,
        getOptions = function() return EXUI.const.fontFlags end,
        currentValue = function() return getText().fontFlag end,
        onChange = function(v) setText('fontFlag', v); mod:RefreshBars() end,
    })
    table.insert(fields, {
        type = 'title',
        label = 'Position',
        name = textKey .. '_positionTitle',
        width = 100,
        size = 14,
        color = { 0.75, 0.75, 0.75 },
        background = { 0.10, 0.10, 0.10, 1 },
        accent = { 0.40, 0.40, 0.40, 1 },
        depends = depends,
    })
    table.insert(fields, {
        type = 'anchor-point',
        label = 'Anchor Point',
        name = textKey .. '_anchorPoint',
        width = 23,
        depends = depends,
        currentValue = function() return getText().anchorPoint end,
        onChange = function(v) setText('anchorPoint', v); mod:RefreshBars() end,
    })
    table.insert(fields, {
        type = 'anchor-point',
        label = 'Relative Anchor Point',
        name = textKey .. '_relativePoint',
        width = 23,
        depends = depends,
        currentValue = function() return getText().relativePoint end,
        onChange = function(v) setText('relativePoint', v); mod:RefreshBars() end,
    })
    table.insert(fields, { type = 'spacer', width = 54, depends = depends })
    table.insert(fields, {
        type = 'range',
        label = 'X Offset',
        name = textKey .. '_xOffset',
        width = 23,
        min = -100,
        max = 100,
        step = 1,
        depends = depends,
        currentValue = function() return getText().xOffset or 0 end,
        onChange = function(v) setText('xOffset', v); mod:RefreshBars() end,
    })
    table.insert(fields, {
        type = 'range',
        label = 'Y Offset',
        name = textKey .. '_yOffset',
        width = 23,
        min = -100,
        max = 100,
        step = 1,
        depends = depends,
        currentValue = function() return getText().yOffset or 0 end,
        onChange = function(v) setText('yOffset', v); mod:RefreshBars() end,
    })

    return fields
end

globalOptions.GetOptions = function(self, mod, section)
    local db = mod.Data:GetDB()
    section = section or 'module'

    if section == 'module' then
        return {
            {
                type = 'toggle',
                label = 'Enabled',
                name = 'enable',
                width = 100,
                currentValue = function() return mod.Data:GetValue('enable') end,
                onChange = function(v)
                    mod.Data:SetValue('enable', v)
                    mod:OnEnableToggle(v)
                end,
            },
            { type = 'spacer', width = 100 },
            {
                type = 'button',
                label = 'Keybind Mode',
                name = 'keybind_mode',
                width = 100,
                buttonText = 'Enter Keybind Mode',
                onClick = function()
                    EXUI:GetModule('action-bars-keybind'):EnterQuickKeybindMode()
                end,
            },
        }
    end

    if section == 'buttons' then
        return {
            { type = 'title', label = 'Global Button Defaults', width = 100 },
            {
                type = 'range',
                label = 'Width',
                name = 'global_width',
                width = 50,
                min = 16,
                max = 80,
                currentValue = function() return db.global.width end,
                onChange = function(v) db.global.width = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'range',
                label = 'Height',
                name = 'global_height',
                width = 50,
                min = 16,
                max = 80,
                currentValue = function() return db.global.height end,
                onChange = function(v) db.global.height = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'range',
                label = 'Icon Zoom',
                name = 'global_zoom',
                width = 50,
                min = 0,
                max = 30,
                currentValue = function() return db.global.zoom end,
                onChange = function(v) db.global.zoom = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'toggle',
                label = 'Show Border',
                name = 'global_showBorder',
                width = 100,
                currentValue = function() return db.global.showBorder end,
                onChange = function(v) db.global.showBorder = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'toggle',
                label = 'Use Masque',
                name = 'global_useMasque',
                width = 100,
                depends = function() return self:IsMasqueAvailable() end,
                currentValue = function() return db.global.useMasque end,
                onChange = function(v) db.global.useMasque = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'dropdown',
                label = 'Masque Skin',
                name = 'global_masqueSkin',
                width = 50,
                depends = function() return self:IsMasqueAvailable() end,
                getOptions = function() return self:GetMasqueSkins() end,
                currentValue = function() return db.global.masqueSkin end,
                onChange = function(v) db.global.masqueSkin = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'toggle',
                label = 'Show Hotkey',
                name = 'global_showHotkey',
                width = 100,
                currentValue = function() return db.global.showHotkey end,
                onChange = function(v) db.global.showHotkey = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'toggle',
                label = 'Show Macro Text',
                name = 'global_showMacro',
                width = 100,
                currentValue = function() return db.global.showMacro end,
                onChange = function(v) db.global.showMacro = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'toggle',
                label = 'Show Stacks',
                name = 'global_showStacks',
                width = 100,
                currentValue = function() return db.global.showStacks end,
                onChange = function(v) db.global.showStacks = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'toggle',
                label = 'Cooldown Swipe',
                name = 'global_showCooldownSwipe',
                width = 100,
                currentValue = function() return db.global.showCooldownSwipe end,
                onChange = function(v) db.global.showCooldownSwipe = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'toggle',
                label = 'Cooldown Text',
                name = 'global_showCooldownText',
                width = 100,
                currentValue = function() return db.global.showCooldownText end,
                onChange = function(v) db.global.showCooldownText = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
            {
                type = 'dropdown',
                label = 'Default Visibility',
                name = 'global_visibility',
                width = 50,
                getOptions = function() return VISIBILITY end,
                currentValue = function() return db.global.visibility end,
                onChange = function(v) db.global.visibility = v; mod.Data:SetDB(db); mod:RefreshBars() end,
            },
        }
    end

    if section == 'text' then
        local fields = {}
        appendFields(fields, self:BuildTextFields(mod, 'global', 'hotkey', 'Hotkey Text'))
        table.insert(fields, { type = 'spacer', width = 100 })
        appendFields(fields, self:BuildTextFields(mod, 'global', 'count', 'Stack Text'))
        table.insert(fields, { type = 'spacer', width = 100 })
        appendFields(fields, self:BuildTextFields(mod, 'global', 'macro', 'Macro Text'))
        table.insert(fields, { type = 'spacer', width = 100 })
        appendFields(fields, self:BuildTextFields(mod, 'global', 'cooldown', 'Cooldown Text'))
        return fields
    end

    return {}
end
