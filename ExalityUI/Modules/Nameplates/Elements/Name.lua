---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUINameplatesElementName
local name = EXUI:GetModule('np-element-name')

name.Create = function(self, frame)
    local fontString = frame.ElementFrame:CreateFontString(nil, 'OVERLAY')
    fontString:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    return fontString
end

local CLASSIFICATION_COLORS = {
    elite = 'classificationElite',
    rare = 'classificationRare',
    rareelite = 'classificationRareElite',
    worldboss = 'classificationWorldBoss',
    minus = 'classificationMinus',
}

local function applyFriendlyName(frame, fontString, db)
    local unit = frame.unit or frame.__unit
    fontString:Show()
    fontString:SetFont(LSM:Fetch('font', db.nameFont), db.nameFontSize, db.nameFontFlag)
    fontString:SetWidth(db.sizeWidth or 140)
    fontString:SetHeight(db.nameFontSize + db.nameFontSize / 2)
    fontString:SetJustifyH('CENTER')
    fontString:ClearAllPoints()
    fontString:SetPoint('CENTER', frame.ElementFrame, 'CENTER', 0, 0)

    if unit and UnitIsPlayer(unit) then
        fontString:SetVertexColor(1, 1, 1, 1)
        frame:Tag(fontString, '[classcolor][name]')
        return
    end

    local color = db.friendlyNpcColor
    if unit then
        local key = CLASSIFICATION_COLORS[UnitClassification(unit)]
        if key and db[key] then
            color = db[key]
        end
    end
    if color then
        fontString:SetVertexColor(color.r, color.g, color.b, color.a or 1)
    end
    frame:Tag(fontString, '[name]')
end

name.Update = function(self, frame)
    local db = frame.db
    local fontString = frame.Name
    if frame.isFriendly then
        applyFriendlyName(frame, fontString, db)
        return
    end
    if not db.nameEnable then
        fontString:Hide()
        frame:Untag(fontString)
        return
    end
    fontString:Show()
    fontString:SetFont(LSM:Fetch('font', db.nameFont), db.nameFontSize, db.nameFontFlag)
    local width = db.sizeWidth
    if db.nameMaxWidth then
        width = Round(db.sizeWidth * db.nameMaxWidth / 100)
    end
    fontString:SetWidth(width)
    fontString:SetHeight(db.nameFontSize + db.nameFontSize / 2)
    fontString:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(db.nameAnchorPoint))
    fontString:ClearAllPoints()
    fontString:SetPoint(db.nameAnchorPoint, frame.ElementFrame, db.nameRelativeAnchorPoint, db.nameXOffset, db.nameYOffset)
    fontString:SetVertexColor(db.nameFontColor.r, db.nameFontColor.g, db.nameFontColor.b, db.nameFontColor.a)
    frame:Tag(fontString, db.nameTag)
end
