---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

local function refreshEditorOptions()
    local editor = EXUI:GetModule('np-aura-editor')
    if editor and editor.RefreshOptions then
        editor:RefreshOptions()
    end
end

local function refreshEditorList()
    local editor = EXUI:GetModule('np-aura-editor')
    if editor and editor.RefreshItemList then
        editor:RefreshItemList()
    end
end

---@class EXUINameplatesAuras
local ufAuras = EXUI:GetModule('np-auras')

---@class EXUINameplatesAurasDefaults
local defaults = EXUI:GetModule('np-auras-defaults')

---@class EXUINPAuraEditorContainerOptions
local containerOptions = EXUI:GetModule('np-aura-editor-container-options')

local append = EXUI.utils.append

local function refreshDisplayAndList(displayID)
    -- Unit / enable / name changes can move displays between Active/Inactive and
    -- must update frames that lost the assignment.
    ufAuras:RefreshAll()
    ufAuras:RefreshEditorList()
end

function containerOptions:GetOptions(displayID)
    local fields = {}

    append(fields, {
        { type = 'title', label = 'Display', width = 100 },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            width = 100,
            currentValue = function()
                return ufAuras:GetDisplayValue(displayID, 'enable')
            end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'enable', v)
                refreshDisplayAndList(displayID)
            end,
        },
        {
            type = 'edit-box',
            label = 'Name',
            name = 'name',
            width = 100,
            currentValue = function()
                return ufAuras:GetDisplayValue(displayID, 'name')
            end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'name', v)
                refreshDisplayAndList(displayID)
            end,
        },
    })

    append(fields, {
        { type = 'title', label = 'Position on Nameplate', width = 100 },
        {
            type = 'anchor-point',
            label = 'Aura Anchor',
            name = 'anchorPoint',
            width = 25,
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'anchorPoint') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'anchorPoint', v)
                ufAuras:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'anchor-point',
            label = 'UnitFrame',
            name = 'relativePoint',
            width = 25,
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'relativePoint') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'relativePoint', v)
                ufAuras:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'X',
            name = 'XOff',
            min = -500,
            max = 500,
            step = 1,
            width = 25,
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'XOff') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'XOff', v)
                ufAuras:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Y',
            name = 'YOff',
            min = -500,
            max = 500,
            step = 1,
            width = 25,
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'YOff') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'YOff', v)
                ufAuras:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Frame Strata',
            name = 'frameStrata',
            width = 50,
            getOptions = function()
                return EXUI.const.frameStrata
            end,
            currentValue = function()
                return ufAuras:GetDisplayValue(displayID, 'frameStrata') or 'MEDIUM'
            end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'frameStrata', v)
                ufAuras:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Frame Level',
            name = 'frameLevel',
            min = 0,
            max = 200,
            step = 1,
            width = 50,
            tooltip = 'Offset above the unit frame overlay (border). Default 10 keeps auras above the border.',
            currentValue = function()
                local value = ufAuras:GetDisplayValue(displayID, 'frameLevel')
                if value == nil then
                    return 10
                end
                return value
            end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'frameLevel', v)
                ufAuras:RefreshDisplay(displayID)
            end,
        },
        { type = 'title', label = 'Layout', width = 100 },
        {
            type = 'anchor-point',
            label = 'Layout Anchor',
            name = 'containerAnchorPoint',
            width = 25,
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'containerAnchorPoint') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'containerAnchorPoint', v)
                ufAuras:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Layout Axis',
            name = 'flowLayoutAxis',
            width = 25,
            getOptions = function() return { Rows = 'Rows', Columns = 'Columns' } end,
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'flowLayoutAxis') or 'Rows' end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'flowLayoutAxis', v)
                ufAuras:RefreshDisplay(displayID)
                refreshEditorOptions()
            end,
        },
        {
            type = 'dropdown',
            label = 'Grow Horizontal',
            name = 'horizontalGrowth',
            width = 25,
            getOptions = function() return { LEFT = 'Left', RIGHT = 'Right' } end,
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'horizontalGrowth') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'horizontalGrowth', v)
                ufAuras:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Grow Vertical',
            name = 'verticalGrowth',
            width = 25,
            getOptions = function() return { UP = 'Up', DOWN = 'Down' } end,
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'verticalGrowth') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'verticalGrowth', v)
                ufAuras:RefreshDisplay(displayID)
            end,
        },
        {
            type = 'toggle',
            label = 'Match Unit Frame Width',
            name = 'matchUnitFrameWidth',
            width = 100,
            currentValue = function()
                local value = ufAuras:GetDisplayValue(displayID, 'matchUnitFrameWidth')
                return value ~= false
            end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'matchUnitFrameWidth', v and true or false)
                ufAuras:RefreshDisplay(displayID)
                refreshEditorOptions()
            end,
        },
        {
            type = 'range',
            label = 'Max Line Size',
            name = 'rowWidth',
            min = 1,
            max = 1000,
            step = 1,
            width = 100,
            tooltip = {
                text = 'Maximum size along the primary layout axis before wrapping (row width for Rows, column height for Columns).',
            },
            depends = function()
                return ufAuras:GetDisplayValue(displayID, 'matchUnitFrameWidth') == false
            end,
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'rowWidth') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'rowWidth', v)
                ufAuras:RefreshDisplay(displayID)
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
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'paddingLeft') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'paddingLeft', v)
                ufAuras:RefreshDisplay(displayID)
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
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'paddingRight') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'paddingRight', v)
                ufAuras:RefreshDisplay(displayID)
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
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'paddingTop') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'paddingTop', v)
                ufAuras:RefreshDisplay(displayID)
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
            currentValue = function() return ufAuras:GetDisplayValue(displayID, 'paddingBottom') end,
            onChange = function(v)
                ufAuras:UpdateDisplayValue(displayID, 'paddingBottom', v)
                ufAuras:RefreshDisplay(displayID)
            end,
        },
        { type = 'title', label = 'Item Enchants', width = 100 },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'itemEnchantEnable',
            width = 100,
            currentValue = function() return ufAuras:GetContainerValue(displayID, 'itemEnchantEnable') end,
            onChange = function(v)
                ufAuras:UpdateContainerValue(displayID, 'itemEnchantEnable', v)
                ufAuras:RefreshDisplay(displayID)
                local editor = EXUI:GetModule('np-aura-editor')
                if editor and editor.RefreshOptions then
                    editor:RefreshOptions()
                end
            end,
        },
    })

    if ufAuras:GetContainerValue(displayID, 'itemEnchantEnable') then
        append(fields, {
            {
                type = 'toggle',
                label = 'Hide Permanent',
                name = 'itemEnchantHidePermanent',
                width = 100,
                currentValue = function() return ufAuras:GetContainerValue(displayID, 'itemEnchantHidePermanent') end,
                onChange = function(v)
                    ufAuras:UpdateContainerValue(displayID, 'itemEnchantHidePermanent', v)
                    ufAuras:RefreshDisplay(displayID)
                end,
            },
            {
                type = 'dropdown',
                label = 'Placement',
                name = 'itemEnchantPlacement',
                width = 50,
                getOptions = function()
                    return { BeforeAuraGroups = 'Before Groups', AfterAuraGroups = 'After Groups' }
                end,
                currentValue = function() return ufAuras:GetContainerValue(displayID, 'itemEnchantPlacement') end,
                onChange = function(v)
                    ufAuras:UpdateContainerValue(displayID, 'itemEnchantPlacement', v)
                    ufAuras:RefreshDisplay(displayID)
                end,
            },
            {
                type = 'toggle',
                label = 'Main Hand',
                name = 'itemEnchantMainHand',
                width = 33,
                currentValue = function() return ufAuras:GetContainerValue(displayID, 'itemEnchantMainHand') end,
                onChange = function(v)
                    ufAuras:UpdateContainerValue(displayID, 'itemEnchantMainHand', v)
                    ufAuras:RefreshDisplay(displayID)
                end,
            },
            {
                type = 'toggle',
                label = 'Off Hand',
                name = 'itemEnchantOffHand',
                width = 33,
                currentValue = function() return ufAuras:GetContainerValue(displayID, 'itemEnchantOffHand') end,
                onChange = function(v)
                    ufAuras:UpdateContainerValue(displayID, 'itemEnchantOffHand', v)
                    ufAuras:RefreshDisplay(displayID)
                end,
            },
            {
                type = 'toggle',
                label = 'Ranged',
                name = 'itemEnchantRanged',
                width = 33,
                currentValue = function() return ufAuras:GetContainerValue(displayID, 'itemEnchantRanged') end,
                onChange = function(v)
                    ufAuras:UpdateContainerValue(displayID, 'itemEnchantRanged', v)
                    ufAuras:RefreshDisplay(displayID)
                end,
            },
        })
    end

    return fields
end
