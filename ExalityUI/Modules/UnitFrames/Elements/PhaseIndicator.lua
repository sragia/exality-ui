---@class ExalityUI
local EXUI = select(2, ...)

local phaseIndicator = EXUI:GetModule('uf-element-phase-indicator')

phaseIndicator.Create = function(self, frame)
    local phaseIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    EXUI:SetSize(phaseIndicator, 24, 24)
    phaseIndicator:SetPoint('CENTER')

    return phaseIndicator
end

phaseIndicator.Update = function(self, frame)
end
