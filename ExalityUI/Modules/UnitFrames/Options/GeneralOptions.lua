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
                    isTextureDropdown = true,
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'statusBarTexture')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'statusBarTexture', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 50
                },
                {
                    type = 'spacer',
                    width = 50
                },
                {
                    type = 'dropdown',
                    name = 'damageAbsorbTexture',
                    label = 'Damage Absorb Texture',
                    getOptions = function()
                        local list = LSM:List('statusbar')
                        local options = {}
                        for _, texture in pairs(list) do
                            options[texture] = texture
                        end
                        return options
                    end,
                    isTextureDropdown = true,
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'damageAbsorbTexture')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'damageAbsorbTexture', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 50
                },
                {
                    type = 'spacer',
                    width = 50
                },
                {
                    type = 'dropdown',
                    name = 'healAbsorbTexture',
                    label = 'Heal Absorb Texture',
                    getOptions = function()
                        local list = LSM:List('statusbar')
                        local options = {}
                        for _, texture in pairs(list) do
                            options[texture] = texture
                        end
                        return options
                    end,
                    isTextureDropdown = true,
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'healAbsorbTexture')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'healAbsorbTexture', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 50
                },
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
                    label = 'Use Smooth Health Color',
                    name = 'useSmoothHealthColor',
                    tooltip = {
                        text = 'This overrides Custom Color.'
                    },
                    currentValue = function()
                        return ufCore:GetValueForUnit('general', 'useSmoothHealthColor')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('general', 'useSmoothHealthColor', value)
                        ufCore:UpdateAllFrames()
                    end,
                    width = 100
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
                    type = 'description',
                    label = 'Health Colors (for Smooth Health Color)',
                    width = 100
                },
                {
                    type = 'color-picker',
                    label = '0%',
                    name = 'healthCurve0',
                    currentValue = function()
                        local curve = ufCore:GetValueForUnit('general', 'healthCurve')
                        if (curve) then
                            return curve[0]
                        end
                        return { r = 1, g = 1, b = 1, a = 1 }
                    end,
                    onChange = function(value)
                        local curve = ufCore:GetValueForUnit('general', 'healthCurve')
                        if (curve) then
                            curve[0] = value
                        end
                        ufCore:UpdateValueForUnit('general', 'healthCurve', curve)
                        ufCore:UpdateHealthColor()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'color-picker',
                    label = '25%',
                    name = 'healthCurve025',
                    currentValue = function()
                        local curve = ufCore:GetValueForUnit('general', 'healthCurve')
                        if (curve) then
                            return curve[0.25]
                        end
                        return { r = 1, g = 1, b = 1, a = 1 }
                    end,
                    onChange = function(value)
                        local curve = ufCore:GetValueForUnit('general', 'healthCurve')
                        if (curve) then
                            curve[0.25] = value
                        end
                        ufCore:UpdateValueForUnit('general', 'healthCurve', curve)
                        ufCore:UpdateHealthColor()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'color-picker',
                    label = '50%',
                    name = 'healthCurve05',
                    currentValue = function()
                        local curve = ufCore:GetValueForUnit('general', 'healthCurve')
                        if (curve) then
                            return curve[0.5]
                        end
                        return { r = 1, g = 1, b = 1, a = 1 }
                    end,
                    onChange = function(value)
                        local curve = ufCore:GetValueForUnit('general', 'healthCurve')
                        if (curve) then
                            curve[0.5] = value
                        end
                        ufCore:UpdateValueForUnit('general', 'healthCurve', curve)
                        ufCore:UpdateHealthColor()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'color-picker',
                    label = '75%',
                    name = 'healthCurve075',
                    currentValue = function()
                        local curve = ufCore:GetValueForUnit('general', 'healthCurve')
                        if (curve) then
                            return curve[0.75]
                        end
                        return { r = 1, g = 1, b = 1, a = 1 }
                    end,
                    onChange = function(value)
                        local curve = ufCore:GetValueForUnit('general', 'healthCurve')
                        if (curve) then
                            curve[0.75] = value
                        end
                        ufCore:UpdateValueForUnit('general', 'healthCurve', curve)
                        ufCore:UpdateHealthColor()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'color-picker',
                    label = '100%',
                    name = 'healthCurve1',
                    currentValue = function()
                        local curve = ufCore:GetValueForUnit('general', 'healthCurve')
                        if (curve) then
                            return curve[1]
                        end
                        return { r = 1, g = 1, b = 1, a = 1 }
                    end,
                    onChange = function(value)
                        local curve = ufCore:GetValueForUnit('general', 'healthCurve')
                        if (curve) then
                            curve[1] = value
                        end
                        ufCore:UpdateValueForUnit('general', 'healthCurve', curve)
                        ufCore:UpdateHealthColor()
                        ufCore:UpdateAllFrames()
                    end,
                    width = 20
                },
                {
                    type = 'title',
                    label = 'Health Absorbs',
                    width = 100
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
                    width = 100
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
