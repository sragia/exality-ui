---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesWindowFrame
local windowConstruct = EXFrames:GetFrame('window-frame')

---@class ExalityFramesListMenu
local listMenu = EXFrames:GetFrame('list-menu-frame')

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIMerchantWindowSprite
local sprite = EXUI:GetModule('merchant-window-sprite')

---@class EXUIMerchantWindowPagination
local pagination = EXUI:GetModule('merchant-window-pagination')

---@class EXUIMerchantWindowRows
local rows = EXUI:GetModule('merchant-window-rows')

---@class EXUIMerchantWindowBulk
local bulk = EXUI:GetModule('merchant-window-bulk')

---@class EXUIMerchantWindow
local merchant = EXUI:GetModule('merchant-window')

merchant.enabled = false
merchant.isOpen = false
merchant.hiddenParent = nil
merchant.window = nil
merchant.refreshQueued = false
merchant.itemDataPending = false
merchant.page = 1

local GRID_TOP = 46
local GRID_SIDE = 10
local PAGER_GAP = 30
local PAGER_BOTTOM = 24
local WINDOW_WIDTH = rows.gridWidth + GRID_SIDE * 2
local WINDOW_HEIGHT = GRID_TOP + rows.gridHeight + PAGER_GAP + pagination.height + PAGER_BOTTOM
local WINDOW_ANCHOR = { 'TOPLEFT', UIParent, 'TOPLEFT', 40, -120 }
local BACKGROUND_ALPHA = 0.95
local PORTRAIT_SCALE = 0.8
local PORTRAIT_SIZE = 87 * PORTRAIT_SCALE
local PORTRAIT_OFFSET_X = 33
local NAME_FONT_SIZE = 20
local FILTER_SIZE = 28
local FILTER_SCALE = 0.4
local ACTION_SIZE = 36
local ACTION_SCALE = 0.8
local ACTION_GAP = 9
local ACTION_RIGHT = -8
local ACTION_BOTTOM = -15
local FOOTER_LEFT = 14
local FOOTER_BOTTOM = 6
local FOOTER_WIDTH = 260
local FOOTER_HEIGHT = 34
local TOKEN_HEIGHT = 18
local TOKEN_ICON_SIZE = 14
local TOKEN_GAP = 8
local CLAMP_LEFT = -10
local CLAMP_TOP = 44
local CLAMP_BOTTOM = -28
local TAB_MERCHANT = 'merchant'
local TAB_BUYBACK = 'buyback'

merchant.activeTab = TAB_MERCHANT

local EVENT_ID = 'merchant-window'
local REFRESH_EVENT_ID = 'merchant-window-refresh'
local EVENTS = { 'MERCHANT_SHOW', 'MERCHANT_CLOSED' }
local REFRESH_EVENTS = {
    'MERCHANT_UPDATE',
    'MERCHANT_FILTER_ITEM_UPDATE',
    'BAG_UPDATE_DELAYED',
    'UNIT_INVENTORY_CHANGED',
    'UPDATE_INVENTORY_DURABILITY',
    'PLAYER_MONEY',
    'GUILDBANK_UPDATE_MONEY',
    'GUILDBANK_UPDATE_WITHDRAWMONEY',
    'CURRENCY_DISPLAY_UPDATE',
    'HEIRLOOMS_UPDATED',
    'GET_ITEM_INFO_RECEIVED',
}
local MERCHANT_POPUPS = {
    'CONFIRM_PURCHASE_TOKEN_ITEM',
    'CONFIRM_PURCHASE_ITEM_DELAYED',
    'CONFIRM_REFUND_TOKEN_ITEM',
    'CONFIRM_REFUND_MAX_HONOR',
    'CONFIRM_REFUND_MAX_ARENA_POINTS',
}

local function UsesGamepadUI()
    return EXUI.IsForever() and InputUtil.IsGamepadUIEnabled()
end

local function MirrorTab(index)
    if (MerchantFrame.selectedTab ~= index) then
        PanelTemplates_SetTab(MerchantFrame, index)
    end
end

local function OpenFilterMenu(owner)
    local entries = {}
    local function AddFilter(label, filter)
        entries[#entries + 1] = {
            text = label,
            color = GetMerchantFilter() == filter and EXUI.const.theme.accent or nil,
            onClick = function()
                SetMerchantFilter(filter)
                merchant:SetPage(1)
            end,
        }
    end

    local sex = UnitSex('player')
    for index = 1, GetNumSpecializations() do
        local name = select(2, C_SpecializationInfo.GetSpecializationInfo(index, false, false, nil, sex))
        AddFilter(name, (LE_LOOT_FILTER_SPEC1 + index) - 1)
    end
    AddFilter(ALL_SPECS, LE_LOOT_FILTER_CLASS)
    entries[#entries + 1] = { isDivider = true }
    AddFilter(ITEM_BIND_ON_EQUIP, LE_LOOT_FILTER_BOE)
    AddFilter(ALL, LE_LOOT_FILTER_ALL)

    listMenu:ToggleAt(owner, entries)
    if (listMenu:IsOpen()) then
        owner.forceOn = true
        owner:UpdateArt()
        listMenu.panel.onHideCallback = function()
            owner.forceOn = nil
            owner:UpdateArt()
        end
    end
end

local function CreateActionButton(parent, offKey, onKey, onEnter, onClick)
    local button = sprite:CreateButton(parent, ACTION_SIZE, ACTION_SIZE, offKey, onKey, ACTION_SCALE)
    button.dimDisabled = true
    button:SetScript('OnClick', onClick)
    button:HookScript('OnEnter', onEnter)
    button:HookScript('OnLeave', GameTooltip_Hide)
    return button
end

merchant.CreateActions = function(self, parent)
    local repairItem = CreateActionButton(parent, 'repairItemOff', 'repairItemOn',
        MerchantRepairItemButton:GetScript('OnEnter'),
        function()
            if (InRepairMode()) then
                HideRepairCursor()
            else
                ShowRepairCursor()
            end
        end)
    repairItem:SetScript('OnUpdate', function(button)
        local active = InRepairMode()
        if (button.forceOn ~= active) then
            button.forceOn = active
            button:UpdateArt()
        end
    end)

    local repairAll = CreateActionButton(parent, 'repairAllOff', 'repairAllOn',
        MerchantRepairAllButton:GetScript('OnEnter'),
        function()
            RepairAllItems()
            PlaySound(SOUNDKIT.ITEM_REPAIR)
            GameTooltip:Hide()
        end)

    local repairGuild = CreateActionButton(parent, 'repairGuildOff', 'repairGuildOn',
        MerchantGuildBankRepairButton:GetScript('OnEnter'),
        function()
            if (CanGuildBankRepair()) then
                RepairAllItems(true)
                PlaySound(SOUNDKIT.ITEM_REPAIR)
            end
            GameTooltip:Hide()
        end)

    local sellJunk = CreateActionButton(parent, 'sellOff', 'sellOn',
        function(button)
            GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
            GameTooltip:SetText(SELL_ALL_JUNK_ITEMS)
            GameTooltip:Show()
        end,
        function()
            MerchantFrame_OnSellAllJunkButtonClicked()
        end)

    self.actions = {
        repairItem = repairItem,
        repairAll = repairAll,
        repairGuild = repairGuild,
        sellJunk = sellJunk,
    }
    -- Right to left, so a vendor offering fewer actions stays flush with the window corner.
    self.actionOrder = { sellJunk, repairItem, repairGuild, repairAll }
end

merchant.CreateFooter = function(self, parent)
    local footer = CreateFrame('Frame', nil, parent)
    footer:SetSize(FOOTER_WIDTH, FOOTER_HEIGHT)
    footer:SetPoint('BOTTOMLEFT', FOOTER_LEFT, FOOTER_BOTTOM)
    self.footer = footer

    local money = footer:CreateFontString(nil, 'OVERLAY')
    money:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    money:SetPoint('TOPLEFT', footer, 'TOPLEFT', 0, 0)
    money:SetTextColor(unpack(EXUI.const.theme.text))
    self.moneyText = money

    self.tokens = {}
end

merchant.CreatePortrait = function(self, window)
    local portrait = CreateFrame('Frame', nil, window)
    portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    portrait:SetPoint('CENTER', window, 'TOPLEFT', PORTRAIT_OFFSET_X, 0)
    portrait:SetFrameLevel(window.header:GetFrameLevel() + 1)

    local mask = portrait:CreateMaskTexture()
    mask:SetAllPoints()
    mask:SetTexture(sprite.portraitMask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')

    -- Keeps the ring filled for merchants without a portrait.
    local background = portrait:CreateTexture(nil, 'BACKGROUND')
    background:SetAllPoints()
    background:SetColorTexture(unpack(EXUI.const.theme.backgroundDeep))
    background:AddMaskTexture(mask)

    local texture = portrait:CreateTexture(nil, 'ARTWORK')
    texture:SetAllPoints()
    texture:AddMaskTexture(mask)
    self.portrait = texture

    local ring = portrait:CreateTexture(nil, 'OVERLAY')
    ring:SetPoint('CENTER')
    sprite:Apply(ring, 'portraitBorder', PORTRAIT_SCALE)

    local name = portrait:CreateFontString(nil, 'OVERLAY')
    name:SetFont(EXUI.const.fonts.DEFAULT, NAME_FONT_SIZE, 'OUTLINE')
    name:SetPoint('LEFT', portrait, 'RIGHT', 14, 0)
    name:SetWidth(WINDOW_WIDTH - PORTRAIT_SIZE - 140)
    name:SetJustifyH('LEFT')
    name:SetWordWrap(false)
    name:SetTextColor(unpack(EXUI.const.theme.text))
    self.nameText = name
end

merchant.StyleTabs = function(self)
    for id, tab in pairs(self.tabs) do
        skins:ApplyWindowTabStyle(tab, id == self.activeTab, false)
    end
end

merchant.CreateTabs = function(self, window)
    local function CreateTab(id, label)
        local tab = CreateFrame('Button', nil, window)
        local text = tab:CreateFontString(nil, 'OVERLAY')
        text:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
        text:SetText(label)
        tab.Text = text
        tab:SetScript('OnClick', function()
            merchant:SetTab(id)
        end)
        tab:SetScript('OnEnter', function()
            merchant:StyleTabs()
        end)
        tab:SetScript('OnLeave', function()
            merchant:StyleTabs()
        end)
        return tab
    end

    local merchantTab = CreateTab(TAB_MERCHANT, MERCHANT)
    local buybackTab = CreateTab(TAB_BUYBACK, BUYBACK)
    self.tabs = {
        [TAB_MERCHANT] = merchantTab,
        [TAB_BUYBACK] = buybackTab,
    }
    self:StyleTabs()
    skins:AnchorWindowTabs(window, { merchantTab, buybackTab })
end

merchant.Create = function(self)
    if (self.window) then
        return
    end

    local window = windowConstruct:Create({
        name = 'EXUIMerchantFrame',
        size = { WINDOW_WIDTH, WINDOW_HEIGHT },
        title = '',
        disableResize = true,
        disableLogoAndVersion = true,
        legacyChrome = {
            hideHeaderBar = true,
            close = {
                width = 38,
                height = 28,
                inset = { 8, 5 },
                buttonBg = EXUI.const.textures.characterFrame.input.buttonBg,
                closeIcon = EXUI.const.textures.frame.closeIcon,
                iconSize = 14,
                normalColor = EXUI.const.theme.faded,
                hoverColor = EXUI.const.theme.dangerHover,
            },
        },
    })
    window:SetFrameStrata('HIGH')
    window:ClearAllPoints()
    window:SetPoint(unpack(WINDOW_ANCHOR))
    window:SetClampRectInsets(CLAMP_LEFT, 0, CLAMP_TOP, CLAMP_BOTTOM)
    window._userPlaced = true
    window.skipShowAnimation = true
    local background = EXUI.const.theme.backgroundDeep
    window:SetBackgroundTexture(EXUI.const.textures.frame.inputs.buttonBg)
    window:SetPanelFillColor(background[1], background[2], background[3], BACKGROUND_ALPHA)
    window.title:Hide()
    window.headerContentGap = 0
    window:SetHeaderInset(0)
    window:SetHeaderHeight(0)
    window.header:SetFrameLevel(window:GetFrameLevel() + 10)
    window:SetScript('OnMouseUp', rows.SellCursorItem)
    window:SetScript('OnReceiveDrag', rows.SellCursorItem)
    window:EnableMouseWheel(true)
    window:SetScript('OnMouseWheel', function(_, delta)
        pagination:Step(delta > 0 and -1 or 1)
    end)
    window:HookScript('OnHide', function()
        merchant:Close()
    end)
    tinsert(UISpecialFrames, 'EXUIMerchantFrame')
    self.window = window

    local container = window.container
    local grid = CreateFrame('Frame', nil, container)
    grid:SetSize(rows.gridWidth, rows.gridHeight)
    grid:SetPoint('TOPLEFT', GRID_SIDE, -GRID_TOP)
    self.grid = grid

    self:CreatePortrait(window)
    self:CreateActions(window)
    self:CreateFooter(container)
    self:CreateTabs(window)

    local pager = pagination:Create(container, function(page)
        merchant:SetPage(page)
    end)
    pager:SetPoint('BOTTOM', 0, PAGER_BOTTOM)

    local filter = sprite:CreateButton(window, FILTER_SIZE, FILTER_SIZE, 'filterOff', 'filterOn', FILTER_SCALE)
    filter:SetPoint('TOPRIGHT', window.close, 'TOPLEFT', -5, 0)
    filter:SetFrameLevel(window.header:GetFrameLevel() + 1)
    filter:SetScript('OnClick', OpenFilterMenu)
    self.filterButton = filter

    bulk:Create(window)
end

merchant.SetTab = function(self, id)
    if (self.activeTab == id) then
        return
    end
    self.activeTab = id
    MirrorTab(id == TAB_BUYBACK and 2 or 1)
    self:StyleTabs()
    self:SetPage(1)
end

merchant.SetPage = function(self, page)
    self.page = page
    bulk:Hide()
    self:Refresh()
end

merchant.RefreshItems = function(self)
    local isMerchantTab = self.activeTab == TAB_MERCHANT
    local count = isMerchantTab and GetMerchantNumItems() or GetNumBuybackItems()
    local pages = math.max(math.ceil(count / rows.perPage), 1)
    self.page = math.min(self.page, pages)

    local offset = (self.page - 1) * rows.perPage
    local shown = math.min(rows.perPage, count - offset)
    local loaded = true

    for slot = 1, shown do
        local row = rows:Acquire(slot, self.grid)
        local rowLoaded
        if (isMerchantTab) then
            rowLoaded = rows:FillMerchant(row, offset + slot)
        else
            rowLoaded = rows:FillBuyback(row, offset + slot)
        end
        loaded = loaded and rowLoaded
    end
    rows:HideFrom(shown + 1)

    self.itemDataPending = not loaded
    pagination:Update(self.page, pages)
end

merchant.RefreshActions = function(self)
    local actions = self.actions
    local isMerchantTab = self.activeTab == TAB_MERCHANT
    local canRepairHere = isMerchantTab and CanMerchantRepair()
    local _, canRepair = GetRepairAllCost()

    actions.repairItem:SetShown(canRepairHere)
    actions.repairAll:SetShown(canRepairHere)
    actions.repairAll:SetEnabled(canRepair)
    actions.repairGuild:SetShown(canRepairHere and CanGuildBankRepair())
    actions.repairGuild:SetEnabled(canRepair)
    actions.sellJunk:SetShown(isMerchantTab and C_MerchantFrame.IsSellAllJunkEnabled())
    actions.sellJunk:SetEnabled(C_MerchantFrame.GetNumJunkItems() > 0)

    local previous
    for _, button in ipairs(self.actionOrder) do
        button:UpdateArt()
        if (button:IsShown()) then
            button:ClearAllPoints()
            if (previous) then
                button:SetPoint('RIGHT', previous, 'LEFT', -ACTION_GAP, 0)
            else
                button:SetPoint('BOTTOMRIGHT', self.window, 'BOTTOMRIGHT', ACTION_RIGHT, ACTION_BOTTOM)
            end
            previous = button
        end
    end

    local filterDisabled = C_GameRules.IsGameRuleActive(Enum.GameRule.MerchantFilterDisabled)
    self.filterButton:SetShown(isMerchantTab and not filterDisabled)
end

merchant.AcquireToken = function(self, index)
    local token = self.tokens[index]
    if (token) then
        return token
    end

    token = CreateFrame('Button', nil, self.footer)
    token:SetHeight(TOKEN_HEIGHT)
    if (index == 1) then
        token:SetPoint('BOTTOMLEFT', self.footer, 'BOTTOMLEFT', 0, 0)
    else
        token:SetPoint('LEFT', self.tokens[index - 1], 'RIGHT', TOKEN_GAP, 0)
    end

    local icon = token:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(TOKEN_ICON_SIZE, TOKEN_ICON_SIZE)
    icon:SetPoint('LEFT')
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    token.icon = icon

    local count = token:CreateFontString(nil, 'OVERLAY')
    count:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    count:SetPoint('LEFT', icon, 'RIGHT', 3, 0)
    count:SetTextColor(unpack(EXUI.const.theme.text))
    token.count = count

    token:SetScript('OnEnter', MerchantFrame_ShowCurrencyTooltip)
    token:SetScript('OnLeave', GameTooltip_Hide)

    self.tokens[index] = token
    return token
end

merchant.RefreshCurrencies = function(self)
    self.moneyText:SetText(C_CurrencyInfo.GetCoinTextureString(GetMoney()))

    local currencies = C_MerchantFrame.GetMerchantCurrencies() or {}
    local shown = math.min(#currencies, MAX_MERCHANT_CURRENCIES)
    for index = 1, shown do
        local token = self:AcquireToken(index)
        local info = C_CurrencyInfo.GetCurrencyInfo(currencies[index])
        token.currencyID = currencies[index]
        token.icon:SetTexture(info.iconFileID)
        token.count:SetText(info.quantity)
        token:SetWidth(TOKEN_ICON_SIZE + 3 + token.count:GetStringWidth())
        token:Show()
    end
    for index = shown + 1, #self.tokens do
        self.tokens[index].currencyID = nil
        self.tokens[index]:Hide()
    end
end

merchant.Refresh = function(self)
    if (not self.isOpen) then
        return
    end
    self:RefreshItems()
    self:RefreshActions()
    self:RefreshCurrencies()
    bulk:Refresh()
end

merchant.QueueRefresh = function(self)
    if (self.refreshQueued) then
        return
    end
    self.refreshQueued = true
    C_Timer.After(0, function()
        self.refreshQueued = false
        self:Refresh()
    end)
end

-- MerchantFrame stays shown under a hidden parent: bag clicks read MerchantFrame:IsShown()
-- for refund confirmations and selling, but its OnShow/OnHide scripts no longer fire.
merchant.Open = function(self)
    self.isOpen = true
    self:Create()
    ResetSetMerchantFilter()
    OpenAllBags(MerchantFrame, true)

    SetPortraitTexture(self.portrait, 'npc')
    self.nameText:SetText(UnitName('npc') or MERCHANT)
    self.page = 1
    self:SetTab(TAB_MERCHANT)

    EXUI:RegisterEventHandler(REFRESH_EVENTS, REFRESH_EVENT_ID, function(event, unit)
        if (event == 'GET_ITEM_INFO_RECEIVED' and not merchant.itemDataPending) then
            return
        end
        if (event == 'UNIT_INVENTORY_CHANGED' and unit ~= 'player') then
            return
        end
        merchant:QueueRefresh()
    end)

    self.window:ShowWindow()
    self:Refresh()
end

merchant.Close = function(self)
    if (not self.isOpen) then
        return
    end
    self.isOpen = false

    EXUI:UnregisterEventHandler(REFRESH_EVENTS, REFRESH_EVENT_ID)
    bulk:Stop()
    bulk:Hide()
    if (listMenu:GetAnchor() == self.filterButton) then
        listMenu:Hide()
    end
    if (InRepairMode()) then
        HideRepairCursor()
    end
    MirrorTab(1)

    CloseMerchant()
    CloseAllBags(MerchantFrame, true)
    ResetCursor()
    for _, popup in ipairs(MERCHANT_POPUPS) do
        StaticPopup_Hide(popup)
    end

    self.window:Hide()
end

merchant.Enable = function(self)
    if (self.enabled or UsesGamepadUI()) then
        return
    end
    self.enabled = true

    if (not self.hiddenParent) then
        self.hiddenParent = CreateFrame('Frame')
        self.hiddenParent:Hide()
    end
    MerchantFrame:SetParent(self.hiddenParent)

    EXUI:RegisterEventHandler(EVENTS, EVENT_ID, function(event)
        if (event == 'MERCHANT_SHOW') then
            merchant:Open()
        else
            merchant:Close()
        end
    end)
end

merchant.Disable = function(self)
    if (not self.enabled) then
        return
    end
    self.enabled = false

    self:Close()
    EXUI:UnregisterEventHandler(EVENTS, EVENT_ID)
    MerchantFrame:SetParent(UIParent)
end

merchant.Init = function(self)
    if (customWindows.Data:GetValue('MerchantEnabled') == true) then
        self:Enable()
    end
end
