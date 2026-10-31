---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIChatUtil
local util = EXUI:GetModule('chat-util')

---@class EXUIChatFormat
local formatter = EXUI:GetModule('chat-format')

---@class EXUIChatHistory
local history = EXUI:GetModule('chat-history')

---@class EXUIChatMessages
local messages = EXUI:GetModule('chat-messages')

---@class EXUIChatComposer
local composer = EXUI:GetModule('chat-composer')

---@class EXUIChatDefault
local defaultChat = EXUI:GetModule('chat-default')

local IsSecret = util.IsSecret

local SOCIAL_BUTTONS = {
    'ChatFrameChannelButton',
    'ChatFrameToggleVoiceDeafenButton',
    'ChatFrameToggleVoiceMuteButton',
    'TextToSpeechButton',
    'TextToSpeechButtonFrame',
    'QuickJoinToastButton',
    'ChatFrameMenuButton',
}

local GROUPS = {
    'SAY',
    'EMOTE',
    'YELL',
    'WHISPER',
    'PARTY',
    'PARTY_LEADER',
    'RAID',
    'RAID_LEADER',
    'RAID_WARNING',
    'INSTANCE_CHAT',
    'INSTANCE_CHAT_LEADER',
    'GUILD',
    'OFFICER',
    'CHANNEL',
    'SYSTEM',
    'BN_WHISPER',
    'MONSTER_SAY',
    'MONSTER_YELL',
    'LOOT',
    'CURRENCY',
    'MONEY',
    'PING',
}

local HIDE_EVENTS = {
    'UPDATE_CHAT_WINDOWS',
    'UPDATE_FLOATING_CHAT_WINDOWS',
    'PLAYER_ENTERING_WORLD',
}

defaultChat.silenced = false

local function CopyList(list)
    local copy = {}
    if type(list) ~= 'table' then
        return copy
    end
    for _, value in pairs(list) do
        copy[#copy + 1] = value
    end
    return copy
end

local function HookHide(frame)
    if not frame or frame.exuiChatHideHook then
        return
    end
    frame:HookScript('OnShow', function(self)
        if not defaultChat.silenced or self.exuiChatHiding then
            return
        end
        self.exuiChatHiding = true
        self:Hide()
        self.exuiChatHiding = false
    end)
    frame.exuiChatHideHook = true
end

----------------------------------------------------------------
-- Blizzard chat frames
----------------------------------------------------------------

function defaultChat:HideSocial()
    self.socialShown = self.socialShown or {}
    for _, name in ipairs(SOCIAL_BUTTONS) do
        local button = _G[name]
        if button then
            if self.socialShown[name] == nil then
                self.socialShown[name] = button:IsShown() and true or false
            end
            button:Hide()
            HookHide(button)
        end
    end
end

function defaultChat:ShowSocial()
    for _, name in ipairs(SOCIAL_BUTTONS) do
        local button = _G[name]
        if button and self.socialShown and self.socialShown[name] then
            button:Show()
        end
    end
    self.socialShown = nil
end

function defaultChat:HideDefault()
    local names = CHAT_FRAMES
    if type(names) == 'table' then
        for _, name in ipairs(names) do
            local frame = _G[name]
            if frame then
                if frame == _G.ChatFrame1 then
                    frame:Show()
                    frame:SetAlpha(0)
                    frame:EnableMouse(false)
                    if frame.SetClipsChildren then
                        frame:SetClipsChildren(false)
                    end
                else
                    frame:Hide()
                end
                local frameName = frame:GetName()
                if frameName then
                    local tab = _G[frameName .. 'Tab']
                    if tab then
                        tab:Hide()
                    end
                end
                if frame.buttonFrame then
                    frame.buttonFrame:Hide()
                end
            end
        end
    end
    if GENERAL_CHAT_DOCK then
        GENERAL_CHAT_DOCK:Hide()
    end
    local box = _G.ChatFrame1EditBox
    if box then
        box:Hide()
    end
    self:HideSocial()
end

function defaultChat:WatchDefault()
    local names = CHAT_FRAMES
    if type(names) == 'table' then
        for _, name in ipairs(names) do
            local frame = _G[name]
            if frame then
                if frame ~= _G.ChatFrame1 then
                    HookHide(frame)
                end
                local frameName = frame:GetName()
                if frameName then
                    HookHide(_G[frameName .. 'Tab'])
                end
                HookHide(frame.buttonFrame)
            end
        end
    end
    HookHide(GENERAL_CHAT_DOCK)
    for _, name in ipairs(SOCIAL_BUTTONS) do
        HookHide(_G[name])
    end
    local box = _G.ChatFrame1EditBox
    if box and box ~= composer.editBox and not box.exuiChatHideHook then
        box:HookScript('OnShow', function(self)
            if not defaultChat.silenced or self.exuiChatHiding then
                return
            end
            self.exuiChatHiding = true
            self:Hide()
            self.exuiChatHiding = false
            composer:HookChatOpen()
        end)
        box.exuiChatHideHook = true
    end
end

function defaultChat:IsSaved(frame)
    for _, entry in ipairs(self.saved or {}) do
        if entry.frame == frame then
            return true
        end
    end
    return false
end

function defaultChat:SilenceFrame(frame)
    if not frame or self:IsSaved(frame) then
        return
    end
    self.saved = self.saved or {}
    local frameName = frame:GetName()
    local tab = frameName and _G[frameName .. 'Tab']
    self.saved[#self.saved + 1] = {
        frame = frame,
        groups = CopyList(frame.messageTypeList),
        channels = CopyList(frame.channelList),
        frameShown = frame:IsShown() and true or false,
        tabShown = tab and tab:IsShown() and true or false,
        buttonShown = frame.buttonFrame and frame.buttonFrame:IsShown() and true or false,
    }
    if frame.RemoveAllMessageGroups then
        frame:RemoveAllMessageGroups()
    end
    if frame.RemoveAllChannels then
        frame:RemoveAllChannels()
    end
    pcall(frame.UnregisterEvent, frame, 'CHAT_MSG_CHANNEL')
    pcall(frame.UnregisterEvent, frame, 'CHAT_MSG_COMMUNITIES_CHANNEL')
    if frame ~= _G.ChatFrame1 then
        HookHide(frame)
    end
    if frameName then
        HookHide(tab)
    end
    HookHide(frame.buttonFrame)
end

function defaultChat:Silence()
    if self.silencing then
        return
    end
    self.silencing = true
    local ok, err = pcall(function()
        self.saved = self.saved or {}
        if not self.chrome then
            local box = _G.ChatFrame1EditBox
            self.chrome = {
                dockShown = GENERAL_CHAT_DOCK and GENERAL_CHAT_DOCK:IsShown() and true or false,
                editShown = box and box:IsShown() and true or false,
            }
        end
        local names = CHAT_FRAMES
        if type(names) == 'table' then
            for _, name in ipairs(names) do
                self:SilenceFrame(_G[name])
            end
        end
        self:WatchDefault()
        self.silenced = true
        self:HideDefault()
    end)
    self.silencing = false
    if not ok then
        error(err)
    end
end

function defaultChat:Restore()
    self.silenced = false
    local saved = self.saved
    local chrome = self.chrome
    self.saved = nil
    self.chrome = nil
    if type(saved) ~= 'table' then
        return
    end

    for _, entry in ipairs(saved) do
        local frame = entry.frame
        if frame then
            if frame.AddMessageGroup then
                for _, group in ipairs(entry.groups) do
                    if not frame:ContainsMessageGroup(group) then
                        frame:AddMessageGroup(group)
                    end
                end
            end
            if frame.AddChannel then
                for _, channel in ipairs(entry.channels) do
                    if not frame:ContainsChannel(channel) then
                        frame:AddChannel(channel)
                    end
                end
            end
            pcall(frame.RegisterEvent, frame, 'CHAT_MSG_CHANNEL')
            pcall(frame.RegisterEvent, frame, 'CHAT_MSG_COMMUNITIES_CHANNEL')
            frame:SetShown(entry.frameShown)
            local frameName = frame:GetName()
            if frameName then
                local tab = _G[frameName .. 'Tab']
                if tab then
                    tab:SetShown(entry.tabShown)
                end
            end
            if frame.buttonFrame then
                frame.buttonFrame:SetShown(entry.buttonShown)
            end
        end
    end

    if GENERAL_CHAT_DOCK then
        GENERAL_CHAT_DOCK:SetShown(not chrome or chrome.dockShown)
    end
    if FCFDock_UpdateTabs and GENERAL_CHAT_DOCK and GENERAL_CHAT_DOCK:IsShown() then
        FCFDock_UpdateTabs(GENERAL_CHAT_DOCK)
    end
    local box = _G.ChatFrame1EditBox
    if box then
        box:SetShown(not chrome or chrome.editShown)
    end
    self:ShowSocial()
end

----------------------------------------------------------------
-- Incoming messages
----------------------------------------------------------------

local function CollectEvents()
    local events = {
        'CHAT_MSG_CHANNEL',
        'CHAT_MSG_COMMUNITIES_CHANNEL',
        'GUILD_MOTD',
        'CHAT_MSG_ACHIEVEMENT',
        'CHAT_MSG_GUILD_ACHIEVEMENT',
        'CHAT_MSG_GUILD_ITEM_LOOTED',
        'CHAT_MSG_BN_INLINE_TOAST_ALERT',
    }
    local seen = {}
    for _, event in ipairs(events) do
        seen[event] = true
    end
    for _, group in ipairs(GROUPS) do
        local info = ChatTypeGroup and ChatTypeGroup[group]
        if info then
            for _, event in pairs(info) do
                if type(event) == 'string' and event:sub(1, 9) == 'CHAT_MSG_' and not seen[event] then
                    seen[event] = true
                    events[#events + 1] = event
                end
            end
        end
    end
    return events
end

function defaultChat:ShowGuildMotd(text)
    if not IsSecret(text) then
        if type(text) ~= 'string' or text == '' then
            return
        end
        if self.lastMotd == text then
            return
        end
        self.lastMotd = text
        if type(GUILD_MOTD_TEMPLATE) == 'string' then
            local ok, formatted = pcall(format, GUILD_MOTD_TEMPLATE, text)
            if ok and type(formatted) == 'string' and formatted ~= '' then
                text = formatted
            end
        end
    end
    if not IsSecret(text) and history:HasMessage(text) then
        return
    end
    history:PushLine('GUILD', text, nil, nil, nil, nil, true)
end

function defaultChat:ShowLoginGuildMotd()
    if not self.silenced or self.loginMotdChecked then
        return
    end
    if not C_GuildInfo or not C_GuildInfo.GetMOTD then
        return
    end
    local ok, motd = pcall(C_GuildInfo.GetMOTD)
    if not ok then
        return
    end
    if IsSecret(motd) then
        self.loginMotdChecked = true
        self:ShowGuildMotd(motd)
        return
    end
    if type(motd) ~= 'string' or motd == '' then
        return
    end
    self.loginMotdChecked = true
    self:ShowGuildMotd(motd)
end

function defaultChat:ShowTimePlayed(totalTime, levelTime)
    if IsSecret(totalTime) or IsSecret(levelTime) or type(totalTime) ~= 'number' or type(levelTime) ~= 'number' then
        return
    end
    if not ChatFrameUtil or not ChatFrameUtil.TimeBreakDown then
        return
    end
    if type(TIME_PLAYED_TOTAL) ~= 'string' or type(TIME_PLAYED_LEVEL) ~= 'string' or type(TIME_DAYHOURMINUTESECOND) ~= 'string' then
        return
    end
    local function PlayedLine(template, seconds)
        local d, h, m, s = ChatFrameUtil.TimeBreakDown(seconds)
        if IsSecret(d) or IsSecret(h) or IsSecret(m) or IsSecret(s) then
            return nil
        end
        local clockOk, clock = pcall(format, TIME_DAYHOURMINUTESECOND, d, h, m, s)
        if not clockOk or type(clock) ~= 'string' then
            return nil
        end
        local textOk, text = pcall(format, template, clock)
        if textOk and type(text) == 'string' and text ~= '' then
            return text
        end
    end
    local total = PlayedLine(TIME_PLAYED_TOTAL, totalTime)
    local level = PlayedLine(TIME_PLAYED_LEVEL, levelTime)
    if total and not history:HasMessage(total) then
        history:PushLine('SYSTEM', total).notice = true
    end
    if level and not history:HasMessage(level) then
        history:PushLine('SYSTEM', level).notice = true
    end
end

function defaultChat:OnChatEvent(event, message, sender, _, channelString, playerName2, _, _, channelIndex, channelBase,
                                 _, lineID, guid, bnSenderID, _, _, _, suppressRaidIcons)
    if event == 'GUILD_MOTD' then
        self.loginMotdChecked = true
        self:ShowGuildMotd(message)
        return
    end
    local chatType = event:sub(10)
    if chatType == 'WHISPER' or chatType == 'BN_WHISPER' then
        util.Chat():PlayWhisperSound()
    end
    if chatType == 'BN_INLINE_TOAST_ALERT' then
        local text = formatter.FormatBNToast(message, sender, bnSenderID)
        if text then
            history:PushLine(chatType, text)
        end
        return
    end
    if chatType == 'LOOT' or chatType == 'CURRENCY' or chatType == 'MONEY' then
        history:PushLine(chatType, message)
        return
    end
    if chatType == 'PING' then
        history:PushLine(chatType, formatter.FormatPing(message, sender), nil, nil, guid, lineID)
        return
    end
    if chatType == 'ACHIEVEMENT' or chatType == 'GUILD_ACHIEVEMENT' or chatType == 'GUILD_ITEM_LOOTED' then
        history:PushLine(chatType, formatter.FormatAnnounce(chatType, message, sender, guid), nil, nil, guid, lineID)
        return
    end
    local notice = formatter.FormatNotice(chatType, message, channelIndex, channelString, sender, playerName2)
    if notice then
        local channel
        if not IsSecret(channelBase) and type(channelBase) == 'string' and channelBase ~= '' then
            channel = channelBase
        elseif not IsSecret(channelString) and type(channelString) == 'string' and channelString ~= '' then
            channel = channelString
        end
        history:PushLine(chatType, notice, nil, channel, nil, lineID)
        return
    end
    local channel
    if util.TYPE_GROUP[chatType] == 'CHANNEL' then
        if not IsSecret(channelBase) and type(channelBase) == 'string' and channelBase ~= '' then
            channel = channelBase
        elseif not IsSecret(channelString) then
            channel = channelString
        else
            channel = channelBase
        end
    end
    message = formatter.ExpandExpressions(message, chatType, suppressRaidIcons)
    history:PushLine(chatType, message, sender, channel, guid, lineID, nil, nil, nil, bnSenderID)
end

function defaultChat:AcceptDirectMessage(message, r, g, b, chatTypeID, quiet)
    if not IsSecret(message) and history:HasMessage(message) then
        return
    end
    local line
    if formatter.IsMotdMessage(message) then
        line = history:PushLine('GUILD', message, nil, nil, nil, nil, true, false, quiet)
    else
        local kind = formatter.ChatTypeByID(chatTypeID)
        if kind == 'LOOT' or kind == 'CURRENCY' or kind == 'MONEY' or kind == 'SYSTEM' then
            line = history:PushLine(kind, message, nil, nil, nil, nil, false, false, quiet)
        elseif kind == nil then
            local colored = not IsSecret(r) and type(r) == 'number' and type(g) == 'number' and type(b) == 'number'
            line = history:PushLine('SYSTEM', message, nil, nil, nil, nil, false, not colored, quiet)
        end
    end
    if line then
        line.notice = true
    end
end

function defaultChat:ImportStartupMessages()
    if self.importingStartup then
        return
    end
    local frame = _G.ChatFrame1
    if not frame or not frame.GetNumMessages or not frame.GetMessageInfo then
        return
    end
    self.importingStartup = true
    local count = frame:GetNumMessages()
    if IsSecret(count) or type(count) ~= 'number' or count < 1 then
        self.importingStartup = false
        return
    end
    local first = count - 39
    if first < 1 then
        first = 1
    end
    self.addingPrint = true
    for i = first, count do
        local message, r, g, b, chatTypeID = frame:GetMessageInfo(i)
        self:AcceptDirectMessage(message, r, g, b, chatTypeID, true)
    end
    self.addingPrint = false
    self.importingStartup = false
    messages:Layout()
end

function defaultChat:HookPrint()
    local frame = _G.ChatFrame1
    if not frame or frame.exuiPrintHook or not hooksecurefunc then
        return
    end
    hooksecurefunc(frame, 'AddMessage', function(_, message, r, g, b, chatTypeID)
        if not defaultChat.silenced or defaultChat.addingPrint then
            return
        end
        defaultChat.addingPrint = true
        local ok, err = pcall(defaultChat.AcceptDirectMessage, defaultChat, message, r, g, b, chatTypeID)
        defaultChat.addingPrint = false
        if not ok then
            error(err)
        end
    end)
    frame.exuiPrintHook = true
end

function defaultChat:RegisterEvents()
    local events = CollectEvents()
    self.chatEvents = events
    local function OnEvent(event, ...)
        if defaultChat.silenced then
            defaultChat:OnChatEvent(event, ...)
        end
    end
    for _, event in ipairs(events) do
        pcall(EXUI.RegisterEventHandler, EXUI, event, 'exui-chat-window', OnEvent)
    end
    EXUI:RegisterEventHandler(HIDE_EVENTS, 'exui-chat-window-hide', function()
        if defaultChat.silenced then
            defaultChat:Silence()
            defaultChat:ImportStartupMessages()
            defaultChat:ShowLoginGuildMotd()
        end
    end)
    EXUI:RegisterEventHandler('TIME_PLAYED_MSG', 'exui-chat-window-played', function(_, totalTime, levelTime)
        if defaultChat.silenced then
            defaultChat:ShowTimePlayed(totalTime, levelTime)
        end
    end)
    EXUI:RegisterEventHandler('PLAYER_LOGOUT', 'exui-chat-window-logout', function()
        if defaultChat.silenced then
            defaultChat:Restore()
        end
    end)
end

function defaultChat:UnregisterEvents()
    if self.chatEvents then
        EXUI:UnregisterEventHandler(self.chatEvents, 'exui-chat-window')
        self.chatEvents = nil
    end
    EXUI:UnregisterEventHandler(HIDE_EVENTS, 'exui-chat-window-hide')
    EXUI:UnregisterEventHandler('TIME_PLAYED_MSG', 'exui-chat-window-played')
    EXUI:UnregisterEventHandler('PLAYER_LOGOUT', 'exui-chat-window-logout')
end
