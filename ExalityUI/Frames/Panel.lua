local addonName = ...
---@class ExalityUI
local EXUI = select(2, ...)

--- @class EXUIPanelFrame
local panel = EXUI:GetModule('panel-frame')

panel.Init = function(self)
    panel.pool = CreateFramePool('Frame', UIParent)
end

local configure = function(frame)
    if (not frame.Texture) then
        local bg = frame:CreateTexture()
        frame.Texture = bg
        bg:SetTexture(EXUI.const.textures.frame.bg)
        bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
        bg:SetTexCoord(7 / 512, 505 / 512, 7 / 512, 505 / 512)
        bg:SetTextureSliceMargins(15, 15, 15, 15)
        bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
        bg:SetAllPoints()
    end
end

---@param self EXUIWindowFrame
---@return Frame
panel.Create = function(self)
    local f = self.pool:Acquire()
    if not f.configured then
        configure(f)
    end

    return f
end
