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
local function StripNineSliceContainer(nineSliceTextures, container)
    if (not container) then return end
    for _, pieceName in ipairs(nineSliceTextures) do
        local piece = container[pieceName]
        if (piece and piece.SetTexture) then
            piece:SetTexture(nil)
            piece:SetAlpha(0)
            piece:SetVertexColor(0, 0, 0, 0)
            piece:Hide()
            if (not piece.exuiStripped) then
                piece.exuiStripped = true
                piece.SetTextureOriginal = piece.SetTexture
                piece.SetAtlasOriginal = piece.SetAtlas
                piece.SetTexture = function()
                    -- noop
                end
                piece.SetAtlas = function()
                    -- noop
                end
            end
        end
    end
end

skins.StripNineSlice = function(self, frame)
    if (frame.NineSlice) then
        StripNineSliceContainer(self.NineSliceTextures, frame.NineSlice)
    end
    -- DialogBorderTemplate inherits NineSlicePanelTemplate directly (no .NineSlice child).
    StripNineSliceContainer(self.NineSliceTextures, frame)
end

local function StripThreeSliceTexture(texture)
    if (not texture) then return end
    texture:SetTexture(nil)
    texture:SetAlpha(0)
    texture:Hide()
    if (not texture.exuiStripped) then
        texture.exuiStripped = true
        texture.SetTextureOriginal = texture.SetTexture
        texture.SetAtlasOriginal = texture.SetAtlas
        texture.SetTexture = function()
            -- noop
        end
        texture.SetAtlas = function()
            -- noop
        end
    end
end

skins.StripThreeSliceButton = function(self, button, options)
    if (not button) then return end
    options = options or {}
    StripThreeSliceTexture(button.Left)
    StripThreeSliceTexture(button.Center)
    StripThreeSliceTexture(button.Right)
    if (button.SetHighlightAtlas and not button.exuiHighlightStripped and not options.keepHighlight) then
        button.exuiHighlightStripped = true
        button.SetHighlightAtlasOriginal = button.SetHighlightAtlas
        button.SetHighlightAtlas = function()
            -- noop
        end
    elseif (button.SetHighlightAtlas and not button.exuiHighlightStripped and options.blockHighlightAtlas) then
        button.exuiHighlightStripped = true
        button.SetHighlightAtlasOriginal = button.SetHighlightAtlas
        button.SetHighlightAtlas = function()
            -- noop: custom SetHighlightTexture
        end
    end
    if (not options.keepHighlight) then
        local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
        if (highlight) then
            highlight:Hide()
            highlight:SetAlpha(0)
        end
    end
end

skins.StripDialogHeader = function(self, header)
    if (not header) then return end
    if (header.LeftBG) then header.LeftBG:Hide() end
    if (header.RightBG) then header.RightBG:Hide() end
    if (header.CenterBG) then header.CenterBG:Hide() end
end
