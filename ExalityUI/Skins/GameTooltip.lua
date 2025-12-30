---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIGameTooltipSkin
local gameTooltipSkin = EXUI:GetModule('skin-GameTooltip')

gameTooltipSkin.Init = function(self)
    skins:StripNineSlice(GameTooltip)

    local backdrop = CreateFrame('Frame', nil, GameTooltip, 'BackdropTemplate')
    backdrop:SetAllPoints()
    backdrop:SetFrameLevel(0)
    if (GameTooltip:GetFrameLevel() == 0) then
        GameTooltip:SetFrameLevel(1)
    end
    backdrop:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    backdrop:SetBackdropColor(0, 0, 0, 0.8)
    backdrop:SetBackdropBorderColor(0, 0, 0, 1)
end
