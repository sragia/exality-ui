---@class ExalityUI
local EXUI = select(2, ...)

local LDB = LibStub:GetLibrary('LibDataBroker-1.1')
local QTip = LibStub:GetLibrary('LibQTip-1.0')

local ICONS = {
}

local PROJECT_NAMES = {
    [2] = 'Classic',
    [3] = 'Plunderstorm',
    [5] = 'BC',
    [11] = 'WotLK',
    [14] = 'Cata',
    [19] = 'MoP'
}

local GetText = function()
    local WoWFriends = C_FriendList.GetNumOnlineFriends() or 0
    local _, BNetFriendsOnline = BNGetNumFriends()

    local online = WoWFriends + (BNetFriendsOnline or 0)
    return 'Friends: ' .. online
end

local toClassFileName = function(class)
    if (class == 'Demon Hunter') then
        return 'DEMONHUNTER'
    elseif (class == 'Death Knight') then
        return 'DEATHKNIGHT'
    end

    return class
end

local tooltip = nil

local font = CreateFont('EXUI_GuildBroker_Tooltip')
font:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')

local anchorFrame = nil
local wowFriends = {}
local bnetFriends = {}
local friendsDirty = true
local updateScheduled = false
local isShift = false

local function FetchWoWFriends()
    wipe(wowFriends)
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if (info and info.connected) then
            wowFriends[#wowFriends + 1] = {
                name = info.name,
                level = info.level,
                class = info.className,
                zone = info.area
            }
        end
    end
end

local function EnsureGameIcon(clientProgram)
    if not clientProgram or ICONS[clientProgram] then
        return
    end
    C_Texture.GetTitleIconTexture(clientProgram, Enum.TitleIconVersion.Small, function(success, file)
        if success and file then
            ICONS[clientProgram] = file
        end
    end)
end

local function AddBNetFriend(entry)
    bnetFriends[#bnetFriends + 1] = entry
    EnsureGameIcon(entry.game)
end

local function HasCharacterName(gameAccountInfo)
    return gameAccountInfo and gameAccountInfo.characterName and gameAccountInfo.characterName ~= ''
end

local function FetchBNetFriends()
    wipe(bnetFriends)
    local numFriends = BNGetNumFriends()

    for i = 1, numFriends do
        local info = C_BattleNet.GetFriendAccountInfo(i)
        local accountInfo = info and info.gameAccountInfo
        if info and accountInfo and accountInfo.isOnline then
            local added = false
            local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(i) or 0

            for gameAcc = 1, numGameAccounts do
                local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, gameAcc)
                if gameAccountInfo
                    and gameAccountInfo.clientProgram
                    and gameAccountInfo.clientProgram ~= 'App'
                    and HasCharacterName(gameAccountInfo) then
                    AddBNetFriend({
                        bnetTag = info.battleTag,
                        bnetName = info.accountName,
                        inGame = true,
                        name = gameAccountInfo.characterName,
                        level = gameAccountInfo.characterLevel,
                        game = gameAccountInfo.clientProgram,
                        zone = gameAccountInfo.areaName,
                        class = gameAccountInfo.className,
                        wowProjectID = gameAccountInfo.wowProjectID,
                    })
                    added = true
                    break
                end
            end

            -- Primary account payload sometimes has the character when the
            -- multi-account walk only found App / incomplete rows.
            if not added
                and accountInfo.clientProgram
                and accountInfo.clientProgram ~= 'App'
                and HasCharacterName(accountInfo) then
                AddBNetFriend({
                    bnetTag = info.battleTag,
                    bnetName = info.accountName,
                    inGame = true,
                    name = accountInfo.characterName,
                    level = accountInfo.characterLevel,
                    game = accountInfo.clientProgram,
                    zone = accountInfo.areaName,
                    class = accountInfo.className,
                    wowProjectID = accountInfo.wowProjectID,
                })
                added = true
            end

            if not added then
                AddBNetFriend({
                    bnetTag = info.battleTag,
                    bnetName = info.accountName,
                    game = accountInfo.clientProgram,
                    inGame = false,
                })
            end
        end
    end
end

local function EnsureFriendLists()
    if not friendsDirty then
        return
    end
    FetchWoWFriends()
    FetchBNetFriends()
    friendsDirty = false
end

local function HideTooltip(refresh)
    if (tooltip) then
        QTip:Release(tooltip)
        tooltip = nil
        if (not refresh) then
            anchorFrame = nil
        end
    end
end

local function ShowTooltip(self)
    EnsureFriendLists()
    if (#bnetFriends == 0 and #wowFriends == 0) then
        return
    end

    tooltip = QTip:Acquire('EXUI: Friends Broker', 4, 'LEFT', 'LEFT', 'LEFT', 'RIGHT')
    Mixin(tooltip.NineSlice, BackdropTemplateMixin)
    tooltip.NineSlice:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    tooltip.NineSlice:SetBackdropColor(0, 0, 0, 0.7)
    tooltip.NineSlice:SetBackdropBorderColor(0, 0, 0, 1)

    tooltip:SetFont(font)
    tooltip:SetHeaderFont(font)

    tooltip:AddLine()
    tooltip:SetCell(1, 1, WrapTextInColorCode('Friend List', 'fff96109'), nil, nil, 4)
    tooltip:AddLine()
    tooltip:AddLine()
    tooltip:AddLine()

    for _, friend in ipairs(wowFriends) do
        local classColor = friend.class and C_ClassColor.GetClassColor(friend.class)
        local nameText = (classColor and friend.name) and classColor:WrapTextInColorCode(friend.name) or (friend.name or '')
        tooltip:AddLine(
            'WoW',
            friend.level or '',
            nameText,
            friend.zone or ''
        )
    end

    for _, friend in ipairs(bnetFriends) do
        local hasCharacter = friend.inGame and friend.name and friend.name ~= ''
        local friendName
        local levelText = ''

        if hasCharacter then
            friendName = friend.name
            if friend.level and friend.level > 0 then
                levelText = friend.level
            end
            if friend.game == 'WoW' and friend.class then
                local classColor = C_ClassColor.GetClassColor(toClassFileName(friend.class))
                if classColor then
                    friendName = classColor:WrapTextInColorCode(friendName)
                end
                friendName = string.format('%s |cFF0085FA(%s)|r', friendName, friend.bnetName or '')
            end
            if friend.wowProjectID and PROJECT_NAMES[friend.wowProjectID] then
                friendName = string.format('%s %s', friendName,
                    WrapTextInColorCode('(' .. PROJECT_NAMES[friend.wowProjectID] .. ')', 'FF00C8FF'))
            end
        else
            friendName = WrapTextInColorCode(tostring(friend.bnetName or friend.bnetTag or '?'), 'FF0085FA')
        end

        local icon = ICONS[friend.game] or '796351'

        tooltip:AddLine(
            string.format('|T%s:0:0|t', icon),
            levelText,
            friendName,
            hasCharacter and (friend.zone or '') or ''
        )
    end

    anchorFrame = self
    tooltip:SmartAnchorTo(self)
    tooltip:Show()
end

local data = {
    type = 'data source',
    text = GetText(),
    OnEnter = function(self)
        self.Text:SetVertexColor(249 / 255, 95 / 255, 9 / 255, 1)
        ShowTooltip(self)
    end,
    OnLeave = function(self)
        self.Text:SetVertexColor(1, 1, 1, 1)
        HideTooltip()
    end,
    OnClick = function(self, button)
        ToggleFriendsFrame(1)
    end,
}

local function RefreshText()
    data.text = GetText()
end

local function ScheduleFriendsUpdate()
    friendsDirty = true
    RefreshText()

    if not anchorFrame then
        return
    end

    if updateScheduled then
        return
    end
    updateScheduled = true
    C_Timer.After(0.25, function()
        updateScheduled = false
        if not anchorFrame then
            return
        end
        HideTooltip(true)
        ShowTooltip(anchorFrame)
    end)
end

local UpdateTooltipOnModifier = function(event, button, state)
    if (button == 'LSHIFT') then
        isShift = state == 1
        if (anchorFrame) then
            HideTooltip(true)
            ShowTooltip(anchorFrame)
        end
    end
end

EXUI:RegisterEventHandler(
    {
        'BN_FRIEND_ACCOUNT_ONLINE',
        'BN_FRIEND_ACCOUNT_OFFLINE',
        'BN_FRIEND_INFO_CHANGED',
        'FRIENDLIST_UPDATE',
        'PLAYER_ENTERING_WORLD'
    },
    'friends-broker',
    ScheduleFriendsUpdate
)
EXUI:RegisterEventHandler('MODIFIER_STATE_CHANGED', 'friends-broker', UpdateTooltipOnModifier)

LDB:NewDataObject('EXUI: Friends', data)
