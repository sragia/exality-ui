---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

skins.NineSliceTextures = {
    'TopRightCorner',
    'TopEdge',
    'TopLeftCorner',
    'RightEdge',
    'BottomEdge',
    'LeftEdge',
    'Center',
    'BottomRightCorner',
    'BottomLeftCorner'
}
skins.StripNineSlice = function(self, frame)
    if (frame.NineSlice) then
        for _, texture in ipairs(self.NineSliceTextures) do
            local frame = frame.NineSlice[texture]
            frame:SetTexture(nil)
            frame:SetAlpha(0)
            frame:SetVertexColor(0, 0, 0, 0)
            frame:Hide()
            frame.SetTextureOriginal = frame.SetTexture
            frame.SetTexture = function(self, texture)
                -- noop
            end
        end
    end
end
