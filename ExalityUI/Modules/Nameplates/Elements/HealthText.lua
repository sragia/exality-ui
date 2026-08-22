---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUINameplatesElementHealthText
local healthText = EXUI:GetModule('np-element-health-text')

healthText.Create = function(self, frame)
    local fontString = frame.ElementFrame:CreateFontString(nil, 'OVERLAY')
    fontString:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    return fontString
end

healthText.Update = function(self, frame)
    local db = frame.db
    local fontString = frame.HealthText
    if frame.isFriendly or not db.healthEnable then
        fontString:Hide()
        frame:Tag(fontString, '')
        return
    end
    fontString:Show()
    fontString:SetFont(LSM:Fetch('font', db.healthFont), db.healthFontSize, db.healthFontFlag)
    fontString:ClearAllPoints()
    fontString:SetPoint(db.healthAnchorPoint, frame.ElementFrame, db.healthRelativeAnchorPoint, db.healthXOffset, db.healthYOffset)
    fontString:SetVertexColor(db.healthFontColor.r, db.healthFontColor.g, db.healthFontColor.b, db.healthFontColor.a)
    frame:Tag(fontString, db.healthTag)
end
