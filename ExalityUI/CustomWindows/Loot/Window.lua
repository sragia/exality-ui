---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesListMenu
local listMenu = EXFrames:GetFrame('list-menu-frame')

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')

---@class EXUILootSprite
local sprite = EXUI:GetModule('loot-sprite')

---@class EXUILootTracker
local tracker = EXUI:GetModule('loot-tracker')

---@class EXUILootItemCard
local itemCard = EXUI:GetModule('loot-item-card')

---@class EXUILootRolls
local lootRolls = EXUI:GetModule('loot-rolls')

---@class EXUILootWindow
local lootWindow = EXUI:GetModule('loot-window')

lootWindow.enabled = false
lootWindow.isPreview = false
lootWindow.hooked = false
lootWindow.frame = nil
lootWindow.cards = {}
lootWindow.selectedEncounterID = nil
lootWindow.refreshQueued = false
lootWindow.hiddenParent = nil

local FONT = EXUI.const.fonts.DEFAULT
local THEME = EXUI.const.theme
local PAD = 12
local SCROLLBAR_SPACE = 10
local HEADER_HEIGHT = 40
local CARD_GAP = 6
local WIDTH = itemCard.width + PAD * 2 + SCROLLBAR_SPACE
local HEIGHT = 420
local BG_SLICE = 20
local BORDER_SLICE = 14

local function GetSetting(key, default)
    local value = customWindows.Data:GetValue(key)
    if (value == nil) then return default end
    return value
end

local function GetNewestEncounterID()
    local newest
    for _, info in ipairs(C_LootHistory.GetAllEncounterInfos() or {}) do
        if (not newest or info.startTime > newest.startTime) then
            newest = info
        end
    end
    return newest and newest.encounterID
end

local function EncounterExists(encounterID)
    return encounterID and C_LootHistory.GetInfoForEncounter(encounterID) ~= nil
end

------------------------------------------------------------------
-- Frame

lootWindow.SavePosition = function(self)
    local point, _, relativePoint, x, y = self.frame:GetPoint(1)
    customWindows.Data:SetValue('LootWindowPoint', point)
    customWindows.Data:SetValue('LootWindowRelativePoint', relativePoint)
    customWindows.Data:SetValue('LootWindowX', x)
    customWindows.Data:SetValue('LootWindowY', y)
end

lootWindow.ApplyPosition = function(self)
    self.frame:ClearAllPoints()
    self.frame:SetPoint(
        GetSetting('LootWindowPoint', 'RIGHT'),
        UIParent,
        GetSetting('LootWindowRelativePoint', 'RIGHT'),
        GetSetting('LootWindowX', -100),
        GetSetting('LootWindowY', 0)
    )
end

lootWindow.OpenEncounterMenu = function(self, owner)
    local encounters = C_LootHistory.GetAllEncounterInfos() or {}
    table.sort(encounters, function(a, b) return a.startTime > b.startTime end)

    local entries = {}
    for _, info in ipairs(encounters) do
        local encounterID = info.encounterID
        table.insert(entries, {
            text = info.encounterName,
            color = encounterID == self.selectedEncounterID and THEME.accent or nil,
            onClick = function()
                self.selectedEncounterID = encounterID
                self:Refresh()
            end,
        })
    end
    if (#entries > 0) then
        listMenu:ToggleAt(owner, entries, 'drawer')
    end
end

lootWindow.Create = function(self)
    if (self.frame) then return end

    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata('HIGH')
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', frame.StartMoving)
    frame:SetScript('OnDragStop', function(f)
        f:StopMovingOrSizing()
        self:SavePosition()
    end)
    frame:Hide()
    self.frame = frame

    local bg = frame:CreateTexture(nil, 'BACKGROUND')
    sprite:Place(bg, 'windowBg', frame, 0, BG_SLICE)

    local border = frame:CreateTexture(nil, 'BORDER')
    sprite:Place(border, 'windowBorder', frame, 0, BORDER_SLICE)
    border:SetVertexColor(unpack(THEME.border))

    local title = frame:CreateFontString(nil, 'OVERLAY')
    title:SetFont(FONT, 14, 'OUTLINE')
    title:SetTextColor(unpack(THEME.textMuted))
    title:SetPoint('TOPLEFT', PAD + 2, -14)
    title:SetText('Loot')

    local close = CreateFrame('Button', nil, frame)
    close:SetSize(sprite:GetBodySize('close'))
    close:SetPoint('TOPRIGHT', -PAD, -14)
    local closeTexture = close:CreateTexture(nil, 'ARTWORK')
    sprite:Place(closeTexture, 'close', close)
    closeTexture:SetVertexColor(unpack(THEME.textMuted))
    close:SetScript('OnEnter', function() closeTexture:SetVertexColor(unpack(THEME.dangerHover)) end)
    close:SetScript('OnLeave', function() closeTexture:SetVertexColor(unpack(THEME.textMuted)) end)
    close:SetScript('OnClick', function()
        if (self.isPreview) then
            lootRolls:StopPreview()
        end
        GroupLootHistoryFrame:Hide()
    end)

    local encounterButton = CreateFrame('Button', nil, frame)
    encounterButton:SetHeight(18)
    encounterButton:SetPoint('LEFT', title, 'RIGHT', 12, 0)
    local encounterText = encounterButton:CreateFontString(nil, 'OVERLAY')
    encounterText:SetFont(FONT, 12, 'OUTLINE')
    encounterText:SetTextColor(unpack(THEME.text))
    encounterText:SetPoint('LEFT')
    encounterText:SetWordWrap(false)
    local chevron = encounterButton:CreateTexture(nil, 'ARTWORK')
    chevron:SetTexture(EXUI.const.textures.frame.inputs.chevronDown)
    chevron:SetSize(10, 10)
    chevron:SetPoint('LEFT', encounterText, 'RIGHT', 4, 0)
    encounterButton:SetScript('OnClick', function(button) self:OpenEncounterMenu(button) end)
    encounterButton.SetLabel = function(button, text)
        encounterText:SetText(text or '')
        encounterText:SetWidth(math.min(encounterText:GetUnboundedStringWidth(), WIDTH - 130))
        button:SetWidth(encounterText:GetWidth() + 14)
        chevron:SetShown(text ~= nil)
    end
    self.encounterButton = encounterButton

    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scroll:SetParent(frame)
    scroll:SetPoint('TOPLEFT', PAD, -HEADER_HEIGHT)
    scroll:SetPoint('BOTTOMRIGHT', -PAD, PAD)
    self.scroll = scroll

    local empty = frame:CreateFontString(nil, 'OVERLAY')
    empty:SetFont(FONT, 12, 'OUTLINE')
    empty:SetTextColor(unpack(THEME.textMuted))
    empty:SetPoint('CENTER', scroll, 'CENTER')
    empty:SetText('No loot yet')
    self.empty = empty

    self:ApplyPosition()
end

------------------------------------------------------------------
-- Content

local function GetItemDisplay(link, onLoad)
    local name, _, quality, _, _, _, _, _, _, texture = C_Item.GetItemInfo(link)
    if (not name) then
        Item:CreateFromItemLink(link):ContinueOnItemLoad(onLoad)
    end
    return name or '', quality, texture
end

local function FillCard(card, roll, texture, name, quality, link)
    card:SetItem(texture, name, quality, 1, link)
    card:SetCounts(tracker:GetCounts(roll))

    local done = card:SetResult(roll.winner, roll.allPassed, roll.players)
    card:SetDoneTint(done)
    if (not done) then
        card:SetTimeLeft(roll.expires and not roll.finishedAt and tracker:GetTimeLeft(roll) or nil)
    end
end

lootWindow.UpdateCard = function(self, card, encounterID, drop)
    local roll = tracker:GetRollForDrop(encounterID, drop.lootListID or drop.lootListKey)
    if (not roll) then
        roll = { players = {} }
        tracker:ApplyDrop(roll, drop)
    end

    local name, quality, texture = GetItemDisplay(drop.itemHyperlink, function() self:QueueRefresh() end)
    FillCard(card, roll, texture, name, quality, drop.itemHyperlink)
end

lootWindow.GetPreviewEntries = function(self)
    local entries = {}
    for _, roll in ipairs(lootRolls:GetPreviewRolls()) do
        table.insert(entries, roll)
    end
    local finished = CopyTable(entries[#entries])
    finished.winner = { name = 'Warrior', class = 'WARRIOR', state = 'need' }
    table.insert(entries, finished)
    return entries
end

lootWindow.Refresh = function(self)
    self.refreshQueued = false
    if (not self.frame or not self.frame:IsShown()) then return end

    local count, fill
    if (self.isPreview) then
        local entries = self:GetPreviewEntries()
        self.encounterButton:SetLabel('Preview')
        count = #entries
        fill = function(card, index)
            local roll = entries[index]
            FillCard(card, roll, roll.texture, roll.name, roll.quality, roll.link)
        end
    else
        if (not EncounterExists(self.selectedEncounterID)) then
            self.selectedEncounterID = GetNewestEncounterID()
        end
        local encounterID = self.selectedEncounterID
        local info = encounterID and C_LootHistory.GetInfoForEncounter(encounterID)
        self.encounterButton:SetLabel(info and info.encounterName)

        local drops = encounterID and C_LootHistory.GetSortedDropsForEncounter(encounterID) or {}
        count = #drops
        fill = function(card, index)
            self:UpdateCard(card, encounterID, drops[index])
        end
    end

    local child = self.scroll.child
    for index = 1, count do
        local card = self.cards[index]
        if (not card) then
            card = itemCard:Create(child)
            self.cards[index] = card
        end
        card:ClearAllPoints()
        card:SetPoint('TOPLEFT', child, 'TOPLEFT', 0, -(index - 1) * (itemCard.height + CARD_GAP))
        fill(card, index)
        card:Show()
    end
    for index = count + 1, #self.cards do
        self.cards[index]:Hide()
    end

    self.empty:SetShown(count == 0)
    local height = math.max(1, count * (itemCard.height + CARD_GAP) - CARD_GAP)
    self.scroll:UpdateScrollChild(self.scroll:GetWidth(), height)
end

lootWindow.QueueRefresh = function(self)
    if (self.refreshQueued or not self.frame or not self.frame:IsShown()) then return end
    self.refreshQueued = true
    C_Timer.After(0, function() self:Refresh() end)
end

lootWindow.Open = function(self)
    self:Create()
    self.frame:Show()
    self:Refresh()
end

lootWindow.SetPreview = function(self, isPreview)
    if (not self.enabled or self.isPreview == isPreview) then return end
    self.isPreview = isPreview
    if (isPreview) then
        self:Open()
    elseif (GroupLootHistoryFrame:IsShown()) then
        self:Refresh()
    else
        self:Close()
    end
end

lootWindow.Close = function(self)
    if (not self.frame) then return end
    if (listMenu:GetAnchor() == self.encounterButton) then
        listMenu:Hide()
    end
    self.frame:Hide()
end

------------------------------------------------------------------
-- Blizzard window

lootWindow.HookBlizzard = function(self)
    if (self.hooked) then return end
    self.hooked = true

    hooksecurefunc(GroupLootHistoryFrame, 'Show', function()
        if (self.enabled) then self:Open() end
    end)
    hooksecurefunc(GroupLootHistoryFrame, 'Hide', function()
        if (self.enabled) then self:Close() end
    end)
    hooksecurefunc(GroupLootHistoryFrame, 'SetShown', function(_, shown)
        if (not self.enabled) then return end
        if (shown) then
            self:Open()
        else
            self:Close()
        end
    end)
    hooksecurefunc('SetLootHistoryFrameToEncounter', function(encounterID)
        if (not self.enabled) then return end
        self.selectedEncounterID = encounterID
        self:Open()
    end)
end

lootWindow.Enable = function(self)
    if (self.enabled) then return end
    self.enabled = true

    if (not self.hiddenParent) then
        self.hiddenParent = CreateFrame('Frame')
        self.hiddenParent:Hide()
    end
    GroupLootHistoryFrame:SetParent(self.hiddenParent)
    self:HookBlizzard()

    tracker:Acquire('loot-window')
    tracker:AddListener('loot-window', function(kind, value)
        if (kind == 'goToEncounter') then
            self.selectedEncounterID = value
        end
        self:QueueRefresh()
    end)

    if (GroupLootHistoryFrame:IsShown()) then
        self:Open()
    end
end

lootWindow.Disable = function(self)
    if (not self.enabled) then return end
    self.enabled = false
    self.isPreview = false

    tracker:Release('loot-window')
    self:Close()
    GroupLootHistoryFrame:Hide()
    GroupLootHistoryFrame:SetParent(UIParent)
end

lootWindow.Init = function(self)
    if (customWindows.Data:GetValue('LootWindowEnabled') == true) then
        self:Enable()
    end
end
