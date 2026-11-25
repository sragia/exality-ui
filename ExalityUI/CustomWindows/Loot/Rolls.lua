---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIEditor
local editor = EXUI:GetModule('editor')

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')

---@class EXUILootSprite
local sprite = EXUI:GetModule('loot-sprite')

---@class EXUILootTracker
local tracker = EXUI:GetModule('loot-tracker')

---@class EXUILootItemCard
local itemCard = EXUI:GetModule('loot-item-card')

---@class EXUILootWindow
local lootWindow = EXUI:GetModule('loot-window')

---@class EXUILootRolls
local lootRolls = EXUI:GetModule('loot-rolls')

lootRolls.enabled = false
lootRolls.isPreview = false
lootRolls.anchor = nil
lootRolls.entries = {}
lootRolls.entryPool = {}
lootRolls.hiddenParent = nil

local FONT = EXUI.const.fonts.DEFAULT
local TAB_WIDTH, TAB_HEIGHT = sprite:GetBodySize('tabBg')
local PASS_SIZE = sprite:GetBodySize('passBg')
local PASS_GAP = 0
local TAB_GAP = 12
local SPACING = 10
local ENTRY_WIDTH = itemCard.width + PASS_GAP + PASS_SIZE
local ENTRY_HEIGHT = itemCard.height + TAB_HEIGHT
local FADE_DURATION = 0.2
local UPDATE_INTERVAL = 0.1
local DISABLED_ALPHA = 0.35

local ROLL_TYPES = {
    need = 1,
    greed = 2,
    transmog = 4,
    pass = 0,
}

local TABS = {
    { state = 'need', label = 'Need', atlas = 'lootroll-toast-icon-need-up', color = { 0.42, 0.75, 0.17 } },
    { state = 'greed', label = 'Greed', atlas = 'lootroll-toast-icon-greed-up', color = { 0.92, 0.72, 0.12 } },
    { state = 'transmog', label = 'Mog', atlas = 'lootroll-toast-icon-transmog-up', color = { 0.55, 0.30, 0.80 }, retailOnly = true },
}

local PREVIEW_ITEMS = {
    { itemID = 10399, quality = Enum.ItemQuality.Uncommon }, -- Blackened Defias Armor
    { itemID = 16707, quality = Enum.ItemQuality.Rare },     -- Shadowcraft Cap
    { itemID = 12640, quality = Enum.ItemQuality.Epic },     -- Lionheart Helm
}

local PREVIEW_PLAYERS = {
    { name = 'Warrior', class = 'WARRIOR', state = 'need', roll = 87 },
    { name = 'Priest', class = 'PRIEST', state = 'greed', roll = 64 },
    { name = 'Mage', class = 'MAGE', state = 'greed', roll = 21 },
    { name = 'Rogue', class = 'ROGUE', state = 'pass' },
    { name = 'Paladin', class = 'PALADIN', state = 'waiting' },
}

local function UsesGamepadUI()
    return EXUI.IsForever() and InputUtil.IsGamepadUIEnabled()
end

local function GetSetting(key, default)
    local value = customWindows.Data:GetValue(key)
    if (value == nil) then return default end
    return value
end

------------------------------------------------------------------
-- Entry

local function SetButtonState(button, enabled, dimmed)
    button:SetEnabled(enabled)
    button.Bg:SetDesaturated(dimmed)
    button.Icon:SetDesaturated(dimmed)
    button:SetAlpha(dimmed and DISABLED_ALPHA or 1)
end

local function OnRollClick(button)
    local entry = button.entry
    if (not entry.roll or entry.roll.isPreview) then return end
    RollOnLoot(entry.roll.rollID, ROLL_TYPES[button.state])
    tracker:SetMyChoice(entry.roll.rollID, button.state)
end

local function CreateTab(entry, info)
    local button = CreateFrame('Button', nil, entry)
    button:SetSize(TAB_WIDTH, TAB_HEIGHT)
    button.entry = entry
    button.state = info.state

    local bg = button:CreateTexture(nil, 'BACKGROUND')
    sprite:Place(bg, 'tabBg', button)
    bg:SetVertexColor(unpack(info.color))
    button.Bg = bg

    local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
    sprite:Place(highlight, 'tabBg', button)
    highlight:SetBlendMode('ADD')
    highlight:SetAlpha(0.25)

    local text = button:CreateFontString(nil, 'OVERLAY')
    text:SetFont(FONT, 11, 'OUTLINE')
    text:SetText(info.label)
    text:SetPoint('CENTER', 9, 0)

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAtlas(info.atlas)
    icon:SetSize(14, 14)
    icon:SetPoint('RIGHT', text, 'LEFT', -4, 0)
    button.Icon = icon

    button:SetScript('OnClick', OnRollClick)
    return button
end

local function CreatePassButton(entry)
    local button = CreateFrame('Button', nil, entry)
    button:SetSize(PASS_SIZE, PASS_SIZE)
    button.entry = entry
    button.state = 'pass'

    local bg = button:CreateTexture(nil, 'BACKGROUND')
    sprite:Place(bg, 'passBg', button)
    button.Bg = bg

    local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
    sprite:Place(highlight, 'passBg', button)
    highlight:SetBlendMode('ADD')
    highlight:SetAlpha(0.25)

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAtlas('lootroll-toast-icon-pass-up')
    icon:SetSize(18, 18)
    icon:SetPoint('CENTER')
    button.Icon = icon

    button:SetScript('OnClick', OnRollClick)
    return button
end

local function CreateFade(entry, fromAlpha, toAlpha)
    local group = entry:CreateAnimationGroup()
    group:SetToFinalAlpha(true)
    local alpha = group:CreateAnimation('Alpha')
    alpha:SetFromAlpha(fromAlpha)
    alpha:SetToAlpha(toAlpha)
    alpha:SetDuration(FADE_DURATION)
    return group
end

local function CreateEntry(parent)
    local entry = CreateFrame('Frame', nil, parent)
    entry:SetSize(ENTRY_WIDTH, ENTRY_HEIGHT)

    local card = itemCard:Create(entry)
    card:SetPoint('TOPLEFT')
    entry.card = card

    entry.tabs = {}
    local shownTabs = {}
    for _, info in ipairs(TABS) do
        if (not info.retailOnly or not EXUI.IsForever()) then
            local tab = CreateTab(entry, info)
            entry.tabs[info.state] = tab
            table.insert(shownTabs, tab)
        end
    end

    local step = TAB_WIDTH + TAB_GAP
    local firstOffset = -step * (#shownTabs - 1) / 2
    for index, tab in ipairs(shownTabs) do
        tab:SetPoint('TOP', card, 'BOTTOM', firstOffset + step * (index - 1), 0)
    end

    local pass = CreatePassButton(entry)
    pass:SetPoint('LEFT', card, 'RIGHT', PASS_GAP, 0)
    entry.tabs.pass = pass

    entry.fadeIn = CreateFade(entry, 0, 1)
    entry.fadeOut = CreateFade(entry, 1, 0)

    return entry
end

local function UpdateEntry(entry, roll)
    entry.roll = roll
    local card = entry.card
    card:SetItem(roll.texture, roll.name, roll.quality, roll.count, roll.link)
    card:SetCounts(tracker:GetCounts(roll))

    local done = card:SetResult(roll.winner, roll.allPassed, roll.players)
    if (not done) then
        card:SetTimeLeft(not roll.finishedAt and tracker:GetTimeLeft(roll) or nil)
    end

    local locked = roll.closed or roll.finishedAt
    local allowed = {
        need = roll.canNeed,
        greed = roll.canGreed and not roll.canTransmog,
        transmog = roll.canTransmog,
        pass = true,
    }
    for state, button in pairs(entry.tabs) do
        local enabled = allowed[state] and not locked
        local dimmed = not allowed[state] or (roll.myState and roll.myState ~= state) or (locked and not roll.myState)
        SetButtonState(button, enabled and true or false, dimmed and true or false)
    end
end

------------------------------------------------------------------
-- Layout

local function IsVisible(roll, now)
    return not roll.finishedAt or now - roll.finishedAt < GetSetting('LootRollsResultHold', 2) + FADE_DURATION
end

lootRolls.GetPreviewRolls = function(self)
    if (not self.previewRolls) then
        self.previewRolls = {}
        for index, item in ipairs(PREVIEW_ITEMS) do
            local players = {}
            for _, player in ipairs(PREVIEW_PLAYERS) do
                players[player.name] = player
            end
            table.insert(self.previewRolls, {
                rollID = -index,
                itemID = item.itemID,
                isPreview = true,
                name = '',
                quality = item.quality,
                count = 1,
                canNeed = true,
                canGreed = true,
                canTransmog = index == 3,
                players = players,
                expires = GetTime() + 30 + index * 10,
            })
        end
    end
    for _, roll in ipairs(self.previewRolls) do
        if (not roll.link) then
            self:LoadPreviewItem(roll)
        end
    end
    return self.previewRolls
end

lootRolls.LoadPreviewItem = function(self, roll)
    local name, link, quality, _, _, _, _, _, _, texture = C_Item.GetItemInfo(roll.itemID)
    if (not name) then
        if (not roll.loading) then
            roll.loading = true
            Item:CreateFromItemID(roll.itemID):ContinueOnItemLoad(function()
                roll.loading = nil
                self:LoadPreviewItem(roll)
                self:RefreshPreview()
            end)
        end
        return
    end
    roll.name, roll.link, roll.quality, roll.texture = name, link, quality, texture
end

lootRolls.RefreshPreview = function(self)
    if (not self.isPreview) then return end
    if (self.enabled) then
        self:Layout()
    end
    lootWindow:QueueRefresh()
end

lootRolls.GetDisplayedRolls = function(self)
    if (self.isPreview) then
        return self.previewRolls
    end

    local now = GetTime()
    local list = {}
    for _, roll in ipairs(tracker:GetRolls()) do
        if (IsVisible(roll, now)) then
            table.insert(list, roll)
        end
    end
    return list
end

lootRolls.AcquireEntry = function(self, roll)
    local entry = table.remove(self.entryPool) or CreateEntry(self.anchor)
    self.entries[roll] = entry
    entry.fadingOut = false
    entry.fadeOut:Stop()
    entry.fadeIn:Restart()
    return entry
end

lootRolls.ReleaseEntry = function(self, roll)
    local entry = self.entries[roll]
    self.entries[roll] = nil
    entry.fadeIn:Stop()
    entry.fadeOut:Stop()
    entry:Hide()
    entry.roll = nil
    table.insert(self.entryPool, entry)
end

lootRolls.Layout = function(self)
    if (not self.anchor) then return end

    local rolls = self:GetDisplayedRolls()
    local growUp = GetSetting('LootRollsGrowth', 'up') == 'up'
    local displayed = {}
    for index, roll in ipairs(rolls) do
        displayed[roll] = true
        local entry = self.entries[roll] or self:AcquireEntry(roll)
        local offset = (index - 1) * (ENTRY_HEIGHT + SPACING)
        entry:ClearAllPoints()
        if (growUp) then
            entry:SetPoint('BOTTOMLEFT', self.anchor, 'BOTTOMLEFT', 0, offset)
        else
            entry:SetPoint('TOPLEFT', self.anchor, 'TOPLEFT', 0, -offset)
        end
        UpdateEntry(entry, roll)
        entry:Show()
    end

    for roll in pairs(self.entries) do
        if (not displayed[roll]) then
            self:ReleaseEntry(roll)
        end
    end

    self.anchor:SetScript('OnUpdate', #rolls > 0 and self.onUpdate or nil)
end

lootRolls.OnUpdate = function(self)
    local now = GetTime()
    for roll, entry in pairs(self.entries) do
        if (not roll.isPreview) then
            if (not IsVisible(roll, now)) then
                self:Layout()
                return
            end
            if (roll.finishedAt and not entry.fadingOut and now - roll.finishedAt >= GetSetting('LootRollsResultHold', 2)) then
                entry.fadingOut = true
                entry.fadeIn:Stop()
                entry.fadeOut:Play()
            end
        end
        if (not roll.finishedAt) then
            entry.card:SetTimeLeft(tracker:GetTimeLeft(roll))
        end
    end
end

------------------------------------------------------------------
-- Preview

lootRolls.StartPreview = function(self)
    self.isPreview = true
    for index, roll in ipairs(self:GetPreviewRolls()) do
        roll.expires = GetTime() + 30 + index * 10
    end
    if (self.enabled) then
        self:Layout()
    end
    lootWindow:SetPreview(true)
end

lootRolls.StopPreview = function(self)
    self.isPreview = false
    if (self.enabled) then
        self:Layout()
    end
    lootWindow:SetPreview(false)
end

lootRolls.TogglePreview = function(self)
    if (self.isPreview) then
        self:StopPreview()
    else
        self:StartPreview()
    end
end

------------------------------------------------------------------
-- Position

lootRolls.UpdatePosition = function(self)
    if (not self.anchor or editor:IsEditorEnabled()) then return end
    self.anchor:ClearAllPoints()
    self.anchor:SetPoint(
        GetSetting('LootRollsAnchor', 'TOP'),
        UIParent,
        GetSetting('LootRollsRelativeAnchor', 'CENTER'),
        GetSetting('LootRollsXOff', 0),
        GetSetting('LootRollsYOff', -150)
    )
end

lootRolls.CreateAnchor = function(self)
    if (self.anchor) then return end
    local anchor = CreateFrame('Frame', nil, UIParent)
    anchor:SetSize(ENTRY_WIDTH, ENTRY_HEIGHT)
    anchor:SetFrameStrata('HIGH')
    self.anchor = anchor

    local elapsed = 0
    self.onUpdate = function(_, delta)
        elapsed = elapsed + delta
        if (elapsed < UPDATE_INTERVAL) then return end
        elapsed = 0
        self:OnUpdate()
    end
end

lootRolls.RegisterEditor = function(self)
    if (editor:IsFrameRegistered(self.anchor)) then return end
    editor:RegisterFrameForEditor(self.anchor, 'Loot Rolls', function(frame)
        editor:PersistAnchoredPosition(frame, function(point, relativePoint, xOff, yOff)
            customWindows.Data:SetValue('LootRollsAnchor', point)
            customWindows.Data:SetValue('LootRollsRelativeAnchor', relativePoint)
            customWindows.Data:SetValue('LootRollsXOff', xOff)
            customWindows.Data:SetValue('LootRollsYOff', yOff)
        end, function()
            self:UpdatePosition()
        end)
    end, function()
        self:StartPreview()
    end, function()
        self:StopPreview()
    end)
end

------------------------------------------------------------------
-- Lifecycle

lootRolls.Enable = function(self)
    if (self.enabled or UsesGamepadUI()) then return end
    self.enabled = true

    self:CreateAnchor()
    self:UpdatePosition()
    self.anchor:Show()
    self:RegisterEditor()

    if (not self.hiddenParent) then
        self.hiddenParent = CreateFrame('Frame')
        self.hiddenParent:Hide()
    end
    GroupLootContainer:SetParent(self.hiddenParent)

    tracker:Acquire('loot-rolls')
    tracker:AddListener('loot-rolls', function(kind)
        if (kind == 'roll' and not self.isPreview) then
            self:Layout()
        end
    end)
    self:Layout()
end

lootRolls.Disable = function(self)
    if (not self.enabled) then return end
    self.enabled = false
    self.isPreview = false
    lootWindow:SetPreview(false)

    tracker:Release('loot-rolls')
    if (editor:IsFrameRegistered(self.anchor)) then
        editor:UnregisterFrameForEditor(self.anchor)
    end
    self:Layout()
    self.anchor:Hide()
    GroupLootContainer:SetParent(UIParent)
end

lootRolls.Init = function(self)
    if (customWindows.Data:GetValue('LootRollsEnabled') == true) then
        self:Enable()
    end
end
