---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesElementClassification
local classification = EXUI:GetModule('np-element-classification')

local ATLAS = {
    elite = 'nameplates-icon-elite-gold',
    rareelite = 'nameplates-icon-elite-silver',
    rare = 'nameplates-icon-rare',
    worldboss = 'nameplates-icon-elite-gold',
}

classification.Create = function(self, frame)
    local texture = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    texture:SetSize(16, 16)
    return texture
end

classification.UpdateIcon = function(self, frame, unit)
    local texture = frame.Classification
    local db = frame.db
    if frame.isFriendly or not db.classificationIconEnable then
        texture:Hide()
        return
    end

    unit = unit or frame.unit or frame.__unit
    if not unit then
        texture:Hide()
        return
    end

    local atlas = ATLAS[UnitClassification(unit)]
    if atlas then
        local ok = pcall(texture.SetAtlas, texture, atlas)
        if ok then
            texture:Show()
            return
        end
    end
    texture:Hide()
end

classification.Update = function(self, frame)
    local db = frame.db
    local texture = frame.Classification
    if frame.isFriendly or not db.classificationIconEnable then
        texture:Hide()
        return
    end

    local size = (db.classificationIconScale or 1) * 16
    texture:ClearAllPoints()
    texture:SetPoint(
        db.classificationIconAnchorPoint,
        frame.ElementFrame,
        db.classificationIconRelativeAnchorPoint,
        db.classificationIconXOff,
        db.classificationIconYOff
    )
    texture:SetSize(size, size)
    self:UpdateIcon(frame, frame.unit or frame.__unit)
end
