---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesElementsDispelOverlay
local dispelOverlay = EXUI:GetModule('uf-element-dispel-overlay')

dispelOverlay.colors = {}

dispelOverlay.Create = function(self, frame)
    local DispelOverlay = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    DispelOverlay:SetAllPoints()
    DispelOverlay:SetTexture(EXUI.const.textures.unitFrames.dispelOverlay)
    DispelOverlay:SetVertexColor(0, 0, 0, 0)
    DispelOverlay:Hide()

    return DispelOverlay
end

dispelOverlay.Update = function(self, frame)
    local db = frame.db
    core:EnableElementForFrame(frame, 'DispelOverlay')

    if (not db.dispelOverlayEnable) then
        core:DisableElementForFrame(frame, 'DispelOverlay')
        return
    end
    frame.DispelOverlay.dispelColorCurve = self:CreateColorCurve(db.dispelOverlayAlpha)
end

dispelOverlay.CreateColorCurve = function(self, alpha)
    local dispelColorCurve = C_CurveUtil.CreateColorCurve()
    dispelColorCurve:SetType(Enum.LuaCurveType.Step)
    for _, dispelIndex in next, EXUI.oUF.Enum.DispelType do
        if (EXUI.oUF.colors.dispel[dispelIndex]) then
            local color = self.colors[dispelIndex]
            if (not color) then
                color = CreateColor(EXUI.oUF.colors.dispel[dispelIndex]:GetRGBA())
            end
            local r, g, b = color:GetRGBA()
            color:SetRGBA(r, g, b, alpha)
            dispelColorCurve:AddPoint(dispelIndex, color)
        end
    end

    return dispelColorCurve
end
