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
            type = 'button',
            icon = {
                file = EXUI.const.textures.frame.icons.info,
                width = 16,
                height = 16,
            },
            onClick = function()
                EXUI:GetModule('uf-options-tags-info'):Show()
            end,
            tooltip = {
                text = 'Available tags'
            },
            color = { 3 / 255, 140 / 255, 252 / 255, 1 },
            width = 8
        },
        {
            type = 'spacer',
            width = 67
        }
    }
end
