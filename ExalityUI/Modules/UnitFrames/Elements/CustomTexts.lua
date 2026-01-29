---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUIUnitFramesCustomTexts
local ctCore = EXUI:GetModule('uf-custom-texts')

local customTexts = EXUI:GetModule('uf-element-custom-texts')

customTexts.pool = nil

customTexts.Init = function(self)
    self.pool = CreateFramePool('Frame', UIParent)
end

customTexts.Create = function(self, frame)
    return {} -- Texts will get created on Update
end

customTexts.CreateText = function(self, frame)
    local textContainer = self.pool:Acquire()
    textContainer:SetSize(1, 1)
    local text = textContainer:CreateFontString(nil, 'OVERLAY')
    text:SetPoint('CENTER')
    text:SetWidth(0)
    textContainer.Text = text
    textContainer:SetParent(frame.ElementFrame)

    textContainer.Destroy = function(self)
        customTexts.pool:Release(self)
    end
    textContainer:Show()
    return textContainer
end

customTexts.Update = function(self, frame)
    local db = frame.db
    local CustomTexts = frame.CustomTexts

    local list = ctCore:List(frame.unit)
    local IDs = {}
    for id, db in pairs(list) do
        table.insert(IDs, id)
    end

    for ID, tagFrame in pairs(CustomTexts) do
        if (not FindInTable(IDs, ID)) then
            frame:Untag(tagFrame.Text)
            tagFrame:Destroy()
            CustomTexts[ID] = nil
        end
    end

    for ID, db in pairs(list) do
        if (not CustomTexts[ID]) then
            CustomTexts[ID] = self:CreateText(frame)
        end
        local textContainer = CustomTexts[ID]
        local text = textContainer.Text
        text:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)
        text:SetVertexColor(db.fontColor.r, db.fontColor.g, db.fontColor.b, db.fontColor.a)
        text:ClearAllPoints()
        textContainer:SetPoint(db.anchorPoint, frame.ElementFrame, db.relativeAnchorPoint, db.XOffset, db.YOffset)
        text:SetPoint(db.anchorPoint, frame.ElementFrame, db.relativeAnchorPoint)
        local ok, err = pcall(function()
            frame:Tag(text, db.tag)
        end)
        if (not ok) then EXUI.utils.printOut(err) end
    end
end
