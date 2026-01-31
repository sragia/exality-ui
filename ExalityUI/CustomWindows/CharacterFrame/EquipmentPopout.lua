---@class ExalityUI
local EXUI = select(2, ...)


---@class EXUICharacterFrameEquipmentPopout
local equipmentPopout = EXUI:GetModule('character-frame-equipment-popout')

equipmentPopout.pool = nil
equipmentPopout.frame = nil

equipmentPopout.Init = function(self)
    local f = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
    f:SetFrameStrata('DIALOG')
    f:SetFrameLevel(99)
    self.frame = f
    self.pool = CreateFramePool('Button', f, 'SecureActionButtonTemplate, BackdropTemplate')

    f:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    f:SetBackdropColor(0, 0, 0, 0.7)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    f:SetSize(250, 200)

    self:SetLogic(f)
end

equipmentPopout.CreateItemButton = function(self, parent)
    local f = self.pool:Acquire()
    if (not f.Configured) then
        f:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
        f:SetBackdropColor(0, 0, 0, 0.7)
        f:SetBackdropBorderColor(0, 0, 0, 1)
        EXUI:SetHeight(f, 20)

        local itemIcon = f:CreateTexture(nil, 'OVERLAY')
        itemIcon:SetPoint('LEFT', 1, 0)
        EXUI:SetSize(itemIcon, 18, 18)
        f.ItemIcon = itemIcon


        local itemName = f:CreateFontString(nil, 'OVERLAY')
        itemName:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        itemName:SetPoint('LEFT', itemIcon, 'RIGHT', 5, 0)
        itemName:SetSize(160, 20)
        itemName:SetJustifyH('LEFT')
        f.ItemName = itemName

        local itemLevel = f:CreateFontString(nil, 'OVERLAY')
        itemLevel:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        itemLevel:SetPoint('RIGHT', -5, 0)
        itemLevel:SetWidth(0)
        itemLevel:SetJustifyH('RIGHT')
        f.ItemLevel = itemLevel

        f:SetScript('OnEnter', function(self)
            if (not self.IsUnequip) then
                GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
                GameTooltip:SetHyperlink(self.ItemLink)
                GameTooltip:Show()
            end
            self:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
            self:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
        end)

        f:SetScript('OnLeave', function(self)
            if (not self.IsUnequip) then
                GameTooltip:Hide()
            end
            self:SetBackdropBorderColor(0, 0, 0, 1)
            self:SetBackdropColor(0, 0, 0, 0.7)
        end)

        f:SetScript('OnClick', function(self, button)
            if (InCombatLockdown()) then return end

            if (self.IsUnequip) then
                local action = EquipmentManager_UnequipItemInSlot(self.SlotId);
                EquipmentManager_RunAction(action);
                return;
            end

            local action = EquipmentManager_EquipItemByLocation(self.ItemLocation, self.SlotId)
            EquipmentManager_RunAction(action)
        end)

        f.Configured = true
    end
    f:Show()

    return f
end

equipmentPopout.SetLogic = function(self, f)
    f.Update = function(self)
        local slot = self.Slot

        local items = GetInventoryItemsForSlot(slot:GetID(), {})
        equipmentPopout.pool:ReleaseAll()

        local itemInfos = {}
        for itemLocation, itemLink in pairs(items) do
            local locationData = EquipmentManager_GetLocationData(itemLocation)
            if ((itemLocation - slot:GetID()) ~= ITEM_INVENTORY_LOCATION_PLAYER and locationData.isBags) then
                local location = ItemLocation:CreateFromBagAndSlot(locationData.bag, locationData.slot)
                local ilvl = C_Item.GetCurrentItemLevel(location)
                local icon = select(10, C_Item.GetItemInfo(itemLink))
                table.insert(itemInfos, { itemLocation = itemLocation, itemLink = itemLink, ilvl = ilvl, icon = icon })
            end
        end

        local height = 8

        -- Unequip Item
        local unequipItem = equipmentPopout:CreateItemButton(self.frame)
        unequipItem.IsUnequip = true
        unequipItem.ItemName:SetText('Unequip Item')
        unequipItem.ItemLevel:SetText('')
        unequipItem.ItemIcon:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-ItemIntoBag")
        unequipItem.SlotId = self.Slot:GetID()
        EXUI:SetPoint(unequipItem, 'TOPLEFT', 4, -4)
        EXUI:SetPoint(unequipItem, 'TOPRIGHT', -4, -4)
        height = height + unequipItem:GetHeight() + 4

        local prev = unequipItem;
        for _, itemInfo in EXUI.utils.spairs(itemInfos, function(t, a, b) return t[a].ilvl > t[b].ilvl end) do
            local itemFrame = equipmentPopout:CreateItemButton(self.frame)
            itemFrame.ItemLink = itemInfo.itemLink
            itemFrame.ItemLocation = itemInfo.itemLocation
            itemFrame.ItemName:SetText(itemInfo.itemLink)
            itemFrame.ItemIcon:SetTexture(itemInfo.icon)
            itemFrame.ItemLevel:SetText(itemInfo.ilvl)
            itemFrame.SlotId = self.Slot:GetID()

            if (prev) then
                EXUI:SetPoint(itemFrame, 'TOPLEFT', prev, 'BOTTOMLEFT', 0, -4)
                EXUI:SetPoint(itemFrame, 'TOPRIGHT', prev, 'BOTTOMRIGHT', 0, -4)
            else
                EXUI:SetPoint(itemFrame, 'TOPLEFT', 4, -4)
                EXUI:SetPoint(itemFrame, 'TOPRIGHT', -4, -4)
            end
            height = height + itemFrame:GetHeight() + 4

            prev = itemFrame
        end
        EXUI:SetHeight(self, height)
    end

    f:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
    f:SetScript('OnEvent', function(self, event, ...)
        self:Update()
    end)
end

equipmentPopout.Show = function(self, parent)
    self.frame:SetParent(parent)
    self.frame:SetFrameLevel(parent:GetFrameLevel() + 100)
    self.frame.Slot = parent

    self.frame:SetPoint('TOPLEFT', parent, 'TOPRIGHT', 5, 0)
    self.frame:Show()

    self.frame:Update()

    return self.frame
end

equipmentPopout.Hide = function(self, altStopped)
    self.frame:Hide()
end
