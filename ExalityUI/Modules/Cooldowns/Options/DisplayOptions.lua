---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICooldownsModule
local cooldowns = EXUI:GetModule('cooldowns')

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUICooldownsDisplayOptions
local displayOptions = EXUI:GetModule('cooldowns-display-options')

local function getFontOptions()
    local fonts = LSM:List('font')
    local options = {}
    for _, font in ipairs(fonts) do
        options[font] = font
    end
    return options
end

function displayOptions:GetOptions(cdID)
    return {
        {
            type = 'title',
            label = 'Size & Position',
            width = 100,
            size = 14,
        },
        {
            type = 'range',
            label = 'Width',
            name = 'width',
            min = 1,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'width')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'width', value)
                cooldowns:UpdateById(cdID)
            end,
        },
        {
            type = 'range',
            label = 'Height',
            name = 'height',
            min = 1,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'height')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'height', value)
                cooldowns:UpdateById(cdID)
            end,
        },
        {
            type = 'spacer',
            width = 60,
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'anchorPoint',
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'anchorPoint')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'anchorPoint', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'relativePoint',
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'relativePoint')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'relativePoint', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'spacer',
            width = 54,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'XOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'XOff')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'XOff', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'YOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'YOff')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'YOff', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'spacer',
            width = 54,
        },
        {
            type = 'dropdown',
            label = 'Frame Strata',
            name = 'frameStrata',
            getOptions = function()
                return EXUI.const.frameStrata
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'frameStrata')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'frameStrata', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 22,
        },
        {
            type = 'range',
            label = 'Frame Level',
            name = 'frameLevel',
            min = 0,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'frameLevel')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'frameLevel', value)
                cooldowns:UpdateById(cdID)
            end,
        },
        {
            type = 'title',
            label = 'Style',
            size = 14,
            width = 100,
        },
        {
            type = 'range',
            label = 'Zoom',
            name = 'zoom',
            min = 0,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'zoom')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'zoom', value)
                cooldowns:UpdateById(cdID)
            end,
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = 'borderColor',
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'borderColor')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'borderColor', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 80,
        },
        {
            type = 'title',
            label = 'Cooldown Text',
            width = 100,
            size = 14,
        },
        {
            type = 'range',
            label = 'Ready Check Interval',
            name = 'readyPollInterval',
            min = 0.2,
            max = 5,
            step = 0.1,
            tooltip = { text = 'How often this display checks if cooldown became ready (seconds).' },
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'readyPollInterval')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'readyPollInterval', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 50,
        },
        {
            type = 'toggle',
            label = 'Desaturate Icon On CD',
            name = 'desaturateOnCooldown',
            tooltip = { text = 'Spell source only. Grays out icon while spell cooldown is active.' },
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'cooldownSource') == 'spell'
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'desaturateOnCooldown')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'desaturateOnCooldown', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 50,
        },
        {
            type = 'toggle',
            label = 'Ignore GCD',
            name = 'ignoreGlobalCooldown',
            tooltip = { text = 'Spell source only. When enabled, global cooldown does not trigger this cooldown display.' },
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'cooldownSource') == 'spell'
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'ignoreGlobalCooldown')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'ignoreGlobalCooldown', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 50,
        },
        {
            type = 'toggle',
            label = 'Show Cooldown Text',
            name = 'showCooldownText',
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'showCooldownText', value)
                cooldowns:UpdateById(cdID)
                EXUI:GetModule('options-fields'):RefreshOptions()
            end,
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'Time Format',
            name = 'cooldownTextFormat',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
            getOptions = function()
                return {
                    default = 'Default',
                    mmss = 'MM:SS (<3m)',
                }
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'cooldownTextFormat')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'cooldownTextFormat', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 50,
        },
        {
            type = 'range',
            label = 'Update Interval',
            name = 'cooldownTextUpdateInterval',
            min = 0.01,
            max = 1,
            step = 0.01,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'cooldownTextUpdateInterval')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'cooldownTextUpdateInterval', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 50,
        },
        {
            type = 'dropdown',
            label = 'CD Font',
            name = 'font',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
            getOptions = getFontOptions,
            isFontDropdown = true,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'font')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'font', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'fontFlag',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'fontFlag')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'fontFlag', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'range',
            label = 'Size',
            name = 'fontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 20,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'fontSize')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'fontSize', value)
                cooldowns:UpdateById(cdID)
            end,
        },
        {
            type = 'spacer',
            width = 34,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
        },
        {
            type = 'anchor-point',
            label = 'CD Anchor Point',
            name = 'fontAnchorPoint',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'fontAnchorPoint')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'fontAnchorPoint', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'anchor-point',
            label = 'CD Relative Anchor Point',
            name = 'fontRelativePoint',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'fontRelativePoint')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'fontRelativePoint', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'spacer',
            width = 54,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'fontXOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 23,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'fontXOff')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'fontXOff', value)
                cooldowns:UpdateById(cdID)
            end,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'fontYOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 23,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showCooldownText')
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'fontYOff')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'fontYOff', value)
                cooldowns:UpdateById(cdID)
            end,
        },
        {
            type = 'title',
            label = 'Stacks Text',
            width = 100,
            size = 14,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks') and
                    cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
        },
        {
            type = 'dropdown',
            label = 'Stacks Font',
            name = 'chargeFont',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks') and
                    cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
            getOptions = getFontOptions,
            isFontDropdown = true,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'chargeFont')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'chargeFont', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'dropdown',
            label = 'Stacks Font Flag',
            name = 'chargeFontFlag',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks') and
                    cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'chargeFontFlag')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'chargeFontFlag', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'range',
            label = 'Stacks Font Size',
            name = 'chargeFontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 20,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks') and
                    cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'chargeFontSize')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'chargeFontSize', value)
                cooldowns:UpdateById(cdID)
            end,
        },
        {
            type = 'spacer',
            width = 34,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks') and
                    cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
        },
        {
            type = 'anchor-point',
            label = 'Stacks Anchor Point',
            name = 'chargeFontAnchorPoint',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks') and
                    cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'chargeFontAnchorPoint')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'chargeFontAnchorPoint', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'anchor-point',
            label = 'Stacks Relative Anchor Point',
            name = 'chargeFontRelativePoint',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks') and
                    cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'chargeFontRelativePoint')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'chargeFontRelativePoint', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 23,
        },
        {
            type = 'spacer',
            width = 54,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks') and
                    cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
        },
        {
            type = 'range',
            label = 'Stacks X Offset',
            name = 'chargeFontXOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 23,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks') and
                    cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'chargeFontXOff')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'chargeFontXOff', value)
                cooldowns:UpdateById(cdID)
            end,
        },
        {
            type = 'range',
            label = 'Stacks Y Offset',
            name = 'chargeFontYOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 23,
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks') and
                    cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'chargeFontYOff')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'chargeFontYOff', value)
                cooldowns:UpdateById(cdID)
            end,
        },
    }
end
