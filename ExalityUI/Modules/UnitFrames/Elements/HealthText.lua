---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')


local healthText = EXUI:GetModule('uf-element-health-text')

healthText.Create = function(self, frame)
    local healthText = frame.ElementFrame:CreateFontString(nil, 'OVERLAY')

    return healthText
end

healthText.Update = function(self, frame)
    local db = frame.db
    local healthText = frame.HealthText
    if (not db.healthEnable) then
        healthText:Hide()
        frame:Tag(healthText, '')
        return
    end
    healthText:Show()
    healthText:SetFont(LSM:Fetch('font', db.healthFont), db.healthFontSize, db.healthFontFlag)
    healthText:SetPoint(db.healthAnchorPoint, frame.ElementFrame, db.healthRelativeAnchorPoint, db.healthXOffset, db.healthYOffset)
    healthText:SetVertexColor(db.healthFontColor.r, db.healthFontColor.g, db.healthFontColor.b, db.healthFontColor.a)
    local ok, err = pcall(function()
        frame:Tag(healthText, db.healthTag)
    end)
    if (not ok) then EXUI.utils.printOut(err) end
end