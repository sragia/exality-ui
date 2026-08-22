---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesOptionsHelpers
local helpers = EXUI:GetModule('np-options-helpers')

---@class EXUIOptionsReloadDialog
local optionsReloadDialog = EXUI:GetModule('options-reload-dialog')

---@class EXUINameplatesOptionsGeneral
local general = EXUI:GetModule('np-options-general')

function general:GetMenu()
    return {
        {
            id = 'enable',
            name = 'Enable',
            options = function()
                return {
                    {
                        type = 'toggle',
                        label = 'Enable Nameplates',
                        name = 'enable',
                        width = 100,
                        currentValue = function()
                            return helpers.Get('enable')
                        end,
                        onChange = function(value)
                            EXUI:GetModule('np-core'):SetValue('enable', value)
                            optionsReloadDialog:ShowDialog('Reload UI to apply nameplate enable changes.')
                        end,
                        tooltip = {
                            text = 'Requires a UI reload. While disabled, nameplates do nothing at runtime.',
                        },
                    },
                }
            end,
        },
        {
            id = 'size',
            name = 'Size',
            options = function()
                return {
                    helpers.Range('Width', 'sizeWidth', 40, 400, 1, 50),
                    helpers.Range('Height', 'sizeHeight', 4, 80, 1, 50),
                }
            end,
        },
        {
            id = 'texture',
            name = 'Texture',
            options = function()
                return {
                    helpers.TextureDropdown('Status Bar Texture', 'statusBarTexture', 50),
                }
            end,
        },
        {
            id = 'border',
            name = 'Border',
            options = function()
                return {
                    helpers.Range('Thickness', 'borderThickness', 0, 4, 1, 50),
                    helpers.Color('Color', 'borderColor', 50),
                }
            end,
        },
    }
end
