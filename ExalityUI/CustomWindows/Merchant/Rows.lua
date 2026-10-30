---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIMerchantWindowRows
local rows = EXUI:GetModule('merchant-window-rows')

---@class EXUIMerchantWindowBulk
local bulk = EXUI:GetModule('merchant-window-bulk')

---@class EXUIMerchantWindowSprite
local sprite = EXUI:GetModule('merchant-window-sprite')

rows.pool = {}

local ROW_SCALE = 0.7
local ROW_WIDTH = 302 * ROW_SCALE
local ROW_HEIGHT = 76 * ROW_SCALE
local ROW_GAP_X = 8
local ROW_GAP_Y = 7
local COLUMNS = 2
local ICON_SIZE = 54 * ROW_SCALE
local ICON_INSET = 11 * ROW_SCALE
local CART_SIZE = 16
local CART_SCALE = 0.36
local TEXT_INSET = 8
local MAX_COST_ITEMS = 3

rows.perPage = 12
rows.gridWidth = ROW_WIDTH * COLUMNS + ROW_GAP_X * (COLUMNS - 1)
rows.gridHeight = (rows.perPage / COLUMNS) * (ROW_HEIGHT + ROW_GAP_Y) - ROW_GAP_Y

local function SellCursorItem()
    if (MerchantFrame.refundItem) then
        if (ContainerFrame_GetExtendedPriceString(MerchantFrame.refundItem, MerchantFrame.refundItemEquipped)) then
            return
        end
    end
    PickupMerchantItem(0)
end
rows.SellCursorItem = SellCursorItem

local function UpdateHoverCursor(self)
    if (IsModifiedClick('DRESSUP')) then
        ShowInspectCursor()
    elseif (CanAffordMerchantItem(self:GetID()) == false) then
        SetCursor('BUY_ERROR_CURSOR')
    else
        SetCursor('BUY_CURSOR')
    end
end

local function SetHover(row, hovered)
    sprite:Apply(row.border, hovered and 'itemBorderHover' or 'itemBorder', ROW_SCALE)
end

local function CreateCart(row)
    local cart = sprite:CreateButton(row, CART_SIZE, CART_SIZE, 'cartOff', 'cartOn', CART_SCALE)
    cart:SetPoint('BOTTOMLEFT', row.icon, 'BOTTOMRIGHT', 8, 1)
    cart:SetScript('OnClick', function()
        bulk:Open(row)
    end)
    -- Entering a child fires the row's OnLeave, so the cart carries the row's hover state.
    cart:HookScript('OnEnter', function(self)
        SetHover(row, true)
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Buy in bulk')
        GameTooltip:Show()
    end)
    cart:HookScript('OnLeave', function()
        SetHover(row, false)
        GameTooltip_Hide()
    end)
    row.cart = cart
end

local function CreateRow(parent)
    local theme = EXUI.const.theme
    local row = CreateFrame('Button', nil, parent)
    row:SetSize(ROW_WIDTH, ROW_HEIGHT)

    -- Sets clicks, drag, SplitStack and UpdateTooltip, so Blizzard's item handlers accept this row.
    MerchantItemButton_OnLoad(row)

    local background = row:CreateTexture(nil, 'BACKGROUND')
    background:SetPoint('CENTER')
    sprite:Apply(background, 'itemBg', ROW_SCALE)

    local border = row:CreateTexture(nil, 'BORDER')
    border:SetPoint('CENTER')
    row.border = border
    SetHover(row, false)

    local icon = row:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint('LEFT', ICON_INSET, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local mask = row:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(sprite.iconMask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)

    local iconBorder = row:CreateTexture(nil, 'ARTWORK', nil, 1)
    iconBorder:SetPoint('CENTER', icon, 'CENTER')
    sprite:Apply(iconBorder, 'iconBorder', ROW_SCALE)
    row.iconBorder = iconBorder

    local questIcon = row:CreateTexture(nil, 'OVERLAY')
    questIcon:SetAllPoints(icon)
    questIcon:SetTexture(TEXTURE_ITEM_QUEST_BANG)
    questIcon:Hide()
    row.questIcon = questIcon

    local count = row:CreateFontString(nil, 'OVERLAY', nil, 1)
    count:SetFont(EXUI.const.fonts.DEFAULT, 14, 'OUTLINE')
    count:SetPoint('TOPRIGHT', icon, 'TOPRIGHT', -3, -3)
    row.countText = count

    local stock = row:CreateFontString(nil, 'OVERLAY', nil, 1)
    stock:SetFont(EXUI.const.fonts.DEFAULT, 9, 'OUTLINE')
    stock:SetPoint('TOPLEFT', icon, 'TOPLEFT', 3, -3)
    stock:SetTextColor(unpack(theme.inProgress))
    row.stockText = stock

    local name = row:CreateFontString(nil, 'OVERLAY')
    name:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    name:SetPoint('TOPLEFT', icon, 'TOPRIGHT', 8, -1)
    name:SetPoint('RIGHT', row, 'RIGHT', -TEXT_INSET, 0)
    name:SetJustifyH('LEFT')
    name:SetWordWrap(false)
    row.nameText = name

    CreateCart(row)

    local cost = row:CreateFontString(nil, 'OVERLAY')
    cost:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    cost:SetPoint('BOTTOMRIGHT', row, 'BOTTOMRIGHT', -TEXT_INSET, TEXT_INSET)
    cost:SetPoint('LEFT', row.cart, 'RIGHT', 4, 0)
    cost:SetJustifyH('RIGHT')
    cost:SetWordWrap(false)
    row.costText = cost

    row:SetScript('OnClick', function(self, button)
        local isMerchantTab = MerchantFrame.selectedTab == 1
        if (isMerchantTab and IsModifiedClick('SPLITSTACK')) then
            if (not HandleModifiedItemClick(GetMerchantItemLink(self:GetID()))) then
                bulk:Open(self)
            end
        elseif (IsModifiedClick()) then
            MerchantItemButton_OnModifiedClick(self, button)
        elseif (isMerchantTab and CursorHasItem()) then
            SellCursorItem()
        else
            -- Blizzard's right-click path buys straight away and keeps its confirmation prompts.
            MerchantItemButton_OnClick(self, 'RightButton')
        end
    end)
    row:SetScript('OnDragStart', function(self)
        MerchantItemButton_OnClick(self, 'LeftButton')
    end)
    row:SetScript('OnReceiveDrag', SellCursorItem)
    row:SetScript('OnEnter', function(self)
        SetHover(self, true)
        MerchantItemButton_OnEnter(self)
        if (MerchantFrame.selectedTab == 1) then
            self:SetScript('OnUpdate', UpdateHoverCursor)
        end
    end)
    row:SetScript('OnLeave', function(self)
        SetHover(self, false)
        self:SetScript('OnUpdate', nil)
        MerchantFrame.itemHover = nil
        GameTooltip_HideResetCursor()
    end)
    row:SetScript('OnHide', function(self)
        SetHover(self, false)
        self:SetScript('OnUpdate', nil)
        if (GameTooltip:IsOwned(self)) then
            MerchantFrame.itemHover = nil
            GameTooltip_HideResetCursor()
        end
    end)

    return row
end

local function ApplyQuality(row, link)
    local theme = EXUI.const.theme
    local quality = link and select(3, C_Item.GetItemInfo(link))
    if (quality) then
        local r, g, b = C_Item.GetItemQualityColor(quality)
        row.nameText:SetTextColor(r, g, b)
        if (quality >= Enum.ItemQuality.Uncommon) then
            row.iconBorder:SetVertexColor(r, g, b, 1)
        else
            row.iconBorder:SetVertexColor(unpack(theme.border))
        end
        return true
    end

    row.nameText:SetTextColor(unpack(theme.text))
    row.iconBorder:SetVertexColor(unpack(theme.border))
    return link == nil
end

local function ApplyCommon(row, index, name, texture, stackCount, numAvailable)
    row:SetID(index)
    row.name = name
    row.texture = texture
    row.count = stackCount
    row.hasItem = true
    row.nameText:SetText(name)
    row.icon:SetTexture(texture)
    row.countText:SetText(stackCount and stackCount > 1 and stackCount or '')
    row.stockText:SetText(numAvailable and numAvailable > 0 and numAvailable or '')
    row:Show()
end

local function BuildCost(index, price, multiplier)
    multiplier = multiplier or 1
    local parts = {}
    if (price and price > 0) then
        parts[#parts + 1] = C_CurrencyInfo.GetCoinTextureString(price * multiplier)
    end
    for i = 1, MAX_COST_ITEMS do
        local texture, value = GetMerchantItemCostItem(index, i)
        if (texture) then
            parts[#parts + 1] = string.format('|T%s:14:14:0:0:64:64:5:59:5:59|t %s', texture, value * multiplier)
        end
    end
    return table.concat(parts, '  ')
end
rows.BuildCost = BuildCost

local function ApplyIconTint(row, r, g, b)
    row.icon:SetVertexColor(r, g, b)
end

rows.Acquire = function(self, slot, parent)
    local row = self.pool[slot]
    if (not row) then
        row = CreateRow(parent)
        local column = (slot - 1) % COLUMNS
        local line = math.floor((slot - 1) / COLUMNS)
        row:SetPoint('TOPLEFT', parent, 'TOPLEFT', column * (ROW_WIDTH + ROW_GAP_X), -line * (ROW_HEIGHT + ROW_GAP_Y))
        self.pool[slot] = row
    end
    return row
end

---@return boolean itemDataLoaded false when the item needs GET_ITEM_INFO_RECEIVED to finish
rows.FillMerchant = function(self, row, index)
    local info = C_MerchantFrame.GetItemInfo(index)
    if (not info) then
        row:Hide()
        return true
    end

    if (info.currencyID) then
        info.name, info.texture, info.numAvailable = CurrencyContainerUtil.GetCurrencyContainerInfo(
            info.currencyID, info.numAvailable, info.name, info.texture, nil)
    end

    local link = GetMerchantItemLink(index)
    row.link = link
    row.extendedCost = info.hasExtendedCost or nil
    row.price = (info.price > 0 or not info.hasExtendedCost) and info.price or nil
    row.showNonrefundablePrompt = not C_MerchantFrame.IsMerchantItemRefundable(index)
    ApplyCommon(row, index, info.name, info.texture, info.stackCount, info.numAvailable)

    local theme = EXUI.const.theme
    local canAfford = CanAffordMerchantItem(index)
    row.costText:SetText(BuildCost(index, info.price))
    row.costText:SetTextColor(unpack(canAfford == false and theme.danger or theme.text))
    row.questIcon:SetShown(info.isQuestStartItem)
    row.cart:Show()

    local itemID = GetMerchantItemID(index)
    local isHeirloom = itemID and C_Heirloom.IsItemHeirloom(itemID)
    local isKnownHeirloom = isHeirloom and C_Heirloom.PlayerHasHeirloom(itemID)
    local tintRed = not info.isPurchasable or (not info.isUsable and not isHeirloom)
    local dimmed = info.numAvailable == 0 or isKnownHeirloom

    row.icon:SetDesaturated(isKnownHeirloom)
    if (tintRed) then
        ApplyIconTint(row, dimmed and 0.5 or 0.9, 0, 0)
    elseif (dimmed) then
        ApplyIconTint(row, 0.5, 0.5, 0.5)
    else
        ApplyIconTint(row, 1, 1, 1)
    end

    return ApplyQuality(row, link)
end

---@return boolean itemDataLoaded false when the item needs GET_ITEM_INFO_RECEIVED to finish
rows.FillBuyback = function(self, row, index)
    local name, texture, price, quantity, numAvailable, isUsable = GetBuybackItemInfo(index)
    if (not name) then
        row:Hide()
        return true
    end

    local link = GetBuybackItemLink(index)
    row.link = link
    row.price = price
    row.extendedCost = nil
    row.showNonrefundablePrompt = nil
    ApplyCommon(row, index, name, texture, quantity, numAvailable)

    row.costText:SetText(C_CurrencyInfo.GetCoinTextureString(price))
    row.costText:SetTextColor(unpack(EXUI.const.theme.text))
    row.questIcon:Hide()
    row.cart:Hide()
    row.icon:SetDesaturated(false)
    if (isUsable) then
        ApplyIconTint(row, 1, 1, 1)
    else
        ApplyIconTint(row, 0.9, 0, 0)
    end

    return ApplyQuality(row, link)
end

rows.HideFrom = function(self, slot)
    for i = slot, #self.pool do
        self.pool[i].hasItem = nil
        self.pool[i]:Hide()
    end
end
