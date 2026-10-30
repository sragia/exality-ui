---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesSimpleButton
local simpleButton = EXFrames:GetFrame('simple-button')

---@class EXUIMerchantWindowRows
local rows = EXUI:GetModule('merchant-window-rows')

---@class EXUIMerchantWindow
local merchant = EXUI:GetModule('merchant-window')

---@class EXUIMerchantWindowBulk
local bulk = EXUI:GetModule('merchant-window-bulk')

bulk.panel = nil
bulk.row = nil
bulk.index = nil
bulk.itemID = nil
bulk.ticker = nil

local PANEL_WIDTH = 190
local PANEL_HEIGHT = 118
local PAD = 10
local STEP_SIZE = 26
local CONTROL_GAP = 6
local BUTTON_HEIGHT = 24
local ART_SLICE = 8
local BUY_INTERVAL = 0.2
local MAX_COST_ITEMS = 3

local function GetOwnedCost(link, currencyName)
    if (currencyName) then
        local currency = C_CurrencyInfo.GetCurrencyInfoFromLink(link)
        return currency and currency.quantity
    end
    return C_Item.GetItemCount(link, false, false, true)
end

-- Whole stacks the player can get right now, limited by vendor stock, gold and cost items.
local function GetMaxStacks(index, info)
    local maxStacks = math.huge
    if (info.numAvailable >= 0) then
        maxStacks = info.numAvailable
    end
    if (info.price > 0) then
        maxStacks = math.min(maxStacks, math.floor(GetMoney() / info.price))
    end
    for i = 1, MAX_COST_ITEMS do
        local _, value, link, currencyName = GetMerchantItemCostItem(index, i)
        local owned = link and value and value > 0 and GetOwnedCost(link, currencyName)
        if (owned) then
            maxStacks = math.min(maxStacks, math.floor(owned / value))
        end
    end
    return maxStacks
end

local function GetOrder(self)
    local info = C_MerchantFrame.GetItemInfo(self.index)
    if (not info) then
        return nil
    end

    local stackSize = math.max(info.stackCount, 1)
    local requested = self.panel.input:GetNumber()
    local wantedStacks = math.ceil(requested / stackSize)
    local maxStacks = GetMaxStacks(self.index, info)

    return {
        info = info,
        stackSize = stackSize,
        stacks = math.min(wantedStacks, maxStacks),
        limited = wantedStacks > maxStacks,
        stacksPerBuy = math.max(math.floor(GetMerchantItemMaxStack(self.index) / stackSize), 1),
    }
end

bulk.Stop = function(self)
    if (self.ticker) then
        self.ticker:Cancel()
        self.ticker = nil
    end
end

bulk.StartPurchase = function(self, index, itemID, stacks, stackSize, stacksPerBuy)
    self:Stop()

    local remaining = stacks
    local function BuyNext()
        if (not merchant.isOpen or GetMerchantItemID(index) ~= itemID) then
            self:Stop()
            return
        end
        local amount = math.min(stacksPerBuy, remaining)
        BuyMerchantItem(index, amount * stackSize)
        remaining = remaining - amount
        if (remaining <= 0) then
            self:Stop()
        end
    end

    BuyNext()
    if (remaining > 0 and merchant.isOpen) then
        self.ticker = C_Timer.NewTicker(BUY_INTERVAL, BuyNext)
    end
end

bulk.Submit = function(self)
    local order = GetOrder(self)
    if (not order or order.stacks <= 0) then
        return
    end

    local index, itemID, row = self.index, self.itemID, self.row
    local totalPrice = order.info.price * order.stacks
    local hasCostItems = GetMerchantItemCostInfo(index) > 0
    local isSingleBuy = order.stacks <= order.stacksPerBuy
    self:Hide()

    -- A single purchase with cost items keeps Blizzard's prompts, including limited currency warnings.
    if (hasCostItems and isSingleBuy) then
        row:SplitStack(order.stacks * order.stackSize)
        return
    end

    local function Buy()
        self:StartPurchase(index, itemID, order.stacks, order.stackSize, order.stacksPerBuy)
    end

    if (hasCostItems or totalPrice >= MERCHANT_HIGH_PRICE_COST) then
        StaticPopup_ShowCustomGenericConfirmation({
            text = string.format('Buy %d x %s for %s?', order.stacks * order.stackSize, order.info.name,
                rows.BuildCost(index, order.info.price, order.stacks)),
            callback = Buy,
        })
    else
        Buy()
    end
end

bulk.Update = function(self)
    local panel = self.panel
    local order = GetOrder(self)
    if (not order) then
        self:Hide()
        return
    end

    local theme = EXUI.const.theme
    local total = order.stacks * order.stackSize
    if (order.limited) then
        panel.totalText:SetText(string.format('You can only get %d', total))
        panel.totalText:SetTextColor(unpack(theme.danger))
    else
        panel.totalText:SetText('Buying')
        panel.totalText:SetTextColor(unpack(theme.text))
    end
    panel.costText:SetText(order.stacks > 0 and rows.BuildCost(self.index, order.info.price, order.stacks) or '')
    panel.buy:SetEnabled(order.stacks > 0)
    panel.buy:SetAlpha(order.stacks > 0 and 1 or 0.5)
end

bulk.Step = function(self, direction)
    local stackSize = math.max(self.row.count or 1, 1)
    local stacks = math.ceil(self.panel.input:GetNumber() / stackSize)
    self.panel.input:SetNumber(math.max(stacks + direction, 1) * stackSize)
end

local function CreateArt(frame, fillColor)
    local fill = frame:CreateTexture(nil, 'BACKGROUND')
    fill:SetTexture(EXFrames.assets.textures.ui.panelBg)
    fill:SetVertexColor(unpack(fillColor))
    fill:SetTextureSliceMargins(ART_SLICE, ART_SLICE, ART_SLICE, ART_SLICE)
    fill:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    fill:SetAllPoints()

    local border = frame:CreateTexture(nil, 'BORDER')
    border:SetTexture(EXFrames.assets.textures.ui.panelBorder)
    border:SetVertexColor(unpack(EXUI.const.theme.border))
    border:SetTextureSliceMargins(ART_SLICE, ART_SLICE, ART_SLICE, ART_SLICE)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    border:SetAllPoints()
end

local function CreateButton(parent, label, onClick)
    local button = simpleButton:Create(parent)
    button:SetText(label)
    button:SetOnClick(onClick)
    return button
end

local function CreateStepButton(parent, label, direction)
    local button = CreateButton(parent, label, function()
        bulk:Step(direction)
    end)
    button:SetSize(STEP_SIZE, STEP_SIZE)
    button.text:SetFont(EXUI.const.fonts.DEFAULT, 14, 'OUTLINE')
    return button
end

bulk.Create = function(self, parent)
    if (self.panel) then
        return
    end

    local theme = EXUI.const.theme
    local panel = CreateFrame('Frame', nil, parent)
    panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    panel:SetFrameStrata('DIALOG')
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:Hide()
    CreateArt(panel, theme.backgroundDeep)
    self.panel = panel

    local totalText = panel:CreateFontString(nil, 'OVERLAY')
    totalText:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    totalText:SetPoint('TOPLEFT', PAD, -PAD)
    totalText:SetPoint('TOPRIGHT', -PAD, -PAD)
    totalText:SetWordWrap(false)
    panel.totalText = totalText

    local minus = CreateStepButton(panel, '-', -1)
    minus:SetPoint('TOPLEFT', PAD, -28)

    local plus = CreateStepButton(panel, '+', 1)
    plus:SetPoint('TOPRIGHT', -PAD, -28)

    local input = CreateFrame('EditBox', nil, panel)
    input:SetHeight(STEP_SIZE)
    input:SetPoint('LEFT', minus, 'RIGHT', CONTROL_GAP, 0)
    input:SetPoint('RIGHT', plus, 'LEFT', -CONTROL_GAP, 0)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    input:SetMaxLetters(6)
    input:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    input:SetTextColor(unpack(theme.text))
    input:SetJustifyH('CENTER')
    input:SetTextInsets(6, 6, 0, 0)
    -- Button art so the box matches the -/+ buttons beside it.
    local inputArt = simpleButton:Create(panel)
    inputArt:SetAllPoints(input)
    inputArt:EnableMouse(false)
    input:SetFrameLevel(inputArt:GetFrameLevel() + 1)
    input:SetScript('OnTextChanged', function()
        if (panel:IsShown()) then
            bulk:Update()
        end
    end)
    input:SetScript('OnEnterPressed', function()
        bulk:Submit()
    end)
    input:SetScript('OnEscapePressed', function()
        bulk:Hide()
    end)
    input:SetScript('OnEditFocusGained', function()
        inputArt.border:SetVertexColor(unpack(theme.accent))
    end)
    input:SetScript('OnEditFocusLost', function()
        inputArt.border:SetVertexColor(unpack(theme.border))
    end)
    panel.input = input

    local costText = panel:CreateFontString(nil, 'OVERLAY')
    costText:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    costText:SetTextColor(unpack(theme.text))
    costText:SetPoint('TOP', input, 'BOTTOM', 0, -7)
    costText:SetPoint('LEFT', PAD, 0)
    costText:SetPoint('RIGHT', -PAD, 0)
    costText:SetWordWrap(false)
    panel.costText = costText

    local buttonWidth = (PANEL_WIDTH - PAD * 2 - CONTROL_GAP) / 2
    local cancel = CreateButton(panel, CANCEL, function()
        bulk:Hide()
    end)
    cancel:SetSize(buttonWidth, BUTTON_HEIGHT)
    cancel:SetPoint('BOTTOMLEFT', PAD, PAD)

    local buy = CreateButton(panel, 'Buy', function()
        bulk:Submit()
    end)
    buy:SetSize(buttonWidth, BUTTON_HEIGHT)
    buy:SetPoint('BOTTOMRIGHT', -PAD, PAD)
    panel.buy = buy
end

bulk.Open = function(self, row)
    self.row = row
    self.index = row:GetID()
    self.itemID = GetMerchantItemID(self.index)

    local panel = self.panel
    local isRightColumn = row:GetLeft() > (panel:GetParent():GetCenter())
    panel:ClearAllPoints()
    if (isRightColumn) then
        panel:SetPoint('TOPRIGHT', row, 'TOPLEFT', -6, 0)
    else
        panel:SetPoint('TOPLEFT', row, 'TOPRIGHT', 6, 0)
    end
    panel:Show()
    panel.input:SetNumber(math.max(row.count or 1, 1))
    panel.input:SetFocus()
    panel.input:HighlightText()
    self:Update()
end

bulk.Hide = function(self)
    if (self.panel and self.panel:IsShown()) then
        self.panel.input:ClearFocus()
        self.panel:Hide()
    end
end

bulk.Refresh = function(self)
    if (not self.panel or not self.panel:IsShown()) then
        return
    end
    if (GetMerchantItemID(self.index) ~= self.itemID) then
        self:Hide()
    else
        self:Update()
    end
end
