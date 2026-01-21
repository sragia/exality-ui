---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

local readyCheckIndicator = EXUI:GetModule('uf-element-ready-check-indicator')

readyCheckIndicator.Create = function(self, frame)
    local ReadyCheckIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    ReadyCheckIndicator:SetSize(16, 16)
    ReadyCheckIndicator:SetPoint('CENTER')
    return ReadyCheckIndicator
end

readyCheckIndicator.Update = function(self, frame)
end
