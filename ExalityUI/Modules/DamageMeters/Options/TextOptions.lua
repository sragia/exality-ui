---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIDamageMetersModule
local meters = EXUI:GetModule('damage-meters')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

local LSM = LibStub('LibSharedMedia-3.0', true)

---@class EXUIDamageMetersTextOptions
local textOptions = EXUI:GetModule('damage-meters-text-options')

local TEXT_SECTIONS = {
    { key = 'name', label = 'Name' },
    { key = 'value', label = 'Value' },
    { key = 'secondary', label = 'Secondary' },
    { key = 'percent', label = 'Percent' },
}

local function windowEnabled(windowID)
    return function()
        return meters:GetModuleValue('enable') and meters:GetValue(windowID, 'enable')
    end
end

local function getFontOptions()
    local fonts = LSM and LSM:List('font') or { 'DMSans' }
    local options = {}
    for _, font in ipairs(fonts) do
        options[font] = font
    end
    return options
end

local function usesCustomFont(windowID, textKey)
    return meters:GetTextValue(windowID, textKey, 'useDefaultFont') == false
end

function textOptions:GetTextSection(windowID, textKey, label, enabled)
    local customFont = function()
        return enabled() and usesCustomFont(windowID, textKey)
    end

    local function updateText(field, value)
        meters:UpdateTextValue(windowID, textKey, field, value)
        meters:UpdateById(windowID)
    end

    return {
        {
            type = 'title',
            label = label,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Show',
            name = textKey .. 'Show',
            width = 100,
            depends = enabled,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'show') ~= false
            end,
            onChange = function(value)
                updateText('show', value)
            end,
        },
        {
            type = 'color-picker',
            label = 'Color',
            name = textKey .. 'Color',
            width = 50,
            depends = enabled,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'color')
            end,
            onChange = function(value)
                updateText('color', value)
            end,
        },
        {
            type = 'toggle',
            label = 'Use Default Font',
            name = textKey .. 'UseDefaultFont',
            width = 100,
            depends = enabled,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'useDefaultFont') ~= false
            end,
            onChange = function(value)
                updateText('useDefaultFont', value)
                optionsFields:RefreshOptions()
            end,
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = textKey .. 'Font',
            width = 50,
            depends = customFont,
            isFontDropdown = true,
            getOptions = getFontOptions,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'font')
            end,
            onChange = function(value)
                updateText('font', value)
            end,
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = textKey .. 'FontFlag',
            width = 25,
            depends = customFont,
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'fontFlag')
            end,
            onChange = function(value)
                updateText('fontFlag', value)
            end,
        },
        {
            type = 'range',
            label = 'Font Size',
            name = textKey .. 'FontSize',
            min = 8,
            max = 22,
            step = 1,
            width = 25,
            depends = customFont,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'fontSize')
            end,
            onChange = function(value)
                updateText('fontSize', value)
            end,
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = textKey .. 'AnchorPoint',
            width = 50,
            depends = enabled,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'anchorPoint')
            end,
            onChange = function(value)
                updateText('anchorPoint', value)
            end,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = textKey .. 'RelativePoint',
            width = 50,
            depends = enabled,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'relativePoint')
            end,
            onChange = function(value)
                updateText('relativePoint', value)
            end,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = textKey .. 'XOff',
            min = -200,
            max = 200,
            step = 1,
            width = 25,
            depends = enabled,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'XOff')
            end,
            onChange = function(value)
                updateText('XOff', value)
            end,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = textKey .. 'YOff',
            min = -40,
            max = 40,
            step = 1,
            width = 25,
            depends = enabled,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'YOff')
            end,
            onChange = function(value)
                updateText('YOff', value)
            end,
        },
        {
            type = 'range',
            label = 'Width',
            name = textKey .. 'Width',
            min = 0,
            max = 240,
            step = 1,
            width = 50,
            depends = enabled,
            currentValue = function()
                return meters:GetTextValue(windowID, textKey, 'width')
            end,
            onChange = function(value)
                updateText('width', value)
            end,
        },
    }
end

function textOptions:GetOptions(windowID)
    local enabled = windowEnabled(windowID)
    local options = {
        {
            type = 'title',
            label = 'Default Font',
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = 'font',
            width = 50,
            depends = enabled,
            isFontDropdown = true,
            getOptions = getFontOptions,
            currentValue = function()
                return meters:GetValue(windowID, 'font')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'font', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'fontFlag',
            width = 25,
            depends = enabled,
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return meters:GetValue(windowID, 'fontFlag')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'fontFlag', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Font Size',
            name = 'fontSize',
            min = 8,
            max = 22,
            step = 1,
            width = 25,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'fontSize')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'fontSize', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'toggle',
            label = 'Class Color Name',
            name = 'classColorName',
            width = 100,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'classColorName')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'classColorName', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Value Decimals',
            name = 'valueDecimals',
            min = 0,
            max = 2,
            step = 1,
            width = 50,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'valueDecimals')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'valueDecimals', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'toggle',
            label = 'Show Rank',
            name = 'showRank',
            width = 100,
            depends = enabled,
            currentValue = function()
                return meters:GetValue(windowID, 'showRank')
            end,
            onChange = function(value)
                meters:UpdateValue(windowID, 'showRank', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'title',
            label = 'Icon',
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Show Spec / Class Icon',
            name = 'iconShow',
            width = 100,
            depends = enabled,
            currentValue = function()
                return meters:GetIconValue(windowID, 'show')
            end,
            onChange = function(value)
                meters:UpdateIconValue(windowID, 'show', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Width',
            name = 'iconWidth',
            min = 8,
            max = 64,
            step = 1,
            width = 25,
            depends = enabled,
            currentValue = function()
                return meters:GetIconValue(windowID, 'width')
            end,
            onChange = function(value)
                meters:UpdateIconValue(windowID, 'width', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Height',
            name = 'iconHeight',
            min = 8,
            max = 64,
            step = 1,
            width = 25,
            depends = enabled,
            currentValue = function()
                return meters:GetIconValue(windowID, 'height')
            end,
            onChange = function(value)
                meters:UpdateIconValue(windowID, 'height', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Zoom',
            name = 'iconZoom',
            min = 0,
            max = 40,
            step = 1,
            width = 50,
            depends = enabled,
            currentValue = function()
                return meters:GetIconValue(windowID, 'zoom')
            end,
            onChange = function(value)
                meters:UpdateIconValue(windowID, 'zoom', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'iconAnchorPoint',
            width = 50,
            depends = enabled,
            currentValue = function()
                return meters:GetIconValue(windowID, 'anchorPoint')
            end,
            onChange = function(value)
                meters:UpdateIconValue(windowID, 'anchorPoint', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'iconRelativePoint',
            width = 50,
            depends = enabled,
            currentValue = function()
                return meters:GetIconValue(windowID, 'relativePoint')
            end,
            onChange = function(value)
                meters:UpdateIconValue(windowID, 'relativePoint', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'iconXOff',
            min = -200,
            max = 200,
            step = 1,
            width = 25,
            depends = enabled,
            currentValue = function()
                return meters:GetIconValue(windowID, 'XOff')
            end,
            onChange = function(value)
                meters:UpdateIconValue(windowID, 'XOff', value)
                meters:UpdateById(windowID)
            end,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'iconYOff',
            min = -40,
            max = 40,
            step = 1,
            width = 25,
            depends = enabled,
            currentValue = function()
                return meters:GetIconValue(windowID, 'YOff')
            end,
            onChange = function(value)
                meters:UpdateIconValue(windowID, 'YOff', value)
                meters:UpdateById(windowID)
            end,
        },
    }

    for _, section in ipairs(TEXT_SECTIONS) do
        local sectionOptions = self:GetTextSection(windowID, section.key, section.label, enabled)
        for _, option in ipairs(sectionOptions) do
            table.insert(options, option)
        end
    end

    return options
end
