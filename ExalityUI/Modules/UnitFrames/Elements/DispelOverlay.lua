---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesAuras
local ufAuras = EXUI:GetModule('uf-auras')

---@class EXUIUnitFramesAurasApply
local apply = EXUI:GetModule('uf-auras-apply')

---@class EXUIUnitFramesElementsDispelOverlay
local dispelOverlay = EXUI:GetModule('uf-element-dispel-overlay')

local SLOT_KEY = 'dispelOverlay'

local DISPEL_STYLE = Enum and Enum.CustomAuraButtonDispelTypeTextureStyle
local DISPEL_STYLE_PRESERVE = (DISPEL_STYLE and DISPEL_STYLE.PreserveAsset) or 3
local DISPEL_STYLE_ICON = (DISPEL_STYLE and DISPEL_STYLE.Icon) or 2

local FILTER_MAP = {
    RAID = 'HARMFUL|RAID',
    RAID_PLAYER_DISPELLABLE = 'HARMFUL|RAID_PLAYER_DISPELLABLE',
    DISPELLABLE = 'HARMFUL|DISPELLABLE',
}

local function GetFilterString(mode)
    return FILTER_MAP[mode] or FILTER_MAP.RAID
end

-- Independent toggles; migrate old exclusive dispelOverlayStyle if needed.
local function ShowOverlay(db)
    if not db then
        return true
    end
    if db.dispelOverlayShowOverlay ~= nil then
        return db.dispelOverlayShowOverlay and true or false
    end
    return (db.dispelOverlayStyle or 'Overlay') ~= 'Icon'
end

local function ShowIcon(db)
    if not db then
        return false
    end
    if db.dispelOverlayShowIcon ~= nil then
        return db.dispelOverlayShowIcon and true or false
    end
    return db.dispelOverlayStyle == 'Icon'
end

local function GetPreviewColor()
    local colors = EXUI.oUF and EXUI.oUF.colors and EXUI.oUF.colors.dispel
    local magic = EXUI.oUF and EXUI.oUF.Enum and EXUI.oUF.Enum.DispelType and EXUI.oUF.Enum.DispelType.Magic
    if colors and magic and colors[magic] then
        return colors[magic]
    end
    return DEBUFF_TYPE_MAGIC_COLOR
end

local function GetHardSignature(db)
    db = db or {}
    -- Size/anchor are applied live on IconHost; only structural mode changes need rebuild.
    return table.concat({
        GetFilterString(db.dispelOverlayFilter),
        ShowOverlay(db) and 'o' or '-',
        ShowIcon(db) and 'i' or '-',
    }, '|')
end

-- Preview lives on ElementFrame (always safe). Live textures live on the AuraButton
-- and inherit DenyTaintedAccessWhenAurasAreSecret — never assume method calls succeed.
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

local function AddDispelTexture(button, texture, style)
    if button.AddDispelTypeTexture then
        button:AddDispelTypeTexture(texture, {
            showWhenHarmful = true,
            showWhenHelpful = false,
            style = style,
        })
    elseif button.SetAuraBorder then
        button:SetAuraBorder(texture, {
            showWhenHarmful = true,
            showWhenHelpful = false,
            style = style,
        })
    end
end

local function LayoutIconHost(host, parent, db)
    if not host then
        return
    end
    local size = (db and db.dispelOverlayIconSize) or 16
    host:ClearAllPoints()
    host:SetSize(size, size)
    host:SetPoint(
        (db and db.dispelOverlayAnchorPoint) or 'CENTER',
        parent,
        (db and db.dispelOverlayRelativeAnchorPoint) or 'CENTER',
        (db and db.dispelOverlayXOff) or 0,
        (db and db.dispelOverlayYOff) or 0
    )
end

local function LayoutPreviewTextures(frame, db)
    local cover = frame.ElementFrame or frame
    local alpha = db and db.dispelOverlayAlpha or 1
    local overlayPreview = frame.DispelOverlay
    local iconPreview = frame.DispelOverlayIconPreview

    if IsOverlayTexture(overlayPreview) then
        overlayPreview:SetAlpha(alpha)
        if ShowOverlay(db) then
            overlayPreview:ClearAllPoints()
            overlayPreview:SetAllPoints(cover)
            overlayPreview:SetTexture(EXUI.const.textures.unitFrames.dispelOverlay)
            overlayPreview:SetTexCoord(0, 1, 0, 1)
        else
            overlayPreview:Hide()
        end
    end

    if IsOverlayTexture(iconPreview) then
        iconPreview:SetAlpha(alpha)
        if ShowIcon(db) then
            local size = (db and db.dispelOverlayIconSize) or 16
            iconPreview:ClearAllPoints()
            iconPreview:SetSize(size, size)
            iconPreview:SetPoint(
                (db and db.dispelOverlayAnchorPoint) or 'CENTER',
                cover,
                (db and db.dispelOverlayRelativeAnchorPoint) or 'CENTER',
                (db and db.dispelOverlayXOff) or 0,
                (db and db.dispelOverlayYOff) or 0
            )
            -- Keep our size: IgnoreAtlasSize == false.
            if iconPreview.SetAtlas then
                iconPreview:SetAtlas('RaidFrame-Icon-DebuffMagic', false)
            end
        else
            iconPreview:Hide()
        end
    end
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
    frame.DispelOverlayLiveIcon = nil
    frame.DispelOverlayIconHost = nil
end

function dispelOverlay:EnsureHeaderBudget(frame)
    local unitType = ufAuras:GetUnitTypeForFrame(frame)
    if unitType == 'party' or unitType == 'raid' then
        apply:EnsureHeaderContainers(unitType)
    end
end

function dispelOverlay:EnsureContainer(frame)
    local db = frame.db
    local showOverlay = ShowOverlay(db)
    local showIcon = ShowIcon(db)
    if not showOverlay and not showIcon then
        self:DiscardContainer(frame)
        return nil
    end

    local hardSig = GetHardSignature(db)
    if frame.DispelOverlayContainer then
        if frame.DispelOverlayContainer._dispelOverlayHardSig == hardSig then
            return frame.DispelOverlayContainer
        end
        self:DiscardContainer(frame)
    end

    if not frame.CreateAuras then
        return nil
    end

    self:EnsureHeaderBudget(frame)

    local filterString = GetFilterString(db and db.dispelOverlayFilter)
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
    local alpha = (db and db.dispelOverlayAlpha) or 1

    container:AddAuraSlot(SLOT_KEY, filterString, {
        initializeFrame = function(button)
            if button.EnableMouse then
                button:EnableMouse(false)
            end
            if button.SetMouseMotionEnabled then
                button:SetMouseMotionEnabled(false)
            end

            button:ClearAllPoints()
            -- Slot button always covers the unit so overlay can fill; icon lives on a
            -- sized host frame that we can still SetSize after initializeFrame.
            button:SetAllPoints(cover)

            if button.ClearDispelTypeTextures then
                button:ClearDispelTypeTextures()
            end

            if showOverlay then
                local live = button:CreateTexture(nil, 'ARTWORK')
                live:SetAllPoints(button)
                live:SetTexture(EXUI.const.textures.unitFrames.dispelOverlay)
                live:SetVertexColor(0, 0, 0, 0)
                live:SetAlpha(alpha)
                live:Hide()
                AddDispelTexture(button, live, DISPEL_STYLE_PRESERVE)
                frame.DispelOverlayLive = live
            else
                frame.DispelOverlayLive = nil
            end

            if showIcon then
                local host = CreateFrame('Frame', nil, button)
                host:EnableMouse(false)
                LayoutIconHost(host, button, db)
                local icon = host:CreateTexture(nil, 'OVERLAY')
                icon:SetAllPoints(host)
                icon:SetAlpha(alpha)
                icon:Hide()
                AddDispelTexture(button, icon, DISPEL_STYLE_ICON)
                frame.DispelOverlayIconHost = host
                frame.DispelOverlayLiveIcon = icon
            else
                frame.DispelOverlayIconHost = nil
                frame.DispelOverlayLiveIcon = nil
            end
        end,
    })

    SafeCall(container, 'ClearAllPoints')
    SafeCall(container, 'SetAllPoints', cover)
    local health = frame.Health
    local baseLevel = (health and health.GetFrameLevel and health:GetFrameLevel()) or frame:GetFrameLevel()
    local elementLevel = cover.GetFrameLevel and cover:GetFrameLevel()
    local level = baseLevel + 10
    if elementLevel and level >= elementLevel then
        level = elementLevel - 1
    end
    SafeCall(container, 'SetFrameLevel', level)
    container._dispelOverlayFilter = filterString
    container._dispelOverlayHardSig = hardSig

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
    local db = frame.db
    local container = frame.DispelOverlayContainer
    local alpha = db and db.dispelOverlayAlpha or 1
    local overlayPreview = frame.DispelOverlay
    local iconPreview = frame.DispelOverlayIconPreview

    if enabled then
        SafeCall(container, 'SetEnabled', false)
        LayoutPreviewTextures(frame, db)

        if ShowOverlay(db) and IsOverlayTexture(overlayPreview) then
            overlayPreview.isPreview = true
            local color = GetPreviewColor()
            local r, g, b = color:GetRGB()
            overlayPreview:SetVertexColor(r, g, b, 1)
            overlayPreview:SetAlpha(alpha)
            overlayPreview:Show()
        elseif IsOverlayTexture(overlayPreview) then
            overlayPreview.isPreview = false
            overlayPreview:Hide()
        end

        if ShowIcon(db) and IsOverlayTexture(iconPreview) then
            iconPreview.isPreview = true
            iconPreview:SetVertexColor(1, 1, 1, 1)
            iconPreview:SetAlpha(alpha)
            iconPreview:Show()
        elseif IsOverlayTexture(iconPreview) then
            iconPreview.isPreview = false
            iconPreview:Hide()
        end
    else
        local wasPreview = (overlayPreview and overlayPreview.isPreview)
            or (iconPreview and iconPreview.isPreview)
        if IsOverlayTexture(overlayPreview) then
            overlayPreview.isPreview = false
            overlayPreview:SetVertexColor(0, 0, 0, 0)
            overlayPreview:SetAlpha(alpha)
            overlayPreview:Hide()
        end
        if IsOverlayTexture(iconPreview) then
            iconPreview.isPreview = false
            iconPreview:SetVertexColor(1, 1, 1, 1)
            iconPreview:SetAlpha(alpha)
            iconPreview:Hide()
        end
        if wasPreview and container then
            SafeCall(container, 'SetEnabled', true)
            SafeCall(container, 'UpdateAllAuras')
        end
    end
end

dispelOverlay.Create = function(self, frame)
    -- Preview-only textures on ElementFrame. Live textures must live on the AuraButton.
    local overlay = frame.ElementFrame:CreateTexture(nil, 'ARTWORK', nil, -8)
    overlay:SetAllPoints()
    overlay:SetTexture(EXUI.const.textures.unitFrames.dispelOverlay)
    overlay:SetVertexColor(0, 0, 0, 0)
    overlay:SetAlpha(1)
    overlay:Hide()
    overlay.isPreview = false

    local icon = frame.ElementFrame:CreateTexture(nil, 'OVERLAY', nil, -7)
    icon:SetSize(16, 16)
    icon:SetPoint('CENTER')
    icon:SetVertexColor(1, 1, 1, 1)
    icon:SetAlpha(1)
    icon:Hide()
    icon.isPreview = false
    frame.DispelOverlayIconPreview = icon

    return overlay
end

dispelOverlay.Update = function(self, frame)
    local db = frame.db
    local preview = frame.DispelOverlay
    if not preview or not ufAuras:IsSupported() then
        return
    end

    if not db.dispelOverlayEnable then
        preview.isPreview = false
        if IsOverlayTexture(preview) then
            preview:SetVertexColor(0, 0, 0, 0)
            preview:Hide()
        end
        if IsOverlayTexture(frame.DispelOverlayIconPreview) then
            frame.DispelOverlayIconPreview.isPreview = false
            frame.DispelOverlayIconPreview:Hide()
        end
        self:DiscardContainer(frame)
        return
    end

    LayoutPreviewTextures(frame, db)

    local container = self:EnsureContainer(frame)
    local alpha = db.dispelOverlayAlpha or 1
    if IsOverlayTexture(preview) then
        preview:SetAlpha(alpha)
    end
    if IsOverlayTexture(frame.DispelOverlayIconPreview) then
        frame.DispelOverlayIconPreview:SetAlpha(alpha)
    end
    SafeCall(frame.DispelOverlayLive, 'SetAlpha', alpha)
    SafeCall(frame.DispelOverlayLiveIcon, 'SetAlpha', alpha)

    -- Icon host is a normal frame (not inbound-configured), so size/position can
    -- update without discarding the aura slot.
    if ShowIcon(db) and frame.DispelOverlayIconHost then
        local cover = frame.ElementFrame or frame
        local hostParent = frame.DispelOverlayIconHost:GetParent() or cover
        LayoutIconHost(frame.DispelOverlayIconHost, hostParent, db)
    end

    local previewEnabled = frame:IsElementPreviewEnabled('dispeloverlay')
    local anyPreview = preview.isPreview
        or (frame.DispelOverlayIconPreview and frame.DispelOverlayIconPreview.isPreview)
    if previewEnabled then
        self:ApplyPreview(frame, true)
        return
    elseif anyPreview then
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
