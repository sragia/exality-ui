---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICharacterFrameEquipmentSlot
local equipmentSlot = EXUI:GetModule('character-frame-equipment-slot')

local SLOTNAME_BY_ID = {
    [1] = 'HEADSLOT',
    [2] = 'NECKSLOT',
    [3] = 'SHOULDERSLOT',
    [4] = 'SHIRTSLOT',
    [5] = 'CHESTSLOT',
    [6] = 'WAISTSLOT',
    [7] = 'LEGSSLOT',
    [8] = 'FEETSLOT',
    [9] = 'WRISTSLOT',
    [10] = 'HANDSSLOT',
    [11] = 'FINGER0SLOT',
    [12] = 'FINGER1SLOT',
    [13] = 'TRINKET0SLOT',
    [14] = 'TRINKET1SLOT',
    [15] = 'BACKSLOT',
    [16] = 'MAINHANDSLOT',
    [17] = 'SECONDARYHANDSLOT',
    [19] = 'TABARDSLOT'
}

local autoEquipSlotIds = {
    1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19
}

local CD_Font = CreateFont('ExalityUI_EQUIPMENT_SLOT_CD_Font')
CD_Font:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')

local EVENTS = {
    "PLAYER_EQUIPMENT_CHANGED",
    "MERCHANT_UPDATE",
    "PLAYERBANKSLOTS_CHANGED",
    "ITEM_LOCK_CHANGED",
    "CURSOR_CHANGED",
    "UPDATE_INVENTORY_ALERTS",
    "AZERITE_ITEM_POWER_LEVEL_CHANGED",
    "AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED",
    "BAG_UPDATE_COOLDOWN"
}
--[[
Midnight (S1)
Veteran 1 - 233
Champ 1 - 246
Hero 1 - 259
Mythic 1 - 272
]]

local ILVL_RARITY = {
    { ilvl = 0,   color = 'ffffffff', border = EXUI.const.textures.characterFrame.border.empty },
    { ilvl = 100, color = 'ff26ff3f', border = EXUI.const.textures.characterFrame.border.uncommon },
    { ilvl = 233, color = 'ff26e2ff', border = EXUI.const.textures.characterFrame.border.rare },
    { ilvl = 259, color = 'ffe226ff', border = EXUI.const.textures.characterFrame.border.epic },
    { ilvl = 279, color = 'ffffc526', border = EXUI.const.textures.characterFrame.border.legendary },
    { ilvl = 289, color = 'ffff2634', border = EXUI.const.textures.characterFrame.border.max },
}

equipmentSlot.GetItemColorAndBorder = function(self, ilvl)
    local result = ILVL_RARITY[1]
    for i = 1, #ILVL_RARITY do
        if ilvl >= ILVL_RARITY[i].ilvl then
            result = ILVL_RARITY[i]
        else
            break
        end
    end
    return result.color, result.border
end

equipmentSlot.Create = function(self, slotId, side, parent)
    local slot = CreateFrame('Button', nil, parent, 'SecureActionButtonTemplate')
    slot:SetSize(36, 36)
    slot:SetID(slotId)
    slot:SetAttribute('type2', 'item')
    slot:SetAttribute('item', slotId)
    slot:RegisterForDrag('LeftButton')
    slot:RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'RightButtonDown')
    slot.slotId = slotId

    FrameUtil.RegisterFrameForEvents(slot, EVENTS)

    local _, textureName = GetInventorySlotInfo(SLOTNAME_BY_ID[slotId])
    slot.emptyTexture = textureName

    -- Icon Texture
    local icon = slot:CreateTexture(nil, 'BACKGROUND')
    slot.Icon = icon
    icon:SetAllPoints()
    icon:SetTexture(textureName)


    local overlayFrame = CreateFrame('Frame', nil, slot)
    overlayFrame:SetAllPoints()
    overlayFrame:SetFrameLevel(slot:GetFrameLevel() + 10)
    slot.OverlayFrame = overlayFrame

    -- Border
    local border = overlayFrame:CreateTexture(nil, 'OVERLAY')
    slot.Border = border
    border:SetPoint('TOPLEFT', -1, 1)
    border:SetPoint('BOTTOMRIGHT', 1, -1)
    border:SetTexture(EXUI.const.textures.characterFrame.border.empty)

    -- Ilvl Text
    local itemLevel = overlayFrame:CreateFontString(nil, 'OVERLAY')
    slot.ItemLevel = itemLevel
    itemLevel:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    itemLevel:SetPoint('TOPRIGHT', -1, -3)
    itemLevel:SetJustifyH('RIGHT')
    itemLevel:SetText('')

    -- Highlight
    local highlight = overlayFrame:CreateTexture(nil, 'ARTWORK')
    slot.Highlight = highlight
    highlight:SetTexture(EXUI.const.textures.characterFrame.highlight)
    highlight:SetPoint('TOPLEFT', 1, -1)
    highlight:SetPoint('BOTTOMRIGHT', -1, 1)
    slot.Highlight.FadeIn = EXUI.utils.animation.fade(highlight, 0.2, 0, 1)
    slot.Highlight.FadeOut = EXUI.utils.animation.fade(highlight, 0.2, 1, 0)
    slot.Highlight.FadeOut:SetScript('OnFinished', function() slot.Highlight:SetAlpha(0) end)
    slot.Highlight:SetAlpha(0)

    local cooldown = CreateFrame('Cooldown', nil, slot)
    slot.Cooldown = cooldown
    cooldown:SetAllPoints()
    cooldown:SetSwipeColor(0, 0, 0, 0.6)
    cooldown:SetCountdownFont('ExalityUI_EQUIPMENT_SLOT_CD_Font')
    cooldown:SetSwipeTexture(EXUI.const.textures.frame.bg)



    -- Enchant Text

    -- Gems TODO

    slot.OnClick = function(self, button)
        if (IsModifiedClick()) then
            local itemLocation = ItemLocation:CreateFromEquipmentSlot(self:GetID());
            if (IsModifiedClick('EXPANDITEM')) then
                if (C_Item.DoesItemExist(itemLocation)) then
                    -- Place Item in the slot
                    SocketInventoryItem(self:GetID())
                end
                return;
            end

            if (HandleModifiedItemClick(GetInventoryItemLink('player', self:GetID()), itemLocation)) then
                return;
            end
        else
            -- Nothing attached to cursor basically
            if (button == 'LeftButton') then
                local hasItem = CursorHasItem()

                local canPickupInventoryItem = not hasItem
                if (hasItem) then
                    for _, slotId in ipairs(autoEquipSlotIds) do
                        if (C_PaperDollInfo.CanCursorCanGoInSlot(slotId)) then
                            canPickupInventoryItem = true
                            break
                        end
                    end
                end

                if (canPickupInventoryItem) then
                    PickupInventoryItem(self:GetID())
                end
            else -- Right Button
                -- UseInventoryItem(self:GetID())
            end
        end
    end

    slot:SetScript('PostClick', slot.OnClick)
    slot:SetScript('OnReceiveDrag', function(self)
        self:OnClick('LeftButton')
    end)
    slot:SetScript('OnShow', function(self)
        self:Update()
    end)

    slot:SetScript('OnEnter', function(self)
        self:RegisterEvent("MODIFIER_STATE_CHANGED");
        self.Highlight.FadeIn:Play()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

        GameTooltip_SuppressAutomaticCompareItem(GameTooltip)

        local hasItem = GameTooltip:SetInventoryItem('player', self:GetID())
        if (not hasItem) then
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')

            GameTooltip:SetText(_G[strupper(SLOTNAME_BY_ID[self:GetID()])])
            GameTooltip:Show()
        end
        local itemLocation = ItemLocation:CreateFromEquipmentSlot(self:GetID());
        if (itemLocation and itemLocation:IsValid()) then
            SetCursorHoveredItem(itemLocation)
        end

        CursorUpdate(self)
    end)

    slot:SetScript('OnLeave', function(self)
        self:UnregisterEvent("MODIFIER_STATE_CHANGED");
        self.Highlight.FadeOut:Play()
        GameTooltip:Hide();
        ClearCursorHoveredItem()
        ResetCursor()
    end)

    slot.Update = function(self)
        local textureName = GetInventoryItemTexture('player', self:GetID())
        local hasItem = textureName ~= nil
        if (hasItem) then
            local itemLink = GetInventoryItemLink("player", self:GetID())
            self.Icon:SetTexture(textureName)
            local ilvl = C_Item.GetDetailedItemLevelInfo(itemLink)
            local color, border = equipmentSlot:GetItemColorAndBorder(ilvl)
            self.ItemLevel:SetText(WrapTextInColorCode(ilvl, color))
            self.Border:SetTexture(border)
            local start, duration = GetInventoryItemCooldown("player", self:GetID());
            self.Cooldown:SetCooldown(start, duration)
        else
            self.Icon:SetTexture(self.emptyTexture)
        end
    end

    slot:SetScript('OnEvent', function(self, event, ...)
        if (event == 'PLAYER_EQUIPMENT_CHANGED') then
            local slot = ...
            if (slot == self:GetID()) then
                self:Update()
            end
        elseif (event == 'BAG_UPDATE_COOLDOWN') then
            self:Update()
        elseif (event == 'UPDATE_INVENTORY_ALERTS') then
            self:Update()
        elseif (event == 'CURSOR_CHANGED') then
            if C_PaperDollInfo.CanCursorCanGoInSlot(self:GetID()) then
                self.Highlight:SetAlpha(1)
            else
                self.Highlight:SetAlpha(0)
            end
        end
    end)

    return slot
end
