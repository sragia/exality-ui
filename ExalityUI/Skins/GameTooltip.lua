---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIGameTooltipSkin
local gameTooltipSkin = EXUI:GetModule('skin-GameTooltip')

-- Never SetFrameLevel on GameTooltip (or its Blizzard children): that permanently
-- taints the tooltip and breaks Blizzard widget layout on secret text heights
-- (map vignette / AreaPOI tooltips → UIWidgetTemplateTextWithState).
local function AddSolidBackdrop(frame, alpha)
    local tex = frame:CreateTexture(nil, 'BACKGROUND', nil, -8)
    tex:SetTexture(EXUI.const.textures.frame.solidBg)
    tex:SetAllPoints()
    tex:SetVertexColor(0, 0, 0, alpha)
    return tex
end

local function SkinTooltip(tooltip)
    if tooltip.exuiSkinned then return end
    tooltip.exuiSkinned = true

    skins:StripNineSlice(tooltip)

    AddSolidBackdrop(tooltip, 0.6)
    local border = EXUI:AddPixelPerfectBorder(tooltip, 1, { register = false, layer = 'BACKGROUND' })
    border:SetBorderColor(0, 0, 0, 1)

    if (tooltip.CompareHeader) then
        skins:StripAllTextures(tooltip.CompareHeader)
        AddSolidBackdrop(tooltip.CompareHeader, 0.6)
        local compareBorder = EXUI:AddPixelPerfectBorder(tooltip.CompareHeader, 1, {
            register = false,
            layer = 'BACKGROUND',
        })
        compareBorder:SetBorderColor(0, 0, 0, 1)
    end

    if (tooltip.StatusBar) then
        tooltip.StatusBar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
        tooltip.StatusBar.bg = AddSolidBackdrop(tooltip.StatusBar, 0.4)
        local statusBarBorder = EXUI:AddPixelPerfectBorder(tooltip.StatusBar, 1, {
            register = false,
            layer = 'BACKGROUND',
        })
        statusBarBorder:SetBorderColor(0, 0, 0, 1)
        tooltip.StatusBar:SetHeight(5)
    end
end

local function SkinAuraButtonTooltips()
    if not AuraContainerInbound or not AuraContainerInbound.SetTooltipBackdrop then
        return
    end

    local bgFile = EXUI.const.textures.frame.solidBg
        or [[Interface\BUTTONS\WHITE8X8.blp]]

    AuraContainerInbound.SetTooltipBackdrop({
        backdropInfo = {
            bgFile = bgFile,
            edgeFile = [[Interface\BUTTONS\WHITE8X8.blp]],
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        },
        borderColor = CreateColor(0, 0, 0, 1),
        centerColor = CreateColor(0, 0, 0, 0.6),
    })
end

gameTooltipSkin.Init = function(self)
    if (not skins:IsEnabled('GameTooltip')) then return end

    SkinTooltip(GameTooltip)

    for _, child in pairs(GameTooltip.shoppingTooltips) do
        SkinTooltip(child)
    end

    SkinAuraButtonTooltips()
end
