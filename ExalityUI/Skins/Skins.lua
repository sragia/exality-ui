---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUISkins
local skins = EXUI:GetModule('skins')

skins.list = {
    { key = 'GameTooltip',      label = 'Game Tooltip' },
    { key = 'GameMenu',         label = 'Game Menu' },
    { key = 'StaticPopup',      label = 'Dialog' },
    { key = 'DeathRecap',       label = 'Death Recap' },
    { key = 'WorldMap',         label = 'World Map' },
    { key = 'PlayerSpells',     label = 'Talents' },
    { key = 'ProfessionsBook',  label = 'Professions Book' },
    { key = 'EncounterJournal', label = 'Encounter Journal' },
    { key = 'PVEFrame',         label = 'Group Finder' },
    {
        key = 'BuffFrame',
        label = 'Hide Buff/Debuff Frames',
        defaultEnabled = false,
        tooltip =
        'Hides Blizzard\'s default player buff and debuff frames. Enable this only if you replace them with your own Aura Displays.',
    },
}

skins.GetEntryDefaultEnabled = function(self, key)
    for _, entry in ipairs(self.list) do
        if (entry.key == key) then
            return entry.defaultEnabled ~= false
        end
    end
    return true
end

skins.IsEnabled = function(self, key)
    if (data:GetDataByKey('skinsEnabled') == false) then
        return false
    end
    local db = data:GetDataByKey('skins')
    if (type(db) ~= 'table') then
        return self:GetEntryDefaultEnabled(key)
    end
    if (db[key] == nil) then
        return self:GetEntryDefaultEnabled(key)
    end
    return db[key] and true or false
end

skins.GetDefaultSkins = function(self)
    local defaults = {}
    for _, entry in ipairs(self.list) do
        defaults[entry.key] = entry.defaultEnabled ~= false
    end
    return defaults
end

skins.EnsureDefaults = function(self)
    local db = data:GetDataByKey('skins')
    if (type(db) ~= 'table' or not next(db)) then
        -- GetDataByKey returns a throwaway {} when the key is missing.
        db = self:GetDefaultSkins()
    else
        for _, entry in ipairs(self.list) do
            if (db[entry.key] == nil) then
                db[entry.key] = entry.defaultEnabled ~= false
            end
        end
    end
    data:SetDataByKey('skins', db)
end

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

local DEFAULT_BORDER_LEVEL_OFFSET = 5

local function RefreshAddBorderOverlay(frame)
    local overlay = frame and frame.exuiBorderOverlay
    local border = overlay and (overlay.border or overlay.PPBorder)
    if (not overlay or not border) then return end

    overlay:ClearAllPoints()
    overlay:SetAllPoints(frame)
    overlay:Show()

    local thickness = border.thicknessPixels or 1
    local borderWidth = EXUI:ScalePixels(thickness, overlay)
    local outward = EXUI:ScalePixels(thickness, overlay)

    border.Top:SetHeight(borderWidth)
    border.Top:ClearAllPoints()
    border.Top:SetPoint('TOPLEFT', overlay, 'TOPLEFT', 0, 0)
    border.Top:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', 0, 0)

    border.Left:SetWidth(borderWidth)
    border.Left:ClearAllPoints()
    border.Left:SetPoint('TOPLEFT', overlay, 'TOPLEFT', -outward, 0)
    border.Left:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', -outward, 0)

    border.Right:SetWidth(borderWidth)
    border.Right:ClearAllPoints()
    border.Right:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', outward, 0)
    border.Right:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', outward, 0)

    border.Bottom:SetHeight(borderWidth)
    border.Bottom:SetSnapToPixelGrid(false)
    border.Bottom:ClearAllPoints()
    border.Bottom:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', 0, -outward)
    border.Bottom:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', 0, -outward)

    border:Show()
end

local function HookAddBorderRefresh(frame)
    if (frame.exuiBorderHooks) then return end
    frame.exuiBorderHooks = true
    frame:HookScript('OnShow', function(self)
        RefreshAddBorderOverlay(self)
    end)
    frame:HookScript('OnSizeChanged', function(self)
        RefreshAddBorderOverlay(self)
    end)
end

---1px pixel-perfect border on an overlay child frame so it draws above Blizzard art.
---@param options? { thickness?: number, color?: number[], level?: number, levelOffset?: number }
skins.AddBorder = function(self, frame, options)
    options = options or {}
    local thickness = options.thickness or 1
    local levelOffset = options.levelOffset or DEFAULT_BORDER_LEVEL_OFFSET
    local frameLevel = options.level or ((frame:GetFrameLevel() or 1) + levelOffset)

    if (not frame.exuiBorderOverlay) then
        local overlay = CreateFrame('Frame', nil, frame)
        overlay:EnableMouse(false)
        overlay.border = EXUI:AddPixelPerfectBorder(overlay, thickness, { register = false, layer = 'OVERLAY' })
        frame.exuiBorderOverlay = overlay
        HookAddBorderRefresh(frame)
    end

    local overlay = frame.exuiBorderOverlay
    overlay:SetFrameLevel(frameLevel)
    overlay.border:SetBorderColor(unpack(options.color or GetTheme().border))
    overlay.border.thicknessPixels = thickness
    RefreshAddBorderOverlay(frame)
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

local PANEL_BUTTON_FONT_SIZE = 12
local PANEL_BUTTON_TEXT_Y_OFFSET = -1
local DIALOG_BUTTON_TEXT_Y_OFFSET = -1
local PANEL_BUTTON_STRIP_OPTIONS = { keepHighlight = false, blockHighlightAtlas = true }

skins.ApplyPanelButtonBackground = function(self, button)
    if (not button.exuiBg) then
        local bg = button:CreateTexture(nil, 'BACKGROUND', nil, 1)
        bg:SetTexture(EXUI.const.textures.frame.whiteTextured)
        bg:SetAllPoints()
        button.exuiBg = bg
    end

    button.exuiBg:SetTexture(EXUI.const.textures.frame.whiteTextured)
    button.exuiBg:SetAllPoints()
    button.exuiBg:SetAlpha(1)
    button.exuiBg:Show()
end

skins.ApplyPanelButtonState = function(self, button, state)
    if (not button.exuiBg) then return end

    local th = GetTheme()
    if (state == 'DISABLED' or not button:IsEnabled()) then
        button.exuiBg:SetVertexColor(unpack(th.faded))
        return
    end

    local resolved = state
    if (not resolved) then
        resolved = button:GetButtonState() or 'NORMAL'
    end

    if (resolved == 'PUSHED') then
        button.exuiBg:SetVertexColor(unpack(th.accentDark))
    elseif (resolved == 'HOVERED' or (resolved == 'NORMAL' and button:IsMouseOver())) then
        button.exuiBg:SetVertexColor(unpack(th.backgroundLight))
    else
        button.exuiBg:SetVertexColor(unpack(th.backgroundDeep))
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
    if (button.SetHighlightAtlas and not button.exuiHighlightAtlasBlocked) then
        button.exuiHighlightAtlasBlocked = true
        button.SetHighlightAtlas = function() end
    end

    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if (highlight) then
        StripTexture(highlight)
    end
end

local function StripClassicDialogButtonTextures(button)
    skins:StripTexture(button:GetNormalTexture())
    skins:StripTexture(button:GetPushedTexture())
    if (button.GetDisabledTexture) then
        skins:StripTexture(button:GetDisabledTexture())
    end
    if (button.GetHighlightTexture) then
        skins:StripTexture(button:GetHighlightTexture())
    end
end

local function HookPanelButtonState(button, fontSize)
    if (button.exuiStateHooked) then return end
    button.exuiStateHooked = true

    button:HookScript('OnEnter', function(btn)
        if (btn:IsEnabled()) then skins:ApplyPanelButtonState(btn, 'HOVERED') end
    end)
    button:HookScript('OnLeave', function(btn)
        skins:ApplyPanelButtonState(btn, 'NORMAL')
    end)
    button:HookScript('OnMouseDown', function(btn)
        if (btn:IsEnabled()) then skins:ApplyPanelButtonState(btn, 'PUSHED') end
    end)
    button:HookScript('OnMouseUp', function(btn)
        if (btn:IsEnabled() and btn:IsMouseOver()) then
            skins:ApplyPanelButtonState(btn, 'HOVERED')
        else
            skins:ApplyPanelButtonState(btn, 'NORMAL')
        end
    end)
    button:HookScript('OnDisable', function(btn)
        skins:ApplyPanelButtonState(btn, 'DISABLED')
        skins:StylePanelButtonText(btn, fontSize)
    end)
    button:HookScript('OnEnable', function(btn)
        skins:ApplyPanelButtonState(btn, btn:IsMouseOver() and 'HOVERED' or 'NORMAL')
        skins:StylePanelButtonText(btn, fontSize)
    end)
    button:HookScript('OnShow', function(btn)
        skins:ApplyPanelButtonState(btn)
        skins:StylePanelButtonText(btn, fontSize)
    end)
end

---@param options? { fontSize?: number }
skins.SkinPanelButton = function(self, button, options)
    if (not button) then return end
    options = options or {}

    self:StripThreeSliceButton(button, PANEL_BUTTON_STRIP_OPTIONS)
    self:ApplyPanelButtonHighlight(button)
    self:ApplyPanelButtonBackground(button)
    self:StylePanelButtonText(button, options.fontSize)
    self:ApplyPanelButtonState(button, 'NORMAL')
    self:AddBorder(button, { thickness = 1 })

    local fontString = button:GetFontString()
    if (fontString and not button.exuiPanelTextOffset) then
        button.exuiPanelTextOffset = true
        fontString:ClearAllPoints()
        fontString:SetPoint('CENTER', button, 'CENTER', 0, PANEL_BUTTON_TEXT_Y_OFFSET)
    end

    HookPanelButtonState(button, options.fontSize)
end

---@param options? { fontSize?: number }
skins.SkinDialogButton = function(self, button, options)
    if (not button) then return end
    options = options or {}

    StripClassicDialogButtonTextures(button)
    self:ApplyPanelButtonHighlight(button)
    self:ApplyPanelButtonBackground(button)
    self:StylePanelButtonText(button, options.fontSize)
    self:ApplyPanelButtonState(button, 'NORMAL')
    self:AddBorder(button, { thickness = 1 })

    local fontString = button:GetFontString()
    if (fontString and not button.exuiDialogTextOffset) then
        button.exuiDialogTextOffset = true
        fontString:ClearAllPoints()
        fontString:SetPoint('CENTER', button, 'CENTER', 0, DIALOG_BUTTON_TEXT_Y_OFFSET)
    end

    HookPanelButtonState(button, options.fontSize)
end

---Modern WowStyle1DropdownTemplate: flat dark box, 1px border, themed text and arrow.
local MODERN_DROPDOWN_FONT_SIZE = 12
local MODERN_DROPDOWN_MENU_FONT_SIZE = 11
local MODERN_DROPDOWN_CHEVRON_SIZE = 12
local MODERN_DROPDOWN_TEXT_LEFT_PAD = 10
local MODERN_DROPDOWN_CHEVRON_RIGHT_PAD = 10
local MODERN_DROPDOWN_MENU_HIGHLIGHT_ALPHA = 0.35
local MODERN_DROPDOWN_MENU_FONT_NAME = 'ExalityUI_ModernDropdownMenuFont'
local modernDropdownHooksInstalled = false

local function EnsureModernDropdownMenuFontObject()
    local font = _G[MODERN_DROPDOWN_MENU_FONT_NAME]
    if (not font) then
        font = CreateFont(MODERN_DROPDOWN_MENU_FONT_NAME)
        font:SetFont(EXUI.const.fonts.DEFAULT, MODERN_DROPDOWN_MENU_FONT_SIZE, 'OUTLINE')
    end
    return MODERN_DROPDOWN_MENU_FONT_NAME
end

local function IsExuiDropdownMenuOwner(region)
    while (region) do
        if (region.exuiSkinned) then
            return true
        end

        local owner = region.GetOwnerRegion and region:GetOwnerRegion()
        if (owner and owner ~= region) then
            region = owner
        else
            region = region:GetParent()
        end
    end

    return false
end

local function IsExuiDropdownMenu(menu)
    if (not menu) then return false end

    local current = menu
    while (current) do
        local menuFrame = current.ToProxy and current:ToProxy()
        if (menuFrame and IsExuiDropdownMenuOwner(menuFrame:GetOwnerRegion())) then
            return true
        end
        current = current.parentMenu
    end

    return false
end

local function IsExuiDropdownMenuFrame(menuFrame)
    if (not menuFrame) then return false end

    if (IsExuiDropdownMenuOwner(menuFrame:GetOwnerRegion())) then
        return true
    end

    if (Menu and Menu.GetManager) then
        local manager = Menu.GetManager()
        if (manager and manager.menus) then
            for _, menu in manager.menus:Enumerate() do
                local proxy = menu.ToProxy and menu:ToProxy()
                if (proxy == menuFrame and IsExuiDropdownMenu(menu)) then
                    return true
                end
            end
        end
    end

    return false
end

local function StyleModernDropdownMenuFont(fontString, enabled, hovered)
    if (not fontString or not fontString.SetFontObject) then return end

    fontString:SetFontObject(EnsureModernDropdownMenuFontObject())

    local th = GetTheme()
    if (hovered) then
        fontString:SetTextColor(unpack(th.white))
    elseif (enabled == false) then
        fontString:SetTextColor(unpack(th.textMuted))
    else
        fontString:SetTextColor(unpack(th.text))
    end
end

local function SkinModernDropdownMenuPanel(menuFrame)
    if (not menuFrame) then return end

    local th = GetTheme()
    local bg = menuFrame.exuiMenuBg

    if (not bg) then
        for _, region in ipairs({ menuFrame:GetRegions() }) do
            if (region:IsObjectType('Texture')) then
                local atlas = region.GetAtlas and region:GetAtlas()
                if (atlas == 'common-dropdown-bg') then
                    bg = region
                    menuFrame.exuiMenuBg = bg
                    break
                end
            end
        end
    end

    if (bg) then
        bg:ClearAllPoints()
        bg:SetAllPoints(menuFrame)
        bg:SetTexture(EXUI.const.textures.frame.solidBg)
        bg:SetTexCoord(0, 1, 0, 1)
        bg:SetVertexColor(unpack(th.backgroundDeep))
        bg:SetAlpha(0.98)
    end

    skins:AddBorder(menuFrame, { thickness = 1, level = 600 })
end

local function SkinModernDropdownMenuHighlight(element)
    local highlightFrame = element.HighlightBGTex
    if (not highlightFrame) then return end

    for _, region in ipairs({ highlightFrame:GetRegions() }) do
        if (region:IsObjectType('Texture')) then
            skins:StripTexture(region)
        end
    end

    if (not highlightFrame.exuiHighlight) then
        local highlight = highlightFrame:CreateTexture(nil, 'BACKGROUND')
        highlight:SetTexture(EXUI.const.textures.frame.solidBg)
        highlight:SetAllPoints()
        highlightFrame.exuiHighlight = highlight
    end

    local th = GetTheme()
    highlightFrame.exuiHighlight:SetVertexColor(th.accent[1], th.accent[2], th.accent[3],
        MODERN_DROPDOWN_MENU_HIGHLIGHT_ALPHA)
end

local function IsMenuElementEnabled(element)
    if (element.IsEnabled) then
        return element:IsEnabled()
    end
    return true
end

local function WrapModernDropdownMenuHover(element)
    if (not element) then return end

    local onEnter = element:GetScript('OnEnter')
    if (onEnter and onEnter ~= element.exuiHoverEnterWrapper and type(onEnter) == 'function') then
        local originalOnEnter = onEnter
        local wrapper = function(button)
            if (type(originalOnEnter) == 'function') then
                originalOnEnter(button)
            end
            StyleModernDropdownMenuFont(button.Text, IsMenuElementEnabled(button), true)
            StyleModernDropdownMenuFont(button.fontString, IsMenuElementEnabled(button), true)
        end
        element.exuiHoverEnterWrapper = wrapper
        element:SetScript('OnEnter', wrapper)
    end

    local onLeave = element:GetScript('OnLeave')
    if (onLeave and onLeave ~= element.exuiHoverLeaveWrapper and type(onLeave) == 'function') then
        local originalOnLeave = onLeave
        local wrapper = function(button)
            if (type(originalOnLeave) == 'function') then
                originalOnLeave(button)
            end
            StyleModernDropdownMenuFont(button.Text, IsMenuElementEnabled(button), false)
            StyleModernDropdownMenuFont(button.fontString, IsMenuElementEnabled(button), false)
        end
        element.exuiHoverLeaveWrapper = wrapper
        element:SetScript('OnLeave', wrapper)
    end
end

local function SkinModernDropdownMenuElement(element)
    if (not element) then return end

    local enabled = element.IsEnabled and element:IsEnabled()

    StyleModernDropdownMenuFont(element.Text, enabled, false)
    StyleModernDropdownMenuFont(element.fontString, enabled, false)

    SkinModernDropdownMenuHighlight(element)
    WrapModernDropdownMenuHover(element)

    if (element.arrow) then
        element.arrow:SetTexture(EXUI.const.textures.frame.icons.chevronRight)
        element.arrow:SetSize(10, 10)
        element.arrow:SetDesaturated(true)
        element.arrow:SetVertexColor(unpack(GetTheme().textMuted))
    end

    for _, region in ipairs({ element:GetRegions() }) do
        if (region:IsObjectType('Texture')) then
            local file = region.GetTexture and region:GetTexture()
            if (file == [[Interface\Common\UI-TooltipDivider-Transparent]]) then
                skins:StripTexture(region)
                region:SetTexture(EXUI.const.textures.frame.solidBg)
                region:SetHeight(EXUI:ScalePixel(1, element, 1))
                region:SetVertexColor(unpack(GetTheme().border))
                region:Show()
            end
        end
    end
end

local function RestyleModernDropdownMenu(menu)
    if (not menu or not menu.ToProxy) then return end
    if (not IsExuiDropdownMenu(menu)) then return end

    local menuFrame = menu:ToProxy()
    SkinModernDropdownMenuPanel(menuFrame)

    if (menu.frames) then
        for _, element in menu.frames:Enumerate() do
            SkinModernDropdownMenuElement(element)
        end
    end
end

local function ApplyModernDropdownArrow(dropdown)
    local arrow = dropdown.exuiChevron
    if (not arrow) then return end

    local th = GetTheme()

    if (dropdown:IsEnabled()) then
        if (dropdown:IsMouseOver()) then
            arrow:SetVertexColor(unpack(th.white))
        else
            arrow:SetVertexColor(unpack(th.textMuted))
        end
    else
        arrow:SetVertexColor(unpack(th.textMuted))
    end

    if (dropdown.IsMenuOpen and dropdown:IsMenuOpen()) then
        arrow:SetRotation(math.rad(180))
    else
        arrow:SetRotation(0)
    end
end

local function BlockDropdownStateTexture(texture)
    if (not texture or texture.exuiStateTextureBlocked) then return end
    texture.exuiStateTextureBlocked = true
    skins:StripTexture(texture)
    texture.SetAtlas = function() end
    texture:Hide()
end

---Re-anchor dropdown chrome so 1px borders land on the pixel grid and stay inside clip rects.
local function RefreshModernDropdownChrome(dropdown)
    if (not dropdown or not dropdown.exuiSkinned) then return end

    local borderWidth = EXUI:ScalePixel(1, dropdown, 1)
    local outward = EXUI:ScalePixels(1, dropdown)

    if (dropdown.exuiBg) then
        dropdown.exuiBg:ClearAllPoints()
        dropdown.exuiBg:SetPoint('TOPLEFT', dropdown, 'TOPLEFT', borderWidth, -borderWidth)
        dropdown.exuiBg:SetPoint('BOTTOMRIGHT', dropdown, 'BOTTOMRIGHT', -borderWidth, borderWidth)
        dropdown.exuiBg:Show()
    end

    local overlay = dropdown.exuiBorderOverlay
    if (not overlay) then return end

    overlay:SetFrameLevel((dropdown:GetFrameLevel() or 1) + DEFAULT_BORDER_LEVEL_OFFSET)
    overlay:ClearAllPoints()
    overlay:SetAllPoints(dropdown)

    local border = overlay.PPBorder
    if (not border) then return end

    border.Top:SetHeight(borderWidth)
    border.Top:ClearAllPoints()
    border.Top:SetPoint('TOPLEFT', overlay, 'TOPLEFT', 0, 0)
    border.Top:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', 0, 0)

    border.Left:SetWidth(borderWidth)
    border.Left:ClearAllPoints()
    border.Left:SetPoint('TOPLEFT', overlay, 'TOPLEFT', -outward, 0)
    border.Left:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', -outward, 0)

    border.Right:SetWidth(borderWidth)
    border.Right:ClearAllPoints()
    border.Right:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', outward, 0)
    border.Right:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', outward, 0)

    border.Bottom:SetHeight(borderWidth)
    border.Bottom:SetSnapToPixelGrid(false)
    border.Bottom:ClearAllPoints()
    border.Bottom:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', 0, -outward)
    border.Bottom:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', 0, -outward)

    border.Top:Show()
    border.Left:Show()
    border.Right:Show()
    border.Bottom:Show()
end

local function InstallModernDropdownHooks()
    if (modernDropdownHooksInstalled) then return end
    if (not WowStyle1DropdownMixin or not MenuMixin or not MenuStyle1Mixin or not DropdownButtonMixin) then return end
    modernDropdownHooksInstalled = true

    if (WowStyle1DropdownMixin) then
        hooksecurefunc(WowStyle1DropdownMixin, 'OnButtonStateChanged', function(dropdown)
            if (not dropdown.exuiSkinned) then return end

            BlockDropdownStateTexture(dropdown.Background)
            BlockDropdownStateTexture(dropdown.Arrow)
            ApplyModernDropdownArrow(dropdown)

            local text = dropdown.Text
            if (not text) then return end

            local th = GetTheme()
            if (dropdown:IsEnabled()) then
                text:SetTextColor(unpack(th.text))
            else
                text:SetTextColor(unpack(th.textMuted))
            end
        end)

        hooksecurefunc(WowStyle1DropdownMixin, 'OnShow', function(dropdown)
            if (not dropdown.exuiSkinned) then return end
            RefreshModernDropdownChrome(dropdown)
            ApplyModernDropdownArrow(dropdown)
        end)
    end

    if (MenuStyle1Mixin) then
        hooksecurefunc(MenuStyle1Mixin, 'Generate', function(menuFrame)
            if (IsExuiDropdownMenuFrame(menuFrame)) then
                SkinModernDropdownMenuPanel(menuFrame)
            end
        end)
    end

    if (MenuMixin) then
        hooksecurefunc(MenuMixin, 'PerformLayout', function(menu)
            RestyleModernDropdownMenu(menu)
        end)
    end

    if (DropdownButtonMixin) then
        hooksecurefunc(DropdownButtonMixin, 'OnMenuOpened', function(dropdown, menu)
            if (not dropdown.exuiSkinned) then return end
            RestyleModernDropdownMenu(menu)
        end)
    end
end

---@param options? { fontSize?: number }
skins.SkinModernDropdown = function(self, dropdown, options)
    if (not dropdown or dropdown.exuiSkinned) then return end
    dropdown.exuiSkinned = true
    options = options or {}
    local th = GetTheme()
    local fontSize = options.fontSize or MODERN_DROPDOWN_FONT_SIZE

    InstallModernDropdownHooks()

    self:StripRegions(dropdown, { 'Background' })
    BlockDropdownStateTexture(dropdown.Background)
    BlockDropdownStateTexture(dropdown.Arrow)

    if (dropdown.exuiBackdrop) then
        dropdown.exuiBackdrop:Hide()
    end

    if (not dropdown.exuiBg) then
        local bg = dropdown:CreateTexture(nil, 'BACKGROUND', nil, 0)
        bg:SetTexture(EXUI.const.textures.frame.solidBg)
        dropdown.exuiBg = bg
    end

    if (not dropdown.exuiBorderOverlay) then
        local overlay = CreateFrame('Frame', nil, dropdown)
        overlay:SetAllPoints()
        overlay:EnableMouse(false)
        overlay.PPBorder = EXUI:AddPixelPerfectBorder(overlay, 1, { register = false, layer = 'OVERLAY' })
        dropdown.exuiBorderOverlay = overlay
    end
    dropdown.exuiBorderOverlay:SetFrameLevel((dropdown:GetFrameLevel() or 1) + DEFAULT_BORDER_LEVEL_OFFSET)

    RefreshModernDropdownChrome(dropdown)

    if (not dropdown.exuiChevron) then
        local chevron = dropdown:CreateTexture(nil, 'OVERLAY', nil, 2)
        chevron:SetTexture(EXUI.const.textures.frame.inputs.chevronDown)
        chevron:SetSize(MODERN_DROPDOWN_CHEVRON_SIZE, MODERN_DROPDOWN_CHEVRON_SIZE)
        chevron:SetPoint('RIGHT', dropdown, 'RIGHT', -MODERN_DROPDOWN_CHEVRON_RIGHT_PAD, 0)
        chevron:SetDesaturated(true)
        dropdown.exuiChevron = chevron
    end

    dropdown.exuiBg:SetVertexColor(unpack(th.background))
    dropdown.exuiBorderOverlay.PPBorder:SetBorderColor(unpack(th.border))

    ApplyModernDropdownArrow(dropdown)

    if (dropdown.Text) then
        dropdown.Text:SetFont(EXUI.const.fonts.DEFAULT, fontSize, '')
        dropdown.Text:ClearAllPoints()
        dropdown.Text:SetPoint('LEFT', dropdown, 'LEFT', MODERN_DROPDOWN_TEXT_LEFT_PAD, 0)
        dropdown.Text:SetPoint('RIGHT', dropdown.exuiChevron, 'LEFT', -6, 0)
        dropdown.Text:SetTextColor(unpack(th.text))
    end

    local function ApplyBorderState(active)
        local border = dropdown.exuiBorderOverlay and dropdown.exuiBorderOverlay.PPBorder
        if (border) then
            local color = active and GetTheme().accent or GetTheme().border
            border:SetBorderColor(unpack(color))
        end
    end

    dropdown:HookScript('OnEnter', function()
        ApplyBorderState(true)
        ApplyModernDropdownArrow(dropdown)
    end)
    dropdown:HookScript('OnLeave', function()
        ApplyBorderState(false)
        ApplyModernDropdownArrow(dropdown)
    end)
    dropdown:HookScript('OnMouseDown', function()
        ApplyBorderState(true)
    end)
    dropdown:HookScript('OnMouseUp', function()
        ApplyBorderState(dropdown:IsMouseOver())
        ApplyModernDropdownArrow(dropdown)
    end)
    dropdown:HookScript('OnShow', function()
        RefreshModernDropdownChrome(dropdown)
        ApplyModernDropdownArrow(dropdown)
    end)
    dropdown:HookScript('OnSizeChanged', function()
        RefreshModernDropdownChrome(dropdown)
    end)
end

---Shared chrome for search/edit/input-scroll fields (same edge math as modern dropdowns).
local function BlockInputBoxSideTextures(editBox)
    for _, key in ipairs({ 'Left', 'Right', 'Middle' }) do
        local texture = editBox[key]
        if (texture and not texture.exuiStateTextureBlocked) then
            texture.exuiStateTextureBlocked = true
            skins:StripTexture(texture)
            texture.SetAtlas = function() end
            texture.SetTexture = function() end
            texture:Hide()
        end
    end
end

local function EnsureInputFieldChrome(frame, bgColor)
    local th = GetTheme()
    if (not frame.exuiBg) then
        local bg = frame:CreateTexture(nil, 'BACKGROUND', nil, 0)
        bg:SetTexture(EXUI.const.textures.frame.solidBg)
        frame.exuiBg = bg
    end

    if (not frame.exuiBorderOverlay) then
        local overlay = CreateFrame('Frame', nil, frame)
        overlay:EnableMouse(false)
        overlay.PPBorder = EXUI:AddPixelPerfectBorder(overlay, 1, { register = false, layer = 'OVERLAY' })
        frame.exuiBorderOverlay = overlay
    end
    frame.exuiBorderOverlay:SetFrameLevel((frame:GetFrameLevel() or 1) + DEFAULT_BORDER_LEVEL_OFFSET)

    frame.exuiBg:SetVertexColor(unpack(bgColor or th.background))
    frame.exuiBorderOverlay.PPBorder:SetBorderColor(unpack(th.border))
end

local function RefreshInputFieldChrome(frame)
    if (not frame or not frame.exuiSkinned) then return end

    local borderWidth = EXUI:ScalePixel(1, frame, 1)
    local outward = EXUI:ScalePixels(1, frame)

    if (frame.exuiBg) then
        frame.exuiBg:ClearAllPoints()
        frame.exuiBg:SetPoint('TOPLEFT', frame, 'TOPLEFT', borderWidth, -borderWidth)
        frame.exuiBg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -borderWidth, borderWidth)
        frame.exuiBg:Show()
    end

    local overlay = frame.exuiBorderOverlay
    if (not overlay or not overlay.PPBorder) then return end

    overlay:SetFrameLevel((frame:GetFrameLevel() or 1) + DEFAULT_BORDER_LEVEL_OFFSET)
    overlay:ClearAllPoints()
    overlay:SetAllPoints(frame)

    local border = overlay.PPBorder
    border.Top:SetHeight(borderWidth)
    border.Top:ClearAllPoints()
    border.Top:SetPoint('TOPLEFT', overlay, 'TOPLEFT', 0, 0)
    border.Top:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', 0, 0)

    border.Left:SetWidth(borderWidth)
    border.Left:ClearAllPoints()
    border.Left:SetPoint('TOPLEFT', overlay, 'TOPLEFT', -outward, 0)
    border.Left:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', -outward, 0)

    border.Right:SetWidth(borderWidth)
    border.Right:ClearAllPoints()
    border.Right:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', outward, 0)
    border.Right:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', outward, 0)

    border.Bottom:SetHeight(borderWidth)
    border.Bottom:SetSnapToPixelGrid(false)
    border.Bottom:ClearAllPoints()
    border.Bottom:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', 0, -outward)
    border.Bottom:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', 0, -outward)

    border.Top:Show()
    border.Left:Show()
    border.Right:Show()
    border.Bottom:Show()
end

local function HookInputFieldChromeRefresh(frame)
    if (frame.exuiChromeHooks) then return end
    frame.exuiChromeHooks = true
    frame:HookScript('OnShow', function(self)
        RefreshInputFieldChrome(self)
    end)
    frame:HookScript('OnSizeChanged', function(self)
        RefreshInputFieldChrome(self)
    end)
end

local function ApplyInputFieldBorderState(frame, active)
    local border = frame.exuiBorderOverlay and frame.exuiBorderOverlay.PPBorder
    if (border) then
        border:SetBorderColor(unpack(active and GetTheme().accent or GetTheme().border))
    end
end

---Flat panel/inset chrome: solid fill + pixel-perfect 1px border (same math as input fields).
---@param options? { color?: number[], alpha?: number }
skins.ApplyFlatChrome = function(self, frame, options)
    if (not frame) then return end
    options = options or {}
    local th = GetTheme()
    local color = options.color or th.backgroundDeep
    local alpha = options.alpha
    local bgColor = color
    if (alpha and color) then
        bgColor = { color[1], color[2], color[3], alpha }
    end

    frame.exuiSkinned = true
    EnsureInputFieldChrome(frame, bgColor)
    if (frame.exuiBg and alpha) then
        frame.exuiBg:SetVertexColor(color[1], color[2], color[3], alpha)
    end
    HookInputFieldChromeRefresh(frame)
    RefreshInputFieldChrome(frame)
end

local function HookInputFieldFocusBorder(frame)
    if (frame.exuiFocusBorderHooks) then return end
    frame.exuiFocusBorderHooks = true

    frame:HookScript('OnEditFocusGained', function(self)
        ApplyInputFieldBorderState(self, true)
    end)
    frame:HookScript('OnEditFocusLost', function(self)
        if (not self:IsMouseOver()) then
            ApplyInputFieldBorderState(self, false)
        end
    end)
    frame:HookScript('OnEnter', function(self)
        ApplyInputFieldBorderState(self, true)
    end)
    frame:HookScript('OnLeave', function(self)
        if (not self.HasFocus or not self:HasFocus()) then
            ApplyInputFieldBorderState(self, false)
        end
    end)
end

---SearchBoxTemplate: flat dark input matching Exality edit boxes.
local SEARCH_BOX_FONT_SIZE = 10
local SEARCH_BOX_ICON_LEFT_PAD = 8
local SEARCH_BOX_ICON_SIZE = 10
local SEARCH_BOX_TEXT_LEFT_INSET = SEARCH_BOX_ICON_LEFT_PAD + SEARCH_BOX_ICON_SIZE + 6

skins.SkinSearchBox = function(self, searchBox)
    if (not searchBox or searchBox.exuiSkinned) then return end
    searchBox.exuiSkinned = true
    local th = GetTheme()

    BlockInputBoxSideTextures(searchBox)
    EnsureInputFieldChrome(searchBox, th.background)
    HookInputFieldChromeRefresh(searchBox)
    HookInputFieldFocusBorder(searchBox)
    RefreshInputFieldChrome(searchBox)

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
end

local EDIT_BOX_FONT_SIZE = 11
local EDIT_BOX_TEXT_INSET = 8

local CHECKBOX_BASE_SIZE = 15
local CHECKBOX_MARK_WIDTH = 20
local CHECKBOX_MARK_HEIGHT = 15
local CHECKBOX_MARK_OFFSET_X = 2
local CHECKBOX_MARK_OFFSET_Y = 1

local function GetCheckboxTextures()
    local EXFrames = EXUI.EXFrames
    return EXFrames and EXFrames.assets and EXFrames.assets.textures.input.checkbox
end

local function LayoutCheckButtonTextures(checkButton)
    local normal = checkButton:GetNormalTexture()
    if (normal) then
        normal:SetSize(CHECKBOX_BASE_SIZE, CHECKBOX_BASE_SIZE)
        normal:ClearAllPoints()
        normal:SetPoint('CENTER')
        normal:SetTexCoord(0, 1, 0, 1)
        normal:SetAlpha(1)
    end

    local pushed = checkButton:GetPushedTexture()
    if (pushed) then
        pushed:SetSize(CHECKBOX_BASE_SIZE, CHECKBOX_BASE_SIZE)
        pushed:ClearAllPoints()
        pushed:SetPoint('CENTER')
        pushed:SetTexCoord(0, 1, 0, 1)
        pushed:SetAlpha(1)
    end

    local disabled = checkButton.GetDisabledTexture and checkButton:GetDisabledTexture()
    if (disabled) then
        disabled:SetSize(CHECKBOX_BASE_SIZE, CHECKBOX_BASE_SIZE)
        disabled:ClearAllPoints()
        disabled:SetPoint('CENTER')
        disabled:SetTexCoord(0, 1, 0, 1)
        disabled:SetDesaturated(true)
        disabled:SetAlpha(0.5)
    end

    local highlight = checkButton:GetHighlightTexture()
    if (highlight) then
        highlight:SetSize(CHECKBOX_BASE_SIZE, CHECKBOX_BASE_SIZE)
        highlight:ClearAllPoints()
        highlight:SetPoint('CENTER')
        highlight:SetTexCoord(0, 1, 0, 1)
        highlight:SetBlendMode('BLEND')
        highlight:SetAlpha(1)
    end

    local checked = checkButton:GetCheckedTexture()
    if (checked) then
        checked:SetSize(CHECKBOX_MARK_WIDTH, CHECKBOX_MARK_HEIGHT)
        checked:ClearAllPoints()
        checked:SetPoint('CENTER', checkButton, 'CENTER', CHECKBOX_MARK_OFFSET_X, CHECKBOX_MARK_OFFSET_Y)
        checked:SetTexCoord(0, 1, 0, 1)
        checked:SetAlpha(1)
    end

    local disabledChecked = checkButton:GetDisabledCheckedTexture()
    if (disabledChecked) then
        disabledChecked:SetSize(CHECKBOX_MARK_WIDTH, CHECKBOX_MARK_HEIGHT)
        disabledChecked:ClearAllPoints()
        disabledChecked:SetPoint('CENTER', checkButton, 'CENTER', CHECKBOX_MARK_OFFSET_X, CHECKBOX_MARK_OFFSET_Y)
        disabledChecked:SetTexCoord(0, 1, 0, 1)
        disabledChecked:SetDesaturated(true)
        disabledChecked:SetAlpha(0.5)
    end
end

local function ApplyCheckButtonSkin(checkButton, tex)
    if (checkButton.exuiApplyingCheckSkin) then return end
    checkButton.exuiApplyingCheckSkin = true

    checkButton:SetNormalTexture(tex.base)
    checkButton:SetPushedTexture(tex.base)
    if (checkButton.SetDisabledTexture) then
        checkButton:SetDisabledTexture(tex.base)
    end
    checkButton:SetHighlightTexture(tex.hover, 'BLEND')
    checkButton:SetCheckedTexture(tex.mark)
    checkButton:SetDisabledCheckedTexture(tex.mark)
    LayoutCheckButtonTextures(checkButton)

    checkButton.exuiApplyingCheckSkin = false
end

---Blizzard CheckButton → ExalityFrames options checkbox art (base / hover / mark).
skins.SkinCheckButton = function(self, checkButton)
    if (not checkButton or checkButton.exuiSkinned) then return end
    local tex = GetCheckboxTextures()
    if (not tex) then return end
    checkButton.exuiSkinned = true

    ApplyCheckButtonSkin(checkButton, tex)

    -- LFG dungeon list swaps multi-check / checkbox art on update; keep our mark.
    hooksecurefunc(checkButton, 'SetCheckedTexture', function(btn)
        if (btn.exuiSkinned and not btn.exuiApplyingCheckSkin) then
            ApplyCheckButtonSkin(btn, tex)
        end
    end)
    hooksecurefunc(checkButton, 'SetDisabledCheckedTexture', function(btn)
        if (btn.exuiSkinned and not btn.exuiApplyingCheckSkin) then
            ApplyCheckButtonSkin(btn, tex)
        end
    end)
    hooksecurefunc(checkButton, 'SetNormalTexture', function(btn)
        if (btn.exuiSkinned and not btn.exuiApplyingCheckSkin) then
            ApplyCheckButtonSkin(btn, tex)
        end
    end)
end

---InputBox / LFGListEditBoxTemplate: flat dark field with 1px border (no search icon).
---@param options? { fontSize?: number, textInset?: number }
skins.SkinEditBox = function(self, editBox, options)
    if (not editBox or editBox.exuiSkinned) then return end
    editBox.exuiSkinned = true
    options = options or {}
    local th = GetTheme()
    local fontSize = options.fontSize or EDIT_BOX_FONT_SIZE
    local textInset = options.textInset or EDIT_BOX_TEXT_INSET

    BlockInputBoxSideTextures(editBox)
    EnsureInputFieldChrome(editBox, th.background)
    HookInputFieldChromeRefresh(editBox)
    HookInputFieldFocusBorder(editBox)
    RefreshInputFieldChrome(editBox)

    if (editBox.SetFont) then
        editBox:SetFont(EXUI.const.fonts.DEFAULT, fontSize, '')
    end
    if (editBox.SetTextColor) then
        editBox:SetTextColor(unpack(th.text))
    end
    if (editBox.SetTextInsets) then
        editBox:SetTextInsets(textInset, textInset, 0, 0)
    end

    if (editBox.Instructions) then
        editBox.Instructions:SetFont(EXUI.const.fonts.DEFAULT, fontSize, '')
        editBox.Instructions:SetTextColor(unpack(th.textMuted))
        editBox.Instructions:ClearAllPoints()
        editBox.Instructions:SetPoint('TOPLEFT', editBox, 'LEFT', textInset, 0)
        editBox.Instructions:SetPoint('BOTTOMRIGHT', editBox, 'RIGHT', -textInset, 0)
    end
end

local INPUT_SCROLL_BORDER_KEYS = {
    'TopLeftTex', 'TopRightTex', 'TopTex',
    'BottomLeftTex', 'BottomRightTex', 'BottomTex',
    'LeftTex', 'RightTex', 'MiddleTex',
}

---InputScrollFrameTemplate: flat multiline description box.
---@param options? { fontSize?: number, textInset?: number }
skins.SkinInputScrollFrame = function(self, scrollFrame, options)
    if (not scrollFrame or scrollFrame.exuiSkinned) then return end
    scrollFrame.exuiSkinned = true
    options = options or {}
    local th = GetTheme()
    local fontSize = options.fontSize or EDIT_BOX_FONT_SIZE
    local textInset = options.textInset or EDIT_BOX_TEXT_INSET

    self:StripRegions(scrollFrame, INPUT_SCROLL_BORDER_KEYS)
    EnsureInputFieldChrome(scrollFrame, th.background)
    HookInputFieldChromeRefresh(scrollFrame)
    RefreshInputFieldChrome(scrollFrame)

    local editBox = scrollFrame.EditBox
    if (editBox) then
        if (editBox.SetFont) then
            editBox:SetFont(EXUI.const.fonts.DEFAULT, fontSize, '')
        end
        if (editBox.SetTextColor) then
            editBox:SetTextColor(unpack(th.text))
        end
        if (editBox.SetTextInsets) then
            editBox:SetTextInsets(textInset, textInset, textInset, textInset)
        end
        if (editBox.Instructions) then
            -- Blizzard defaults to TOPLEFT 0,0; pull off the chrome edge.
            editBox.Instructions:SetFont(EXUI.const.fonts.DEFAULT, fontSize, '')
            editBox.Instructions:SetTextColor(unpack(th.textMuted))
            editBox.Instructions:ClearAllPoints()
            editBox.Instructions:SetPoint('TOPLEFT', editBox, 'TOPLEFT', textInset, -textInset)
            editBox.Instructions:SetPoint('TOPRIGHT', editBox, 'TOPRIGHT', -textInset, -textInset)
        end

        if (not editBox.exuiFocusBorderHooks) then
            editBox.exuiFocusBorderHooks = true
            editBox:HookScript('OnEditFocusGained', function()
                ApplyInputFieldBorderState(scrollFrame, true)
            end)
            editBox:HookScript('OnEditFocusLost', function()
                ApplyInputFieldBorderState(scrollFrame, false)
            end)
        end
    end

    if (scrollFrame.CharCount) then
        scrollFrame.CharCount:SetFont(EXUI.const.fonts.DEFAULT, 10, '')
        scrollFrame.CharCount:SetTextColor(unpack(th.textMuted))
    end

    if (scrollFrame.ScrollBar) then
        self:SkinMinimalScrollBar(scrollFrame.ScrollBar)
    end
end

---SpellSearchPreviewContainerTemplate: flat dropdown under spell/talent search boxes.
local SEARCH_PREVIEW_FONT_SIZE = 11
local SEARCH_PREVIEW_HIGHLIGHT_ALPHA = 0.35
local searchPreviewHooksInstalled = false

local function StyleSearchPreviewLabel(fontString)
    if (not fontString) then return end
    local th = GetTheme()
    fontString:SetFont(EXUI.const.fonts.DEFAULT, SEARCH_PREVIEW_FONT_SIZE, 'OUTLINE')
    fontString:SetTextColor(unpack(th.text))
end

local function ApplySearchPreviewRowHighlight(button, highlighted)
    if (not button) then return end
    local th = GetTheme()

    if (not button.exuiHighlight) then
        local highlight = button:CreateTexture(nil, 'BACKGROUND', nil, 2)
        highlight:SetTexture(EXUI.const.textures.frame.solidBg)
        highlight:SetAllPoints()
        button.exuiHighlight = highlight
    end

    if (highlighted) then
        button.exuiHighlight:SetVertexColor(th.accent[1], th.accent[2], th.accent[3], SEARCH_PREVIEW_HIGHLIGHT_ALPHA)
        button.exuiHighlight:Show()
    else
        button.exuiHighlight:Hide()
    end

    if (button.HighlightTexture) then
        button.HighlightTexture:Hide()
    end
end

local function SkinSearchPreviewRow(button)
    if (not button or button.exuiPreviewRowSkinned) then return end
    button.exuiPreviewRowSkinned = true
    local th = GetTheme()

    skins:StripTexture(button:GetNormalTexture())
    skins:StripTexture(button:GetPushedTexture())
    if (button.HighlightTexture) then
        skins:StripTexture(button.HighlightTexture)
    end

    if (button.IconFrame) then
        button.IconFrame:SetDesaturated(true)
        button.IconFrame:SetVertexColor(unpack(th.border))
    end

    if (button.Icon and button.Icon.SetDesaturated and not button.Name) then
        button.Icon:SetDesaturated(true)
        button.Icon:SetVertexColor(unpack(th.textMuted))
    end

    StyleSearchPreviewLabel(button.Name or button.Text)
end

local function RestyleSearchPreviewSuggestedRows(container)
    if (not container or not container.suggestedResultButtonsPool) then return end

    for button in container.suggestedResultButtonsPool:EnumerateActive() do
        SkinSearchPreviewRow(button)
        ApplySearchPreviewRowHighlight(button, button.displayIndex == container.highlightedIndex)
    end
end

local function RefreshSearchPreviewLayer(container)
    if (not container) then return end

    if (container.exuiBg) then
        container.exuiBg:Show()
    end

    local parent = container:GetParent()
    if (parent) then
        container:SetFrameStrata(parent:GetFrameStrata())
        container:SetFrameLevel(math.max(container:GetFrameLevel(), parent:GetFrameLevel() + 150))
    end

    if (container.exuiBorderOverlay) then
        container.exuiBorderOverlay:SetFrameLevel(container:GetFrameLevel() + 50)
    end

    if (container.ScrollBox) then
        container.ScrollBox:SetFrameStrata(container:GetFrameStrata())
        container.ScrollBox:SetFrameLevel(container:GetFrameLevel() + 10)
    end

    if (container.suggestedResultButtonsPool) then
        for button in container.suggestedResultButtonsPool:EnumerateActive() do
            button:SetFrameStrata(container:GetFrameStrata())
            button:SetFrameLevel(container:GetFrameLevel() + 20)
        end
    end
end

local function InstallSearchPreviewHooks()
    if (searchPreviewHooksInstalled) then return end
    searchPreviewHooksInstalled = true

    hooksecurefunc(SpellSearchPreviewResultMixin, 'Init', function(button)
        SkinSearchPreviewRow(button)
        ApplySearchPreviewRowHighlight(button, false)

        local owner = button.owningFrame
        if (owner and owner.exuiPreviewWidth) then
            button:SetWidth(owner.exuiPreviewWidth)
        end
    end)

    hooksecurefunc(SpellSearchPreviewResultMixin, 'OnShow', function(button)
        local owner = button.owningFrame
        if (owner and owner.exuiSkinned) then
            button:SetFrameStrata(owner:GetFrameStrata())
            button:SetFrameLevel(owner:GetFrameLevel() + 25)
        end
    end)

    hooksecurefunc(SpellSearchPreviewResultMixin, 'SetHighlighted', function(button, isHighlighted)
        ApplySearchPreviewRowHighlight(button, isHighlighted)
    end)

    hooksecurefunc(SpellSearchPreviewContainerMixin, 'UpdateResultsDisplay', function(container)
        RestyleSearchPreviewSuggestedRows(container)
        RefreshSearchPreviewLayer(container)
    end)

    hooksecurefunc(SpellSearchPreviewContainerMixin, 'HighlightPreviewResult', function(container)
        RestyleSearchPreviewSuggestedRows(container)
    end)
end

skins.SkinSearchPreviewContainer = function(self, container)
    if (not container or container.exuiSkinned) then return end
    container.exuiSkinned = true
    local th = GetTheme()

    InstallSearchPreviewHooks()

    self:StripRegions(container, {
        'Background',
        'BorderAnchor',
        'BotRightCorner',
        'BottomBorder',
        'LeftBorder',
        'RightBorder',
    })

    if (container.exuiBackdrop) then
        container.exuiBackdrop:Hide()
    end

    if (not container.exuiBg) then
        local bg = container:CreateTexture(nil, 'BACKGROUND', nil, 0)
        bg:SetTexture(EXUI.const.textures.frame.solidBg)
        bg:SetAllPoints()
        container.exuiBg = bg
    end

    container.exuiBg:SetVertexColor(unpack(th.backgroundDeep))
    self:AddBorder(container, { thickness = 1, level = 40 })

    if (container.OverflowCount and container.OverflowCount.Text) then
        local overflowText = container.OverflowCount.Text
        overflowText:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
        overflowText:SetTextColor(unpack(th.textMuted))
    end

    container:HookScript('OnShow', RefreshSearchPreviewLayer)
    RefreshSearchPreviewLayer(container)
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
