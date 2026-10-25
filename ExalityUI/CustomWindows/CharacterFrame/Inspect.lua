---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesWindowFrame
local windowConstruct = EXFrames:GetFrame('window-frame')

---@class ExalityFramesTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

---@class EXUICharacterFrameInspectSlot
local inspectSlot = EXUI:GetModule('character-frame-inspect-slot')

---@class EXUICharacterFrameEdgeToggle
local edgeToggle = EXUI:GetModule('character-frame-edge-toggle')

---@class EXUICharacterFrameWindow
local characterFrame = EXUI:GetModule('character-frame-window')

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')

---@class EXUITalentsWindow
local talentsWindow = EXUI:GetModule('talents-window')

-------------------------

---@class EXUICharacterFrameInspect
local inspect = EXUI:GetModule('character-frame-inspect')

inspect.enabled = false
inspect.isCreated = false
inspect.window = nil
inspect.unit = nil
inspect.pendingUnit = nil
inspect.blizzardOverride = false
inspect.isAttached = false
inspect.activePanel = nil

local LEFT_SLOTS = { 1, 2, 3, 15, 5, 4, 19, 9 }
local RIGHT_SLOTS = { 10, 6, 7, 8, 11, 12, 13, 14 }
local SLOT_SIZE = 36
local SLOT_GAP = 6
local WINDOW_BG = [[Interface/Addons/ExalityUI/Options/Assets/main-bg_2.png]]
local WINDOW_CORNER = 24
local PANEL_WIDTH = 260
local PANEL_GAP = 34
local CONTENT_PAD = 12
local ROW_HEIGHT = 18
local ANIM_DURATION = 0.18
local RETRY_DELAY = 0.5
local RETRY_LIMIT = 20
local TOGGLE_FIRST_Y = -60
local TOGGLE_STEP_Y = -34
local HEADER_GOLD = { 235 / 255, 183 / 255, 52 / 255, 1 }

local TOGGLE_COLORS = {
    pvp = { { 210 / 255, 60 / 255, 60 / 255, 1 }, { 240 / 255, 100 / 255, 100 / 255, 1 } },
    guild = { { 0 / 255, 170 / 255, 100 / 255, 1 }, { 40 / 255, 210 / 255, 130 / 255, 1 } },
    dressUp = { { 180 / 255, 140 / 255, 230 / 255, 1 }, { 210 / 255, 180 / 255, 255 / 255, 1 } },
}

local FACTION_LOGOS = {
    Alliance = [[Interface\Timer\Alliance-Logo]],
    Horde = [[Interface\Timer\Horde-Logo]],
    Neutral = [[Interface\Timer\Panda-Logo]],
}

local function BottomSlotIds()
    if (EXUI.IsForever()) then
        return { 16, 17, INVSLOT_RANGED }
    end
    return { 16, 17 }
end

local function InspectSpecID(unit)
    if (EXUI.IsForever() or not unit) then
        return nil
    end
    local specID = C_SpecializationInfo.GetInspectSpecialization(unit)
    if (specID and specID > 0) then
        return specID
    end
end

local function GuildInfo(unit)
    local guildPoints, numMembers, guildName, realmName = C_PaperDollInfo.GetInspectGuildInfo(unit)
    if (guildName and guildName ~= '') then
        return guildName, numMembers, realmName, guildPoints
    end
end

---------------- Header / Model / Background ----------------

inspect.UpdateHeader = function(self)
    local unit = self.unit
    local window = self.window
    if (not unit or not window) then
        return
    end

    local level, effectiveLevel = UnitLevel(unit), UnitEffectiveLevel(unit)
    if (level == -1 or effectiveLevel == -1) then
        level = '??'
    elseif (effectiveLevel ~= level) then
        level = EFFECTIVE_LEVEL_FORMAT:format(effectiveLevel, level)
    end
    window.Header.LevelText:SetText(level)

    local className, classFile = UnitClass(unit)
    local classColor = C_ClassColor.GetClassColor(classFile)
    local classText = classColor and classColor:WrapTextInColorCode(className) or className
    local specID = InspectSpecID(unit)
    local specName = specID and select(2, GetSpecializationInfoByID(specID, UnitSex(unit)))
    if (specName and specName ~= '' and specName ~= className) then
        window.Header.ClassSpecText:SetText(string.format('%s %s', specName, classText))
    else
        window.Header.ClassSpecText:SetText(classText)
    end

    local ilvl = C_PaperDollInfo.GetInspectItemLevel(unit)
    if (ilvl and ilvl > 0) then
        window.Header.Ilvl:SetText(WrapTextInColorCode(string.format('%.2f', ilvl), EXUI.utils.getIlvlColor(ilvl)))
        window.Header.Separator:Show()
    else
        window.Header.Ilvl:SetText('')
        window.Header.Separator:Hide()
    end

    window:SetTitle(UnitPVPName(unit) or GetUnitName(unit, true) or '')
    if (classColor) then
        window.CharacterGlow:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.5)
    end
    self:UpdateBackground(specID)
end

inspect.UpdateBackground = function(self, specID)
    local window = self.window
    local visuals = specID and not InCombatLockdown() and ClassTalentUtil and ClassTalentUtil.GetVisualsForSpecID and
        ClassTalentUtil.GetVisualsForSpecID(specID)
    if (specID and not ClassTalentUtil and not InCombatLockdown() and C_AddOns and C_AddOns.LoadAddOn) then
        C_AddOns.LoadAddOn('Blizzard_PlayerSpells')
        visuals = ClassTalentUtil and ClassTalentUtil.GetVisualsForSpecID and ClassTalentUtil.GetVisualsForSpecID(specID)
    end
    local atlas = visuals and visuals.background
    if (not atlas or not C_Texture.GetAtlasInfo(atlas)) then
        self.background:Hide()
        self.backgroundBacking:Hide()
        window.Texture:Show()
        return
    end
    window.Texture:Hide()
    if (window.PPBorder) then
        window.PPBorder:Hide()
    end
    self.backgroundBacking:Show()
    self.background:Show()
    self.backgroundAtlas = atlas
    characterFrame:FitAtlas(self.background, atlas)
end

inspect.UpdateModel = function(self)
    local model = self.window.CharacterModel
    model:Show()
    local canDraw = model:SetUnit(self.unit)
    if (canDraw ~= false) then
        model.unavailable = false
        -- Model is revealed by the window fade-in handler; PlayerModel ignores parent animations.
        if (self.window.fadeIn and self.window.fadeIn:IsPlaying()) then
            model:Hide()
        end
        self.window.FactionLogo:Hide()
        return
    end
    model.unavailable = true
    model:Hide()
    local logo = FACTION_LOGOS[UnitFactionGroup(self.unit) or '']
    self.window.FactionLogo:SetTexture(logo)
    self.window.FactionLogo:SetShown(logo ~= nil)
end

inspect.UpdateSlots = function(self)
    local complete = true
    for _, slot in ipairs(self.slots) do
        slot.unit = self.unit
        if (not slot:Update()) then
            complete = false
        end
    end
    local ilvl = self.unit and C_PaperDollInfo.GetInspectItemLevel(self.unit)
    if (not ilvl or ilvl <= 0) then
        complete = false
    end
    if (complete) then
        self:CancelRetry()
    else
        self:ScheduleRetry()
    end
end

-- Inspected gear streams in after INSPECT_READY; poll briefly until every slot has its data.
inspect.ScheduleRetry = function(self)
    if (self.retryTimer) then
        return
    end
    self.retryCount = (self.retryCount or 0) + 1
    if (self.retryCount > RETRY_LIMIT) then
        return
    end
    self.retryTimer = C_Timer.NewTimer(RETRY_DELAY, function()
        inspect.retryTimer = nil
        if (inspect:IsShown() and inspect.unit) then
            inspect:UpdateSlots()
            inspect:UpdateHeader()
        end
    end)
end

inspect.CancelRetry = function(self)
    if (self.retryTimer) then
        self.retryTimer:Cancel()
        self.retryTimer = nil
    end
end

---------------- Panels ----------------

local function CreateCloseButton(panel, onClick)
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

    close:SetScript('OnEnter', function()
        bg:SetVertexColor(unpack(theme.dangerHover))
    end)
    close:SetScript('OnLeave', function()
        bg:SetVertexColor(unpack(theme.faded))
    end)
    close:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        onClick()
    end)
    return close
end

local function CreatePanel(window, titleText)
    local theme = EXUI.const.theme
    local panel = CreateFrame('Frame', nil, window)
    panel:SetWidth(PANEL_WIDTH)
    panel:SetPoint('TOPLEFT', window, 'TOPRIGHT', PANEL_GAP, 0)
    panel:SetPoint('BOTTOMLEFT', window, 'BOTTOMRIGHT', PANEL_GAP, 0)
    panel:SetFrameLevel(window:GetFrameLevel() + 5)
    panel:Hide()

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

    panel.close = CreateCloseButton(panel, function()
        inspect:HidePanel()
    end)

    local title = panel:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    title:SetPoint('TOPLEFT', CONTENT_PAD, -10)
    title:SetPoint('TOPRIGHT', panel.close, 'TOPLEFT', -6, -2)
    title:SetJustifyH('LEFT')
    title:SetText(titleText)
    title:SetTextColor(unpack(theme.text))
    panel.Title = title

    panel.fadeIn = EXUI.utils.animation.fade(panel, ANIM_DURATION, 0, 1)
    return panel
end

local function CreateText(parent, size, color)
    local text = parent:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, size, 'OUTLINE')
    text:SetTextColor(unpack(color or EXUI.const.theme.text))
    text:SetJustifyH('LEFT')
    return text
end

-- Label on the left, value on the right; returns the row so callers can chain anchors.
local function CreateStatRow(parent, anchor, label)
    local row = CreateFrame('Frame', nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -2)
    row:SetPoint('TOPRIGHT', anchor, 'BOTTOMRIGHT', 0, -2)
    row.Label = CreateText(row, 11, EXUI.const.theme.textMuted)
    row.Label:SetPoint('LEFT')
    row.Label:SetText(label or '')
    row.Value = CreateText(row, 11)
    row.Value:SetPoint('RIGHT')
    row.Value:SetJustifyH('RIGHT')
    return row
end

local function CreateSectionHeader(parent, anchor, label, gap)
    local header = CreateFrame('Frame', nil, parent)
    header:SetHeight(ROW_HEIGHT)
    header:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -(gap or 10))
    header:SetPoint('TOPRIGHT', anchor, 'BOTTOMRIGHT', 0, -(gap or 10))
    header.Text = CreateText(header, 12, HEADER_GOLD)
    header.Text:SetPoint('LEFT')
    header.Text:SetText(label)
    return header
end

local function CreateContentTop(panel)
    local top = CreateFrame('Frame', nil, panel)
    top:SetHeight(1)
    top:SetPoint('TOPLEFT', CONTENT_PAD, -34)
    top:SetPoint('TOPRIGHT', -CONTENT_PAD, -34)
    return top
end

local function CreatePvpTalentSlot(parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetSize(34, 34)
    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    button.Icon = icon
    local mask = button:CreateMaskTexture()
    mask:SetAllPoints()
    mask:SetTexture(EXUI.const.textures.characterFrame.slotMask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)
    local border = button:CreateTexture(nil, 'OVERLAY')
    border:SetPoint('TOPLEFT', -1, 1)
    border:SetPoint('BOTTOMRIGHT', 1, -1)
    border:SetTexture(EXUI.const.textures.characterFrame.border.empty)
    button:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        if (self.talentID) then
            GameTooltip:SetPvpTalent(self.talentID, true)
        else
            GameTooltip:SetText(TALENT_NOT_SELECTED, HIGHLIGHT_FONT_COLOR:GetRGB())
        end
        GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    button:SetScript('OnClick', function(self)
        if (self.talentID and IsModifiedClick('CHATLINK')) then
            local link = GetPvpTalentLink(self.talentID)
            if (link) then
                ChatFrameUtil.InsertLink(link)
            end
        end
    end)
    return button
end

inspect.CreatePvpPanel = function(self, window)
    local panel = CreatePanel(window, PVP or 'PvP')
    local top = CreateContentTop(panel)

    if (EXUI.IsForever()) then
        panel.Season = CreateStatRow(panel, top, '')
        panel.Rank = CreateStatRow(panel, panel.Season, RANK or 'Rank')
        panel.Progress = CreateStatRow(panel, panel.Rank, '')

        local bar = CreateFrame('StatusBar', nil, panel)
        bar:SetHeight(10)
        bar:SetPoint('TOPLEFT', panel.Progress, 'BOTTOMLEFT', 0, -4)
        bar:SetPoint('TOPRIGHT', panel.Progress, 'BOTTOMRIGHT', 0, -4)
        bar:SetStatusBarTexture([[Interface\Buttons\WHITE8X8]])
        bar:SetStatusBarColor(unpack(HEADER_GOLD))
        local barBg = bar:CreateTexture(nil, 'BACKGROUND')
        barBg:SetAllPoints()
        barBg:SetColorTexture(0, 0, 0, 0.5)
        panel.Bar = bar

        local kills = CreateSectionHeader(panel, bar, HONORABLE_KILLS or 'Honorable Kills')
        panel.Today = CreateStatRow(panel, kills, HONOR_TODAY or 'Today')
        panel.Lifetime = CreateStatRow(panel, panel.Today, HONOR_LIFETIME or 'Lifetime')
        self.pvpPanel = panel
        return panel
    end

    panel.HonorLevel = CreateStatRow(panel, top, '')
    panel.HKs = CreateStatRow(panel, panel.HonorLevel, HONORABLE_KILLS or 'Honorable Kills')

    local rated = CreateSectionHeader(panel, panel.HKs, 'Rated')
    panel.Rated = rated
    panel.Brackets = {}
    local brackets = {
        { key = 'arena2', label = ARENA_BATTLES_2V2 or '2v2' },
        { key = 'arena3', label = ARENA_BATTLES_3V3 or '3v3' },
        { key = 'rbg', label = PVP_RATED_BATTLEGROUNDS or 'Rated Battlegrounds' },
        { key = 'shuffle', label = PVP_RATED_SOLO_SHUFFLE or 'Solo Shuffle' },
        { key = 'blitz', label = PVP_RATED_BG_BLITZ or 'Battleground Blitz' },
    }
    local anchor = rated
    for _, info in ipairs(brackets) do
        local row = CreateStatRow(panel, anchor, info.label)
        row.Record = CreateText(row, 10, EXUI.const.theme.textMuted)
        row.Record:SetPoint('RIGHT', row.Value, 'LEFT', -8, 0)
        panel.Brackets[info.key] = row
        anchor = row
    end

    local talents = CreateSectionHeader(panel, anchor, 'PvP Talents')
    panel.TalentsHeader = talents
    panel.TalentSlots = {}
    local prev
    for i = 1, 3 do
        local slot = CreatePvpTalentSlot(panel)
        if (prev) then
            slot:SetPoint('LEFT', prev, 'RIGHT', SLOT_GAP, 0)
        else
            slot:SetPoint('TOPLEFT', talents, 'BOTTOMLEFT', 0, -6)
        end
        slot.slotIndex = i
        panel.TalentSlots[i] = slot
        prev = slot
    end

    self.pvpPanel = panel
    return panel
end

local function FormatRecord(won, played)
    won = won or 0
    played = played or 0
    return string.format('%d - %d', won, played - won)
end

inspect.UpdatePvpPanel = function(self)
    local panel = self.pvpPanel
    local unit = self.unit
    if (not panel or not panel:IsShown() or not unit) then
        return
    end

    if (EXUI.IsForever()) then
        local todayHK, _, _, _, lifetimeHK, _, rankLevel, honorCurrent, honorNextLevel = GetInspectHonorData()
        rankLevel = rankLevel or 0
        honorCurrent = honorCurrent or 0
        honorNextLevel = honorNextLevel or 0
        local season = GetCurrentArenaSeason and GetCurrentArenaSeason() or 0
        panel.Season.Label:SetText(string.format(EXPANSION_SEASON_NAME or 'Season %2$d', '', season))
        panel.Season:SetShown(season > 0)
        local rankText = PVP_RANK_0_NAME
        if (rankLevel > 0) then
            local affix = UnitFactionGroup(unit) == 'Alliance' and '_1' or '_0'
            local key = 'PVP_RANK_' .. tostring(Enum.PvPRanks.Rank_1 + rankLevel - 1) .. affix
            rankText = PVP_RANK_NUMBER_AND_TITLE:format(rankLevel, GetText(key, UnitSex(unit)))
        end
        panel.Rank.Value:SetText(rankText)
        panel.Progress.Label:SetText(string.format(PVP_RANK_CURRENT_PROGRESS, honorCurrent, honorNextLevel))
        panel.Bar:SetMinMaxValues(0, math.max(honorNextLevel, 1))
        panel.Bar:SetValue(honorCurrent)
        panel.Today.Value:SetText(todayHK or 0)
        panel.Lifetime.Value:SetText(lifetimeHK or 0)
        return
    end

    local _, _, _, _, lifetimeHKs, _, honorLevel = GetInspectHonorData()
    panel.HonorLevel.Label:SetFormattedText(HONOR_LEVEL_LABEL, honorLevel or 0)
    panel.HKs.Value:SetText(lifetimeHKs or 0)

    local canShowRated = C_SpecializationInfo.CanPlayerUsePVPTalentUI()
    panel.HonorLevel:SetShown(canShowRated)
    panel.Rated:SetShown(canShowRated)
    panel.TalentsHeader:SetShown(canShowRated)
    for _, row in pairs(panel.Brackets) do
        row:SetShown(canShowRated)
    end
    for _, slot in ipairs(panel.TalentSlots) do
        slot:SetShown(canShowRated)
    end
    if (not canShowRated) then
        return
    end

    for index, key in ipairs({ 'arena2', 'arena3' }) do
        local rating, seasonPlayed, seasonWon = GetInspectArenaData(index)
        panel.Brackets[key].Value:SetText(rating or 0)
        panel.Brackets[key].Record:SetText(FormatRecord(seasonWon, seasonPlayed))
    end
    local rbg = C_PaperDollInfo.GetInspectRatedBGData()
    panel.Brackets.rbg.Value:SetText(rbg and rbg.rating or 0)
    panel.Brackets.rbg.Record:SetText(FormatRecord(rbg and rbg.won, rbg and rbg.played))
    local shuffle = C_PaperDollInfo.GetInspectRatedSoloShuffleData()
    panel.Brackets.shuffle.Value:SetText(shuffle and shuffle.rating or 0)
    panel.Brackets.shuffle.Record:SetText(FormatRecord(shuffle and shuffle.roundsWon, shuffle and shuffle.roundsPlayed))
    local blitz = C_PaperDollInfo.GetInspectRatedBGBlitzData()
    panel.Brackets.blitz.Value:SetText(blitz and blitz.rating or 0)
    panel.Brackets.blitz.Record:SetText(FormatRecord(blitz and blitz.gamesWon, blitz and blitz.gamesPlayed))

    for _, slot in ipairs(panel.TalentSlots) do
        local talentID = C_SpecializationInfo.GetInspectSelectedPvpTalent(unit, slot.slotIndex)
        slot.talentID = talentID
        if (talentID) then
            slot.Icon:SetTexture(select(3, GetPvpTalentInfoByID(talentID)))
            slot.Icon:SetVertexColor(1, 1, 1, 1)
        else
            slot.Icon:SetTexture(EXUI.const.textures.characterFrame.gem.empty)
            slot.Icon:SetVertexColor(1, 1, 1, 0.4)
        end
    end
end

inspect.CreateGuildPanel = function(self, window)
    local panel = CreatePanel(window, GUILD or 'Guild')

    local banner = CreateFrame('Frame', nil, panel)
    banner:SetSize(118, 144)
    banner:SetPoint('TOP', 0, -40)
    local bannerBg = banner:CreateTexture(nil, 'BACKGROUND', nil, 1)
    bannerBg:SetAllPoints()
    bannerBg:SetTexture([[Interface\GuildFrame\GuildInspect-Parts]])
    bannerBg:SetTexCoord(0.23632813, 0.46679688, 0.70117188, 0.98242188)
    local bannerBorder = banner:CreateTexture(nil, 'BACKGROUND', nil, 2)
    bannerBorder:SetAllPoints()
    bannerBorder:SetTexture([[Interface\GuildFrame\GuildInspect-Parts]])
    bannerBorder:SetTexCoord(0.00195313, 0.23242188, 0.70117188, 0.98242188)
    local leftIcon = banner:CreateTexture(nil, 'ARTWORK')
    leftIcon:SetSize(50, 125)
    leftIcon:SetPoint('TOPLEFT', 10, -1)
    leftIcon:SetTexCoord(1, 0, 0, 1)
    local rightIcon = banner:CreateTexture(nil, 'ARTWORK')
    rightIcon:SetSize(50, 125)
    rightIcon:SetPoint('LEFT', leftIcon, 'RIGHT', -1, 0)
    panel.BannerBg = bannerBg
    panel.BannerBorder = bannerBorder
    panel.LeftIcon = leftIcon
    panel.RightIcon = rightIcon

    local name = CreateText(panel, 16, HEADER_GOLD)
    name:SetPoint('TOP', banner, 'BOTTOM', 0, -12)
    name:SetWidth(PANEL_WIDTH - CONTENT_PAD * 2)
    name:SetJustifyH('CENTER')
    panel.Name = name

    local realm = CreateText(panel, 12)
    realm:SetPoint('TOP', name, 'BOTTOM', 0, -6)
    realm:SetJustifyH('CENTER')
    panel.Realm = realm

    local faction = CreateText(panel, 12, EXUI.const.theme.textMuted)
    faction:SetPoint('TOP', realm, 'BOTTOM', 0, -10)
    faction:SetJustifyH('CENTER')
    panel.Faction = faction

    local members = CreateText(panel, 12, EXUI.const.theme.textMuted)
    members:SetPoint('TOP', faction, 'BOTTOM', 0, -4)
    members:SetJustifyH('CENTER')
    panel.Members = members

    self.guildPanel = panel
    return panel
end

inspect.UpdateGuildPanel = function(self)
    local panel = self.guildPanel
    local unit = self.unit
    if (not panel or not panel:IsShown() or not unit) then
        return
    end
    local guildName, numMembers, realmName = GuildInfo(unit)
    local _, factionName = UnitFactionGroup(unit)
    panel.Name:SetText(guildName or '')
    if (realmName and realmName ~= '' and not EXUI.IsForever()) then
        panel.Realm:SetFormattedText(INSPECT_GUILD_REALM, realmName)
    else
        panel.Realm:SetText('')
    end
    if (factionName and numMembers) then
        panel.Faction:SetFormattedText(INSPECT_GUILD_FACTION, factionName)
        panel.Members:SetFormattedText(INSPECT_GUILD_NUM_MEMBERS, numMembers)
    else
        panel.Faction:SetText('')
        panel.Members:SetText('')
    end
    SetDoubleGuildTabardTextures(unit, panel.LeftIcon, panel.RightIcon, panel.BannerBg, panel.BannerBorder)
end

inspect.UpdatePanels = function(self)
    self:UpdatePvpPanel()
    self:UpdateGuildPanel()
end

inspect.ShowPanel = function(self, id)
    if (self.activePanel == id) then
        self:HidePanel()
        return
    end
    self:HidePanel()
    local panel = self.panels[id]
    if (not panel) then
        return
    end
    self.activePanel = id
    panel:SetAlpha(0)
    panel:Show()
    panel.fadeIn:Play()
    self:UpdatePanels()
    self:UpdateToggles()
end

inspect.HidePanel = function(self)
    if (self.panels) then
        for _, panel in pairs(self.panels) do
            panel.fadeIn:Stop()
            panel:SetAlpha(1)
            panel:Hide()
        end
    end
    self.activePanel = nil
    self:UpdateToggles()
end

---------------- Toggles ----------------

local function CanOpenTalents()
    return not InCombatLockdown() and C_Traits.HasValidInspectData()
end

inspect.OpenTalents = function(self)
    local unit = self.unit
    if (not unit or not CanOpenTalents()) then
        return
    end
    if (customWindows.Data:GetValue('TalentsEnabled') == true) then
        talentsWindow:ShowInspect(unit)
        return
    end
    PlayerSpellsFrame_LoadUI()
    PlayerSpellsUtil.OpenToClassTalentsTab(unit)
end

inspect.OpenDressUp = function(self)
    if (not self.unit) then
        return
    end
    DressUpItemTransmogInfoList(C_TransmogCollection.GetInspectItemTransmogInfoList())
    if (DressUpFrame) then
        characterFrame:MoveFrameNextTo(DressUpFrame, self.window)
    end
end

inspect.CreateToggles = function(self, window)
    local y = TOGGLE_FIRST_Y
    local function NextY()
        local current = y
        y = y + TOGGLE_STEP_Y
        return current
    end
    self.toggles = {}

    self.toggles.pvp = edgeToggle:Create(window, {
        icon = [[Interface/Addons/ExalityUI/Assets/Images/Talents/pvp-icon.png]],
        offsetY = NextY(),
        tooltip = PVP or 'PvP',
        iconColor = TOGGLE_COLORS.pvp[1],
        iconHoverColor = TOGGLE_COLORS.pvp[2],
        onClick = function()
            inspect:ShowPanel('pvp')
        end,
    })

    self.toggles.guild = edgeToggle:Create(window, {
        icon = EXUI.const.textures.characterFrame.users,
        offsetY = NextY(),
        tooltip = GUILD or 'Guild',
        iconColor = TOGGLE_COLORS.guild[1],
        iconHoverColor = TOGGLE_COLORS.guild[2],
        onClick = function()
            inspect:ShowPanel('guild')
        end,
    })

    if (EXUI.IsForever()) then
        return
    end

    self.toggles.dressUp = edgeToggle:Create(window, {
        icon = [[Interface/Addons/ExalityUI/Assets/Images/Icons/eye.png]],
        offsetY = NextY(),
        tooltip = VIEW_IN_DRESSUP_FRAME or 'View in Dressing Room',
        iconColor = TOGGLE_COLORS.dressUp[1],
        iconHoverColor = TOGGLE_COLORS.dressUp[2],
        onClick = function()
            inspect:OpenDressUp()
        end,
    })

    self.toggles.talents = edgeToggle:Create(window, {
        atlas = {
            normal = 'UI-HUD-MicroMenu-SpecTalents-Up',
            hover = 'UI-HUD-MicroMenu-SpecTalents-Mouseover',
            disabled = 'UI-HUD-MicroMenu-SpecTalents-Disabled',
        },
        iconSize = 20,
        iconHeight = 26,
        offsetY = NextY(),
        tooltip = INSPECT_TALENTS_BUTTON or 'Talents',
        onClick = function()
            inspect:OpenTalents()
        end,
        onEnter = function(btn)
            GameTooltip:SetOwner(btn, 'ANCHOR_RIGHT')
            GameTooltip:SetText(INSPECT_TALENTS_BUTTON or 'Talents')
            if (not C_Traits.HasValidInspectData()) then
                GameTooltip_AddErrorLine(GameTooltip, UNAVAILABLE)
            elseif (InCombatLockdown()) then
                GameTooltip_AddErrorLine(GameTooltip, ERR_NOT_IN_COMBAT)
            end
            GameTooltip:Show()
        end,
    })
end

inspect.UpdateToggles = function(self)
    if (not self.toggles or not self.unit) then
        return
    end
    for id, button in pairs(self.toggles) do
        if (self.panels[id]) then
            button.iconColor = self.activePanel == id and TOGGLE_COLORS[id][2] or TOGGLE_COLORS[id][1]
        end
    end

    local hasGuild = GuildInfo(self.unit) ~= nil
    local guild = self.toggles.guild
    guild.edgeHidden = not hasGuild
    if (not hasGuild) then
        guild.stopWindowAnims()
        guild:Hide()
        if (self.activePanel == 'guild') then
            self:HidePanel()
            return
        end
    elseif (self.window:IsShown() and not guild:IsShown()) then
        guild:SetAlpha(1)
        guild:Show()
    end

    local talents = self.toggles.talents
    if (talents) then
        talents:SetEnabled(C_Traits.HasValidInspectData())
    end

    for _, button in pairs(self.toggles) do
        edgeToggle:ApplyVisual(button, button:IsMouseOver())
    end
end

---------------- Window ----------------

inspect.CreateToBlizzIcon = function(self, window)
    local button = CreateFrame('Button', nil, window)
    button:SetSize(38, 28)

    local texture = button:CreateTexture(nil, 'BACKGROUND')
    texture:SetTexture(EXUI.const.textures.frame.inputs.buttonBg)
    texture:SetTextureSliceMargins(20, 20, 20, 20)
    texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    texture:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
    texture:SetAllPoints()

    local icon = button:CreateTexture(nil, 'OVERLAY')
    icon:SetTexture(EXUI.const.textures.characterFrame.toBlizzIcon)
    icon:SetPoint('CENTER')
    icon:SetSize(17, 12)

    button:SetScript('OnClick', function()
        inspect:OpenDefault()
    end)
    button.Tooltip = tooltip:Get({
        text = 'Open Default Inspect Frame'
    }, button)
    button:SetScript('OnEnter', function(self)
        texture:SetVertexColor(60 / 255, 60 / 255, 60 / 255, 1)
        self.Tooltip:ShowTooltip()
    end)
    button:SetScript('OnLeave', function(self)
        texture:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
        self.Tooltip:HideTooltip()
    end)
    return button
end

inspect.AddSlots = function(self, slots, parent, side)
    local prev
    for index, slotId in ipairs(slots) do
        local slot = inspectSlot:Create(slotId, side, index, parent)
        if (side == 'BOTTOM') then
            if (prev) then
                slot:SetPoint('LEFT', prev, 'RIGHT', SLOT_GAP, 0)
            else
                slot:SetPoint('LEFT', parent, 'LEFT', 0, 0)
            end
        elseif (prev) then
            slot:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -SLOT_GAP)
        else
            slot:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
        end
        table.insert(self.slots, slot)
        prev = slot
    end
end

inspect.Create = function(self)
    local theme = EXUI.const.theme
    local window = windowConstruct:Create({
        name = 'ExalityUIInspectFrame',
        size = { 510, 470 },
        title = '',
        legacyChrome = {
            hideHeaderBar = true,
            close = {
                width = 38,
                height = 28,
                inset = { 8, 5 },
                buttonBg = EXUI.const.textures.characterFrame.input.buttonBg,
                closeIcon = EXUI.const.textures.frame.closeIcon,
                iconSize = 14,
                normalColor = theme.faded,
                hoverColor = theme.dangerHover,
            },
        },
    })
    self.window = window

    local cornerMask = window:CreateMaskTexture()
    cornerMask:SetAllPoints()
    cornerMask:SetTexture(WINDOW_BG, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    cornerMask:SetTextureSliceMargins(WINDOW_CORNER, WINDOW_CORNER, WINDOW_CORNER, WINDOW_CORNER)
    cornerMask:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)

    local backing = window:CreateTexture(nil, 'BACKGROUND', nil, 0)
    backing:SetAllPoints()
    backing:SetColorTexture(unpack(theme.backgroundDeep))
    backing:AddMaskTexture(cornerMask)
    backing:Hide()
    self.backgroundBacking = backing

    local background = window:CreateTexture(nil, 'BACKGROUND', nil, 1)
    background:SetAllPoints()
    background:AddMaskTexture(cornerMask)
    background:Hide()
    self.background = background
    window:HookScript('OnSizeChanged', function()
        characterFrame:FitAtlas(inspect.background, inspect.backgroundAtlas)
    end)

    local container = window.container
    local escapeHandler = CreateFrame('Button', nil, container)
    escapeHandler:SetScript('OnKeyDown', function(handler, key)
        if (InCombatLockdown()) then
            return
        end
        if (key == 'ESCAPE') then
            handler:SetPropagateKeyboardInput(false)
            window:HideWindow()
            return
        end
        handler:SetPropagateKeyboardInput(true)
    end)
    self.escapeHandler = escapeHandler

    -- Header --
    local headerFrame = CreateFrame('Frame', nil, container)
    headerFrame:SetHeight(30)
    headerFrame:SetPoint('TOPLEFT', 0, 20)
    headerFrame:SetPoint('TOPRIGHT', 0, 20)
    window.Header = headerFrame

    local levelText = headerFrame:CreateFontString(nil, 'OVERLAY')
    headerFrame.LevelText = levelText
    levelText:SetFont(EXUI.const.fonts.DEFAULT, 24, 'OUTLINE')
    levelText:SetPoint('TOPLEFT')

    local classSpecText = headerFrame:CreateFontString(nil, 'OVERLAY')
    headerFrame.ClassSpecText = classSpecText
    classSpecText:SetFont(EXUI.const.fonts.DEFAULT, 14, 'OUTLINE')
    classSpecText:SetPoint('BOTTOMLEFT', levelText, 'BOTTOMRIGHT', 5, 2)

    local separator = headerFrame:CreateTexture(nil, 'OVERLAY')
    headerFrame.Separator = separator
    separator:SetTexture(EXUI.const.textures.characterFrame.dot)
    separator:SetSize(4, 4)
    separator:SetPoint('CENTER', classSpecText, 'RIGHT', 10, 0)

    local ilvl = headerFrame:CreateFontString(nil, 'OVERLAY')
    headerFrame.Ilvl = ilvl
    ilvl:SetFont(EXUI.const.fonts.DEFAULT, 14, 'OUTLINE')
    ilvl:SetPoint('LEFT', separator, 'RIGHT', 10, 0)

    -- Gear Slots --
    local leftSlots = CreateFrame('Frame', nil, container)
    leftSlots:SetSize(38, 350)
    leftSlots:SetPoint('TOPLEFT', headerFrame, 'BOTTOMLEFT', 0, -10)

    local modelFrame = CreateFrame('Frame', nil, container)
    modelFrame:SetSize(380, 334)
    modelFrame:SetPoint('TOPLEFT', leftSlots, 'TOPRIGHT', 10, 0)

    local glow = modelFrame:CreateTexture(nil, 'OVERLAY')
    glow:SetTexture(EXUI.const.textures.characterFrame.characterGlow)
    glow:SetSize(250, 350)
    glow:SetPoint('CENTER')
    glow:SetAlpha(0.5)
    window.CharacterGlow = glow

    local factionLogo = modelFrame:CreateTexture(nil, 'ARTWORK')
    factionLogo:SetSize(180, 180)
    factionLogo:SetPoint('CENTER')
    factionLogo:Hide()
    window.FactionLogo = factionLogo

    local model = CreateFrame('PlayerModel', nil, modelFrame)
    model:SetAllPoints()
    window.CharacterModel = model
    characterFrame:SetupRotatingModel(model, window)

    local rightSlots = CreateFrame('Frame', nil, container)
    rightSlots:SetSize(38, 350)
    rightSlots:SetPoint('TOPLEFT', modelFrame, 'TOPRIGHT', 10, 0)

    local bottomIds = BottomSlotIds()
    local bottomSlots = CreateFrame('Frame', nil, container)
    bottomSlots:SetSize(#bottomIds * SLOT_SIZE + (#bottomIds - 1) * SLOT_GAP, SLOT_SIZE)
    bottomSlots:SetPoint('TOP', modelFrame, 'BOTTOM', 0, 0)

    self.slots = {}
    self:AddSlots(LEFT_SLOTS, leftSlots, 'LEFT')
    self:AddSlots(RIGHT_SLOTS, rightSlots, 'RIGHT')
    self:AddSlots(bottomIds, bottomSlots, 'BOTTOM')

    window:Configure({
        staticAnchor = { 'TOPLEFT', UIParent, 'TOPLEFT', 20, -150 },
        titleSize = 14,
        disableLogoAndVersion = true,
        disableResize = true,
    })

    container:ClearAllPoints()
    container:SetPoint('TOPLEFT', 15, -42)
    container:SetPoint('BOTTOMRIGHT', -15, 15)

    window.title:ClearAllPoints()
    window.title:SetPoint('CENTER', window, 'TOP', 0, 0)

    self.panels = {
        pvp = self:CreatePvpPanel(window),
        guild = self:CreateGuildPanel(window),
    }
    self:CreateToggles(window)

    local toBlizzIcon = self:CreateToBlizzIcon(window)
    toBlizzIcon:SetPoint('TOPRIGHT', window.close, 'TOPLEFT', -5, 0)

    local events = CreateFrame('Frame', nil, window)
    events:SetScript('OnEvent', function(_, event, ...)
        inspect:OnUnitEvent(event, ...)
    end)
    self.events = events

    window:HookScript('OnShow', function()
        inspect:RegisterUnitEvents()
        if (not InCombatLockdown()) then
            escapeHandler:SetPropagateKeyboardInput(true)
            escapeHandler:EnableKeyboard(true)
        end
    end)
    window:HookScript('OnHide', function()
        inspect:OnWindowHidden()
    end)
    window:Hide()
end

inspect.RegisterUnitEvents = function(self)
    local events = self.events
    events:UnregisterAllEvents()
    if (not self.unit) then
        return
    end
    events:RegisterUnitEvent('UNIT_INVENTORY_CHANGED', self.unit)
    events:RegisterUnitEvent('UNIT_MODEL_CHANGED', self.unit)
    events:RegisterUnitEvent('UNIT_LEVEL', self.unit)
    events:RegisterUnitEvent('UNIT_NAME_UPDATE', self.unit)
    events:RegisterEvent('INSPECT_HONOR_UPDATE')
    events:RegisterEvent('PLAYER_TARGET_CHANGED')
    events:RegisterEvent('GROUP_ROSTER_UPDATE')
end

inspect.OnUnitEvent = function(self, event)
    if (event == 'UNIT_INVENTORY_CHANGED') then
        self.retryCount = 0
        self:UpdateSlots()
        self:UpdateHeader()
    elseif (event == 'UNIT_MODEL_CHANGED') then
        self:UpdateModel()
    elseif (event == 'UNIT_LEVEL' or event == 'UNIT_NAME_UPDATE') then
        self:UpdateHeader()
    elseif (event == 'INSPECT_HONOR_UPDATE') then
        self:UpdatePvpPanel()
    elseif (event == 'PLAYER_TARGET_CHANGED' and self.unit == 'target') or
        (event == 'GROUP_ROSTER_UPDATE' and self.unit ~= 'target') then
        self.window:HideWindow()
    end
end

inspect.OnWindowHidden = function(self)
    self:CancelRetry()
    self.events:UnregisterAllEvents()
    self:HidePanel()
    if (not InCombatLockdown()) then
        self.escapeHandler:EnableKeyboard(false)
    end
    if (not self.blizzardOverride and not talentsWindow:IsInspecting() and
            not (PlayerSpellsFrame and PlayerSpellsFrame:IsInspecting())) then
        ClearInspectPlayer()
    end
    self.unit = nil
end

inspect.Refresh = function(self)
    self.retryCount = 0
    self:UpdateHeader()
    self:UpdateSlots()
    self:UpdateModel()
    self:UpdatePanels()
    self:UpdateToggles()
end

inspect.Show = function(self, unit)
    if (not self.isCreated) then
        self:Create()
        self.isCreated = true
    end
    local changed = self.unit ~= unit
    self.unit = unit
    self:UpdateToggles()
    if (not self.window:IsShown()) then
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        self.window:ShowWindow()
    elseif (changed) then
        self:RegisterUnitEvents()
    end
    self:Refresh()
end

inspect.IsShown = function(self)
    return self.window ~= nil and self.window:IsShown()
end

inspect.OpenDefault = function(self)
    local unit = self.unit
    if (not unit or not InspectFrame) then
        return
    end
    self.blizzardOverride = true
    self.window:HideWindow()
    InspectFrame:RegisterEvent('INSPECT_READY')
    InspectUnit(unit)
end

---------------- Blizzard interception ----------------

inspect.OnInspectReady = function(self, guid)
    if (self.blizzardOverride) then
        return
    end
    if (self.pendingUnit and UnitGUID(self.pendingUnit) == guid) then
        local unit = self.pendingUnit
        self.pendingUnit = nil
        self:Show(unit)
        return
    end
    if (self:IsShown() and self.unit and UnitGUID(self.unit) == guid) then
        self:Refresh()
    end
end

inspect.Attach = function(self)
    if (not InspectFrame) then
        return
    end
    if (not self.isAttached) then
        self.isAttached = true
        hooksecurefunc('InspectFrame_Show', function(unit)
            if (not inspect.enabled) then
                return
            end
            if (inspect.blizzardOverride) then
                if (not CanInspect(unit, true)) then
                    inspect.blizzardOverride = false
                    InspectFrame:UnregisterEvent('INSPECT_READY')
                end
                return
            end
            inspect.pendingUnit = CanInspect(unit, true) and unit or nil
        end)
        InspectFrame:HookScript('OnHide', function()
            if (not inspect.blizzardOverride) then
                return
            end
            inspect.blizzardOverride = false
            if (inspect.enabled) then
                InspectFrame:UnregisterEvent('INSPECT_READY')
            end
        end)
    end
    InspectFrame:UnregisterEvent('INSPECT_READY')
end

inspect.HookDressUp = function(self)
    if (self.dressUpHooked or not DressUpFrame) then
        return
    end
    self.dressUpHooked = true
    DressUpFrame:HookScript('OnShow', function(frame)
        if (inspect.enabled and inspect:IsShown()) then
            characterFrame:MoveFrameNextTo(frame, inspect.window)
        end
    end)
end

inspect.Enable = function(self)
    self.enabled = true
    self:HookDressUp()
    EXUI:RegisterEventHandler('INSPECT_READY', 'character-frame-inspect', function(_, guid)
        inspect:OnInspectReady(guid)
    end)
    if (InspectFrame) then
        self:Attach()
        return
    end
    EXUI:RegisterEventHandler('ADDON_LOADED', 'character-frame-inspect', function(_, addonName)
        if (addonName == 'Blizzard_InspectUI') then
            EXUI:UnregisterEventHandler('ADDON_LOADED', 'character-frame-inspect')
            inspect:Attach()
        end
    end)
end

inspect.Disable = function(self)
    self.enabled = false
    self.pendingUnit = nil
    EXUI:UnregisterEventHandler('INSPECT_READY', 'character-frame-inspect')
    EXUI:UnregisterEventHandler('ADDON_LOADED', 'character-frame-inspect')
    if (InspectFrame and self.isAttached) then
        InspectFrame:RegisterEvent('INSPECT_READY')
    end
    if (self:IsShown()) then
        self.window:HideWindow()
    end
end
