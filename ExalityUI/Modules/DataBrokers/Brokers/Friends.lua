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

local function ShowTooltip(self)
    if (#bnetFriends == 0 and #wowFriends == 0) then
        return
    end

    tooltip = QTip:Acquire('EXUI: Friends Broker', 4, 'LEFT', 'LEFT', 'LEFT', 'RIGHT')
    -- Style
    Mixin(tooltip.NineSlice, BackdropTemplateMixin)
    tooltip.NineSlice:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    tooltip.NineSlice:SetBackdropColor(0, 0, 0, 0.7)
    tooltip.NineSlice:SetBackdropBorderColor(0, 0, 0, 1)

    tooltip:SetFont(font)
    tooltip:SetHeaderFont(font)

    -- Info
    tooltip:AddLine()
    tooltip:SetCell(1, 1, WrapTextInColorCode('Friend List', 'fff96109'), nil, nil, 4)
    tooltip:AddLine()
    tooltip:AddLine()
    tooltip:AddLine()

    -- Add WoW Friends
    for _, friend in ipairs(wowFriends) do
        tooltip:AddLine(
            'WoW',
            friend.level,
            C_ClassColor.GetClassColor(friend.class):WrapTextInColorCode(friend.name),
            friend.zone
        )
    end

    -- Add Bnet Friends
    for _, friend in ipairs(bnetFriends) do
        local friendName = friend.inGame and friend.name or
            WrapTextInColorCode(string.format('%s', friend.bnetName), 'FF0085FA')
        if (friend.game == 'WoW' and friend.class) then
            friendName = C_ClassColor.GetClassColor(toClassFileName(friend.class)):WrapTextInColorCode(friendName)
        end

        if (friend.wowProjectID and PROJECT_NAMES[friend.wowProjectID]) then
            friendName = string.format('%s %s', friendName,
                WrapTextInColorCode('(' .. PROJECT_NAMES[friend.wowProjectID] .. ')', 'FF00C8FF'))
        end

        local icon = ICONS[friend.game] or '796351'

        tooltip:AddLine(
            string.format('|T%s:0:0|t', icon),
            friend.level,
            friendName,
            friend.zone
        )
    end



    -- Anchor And Show
    anchorFrame = self
    tooltip:SmartAnchorTo(self)

    tooltip:Show()
end

local function FetchWoWFriends()
    wipe(wowFriends)
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if (info and info.connected) then
            table.insert(wowFriends, {
                name = info.name,
                level = info.level,
                class = info.className,
                zone = info.area
            })
        end
    end
end

local function FetchBNetFriends()
    wipe(bnetFriends)
    local numFriends = BNGetNumFriends()

    for i = 1, numFriends do
        local info = C_BattleNet.GetFriendAccountInfo(i)
        if (info and info.gameAccountInfo.isOnline) then
            local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(i)
            if (numGameAccounts and numGameAccounts > 1) then
                for gameAcc = 1, numGameAccounts do
                    local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, gameAcc)
                    if (gameAccountInfo and gameAccountInfo.clientProgram ~= 'App') then -- App is just battle net, if they are in game then just ignore
                        table.insert(bnetFriends, {
                            bnetTag = info.battleTag,
                            bnetName = info.accountName,
                            inGame = true,
                            name = gameAccountInfo.characterName,
                            level = gameAccountInfo.characterLevel,
                            game = gameAccountInfo.clientProgram,
                            zone = gameAccountInfo.areaName,
                            class = gameAccountInfo.className,
                            wowProjectID = gameAccountInfo.wowProjectID
                        })
                        if (not ICONS[gameAccountInfo.clientProgram]) then
                            C_Texture.GetTitleIconTexture(gameAccountInfo.clientProgram, Enum.TitleIconVersion.Small,
                                function(success, file)
                                    if (success and file) then
                                        ICONS[gameAccountInfo.clientProgram] = file
                                    end
                                end)
                        end
                    end
                end
            else
                -- Probably just online on battle net
                table.insert(bnetFriends, {
                    bnetTag = info.battleTag,
                    bnetName = info.accountName,
                    game = info.gameAccountInfo.clientProgram,
                    inGame = false,
                })

                if (not ICONS[info.gameAccountInfo.clientProgram]) then
                    C_Texture.GetTitleIconTexture(info.gameAccountInfo.clientProgram, Enum.TitleIconVersion.Small,
                        function(success, file)
                            if (success and file) then
                                ICONS[info.gameAccountInfo.clientProgram] = file
                            end
                        end)
                end
            end
        end
    end
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

local Update = function()
    FetchWoWFriends()
    FetchBNetFriends()
    data.text = GetText()
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
        'CHAT_MSG_SYSTEM',
        'PLAYER_ENTERING_WORLD'
    },
    'friends-broker',
    Update
)
EXUI:RegisterEventHandler('MODIFIER_STATE_CHANGED', 'friends-broker', UpdateTooltipOnModifier)

LDB:NewDataObject('EXUI: Friends', data)
