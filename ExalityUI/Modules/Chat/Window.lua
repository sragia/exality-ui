---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIChatUtil
local util = EXUI:GetModule('chat-util')

---@class EXUIChatHistory
local history = EXUI:GetModule('chat-history')

---@class EXUIChatMessages
local messages = EXUI:GetModule('chat-messages')

---@class EXUIChatComposer
local composer = EXUI:GetModule('chat-composer')

---@class EXUIChatPanels
local panels = EXUI:GetModule('chat-panels')

---@class EXUIChatDefault
local defaultChat = EXUI:GetModule('chat-default')

---@class EXUIChatWindow
local window = EXUI:GetModule('chat-window')

local Chat = util.Chat
local ApplySprite = util.ApplySprite
local ApplySlicedSprite = util.ApplySlicedSprite

local BG_RECT = { 7, 74, 134, 201 }
local BG_BORDER_RECT = { 143, 73, 270, 200 }
local BG_SLICE = 3
local EDIT_BG_RECT = { 7, 261, 265, 290 }
local EDIT_BORDER_RECT = { 7, 295, 265, 324 }
local EDIT_SHADOW_RECT = { 0, 327, 275, 376 }
local EDIT_SLICE = 3
local EDIT_HEIGHT = 30
local EDIT_SHADOW_OUTSET = { 6, 9, 9, 9 }
local MENU_RECT = { 60, 7, 81, 56 }
local SCROLL_RECT = { 4, 5, 49, 60 }
local MENU_ICON_W = 10
local MENU_ICON_H = 22

local function CreateMenuButton(frame)
    local menuButton = CreateFrame('Button', nil, frame)
    menuButton:SetSize(16, 26)
    menuButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -6, -4)
    menuButton:SetFrameLevel(frame:GetFrameLevel() + 20)
    local menuIcon = menuButton:CreateTexture(nil, 'ARTWORK')
    menuIcon:SetSize(MENU_ICON_W, MENU_ICON_H)
    menuIcon:SetPoint('CENTER')
    ApplySprite(menuIcon, MENU_RECT)
    menuIcon:SetAlpha(0.35)
    menuButton:SetScript('OnClick', function()
        panels:ToggleMenu()
    end)
    menuButton:SetScript('OnEnter', function(self)
        menuIcon:SetAlpha(1)
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Chat Menu')
        GameTooltip:Show()
    end)
    menuButton:SetScript('OnLeave', function()
        menuIcon:SetAlpha(0.35)
        GameTooltip:Hide()
    end)
    return menuButton
end

local function CreateClip(frame)
    local clip = CreateFrame('Frame', nil, frame)
    clip:SetPoint('TOPLEFT', frame, 'TOPLEFT', 12, -28)
    clip:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -12, 40)
    clip:SetClipsChildren(true)
    local host = _G.ChatFrame1
    if host then
        clip:SetParent(host)
        if clip.SetIgnoreParentAlpha then
            clip:SetIgnoreParentAlpha(true)
        end
        if clip.SetHyperlinkPropagateToParent then
            clip:SetHyperlinkPropagateToParent(true)
        end
        if host.SetClipsChildren then
            host:SetClipsChildren(false)
        end
    end
    clip:EnableMouseWheel(true)
    clip:EnableMouse(true)
    clip:SetScript('OnMouseWheel', function(_, delta)
        messages:Scroll(delta)
    end)
    clip:SetScript('OnSizeChanged', function()
        messages:Layout()
    end)
    return clip
end

local function LiftAboveClip(button, clip)
    local host = clip:GetParent()
    if button:GetParent() ~= host then
        button:SetParent(host)
        if button.SetIgnoreParentAlpha then
            button:SetIgnoreParentAlpha(true)
        end
    end
    button:SetFrameLevel(clip:GetFrameLevel() + 20)
end

local function CreateScrollButton(frame)
    local scrollButton = CreateFrame('Button', nil, frame)
    scrollButton:SetSize(20, 24)
    scrollButton:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6, 6)
    scrollButton:SetFrameLevel(frame:GetFrameLevel() + 20)
    local scrollIcon = scrollButton:CreateTexture(nil, 'ARTWORK')
    scrollIcon:SetAllPoints()
    ApplySprite(scrollIcon, SCROLL_RECT)
    scrollButton:SetScript('OnClick', function()
        messages:ScrollToBottom()
    end)
    scrollButton:Hide()
    return scrollButton
end

local function CreateEditBackground(frame)
    local editBg = CreateFrame('Frame', nil, frame)
    editBg:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 10, 8)
    editBg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -10, 8)
    editBg:SetHeight(EDIT_HEIGHT)
    local shadowLeft, shadowRight, shadowTop, shadowBottom = unpack(EDIT_SHADOW_OUTSET)
    local shadow = editBg:CreateTexture(nil, 'BACKGROUND', nil, -1)
    shadow:SetPoint('TOPLEFT', editBg, 'TOPLEFT', -shadowLeft, shadowTop)
    shadow:SetPoint('BOTTOMRIGHT', editBg, 'BOTTOMRIGHT', shadowRight, -shadowBottom)
    ApplySlicedSprite(shadow, EDIT_SHADOW_RECT, shadowLeft + EDIT_SLICE, shadowTop + EDIT_SLICE, shadowRight + EDIT_SLICE,
        shadowBottom + EDIT_SLICE)
    local plate = editBg:CreateTexture(nil, 'BACKGROUND')
    plate:SetAllPoints()
    ApplySlicedSprite(plate, EDIT_BG_RECT, EDIT_SLICE, EDIT_SLICE, EDIT_SLICE, EDIT_SLICE)
    local border = editBg:CreateTexture(nil, 'BORDER')
    border:SetAllPoints()
    ApplySlicedSprite(border, EDIT_BORDER_RECT, EDIT_SLICE, EDIT_SLICE, EDIT_SLICE, EDIT_SLICE)
    return editBg
end

function window:Create()
    if self.frame then
        return
    end

    local frame = CreateFrame('Frame', 'ExalityUIChat', UIParent)
    frame:SetSize(460, 230)
    frame:SetFrameStrata('LOW')
    frame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 24, 24)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetScript('OnUpdate', function()
        if Chat():GetHideAfter() > 0 then
            messages:RefreshFade()
        end
        composer:Sync()
    end)
    self.frame = frame

    local tabBar = CreateFrame('Frame', nil, frame)
    tabBar:SetPoint('TOPLEFT', frame, 'TOPLEFT', 8, -4)
    tabBar:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -24, -4)
    tabBar:SetHeight(24)
    self.tabBar = tabBar

    self.menuButton = CreateMenuButton(frame)

    local bg = frame:CreateTexture(nil, 'BACKGROUND', nil, -1)
    bg:SetAllPoints()
    ApplySlicedSprite(bg, BG_RECT, BG_SLICE, BG_SLICE, BG_SLICE, BG_SLICE)
    self.bg = bg
    local frameBorder = frame:CreateTexture(nil, 'BORDER')
    frameBorder:SetAllPoints()
    ApplySlicedSprite(frameBorder, BG_BORDER_RECT, BG_SLICE, BG_SLICE, BG_SLICE, BG_SLICE)

    self.clip = CreateClip(frame)
    self.scrollButton = CreateScrollButton(frame)
    LiftAboveClip(self.menuButton, self.clip)
    LiftAboveClip(self.scrollButton, self.clip)
    self.editBg = CreateEditBackground(frame)

    composer:Create(self.editBg)
    self.editBg:Hide()
    self:ApplySize()
    self:ApplyPosition()
    self:ApplyChrome()
    composer:Hide(true)
end

function window:ApplyPosition()
    local frame = self.frame
    if not frame then
        return
    end
    local point = Chat().Data:GetValue('anchorPoint') or 'BOTTOMLEFT'
    local relative = Chat().Data:GetValue('relativeAnchor') or point
    local x = Chat().Data:GetValue('xOffset')
    local y = Chat().Data:GetValue('yOffset')
    if type(x) ~= 'number' then
        x = 24
    end
    if type(y) ~= 'number' then
        y = 24
    end
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, relative, x, y)
end

function window:ApplySize()
    local frame = self.frame
    if not frame then
        return
    end
    local width = Chat().Data:GetValue('width')
    local height = Chat().Data:GetValue('height')
    if type(width) ~= 'number' then
        width = 460
    end
    if type(height) ~= 'number' then
        height = 230
    end
    frame:SetSize(width, height)
end

function window:ApplyChrome()
    local frame = self.frame
    if not frame or not self.tabBar or not self.clip or not self.editBg then
        return
    end
    local tabTop = Chat():GetTabSide() ~= 'bottom'
    local editTop = Chat():GetEditBoxSide() == 'top'
    local sameSide = tabTop == editTop
    local outward = sameSide and 26 or 2

    self.tabBar:ClearAllPoints()
    if tabTop then
        self.tabBar:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 6, 0)
        self.tabBar:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', -6, 0)
    else
        self.tabBar:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 6, 0)
        self.tabBar:SetPoint('TOPRIGHT', frame, 'BOTTOMRIGHT', -6, 0)
    end

    if self.menuButton then
        self.menuButton:ClearAllPoints()
        self.menuButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -6, -4)
    end

    self.clip:ClearAllPoints()
    self.clip:SetPoint('TOPLEFT', frame, 'TOPLEFT', 8, -8)
    self.clip:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -8, 8)

    self.editBg:ClearAllPoints()
    if editTop then
        self.editBg:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, outward)
        self.editBg:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', 0, outward)
    else
        self.editBg:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 0, -outward)
        self.editBg:SetPoint('TOPRIGHT', frame, 'BOTTOMRIGHT', 0, -outward)
    end
    self.editBg:SetHeight(EDIT_HEIGHT)

    if composer.open then
        composer:Show()
    else
        composer:Hide(true)
    end
end

----------------------------------------------------------------
-- Lock / move
----------------------------------------------------------------

function window:IsLocked()
    local locked = Chat().Data:GetValue('locked')
    if locked == nil then
        return true
    end
    return locked and true or false
end

function window:SavePointFromFrame(frame)
    if not frame or frame:GetNumPoints() < 1 then
        return
    end
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if type(point) ~= 'string' or type(x) ~= 'number' or type(y) ~= 'number' then
        return
    end
    Chat().Data:SetValue('anchorPoint', point)
    Chat().Data:SetValue('relativeAnchor', relativePoint or point)
    Chat().Data:SetValue('xOffset', x)
    Chat().Data:SetValue('yOffset', y)
end

function window:BeginMove()
    if self:IsLocked() or self.moving then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local frame = self.frame
    if not frame then
        return
    end
    frame:SetMovable(true)
    frame.isMovable = true
    if not pcall(frame.StartMoving, frame) then
        return
    end
    self.moving = true
end

function window:EndMove()
    local frame = self.frame
    if not frame or not self.moving then
        return
    end
    self.moving = false
    frame:StopMovingOrSizing()
    self:SavePointFromFrame(frame)
    if self:IsLocked() then
        frame:SetMovable(false)
        frame.isMovable = false
    end
end

function window:BindMoveTarget(target)
    if not target or target == self.frame then
        return
    end
    if self:IsLocked() then
        target:RegisterForDrag()
        target:SetScript('OnDragStart', nil)
        target:SetScript('OnDragStop', nil)
        return
    end
    target:RegisterForDrag('LeftButton')
    target:SetScript('OnDragStart', function()
        window:BeginMove()
    end)
    target:SetScript('OnDragStop', function()
        window:EndMove()
    end)
end

function window:ApplyLock()
    local frame = self.frame
    if not frame then
        return
    end
    local locked = self:IsLocked()
    frame.isMovable = not locked
    frame:SetMovable(not locked)
    if panels.dragTabId and locked then
        panels:EndTabDrag()
    end
    if self.editBg then
        self.editBg:EnableMouse(not locked)
    end
    self:BindMoveTarget(self.clip)
    self:BindMoveTarget(self.editBg)
    for _, row in ipairs(messages.rows) do
        self:BindMoveTarget(row)
    end
    if frame.editor then
        return
    end
    if locked then
        frame:RegisterForDrag()
        frame:SetScript('OnDragStart', nil)
        frame:SetScript('OnDragStop', nil)
        return
    end
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', function()
        window:BeginMove()
    end)
    frame:SetScript('OnDragStop', function()
        window:EndMove()
    end)
end

----------------------------------------------------------------
-- Editor mode
----------------------------------------------------------------

function window:SetMessageMouse(enabled)
    if self.clip then
        self.clip:EnableMouse(enabled)
    end
    if self.menuButton then
        self.menuButton:EnableMouse(enabled)
    end
    if self.scrollButton then
        self.scrollButton:EnableMouse(enabled)
    end
    messages:SetMouse(enabled)
end

function window:HookEditorOverlay()
    local overlay = self.frame and self.frame.editor
    if not overlay or overlay.exuiChatHook then
        return
    end
    overlay:HookScript('OnShow', function()
        window:SetMessageMouse(false)
        if composer.editBox then
            composer.editBox:ClearFocus()
        end
    end)
    overlay:HookScript('OnHide', function()
        window:SetMessageMouse(true)
    end)
    overlay.exuiChatHook = true
    if overlay:IsShown() then
        self:SetMessageMouse(false)
    end
end

function window:RegisterEditor()
    local editor = EXUI:GetModule('editor')
    if not editor or not editor.RegisterFrameForEditor or not self.frame then
        return
    end
    if not editor:IsFrameRegistered(self.frame) then
        editor:RegisterFrameForEditor(self.frame, 'Chat', function(frame)
            window:SavePointFromFrame(frame)
        end)
    end
    self:HookEditorOverlay()
end

function window:UnregisterEditor()
    local editor = EXUI:GetModule('editor')
    if self.frame and editor and editor.UnregisterFrameForEditor then
        editor:UnregisterFrameForEditor(self.frame)
    end
    if self.frame and self.frame.editor then
        self.frame.editor:Hide()
    end
end

----------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------

function window:Refresh()
    if not self.frame then
        return
    end
    self.bg:SetAlpha(Chat():GetBackgroundAlpha())
    self:ApplySize()
    self:ApplyPosition()
    self:ApplyChrome()
    composer:RefreshHeader()
    panels:RefreshTabs()
    messages:Layout()
end

function window:Enable()
    self:Create()
    history:LoadLog()
    defaultChat:Silence()
    defaultChat:HookPrint()
    defaultChat:ImportStartupMessages()
    defaultChat:RegisterEvents()
    defaultChat:ShowLoginGuildMotd()
    composer:HookChatOpen()
    self:RegisterEditor()
    self:ApplyLock()
    self.frame:Show()
    self.menuButton:Show()
    self:Refresh()
    if composer.editBox then
        composer.editBox:ClearFocus()
        composer:Hide(true)
    end
end

function window:Disable()
    defaultChat:UnregisterEvents()
    composer:Release()
    panels:HideMenu()
    panels:HideConfig()
    self:UnregisterEditor()
    defaultChat:Restore()
    if self.frame then
        self.frame:Hide()
        self.menuButton:Hide()
        self.scrollButton:Hide()
    end
end
