---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0', true)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIActionBarsGlobalOptions
local globalOptions = EXUI:GetModule('action-bars-global-options')

local cachedFontOptions

local VISIBILITY = {
    always = 'Always',
    hover = 'On Hover',
    hidden = 'Hidden',
}

local ORIENTATION = {
    horizontal = 'Horizontal',
    vertical = 'Vertical',
}

local GLOW_TYPES = {
    libbuttonglow = 'LibButtonGlow (Default)',
    button = 'LibCustomGlow: Action Button Glow',
    pixel = 'LibCustomGlow: Pixel Glow',
    autocast = 'LibCustomGlow: Autocast Shine',
    proc = 'LibCustomGlow: Proc Glow',
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

globalOptions.GetGlowTypeOptions = function()
    return GLOW_TYPES
end

globalOptions.GetFontOptions = function()
    if cachedFontOptions then
        return cachedFontOptions
    end
    local fonts = {}
    if LSM then
        for _, font in ipairs(LSM:List('font')) do
            fonts[font] = font
        end
    end
    cachedFontOptions = fonts
    return cachedFontOptions
end

if LSM then
    LSM.RegisterCallback(globalOptions, 'LibSharedMedia_Registered', function(_, mediaType)
        if mediaType == 'font' then
            cachedFontOptions = nil
        end
    end)
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
        onChange = function(v)
            setText('enabled', v); mod:RefreshBars()
        end,
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
        onChange = function(v)
            setText('font', v); mod:RefreshBars()
        end,
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
        onChange = function(v)
            setText('fontSize', v); mod:RefreshBars()
        end,
    })
    table.insert(fields, {
        type = 'dropdown',
        label = 'Font Flag',
        name = textKey .. '_fontFlag',
        width = 50,
        depends = depends,
        getOptions = function() return EXUI.const.fontFlags end,
        currentValue = function() return getText().fontFlag end,
        onChange = function(v)
            setText('fontFlag', v); mod:RefreshBars()
        end,
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
        onChange = function(v)
            setText('anchorPoint', v); mod:RefreshBars()
        end,
    })
    table.insert(fields, {
        type = 'anchor-point',
        label = 'Relative Anchor Point',
        name = textKey .. '_relativePoint',
        width = 23,
        depends = depends,
        currentValue = function() return getText().relativePoint end,
        onChange = function(v)
            setText('relativePoint', v); mod:RefreshBars()
        end,
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
        onChange = function(v)
            setText('xOffset', v); mod:RefreshBars()
        end,
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
        onChange = function(v)
            setText('yOffset', v); mod:RefreshBars()
        end,
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
            { type = 'title',  label = 'Global Button Defaults', width = 100 },
            {
                type = 'range',
                label = 'Width',
                name = 'global_width',
                width = 50,
                min = 16,
                max = 80,
                currentValue = function() return db.global.width end,
                onChange = function(v)
                    db.global.width = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'range',
                label = 'Height',
                name = 'global_height',
                width = 50,
                min = 16,
                max = 80,
                currentValue = function() return db.global.height end,
                onChange = function(v)
                    db.global.height = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'range',
                label = 'Icon Zoom',
                name = 'global_zoom',
                width = 50,
                min = 0,
                max = 30,
                currentValue = function() return db.global.zoom end,
                onChange = function(v)
                    db.global.zoom = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'toggle',
                label = 'Show Border',
                name = 'global_showBorder',
                width = 100,
                currentValue = function() return db.global.showBorder end,
                onChange = function(v)
                    db.global.showBorder = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'toggle',
                label = 'Button Background',
                name = 'global_showBackdrop',
                width = 100,
                currentValue = function() return db.global.showBackdrop ~= false end,
                onChange = function(v)
                    db.global.showBackdrop = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'color-picker',
                label = 'Background Color',
                name = 'global_backdropColor',
                width = 50,
                depends = function() return db.global.showBackdrop ~= false and db.global.showBorder end,
                currentValue = function() return db.global.backdropColor end,
                onChange = function(v)
                    db.global.backdropColor = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'toggle',
                label = 'Use Masque',
                name = 'global_useMasque',
                width = 100,
                depends = function() return self:IsMasqueAvailable() end,
                currentValue = function() return db.global.useMasque end,
                onChange = function(v)
                    db.global.useMasque = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'dropdown',
                label = 'Masque Skin',
                name = 'global_masqueSkin',
                width = 50,
                depends = function() return self:IsMasqueAvailable() end,
                getOptions = function() return self:GetMasqueSkins() end,
                currentValue = function() return db.global.masqueSkin end,
                onChange = function(v)
                    db.global.masqueSkin = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'toggle',
                label = 'Cooldown Swipe',
                name = 'global_showCooldownSwipe',
                width = 100,
                currentValue = function() return db.global.showCooldownSwipe end,
                onChange = function(v)
                    db.global.showCooldownSwipe = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'toggle',
                label = 'Cooldown Text',
                name = 'global_showCooldownText',
                width = 100,
                currentValue = function() return db.global.showCooldownText end,
                onChange = function(v)
                    db.global.showCooldownText = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'toggle',
                label = 'Hide Cooldown Charge',
                name = 'global_hideCooldownCharge',
                width = 100,
                currentValue = function() return db.global.hideCooldownCharge == true end,
                onChange = function(v)
                    db.global.hideCooldownCharge = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            {
                type = 'dropdown',
                label = 'Default Visibility',
                name = 'global_visibility',
                width = 50,
                getOptions = function() return VISIBILITY end,
                currentValue = function() return db.global.visibility end,
                onChange = function(v)
                    db.global.visibility = v; mod.Data:SetDB(db); mod:RefreshBars()
                end,
            },
            { type = 'spacer', width = 100 },
            { type = 'title',  label = 'Glow',                   width = 100 },
            {
                type = 'dropdown',
                label = 'Action Proc Glow',
                name = 'global_glowType',
                width = 50,
                getOptions = function() return self:GetGlowTypeOptions() end,
                currentValue = function() return db.global.glowType or 'libbuttonglow' end,
                onChange = function(v)
                    db.global.glowType = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                    mod:RefreshBars()
                    EXUI:GetModule('options-fields'):RefreshOptions()
                end,
            },
            {
                type = 'color-picker',
                label = 'Glow Color',
                name = 'global_glowColor',
                width = 50,
                depends = function() return (db.global.glowType or 'libbuttonglow') ~= 'libbuttonglow' end,
                currentValue = function()
                    return db.global.glowColor or { r = 0.95, g = 0.95, b = 0.32, a = 1 }
                end,
                onChange = function(v)
                    db.global.glowColor = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
            },
            {
                type = 'range',
                label = 'Glow Frequency',
                name = 'global_glowFrequency',
                width = 50,
                min = 0.05,
                max = 3,
                step = 0.01,
                depends = function() return (db.global.glowType or 'libbuttonglow') ~= 'proc' end,
                currentValue = function() return db.global.glowFrequency or 0.25 end,
                onChange = function(v)
                    db.global.glowFrequency = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
            },
            {
                type = 'range',
                label = 'Glow Frame Level',
                name = 'global_glowFrameLevel',
                width = 50,
                min = 1,
                max = 20,
                step = 1,
                depends = function() return (db.global.glowType or 'libbuttonglow') ~= 'libbuttonglow' end,
                currentValue = function() return db.global.glowFrameLevel or 8 end,
                onChange = function(v)
                    db.global.glowFrameLevel = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
            },
            {
                type = 'range',
                label = 'Pixel Lines',
                name = 'global_glowPixelLines',
                width = 50,
                min = 1,
                max = 20,
                step = 1,
                depends = function() return (db.global.glowType or 'libbuttonglow') == 'pixel' end,
                currentValue = function() return db.global.glowPixelLines or 8 end,
                onChange = function(v)
                    db.global.glowPixelLines = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
            },
            {
                type = 'range',
                label = 'Pixel Length',
                name = 'global_glowPixelLength',
                width = 50,
                min = 1,
                max = 24,
                step = 1,
                depends = function() return (db.global.glowType or 'libbuttonglow') == 'pixel' end,
                currentValue = function() return db.global.glowPixelLength or 8 end,
                onChange = function(v)
                    db.global.glowPixelLength = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
            },
            {
                type = 'range',
                label = 'Pixel Thickness',
                name = 'global_glowPixelThickness',
                width = 50,
                min = 1,
                max = 5,
                step = 1,
                depends = function() return (db.global.glowType or 'libbuttonglow') == 'pixel' end,
                currentValue = function() return db.global.glowPixelThickness or 1 end,
                onChange = function(v)
                    db.global.glowPixelThickness = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
            },
            {
                type = 'toggle',
                label = 'Pixel Border',
                name = 'global_glowPixelBorder',
                width = 100,
                depends = function() return (db.global.glowType or 'libbuttonglow') == 'pixel' end,
                currentValue = function() return db.global.glowPixelBorder ~= false end,
                onChange = function(v)
                    db.global.glowPixelBorder = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
            },
            {
                type = 'range',
                label = 'Autocast Particles',
                name = 'global_glowAutoCastParticles',
                width = 50,
                min = 1,
                max = 12,
                step = 1,
                depends = function() return (db.global.glowType or 'libbuttonglow') == 'autocast' end,
                currentValue = function() return db.global.glowAutoCastParticles or 4 end,
                onChange = function(v)
                    db.global.glowAutoCastParticles = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
            },
            {
                type = 'range',
                label = 'Autocast Scale',
                name = 'global_glowAutoCastScale',
                width = 50,
                min = 0.5,
                max = 2,
                step = 0.05,
                depends = function() return (db.global.glowType or 'libbuttonglow') == 'autocast' end,
                currentValue = function() return db.global.glowAutoCastScale or 1 end,
                onChange = function(v)
                    db.global.glowAutoCastScale = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
            },
            {
                type = 'range',
                label = 'Proc Duration',
                name = 'global_glowProcDuration',
                width = 50,
                min = 0.2,
                max = 3,
                step = 0.05,
                depends = function() return (db.global.glowType or 'libbuttonglow') == 'proc' end,
                currentValue = function() return db.global.glowProcDuration or 1 end,
                onChange = function(v)
                    db.global.glowProcDuration = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
            },
            {
                type = 'toggle',
                label = 'Proc Start Animation',
                name = 'global_glowProcStartAnim',
                width = 100,
                depends = function() return (db.global.glowType or 'libbuttonglow') == 'proc' end,
                currentValue = function() return db.global.glowProcStartAnim ~= false end,
                onChange = function(v)
                    db.global.glowProcStartAnim = v
                    mod.Data:SetDB(db)
                    EXUI:GetModule('action-bars-glow'):ApplySettings()
                end,
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
