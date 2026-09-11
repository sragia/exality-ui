---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIDamageMetersModule
local meters = EXUI:GetModule('damage-meters')

local LSM = LibStub('LibSharedMedia-3.0', true)

---@class EXUIDamageMetersStyleOptions
local styleOptions = EXUI:GetModule('damage-meters-style-options')

local function windowEnabled(windowID)
    return function()
        return meters:GetModuleValue('enable') and meters:GetValue(windowID, 'enable')
    end
end

function styleOptions:GetOptions(windowID)
    local enabled = windowEnabled(windowID)

    return {
        {
            type = 'title',
            label = 'Window',
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Show View Title',
            name = 'showTitle',
            width = 100,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'showTitle')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'showTitle', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'toggle',
            label = 'Show Combat Timer',
            name = 'showTimer',
            width = 100,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'showTimer')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'showTimer', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = 'borderColor',
            width = 50,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'borderColor')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'borderColor', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'color-picker',
            label = 'Backdrop Color',
            name = 'backdropColor',
            width = 50,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'backdropColor')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'backdropColor', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'title',
            label = 'Bars',
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'Bar Texture',
            name = 'barTexture',
            isTextureDropdown = true,
            width = 50,
            depends = enabled,
            getOptions = function()
                local textures = LSM and LSM:List('statusbar') or { 'ExalityUI Status Bar' }
                local options = {}
                for _, texture in ipairs(textures) do
                    options[texture] = texture
                end
                return options
            end,
            currentValue = function()
                return meters:GetValue(windowID, 'barTexture')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'barTexture', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Bar Height',
            name = 'barHeight',
            min = 10,
            max = 36,
            step = 1,
            width = 25,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'barHeight')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'barHeight', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Bar Spacing',
            name = 'barSpacing',
            min = 0,
            max = 8,
            step = 1,
            width = 25,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'barSpacing')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'barSpacing', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'toggle',
            label = 'Class Color',
            name = 'useClassColor',
            width = 100,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'useClassColor')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'useClassColor', value)
                meters:UpdateById(windowID)
                EXUI:GetModule('options-fields'):RefreshOptions()
            end,
        },
        {
            type = 'color-picker',
            label = 'Custom Bar Color',
            name = 'customBarColor',
            width = 50,
            depends = function()
                return enabled() and not meters:GetValue(windowID, 'useClassColor')
            end,
            currentValue = function()
                return meters:GetValue(windowID, 'customBarColor')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'customBarColor', value)
                meters:UpdateById(windowID)
            end,
        },
    }
end
