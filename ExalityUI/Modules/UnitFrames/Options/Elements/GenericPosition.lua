---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsGenericPosition
local genericPosition = EXUI:GetModule('uf-options-generic-position')

-- Matches where each element sits when nothing has been set
local DEFAULT_FRAME_LEVELS = {
    raidRoles = 1,
    portrait = 5,
}

genericPosition.GetOptions = function(self, unit, prefix, hideFrameLevel)
    local fields = {
        {
            type = 'title',
            width = 100,
            label = 'Position',
            size = 18
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = prefix .. 'AnchorPoint',
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'AnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'AnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = prefix .. 'RelativeAnchorPoint',
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'RelativeAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'RelativeAnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'spacer',
            width = 54
        },
        {
            type = 'range',
            label = 'X Offset',
            name = prefix .. 'XOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'XOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'XOff', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = prefix .. 'YOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'YOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'YOff', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        }
    }

    if not hideFrameLevel then
        table.insert(fields, {
            type = 'range',
            label = 'Frame Level',
            name = prefix .. 'FrameLevel',
            min = 0,
            max = 50,
            step = 1,
            width = 23,
            tooltip = { text = 'Offset above the unit frame overlay (border). Shaped portraits sit at 5-7 by default.' },
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'FrameLevel') or DEFAULT_FRAME_LEVELS[prefix] or 0
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'FrameLevel', value)
                core:UpdateFrameForUnit(unit)
            end
        })
    end

    return fields
end
