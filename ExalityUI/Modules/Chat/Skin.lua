---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIChat
local chat = EXUI:GetModule('chat')

---@class EXUIChatSkin
local skin = EXUI:GetModule('chat-skin')

local EXFrames = EXUI.EXFrames

local SPRITE = [[Interface/Addons/ExalityUI/Assets/Images/Chat/chat-sprite.png]]
local SHEET = 500

-- Inclusive pixel rects: left, top, right, bottom.
local RECT = {
    scroll = { 4, 5, 49, 60 },
    menu = { 60, 7, 81, 56 },
    channels = { 90, 1, 151, 60 },
    copy = { 158, 1, 219, 62 },
    plus = { 227, 9, 272, 54 },
    background = { 7, 81, 134, 200 },
    line = { 7, 213, 70, 214 },
    glow = { 7, 231, 69, 259 },
}

local TAB_ART = {
    'Left', 'Middle', 'Right',
    'ActiveLeft', 'ActiveMiddle', 'ActiveRight',
    'HighlightLeft', 'HighlightMiddle', 'HighlightRight',
    'glow',
}

local SCROLL_ATLAS = {
    GetNormalTexture = true,
    GetPushedTexture = true,
    GetHighlightTexture = true,
    GetDisabledTexture = true,
}

local GLOW_HEIGHT = 32
local BG_SLICE = 5
local MENU_BUTTON_W = 14
local MENU_BUTTON_H = 22
local TEXT_PAD = 8

local CHROME_BUTTONS = {
    'ChatFrameMenuButton',
    'ChatFrameChannelButton',
    'ChatFrameToggleVoiceDeafenButton',
    'ChatFrameToggleVoiceMuteButton',
    'TextToSpeechButtonFrame',
    'QuickJoinToastButton',
}

local installed = false
local UpdateScrollButton
local PadMessageLines
local HideStamps
local EnsureLog
local SuppressCombatLog

local function TexCoords(rect)
    return rect[1] / SHEET, (rect[3] + 1) / SHEET, rect[2] / SHEET, (rect[4] + 1) / SHEET
end

local function ApplySprite(texture, rect)
    texture:SetTexture(SPRITE)
    texture:SetTexCoord(TexCoords(rect))
    texture:SetVertexColor(1, 1, 1, 1)
end

local function DefaultTabColor()
    local color = DEFAULT_TAB_SELECTED_COLOR_TABLE
    if color then
        return color.r, color.g, color.b
    end
    return 1, 0.5, 0.25
end

local function EachFrame(fn)
    if not CHAT_FRAMES then
        return
    end
    for _, frameName in pairs(CHAT_FRAMES) do
        local frame = _G[frameName]
        if frame then
            fn(frame)
        end
    end
end

local function TabSide()
    return chat:GetTabSide()
end

local function EditBoxSide()
    return chat:GetEditBoxSide()
end

local function BackgroundAlpha()
    return chat:GetBackgroundAlpha()
end

local function HostFrame(chatFrame)
    if chatFrame.isDocked and GENERAL_CHAT_DOCK then
        return FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK) or GENERAL_CHAT_DOCK.primary or chatFrame
    end
    return chatFrame
end

local function RelativeOffset(region, anchor)
    if not region or not anchor or not region.GetLeft or not anchor.GetLeft then
        return nil
    end
    local regionLeft = region:GetLeft()
    local anchorLeft = anchor:GetLeft()
    if not regionLeft or not anchorLeft then
        return nil
    end
    local regionScale = region:GetEffectiveScale()
    local anchorScale = anchor:GetEffectiveScale()
    if not anchorScale or anchorScale == 0 then
        return nil
    end
    local x = (regionLeft * regionScale - anchorLeft * anchorScale) / anchorScale
    local width = (region:GetWidth() or 0) * regionScale / anchorScale
    return x, width
end

local function Pixel(region, count)
    if EXUI.ScalePixels then
        return EXUI:ScalePixels(count, region)
    end
    return count
end

local function HideRegion(region)
    if not region then
        return
    end
    if region.exuiPrevAlpha == nil then
        region.exuiPrevAlpha = region:GetAlpha()
    end
    if UIFrameFadeRemoveFrame then
        UIFrameFadeRemoveFrame(region)
    end
    region:SetAlpha(0)
    region.exuiHidden = true
end

local function KillChromeTexture(region)
    if not region then
        return
    end
    HideRegion(region)
    region.exuiWasHidden = true
    region:Hide()
end

local function ShowRegion(region)
    if not region or not region.exuiHidden then
        return
    end
    region:SetAlpha(region.exuiPrevAlpha or 1)
    if region.exuiWasHidden then
        region:Show()
        region.exuiWasHidden = nil
    end
    region.exuiHidden = nil
    region.exuiPrevAlpha = nil
end

local function HideTabArt(tab)
    for _, key in ipairs(TAB_ART) do
        HideRegion(tab[key])
    end
    if tab.conversationIcon then
        HideRegion(tab.conversationIcon)
    end
    local name = tab.GetName and tab:GetName()
    if name then
        HideRegion(_G[name .. 'Flash'])
    end
end

local function ShowTabArt(tab)
    for _, key in ipairs(TAB_ART) do
        ShowRegion(tab[key])
    end
    if tab.conversationIcon then
        ShowRegion(tab.conversationIcon)
    end
    local name = tab.GetName and tab:GetName()
    if name then
        ShowRegion(_G[name .. 'Flash'])
    end
    local fontString = tab:GetFontString()
    if fontString and fontString.exuiCentered then
        if fontString.exuiHome then
            fontString:SetParent(fontString.exuiHome)
            fontString.exuiHome = nil
        end
        fontString:ClearAllPoints()
        fontString:SetPoint('CENTER', tab, 'CENTER', 0, -5)
        fontString:Show()
        fontString.exuiCentered = nil
    end
    if tab.exuiHitRect then
        tab:SetHitRectInsets(0, 0, 0, 0)
        tab.exuiHitRect = nil
    end
end

local function HideNamed(frameName, suffix)
    HideRegion(_G[frameName .. suffix])
end

local function HideEditBoxChrome(editBox)
    if not editBox then
        return
    end
    local name = editBox:GetName()
    if name then
        HideNamed(name, 'Left')
        HideNamed(name, 'Right')
        HideNamed(name, 'Mid')
    end
    HideRegion(editBox.focusLeft)
    HideRegion(editBox.focusRight)
    HideRegion(editBox.focusMid)
end

local function ShowEditBoxChrome(editBox)
    if not editBox then
        return
    end
    local name = editBox:GetName()
    if name then
        ShowRegion(_G[name .. 'Left'])
        ShowRegion(_G[name .. 'Right'])
        ShowRegion(_G[name .. 'Mid'])
    end
    ShowRegion(editBox.focusLeft)
    ShowRegion(editBox.focusRight)
    ShowRegion(editBox.focusMid)
    if editBox.exuiBg then
        editBox.exuiBg:Hide()
    end
end

local function HideChromeButtons()
    for _, name in ipairs(CHROME_BUTTONS) do
        local button = _G[name]
        if button then
            if not button.exuiChatHooked then
                button.exuiChatHooked = true
                button:HookScript('OnShow', function(self)
                    if chat.enabled then
                        self:Hide()
                    end
                end)
            end
            button:Hide()
        end
    end
end

local function ShowChromeButtons()
    for _, name in ipairs(CHROME_BUTTONS) do
        local button = _G[name]
        if button then
            button:Show()
        end
    end
end

local function HideFrameChrome(chatFrame)
    local name = chatFrame:GetName()
    if CHAT_FRAME_TEXTURES and name then
        for _, suffix in pairs(CHAT_FRAME_TEXTURES) do
            KillChromeTexture(_G[name .. suffix])
        end
    end
    KillChromeTexture(chatFrame.Background)
    if chatFrame.buttonFrame then
        chatFrame.buttonFrame:Hide()
    end
    HideChromeButtons()
    if chatFrame.ScrollBar then
        if UIFrameFadeRemoveFrame then
            UIFrameFadeRemoveFrame(chatFrame.ScrollBar)
        end
        chatFrame.ScrollBar:SetAlpha(0)
    end
end

local function ShowFrameChrome(chatFrame)
    local name = chatFrame:GetName()
    if CHAT_FRAME_TEXTURES and name then
        for _, suffix in pairs(CHAT_FRAME_TEXTURES) do
            ShowRegion(_G[name .. suffix])
        end
    end
    if chatFrame.buttonFrame then
        chatFrame.buttonFrame:SetAlpha(0.2)
        chatFrame.buttonFrame:Show()
    end
    ShowChromeButtons()
    if chatFrame.ScrollBar then
        chatFrame.ScrollBar:SetAlpha(0)
    end
end

local function CaptureButtonAtlas(texture)
    if texture and texture.GetAtlas then
        return texture:GetAtlas()
    end
end

local function StyleScrollButton(chatFrame)
    local button = chatFrame.ScrollToBottomButton
    if not button then
        return
    end
    if not button.exuiStyled then
        button.exuiAtlases = {}
        for method in pairs(SCROLL_ATLAS) do
            local texture = button[method](button)
            button.exuiAtlases[method] = CaptureButtonAtlas(texture)
        end
        if button.Flash then
            button.exuiFlashAtlas = CaptureButtonAtlas(button.Flash)
        end
        button.exuiStyled = true
    end
    local left, right, top, bottom = TexCoords(RECT.scroll)
    for method in pairs(SCROLL_ATLAS) do
        local texture = button[method](button)
        if texture then
            texture:SetTexture(SPRITE)
            texture:SetTexCoord(left, right, top, bottom)
        end
    end
    if button.Flash then
        button.Flash:SetTexture(SPRITE)
        button.Flash:SetTexCoord(left, right, top, bottom)
    end
    button:SetSize(12, 16)
end

local function RestoreScrollButton(chatFrame)
    local button = chatFrame.ScrollToBottomButton
    if not button or not button.exuiStyled then
        return
    end
    for method, atlas in pairs(button.exuiAtlases or {}) do
        local texture = button[method](button)
        if texture and atlas and texture.SetAtlas then
            texture:SetAtlas(atlas)
        end
    end
    if button.Flash and button.exuiFlashAtlas and button.Flash.SetAtlas then
        button.Flash:SetAtlas(button.exuiFlashAtlas)
    end
    button:SetSize(17, 15)
    button.exuiStyled = nil
end

local function ApplySlicedBackground(texture, region)
    texture:SetTexture(SPRITE)
    texture:SetVertexColor(1, 1, 1, 1)
    local rect = RECT.background
    texture:SetTexCoord(rect[1] / SHEET, (rect[3] + 1) / SHEET, rect[2] / SHEET, (rect[4] + 1) / SHEET)
    if EXFrames.utils and EXFrames.utils.texture and EXFrames.utils.texture.applySlice and Enum and Enum.UITextureSliceMode then
        EXFrames.utils.texture.applySlice(texture, BG_SLICE, region, Enum.UITextureSliceMode.Stretched)
    elseif texture.SetTextureSliceMargins then
        texture:SetTextureSliceMargins(BG_SLICE, BG_SLICE, BG_SLICE, BG_SLICE)
        if texture.SetTextureSliceMode and Enum and Enum.UITextureSliceMode then
            texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        end
    end
end

local function EnsureBackground(chatFrame)
    if not chatFrame.exuiBg then
        local bg = chatFrame:CreateTexture(nil, 'BACKGROUND', nil, -8)
        bg:SetAllPoints()
        chatFrame.exuiBg = bg
    end
    ApplySlicedBackground(chatFrame.exuiBg, chatFrame)
    return chatFrame.exuiBg
end

local function EnsureEditBoxBackground(editBox)
    if not editBox then
        return nil
    end
    if not editBox.exuiBg then
        local bg = editBox:CreateTexture(nil, 'BACKGROUND', nil, -8)
        bg:SetAllPoints()
        editBox.exuiBg = bg
    end
    ApplySlicedBackground(editBox.exuiBg, editBox)
    return editBox.exuiBg
end

local function EnsureTabDecor(tab)
    if tab.exuiLine then
        return
    end
    local line = tab:CreateTexture(nil, 'BORDER', nil, 7)
    ApplySprite(line, RECT.line)
    line:Hide()
    tab.exuiLine = line

    local glow = tab:CreateTexture(nil, 'BACKGROUND', nil, -7)
    ApplySprite(glow, RECT.glow)
    glow:Hide()
    tab.exuiGlow = glow
end

local function PlaceTabText(tab, host, line)
    local fontString = tab:GetFontString()
    if not fontString or not line then
        return
    end
    if fontString.exuiHome then
        fontString:SetParent(fontString.exuiHome)
        fontString.exuiHome = nil
    end
    fontString:SetDrawLayer('OVERLAY', 7)
    fontString:ClearAllPoints()
    local gap = Pixel(host, 3)
    if TabSide() == 'bottom' then
        fontString:SetPoint('TOP', line, 'BOTTOM', 0, -gap)
    else
        fontString:SetPoint('BOTTOM', line, 'TOP', 0, gap)
    end
    fontString:Show()
    fontString.exuiCentered = true
    if tab.exuiHitRect then
        tab:SetHitRectInsets(0, 0, 0, 0)
        tab.exuiHitRect = nil
    end
end

skin.ResolveTabColor = function(self, chatFrame, tab)
    local saved = chat:GetSavedTabColor(chatFrame:GetID())
    if saved then
        return saved.r, saved.g, saved.b
    end
    if tab and tab.selectedColorTable then
        return tab.selectedColorTable.r, tab.selectedColorTable.g, tab.selectedColorTable.b
    end
    return DefaultTabColor()
end

local function StyleTabText(tab, selected)
    local fontString = tab:GetFontString()
    if not fontString then
        return
    end
    if selected then
        fontString:SetTextColor(1, 1, 1)
        return
    end
    local muted = EXFrames.Theme and EXFrames.Theme.textMuted
    if muted then
        fontString:SetTextColor(muted[1], muted[2], muted[3])
        return
    end
    fontString:SetTextColor(0.54, 0.50, 0.46)
end

local function StyleTab(chatFrame, tab, selected)
    if not tab then
        return
    end
    EnsureTabDecor(tab)
    HideTabArt(tab)
    local r, g, b = skin:ResolveTabColor(chatFrame, tab)
    local lineAlpha = selected and 1 or 0.4
    local glowAlpha = selected and 0.9 or 0.22
    tab.exuiLine:SetDrawLayer('BORDER', selected and 2 or 1)
    tab.exuiGlow:SetDrawLayer('BACKGROUND', selected and -6 or -7)
    tab.exuiLine:SetVertexColor(r, g, b, lineAlpha)
    tab.exuiGlow:SetVertexColor(r, g, b, glowAlpha)
    StyleTabText(tab, selected)
end

local function PlaceTabDecor(chatFrame, tab)
    if not tab or not tab.exuiLine then
        return false
    end
    if not tab:IsShown() then
        tab.exuiLine:Hide()
        tab.exuiGlow:Hide()
        return true
    end
    local width = tab:GetWidth()
    if not width or width <= 1 then
        return false
    end
    local line = tab.exuiLine
    local glow = tab.exuiGlow
    local lineH = Pixel(tab, 2)
    local seam = Pixel(tab, 1)
    local left, right, top, bottom = TexCoords(RECT.glow)
    line:SetParent(tab)
    glow:SetParent(tab)
    glow:SetDrawLayer('BACKGROUND', -8)
    line:ClearAllPoints()
    glow:ClearAllPoints()
    line:SetSize(width, lineH)
    glow:SetWidth(width)
    glow:SetHeight(GLOW_HEIGHT)
    if TabSide() == 'bottom' then
        line:SetPoint('TOPLEFT', tab, 'TOPLEFT', 0, 0)
        glow:SetPoint('TOPLEFT', line, 'BOTTOMLEFT', 0, -seam)
        glow:SetTexCoord(left, right, top, bottom)
    else
        line:SetPoint('BOTTOMLEFT', tab, 'BOTTOMLEFT', 0, 0)
        glow:SetPoint('BOTTOMLEFT', line, 'TOPLEFT', 0, seam)
        glow:SetTexCoord(left, right, bottom, top)
    end
    line:Show()
    glow:Show()
    PlaceTabText(tab, tab, line)
    return true
end

local function SideClearance(chatFrame, side)
    local gap = Pixel(chatFrame, 4)
    if TabSide() ~= side then
        return gap
    end
    local dock = GENERAL_CHAT_DOCK
    local height = dock and dock:GetHeight() or 0
    if not height or height < 8 then
        height = 26
    end
    return height + gap
end

local function LayoutEditBox(chatFrame)
    local editBox = chatFrame.editBox
    if not editBox then
        return
    end
    local side = EditBoxSide()
    local clearance = SideClearance(chatFrame, side)
    local pad = Pixel(chatFrame, TEXT_PAD)
    editBox:ClearAllPoints()
    if side == 'top' then
        editBox:SetPoint('BOTTOMLEFT', chatFrame, 'TOPLEFT', 0, clearance)
        editBox:SetPoint('BOTTOMRIGHT', chatFrame, 'TOPRIGHT', 0, clearance)
    else
        editBox:SetPoint('TOPLEFT', chatFrame, 'BOTTOMLEFT', 0, -clearance)
        editBox:SetPoint('TOPRIGHT', chatFrame, 'BOTTOMRIGHT', 0, -clearance)
    end
    if editBox.SetTextInsets then
        editBox:SetTextInsets(pad, pad, 0, 0)
    end
    editBox.exuiAnchored = true
end

local function RestoreEditBox(chatFrame)
    local editBox = chatFrame.editBox
    if not editBox or not editBox.exuiAnchored then
        return
    end
    editBox:ClearAllPoints()
    if editBox.SetTextInsets then
        editBox:SetTextInsets(0, 0, 0, 0)
    end
    editBox:SetPoint('TOPLEFT', chatFrame, 'BOTTOMLEFT', -5, -2)
    if chatFrame.ScrollBar then
        editBox:SetPoint('RIGHT', chatFrame.ScrollBar, 'RIGHT', 8, 0)
    else
        editBox:SetPoint('TOPRIGHT', chatFrame, 'BOTTOMRIGHT', 8, -2)
    end
    editBox.exuiAnchored = nil
end

local function LayoutMenuButton(button, chatFrame)
    if not button or not chatFrame then
        return
    end
    local host = HostFrame(chatFrame)
    local pad = Pixel(host, 4)
    button:SetParent(host)
    button:SetFrameStrata(host:GetFrameStrata() or 'LOW')
    button:SetFrameLevel((host:GetFrameLevel() or 1) + 30)
    button:ClearAllPoints()
    button:SetPoint('TOPRIGHT', host, 'TOPRIGHT', -pad, -pad)
end

local function ConfigureMenuButton(button, chatFrame)
    button.chatFrame = chatFrame
    button:SetSize(MENU_BUTTON_W, MENU_BUTTON_H)
    button:SetFrameStrata('MEDIUM')
    if not button.icon then
        local icon = button:CreateTexture(nil, 'ARTWORK')
        icon:SetAllPoints()
        ApplySprite(icon, RECT.menu)
        button.icon = icon
        button:SetScript('OnClick', function(self)
            local target = self.chatFrame
            if target and target.isDocked and GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow then
                target = FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK) or target
            end
            EXUI:GetModule('chat-menu'):Toggle(self, target)
        end)
        button:SetScript('OnEnter', function(self)
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            GameTooltip:SetText('Chat Menu')
            GameTooltip:Show()
        end)
        button:SetScript('OnLeave', function()
            GameTooltip:Hide()
        end)
    end
end

local function EnsureFrameButton(chatFrame)
    if chatFrame.exuiMenuButton then
        return chatFrame.exuiMenuButton
    end
    local button = CreateFrame('Button', nil, chatFrame)
    ConfigureMenuButton(button, chatFrame)
    chatFrame.exuiMenuButton = button
    return button
end

local function EnsureDockButton()
    if skin.dockButton or not GENERAL_CHAT_DOCK or not GENERAL_CHAT_DOCK.primary then
        return skin.dockButton
    end
    local button = CreateFrame('Button', nil, GENERAL_CHAT_DOCK)
    ConfigureMenuButton(button, GENERAL_CHAT_DOCK.primary)
    skin.dockButton = button
    return button
end

local function ApplyBackgroundAlpha(chatFrame)
    local alpha = BackgroundAlpha()
    if chatFrame.exuiBg then
        chatFrame.exuiBg:SetAlpha(alpha)
    end
    if chatFrame.editBox and chatFrame.editBox.exuiBg then
        chatFrame.editBox.exuiBg:SetAlpha(math.min(1, alpha + 0.15))
    end
end

local function HookFrame(chatFrame)
    if chatFrame.exuiHooked then
        return
    end
    chatFrame.exuiHooked = true
    chatFrame:HookScript('OnSizeChanged', function()
        if not chat.enabled or skin.layouting then
            return
        end
        skin:QueueDecor()
    end)
    if chatFrame.buttonFrame then
        chatFrame.buttonFrame:HookScript('OnShow', function(self)
            if chat.enabled then
                self:Hide()
            end
        end)
    end
    local editBox = chatFrame.editBox
    if editBox then
        editBox:HookScript('OnShow', function()
            if chat.enabled then
                LayoutEditBox(chatFrame)
            end
        end)
        editBox:HookScript('OnEditFocusGained', function(self)
            if chat.enabled then
                HideEditBoxChrome(self)
            end
        end)
        editBox:HookScript('OnEditFocusLost', function(self)
            if chat.enabled then
                HideEditBoxChrome(self)
            end
        end)
    end
end

local function EnsureFrame(chatFrame)
    HookFrame(chatFrame)
    EnsureBackground(chatFrame)
    if chatFrame.editBox then
        EnsureEditBoxBackground(chatFrame.editBox)
        HideEditBoxChrome(chatFrame.editBox)
        chatFrame.editBox.exuiBg:Show()
    end
    HideFrameChrome(chatFrame)
    StyleScrollButton(chatFrame)
    local tab = _G[chatFrame:GetName() .. 'Tab']
    if tab then
        local selected = not chatFrame.isDocked
            or (GENERAL_CHAT_DOCK and chatFrame == FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK))
        StyleTab(chatFrame, tab, selected)
    end
    ApplyBackgroundAlpha(chatFrame)
    if chatFrame.exuiBg then
        chatFrame.exuiBg:Show()
    end
    PadMessageLines(chatFrame)
    UpdateScrollButton(chatFrame)
    if chatFrame ~= ChatFrame2 then
        EnsureLog(chatFrame)
    end
end

skin.LayoutDock = function(self)
    local dock = GENERAL_CHAT_DOCK
    if not dock or not dock.primary or self.layouting then
        return
    end
    self.layouting = true
    local primary = dock.primary
    dock:ClearAllPoints()
    if TabSide() == 'bottom' then
        dock:SetPoint('TOPLEFT', primary, 'BOTTOMLEFT', 0, 0)
        dock:SetPoint('TOPRIGHT', primary, 'BOTTOMRIGHT', 0, 0)
    else
        dock:SetPoint('BOTTOMLEFT', primary, 'TOPLEFT', 0, 0)
        dock:SetPoint('BOTTOMRIGHT', primary, 'TOPRIGHT', 0, 0)
    end
    self.dockAnchored = true
    self.layouting = false
end

skin.LayoutUndockedTab = function(self, chatFrame)
    if not chatFrame or chatFrame.isDocked then
        return
    end
    local tab = _G[chatFrame:GetName() .. 'Tab']
    if not tab then
        return
    end
    tab:ClearAllPoints()
    if TabSide() == 'bottom' then
        tab:SetPoint('TOPLEFT', chatFrame, 'BOTTOMLEFT', 2, 0)
    else
        tab:SetPoint('BOTTOMLEFT', chatFrame, 'TOPLEFT', 2, 0)
    end
end

skin.PlaceAllDecor = function(self, attempt)
    if not chat.enabled then
        return
    end
    attempt = attempt or 0
    local pending = false
    EachFrame(function(chatFrame)
        local tab = _G[chatFrame:GetName() .. 'Tab']
        if tab and not PlaceTabDecor(chatFrame, tab) then
            pending = true
        end
    end)
    if pending and attempt < 5 then
        self:QueueDecor(attempt + 1)
    end
end

skin.QueueDecor = function(self, attempt)
    if self.decorQueued then
        return
    end
    self.decorQueued = true
    local function run()
        self.decorQueued = false
        if chat.enabled then
            self:PlaceAllDecor(attempt or 0)
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

skin.ScheduleRetab = function(self)
    if self.retabQueued or not FCFDock_UpdateTabs or not GENERAL_CHAT_DOCK then
        return
    end
    self.retabQueued = true
    local function run()
        self.retabQueued = false
        if chat.enabled and GENERAL_CHAT_DOCK and FCFDock_UpdateTabs then
            FCFDock_UpdateTabs(GENERAL_CHAT_DOCK, true)
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

skin.LayoutChrome = function(self)
    if not chat.enabled then
        return
    end
    self:LayoutDock()
    local dockButton = EnsureDockButton()
    if dockButton and GENERAL_CHAT_DOCK and GENERAL_CHAT_DOCK.primary then
        dockButton.chatFrame = GENERAL_CHAT_DOCK.primary
        LayoutMenuButton(dockButton, GENERAL_CHAT_DOCK.primary)
        dockButton:Show()
    end
    EachFrame(function(chatFrame)
        if not chatFrame.isDocked then
            self:LayoutUndockedTab(chatFrame)
        end
        LayoutEditBox(chatFrame)
        local useOwnButton = not chatFrame.isDocked
        local button = chatFrame.exuiMenuButton
        if useOwnButton then
            button = EnsureFrameButton(chatFrame)
            LayoutMenuButton(button, chatFrame)
            button:SetShown(chatFrame:IsShown())
        elseif button then
            button:Hide()
        end
    end)
    self:QueueDecor()
    if not self.applying then
        self:ScheduleRetab()
    end
end

skin.Apply = function(self)
    if not chat.enabled or not ChatFrame1 then
        return
    end
    EachFrame(function(chatFrame)
        EnsureFrame(chatFrame)
    end)
    self:LayoutChrome()
    SuppressCombatLog()
    self:RefreshTimestamps()
end

skin.HideChrome = function(self, chatFrame)
    if not chat.enabled or not chatFrame then
        return
    end
    HideFrameChrome(chatFrame)
    if chatFrame.editBox then
        HideEditBoxChrome(chatFrame.editBox)
    end
    local tab = _G[chatFrame:GetName() .. 'Tab']
    if tab then
        HideTabArt(tab)
    end
end

local function RestoreDock()
    local dock = GENERAL_CHAT_DOCK
    if not dock or not dock.primary or not skin.dockAnchored then
        return
    end
    dock:ClearAllPoints()
    dock:SetPoint('BOTTOMLEFT', dock.primary, 'TOPLEFT', 0, 3)
    dock:SetPoint('BOTTOMRIGHT', dock.primary, 'TOPRIGHT', 0, 3)
    skin.dockAnchored = nil
end

skin.Remove = function(self)
    if skin.dockButton then
        skin.dockButton:Hide()
    end
    EachFrame(function(chatFrame)
        ShowFrameChrome(chatFrame)
        ShowEditBoxChrome(chatFrame.editBox)
        RestoreEditBox(chatFrame)
        RestoreScrollButton(chatFrame)
        if chatFrame.exuiBg then
            chatFrame.exuiBg:Hide()
        end
        if chatFrame.exuiMenuButton then
            chatFrame.exuiMenuButton:Hide()
        end
        HideStamps(chatFrame)
        if chatFrame.exuiLog then
            HideStamps(chatFrame.exuiLog)
            chatFrame.exuiLog:Hide()
        end
        ShowBlizzardText(chatFrame)
        local tab = _G[chatFrame:GetName() .. 'Tab']
        if tab then
            ShowTabArt(tab)
            if tab.exuiLine then
                tab.exuiLine:Hide()
            end
            if tab.exuiGlow then
                tab.exuiGlow:Hide()
            end
        end
        if chatFrame.SetTextCopyable and chatFrame.exuiCopyable then
            chatFrame:SetTextCopyable(false)
            chatFrame.exuiCopyable = nil
        end
    end)
    RestoreCombatLog()
    RestoreDock()
    if FCFDock_UpdateTabs and GENERAL_CHAT_DOCK then
        FCFDock_UpdateTabs(GENERAL_CHAT_DOCK, true)
    end
end

local function IsSkinnedFrame(frame)
    if not frame or not frame.GetName or not CHAT_FRAMES then
        return false
    end
    local name = frame:GetName()
    for _, frameName in pairs(CHAT_FRAMES) do
        if frameName == name then
            return true
        end
    end
    return false
end

local messageClock = setmetatable({}, { __mode = 'k' })

local function IsCombatLogFrame(chatFrame)
    return chatFrame == ChatFrame2
end

local function HideBlizzardText(chatFrame)
    if chatFrame.FontStringContainer then
        if chatFrame.exuiTextAlpha == nil then
            chatFrame.exuiTextAlpha = chatFrame.FontStringContainer:GetAlpha()
        end
        chatFrame.FontStringContainer:SetAlpha(0)
    end
end

local function ShowBlizzardText(chatFrame)
    if chatFrame.FontStringContainer and chatFrame.exuiTextAlpha ~= nil then
        chatFrame.FontStringContainer:SetAlpha(chatFrame.exuiTextAlpha)
        chatFrame.exuiTextAlpha = nil
    end
end

local function FormatClock(when)
    local pattern = chat.GetTimestampPattern and chat:GetTimestampPattern()
    if not pattern or type(when) ~= 'number' then
        return nil
    end
    local ok, text
    if TimeUtil and TimeUtil.BetterDate then
        ok, text = pcall(TimeUtil.BetterDate, pattern, when)
    else
        ok, text = pcall(date, pattern, when)
    end
    if ok and type(text) == 'string' and text ~= '' then
        return text
    end
end

local function ApplyStampStyle(fontString)
    local font = EXFrames.assets.font.default()
    fontString:SetFont(font, chat:GetTimestampFontSize(), 'OUTLINE')
    local r, g, b = chat:GetTimestampColor()
    fontString:SetTextColor(r, g, b, 1)
end

local function EnsureStampHost(chatFrame)
    if chatFrame.exuiStampHost then
        return
    end
    local host = CreateFrame('Frame', nil, chatFrame)
    host:SetAllPoints()
    host:EnableMouse(false)
    chatFrame.exuiStampHost = host
    chatFrame.exuiStamps = {}
end

HideStamps = function(chatFrame)
    if chatFrame.exuiStampHost then
        chatFrame.exuiStampHost:Hide()
    end
end

local function MeasureStamp(chatFrame)
    if not chat.TimestampsShown or not chat:TimestampsShown() then
        return 0
    end
    local sample = FormatClock(time())
    if not sample then
        return 0
    end
    EnsureStampHost(chatFrame)
    local probe = chatFrame.exuiStampProbe
    if not probe then
        probe = chatFrame.exuiStampHost:CreateFontString(nil, 'OVERLAY')
        probe:Hide()
        chatFrame.exuiStampProbe = probe
    end
    ApplyStampStyle(probe)
    probe:SetText(sample)
    return (probe:GetStringWidth() or 0) + Pixel(chatFrame, 6)
end

local function LayoutOwnedTimestamps(messageFrame)
    local view = messageFrame.exuiView
    if not view or not chat.enabled or not chat:TimestampsShown() then
        if view then
            HideStamps(view)
        end
        return
    end
    local lines = messageFrame.visibleLines
    if not lines then
        HideStamps(view)
        return
    end
    EnsureStampHost(view)
    local host = view.exuiStampHost
    host:SetFrameLevel((view:GetFrameLevel() or 0) + 5)
    host:Show()
    local index = 1
    while lines[index] do
        local line = lines[index]
        local info = line.messageInfo
        local when = info and messageClock[info]
        local stamp = view.exuiStamps[index]
        if not stamp then
            stamp = host:CreateFontString(nil, 'OVERLAY')
            stamp:SetJustifyH('RIGHT')
            view.exuiStamps[index] = stamp
        end
        local text = when and line:IsShown() and FormatClock(when)
        if text then
            ApplyStampStyle(stamp)
            stamp:SetText(text)
            stamp:ClearAllPoints()
            stamp:SetPoint('RIGHT', line, 'LEFT', -Pixel(view, 4), 0)
            local alpha = line:GetAlpha()
            if type(alpha) == 'number' then
                stamp:SetAlpha(alpha)
            end
            stamp:Show()
        else
            stamp:Hide()
        end
        index = index + 1
    end
    for extra = index, #view.exuiStamps do
        view.exuiStamps[extra]:Hide()
    end
end

local function NoteClock(messageFrame)
    local history = messageFrame.historyBuffer
    if not history or not history.GetEntryAtIndex then
        return
    end
    local info = history:GetEntryAtIndex(1)
    if info then
        messageClock[info] = time()
    end
end

local function LayoutLog(view)
    local messages = view.messages
    if not messages then
        return
    end
    local width = MeasureStamp(view)
    messages:ClearAllPoints()
    messages:SetPoint('TOPLEFT', view, 'TOPLEFT', width, 0)
    messages:SetPoint('BOTTOMRIGHT', view, 'BOTTOMRIGHT', 0, 0)
end

local function CopyChatFont(chatFrame, messages)
    if not chatFrame.GetFont then
        return false
    end
    local file, size, flags = chatFrame:GetFont()
    if type(file) == 'string' and type(size) == 'number' then
        messages:SetFont(file, size, flags)
        return true
    end
    return false
end

local function BackfillLog(chatFrame, messages)
    local history = chatFrame.historyBuffer
    if not history or not history.GetNumElements or not history.GetEntryAtIndex then
        return
    end
    local count = history:GetNumElements()
    if type(count) ~= 'number' or count < 1 then
        return
    end
    for index = count, 1, -1 do
        local entry = history:GetEntryAtIndex(index)
        if entry then
            pcall(messages.AddMessage, messages, entry.message, entry.r, entry.g, entry.b)
        end
    end
end

EnsureLog = function(chatFrame)
    if not chatFrame or IsCombatLogFrame(chatFrame) then
        return
    end
    HideBlizzardText(chatFrame)
    local view = chatFrame.exuiLog
    if not view then
        view = CreateFrame('Frame', nil, chatFrame)
        view:SetFrameLevel((chatFrame:GetFrameLevel() or 0) + 8)
        view.chatFrame = chatFrame
        chatFrame.exuiLog = view

        local messages = CreateFrame('ScrollingMessageFrame', nil, view)
        messages.exuiOwned = true
        messages.exuiView = view
        messages:SetFading(false)
        messages:SetMaxLines(250)
        messages:SetJustifyH('LEFT')
        if messages.SetHyperlinksEnabled then
            messages:SetHyperlinksEnabled(true)
        end
        messages:EnableMouse(true)
        messages:EnableMouseWheel(true)
        messages:SetScript('OnHyperlinkClick', function(self, link, text, button)
            if SetItemRef then
                SetItemRef(link, text, button, chatFrame)
            end
        end)
        view.messages = messages
        if not CopyChatFont(chatFrame, messages) and ChatFontNormal then
            messages:SetFontObject(ChatFontNormal)
        end
        BackfillLog(chatFrame, messages)
        local button = chatFrame.ScrollToBottomButton
        if button and not button.exuiLogClick then
            button.exuiLogClick = true
            button:HookScript('OnClick', function()
                local log = chatFrame.exuiLog and chatFrame.exuiLog.messages
                if chat.enabled and log and log.ScrollToBottom then
                    log:ScrollToBottom()
                end
            end)
        end
    end
    local pad = Pixel(chatFrame, TEXT_PAD)
    view:ClearAllPoints()
    view:SetPoint('TOPLEFT', chatFrame, 'TOPLEFT', pad, -pad)
    view:SetPoint('BOTTOMRIGHT', chatFrame, 'BOTTOMRIGHT', -pad, pad)
    view:Show()
    LayoutLog(view)
    if view.messages.MarkDisplayDirty then
        view.messages:MarkDisplayDirty()
    end
end

local function MirrorMessage(chatFrame, message, r, g, b)
    if not chat.enabled or not IsSkinnedFrame(chatFrame) or IsCombatLogFrame(chatFrame) then
        return
    end
    EnsureLog(chatFrame)
    local messages = chatFrame.exuiLog and chatFrame.exuiLog.messages
    if not messages then
        return
    end
    local red = type(r) == 'number' and r or 1
    local green = type(g) == 'number' and g or 1
    local blue = type(b) == 'number' and b or 1
    messages:AddMessage(message, red, green, blue)
    if chat:TimestampsShown() then
        NoteClock(messages)
    end
end

SuppressCombatLog = function()
    local frame = ChatFrame2
    local tab = _G['ChatFrame2Tab']
    if not frame or not tab then
        return
    end
    if not frame.exuiLogHooked then
        frame.exuiLogHooked = true
        frame:HookScript('OnShow', function(self)
            if chat.enabled and skin.logUndocked then
                self:Hide()
            end
        end)
        tab:HookScript('OnShow', function(self)
            if chat.enabled and skin.logUndocked then
                self:Hide()
            end
        end)
    end
    if frame.isDocked and FCF_UnDockFrame then
        if GENERAL_CHAT_DOCK and FCFDock_SelectWindow and FCFDock_GetSelectedWindow
            and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK) == frame then
            FCFDock_SelectWindow(GENERAL_CHAT_DOCK, ChatFrame1)
        end
        FCF_UnDockFrame(frame)
        skin.logUndocked = true
    end
    frame:Hide()
    tab:Hide()
    skin.logHidden = true
end

local function RestoreCombatLog()
    local frame = ChatFrame2
    local tab = _G['ChatFrame2Tab']
    if not frame or not skin.logHidden then
        return
    end
    local redock = skin.logUndocked
    skin.logUndocked = nil
    skin.logHidden = nil
    frame:Show()
    if redock and FCF_DockFrame then
        FCF_DockFrame(frame, 2)
    elseif tab then
        tab:Show()
    end
end

skin.RefreshTimestamps = function(self)
    if not chat.enabled then
        return
    end
    EachFrame(function(chatFrame)
        local view = chatFrame.exuiLog
        if not view or not view.messages then
            return
        end
        LayoutLog(view)
        if view.messages.MarkDisplayDirty then
            view.messages:MarkDisplayDirty()
        end
    end)
end

skin.ClockPrefix = function(self, chatFrame, messageIndex)
    local messages = chatFrame and chatFrame.exuiLog and chatFrame.exuiLog.messages
    if not messages or not chat:TimestampsShown() or not messages.historyBuffer or not messages.GetNumMessages then
        return nil
    end
    local count = messages:GetNumMessages()
    if type(count) ~= 'number' or type(messageIndex) ~= 'number' then
        return nil
    end
    local entry = messages.historyBuffer:GetEntryAtIndex(count - messageIndex + 1)
    return entry and FormatClock(messageClock[entry])
end

UpdateScrollButton = function(chatFrame)
    if not chat.enabled or not IsSkinnedFrame(chatFrame) then
        return
    end
    local button = chatFrame.ScrollToBottomButton
    local scroller = chatFrame.exuiLog and chatFrame.exuiLog.messages or chatFrame
    if not button or not scroller.AtBottom then
        return
    end
    if UIFrameFadeRemoveFrame then
        UIFrameFadeRemoveFrame(button)
    end
    if scroller:AtBottom() then
        button:SetAlpha(0)
        button:EnableMouse(false)
    else
        button:SetAlpha(1)
        button:EnableMouse(true)
    end
end

PadMessageLines = function(chatFrame)
    if not chat.enabled or not IsSkinnedFrame(chatFrame) then
        return
    end
    local lines = chatFrame.visibleLines
    local first = lines and lines[1]
    if not first then
        return
    end
    local pad = Pixel(chatFrame, TEXT_PAD)
    local left = pad + MeasureStamp(chatFrame)
    local width = (chatFrame:GetWidth() or 0) - left - pad
    if width < 1 then
        width = 1
    end
    first:ClearAllPoints()
    if chatFrame.GetInsertMode and chatFrame:GetInsertMode() == SCROLLING_MESSAGE_FRAME_INSERT_MODE_TOP then
        first:SetPoint('TOPLEFT', chatFrame, 'TOPLEFT', left, -pad)
    else
        first:SetPoint('BOTTOMLEFT', chatFrame, 'BOTTOMLEFT', left, pad)
    end
    local index = 1
    while lines[index] do
        lines[index]:SetWidth(width)
        index = index + 1
    end
end

local function Hook(name, fn)
    if _G[name] then
        hooksecurefunc(name, fn)
    end
end

skin.Install = function(self)
    if installed then
        return
    end
    installed = true

    Hook('FCFDock_UpdateTabs', function(dock)
        if not chat.enabled or skin.layouting or skin.applying then
            return
        end
        local before = dock and dock.GetWidth and dock:GetWidth() or 0
        skin.applying = true
        skin:Apply()
        skin.applying = false
        local after = dock and dock.GetWidth and dock:GetWidth() or 0
        if dock and math.abs(before - after) > 1 then
            skin:ScheduleRetab()
        end
    end)
    Hook('FCFDock_SetPrimary', function()
        if not chat.enabled then
            return
        end
        skin:LayoutChrome()
    end)
    Hook('FCF_SetTabPosition', function(chatFrame)
        if not chat.enabled or skin.layouting then
            return
        end
        skin:LayoutUndockedTab(chatFrame)
        skin:QueueDecor()
    end)
    Hook('FCFTab_UpdateColors', function(tab, selected)
        if not chat.enabled or not tab or not tab.GetID then
            return
        end
        local chatFrame = FCF_GetChatFrameByID and FCF_GetChatFrameByID(tab:GetID())
        if not chatFrame or not chatFrame.GetName then
            return
        end
        local frameName = chatFrame:GetName()
        if not frameName or tab ~= _G[frameName .. 'Tab'] then
            return
        end
        StyleTab(chatFrame, tab, selected)
        if not PlaceTabDecor(chatFrame, tab) then
            skin:QueueDecor()
        end
    end)
    Hook('FCF_FadeInChatFrame', function(chatFrame)
        skin:HideChrome(chatFrame)
    end)
    Hook('FCF_FadeOutChatFrame', function(chatFrame)
        skin:HideChrome(chatFrame)
    end)
    Hook('FCF_SetWindowAlpha', function(chatFrame)
        skin:HideChrome(chatFrame)
    end)
    Hook('FCF_FadeInScrollbar', function(chatFrame)
        if chat.enabled and chatFrame then
            skin:HideChrome(chatFrame)
        end
    end)
    Hook('FCF_FadeOutScrollbar', function(chatFrame)
        if chat.enabled and chatFrame and chatFrame.ScrollBar then
            if UIFrameFadeRemoveFrame then
                UIFrameFadeRemoveFrame(chatFrame.ScrollBar)
            end
            chatFrame.ScrollBar:SetAlpha(0)
        end
        UpdateScrollButton(chatFrame)
    end)

    if ChatFrameMixin then
        if ChatFrameMixin.OnUpdate then
            hooksecurefunc(ChatFrameMixin, 'OnUpdate', UpdateScrollButton)
        end
        if ChatFrameMixin.RefreshLayout then
            hooksecurefunc(ChatFrameMixin, 'RefreshLayout', PadMessageLines)
        end
        if ChatFrameMixin.AddMessage then
            hooksecurefunc(ChatFrameMixin, 'AddMessage', MirrorMessage)
        end
    end
    if ScrollingMessageFrameMixin and ScrollingMessageFrameMixin.RefreshDisplay then
        hooksecurefunc(ScrollingMessageFrameMixin, 'RefreshDisplay', function(self)
            if self.exuiOwned then
                LayoutOwnedTimestamps(self)
            end
        end)
    end
end

skin.IconRect = RECT
skin.ApplySprite = ApplySprite
skin.TexCoords = TexCoords
