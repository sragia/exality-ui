---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

local offline = EXUI:GetModule('uf-element-offline')

offline.Create = function(self, frame)
    local healthPerc = frame.ElementFrame:CreateFontString(nil, 'OVERLAY')
    healthPerc:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')

    return healthPerc
end

offline.Update = function(self, frame)
    local Offline = frame.Offline
    local db = frame.db
    if (not db.offlineEnable) then
        Offline:Hide()
        frame:Tag(Offline, '')
        return
    end
    Offline:Show()
    Offline:SetFont(LSM:Fetch('font', db.offlineFont), db.offlineFontSize, db.offlineFontFlag)
    Offline:SetVertexColor(db.offlineFontColor.r, db.offlineFontColor.g, db.offlineFontColor.b,
        db.offlineFontColor.a)
    Offline:ClearAllPoints()
    Offline:SetPoint(db.offlineAnchorPoint, frame.ElementFrame, db.offlineRelativeAnchorPoint,
        db.offlineXOffset, db.offlineYOffset)
    local ok, err = pcall(function()
        frame:Tag(Offline, db.offlineTag)
    end)
    if (not ok) then EXUI.utils.printOut(err) end
end
