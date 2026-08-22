---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUINameplatesCustomTexts
local ctCore = EXUI:GetModule('np-custom-texts')

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUINameplatesCustomTextsEditor
local editor = EXUI:GetModule('np-custom-texts-editor')

editor.window = nil
editor.fields = {}
editor.currentID = nil

editor.CreateWindow = function(self)
    return EXFrames:GetFrame('window-frame'):Create({
        size = { 500, 600 },
        title = 'Custom Text Editor',
    })
end

editor.GetOptions = function(self, id)
    return {
        { type = 'title', width = 100, label = 'Font Style', size = 18 },
        {
            type = 'dropdown',
            label = 'Font',
            name = 'font',
            isFontDropdown = true,
            getOptions = function()
                local options = {}
                for _, font in ipairs(LSM:List('font')) do
                    options[font] = font
                end
                return options
            end,
            currentValue = function() return ctCore:GetValue(id, 'font') end,
            onChange = function(value)
                ctCore:UpdateValue(id, 'font', value)
                npCore:UpdateAllPlates()
            end,
            width = 50,
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'fontFlag',
            getOptions = function() return EXUI.const.fontFlags end,
            currentValue = function() return ctCore:GetValue(id, 'fontFlag') end,
            onChange = function(value)
                ctCore:UpdateValue(id, 'fontFlag', value)
                npCore:UpdateAllPlates()
            end,
            width = 50,
        },
        {
            type = 'range',
            label = 'Size',
            name = 'fontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 50,
            currentValue = function() return ctCore:GetValue(id, 'fontSize') end,
            onChange = function(value)
                ctCore:UpdateValue(id, 'fontSize', value)
                npCore:UpdateAllPlates()
            end,
        },
        {
            type = 'color-picker',
            label = 'Color',
            name = 'fontColor',
            currentValue = function() return ctCore:GetValue(id, 'fontColor') end,
            onChange = function(value)
                ctCore:UpdateValue(id, 'fontColor', value)
                npCore:UpdateAllPlates()
            end,
            width = 50,
        },
        { type = 'title', width = 100, label = 'Position', size = 18 },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'anchorPoint',
            currentValue = function() return ctCore:GetValue(id, 'anchorPoint') end,
            onChange = function(value)
                ctCore:UpdateValue(id, 'anchorPoint', value)
                npCore:UpdateAllPlates()
            end,
            width = 50,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'relativeAnchorPoint',
            currentValue = function() return ctCore:GetValue(id, 'relativeAnchorPoint') end,
            onChange = function(value)
                ctCore:UpdateValue(id, 'relativeAnchorPoint', value)
                npCore:UpdateAllPlates()
            end,
            width = 50,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'XOffset',
            min = -1000,
            max = 1000,
            step = 1,
            width = 50,
            currentValue = function() return ctCore:GetValue(id, 'XOffset') end,
            onChange = function(value)
                ctCore:UpdateValue(id, 'XOffset', value)
                npCore:UpdateAllPlates()
            end,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'YOffset',
            min = -1000,
            max = 1000,
            step = 1,
            width = 50,
            currentValue = function() return ctCore:GetValue(id, 'YOffset') end,
            onChange = function(value)
                ctCore:UpdateValue(id, 'YOffset', value)
                npCore:UpdateAllPlates()
            end,
        },
        { type = 'title', width = 100, label = 'Tag', size = 18 },
        {
            type = 'edit-box',
            label = 'Tag',
            name = 'tag',
            currentValue = function() return ctCore:GetValue(id, 'tag') end,
            onChange = function(value)
                ctCore:UpdateValue(id, 'tag', value)
                npCore:UpdateAllPlates()
            end,
            width = 50,
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
            tooltip = { text = 'Available tags' },
            color = { 3 / 255, 140 / 255, 252 / 255, 1 },
            width = 12,
        },
    }
end

editor.Populate = function(self, id)
    for _, field in ipairs(self.fields) do
        field:Destroy()
    end
    wipe(self.fields)
    for _, option in ipairs(self:GetOptions(id)) do
        local field = EXUI:GetModule('options-fields'):GetField(option)
        EXUI:GetModule('options-fields'):CreateOrUpdateTooltip(field, option.tooltip)
        if field then
            field:SetOptionData(option)
            field:SetParent(self.window.container)
            table.insert(self.fields, field)
        end
    end
    EXUI.utils.organizeFramesInGrid('np-custom-text-editor-fields', self.fields, 10, self.window.container, 10, 10)
end

editor.Show = function(self, id)
    if not self.window then
        self.window = self:CreateWindow()
    end
    if not ctCore:Get(id) then
        return
    end
    self.currentID = id
    self:Populate(id)
    self.window:ShowWindow()
end
