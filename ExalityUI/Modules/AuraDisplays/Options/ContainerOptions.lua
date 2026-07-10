---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIAuraDisplaysDefaults
local defaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUIAuraDisplaysModule
local auraDisplays = EXUI:GetModule('aura-displays')

---@class EXUIAuraDisplaysUnitResolver
local unitResolver = EXUI:GetModule('aura-displays-unit-resolver')

---@class EXUIAuraDisplaysContainerOptions
local containerOptions = EXUI:GetModule('aura-displays-container-options')

local function append(target, source)
    for _, field in ipairs(source) do
        table.insert(target, field)
    end
end

function containerOptions:GetOptions(displayID)
    local fields = {}

    append(fields, {
        { type = 'title', label = 'Display', width = 100 },
        {
            type = 'toggle', label = 'Enable', name = 'enable', width = 100,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'enable') end,
            onChange = function(v) auraDisplays:UpdateDisplayValue(displayID, 'enable', v); auraDisplays:RefreshDisplay(displayID) end,
        },
        {
            type = 'edit-box', label = 'Name', name = 'name', width = 100,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'name') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'name', v)
                auraDisplays:RefreshDisplay(displayID)
                optionsFields:RefreshItemList()
            end,
        },
        { type = 'title', label = 'Tracking', width = 100 },
        {
            type = 'dropdown',
            label = 'Unit',
            name = 'unit',
            width = 100,
            getOptions = function() return defaults.UNIT_OPTIONS end,
            currentValue = function()
                local display = auraDisplays:GetDisplay(displayID)
                return unitResolver:GetContainerUnitSelection(display and display.container)
            end,
            onChange = function(v)
                auraDisplays:UpdateContainerValue(displayID, 'unit', v)
                if v ~= unitResolver.CUSTOM then
                    auraDisplays:UpdateContainerValue(displayID, 'unitCustom', '')
                end
                auraDisplays:RefreshDisplay(displayID)
                optionsFields:RefreshOptions()
            end,
        },
        {
            type = 'edit-box',
            label = 'Custom Unit',
            name = 'unitCustom',
            width = 100,
            depends = function()
                local display = auraDisplays:GetDisplay(displayID)
                return unitResolver:GetContainerUnitSelection(display and display.container) == unitResolver.CUSTOM
            end,
            currentValue = function()
                local unit = auraDisplays:GetContainerValue(displayID, 'unit')
                if unit == unitResolver.CUSTOM then
                    return auraDisplays:GetContainerValue(displayID, 'unitCustom') or ''
                end
                if unitResolver:IsKnownUnitKey(unit) or unit == unitResolver.CO_TANK then
                    return ''
                end
                return unit or ''
            end,
            onChange = function(v)
                auraDisplays:UpdateContainerValue(displayID, 'unit', unitResolver.CUSTOM)
                auraDisplays:UpdateContainerValue(displayID, 'unitCustom', v)
                auraDisplays:RefreshDisplay(displayID)
            end,
        },
        { type = 'title', label = 'Layout',   width = 100 },
        {
            type = 'anchor-point',
            label = 'Layout Anchor',
            name = 'containerAnchorPoint',
            width = 25,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'containerAnchorPoint') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'containerAnchorPoint', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Grow Horizontal',
            name = 'horizontalGrowth',
            width = 25,
            getOptions = function() return { LEFT = 'Left', RIGHT = 'Right' } end,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'horizontalGrowth') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'horizontalGrowth', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Grow Vertical',
            name = 'verticalGrowth',
            width = 25,
            getOptions = function() return { UP = 'Up', DOWN = 'Down' } end,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'verticalGrowth') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'verticalGrowth', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Row Width (0=unlimited)',
            name = 'rowWidth',
            min = 1, -- TODO: Don't allow 0 for now, causes crash
            max = 1000,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'rowWidth') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'rowWidth', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Padding Left',
            name = 'paddingLeft',
            min = 0,
            max = 100,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'paddingLeft') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'paddingLeft', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Padding Right',
            name = 'paddingRight',
            min = 0,
            max = 100,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'paddingRight') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'paddingRight', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Padding Top',
            name = 'paddingTop',
            min = 0,
            max = 100,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'paddingTop') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'paddingTop', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Padding Bottom',
            name = 'paddingBottom',
            min = 0,
            max = 100,
            step = 1,
            width = 25,
            currentValue = function() return auraDisplays:GetDisplayValue(displayID, 'paddingBottom') end,
            onChange = function(v)
                auraDisplays:UpdateDisplayValue(displayID, 'paddingBottom', v); auraDisplays:RefreshDisplay(displayID)
            end,
        },
        { type = 'title', label = 'Item Enchants', width = 100 },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'itemEnchantEnable',
            width = 100,
            currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantEnable') end,
            onChange = function(v)
                auraDisplays:UpdateContainerValue(displayID, 'itemEnchantEnable', v); auraDisplays:RefreshDisplay(
                    displayID); optionsFields:RefreshOptions()
            end,
        },
    })

    if auraDisplays:GetContainerValue(displayID, 'itemEnchantEnable') then
        append(fields, {
            {
                type = 'toggle',
                label = 'Hide Permanent',
                name = 'itemEnchantHidePermanent',
                width = 50,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantHidePermanent') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantHidePermanent', v); auraDisplays
                        :RefreshDisplay(displayID)
                end,
            },
            {
                type = 'dropdown',
                label = 'Placement',
                name = 'itemEnchantPlacement',
                width = 50,
                getOptions = function() return { BeforeAuraGroups = 'Before Groups', AfterAuraGroups = 'After Groups' } end,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantPlacement') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantPlacement', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'toggle',
                label = 'Main Hand',
                name = 'itemEnchantMainHand',
                width = 33,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantMainHand') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantMainHand', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'toggle',
                label = 'Off Hand',
                name = 'itemEnchantOffHand',
                width = 33,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantOffHand') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantOffHand', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'toggle',
                label = 'Ranged',
                name = 'itemEnchantRanged',
                width = 33,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantRanged') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantRanged', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'range',
                label = 'Spacing X',
                name = 'itemEnchantSpacingX',
                min = 0,
                max = 50,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantSpacingX') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantSpacingX', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'range',
                label = 'Spacing Y',
                name = 'itemEnchantSpacingY',
                min = 0,
                max = 50,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantSpacingY') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantSpacingY', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'range',
                label = 'Gap X',
                name = 'itemEnchantGapX',
                min = 0,
                max = 50,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantGapX') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantGapX', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'range',
                label = 'Gap Y',
                name = 'itemEnchantGapY',
                min = 0,
                max = 50,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantGapY') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantGapY', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'range',
                label = 'Width (0=auto)',
                name = 'itemEnchantWidth',
                min = 0,
                max = 100,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantWidth') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantWidth', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
            {
                type = 'range',
                label = 'Height (0=auto)',
                name = 'itemEnchantHeight',
                min = 0,
                max = 100,
                step = 1,
                width = 25,
                currentValue = function() return auraDisplays:GetContainerValue(displayID, 'itemEnchantHeight') end,
                onChange = function(v)
                    auraDisplays:UpdateContainerValue(displayID, 'itemEnchantHeight', v); auraDisplays:RefreshDisplay(
                        displayID)
                end,
            },
        })
    end

    return fields
end
