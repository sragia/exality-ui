---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUINameplatesElementHealthPerc
local healthPerc = EXUI:GetModule('np-element-health-perc')

healthPerc.Create = function(self, frame)
    local fontString = frame.ElementFrame:CreateFontString(nil, 'OVERLAY')
    fontString:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    return fontString
end

healthPerc.Update = function(self, frame)
    local db = frame.db
    local fontString = frame.HealthPerc
    if frame.isFriendly or not db.healthpercEnable then
        fontString:Hide()
        frame:Tag(fontString, '')
        return
    end
    fontString:Show()
    fontString:SetFont(LSM:Fetch('font', db.healthpercFont), db.healthpercFontSize, db.healthpercFontFlag)
    fontString:SetVertexColor(db.healthpercFontColor.r, db.healthpercFontColor.g, db.healthpercFontColor.b, db.healthpercFontColor.a)
    fontString:ClearAllPoints()
    fontString:SetPoint(
        db.healthpercAnchorPoint,
        frame.ElementFrame,
        db.healthpercRelativeAnchorPoint,
        db.healthpercXOffset,
        db.healthpercYOffset
    )
    frame:Tag(fontString, db.healthpercTag)
end
