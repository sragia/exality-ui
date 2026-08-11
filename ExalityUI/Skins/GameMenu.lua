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
    border.Top:SetPoint('TOPLEFT', overlay, 'TOPLEFT', 0, 0)
    border.Top:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', 0, 0)

    border.Left:SetWidth(size)
    border.Left:ClearAllPoints()
    border.Left:SetPoint('TOPLEFT', overlay, 'TOPLEFT', 0, 0)
    border.Left:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', 0, 0)

    border.Right:SetWidth(size)
    border.Right:ClearAllPoints()
    border.Right:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', 0, 0)
    border.Right:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', 0, 0)

    border.Bottom:SetHeight(size)
    border.Bottom:SetSnapToPixelGrid(false)
    border.Bottom:ClearAllPoints()
    local bottomNudge = EXUI:ScalePixels(1, overlay)
    border.Bottom:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', 0, -bottomNudge)
    border.Bottom:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', 0, -bottomNudge)
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
local HIGHLIGHT_ALPHA = 0.6
local HIGHLIGHT_MARGINS = 10

local function ApplyGameMenuHighlight(button)
    if (not button.exuiHighlightConfigured) then
        button.exuiHighlightConfigured = true

        if (button.SetHighlightAtlas and not button.exuiHighlightAtlasBlocked) then
            button.exuiHighlightAtlasBlocked = true
            button.SetHighlightAtlas = function() end
        end

        button:SetHighlightTexture(EXUI.const.textures.skins.btnHighlight, 'BLEND')
    end

    local highlight = button:GetHighlightTexture()
    if (not highlight) then return end

    highlight:ClearAllPoints()
    highlight:SetAllPoints(button)
    highlight:SetTexCoord(0, 1, 0, 1)
    highlight:SetTextureSliceMargins(HIGHLIGHT_MARGINS, HIGHLIGHT_MARGINS, HIGHLIGHT_MARGINS, HIGHLIGHT_MARGINS)
    highlight:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    highlight:SetVertexColor(unpack(GetTheme().accent))
    highlight:SetAlpha(HIGHLIGHT_ALPHA)
end

function gameMenuSkin:SkinButton(button)
    if (not button) then return end

    skins:SkinPanelButton(button, { fontSize = FONT_SIZE })
    button.exuiHighlightConfigured = nil
    ApplyGameMenuHighlight(button)

    if (button.UpdateButton and not button.exuiUpdateHooked) then
        button.exuiUpdateHooked = true
        hooksecurefunc(button, 'UpdateButton', function(self, buttonState)
            skins:StripThreeSliceButton(self, STRIP_OPTIONS)
            ApplyGameMenuHighlight(self)
            skins:ApplyPanelButtonBackground(self)
            skins:ApplyPanelButtonState(self, buttonState)
            skins:StylePanelButtonText(self, FONT_SIZE)
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

    skins:AddBackdrop(frame, { color = th.backgroundDeep, alpha = MENU_BG_ALPHA })

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
            ApplyGameMenuHighlight(button)
            skins:ApplyPanelButtonBackground(button)
            skins:ApplyPanelButtonState(button, buttonState)
            skins:StylePanelButtonText(button, FONT_SIZE)
        end)
    end

    if (ThreeSliceButtonMixin and ThreeSliceButtonMixin.OnMouseDown) then
        hooksecurefunc(ThreeSliceButtonMixin, 'OnMouseDown', function(button)
            if (button:GetParent() ~= GameMenuFrame) then return end
            skins:ApplyPanelButtonState(button, 'PUSHED')
        end)
    end

    if (ThreeSliceButtonMixin and ThreeSliceButtonMixin.OnMouseUp) then
        hooksecurefunc(ThreeSliceButtonMixin, 'OnMouseUp', function(button)
            if (button:GetParent() ~= GameMenuFrame) then return end
            skins:ApplyPanelButtonState(button, button:IsMouseOver() and 'HOVERED' or 'NORMAL')
        end)
    end

    if (ThreeSliceButtonMixin and ThreeSliceButtonMixin.InitButton) then
        hooksecurefunc(ThreeSliceButtonMixin, 'InitButton', function(button)
            if (button:GetParent() ~= GameMenuFrame) then return end
            button.exuiHighlightConfigured = nil
            ApplyGameMenuHighlight(button)
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
    if (not skins:IsEnabled('GameMenu')) then return end

    if (GameMenuFrame) then
        self:Install()
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-GameMenu', function(_, addon)
        if (addon ~= 'Blizzard_GameMenu') then return end
        self:Install()
    end)
end
