---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIGameTooltipSkin
local gameTooltipSkin = EXUI:GetModule('skin-GameTooltip')

local function SkinTooltip(tooltip)
    skins:StripNineSlice(tooltip)

    local backdrop = CreateFrame('Frame', nil, tooltip, 'BackdropTemplate')
    backdrop:SetAllPoints()
    backdrop:SetFrameLevel(0)
    if (tooltip:GetFrameLevel() == 0) then
        tooltip:SetFrameLevel(1)
    end
    backdrop:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    backdrop:SetBackdropColor(0, 0, 0, 0.8)
    backdrop:SetBackdropBorderColor(0, 0, 0, 1)

    if (tooltip.CompareHeader) then
        for _, region in ipairs(tooltip.CompareHeader:GetRegions()) do
            if (region.SetTexture) then
                region:SetTexture(nil)
                region:SetAlpha(0)
                region:Hide()
            end
        end
        local compareBackdrop = CreateFrame('Frame', nil, tooltip.CompareHeader, 'BackdropTemplate')
        compareBackdrop:SetAllPoints()
        compareBackdrop:SetFrameLevel(0)
        compareBackdrop:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
        compareBackdrop:SetBackdropColor(0, 0, 0, 0.8)
        compareBackdrop:SetBackdropBorderColor(0, 0, 0, 1)
        if (tooltip.CompareHeader:GetFrameLevel() == 0) then
            tooltip.CompareHeader:SetFrameLevel(1)
        end
    end
    if (tooltip.StatusBar) then
        tooltip.StatusBar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
        local sbBackdrop = CreateFrame('Frame', nil, tooltip.StatusBar, 'BackdropTemplate')
        sbBackdrop:SetAllPoints()
        sbBackdrop:SetFrameLevel(0)
        sbBackdrop:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
        sbBackdrop:SetBackdropColor(0, 0, 0, 0.4)
        sbBackdrop:SetBackdropBorderColor(0, 0, 0, 1)
        if (tooltip.StatusBar:GetFrameLevel() == 0) then
            tooltip.StatusBar:SetFrameLevel(1)
        end
        tooltip.StatusBar.bg = sbBackdrop
    end
end

gameTooltipSkin.Init = function(self)
    SkinTooltip(GameTooltip)

    for _, child in pairs(GameTooltip.shoppingTooltips) do
        SkinTooltip(child)
    end
end
