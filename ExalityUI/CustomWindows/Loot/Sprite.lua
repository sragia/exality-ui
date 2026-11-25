---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUILootSprite
local sprite = EXUI:GetModule('loot-sprite')

sprite.iconMask = [[Interface/Addons/ExalityUI/Assets/Images/Loot/icon-mask.png]]

local TEXTURE = [[Interface/Addons/ExalityUI/Assets/Images/Loot/sprite.png]]
local TEXTURE_W, TEXTURE_H = 423, 545

-- cell = texels drawn (incl. shadow), body = part that lines up with the target frame.
local RECTS = {
    itemBg = { cell = { 5, 6, 332, 73 }, body = { 10, 11, 327, 68 } },
    close = { cell = { 336, 9, 352, 25 }, body = { 338, 11, 350, 23 } },
    itemBorder = { cell = { 10, 81, 327, 138 }, body = { 10, 81, 327, 138 } },
    iconBg = { cell = { 5, 146, 54, 195 }, body = { 10, 151, 49, 190 } },
    iconBorder = { cell = { 60, 145, 111, 196 }, body = { 65, 150, 106, 191 } },
    tabBg = { cell = { 5, 206, 98, 236 }, body = { 10, 211, 93, 231 } },
    passBg = { cell = { 5, 247, 44, 286 }, body = { 10, 252, 39, 281 } },
    windowBg = { cell = { 5, 289, 197, 512 }, body = { 10, 294, 192, 507 } },
    windowBorder = { cell = { 209, 294, 391, 507 }, body = { 209, 294, 391, 507 } },
}

sprite.GetBodySize = function(self, key)
    local body = RECTS[key].body
    return body[3] - body[1] + 1, body[4] - body[2] + 1
end

sprite.Place = function(self, texture, key, target, outset, sliceMargin)
    local rect = RECTS[key]
    local cell, body = rect.cell, rect.body
    outset = outset or 0

    texture:SetTexture(TEXTURE)
    texture:SetTexCoord(cell[1] / TEXTURE_W, (cell[3] + 1) / TEXTURE_W, cell[2] / TEXTURE_H, (cell[4] + 1) / TEXTURE_H)
    texture:ClearAllPoints()
    texture:SetPoint('TOPLEFT', target, 'TOPLEFT', cell[1] - body[1] - outset, body[2] - cell[2] + outset)
    texture:SetPoint('BOTTOMRIGHT', target, 'BOTTOMRIGHT', cell[3] - body[3] + outset, body[4] - cell[4] - outset)

    if (sliceMargin) then
        texture:SetTextureSliceMargins(sliceMargin, sliceMargin, sliceMargin, sliceMargin)
        texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    end
end
