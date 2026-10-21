---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIChatUtil
local util = EXUI:GetModule('chat-util')

---@class EXUIChatMessages
local messages = EXUI:GetModule('chat-messages')

---@class EXUIChatPanels
local panels = EXUI:GetModule('chat-panels')

---@class EXUIChatHistory
local history = EXUI:GetModule('chat-history')

local Chat = util.Chat
local IsSecret = util.IsSecret

local MAX_LINES = 1000
local TRIM_SLACK = 100
local TAB_LINES = 250
local HIDDEN_LINES = 100
local MAX_STORED = 100

local PERSIST = {
    SAY = true,
    EMOTE = true,
    TEXT_EMOTE = true,
    YELL = true,
    WHISPER = true,
    WHISPER_INFORM = true,
    BN_WHISPER = true,
    BN_WHISPER_INFORM = true,
    PARTY = true,
    PARTY_LEADER = true,
    RAID = true,
    RAID_LEADER = true,
    RAID_WARNING = true,
    INSTANCE_CHAT = true,
    INSTANCE_CHAT_LEADER = true,
    GUILD = true,
    OFFICER = true,
}

history.lines = {}

local function ChatLog()
    if type(ExalityUICharData) ~= 'table' then
        return nil
    end
    if type(ExalityUICharData.chatLog) ~= 'table' then
        ExalityUICharData.chatLog = {}
    end
    return ExalityUICharData.chatLog
end

local function DefaultGroups()
    local groups = {}
    for _, entry in ipairs(util.PICK) do
        groups[entry.key] = true
    end
    return groups
end

history.NewTab = function(id, name)
    return {
        id = id,
        name = name,
        groups = DefaultGroups(),
        channels = {},
        scroll = 0,
    }
end

function history:EnsureTabs()
    if self.tabs then
        return self.tabs
    end
    local tabs = Chat().Data:GetValue('tabs')
    if type(tabs) ~= 'table' or #tabs == 0 then
        tabs = { history.NewTab(1, 'General') }
        Chat().Data:SetValue('tabs', tabs)
        Chat().Data:SetValue('activeTab', 1)
    end
    self.tabs = tabs
    return tabs
end

function history:SaveTabs()
    Chat().Data:SetValue('tabs', self.tabs)
end

function history:ActiveTab()
    local tabs = self:EnsureTabs()
    local id = Chat().Data:GetValue('activeTab')
    for _, tab in ipairs(tabs) do
        if tab.id == id then
            return tab
        end
    end
    return tabs[1]
end

local function ChannelKey(name)
    if IsSecret(name) or type(name) ~= 'string' or name == '' then
        return nil
    end
    name = name:gsub('^%d+%.%s*', '')
    local base = name:match('^(.-)%s*%-%s*.+$')
    if type(base) == 'string' and base ~= '' then
        return base
    end
    return name
end

local function SameChannel(left, right)
    if IsSecret(left) or IsSecret(right) then
        return false
    end
    if type(left) ~= 'string' or type(right) ~= 'string' or left == '' or right == '' then
        return false
    end
    if left == right then
        return true
    end
    local a = ChannelKey(left)
    local b = ChannelKey(right)
    return a ~= nil and a == b
end

function history:ChannelListed(tab, channel)
    local selected = tab and tab.channels
    if type(selected) ~= 'table' or not next(selected) then
        return false
    end
    if IsSecret(channel) or type(channel) ~= 'string' or channel == '' then
        return false
    end
    for name in pairs(selected) do
        if SameChannel(channel, name) then
            return true
        end
    end
    return false
end

function history:LineMatches(tab, line)
    if line and line.marker then
        return true
    end
    if not tab or type(tab.groups) ~= 'table' then
        return true
    end
    if line.notice then
        return tab.groups.SYSTEM or tab.groups.GUILD or tab.groups.SAY or false
    end
    if line.chatType == 'BN_INLINE_TOAST_ALERT' then
        return tab.groups.WHISPER or tab.groups.SYSTEM or tab.groups.GUILD or tab.groups.SAY or false
    end
    if line.chatType == 'ACHIEVEMENT' then
        return tab.groups.SAY or tab.groups.PARTY or tab.groups.RAID or tab.groups.INSTANCE_CHAT or false
    end
    local group = util.TYPE_GROUP[line.chatType] or 'SYSTEM'
    if group == 'CHANNEL' then
        return self:ChannelListed(tab, line.channel)
    end
    if not tab.groups[group] then
        return false
    end
    return true
end

function history:MatchingLines()
    local tab = self:ActiveTab()
    local lines = {}
    for _, line in ipairs(self.lines) do
        if self:LineMatches(tab, line) then
            lines[#lines + 1] = line
        end
    end
    return lines
end

function history:MarkWhisperTabs(line)
    if line.chatType ~= 'WHISPER' and line.chatType ~= 'BN_WHISPER' then
        return
    end
    local active = self:ActiveTab()
    local marked = false
    for _, tab in ipairs(self:EnsureTabs()) do
        if tab.id ~= active.id and self:LineMatches(tab, line) then
            self.whisperTabs = self.whisperTabs or {}
            if not self.whisperTabs[tab.id] then
                self.whisperTabs[tab.id] = true
                marked = true
            end
        end
    end
    if marked then
        panels:RefreshTabs()
    end
end

function history:RememberLine(line)
    if not line or line.motd or not PERSIST[line.chatType] then
        return
    end
    if IsSecret(line.message) or type(line.message) ~= 'string' or line.message == '' then
        return
    end
    local sender = line.sender
    if IsSecret(sender) or type(sender) ~= 'string' or sender == '' then
        sender = nil
    end
    local guid = line.guid
    if IsSecret(guid) or type(guid) ~= 'string' or guid == '' then
        guid = nil
    end
    local store = ChatLog()
    if not store then
        return
    end
    store[#store + 1] = {
        chatType = line.chatType,
        message = line.message,
        sender = sender,
        guid = guid,
        stamp = line.stamp,
    }
    while #store > MAX_STORED do
        table.remove(store, 1)
    end
end

function history:TrimLines()
    local lines = self.lines
    if #lines <= MAX_LINES then
        return
    end
    local tabs = self:EnsureTabs()
    local counts = {}
    local hidden = 0
    local kept = 0
    local keep = {}
    for index = #lines, 1, -1 do
        local line = lines[index]
        local matched, wanted = false, false
        for tabIndex, tab in ipairs(tabs) do
            if self:LineMatches(tab, line) then
                matched = true
                local count = counts[tabIndex] or 0
                if count < TAB_LINES then
                    wanted = true
                end
                counts[tabIndex] = count + 1
            end
        end
        if not matched then
            hidden = hidden + 1
            wanted = hidden <= HIDDEN_LINES
        end
        if wanted and kept < MAX_LINES - TRIM_SLACK then
            keep[index] = true
            kept = kept + 1
        end
    end
    local write = 0
    for read = 1, #lines do
        local line = lines[read]
        if keep[read] then
            write = write + 1
            lines[write] = line
        else
            messages:ReleaseLine(line)
        end
    end
    for index = #lines, write + 1, -1 do
        lines[index] = nil
    end
end

function history:LoadLog()
    if self.logLoaded then
        return
    end
    self.logLoaded = true
    local store = ChatLog()
    if not store then
        return
    end
    local now = time()
    local session = GetTime()
    for _, entry in ipairs(store) do
        if type(entry) == 'table' and PERSIST[entry.chatType] and type(entry.message) == 'string' and entry.message ~= '' then
            local stamp = entry.stamp
            if type(stamp) ~= 'number' then
                stamp = now
            end
            local age = now - stamp
            if age < 0 then
                age = 0
            end
            self.lines[#self.lines + 1] = {
                clock = session - age,
                stamp = stamp,
                chatType = entry.chatType,
                message = entry.message,
                sender = type(entry.sender) == 'string' and entry.sender or nil,
                guid = type(entry.guid) == 'string' and entry.guid or nil,
            }
        end
    end
    self:TrimLines()
    if #self.lines > 0 then
        self.lines[#self.lines + 1] = {
            clock = session,
            stamp = now,
            chatType = 'SYSTEM',
            message = '- new messages -',
            marker = true,
        }
        messages.fadeReset = session
    end
end

function history:PushLine(chatType, message, sender, channel, guid, lineID, motd, plain, quiet, bnID)
    if IsSecret(lineID) or type(lineID) ~= 'number' then
        lineID = nil
    end
    local line = {
        clock = GetTime(),
        stamp = time(),
        chatType = chatType,
        message = message,
        sender = sender,
        channel = channel,
        guid = guid,
        lineID = lineID,
        motd = motd and true or false,
        plain = plain and true or false,
    }
    if IsSecret(bnID) or type(bnID) == 'number' then
        line.bnID = bnID
    end
    self.lines[#self.lines + 1] = line
    self:RememberLine(line)
    self:TrimLines()
    self:MarkWhisperTabs(line)
    local active = self:ActiveTab()
    if active and (active.scroll or 0) > 0 and self:LineMatches(active, line) then
        active.scroll = active.scroll + 1
    end
    if not quiet then
        messages:Layout()
    end
    return line
end

function history:HasMessage(text)
    if IsSecret(text) or type(text) ~= 'string' then
        return false
    end
    local lines = self.lines
    local i = #lines
    local stop = i - 40
    if stop < 1 then
        stop = 1
    end
    while i >= stop do
        local existing = lines[i] and lines[i].message
        if not IsSecret(existing) and existing == text then
            return true
        end
        i = i - 1
    end
    return false
end
