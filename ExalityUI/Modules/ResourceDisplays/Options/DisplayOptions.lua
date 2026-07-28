---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysDisplayOptions
local displayOptions = EXUI:GetModule('resource-displays-display-options')

local append = EXUI.utils.append

function displayOptions:GetOptions(displayID)
    local currentItem = core:GetDBByDisplayID(displayID)
    if not currentItem or next(currentItem) == nil then
        return {}
    end

    local isSelfControlledSize = core:IsSelfControlledSize(currentItem.resourceType)
    local fields = {
        {
            type = 'title',
            label = isSelfControlledSize and 'Position' or 'Size & Position',
            size = 14,
            width = 100,
        },
    }

    if not isSelfControlledSize then
        append(fields, {
            {
                type = 'range',
                label = 'Width',
                name = 'width',
                min = 1,
                max = 1000,
                step = 1,
                width = 20,
                currentValue = function()
                    return core:GetValueForDisplay(displayID, 'width')
                end,
                onChange = function(value)
                    core:UpdateValueForDisplay(displayID, 'width', value)
                    core:RefreshDisplayByID(displayID)
                end,
            },
            {
                type = 'range',
                label = 'Height',
                name = 'height',
                min = 1,
                max = 100,
                step = 1,
                width = 20,
                currentValue = function()
                    return core:GetValueForDisplay(displayID, 'height')
                end,
                onChange = function(value)
                    core:UpdateValueForDisplay(displayID, 'height', value)
                    core:RefreshDisplayByID(displayID)
                end,
            },
            {
                type = 'spacer',
                width = 60,
            },
        })
    end

    append(fields, {
        {
            type = 'range',
            label = 'Scale',
            name = 'scale',
            min = 0.5,
            max = 2,
            step = 0.05,
            width = 20,
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'scale') or 1
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'scale', value)
                core:RefreshDisplayByID(displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Frame Strata',
            name = 'frameStrata',
            getOptions = function()
                return {
                    BACKGROUND = { label = 'Background', order = 1 },
                    LOW = { label = 'Low', order = 2 },
                    MEDIUM = { label = 'Medium', order = 3 },
                    HIGH = { label = 'High', order = 4 },
                    DIALOG = { label = 'Dialog', order = 5 },
                }
            end,
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'frameStrata') or 'MEDIUM'
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'frameStrata', value)
                core:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'range',
            label = 'Frame Level',
            name = 'frameLevel',
            min = 1,
            max = 500,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'frameLevel') or 100
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'frameLevel', value)
                core:RefreshDisplayByID(displayID)
            end,
        },
        {
            type = 'spacer',
            width = 35,
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'anchorPoint',
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'anchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'anchorPoint', value)
                core:RefreshDisplayByID(displayID)
            end,
            width = 23,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'relativeAnchorPoint',
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'relativeAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'relativeAnchorPoint', value)
                core:RefreshDisplayByID(displayID)
            end,
            width = 23,
        },
        {
            type = 'spacer',
            width = 54,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'XOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'XOff')
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'XOff', value)
                core:RefreshDisplayByID(displayID)
            end,
            width = 23,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'positionYOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'YOff')
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'YOff', value)
                core:RefreshDisplayByID(displayID)
            end,
            width = 23,
        },
        {
            type = 'title',
            label = 'Visibility',
            size = 14,
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'Show When',
            name = 'visibilityRule',
            getOptions = function()
                return {
                    always = 'Always',
                    inCombat = 'In Combat',
                    withTarget = 'With Target',
                    combatOrTarget = 'Combat or Target',
                    hidden = 'Hidden',
                }
            end,
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'visibilityRule') or 'always'
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'visibilityRule', value)
                core:RefreshDisplayByID(displayID)
            end,
            width = 50,
        },
        {
            type = 'toggle',
            label = 'Fade On Show',
            name = 'fadeOnHide',
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'fadeOnHide')
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'fadeOnHide', value)
                core:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
    })

    local control = core:GetPowerTypeControl(currentItem.resourceType)
    if control then
        append(fields, control:GetOptions(displayID))
    end

    return fields
end
