---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

local data = EXUI:GetModule('data')

---@class EXUIPVEFrameSearchEntrySkin
local searchEntrySkin = EXUI:GetModule('skin-PVEFrame-searchEntry')

---@class EXUIPVEFrameFiltersSkin
local filters = EXUI:GetModule('skin-PVEFrame-filters')

local PANEL_WIDTH = 240
local PANEL_GAP = 6
local TITLE_HEIGHT = 28
local CONTENT_PAD = 10
local CONTENT_WIDTH = PANEL_WIDTH - CONTENT_PAD * 2 - 12
local FOOTER_HEIGHT = 24
local ROW_HEIGHT = 20
local ROW_GAP = 4
local SECTION_GAP = 8
local SECTION_TITLE_SIZE = 12
local NUMBER_BOX_HEIGHT = 34
local ANIM_DURATION = 0.18

local BUTTON_SIZE = 24
local BUTTON_ICON_SIZE = 18
local BUTTON_ICON_ALPHA = 0.8
local BUTTON_DOT_SIZE = 6

local RAID_CATEGORY_ID = 3
local SETTINGS_KEY = 'lfgFilters'

local ROLES = { 'TANK', 'HEALER', 'DAMAGER' }
local ROLE_NAMES = { TANK = TANK, HEALER = HEALER, DAMAGER = DAMAGER }

local RAID_DIFFICULTIES = {
    { key = 'normal', label = PLAYER_DIFFICULTY1, field = 'isNormalActivity' },
    { key = 'heroic', label = PLAYER_DIFFICULTY2, field = 'isHeroicActivity' },
    { key = 'mythic', label = PLAYER_DIFFICULTY6, field = 'isMythicActivity' },
}

local DUNGEON_DIFFICULTIES = {
    { key = 'difficultyNormal', label = PLAYER_DIFFICULTY1 },
    { key = 'difficultyHeroic', label = PLAYER_DIFFICULTY2 },
    { key = 'difficultyMythic', label = PLAYER_DIFFICULTY6 },
    { key = 'difficultyMythicPlus', label = PLAYER_DIFFICULTY_MYTHIC_PLUS },
}

local PLAYSTYLES = {
    { key = 'generalPlaystyle1', label = GROUP_FINDER_GENERAL_PLAYSTYLE1 },
    { key = 'generalPlaystyle2', label = GROUP_FINDER_GENERAL_PLAYSTYLE2 },
    { key = 'generalPlaystyle3', label = GROUP_FINDER_GENERAL_PLAYSTYLE3 },
    { key = 'generalPlaystyle4', label = GROUP_FINDER_GENERAL_PLAYSTYLE4 },
}

local REQUIRE_FLAGS = { 'needsTank', 'needsHealer', 'needsDamage', 'needsMyClass', 'hasTank', 'hasHealer' }

filters.panel = nil
filters.button = nil
filters.isOpen = false
filters.widgets = {}

local function GetTheme()
    return EXUI.const.theme
end

local function IsChatLockdown()
    return C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
end

local function GetSearchPanel()
    return LFGListFrame and LFGListFrame.SearchPanel
end

local function GetContext()
    local panel = GetSearchPanel()
    local categoryID = panel and panel.categoryID
    if (categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then return 'dungeon' end
    if (categoryID == RAID_CATEGORY_ID) then return 'raid' end
    return 'other'
end

local function CanChangeLanguages()
    return LFGListCanChangeLanguages and LFGListCanChangeLanguages()
end

local function IsAdvancedFilterAvailable()
    return C_LFGList.GetAdvancedFilter and GameRulesUtil and GameRulesUtil.IsPlayerAtEffectiveMaxLevel()
end

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

local function GetSettings()
    local db = data:GetDataByKey(SETTINGS_KEY)
    db.dungeon = db.dungeon or {}
    db.dungeon.roles = db.dungeon.roles or {}
    db.raid = db.raid or {}
    db.raid.roles = db.raid.roles or {}
    db.raid.excluded = db.raid.excluded or {}
    db.raid.difficultyExcluded = db.raid.difficultyExcluded or {}
    return db
end

local function SaveSettings(db)
    data:SetDataByKey(SETTINGS_KEY, db)
end

local function HasRoleLimits(roles)
    for _, role in ipairs(ROLES) do
        local limit = roles[role]
        if (limit and (limit.min or limit.max)) then return true end
    end
    return false
end

local function IsPostFilterActive(context, db)
    db = db or GetSettings()
    if (context == 'dungeon') then
        return HasRoleLimits(db.dungeon.roles)
    elseif (context == 'raid') then
        return HasRoleLimits(db.raid.roles) or next(db.raid.excluded) ~= nil
            or next(db.raid.difficultyExcluded) ~= nil
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Blizzard advanced filter (mirrors LFGListSearchPanel_SetupAdvancedFilter)
-- ---------------------------------------------------------------------------

local function GetDungeonActivityGroups()
    local function Groups(flags)
        return C_LFGList.GetAvailableActivityGroups(GROUP_FINDER_CATEGORY_ID_DUNGEONS, bit.bor(flags, Enum.LFGListFilter.PvE))
    end

    local groups = {}
    tAppendAll(groups, Groups(Enum.LFGListFilter.CurrentSeason))
    tAppendAll(groups, Groups(bit.bor(Enum.LFGListFilter.CurrentExpansion, Enum.LFGListFilter.NotCurrentSeason)))
    if (PlayerIsTimerunning and PlayerIsTimerunning()) then
        tAppendAll(groups, Groups(Enum.LFGListFilter.Timerunning))
    end
    return groups
end

local function NoneChecked(enabled, list)
    for _, entry in ipairs(list) do
        if (enabled[entry.key]) then return false end
    end
    return true
end

local function AllOrNone(enabled, list)
    local checked = 0
    for _, entry in ipairs(list) do
        if (enabled[entry.key]) then checked = checked + 1 end
    end
    return checked == 0 or checked == #list
end

local function IsAdvancedFilterDefault()
    if (not IsAdvancedFilterAvailable()) then return true end

    local enabled = C_LFGList.GetAdvancedFilter()
    for _, key in ipairs(REQUIRE_FLAGS) do
        if (enabled[key]) then return false end
    end
    if (enabled.minimumRating ~= 0) then return false end

    local activities = #enabled.activities
    if (activities ~= 0 and activities ~= #GetDungeonActivityGroups()) then return false end

    return AllOrNone(enabled, DUNGEON_DIFFICULTIES) and AllOrNone(enabled, PLAYSTYLES)
end

local function RefreshEntries()
    local panel = GetSearchPanel()
    if (panel and panel.ScrollBox) then
        panel.ScrollBox:ForEachFrame(LFGListSearchEntry_Update)
    end
end

local function ResetAdvancedFilter()
    local enabled = C_LFGList.GetAdvancedFilter()
    for _, key in ipairs(REQUIRE_FLAGS) do
        enabled[key] = false
    end
    enabled.minimumRating = 0
    for _, entry in ipairs(DUNGEON_DIFFICULTIES) do
        enabled[entry.key] = true
    end
    for _, entry in ipairs(PLAYSTYLES) do
        enabled[entry.key] = true
    end
    enabled.activities = GetDungeonActivityGroups()
    C_LFGList.SaveAdvancedFilter(enabled)
end

-- ---------------------------------------------------------------------------
-- Post filter
-- ---------------------------------------------------------------------------

local function PassesRoles(resultID, roles)
    local counts = C_LFGList.GetSearchResultMemberCounts(resultID)
    if (not counts) then return true end

    for _, role in ipairs(ROLES) do
        local limit = roles[role]
        local count = counts[role] or 0
        if (limit and ((limit.min and count < limit.min) or (limit.max and count > limit.max))) then
            return false
        end
    end
    return true
end

local function PassesRaid(resultID, raid)
    local info = C_LFGList.GetSearchResultInfo(resultID)
    local activityID = info and info.activityIDs and info.activityIDs[1]
    local activity = activityID and C_LFGList.GetActivityInfoTable(activityID)
    if (not activity) then return true end

    if (raid.excluded[activity.groupFinderActivityGroupID]) then return false end
    for _, difficulty in ipairs(RAID_DIFFICULTIES) do
        if (raid.difficultyExcluded[difficulty.key] and activity[difficulty.field]) then return false end
    end
    return true
end

local function FilterResults(panel)
    if (panel ~= GetSearchPanel() or not panel.results) then return end

    local context = GetContext()
    local db = GetSettings()
    if (not IsPostFilterActive(context, db) or IsChatLockdown()) then return end

    local settings = db[context]
    local results = panel.results
    local removed = false
    for i = #results, 1, -1 do
        local resultID = results[i]
        if (not PassesRoles(resultID, settings.roles) or (context == 'raid' and not PassesRaid(resultID, settings))) then
            table.remove(results, i)
            removed = true
        end
    end

    if (removed) then
        panel.totalResults = #results
    end
end

local function ReapplyPostFilter()
    local panel = GetSearchPanel()
    if (panel and panel:IsShown() and not panel.searching) then
        LFGListSearchPanel_UpdateResultList(panel)
    end
end

-- ---------------------------------------------------------------------------
-- Panel content
-- ---------------------------------------------------------------------------

local function Track(widget, cleanup)
    filters.widgets[#filters.widgets + 1] = { widget = widget, cleanup = cleanup }
end

local function ReleaseWidgets()
    for _, entry in ipairs(filters.widgets) do
        if (entry.cleanup) then entry.cleanup(entry.widget) end
        entry.widget:Destroy()
    end
    wipe(filters.widgets)
end

local function Place(builder, frame, height, gap)
    frame:ClearAllPoints()
    frame:SetPoint('TOPLEFT', builder.parent, 'TOPLEFT', 0, -builder.y)
    frame:SetWidth(builder.width)
    frame:SetHeight(height)
    builder.y = builder.y + height + (gap or ROW_GAP)
end

local function AddSection(builder, label)
    if (builder.y > 0) then
        builder.y = builder.y + SECTION_GAP
    end

    local title = EXFrames:GetFrame('title'):Create(builder.parent)
    title:SetOptionData({ label = label, size = SECTION_TITLE_SIZE })
    Track(title)
    Place(builder, title, title:GetHeight())
end

local function AddCheckbox(builder, label, isChecked, onToggle)
    local checkbox = EXFrames:GetFrame('checkbox'):Create(builder.parent)
    checkbox:SetLabel(label)
    checkbox.onChange = nil
    checkbox.suppressOnChange = true
    checkbox:SetValue('value', isChecked and true or false)
    checkbox.suppressOnChange = false
    checkbox.onChange = onToggle
    Track(checkbox)
    Place(builder, checkbox, ROW_HEIGHT)
    return checkbox
end

local function ResetNumberBox(box)
    box.editBox:SetNumeric(false)
    box.editBox:SetMaxLetters(0)
    box.editBox.onFocusLost = nil
    box.editBox:SetScript('OnEnterPressed', nil)
end

local function CreateNumberBox(builder, label, value, onCommit)
    local box = EXFrames:GetFrame('edit-box-input'):Create(builder.parent, {})
    box:SetLabel(label)
    box.onChange = nil
    box.editBox:SetNumeric(true)
    box.editBox:SetMaxLetters(4)
    box:SetEditorValue(value and tostring(value) or '')
    box.editBox.onFocusLost = function(text)
        onCommit(tonumber(text))
    end
    box.editBox:SetScript('OnEnterPressed', function(self) self:ClearFocus() end)
    Track(box, ResetNumberBox)
    return box
end

local function AddButtonPair(builder, leftLabel, onLeft, rightLabel, onRight)
    local half = (builder.width - ROW_GAP) / 2
    for i, def in ipairs({ { leftLabel, onLeft }, { rightLabel, onRight } }) do
        local button = EXFrames:GetFrame('simple-button'):Create(builder.parent)
        button:SetText(def[1])
        button:SetSize(half, ROW_HEIGHT + 2)
        button:SetOnClick(def[2])
        button:ClearAllPoints()
        button:SetPoint('TOPLEFT', builder.parent, 'TOPLEFT', (i - 1) * (half + ROW_GAP), -builder.y)
        Track(button)
    end
    builder.y = builder.y + ROW_HEIGHT + 2 + ROW_GAP
end

local function AddRoleLimits(builder, contextKey)
    AddSection(builder, 'Roles in Group')

    local half = (builder.width - ROW_GAP * 2) / 2
    for _, role in ipairs(ROLES) do
        local db = GetSettings()
        local limit = db[contextKey].roles[role] or {}
        for i, bound in ipairs({ 'min', 'max' }) do
            local box = CreateNumberBox(builder, string.format('%s %s', ROLE_NAMES[role], bound), limit[bound],
                function(value)
                    local current = GetSettings()
                    local roleLimit = current[contextKey].roles[role] or {}
                    if (roleLimit[bound] == value) then return end
                    roleLimit[bound] = value
                    current[contextKey].roles[role] = (roleLimit.min or roleLimit.max) and roleLimit or nil
                    SaveSettings(current)
                    filters:OnSettingsChanged(true)
                end)
            box:ClearAllPoints()
            box:SetPoint('TOPLEFT', builder.parent, 'TOPLEFT', (i - 1) * (half + ROW_GAP * 2), -builder.y)
            box:SetSize(half, NUMBER_BOX_HEIGHT)
        end
        builder.y = builder.y + NUMBER_BOX_HEIGHT + ROW_GAP
    end
end

local function AddLanguages(builder)
    if (not CanChangeLanguages()) then return end

    local enabled = C_LFGList.GetLanguageSearchFilter()
    local defaults = C_LFGList.GetDefaultLanguageSearchFilter()
    local added = false
    for _, lang in ipairs(C_LFGList.GetAvailableLanguageSearchFilter()) do
        if (not defaults[lang]) then
            if (not added) then
                AddSection(builder, LANGUAGES_LABEL)
                added = true
            end
            AddCheckbox(builder, _G['LFG_LIST_LANGUAGE_' .. string.upper(lang)] or lang, enabled[lang], function(value)
                enabled[lang] = value
                C_LFGList.SaveLanguageSearchFilter(enabled)
                filters:OnSettingsChanged(false)
            end)
        end
    end
end

local function BuildAdvancedFilter(builder)
    local enabled = C_LFGList.GetAdvancedFilter()

    local function Save()
        C_LFGList.SaveAdvancedFilter(enabled)
        RefreshEntries()
        filters:OnSettingsChanged(false)
    end

    local function AddFlag(label, key, forceChecked)
        if (forceChecked) then enabled[key] = true end
        AddCheckbox(builder, label, enabled[key], function(value)
            enabled[key] = value
            Save()
        end)
    end

    AddSection(builder, LFG_LIST_REQUIRE)
    local availTank, availHealer, availDPS = C_LFGList.GetAvailableRoles()
    if (availTank) then AddFlag(LFG_LIST_NEEDS_TANK, 'needsTank') end
    if (availHealer) then AddFlag(LFG_LIST_NEEDS_HEALER, 'needsHealer') end
    if (availDPS) then AddFlag(LFG_LIST_NEEDS_DAMAGE, 'needsDamage') end
    AddFlag(string.format(LFG_LIST_CLASS_AVAILABLE, PlayerUtil.GetClassName()), 'needsMyClass')
    AddFlag(LFG_LIST_HAS_TANK, 'hasTank')
    AddFlag(LFG_LIST_HAS_HEALER, 'hasHealer')

    AddSection(builder, DUNGEONS)
    local groups = GetDungeonActivityGroups()
    local activitySet = {}
    if (#enabled.activities == 0) then
        for _, groupID in ipairs(groups) do activitySet[groupID] = true end
    else
        for _, groupID in ipairs(enabled.activities) do activitySet[groupID] = true end
    end

    local function SaveActivities()
        enabled.activities = {}
        for groupID, checked in pairs(activitySet) do
            if (checked) then table.insert(enabled.activities, groupID) end
        end
        Save()
    end

    local activityBoxes = {}
    local function SetAllActivities(checked)
        for _, groupID in ipairs(groups) do
            activitySet[groupID] = checked or nil
        end
        for _, checkbox in pairs(activityBoxes) do
            checkbox.suppressOnChange = true
            checkbox:SetValue('value', checked)
            checkbox.suppressOnChange = false
        end
        SaveActivities()
    end

    AddButtonPair(builder, CHECK_ALL, function() SetAllActivities(true) end,
        UNCHECK_ALL, function() SetAllActivities(false) end)

    for _, groupID in ipairs(groups) do
        local name = C_LFGList.GetActivityGroupInfo(groupID)
        if (name) then
            activityBoxes[groupID] = AddCheckbox(builder, name, activitySet[groupID], function(value)
                activitySet[groupID] = value
                SaveActivities()
            end)
        end
    end

    AddSection(builder, LFG_LIST_MINIMUM_RATING)
    local ratingBox = CreateNumberBox(builder, '', enabled.minimumRating > 0 and enabled.minimumRating or nil,
        function(value)
            value = value or 0
            if (enabled.minimumRating == value) then return end
            enabled.minimumRating = value
            Save()
        end)
    Place(builder, ratingBox, NUMBER_BOX_HEIGHT)

    AddSection(builder, LFG_LIST_DIFFICULTY)
    local noneChecked = NoneChecked(enabled, DUNGEON_DIFFICULTIES)
    for _, entry in ipairs(DUNGEON_DIFFICULTIES) do
        AddFlag(entry.label, entry.key, noneChecked)
    end

    AddSection(builder, GROUP_FINDER_FILTER_PLAYSTYLE)
    noneChecked = NoneChecked(enabled, PLAYSTYLES)
    for _, entry in ipairs(PLAYSTYLES) do
        AddFlag(entry.label, entry.key, noneChecked)
    end
end

local function BuildRaidFilter(builder)
    local panel = GetSearchPanel()
    local groups = C_LFGList.GetAvailableActivityGroups(RAID_CATEGORY_ID, panel and panel.filters or 0)

    local function Toggle(field, key, included)
        local db = GetSettings()
        db.raid[field][key] = (not included) or nil
        SaveSettings(db)
        filters:OnSettingsChanged(true)
    end

    local db = GetSettings()
    if (groups and #groups > 0) then
        AddSection(builder, RAIDS)
        for _, groupID in ipairs(groups) do
            local name = C_LFGList.GetActivityGroupInfo(groupID)
            if (name) then
                AddCheckbox(builder, name, not db.raid.excluded[groupID], function(value)
                    Toggle('excluded', groupID, value)
                end)
            end
        end
    end

    AddSection(builder, LFG_LIST_DIFFICULTY)
    for _, difficulty in ipairs(RAID_DIFFICULTIES) do
        AddCheckbox(builder, difficulty.label, not db.raid.difficultyExcluded[difficulty.key], function(value)
            Toggle('difficultyExcluded', difficulty.key, value)
        end)
    end
end

function filters:Rebuild()
    if (not self.panel) then return end
    ReleaseWidgets()

    local context = GetContext()
    local builder = { parent = self.scrollChild, width = CONTENT_WIDTH, y = 0 }

    if (context == 'dungeon') then
        if (IsAdvancedFilterAvailable()) then
            BuildAdvancedFilter(builder)
        end
        AddRoleLimits(builder, 'dungeon')
    elseif (context == 'raid') then
        BuildRaidFilter(builder)
        AddRoleLimits(builder, 'raid')
    end
    AddLanguages(builder)

    local panel = GetSearchPanel()
    local categoryInfo = panel and panel.categoryID and C_LFGList.GetLfgCategoryInfo(panel.categoryID)
    self.panel.Title:SetText(categoryInfo and string.format('%s: %s', FILTERS, categoryInfo.name) or FILTERS)
    self.panel.Reset:SetShown(context ~= 'other')

    self.scrollChild:SetHeight(math.max(1, builder.y))
    self.scrollFrame:UpdateScrollChild(CONTENT_WIDTH, builder.y)
end

function filters:Reset()
    local context = GetContext()
    local db = GetSettings()
    if (context == 'dungeon') then
        wipe(db.dungeon.roles)
        if (IsAdvancedFilterAvailable()) then
            ResetAdvancedFilter()
        end
    elseif (context == 'raid') then
        wipe(db.raid.roles)
        wipe(db.raid.excluded)
        wipe(db.raid.difficultyExcluded)
    end
    SaveSettings(db)

    local panel = GetSearchPanel()
    if (context == 'dungeon' and panel) then
        LFGListSearchPanel_DoSearch(panel)
    else
        ReapplyPostFilter()
    end
    self:Rebuild()
    self:UpdateButton()
end

function filters:OnSettingsChanged(postFilterChanged)
    if (postFilterChanged) then
        ReapplyPostFilter()
    end
    self:UpdateButton()
end

-- ---------------------------------------------------------------------------
-- Panel
-- ---------------------------------------------------------------------------

local function CreateCloseButton(panel)
    local theme = GetTheme()
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

    close:SetScript('OnEnter', function() bg:SetVertexColor(unpack(theme.dangerHover)) end)
    close:SetScript('OnLeave', function() bg:SetVertexColor(unpack(theme.faded)) end)
    close:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        filters:HidePanel()
    end)

    panel.close = close
end

function filters:CreatePanel()
    local theme = GetTheme()
    local panel = CreateFrame('Frame', nil, PVEFrame)
    panel:SetWidth(PANEL_WIDTH)
    panel:SetPoint('TOPLEFT', PVEFrame, 'TOPRIGHT', PANEL_GAP, 0)
    panel:SetPoint('BOTTOMLEFT', PVEFrame, 'BOTTOMRIGHT', PANEL_GAP, 0)
    panel:SetFrameLevel(PVEFrame:GetFrameLevel() + 20)
    panel:EnableMouse(true)
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

    CreateCloseButton(panel)

    local title = panel:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    title:SetPoint('TOPLEFT', CONTENT_PAD, -10)
    title:SetPoint('TOPRIGHT', panel.close, 'TOPLEFT', -6, -2)
    title:SetJustifyH('LEFT')
    title:SetWordWrap(false)
    title:SetTextColor(unpack(theme.text))
    panel.Title = title

    local reset = EXFrames:GetFrame('simple-button'):Create(panel)
    reset:SetText(RESET)
    reset:SetHeight(FOOTER_HEIGHT)
    reset:ClearAllPoints()
    reset:SetPoint('BOTTOMLEFT', CONTENT_PAD, CONTENT_PAD)
    reset:SetPoint('BOTTOMRIGHT', -CONTENT_PAD, CONTENT_PAD)
    reset:SetOnClick(function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        filters:Reset()
    end)
    panel.Reset = reset

    local scrollFrame = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scrollFrame:SetParent(panel)
    scrollFrame:SetPoint('TOPLEFT', CONTENT_PAD, -(TITLE_HEIGHT + 4))
    scrollFrame:SetPoint('BOTTOMRIGHT', -CONTENT_PAD, CONTENT_PAD * 2 + FOOTER_HEIGHT)
    self.scrollFrame = scrollFrame
    self.scrollChild = scrollFrame.child

    panel.fadeIn = EXUI.utils.animation.fade(panel, ANIM_DURATION, 0, 1)
    panel.fadeOut = EXUI.utils.animation.fade(panel, ANIM_DURATION, 1, 0)
    panel.fadeOut:SetScript('OnFinished', function()
        panel:Hide()
        panel:SetAlpha(1)
    end)

    self.panel = panel
end

function filters:ShowPanel()
    if (not self.panel) then self:CreatePanel() end
    self.isOpen = true
    self.panel.fadeOut:Stop()
    self.panel:SetAlpha(0)
    self.panel:Show()
    self:Rebuild()
    self.panel.fadeIn:Play()
end

function filters:HidePanel(immediate)
    if (not self.panel or not self.isOpen) then return end
    self.isOpen = false
    self.panel.fadeIn:Stop()
    if (immediate or not self.panel:IsVisible()) then
        self.panel:Hide()
        self.panel:SetAlpha(1)
        ReleaseWidgets()
        return
    end
    self.panel.fadeOut:Play()
end

function filters:Toggle()
    if (self.isOpen) then
        self:HidePanel()
    else
        self:ShowPanel()
    end
end

-- ---------------------------------------------------------------------------
-- Toolbar button
-- ---------------------------------------------------------------------------

function filters:IsAnyActive(context)
    if (IsPostFilterActive(context)) then return true end
    return context == 'dungeon' and not IsAdvancedFilterDefault()
end

function filters:UpdateButton()
    local button = self.button
    if (not button) then return end

    local context = GetContext()
    local shown = context ~= 'other' or CanChangeLanguages()
    button:SetShown(shown)
    button.Dot:SetShown(shown and self:IsAnyActive(context))
end

function filters:CreateButton(parent)
    if (self.button) then return self.button end

    local button = CreateFrame('Button', nil, parent)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetPoint('CENTER')
    searchEntrySkin.ApplySprite(icon, 'filter')
    searchEntrySkin.SetSpriteHeight(icon, 'filter', BUTTON_ICON_SIZE)
    icon:SetAlpha(BUTTON_ICON_ALPHA)
    button.Icon = icon

    local dot = button:CreateTexture(nil, 'OVERLAY')
    dot:SetTexture(EXUI.const.textures.unitFrames.portraitMaskCircle)
    dot:SetVertexColor(unpack(GetTheme().accent))
    dot:SetSize(BUTTON_DOT_SIZE, BUTTON_DOT_SIZE)
    dot:SetPoint('TOPRIGHT', button, 'TOPRIGHT', 0, 0)
    dot:Hide()
    button.Dot = dot

    button:SetScript('OnEnter', function(self)
        self.Icon:SetAlpha(1)
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetText(FILTERS, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
        GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function(self)
        self.Icon:SetAlpha(BUTTON_ICON_ALPHA)
        GameTooltip:Hide()
    end)
    button:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        filters:Toggle()
    end)

    self.button = button
    self:UpdateButton()
    return button
end

-- ---------------------------------------------------------------------------
-- Hooks
-- ---------------------------------------------------------------------------

function filters:Install()
    if (self.installed or type(LFGListUtil_SortSearchResults) ~= 'function') then return end
    local panel = GetSearchPanel()
    if (not panel) then return end
    self.installed = true

    hooksecurefunc('LFGListUtil_SortSearchResults', FilterResults)

    hooksecurefunc('LFGListSearchPanel_SetCategory', function()
        filters:UpdateButton()
        if (filters.isOpen) then filters:Rebuild() end
    end)

    panel:HookScript('OnShow', function() filters:UpdateButton() end)
    panel:HookScript('OnHide', function() filters:HidePanel(true) end)
end
