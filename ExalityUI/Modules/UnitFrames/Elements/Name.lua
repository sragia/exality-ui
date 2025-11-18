---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')


local name = EXUI:GetModule('uf-element-name')

name.Create = function(self, frame)
    local name = frame.ElementFrame:CreateFontString(nil, 'OVERLAY')

    return name
end

name.Update = function(self, frame)
    local name = frame.Name
    local db = frame.db
    if (not db.nameEnable) then
        name:Hide()
        frame:Tag(name, '')
        return
    end
    name:Show()
    name:SetFont(LSM:Fetch('font', db.nameFont), db.nameFontSize, db.nameFontFlag)
    name:SetPoint(db.nameAnchorPoint, frame.ElementFrame, db.nameRelativeAnchorPoint, db.nameXOffset, db.nameYOffset)
    name:SetVertexColor(db.nameFontColor.r, db.nameFontColor.g, db.nameFontColor.b, db.nameFontColor.a)
    local ok, err = pcall(function()
        frame:Tag(name, db.nameTag)
    end)
    if (not ok) then EXUI.utils.printOut(err) end
end