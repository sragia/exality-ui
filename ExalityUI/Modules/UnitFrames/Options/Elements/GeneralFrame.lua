---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsCore
local optionsCore = EXUI:GetModule('uf-options-core')

---@class EXUIOptionsReloadDialog
local optionsReloadDialog = EXUI:GetModule('options-reload-dialog')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIUnitFramesOptionsGeneralFrame
local generalFrame = EXUI:GetModule('uf-options-general-frame')

generalFrame.GetOptions = function(self, unit)
    return {
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'enable', value)
                core:UpdateFrameForUnit(unit)
                optionsCore:RefreshCurrentView()

                if (value == true and core:GetValueForUnit(unit, 'showBlizzardFrame')) then
                    optionsReloadDialog:ShowDialog()
                end
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'enable')
            end,
            width = 100
        },
        {
            type = 'toggle',
            label = 'Show Blizzard (Default) Frame',
            name = 'showBlizzardFrame',
            currentValue = function()
                return core:GetValueForUnit(unit, 'showBlizzardFrame')
            end,
            depends = function()
                return not core:GetValueForUnit(unit, 'enable')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'showBlizzardFrame', value)
                optionsReloadDialog:ShowDialog()
            end,
            width = 100
        },
        {
            type = 'title',
            label = 'Overrides',
            width = 100
        },
        {
            type = 'title',
            label = 'Textures',
            accent = EXUI.const.colors.accentSecondary,
            width = 100,
            size = 14
        },
        {
            type = 'dropdown',
            name = 'overrideStatusBarTexture',
            label = 'Status Bar Texture',
            getOptions = function()
                local list = LSM:List('statusbar')
                local options = {
                    [''] = {
                        label = 'Use Default',
                        order = 0
                    }
                }
                local order = 1
                for _, texture in EXUI.utils.spairs(list, function(t, a, b) return t[a] < t[b] end) do
                    options[texture] = {
                        label = texture,
                        order = order
                    }
                    order = order + 1
                end
                return options
            end,
            isTextureDropdown = true,
            currentValue = function()
                return core:GetValueForUnit(unit, 'overrideStatusBarTexture')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'overrideStatusBarTexture', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 50
        },
        {
            type = 'spacer',
            width = 50
        },
        {
            type = 'dropdown',
            name = 'overrideDamageAbsorbTexture',
            label = 'Damage Absorb Texture',
            getOptions = function()
                local list = LSM:List('statusbar')
                local options = {
                    [''] = {
                        label = 'Use Default',
                        order = 0
                    }
                }
                local order = 1
                for _, texture in EXUI.utils.spairs(list, function(t, a, b) return t[a] < t[b] end) do
                    options[texture] = {
                        label = texture,
                        order = order
                    }
                    order = order + 1
                end
                return options
            end,
            isTextureDropdown = true,
            currentValue = function()
                return core:GetValueForUnit(unit, 'overrideDamageAbsorbTexture')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'overrideDamageAbsorbTexture', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 50
        },
        {
            type = 'spacer',
            width = 50
        },
        {
            type = 'dropdown',
            name = 'overrideHealAbsorbTexture',
            label = 'Heal Absorb Texture',
            getOptions = function()
                local list = LSM:List('statusbar')
                local options = {
                    [''] = {
                        label = 'Use Default',
                        order = 0
                    }
                }
                local order = 1
                for _, texture in EXUI.utils.spairs(list, function(t, a, b) return t[a] < t[b] end) do
                    order = order + 1
                    options[texture] = {
                        label = texture,
                        order = order
                    }
                end
                return options
            end,
            isTextureDropdown = true,
            currentValue = function()
                return core:GetValueForUnit(unit, 'overrideHealAbsorbTexture')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'overrideHealAbsorbTexture', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 50
        },
        {
            type = 'spacer',
            width = 50
        },
        {
            type = 'title',
            label = 'Health',
            accent = EXUI.const.colors.accentSecondary,
            width = 100,
            size = 14
        },
        {
            type = 'toggle',
            name = 'overrideHealthColor',
            label = 'Use Custom Health Colors',
            currentValue = function()
                return core:GetValueForUnit(unit, 'overrideHealthColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'overrideHealthColor', value)
                core:UpdateFrameForUnit(unit)
                optionsCore:RefreshCurrentView()
            end,
            width = 100
        },
        {
            type = 'toggle',
            label = 'Use Custom Color',
            name = 'useCustomHealthColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'useCustomHealthColor')
            end,
            depends = function()
                return core:GetValueForUnit(unit, 'overrideHealthColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'useCustomHealthColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 100
        },
        {
            type = 'color-picker',
            label = 'Custom Color',
            name = 'customHealthColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'customHealthColor')
            end,
            depends = function()
                return core:GetValueForUnit(unit, 'overrideHealthColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'customHealthColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'toggle',
            label = 'Use Class Colored Backdrop',
            name = 'useClassColoredBackdrop',
            currentValue = function()
                return core:GetValueForUnit(unit, 'useClassColoredBackdrop')
            end,
            depends = function()
                return core:GetValueForUnit(unit, 'overrideHealthColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'useClassColoredBackdrop', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 100
        },
        {
            type = 'toggle',
            label = 'Use Custom Backdrop Color',
            name = 'useCustomBackdropColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'useCustomBackdropColor')
            end,
            depends = function()
                return core:GetValueForUnit(unit, 'overrideHealthColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'useCustomBackdropColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 100
        },
        {
            type = 'color-picker',
            label = 'Custom Backdrop Color',
            name = 'customBackdropColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'customBackdropColor')
            end,
            depends = function()
                return core:GetValueForUnit(unit, 'overrideHealthColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'customBackdropColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'title',
            label = 'Health Absorbs',
            accent = EXUI.const.colors.accentSecondary,
            width = 100,
            size = 14
        },
        {
            type = 'toggle',
            label = 'Use Custom Health Absorbs Color',
            name = 'useCustomHealthAbsorbsColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'useCustomHealthAbsorbsColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'useCustomHealthAbsorbsColor', value)
                core:UpdateFrameForUnit(unit)
                optionsCore:RefreshCurrentView()
            end,
            width = 100
        },
        {
            type = 'color-picker',
            label = 'Damage Absorb Color',
            name = 'damageAbsorbColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'damageAbsorbColor')
            end,
            depends = function()
                return core:GetValueForUnit(unit, 'useCustomHealthAbsorbsColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'damageAbsorbColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'color-picker',
            label = 'Heal Absorb Color',
            name = 'healAbsorbColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'healAbsorbColor')
            end,
            depends = function()
                return core:GetValueForUnit(unit, 'useCustomHealthAbsorbsColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'healAbsorbColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
    }
end
