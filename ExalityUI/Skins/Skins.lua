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
local function StripTexture(texture)
    texture:SetTexture(nil)
    texture:SetAlpha(0)
    texture:SetVertexColor(0, 0, 0, 0)
    texture:Hide()
end

local function StripNineSliceContainer(nineSliceTextures, container)
    if (not container) then return end
    container.exuiNineSliceStripped = true
    for _, pieceName in ipairs(nineSliceTextures) do
        local piece = container[pieceName]
        if (piece and piece.SetTexture) then
            StripTexture(piece)
        end
    end
end

-- Re-strip after Blizzard reapplies a layout. Never replace piece methods with addon
-- functions: secure callers (e.g. GameTooltip_OnHide) get tainted and error on secret values.
hooksecurefunc(NineSliceUtil, 'ApplyLayout', function(container)
    if (container.exuiNineSliceStripped) then
        StripNineSliceContainer(skins.NineSliceTextures, container)
    end
end)

skins.StripNineSlice = function(self, frame)
    if (frame.NineSlice) then
        StripNineSliceContainer(self.NineSliceTextures, frame.NineSlice)
    end
    -- DialogBorderTemplate inherits NineSlicePanelTemplate directly (no .NineSlice child).
    StripNineSliceContainer(self.NineSliceTextures, frame)
end

local function StripThreeSliceTexture(texture)
    if (not texture) then return end
    StripTexture(texture)
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
