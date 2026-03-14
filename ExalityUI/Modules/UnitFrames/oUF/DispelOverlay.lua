---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

-- For preview
local dispelTypes = { 1, 2, 3, 4, 9, 11 }

local function Update(self, event, unit, updateInfo)
    local element = self.DispelOverlay
    if (not element) then return end

    if (element.isPreview) then
        element:Show()
        element:SetVertexColor(element.dispelColorCurve:Evaluate(dispelTypes[math.random(1, #dispelTypes)]):GetRGBA())
        return
    else
        element:Hide()
    end
    local slots = { C_UnitAuras.GetAuraSlots(unit, 'HARMFUL|RAID_PLAYER_DISPELLABLE') }
    if (#slots < 2) then
        element:Hide()
        return
    end
    for i = 2, #slots do
        local data = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
        if (data) then
            local color = C_UnitAuras.GetAuraDispelTypeColor(unit, data.auraInstanceID, element.dispelColorCurve)
            if (color == nil) then
                color = element.dispelColorCurve:Evaluate(0)
            end

            element:SetVertexColor(color:GetRGBA())
            element:Show()
        else
            element:Hide()
        end
    end
end

local function Enable(self)
    local element = self.DispelOverlay

    if (not element) then return end

    if (not element.dispelColorCurve) then
        element.dispelColorCurve = C_CurveUtil.CreateColorCurve()
        element.dispelColorCurve:SetType(Enum.LuaCurveType.Step)
        for _, dispelIndex in next, EXUI.oUF.Enum.DispelType do
            if (self.colors.dispel[dispelIndex]) then
                element.dispelColorCurve:AddPoint(dispelIndex, self.colors.dispel[dispelIndex])
            end
        end
    end
    self:RegisterEvent('UNIT_AURA', Update)

    return true
end

local function Disable(self)
    self:UnregisterEvent('UNIT_AURA', Update)

    if (self.DispelOverlay) then
        self.DispelOverlay:Hide()
    end
end

EXUI.oUF:AddElement('DispelOverlay', Update, Enable, Disable)
