---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIBagsPins
local pins = EXUI:GetModule('bags-pins')

---@class EXUIBagsSlots
local slots = EXUI:GetModule('bags-slots')

---@class EXUIBags
local bags

local BACKPACK = Enum.BagIndex.Backpack
local REAGENT_BAG = Enum.BagIndex.ReagentBag
local MAX_PINS = 12

pins.buttons = {}
pins.keystoneButton = nil

local function GetData()
    bags = bags or EXUI:GetModule('bags')
    return bags.Data
end

local function GetPinnedIDs()
    local list = GetData():GetValue('pinnedItems')
    if type(list) ~= 'table' then
        list = {}
        GetData():SetValue('pinnedItems', list)
    end
    return list
end

local function FindItem(itemID)
    for bag = BACKPACK, REAGENT_BAG do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            if C_Container.GetContainerItemID(bag, slot) == itemID then
                return bag, slot
            end
        end
    end
end

local function FindKeystone()
    for bag = BACKPACK, REAGENT_BAG do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID and C_Item.IsItemKeystoneByID(itemID) then
                return bag, slot, itemID
            end
        end
    end
end

local function OnPinClick(button, mouseButton)
    if mouseButton == 'RightButton' and not button.isKeystone then
        if button.itemID then
            pins:RemovePin(button.itemID)
        end
        return
    end

    if not button.bagID then
        return
    end

    if IsModifiedClick() then
        local itemLocation = ItemLocation:CreateFromBagAndSlot(button.bagID, button:GetID())
        if HandleModifiedItemClick(C_Container.GetContainerItemLink(button.bagID, button:GetID()), itemLocation) then
            return
        end
    end

    if mouseButton == 'LeftButton' then
        C_Container.PickupContainerItem(button.bagID, button:GetID())
    else
        C_Container.UseContainerItem(button.bagID, button:GetID())
    end
end

pins.Create = function(self, parent)
    self.parent = parent
    self.keystoneButton = slots:CreateItemButton(parent)
    self.keystoneButton.isKeystone = true
    self.keystoneButton:SetScript('OnClick', OnPinClick)
    self.keystoneButton:SetScript('OnDragStart', function(button)
        OnPinClick(button, 'LeftButton')
    end)
    self.keystoneButton:SetScript('OnReceiveDrag', function(button)
        OnPinClick(button, 'LeftButton')
    end)

    for i = 1, MAX_PINS do
        local button = slots:CreateItemButton(parent)
        button:SetScript('OnDragStart', function(btn)
            OnPinClick(btn, 'LeftButton')
        end)
        button:SetScript('OnReceiveDrag', function(btn)
            if btn.isDropSlot or CursorHasItem() then
                if self:TryPinCursorItem() then
                    return
                end
            end
            OnPinClick(btn, 'LeftButton')
        end)
        button:SetScript('OnClick', function(btn, mouseButton)
            if btn.isDropSlot then
                self:TryPinCursorItem()
                return
            end
            OnPinClick(btn, mouseButton)
        end)
        self.buttons[i] = button
    end

    parent:EnableMouse(true)
    parent:SetScript('OnReceiveDrag', function()
        self:TryPinCursorItem()
    end)
    parent:SetScript('OnMouseUp', function()
        self:TryPinCursorItem()
    end)
end

pins.TryPinCursorItem = function(self)
    if not CursorHasItem() then
        return false
    end
    local itemLocation = C_Cursor.GetCursorItem and C_Cursor.GetCursorItem()
    if not itemLocation then
        return false
    end
    local itemID = C_Item.GetItemID(itemLocation)
    if itemID then
        self:AddPin(itemID)
        ClearCursor()
        return true
    end
    return false
end

pins.HasPin = function(self, itemID)
    if C_Item.IsItemKeystoneByID(itemID) then
        return true
    end
    local list = GetPinnedIDs()
    for i = 1, #list do
        if list[i] == itemID then
            return true
        end
    end
    return false
end

pins.AddPin = function(self, itemID)
    if not itemID or C_Item.IsItemKeystoneByID(itemID) then
        return
    end
    local list = GetPinnedIDs()
    for i = 1, #list do
        if list[i] == itemID then
            return
        end
    end
    if #list >= MAX_PINS then
        return
    end
    list[#list + 1] = itemID
    GetData():SetValue('pinnedItems', list)
    bags = bags or EXUI:GetModule('bags')
    bags:Refresh()
end

pins.RemovePin = function(self, itemID)
    local list = GetPinnedIDs()
    for i = #list, 1, -1 do
        if list[i] == itemID then
            table.remove(list, i)
        end
    end
    GetData():SetValue('pinnedItems', list)
    bags = bags or EXUI:GetModule('bags')
    bags:Refresh()
end

pins.TogglePin = function(self, itemID)
    if not itemID or C_Item.IsItemKeystoneByID(itemID) then
        return
    end
    if self:HasPin(itemID) then
        self:RemovePin(itemID)
    else
        self:AddPin(itemID)
    end
end

pins.Layout = function(self, parent, slotSize, spacing)
    local shown = 0
    local y = 0

    local keyBag, keySlot, keyID = FindKeystone()
    if keyBag then
        self.keystoneButton:SetParent(parent)
        self.keystoneButton:SetSize(slotSize, slotSize)
        self.keystoneButton:ClearAllPoints()
        self.keystoneButton:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, -y)
        slots:Assign(self.keystoneButton, keyBag, keySlot)
        self.keystoneButton.itemID = keyID
        self.keystoneButton.isKeystone = true
        self.keystoneButton:Show()
        slots:UpdateItemButton(self.keystoneButton)
        shown = shown + 1
        y = y + slotSize + spacing
    else
        self.keystoneButton:Hide()
        self.keystoneButton.bagID = nil
    end

    local list = GetPinnedIDs()
    local used = 0
    for i = 1, #list do
        local bag, slot = FindItem(list[i])
        used = used + 1
        local button = self.buttons[used]
        if button then
            button:SetParent(parent)
            button:SetSize(slotSize, slotSize)
            button:ClearAllPoints()
            button:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, -y)
            button.itemID = list[i]
            button.isKeystone = false
            button.isDropSlot = false
            if bag then
                slots:Assign(button, bag, slot)
                button:Show()
                slots:UpdateItemButton(button)
                shown = shown + 1
                y = y + slotSize + spacing
            else
                button:Hide()
                button.bagID = nil
            end
        end
    end

    local dropIndex = used + 1
    local drop = self.buttons[dropIndex]
    if drop then
        drop:SetParent(parent)
        drop:SetSize(slotSize, slotSize)
        drop:ClearAllPoints()
        drop:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, -y)
        drop.isKeystone = false
        drop.isDropSlot = true
        slots:ShowEmpty(drop)
        shown = shown + 1
        y = y + slotSize + spacing
        used = dropIndex
    end

    for i = used + 1, #self.buttons do
        self.buttons[i]:Hide()
        self.buttons[i].bagID = nil
        self.buttons[i].isDropSlot = false
    end

    return slotSize, math.max(y - spacing, slotSize)
end

pins.ForEachVisible = function(self, callback)
    if self.keystoneButton and self.keystoneButton:IsShown() then
        callback(self.keystoneButton)
    end
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button:IsShown() then
            callback(button)
        end
    end
end

pins.UpdateLock = function(self, bagID, slotID)
    self:ForEachVisible(function(button)
        if button.bagID == bagID and button:GetID() == slotID then
            slots:UpdateItemButton(button)
        end
    end)
end

pins.UpdateCooldowns = function(self)
    self:ForEachVisible(function(button)
        slots:UpdateCooldown(button)
    end)
end
