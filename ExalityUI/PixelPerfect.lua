---@class ExalityUI
local EXUI = select(2, ...)

local pixelPerfect = EXUI:GetModule('pixel-perfect')

pixelPerfect.UIScale = 1
pixelPerfect.borders = {}
pixelPerfect.snapFrames = {}

---@param region? Frame
function pixelPerfect:GetLayoutScale(region)
    if region and region.GetEffectiveScale then
        return region:GetEffectiveScale()
    end
    return UIParent:GetEffectiveScale()
end

---@param region? Frame
function EXUI:GetLayoutScale(region)
    return pixelPerfect:GetLayoutScale(region)
end

local function toPhysicalPixels(value, scale)
    return Round(value * scale / PixelUtil.GetPixelToUIUnitFactor())
end

local function fromPhysicalPixels(pixels, scale)
    return pixels * PixelUtil.GetPixelToUIUnitFactor() / scale
end

---Snap a UI-unit value to the nearest physical pixel at the given layout scale.
---@param value number
---@param region? Frame
---@param minPixels? number
function EXUI:ScalePixel(value, region, minPixels)
    return PixelUtil.GetNearestPixelSize(value, self:GetLayoutScale(region), minPixels)
end

---Convert a desired physical pixel count into exact UI units.
---@param pixelCount number
---@param region? Frame
function EXUI:ScalePixels(pixelCount, region)
    local scale = self:GetLayoutScale(region)
    return fromPhysicalPixels(pixelCount, scale)
end

---UI inset matching a border thickness, with optional extra padding.
---@param region? Frame
---@param thickness? number
---@param padding? number
function EXUI:GetBorderInset(region, thickness, padding)
    thickness = thickness or 1
    padding = padding or 0
    return self:ScalePixels(thickness, region) + padding
end

local ANCHOR_COORDS = {
    TOPLEFT = function(left, bottom, width, height)
        return left, bottom + height
    end,
    TOP = function(left, bottom, width, height)
        return left + width * 0.5, bottom + height
    end,
    TOPRIGHT = function(left, bottom, width, height)
        return left + width, bottom + height
    end,
    LEFT = function(left, bottom, width, height)
        return left, bottom + height * 0.5
    end,
    CENTER = function(left, bottom, width, height)
        return left + width * 0.5, bottom + height * 0.5
    end,
    RIGHT = function(left, bottom, width, height)
        return left + width, bottom + height * 0.5
    end,
    BOTTOMLEFT = function(left, bottom, width, height)
        return left, bottom
    end,
    BOTTOM = function(left, bottom, width, height)
        return left + width * 0.5, bottom
    end,
    BOTTOMRIGHT = function(left, bottom, width, height)
        return left + width, bottom
    end,
}

local function getAnchorCoord(left, bottom, width, height, anchor)
    local fn = ANCHOR_COORDS[anchor]
    if not fn then
        return left, bottom
    end
    return fn(left, bottom, width, height)
end

local function getRelativeAnchorCoord(relativeTo, relativePoint)
    local left, bottom, width, height = relativeTo:GetRect()
    if not left or not bottom or not width or not height then
        return 0, 0
    end
    return getAnchorCoord(left, bottom, width, height, relativePoint)
end

---Register a root frame for pixel snapping on UI scale refresh.
---@param frame Frame
function EXUI:RegisterSnapFrame(frame)
    table.insert(pixelPerfect.snapFrames, frame)
end

---Align a frame's screen rect to the physical pixel grid.
---@param frame Frame
function EXUI:SnapFrameToPixels(frame)
    local point, relativeTo, relativePoint = frame:GetPoint(1)
    if not point then
        return
    end
    relativeTo = relativeTo or UIParent
    relativePoint = relativePoint or point

    local scale = self:GetLayoutScale(frame)

    local left = frame:GetLeft()
    local bottom = frame:GetBottom()
    local width = frame:GetWidth()
    local height = frame:GetHeight()
    if not left or not bottom or not width or not height then
        return
    end

    local pxLeft = toPhysicalPixels(left, scale)
    local pxBottom = toPhysicalPixels(bottom, scale)
    local pxRight = toPhysicalPixels(left + width, scale)
    local pxTop = toPhysicalPixels(bottom + height, scale)

    if pxRight <= pxLeft then
        pxRight = pxLeft + 1
    end
    if pxTop <= pxBottom then
        pxTop = pxBottom + 1
    end

    local newWidth = fromPhysicalPixels(pxRight - pxLeft, scale)
    local newHeight = fromPhysicalPixels(pxTop - pxBottom, scale)
    local newLeft = fromPhysicalPixels(pxLeft, scale)
    local newBottom = fromPhysicalPixels(pxBottom, scale)

    frame:SetSize(newWidth, newHeight)

    local frameX, frameY = getAnchorCoord(newLeft, newBottom, newWidth, newHeight, point)
    local relX, relY = getRelativeAnchorCoord(relativeTo, relativePoint)
    local newXOfs = frameX - relX
    local newYOfs = frameY - relY

    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, newXOfs, newYOfs)
end

function EXUI:SetSize(frame, width, height)
    frame:SetSize(self:ScalePixel(width, frame), self:ScalePixel(height, frame))
end

function EXUI:SetHeight(frame, height)
    frame:SetHeight(self:ScalePixel(height, frame))
end

function EXUI:SetWidth(frame, width)
    frame:SetWidth(self:ScalePixel(width, frame))
end

function EXUI:SetPoint(frame, point, arg2, arg3, arg4, arg5)
    if (type(arg2) == 'number') then
        frame:SetPoint(point, self:ScalePixel(arg2, frame), self:ScalePixel(arg3, frame))
    else
        frame:SetPoint(point, arg2, arg3, self:ScalePixel(arg4, frame), self:ScalePixel(arg5, frame))
    end
end

local function configureBorderTexture(texture)
    texture:SetSnapToPixelGrid(true)
    texture:SetTexelSnappingBias(0)
end

local function applyBorderThickness(border, thickness, region)
    local size = EXUI:ScalePixels(thickness, region)
    local frame = border.anchor

    border.Top:ClearAllPoints()
    border.Top:SetHeight(size)
    border.Top:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    border.Top:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0)

    border.Bottom:ClearAllPoints()
    border.Bottom:SetHeight(size)
    border.Bottom:SetSnapToPixelGrid(false)
    local bottomNudge = EXUI:ScalePixels(1, region)
    border.Bottom:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, -bottomNudge)
    border.Bottom:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, -bottomNudge)

    border.Left:ClearAllPoints()
    border.Left:SetWidth(size)
    border.Left:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    border.Left:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, 0)

    border.Right:ClearAllPoints()
    border.Right:SetWidth(size)
    border.Right:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0)
    border.Right:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
end

function EXUI:ApplySolidBorder(frame, borderSize, borderColor, bgColor)
    borderSize = borderSize or 1
    frame:SetBackdrop(EXUI.const.backdrop.backgroundOnly)
    if bgColor then
        frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    end
    if not frame.PPBorder then
        frame.PPBorder = self:AddPixelPerfectBorder(frame, borderSize)
    else
        frame.PPBorder:SetBorderThickness(borderSize)
    end
    if borderColor then
        frame.PPBorder:SetBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    end
end

---Border textures live on the anchor frame so OVERLAY text stays above them.
---@param options? { layer?: string, register?: boolean }
function EXUI:AddPixelPerfectBorder(frame, thickness, options)
    thickness = thickness or 1
    options = options or {}
    local layer = options.layer or 'BORDER'
    local register = options.register ~= false

    local border = {
        anchor = frame,
        thicknessPixels = thickness,
    }

    border.Top = frame:CreateTexture(nil, layer, nil, 1)
    border.Top:SetTexture(EXUI.const.textures.frame.solidBg)
    configureBorderTexture(border.Top)

    border.Bottom = frame:CreateTexture(nil, layer, nil, 2)
    border.Bottom:SetTexture(EXUI.const.textures.frame.solidBg)
    configureBorderTexture(border.Bottom)

    border.Left = frame:CreateTexture(nil, layer, nil, 3)
    border.Left:SetTexture(EXUI.const.textures.frame.solidBg)
    configureBorderTexture(border.Left)

    border.Right = frame:CreateTexture(nil, layer, nil, 4)
    border.Right:SetTexture(EXUI.const.textures.frame.solidBg)
    configureBorderTexture(border.Right)

    applyBorderThickness(border, thickness, frame)

    border.SetBorderColor = function(self, r, g, b, a)
        self.Top:SetVertexColor(r, g, b, a)
        self.Bottom:SetVertexColor(r, g, b, a)
        self.Left:SetVertexColor(r, g, b, a)
        self.Right:SetVertexColor(r, g, b, a)
    end

    border.SetBorderThickness = function(self, nextThickness)
        self.thicknessPixels = nextThickness or self.thicknessPixels or 1
        applyBorderThickness(self, self.thicknessPixels, self.anchor)
    end

    if register then
        table.insert(pixelPerfect.borders, border)
    end
    return border
end

local function refreshUnitFrameBorder(frame)
    local elementFrame = frame.ElementFrame
    if elementFrame and elementFrame.PPBorder then
        elementFrame.PPBorder:SetBorderThickness(1)
    end
end

pixelPerfect.Refresh = function(self)
    local snapped = {}
    for i = #self.borders, 1, -1 do
        local border = self.borders[i]
        if border.anchor and border.anchor:IsShown() then
            if not snapped[border.anchor] then
                EXUI:SnapFrameToPixels(border.anchor)
                snapped[border.anchor] = true
            end
            border:SetBorderThickness(border.thicknessPixels)
            if border.anchor.ApplyContentInsets then
                border.anchor:ApplyContentInsets()
            end
        else
            table.remove(self.borders, i)
        end
    end

    for i = #self.snapFrames, 1, -1 do
        local frame = self.snapFrames[i]
        if frame and frame.IsShown and frame:IsShown() then
            EXUI:SnapFrameToPixels(frame)
            refreshUnitFrameBorder(frame)
        elseif not frame then
            table.remove(self.snapFrames, i)
        end
    end
end

pixelPerfect.Initialize = function(self)
    self.UIScale = UIParent:GetScale()
    self:Refresh()
end
