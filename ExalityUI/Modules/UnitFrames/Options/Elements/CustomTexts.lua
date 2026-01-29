---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesCustomTexts
local ctCore = EXUI:GetModule('uf-custom-texts')

---@class EXUIUnitFramesOptionsCore
local optionsCore = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local UFCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsCustomTexts
local customTexts = EXUI:GetModule('uf-options-custom-texts')

customTexts.GetOptions = function(self, unit)
    local options = {
        {
            type = 'title',
            label = 'Custom Texts',
            width = 100
        },
    }

    local list = ctCore:List(unit)
    for id, db in pairs(list) do
        if (db) then
            table.insert(options, {
                type = 'custom-texts-list-item',
                customTexts = {
                    unit = unit,
                    id = id
                },
                tag = db.tag,
                width = 100
            })
        end
    end

    table.insert(options, {
        type = 'button',
        label = 'Add Custom Text',
        onClick = function()
            ctCore:Create(unit)
            optionsCore:RefreshCurrentView()
            UFCore:UpdateFrameForUnit(unit)
        end,
        width = 100,
        color = { 30 / 255, 120 / 255, 0, 1 }
    })

    return options
end
