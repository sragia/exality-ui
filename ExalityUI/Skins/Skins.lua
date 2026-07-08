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
    -- UIPanelButtonTemplate names its center piece Middle instead of Center.
    StripThreeSliceTexture(button.Middle)
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

local function GetTheme()
    return EXUI.const.theme
end

skins.StripTexture = function(self, texture)
    if (not texture or not texture.SetTexture) then return end
    StripTexture(texture)
end

---Strip named texture children (parentKeys) off a frame. Non-texture keys are skipped.
skins.StripRegions = function(self, frame, keys)
    if (not frame) then return end
    for _, key in ipairs(keys) do
        local region = frame[key]
        if (region and region.SetTexture and region.IsObjectType and region:IsObjectType('Texture')) then
            StripTexture(region)
        end
    end
end

---Strip every plain texture region directly on a frame (unnamed background tiles etc).
skins.StripAllTextures = function(self, frame)
    if (not frame or not frame.GetRegions) then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if (region:IsObjectType('Texture')) then
            StripTexture(region)
        end
    end
end

---Strip texture regions matching an atlas name; for decor without a parentKey.
skins.StripAtlasRegions = function(self, frame, atlasName)
    if (not frame or not frame.GetRegions) then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if (region:IsObjectType('Texture') and region.GetAtlas and region:GetAtlas() == atlasName) then
            StripTexture(region)
        end
    end
end

---Solid dark background behind a frame's content.
---@param options? { color?: number[], alpha?: number, level?: number }
skins.AddBackdrop = function(self, frame, options)
    options = options or {}
    if (not frame.exuiBackdrop) then
        local backdrop = CreateFrame('Frame', nil, frame)
        backdrop:SetAllPoints()
        backdrop:SetFrameLevel(options.level or 0)
        backdrop:EnableMouse(false)

        local bg = backdrop:CreateTexture(nil, 'BACKGROUND')
        bg:SetTexture(EXUI.const.textures.frame.solidBg)
        bg:SetAllPoints()

        backdrop.bg = bg
        frame.exuiBackdrop = backdrop
    end

    local color = options.color or GetTheme().backgroundDeep
    frame.exuiBackdrop.bg:SetVertexColor(color[1], color[2], color[3], options.alpha or color[4] or 1)
    frame.exuiBackdrop:Show()
    return frame.exuiBackdrop
end

---1px pixel-perfect border on an overlay child frame so it draws above Blizzard art.
---@param options? { thickness?: number, color?: number[], level?: number }
skins.AddBorder = function(self, frame, options)
    options = options or {}
    local thickness = options.thickness or 1

    if (not frame.exuiBorderOverlay) then
        local overlay = CreateFrame('Frame', nil, frame)
        overlay:EnableMouse(false)
        overlay:SetFrameLevel(options.level or 500)
        overlay.border = EXUI:AddPixelPerfectBorder(overlay, thickness, { register = false, layer = 'OVERLAY' })
        frame.exuiBorderOverlay = overlay
    end

    local overlay = frame.exuiBorderOverlay
    overlay:ClearAllPoints()
    overlay:SetAllPoints(frame)
    overlay.border:SetBorderColor(unpack(options.color or GetTheme().border))
    overlay.border:SetBorderThickness(thickness)
    overlay:Show()
    return overlay
end

---Minimal close button: strip the round red atlas art, keep just an X that tints red on hover.
---@param options? { iconSize?: number }
skins.SkinCloseButton = function(self, button, options)
    if (not button) then return end
    options = options or {}
    local th = GetTheme()

    if (not button.exuiCloseSkinned) then
        button.exuiCloseSkinned = true

        self:StripTexture(button:GetNormalTexture())
        self:StripTexture(button:GetPushedTexture())
        if (button.GetDisabledTexture) then self:StripTexture(button:GetDisabledTexture()) end
        if (button.GetHighlightTexture) then self:StripTexture(button:GetHighlightTexture()) end

        local icon = button:CreateTexture(nil, 'OVERLAY')
        icon:SetTexture(EXUI.const.textures.frame.closeIcon)
        icon:SetPoint('CENTER')
        button.exuiIcon = icon

        button:HookScript('OnEnter', function(btn)
            btn.exuiIcon:SetVertexColor(unpack(GetTheme().dangerHover))
        end)
        button:HookScript('OnLeave', function(btn)
            btn.exuiIcon:SetVertexColor(unpack(GetTheme().textMuted))
        end)
    end

    local iconSize = options.iconSize or 14
    button.exuiIcon:SetSize(iconSize, iconSize)
    button.exuiIcon:SetVertexColor(unpack(th.textMuted))
end

local function ResolveButtonRegion(button, key)
    if (key == 'NormalTexture') then return button:GetNormalTexture() end
    if (key == 'PushedTexture') then return button:GetPushedTexture() end
    if (key == 'HighlightTexture') then return button.GetHighlightTexture and button:GetHighlightTexture() end
    if (key == 'DisabledTexture') then return button.GetDisabledTexture and button:GetDisabledTexture() end
    return button[key]
end

---Flat icon-style button (minimap-style trackers, chevrons, ...): strip listed decoration,
---desaturate + tint the remaining art, accent tint on hover.
---@param options? { strip?: string[], tint?: string[], normalColor?: number[], hoverColor?: number[] }
skins.SkinIconButton = function(self, button, options)
    if (not button or button.exuiIconSkinned) then return end
    button.exuiIconSkinned = true
    options = options or {}

    local normalColor = options.normalColor or GetTheme().textMuted
    local hoverColor = options.hoverColor or GetTheme().accentLight

    for _, key in ipairs(options.strip or {}) do
        local region = ResolveButtonRegion(button, key)
        if (region and region.SetTexture) then
            StripTexture(region)
        end
    end

    local tinted = {}
    for _, key in ipairs(options.tint or { 'NormalTexture', 'PushedTexture' }) do
        local region = ResolveButtonRegion(button, key)
        if (region and region.SetDesaturated) then
            region:SetDesaturated(true)
            region:SetVertexColor(unpack(normalColor))
            table.insert(tinted, region)
        end
    end

    local function ApplyTint(color)
        for _, region in ipairs(tinted) do
            region:SetVertexColor(unpack(color))
        end
    end
    button:HookScript('OnEnter', function() ApplyTint(hoverColor) end)
    button:HookScript('OnLeave', function() ApplyTint(normalColor) end)
end

local PANEL_BUTTON_BG_MARGINS = 10
local PANEL_BUTTON_HIGHLIGHT_MARGINS = 10
local PANEL_BUTTON_FONT_SIZE = 12

skins.ApplyPanelButtonBackground = function(self, button)
    if (not button.exuiBg) then
        local bg = button:CreateTexture(nil, 'BACKGROUND', nil, 1)
        bg:SetAllPoints()
        button.exuiBg = bg
    end

    button.exuiBg:SetTexture(EXUI.const.textures.frame.inputs.buttonBg)
    button.exuiBg:SetTextureSliceMargins(PANEL_BUTTON_BG_MARGINS, PANEL_BUTTON_BG_MARGINS, PANEL_BUTTON_BG_MARGINS, PANEL_BUTTON_BG_MARGINS)
    button.exuiBg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    button.exuiBg:SetAlpha(1)
    button.exuiBg:Show()
end

local function ResolveButtonState(button, state)
    if (state) then return state end
    if (not button:IsEnabled()) then return 'DISABLED' end
    return button:GetButtonState() or 'NORMAL'
end

skins.ApplyPanelButtonState = function(self, button, state)
    if (not button.exuiBg) then return end
    state = ResolveButtonState(button, state)
    local th = GetTheme()
    if (state == 'DISABLED' or not button:IsEnabled()) then
        button.exuiBg:SetVertexColor(unpack(th.faded))
    elseif (state == 'PUSHED') then
        button.exuiBg:SetVertexColor(unpack(th.accentDark))
    else
        button.exuiBg:SetVertexColor(unpack(th.backgroundLight))
    end
end

skins.StylePanelButtonText = function(self, button, fontSize)
    local fontString = button:GetFontString()
    if (not fontString) then return end
    local th = GetTheme()
    fontString:SetDrawLayer('OVERLAY')
    fontString:SetFont(EXUI.const.fonts.DEFAULT, fontSize or PANEL_BUTTON_FONT_SIZE, 'OUTLINE')
    if (button:IsEnabled()) then
        fontString:SetTextColor(unpack(th.text))
    else
        fontString:SetTextColor(unpack(th.textMuted))
    end
end

skins.ApplyPanelButtonHighlight = function(self, button)
    if (button.exuiHighlightConfigured) then return end
    button.exuiHighlightConfigured = true

    if (button.SetHighlightAtlas and not button.exuiHighlightAtlasBlocked) then
        button.exuiHighlightAtlasBlocked = true
        button.SetHighlightAtlas = function()
            -- keep custom SetHighlightTexture
        end
    end

    button:SetHighlightTexture(EXUI.const.textures.skins.btnHighlight, 'BLEND')
    local highlight = button:GetHighlightTexture()
    if (not highlight) then return end

    highlight:SetTextureSliceMargins(PANEL_BUTTON_HIGHLIGHT_MARGINS, PANEL_BUTTON_HIGHLIGHT_MARGINS, PANEL_BUTTON_HIGHLIGHT_MARGINS, PANEL_BUTTON_HIGHLIGHT_MARGINS)
    highlight:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    highlight:SetVertexColor(unpack(GetTheme().accent))
    -- Undo a prior strip; the button widget drives visibility itself.
    highlight:SetAlpha(1)
end

local PANEL_BUTTON_STRIP_OPTIONS = { keepHighlight = true, blockHighlightAtlas = true }

---Full flat treatment for UIPanelButtonTemplate-style three-slice buttons.
---@param options? { fontSize?: number }
skins.SkinPanelButton = function(self, button, options)
    if (not button) then return end
    options = options or {}

    self:StripThreeSliceButton(button, PANEL_BUTTON_STRIP_OPTIONS)
    self:ApplyPanelButtonBackground(button)
    self:ApplyPanelButtonHighlight(button)
    self:StylePanelButtonText(button, options.fontSize)
    self:ApplyPanelButtonState(button, 'NORMAL')

    if (not button.exuiStateHooked) then
        button.exuiStateHooked = true
        local fontSize = options.fontSize
        button:HookScript('OnMouseDown', function(btn)
            if (btn:IsEnabled()) then skins:ApplyPanelButtonState(btn, 'PUSHED') end
        end)
        button:HookScript('OnMouseUp', function(btn)
            skins:ApplyPanelButtonState(btn)
        end)
        button:HookScript('OnDisable', function(btn)
            skins:ApplyPanelButtonState(btn, 'DISABLED')
            skins:StylePanelButtonText(btn, fontSize)
        end)
        button:HookScript('OnEnable', function(btn)
            skins:ApplyPanelButtonState(btn, 'NORMAL')
            skins:StylePanelButtonText(btn, fontSize)
        end)
        button:HookScript('OnShow', function(btn)
            skins:ApplyPanelButtonState(btn)
            skins:StylePanelButtonText(btn, fontSize)
        end)
    end
end

---Modern WowStyle1DropdownTemplate: flat dark box, 1px border, themed text and arrow.
skins.SkinModernDropdown = function(self, dropdown)
    if (not dropdown or dropdown.exuiSkinned) then return end
    dropdown.exuiSkinned = true
    local th = GetTheme()

    self:StripRegions(dropdown, { 'Background' })
    self:AddBackdrop(dropdown, { color = th.background, alpha = 0.9 })
    self:AddBorder(dropdown)

    if (dropdown.Arrow) then
        dropdown.Arrow:SetDesaturated(true)
        dropdown.Arrow:SetVertexColor(unpack(th.textMuted))
    end
    if (dropdown.Text) then
        dropdown.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, '')
        dropdown.Text:SetTextColor(unpack(th.text))
    end
end

---SearchBoxTemplate: flat dark input matching Exality edit boxes.
local SEARCH_BOX_FONT_SIZE = 10
local SEARCH_BOX_ICON_LEFT_PAD = 8
local SEARCH_BOX_ICON_SIZE = 10
local SEARCH_BOX_TEXT_LEFT_INSET = SEARCH_BOX_ICON_LEFT_PAD + SEARCH_BOX_ICON_SIZE + 6

local function RefreshSearchBoxBorder(searchBox)
    local chrome = searchBox.exuiChrome
    if (not chrome or not chrome.PPBorder) then return end
    EXUI:SnapFrameToPixels(chrome)
    chrome.PPBorder:SetBorderThickness(1)
end

skins.SkinSearchBox = function(self, searchBox)
    if (not searchBox or searchBox.exuiSkinned) then return end
    local th = GetTheme()

    self:StripRegions(searchBox, { 'Left', 'Right', 'Middle' })

    if (not searchBox.exuiChrome) then
        local chrome = CreateFrame('Frame', nil, searchBox:GetParent())
        chrome:SetPoint('TOPLEFT', searchBox, 'TOPLEFT', 0, 0)
        chrome:SetPoint('BOTTOMRIGHT', searchBox, 'BOTTOMRIGHT', 0, 0)
        chrome:SetFrameLevel(searchBox:GetFrameLevel() - 1)
        chrome:EnableMouse(false)

        local bg = chrome:CreateTexture(nil, 'BACKGROUND')
        bg:SetTexture(EXUI.const.textures.frame.inputs.editboxBg)
        bg:SetTextureSliceMargins(6, 6, 6, 6)
        bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        bg:SetAllPoints()
        chrome.bg = bg

        chrome.PPBorder = EXUI:AddPixelPerfectBorder(chrome, 1, { register = true, layer = 'OVERLAY' })
        searchBox.exuiChrome = chrome
    end

    searchBox.exuiChrome.bg:SetVertexColor(unpack(th.backgroundDeep))
    searchBox.exuiChrome.PPBorder:SetBorderColor(unpack(th.border))
    RefreshSearchBoxBorder(searchBox)

    local function ApplyBorderState(active)
        local border = searchBox.exuiChrome and searchBox.exuiChrome.PPBorder
        if (border) then
            local color = active and GetTheme().accent or GetTheme().border
            border:SetBorderColor(unpack(color))
        end
    end

    if (searchBox.SetFont) then
        searchBox:SetFont(EXUI.const.fonts.DEFAULT, SEARCH_BOX_FONT_SIZE, '')
    end
    if (searchBox.SetTextColor) then
        searchBox:SetTextColor(unpack(th.text))
    end

    if (searchBox.Instructions) then
        searchBox.Instructions:SetFont(EXUI.const.fonts.DEFAULT, SEARCH_BOX_FONT_SIZE, '')
        searchBox.Instructions:SetTextColor(unpack(th.textMuted))
        searchBox.Instructions:ClearAllPoints()
        searchBox.Instructions:SetPoint('TOPLEFT', searchBox, 'LEFT', SEARCH_BOX_TEXT_LEFT_INSET, 0)
        searchBox.Instructions:SetPoint('BOTTOMRIGHT', searchBox, 'RIGHT', -20, 0)
    end

    if (searchBox.searchIcon) then
        searchBox.searchIcon:ClearAllPoints()
        searchBox.searchIcon:SetSize(SEARCH_BOX_ICON_SIZE, SEARCH_BOX_ICON_SIZE)
        searchBox.searchIcon:SetPoint('LEFT', searchBox, 'LEFT', SEARCH_BOX_ICON_LEFT_PAD, 0)
        searchBox.searchIcon:SetDesaturated(true)
        searchBox.searchIcon:SetVertexColor(unpack(th.textMuted))
    end

    if (searchBox.SetTextInsets) then
        searchBox:SetTextInsets(SEARCH_BOX_TEXT_LEFT_INSET, 20, 0, 0)
    end

    local clearButton = searchBox.clearButton
    if (clearButton and clearButton.Icon) then
        clearButton.Icon:SetDesaturated(true)
        clearButton.Icon:SetVertexColor(unpack(th.textMuted))
        clearButton:HookScript('OnEnter', function()
            clearButton.Icon:SetVertexColor(unpack(GetTheme().accentLight))
        end)
        clearButton:HookScript('OnLeave', function()
            clearButton.Icon:SetVertexColor(unpack(GetTheme().textMuted))
        end)
    end

    searchBox:HookScript('OnShow', RefreshSearchBoxBorder)
    searchBox:HookScript('OnSizeChanged', RefreshSearchBoxBorder)
    searchBox:HookScript('OnEditFocusGained', function()
        ApplyBorderState(true)
    end)
    searchBox:HookScript('OnEditFocusLost', function()
        if (not searchBox:IsMouseOver()) then
            ApplyBorderState(false)
        end
    end)
    searchBox:HookScript('OnEnter', function()
        ApplyBorderState(true)
    end)
    searchBox:HookScript('OnLeave', function()
        if (not searchBox:HasFocus()) then
            ApplyBorderState(false)
        end
    end)

    searchBox.exuiSkinned = true
end

---Flat restyle for the code-created MinimalScrollBar (modern ScrollFrameTemplate scroll bar).
skins.SkinMinimalScrollBar = function(self, scrollBar)
    if (not scrollBar or scrollBar.exuiSkinned) then return end
    scrollBar.exuiSkinned = true
    local th = GetTheme()

    local track = scrollBar.Track
    if (track) then
        self:StripRegions(track, { 'Begin', 'Middle', 'End' })

        local thumb = track.Thumb
        if (thumb) then
            -- Alpha-only hide: the thumb mixin's OnSizeChanged reads Middle:GetAtlas()
            -- for texcoords and errors if the texture was wiped. SetAtlas on hover/press
            -- does not reset alpha, so the pieces stay invisible.
            for _, key in ipairs({ 'Begin', 'Middle', 'End' }) do
                local piece = thumb[key]
                if (piece) then
                    piece:SetAlpha(0)
                end
            end

            local bg = thumb:CreateTexture(nil, 'ARTWORK', nil, 7)
            bg:SetTexture(EXUI.const.textures.frame.solidBg)
            bg:SetPoint('TOPLEFT', 1, 0)
            bg:SetPoint('BOTTOMRIGHT', -1, 0)
            bg:SetVertexColor(unpack(th.border))
            thumb.exuiBg = bg

            thumb:HookScript('OnEnter', function(btn)
                btn.exuiBg:SetVertexColor(unpack(GetTheme().accent))
            end)
            thumb:HookScript('OnLeave', function(btn)
                btn.exuiBg:SetVertexColor(unpack(GetTheme().border))
            end)
        end
    end

    -- Stepper arrows: atlas swaps preserve desaturation and vertex color.
    for _, key in ipairs({ 'Back', 'Forward' }) do
        local stepper = scrollBar[key]
        if (stepper and stepper.Texture) then
            stepper.Texture:SetDesaturated(true)
            stepper.Texture:SetVertexColor(unpack(th.textMuted))
        end
    end
end

---Generic skin for the PortraitFrame/ButtonFrame template family (map, quest popup, ...).
---@param options? { hidePortrait?: boolean, titleSize?: number, backdropColor?: number[], backdropAlpha?: number, backdropAnchor?: Frame, skipBackdrop?: boolean, skipBorder?: boolean }
skins.SkinPanelFrame = function(self, frame, options)
    if (not frame) then return end
    options = options or {}
    local th = GetTheme()

    self:StripNineSlice(frame)
    self:StripRegions(frame, { 'Bg', 'TopTileStreaks', 'InsetBorderTop', 'Underlay' })

    if (frame.Inset) then
        self:StripNineSlice(frame.Inset)
        self:StripRegions(frame.Inset, { 'Bg' })
    end

    if (options.hidePortrait and frame.PortraitContainer) then
        -- Blizzard re-Shows the container (SetPortraitShown); alpha survives that.
        frame.PortraitContainer:SetAlpha(0)
    end

    local title = frame.TitleContainer and frame.TitleContainer.TitleText
    if (title) then
        title:SetFont(EXUI.const.fonts.DEFAULT, options.titleSize or 13, 'OUTLINE')
        title:SetTextColor(unpack(th.text))
    end

    if (frame.CloseButton) then
        self:SkinCloseButton(frame.CloseButton)
    end

    if (not options.skipBackdrop) then
        self:AddBackdrop(options.backdropAnchor or frame, {
            color = options.backdropColor,
            alpha = options.backdropAlpha,
        })
    end
    if (not options.skipBorder) then
        self:AddBorder(frame)
    end
end
