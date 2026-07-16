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

-- Preview lives on ElementFrame (always safe). Live border lives on the AuraButton
-- and inherits DenyTaintedAccessWhenAurasAreSecret — never assume method calls succeed.
local function IsOverlayTexture(overlay)
    if not overlay or type(overlay.GetObjectType) ~= 'function' then
        return false
    end
    local ok, objectType = pcall(overlay.GetObjectType, overlay)
    return ok and objectType == 'Texture'
end

local function SafeCall(object, methodName, ...)
    if not object then
        return false
    end
    local method = object[methodName]
    if type(method) ~= 'function' then
        return false
    end
    return pcall(method, object, ...)
end

function dispelOverlay:DiscardContainer(frame)
    local container = frame.DispelOverlayContainer
    if not container then
        return
    end
    SafeCall(container, 'SetEnabled', false)
    SafeCall(container, 'Hide')
    SafeCall(container, 'ClearAllPoints')
    SafeCall(container, 'SetParent', nil)
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

    -- Size/anchor the button only in initializeFrame: AddAuraSlot applies access
    -- restrictions and UpdateAllAuras before returning, so post-return layout is
    -- denied when auras are secret (e.g. reload inside M+).
    container:AddAuraSlot(SLOT_KEY, filterString, {
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

    SafeCall(container, 'ClearAllPoints')
    SafeCall(container, 'SetAllPoints', cover)
    -- Above health/power, below ElementFrame so name/health text stay readable.
    local health = frame.Health
    local baseLevel = (health and health.GetFrameLevel and health:GetFrameLevel()) or frame:GetFrameLevel()
    local elementLevel = cover.GetFrameLevel and cover:GetFrameLevel()
    local level = baseLevel + 10
    if elementLevel and level >= elementLevel then
        level = elementLevel - 1
    end
    SafeCall(container, 'SetFrameLevel', level)
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
    if SafeCall(container, 'SetAuraSlotFilterString', SLOT_KEY, filterString) then
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
        SafeCall(container, 'SetEnabled', false)
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
            SafeCall(container, 'SetEnabled', true)
            SafeCall(container, 'UpdateAllAuras')
        end
    end
end

dispelOverlay.Create = function(self, frame)
    -- Preview-only texture on ElementFrame. Live overlay must live on the AuraButton
    -- (SetAuraBorder forbidden aspects), so preview stays separate.
    -- ARTWORK (sublevel -8) keeps preview under OVERLAY texts on ElementFrame.
    local preview = frame.ElementFrame:CreateTexture(nil, 'ARTWORK', nil, -8)
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
    if not preview or not ufAuras:IsSupported() then -- Temp block until we are in 12.1
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
    -- Live border may be secret-restricted; skip alpha if access is denied.
    SafeCall(frame.DispelOverlayLive, 'SetAlpha', alpha)

    local previewEnabled = frame:IsElementPreviewEnabled('dispeloverlay')
    if previewEnabled then
        self:ApplyPreview(frame, true)
        return
    elseif preview.isPreview then
        self:ApplyPreview(frame, false)
    end

    if container then
        self:ApplyFilter(container, db.dispelOverlayFilter)
        if frame.unit then
            SafeCall(container, 'SetUnit', frame.unit)
        end
        SafeCall(container, 'SetEnabled', true)
        SafeCall(container, 'Show')
        SafeCall(container, 'UpdateAllAuras')
    end
end
