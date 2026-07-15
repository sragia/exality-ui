---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

local function refreshEditorOptions()
    local editor = EXUI:GetModule('uf-aura-editor')
    if editor and editor.RefreshOptions then
        editor:RefreshOptions()
    end
end

local function refreshEditorList()
    local editor = EXUI:GetModule('uf-aura-editor')
    if editor and editor.RefreshItemList then
        editor:RefreshItemList()
    end
end

---@class EXUIUnitFramesAuras
local auraDisplays = EXUI:GetModule('uf-auras')

---@class EXUIUFAuraEditorGroupNav
local groupNav = EXUI:GetModule('uf-aura-editor-group-nav')

---@class EXUIUFAuraEditorVisualOptions
local visualOptions = EXUI:GetModule('uf-aura-editor-visual-options')

---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

local function append(target, source)
    for _, field in ipairs(source) do
        table.insert(target, field)
    end
end

local function isBarStyle(displayID, groupID)
    return auraDisplays:GetGroupVisual(displayID, groupID, 'displayStyle') == 'bar'
end

local function updateVisual(displayID, groupID, key, value, refreshOptions)
    auraDisplays:UpdateGroupVisual(displayID, groupID, key, value)
    auraDisplays:RefreshDisplay(displayID)
    if refreshOptions then
        refreshEditorOptions()
    end
end

function visualOptions:MakeTextFields(displayID, groupID, prefix, label, options)
    options = options or {}
    local fields = {}

    if not options.skipTitle then
        table.insert(fields, { type = 'title', label = label, width = 100 })
    end

    if prefix == 'duration' then
        table.insert(fields, {
            type = 'dropdown',
            label = 'Time Format',
            name = 'durationFormat',
            width = 100,
            getOptions = function()
                return durationFormat:GetFormatOptions()
            end,
            currentValue = function()
                return auraDisplays:GetGroupVisual(displayID, groupID, 'durationFormat') or
                    durationFormat.FORMAT_FALLBACK
            end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, 'durationFormat', v)
                auraDisplays:RefreshDisplay(displayID)
            end,
        })
    end

    append(fields, {
        {
            type = 'dropdown',
            label = 'Font',
            name = prefix .. 'Font',
            width = 25,
            getOptions = function()
                local fonts = {}
                if LSM then for _, font in ipairs(LSM:List('font')) do fonts[font] = font end end
                return fonts
            end,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, prefix .. 'Font') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, prefix .. 'Font', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'range',
            label = 'Size',
            name = prefix .. 'FontSize',
            min = 6,
            max = 32,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, prefix .. 'FontSize') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, prefix .. 'FontSize', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Outline',
            name = prefix .. 'FontFlag',
            width = 25,
            getOptions = function() return EXUI.const.fontFlags end,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, prefix .. 'FontFlag') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, prefix .. 'FontFlag', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'color-picker',
            label = 'Color',
            name = prefix .. 'Color',
            width = 25,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, prefix .. 'Color') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, prefix .. 'Color', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'anchor-point',
            label = 'Anchor',
            name = prefix .. 'AnchorPoint',
            width = 25,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, prefix .. 'AnchorPoint') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, prefix .. 'AnchorPoint', v); auraDisplays
                    :RefreshDisplay(displayID)
            end,
        },
        {
            type = 'anchor-point',
            label = 'Relative',
            name = prefix .. 'RelativePoint',
            width = 25,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, prefix .. 'RelativePoint') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, prefix .. 'RelativePoint', v); auraDisplays
                    :RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'X',
            name = prefix .. 'XOff',
            min = -200,
            max = 200,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, prefix .. 'XOff') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, prefix .. 'XOff', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'range',
            label = 'Y',
            name = prefix .. 'YOff',
            min = -200,
            max = 200,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, prefix .. 'YOff') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, prefix .. 'YOff', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
    })
    return fields
end

function visualOptions:GetOptions(displayID, groupID)
    groupNav:EnsureGroupSelected(displayID)
    groupID = groupID or auraDisplays.currGroupID
    if not groupID then return {} end

    local fields = {}
    append(fields, groupNav:GetFields(displayID))

    append(fields, {
        { type = 'title', label = 'Display Style', width = 100 },
        {
            type = 'dropdown',
            label = 'Style',
            name = 'displayStyle',
            width = 100,
            getOptions = function()
                return { icon = 'Icon', bar = 'Bar' }
            end,
            currentValue = function()
                return auraDisplays:GetGroupVisual(displayID, groupID, 'displayStyle') or 'icon'
            end,
            onChange = function(v)
                updateVisual(displayID, groupID, 'displayStyle', v, true)
            end,
        },
    })

    append(fields, {
        { type = 'title', label = 'Group Layout',    width = 100 },
        {
            type = 'range',
            label = 'Spacing X',
            name = 'elementSpacingX',
            min = 0,
            max = 50,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'elementSpacingX') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, 'elementSpacingX', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'range',
            label = 'Spacing Y',
            name = 'elementSpacingY',
            min = 0,
            max = 50,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'elementSpacingY') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, 'elementSpacingY', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'range',
            label = 'Gap X',
            name = 'gapX',
            min = 0,
            max = 50,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'gapX') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, 'gapX', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Gap Y',
            name = 'gapY',
            min = 0,
            max = 50,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'gapY') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, 'gapY', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'toggle',
            label = 'Group Starts on New Row',
            name = 'forceNewRow',
            width = 100,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'forceNewRow') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, 'forceNewRow', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
    })

    if isBarStyle(displayID, groupID) then
        append(fields, {
            { type = 'title', label = 'Bar',        width = 100 },
            {
                type = 'range',
                label = 'Width',
                name = 'barWidth',
                min = 40,
                max = 400,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'barWidth') end,
                onChange = function(v) updateVisual(displayID, groupID, 'barWidth', v) end,
            },
            {
                type = 'range',
                label = 'Height',
                name = 'barHeight',
                min = 8,
                max = 64,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'barHeight') end,
                onChange = function(v) updateVisual(displayID, groupID, 'barHeight', v) end,
            },
            {
                type = 'color-picker',
                label = 'Fill Color',
                name = 'barColor',
                width = 25,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'barColor') end,
                onChange = function(v) updateVisual(displayID, groupID, 'barColor', v) end,
            },
            {
                type = 'color-picker',
                label = 'Track Color',
                name = 'barBackgroundColor',
                width = 25,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'barBackgroundColor') end,
                onChange = function(v) updateVisual(displayID, groupID, 'barBackgroundColor', v) end,
            },
            {
                type = 'dropdown',
                label = 'Texture',
                name = 'barTexture',
                width = 50,
                getOptions = function()
                    local textures = {}
                    if LSM then
                        for _, texture in ipairs(LSM:List('statusbar')) do
                            textures[texture] = texture
                        end
                    end
                    return textures
                end,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'barTexture') end,
                onChange = function(v) updateVisual(displayID, groupID, 'barTexture', v) end,
            },
            {
                type = 'dropdown',
                label = 'Timer Direction',
                name = 'barTimerDirection',
                width = 50,
                getOptions = function()
                    return {
                        RemainingTime = 'Deplete (Remaining)',
                        ElapsedTime = 'Fill (Elapsed)',
                    }
                end,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'barTimerDirection') end,
                onChange = function(v) updateVisual(displayID, groupID, 'barTimerDirection', v) end,
            },
            { type = 'title', label = 'Bar Border', width = 100 },
            {
                type = 'color-picker',
                label = 'Color',
                name = 'barBorderColor',
                width = 50,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'barBorderColor') end,
                onChange = function(v) updateVisual(displayID, groupID, 'barBorderColor', v) end,
            },
            {
                type = 'range',
                label = 'Thickness',
                name = 'barBorderThickness',
                min = 1,
                max = 8,
                step = 1,
                width = 50,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'barBorderThickness') end,
                onChange = function(v) updateVisual(displayID, groupID, 'barBorderThickness', v) end,
            },
            { type = 'title', label = 'Bar Icon', width = 100 },
            {
                type = 'toggle',
                label = 'Show Icon',
                name = 'showBarIcon',
                width = 100,
                currentValue = function()
                    return auraDisplays:GetGroupVisual(displayID, groupID, 'showBarIcon') ~= false
                end,
                onChange = function(v) updateVisual(displayID, groupID, 'showBarIcon', v, true) end,
            },
        })

        if auraDisplays:GetGroupVisual(displayID, groupID, 'showBarIcon') ~= false then
            append(fields, {
                {
                    type = 'dropdown',
                    label = 'Position',
                    name = 'barIconPosition',
                    width = 25,
                    getOptions = function()
                        return { LEFT = 'Left', RIGHT = 'Right' }
                    end,
                    currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'barIconPosition') end,
                    onChange = function(v) updateVisual(displayID, groupID, 'barIconPosition', v) end,
                },
                {
                    type = 'range',
                    label = 'Gap',
                    name = 'barIconGap',
                    min = 0,
                    max = 20,
                    step = 1,
                    width = 25,
                    currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'barIconGap') end,
                    onChange = function(v) updateVisual(displayID, groupID, 'barIconGap', v) end,
                },
                {
                    type = 'range',
                    label = 'Zoom %',
                    name = 'iconZoom',
                    min = 0,
                    max = 40,
                    step = 1,
                    width = 25,
                    currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'iconZoom') end,
                    onChange = function(v) updateVisual(displayID, groupID, 'iconZoom', v) end,
                },
                {
                    type = 'toggle',
                    label = 'Show Border',
                    name = 'showIconBorder',
                    width = 100,
                    currentValue = function()
                        return auraDisplays:GetGroupVisual(displayID, groupID, 'showIconBorder') ~= false
                    end,
                    onChange = function(v) updateVisual(displayID, groupID, 'showIconBorder', v, true) end,
                },
            })

            if auraDisplays:GetGroupVisual(displayID, groupID, 'showIconBorder') ~= false then
                append(fields, {
                    {
                        type = 'color-picker',
                        label = 'Border Color',
                        name = 'iconBorderColor',
                        width = 50,
                        currentValue = function()
                            return auraDisplays:GetGroupVisual(displayID, groupID,
                                'iconBorderColor')
                        end,
                        onChange = function(v) updateVisual(displayID, groupID, 'iconBorderColor', v) end,
                    },
                    {
                        type = 'range',
                        label = 'Border Thickness',
                        name = 'iconBorderThickness',
                        min = 1,
                        max = 8,
                        step = 1,
                        width = 50,
                        currentValue = function()
                            return auraDisplays:GetGroupVisual(displayID, groupID,
                                'iconBorderThickness')
                        end,
                        onChange = function(v) updateVisual(displayID, groupID, 'iconBorderThickness', v) end,
                    },
                })
            end
        end
    else
        append(fields, {
            { type = 'title', label = 'Icon',        width = 100 },
            {
                type = 'range',
                label = 'Width',
                name = 'iconWidth',
                min = 8,
                max = 100,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'iconWidth') end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'iconWidth', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'range',
                label = 'Height',
                name = 'iconHeight',
                min = 8,
                max = 100,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'iconHeight') end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'iconHeight', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'range',
                label = 'Zoom %',
                name = 'iconZoom',
                min = 0,
                max = 40,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'iconZoom') end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'iconZoom', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            { type = 'title', label = 'Icon Border', width = 100 },
            {
                type = 'toggle',
                label = 'Show Border',
                name = 'showIconBorder',
                width = 100,
                currentValue = function()
                    return auraDisplays:GetGroupVisual(displayID, groupID, 'showIconBorder') ~= false
                end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'showIconBorder', v); auraDisplays:RefreshDisplay(
                        displayID); refreshEditorOptions()
                end,
            },
        })

        if auraDisplays:GetGroupVisual(displayID, groupID, 'showIconBorder') ~= false then
            append(fields, {
                {
                    type = 'color-picker',
                    label = 'Color',
                    name = 'iconBorderColor',
                    width = 50,
                    currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'iconBorderColor') end,
                    onChange = function(v)
                        auraDisplays:UpdateGroupVisual(displayID, groupID, 'iconBorderColor', v); auraDisplays
                            :RefreshDisplay(
                                displayID)
                    end,
                },
                {
                    type = 'range',
                    label = 'Thickness',
                    name = 'iconBorderThickness',
                    min = 1,
                    max = 8,
                    step = 1,
                    width = 50,
                    currentValue = function()
                        return auraDisplays:GetGroupVisual(displayID, groupID,
                            'iconBorderThickness')
                    end,
                    onChange = function(v)
                        auraDisplays:UpdateGroupVisual(displayID, groupID, 'iconBorderThickness', v); auraDisplays
                            :RefreshDisplay(
                                displayID)
                    end,
                },
            })
        end
    end

    append(fields, {
        { type = 'title', label = 'Stacks', width = 100 },
        {
            type = 'toggle',
            label = 'Show Stacks',
            name = 'showStacks',
            width = 100,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'showStacks') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, 'showStacks', v); auraDisplays:RefreshDisplay(
                    displayID); refreshEditorOptions()
            end,
            depends = function() return true end,
        },
    })

    if auraDisplays:GetGroupVisual(displayID, groupID, 'showStacks') then
        append(fields, self:MakeTextFields(displayID, groupID, 'stack', 'Stacks', { skipTitle = true }))
    end

    append(fields, {
        { type = 'title', label = 'Duration', width = 100 },
        {
            type = 'toggle',
            label = 'Show Duration Text',
            name = 'showDurationText',
            width = 100,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'showDurationText') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, 'showDurationText', v); auraDisplays:RefreshDisplay(
                    displayID); refreshEditorOptions()
            end,
        },
    })

    if not isBarStyle(displayID, groupID) then
        append(fields, {
            {
                type = 'toggle',
                label = 'Show Cooldown Sweep',
                name = 'showDurationCooldown',
                width = 100,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'showDurationCooldown') end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'showDurationCooldown', v); auraDisplays
                        :RefreshDisplay(displayID)
                end,
            },
        })
    end

    if auraDisplays:GetGroupVisual(displayID, groupID, 'showDurationText') then
        append(fields, self:MakeTextFields(displayID, groupID, 'duration', 'Duration Text', { skipTitle = true }))
    end

    append(fields, {
        { type = 'title', label = 'Spell Name', width = 100 },
        {
            type = 'toggle',
            label = 'Show Spell Name',
            name = 'showSpellName',
            width = 100,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'showSpellName') end,
            onChange = function(v) updateVisual(displayID, groupID, 'showSpellName', v, true) end,
        },
    })

    if auraDisplays:GetGroupVisual(displayID, groupID, 'showSpellName') then
        append(fields, self:MakeTextFields(displayID, groupID, 'spellName', 'Spell Name', { skipTitle = true }))
    end

    if not isBarStyle(displayID, groupID) then
        append(fields, {
            { type = 'title', label = 'Dispel', width = 100 },
            {
                type = 'toggle',
                label = 'Show Dispel Border',
                name = 'showDispelBorder',
                width = 100,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'showDispelBorder') end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'showDispelBorder', v); auraDisplays
                        :RefreshDisplay(
                            displayID)
                end,
            },
        })
    end

    if auraDisplays:GetGroupConditions(displayID, groupID, 'groupType') == 'slot' then
        append(fields, {
            { type = 'title', label = 'Slot Position', width = 100 },
            {
                type = 'anchor-point',
                label = 'Anchor',
                name = 'slotAnchorPoint',
                width = 25,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'slotAnchorPoint') end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'slotAnchorPoint', v); auraDisplays
                        :RefreshDisplay(displayID)
                end,
            },
            {
                type = 'anchor-point',
                label = 'Relative',
                name = 'slotRelativePoint',
                width = 25,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'slotRelativePoint') end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'slotRelativePoint', v); auraDisplays
                        :RefreshDisplay(displayID)
                end,
            },
            {
                type = 'range',
                label = 'X',
                name = 'slotXOff',
                min = -500,
                max = 500,
                step = 1,
                width = 12,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'slotXOff') end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'slotXOff', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'range',
                label = 'Y',
                name = 'slotYOff',
                min = -500,
                max = 500,
                step = 1,
                width = 12,
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'slotYOff') end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'slotYOff', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
        })
    end

    return fields
end
