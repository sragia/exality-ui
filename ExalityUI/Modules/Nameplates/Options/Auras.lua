---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesAuras
local npAuras = EXUI:GetModule('np-auras')

---@class EXUINameplatesOptionsAuras
local auras = EXUI:GetModule('np-options-auras')

function auras:GetMenu()
    return {
        {
            id = 'displays',
            name = 'Displays',
            options = function()
                if not npAuras:IsSupported() then
                    return {
                        {
                            type = 'description',
                            label = 'Aura containers require WoW 12.1 or newer.',
                            width = 100,
                        },
                    }
                end
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
