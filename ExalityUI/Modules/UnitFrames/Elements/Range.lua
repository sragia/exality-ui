---@class ExalityUI
local EXUI = select(2, ...)

local range = EXUI:GetModule('uf-element-range')

range.Create = function(self, frame)
    return {
        insideAlpha = 1,
        outsideAlpha = 0.5,
        PostUpdate = range.PostUpdate
    }
end

range.PostUpdate = function(rangeElement, frame, inRange, isEligible)
    if (frame.Health and type(inRange) == 'boolean') then
        frame.Health.bg:SetAlphaFromBoolean(inRange, 1, 0.1)
    end
end

range.Update = function(self, frame)
end
