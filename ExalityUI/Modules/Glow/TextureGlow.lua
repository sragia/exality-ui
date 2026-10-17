---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUITextureGlow
local textureGlow = EXUI:GetModule('texture-glow')

local BOTTOM_TEXTURE = 'Interface\\AddOns\\ExalityUI\\Assets\\Images\\Glow\\bottom-glow.png'
local EDGE_TEXTURE = 'Interface\\AddOns\\ExalityUI\\Assets\\Images\\Glow\\border-edge.png'
local CORNER_TEXTURE = 'Interface\\AddOns\\ExalityUI\\Assets\\Images\\Glow\\border-corner.png'

local BLEND_MODES = {
    ADD = true,
    BLEND = true,
    MOD = true,
    ALPHAKEY = true,
    DISABLE = true,
}

local function createPiece(parent, path)
    local texture = parent:CreateTexture(nil, 'OVERLAY')
    texture:SetTexture(path)
    texture:SetBlendMode('ADD')
    texture:Hide()
    return texture
end

local function paint(texture, color, blendMode)
    texture:SetBlendMode(blendMode)
    texture:SetVertexColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
end

local function hidePieces(list)
    for index = 1, #list do
        list[index]:Hide()
    end
end

local function layoutBorder(glow, region, width, height, size)
    if size > width * 0.5 then
        size = width * 0.5
    end
    if size > height * 0.5 then
        size = height * 0.5
    end
    if size < 1 then
        size = 1
    end

    local spanW = width - size * 2
    local spanH = height - size * 2
    local edges = glow.Edges
    local corners = glow.Corners

    local bottom = edges[1]
    bottom:ClearAllPoints()
    if spanW > 1 then
        bottom:SetPoint('BOTTOMLEFT', region, 'BOTTOMLEFT', size, 0)
        bottom:SetSize(spanW, size)
        bottom:SetTexCoord(0, 1, 0, 1)
        bottom:Show()
    else
        bottom:Hide()
    end

    local top = edges[2]
    top:ClearAllPoints()
    if spanW > 1 then
        top:SetPoint('TOPLEFT', region, 'TOPLEFT', size, 0)
        top:SetSize(spanW, size)
        top:SetTexCoord(0, 1, 1, 0)
        top:Show()
    else
        top:Hide()
    end

    local left = edges[3]
    left:ClearAllPoints()
    if spanH > 1 then
        left:SetPoint('TOPLEFT', region, 'TOPLEFT', 0, -size)
        left:SetSize(size, spanH)
        left:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
        left:Show()
    else
        left:Hide()
    end

    local right = edges[4]
    right:ClearAllPoints()
    if spanH > 1 then
        right:SetPoint('TOPRIGHT', region, 'TOPRIGHT', 0, -size)
        right:SetSize(size, spanH)
        right:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
        right:Show()
    else
        right:Hide()
    end

    local bottomRight = corners[1]
    bottomRight:ClearAllPoints()
    bottomRight:SetPoint('BOTTOMRIGHT', region, 'BOTTOMRIGHT', 0, 0)
    bottomRight:SetSize(size, size)
    bottomRight:SetTexCoord(0, 1, 0, 1)
    bottomRight:Show()

    local bottomLeft = corners[2]
    bottomLeft:ClearAllPoints()
    bottomLeft:SetPoint('BOTTOMLEFT', region, 'BOTTOMLEFT', 0, 0)
    bottomLeft:SetSize(size, size)
    bottomLeft:SetTexCoord(1, 0, 0, 1)
    bottomLeft:Show()

    local topRight = corners[3]
    topRight:ClearAllPoints()
    topRight:SetPoint('TOPRIGHT', region, 'TOPRIGHT', 0, 0)
    topRight:SetSize(size, size)
    topRight:SetTexCoord(0, 1, 1, 0)
    topRight:Show()

    local topLeft = corners[4]
    topLeft:ClearAllPoints()
    topLeft:SetPoint('TOPLEFT', region, 'TOPLEFT', 0, 0)
    topLeft:SetSize(size, size)
    topLeft:SetTexCoord(1, 0, 1, 0)
    topLeft:Show()
end

---Created as a child of `parent`. Do not reparent it.
---@param parent Frame
---@return Frame
function textureGlow:Ensure(parent)
    local glow = parent.TextureGlow
    if glow then
        return glow
    end

    glow = CreateFrame('Frame', nil, parent)
    glow:EnableMouse(false)
    if glow.SetMouseMotionEnabled then
        glow:SetMouseMotionEnabled(false)
    end
    if glow.SetMouseClickEnabled then
        glow:SetMouseClickEnabled(false)
    end
    glow:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 0) + 2)
    glow:Hide()

    glow.Bottom = createPiece(glow, BOTTOM_TEXTURE)
    glow.Edges = {
        createPiece(glow, EDGE_TEXTURE),
        createPiece(glow, EDGE_TEXTURE),
        createPiece(glow, EDGE_TEXTURE),
        createPiece(glow, EDGE_TEXTURE),
    }
    glow.Corners = {
        createPiece(glow, CORNER_TEXTURE),
        createPiece(glow, CORNER_TEXTURE),
        createPiece(glow, CORNER_TEXTURE),
        createPiece(glow, CORNER_TEXTURE),
    }

    local shown = glow:CreateAnimationGroup()
    shown:SetLooping('BOUNCE')
    local shownFade = shown:CreateAnimation('Alpha')
    shownFade:SetTarget(glow)
    shownFade:SetFromAlpha(1)
    shownFade:SetToAlpha(0.25)
    shownFade:SetDuration(0.5)
    glow.ShownPulse = shown
    glow.ShownFade = shownFade

    local assigned = glow:CreateAnimationGroup()
    assigned:SetLooping('NONE')
    local assignedHold = assigned:CreateAnimation('Alpha')
    assignedHold:SetTarget(glow)
    assignedHold:SetOrder(1)
    assignedHold:SetFromAlpha(1)
    assignedHold:SetToAlpha(1)
    assignedHold:SetDuration(1)
    local assignedFade = assigned:CreateAnimation('Alpha')
    assignedFade:SetTarget(glow)
    assignedFade:SetOrder(2)
    assignedFade:SetFromAlpha(1)
    assignedFade:SetToAlpha(0)
    assignedFade:SetDuration(0.25)
    glow.AssignedFlash = assigned
    glow.AssignedHold = assignedHold
    glow.AssignedFade = assignedFade

    parent.TextureGlow = glow
    return glow
end

function textureGlow:ConfigureAnimations(glow, maxAlpha, minAlpha, interval, assignDuration)
    glow.ShownFade:SetFromAlpha(maxAlpha)
    glow.ShownFade:SetToAlpha(minAlpha)
    glow.ShownFade:SetDuration(interval)
    glow.AssignedHold:SetFromAlpha(maxAlpha)
    glow.AssignedHold:SetToAlpha(maxAlpha)
    glow.AssignedHold:SetDuration(assignDuration)
    glow.AssignedFade:SetFromAlpha(maxAlpha)
    glow.AssignedFade:SetToAlpha(0)
end

---`options.kind` is `bottom` or `edge`.
---`options.size` is the border thickness in pixels. Bottom Glow stretches to the whole frame.
---@param glow Frame
---@param region Region
---@param options table|nil
function textureGlow:Apply(glow, region, options)
    options = options or {}
    local width, height = region:GetSize()
    if not width or width <= 0 then
        width = 40
    end
    if not height or height <= 0 then
        height = 40
    end

    local color = options.color or { r = 1, g = 0.82, b = 0, a = 1 }
    local blendMode = options.blendMode
    if not BLEND_MODES[blendMode] then
        blendMode = 'ADD'
    end
    glow:ClearAllPoints()
    glow:SetAllPoints(region)

    paint(glow.Bottom, color, blendMode)
    for index = 1, 4 do
        paint(glow.Edges[index], color, blendMode)
        paint(glow.Corners[index], color, blendMode)
    end

    if options.kind == 'edge' then
        glow.Bottom:Hide()
        local size = options.size or 18
        if size < 4 then
            size = 4
        end
        layoutBorder(glow, region, width, height, size)
        return
    end

    hidePieces(glow.Edges)
    hidePieces(glow.Corners)
    glow.Bottom:ClearAllPoints()
    glow.Bottom:SetAllPoints(region)
    glow.Bottom:SetTexCoord(0, 1, 0, 1)
    glow.Bottom:Show()
end

local function clearPiecePoints(texture)
    if texture then
        texture:ClearAllPoints()
    end
end

function textureGlow:Hide(glow)
    if not glow then
        return
    end
    if glow.ShownPulse then
        glow.ShownPulse:Stop()
    end
    if glow.AssignedFlash then
        glow.AssignedFlash:Stop()
    end
    -- Preview glows are anchored to the unit frame from inside the aura button.
    -- Drop those anchors while the preview is hidden so a live aura update does
    -- not keep a descendant tied to the unit frame. Adopted glows cannot be
    -- reanchored once auras are secret.
    if not glow.exuiAnimationsAdopted then
        glow:ClearAllPoints()
        clearPiecePoints(glow.Bottom)
        if glow.Edges then
            for index = 1, #glow.Edges do
                clearPiecePoints(glow.Edges[index])
            end
        end
        if glow.Corners then
            for index = 1, #glow.Corners do
                clearPiecePoints(glow.Corners[index])
            end
        end
    end
    glow:Hide()
end
