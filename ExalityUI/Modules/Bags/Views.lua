---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIBagsViews
local views = EXUI:GetModule('bags-views')

---@class EXUIBagsSlots
local slots = EXUI:GetModule('bags-slots')

---@class EXUIBags
local bags

local BACKPACK = Enum.BagIndex.Backpack
local REAGENT_BAG = Enum.BagIndex.ReagentBag
local TITLE_INSET = 10
local CLIP_INSET = 2
local TITLE_GLOW = { 61 / 255, 53 / 255, 48 / 255, 1 } -- #3d3530

local GEAR_GROUPS = {
    { id = 'weapons', label = 'Weapons', types = {
        [Enum.InventoryType.IndexWeaponType] = true,
        [Enum.InventoryType.Index2HweaponType] = true,
        [Enum.InventoryType.IndexWeaponmainhandType] = true,
        [Enum.InventoryType.IndexWeaponoffhandType] = true,
        [Enum.InventoryType.IndexShieldType] = true,
        [Enum.InventoryType.IndexHoldableType] = true,
        [Enum.InventoryType.IndexRangedType] = true,
        [Enum.InventoryType.IndexRangedrightType] = true,
        [Enum.InventoryType.IndexThrownType] = true,
    } },
    { id = 'head', label = 'Head', types = { [Enum.InventoryType.IndexHeadType] = true } },
    { id = 'neck', label = 'Neck', types = { [Enum.InventoryType.IndexNeckType] = true } },
    { id = 'shoulder', label = 'Shoulder', types = { [Enum.InventoryType.IndexShoulderType] = true } },
    { id = 'back', label = 'Back', types = { [Enum.InventoryType.IndexCloakType] = true } },
    { id = 'chest', label = 'Chest', types = {
        [Enum.InventoryType.IndexChestType] = true,
        [Enum.InventoryType.IndexRobeType] = true,
    } },
    { id = 'wrist', label = 'Wrist', types = { [Enum.InventoryType.IndexWristType] = true } },
    { id = 'hands', label = 'Hands', types = { [Enum.InventoryType.IndexHandType] = true } },
    { id = 'waist', label = 'Waist', types = { [Enum.InventoryType.IndexWaistType] = true } },
    { id = 'legs', label = 'Legs', types = { [Enum.InventoryType.IndexLegsType] = true } },
    { id = 'feet', label = 'Feet', types = { [Enum.InventoryType.IndexFeetType] = true } },
    { id = 'finger', label = 'Finger', types = { [Enum.InventoryType.IndexFingerType] = true } },
    { id = 'trinket', label = 'Trinket', types = { [Enum.InventoryType.IndexTrinketType] = true } },
    { id = 'other', label = 'Other', types = {} },
}

local GEAR_ASSIGNED = {}
for i = 1, #GEAR_GROUPS do
    for invType in pairs(GEAR_GROUPS[i].types) do
        GEAR_ASSIGNED[invType] = true
    end
end

views.headerSets = {}
views.activeSetName = 'bags'
views.headers = {}
views.usedHeaders = 0

local function GetHeaderSet(name)
    name = name or views.activeSetName or 'bags'
    local set = views.headerSets[name]
    if not set then
        set = { headers = {}, used = 0, parent = nil }
        views.headerSets[name] = set
    end
    return set
end

local function GetLayout(context)
    bags = bags or EXUI:GetModule('bags')
    if context and (context.pool == 'bank' or context.layout == 'bank') then
        return bags:GetLayoutSettings('bank')
    end
    return bags:GetLayoutSettings()
end

local function CreateHeader(parent)
    local frame = CreateFrame('Frame', nil, parent)
    frame:SetHeight(22)

    local glow = frame:CreateTexture(nil, 'BACKGROUND')
    frame.Glow = glow
    glow:SetTexture(EXUI.const.textures.bags.glow)
    glow:SetTexCoord(1, 0, 0, 1)
    glow:SetVertexColor(unpack(TITLE_GLOW))
    glow:SetSize(100, 22)
    glow:SetPoint('LEFT')

    local label = frame:CreateFontString(nil, 'OVERLAY')
    frame.Label = label
    label:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    label:SetPoint('LEFT', TITLE_INSET, 0)
    label:SetTextColor(unpack(EXUI.const.theme.text))
    label:SetJustifyH('LEFT')

    frame:Hide()
    return frame
end

views.CreateHeaders = function(self, parent, setName)
    setName = setName or 'bags'
    local set = GetHeaderSet(setName)
    set.parent = parent
    if #set.headers == 0 then
        for i = 1, 16 do
            set.headers[i] = CreateHeader(parent)
        end
    end
    if setName == 'bags' then
        self.headers = set.headers
        self.parent = parent
        self.usedHeaders = 0
    end
end

views.AcquireHeader = function(self, text)
    local set = GetHeaderSet()
    set.used = set.used + 1
    local header = set.headers[set.used]
    if not header then
        header = CreateHeader(set.parent)
        set.headers[set.used] = header
    end
    header.Label:SetText(text)
    header:Show()
    self.usedHeaders = set.used
    return header
end

views.PlaceHeader = function(self, header, parent, y)
    header:ClearAllPoints()
    header:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, -y)
    header:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', 0, -y)
end

views.ReleaseHeaders = function(self)
    local set = GetHeaderSet()
    for i = 1, #set.headers do
        set.headers[i]:Hide()
    end
    set.used = 0
    self.usedHeaders = 0
end

views.LayoutRow = function(self, buttons, parent, x, y, columns, slotSize, spacing)
    for i = 1, #buttons do
        local button = buttons[i]
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)
        local px = x + col * (slotSize + spacing)
        local py = y + row * (slotSize + spacing)
        if button.placedX ~= px or button.placedY ~= py or button.placedSize ~= slotSize then
            button:ClearAllPoints()
            button:SetSize(slotSize, slotSize)
            button:SetPoint('TOPLEFT', parent, 'TOPLEFT', px, -py)
            button.placedX, button.placedY, button.placedSize = px, py, slotSize
        end
        slots:SetButtonShown(button, true)
        slots:UpdateItemButton(button)
    end
    if #buttons == 0 then
        return 0
    end
    local rows = math.ceil(#buttons / columns)
    return rows * slotSize + (rows - 1) * spacing
end

local function CollectSlotsFromBags(bagIDs, filter)
    local result = {}
    for i = 1, #(bagIDs or {}) do
        local bag = bagIDs[i]
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            if not filter or filter(bag, slot) then
                result[#result + 1] = { bag = bag, slot = slot }
            end
        end
    end
    return result
end

local function CollectSlots(fromBag, toBag, filter)
    local bagIDs = {}
    for bag = fromBag, toBag do
        bagIDs[#bagIDs + 1] = bag
    end
    return CollectSlotsFromBags(bagIDs, filter)
end

local function BindCollected(collected, parent, poolName)
    local buttons = {}
    for i = 1, #collected do
        local button = slots:Acquire(i, parent, poolName)
        if button then
            slots:Assign(button, collected[i].bag, collected[i].slot)
            buttons[#buttons + 1] = button
        end
    end
    slots:ReleaseFrom(#collected + 1, poolName)
    return buttons
end

local function GetBagIDs(context)
    if context and context.bagIDs then
        return context.bagIDs
    end
    local bagIDs = {}
    for bag = BACKPACK, REAGENT_BAG do
        bagIDs[#bagIDs + 1] = bag
    end
    return bagIDs
end

local function GetPoolName(context)
    return context and context.pool or 'bags'
end

local function ItemClassFilter(classSet, extra)
    return function(bag, slot)
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if not info or not info.itemID then
            return false
        end
        if extra and extra(bag, slot, info) then
            return true
        end
        local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(info.itemID)
        return classID and classSet[classID]
    end
end

views.LayoutBags = function(self, parent, context)
    local layout = GetLayout(context)
    local columns, slotSize, spacing = layout.columns, layout.slotSize, layout.spacing
    local poolName = GetPoolName(context)
    local y = CLIP_INSET
    local used = 0

    if context and context.bagIDs then
        local collected = CollectSlotsFromBags(context.bagIDs)
        local buttons = {}
        for i = 1, #collected do
            local button = slots:Acquire(used + 1, parent, poolName)
            if button then
                used = used + 1
                slots:Assign(button, collected[i].bag, collected[i].slot)
                buttons[#buttons + 1] = button
            end
        end
        y = y + self:LayoutRow(buttons, parent, TITLE_INSET, y, columns, slotSize, spacing)
        slots:ReleaseFrom(used + 1, poolName)
        return y + CLIP_INSET
    end

    local regular = CollectSlots(BACKPACK, Enum.BagIndex.Bag_4)
    local regularButtons = {}
    for i = 1, #regular do
        local button = slots:Acquire(used + 1, parent, poolName)
        if button then
            used = used + 1
            slots:Assign(button, regular[i].bag, regular[i].slot)
            regularButtons[#regularButtons + 1] = button
        end
    end
    y = y + self:LayoutRow(regularButtons, parent, TITLE_INSET, y, columns, slotSize, spacing)

    if slots:IsReagentBagEquipped() then
        if y > CLIP_INSET then
            y = y + 8
        end
        local header = self:AcquireHeader('Reagents')
        self:PlaceHeader(header, parent, y)
        y = y + header:GetHeight() + 6

        local reagent = CollectSlots(REAGENT_BAG, REAGENT_BAG)
        local reagentButtons = {}
        for i = 1, #reagent do
            local button = slots:Acquire(used + 1, parent, poolName)
            if button then
                used = used + 1
                slots:Assign(button, reagent[i].bag, reagent[i].slot)
                reagentButtons[#reagentButtons + 1] = button
            end
        end
        y = y + self:LayoutRow(reagentButtons, parent, TITLE_INSET, y, columns, slotSize, spacing)
    end

    slots:ReleaseFrom(used + 1, poolName)
    return y + CLIP_INSET
end

views.LayoutFiltered = function(self, parent, filter, context)
    local layout = GetLayout(context)
    local poolName = GetPoolName(context)
    local collected = CollectSlotsFromBags(GetBagIDs(context), filter)
    local buttons = BindCollected(collected, parent, poolName)
    local height = self:LayoutRow(buttons, parent, TITLE_INSET, CLIP_INSET, layout.columns, layout.slotSize, layout.spacing)
    if height <= 0 then
        return 0
    end
    return height + CLIP_INSET * 2
end

views.LayoutGear = function(self, parent, context)
    local layout = GetLayout(context)
    local columns, slotSize, spacing = layout.columns, layout.slotSize, layout.spacing
    local poolName = GetPoolName(context)
    local bagIDs = GetBagIDs(context)
    local grouped = {}
    for i = 1, #GEAR_GROUPS do
        grouped[GEAR_GROUPS[i].id] = {}
    end

    for i = 1, #bagIDs do
        local bag = bagIDs[i]
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID and slots:IsGearItem(info.itemID) then
                local invType = C_Item.GetItemInventoryTypeByID(info.itemID)
                local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
                local ilvl = C_Item.GetCurrentItemLevel(itemLocation) or 0
                local groupID = 'other'
                for j = 1, #GEAR_GROUPS do
                    if GEAR_GROUPS[j].types[invType] then
                        groupID = GEAR_GROUPS[j].id
                        break
                    end
                end
                if not GEAR_ASSIGNED[invType] then
                    groupID = 'other'
                end
                local list = grouped[groupID]
                list[#list + 1] = { bag = bag, slot = slot, ilvl = ilvl }
            end
        end
    end

    for i = 1, #GEAR_GROUPS do
        local list = grouped[GEAR_GROUPS[i].id]
        table.sort(list, function(a, b)
            return a.ilvl > b.ilvl
        end)
    end

    local y = CLIP_INSET
    local used = 0
    for i = 1, #GEAR_GROUPS do
        local list = grouped[GEAR_GROUPS[i].id]
        if #list > 0 then
            if y > CLIP_INSET then
                y = y + 8
            end
            local header = self:AcquireHeader(GEAR_GROUPS[i].label)
            self:PlaceHeader(header, parent, y)
            y = y + header:GetHeight() + 6

            local buttons = {}
            for j = 1, #list do
                local button = slots:Acquire(used + 1, parent, poolName)
                if button then
                    used = used + 1
                    slots:Assign(button, list[j].bag, list[j].slot)
                    buttons[#buttons + 1] = button
                end
            end
            y = y + self:LayoutRow(buttons, parent, TITLE_INSET, y, columns, slotSize, spacing)
        end
    end

    slots:ReleaseFrom(used + 1, poolName)
    return y + CLIP_INSET
end

local CONSUMABLE_CLASSES = {
    [Enum.ItemClass.Consumable] = true,
}

local REAGENT_CLASSES = {
    [Enum.ItemClass.Reagent] = true,
    [Enum.ItemClass.Tradegoods] = true,
}

local function IsCraftingReagent(itemID)
    local name = C_Item.GetItemInfo(itemID)
    if not name then
        return false
    end
    local isCraftingReagent = select(17, C_Item.GetItemInfo(itemID))
    return isCraftingReagent
end

local function IsQuestItem(bag, slot, info)
    if info.itemID then
        local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(info.itemID)
        if classID == Enum.ItemClass.Questitem then
            return true
        end
    end
    local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
    return questInfo and questInfo.isQuestItem
end

local function GridHeight(count, columns, slotSize, spacing)
    if count <= 0 then
        return 0
    end
    local rows = math.ceil(count / columns)
    return rows * slotSize + (rows - 1) * spacing
end

views.MeasureBagsHeight = function(self)
    local layout = GetLayout()
    local columns, slotSize, spacing = layout.columns, layout.slotSize, layout.spacing

    local regular = 0
    for bag = BACKPACK, Enum.BagIndex.Bag_4 do
        regular = regular + (C_Container.GetContainerNumSlots(bag) or 0)
    end
    local height = GridHeight(regular, columns, slotSize, spacing)
    if slots:IsReagentBagEquipped() then
        if height > 0 then
            height = height + 8
        end
        height = height + 22 + 6
        height = height + GridHeight(C_Container.GetContainerNumSlots(REAGENT_BAG) or 0, columns, slotSize, spacing)
    end
    return height
end

views.MeasureGridHeight = function(self, bagIDs, context)
    local layout = GetLayout(context or { pool = 'bank' })
    local count = 0
    for i = 1, #(bagIDs or {}) do
        count = count + (C_Container.GetContainerNumSlots(bagIDs[i]) or 0)
    end
    return GridHeight(count, layout.columns, layout.slotSize, layout.spacing)
end

views.Layout = function(self, parent, viewID, context)
    self.activeSetName = (context and context.headerSet) or 'bags'
    self:ReleaseHeaders()
    if viewID == 'bags' then
        return self:LayoutBags(parent, context)
    elseif viewID == 'gear' then
        return self:LayoutGear(parent, context)
    elseif viewID == 'consumables' then
        return self:LayoutFiltered(parent, ItemClassFilter(CONSUMABLE_CLASSES), context)
    elseif viewID == 'reagents' then
        return self:LayoutFiltered(parent, ItemClassFilter(REAGENT_CLASSES, function(_, _, info)
            return info.itemID and IsCraftingReagent(info.itemID)
        end), context)
    elseif viewID == 'quest' then
        return self:LayoutFiltered(parent, function(bag, slot)
            local info = C_Container.GetContainerItemInfo(bag, slot)
            return info and IsQuestItem(bag, slot, info)
        end, context)
    end
    return 0
end
