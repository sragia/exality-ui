---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICharacterFrameEquipmentSlot
local equipmentSlot = EXUI:GetModule('character-frame-equipment-slot')

-------------------

---@class EXUICharacterFrameInspectSlot
local inspectSlot = EXUI:GetModule('character-frame-inspect-slot')

local function FormatEnchant(enchant)
    if (not enchant) then
        return ''
    end
    for pattern, replacement in pairs(equipmentSlot.replacements) do
        enchant = string.gsub(enchant, pattern, replacement)
    end
    return (string.gsub(string.gsub(enchant, '|A.-|a', ''), '^.-%-%s*', ''))
end

---@param slotId number
---@param side 'LEFT' | 'RIGHT' | 'BOTTOM'
---@param parent Frame
---@return Button
inspectSlot.Create = function(self, slotId, side, index, parent)
    local slot = CreateFrame('Button', nil, parent)
    slot:SetSize(36, 36)
    slot:SetID(slotId)
    slot:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    slot.Side = side
    slot.Index = index
    slot.slotId = slotId

    equipmentSlot:BuildVisuals(slot, slotId, side, index)

    slot.GetLink = function(self)
        return self.unit and GetInventoryItemLink(self.unit, self:GetID())
    end

    -- Returns false while the item is equipped but its data has not reached the client yet.
    slot.Update = function(self)
        local unit = self.unit
        local textureName = unit and GetInventoryItemTexture(unit, self:GetID())
        if (not textureName) then
            self.Icon:SetTexture(self.emptyTexture)
            self.Border:SetTexture(EXUI.const.textures.characterFrame.border.empty)
            self.ItemLevel:SetText('')
            self.EnchantText:SetText('')
            self:AddGems(nil)
            return true
        end

        local itemLink = GetInventoryItemLink(unit, self:GetID())
        self.Icon:SetTexture(textureName)
        if (not itemLink) then
            self.Border:SetTexture(EXUI.const.textures.characterFrame.border.empty)
            self.ItemLevel:SetText('')
            self.EnchantText:SetText('')
            self:AddGems(nil)
            return false
        end

        local ilvl = C_Item.GetDetailedItemLevelInfo(itemLink)
        local color, border = equipmentSlot:GetItemColorAndBorder(ilvl)
        if (EXUI.IsForever()) then
            border = equipmentSlot:QualityBorder(GetInventoryItemQuality(unit, self:GetID()))
        end
        self.ItemLevel:SetText(ilvl and WrapTextInColorCode(ilvl, color) or '')
        self.Border:SetTexture(border)
        self.EnchantText:SetText(FormatEnchant(EXUI.utils.GetItemEnchant(itemLink)))
        self:AddGems(itemLink)

        local item = Item:CreateFromItemLink(itemLink)
        if (not item:IsItemEmpty() and not item:IsItemDataCached()) then
            if (self.pendingLoad ~= itemLink) then
                self.pendingLoad = itemLink
                item:ContinueOnItemLoad(function()
                    self.pendingLoad = nil
                    if (self:GetLink() == itemLink) then
                        self:Update()
                    end
                end)
            end
            return false
        end
        return ilvl ~= nil
    end

    slot:SetScript('OnEnter', function(self)
        self.Highlight.FadeIn:Play()
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        if (not self.unit or not GameTooltip:SetInventoryItem(self.unit, self:GetID())) then
            GameTooltip:SetText(equipmentSlot:SlotName(self:GetID()) or '')
        end
        GameTooltip:Show()
        CursorUpdate(self)
    end)

    slot:SetScript('OnLeave', function(self)
        self.Highlight.FadeOut:Play()
        GameTooltip:Hide()
        ResetCursor()
    end)

    slot:SetScript('OnClick', function(self)
        local itemLink = self:GetLink()
        if (itemLink) then
            HandleModifiedItemClick(itemLink)
        end
    end)

    return slot
end
