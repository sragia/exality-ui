---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIAuraDisplaysModule
local auraDisplays = EXUI:GetModule('aura-displays')

---@class EXUIAuraDisplaysGroupNav
local groupNav = EXUI:GetModule('aura-displays-group-nav')

---@class EXUIAuraDisplaysVisualOptions
local visualOptions = EXUI:GetModule('aura-displays-visual-options')

---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

local function append(target, source)
    for _, field in ipairs(source) do
        table.insert(target, field)
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
        { type = 'title', label = 'Screen Position', width = 100 },
        {
            type = 'anchor-point',
            label = 'Anchor',
            name = 'anchorPoint',
            width = 25,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'anchorPoint') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'anchorPoint', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'anchor-point',
            label = 'Relative',
            name = 'relativePoint',
            width = 25,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'relativePoint') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'relativePoint', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'X',
            name = 'XOff',
            min = -2000,
            max = 2000,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'XOff') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'XOff', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Y',
            name = 'YOff',
            min = -2000,
            max = 2000,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'YOff') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'YOff', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Strata',
            name = 'frameStrata',
            width = 50,
            getOptions = function() return EXUI.const.frameStrata end,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'frameStrata') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'frameStrata', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
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
        { type = 'title', label = 'Icon', width = 100 },
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
                auraDisplays:UpdateGroupVisual(displayID, groupID, 'iconZoom', v); auraDisplays:RefreshDisplay(displayID)
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
                    displayID); optionsFields:RefreshOptions()
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
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'iconBorderColor', v); auraDisplays:RefreshDisplay(
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
                currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'iconBorderThickness') end,
                onChange = function(v)
                    auraDisplays:UpdateGroupVisual(displayID, groupID, 'iconBorderThickness', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
        })
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
                    displayID); optionsFields:RefreshOptions()
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
                    displayID); optionsFields:RefreshOptions()
            end,
        },
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

    if auraDisplays:GetGroupVisual(displayID, groupID, 'showDurationText') then
        append(fields, self:MakeTextFields(displayID, groupID, 'duration', 'Duration Text', { skipTitle = true }))
    end

    append(fields, {
        { type = 'title', label = 'Dispel', width = 100 },
        {
            type = 'toggle',
            label = 'Show Dispel Border',
            name = 'showDispelBorder',
            width = 100,
            currentValue = function() return auraDisplays:GetGroupVisual(displayID, groupID, 'showDispelBorder') end,
            onChange = function(v)
                auraDisplays:UpdateGroupVisual(displayID, groupID, 'showDispelBorder', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
    })

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
