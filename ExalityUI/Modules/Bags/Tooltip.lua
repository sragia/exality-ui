---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIBagsTooltip
local tooltip = EXUI:GetModule('bags-tooltip')

tooltip.enabled = false
tooltip.hooked = false

local BANK_COLOR = { 0.4, 0.7, 1 }
local TOTAL_COLOR = { 1, 1, 1 }

local function AddCount(target, label, count, color)
    if count > 0 then
        local hex = string.format('%02x%02x%02x', color[1] * 255, color[2] * 255, color[3] * 255)
        target:AddLine(string.format('|cff%s%s:|r %d', hex, label, count), 1, 1, 1)
    end
end

local function OnItemTooltip(target, data)
    if not tooltip.enabled or not data or not target.AddLine then
        return
    end
    local itemID = data.id
    if issecretvalue and issecretvalue(itemID) then
        return
    end
    if type(itemID) ~= 'number' then
        return
    end

    local inBags = C_Item.GetItemCount(itemID)
    local inBank = C_Item.GetItemCount(itemID, true, false, true) - inBags
    local inWarband = 0
    if EXUI.IsRetail() then
        inWarband = C_Item.GetItemCount(itemID, false, false, false, true) - inBags
    end
    if inBags <= 0 and inBank <= 0 and inWarband <= 0 then
        return
    end

    target:AddLine(' ')
    AddCount(target, 'Bags', inBags, EXUI.const.theme.accent)
    AddCount(target, 'Bank', inBank, BANK_COLOR)
    AddCount(target, 'Warband', inWarband, BANK_COLOR)
    local sources = (inBags > 0 and 1 or 0) + (inBank > 0 and 1 or 0) + (inWarband > 0 and 1 or 0)
    if sources > 1 then
        AddCount(target, 'Total', math.max(inBags, 0) + math.max(inBank, 0) + math.max(inWarband, 0), TOTAL_COLOR)
    end
end

tooltip.Enable = function(self)
    self.enabled = true
    -- Post calls can't be removed, so register once and gate on enabled
    if not self.hooked and TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
        self.hooked = true
    end
end

tooltip.Disable = function(self)
    self.enabled = false
end
