---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

core:AddOption({
    name = 'Target of Target',
    id = 'targettarget',
    allowPreview = true,
    menu = {
        {
            name = 'Size & Position',
            id = 'sizeposition',
            options = {
                function()
                    return EXUI:GetModule('uf-options-size-and-position'):GetOptions('targettarget')
                end
            }
        },
        {
            name = 'Name',
            id = 'name',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('targettarget', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('targettarget', 'name')
                end
            }
        },
    }
})
