---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsCore
local optionsCore = EXUI:GetModule('uf-options-core')

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUIUnitFramesOptionsCastBar
local castBar = EXUI:GetModule('uf-options-cast-bar')

castBar.GetOptions = function(self, unit)
    return {
        {
            type = 'title',
            width = 100,
            label = 'Size & Position',
            size = 18
        },
        {
            type = 'toggle',
            name = 'castbarMatchFrameWidth',
            label = 'Match Frame Width',
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarMatchFrameWidth')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarMatchFrameWidth', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 100,
        },
        {
            type = 'range',
            label = 'Width',
            name = 'castbarWidth',
            min = 1,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarWidth')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarWidth', value)
                core:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'range',
            label = 'Height',
            name = 'castbarHeight',
            min = 1,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarHeight')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarHeight', value)
                core:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'toggle',
            name = 'castbarAnchorToFrame',
            label = 'Anchor to Frame',
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarAnchorToFrame')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarAnchorToFrame', value)
                core:UpdateFrameForUnit(unit)
                optionsCore:RefreshCurrentView()
            end,
            width = 100,
        },
        -- Anchored to Frame
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = 'castbarAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return core:GetValueForUnit(unit, 'castbarAnchorToFrame')
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarAnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 22
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'castbarRelativeAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return core:GetValueForUnit(unit, 'castbarAnchorToFrame')
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarRelativeAnchorPoint')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarRelativeAnchorPoint', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 22
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'castbarXOff',
            min = -1000,
            max = 1000,
            step = 1,
            depends = function()
                return core:GetValueForUnit(unit, 'castbarAnchorToFrame')
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarXOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarXOff', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'castbarYOff',
            min = -1000,
            max = 1000,
            step = 1,
            depends = function()
                return core:GetValueForUnit(unit, 'castbarAnchorToFrame')
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarYOff')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarYOff', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },

        -- Anchored to UIParent
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = 'castbarAnchorPointUIParent',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return not core:GetValueForUnit(unit, 'castbarAnchorToFrame')
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarAnchorPointUIParent')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarAnchorPointUIParent', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 22
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'castbarRelativeAnchorPointUIParent',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return not core:GetValueForUnit(unit, 'castbarAnchorToFrame')
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarRelativeAnchorPointUIParent')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarRelativeAnchorPointUIParent', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 22
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'castbarXOffUIParent',
            min = -1000,
            max = 1000,
            step = 1,
            depends = function()
                return not core:GetValueForUnit(unit, 'castbarAnchorToFrame')
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarXOffUIParent')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarXOffUIParent', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'castbarYOffUIParent',
            min = -1000,
            max = 1000,
            step = 1,
            depends = function()
                return not core:GetValueForUnit(unit, 'castbarAnchorToFrame')
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarYOffUIParent')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarYOffUIParent', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },



        {
            type = 'title',
            width = 100,
            label = 'Font Style',
            size = 18
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = 'castbarFont',
            getOptions = function()
                local fonts = LSM:List('font')
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarFont')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarFont', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },

        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'castbarFontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarFontFlag')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarFontFlag', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'Size',
            name = 'castbarFontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 20,
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarFontSize')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarFontSize', value)
                core:UpdateFrameForUnit(unit)
            end
        },
        {
            type = 'color-picker',
            label = 'Color',
            name = 'castbarFontColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarFontColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarFontColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },



        {
            type = 'title',
            width = 100,
            label = 'Bar Style',
            size = 18
        },
        {
            type = 'color-picker',
            label = 'Background Color',
            name = 'castbarBackgroundColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarBackgroundColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarBackgroundColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = 'castbarBackgroundBorderColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarBackgroundBorderColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarBackgroundBorderColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
        {
            type = 'color-picker',
            label = 'Bar Color',
            name = 'castbarForegroundColor',
            currentValue = function()
                return core:GetValueForUnit(unit, 'castbarForegroundColor')
            end,
            onChange = function(value)
                core:UpdateValueForUnit(unit, 'castbarForegroundColor', value)
                core:UpdateFrameForUnit(unit)
            end,
            width = 20
        },
    }
end
