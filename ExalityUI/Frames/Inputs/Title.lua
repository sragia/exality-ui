---@class ExalityUI
local EXUI = select(2, ...)

--[[
Basically a dummy frame to fill space in options
]]

---@class EXUITitle
local title = EXUI:GetModule('title')

title.pool = {}

title.Init = function(self)
    self.pool = CreateFramePool('Frame', UIParent)
end

local function ConfigureFrame(f)
    f:SetSize(100, 30)
    f.SetFrameWidth = function(self, width)
        f:SetWidth(width)
    end
    f.SetOptionData = function(self, option) 
        self.optionData = option
        self.titleText:SetText(option.label)
    end

    local titleText = f:CreateFontString(nil, 'OVERLAY')
    titleText:SetFont(EXUI.const.fonts.DEFAULT, 18, 'OUTLINE')
    titleText:SetVertexColor(1, 1, 1, 1)
    titleText:SetShadowOffset(2, -2)
    titleText:SetShadowColor(249/255, 95/255, 9/255, 1)
    titleText:SetPoint('LEFT', 5, 0)
    titleText:SetWidth(0)
    f.titleText = titleText

    local bg = f:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXUI.const.textures.frame.titleBg)
    bg:SetVertexColor(1, 1, 1, 0.2)
    bg:SetPoint('TOPLEFT')
    bg:SetPoint('BOTTOMLEFT', 100, 0)
    f.bg = bg


    f.configured = true
end

---Create/Get Title element
---@param self EXUITitle
---@return Frame
title.Create = function(self)
    local f = self.pool:Acquire()
    if (not f.configured) then
        ConfigureFrame(f)
    end 
    f.Destroy = function(self)
        title.pool:Release(self)
    end

    f:Show()
    return f
end
