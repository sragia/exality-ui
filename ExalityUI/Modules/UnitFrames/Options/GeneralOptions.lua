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
                    onObserve = function(value)
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
                    onObserve = function(value)
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
                    onObserve = function(value)
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
                }
            }
        }
    }
})