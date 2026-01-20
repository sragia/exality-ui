---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')


local name = EXUI:GetModule('uf-element-name')

name.Create = function(self, frame)
    local name = frame.ElementFrame:CreateFontString('EXUI_Name_' .. frame.unit, 'OVERLAY')
    name:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    name:SetWidth(100)
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
    if (db.nameMaxWidth) then
        local width = Round(db.sizeWidth * db.nameMaxWidth / 100)
        name:SetWidth(width)
    else
        name:SetWidth(db.sizeWidth)
    end

    name:SetHeight(db.nameFontSize + db.nameFontSize / 2)
    name:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(db.nameAnchorPoint))
    name:ClearAllPoints()
    name:SetPoint(db.nameAnchorPoint, frame.ElementFrame, db.nameRelativeAnchorPoint, db.nameXOffset, db.nameYOffset)
    name:SetVertexColor(db.nameFontColor.r, db.nameFontColor.g, db.nameFontColor.b, db.nameFontColor.a)
    local ok, err = pcall(function()
        frame:Tag(name, db.nameTag)
    end)
    if (not ok) then EXUI.utils.printOut(err) end
end
