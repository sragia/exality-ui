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

    if (frame.isFake and frame.elementPreviews and frame.elementPreviews.privateauras) then
        self:CreateOrUpdatePreview(frame)
    else
        self:HidePreview(frame)
    end

    PrivateAuras:PostUpdate()
end

privateAuras.CreateOrUpdatePreview = function(self, frame)
    local PrivateAuras = frame.PrivateAuras
    local num = math.min(5, PrivateAuras.num)
    if (not frame.PrivateAurasPreviews) then
        frame.PrivateAurasPreviews = EXUI:GetModule('uf-preview-util'):GetFakeAuras(PrivateAuras, num)
    else
        for _, button in ipairs(frame.PrivateAurasPreviews) do
            if (button) then
                EXUI:GetModule('uf-preview-util'):DestroyAura(button)
            end
        end

        frame.PrivateAurasPreviews = EXUI:GetModule('uf-preview-util'):GetFakeAuras(PrivateAuras, num)
    end
    local element = frame.PrivateAurasPreviews
    local width = PrivateAuras.width or PrivateAuras.size or 16
    local height = PrivateAuras.height or PrivateAuras.size or 16
    local sizeX = width + (PrivateAuras.spacingX or PrivateAuras.spacing or 0)
    local sizeY = height + (PrivateAuras.spacingY or PrivateAuras.spacing or 0)
    local anchor = PrivateAuras.initialAnchor or 'BOTTOMLEFT'
    local growthX = (PrivateAuras.growthX == 'LEFT' and -1) or 1
    local growthY = (PrivateAuras.growthY == 'DOWN' and -1) or 1
    local cols = PrivateAuras.maxCols or math.floor(PrivateAuras:GetWidth() / sizeX + 0.5)
    for i = 1, num do
        local button = element[i]
        if (not button) then break end

        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        button:SetSize(width, height)

        button:ClearAllPoints()
        button:SetPoint(anchor, PrivateAuras, anchor, col * sizeX * growthX, row * sizeY * growthY)
        button:Show()
        button.Count:SetText('')
    end
end

privateAuras.HidePreview = function(self, frame)
    if (not frame.PrivateAurasPreviews) then return end

    for _, button in ipairs(frame.PrivateAurasPreviews) do
        if (button) then
            button:Hide()
        end
    end
end
