---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIUnitFramesOptionsGenericShowPreview
local genericShowPreview = EXUI:GetModule('uf-options-generic-show-preview')

genericShowPreview.GetOptions = function(self, unit)
    return {
        {
            label = 'Show Preview',
            name = 'showPreview',
            type = 'button',
            onClick = function()
                core:ForceShow(unit)
            end,
            width = 16,
            color = { 219/255, 73/255, 0 , 1 }
        },
    }
end