---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIUnitFramesCustomTexts
local ctCore = EXUI:GetModule('uf-custom-texts')

---@class EXUIUnitFramesCore
local UFCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsCore
local optionsCore = EXUI:GetModule('uf-options-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIUnitFramesOptionsCustomTextsEditor
local editor = EXUI:GetModule('custom-texts-editor')

editor.window = nil
editor.currentListItem = nil
editor.fields = {}

editor.CreateWindow = function(self)
    local window = EXFrames:GetFrame('window-frame'):Create({
        size = { 500, 600 },
        title = 'Custom Text Editor'
    })

    return window
end

editor.GetOptions = function(self, unit, id)
    return {
        {
            type = 'title',
            width = 100,
            label = 'Font Style',
            size = 18
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = 'font',
            getOptions = function()
                local fonts = LSM:List('font')
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            currentValue = function()
                return ctCore:GetValue(unit, id, 'font')
            end,
            onChange = function(value)
                ctCore:UpdateValue(unit, id, 'font', value)
                UFCore:UpdateFrameForUnit(unit)
            end,
            width = 50
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'fontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return ctCore:GetValue(unit, id, 'fontFlag')
            end,
            onChange = function(value)
                ctCore:UpdateValue(unit, id, 'fontFlag', value)
                UFCore:UpdateFrameForUnit(unit)
            end,
            width = 50
        },
        {
            type = 'range',
            label = 'Size',
            name = 'fontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 50,
            currentValue = function()
                return ctCore:GetValue(unit, id, 'fontSize')
            end,
            onChange = function(value)
                ctCore:UpdateValue(unit, id, 'fontSize', value)
                UFCore:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'color-picker',
            label = 'Color',
            name = 'fontColor',
            currentValue = function()
                return ctCore:GetValue(unit, id, 'fontColor')
            end,
            onChange = function(value)
                ctCore:UpdateValue(unit, id, 'fontColor', value)
                UFCore:UpdateFrameForUnit(unit)
            end,
            width = 50
        },
        {
            type = 'title',
            width = 100,
            label = 'Position',
            size = 18
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = 'anchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return ctCore:GetValue(unit, id, 'anchorPoint')
            end,
            onChange = function(value)
                ctCore:UpdateValue(unit, id, 'anchorPoint', value)
                UFCore:UpdateFrameForUnit(unit)
            end,
            width = 50
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'relativeAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return ctCore:GetValue(unit, id, 'relativeAnchorPoint')
            end,
            onChange = function(value)
                ctCore:UpdateValue(unit, id, 'relativeAnchorPoint', value)
                UFCore:UpdateFrameForUnit(unit)
            end,
            width = 50
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'XOffset',
            min = -1000,
            max = 1000,
            step = 1,
            width = 50,
            currentValue = function()
                return ctCore:GetValue(unit, id, 'XOffset')
            end,
            onChange = function(value)
                ctCore:UpdateValue(unit, id, 'XOffset', value)
                UFCore:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'YOffset',
            min = -1000,
            max = 1000,
            step = 1,
            width = 50,
            currentValue = function()
                return ctCore:GetValue(unit, id, 'YOffset')
            end,
            onChange = function(value)
                ctCore:UpdateValue(unit, id, 'YOffset', value)
                UFCore:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'title',
            width = 100,
            label = 'Tag',
            size = 18
        },
        {
            type = 'edit-box',
            label = 'Tag',
            name = 'tag',
            currentValue = function()
                return ctCore:GetValue(unit, id, 'tag')
            end,
            onChange = function(value)
                ctCore:UpdateValue(unit, id, 'tag', value)
                UFCore:UpdateFrameForUnit(unit)
                self.currentListItem:RefreshTag()
            end,
            width = 50
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
            width = 12
        },
        {
            type = 'spacer',
            width = 67
        }
    }
end

editor.Populate = function(self, unit, id)
    for _, field in ipairs(self.fields) do
        field:Destroy()
    end
    wipe(self.fields)
    local options = self:GetOptions(unit, id)
    for _, option in ipairs(options) do
        local field = EXUI:GetModule('options-fields'):GetField(option)
        EXUI:GetModule('options-fields'):CreateOrUpdateTooltip(field, option.tooltip)
        if (field) then
            field:SetOptionData(option)
            field:SetParent(self.window.container)
            table.insert(self.fields, field)
        end
    end
    EXUI.utils.organizeFramesInGrid('custom-text-editor-fields', self.fields, 10, self.window.container, 10, 10)
end

editor.Show = function(self, unit, id, listItem)
    if (not self.window) then
        self.window = self:CreateWindow()
    end
    local db = ctCore:Get(unit, id)
    if (not db) then return EXUI.utils.printOut('Custom text not found for unit: ' .. unit .. ' and id: ' .. id) end
    self.currentListItem = listItem
    self:Populate(unit, id)
    self.window:ShowWindow()
end
