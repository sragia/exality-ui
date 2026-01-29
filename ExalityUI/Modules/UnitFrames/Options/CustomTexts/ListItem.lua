---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIUnitFramesCustomTexts
local ctCore = EXUI:GetModule('uf-custom-texts')

---@class EXUIUnitFramesCore
local UFCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsCustomTextsListItem
local listItem = EXUI:GetModule('custom-texts-list-item')

listItem.pool = nil

listItem.Init = function(self)
    self.pool = CreateFramePool('Frame', UIParent)
end

local function ConfigureFrame(f)
    f:SetHeight(35)

    local bg = f:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXFrames.assets.textures.input.buttonBg)
    bg:SetTextureSliceMargins(10, 10, 10, 10)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetVertexColor(0.2, 0.2, 0.2, 1)
    bg:SetAllPoints()
    f.bg = bg

    local tagText = f:CreateFontString(nil, 'OVERLAY')
    tagText:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    tagText:SetPoint('LEFT', 10, 0)
    tagText:SetWidth(0)
    f.tagText = tagText

    f.dialog = EXFrames:GetFrame('dialog-frame'):Create({
        size = { 400, 80 },
        title = 'Delete Custom Text'
    })
    f.dialog:SetText('Are you sure you want to delete this custom text?')

    local deleteButton = EXFrames:GetFrame('button'):Create({
        text = 'Delete',
        onClick = function(self)
            self:GetParent().dialog:SetButtons({
                {
                    text = 'Yes',
                    onClick = function()
                        ctCore:Delete(self.customTexts.unit, self.customTexts.id)
                        EXUI:GetModule('uf-options-core'):RefreshCurrentView()
                        self:GetParent().dialog:Hide()
                        UFCore:UpdateFrameForUnit(self.customTexts.unit)
                    end,
                    color = EXUI.const.colors.red
                },
                {
                    text = 'No',
                    onClick = function()
                        self:GetParent().dialog:Hide()
                    end,
                    color = EXUI.const.colors.gray
                }
            })
            self:GetParent().dialog:ShowDialog()
        end,
        size = { 70, 25 },
        color = { 171 / 255, 0, 20 / 255, 1 }
    }, f)
    deleteButton:SetPoint('RIGHT', -10, 0)
    f.DeleteButton = deleteButton

    local editButton = EXFrames:GetFrame('button'):Create({
        text = 'Edit',
        onClick = function(self)
            EXUI:GetModule('custom-texts-editor'):Show(self.customTexts.unit, self.customTexts.id, self:GetParent())
        end,
        size = { 70, 25 },
        color = { 219 / 255, 73 / 255, 0, 1 }
    }, f)
    editButton:SetPoint('RIGHT', deleteButton, 'LEFT', -10, 0)
    f.EditButton = editButton

    f.RefreshTag = function(self)
        local tag = ctCore:GetValue(self.optionData.customTexts.unit, self.optionData.customTexts.id, 'tag')
        self.tagText:SetText(tag)
    end

    f.SetOptionData = function(self, option)
        self.optionData = option
        self.tagText:SetText(option.tag)
        self.EditButton.customTexts = option.customTexts
        self.DeleteButton.customTexts = option.customTexts
    end

    f.SetFrameWidth = function(self, width)
        self:SetWidth(width)
    end

    f.configured = true
end

listItem.Create = function(self)
    local f = self.pool:Acquire()
    if (not f.configured) then
        ConfigureFrame(f)
    end
    f.Destroy = function(self)
        listItem.pool:Release(self)
    end
    f:Show()
    return f
end
