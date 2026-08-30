---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIBagsSlots
local slots = EXUI:GetModule('bags-slots')

local BACKPACK = Enum.BagIndex.Backpack
local REAGENT_BAG = Enum.BagIndex.ReagentBag
local FIRST_BAG = Enum.BagIndex.Bag_1
local LAST_BAG = Enum.BagIndex.Bag_4

slots.pools = {
    bags = {},
    bank = {},
}
slots.search = {
    bags = '',
    bank = '',
}
slots.buttons = slots.pools.bags
slots.bagButtons = {}

local SEARCH_DIM = 0.3

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

    local extras = {
        button.NewItemTexture,
        button.BattlepayItemTexture,
        button.IconQuestTexture,
        button.JunkIcon,
        button.UpgradeIcon,
        button.flash,
        button.searchOverlay,
        button.SearchOverlay,
        button.BagIndicator,
    }
    for i = 1, #extras do
        local region = extras[i]
        if region then
            region:SetAlpha(0)
            region:Hide()
        end
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

local qualityInfoCache = {}

local function GetCraftingQualityInfo(itemIDOrLink)
    if not itemIDOrLink or not C_TradeSkillUI then
        return nil
    end
    local cached = qualityInfoCache[itemIDOrLink]
    if cached ~= nil then
        return cached or nil
    end
    local info = C_TradeSkillUI.GetItemReagentQualityInfo(itemIDOrLink)
        or C_TradeSkillUI.GetItemCraftedQualityInfo(itemIDOrLink)
    qualityInfoCache[itemIDOrLink] = info or false
    return info
end

local function UpdateJunkIcon(button, info)
    local icon = button.JunkCoin
    if not icon then
        return
    end
    local isJunk = info and info.quality == Enum.ItemQuality.Poor and not info.hasNoValue
    icon:SetShown(isJunk)
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

local function OnItemEnter(button)
    SetHovered(button, true)
end

local function OnItemLeave(button)
    SetHovered(button, false)
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

    local junk = overlay:CreateTexture(nil, 'OVERLAY')
    button.JunkCoin = junk
    junk:SetAtlas('bags-junkcoin', true)
    junk:SetPoint('BOTTOMLEFT', 1, 1)
    junk:Hide()

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

    button:HookScript('OnEnter', OnItemEnter)
    button:HookScript('OnLeave', OnItemLeave)
end

slots.MatchesSearch = function(self, info, query)
    if not query or query == '' then
        return true
    end
    if not info then
        return false
    end
    local name = info.itemName and info.itemName:lower()
    if name and name:find(query, 1, true) then
        return true
    end
    if info.itemID and tostring(info.itemID):find(query, 1, true) then
        return true
    end
    return false
end

slots.ApplySearchDim = function(self, button, matches)
    local alpha = matches and 1 or SEARCH_DIM
    if button.Icon then
        button.Icon:SetAlpha(alpha)
    end
    if button.EmptyTexture then
        button.EmptyTexture:SetAlpha(alpha)
    end
    if button.Overlay then
        button.Overlay:SetAlpha(alpha)
    end
end

slots.GetSearch = function(self, poolName)
    return self.search[poolName or 'bags'] or ''
end

slots.SetSearch = function(self, poolName, text)
    poolName = poolName or 'bags'
    local query = (text or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')
    if self.search[poolName] == query then
        return
    end
    self.search[poolName] = query
    self:UpdateVisible(poolName)
    if poolName == 'bags' then
        local pins = EXUI:GetModule('bags-pins')
        pins:ForEachVisible(function(button)
            self:UpdateItemButton(button)
        end)
    end
end

slots.CreateSearchBox = function(self, parent, poolName)
    local theme = EXUI.const.theme
    local box = CreateFrame('EditBox', nil, parent, 'BackdropTemplate')
    box:SetAutoFocus(false)
    box:SetFont(EXUI.const.fonts.DEFAULT, 11, '')
    box:SetTextColor(unpack(theme.text))
    box:SetTextInsets(8, 8, 0, 0)
    box:SetMaxLetters(80)
    box:SetBackdrop(EXUI.const.backdrop.DEFAULT)
    box:SetBackdropColor(theme.backgroundDeep[1], theme.backgroundDeep[2], theme.backgroundDeep[3], 1)
    box:SetBackdropBorderColor(theme.border[1], theme.border[2], theme.border[3], 1)

    local hint = box:CreateFontString(nil, 'OVERLAY')
    box.Hint = hint
    hint:SetFont(EXUI.const.fonts.DEFAULT, 11, '')
    hint:SetTextColor(unpack(theme.textMuted))
    hint:SetPoint('LEFT', 8, 0)
    hint:SetText('Search')

    box:SetScript('OnTextChanged', function(editBox)
        local text = editBox:GetText() or ''
        hint:SetShown(text == '')
        self:SetSearch(poolName, text)
    end)
    box:SetScript('OnEscapePressed', function(editBox)
        if (editBox:GetText() or '') ~= '' then
            editBox:SetText('')
        end
        editBox:ClearFocus()
    end)
    box:SetScript('OnEnterPressed', function(editBox)
        editBox:ClearFocus()
    end)
    box:SetScript('OnEditFocusGained', function()
        box:SetBackdropBorderColor(theme.borderActive[1], theme.borderActive[2], theme.borderActive[3], 1)
    end)
    box:SetScript('OnEditFocusLost', function()
        box:SetBackdropBorderColor(theme.border[1], theme.border[2], theme.border[3], 1)
    end)
    return box
end

local function ButtonBagID(button)
    if button.GetBagID then
        return button:GetBagID()
    end
    return button.bagID
end

-- Parent frames hold bag IDs (Baganator-style). SetBagID uses SetAttribute
-- and taints UseContainerItem if rewritten in combat.
slots.GetBagIndexFrame = function(self, bagID, anchor)
    if not anchor then
        return nil
    end
    self.indexFrames = self.indexFrames or {}
    local byAnchor = self.indexFrames[anchor]
    if not byAnchor then
        byAnchor = {}
        self.indexFrames[anchor] = byAnchor
    end
    local frame = byAnchor[bagID]
    if not frame then
        frame = CreateFrame('Frame', nil, anchor)
        frame:SetID(bagID)
        frame:SetAllPoints(anchor)
        frame.exuiBagIndex = true
        byAnchor[bagID] = frame
    end
    return frame
end

slots.Assign = function(self, button, bagID, slotID)
    if not button then
        return
    end
    if ButtonBagID(button) == bagID and button:GetID() == slotID then
        return
    end
    button.itemSnap = nil
    if InCombatLockdown() then
        return
    end
    local parent = button:GetParent()
    local anchor = parent and parent.exuiBagIndex and parent:GetParent() or parent
    local indexFrame = self:GetBagIndexFrame(bagID, anchor)
    if indexFrame and button:GetParent() ~= indexFrame then
        button:SetParent(indexFrame)
    end
    button:SetID(slotID)
end

slots.BindPlayerSlots = function(self, parent)
    if InCombatLockdown() then
        return
    end
    parent = parent or (self.buttons[1] and self.buttons[1]:GetParent())
    self:EnsurePool(parent)
    local index = 1
    for bag = BACKPACK, REAGENT_BAG do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local button = self:Acquire(index, parent, 'bags')
            if button then
                self:Assign(button, bag, slot)
            end
            index = index + 1
        end
    end
end

local gearCache = {}

slots.IsGearItem = function(self, itemID)
    if not itemID then
        return false
    end
    local cached = gearCache[itemID]
    if cached ~= nil then
        return cached
    end
    local invType = C_Item.GetItemInventoryTypeByID(itemID)
    local isGear = invType
        and invType ~= Enum.InventoryType.IndexNonEquipType
        and invType ~= Enum.InventoryType.IndexBagType
        and invType ~= Enum.InventoryType.IndexQuiverType
        and invType ~= Enum.InventoryType.IndexAmmoType
    gearCache[itemID] = isGear and true or false
    return gearCache[itemID]
end

slots.SetButtonShown = function(self, button, shown)
    if not button then
        return
    end
    button:SetShown(shown and true or false)
end

slots.IsButtonShown = function(self, button)
    return button and button:IsShown()
end

slots.UpdateItemButton = function(self, button)
    if button.isDropSlot then
        return
    end
    local bagID, slotID = ButtonBagID(button), button:GetID()
    if not bagID or not slotID or slotID == 0 then
        self:SetButtonShown(button, false)
        return
    end

    local info = C_Container.GetContainerItemInfo(bagID, slotID)
    local query = self:GetSearch(button.poolName)
    local snap = button.itemSnap

    if not info then
        if snap and snap.empty and snap.query == query then
            return
        end
        button.Icon:SetTexture(nil)
        button.Icon:Hide()
        button.EmptyTexture:Show()
        button.ItemLevel:SetText('')
        button.StackCount:SetText('')
        if button.QualityIcon then
            button.QualityIcon:Hide()
        end
        UpdateJunkIcon(button)
        ApplyBorderColor(button, unpack(DEFAULT_BORDER))
        if button.Cooldown then
            button.Cooldown:Hide()
        end
        self:ApplySearchDim(button, query == '')
        button.itemSnap = { empty = true, query = query }
        return
    end

    local count = info.stackCount or 1
    if snap
        and not snap.empty
        and snap.id == info.itemID
        and snap.count == count
        and snap.locked == info.isLocked
        and snap.icon == info.iconFileID
        and snap.quality == info.quality
        and snap.noValue == info.hasNoValue
        and snap.query == query
    then
        self:UpdateCooldown(button)
        return
    end

    button.EmptyTexture:Hide()
    button.Icon:Show()
    button.Icon:SetTexture(info.iconFileID)
    local matches = self:MatchesSearch(info, query)
    button.Icon:SetDesaturated(info.isLocked or not matches)

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

    UpdateJunkIcon(button, info)
    self:UpdateCooldown(button)
    self:ApplySearchDim(button, matches)
    button.itemSnap = {
        empty = false,
        id = itemID,
        count = count,
        locked = info.isLocked,
        icon = info.iconFileID,
        quality = info.quality,
        noValue = info.hasNoValue,
        query = query,
    }
end

slots.EnsureCooldown = function(self, button)
    if button.Cooldown then
        return button.Cooldown
    end
    local cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
    button.Cooldown = cooldown
    cooldown:SetAllPoints()
    cooldown:SetFrameLevel(button:GetFrameLevel() + 2)
    cooldown:SetDrawEdge(false)
    cooldown:SetSwipeColor(0, 0, 0, 0.55)
    if button.Overlay then
        button.Overlay:SetFrameLevel(button:GetFrameLevel() + 4)
    end
    return cooldown
end

slots.UpdateCooldown = function(self, button)
    local bagID = ButtonBagID(button)
    if not bagID then
        return
    end
    local start, duration, enable = C_Container.GetContainerItemCooldown(bagID, button:GetID())
    if start and duration and duration > 0 then
        CooldownFrame_Set(self:EnsureCooldown(button), start, duration, enable)
    elseif button.Cooldown then
        button.Cooldown:Clear()
        button.Cooldown:Hide()
    end
end

slots.CreateItemButton = function(self, parent)
    local button = CreateFrame('ItemButton', nil, parent, 'ContainerFrameItemButtonTemplate')
    self:StyleItemButton(button)
    button:RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonUp')
    button.poolName = 'bags'
    button:Hide()
    return button
end

slots.GetPool = function(self, poolName)
    poolName = poolName or 'bags'
    local pool = self.pools[poolName]
    if not pool then
        pool = {}
        self.pools[poolName] = pool
    end
    if poolName == 'bags' then
        self.buttons = pool
    end
    return pool
end

slots.RequiredCount = function(self)
    local count = 0
    for bag = BACKPACK, REAGENT_BAG do
        count = count + (C_Container.GetContainerNumSlots(bag) or 0)
    end
    return count
end

slots.RequiredCountForBags = function(self, bagIDs)
    local count = 0
    for i = 1, #(bagIDs or {}) do
        count = count + (C_Container.GetContainerNumSlots(bagIDs[i]) or 0)
    end
    return count
end

slots.EnsurePool = function(self, parent, needed, poolName)
    local pool = self:GetPool(poolName)
    needed = needed or (poolName == 'bank' and #pool or self:RequiredCount())
    while #pool < needed do
        local button = self:CreateItemButton(parent)
        if not button then
            break
        end
        pool[#pool + 1] = button
    end
end

slots.Acquire = function(self, index, parent, poolName)
    self:EnsurePool(parent, index, poolName)
    local button = self:GetPool(poolName)[index]
    if not button then
        return nil
    end
    button.poolName = poolName or 'bags'
    if parent and button:GetParent() ~= parent and not InCombatLockdown() then
        local current = button:GetParent()
        if not (current and current.exuiBagIndex) then
            button:SetParent(parent)
        end
    end
    return button
end

slots.ReleaseFrom = function(self, index, poolName)
    local pool = self:GetPool(poolName)
    for i = index, #pool do
        local button = pool[i]
        self:SetButtonShown(button, false)
        button.itemSnap = nil
        button.placedX, button.placedY, button.placedSize = nil, nil, nil
    end
end

slots.GetVisibleButtons = function(self, poolName)
    local visible = {}
    local pool = self:GetPool(poolName)
    for i = 1, #pool do
        local button = pool[i]
        if self:IsButtonShown(button) then
            visible[#visible + 1] = button
        end
    end
    return visible
end

slots.ForEachButton = function(self, callback, poolName)
    if poolName then
        local pool = self:GetPool(poolName)
        for i = 1, #pool do
            callback(pool[i])
        end
        return
    end
    for _, pool in pairs(self.pools) do
        for i = 1, #pool do
            callback(pool[i])
        end
    end
end

slots.UpdateVisible = function(self, poolName)
    self:ForEachButton(function(button)
        if self:IsButtonShown(button) then
            self:UpdateItemButton(button)
        end
    end, poolName)
end

slots.UpdateVisibleCooldowns = function(self, poolName)
    self:ForEachButton(function(button)
        if self:IsButtonShown(button) then
            self:UpdateCooldown(button)
        end
    end, poolName)
end

slots.UpdateLock = function(self, bagID, slotID, poolName)
    self:ForEachButton(function(button)
        if self:IsButtonShown(button) and ButtonBagID(button) == bagID and button:GetID() == slotID then
            self:UpdateItemButton(button)
        end
    end, poolName)
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
    if not InCombatLockdown() then
        button:SetID(0)
    end
    button.itemID = nil
    button.Icon:SetTexture(nil)
    button.Icon:Hide()
    button.EmptyTexture:Show()
    button.ItemLevel:SetText('')
    button.StackCount:SetText('')
    UpdateJunkIcon(button)
    if button.Cooldown then
        button.Cooldown:Hide()
    end
    ApplyBorderColor(button, unpack(DEFAULT_BORDER))
    self:ApplySearchDim(button, self:GetSearch(button.poolName) == '')
    self:SetButtonShown(button, true)
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
