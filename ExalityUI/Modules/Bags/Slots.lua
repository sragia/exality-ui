---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIBagsSlots
local slots = EXUI:GetModule('bags-slots')

local BACKPACK = Enum.BagIndex.Backpack
local REAGENT_BAG = Enum.BagIndex.ReagentBag
local FIRST_BAG = Enum.BagIndex.Bag_1
local LAST_BAG = Enum.BagIndex.Bag_4

slots.buttons = {}
slots.bagButtons = {}

local DEFAULT_BORDER = { 69 / 255, 60 / 255, 54 / 255 } -- #453c36

local function HexToRGB(hex)
    if not hex then
        return 1, 1, 1
    end
    hex = hex:gsub('#', '')
    if #hex == 8 then
        return tonumber(hex:sub(3, 4), 16) / 255,
            tonumber(hex:sub(5, 6), 16) / 255,
            tonumber(hex:sub(7, 8), 16) / 255
    end
    if #hex == 6 then
        return tonumber(hex:sub(1, 2), 16) / 255,
            tonumber(hex:sub(3, 4), 16) / 255,
            tonumber(hex:sub(5, 6), 16) / 255
    end
    return 1, 1, 1
end

local function HideDefaultItemButtonArt(button)
    if button.IconBorder then
        button.IconBorder:SetAlpha(0)
        button.IconBorder:Hide()
    end
    if button.IconOverlay then
        button.IconOverlay:Hide()
    end
    if button.IconOverlay2 then
        button.IconOverlay2:Hide()
    end
    if button.NormalTexture then
        button.NormalTexture:SetAlpha(0)
        button.NormalTexture:Hide()
    end
    if button.PushedTexture then
        button.PushedTexture:SetAlpha(0)
        button.PushedTexture:Hide()
    end
    if button.HighlightTexture then
        button.HighlightTexture:SetAlpha(0)
        button.HighlightTexture:Hide()
    end
    if button.SlotBackground then
        button.SlotBackground:Hide()
    end
    if button.ItemContextOverlay then
        button.ItemContextOverlay:Hide()
    end
end

local function ApplyBorderColor(button, r, g, b)
    button.borderR, button.borderG, button.borderB = r, g, b
    if not button.hovered then
        button.Border:SetVertexColor(r, g, b, 1)
    end
end

local function SetHovered(button, hovered)
    button.hovered = hovered
    if hovered then
        button.Border:SetVertexColor(1, 1, 1, 1)
    else
        button.Border:SetVertexColor(button.borderR or 1, button.borderG or 1, button.borderB or 1, 1)
    end
end

local function GetCraftingQualityInfo(itemIDOrLink)
    if not itemIDOrLink or not C_TradeSkillUI then
        return nil
    end
    return C_TradeSkillUI.GetItemReagentQualityInfo(itemIDOrLink)
        or C_TradeSkillUI.GetItemCraftedQualityInfo(itemIDOrLink)
end

local function UpdateQualityIcon(button, itemIDOrLink)
    local icon = button.QualityIcon
    if not icon then
        return
    end
    local qualityInfo = GetCraftingQualityInfo(itemIDOrLink)
    local atlas = qualityInfo and qualityInfo.iconInventory
    if atlas then
        icon:SetAtlas(atlas, true)
        icon:Show()
    else
        icon:Hide()
    end
end

local function SplitStack(button, amount)
    if button.bagID and button:GetID() then
        C_Container.SplitContainerItem(button.bagID, button:GetID(), amount)
    end
end

local function OnModifiedClick(button, mouseButton)
    local bagID, slotID = button.bagID, button:GetID()
    if not bagID or not slotID then
        return
    end

    local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
    if IsModifiedClick('EXPANDITEM') and C_Item.DoesItemExist(itemLocation) then
        if C_Container.SocketContainerItem(bagID, slotID) then
            return
        end
    end

    if HandleModifiedItemClick(C_Container.GetContainerItemLink(bagID, slotID), itemLocation) then
        return
    end

    if not CursorHasItem() and IsModifiedClick('SPLITSTACK') then
        local info = C_Container.GetContainerItemInfo(bagID, slotID)
        if info and not info.isLocked and info.stackCount and info.stackCount > 1 then
            button.SplitStack = SplitStack
            StackSplitFrame:OpenStackSplitFrame(info.stackCount, button, 'BOTTOMRIGHT', 'TOPRIGHT')
        end
    end
end

local function OnItemClick(button, mouseButton)
    local bagID, slotID = button.bagID, button:GetID()
    if not bagID or not slotID then
        return
    end

    if IsModifiedClick() then
        OnModifiedClick(button, mouseButton)
        return
    end

    if mouseButton == 'LeftButton' then
        if SpellCanTargetItem and (SpellCanTargetItem() or (SpellCanTargetItemID and SpellCanTargetItemID())) then
            C_Container.UseContainerItem(bagID, slotID)
        else
            C_Container.PickupContainerItem(bagID, slotID)
        end
        if StackSplitFrame then
            StackSplitFrame:Hide()
        end
    else
        C_Container.UseContainerItem(bagID, slotID)
    end
end

local function OnItemEnter(button)
    SetHovered(button, true)
    local bagID, slotID = button.bagID, button:GetID()
    if not bagID or not slotID then
        return
    end
    GameTooltip:SetOwner(button, 'ANCHOR_TOPLEFT')
    GameTooltip:SetBagItem(bagID, slotID)
    GameTooltip:Show()

    if SpellIsTargeting and SpellIsTargeting() then
        return
    end
    if IsModifiedClick('DRESSUP') then
        ShowInspectCursor()
    elseif MerchantFrame and MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1 then
        C_Container.ShowContainerSellCursor(bagID, slotID)
    else
        ResetCursor()
    end
end

local function OnItemLeave(button)
    SetHovered(button, false)
    GameTooltip:Hide()
    if not SpellIsTargeting or not SpellIsTargeting() then
        ResetCursor()
    end
end

slots.StyleItemButton = function(self, button)
    HideDefaultItemButtonArt(button)

    local empty = button:CreateTexture(nil, 'BACKGROUND')
    button.EmptyTexture = empty
    empty:SetAllPoints()
    empty:SetTexture(EXUI.const.textures.bags.slotEmpty)

    local icon = button.icon or button.Icon
    if not icon then
        icon = button:CreateTexture(nil, 'ARTWORK')
        button.icon = icon
    end
    button.Icon = icon
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local mask = button:CreateMaskTexture()
    button.IconMask = mask
    mask:SetAllPoints(icon)
    mask:SetTexture(EXUI.const.textures.bags.slotMask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)

    local overlay = CreateFrame('Frame', nil, button)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(button:GetFrameLevel() + 4)
    button.Overlay = overlay

    local border = overlay:CreateTexture(nil, 'OVERLAY')
    button.Border = border
    border:SetPoint('TOPLEFT', -1, 1)
    border:SetPoint('BOTTOMRIGHT', 1, -1)
    border:SetTexture(EXUI.const.textures.bags.slotBorder)
    ApplyBorderColor(button, unpack(DEFAULT_BORDER))

    local qualityIcon = overlay:CreateTexture(nil, 'OVERLAY')
    button.QualityIcon = qualityIcon
    qualityIcon:SetPoint('TOPLEFT', 1, -1)
    qualityIcon:Hide()

    local itemLevel = overlay:CreateFontString(nil, 'OVERLAY')
    button.ItemLevel = itemLevel
    itemLevel:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    itemLevel:SetPoint('TOPLEFT', 2, -2)
    itemLevel:SetJustifyH('LEFT')
    itemLevel:SetText('')

    local stackCount = overlay:CreateFontString(nil, 'OVERLAY')
    button.StackCount = stackCount
    stackCount:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    stackCount:SetPoint('TOPRIGHT', -2, -2)
    stackCount:SetJustifyH('RIGHT')
    stackCount:SetText('')

    if button.Count then
        button.Count:Hide()
        button.Count:SetAlpha(0)
    end

    local cooldown = button.Cooldown or CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
    button.Cooldown = cooldown
    cooldown:SetAllPoints()
    cooldown:SetFrameLevel(button:GetFrameLevel() + 2)
    cooldown:SetDrawEdge(false)
    cooldown:SetSwipeColor(0, 0, 0, 0.55)

    button.GetBagID = function(self)
        return self.bagID
    end

    button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    button:RegisterForDrag('LeftButton')
    button:SetScript('OnClick', OnItemClick)
    button:SetScript('OnDragStart', function(self)
        OnItemClick(self, 'LeftButton')
    end)
    button:SetScript('OnReceiveDrag', function(self)
        OnItemClick(self, 'LeftButton')
    end)
    button:SetScript('OnEnter', OnItemEnter)
    button:SetScript('OnLeave', OnItemLeave)
end

slots.Assign = function(self, button, bagID, slotID)
    button.bagID = bagID
    button:SetID(slotID)
end

slots.IsGearItem = function(self, itemID)
    if not itemID then
        return false
    end
    local invType = C_Item.GetItemInventoryTypeByID(itemID)
    if not invType then
        return false
    end
    return invType ~= Enum.InventoryType.IndexNonEquipType
        and invType ~= Enum.InventoryType.IndexBagType
        and invType ~= Enum.InventoryType.IndexQuiverType
        and invType ~= Enum.InventoryType.IndexAmmoType
end

slots.UpdateItemButton = function(self, button)
    local bagID, slotID = button.bagID, button:GetID()
    if not bagID or not slotID then
        button:Hide()
        return
    end

    local info = C_Container.GetContainerItemInfo(bagID, slotID)
    if not info then
        button.Icon:SetTexture(nil)
        button.Icon:Hide()
        button.EmptyTexture:Show()
        button.ItemLevel:SetText('')
        button.StackCount:SetText('')
        if button.QualityIcon then
            button.QualityIcon:Hide()
        end
        ApplyBorderColor(button, unpack(DEFAULT_BORDER))
        if button.Cooldown then
            button.Cooldown:Hide()
        end
        return
    end

    button.EmptyTexture:Hide()
    button.Icon:Show()
    button.Icon:SetTexture(info.iconFileID)
    button.Icon:SetDesaturated(info.isLocked)

    local count = info.stackCount or 1
    button.StackCount:SetText(count > 1 and count or '')

    local itemID = info.itemID
    local isGear = self:IsGearItem(itemID)
    if isGear then
        local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
        local ilvl = C_Item.GetCurrentItemLevel(itemLocation)
        local ilvlInfo = EXUI.utils.getIlvlInfo(ilvl)
        button.ItemLevel:SetText(ilvl and WrapTextInColorCode(ilvl, ilvlInfo.color) or '')
        if button.QualityIcon then
            button.QualityIcon:Hide()
        end
        if not ilvl or ilvlInfo.color == 'ffffffff' then
            ApplyBorderColor(button, unpack(DEFAULT_BORDER))
        else
            ApplyBorderColor(button, HexToRGB(ilvlInfo.color))
        end
    else
        button.ItemLevel:SetText('')
        UpdateQualityIcon(button, info.hyperlink or itemID)
        local quality = info.quality or Enum.ItemQuality.Common
        if quality <= Enum.ItemQuality.Common then
            ApplyBorderColor(button, unpack(DEFAULT_BORDER))
        else
            local r, g, b = C_Item.GetItemQualityColor(quality)
            ApplyBorderColor(button, r or 1, g or 1, b or 1)
        end
    end

    self:UpdateCooldown(button)
end

slots.UpdateCooldown = function(self, button)
    if not button.Cooldown or not button.bagID then
        return
    end
    local start, duration, enable = C_Container.GetContainerItemCooldown(button.bagID, button:GetID())
    if start and duration and duration > 0 then
        CooldownFrame_Set(button.Cooldown, start, duration, enable)
    else
        button.Cooldown:Clear()
        button.Cooldown:Hide()
    end
end

slots.CreateItemButton = function(self, parent)
    local button = CreateFrame('ItemButton', nil, parent)
    self:StyleItemButton(button)
    button:Hide()
    return button
end

slots.RequiredCount = function(self)
    local count = 0
    for bag = BACKPACK, REAGENT_BAG do
        count = count + (C_Container.GetContainerNumSlots(bag) or 0)
    end
    return count
end

slots.EnsurePool = function(self, parent, needed)
    needed = needed or self:RequiredCount()
    while #self.buttons < needed do
        self.buttons[#self.buttons + 1] = self:CreateItemButton(parent)
    end
end

slots.Acquire = function(self, index, parent)
    self:EnsurePool(parent, index)
    local button = self.buttons[index]
    if parent and button:GetParent() ~= parent then
        button:SetParent(parent)
    end
    return button
end

slots.ReleaseFrom = function(self, index)
    for i = index, #self.buttons do
        local button = self.buttons[i]
        button:Hide()
        button.bagID = nil
    end
end

slots.GetVisibleButtons = function(self)
    local visible = {}
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button:IsShown() then
            visible[#visible + 1] = button
        end
    end
    return visible
end

slots.UpdateVisible = function(self)
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button:IsShown() then
            self:UpdateItemButton(button)
        end
    end
end

slots.UpdateVisibleCooldowns = function(self)
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button:IsShown() then
            self:UpdateCooldown(button)
        end
    end
end

slots.UpdateLock = function(self, bagID, slotID)
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button:IsShown() and button.bagID == bagID and button:GetID() == slotID then
            self:UpdateItemButton(button)
        end
    end
end

local function OnBagButtonClick(button)
    if button.isBackpack then
        PutItemInBackpack()
        return
    end
    local invID = C_Container.ContainerIDToInventoryID(button.bagID)
    if invID then
        if not PutItemInBag(invID) and CursorHasItem() then
            return
        end
    end
end

local function OnBagButtonDrag(button)
    if button.isBackpack then
        return
    end
    local invID = C_Container.ContainerIDToInventoryID(button.bagID)
    if invID then
        PickupBagFromSlot(invID)
    end
end

local function OnBagButtonEnter(button)
    SetHovered(button, true)
    GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
    if button.isBackpack then
        GameTooltip_SetTitle(GameTooltip, BACKPACK_TOOLTIP)
        local free = C_Container.CalculateTotalNumberOfFreeBagSlots and C_Container.CalculateTotalNumberOfFreeBagSlots()
        if free then
            GameTooltip:AddLine(NUM_FREE_SLOTS and NUM_FREE_SLOTS:format(free) or tostring(free))
        end
    else
        local invID = C_Container.ContainerIDToInventoryID(button.bagID)
        if invID and GameTooltip:SetInventoryItem('player', invID) then
            -- tooltip set
        else
            local title = button.bagID == REAGENT_BAG and EQUIP_CONTAINER_REAGENT or EQUIP_CONTAINER
            GameTooltip_SetTitle(GameTooltip, title)
        end
    end
    GameTooltip:Show()
end

slots.UpdateBagButton = function(self, button)
    local texture
    if button.isBackpack then
        texture = [[Interface\Icons\INV_Misc_Bag_08]]
    else
        local invID = C_Container.ContainerIDToInventoryID(button.bagID)
        if invID then
            texture = GetInventoryItemTexture('player', invID)
        end
    end

    if texture then
        button.EmptyTexture:Hide()
        button.Icon:Show()
        button.Icon:SetTexture(texture)
        ApplyBorderColor(button, unpack(DEFAULT_BORDER))
    else
        button.Icon:Hide()
        button.EmptyTexture:Show()
        ApplyBorderColor(button, unpack(DEFAULT_BORDER))
    end
end

slots.ShowEmpty = function(self, button)
    button.bagID = nil
    button.itemID = nil
    button:SetID(0)
    button.Icon:SetTexture(nil)
    button.Icon:Hide()
    button.EmptyTexture:Show()
    button.ItemLevel:SetText('')
    button.StackCount:SetText('')
    if button.Cooldown then
        button.Cooldown:Hide()
    end
    ApplyBorderColor(button, unpack(DEFAULT_BORDER))
    button:Show()
end

slots.CreateBagButton = function(self, parent, bagID)
    local button = CreateFrame('ItemButton', nil, parent)
    self:StyleItemButton(button)
    button.bagID = bagID
    button.isBackpack = bagID == BACKPACK
    button.isReagent = bagID == REAGENT_BAG
    button:SetID(bagID)
    button:Show()
    button:SetScript('OnClick', OnBagButtonClick)
    button:SetScript('OnDragStart', OnBagButtonDrag)
    button:SetScript('OnReceiveDrag', OnBagButtonClick)
    button:SetScript('OnEnter', OnBagButtonEnter)
    button:SetScript('OnLeave', OnItemLeave)
    self:UpdateBagButton(button)
    return button
end

slots.CreateBagBar = function(self, parent)
    wipe(self.bagButtons)
    for bag = FIRST_BAG, LAST_BAG do
        self.bagButtons[#self.bagButtons + 1] = self:CreateBagButton(parent, bag)
    end
    self.bagButtons[#self.bagButtons + 1] = self:CreateBagButton(parent, REAGENT_BAG)
    return self.bagButtons
end

slots.UpdateBagBar = function(self)
    for i = 1, #self.bagButtons do
        self:UpdateBagButton(self.bagButtons[i])
    end
end

slots.IsReagentBagEquipped = function(self)
    return (C_Container.GetContainerNumSlots(REAGENT_BAG) or 0) > 0
end

slots.EnumerateBags = function(self)
    return BACKPACK, REAGENT_BAG
end
