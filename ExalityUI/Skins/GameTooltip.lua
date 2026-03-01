---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIGameTooltipSkin
local gameTooltipSkin = EXUI:GetModule('skin-GameTooltip')

local function SkinTooltip(tooltip)
    skins:StripNineSlice(tooltip)

    local backdrop = CreateFrame('Frame', nil, tooltip)
    backdrop:SetAllPoints()
    backdrop:SetFrameLevel(0)
    if (tooltip:GetFrameLevel() == 0) then
        tooltip:SetFrameLevel(1)
    end
    local tex = backdrop:CreateTexture()
    tex:SetTexture(EXUI.const.textures.frame.solidBg)
    tex:SetAllPoints()
    tex:SetVertexColor(0, 0, 0, 0.6)

    local border = EXUI:AddPixelPerfectBorder(backdrop, 1)
    border:SetBorderColor(0, 0, 0, 1)

    if (tooltip.CompareHeader) then
        for _, region in ipairs(tooltip.CompareHeader:GetRegions()) do
            if (region.SetTexture) then
                region:SetTexture(nil)
                region:SetAlpha(0)
                region:Hide()
            end
        end
        local compareBackdrop = CreateFrame('Frame', nil, tooltip.CompareHeader)
        compareBackdrop:SetAllPoints()
        compareBackdrop:SetFrameLevel(0)
        local tex = compareBackdrop:CreateTexture()
        tex:SetTexture(EXUI.const.textures.frame.solidBg)
        tex:SetAllPoints()
        tex:SetVertexColor(0, 0, 0, 0.6)
        local compareBorder = EXUI:AddPixelPerfectBorder(compareBackdrop, 1)
        compareBorder:SetBorderColor(0, 0, 0, 1)


        if (tooltip.CompareHeader:GetFrameLevel() == 0) then
            tooltip.CompareHeader:SetFrameLevel(1)
        end
    end
    if (tooltip.StatusBar) then
        tooltip.StatusBar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
        local sbBackdrop = CreateFrame('Frame', nil, tooltip.StatusBar)
        sbBackdrop:SetAllPoints()
        sbBackdrop:SetFrameLevel(0)
        local tex = sbBackdrop:CreateTexture()
        tex:SetTexture(EXUI.const.textures.frame.solidBg)
        tex:SetAllPoints()
        tex:SetVertexColor(0, 0, 0, 0.4)
        local statusBarBorder = EXUI:AddPixelPerfectBorder(sbBackdrop, 1)
        statusBarBorder:SetBorderColor(0, 0, 0, 1)

        if (tooltip.StatusBar:GetFrameLevel() == 0) then
            tooltip.StatusBar:SetFrameLevel(1)
        end
        tooltip.StatusBar:SetHeight(5)
        tooltip.StatusBar.bg = sbBackdrop
    end
end

gameTooltipSkin.Init = function(self)
    SkinTooltip(GameTooltip)

    for _, child in pairs(GameTooltip.shoppingTooltips) do
        SkinTooltip(child)
    end
end
