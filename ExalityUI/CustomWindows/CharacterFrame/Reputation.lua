---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

---@class EXUICharacterFrameReputation
local reputation = EXUI:GetModule('character-frame-reputation')

---@class EXUICharacterFrameCurrencies
local currencies = EXUI:GetModule('character-frame-currencies')

reputation.panel = nil
reputation.toggle = nil
reputation.optionsPopup = nil
reputation.scrollFrame = nil
reputation.scrollChild = nil
reputation.headerRows = {}
reputation.factionRows = {}
reputation.isOpen = false
reputation.useAnimation = true
reputation.selectedIndex = nil
reputation.selectedName = nil
reputation.selectedFactionID = nil

local PANEL_WIDTH = 360
local PANEL_GAP = 6
local OPTIONS_WIDTH = 210
local VIEW_RENOWN_HEIGHT = 26
local OPTIONS_GAP = 4
local BUTTON_WIDTH = 38
local BUTTON_HEIGHT = 30
local BUTTON_OUTSET_X = -10
local BUTTON_ICON_OFFSET_X = 5
local BUTTON_OFFSET_Y = -94
local TITLE_HEIGHT = 28
local ROW_HEIGHT = 28
local HEADER_HEIGHT = 22
local ROW_GAP = 2
local CONTENT_PAD = 10
local BAR_WIDTH = 120
local BAR_HEIGHT = 16
local ANIM_DURATION = 0.18
local HEADER_GOLD = { 235 / 255, 183 / 255, 52 / 255, 1 } -- #ebb734
local TOGGLE_ICON = { 0 / 255, 170 / 255, 100 / 255, 1 }  -- #00AA64
local TOGGLE_ICON_HOVER = { 40 / 255, 210 / 255, 130 / 255, 1 }
local MAX_REACTION = MAX_REPUTATION_REACTION or 8

local function NormalizeBarValues(minValue, maxValue, currentValue)
    maxValue = maxValue - minValue
    currentValue = currentValue - minValue
    minValue = 0
    return minValue, maxValue, currentValue
end

local function GetBarColor(colorIndex)
    local colors = FACTION_BAR_COLORS
    local c = colors and colors[colorIndex]
    if c then
        return c.r or c[1], c.g or c[2], c.b or c[3]
    end
    return 0.3, 0.7, 0.3
end

local function GetItemQualityRGB(quality)
    local colors = ITEM_QUALITY_COLORS
    local c = colors and colors[quality]
    if c then
        return c.r, c.g, c.b
    end

    -- Fallbacks if quality colors are not loaded yet
    if quality == (Enum and Enum.ItemQuality and Enum.ItemQuality.Legendary) or quality == 5 then
        return 1.0, 0.5, 0.0
    elseif quality == (Enum and Enum.ItemQuality and Enum.ItemQuality.Epic) or quality == 4 then
        return 0.64, 0.21, 0.93
    elseif quality == (Enum and Enum.ItemQuality and Enum.ItemQuality.Rare) or quality == 3 then
        return 0.0, 0.44, 0.87
    elseif quality == (Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon) or quality == 2 then
        return 0.10, 0.90, 0.20
    end
    return 0.35, 0.75, 0.35 -- Common (soft green, not white)
end

-- Progress 0-1 → soft green → strong green → Rare → Epic → Legendary
-- Revered / ~80% renown → Epic; Exalted / max renown → Legendary
local function GetProgressQualityColor(progress)
    progress = math.max(0, math.min(1, progress or 0))
    local quality = Enum and Enum.ItemQuality
    if progress >= 1 then
        return GetItemQualityRGB(quality and quality.Legendary or 5)
    elseif progress >= 0.8 then
        return GetItemQualityRGB(quality and quality.Epic or 4)
    elseif progress >= 0.6 then
        return GetItemQualityRGB(quality and quality.Rare or 3)
    elseif progress >= 0.4 then
        -- Stronger green than default uncommon
        return 0.10, 0.90, 0.20
    end
    -- Soft green instead of common white
    return 0.35, 0.75, 0.35
end

-- Friendly / Honored / Revered / Exalted mapped so Revered≈epic and Exalted=legendary
-- Within each standing the bar fill lerps toward the next tier (so Friendly can reach Uncommon mid-bar)
local STANDING_PROGRESS = {
    [5] = 0.20, -- Friendly → Common
    [6] = 0.60, -- Honored → Rare
    [7] = 0.80, -- Revered → Epic
    [8] = 1.00, -- Exalted → Legendary
}

local function GetStandardStandingProgress(reaction, barFill)
    if not reaction or reaction < 5 then
        return nil
    end
    if reaction >= MAX_REACTION then
        return 1
    end
    local from = STANDING_PROGRESS[reaction] or 0.2
    local to = STANDING_PROGRESS[reaction + 1] or 1
    barFill = math.max(0, math.min(1, barFill or 0))
    return from + (to - from) * barFill
end

local function GetMaxRenownLevel(factionID)
    local levels = C_MajorFactions.GetRenownLevels(factionID)
    if levels and #levels > 0 then
        return levels[#levels].level
    end
    return nil
end

local function GetRenownProgress(factionID, major, isMaxRenown)
    if isMaxRenown then
        return 1
    end
    local maxLevel = GetMaxRenownLevel(factionID)
    if not maxLevel or maxLevel <= 0 then
        return 0
    end
    local level = (major and major.renownLevel) or C_MajorFactions.GetCurrentRenownLevel(factionID) or 0
    local threshold = major and major.renownLevelThreshold or 1
    local earned = major and major.renownReputationEarned or 0
    if threshold <= 0 then
        threshold = 1
    end
    local fill = math.max(0, math.min(1, earned / threshold))
    return math.max(0, math.min(1, ((level - 1) + fill) / maxLevel))
end

local function GetFriendshipProgress(factionID, barFill, isMaxRank)
    if isMaxRank then
        return 1
    end
    local ranks = C_GossipInfo.GetFriendshipReputationRanks(factionID)
    if not ranks or not ranks.maxLevel or ranks.maxLevel <= 0 then
        return barFill or 0
    end
    local level = ranks.currentLevel or 0
    local fill = math.max(0, math.min(1, barFill or 0))
    return math.max(0, math.min(1, ((level - 1) + fill) / ranks.maxLevel))
end

local function FormatBarProgressText(currentValue, maxValue, isCapped)
    if isCapped or not maxValue or maxValue <= 0 then
        return nil
    end
    local text = (REPUTATION_PROGRESS_FORMAT or '%s / %s'):format(
        BreakUpLargeNumbers(currentValue),
        BreakUpLargeNumbers(maxValue)
    )
    if HIGHLIGHT_FONT_COLOR and HIGHLIGHT_FONT_COLOR.WrapTextInColorCode then
        return HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(text)
    end
    return text
end

local function GetReputationBarState(data)
    if not data or not data.factionID then
        local r, g, b = GetBarColor(4)
        return 0, 1, 0, r, g, b, '', nil
    end

    local friendship = C_GossipInfo.GetFriendshipReputation(data.factionID)
    if friendship and friendship.friendshipFactionID and friendship.friendshipFactionID > 0 then
        local isMaxRank = friendship.nextThreshold == nil
        local minValue, maxValue, currentValue
        if isMaxRank then
            minValue, maxValue, currentValue = 0, 1, 1
        else
            minValue, maxValue, currentValue = friendship.reactionThreshold, friendship.nextThreshold, friendship.standing
        end
        minValue, maxValue, currentValue = NormalizeBarValues(minValue, maxValue, currentValue)
        local barFill = (maxValue > 0) and (currentValue / maxValue) or 0
        local r, g, b = GetProgressQualityColor(GetFriendshipProgress(data.factionID, barFill, isMaxRank))
        return minValue, maxValue, currentValue, r, g, b, friendship.reaction or '', FormatBarProgressText(currentValue, maxValue, isMaxRank)
    end

    if C_Reputation.IsMajorFaction(data.factionID) then
        local major = C_MajorFactions.GetMajorFactionData(data.factionID)
        local isMaxRenown = C_MajorFactions.HasMaximumRenown(data.factionID)
        local minValue, maxValue, currentValue
        if isMaxRenown then
            minValue, maxValue, currentValue = 0, 1, 1
        elseif major then
            minValue, maxValue, currentValue = 0, major.renownLevelThreshold or 1, major.renownReputationEarned or 0
        else
            minValue, maxValue, currentValue = 0, 1, 0
        end
        minValue, maxValue, currentValue = NormalizeBarValues(minValue, maxValue, currentValue)
        local standing = (RENOWN_LEVEL_LABEL or 'Renown %d'):format(major and major.renownLevel or 0)
        local r, g, b = GetProgressQualityColor(GetRenownProgress(data.factionID, major, isMaxRenown))
        return minValue, maxValue, currentValue, r, g, b, standing, FormatBarProgressText(currentValue, maxValue, isMaxRenown)
    end

    local reaction = data.reaction or 0
    local isCapped = reaction >= MAX_REACTION
    local minValue, maxValue, currentValue
    if isCapped then
        minValue, maxValue, currentValue = 0, 1, 1
    else
        minValue, maxValue, currentValue = data.currentReactionThreshold or 0, data.nextReactionThreshold or 1, data.currentStanding or 0
    end
    minValue, maxValue, currentValue = NormalizeBarValues(minValue, maxValue, currentValue)
    local standing
    if GetText then
        standing = GetText('FACTION_STANDING_LABEL' .. reaction, UnitSex('player')) or ''
    else
        standing = _G['FACTION_STANDING_LABEL' .. reaction] or ''
    end

    local r, g, b
    if C_Reputation.IsFactionParagonForCurrentPlayer and C_Reputation.IsFactionParagonForCurrentPlayer(data.factionID) then
        r, g, b = GetProgressQualityColor(1)
    else
        local barFill = (maxValue > 0) and (currentValue / maxValue) or 0
        local progress = GetStandardStandingProgress(reaction, barFill)
        if progress then
            r, g, b = GetProgressQualityColor(progress)
        else
            r, g, b = GetBarColor(reaction)
        end
    end
    return minValue, maxValue, currentValue, r, g, b, standing, FormatBarProgressText(currentValue, maxValue, isCapped)
end

local function HideFactionTooltip(owner)
    if GameTooltip:GetOwner() == owner then
        GameTooltip:Hide()
    end
    if EmbeddedItemTooltip and EmbeddedItemTooltip:GetOwner() == owner then
        if EmbeddedItemTooltip_Hide then
            EmbeddedItemTooltip_Hide(EmbeddedItemTooltip)
        else
            EmbeddedItemTooltip:Hide()
        end
    end
end

local function ShowFactionTooltip(owner)
    local factionID = owner.factionID
    if not factionID then
        return
    end

    local clickInstruction = REPUTATION_BUTTON_TOOLTIP_CLICK_INSTRUCTION or '<Click to view options>'

    if C_Reputation.IsFactionParagonForCurrentPlayer and C_Reputation.IsFactionParagonForCurrentPlayer(factionID) then
        local tip = EmbeddedItemTooltip or GameTooltip
        tip:SetOwner(owner, 'ANCHOR_RIGHT', 2, 2)
        if ReputationUtil and ReputationUtil.AddParagonRewardsToTooltip then
            ReputationUtil.AddParagonRewardsToTooltip(tip, factionID)
        end
        if GameTooltip_AddBlankLineToTooltip then
            GameTooltip_AddBlankLineToTooltip(tip)
        end
        if GameTooltip_AddInstructionLine then
            GameTooltip_AddInstructionLine(tip, clickInstruction)
        elseif GameTooltip_SetBottomText then
            GameTooltip_SetBottomText(tip, clickInstruction, GREEN_FONT_COLOR)
        else
            tip:AddLine(clickInstruction, 0.1, 1, 0.1, true)
        end
        tip:Show()
        return
    end

    local friendship = C_GossipInfo.GetFriendshipReputation(factionID)
    if friendship and friendship.friendshipFactionID and friendship.friendshipFactionID > 0 then
        GameTooltip:SetOwner(owner, 'ANCHOR_RIGHT', 2, 2)
        local rankInfo = C_GossipInfo.GetFriendshipReputationRanks(friendship.friendshipFactionID)
        if rankInfo and rankInfo.maxLevel and rankInfo.maxLevel > 0 then
            local title = friendship.name .. ' (' .. rankInfo.currentLevel .. ' / ' .. rankInfo.maxLevel .. ')'
            if GameTooltip_SetTitle then
                GameTooltip_SetTitle(GameTooltip, title, HIGHLIGHT_FONT_COLOR)
            else
                GameTooltip:SetText(title, 1, 1, 1)
            end
        elseif GameTooltip_SetTitle then
            GameTooltip_SetTitle(GameTooltip, friendship.name, HIGHLIGHT_FONT_COLOR)
        else
            GameTooltip:SetText(friendship.name or '', 1, 1, 1)
        end

        if ReputationUtil and ReputationUtil.TryAppendAccountReputationLineToTooltip then
            ReputationUtil.TryAppendAccountReputationLineToTooltip(GameTooltip, factionID)
        end

        if GameTooltip_AddBlankLineToTooltip then
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
        end
        GameTooltip:AddLine(friendship.text, nil, nil, nil, true)
        if friendship.nextThreshold then
            local current = friendship.standing - friendship.reactionThreshold
            local max = friendship.nextThreshold - friendship.reactionThreshold
            if GameTooltip_AddHighlightLine then
                GameTooltip_AddHighlightLine(GameTooltip, friendship.reaction .. ' (' .. current .. ' / ' .. max .. ')', true)
            else
                GameTooltip:AddLine(friendship.reaction .. ' (' .. current .. ' / ' .. max .. ')', 1, 1, 1, true)
            end
        elseif GameTooltip_AddHighlightLine then
            GameTooltip_AddHighlightLine(GameTooltip, friendship.reaction, true)
        else
            GameTooltip:AddLine(friendship.reaction, 1, 1, 1, true)
        end

        if GameTooltip_AddBlankLineToTooltip then
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
        end
        if GameTooltip_AddInstructionLine then
            GameTooltip_AddInstructionLine(GameTooltip, clickInstruction)
        else
            GameTooltip:AddLine(clickInstruction, 0.1, 1, 0.1, true)
        end
        GameTooltip:Show()
        return
    end

    if C_Reputation.IsMajorFaction(factionID) then
        GameTooltip:SetOwner(owner, 'ANCHOR_RIGHT', 2, 2)
        if RenownRewardUtil and RenownRewardUtil.AddMajorFactionToTooltip then
            RenownRewardUtil.AddMajorFactionToTooltip(GameTooltip, factionID, function()
                if GameTooltip:GetOwner() == owner then
                    ShowFactionTooltip(owner)
                end
            end)
        else
            local major = C_MajorFactions.GetMajorFactionData(factionID)
            if GameTooltip_SetTitle then
                GameTooltip_SetTitle(GameTooltip, major and major.name or owner.factionName or '', HIGHLIGHT_FONT_COLOR)
            else
                GameTooltip:SetText(major and major.name or owner.factionName or '', 1, 1, 1)
            end
            if ReputationUtil and ReputationUtil.TryAppendAccountReputationLineToTooltip then
                ReputationUtil.TryAppendAccountReputationLineToTooltip(GameTooltip, factionID)
            end
            if major and GameTooltip_AddHighlightLine then
                GameTooltip_AddHighlightLine(GameTooltip, (RENOWN_LEVEL_LABEL or 'Renown %d'):format(major.renownLevel))
            end
        end
        if GameTooltip_AddBlankLineToTooltip then
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
        end
        if GameTooltip_AddInstructionLine then
            GameTooltip_AddInstructionLine(GameTooltip, clickInstruction)
        else
            GameTooltip:AddLine(clickInstruction, 0.1, 1, 0.1, true)
        end
        GameTooltip:Show()
        return
    end

    GameTooltip:SetOwner(owner, 'ANCHOR_RIGHT', 2, 2)
    if GameTooltip_SetTitle then
        GameTooltip_SetTitle(GameTooltip, owner.factionName or '')
    else
        GameTooltip:SetText(owner.factionName or '', 1, 1, 1)
    end
    if ReputationUtil and ReputationUtil.TryAppendAccountReputationLineToTooltip then
        ReputationUtil.TryAppendAccountReputationLineToTooltip(GameTooltip, factionID)
    end
    if owner.description and owner.description ~= '' then
        if GameTooltip_AddBlankLineToTooltip then
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
        end
        if GameTooltip_AddNormalLine then
            GameTooltip_AddNormalLine(GameTooltip, owner.description, true)
        else
            GameTooltip:AddLine(owner.description, 1, 0.82, 0, true)
        end
    end
    if GameTooltip_AddBlankLineToTooltip then
        GameTooltip_AddBlankLineToTooltip(GameTooltip)
    end
    if GameTooltip_AddInstructionLine then
        GameTooltip_AddInstructionLine(GameTooltip, clickInstruction)
    else
        GameTooltip:AddLine(clickInstruction, 0.1, 1, 0.1, true)
    end
    GameTooltip:Show()
end

local function OpenMajorFactionRenown(factionID)
    if not factionID then
        return
    end
    if not EncounterJournal then
        EncounterJournal_LoadUI()
    end
    if not EncounterJournal then
        return
    end
    if not EncounterJournal:IsShown() then
        ShowUIPanel(EncounterJournal)
    end
    if EJ_ContentTab_Select and EncounterJournal.JourneysTab then
        EJ_ContentTab_Select(EncounterJournal.JourneysTab:GetID())
    end
    if EncounterJournalJourneysFrame and EncounterJournalJourneysFrame.ResetView then
        EncounterJournalJourneysFrame:ResetView(nil, factionID)
    end
end

local function ApplyRowVisual(button, selected, hovered)
    local theme = EXUI.const.theme
    if selected then
        button.border:SetBorderColor(unpack(theme.accent))
        button.border:SetBorderThickness(2)
        button.bg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 0.9)
    elseif hovered then
        button.border:SetBorderColor(0.55, 0.55, 0.55, 1)
        button.border:SetBorderThickness(1)
        button.bg:SetVertexColor(0.2, 0.2, 0.2, 0.7)
    else
        button.border:SetBorderColor(unpack(theme.border))
        button.border:SetBorderThickness(1)
        button.bg:SetVertexColor(0, 0, 0, 0.55)
    end
end

local function ApplyHeaderVisual(button, hovered)
    local theme = EXUI.const.theme
    if hovered then
        button.bg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 0.85)
    else
        button.bg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 0.55)
    end
end

local function ApplyToggleVisual(button, hovered)
    local theme = EXUI.const.theme
    if hovered then
        button.bg:SetVertexColor(unpack(theme.backgroundLight))
        button.icon:SetVertexColor(unpack(TOGGLE_ICON_HOVER))
    else
        button.bg:SetVertexColor(unpack(theme.backgroundDeep))
        button.icon:SetVertexColor(unpack(TOGGLE_ICON))
    end
end

local function SetHeaderTextColor(button, isChild)
    if not isChild then
        button.Text:SetTextColor(unpack(HEADER_GOLD))
        button.Collapse:SetVertexColor(HEADER_GOLD[1], HEADER_GOLD[2], HEADER_GOLD[3], 0.95)
    else
        button.Text:SetTextColor(unpack(EXUI.const.theme.textMuted))
        button.Collapse:SetVertexColor(1, 1, 1, 0.85)
    end
end

local function ApplyBarState(row, data)
    local minValue, maxValue, currentValue, r, g, b, standing, progressText = GetReputationBarState(data)
    row.Bar:SetMinMaxValues(minValue, maxValue)
    row.Bar:SetValue(currentValue)
    row.Bar:SetStatusBarColor(r, g, b, 1)
    row.standingText = standing or ''
    row.progressText = progressText
    if row.isHovered and row.progressText then
        row.Standing:SetText(row.progressText)
    else
        row.Standing:SetText(row.standingText)
    end
end

reputation.CreateHeaderRow = function(self, parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(HEADER_HEIGHT)
    button.isHeader = true

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    button.bg:SetAllPoints()

    button.Collapse = button:CreateTexture(nil, 'OVERLAY')
    button.Collapse:SetTexture(EXUI.const.textures.frame.icons.chevronRight)
    button.Collapse:SetSize(10, 10)
    button.Collapse:SetPoint('LEFT', 6, 0)
    button.Collapse:SetVertexColor(1, 1, 1, 0.85)

    button.Text = button:CreateFontString(nil, 'OVERLAY')
    button.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Text:SetPoint('LEFT', button.Collapse, 'RIGHT', 4, 0)
    button.Text:SetPoint('RIGHT', -8, 0)
    button.Text:SetJustifyH('LEFT')
    button.Text:SetWordWrap(false)

    button:SetScript('OnEnter', function(btn)
        ApplyHeaderVisual(btn, true)
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyHeaderVisual(btn, false)
    end)
    button:SetScript('OnClick', function(btn)
        if not btn.factionIndex then
            return
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        if btn.isCollapsed then
            C_Reputation.ExpandFactionHeader(btn.factionIndex)
        else
            C_Reputation.CollapseFactionHeader(btn.factionIndex)
        end
        reputation:Update()
    end)

    return button
end

reputation.CreateFactionRow = function(self, parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(ROW_HEIGHT)
    button.isHeader = false

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    button.bg:SetAllPoints()

    button.border = EXUI:AddPixelPerfectBorder(button, 1, { register = false, outwardBottom = false })
    button.border:SetBorderColor(unpack(EXUI.const.theme.border))

    local bar = CreateFrame('StatusBar', nil, button)
    bar:SetSize(BAR_WIDTH, BAR_HEIGHT)
    bar:SetPoint('RIGHT', -8, 0)
    bar:SetStatusBarTexture([[Interface/Addons/ExalityUI/Assets/Images/StatusBar/noisy]])
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    button.Bar = bar

    local barBg = bar:CreateTexture(nil, 'BACKGROUND')
    barBg:SetTexture(EXUI.const.textures.frame.solidBg)
    barBg:SetAllPoints()
    barBg:SetVertexColor(0, 0, 0, 0.65)
    button.BarBg = barBg

    button.Standing = bar:CreateFontString(nil, 'OVERLAY')
    button.Standing:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    button.Standing:SetPoint('CENTER')
    button.Standing:SetJustifyH('CENTER')
    button.Standing:SetWordWrap(false)
    button.Standing:SetTextColor(1, 1, 1, 1)

    button.Text = button:CreateFontString(nil, 'OVERLAY')
    button.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Text:SetPoint('LEFT', 8, 0)
    button.Text:SetPoint('RIGHT', bar, 'LEFT', -8, 0)
    button.Text:SetJustifyH('LEFT')
    button.Text:SetWordWrap(false)
    button.Text:SetTextColor(unpack(EXUI.const.theme.text))

    button:SetScript('OnEnter', function(btn)
        btn.isHovered = true
        ApplyRowVisual(btn, btn.factionIndex == reputation.selectedIndex, true)
        if btn.progressText then
            btn.Standing:SetText(btn.progressText)
        end
        if btn.factionIndex ~= reputation.selectedIndex then
            ShowFactionTooltip(btn)
        end
    end)
    button:SetScript('OnLeave', function(btn)
        btn.isHovered = false
        ApplyRowVisual(btn, btn.factionIndex == reputation.selectedIndex, false)
        btn.Standing:SetText(btn.standingText or '')
        HideFactionTooltip(btn)
    end)
    button:SetScript('OnClick', function(btn)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        HideFactionTooltip(btn)
        if reputation.selectedIndex == btn.factionIndex and reputation.optionsPopup and reputation.optionsPopup:IsShown() then
            reputation:HideOptions()
        else
            reputation:ShowOptions(btn)
        end
    end)

    return button
end

reputation.AcquireHeaderRow = function(self, index)
    local row = self.headerRows[index]
    if not row then
        row = self:CreateHeaderRow(self.scrollChild)
        self.headerRows[index] = row
    end
    return row
end

reputation.AcquireFactionRow = function(self, index)
    local row = self.factionRows[index]
    if not row then
        row = self:CreateFactionRow(self.scrollChild)
        self.factionRows[index] = row
    end
    return row
end

reputation.UpdateScroll = function(self)
    if not self.scrollFrame then
        return
    end
    local width = math.max(1, self.scrollFrame:GetWidth())
    local height = math.max(1, self.scrollChild:GetHeight())
    self.scrollFrame:UpdateScrollChild(width, height)
end

reputation.Update = function(self)
    if not self.panel or not self.isOpen then
        return
    end

    local content = self.scrollChild
    local y = -2
    local headerIndex = 0
    local factionRowIndex = 0
    local listSize = C_Reputation.GetNumFactions()

    for i = 1, listSize do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data then
            if data.isHeader then
                headerIndex = headerIndex + 1
                local row = self:AcquireHeaderRow(headerIndex)
                local indent = data.isChild and 8 or 0

                row:ClearAllPoints()
                row:SetPoint('TOPLEFT', content, 'TOPLEFT', 2 + indent, y)
                row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -2, y)
                row:Show()

                row.factionIndex = i
                row.isCollapsed = data.isCollapsed
                row.isChild = data.isChild
                row.Text:SetText(data.name or '')
                row.Collapse:SetTexture(EXUI.const.textures.frame.icons.chevronRight)
                if data.isCollapsed then
                    row.Collapse:SetRotation(0)
                else
                    row.Collapse:SetRotation(math.rad(-90))
                end
                SetHeaderTextColor(row, data.isChild)
                ApplyHeaderVisual(row, false)
                y = y - HEADER_HEIGHT - ROW_GAP
            else
                factionRowIndex = factionRowIndex + 1
                local row = self:AcquireFactionRow(factionRowIndex)
                local indent = data.isChild and EXUI:ScalePixel(16, row) or EXUI:ScalePixel(6, row)
                local xPad = EXUI:ScalePixel(2, row)
                local yPos = EXUI:ScalePixel(y, row)

                row:ClearAllPoints()
                row:SetPoint('TOPLEFT', content, 'TOPLEFT', xPad + indent, yPos)
                row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -xPad, yPos)
                row:Show()

                row.factionIndex = i
                row.factionID = data.factionID
                row.factionName = data.name
                row.description = data.description
                row.canToggleAtWar = data.canToggleAtWar
                row.atWarWith = data.atWarWith
                row.canSetInactive = data.canSetInactive
                row.isWatched = data.isWatched
                row.Text:SetText(data.name or '')
                ApplyBarState(row, data)
                ApplyRowVisual(row, i == self.selectedIndex, false)
                y = y - ROW_HEIGHT - ROW_GAP
            end
        end
    end

    for i = headerIndex + 1, #self.headerRows do
        self.headerRows[i]:Hide()
    end
    for i = factionRowIndex + 1, #self.factionRows do
        self.factionRows[i]:Hide()
    end

    content:SetHeight(math.max((-y) + 4, 1))
    self:UpdateScroll()

    if self.optionsPopup and self.optionsPopup:IsShown() then
        self:RefreshOptionsPopup()
    end
end

reputation.ResolveSelectedIndex = function(self)
    if not self.selectedName and not self.selectedFactionID then
        return nil
    end
    local listSize = C_Reputation.GetNumFactions()
    for i = 1, listSize do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and not data.isHeader then
            if self.selectedFactionID and data.factionID == self.selectedFactionID then
                return i, data
            end
            if self.selectedName and data.name == self.selectedName then
                return i, data
            end
        end
    end
    return nil
end

reputation.HideOptions = function(self)
    self.selectedIndex = nil
    self.selectedName = nil
    self.selectedFactionID = nil
    C_Reputation.SetSelectedFaction(0)
    if self.optionsPopup then
        self.optionsPopup:Hide()
    end
    for _, row in ipairs(self.factionRows) do
        if row:IsShown() then
            ApplyRowVisual(row, false, false)
        end
    end
end

reputation.SetCheckboxValue = function(self, checkbox, value)
    if not checkbox then
        return
    end
    checkbox.suppressOnChange = true
    checkbox:SetValue('value', value and true or false)
    checkbox.suppressOnChange = false
end

reputation.RefreshOptionsPopup = function(self)
    local popup = self.optionsPopup
    if not popup or not popup:IsShown() then
        return
    end

    local index, data = self:ResolveSelectedIndex()
    if not index or not data then
        self:HideOptions()
        return
    end

    self.selectedIndex = index
    self.selectedFactionID = data.factionID
    self.selectedName = data.name
    C_Reputation.SetSelectedFaction(index)

    popup.Title:SetText(data.name or REPUTATION or 'Reputation')

    local showAtWar = data.canToggleAtWar and true or false
    local showInactive = data.canSetInactive and true or false
    local isMajorFaction = data.factionID and C_Reputation.IsMajorFaction(data.factionID)
    local majorData = isMajorFaction and C_MajorFactions.GetMajorFactionData(data.factionID) or nil
    local showViewRenown = majorData and majorData.isUnlocked and true or false

    popup.atWarCheckbox:SetShown(showAtWar)
    popup.inactiveCheckbox:SetShown(showInactive)
    popup.watchCheckbox:Show()
    popup.viewRenownButton:SetShown(showViewRenown)

    self:SetCheckboxValue(popup.atWarCheckbox, data.atWarWith)
    self:SetCheckboxValue(popup.inactiveCheckbox, not C_Reputation.IsFactionActive(index))
    self:SetCheckboxValue(popup.watchCheckbox, data.isWatched)

    if showViewRenown then
        popup.viewRenownButton.factionID = data.factionID
        popup.viewRenownButton:Enable()
        popup.viewRenownButton.Label:SetTextColor(1, 1, 1, 1)
    end

    -- Re-stack visible controls from the title
    local anchor = popup.Title
    local gap = -10
    if showAtWar then
        popup.atWarCheckbox:ClearAllPoints()
        popup.atWarCheckbox:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', -2, gap)
        anchor = popup.atWarCheckbox
        gap = -4
    end
    if showInactive then
        popup.inactiveCheckbox:ClearAllPoints()
        popup.inactiveCheckbox:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', showAtWar and 0 or -2, gap)
        anchor = popup.inactiveCheckbox
        gap = -4
    end
    popup.watchCheckbox:ClearAllPoints()
    popup.watchCheckbox:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', (showAtWar or showInactive) and 0 or -2, gap)

    local bottomWidget = popup.watchCheckbox
    if showViewRenown then
        popup.viewRenownButton:ClearAllPoints()
        popup.viewRenownButton:SetPoint('TOPLEFT', popup.watchCheckbox, 'BOTTOMLEFT', 2, -8)
        popup.viewRenownButton:SetPoint('RIGHT', popup, 'RIGHT', -12, 0)
        bottomWidget = popup.viewRenownButton
    end

    local titleHeight = popup.Title:GetStringHeight() or 14
    local height = 12 + titleHeight + 10
    if showAtWar then
        height = height + 22 + 4
    end
    if showInactive then
        height = height + 22 + 4
    end
    height = height + 22
    if showViewRenown then
        height = height + 8 + VIEW_RENOWN_HEIGHT
    end
    height = height + 10

    -- Prefer live layout measurement so wrapped titles always fit
    local popupTop = popup:GetTop()
    local widgetBottom = bottomWidget:GetBottom()
    if popupTop and widgetBottom then
        height = math.max(height, popupTop - widgetBottom + 10)
    end
    popup:SetHeight(height)
end

reputation.ShowOptions = function(self, row)
    if not self.optionsPopup or not row then
        return
    end

    self.selectedIndex = row.factionIndex
    self.selectedName = row.factionName
    self.selectedFactionID = row.factionID
    C_Reputation.SetSelectedFaction(row.factionIndex)

    for _, other in ipairs(self.factionRows) do
        if other:IsShown() then
            ApplyRowVisual(other, other.factionIndex == self.selectedIndex, false)
        end
    end

    self.optionsPopup:Show()
    self:RefreshOptionsPopup()
end

reputation.CreateOptionsCheckbox = function(self, parent, label, tooltipText)
    local checkbox = EXFrames:GetFrame('checkbox'):Create()
    checkbox:SetParent(parent)
    checkbox:SetHeight(22)
    checkbox:SetFrameWidth(OPTIONS_WIDTH - 24)
    checkbox:SetLabel(label)
    checkbox.Label:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    checkbox.Label:SetTextColor(unpack(EXUI.const.theme.text))

    checkbox:HookScript('OnEnter', function(cb)
        if tooltipText then
            GameTooltip:SetOwner(cb, 'ANCHOR_RIGHT')
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    checkbox:HookScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    return checkbox
end

reputation.CreateOptionsPopup = function(self, panel)
    local theme = EXUI.const.theme
    local popup = CreateFrame('Frame', nil, panel)
    popup:SetSize(OPTIONS_WIDTH, 120)
    popup:SetPoint('TOPLEFT', panel, 'TOPRIGHT', OPTIONS_GAP, -28)
    popup:SetFrameLevel(panel:GetFrameLevel() + 10)
    popup:EnableMouse(true)
    popup:Hide()

    local bg = popup:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXFrames.assets.textures.ui.panelBg)
    bg:SetVertexColor(unpack(theme.backgroundDeep))
    bg:SetTextureSliceMargins(8, 8, 8, 8)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAllPoints()

    local border = popup:CreateTexture(nil, 'OVERLAY', nil, 1)
    border:SetTexture(EXFrames.assets.textures.ui.panelBorder)
    border:SetVertexColor(unpack(theme.border))
    border:SetTextureSliceMargins(8, 8, 8, 8)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    border:SetAllPoints()

    local close = CreateFrame('Button', nil, popup)
    close:SetSize(22, 18)
    close:SetPoint('TOPRIGHT', -6, -6)
    local closeBg = close:CreateTexture(nil, 'BACKGROUND')
    closeBg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    closeBg:SetTextureSliceMargins(20, 20, 20, 20)
    closeBg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    closeBg:SetVertexColor(unpack(theme.faded))
    closeBg:SetAllPoints()
    local closeIcon = close:CreateTexture(nil, 'OVERLAY')
    closeIcon:SetTexture(EXUI.const.textures.frame.closeIcon)
    closeIcon:SetSize(10, 10)
    closeIcon:SetPoint('CENTER')
    close:SetScript('OnEnter', function()
        closeBg:SetVertexColor(unpack(theme.dangerHover))
    end)
    close:SetScript('OnLeave', function()
        closeBg:SetVertexColor(unpack(theme.faded))
    end)
    close:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        reputation:HideOptions()
    end)

    local title = popup:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    title:SetPoint('TOPLEFT', 12, -12)
    title:SetPoint('TOPRIGHT', close, 'TOPLEFT', -4, -1)
    title:SetJustifyH('CENTER')
    title:SetJustifyV('TOP')
    title:SetWordWrap(true)
    title:SetText(REPUTATION or 'Reputation')
    title:SetTextColor(unpack(HEADER_GOLD))
    popup.Title = title

    local atWarCheckbox = self:CreateOptionsCheckbox(popup, AT_WAR or 'At War', REPUTATION_AT_WAR_DESCRIPTION)
    atWarCheckbox:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', -2, -10)
    atWarCheckbox.onChange = function(value)
        if not reputation.selectedIndex then
            return
        end
        PlaySound(value and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        C_Reputation.ToggleFactionAtWar(reputation.selectedIndex)
        reputation:Update()
    end
    popup.atWarCheckbox = atWarCheckbox

    local inactiveCheckbox = self:CreateOptionsCheckbox(popup, MOVE_TO_INACTIVE or 'Make Inactive', REPUTATION_MOVE_TO_INACTIVE)
    inactiveCheckbox:SetPoint('TOPLEFT', atWarCheckbox, 'BOTTOMLEFT', 0, -4)
    inactiveCheckbox.onChange = function(value)
        if not reputation.selectedIndex then
            return
        end
        PlaySound(value and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        C_Reputation.SetFactionActive(reputation.selectedIndex, not value)
        local index = reputation:ResolveSelectedIndex()
        if index then
            reputation.selectedIndex = index
        end
        reputation:Update()
    end
    popup.inactiveCheckbox = inactiveCheckbox

    local watchCheckbox = self:CreateOptionsCheckbox(popup, SHOW_FACTION_ON_MAINSCREEN or 'Show as Experience Bar', REPUTATION_SHOW_AS_XP)
    watchCheckbox:SetPoint('TOPLEFT', inactiveCheckbox, 'BOTTOMLEFT', 0, -4)
    watchCheckbox.onChange = function(value)
        if not reputation.selectedIndex then
            return
        end
        PlaySound(value and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        C_Reputation.SetWatchedFactionByIndex(value and reputation.selectedIndex or 0)
        if StatusTrackingBarManager and StatusTrackingBarManager.UpdateBarsShown then
            StatusTrackingBarManager:UpdateBarsShown()
        end
        reputation:Update()
    end
    popup.watchCheckbox = watchCheckbox

    local viewRenown = CreateFrame('Button', nil, popup)
    viewRenown:SetHeight(VIEW_RENOWN_HEIGHT)
    viewRenown:SetPoint('BOTTOMLEFT', 12, 10)
    viewRenown:SetPoint('BOTTOMRIGHT', -12, 10)
    viewRenown:Hide()

    local viewBg = viewRenown:CreateTexture(nil, 'BACKGROUND')
    viewBg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    viewBg:SetTextureSliceMargins(20, 20, 20, 20)
    viewBg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    viewBg:SetVertexColor(0.55, 0.12, 0.12, 1)
    viewBg:SetAllPoints()
    viewRenown.bg = viewBg

    local viewLabel = viewRenown:CreateFontString(nil, 'OVERLAY')
    viewLabel:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    viewLabel:SetPoint('CENTER')
    viewLabel:SetText(VIEW_RENOWN_BUTTON_LABEL or 'View Renown')
    viewLabel:SetTextColor(1, 1, 1, 1)
    viewRenown.Label = viewLabel

    viewRenown:SetScript('OnEnter', function(btn)
        if btn:IsEnabled() then
            viewBg:SetVertexColor(0.7, 0.18, 0.18, 1)
        end
    end)
    viewRenown:SetScript('OnLeave', function()
        viewBg:SetVertexColor(0.55, 0.12, 0.12, 1)
    end)
    viewRenown:SetScript('OnClick', function(btn)
        if not btn.factionID then
            return
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        OpenMajorFactionRenown(btn.factionID)
    end)
    popup.viewRenownButton = viewRenown

    self.optionsPopup = popup
    return popup
end

local function HideEdgeToggles()
    if currencies.toggle then
        if currencies.toggle.fadeIn then
            currencies.toggle.fadeIn:Stop()
        end
        if currencies.toggle.stopWindowAnims then
            currencies.toggle.stopWindowAnims()
        end
        currencies.toggle.edgeHidden = true
        currencies.toggle:SetAlpha(1)
        currencies.toggle:Hide()
    end
    if reputation.toggle then
        if reputation.toggle.fadeIn then
            reputation.toggle.fadeIn:Stop()
        end
        if reputation.toggle.stopWindowAnims then
            reputation.toggle.stopWindowAnims()
        end
        reputation.toggle.edgeHidden = true
        reputation.toggle:SetAlpha(1)
        reputation.toggle:Hide()
    end
end

local function RevealEdgeToggles(animated)
    if currencies.isOpen or reputation.isOpen then
        return
    end
    if currencies.RevealToggle then
        currencies:RevealToggle(animated)
    end
    if reputation.RevealToggle then
        reputation:RevealToggle(animated)
    end
end

reputation.StopAnimations = function(self)
    if self.panel and self.panel.fadeIn then
        self.panel.fadeIn:Stop()
    end
    if self.panel and self.panel.fadeOut then
        self.panel.fadeOut:Stop()
    end
    if self.toggle and self.toggle.fadeIn then
        self.toggle.fadeIn:Stop()
    end
end

reputation.RevealToggle = function(self, animated)
    if not self.toggle then
        return
    end
    self.toggle.edgeHidden = false
    if self.toggle.stopWindowAnims then
        self.toggle.stopWindowAnims()
    end
    ApplyToggleVisual(self.toggle, false)
    if animated and self.useAnimation and self.toggle.fadeIn then
        self.toggle:SetAlpha(0)
        self.toggle:Show()
        self.toggle.fadeIn:Play()
    else
        self.toggle:SetAlpha(1)
        self.toggle:Show()
    end
end

reputation.ShowPanel = function(self)
    if not self.panel then
        return
    end

    self.isOpen = true
    if currencies and currencies.isOpen and currencies.HidePanel then
        currencies:HidePanel(true)
    end

    self:StopAnimations()
    HideEdgeToggles()
    self.panel:Show()
    self:Update()

    if self.useAnimation and self.panel.fadeIn then
        self.panel:SetAlpha(0)
        self.panel.fadeIn:Play()
    else
        self.panel:SetAlpha(1)
    end
end

reputation.HidePanel = function(self, immediate)
    if not self.panel then
        return
    end

    self.isOpen = false
    self:HideOptions()
    self:StopAnimations()

    if immediate or not self.useAnimation or not self.panel.fadeOut then
        self.panel:SetAlpha(1)
        self.panel:Hide()
        RevealEdgeToggles(false)
        return
    end

    self.panel.fadeOut:SetScript('OnFinished', function()
        self.panel:Hide()
        self.panel:SetAlpha(1)
        RevealEdgeToggles(true)
    end)
    self.panel.fadeOut:Play()
end

local function AttachToggleBehindWindow(button, window, offsetX, offsetY)
    local animDuration = 0.2
    local diveY = 20

    button.hostWindow = window
    button:SetParent(window:GetParent() or UIParent)
    button:SetFrameStrata(window:GetFrameStrata())
    button:SetFrameLevel(math.max(1, window:GetFrameLevel() - 1))
    button:ClearAllPoints()
    button:SetPoint('TOPLEFT', window, 'TOPRIGHT', offsetX, offsetY)
    button:Hide()

    local function syncLayer()
        if not window:IsShown() then
            return
        end
        button:SetFrameStrata(window:GetFrameStrata())
        button:SetFrameLevel(math.max(1, window:GetFrameLevel() - 1))
    end

    -- Match window dive/fade. No point adjustment: layout already follows the window anchor.
    local windowFadeIn = button:CreateAnimationGroup()
    local alphaIn = windowFadeIn:CreateAnimation('Alpha')
    alphaIn:SetFromAlpha(0)
    alphaIn:SetToAlpha(1)
    alphaIn:SetDuration(animDuration)
    alphaIn:SetSmoothing('IN')
    local translateIn = windowFadeIn:CreateAnimation('Translation')
    translateIn:SetOffset(0, -diveY)
    translateIn:SetDuration(animDuration)
    translateIn:SetSmoothing('IN')
    windowFadeIn:SetScript('OnFinished', function()
        button:SetAlpha(1)
    end)
    button.windowFadeIn = windowFadeIn

    local windowFadeOut = button:CreateAnimationGroup()
    local alphaOut = windowFadeOut:CreateAnimation('Alpha')
    alphaOut:SetFromAlpha(1)
    alphaOut:SetToAlpha(0)
    alphaOut:SetDuration(animDuration)
    alphaOut:SetSmoothing('OUT')
    local translateOut = windowFadeOut:CreateAnimation('Translation')
    translateOut:SetOffset(0, diveY)
    translateOut:SetDuration(animDuration)
    translateOut:SetSmoothing('OUT')
    windowFadeOut:SetScript('OnFinished', function()
        button:SetAlpha(1)
        button:Hide()
    end)
    button.windowFadeOut = windowFadeOut

    local function stopWindowAnims()
        if button.windowFadeIn then
            button.windowFadeIn:Stop()
        end
        if button.windowFadeOut then
            button.windowFadeOut:Stop()
        end
    end
    button.stopWindowAnims = stopWindowAnims

    if window.fadeIn then
        window.fadeIn:HookScript('OnPlay', function()
            if button.edgeHidden then
                return
            end
            stopWindowAnims()
            if button.fadeIn then
                button.fadeIn:Stop()
            end
            syncLayer()
            button:SetAlpha(0)
            button:Show()
            button.windowFadeIn:Play()
        end)
    end

    if window.fadeOut then
        window.fadeOut:HookScript('OnPlay', function()
            if button.edgeHidden or not button:IsShown() then
                return
            end
            stopWindowAnims()
            if button.fadeIn then
                button.fadeIn:Stop()
            end
            button.windowFadeOut:Play()
        end)
    end

    window:HookScript('OnHide', function()
        stopWindowAnims()
        button:SetAlpha(1)
        button:Hide()
    end)

    window:HookScript('OnShow', syncLayer)
end

reputation.CreateToggle = function(self, window)
    local button = CreateFrame('Button', nil, window:GetParent() or UIParent)
    button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)

    local bg = button:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    bg:SetTextureSliceMargins(20, 20, 20, 20)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetAllPoints()
    button.bg = bg

    local icon = button:CreateTexture(nil, 'OVERLAY')
    icon:SetTexture(EXUI.const.textures.characterFrame.users)
    icon:SetSize(18, 18)
    icon:SetPoint('CENTER', BUTTON_ICON_OFFSET_X, 0)
    icon:SetVertexColor(1, 1, 1, 1)
    button.icon = icon

    AttachToggleBehindWindow(button, window, BUTTON_OUTSET_X, BUTTON_OFFSET_Y)

    button.Tooltip = tooltip:Get({
        text = REPUTATION or 'Reputation'
    }, button)

    button:SetScript('OnEnter', function(btn)
        ApplyToggleVisual(btn, true)
        btn.Tooltip:ShowTooltip()
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyToggleVisual(btn, false)
        btn.Tooltip:HideTooltip()
    end)
    button:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        reputation:ShowPanel()
    end)

    button.fadeIn = EXUI.utils.animation.fade(button, ANIM_DURATION, 0, 1)

    ApplyToggleVisual(button, false)
    self.toggle = button
    return button
end

reputation.CreateCloseButton = function(self, panel)
    local theme = EXUI.const.theme
    local close = CreateFrame('Button', nil, panel)
    close:SetSize(28, 22)
    close:SetPoint('TOPRIGHT', -8, -6)
    close:SetFrameLevel(panel:GetFrameLevel() + 5)

    local bg = close:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    bg:SetTextureSliceMargins(20, 20, 20, 20)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetVertexColor(unpack(theme.faded))
    bg:SetAllPoints()

    local icon = close:CreateTexture(nil, 'OVERLAY')
    icon:SetTexture(EXUI.const.textures.frame.closeIcon)
    icon:SetSize(12, 12)
    icon:SetPoint('CENTER')
    icon:SetVertexColor(1, 1, 1, 1)

    close:SetScript('OnEnter', function()
        bg:SetVertexColor(unpack(theme.dangerHover))
    end)
    close:SetScript('OnLeave', function()
        bg:SetVertexColor(unpack(theme.faded))
    end)
    close:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        reputation:HidePanel()
    end)

    panel.close = close
    return close
end

reputation.CreatePanel = function(self, window)
    local theme = EXUI.const.theme
    local panel = CreateFrame('Frame', nil, window)
    panel:SetWidth(PANEL_WIDTH)
    panel:SetPoint('TOPLEFT', window, 'TOPRIGHT', PANEL_GAP, 0)
    panel:SetPoint('BOTTOMLEFT', window, 'BOTTOMRIGHT', PANEL_GAP, 0)
    panel:SetFrameLevel(window:GetFrameLevel() + 5)
    panel:Hide()
    panel:SetAlpha(1)

    local bg = panel:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXFrames.assets.textures.ui.panelBg)
    bg:SetVertexColor(unpack(theme.backgroundDeep))
    bg:SetTextureSliceMargins(8, 8, 8, 8)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAllPoints()

    local border = panel:CreateTexture(nil, 'OVERLAY', nil, 1)
    border:SetTexture(EXFrames.assets.textures.ui.panelBorder)
    border:SetVertexColor(unpack(theme.border))
    border:SetTextureSliceMargins(8, 8, 8, 8)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    border:SetAllPoints()

    self:CreateCloseButton(panel)
    self:CreateOptionsPopup(panel)

    local title = panel:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    title:SetPoint('TOPLEFT', CONTENT_PAD, -10)
    title:SetPoint('TOPRIGHT', panel.close, 'TOPLEFT', -6, -2)
    title:SetJustifyH('LEFT')
    title:SetText(REPUTATION or 'Reputation')
    title:SetTextColor(unpack(theme.text))
    panel.Title = title

    local scrollFrame = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scrollFrame:SetParent(panel)
    scrollFrame:SetPoint('TOPLEFT', CONTENT_PAD, -(TITLE_HEIGHT + 4))
    scrollFrame:SetPoint('BOTTOMRIGHT', -CONTENT_PAD, CONTENT_PAD)
    self.scrollFrame = scrollFrame
    self.scrollChild = scrollFrame.child

    scrollFrame:HookScript('OnSizeChanged', function()
        if reputation.isOpen then
            reputation:Update()
        end
    end)

    panel.fadeIn = EXUI.utils.animation.fade(panel, ANIM_DURATION, 0, 1)
    panel.fadeOut = EXUI.utils.animation.fade(panel, ANIM_DURATION, 1, 0)

    panel:RegisterEvent('UPDATE_FACTION')
    panel:RegisterEvent('MAJOR_FACTION_RENOWN_LEVEL_CHANGED')
    panel:SetScript('OnEvent', function()
        if reputation.isOpen then
            reputation:Update()
        end
    end)

    self.panel = panel
    return panel
end

reputation.Create = function(self, window)
    self:CreateToggle(window)
    self:CreatePanel(window)
end

reputation.Hide = function(self)
    self.isOpen = false
    self:HideOptions()
    self:StopAnimations()
    if self.panel then
        self.panel:SetAlpha(1)
        self.panel:Hide()
    end
    if self.toggle then
        -- Keep visible so window close animation can fade/dive it out with the frame.
        self.toggle.edgeHidden = false
    end
end
