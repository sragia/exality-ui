---@class ExalityUI
local EXUI = select(2, ...)

local LDB = LibStub:GetLibrary('LibDataBroker-1.1')
local QTip = LibStub:GetLibrary('LibQTip-1.0')

local GetText = function()
    local isInGuild = IsInGuild()
    if (not isInGuild) then
        return 'Not in guild'
    end
    local _, online = GetNumGuildMembers()
    return 'Guild: ' .. online
end

local tooltip = nil

local font = CreateFont('EXUI_GuildBroker_Tooltip')
font:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')

local isShift = false
local anchorFrame = nil

local function ShowTooltip(self)
    local guildName, guildRank = GetGuildInfo('player')
    if (not guildName) then
        return
    end

    tooltip = QTip:Acquire('EXUI: Guild Broker', 3, 'LEFT', 'LEFT', 'RIGHT')
    -- Style
    Mixin(tooltip.NineSlice, BackdropTemplateMixin)
    tooltip.NineSlice:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    tooltip.NineSlice:SetBackdropColor(0, 0, 0, 0.7)
    tooltip.NineSlice:SetBackdropBorderColor(0, 0, 0, 1)

    tooltip:SetFont(font)
    tooltip:SetHeaderFont(font)

    -- Info
    tooltip:AddLine()
    tooltip:SetCell(1, 1, WrapTextInColorCode(guildName, 'FFFFFFFF'), nil, nil, 3)
    tooltip:AddLine()
    tooltip:SetCell(2, 1, WrapTextInColorCode(guildRank, 'fff96109'), nil, nil, 3)
    tooltip:AddLine()
    tooltip:AddLine()

    -- C_ColorUtil.GenerateTextColorCode(GetQuestDifficultyColor(80))

    local myZone = GetSubZoneText()
    for i = 1, GetNumGuildMembers() do
        local name, rankName, _, level, _, zone, publicNote, _, isOnline, _, class = GetGuildRosterInfo(i)

        if (isOnline) then
            local classColor = C_ClassColor.GetClassColor(class)
            tooltip:AddLine(
                WrapTextInColorCode(level, C_ColorUtil.GenerateTextColorCode(GetQuestDifficultyColor(level))),
                classColor:WrapTextInColorCode(name),
                WrapTextInColorCode(zone, zone == myZone and 'FF00FD00' or 'ffffffff')
            )
            if (isShift) then
                tooltip:AddLine(
                    WrapTextInColorCode('Rank:', 'fff96109'),
                    rankName
                )
                tooltip:AddLine(
                    WrapTextInColorCode('Note:', 'FF808080'),
                    publicNote
                )
            end
        end
    end
    -- Anchor And Show
    anchorFrame = self
    tooltip:SmartAnchorTo(self)

    tooltip:Show()
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
        ToggleGuildFrame()
    end,
}

local UpdateText = function()
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
    { 'GUILD_ROSTER_UPDATE', 'PLAYER_LOGIN', 'PLAYER_ENTERING_WORLD', 'PLAYER_GUILD_UPDATE' },
    'guild-broker',
    UpdateText
)
EXUI:RegisterEventHandler('MODIFIER_STATE_CHANGED', 'guild-broker', UpdateTooltipOnModifier)

LDB:NewDataObject('EXUI: Guild', data)
