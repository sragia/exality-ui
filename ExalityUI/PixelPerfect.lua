---@class ExalityUI
local EXUI = select(2, ...)

local pixelPerfect = EXUI:GetModule('pixel-perfect')

pixelPerfect.UIScale = 1
pixelPerfect.borders = {}
pixelPerfect.snapFrames = {}
pixelPerfect.cachedUIParentScale = nil
pixelPerfect.pendingRounding = {}

local function isBlockedInCombat(region)
    if not InCombatLockdown() then
        return false
    end
    local isProtected = region:IsProtected()
    if issecretvalue(isProtected) then
        return true
    end
    return isProtected
end

local flushPendingRounding

-- False when the object denies tainted access (secret auras in delves). A missing
-- probe, a secret result, or an error all count as inaccessible.
local function isAccessible(region)
    if not region then
        return false
    end
    local ok, canAccess = pcall(function()
        local probe = region.CanBeAccessedInContext
        if type(probe) ~= 'function' then
            return false
        end
        local allowed = probe(region)
        if allowed == nil or issecretvalue(allowed) then
            return false
        end
        return allowed and true or false
    end)
    return ok and canAccess == true
end

local function collectDescendants(region, methodName)
    local ok, list = pcall(function()
        local method = region[methodName]
        if type(method) ~= 'function' then
            return nil
        end
        return { method(region) }
    end)
    if not ok or not list then
        return nil
    end
    return list
end

local function roundTree(region, recursive)
    if isBlockedInCombat(region) then
        local pending = pixelPerfect.pendingRounding
        pending[region] = pending[region] or recursive or false
        EXUI:RegisterEventHandler('PLAYER_REGEN_ENABLED', 'pixel-perfect-rounding', flushPendingRounding)
        return
    end

    if not region.__exuiSnapRoot and not region.__exuiNativeRound
        and pcall(region.SetRoundLayoutToNearestPixel, region, true) then
        region.__exuiNativeRound = true
    end

    if not recursive then
        return
    end

    local regions = collectDescendants(region, 'GetRegions')
    if regions then
        for _, child in ipairs(regions) do
            pcall(function()
                if not isAccessible(child) or child.__exuiNativeRound then
                    return
                end
                if pcall(child.SetRoundLayoutToNearestPixel, child, true) then
                    child.__exuiNativeRound = true
                end
            end)
        end
    end

    local children = collectDescendants(region, 'GetChildren')
    if children then
        for _, child in ipairs(children) do
            pcall(function()
                if not isAccessible(child) then
                    return
                end
                roundTree(child, true)
            end)
        end
    end
end

flushPendingRounding = function()
    EXUI:UnregisterEventHandler('PLAYER_REGEN_ENABLED', 'pixel-perfect-rounding')
    local pending = pixelPerfect.pendingRounding
    pixelPerfect.pendingRounding = {}
    for region, recursive in pairs(pending) do
        roundTree(region, recursive)
    end
end

---Let the engine round this region's layout to the physical pixel grid.
---Protected regions are deferred until combat ends.
---@param region? ScriptRegion
---@param recursive? boolean also apply to existing child regions and frames
---@return boolean enabled
function EXUI:EnableNativeRounding(region, recursive)
    if not region then
        return false
    end
    if region.__exuiSnapRoot and not recursive then
        return false
    end
    if region.__exuiNativeRound and not recursive then
        return true
    end
    roundTree(region, recursive)
    return region.__exuiNativeRound == true
end

function pixelPerfect:InvalidateScaleCache()
    self.cachedUIParentScale = nil
end

---@param region? Frame
function pixelPerfect:GetLayoutScale(region)
    if region and region ~= UIParent and region.GetEffectiveScale then
        return region:GetEffectiveScale()
    end
    if not self.cachedUIParentScale then
        self.cachedUIParentScale = UIParent:GetEffectiveScale()
    end
    return self.cachedUIParentScale
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

---Snap a UI-unit value to the nearest physical pixel at a precomputed layout scale.
---@param value number
---@param scale number
---@param minPixels? number
function EXUI:ScalePixelWithScale(value, scale, minPixels)
    return PixelUtil.GetNearestPixelSize(value, scale, minPixels)
end

---Snap a UI-unit value to the nearest physical pixel at the given layout scale.
---@param value number
---@param region? Frame
---@param minPixels? number
function EXUI:ScalePixel(value, region, minPixels)
    return self:ScalePixelWithScale(value, self:GetLayoutScale(region), minPixels)
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

-- Native rounding rounds anchor offsets, not edges, so a CENTER-anchored odd-pixel
-- root lands on half pixels. Roots keep Lua snapping; descendants use native rounding.
local function markSnapRoot(frame)
    frame.__exuiSnapRoot = true
    if frame.__exuiNativeRound and not isBlockedInCombat(frame)
        and pcall(frame.SetRoundLayoutToNearestPixel, frame, false) then
        frame.__exuiNativeRound = nil
    end
end

---Register a root frame for pixel snapping on UI scale refresh.
---@param frame Frame
function EXUI:RegisterSnapFrame(frame)
    markSnapRoot(frame)
    self:EnableNativeRounding(frame, true)
    table.insert(pixelPerfect.snapFrames, frame)
end

---Align a frame's screen rect to the physical pixel grid.
---@param frame Frame
function EXUI:SnapFrameToPixels(frame)
    markSnapRoot(frame)
    if isBlockedInCombat(frame) then
        return
    end

    local editorModule = EXUI:GetModule('editor')
    if editorModule and editorModule.enabled and frame.editor then
        return
    end

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
    if self:EnableNativeRounding(frame) then
        frame:SetSize(width, height)
        return
    end
    frame:SetSize(self:ScalePixel(width, frame), self:ScalePixel(height, frame))
end

function EXUI:SetHeight(frame, height)
    if self:EnableNativeRounding(frame) then
        frame:SetHeight(height)
        return
    end
    frame:SetHeight(self:ScalePixel(height, frame))
end

function EXUI:SetWidth(frame, width)
    if self:EnableNativeRounding(frame) then
        frame:SetWidth(width)
        return
    end
    frame:SetWidth(self:ScalePixel(width, frame))
end

function EXUI:SetPoint(frame, point, arg2, arg3, arg4, arg5)
    self:SetPointWithScale(frame, nil, point, arg2, arg3, arg4, arg5)
end

function EXUI:SetPointWithScale(frame, scale, point, arg2, arg3, arg4, arg5)
    if self:EnableNativeRounding(frame) then
        if (type(arg2) == 'number') then
            frame:SetPoint(point, arg2 or 0, arg3 or 0)
        else
            frame:SetPoint(point, arg2, arg3, arg4 or 0, arg5 or 0)
        end
        return
    end
    scale = scale or self:GetLayoutScale(frame)
    if (type(arg2) == 'number') then
        frame:SetPoint(point, self:ScalePixelWithScale(arg2 or 0, scale), self:ScalePixelWithScale(arg3 or 0, scale))
    else
        frame:SetPoint(point, arg2, arg3, self:ScalePixelWithScale(arg4 or 0, scale), self:ScalePixelWithScale(arg5 or 0, scale))
    end
end

local function configureBorderTexture(texture)
    texture:SetSnapToPixelGrid(true)
    texture:SetTexelSnappingBias(0)
    EXUI:EnableNativeRounding(texture)
end

local function applyBorderThickness(border, thickness, region)
    local size = EXUI:ScalePixels(thickness, region)
    local frame = border.anchor
    local sideOut = 0
    if border.outwardSides then
        sideOut = EXUI:ScalePixels(1, region)
    end
    local bottomOffset = 0
    if border.outwardBottom ~= false then
        bottomOffset = -EXUI:ScalePixels(1, region)
    end

    border.Top:ClearAllPoints()
    border.Top:SetHeight(size)
    border.Top:SetSnapToPixelGrid(false)
    border.Top:SetPoint('TOPLEFT', frame, 'TOPLEFT', -sideOut, 0)
    border.Top:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', sideOut, 0)

    border.Bottom:ClearAllPoints()
    border.Bottom:SetHeight(size)
    border.Bottom:SetSnapToPixelGrid(false)
    border.Bottom:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', -sideOut, bottomOffset)
    border.Bottom:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', sideOut, bottomOffset)

    border.Left:ClearAllPoints()
    border.Left:SetWidth(size)
    border.Left:SetSnapToPixelGrid(false)
    -- Sides stop at the top/bottom edges so translucent borders don't double up in the corners.
    border.Left:SetPoint('TOPLEFT', frame, 'TOPLEFT', -sideOut, -size)
    border.Left:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', -sideOut, bottomOffset + size)

    border.Right:ClearAllPoints()
    border.Right:SetWidth(size)
    border.Right:SetSnapToPixelGrid(false)
    border.Right:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', sideOut, -size)
    border.Right:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', sideOut, bottomOffset + size)
end

function EXUI:ApplySolidBorder(frame, borderSize, borderColor, bgColor, options)
    borderSize = borderSize or 1
    options = options or {}
    frame:SetBackdrop(EXUI.const.backdrop.backgroundOnly)
    if bgColor then
        frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    end
    if not frame.PPBorder then
        frame.PPBorder = self:AddPixelPerfectBorder(frame, borderSize, options)
    else
        if options.outwardBottom ~= nil then
            frame.PPBorder.outwardBottom = options.outwardBottom
        end
        frame.PPBorder:SetBorderThickness(borderSize)
    end
    if borderColor then
        frame.PPBorder:SetBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    end
end

---Border textures live on the anchor frame so OVERLAY text stays above them.
---@param options? { layer?: string, register?: boolean, outwardBottom?: boolean, outwardSides?: boolean }
function EXUI:AddPixelPerfectBorder(frame, thickness, options)
    thickness = thickness or 1
    options = options or {}
    local layer = options.layer or 'BORDER'
    local register = options.register ~= false
    EXUI:EnableNativeRounding(frame)

    local border = {
        anchor = frame,
        thicknessPixels = thickness,
        outwardBottom = options.outwardBottom,
        outwardSides = options.outwardSides,
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

    border.Show = function(self)
        self.Top:Show()
        self.Bottom:Show()
        self.Left:Show()
        self.Right:Show()
    end

    border.Hide = function(self)
        self.Top:Hide()
        self.Bottom:Hide()
        self.Left:Hide()
        self.Right:Hide()
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
    self:InvalidateScaleCache()
    local snapped = {}
    for i = #self.borders, 1, -1 do
        local border = self.borders[i]
        if border.anchor and border.anchor:IsShown() then
            if not snapped[border.anchor] and border.anchor:GetNumPoints() == 1 then
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
            EXUI:EnableNativeRounding(frame, true)
            refreshUnitFrameBorder(frame)
            if frame.ApplyContentInsets then
                frame:ApplyContentInsets()
            end
        elseif not frame then
            table.remove(self.snapFrames, i)
        end
    end
end

pixelPerfect.Initialize = function(self)
    self:InvalidateScaleCache()
    self.UIScale = UIParent:GetScale()
    self:Refresh()
end
