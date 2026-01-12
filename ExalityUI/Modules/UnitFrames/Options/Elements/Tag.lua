---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsTag
local tag = EXUI:GetModule('uf-options-tag')

tag.GetOptions = function(self, unit, prefix)
    return {
        {
            type = 'title',
            width = 100,
            label = 'Tag',
            size = 18
        },
        {
            type = 'edit-box',
            label = 'Tag',
            name = prefix .. 'Tag',
            currentValue = function()
                return core:GetValueForUnit(unit, prefix .. 'Tag')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, prefix .. 'Tag', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 25
        },
        {
            type = 'spacer',
            width = 75
        }
    }
end
