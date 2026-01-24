---@class ExalityUI
local EXUI = select(2, ...)
---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local privateAuras = EXUI:GetModule('uf-element-private-auras')

privateAuras.Create = function(self, frame)
    local PrivateAuras = CreateFrame('Frame', '$parent_PrivateAuras', frame.ElementFrame)
    PrivateAuras:SetSize(1, 1)

    PrivateAuras:Show()
    return PrivateAuras
end

privateAuras.DisplayPreview = function(self, PrivateAuras)
    PrivateAuras.previews = PrivateAuras.previews or {}
    for _, preview in ipairs(PrivateAuras.previews) do
        if (preview) then
            preview:Hide()
        end
    end
    for i = 1, PrivateAuras.maxNum do
        local preview = PrivateAuras.previews[i]
        if (not preview) then
            preview = CreateFrame('Frame', nil, PrivateAuras)
            local tex = preview:CreateTexture(nil, 'BACKGROUND')
            tex:SetAllPoints()
            tex:SetTexture(237514)
            table.insert(PrivateAuras.previews, preview)
        end

        preview:ClearAllPoints()
        local direction = PrivateAuras.growthX == 'RIGHT' and 1 or -1
        EXUI:SetPoint(
            preview,
            'CENTER',
            PrivateAuras,
            'CENTER',
            (i - 1) * direction * (PrivateAuras.iconWidth + PrivateAuras.spacing),
            0
        )
        preview:SetSize(PrivateAuras.iconWidth, PrivateAuras.iconHeight)
        preview:Show()
    end
end

privateAuras.HidePreview = function(self, PrivateAuras)
    if (not PrivateAuras.previews) then return end
    for _, preview in ipairs(PrivateAuras.previews) do
        if (preview) then
            preview:Hide()
        end
    end
end

privateAuras.Update = function(self, frame)
    local db = frame.db
    local PrivateAuras = frame.PrivateAuras

    if (db.privateAurasEnable) then
        core:EnableElementForFrame(frame, 'PrivateAuras')
    else
        core:DisableElementForFrame(frame, 'PrivateAuras')
    end

    PrivateAuras.maxNum = db.privateAurasMaxNum
    PrivateAuras.iconWidth = db.privateAurasIconWidth
    PrivateAuras.iconHeight = db.privateAurasIconHeight
    PrivateAuras.spacing = db.privateAurasSpacing
    PrivateAuras.growthX = db.privateAurasGrowthX

    PrivateAuras:ClearAllPoints()

    EXUI:SetPoint(
        PrivateAuras,
        db.privateAurasAnchorPoint,
        frame.ElementFrame,
        db.privateAurasRelativeAnchorPoint,
        db.privateAurasXOff,
        db.privateAurasYOff
    )

    if (frame.isFake) then
        self:DisplayPreview(PrivateAuras)
    else
        self:HidePreview(PrivateAuras)
    end
end
