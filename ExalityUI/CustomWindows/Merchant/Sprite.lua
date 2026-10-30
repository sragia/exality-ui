---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIMerchantWindowSprite
local sprite = EXUI:GetModule('merchant-window-sprite')

sprite.portraitMask = [[Interface/Addons/ExalityUI/Assets/Images/Vendor/npc-portrait-mask.png]]
sprite.iconMask = [[Interface/Addons/ExalityUI/Assets/Images/Vendor/item-icon-mask.png]]

local TEXTURE = [[Interface/Addons/ExalityUI/Assets/Images/Vendor/sprite.png]]
local TEXTURE_W, TEXTURE_H = 481, 556
local DISABLED_BRIGHTNESS = 0.45

-- Cells include each element's glow and shadow.
local RECTS = {
    filterOn = { 1, 3, 55, 53 },
    filterOff = { 56, 3, 108, 53 },
    chevronOn = { 109, 3, 143, 53 },
    chevronOff = { 144, 3, 178, 53 },
    cartOff = { 179, 3, 228, 53 },
    cartOn = { 229, 3, 278, 53 },
    -- Same size, same body position: differently sized cells snap to pixels differently and the icon jumps.
    repairItemOff = { 0, 56, 51, 120 },
    repairItemOn = { 58, 56, 109, 120 },
    repairGuildOff = { 117, 63, 167, 112 },
    repairGuildOn = { 170, 56, 233, 120 },
    sellOff = { 235, 63, 286, 112 },
    sellOn = { 288, 56, 353, 119 },
    repairAllOff = { 356, 63, 405, 112 },
    repairAllOn = { 408, 56, 471, 120 },
    dotOn = { 1, 130, 25, 155 },
    dotOff = { 26, 130, 49, 155 },
    pill = { 50, 130, 86, 155 },
    portraitBorder = { 2, 159, 106, 263 },
    iconBorder = { 108, 178, 177, 247 },
    itemBg = { 4, 274, 317, 361 },
    itemBorderHover = { 10, 372, 311, 447 },
    itemBorder = { 10, 455, 311, 530 },
}

sprite.Apply = function(self, texture, key, scale, mirrored)
    local rect = RECTS[key]
    local left, right = rect[1] / TEXTURE_W, (rect[3] + 1) / TEXTURE_W
    if (mirrored) then
        left, right = right, left
    end
    texture:SetTexture(TEXTURE)
    texture:SetTexCoord(left, right, rect[2] / TEXTURE_H, (rect[4] + 1) / TEXTURE_H)
    texture:SetSize((rect[3] - rect[1] + 1) * scale, (rect[4] - rect[2] + 1) * scale)
end

local function UpdateArt(button)
    local enabled = button:IsEnabled()
    local active = enabled and (button.forceOn or button.hovered)
    sprite:Apply(button.art, active and button.onKey or button.offKey, button.artScale, button.mirrored)
    local dimmed = not enabled and button.dimDisabled
    local brightness = dimmed and DISABLED_BRIGHTNESS or 1
    button.art:SetDesaturated(dimmed)
    button.art:SetVertexColor(brightness, brightness, brightness)
end

-- The art sits centred on the button and is larger than it, so glows spill past the hit rect.
sprite.CreateButton = function(self, parent, width, height, offKey, onKey, scale, mirrored)
    local button = CreateFrame('Button', nil, parent)
    button:SetSize(width, height)
    button.offKey = offKey
    button.onKey = onKey
    button.artScale = scale
    button.mirrored = mirrored
    button.UpdateArt = UpdateArt

    local art = button:CreateTexture(nil, 'ARTWORK')
    art:SetPoint('CENTER')
    button.art = art

    button:SetScript('OnEnter', function(frame)
        frame.hovered = true
        frame:UpdateArt()
    end)
    button:SetScript('OnLeave', function(frame)
        frame.hovered = nil
        frame:UpdateArt()
    end)
    button:UpdateArt()
    return button
end
