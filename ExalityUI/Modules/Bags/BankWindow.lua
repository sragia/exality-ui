---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIBankWindow
local bankWindow = EXUI:GetModule('bags-bank-window')

---@class EXUIBags
local bags

---@class EXUIBagsSlots
local slots = EXUI:GetModule('bags-slots')

---@class EXUIBagsViews
local views = EXUI:GetModule('bags-views')

local TAB_WIDTH = 92
local TAB_HEIGHT = 26
local TAB_GAP = 2
local HEADER_HEIGHT = 40
local FOOTER_HEIGHT = 32
local PAD = 10
local CLIP_INSET = 2
local SCROLL_GUTTER = 16
local BAR_GAP = 5
local SLICE = 16
local HEADER_BTN_GAP = 12
local POOL = 'bank'

local FILTER_TABS = {
    { id = 'bags', label = 'Bags' },
    { id = 'gear', label = 'Gear' },
    { id = 'consumables', label = 'Consumables' },
    { id = 'reagents', label = 'Reagents' },
    { id = 'quest', label = 'Quest' },
}

local MODE_TABS = {
    { id = 'personal', label = 'Personal', bankType = Enum.BankType.Character },
    { id = 'warband', label = 'Warband', bankType = Enum.BankType.Account },
}

bankWindow.frame = nil
bankWindow.activeTab = 'bags'
bankWindow.activeMode = 'personal'
bankWindow.layoutSignature = nil
bankWindow.tabButtons = {}
bankWindow.modeButtons = {}

local function GetBags()
    bags = bags or EXUI:GetModule('bags')
    return bags
end

local function GetBankType()
    if bankWindow.activeMode == 'warband' then
        return Enum.BankType.Account
    end
    return Enum.BankType.Character
end

local function FetchTabIDs(bankType)
    if not C_Bank or not C_Bank.FetchPurchasedBankTabIDs then
        return {}
    end
    return C_Bank.FetchPurchasedBankTabIDs(bankType) or {}
end

local function CanViewBankType(bankType)
    return C_Bank and C_Bank.CanViewBank and C_Bank.CanViewBank(bankType)
end

local function ApplyPanelTextures(frame)
    local bg = frame:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetTexture(EXUI.const.textures.bags.bg)
    bg:SetTextureSliceMargins(SLICE, SLICE, SLICE, SLICE)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    frame.Background = bg

    local border = frame:CreateTexture(nil, 'BORDER')
    border:SetAllPoints()
    border:SetTexture(EXUI.const.textures.bags.border)
    border:SetTextureSliceMargins(SLICE, SLICE, SLICE, SLICE)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    frame.Border = border
end

local function StyleTab(button, active, hovered, lineOnLeft)
    local theme = EXUI.const.theme
    button.Glow:Show()
    if active then
        button.Glow:SetVertexColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.85)
        button.Line:SetColorTexture(1, 1, 1, 1)
        button.Label:SetTextColor(1, 1, 1, 1)
    else
        button.Glow:SetVertexColor(theme.background[1], theme.background[2], theme.background[3], 1)
        local r, g, b = unpack(theme.border)
        button.Line:SetColorTexture(r, g, b, 1)
        if hovered then
            button.Label:SetTextColor(1, 1, 1, 1)
        else
            button.Label:SetTextColor(unpack(theme.textMuted))
        end
    end
    if lineOnLeft then
        button.Line:ClearAllPoints()
        button.Line:SetPoint('TOPLEFT')
        button.Line:SetPoint('BOTTOMLEFT')
    end
end

local function FormatMoney(copper)
    copper = copper or 0
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperLeft = copper % 100
    return string.format(
        '%s|cffffd100g|r %d|cffc7c7cfs|r %d|cffeda55fc|r',
        EXUI.utils.formatNumberWithCommas(gold),
        silver,
        copperLeft
    )
end

local function CreateHeaderButton(parent, label, iconTexture)
    local button = CreateFrame('Button', nil, parent)
    local muted = EXUI.const.theme.textMuted

    local text = button:CreateFontString(nil, 'OVERLAY')
    button.Label = text
    text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    text:SetPoint('LEFT')
    text:SetText(label)
    text:SetTextColor(unpack(muted))

    local icon = button:CreateTexture(nil, 'ARTWORK')
    button.Icon = icon
    if iconTexture then
        icon:SetTexture(iconTexture)
        icon:SetPoint('LEFT', text, 'RIGHT', 4, 0)
        icon:SetSize(18, 18)
        icon:SetVertexColor(unpack(muted))
    else
        icon:Hide()
    end

    button:SetScript('OnEnter', function()
        if not button:IsEnabled() then
            return
        end
        icon:SetVertexColor(1, 1, 1, 1)
        text:SetTextColor(1, 1, 1, 1)
        if button.tooltip then
            GameTooltip:SetOwner(button, 'ANCHOR_TOP')
            GameTooltip:SetText(button.tooltip, 1, 1, 1, 1, true)
            if button.tooltipLines then
                for i = 1, #button.tooltipLines do
                    GameTooltip:AddLine(button.tooltipLines[i], 1, 1, 1, true)
                end
            end
            GameTooltip:Show()
        end
    end)
    button:SetScript('OnLeave', function()
        icon:SetVertexColor(unpack(muted))
        text:SetTextColor(unpack(muted))
        GameTooltip:Hide()
    end)

    return button
end

local function SizeHeaderButton(button, bagSize)
    local textWidth = button.Label:GetStringWidth()
    if button.Icon:IsShown() then
        local iconSize = math.max(12, bagSize - 8)
        button.Icon:SetSize(iconSize, iconSize)
        button:SetSize(iconSize + 4 + textWidth, bagSize)
    else
        button:SetSize(textWidth, bagSize)
    end
end

bankWindow.CreateFilterTabs = function(self, parent)
    local lineWidth = EXUI:ScalePixels(1, parent)
    for i, tab in ipairs(FILTER_TABS) do
        local button = CreateFrame('Button', nil, parent)
        button:SetSize(TAB_WIDTH, TAB_HEIGHT)
        button.tabID = tab.id

        local glow = button:CreateTexture(nil, 'BACKGROUND')
        button.Glow = glow
        glow:SetAllPoints()
        glow:SetTexture(EXUI.const.textures.bags.glow)

        local label = button:CreateFontString(nil, 'OVERLAY')
        button.Label = label
        label:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        label:SetPoint('RIGHT', -8, 0)
        label:SetJustifyH('RIGHT')
        label:SetText(tab.label)

        local line = button:CreateTexture(nil, 'OVERLAY')
        button.Line = line
        line:SetWidth(lineWidth)
        line:SetPoint('TOPRIGHT')
        line:SetPoint('BOTTOMRIGHT')

        button:SetScript('OnClick', function()
            self:SetTab(tab.id)
        end)
        button:SetScript('OnEnter', function()
            StyleTab(button, self.activeTab == tab.id, true)
        end)
        button:SetScript('OnLeave', function()
            StyleTab(button, self.activeTab == tab.id, false)
        end)

        if i == 1 then
            button:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
        else
            button:SetPoint('TOPLEFT', self.tabButtons[i - 1], 'BOTTOMLEFT', 0, -TAB_GAP)
        end

        self.tabButtons[i] = button
        StyleTab(button, tab.id == self.activeTab, false)
    end
end

bankWindow.CreateModeTabs = function(self, parent)
    local lineWidth = EXUI:ScalePixels(1, parent)
    for i, tab in ipairs(MODE_TABS) do
        local button = CreateFrame('Button', nil, parent)
        button:SetSize(TAB_WIDTH, TAB_HEIGHT)
        button.modeID = tab.id
        button.bankType = tab.bankType

        local glow = button:CreateTexture(nil, 'BACKGROUND')
        button.Glow = glow
        glow:SetAllPoints()
        glow:SetTexture(EXUI.const.textures.bags.glow)
        glow:SetTexCoord(1, 0, 0, 1)

        local label = button:CreateFontString(nil, 'OVERLAY')
        button.Label = label
        label:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        label:SetPoint('LEFT', 8, 0)
        label:SetJustifyH('LEFT')
        label:SetText(tab.label)

        local line = button:CreateTexture(nil, 'OVERLAY')
        button.Line = line
        line:SetWidth(lineWidth)
        line:SetPoint('TOPLEFT')
        line:SetPoint('BOTTOMLEFT')

        button:SetScript('OnClick', function()
            self:SetMode(tab.id)
        end)
        button:SetScript('OnEnter', function()
            StyleTab(button, self.activeMode == tab.id, true, true)
        end)
        button:SetScript('OnLeave', function()
            StyleTab(button, self.activeMode == tab.id, false, true)
        end)

        if i == 1 then
            button:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
        else
            button:SetPoint('TOPLEFT', self.modeButtons[i - 1], 'BOTTOMLEFT', 0, -TAB_GAP)
        end

        self.modeButtons[i] = button
        StyleTab(button, tab.id == self.activeMode, false, true)
    end
end

bankWindow.UpdateFilterTabs = function(self)
    for i = 1, #self.tabButtons do
        local button = self.tabButtons[i]
        StyleTab(button, button.tabID == self.activeTab, false)
    end
end

bankWindow.UpdateModeTabs = function(self)
    for i = 1, #self.modeButtons do
        local button = self.modeButtons[i]
        local canView = CanViewBankType(button.bankType)
        button:SetShown(canView)
        StyleTab(button, button.modeID == self.activeMode, false, true)
    end
end

bankWindow.SetTab = function(self, tabID)
    if self.activeTab == tabID then
        return
    end
    self.activeTab = tabID
    self:UpdateFilterTabs()
    GetBags():RefreshBank()
end

bankWindow.SetMode = function(self, modeID)
    if self.activeMode == modeID then
        return
    end
    self.activeMode = modeID
    self:UpdateModeTabs()
    GetBags():RefreshBank()
end

bankWindow.CreateHeaderBar = function(self, parent)
    local bar = CreateFrame('Frame', nil, parent)
    self.headerBar = bar
    bar:SetPoint('TOPLEFT', PAD, 0)
    bar:SetPoint('BOTTOMRIGHT', -PAD, 0)

    local sortBtn = CreateHeaderButton(bar, 'Sort', EXUI.const.textures.bags.sort)
    self.sortButton = sortBtn
    sortBtn:SetScript('OnClick', function()
        if C_Container.SortBank then
            C_Container.SortBank(GetBankType())
        end
    end)

    local depositBtn = CreateHeaderButton(bar, 'Deposit', EXUI.const.textures.bags.deposit)
    self.depositButton = depositBtn
    depositBtn:SetScript('OnClick', function()
        local bankType = GetBankType()
        if bankType == Enum.BankType.Account and StaticPopupDialogs['ACCOUNT_BANK_DEPOSIT_ALL_NO_REFUND_CONFIRM'] then
            local hasRefundable
            if ItemUtil and ItemUtil.IteratePlayerInventory then
                hasRefundable = ItemUtil.IteratePlayerInventory(function(itemLocation)
                    return C_Bank.IsItemAllowedInBankType(Enum.BankType.Account, itemLocation)
                        and C_Item.CanBeRefunded(itemLocation)
                end)
            end
            if hasRefundable then
                StaticPopup_Show('ACCOUNT_BANK_DEPOSIT_ALL_NO_REFUND_CONFIRM', nil, nil, { bankType = bankType })
                return
            end
        end
        C_Bank.AutoDepositItemsIntoBank(bankType)
    end)

    local buyBtn = CreateHeaderButton(bar, 'Buy Tab', EXUI.const.textures.bags.buyTab)
    self.buyTabButton = buyBtn
    buyBtn:SetScript('OnClick', function()
        StaticPopup_Show('CONFIRM_BUY_BANK_TAB', nil, nil, { bankType = GetBankType() })
    end)

    self.searchBox = slots:CreateSearchBox(bar, 'bank')

    local closeBtn = CreateFrame('Button', nil, bar)
    self.closeButton = closeBtn

    local theme = EXFrames.Theme
    local closeBg = closeBtn:CreateTexture(nil, 'BACKGROUND')
    closeBtn.Background = closeBg
    closeBg:SetAllPoints()
    closeBg:SetTexture(EXFrames.assets.textures.ui.buttonBg)
    closeBg:SetTextureSliceMargins(6, 6, 6, 6)
    closeBg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    closeBg:SetVertexColor(unpack(theme.faded))

    local closeIcon = closeBtn:CreateTexture(nil, 'OVERLAY')
    closeBtn.Icon = closeIcon
    closeIcon:SetTexture(EXFrames.assets.textures.icon.close)
    closeIcon:SetVertexColor(unpack(EXUI.const.theme.textMuted))
    closeIcon:SetPoint('CENTER')

    closeBtn:SetScript('OnClick', function()
        GetBags():CloseBank()
    end)
    closeBtn:SetScript('OnEnter', function()
        closeBg:SetVertexColor(unpack(theme.dangerHover))
        closeIcon:SetVertexColor(1, 1, 1, 1)
    end)
    closeBtn:SetScript('OnLeave', function()
        closeBg:SetVertexColor(unpack(theme.faded))
        closeIcon:SetVertexColor(unpack(EXUI.const.theme.textMuted))
    end)
end

bankWindow.LayoutHeaderButtons = function(self, bagSize)
    SizeHeaderButton(self.sortButton, bagSize)
    SizeHeaderButton(self.depositButton, bagSize)
    SizeHeaderButton(self.buyTabButton, bagSize)

    local iconSize = math.max(12, bagSize - 8)
    self.closeButton:SetSize(math.max(22, math.floor(bagSize * 1.35)), bagSize)
    local closeIconSize = math.max(14, bagSize - 4)
    self.closeButton.Icon:SetSize(closeIconSize, closeIconSize)

    local bankType = GetBankType()
    local canDeposit = C_Bank.DoesBankTypeSupportAutoDeposit and C_Bank.DoesBankTypeSupportAutoDeposit(bankType)
    self.depositButton:SetShown(canDeposit ~= false)

    local canBuy = C_Bank.CanPurchaseBankTab and C_Bank.CanPurchaseBankTab(bankType)
        and not (C_Bank.HasMaxBankTabs and C_Bank.HasMaxBankTabs(bankType))
    self.buyTabButton:SetShown(canBuy)

    self.buyTabButton.tooltip = nil
    self.buyTabButton.tooltipLines = nil
    if canBuy and C_Bank.FetchNextPurchasableBankTabData then
        local tabData = C_Bank.FetchNextPurchasableBankTabData(bankType)
        if tabData then
            self.buyTabButton.tooltip = tabData.purchasePromptTitle or 'Buy Tab'
            local lines = {}
            if tabData.purchasePromptBody then
                lines[#lines + 1] = tabData.purchasePromptBody
            end
            if tabData.tabCost then
                lines[#lines + 1] = GetCoinTextureString(tabData.tabCost)
            end
            self.buyTabButton.tooltipLines = lines
        end
    end

    self.closeButton:ClearAllPoints()
    self.closeButton:SetPoint('RIGHT', 0, 0)

    local prev = self.closeButton
    local order = { self.buyTabButton, self.depositButton, self.sortButton }
    for i = 1, #order do
        local button = order[i]
        if button:IsShown() then
            button:ClearAllPoints()
            button:SetPoint('RIGHT', prev, 'LEFT', -HEADER_BTN_GAP, 0)
            prev = button
        end
    end

    self.searchBox:SetSize(150, math.max(20, bagSize))
    self.searchBox:ClearAllPoints()
    if prev then
        self.searchBox:SetPoint('RIGHT', prev, 'LEFT', -12, 0)
    else
        self.searchBox:SetPoint('RIGHT', 0, 0)
    end
end

bankWindow.CreateFooter = function(self, parent)
    local footer = CreateFrame('Frame', nil, parent)
    self.footerContent = footer
    footer:SetPoint('TOPLEFT', PAD, 0)
    footer:SetPoint('BOTTOMRIGHT', -PAD, 0)

    local gold = footer:CreateFontString(nil, 'OVERLAY')
    self.goldText = gold
    gold:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    gold:SetPoint('LEFT', 0, 0)
    gold:SetTextColor(unpack(EXUI.const.theme.text))

    local withdraw = CreateHeaderButton(footer, 'Withdraw', nil)
    self.withdrawGoldButton = withdraw
    withdraw.Icon:Hide()
    withdraw:SetScript('OnClick', function()
        StaticPopup_Hide('BANK_MONEY_DEPOSIT')
        if StaticPopup_Visible('BANK_MONEY_WITHDRAW') then
            StaticPopup_Hide('BANK_MONEY_WITHDRAW')
            return
        end
        StaticPopup_Show('BANK_MONEY_WITHDRAW', nil, nil, { bankType = Enum.BankType.Account })
    end)

    local deposit = CreateHeaderButton(footer, 'Deposit', nil)
    self.depositGoldButton = deposit
    deposit.Icon:Hide()
    deposit:SetScript('OnClick', function()
        StaticPopup_Hide('BANK_MONEY_WITHDRAW')
        if StaticPopup_Visible('BANK_MONEY_DEPOSIT') then
            StaticPopup_Hide('BANK_MONEY_DEPOSIT')
            return
        end
        StaticPopup_Show('BANK_MONEY_DEPOSIT', nil, nil, { bankType = Enum.BankType.Account })
    end)
end

bankWindow.UpdateFooter = function(self)
    local amount = 0
    if C_Bank and C_Bank.FetchDepositedMoney then
        amount = C_Bank.FetchDepositedMoney(Enum.BankType.Account) or 0
    end
    self.goldText:SetText(FormatMoney(amount))

    local transfer = C_Bank.DoesBankTypeSupportMoneyTransfer
        and C_Bank.DoesBankTypeSupportMoneyTransfer(Enum.BankType.Account)
    self.depositGoldButton:SetShown(transfer)
    self.withdrawGoldButton:SetShown(transfer)
    if not transfer then
        return
    end

    local canDeposit = not C_Bank.CanDepositMoney or C_Bank.CanDepositMoney(Enum.BankType.Account)
    local canWithdraw = not C_Bank.CanWithdrawMoney or C_Bank.CanWithdrawMoney(Enum.BankType.Account)
    self.depositGoldButton:SetEnabled(canDeposit)
    self.withdrawGoldButton:SetEnabled(canWithdraw)

    SizeHeaderButton(self.depositGoldButton, 20)
    SizeHeaderButton(self.withdrawGoldButton, 20)
    self.depositGoldButton:SetWidth(self.depositGoldButton.Label:GetStringWidth())
    self.withdrawGoldButton:SetWidth(self.withdrawGoldButton.Label:GetStringWidth())

    self.depositGoldButton:ClearAllPoints()
    self.depositGoldButton:SetPoint('RIGHT', 0, 0)
    self.withdrawGoldButton:ClearAllPoints()
    self.withdrawGoldButton:SetPoint('RIGHT', self.depositGoldButton, 'LEFT', -HEADER_BTN_GAP, 0)
end

bankWindow.Create = function(self)
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame('Frame', 'EXUIBankFrame', UIParent)
    self.frame = frame
    frame:SetSize(480, 320)
    frame:SetFrameStrata('HIGH')
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:Hide()

    local main = CreateFrame('Frame', nil, frame)
    self.main = main
    main:SetPoint('TOPLEFT', TAB_WIDTH, 0)
    main:SetPoint('BOTTOMRIGHT', -TAB_WIDTH, 0)
    main:EnableMouse(true)
    main:RegisterForDrag('LeftButton')

    local function startDrag()
        self.dragging = true
        frame:StartMoving()
    end
    local function stopDrag()
        frame:StopMovingOrSizing()
        self.dragging = false
        self:SavePosition()
    end
    frame:SetScript('OnDragStart', startDrag)
    frame:SetScript('OnDragStop', stopDrag)
    main:SetScript('OnDragStart', startDrag)
    main:SetScript('OnDragStop', stopDrag)

    local header = CreateFrame('Frame', nil, main)
    self.header = header
    header:SetHeight(HEADER_HEIGHT)
    header:SetPoint('TOPLEFT')
    header:SetPoint('TOPRIGHT')
    ApplyPanelTextures(header)
    header:EnableMouse(true)
    header:RegisterForDrag('LeftButton')
    header:SetScript('OnDragStart', startDrag)
    header:SetScript('OnDragStop', stopDrag)

    local body = CreateFrame('Frame', nil, main)
    self.body = body
    body:SetPoint('TOPLEFT', header, 'BOTTOMLEFT', 0, -BAR_GAP)
    body:SetPoint('TOPRIGHT', header, 'BOTTOMRIGHT', 0, -BAR_GAP)
    body:SetPoint('BOTTOMLEFT', 0, FOOTER_HEIGHT + BAR_GAP)
    body:SetPoint('BOTTOMRIGHT', 0, FOOTER_HEIGHT + BAR_GAP)
    ApplyPanelTextures(body)
    body:EnableMouse(true)
    body:RegisterForDrag('LeftButton')
    body:SetScript('OnDragStart', startDrag)
    body:SetScript('OnDragStop', stopDrag)

    local footer = CreateFrame('Frame', nil, main)
    self.footer = footer
    footer:SetHeight(FOOTER_HEIGHT)
    footer:SetPoint('BOTTOMLEFT')
    footer:SetPoint('BOTTOMRIGHT')
    ApplyPanelTextures(footer)
    footer:EnableMouse(true)
    footer:RegisterForDrag('LeftButton')
    footer:SetScript('OnDragStart', startDrag)
    footer:SetScript('OnDragStop', stopDrag)

    self.tabs = CreateFrame('Frame', nil, frame)
    self.tabs:SetWidth(TAB_WIDTH)
    self.tabs:SetPoint('TOPLEFT', 0, -HEADER_HEIGHT - BAR_GAP - PAD)
    self.tabs:SetPoint('BOTTOMLEFT', 0, FOOTER_HEIGHT + BAR_GAP)
    self:CreateFilterTabs(self.tabs)

    self.modeTabs = CreateFrame('Frame', nil, frame)
    self.modeTabs:SetWidth(TAB_WIDTH)
    self.modeTabs:SetPoint('TOPRIGHT', 0, -HEADER_HEIGHT - BAR_GAP - PAD)
    self.modeTabs:SetPoint('BOTTOMRIGHT', 0, FOOTER_HEIGHT + BAR_GAP)
    self:CreateModeTabs(self.modeTabs)

    self:CreateHeaderBar(header)

    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    self.scroll = scroll
    scroll:SetParent(body)
    scroll:ClearAllPoints()
    scroll:SetPoint('TOPLEFT', 0, -(PAD - CLIP_INSET))
    scroll:SetPoint('BOTTOMRIGHT', -(PAD - CLIP_INSET), PAD - CLIP_INSET)
    self.content = scroll.child
    self.content:EnableMouseWheel(true)
    self.content:SetScript('OnMouseWheel', scroll:GetScript('OnMouseWheel'))

    self:CreateFooter(footer)
    views:CreateHeaders(self.content, POOL)
    slots:EnsurePool(self.content, 1, POOL)

    frame:SetScript('OnShow', function()
        GetBags():OnBankShown()
    end)
    frame:SetScript('OnHide', function()
        GetBags():OnBankHidden()
    end)

    tinsert(UISpecialFrames, 'EXUIBankFrame')
    self:RestorePosition()
    return frame
end

bankWindow.GetTabStackHeight = function(self)
    return #FILTER_TABS * TAB_HEIGHT + (#FILTER_TABS - 1) * TAB_GAP
end

bankWindow.GetContentWidth = function(self, layout)
    return layout.columns * layout.slotSize + (layout.columns - 1) * layout.spacing
end

bankWindow.GetChildWidth = function(self, layout)
    return PAD + self:GetContentWidth(layout) + CLIP_INSET
end

bankWindow.GetScrollGutter = function(self)
    local scroll = self.scroll
    if not scroll then
        return SCROLL_GUTTER
    end
    local barSpace = (scroll.scrollbarWidth or 4) + (scroll.scrollbarPadding or 2) * 2
    return math.max(SCROLL_GUTTER, barSpace + 8)
end

bankWindow.ApplySize = function(self, bagsHeight)
    local layout = GetBags():GetLayoutSettings('bank')
    local contentWidth = self:GetContentWidth(layout)
    local mainWidth = contentWidth + PAD * 2 + self:GetScrollGutter()
    local bodyInner = math.max(bagsHeight, self:GetTabStackHeight())
    local height = HEADER_HEIGHT + BAR_GAP + bodyInner + PAD * 2 + BAR_GAP + FOOTER_HEIGHT
    local totalWidth = TAB_WIDTH + mainWidth + TAB_WIDTH

    local sizeChanged = math.abs((self.frame:GetWidth() or 0) - totalWidth) > 0.5
        or math.abs((self.frame:GetHeight() or 0) - height) > 0.5
    if sizeChanged then
        self.frame:SetSize(totalWidth, height)
        if not self.dragging then
            self:ClampToScreen()
        end
    end
    self.main:ClearAllPoints()
    self.main:SetPoint('TOPLEFT', TAB_WIDTH, 0)
    self.main:SetPoint('BOTTOMRIGHT', -TAB_WIDTH, 0)

    local bagSize = math.max(20, math.floor(layout.slotSize * 0.62))
    self:LayoutHeaderButtons(bagSize)
end

bankWindow.ClampToScreen = function(self)
    if self.dragging then
        return
    end
    local left, bottom = self.frame:GetLeft(), self.frame:GetBottom()
    if not left then
        return
    end
    local width, height = self.frame:GetWidth(), self.frame:GetHeight()
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    if left < 0 then
        left = 0
    end
    if bottom < 0 then
        bottom = 0
    end
    if left + width > screenW then
        left = screenW - width
    end
    if bottom + height > screenH then
        bottom = screenH - height
    end
    self.frame:ClearAllPoints()
    self.frame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', left, bottom)
end

bankWindow.SavePosition = function(self)
    if not self.frame or not self.frame:GetLeft() then
        return
    end
    local left, bottom = self.frame:GetLeft(), self.frame:GetBottom()
    GetBags().Data:SetValue('bankPosX', left)
    GetBags().Data:SetValue('bankPosY', bottom)
end

bankWindow.RestorePosition = function(self)
    local x = GetBags().Data:GetValue('bankPosX')
    local y = GetBags().Data:GetValue('bankPosY')
    self.frame:ClearAllPoints()
    if x and y then
        self.frame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', x, y)
    else
        self.frame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 80, 140)
    end
end

bankWindow.GetViewContext = function(self)
    return {
        pool = POOL,
        headerSet = POOL,
        bagIDs = FetchTabIDs(GetBankType()),
    }
end

bankWindow.GetLayoutSignature = function(self)
    local layout = GetBags():GetLayoutSettings('bank')
    local bagIDs = FetchTabIDs(GetBankType())
    local parts = { self.activeTab, self.activeMode, layout.slotSize, layout.columns, layout.spacing }
    for i = 1, #bagIDs do
        parts[#parts + 1] = bagIDs[i]
        parts[#parts + 1] = C_Container.GetContainerNumSlots(bagIDs[i]) or 0
    end
    return table.concat(parts, ':')
end

bankWindow.NeedsLayout = function(self)
    if not self.layoutSignature or self.activeTab ~= 'bags' then
        return true
    end
    return self.layoutSignature ~= self:GetLayoutSignature()
end

bankWindow.RefreshContents = function(self)
    slots:UpdateVisible(POOL)
    self:UpdateFooter()
end

bankWindow.LayoutIfNeeded = function(self)
    if self:NeedsLayout() then
        self:Layout()
    else
        self:RefreshContents()
    end
end

bankWindow.Layout = function(self)
    if not self.frame then
        return
    end
    local layout = GetBags():GetLayoutSettings('bank')
    if (self.laidOutTab ~= self.activeTab or self.laidOutMode ~= self.activeMode) and self.scroll then
        self.scroll:SetVerticalScroll(0)
        self.laidOutTab = self.activeTab
        self.laidOutMode = self.activeMode
    end

    self:UpdateModeTabs()
    local context = self:GetViewContext()
    slots:EnsurePool(self.content, slots:RequiredCountForBags(context.bagIDs), POOL)
    local contentHeight = views:Layout(self.content, self.activeTab, context)
    local personalHeight = views:MeasureGridHeight(FetchTabIDs(Enum.BankType.Character))
    self:ApplySize(personalHeight)
    if self.scroll then
        self.content:SetHeight(math.max(contentHeight, 1))
        self.scroll:UpdateScrollChild(self:GetChildWidth(layout), math.max(contentHeight, 1))
    end
    self:UpdateFooter()
    self.layoutSignature = self:GetLayoutSignature()
end

bankWindow.Show = function(self)
    self:Create()
    if not CanViewBankType(Enum.BankType.Character) and CanViewBankType(Enum.BankType.Account) then
        self.activeMode = 'warband'
    elseif CanViewBankType(Enum.BankType.Character) then
        self.activeMode = 'personal'
    end
    self:UpdateModeTabs()
    if self.frame:IsShown() then
        self:LayoutIfNeeded()
        return
    end
    self.frame:Show()
    self:LayoutIfNeeded()
end

bankWindow.Hide = function(self)
    if not self.frame or not self.frame:IsShown() then
        return
    end
    if self.searchBox then
        self.searchBox:ClearFocus()
        self.searchBox:SetText('')
    end
    self.frame:Hide()
end

bankWindow.IsShown = function(self)
    return self.frame and self.frame:IsShown()
end
