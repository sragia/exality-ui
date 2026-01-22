---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

core:AddOption({
    name = 'General',
    id = 'general',
    prefix = 'general',
    defaultMenu = 'general',
    menu = {
        {
            name = 'Textures',
            id = 'textures',
            options = {
                {
                    type = 'dropdown',
                    name = 'statusBarTexture',
                    label = 'Status Bar Texture',
                    getOptions = function()
                        local list = LSM:List('statusbar')
                        local options = {}
                        for _, texture in pairs(list) do
                            options[texture] = texture
                        end
                        return options
                    end,
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'statusBarTexture')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'statusBarTexture', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 50
                }
            }
        },
        {
            name = 'Colors',
            id = 'colors',
            options = {
                {
                    type = 'title',
                    label = 'Health',
                    width = 100
                },
                {
                    type = 'toggle',
                    label = 'Use Custom Color',
                    name = 'useCustomHealthColor',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'useCustomHealthColor')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'useCustomHealthColor', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 100
                },
                {
                    type = 'color-picker',
                    label = 'Custom Color',
                    name = 'customHealthColor',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'customHealthColor')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'customHealthColor', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'toggle',
                    label = 'Use Class Colored Backdrop',
                    name = 'useClassColoredBackdrop',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'useClassColoredBackdrop')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'useClassColoredBackdrop', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 100
                },
                {
                    type = 'toggle',
                    label = 'Use Custom Backdrop Color',
                    name = 'useCustomBackdropColor',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'useCustomBackdropColor')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'useCustomBackdropColor', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 100
                },
                {
                    type = 'color-picker',
                    label = 'Custom Backdrop Color',
                    name = 'customBackdropColor',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'customBackdropColor')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'customBackdropColor', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'title',
                    label = 'Health Absorbs',
                    width = 100,
                    size = 14
                },
                {
                    type = 'color-picker',
                    label = 'Damage Absorb Color',
                    name = 'damageAbsorbColor',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'damageAbsorbColor')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'damageAbsorbColor', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'color-picker',
                    label = 'Heal Absorb Color',
                    name = 'healAbsorbColor',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'healAbsorbColor')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'healAbsorbColor', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'title',
                    label = 'Power',
                    width = 100,
                    size = 14
                },
                {
                    type = 'color-picker',
                    label = 'Mana',
                    name = 'powerColorMana',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'powerColor' .. Enum.PowerType.Mana)
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'powerColor' .. Enum.PowerType.Mana, value)
                        ufCore:UpdatePowerColors()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'color-picker',
                    label = 'Rage',
                    name = 'powerColorRage',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'powerColor' .. Enum.PowerType.Rage)
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'powerColor' .. Enum.PowerType.Rage, value)
                        ufCore:UpdatePowerColors()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'color-picker',
                    label = 'Focus',
                    name = 'powerColorFocus',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'powerColor' .. Enum.PowerType.Focus)
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'powerColor' .. Enum.PowerType.Focus, value)
                        ufCore:UpdatePowerColors()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'color-picker',
                    label = 'Energy',
                    name = 'powerColorEnergy',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'powerColor' .. Enum.PowerType.Energy)
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'powerColor' .. Enum.PowerType.Energy, value)
                        ufCore:UpdatePowerColors()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'color-picker',
                    label = 'Fury',
                    name = 'powerColorFury',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'powerColor' .. Enum.PowerType.Fury)
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'powerColor' .. Enum.PowerType.Fury, value)
                        ufCore:UpdatePowerColors()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'color-picker',
                    label = 'Runic Power',
                    name = 'powerColorRunicPower',
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'powerColor' .. Enum.PowerType.RunicPower)
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'powerColor' .. Enum.PowerType.RunicPower, value)
                        ufCore:UpdatePowerColors()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                }
            }
        }
    }
})
