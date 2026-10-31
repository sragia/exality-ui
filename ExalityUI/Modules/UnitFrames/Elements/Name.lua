---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local name = EXUI:GetModule('uf-element-name')

name.Create = function(self, frame)
    local holder = core:CreateElementHolder(frame)
    local name = holder:CreateFontString('EXUI_Name_' .. frame.__unit, 'OVERLAY')
    name.holder = holder
    name:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    name:SetWidth(100)
    return name
end

name.Update = function(self, frame)
    local name = frame.Name
    local db = frame.db
    if (not db.nameEnable) then
        name:Hide()
        frame:Untag(name)
        return
    end
    name:Show()
    core:ApplyElementFrameLevel(frame, name.holder, db.nameFrameLevel)
    name:SetFont(LSM:Fetch('font', db.nameFont), db.nameFontSize, db.nameFontFlag)
    EXUI.utils.applyFontShadow(name, db.nameFontShadow, db.nameFontShadowX, db.nameFontShadowY, db.nameFontShadowColor)
    if (db.nameMaxWidth) then
        local width = Round(db.sizeWidth * db.nameMaxWidth / 100)
        name:SetWidth(width)
    else
        name:SetWidth(db.sizeWidth)
    end

    name:SetHeight(db.nameFontSize + db.nameFontSize / 2)
    -- Same text in a same width box keeps its old layout, UpdateTags sets it back after
    name:SetText('')
    name:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(db.nameAnchorPoint))
    name:ClearAllPoints()
    name:SetPoint(db.nameAnchorPoint, frame.ElementFrame, db.nameRelativeAnchorPoint, db.nameXOffset, db.nameYOffset)
    name:SetVertexColor(db.nameFontColor.r, db.nameFontColor.g, db.nameFontColor.b, db.nameFontColor.a)
    frame:Tag(name, db.nameTag)
end
