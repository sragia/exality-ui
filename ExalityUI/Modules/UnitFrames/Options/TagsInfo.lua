---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIoUFTags
local tags = EXUI:GetModule('oUF-Tags')

---@class EXUIUnitFramesOptionsTagsInfo
local tagsInfo = EXUI:GetModule('uf-options-tags-info')

tagsInfo.window = nil

local function CreateItem(tagName, parent)
    local item = CreateFrame('Frame', nil, parent)
    item:SetHeight(20)
    local modifiedTag = string.format('[%s]', tagName)
    local editBox
    local function onChange()
        editBox:SetEditorValue(modifiedTag) -- Prevent changing
    end
    editBox = EXFrames:GetFrame('edit-box-input'):Create({
        label = '',
        initial = modifiedTag,
        onChange = onChange
    }, item)
    editBox:SetHeight(40)
    editBox:SetWidth(160)
    editBox:SetPoint('LEFT')

    if (tags.DESCRIPTIONS[tagName]) then
        local description = item:CreateFontString(nil, 'OVERLAY')
        description:SetFont(EXFrames.assets.font.default(), 10, 'OUTLINE')
        description:SetText(tags.DESCRIPTIONS[tagName])
        description:SetPoint('LEFT', editBox, 'RIGHT', 10, -7)
        description:SetWidth(0)
        item.description = description
    end
    item:Show()
    return item
end


tagsInfo.Create = function(self)
    self.window = EXFrames:GetFrame('window-frame'):Create({
        size = { 600, 600 },
        title = 'Tags Info'
    })
    local container = self.window.container
    local scrollFrame = EXFrames:GetFrame('scroll-frame'):Create()
    scrollFrame:SetParent(container)
    scrollFrame:SetPoint('TOPLEFT', 0, -10)
    scrollFrame:SetPoint('BOTTOMRIGHT', -30, 10)
    self.window.scrollFrame = scrollFrame

    local child = scrollFrame.child

    local items = {}

    for tagName in pairs(EXUI.oUF.Tags.Events) do
        table.insert(items, CreateItem(tagName, child))
    end

    EXUI.utils.organizeFramesInList(items, 10, child)
end

tagsInfo.Show = function(self)
    if (not self.window) then
        self:Create()
    end

    self.window:ShowWindow()
    self.window.scrollFrame:UpdateScrollChild(self.window.container:GetWidth() - 30,
        self.window.container:GetHeight() - 20)
end
