---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIChatUtil
local util = EXUI:GetModule('chat-util')

---@class EXUIChatDefault
local defaultChat = EXUI:GetModule('chat-default')

---@class EXUIChatWindow
local window = EXUI:GetModule('chat-window')

---@class EXUIChatComposer
local composer = EXUI:GetModule('chat-composer')

local FontPath = util.FontPath
local IsSecret = util.IsSecret

local function HideEditChrome(box)
    local function hide(region)
        if not region then
            return
        end
        if region.SetAlpha then
            region:SetAlpha(0)
        end
        if region.Hide then
            region:Hide()
        end
    end
    hide(box.NewcomerHint)
    hide(box.prompt)
    hide(box.focusLeft)
    hide(box.focusRight)
    hide(box.focusMid)
    local name = box.GetName and box:GetName()
    if name then
        hide(_G[name .. 'Left'])
        hide(_G[name .. 'Right'])
        hide(_G[name .. 'Mid'])
        hide(_G[name .. 'Language'])
    end
end

local function CreateEditBox(parent)
    local mixin = ChatFrameEditBoxMixin
    local originalOnLoad = mixin and mixin.OnLoad
    if originalOnLoad then
        mixin.OnLoad = function(self)
            if not self.chatFrame then
                self.chatFrame = _G.ChatFrame1
            end
            return originalOnLoad(self)
        end
    end
    local created, createdBox = pcall(CreateFrame, 'EditBox', 'ExalityUIChatEditBox', parent, 'ChatFrameEditBoxTemplate')
    if originalOnLoad then
        mixin.OnLoad = originalOnLoad
    end
    if not created then
        error(createdBox)
    end
    return createdBox
end

function composer:Create(editBg)
    local header = editBg:CreateFontString(nil, 'OVERLAY')
    header:SetFont(FontPath(), 13, 'OUTLINE')
    header:SetPoint('LEFT', editBg, 'LEFT', 8, 0)
    header:SetWidth(36)
    header:SetJustifyH('LEFT')
    header:Hide()
    self.header = header

    local editBox = _G.ChatFrame1EditBox
    if editBox then
        editBox.exuiAdopted = true
        editBox.exuiSavedParent = editBox:GetParent()
    else
        editBox = CreateEditBox(window.frame)
    end
    self.editBox = editBox
    if not editBox.exuiFocusHooked then
        editBox.exuiFocusHooked = true
        editBox:HookScript('OnEditFocusGained', function()
            composer.editFocused = true
        end)
        editBox:HookScript('OnEditFocusLost', function()
            composer.editFocused = false
        end)
    end
    if editBox.SetIgnoreParentAlpha then
        editBox:SetIgnoreParentAlpha(true)
    end
    editBox:ClearAllPoints()
    editBox:SetFrameStrata('DIALOG')
    editBox:SetFrameLevel(editBg:GetFrameLevel() + 20)
    if editBox.SetToplevel then
        editBox:SetToplevel(false)
    end
    editBox:SetFont(FontPath(), 13, '')
    editBox:SetAutoFocus(false)
    editBox:SetPoint('TOPLEFT', editBg, 'TOPLEFT', 4, -2)
    editBox:SetPoint('BOTTOMRIGHT', editBg, 'BOTTOMRIGHT', -4, 2)
    HideEditChrome(editBox)
    editBox:Show()
    editBox:SetAlpha(0)
    editBox:EnableMouse(false)
    self.open = false
end

function composer:HookChatOpen()
    if self.chatOpenHooked or not ChatFrameUtil or not ChatFrameUtil.OpenChat then
        return
    end
    local function AllowComposer()
        composer.allowed = true
    end
    hooksecurefunc(ChatFrameUtil, 'OpenChat', AllowComposer)
    if type(ChatFrame_OpenChat) == 'function' then
        hooksecurefunc('ChatFrame_OpenChat', AllowComposer)
    end
    self.chatOpenHooked = true
end

function composer:Release()
    local edit = self.editBox
    if not edit then
        return
    end
    edit:ClearFocus()
    if not edit.exuiAdopted then
        return
    end
    if edit.SetToplevel then
        edit:SetToplevel(true)
    end
    if edit.SetFontObject and ChatFontNormal then
        pcall(edit.SetFontObject, edit, ChatFontNormal)
    end
    edit:SetAlpha(1)
    edit:EnableMouse(true)
    if edit.exuiSavedParent then
        edit:SetParent(edit.exuiSavedParent)
    end
    edit:ClearAllPoints()
    edit.exuiAdopted = nil
end

function composer:PaintHeader(text, r, g, b)
    if not self.header then
        return
    end
    if IsSecret(text) then
        self.header:SetText(text)
    elseif type(text) ~= 'string' or text == '' then
        self.header:SetText('Say')
    else
        self.header:SetText(text)
    end
    if not IsSecret(r) and not IsSecret(g) and not IsSecret(b) then
        self.header:SetTextColor(r or 1, g or 1, b or 1)
        if self.editBox then
            self.editBox:SetTextColor(r or 1, g or 1, b or 1)
        end
    end
    local width = self.header:GetStringWidth()
    if IsSecret(width) or type(width) ~= 'number' or width < 8 then
        width = 36
    end
    self.header:SetWidth(width + 4)
end

local function CaptureHeader(box)
    local header = box and (box.header or (box.GetName and _G[box:GetName() .. 'Header']))
    local shown = header and header.GetText and header:GetText() or ''
    if IsSecret(shown) then
        local r, g, b = 1, 1, 1
        if header and header.GetTextColor then
            local hr, hg, hb = header:GetTextColor()
            if not IsSecret(hr) and not IsSecret(hg) and not IsSecret(hb) then
                r, g, b = hr or 1, hg or 1, hb or 1
            end
        end
        return shown, r, g, b
    end
    local chatType = 'SAY'
    if box and box.GetChatType then
        local kind = box:GetChatType()
        if not IsSecret(kind) and type(kind) == 'string' and kind ~= '' then
            chatType = kind
        end
    end
    local channel
    if chatType == 'CHANNEL' and box.GetChannelTarget and GetChannelName then
        local id = box:GetChannelTarget()
        if not IsSecret(id) and type(id) == 'number' and id > 0 then
            local _, name = GetChannelName(id)
            if type(name) == 'string' and name ~= '' then
                channel = name
            end
        end
    end
    local r, g, b = util.MessageColor(chatType, channel)
    if type(shown) ~= 'string' then
        shown = util.LABEL[chatType] or 'Say'
    end
    return shown, r, g, b
end

function composer:RefreshHeader()
    local edit = self.editBox
    if not edit or not self.header then
        return
    end
    local box = edit.UpdateHeader and edit or _G.ChatFrame1EditBox
    if box and box.UpdateHeader then
        pcall(box.UpdateHeader, box)
        self:PaintHeader(CaptureHeader(box))
        return
    end
    self:PaintHeader('Say', util.ChatColor('SAY'))
end

function composer:CommitCommand()
    local edit = self.editBox
    if not edit then
        return
    end
    local text = edit:GetText()
    if IsSecret(text) or type(text) ~= 'string' or text:sub(1, 1) ~= '/' or not text:find('%s') then
        return
    end
    local box = edit.ParseText and edit or _G.ChatFrame1EditBox
    if not box or not box.ParseText then
        return
    end
    if box ~= edit then
        box:SetText(text)
    end
    box:ParseText(0, true)
    if box ~= edit then
        local left = box:GetText()
        if not IsSecret(left) and type(left) == 'string' and left ~= text then
            edit:SetText(left)
            edit:SetCursorPosition(#left)
        end
    end
    if AutoComplete_HideIfAttachedTo then
        AutoComplete_HideIfAttachedTo(box)
    end
end

function composer:PlaceEditBox()
    local edit = self.editBox
    local bg = window.editBg
    if not edit or not bg then
        return
    end
    if edit.SetFrameStrata then
        edit:SetFrameStrata('DIALOG')
    end
    edit:SetFrameLevel((bg:GetFrameLevel() or 0) + 20)
end

local function IsAnchoredTo(edit, point, relativeTo, x, y)
    local p, rel, relPoint, px, py = edit:GetPointByName(point)
    return p and rel == relativeTo and relPoint == point and px == x and py == y
end

-- Sync runs every frame; avoid re-anchoring (and the layout pass it triggers) when nothing moved.
local function IsDockedInBackground(edit, bg)
    if edit:GetNumPoints() ~= 2 then
        return false
    end
    if not IsAnchoredTo(edit, 'TOPLEFT', bg, 4, -2) or not IsAnchoredTo(edit, 'BOTTOMRIGHT', bg, -4, 2) then
        return false
    end
    if edit.GetTextInsets then
        local left, right, top, bottom = edit:GetTextInsets()
        return left == 4 and right == 8 and top == 0 and bottom == 0
    end
    return true
end

function composer:AnchorEditBox(besideHeader)
    local edit = self.editBox
    local bg = window.editBg
    if not edit or not bg then
        return
    end
    if not besideHeader and IsDockedInBackground(edit, bg) then
        return
    end
    edit:ClearAllPoints()
    if besideHeader and self.header and self.header:IsShown() then
        edit:SetPoint('LEFT', self.header, 'RIGHT', 6, 0)
        edit:SetPoint('RIGHT', bg, 'RIGHT', -4, 0)
        edit:SetHeight(22)
    else
        edit:SetPoint('TOPLEFT', bg, 'TOPLEFT', 4, -2)
        edit:SetPoint('BOTTOMRIGHT', bg, 'BOTTOMRIGHT', -4, 2)
    end
    if edit.SetTextInsets then
        edit:SetTextInsets(4, 8, 0, 0)
    end
end

function composer:Show()
    self.open = true
    if window.editBg then
        window.editBg:Show()
    end
    if self.header and not self.outsideLabel then
        self.header:Hide()
    end
    if self.editBox then
        self.editBox:Show()
        self.editBox:SetAlpha(1)
        self.editBox:EnableMouse(true)
    end
    self:PlaceEditBox()
end

function composer:Hide(force)
    if not force and self.editFocused then
        return
    end
    self.open = false
    if window.editBg then
        window.editBg:Hide()
    end
    if self.header then
        self.header:Hide()
    end
    if self.editBox then
        self.editBox:SetAlpha(0)
        self.editBox:EnableMouse(false)
    end
end

function composer:Sync()
    local edit = self.editBox
    if not edit then
        return
    end
    local chat = _G.ChatFrame1
    if chat and defaultChat.silenced and chat ~= edit:GetParent() then
        chat = nil
    end
    if chat and defaultChat.silenced then
        if not chat:IsShown() then
            chat:Show()
        end
        if chat.SetClipsChildren and chat:DoesClipChildren() then
            chat:SetClipsChildren(false)
        end
        if chat:GetAlpha() ~= 0 then
            chat:SetAlpha(0)
        end
        if chat:IsMouseEnabled() then
            chat:EnableMouse(false)
        end
    end
    if edit.setText == 1 and IsSecret(edit.text) then
        self.secretTextWait = (self.secretTextWait or 0) + 1
        if self.secretTextWait > 5 then
            edit.setText = 0
            edit.text = nil
            self.secretTextWait = nil
        end
    else
        self.secretTextWait = nil
    end
    local focused = self.editFocused == true
    if focused and not self.allowed then
        edit:ClearFocus()
        focused = false
    end
    if focused then
        self:Show()
        edit:SetAlpha(1)
        edit:EnableMouse(true)
        HideEditChrome(edit)
        if self.outsideLabel then
            if edit.header and edit.header:IsShown() then
                edit.header:Hide()
                if edit.headerSuffix then
                    edit.headerSuffix:Hide()
                end
                if edit.SetTextInsets then
                    edit:SetTextInsets(4, 8, 0, 0)
                end
            end
        elseif edit.header then
            edit.header:Show()
        end
        return
    end
    if window.editBg then
        window.editBg:Hide()
    end
    if self.header then
        self.header:Hide()
    end
    self.outsideLabel = false
    self:AnchorEditBox(false)
    self.open = false
    if edit:GetAlpha() ~= 0 then
        edit:SetAlpha(0)
    end
end

function composer:UseEditBox(func, ...)
    local frame = _G.DEFAULT_CHAT_FRAME or _G.ChatFrame1
    local edit = self.editBox
    if not func or not edit or not frame then
        if func then
            func(...)
        end
        return
    end
    local savedBox = frame.editBox
    local savedLast = _G.LAST_ACTIVE_CHAT_EDIT_BOX
    local swapBox = savedBox ~= edit
    local swapLast = savedLast ~= edit
    local call = securecallfunction
    if swapBox then
        frame.editBox = edit
    end
    if swapLast then
        _G.LAST_ACTIVE_CHAT_EDIT_BOX = edit
    end
    if call then
        call(func, ...)
    else
        func(...)
    end
    if swapBox and frame.editBox == edit then
        frame.editBox = savedBox
    end
    if swapLast and _G.LAST_ACTIVE_CHAT_EDIT_BOX == edit and savedLast and _G.ACTIVE_CHAT_EDIT_BOX ~= edit then
        _G.LAST_ACTIVE_CHAT_EDIT_BOX = savedLast
    end
end

function composer:BeginWhisper(name, chatType)
    local edit = self.editBox
    if not edit then
        return
    end
    local secret = IsSecret(name)
    if not secret and (type(name) ~= 'string' or name == '') then
        return
    end
    local bn = chatType == 'BN_WHISPER' or chatType == 'BN_WHISPER_INFORM'
    self.allowed = true
    self:Show()
    edit:SetFocus()
    if secret then
        local kind = bn and 'BN_WHISPER' or 'WHISPER'
        local label = CHAT_WHISPER_SEND
        if bn then
            label = CHAT_BN_WHISPER_SEND or label
        end
        if edit.SetChatType then
            edit:SetChatType(kind)
        end
        if edit.SetStickyType then
            edit:SetStickyType(kind)
        end
        if self.header and label and self.header.SetFormattedText then
            self.outsideLabel = true
            self.header:SetWidth(0)
            self.header:SetFormattedText(label, name)
            local r, g, b = util.MessageColor(kind)
            if not IsSecret(r) and not IsSecret(g) and not IsSecret(b) then
                self.header:SetTextColor(r or 1, g or 1, b or 1)
            end
            self.header:Show()
            self:AnchorEditBox(true)
        end
        if edit.header then
            edit.header:Hide()
        end
        if edit.SetTextInsets then
            edit:SetTextInsets(4, 8, 0, 0)
        end
        return
    end
    if bn then
        if edit.SetChatType then
            edit:SetChatType('BN_WHISPER')
        end
        if edit.SetTellTarget then
            edit:SetTellTarget(name)
        end
        edit:SetText('')
        self:RefreshHeader()
        return
    end
    local slash = SLASH_WHISPER1 or '/w'
    edit:SetText(slash .. ' ' .. name .. ' ')
    self:CommitCommand()
    self:RefreshHeader()
end

function composer:ClickName(line, button)
    local name = line and line.sender
    if IsSecret(name) then
        return
    end
    if type(name) ~= 'string' or name == '' then
        return
    end
    if IsModifiedClick and IsModifiedClick('CHATLINK') then
        local edit = self.editBox
        if not edit then
            return
        end
        edit:SetFocus()
        local current = edit:GetText()
        if IsSecret(current) or type(current) ~= 'string' then
            current = ''
        end
        if current ~= '' and current:sub(-1) ~= ' ' then
            current = current .. ' '
        end
        edit:SetText(current .. name)
        return
    end
    if button == 'RightButton' and FriendsFrame_ShowDropdown then
        local lineID = line.lineID
        if IsSecret(lineID) or type(lineID) ~= 'number' then
            lineID = nil
        end
        pcall(FriendsFrame_ShowDropdown, name, 1, lineID, line.chatType)
        return
    end
    self:BeginWhisper(name, line.chatType)
end

function composer:ClickLink(link, text, button)
    if IsSecret(link) then
        if SetItemRef then
            self:UseEditBox(SetItemRef, link, text, button, _G.ChatFrame1)
        end
        return
    end
    if type(link) ~= 'string' then
        return
    end
    local kind = link:match('^([^:]+)')
    if kind == 'player' or kind == 'playerCommunity' or kind == 'playerGM' then
        local name, lineText, chatType = link:match('^[^:]+:([^:]+):([^:]*):([^:]*)')
        if not name or name == '' then
            name = link:match('^[^:]+:([^:]+)')
        end
        if name and name ~= '' then
            local lineID = tonumber(lineText)
            if lineID == 0 then
                lineID = nil
            end
            if type(chatType) ~= 'string' or chatType == '' or chatType == '0' then
                chatType = 'SAY'
            end
            self:ClickName({ sender = name, chatType = chatType, lineID = lineID }, button)
        end
        return
    end
    if kind == 'BNplayer' or kind == 'BNplayerCommunity' then
        local name = link:match('^[^:]+:([^:]+)')
        if name and name ~= '' then
            self:ClickName({ sender = name, chatType = 'BN_WHISPER' }, button)
        end
        return
    end
    if SetItemRef then
        SetItemRef(link, text, button, _G.ChatFrame1)
    end
end

function composer:ShowLinkTooltip(owner, link)
    if IsSecret(link) or type(link) ~= 'string' then
        return
    end
    local kind = link:match('^([^:]+)')
    if kind == 'player' or kind == 'playerCommunity' or kind == 'playerGM' or kind == 'BNplayer' or kind == 'BNplayerCommunity' then
        return
    end
    GameTooltip:SetOwner(owner, 'ANCHOR_CURSOR')
    if not pcall(GameTooltip.SetHyperlink, GameTooltip, link) then
        GameTooltip:Hide()
        return
    end
    GameTooltip:Show()
end
