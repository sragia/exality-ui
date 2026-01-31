---@class ExalityUI
local EXUI = select(2, ...)
---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local privateAuras = EXUI:GetModule('uf-element-private-auras')

privateAuras.Create = function(self, frame)
    local PrivateAuras = CreateFrame('Frame', '$parent_PrivateAuras', frame.ElementFrame)
    PrivateAuras:SetSize(16, 16)

    PrivateAuras.PostUpdate = function(self)
        local width = self.disableTooltip and 0.1 or self.width
        local height = self.disableTooltip and 0.1 or self.height
        for i = 1, (self.num or 0) do
            local aura = self[i]
            if (aura) then
                aura:SetSize(width, height) -- Hacky way to disable tooltip. Credit to Reloe for the way
            end
        end
    end

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
    for i = 1, PrivateAuras.num do
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
            (i - 1) * direction * (PrivateAuras.width + PrivateAuras.spacing),
            0
        )
        preview:SetSize(PrivateAuras.width, PrivateAuras.height)
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
    local borderScale = db.privateAurasIconWidth / 16
    if (db.privateAurasDisableBorder) then
        borderScale = -100
    end

    PrivateAuras.num = db.privateAurasMaxNum
    PrivateAuras.width = db.privateAurasIconWidth
    PrivateAuras.height = db.privateAurasIconHeight
    PrivateAuras.spacingX = db.privateAurasSpacingX
    PrivateAuras.spacingY = db.privateAurasSpacingY
    PrivateAuras.growthX = db.privateAurasGrowthX
    PrivateAuras.growthY = db.privateAurasGrowthY
    PrivateAuras.borderScale = borderScale
    PrivateAuras.disableCooldown = db.privateAurasDisableCooldownSpiral
    PrivateAuras.disableCooldownText = db.privateAurasDisableCooldownText
    PrivateAuras.maxCols = db.privateAurasMaxCols
    PrivateAuras.disableTooltip = db.privateAurasDisableTooltip

    PrivateAuras.initialAnchor = 'CENTER'

    PrivateAuras:ClearAllPoints()

    EXUI:SetSize(PrivateAuras, db.privateAurasIconWidth, db.privateAurasIconHeight)

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

    PrivateAuras:PostUpdate()
end
