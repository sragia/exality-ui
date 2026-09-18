---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesOptionsAuras
local auras = EXUI:GetModule('np-options-auras')

function auras:GetMenu()
    return {
        {
            id = 'displays',
            name = 'Displays',
            options = function()
                return {
                    {
                        type = 'button',
                        label = 'Open Aura Editor',
                        width = 50,
                        color = { 249 / 255, 95 / 255, 9 / 255, 1 },
                        onClick = function()
                            EXUI:GetModule('np-aura-editor'):Show()
                        end,
                    },
                }
            end,
        },
    }
end
