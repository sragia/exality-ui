---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUINameplatesCustomTexts
local ctCore = EXUI:GetModule('np-custom-texts')

---@class EXUINameplatesElementCustomTexts
local customTexts = EXUI:GetModule('np-element-custom-texts')

customTexts.pool = nil

customTexts.Init = function(self)
    if self.pool then
        return
    end
    self.pool = CreateFramePool('Frame', UIParent)
end

customTexts.Create = function(self, frame)
    return {}
end

customTexts.CreateText = function(self, frame)
    local textContainer = self.pool:Acquire()
    textContainer:SetSize(1, 1)
    local text = textContainer:CreateFontString(nil, 'OVERLAY')
    text:SetPoint('CENTER')
    text:SetWidth(0)
    textContainer.Text = text
    textContainer:SetParent(frame.ElementFrame)
    textContainer.Destroy = function(container)
        customTexts.pool:Release(container)
    end
    textContainer:Show()
    return textContainer
end

customTexts.Update = function(self, frame)
    local CustomTexts = frame.CustomTexts
    if frame.isFriendly then
        for ID, tagFrame in pairs(CustomTexts) do
            frame:Untag(tagFrame.Text)
            tagFrame:Hide()
        end
        return
    end
    for _, tagFrame in pairs(CustomTexts) do
        tagFrame:Show()
    end
    local list = ctCore:List()
    local IDs = {}
    for id in pairs(list) do
        table.insert(IDs, id)
    end

    for ID, tagFrame in pairs(CustomTexts) do
        if not FindInTable(IDs, ID) then
            frame:Untag(tagFrame.Text)
            tagFrame:Destroy()
            CustomTexts[ID] = nil
        end
    end

    for ID, db in pairs(list) do
        if not CustomTexts[ID] then
            CustomTexts[ID] = self:CreateText(frame)
        end
        local textContainer = CustomTexts[ID]
        local text = textContainer.Text
        text:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)
        text:SetVertexColor(db.fontColor.r, db.fontColor.g, db.fontColor.b, db.fontColor.a)
        textContainer:ClearAllPoints()
        text:ClearAllPoints()
        textContainer:SetPoint(db.anchorPoint, frame.ElementFrame, db.relativeAnchorPoint, db.XOffset, db.YOffset)
        text:SetPoint(db.anchorPoint, textContainer, db.relativeAnchorPoint)
        if db.maxWidth then
            text:SetWidth(Round((frame.db.sizeWidth or 140) * db.maxWidth / 100))
        end
        frame:Tag(text, db.tag)
    end
end
