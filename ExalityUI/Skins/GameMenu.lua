---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIGameMenuSkin
local gameMenuSkin = EXUI:GetModule('skin-GameMenu')

local FONT_PATH = EXUI.const.fonts.DEFAULT
local FONT_SIZE = 14
local MENU_BG_ALPHA = 0.82
local BORDER_THICKNESS = 1
local BUTTON_SPACING = 4
local HEADER_TEXT_TOP_OFFSET = -30
local FRAME_TOP_PADDING = 54

local function GetTheme()
    return EXUI.const.theme
end

local function ApplyMenuBorderEdges(overlay)
    local border = overlay.border
    if (not border) then return end

    local size = EXUI:ScalePixel(BORDER_THICKNESS, overlay, 1)

    border.Top:SetHeight(size)
    border.Top:ClearAllPoints()
    border.Top:SetPoint('TOPLEFT', overlay, 'TOPLEFT', size, 0)
    border.Top:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', -size, 0)

    border.Left:SetWidth(size)
    border.Left:ClearAllPoints()
    border.Left:SetPoint('TOPLEFT', overlay, 'TOPLEFT', 0, -size)
    border.Left:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', 0, size)

    border.Right:SetWidth(size)
    border.Right:ClearAllPoints()
    border.Right:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', 0, -size)
    border.Right:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', 0, size)

    border.Bottom:SetHeight(size)
    border.Bottom:SetSnapToPixelGrid(false)
    border.Bottom:ClearAllPoints()
    local bottomNudge = EXUI:ScalePixels(1, overlay)
    border.Bottom:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', size, -bottomNudge)
    border.Bottom:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', -size, -bottomNudge)
    border.Bottom:Show()
end

local function ApplyFrameBorder(frame)
    if (not frame.exuiBorderOverlay) then
        local overlay = CreateFrame('Frame', nil, frame)
        overlay:EnableMouse(false)
        overlay:SetFrameLevel(500)
        overlay.border = EXUI:AddPixelPerfectBorder(overlay, BORDER_THICKNESS, { register = false, layer = 'OVERLAY' })
        frame.exuiBorderOverlay = overlay
    end

    local overlay = frame.exuiBorderOverlay
    overlay:ClearAllPoints()
    overlay:SetAllPoints(frame)

    local th = GetTheme()
    overlay.border:SetBorderColor(unpack(th.border))
    ApplyMenuBorderEdges(overlay)
    overlay:Show()
end

local function ApplyHeaderLayout(frame)
    if (not frame.Header) then return end

    if (not frame.Header.exuiSkinned) then
        frame.Header.exuiSkinned = true
        skins:StripDialogHeader(frame.Header)
    end

    if (frame.Header.Text) then
        frame.Header.Text:SetFont(FONT_PATH, 14, 'OUTLINE')
        frame.Header.Text:SetTextColor(unpack(GetTheme().text))
        frame.Header.Text:ClearAllPoints()
        frame.Header.Text:SetPoint('TOP', frame.Header, 'TOP', 0, HEADER_TEXT_TOP_OFFSET)
    end
end

local BUTTON_BG_MARGINS = 10

local function GetButtonTexture()
    return EXUI.const.textures.frame.inputs.buttonBg
end

local function IsGameMenuFrame(frame)
    return frame == GameMenuFrame
end

local function ForEachMenuButton(frame, callback)
    if (not frame) then return end
    if (frame.buttonPool and frame.buttonPool.EnumerateActive) then
        for button in frame.buttonPool:EnumerateActive() do
            callback(button)
        end
        return
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        if (child:IsObjectType('Button')) then
            callback(child)
        end
    end
end

local STRIP_OPTIONS = { keepHighlight = true, blockHighlightAtlas = true }

local HIGHLIGHT_MARGINS = 10

local function GetHighlightTexture()
    return EXUI.const.textures.skins.btnHighlight
end

local function BlockHighlightAtlas(button)
    if (button.SetHighlightAtlas and not button.exuiHighlightAtlasBlocked) then
        button.exuiHighlightAtlasBlocked = true
        button.SetHighlightAtlas = function()
            -- keep custom SetHighlightTexture
        end
    end
end

local function SetupButtonHighlight(button)
    if (button.exuiHighlightConfigured) then return end
    button.exuiHighlightConfigured = true

    BlockHighlightAtlas(button)

    local texture = GetHighlightTexture()
    local th = GetTheme()

    button:SetHighlightTexture(texture, 'BLEND')
    local highlight = button:GetHighlightTexture()
    if (not highlight) then return end

    highlight:SetTextureSliceMargins(HIGHLIGHT_MARGINS, HIGHLIGHT_MARGINS, HIGHLIGHT_MARGINS, HIGHLIGHT_MARGINS)
    highlight:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    highlight:SetVertexColor(unpack(th.accent))
end

local function ResolveButtonState(button, state)
    if (state) then return state end
    if (not button:IsEnabled()) then return 'DISABLED' end
    return button:GetButtonState() or 'NORMAL'
end

local function ApplyButtonState(button, state)
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

local function StyleButtonText(button)
    local fontString = button:GetFontString()
    if (not fontString) then return end
    local th = GetTheme()
    fontString:SetDrawLayer('OVERLAY')
    fontString:SetFont(FONT_PATH, FONT_SIZE, 'OUTLINE')
    if (button:IsEnabled()) then
        fontString:SetTextColor(unpack(th.text))
    else
        fontString:SetTextColor(unpack(th.textMuted))
    end
end

local function EnsureButtonBackground(button)
    local texture = GetButtonTexture()

    if (not button.exuiBg) then
        local bg = button:CreateTexture(nil, 'BACKGROUND', nil, 1)
        bg:SetAllPoints()
        button.exuiBg = bg
    end

    button.exuiBg:SetTexture(texture)
    button.exuiBg:SetTextureSliceMargins(BUTTON_BG_MARGINS, BUTTON_BG_MARGINS, BUTTON_BG_MARGINS, BUTTON_BG_MARGINS)
    button.exuiBg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    button.exuiBg:SetAlpha(1)
    button.exuiBg:Show()
end

local function EnsureButtonTextures(button)
    EnsureButtonBackground(button)
    SetupButtonHighlight(button)
end

function gameMenuSkin:SkinButton(button)
    if (not button) then return end

    button.exuiHighlightConfigured = nil

    skins:StripThreeSliceButton(button, STRIP_OPTIONS)
    EnsureButtonTextures(button)

    StyleButtonText(button)
    ApplyButtonState(button, 'NORMAL')

    if (button.UpdateButton and not button.exuiUpdateHooked) then
        button.exuiUpdateHooked = true
        hooksecurefunc(button, 'UpdateButton', function(self, buttonState)
            skins:StripThreeSliceButton(self, STRIP_OPTIONS)
            EnsureButtonBackground(self)
            ApplyButtonState(self, buttonState)
            StyleButtonText(self)
        end)
    end
end

function gameMenuSkin:SkinButtons(frame)
    ForEachMenuButton(frame, function(button)
        self:SkinButton(button)
    end)
end

function gameMenuSkin:SkinFrame(frame)
    if (not frame) then return end

    local th = GetTheme()

    if (frame.spacing ~= BUTTON_SPACING) then
        frame.spacing = BUTTON_SPACING
        if (frame.MarkDirty) then
            frame:MarkDirty()
        end
    end

    if (frame.topPadding ~= FRAME_TOP_PADDING) then
        frame.topPadding = FRAME_TOP_PADDING
        if (frame.MarkDirty) then
            frame:MarkDirty()
        end
    end

    if (frame.Border and not frame.Border.exuiHidden) then
        skins:StripNineSlice(frame.Border)
        if (frame.Border.Bg) then
            frame.Border.Bg:Hide()
        end
        frame.Border:Hide()
        frame.Border:SetAlpha(0)
        frame.Border.exuiHidden = true
    end

    if (not frame.exuiBackdrop) then
        local backdrop = CreateFrame('Frame', nil, frame)
        backdrop:SetAllPoints()
        backdrop:SetFrameLevel(0)
        backdrop:EnableMouse(false)

        local bg = backdrop:CreateTexture(nil, 'BACKGROUND')
        bg:SetTexture(EXUI.const.textures.frame.solidBg)
        bg:SetAllPoints()

        frame.exuiBackdrop = backdrop
        frame.exuiBackdrop.bg = bg
    end

    local backdrop = frame.exuiBackdrop
    backdrop.bg:SetVertexColor(th.backgroundDeep[1], th.backgroundDeep[2], th.backgroundDeep[3], MENU_BG_ALPHA)
    backdrop:Show()

    ApplyFrameBorder(frame)
    ApplyHeaderLayout(frame)
end

local function RefreshGameMenu(menuFrame)
    if (not IsGameMenuFrame(menuFrame)) then return end
    gameMenuSkin:SkinFrame(menuFrame)
    gameMenuSkin:SkinButtons(menuFrame)
end

function gameMenuSkin:InstallHooks()
    if (self.hooksInstalled) then return end
    self.hooksInstalled = true

    if (GameMenuFrameMixin and GameMenuFrameMixin.InitButtons) then
        hooksecurefunc(GameMenuFrameMixin, 'InitButtons', function(menuFrame)
            RefreshGameMenu(menuFrame)
            C_Timer.After(0, function()
                if (menuFrame:IsShown()) then
                    RefreshGameMenu(menuFrame)
                end
            end)
        end)
    end

    if (GameMenuFrameMixin and GameMenuFrameMixin.OnShow) then
        hooksecurefunc(GameMenuFrameMixin, 'OnShow', function(menuFrame)
            C_Timer.After(0, function()
                if (menuFrame:IsShown()) then
                    RefreshGameMenu(menuFrame)
                end
            end)
        end)
    end

    if (ThreeSliceButtonMixin and ThreeSliceButtonMixin.UpdateButton) then
        hooksecurefunc(ThreeSliceButtonMixin, 'UpdateButton', function(button, buttonState)
            if (button:GetParent() ~= GameMenuFrame) then return end
            skins:StripThreeSliceButton(button, STRIP_OPTIONS)
            EnsureButtonBackground(button)
            ApplyButtonState(button, buttonState)
            StyleButtonText(button)
        end)
    end

    if (ThreeSliceButtonMixin and ThreeSliceButtonMixin.OnMouseDown) then
        hooksecurefunc(ThreeSliceButtonMixin, 'OnMouseDown', function(button)
            if (button:GetParent() ~= GameMenuFrame) then return end
            ApplyButtonState(button, 'PUSHED')
        end)
    end

    if (ThreeSliceButtonMixin and ThreeSliceButtonMixin.OnMouseUp) then
        hooksecurefunc(ThreeSliceButtonMixin, 'OnMouseUp', function(button)
            if (button:GetParent() ~= GameMenuFrame) then return end
            ApplyButtonState(button, 'NORMAL')
        end)
    end

    if (ThreeSliceButtonMixin and ThreeSliceButtonMixin.InitButton) then
        hooksecurefunc(ThreeSliceButtonMixin, 'InitButton', function(button)
            if (button:GetParent() ~= GameMenuFrame) then return end
            button.exuiHighlightConfigured = nil
            SetupButtonHighlight(button)
        end)
    end

    if (GameMenuFrame and GameMenuFrame.OnCleaned and not GameMenuFrame.exuiLayoutHooked) then
        GameMenuFrame.exuiLayoutHooked = true
        hooksecurefunc(GameMenuFrame, 'OnCleaned', function(frame)
            ApplyFrameBorder(frame)
        end)
    end
end

function gameMenuSkin:Install()
    if (self.installed or not GameMenuFrame) then return end
    self.installed = true

    self:InstallHooks()
    RefreshGameMenu(GameMenuFrame)

    if (GameMenuFrame:IsShown()) then
        C_Timer.After(0, function()
            RefreshGameMenu(GameMenuFrame)
        end)
    end
end

gameMenuSkin.Init = function(self)
    if (GameMenuFrame) then
        self:Install()
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-GameMenu', function(_, addon)
        if (addon ~= 'Blizzard_GameMenu') then return end
        self:Install()
    end)
end
