---@class ExalityUI
local EXUI = select(2, ...)

-- Expose oUF Tags table to allow for custom tags to be added
ExalityUI.oUF = {
    Tags = EXUI.oUF.Tags,
}
