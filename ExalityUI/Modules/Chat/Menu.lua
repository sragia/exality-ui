---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIChatMenu
local menu = EXUI:GetModule('chat-menu')

---@class EXUIChatSkin
local skin = EXUI:GetModule('chat-skin')

local EXFrames = EXUI.EXFrames

local ATLAS_W, ATLAS_H = 472, 329
local ROW_HEIGHT = 26
local ROW_GAP = 3
local PAD = 6
local ICON_MAX = 16

local SPLIT_RECTS = {
    lock = { 415, 58, 464, 111 },
    unlock = { 415, 114, 464, 167 },
    simpleBg = { 6, 117, 199, 140 },
    simpleBorderOff = { 6, 144, 199, 167 },
    simpleGlowOff = { 6, 171, 135, 194 },
    simpleBorderOn = { 6, 198, 199, 221 },
    simpleGlowOn = { 6, 225, 135, 248 },
}

local panel
local rows = {}
local copyFrame

local function SplitAtlas()
    return EXFrames.assets.textures.splitOptions.atlas
end

local function ApplySplit(texture, key)
    local rect = SPLIT_RECTS[key]
    texture:SetTexture(SplitAtlas())
    texture:SetTexCoord(
        rect[1] / ATLAS_W,
        (rect[3] + 1) / ATLAS_W,
        rect[2] / ATLAS_H,
        (rect[4] + 1) / ATLAS_H
    )
    texture:SetVertexColor(1, 1, 1, 1)
end

local function SliceRow(texture, parent)
    if not texture or not parent or parent:GetWidth() <= 0 then
        return
    end
    if not EXFrames.utils or not EXFrames.utils.texture or not Enum or not Enum.UITextureSliceMode then
        return
    end
    EXFrames.utils.texture.applySlice(texture, 4, parent, Enum.UITextureSliceMode.Stretched)
end

local function CanRead(value)
    if value == nil then
        return false
    end
    if canaccessvalue and not canaccessvalue(value) then
        return false
    end
    return true
end

local function PlainText(text)
    if not CanRead(text) then
        return nil
    end
    text = text:gsub('|c%x%x%x%x%x%x%x%x', '')
    text = text:gsub('|r', '')
    text = text:gsub('|H.-|h(.-)|h', '%1')
    text = text:gsub('|T.-|t', '')
    text = text:gsub('|A.-|a', '')
    text = text:gsub('|K.-|k', '')
    return text
end

local function IconSize(rect)
    local width = rect[3] - rect[1] + 1
    local height = rect[4] - rect[2] + 1
    local scale = ICON_MAX / math.max(width, height)
    return width * scale, height * scale
end

local function IsDockTarget(chatFrame)
    return chatFrame and chatFrame.isDocked and GENERAL_CHAT_DOCK and GENERAL_CHAT_DOCK.primary
end

local function IsLocked(chatFrame)
    if IsDockTarget(chatFrame) then
        return GENERAL_CHAT_DOCK.primary.isLocked and true or false
    end
    return chatFrame and chatFrame.isLocked and true or false
end

local function ToggleLock(chatFrame)
    if IsDockTarget(chatFrame) and FCF_ToggleLockOnDockedFrame then
        CURRENT_CHAT_FRAME_ID = GENERAL_CHAT_DOCK.primary:GetID()
        FCF_ToggleLockOnDockedFrame()
        return
    end
    if FCF_ToggleLock then
        CURRENT_CHAT_FRAME_ID = chatFrame:GetID()
        FCF_ToggleLock()
    end
end

local function OpenChannels(chatFrame)
    CURRENT_CHAT_FRAME_ID = chatFrame:GetID()
    if ShowUIPanel and ChatConfigFrame then
        ShowUIPanel(ChatConfigFrame)
    end
end

local function CollectChatText(chatFrame)
    local lines = {}
    local source = chatFrame.exuiLog and chatFrame.exuiLog.messages or chatFrame
    if source.ForEachMessageInfoText then
        local index = 0
        source:ForEachMessageInfoText(function(text)
            index = index + 1
            local plain = PlainText(text)
            if plain and plain ~= '' then
                local clock = skin.ClockPrefix and skin:ClockPrefix(chatFrame, index)
                if clock then
                    lines[#lines + 1] = clock .. plain
                else
                    lines[#lines + 1] = plain
                end
            end
        end)
    end
    if chatFrame.SetTextCopyable then
        chatFrame:SetTextCopyable(true)
        chatFrame.exuiCopyable = true
    end
    if #lines == 0 then
        return 'Nothing to copy.'
    end
    return table.concat(lines, '\n')
end

local function EnsureCopyFrame()
    if copyFrame then
        return copyFrame
    end
    local frame = EXFrames:GetFrame('window-frame'):Create({
        name = 'EXUIChatCopyFrame',
        size = { 520, 420 },
        title = 'Copy Chat',
    })
    tinsert(UISpecialFrames, 'EXUIChatCopyFrame')

    local scroll = CreateFrame('ScrollFrame', nil, frame.container)
    scroll:SetAllPoints()
    scroll:EnableMouseWheel(true)
    scroll:SetScript('OnMouseWheel', function(self, delta)
        local range = self:GetVerticalScrollRange()
        local nextScroll = self:GetVerticalScroll() - (delta * 24)
        if nextScroll < 0 then
            nextScroll = 0
        elseif nextScroll > range then
            nextScroll = range
        end
        self:SetVerticalScroll(nextScroll)
    end)

    local editBox = CreateFrame('EditBox', nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont(EXFrames.assets.font.default(), 12, '')
    editBox:SetTextColor(unpack(EXFrames.Theme.text))
    editBox:SetWidth(440)
    editBox:SetScript('OnEscapePressed', function(self)
        self:ClearFocus()
        frame:HideWindow()
    end)
    scroll:SetScrollChild(editBox)
    frame.editBox = editBox
    frame.scroll = scroll
    copyFrame = frame
    return frame
end

local function ShowCopy(chatFrame)
    local frame = EnsureCopyFrame()
    local body = CollectChatText(chatFrame)
    local editBox = frame.editBox
    frame:ShowWindow()
    editBox:SetWidth(math.max(120, frame.scroll:GetWidth() - 4))
    editBox:SetText(body)
    local _, breaks = body:gsub('\n', '\n')
    editBox:SetHeight(math.max(frame.scroll:GetHeight(), ((breaks or 0) + 1) * 16))
    frame.scroll:SetVerticalScroll(0)
    editBox:SetFocus()
    editBox:HighlightText()
end

local function EntriesFor(chatFrame)
    local locked = IsLocked(chatFrame)
    local canAdd = not FCF_CanOpenNewWindow or FCF_CanOpenNewWindow()
    return {
        {
            label = 'Add Tab',
            sprite = 'plus',
            disabled = not canAdd,
            onClick = function()
                if FCF_NewChatWindow then
                    FCF_NewChatWindow()
                end
            end,
        },
        {
            label = 'Copy Chat',
            sprite = 'copy',
            onClick = function()
                ShowCopy(chatFrame)
            end,
        },
        {
            label = 'Open Chat Channels',
            sprite = 'channels',
            onClick = function()
                OpenChannels(chatFrame)
            end,
        },
        {
            label = locked and 'Unlock' or 'Lock',
            split = locked and 'unlock' or 'lock',
            onClick = function()
                ToggleLock(chatFrame)
            end,
        },
    }
end

local function SetRowIcon(row, entry)
    local icon = row.icon
    icon:SetVertexColor(1, 1, 1, entry.disabled and 0.35 or 1)
    if entry.swatch then
        icon:SetTexture(EXFrames.assets.textures.solidWhite)
        icon:SetTexCoord(0, 1, 0, 1)
        icon:SetVertexColor(entry.swatch.r or 1, entry.swatch.g or 1, entry.swatch.b or 1, entry.disabled and 0.35 or 1)
        icon:SetSize(12, 12)
        return
    end
    if entry.split then
        ApplySplit(icon, entry.split)
        icon:SetSize(14, 15)
        return
    end
    local rect = skin.IconRect[entry.sprite]
    skin.ApplySprite(icon, rect)
    local width, height = IconSize(rect)
    icon:SetSize(width, height)
end

local function StyleRow(row, hovered)
    local border = hovered and 'simpleBorderOn' or 'simpleBorderOff'
    local glow = hovered and 'simpleGlowOn' or 'simpleGlowOff'
    ApplySplit(row.border, border)
    ApplySplit(row.glow, glow)
    SliceRow(row.border, row)
    SliceRow(row.glow, row)
    row.glow:SetAlpha(hovered and 0.45 or 0.65)
end

local function EnsureRow(index)
    local row = rows[index]
    if row then
        return row
    end
    row = CreateFrame('Button', nil, panel)
    row:SetHeight(ROW_HEIGHT)
    row:RegisterForClicks('LeftButtonUp')

    local bg = row:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    ApplySplit(bg, 'simpleBg')
    SliceRow(bg, row)
    row.bg = bg

    local glow = row:CreateTexture(nil, 'ARTWORK')
    glow:SetAllPoints()
    ApplySplit(glow, 'simpleGlowOff')
    SliceRow(glow, row)
    glow:SetAlpha(0.65)
    row.glow = glow

    local border = row:CreateTexture(nil, 'OVERLAY', nil, 1)
    border:SetAllPoints()
    ApplySplit(border, 'simpleBorderOff')
    SliceRow(border, row)
    row.border = border

    local icon = row:CreateTexture(nil, 'OVERLAY', nil, 2)
    icon:SetPoint('LEFT', 8, 0)
    row.icon = icon

    local label = row:CreateFontString(nil, 'OVERLAY')
    label:SetDrawLayer('OVERLAY', 3)
    label:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')
    label:SetPoint('LEFT', icon, 'RIGHT', 8, 0)
    label:SetPoint('RIGHT', -8, 0)
    label:SetJustifyH('LEFT')
    row.label = label

    row:HookScript('OnSizeChanged', function(self)
        SliceRow(self.bg, self)
        SliceRow(self.glow, self)
        SliceRow(self.border, self)
    end)
    row:SetScript('OnEnter', function(self)
        if self.entry and not self.entry.disabled then
            StyleRow(self, true)
        end
    end)
    row:SetScript('OnLeave', function(self)
        StyleRow(self, false)
    end)
    row:SetScript('OnClick', function(self)
        local entry = self.entry
        if not entry or entry.disabled or not entry.onClick then
            return
        end
        local clicked = panel.chatFrame
        menu:Hide()
        entry.onClick(clicked)
    end)

    rows[index] = row
    return row
end

local function EnsurePanel()
    if panel then
        return panel
    end
    panel = CreateFrame('Frame', 'EXUIChatMenu', UIParent)
    panel:SetFrameStrata('TOOLTIP')
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:Hide()
    tinsert(UISpecialFrames, 'EXUIChatMenu')

    local fill = panel:CreateTexture(nil, 'BACKGROUND', nil, -1)
    fill:SetAllPoints()
    fill:SetTexture(EXFrames.assets.textures.solidWhite)
    fill:SetVertexColor(unpack(EXFrames.Theme.backgroundDeep))

    panel:SetScript('OnUpdate', function(self)
        if not self:IsShown() then
            return
        end
        if not (IsMouseButtonDown('LeftButton') or IsMouseButtonDown('RightButton')) then
            return
        end
        if self:IsMouseOver() then
            return
        end
        if self.anchor and self.anchor:IsMouseOver() then
            return
        end
        menu:Hide()
    end)
    return panel
end

local function Layout(anchor, entries)
    local width = 196
    local height = PAD * 2 + (#entries * ROW_HEIGHT) + ((#entries - 1) * ROW_GAP)
    panel:SetSize(width, height)
    panel.anchor = anchor
    panel:ClearAllPoints()
    panel:SetPoint('TOPRIGHT', anchor, 'BOTTOMRIGHT', 0, -4)

    for index = 1, #entries do
        local row = EnsureRow(index)
        local entry = entries[index]
        row.entry = entry
        row:SetParent(panel)
        row:ClearAllPoints()
        row:SetPoint('TOPLEFT', PAD, -PAD - ((index - 1) * (ROW_HEIGHT + ROW_GAP)))
        row:SetPoint('TOPRIGHT', -PAD, -PAD - ((index - 1) * (ROW_HEIGHT + ROW_GAP)))
        SetRowIcon(row, entry)
        StyleRow(row, false)
        row.label:SetText(entry.label)
        if entry.disabled then
            row.label:SetTextColor(unpack(EXFrames.Theme.textMuted))
        else
            row.label:SetTextColor(unpack(EXFrames.Theme.text))
        end
        row:Show()
    end
    for index = #entries + 1, #rows do
        rows[index]:Hide()
    end
end

menu.Hide = function(self)
    if panel then
        panel:Hide()
    end
end

local function CopyTextPresent(value)
    if issecretvalue and issecretvalue(value) then
        return true
    end
    if canaccessvalue and not canaccessvalue(value) then
        return true
    end
    return type(value) == 'string' and value ~= ''
end

local function EnsureCopyMessages(frame)
    if frame.messages then
        return frame.messages
    end
    local messages = CreateFrame('ScrollingMessageFrame', nil, frame.container)
    messages:SetPoint('TOPLEFT', frame.container, 'TOPLEFT', 8, -8)
    messages:SetPoint('BOTTOMRIGHT', frame.container, 'BOTTOMRIGHT', -8, 8)
    messages:SetFading(false)
    messages:SetMaxLines(500)
    messages:SetJustifyH('LEFT')
    messages:EnableMouse(true)
    messages:EnableMouseWheel(true)
    if messages.SetHyperlinksEnabled then
        messages:SetHyperlinksEnabled(true)
    end
    if messages.SetTextCopyable then
        messages:SetTextCopyable(true)
    end
    messages:SetFont(EXFrames.assets.font.default(), 12, '')
    messages:SetScript('OnMouseWheel', function(self, delta)
        if delta > 0 then
            self:ScrollUp()
        else
            self:ScrollDown()
        end
    end)
    messages:SetScript('OnHyperlinkClick', function(_, link, text, button)
        if SetItemRef then
            SetItemRef(link, text, button)
        end
    end)
    frame.messages = messages
    return messages
end

menu.ShowCopy = function(self, body)
    local frame = EnsureCopyFrame()
    frame:ShowWindow()
    if type(body) == 'table' then
        if frame.scroll then
            frame.scroll:Hide()
        end
        local messages = EnsureCopyMessages(frame)
        messages:Show()
        local limit = #body + 5
        if limit < 50 then
            limit = 50
        end
        messages:SetMaxLines(limit)
        messages:Clear()
        local count = 0
        for _, entry in ipairs(body) do
            local text = entry and entry.text
            if CopyTextPresent(text) then
                messages:AddMessage(text, entry.r or 1, entry.g or 1, entry.b or 1)
                count = count + 1
            end
        end
        if count == 0 then
            messages:AddMessage('Nothing to copy.', 1, 1, 1)
        end
        return
    end
    if frame.messages then
        frame.messages:Hide()
    end
    if frame.scroll then
        frame.scroll:Show()
    end
    local editBox = frame.editBox
    editBox:SetWidth(math.max(120, frame.scroll:GetWidth() - 4))
    editBox:SetText(body or '')
    local _, breaks = (body or ''):gsub('\n', '\n')
    editBox:SetHeight(math.max(frame.scroll:GetHeight(), ((breaks or 0) + 1) * 16))
    frame.scroll:SetVerticalScroll(0)
    editBox:SetFocus()
    editBox:HighlightText()
end

menu.ShowEntries = function(self, anchor, entries)
    if not anchor then
        return
    end
    EnsurePanel()
    if panel:IsShown() and panel.anchor == anchor then
        panel:Hide()
        return
    end
    Layout(anchor, entries or {})
    panel:Show()
end

menu.Toggle = function(self, anchor, chatFrame)
    if not anchor or not chatFrame then
        return
    end
    self:ShowEntries(anchor, EntriesFor(chatFrame))
end
