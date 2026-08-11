---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIMythicPlusTimerModule
local mythicPlusTimer = EXUI:GetModule('mythic-plus-timer')

---@class EXUIMythicPlusTimerStyleOptions
local styleOptions = EXUI:GetModule('mythic-plus-timer-style-options')

local LSM = LibStub('LibSharedMedia-3.0', true)

local FONT_GROUPS = {
    { prefix = 'death', label = 'Death Counter' },
    { prefix = 'maxTimer', label = 'Max Timer' },
    { prefix = 'deathPenalty', label = 'Death Penalty' },
    { prefix = 'elapsed', label = 'Elapsed Timer' },
    { prefix = 'keyLevel', label = 'Key Level' },
    { prefix = 'milestone', label = 'Milestone Timer' },
    { prefix = 'forcesPercent', label = 'Forces Percent' },
    { prefix = 'forcesRaw', label = 'Forces Count' },
    { prefix = 'boss', label = 'Boss Names' },
}

local function enabled()
    return mythicPlusTimer.Data:GetValue('enable')
end

local function fontFields(prefix, label)
    return {
        {
            type = 'dropdown',
            label = label .. ' Font',
            name = prefix .. 'Font',
            getOptions = function()
                local fonts = LSM and LSM:List('font') or { 'DMSans' }
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            depends = enabled,
            currentValue = function()
                return mythicPlusTimer.Data:GetValue(prefix .. 'Font')
            end,
            onChange = function(value)
                mythicPlusTimer.Data:SetValue(prefix .. 'Font', value)
                mythicPlusTimer:Configure()
            end,
            width = 50,
        },
        {
            type = 'dropdown',
            label = label .. ' Font Flag',
            name = prefix .. 'FontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            depends = enabled,
            currentValue = function()
                return mythicPlusTimer.Data:GetValue(prefix .. 'FontFlag')
            end,
            onChange = function(value)
                mythicPlusTimer.Data:SetValue(prefix .. 'FontFlag', value)
                mythicPlusTimer:Configure()
            end,
            width = 25,
        },
        {
            type = 'range',
            label = label .. ' Font Size',
            name = prefix .. 'FontSize',
            min = 8,
            max = 32,
            step = 1,
            depends = enabled,
            currentValue = function()
                return mythicPlusTimer.Data:GetValue(prefix .. 'FontSize')
            end,
            onChange = function(value)
                mythicPlusTimer.Data:SetValue(prefix .. 'FontSize', value)
                mythicPlusTimer:Configure()
            end,
            width = 25,
        },
    }
end

local function barColorFields(prefix, label)
    return {
        {
            type = 'color-picker',
            label = label .. ' Fill',
            name = prefix .. 'Fill',
            depends = enabled,
            currentValue = function()
                local bar = mythicPlusTimer.Data:GetValue(prefix)
                return bar and bar.fill
            end,
            onChange = function(value)
                local bar = mythicPlusTimer.Data:GetValue(prefix) or {}
                bar.fill = value
                mythicPlusTimer.Data:SetValue(prefix, bar)
                mythicPlusTimer:Configure()
            end,
            width = 33,
        },
        {
            type = 'color-picker',
            label = label .. ' Border',
            name = prefix .. 'Border',
            depends = enabled,
            currentValue = function()
                local bar = mythicPlusTimer.Data:GetValue(prefix)
                return bar and bar.border
            end,
            onChange = function(value)
                local bar = mythicPlusTimer.Data:GetValue(prefix) or {}
                bar.border = value
                mythicPlusTimer.Data:SetValue(prefix, bar)
                mythicPlusTimer:Configure()
            end,
            width = 33,
        },
        {
            type = 'color-picker',
            label = label .. ' Background',
            name = prefix .. 'Background',
            depends = enabled,
            currentValue = function()
                local bar = mythicPlusTimer.Data:GetValue(prefix)
                return bar and bar.background
            end,
            onChange = function(value)
                local bar = mythicPlusTimer.Data:GetValue(prefix) or {}
                bar.background = value
                mythicPlusTimer.Data:SetValue(prefix, bar)
                mythicPlusTimer:Configure()
            end,
            width = 34,
        },
    }
end

function styleOptions:GetOptions()
    local options = {
        {
            type = 'title',
            label = 'Fonts',
            width = 100,
            depends = enabled,
        },
    }

    for _, group in ipairs(FONT_GROUPS) do
        for _, field in ipairs(fontFields(group.prefix, group.label)) do
            options[#options + 1] = field
        end
    end

    options[#options + 1] = {
        type = 'title',
        label = 'Text Colors',
        size = 14,
        width = 100,
        depends = enabled,
    }

    options[#options + 1] = {
        type = 'color-picker',
        label = 'Max Timer Color',
        name = 'maxTimerColor',
        depends = enabled,
        currentValue = function()
            return mythicPlusTimer.Data:GetValue('maxTimerColor')
        end,
        onChange = function(value)
            mythicPlusTimer.Data:SetValue('maxTimerColor', value)
            mythicPlusTimer:Configure()
        end,
        width = 50,
    }

    options[#options + 1] = {
        type = 'color-picker',
        label = 'Elapsed Timer Color',
        name = 'elapsedColor',
        depends = enabled,
        currentValue = function()
            return mythicPlusTimer.Data:GetValue('elapsedColor')
        end,
        onChange = function(value)
            mythicPlusTimer.Data:SetValue('elapsedColor', value)
            mythicPlusTimer:Configure()
        end,
        width = 50,
    }

    options[#options + 1] = {
        type = 'color-picker',
        label = 'Boss Killed Color',
        name = 'bossKilledColor',
        depends = enabled,
        currentValue = function()
            return mythicPlusTimer.Data:GetValue('bossKilledColor')
        end,
        onChange = function(value)
            mythicPlusTimer.Data:SetValue('bossKilledColor', value)
            mythicPlusTimer:Configure()
        end,
        width = 50,
    }

    options[#options + 1] = {
        type = 'color-picker',
        label = 'Boss Pending Color',
        name = 'bossPendingColor',
        depends = enabled,
        currentValue = function()
            return mythicPlusTimer.Data:GetValue('bossPendingColor')
        end,
        onChange = function(value)
            mythicPlusTimer.Data:SetValue('bossPendingColor', value)
            mythicPlusTimer:Configure()
        end,
        width = 50,
    }

    options[#options + 1] = {
        type = 'title',
        label = 'Bars',
        size = 14,
        width = 100,
        depends = enabled,
    }

    options[#options + 1] = {
        type = 'range',
        label = 'Bar Width',
        name = 'barWidth',
        min = 140,
        max = 400,
        step = 1,
        depends = enabled,
        currentValue = function()
            return mythicPlusTimer.Data:GetValue('barWidth')
        end,
        onChange = function(value)
            mythicPlusTimer.Data:SetValue('barWidth', value)
            mythicPlusTimer:Configure()
        end,
        width = 50,
    }

    options[#options + 1] = {
        type = 'dropdown',
        label = 'Bar Texture',
        name = 'barTexture',
        getOptions = function()
            local textures = LSM and LSM:List('statusbar') or { 'ExalityUI Noisy' }
            local optionsMap = {}
            for _, texture in ipairs(textures) do
                optionsMap[texture] = texture
            end
            return optionsMap
        end,
        isTextureDropdown = true,
        depends = enabled,
        currentValue = function()
            return mythicPlusTimer.Data:GetValue('barTexture')
        end,
        onChange = function(value)
            mythicPlusTimer.Data:SetValue('barTexture', value)
            mythicPlusTimer:Configure()
        end,
        width = 50,
    }

    options[#options + 1] = {
        type = 'range',
        label = 'Bar Border Thickness',
        name = 'barBorderThickness',
        min = 0,
        max = 4,
        step = 1,
        depends = enabled,
        currentValue = function()
            return mythicPlusTimer.Data:GetValue('barBorderThickness')
        end,
        onChange = function(value)
            mythicPlusTimer.Data:SetValue('barBorderThickness', value)
            mythicPlusTimer:Configure()
        end,
        width = 50,
    }

    options[#options + 1] = {
        type = 'title',
        label = 'Timer Bar',
        size = 14,
        width = 100,
        depends = enabled,
    }

    options[#options + 1] = {
        type = 'range',
        label = 'Timer Bar Height',
        name = 'timerBarHeight',
        min = 6,
        max = 32,
        step = 1,
        depends = enabled,
        currentValue = function()
            return mythicPlusTimer.Data:GetValue('timerBarHeight')
        end,
        onChange = function(value)
            mythicPlusTimer.Data:SetValue('timerBarHeight', value)
            mythicPlusTimer:Configure()
        end,
        width = 100,
    }

    for _, field in ipairs(barColorFields('timerBar', 'Timer Bar')) do
        options[#options + 1] = field
    end

    options[#options + 1] = {
        type = 'title',
        label = 'Forces Bar',
        size = 14,
        width = 100,
        depends = enabled,
    }

    options[#options + 1] = {
        type = 'range',
        label = 'Forces Bar Height',
        name = 'forcesBarHeight',
        min = 6,
        max = 32,
        step = 1,
        depends = enabled,
        currentValue = function()
            return mythicPlusTimer.Data:GetValue('forcesBarHeight')
        end,
        onChange = function(value)
            mythicPlusTimer.Data:SetValue('forcesBarHeight', value)
            mythicPlusTimer:Configure()
        end,
        width = 100,
    }

    for _, field in ipairs(barColorFields('forcesBar', 'Forces Bar')) do
        options[#options + 1] = field
    end

    return options
end
