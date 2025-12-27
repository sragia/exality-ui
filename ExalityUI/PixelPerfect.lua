---@class ExalityUI
local EXUI = select(2, ...)


local pixelPerfect = EXUI:GetModule('pixel-perfect')

pixelPerfect.UIScale = 1
pixelPerfect.Mult = 1

pixelPerfect.Initialize = function(self)
    local _, screenHeight = GetPhysicalScreenSize()
    local perfect = 768 / screenHeight
    self.UIScale = UIParent:GetScale()
    self.Mult = perfect / self.UIScale
end

EXUI.ScalePixel = function(self, value)
    return PixelUtil.GetNearestPixelSize(value, pixelPerfect.UIScale) - 0.07
end

function EXUI:SetSize(frame, width, height)
    frame:SetSize(self:ScalePixel(width), self:ScalePixel(height))
end

function EXUI:SetHeight(frame, height)
    frame:SetHeight(self:ScalePixel(height))
end

function EXUI:SetWidth(frame, width)
    frame:SetWidth(self:ScalePixel(width))
end

function EXUI:SetPoint(frame, point, arg2, arg3, arg4, arg5)
    if (type(arg2) == 'number') then
        -- SetPoint(point, x, y)
        frame:SetPoint(point, self:ScalePixel(arg2), self:ScalePixel(arg3))
    else
        -- SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
        frame:SetPoint(point, arg2, arg3, self:ScalePixel(arg4), self:ScalePixel(arg5))
    end
end
