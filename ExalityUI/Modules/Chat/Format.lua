---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIChatUtil
local util = EXUI:GetModule('chat-util')

---@class EXUIChatFormat
local formatter = EXUI:GetModule('chat-format')

local IsSecret = util.IsSecret
local HasText = util.HasText

formatter.TAG_GAP = ' '
local TAG_GAP = formatter.TAG_GAP

formatter.IsStatusLine = function(chatType)
    return chatType == 'SYSTEM' or chatType == 'BN_INLINE_TOAST_ALERT' or chatType == 'BN_WHISPER_PLAYER_OFFLINE'
end

local function StripHyperlinks(text)
    if not C_StringUtil or not C_StringUtil.StripHyperlinks then
        return text
    end
    local ok, stripped = pcall(C_StringUtil.StripHyperlinks, text, true, true, false, true, true)
    if ok then
        return stripped
    end
    return text
end

local function RepairLinkText(text)
    if IsSecret(text) then
        return text
    end
    if type(text) ~= 'string' then
        return text
    end
    if text:find('||', 1, true) then
        text = text:gsub('||', '|')
    end
    if not text:find('|Hplayer', 1, true) and not text:find('|HBNplayer', 1, true) then
        return text
    end
    local plain = text
    plain = plain:gsub('|HBNplayer:.-|h(.-)|h', '%1')
    plain = plain:gsub('|Hplayer:.-|h(.-)|h', '%1')
    plain = plain:gsub('|HBNplayer:+%s*', '')
    plain = plain:gsub('|Hplayer:+%s*', '')
    plain = plain:gsub('^[:%s]+', '')
    if plain ~= '' then
        return plain
    end
    return text
end

formatter.StripStatusLinks = function(text)
    return RepairLinkText(StripHyperlinks(text))
end

formatter.StatusTextWithPlayerLinks = function(text)
    if IsSecret(text) or type(text) ~= 'string' then
        return formatter.StripStatusLinks(text), false
    end
    if text:find('||', 1, true) then
        text = text:gsub('||', '|')
    end
    local links = {}
    text = text:gsub('|H(B?N?player[%a]*:[^|]+)|h(.-)|h', function(link, label)
        links[#links + 1] = '|H' .. link .. '|h' .. label .. '|h'
        return '#EXUILINK' .. #links .. '#'
    end)
    text = formatter.StripStatusLinks(text)
    if #links == 0 or type(text) ~= 'string' then
        return text, false
    end
    text = text:gsub('#EXUILINK(%d+)#', function(index)
        return links[tonumber(index)]
    end)
    return text, true
end

local function ShowText(fontString, value)
    if IsSecret(value) then
        fontString:SetText(value)
        return
    end
    if value == nil then
        fontString:SetText('')
        return
    end
    fontString:SetText(value)
end

formatter.SetLineText = function(fontString, channel, name, body, messageRight, action, keepLinks)
    local hasName = HasText(name)
    local hasChannel = type(channel) == 'string' and channel ~= ''
    local pattern
    local first, second, third
    local count = 1
    if messageRight then
        if hasChannel and hasName then
            if action then
                pattern = '%s %s|r' .. TAG_GAP .. '%s'
            else
                pattern = '%s :%s|r' .. TAG_GAP .. '%s'
            end
            first, second, third = body, name, channel
            count = 3
        elseif hasName then
            if action then
                pattern = '%s %s'
            else
                pattern = '%s :%s'
            end
            first, second = body, name
            count = 2
        elseif hasChannel then
            pattern = '%s' .. TAG_GAP .. '%s'
            first, second = body, channel
            count = 2
        else
            pattern = '%s'
            first = body
        end
    elseif hasChannel and hasName then
        if action then
            pattern = '%s' .. TAG_GAP .. '%s|r %s'
        else
            pattern = '%s' .. TAG_GAP .. '%s|r: %s'
        end
        first, second, third = channel, name, body
        count = 3
    elseif hasName then
        if action then
            pattern = '%s|r %s'
        else
            pattern = '%s|r: %s'
        end
        first, second = name, body
        count = 2
    elseif hasChannel then
        pattern = '%s' .. TAG_GAP .. '%s'
        first, second = channel, body
        count = 2
    else
        pattern = '%s'
        first = body
    end
    if count == 1 and IsSecret(first) then
        ShowText(fontString, first)
        return
    end
    local ok, formatted
    if count == 3 then
        ok, formatted = pcall(string.format, pattern, first, second, third)
    elseif count == 2 then
        ok, formatted = pcall(string.format, pattern, first, second)
    else
        ok, formatted = pcall(string.format, pattern, first)
    end
    local repair = keepLinks and function(value) return value end or RepairLinkText
    if ok then
        ShowText(fontString, repair(formatted))
    else
        ShowText(fontString, repair(body))
    end
end

formatter.ClassColoredName = function(name, guid)
    if not util.Chat():UseClassColor() or not GetPlayerInfoByGUID or not C_ClassColor or not C_ClassColor.GetClassColor then
        return name
    end
    if not IsSecret(guid) and (type(guid) ~= 'string' or guid == '') then
        return name
    end
    local ok, _, englishClass = pcall(GetPlayerInfoByGUID, guid)
    if not ok or not (IsSecret(englishClass) or (type(englishClass) == 'string' and englishClass ~= '')) then
        return name
    end
    local colorOk, color = pcall(C_ClassColor.GetClassColor, englishClass)
    if not colorOk or not color or not color.WrapTextInColorCode then
        return name
    end
    local wrapOk, colored = pcall(color.WrapTextInColorCode, color, name)
    if wrapOk and (IsSecret(colored) or (type(colored) == 'string' and colored ~= '')) then
        return colored
    end
    return name
end

formatter.NameLink = function(line, plain)
    local colored = formatter.ClassColoredName(plain, line.guid)
    local lineID = line.lineID
    if IsSecret(lineID) or type(lineID) ~= 'number' then
        lineID = 0
    end
    local chatType = line.chatType
    if type(chatType) ~= 'string' or chatType == '' then
        chatType = 'SAY'
    end
    if IsSecret(plain) or IsSecret(line.sender) then
        if chatType == 'BN_WHISPER' or chatType == 'BN_WHISPER_INFORM' then
            return string.format('|HBNplayer:%s:%s:0:%s:0|h%s|h', plain, line.bnID or 0, chatType, colored)
        end
        return string.format('|Hplayer:%s|h%s|h', plain, colored)
    end
    local bnID = line.bnID
    if (chatType == 'BN_WHISPER' or chatType == 'BN_WHISPER_INFORM') and GetBNPlayerLink and (IsSecret(bnID) or type(bnID) == 'number') then
        local ok, link = pcall(GetBNPlayerLink, line.sender, colored, bnID, lineID, chatType, 0)
        if ok and HasText(link) then
            return link
        end
    end
    if GetPlayerLink and chatType ~= 'BN_WHISPER' and chatType ~= 'BN_WHISPER_INFORM' then
        local ok, link = pcall(GetPlayerLink, plain, colored, lineID, chatType, '')
        if ok and HasText(link) then
            return link
        end
    end
    return colored
end

local function AnnounceName(sender, guid)
    if IsSecret(sender) or type(sender) ~= 'string' or sender == '' then
        return nil
    end
    local name = sender
    if Ambiguate then
        local ok, shortName = pcall(Ambiguate, sender, 'short')
        if ok and type(shortName) == 'string' and shortName ~= '' then
            name = shortName
        end
    end
    name = formatter.ClassColoredName(name, guid)
    if GetPlayerLink then
        local ok, link = pcall(GetPlayerLink, sender, name)
        if ok and type(link) == 'string' and link ~= '' then
            return link
        end
    end
    return name
end

formatter.FormatAnnounce = function(chatType, message, sender, guid)
    if IsSecret(message) or type(message) ~= 'string' or message == '' then
        return message
    end
    local name = AnnounceName(sender, guid)
    if not name then
        return message
    end
    local ok, text
    if chatType == 'GUILD_ITEM_LOOTED' then
        ok, text = pcall(string.gsub, message, '$s', name, 1)
    else
        ok, text = pcall(string.gsub, message, '%%s', name, 1)
    end
    if ok and type(text) == 'string' and text ~= '' then
        return text
    end
    return message
end

formatter.FormatNotice = function(chatType, token, channelIndex, channelName, playerName, playerName2)
    if chatType ~= 'CHANNEL_NOTICE' and chatType ~= 'CHANNEL_NOTICE_USER' then
        return nil
    end
    if IsSecret(token) or type(token) ~= 'string' or token == '' then
        return nil
    end
    local globalstring
    if token == 'TRIAL_RESTRICTED' and CHAT_TRIAL_RESTRICTED_NOTICE_TRIAL then
        globalstring = CHAT_TRIAL_RESTRICTED_NOTICE_TRIAL
    else
        globalstring = _G['CHAT_' .. token .. '_NOTICE_BN'] or _G['CHAT_' .. token .. '_NOTICE']
    end
    if type(globalstring) ~= 'string' then
        return nil
    end
    local ok, text
    if chatType == 'CHANNEL_NOTICE' then
        local shown = channelName
        if type(channelName) == 'string' and ChatFrameUtil and ChatFrameUtil.ResolvePrefixedChannelName then
            local resolvedOk, resolved = pcall(ChatFrameUtil.ResolvePrefixedChannelName, channelName)
            if resolvedOk and type(resolved) == 'string' and resolved ~= '' then
                shown = resolved
            end
        end
        ok, text = pcall(format, globalstring, channelIndex, shown)
    elseif not IsSecret(playerName2) and type(playerName2) == 'string' and playerName2 ~= '' then
        ok, text = pcall(format, globalstring, channelIndex, channelName, playerName, playerName2)
    elseif token == 'INVITE' and not IsSecret(playerName) then
        ok, text = pcall(format, globalstring, channelName, playerName)
    else
        ok, text = pcall(format, globalstring, channelIndex, channelName, playerName)
    end
    if ok and type(text) == 'string' and text ~= '' then
        return text
    end
end

local function BNDisplayName(name, bnetID)
    local display = name
    if IsSecret(bnetID) or not C_BattleNet or not C_BattleNet.GetAccountInfoByID then
        return display
    end
    local ok, info = pcall(C_BattleNet.GetAccountInfoByID, bnetID)
    if not ok or type(info) ~= 'table' or type(info.gameAccountInfo) ~= 'table' then
        return display
    end
    local game = info.gameAccountInfo
    local character = game.characterName
    local client = game.clientProgram
    if IsSecret(character) or IsSecret(client) or type(character) ~= 'string' or character == '' or client == '' then
        return display
    end
    local tag = info.battleTag
    if IsSecret(tag) then
        tag = nil
    end
    local shown = character
    if BNet_GetValidatedCharacterName then
        local nameOk, validated = pcall(BNet_GetValidatedCharacterName, character, tag, client)
        if nameOk and type(validated) == 'string' and validated ~= '' then
            shown = validated
        end
    end
    return name .. ' (' .. shown .. ')'
end

formatter.FormatBNToast = function(token, name, bnetID)
    if IsSecret(token) or type(token) ~= 'string' or token == '' then
        return nil
    end
    local globalstring = _G['BN_INLINE_TOAST_' .. token]
    if type(globalstring) ~= 'string' then
        return nil
    end
    if token == 'FRIEND_REQUEST' then
        return globalstring
    end
    if token == 'FRIEND_PENDING' then
        if not BNGetNumFriendInvites then
            return nil
        end
        local pendingOk, pending = pcall(format, globalstring, BNGetNumFriendInvites())
        if pendingOk and type(pending) == 'string' and pending ~= '' then
            return pending
        end
        return nil
    end
    local display
    if IsSecret(name) then
        local shownOk, shown = pcall(string.format, '[%s]', name)
        if not shownOk then
            return nil
        end
        display = shown
    elseif type(name) ~= 'string' or name == '' then
        return nil
    else
        display = '[' .. name .. ']'
        if token == 'FRIEND_ONLINE' or token == 'FRIEND_OFFLINE' then
            display = '[' .. BNDisplayName(name, bnetID) .. ']'
        end
    end
    local ok, text = pcall(format, globalstring, display)
    if ok and (IsSecret(text) or (type(text) == 'string' and text ~= '')) then
        return text
    end
end

formatter.ExpandExpressions = function(message, chatType, suppressIcons)
    if not C_ChatInfo or not C_ChatInfo.ReplaceIconAndGroupExpressions then
        return message
    end
    if not IsSecret(message) and type(message) ~= 'string' then
        return message
    end
    local noGroups = true
    if ChatFrameUtil and ChatFrameUtil.GetChatCategory and ChatFrameUtil.CanChatGroupPerformExpressionExpansion then
        noGroups = not ChatFrameUtil.CanChatGroupPerformExpressionExpansion(ChatFrameUtil.GetChatCategory(chatType))
    end
    local ok, expanded = pcall(C_ChatInfo.ReplaceIconAndGroupExpressions, message, suppressIcons and true or false,
        noGroups)
    if ok then
        return expanded
    end
    return message
end

local chatTypeByID

formatter.ChatTypeByID = function(id)
    if IsSecret(id) or type(id) ~= 'number' or not ChatTypeInfo then
        return nil
    end
    if not chatTypeByID then
        chatTypeByID = {}
        for name, info in pairs(ChatTypeInfo) do
            if type(info) == 'table' and type(info.id) == 'number' then
                chatTypeByID[info.id] = name
            end
        end
    end
    return chatTypeByID[id]
end

formatter.IsMotdMessage = function(message)
    if IsSecret(message) or type(message) ~= 'string' or type(GUILD_MOTD_TEMPLATE) ~= 'string' then
        return false
    end
    local prefix = GUILD_MOTD_TEMPLATE:match('^(.-)%%s')
    if type(prefix) ~= 'string' or prefix == '' then
        return false
    end
    return message:sub(1, #prefix) == prefix
end
