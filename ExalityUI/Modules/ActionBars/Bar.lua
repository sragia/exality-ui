---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsBar
local bar = EXUI:GetModule('ab-bar')

-- TODO

bar.Create = function(self, id)
    local bar = CreateFrame('Frame', 'EXUIActionBar' .. id, UIParent, 'SecureHandlerStateTemplate')
    RegisterStateDriver(bar, 'page', '[]')

    return bar
end
