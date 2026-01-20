---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

local healthPerc = EXUI:GetModule('uf-element-health-perc')

healthPerc.Create = function(self, frame)
    local healthPerc = frame.ElementFrame:CreateFontString(nil, 'OVERLAY')
    healthPerc:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')

    return healthPerc
end

healthPerc.Update = function(self, frame)
    local healthPerc = frame.HealthPerc
    local db = frame.db
    if (not db.healthpercEnable) then
        healthPerc:Hide()
        frame:Tag(healthPerc, '')
        return
    end
    healthPerc:Show()
    healthPerc:SetFont(LSM:Fetch('font', db.healthpercFont), db.healthpercFontSize, db.healthpercFontFlag)
    healthPerc:SetVertexColor(db.healthpercFontColor.r, db.healthpercFontColor.g, db.healthpercFontColor.b,
        db.healthpercFontColor.a)
    healthPerc:ClearAllPoints()
    healthPerc:SetPoint(db.healthpercAnchorPoint, frame.ElementFrame, db.healthpercRelativeAnchorPoint,
        db.healthpercXOffset, db.healthpercYOffset)
    local ok, err = pcall(function()
        frame:Tag(healthPerc, db.healthpercTag)
    end)
    if (not ok) then EXUI.utils.printOut(err) end
end
