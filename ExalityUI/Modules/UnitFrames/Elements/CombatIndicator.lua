---@class ExalityUI
local EXUI = select(2, ...)

local combatIndicator = EXUI:GetModule('uf-element-combat-indicator')

combatIndicator.Create = function(self, frame)
    local combatIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    combatIndicator:SetSize(16, 16)
    combatIndicator:SetPoint('RIGHT', frame.ElementFrame, 'TOPRIGHT', 0, 0)

    return combatIndicator
end

combatIndicator.Update = function(self, frame)
    local db = frame.db
    local combatIndicator = frame.CombatIndicator
    if (not db.combatIndicatorEnable) then
        frame:DisableElement('CombatIndicator')
        return
    end

    frame:EnableElement('CombatIndicator')
    local size = (db.combatIndicatorScale or 1) * 16
    combatIndicator:SetSize(size, size)
    combatIndicator:ClearAllPoints()
    combatIndicator:SetPoint(
        db.combatIndicatorAnchorPoint,
        frame.ElementFrame,
        db.combatIndicatorRelativeAnchorPoint,
        db.combatIndicatorXOff,
        db.combatIndicatorYOff
    )

    if (frame:IsElementPreviewEnabled('combatindicator') and not combatIndicator:IsShown()) then
        combatIndicator.PostUpdate = function(self, inCombat)
            self:SetAtlas('UI-HUD-UnitFrame-Player-CombatIcon')
            self:Show()
        end
        combatIndicator:Show()
        combatIndicator.isPreview = true
    elseif (not frame:IsElementPreviewEnabled('combatindicator') and combatIndicator.isPreview) then
        combatIndicator.PostUpdate = nil
        combatIndicator.isPreview = false
    end
end
