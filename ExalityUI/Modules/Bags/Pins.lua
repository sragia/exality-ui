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

local function BuildItemIndex()
    local byID = {}
    local keyBag, keySlot, keyID
    for bag = BACKPACK, REAGENT_BAG do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                if not byID[itemID] then
                    byID[itemID] = { bag, slot }
                end
                if not keyBag and C_Item.IsItemKeystoneByID(itemID) then
                    keyBag, keySlot, keyID = bag, slot, itemID
                end
            end
        end
    end
    return byID, keyBag, keySlot, keyID
end

local function HookPinButton(button)
    button:HookScript('OnClick', function(btn, mouseButton)
        if mouseButton == 'MiddleButton' then
            if not btn.isKeystone and btn.itemID then
                pins:RemovePin(btn.itemID)
            end
            return
        end
        if btn.isDropSlot then
            pins:TryPinCursorItem()
        end
    end)
    button:HookScript('OnReceiveDrag', function(btn)
        if btn.isDropSlot or CursorHasItem() then
            pins:TryPinCursorItem()
        end
    end)
end

pins.Create = function(self, parent)
    self.parent = parent
    self.keystoneButton = slots:CreateItemButton(parent)
    self.keystoneButton.isKeystone = true
    HookPinButton(self.keystoneButton)

    for i = 1, MAX_PINS do
        local button = slots:CreateItemButton(parent)
        HookPinButton(button)
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
    EXUI:GetModule('bags-window').layoutSignature = nil
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
    EXUI:GetModule('bags-window').layoutSignature = nil
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

    local byID, keyBag, keySlot, keyID = BuildItemIndex()
    if keyBag then
        if not InCombatLockdown() and self.keystoneButton:GetParent() ~= parent then
            self.keystoneButton:SetParent(parent)
        end
        self.keystoneButton:SetSize(slotSize, slotSize)
        self.keystoneButton:ClearAllPoints()
        self.keystoneButton:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, -y)
        slots:Assign(self.keystoneButton, keyBag, keySlot)
        self.keystoneButton.itemID = keyID
        self.keystoneButton.isKeystone = true
        slots:SetButtonShown(self.keystoneButton, true)
        slots:UpdateItemButton(self.keystoneButton)
        shown = shown + 1
        y = y + slotSize + spacing
    else
        slots:SetButtonShown(self.keystoneButton, false)
    end

    local list = GetPinnedIDs()
    local used = 0
    for i = 1, #list do
        local found = byID[list[i]]
        local bag, slot = found and found[1], found and found[2]
        used = used + 1
        local button = self.buttons[used]
        if button then
            if not InCombatLockdown() and button:GetParent() ~= parent then
                button:SetParent(parent)
            end
            button:SetSize(slotSize, slotSize)
            button:ClearAllPoints()
            button:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, -y)
            button.itemID = list[i]
            button.isKeystone = false
            button.isDropSlot = false
            if bag then
                slots:Assign(button, bag, slot)
                slots:SetButtonShown(button, true)
                slots:UpdateItemButton(button)
                shown = shown + 1
                y = y + slotSize + spacing
            else
                slots:SetButtonShown(button, false)
            end
        end
    end

    local dropIndex = used + 1
    local drop = self.buttons[dropIndex]
    if drop then
        if not InCombatLockdown() and drop:GetParent() ~= parent then
            drop:SetParent(parent)
        end
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
        slots:SetButtonShown(self.buttons[i], false)
        self.buttons[i].isDropSlot = false
    end

    return slotSize, math.max(y - spacing, slotSize)
end

pins.ForEachVisible = function(self, callback)
    if self.keystoneButton and slots:IsButtonShown(self.keystoneButton) then
        callback(self.keystoneButton)
    end
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if slots:IsButtonShown(button) then
            callback(button)
        end
    end
end

pins.UpdateLock = function(self, bagID, slotID)
    self:ForEachVisible(function(button)
        if (button.GetBagID and button:GetBagID() or button.bagID) == bagID and button:GetID() == slotID then
            slots:UpdateItemButton(button)
        end
    end)
end

pins.UpdateCooldowns = function(self)
    self:ForEachVisible(function(button)
        slots:UpdateCooldown(button)
    end)
end
