---@class ExalityUI
local EXUI = select(2, ...)

local EXFrames = EXUI.EXFrames

---@class EXUIChatUtil
local util = EXUI:GetModule('chat-util')

util.SPRITE = 'Interface\\AddOns\\ExalityUI\\Assets\\Images\\Chat\\chat-sprite.png'
util.SHEET = 500

util.PICK = {
    { key = 'SAY',           label = 'Say' },
    { key = 'EMOTE',         label = 'Emote' },
    { key = 'YELL',          label = 'Yell' },
    { key = 'WHISPER',       label = 'Whisper' },
    { key = 'PARTY',         label = 'Party' },
    { key = 'RAID',          label = 'Raid' },
    { key = 'INSTANCE_CHAT', label = 'Instance' },
    { key = 'GUILD',         label = 'Guild' },
    { key = 'OFFICER',       label = 'Officer' },
    { key = 'SYSTEM',        label = 'System' },
}

util.TYPE_GROUP = {
    SAY = 'SAY',
    MONSTER_SAY = 'SAY',
    EMOTE = 'EMOTE',
    TEXT_EMOTE = 'EMOTE',
    YELL = 'YELL',
    MONSTER_YELL = 'YELL',
    WHISPER = 'WHISPER',
    WHISPER_INFORM = 'WHISPER',
    AFK = 'WHISPER',
    DND = 'WHISPER',
    BN_WHISPER = 'WHISPER',
    BN_WHISPER_INFORM = 'WHISPER',
    PARTY = 'PARTY',
    PARTY_LEADER = 'PARTY',
    MONSTER_PARTY = 'PARTY',
    RAID = 'RAID',
    RAID_LEADER = 'RAID',
    RAID_WARNING = 'RAID',
    INSTANCE_CHAT = 'INSTANCE_CHAT',
    INSTANCE_CHAT_LEADER = 'INSTANCE_CHAT',
    GUILD = 'GUILD',
    GUILD_ACHIEVEMENT = 'GUILD',
    GUILD_ITEM_LOOTED = 'GUILD',
    OFFICER = 'OFFICER',
    CHANNEL = 'CHANNEL',
    CHANNEL_JOIN = 'CHANNEL',
    CHANNEL_LEAVE = 'CHANNEL',
    CHANNEL_NOTICE = 'CHANNEL',
    CHANNEL_NOTICE_USER = 'CHANNEL',
    CHANNEL_LIST = 'CHANNEL',
    COMMUNITIES_CHANNEL = 'CHANNEL',
    SYSTEM = 'SYSTEM',
}

util.LABEL = {
    SAY = 'Say',
    EMOTE = 'Emote',
    TEXT_EMOTE = 'Emote',
    YELL = 'Yell',
    WHISPER = 'Whisper',
    WHISPER_INFORM = 'To',
    AFK = 'AFK',
    DND = 'DND',
    PARTY = 'Party',
    PARTY_LEADER = 'Party',
    MONSTER_PARTY = 'Party',
    RAID = 'Raid',
    RAID_LEADER = 'Raid',
    RAID_WARNING = 'Warning',
    INSTANCE_CHAT = 'Instance',
    INSTANCE_CHAT_LEADER = 'Instance',
    GUILD = 'Guild',
    OFFICER = 'Officer',
    CHANNEL = 'Channel',
    CHANNEL_JOIN = 'Channel',
    CHANNEL_LEAVE = 'Channel',
    CHANNEL_NOTICE = 'Channel',
    CHANNEL_NOTICE_USER = 'Channel',
    CHANNEL_LIST = 'Channel',
    COMMUNITIES_CHANNEL = 'Community',
    SYSTEM = 'System',
    BN_WHISPER = 'Whisper',
    BN_WHISPER_INFORM = 'To',
}

util.Chat = function()
    return EXUI:GetModule('chat')
end

util.FontPath = function()
    return EXFrames.assets.font.default()
end

util.IsSecret = function(value)
    if issecretvalue and issecretvalue(value) then
        return true
    end
    if canaccessvalue and not canaccessvalue(value) then
        return true
    end
    return false
end

local IsSecret = util.IsSecret

util.PlainSize = function(value, fallback, ceiling)
    if IsSecret(value) or type(value) ~= 'number' or value ~= value or value < 1 then
        return fallback
    end
    if type(ceiling) == 'number' and value > ceiling then
        return ceiling
    end
    return value
end

util.HasText = function(value)
    if IsSecret(value) then
        return true
    end
    return type(value) == 'string' and value ~= ''
end

util.ShortName = function(sender)
    if not util.HasText(sender) then
        return nil
    end
    if Ambiguate then
        local ok, shortName = pcall(Ambiguate, sender, 'short')
        if ok and util.HasText(shortName) then
            return shortName
        end
    end
    return sender
end

util.LineWhen = function(line)
    local stamp = line and line.stamp
    if type(stamp) == 'number' then
        return stamp
    end
    local clock = line and line.clock
    if type(clock) == 'number' then
        return clock
    end
end

util.TypeTag = function(chatType)
    local group = util.TYPE_GROUP[chatType]
    if type(chatType) ~= 'string' or chatType == 'SYSTEM' or group == 'SYSTEM' then
        return nil
    end
    if chatType:sub(1, 8) == 'MONSTER_' or chatType:sub(1, 10) == 'RAID_BOSS_' then
        return nil
    end
    if group == 'CHANNEL' then
        return nil
    end
    return util.LABEL[chatType]
end

util.ApplySprite = function(texture, rect)
    texture:SetTexture(util.SPRITE)
    texture:SetTexCoord(rect[1] / util.SHEET, (rect[3] + 1) / util.SHEET, rect[2] / util.SHEET,
        (rect[4] + 1) / util.SHEET)
    texture:SetVertexColor(1, 1, 1, 1)
end

util.ApplySlicedSprite = function(texture, rect, left, top, right, bottom)
    util.ApplySprite(texture, rect)
    if texture.SetTextureSliceMargins then
        texture:SetTextureSliceMargins(left, top, right, bottom)
        if texture.SetTextureSliceMode and Enum and Enum.UITextureSliceMode then
            texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        end
    end
end

util.ChatColor = function(chatType)
    local info = ChatTypeInfo and chatType and ChatTypeInfo[chatType]
    if not info then
        return 1, 1, 1
    end
    return info.r or 1, info.g or 1, info.b or 1
end

util.StoredColor = function(key)
    local colors = util.Chat().Data:GetValue('messageColors')
    if type(colors) ~= 'table' then
        return nil
    end
    local color = colors[key]
    if type(color) ~= 'table' then
        return nil
    end
    return color
end

util.FallbackColor = function(key)
    if type(key) == 'string' and key:sub(1, 8) == 'channel:' then
        local name = key:sub(9)
        if GetChannelName then
            local id = GetChannelName(name)
            if type(id) == 'number' and id > 0 then
                return util.ChatColor('CHANNEL' .. id)
            end
        end
        return util.ChatColor('CHANNEL')
    end
    return util.ChatColor(key)
end

util.MessageColor = function(chatType, channel)
    if not IsSecret(channel) and type(channel) == 'string' and channel ~= '' then
        local saved = util.StoredColor('channel:' .. channel)
        if saved then
            return saved.r or 1, saved.g or 1, saved.b or 1
        end
    end
    local group = util.TYPE_GROUP[chatType] or chatType
    local saved = util.StoredColor(group)
    if saved then
        return saved.r or 1, saved.g or 1, saved.b or 1
    end
    return util.ChatColor(chatType)
end
