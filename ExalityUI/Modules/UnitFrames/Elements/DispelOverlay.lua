---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesAuras
local ufAuras = EXUI:GetModule('uf-auras')

---@class EXUIUnitFramesAurasApply
local apply = EXUI:GetModule('uf-auras-apply')

---@class EXUIUnitFramesElementsDispelOverlay
local dispelOverlay = EXUI:GetModule('uf-element-dispel-overlay')

local SLOT_KEY = 'dispelOverlay'
local BORDER_STYLE_COLOR = (AuraButtonBorderStyle and AuraButtonBorderStyle.Color) or 1

local FILTER_MAP = {
    RAID = 'HARMFUL|RAID',
    RAID_PLAYER_DISPELLABLE = 'HARMFUL|RAID_PLAYER_DISPELLABLE',
    DISPELLABLE = 'HARMFUL|DISPELLABLE',
}

local function GetFilterString(mode)
    return FILTER_MAP[mode] or FILTER_MAP.RAID
end

local function GetPreviewColor()
    local colors = EXUI.oUF and EXUI.oUF.colors and EXUI.oUF.colors.dispel
    local magic = EXUI.oUF and EXUI.oUF.Enum and EXUI.oUF.Enum.DispelType and EXUI.oUF.Enum.DispelType.Magic
    if colors and magic and colors[magic] then
        return colors[magic]
    end
    return DEBUFF_TYPE_MAGIC_COLOR
end

local function IsOverlayTexture(overlay)
    return overlay and overlay.GetObjectType and overlay:GetObjectType() == 'Texture'
end

function dispelOverlay:DiscardContainer(frame)
    local container = frame.DispelOverlayContainer
    if not container then
        return
    end
    if container.SetEnabled then
        container:SetEnabled(false)
    end
    container:Hide()
    container:ClearAllPoints()
    container:SetParent(nil)
    frame.DispelOverlayContainer = nil
    frame.DispelOverlayLive = nil
end

function dispelOverlay:EnsureHeaderBudget(frame)
    local unitType = ufAuras:GetUnitTypeForFrame(frame)
    if unitType == 'party' or unitType == 'raid' then
        apply:EnsureHeaderContainers(unitType)
    end
end

function dispelOverlay:EnsureContainer(frame)
    if frame.DispelOverlayContainer then
        return frame.DispelOverlayContainer
    end
    if not frame.CreateAuras or InCombatLockdown() then
        return nil
    end

    self:EnsureHeaderBudget(frame)

    local filterString = GetFilterString(frame.db and frame.db.dispelOverlayFilter)
    local container = frame:CreateAuras({
        maxWidth = 1,
        initialAnchor = 'CENTER',
        growthX = 'RIGHT',
        growthY = 'DOWN',
    })
    if not container then
        return nil
    end

    local cover = frame.ElementFrame or frame
    local alpha = (frame.db and frame.db.dispelOverlayAlpha) or 1

    -- AuraButton regions passed to SetAuraBorder must be parented+anchored to the
    -- button (forbidden parent/layout aspects). Size the button to the unit frame.
    local auraButton = container:AddAuraSlot(SLOT_KEY, filterString, {
        initializeFrame = function(button)
            if button.EnableMouse then
                button:EnableMouse(false)
            end
            if button.SetMouseMotionEnabled then
                button:SetMouseMotionEnabled(false)
            end

            button:ClearAllPoints()
            button:SetAllPoints(cover)

            local live = button:CreateTexture(nil, 'OVERLAY')
            live:SetAllPoints(button)
            live:SetTexture(EXUI.const.textures.unitFrames.dispelOverlay)
            live:SetVertexColor(0, 0, 0, 0)
            live:SetAlpha(alpha)
            live:Hide()

            if button.SetAuraBorder then
                button:SetAuraBorder(live, {
                    showIcon = false,
                    showWhenHarmful = true,
                    showWhenHelpful = false,
                    style = BORDER_STYLE_COLOR,
                })
            end

            frame.DispelOverlayLive = live
        end,
    })

    if auraButton then
        auraButton:ClearAllPoints()
        auraButton:SetAllPoints(cover)
    end

    container:ClearAllPoints()
    container:SetAllPoints(cover)
    local baseLevel = cover.GetFrameLevel and cover:GetFrameLevel() or frame:GetFrameLevel()
    if container.SetFrameLevel then
        container:SetFrameLevel(baseLevel + 10)
    end
    container._dispelOverlayFilter = filterString

    frame.DispelOverlayContainer = container
    return container
end

function dispelOverlay:ApplyFilter(container, mode)
    if not container then
        return
    end
    local filterString = GetFilterString(mode)
    if container._dispelOverlayFilter == filterString then
        return
    end
    if container.SetAuraSlotFilterString then
        container:SetAuraSlotFilterString(SLOT_KEY, filterString)
        container._dispelOverlayFilter = filterString
    end
end

function dispelOverlay:ApplyPreview(frame, enabled)
    local preview = frame.DispelOverlay
    if not IsOverlayTexture(preview) then
        return
    end

    local container = frame.DispelOverlayContainer
    local db = frame.db
    local alpha = db and db.dispelOverlayAlpha or 1

    if enabled then
        preview.isPreview = true
        -- Pause live container so it doesn't fight preview; preview texture is on
        -- ElementFrame and is not tied to AuraButton visibility.
        if container and container.SetEnabled then
            container:SetEnabled(false)
        end
        local color = GetPreviewColor()
        local r, g, b = color:GetRGB()
        preview:SetVertexColor(r, g, b, 1)
        preview:SetAlpha(alpha)
        preview:Show()
    elseif preview.isPreview then
        preview.isPreview = false
        preview:SetVertexColor(0, 0, 0, 0)
        preview:SetAlpha(alpha)
        preview:Hide()
        if container then
            if container.SetEnabled then
                container:SetEnabled(true)
            end
            if container.UpdateAllAuras then
                container:UpdateAllAuras()
            end
        end
    end
end

dispelOverlay.Create = function(self, frame)
    -- Preview-only texture on ElementFrame. Live overlay must live on the AuraButton
    -- (SetAuraBorder forbidden aspects), so preview stays separate.
    local preview = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    preview:SetAllPoints()
    preview:SetTexture(EXUI.const.textures.unitFrames.dispelOverlay)
    preview:SetVertexColor(0, 0, 0, 0)
    preview:SetAlpha(1)
    preview:Hide()
    preview.isPreview = false
    return preview
end

dispelOverlay.Update = function(self, frame)
    local db = frame.db
    local preview = frame.DispelOverlay
    if not preview then
        return
    end

    if not db.dispelOverlayEnable then
        preview.isPreview = false
        if IsOverlayTexture(preview) then
            preview:SetVertexColor(0, 0, 0, 0)
            preview:Hide()
        end
        self:DiscardContainer(frame)
        return
    end

    local container = self:EnsureContainer(frame)
    local alpha = db.dispelOverlayAlpha or 1
    if IsOverlayTexture(preview) then
        preview:SetAlpha(alpha)
    end
    if IsOverlayTexture(frame.DispelOverlayLive) then
        frame.DispelOverlayLive:SetAlpha(alpha)
    end

    local previewEnabled = frame:IsElementPreviewEnabled('dispeloverlay')
    if previewEnabled then
        self:ApplyPreview(frame, true)
        return
    elseif preview.isPreview then
        self:ApplyPreview(frame, false)
    end

    if container then
        self:ApplyFilter(container, db.dispelOverlayFilter)
        if container.SetUnit and frame.unit then
            container:SetUnit(frame.unit)
        end
        if container.SetEnabled then
            container:SetEnabled(true)
        end
        container:Show()
        if container.UpdateAllAuras then
            container:UpdateAllAuras()
        end
    end
end
