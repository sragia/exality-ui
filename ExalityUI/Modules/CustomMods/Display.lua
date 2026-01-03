---@class ExalityUI
local EXUI = select(2, ...)


---@class EXUICustomModsDisplay
local display = EXUI:GetModule('custom-mods-display')

display.pool = CreateFramePool('Frame', UIParent, 'BackdropTemplate')
display.frames = {}

--[[
width/height (from display)
position (from display)

Backdrop (background and border) (from display)
Text (from trigger)
Icon (from trigger)
]]

display.Init = function(self)
end

display.Create = function(self, id)
    local frame = self.pool:Acquire()
    frame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())

    frame.Update = self.Update

    self.frames[id] = frame
end

display.Destroy = function(self, id)
    local frame = self.frames[id]

    if (frame) then
        self.pool:Release(frame)
        self.frames[id] = nil
    end
end

display.Update = function(frame, data)
    if (not data.show) then
        frame:Hide()
        return
    end
    frame:Show()
    EXUI:SetSize(frame, data.width, data.height)
    EXUI:SetPoint(frame, data.anchorPoint, UIParent, data.relativeAnchorPoint, data.XOff, data.YOff)
    if (data.backdrop) then
        frame:SetBackdropBorderColor(data.backdrop.borderColor.r, data.backdrop.borderColor.g,
            data.backdrop.borderColor.b, data.backdrop.borderColor.a)
        frame:SetBackdropColor(data.backdrop.bgColor.r, data.backdrop.bgColor.g, data.backdrop.bgColor.b,
            data.backdrop.bgColor.a)
    else
        frame:SetBackdropBorderColor(0, 0, 0, 0)
        frame:SetBackdropColor(0, 0, 0, 0)
    end

    -- if (data.text) then
    --     frame.Text:SetText(data.text)
    -- end
end
