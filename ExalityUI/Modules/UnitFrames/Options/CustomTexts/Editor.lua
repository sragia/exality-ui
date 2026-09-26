---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIUnitFramesCustomTexts
local ctCore = EXUI:GetModule('uf-custom-texts')

---@class EXUIUnitFramesCore
local UFCore = EXUI:GetModule('uf-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

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
    local fields = {
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
    }

    for _, field in ipairs(EXUI.utils.fontShadowFields(
        'font',
        function(key)
            return ctCore:GetValue(unit, id, key)
        end,
        function(key, value)
            ctCore:UpdateValue(unit, id, key, value)
            UFCore:UpdateFrameForUnit(unit)
        end,
        50,
        function()
            C_Timer.After(0, function()
                if self.window and self.window:IsShown() then
                    self:Populate(unit, id)
                end
            end)
        end
    )) do
        table.insert(fields, field)
    end

    for _, field in ipairs({
        {
            type = 'title',
            width = 100,
            label = 'Position',
            size = 18
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'anchorPoint',
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
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'relativeAnchorPoint',
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
    }) do
        table.insert(fields, field)
    end
    return fields
end

editor.EnsureScroll = function(self)
    if self.scroll then
        return self.scroll
    end
    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scroll:SetParent(self.window.container)
    scroll:SetAllPoints()
    scroll:SetFrameLevel(self.window.container:GetFrameLevel() + 5)
    scroll.child.exuiAutoSizeHeight = true
    self.scroll = scroll
    return scroll
end

editor.GetLayoutWidth = function(self)
    local scroll = self.scroll
    local width = scroll and scroll:GetWidth() or 0
    if width < 64 then
        local container = self.window and self.window.container
        width = container and container:GetWidth() or 0
    end
    if width < 64 then
        width = 480
    end
    return math.max(1, width - 20)
end

editor.UpdateScroll = function(self)
    local scroll = self.scroll
    local root = self.layoutRoot
    if not scroll or not root then
        return
    end
    local width = self:GetLayoutWidth()
    root:SetWidth(width)
    root:Layout()
    local child = scroll.child
    child:SetHeight(math.max(1, root:GetHeight()))
    scroll:UpdateScrollChild(width, child:GetHeight())
end

editor.ClearFields = function(self)
    self._optionsMountHost = nil
    if self.layoutRoot then
        self.layoutRoot:Destroy()
        self.layoutRoot = nil
    end
    for _, field in ipairs(self.fields) do
        optionsFields:ReleaseField(field)
    end
    wipe(self.fields)
end

editor.Populate = function(self, unit, id)
    self:ClearFields()
    local scroll = self:EnsureScroll()
    local child = scroll.child
    local width = self:GetLayoutWidth()
    self._optionsMountHost = {
        container = child,
        getWidth = function()
            return self:GetLayoutWidth()
        end,
        updateScroll = function()
            self:UpdateScroll()
        end,
    }
    self.layoutRoot = optionsFields:MountOptionsOnContainer(
        child,
        self:GetOptions(unit, id),
        width,
        self.fields,
        string.format('UF Custom Text Editor:%s:%s', unit or '', id or ''),
        self._optionsMountHost
    )
    self:UpdateScroll()
end

editor.Show = function(self, unit, id, listItem)
    if (not self.window) then
        self.window = self:CreateWindow()
    end
    local db = ctCore:Get(unit, id)
    if (not db) then return EXUI.utils.printOut('Custom text not found for unit: ' .. unit .. ' and id: ' .. id) end
    self.currentListItem = listItem
    self.currentUnit = unit
    self.currentID = id
    self.window:ShowWindow()
    self:Populate(unit, id)
    C_Timer.After(0, function()
        if self.window and self.window:IsShown() and self.currentUnit == unit and self.currentID == id then
            self:UpdateScroll()
        end
    end)
end
