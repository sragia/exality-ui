---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local offline = EXUI:GetModule('uf-element-offline')

offline.Create = function(self, frame)
    local holder = core:CreateElementHolder(frame)
    local offlineText = holder:CreateFontString(nil, 'OVERLAY')
    offlineText:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    offlineText.holder = holder

    return offlineText
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
    core:ApplyElementFrameLevel(frame, Offline.holder, db.offlineFrameLevel)
    Offline:SetFont(LSM:Fetch('font', db.offlineFont), db.offlineFontSize, db.offlineFontFlag)
    EXUI.utils.applyFontShadow(Offline, db.offlineFontShadow, db.offlineFontShadowX, db.offlineFontShadowY,
        db.offlineFontShadowColor)
    Offline:SetVertexColor(db.offlineFontColor.r, db.offlineFontColor.g, db.offlineFontColor.b,
        db.offlineFontColor.a)
    Offline:ClearAllPoints()
    Offline:SetPoint(db.offlineAnchorPoint, frame.ElementFrame, db.offlineRelativeAnchorPoint,
        db.offlineXOffset, db.offlineYOffset)

    if (frame:IsElementPreviewEnabled('offline')) then
        frame:Tag(Offline, 'Offline')
    else
        frame:Tag(Offline, db.offlineTag)
    end
end
