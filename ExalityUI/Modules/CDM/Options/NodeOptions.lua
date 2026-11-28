---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIStyles
local styles = EXUI:GetModule('styles')

---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

---@class EXUICDMData
local data = EXUI:GetModule('cdm-data')

---@class EXUICDMDefaults
local defaults = EXUI:GetModule('cdm-defaults')

---@class EXUICDMSources
local sources = EXUI:GetModule('cdm-sources')

---@class EXUICDMLayout
local layout = EXUI:GetModule('cdm-layout')

---@class EXUICDMCatalog
local catalog = EXUI:GetModule('cdm-catalog')

---@class EXUICDMAuras
local auras = EXUI:GetModule('cdm-auras')

---@class EXUICDMOptionsBuilder
local B = EXUI:GetModule('cdm-options-builder')

---@class EXUICDMNodeOptions
local nodeOptions = EXUI:GetModule('cdm-node-options')

local append = EXUI.utils.append

local JUSTIFY = {
    LEFT = { label = 'Left', order = 1 },
    CENTER = { label = 'Center', order = 2 },
    RIGHT = { label = 'Right', order = 3 },
}

local COMBAT = {
    any = { label = 'Always', order = 1 },
    ['in'] = { label = 'In Combat', order = 2 },
    out = { label = 'Out of Combat', order = 3 },
}

local AURA_STATE = {
    always = { label = 'Always', order = 1 },
    active = { label = 'Only When Active', order = 2 },
}

local STATE = {
    any = { label = 'Always', order = 1 },
    cooldown = { label = 'On Cooldown', order = 2 },
    ready = { label = 'Ready', order = 3 },
    usable = { label = 'Usable', order = 4 },
    threshold = { label = 'Last Seconds', order = 5 },
    effect = { label = 'Effect Active', order = 6 },
}

local ITEM_STATE = {}
for key, entry in pairs(STATE) do
    if key ~= 'effect' then
        ITEM_STATE[key] = entry
    end
end

local DISPLAYS = {
    icon = { label = 'Icon', order = 1 },
    bar = { label = 'Bar', order = 2 },
}

local SOURCE_TYPES = {
    spell = { label = 'Spell', order = 1 },
    item = { label = 'Item', order = 2 },
    equipment = { label = 'Equipment Slot', order = 3 },
    aura = { label = 'Buff / Debuff', order = 4 },
}

local PROC_GLOW_KINDS = {
    style = { label = 'Style Glow', order = 1 },
    edge = { label = 'Edge', order = 2 },
}

local GLOW_KINDS = {
    style = { label = 'Style Glow', order = 1 },
    edge = { label = 'Edge', order = 2 },
    bottom = { label = 'Fill', order = 3 },
}

local ORIENTATIONS = {
    horizontal = { label = 'Horizontal', order = 1 },
    vertical = { label = 'Vertical', order = 2 },
}

local ICON_POSITIONS = {
    start = { label = 'Left / Top', order = 1 },
    ['end'] = { label = 'Right / Bottom', order = 2 },
    none = { label = 'No Icon', order = 3 },
}

local LINKED_ICON = {
    none = { label = 'Keep Icon', order = 1 },
    aura = { label = 'Aura Icon', order = 2 },
    spell = { label = 'Full Color Icon', order = 3 },
}

local MISSING_EFFECTS = {
    none = { label = 'Nothing', order = 1 },
    desaturate = { label = 'Desaturate', order = 2 },
    hide = { label = 'Hide', order = 3 },
}

local function cdm()
    return EXUI:GetModule('cdm')
end

local function refreshAll()
    cdm():Refresh()
    optionsFields:RefreshItemList()
    optionsFields:RefreshOptions()
end

local function isRoot(id)
    return data:GetParentID(data:GetNode(id)) == nil
end

------------------------------------------------------------
-- Building blocks

-- Rows are laid out by percent and stretch to fill, so every row is padded to 100.
local function row(fields)
    local used = 0
    for _, field in ipairs(fields) do
        used = used + (field.width or 25)
    end
    if used < 100 then
        fields[#fields + 1] = B:Spacer(100 - used)
    end
    return fields
end

local function section(label, extra)
    return B:Title(label, extra)
end

local function subSection(label, extra)
    local options = { size = 12 }
    for key, value in pairs(extra or {}) do
        options[key] = value
    end
    return B:Title(label, options)
end

-- Field spec factory for one data path. Every builder below names its fields prefix .. key.
local function specs(path, prefix)
    return function(key, label, width, extra)
        local result = { path = path .. '.' .. key, name = prefix .. key, label = label, width = width }
        for k, v in pairs(extra or {}) do
            result[k] = v
        end
        return result
    end
end

local function styleField(id, spec)
    return B:Dropdown(id, spec('style', 'Style', 50), function() return styles:GetDropdownOptions() end)
end

local function manageStylesButton(name)
    return {
        type = 'button',
        label = 'Manage Styles',
        name = name,
        width = 25,
        onClick = function() EXUI:GetModule('styles-options'):Open() end,
    }
end

------------------------------------------------------------
-- General

function nodeOptions:GetScopeFields(id)
    if not isRoot(id) then
        return {}
    end
    local scope = data:GetScope(id)
    local owner = ''
    if scope and scope.mode == 'character' then
        owner = 'Owner: ' .. (scope.owner or '?')
    elseif scope and scope.mode == 'class' then
        owner = 'Class: ' .. (scope.class or '?')
    end
    return row({
        {
            type = 'dropdown',
            label = 'Visible To',
            name = 'scopeMode',
            width = 50,
            tooltip = { text = 'Which characters load this. Everything inside follows its top-level group.' },
            getOptions = function() return defaults.SCOPE_MODES end,
            currentValue = function()
                local current = data:GetScope(id)
                return current and current.mode or 'all'
            end,
            onChange = function(value)
                data:SetScopeMode(id, value)
                refreshAll()
            end,
        },
        { type = 'description', label = owner, width = 50 },
    })
end

function nodeOptions:GetGroupGeneral(id)
    local fields = {}
    append(fields, optionsFields:GetGroupFields({
        get = function(key) return data:GetValue(id, key) end,
        set = function(key, value) data:SetValue(id, key, value) end,
        onChange = function(key)
            cdm():Refresh()
            optionsFields:RefreshItemList()
            if key == 'enable' then
                optionsFields:RefreshOptions()
            end
        end,
    }))
    append(fields, self:GetScopeFields(id))
    return fields
end

local function setAuraList(id, path, spellIDs, input)
    data:SetValue(id, path .. '.input', input)
    data:SetValue(id, path .. '.spellIDs', spellIDs)
end

-- path: 'source' or 'linkedAuras.N'. Shared by aura items and linked auras.
function nodeOptions:GetAuraWatchFields(id, path, keyPrefix)
    local spec = specs(path, keyPrefix)
    local fields = row({
        {
            type = 'edit-box',
            label = 'Spell IDs or Names (comma separated)',
            name = keyPrefix .. 'input',
            width = 50,
            currentValue = function() return data:GetValue(id, path .. '.input') end,
            onChange = function(value)
                setAuraList(id, path, catalog:ResolveSpellList(value), value)
                cdm():Refresh()
                optionsFields:RefreshItemList()
            end,
        },
        {
            type = 'button',
            label = 'Pick from Cooldown Manager',
            name = keyPrefix .. 'pick',
            width = 25,
            onClick = function(button)
                catalog:ShowPicker(button, function(entry)
                    local ids = {}
                    for _, spellID in ipairs(entry.spellIDs) do
                        ids[#ids + 1] = tostring(spellID)
                    end
                    setAuraList(id, path, CopyTable(entry.spellIDs), table.concat(ids, ', '))
                    local node = data:GetNode(id)
                    if path == 'source' and node.name == defaults.ITEM.name then
                        node.name = entry.name
                    end
                    refreshAll()
                end, true)
            end,
        },
        B:Toggle(id, spec('onlyMine', 'Only Mine', 25)),
    })
    append(fields, row({
        B:Dropdown(id, spec('unit', 'Unit', 50, { refresh = true }), auras.UNITS),
        B:Dropdown(id, spec('filter', 'Type', 50, { refresh = true, list = true }), auras.FILTERS),
    }))
    append(fields, {
        B:Disclaimer(keyPrefix .. 'restricted',
            'In restricted content spell IDs only match buffs on friendly units and debuffs on enemy units, unless the spell is never secret.'),
    })
    return fields
end

local function sourceFields(id, node)
    local kind = node.source.type
    local fields = { section('Source') }
    local sourceType = B:Dropdown(id, { path = 'source.type', label = 'Source', width = 50, list = true },
        SOURCE_TYPES)
    local setSourceType = sourceType.onChange
    sourceType.onChange = function(value)
        setSourceType(value)
        -- Buff / Debuff items have no Linked Auras tab.
        optionsFields:AddInnerTabs(cdm())
    end
    local first = { sourceType }
    if kind == 'spell' then
        first[#first + 1] = B:Toggle(id, { path = 'source.ignoreGCD', label = 'Ignore Global Cooldown', width = 50 })
    end
    append(fields, row(first))

    if kind == 'spell' then
        append(fields, row({
            {
                type = 'edit-box',
                label = 'Spell ID or Name',
                name = 'source.spellID',
                width = 50,
                currentValue = function()
                    local spellID = data:GetValue(id, 'source.spellID')
                    return spellID and tostring(spellID) or ''
                end,
                onChange = function(value)
                    local spellID = catalog:ResolveSpellInput(value)
                    if spellID or strtrim(value or '') == '' then
                        data:SetValue(id, 'source.spellID', spellID)
                        cdm():Refresh()
                        optionsFields:RefreshItemList()
                    end
                end,
            },
            {
                type = 'button',
                label = 'Pick from Cooldown Manager',
                name = 'pickSpell',
                width = 25,
                onClick = function(button)
                    catalog:ShowPicker(button, function(entry)
                        local current = data:GetNode(id)
                        for key, value in pairs(entry.source) do
                            current.source[key] = value
                        end
                        if current.name == defaults.ITEM.name then
                            current.name = entry.name
                        end
                        refreshAll()
                    end)
                end,
            },
        }))
    elseif kind == 'item' then
        append(fields, row({
            {
                type = 'cdm-item-id-input',
                label = 'Item',
                name = 'source.itemID',
                width = 50,
                currentValue = function() return data:GetValue(id, 'source.itemID') end,
                onChange = function(value)
                    data:SetValue(id, 'source.itemID', value)
                    refreshAll()
                end,
            },
        }))
    elseif kind == 'equipment' then
        append(fields, row({
            B:Dropdown(id, { path = 'source.slot', label = 'Equipment Slot', width = 50, list = true },
                function() return sources:GetSlotOptions() end),
        }))
    elseif kind == 'aura' then
        append(fields, nodeOptions:GetAuraWatchFields(id, 'source', 'source'))
    end
    return fields
end

function nodeOptions:GetItemGeneral(id)
    local node = data:GetNode(id)
    local fields = {
        B:Toggle(id, { path = 'enable', label = 'Enable', width = 100, list = true }),
    }
    append(fields, row({
        B:Edit(id, { path = 'name', label = 'Name', width = 50, list = true }),
        B:Dropdown(id, { path = 'display', label = 'Display', width = 25, refresh = true }, DISPLAYS),
    }))
    append(fields, self:GetScopeFields(id))
    append(fields, sourceFields(id, node))
    return fields
end

------------------------------------------------------------
-- Position / Layout

function nodeOptions:GetPositionFields(id)
    if cdm():IsPositionedByParent(data:GetNode(id)) then
        return {
            section('Position'),
            B:Disclaimer('positionByGroup', 'Position, strata and level come from the parent group.'),
        }
    end
    local node = data:GetNode(id)
    if node.kind == 'group' and layout:IsFree(node) then
        return {
            section('Position'),
            B:Disclaimer('positionFree', 'Items in a Free group are positioned one by one, under their General tab.'),
        }
    end
    local fields = { section('Position') }
    append(fields, row({
        B:Anchor(id, { path = 'position.anchorPoint', label = 'Anchor Point', width = 25 }),
        B:Anchor(id, { path = 'position.relativePoint', label = 'Relative Anchor Point', width = 25 }),
        B:Range(id, { path = 'position.XOff', label = 'X Offset', width = 25 }, -2000, 2000, 1),
        B:Range(id, { path = 'position.YOff', label = 'Y Offset', width = 25 }, -2000, 2000, 1),
    }))
    append(fields, row({
        B:Dropdown(id, { path = 'frameStrata', label = 'Frame Strata', width = 50 }, EXUI.const.frameStrata),
        B:Range(id, { path = 'frameLevel', label = 'Frame Level', width = 50 }, 0, 100, 1),
    }))
    return fields
end

local MODE_INFO = {
    row = 'All items on one line.',
    grid = 'Items wrap onto a new line after Items Per Line.',
    custom = 'Drag items in the preview above to arrange them. Drop above or below every line to start a new one.',
    auraRow = 'Shows only Buff / Debuff items on the Aura Unit, and only while they are active. Missing ones close their gap even in combat. Align moves the whole block, and the items\' own visibility settings do not apply. To combine with other items, put this group in a parent group, e.g. Custom Lines with this group on its own line.',
    free = 'Every item is positioned on its own, under its General tab.',
}

function nodeOptions:GetLayoutFields(id)
    local mode = data:GetValue(id, 'layout.mode')
    local fields = {}
    if mode ~= 'free' then
        append(fields, {
            { type = 'cdm-designer', name = 'designer', groupID = id, width = 100 },
        })
    end
    append(fields, { section('Layout') })
    local first = { B:Dropdown(id, { path = 'layout.mode', label = 'Mode', width = 50, refresh = true }, layout.MODES) }
    if mode == 'auraRow' then
        first[#first + 1] = B:Dropdown(id, { path = 'layout.flowUnit', label = 'Aura Unit', width = 50 }, auras.UNITS)
    elseif mode ~= 'free' then
        first[#first + 1] = B:Toggle(id, {
            path = 'layout.collapse',
            label = 'Close Gaps',
            width = 50,
            tooltip = { text = 'Hidden items give up their spot. Items faded with Alpha When Hidden keep it.' },
        })
    end
    append(fields, row(first))
    append(fields, { B:Disclaimer('modeInfo', MODE_INFO[mode] or '') })

    if mode ~= 'free' then
        append(fields, { subSection('Direction') })
        append(fields, row({
            B:Dropdown(id, { path = 'layout.direction', label = 'Line Direction', width = 25 }, layout.DIRECTIONS),
            B:Dropdown(id, { path = 'layout.align', label = 'Align', width = 25 }, layout.ALIGN),
            B:Dropdown(id, { path = 'layout.growX', label = 'Grow Horizontally', width = 25 }, layout.GROW_X),
            B:Dropdown(id, { path = 'layout.growY', label = 'Grow Vertically', width = 25 }, layout.GROW_Y),
        }))
        append(fields, { subSection('Spacing') })
        local spacing = {}
        if mode == 'grid' or mode == 'auraRow' then
            spacing[#spacing + 1] = B:Range(id, { path = 'layout.perLine', label = 'Items Per Line', width = 34 }, 1, 40, 1)
        end
        local width = #spacing > 0 and 33 or 50
        spacing[#spacing + 1] = B:Range(id, { path = 'layout.spacingX', label = 'Horizontal Spacing', width = width },
            -10, 100, 1)
        spacing[#spacing + 1] = B:Range(id, { path = 'layout.spacingY', label = 'Vertical Spacing', width = width },
            -10, 100, 1)
        append(fields, row(spacing))
    end
    append(fields, self:GetPositionFields(id))
    return fields
end

------------------------------------------------------------
-- Appearance

local function copyParentKeys(id, appearance, keys)
    local parent = data:GetParent(data:GetNode(id))
    if not parent then
        return
    end
    for _, key in ipairs(keys) do
        local value = parent[appearance][key]
        data:SetValue(id, appearance .. '.' .. key, type(value) == 'table' and EXUI.utils.deepCloneTable(value) or value)
    end
end

local LOOK_KEYS = {}
for key in pairs(defaults.ICON) do
    if key ~= 'width' and key ~= 'height' then
        LOOK_KEYS[#LOOK_KEYS + 1] = key
    end
end

local BAR_KEYS = {}
for key in pairs(defaults.BAR) do
    BAR_KEYS[#BAR_KEYS + 1] = key
end

local function overrideToggle(id, part, label, width, copy)
    return {
        type = 'toggle',
        label = label,
        name = 'override.' .. part,
        width = width,
        currentValue = function() return data:GetValue(id, 'override.' .. part) end,
        onChange = function(value)
            if value then
                copy()
            end
            data:SetValue(id, 'override.' .. part, value)
            refreshAll()
        end,
    }
end

-- Range and procs only exist for spells; groups keep them so spell children can inherit.
local function spellOrGroup(node)
    return node.kind == 'group' or node.source.type == 'spell'
end

local function rangeProcFields(id, appearance)
    local spec = specs(appearance, appearance)
    local look = data:GetValue(id, appearance)
    local fields = { subSection('Out of Range') }
    local range = { B:Toggle(id, spec('rangeTint', 'Tint When Out of Range', 50, { refresh = true })) }
    if look.rangeTint then
        range[#range + 1] = B:Color(id, spec('rangeColor', 'Color', 25))
    end
    append(fields, row(range))

    append(fields, { subSection('Proc Glow') })
    local proc = {
        B:Toggle(id, spec('procGlow', 'Glow on Proc', 50, {
            refresh = true,
            tooltip = { text = 'Glow while the game highlights the spell, like action bar procs.' },
        })),
    }
    if look.procGlow then
        proc[#proc + 1] = B:Dropdown(id, spec('procGlowKind', 'Type', 25), PROC_GLOW_KINDS)
        proc[#proc + 1] = B:Color(id, spec('procGlowColor', 'Color', 25))
    end
    append(fields, row(proc))
    return fields
end

local function iconAppearanceFields(id, node, inherits)
    local spec = specs('iconAppearance', 'icon')
    local look = node.iconAppearance
    local ownSize = not inherits or node.override.size
    local ownLook = not inherits or node.override.icon
    local fields = { section('Icon') }
    if inherits then
        append(fields, row({
            overrideToggle(id, 'size', 'Own Size', 25, function() copyParentKeys(id, 'iconAppearance', { 'width', 'height' }) end),
            overrideToggle(id, 'icon', 'Own Look', 25, function() copyParentKeys(id, 'iconAppearance', LOOK_KEYS) end),
        }))
        if not ownSize and not ownLook then
            append(fields, { B:Disclaimer('iconInherited', 'Size and look come from the group. Turn on what this item should set itself.') })
        end
    end
    if ownSize then
        append(fields, { subSection('Size') })
        append(fields, row({
            B:Range(id, spec('width', 'Width', 50), 4, 400, 1),
            B:Range(id, spec('height', 'Height', 50), 4, 400, 1),
        }))
    end
    if not ownLook then
        return fields
    end
    append(fields, { subSection('Look') })
    append(fields, row({ styleField(id, spec), manageStylesButton('iconManageStyles') }))
    append(fields, row({
        B:Range(id, spec('zoom', 'Zoom', 50), 0, 100, 1),
        B:Color(id, spec('backgroundColor', 'Background', 25)),
    }))
    append(fields, { subSection('Border') })
    append(fields, row({
        B:Range(id, spec('borderSize', 'Size', 50, {
            tooltip = { text = 'With a Style the border follows its shape.' },
        }), 0, 10, 1),
        B:Color(id, spec('borderColor', 'Color', 25)),
    }))
    append(fields, { subSection('Cooldown') })
    local swipe = { B:Toggle(id, spec('showSwipe', 'Swipe', 25, { refresh = true })) }
    if look.showSwipe then
        swipe[#swipe + 1] = B:Color(id, spec('swipeColor', 'Swipe Color', 25))
        swipe[#swipe + 1] = B:Toggle(id, spec('reverseSwipe', 'Reverse Swipe', 25))
    end
    append(fields, row(swipe))
    append(fields, row({ B:Toggle(id, spec('showEdge', 'Edge', 25)) }))
    append(fields, row({ B:Toggle(id, spec('showBling', 'Bling When Ready', 25)) }))
    append(fields, row({ B:Toggle(id, spec('desaturateOnCooldown', 'Desaturate on Cooldown', 25)) }))
    if spellOrGroup(node) then
        append(fields, rangeProcFields(id, 'iconAppearance'))
    end
    return fields
end

local function barAppearanceFields(id, node, inherits, expanded)
    local spec = specs('barAppearance', 'bar')
    local look = node.barAppearance
    local fields = { section('Bar', { expanded = expanded }) }
    if inherits then
        append(fields, row({
            overrideToggle(id, 'bar', 'Own Look', 25, function() copyParentKeys(id, 'barAppearance', BAR_KEYS) end),
        }))
        if not node.override.bar then
            append(fields, { B:Disclaimer('barInherited', 'Size and look come from the group. Turn on Own Look to set them here.') })
            return fields
        end
    end
    append(fields, { subSection('Size') })
    append(fields, row({
        B:Range(id, spec('width', 'Width', 50), 4, 800, 1),
        B:Range(id, spec('height', 'Height', 50), 4, 400, 1),
    }))
    append(fields, { subSection('Look') })
    append(fields, row({ styleField(id, spec), manageStylesButton('barManageStyles') }))
    append(fields, row({
        B:Dropdown(id, spec('texture', 'Texture', 50, { isTextureDropdown = true }), function()
            local textures = {}
            for _, texture in ipairs(LSM:List('statusbar')) do
                textures[texture] = texture
            end
            return textures
        end),
        B:Dropdown(id, spec('orientation', 'Orientation', 50), ORIENTATIONS),
    }))
    append(fields, row({
        B:Color(id, spec('color', 'Bar Color', 25)),
        B:Color(id, spec('backgroundColor', 'Background', 25)),
        B:Toggle(id, spec('reverseFill', 'Reverse Fill', 25)),
        B:Toggle(id, spec('fillWhenReady', 'Full When Ready', 25, {
            tooltip = { text = 'Show a full bar while the cooldown is ready instead of an empty one.' },
        })),
    }))
    append(fields, { subSection('Border') })
    append(fields, row({
        B:Range(id, spec('borderSize', 'Size', 50, {
            tooltip = { text = 'With a Style the border follows its shape.' },
        }), 0, 10, 1),
        B:Color(id, spec('borderColor', 'Color', 25)),
    }))
    append(fields, { subSection('Bar Icon') })
    append(fields, row({ B:Dropdown(id, spec('iconPosition', 'Position', 50, { refresh = true }), ICON_POSITIONS) }))
    if look.iconPosition ~= 'none' then
        append(fields, row({
            B:Range(id, spec('gap', 'Gap', 50), 0, 20, 1),
            B:Range(id, spec('zoom', 'Zoom', 50), 0, 100, 1),
        }))
        local swipe = { B:Toggle(id, spec('showSwipe', 'Swipe', 25, { refresh = true })) }
        if look.showSwipe then
            swipe[#swipe + 1] = B:Color(id, spec('swipeColor', 'Swipe Color', 25))
        end
        append(fields, row(swipe))
        append(fields, row({ B:Toggle(id, spec('desaturateOnCooldown', 'Desaturate on Cooldown', 25)) }))
    end
    if spellOrGroup(node) then
        append(fields, rangeProcFields(id, 'barAppearance'))
    end
    return fields
end

-- Glow / border / pandemic shown while an aura is up; path is 'source' or 'linkedAuras.N'.
local function effectFields(id, path, prefix)
    local spec = specs(path, prefix)
    local config = data:GetValue(id, path)
    local fields = { subSection('Glow') }
    local glow = { B:Toggle(id, spec('glow', 'Glow', 25, { refresh = true })) }
    if config.glow then
        glow[#glow + 1] = B:Dropdown(id, spec('glowKind', 'Type', 25, { refresh = true }), GLOW_KINDS)
        glow[#glow + 1] = B:Color(id, spec('glowColor', 'Color', 25))
        glow[#glow + 1] = B:Toggle(id, spec('glowPulse', 'Pulse', 25))
    end
    append(fields, row(glow))
    if config.glow and config.glowKind == 'edge' then
        append(fields, row({ B:Range(id, spec('glowSize', 'Size', 50), 4, 40, 1) }))
    end

    append(fields, { subSection('Border') })
    local border = { B:Toggle(id, spec('border', 'Border', 25, { refresh = true })) }
    if config.border then
        border[#border + 1] = B:Color(id, spec('borderColor', 'Color', 25))
        border[#border + 1] = B:Range(id, spec('borderSize', 'Size', 50, {
            tooltip = { text = 'Used when the item has no Style. With a Style the border follows its shape.' },
        }), 1, 10, 1)
    end
    append(fields, row(border))

    append(fields, { subSection('Pandemic') })
    local pandemic = {
        B:Toggle(id, spec('pandemic', 'Pandemic Glow', 25, {
            refresh = true,
            tooltip = { text = 'Glow while the aura can be refreshed without losing duration. Only auras with a refresh window have one, mostly your own damage and healing over time.' },
        })),
    }
    if config.pandemic then
        pandemic[#pandemic + 1] = B:Color(id, spec('pandemicColor', 'Color', 25))
        pandemic[#pandemic + 1] = B:Toggle(id, spec('pandemicPulse', 'Pulse', 25))
    end
    append(fields, row(pandemic))
    return fields
end

local function usesBars(id)
    for _, child in ipairs(data:GetChildren(id)) do
        if (child.kind == 'item' and child.display == 'bar') or (child.kind == 'group' and usesBars(child.id)) then
            return true
        end
    end
    return false
end

function nodeOptions:GetAppearanceFields(id)
    local node = data:GetNode(id)
    local inherits = node.kind == 'item' and not isRoot(id)
    local fields = {}
    if node.kind == 'group' then
        append(fields, { B:Disclaimer('groupDefaults', 'Items inside use these settings unless they set their own.') })
        append(fields, iconAppearanceFields(id, node, false))
        append(fields, barAppearanceFields(id, node, false, usesBars(id)))
        return fields
    end
    if node.display == 'bar' then
        append(fields, barAppearanceFields(id, node, inherits))
    else
        append(fields, iconAppearanceFields(id, node, inherits))
    end
    if node.source.type == 'aura' then
        append(fields, { section('While Active') })
        append(fields, effectFields(id, 'source', 'source'))
    end
    return fields
end

------------------------------------------------------------
-- Texts

-- listPath: 'texts' or 'linkedAuras.N.texts'. nested renders the text as a subsection.
local function textFields(id, listPath, index, text, nested)
    local base = listPath .. '.' .. index
    local spec = specs(base, text.id)
    local label = (defaults.TEXT_KINDS[text.kind] or defaults.TEXT_KINDS.custom).label
    local title = string.format('Text %d: %s', index, label)
    local fields = { nested and subSection(title, { expanded = false }) or section(title, { expanded = false }) }

    local first = {
        B:Toggle(id, spec('enable', 'Enable', 25)),
        B:Dropdown(id, spec('kind', 'Shows', 25, { refresh = true }), defaults.TEXT_KINDS),
    }
    if text.kind == 'custom' then
        first[#first + 1] = B:Edit(id, spec('text', 'Text', 50))
    end
    append(fields, row(first))
    append(fields, row({
        B:Font(id, spec('font', 'Font', 25)),
        B:Range(id, spec('fontSize', 'Size', 25), 6, 64, 1),
        B:Dropdown(id, spec('fontFlag', 'Outline', 25), EXUI.const.fontFlags),
        B:Dropdown(id, spec('justify', 'Justify', 25), JUSTIFY),
    }))
    local colors = { B:Color(id, spec('color', 'Color', 25)) }
    if text.kind == 'cooldown' then
        colors[#colors + 1] = B:Range(id, spec('urgentSeconds', 'Urgent Below (sec)', 25, {
            refresh = true,
            tooltip = { text = 'Below this many seconds the text uses the urgent color. 0 turns it off. Give the normal color 0 alpha to only show the text in its last seconds.' },
        }), 0, 30, 1)
        if (text.urgentSeconds or 0) > 0 then
            colors[#colors + 1] = B:Color(id, spec('urgentColor', 'Urgent Color', 25))
        end
    end
    append(fields, row(colors))
    local shadow = EXUI.utils.fontShadowFields(text.id .. 'text', function(key)
        return data:GetValue(id, base .. '.' .. key:sub(#text.id + 1))
    end, function(key, value)
        data:SetValue(id, base .. '.' .. key:sub(#text.id + 1), value)
        cdm():Refresh()
    end, 25, function()
        optionsFields:RefreshOptions()
    end)
    append(fields, row(text.textShadow and shadow or { shadow[1] }))
    append(fields, row({
        B:Anchor(id, spec('anchorPoint', 'Anchor Point', 25)),
        B:Anchor(id, spec('relativePoint', 'Relative Anchor Point', 25)),
        B:Range(id, spec('XOff', 'X Offset', 25), -200, 200, 1),
        B:Range(id, spec('YOff', 'Y Offset', 25), -200, 200, 1),
    }))
    if text.kind == 'cooldown' then
        append(fields, row({
            B:Dropdown(id, spec('format', 'Time Format', 50), function() return durationFormat:GetFormatOptions() end),
            B:Range(id, spec('updateInterval', 'Update Every (sec)', 50), 0.05, 1, 0.05),
        }))
    end
    append(fields, {
        B:Spacer(75),
        {
            type = 'button',
            label = 'Remove Text',
            name = text.id .. 'remove',
            width = 25,
            color = EXUI.EXFrames.Theme.danger,
            onClick = function()
                table.remove(data:GetValue(id, listPath), index)
                refreshAll()
            end,
        },
    })
    return fields
end

local function addTextButton(id, name, listPath, kind)
    return B:Button(name, 'Add Text', function()
        local text = { kind = kind }
        defaults:MergeText(text)
        table.insert(data:GetValue(id, listPath), text)
        refreshAll()
    end, 100)
end

function nodeOptions:GetTextFields(id)
    local node = data:GetNode(id)
    local fields = {}
    if node.kind == 'item' and not isRoot(id) then
        append(fields, row({
            overrideToggle(id, 'texts', 'Own Texts', 25, function()
                node.texts = EXUI.utils.deepCloneTable(data:GetParent(node).texts)
            end),
        }))
        if not node.override.texts then
            append(fields, { B:Disclaimer('inheritTexts', 'Texts come from the group. Turn on Own Texts to set them here.') })
            return fields
        end
    end
    append(fields, { addTextButton(id, 'addText', 'texts', 'custom') })
    for index, text in ipairs(node.texts) do
        append(fields, textFields(id, 'texts', index, text))
    end
    return fields
end

------------------------------------------------------------
-- Linked auras

local function bridgeTracks(spellIDs, kind)
    return EXUI:GetModule('cdm-bridge'):IsTracked(spellIDs, kind)
end

local function linkedAuraFields(id, index, linked)
    local path = 'linkedAuras.' .. index
    local prefix = linked.id
    local spec = specs(path, prefix)
    local name = linked.spellIDs[1] and C_Spell.GetSpellName(linked.spellIDs[1]) or 'No aura set'
    local fields = {
        section(string.format('%d. %s', index, name)),
        B:Spacer(50),
        B:Button(prefix .. 'addText', 'Add Text', function()
            local text = { kind = 'cooldown' }
            defaults:MergeText(text)
            table.insert(data:GetValue(id, path .. '.texts'), text)
            refreshAll()
        end, 25),
        {
            type = 'button',
            label = 'Remove',
            name = prefix .. 'remove',
            width = 25,
            color = EXUI.EXFrames.Theme.danger,
            onClick = function()
                table.remove(data:GetNode(id).linkedAuras, index)
                refreshAll()
            end,
        },
        subSection('Aura'),
    }
    append(fields, nodeOptions:GetAuraWatchFields(id, path, prefix))

    append(fields, { subSection('Icon and Swipe') })
    local swipe = { B:Toggle(id, spec('swipe', 'Aura Swipe', 25, { refresh = true })) }
    if linked.swipe then
        swipe[#swipe + 1] = B:Color(id, spec('swipeColor', 'Swipe Color', 25))
        swipe[#swipe + 1] = B:Toggle(id, spec('reverseSwipe', 'Reverse Swipe', 25))
    end
    append(fields, row({ B:Dropdown(id, spec('icon', 'Icon', 50), LINKED_ICON) }))
    append(fields, row(swipe))
    append(fields, effectFields(id, path, prefix))

    append(fields, { subSection('While Missing') })
    append(fields, row({
        B:Dropdown(id, spec('missingEffect', 'Cooldown', 50, {
            refresh = true,
            tooltip = { text = 'Hide uses Alpha When Hidden from the Visibility tab and closes the gap in groups.' },
        }), MISSING_EFFECTS),
    }))
    if linked.missingEffect ~= 'none' then
        append(fields, {
            B:Disclaimer(prefix .. 'missingInfo',
                "Needs this aura in Blizzard's Cooldown Manager under Tracked Buffs, with Tracked Buffs visibility set to Always in Edit Mode. It is turned on for you and kept hidden."),
            B:Disclaimer(prefix .. 'untracked',
                "This aura is not in Blizzard's Cooldown Manager right now, so this has no effect. Add it under Tracked Buffs.",
                function() return bridgeTracks(data:GetValue(id, path .. '.spellIDs'), 'buff') == false end),
        })
    end

    for textIndex, text in ipairs(linked.texts) do
        append(fields, textFields(id, path .. '.texts', textIndex, text, true))
    end
    return fields
end

function nodeOptions:GetLinkedAuraFields(id)
    local node = data:GetNode(id)
    if node.source.type == 'aura' then
        return { B:Disclaimer('linkedAuraSource', 'This item already tracks an aura. Linked auras are for cooldowns.') }
    end
    local fields = {
        B:Disclaimer('linkedAuraInfo', 'Show a buff or debuff on this cooldown. Everything set for it, texts included, appears only while it is up; Remaining Time and Charges / Stacks texts read from the aura.'),
        B:Button('addLinkedAura', 'Add Linked Aura', function()
            local linked = {}
            defaults:MergeLinkedAura(linked)
            table.insert(node.linkedAuras, linked)
            refreshAll()
        end, 100),
    }
    for index, linked in ipairs(node.linkedAuras) do
        append(fields, linkedAuraFields(id, index, linked))
    end
    return fields
end

------------------------------------------------------------
-- Visibility / Load

local function hiddenAlphaField(id, width)
    return B:Range(id, {
        path = 'visibility.hiddenAlpha',
        label = 'Alpha When Hidden',
        width = width,
        tooltip = { text = 'Above 0 fades instead of hiding, and the item keeps its spot in the group.' },
    }, 0, 1, 0.05)
end

local function cooldownVisibilityFields(id, node)
    local state = node.visibility.cooldownState
    local isSpell = node.source.type == 'spell'
    if state == 'effect' and not isSpell then
        state = 'any'
    end
    local fields = row({
        B:Dropdown(id, { path = 'visibility.combat', label = 'Combat', width = 50 }, COMBAT),
        B:Dropdown(id, { path = 'visibility.cooldownState', label = 'State', width = 50, refresh = true },
            isSpell and STATE or ITEM_STATE),
    })
    local second = { hiddenAlphaField(id, 50) }
    if state == 'threshold' then
        second[#second + 1] = B:Range(id, {
            path = 'visibility.threshold',
            label = 'Seconds Left',
            width = 50,
            tooltip = { text = 'Shown during the last seconds of the cooldown and while ready. Before that it uses Alpha When Hidden.' },
        }, 1, 30, 1)
    end
    append(fields, row(second))
    if state == 'threshold' then
        append(fields, {
            B:Disclaimer('thresholdNotice',
                'The remaining time is hidden from addons in combat, so a Last Seconds item keeps its spot in a group even while faded out.'),
        })
    elseif state == 'effect' then
        local spellID = tonumber(node.source.spellID)
        append(fields, {
            B:Disclaimer('effectNotice',
                "Shows only while the spell's buff or totem is up. Needs the spell in Blizzard's Cooldown Manager under Essential or Utility, with that bar's visibility set to Always in Edit Mode. It is turned on for you and kept hidden."),
            B:Disclaimer('effectUntracked',
                "This spell is not in Blizzard's Cooldown Manager right now, so Effect Active has no effect.",
                function()
                    return spellID ~= nil and bridgeTracks({ spellID, C_Spell.GetOverrideSpell(spellID) }, 'cooldown') == false
                end),
        })
    end
    return fields
end

local function auraVisibilityFields(id, node)
    local active = node.visibility.auraState == 'active'
    local fields = row({
        B:Dropdown(id, { path = 'visibility.combat', label = 'Combat', width = 50 }, COMBAT),
        B:Dropdown(id, { path = 'visibility.auraState', label = 'State', width = 50, refresh = true, list = true },
            AURA_STATE),
    })
    local second = { hiddenAlphaField(id, 50) }
    if not active then
        second[#second + 1] = B:Range(id, {
            path = 'source.missingAlpha',
            label = 'Icon Alpha When Missing',
            width = 50,
            tooltip = { text = 'The desaturated icon shown while the aura is not up.' },
        }, 0, 1, 0.05)
    end
    append(fields, row(second))
    if active then
        append(fields, {
            B:Disclaimer('auraStateNotice',
                "Whether an aura is up is hidden from addons in combat. With the buff in Blizzard's Cooldown Manager under Tracked Buffs the item also gives up its spot in groups; otherwise it keeps it."),
        })
    end
    return fields
end

function nodeOptions:GetVisibilityFields(id)
    local node = data:GetNode(id)
    local fields = { section('Visibility') }
    if node.kind == 'group' then
        append(fields, row({
            B:Dropdown(id, { path = 'visibility.combat', label = 'Combat', width = 50 }, COMBAT),
            hiddenAlphaField(id, 50),
        }))
    elseif node.source.type == 'aura' then
        append(fields, auraVisibilityFields(id, node))
    else
        append(fields, cooldownVisibilityFields(id, node))
    end
    return fields
end

function nodeOptions:GetLoadFields(id)
    return EXUI:GetModule('cdm-load-options'):GetOptions(id)
end
