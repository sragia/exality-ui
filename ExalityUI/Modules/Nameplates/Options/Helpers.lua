---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUINameplatesOptionsHelpers
local helpers = EXUI:GetModule('np-options-helpers')

local LSM = LibStub('LibSharedMedia-3.0', true)

helpers.Refresh = function()
    npCore:UpdateAllPlates()
end

helpers.Get = function(key)
    return npCore:GetValue(key)
end

helpers.Set = function(key, value)
    npCore:SetValue(key, value)
    npCore:UpdateAllPlates()
end

helpers.SetCVar = function(key, value)
    npCore:SetValue(key, value)
    EXUI:GetModule('np-cvars'):ApplyKey(key, value)
end

helpers.CVarExists = function(key)
    return EXUI:GetModule('np-cvars'):Exists(key)
end

helpers.CVarToggle = function(label, key)
    return {
        type = 'toggle',
        label = label,
        name = key,
        width = 100,
        depends = function()
            return helpers.CVarExists(key)
        end,
        currentValue = function()
            return npCore:GetValue(key)
        end,
        onChange = function(value)
            helpers.SetCVar(key, value)
        end,
    }
end

helpers.CVarRange = function(label, key, min, max, step, width)
    return {
        type = 'range',
        label = label,
        name = key,
        min = min,
        max = max,
        step = step or 1,
        width = width or 50,
        depends = function()
            return helpers.CVarExists(key)
        end,
        currentValue = function()
            return npCore:GetValue(key)
        end,
        onChange = function(value)
            helpers.SetCVar(key, value)
        end,
    }
end

helpers.CVarDropdown = function(label, key, getOptions, width)
    return {
        type = 'dropdown',
        label = label,
        name = key,
        width = width or 50,
        getOptions = getOptions,
        depends = function()
            return helpers.CVarExists(key)
        end,
        currentValue = function()
            return npCore:GetValue(key)
        end,
        onChange = function(value)
            helpers.SetCVar(key, value)
        end,
    }
end

helpers.Toggle = function(label, key)
    return {
        type = 'toggle',
        label = label,
        name = key,
        width = 100,
        currentValue = function()
            return npCore:GetValue(key)
        end,
        onChange = function(value)
            helpers.Set(key, value)
        end,
    }
end

helpers.Range = function(label, key, min, max, step, width)
    return {
        type = 'range',
        label = label,
        name = key,
        min = min,
        max = max,
        step = step or 1,
        width = width or 25,
        currentValue = function()
            return npCore:GetValue(key)
        end,
        onChange = function(value)
            helpers.Set(key, value)
        end,
    }
end

helpers.Color = function(label, key, width)
    return {
        type = 'color-picker',
        label = label,
        name = key,
        width = width or 25,
        currentValue = function()
            return npCore:GetValue(key)
        end,
        onChange = function(value)
            helpers.Set(key, value)
        end,
    }
end

helpers.Dropdown = function(label, key, getOptions, width)
    return {
        type = 'dropdown',
        label = label,
        name = key,
        width = width or 25,
        getOptions = getOptions,
        currentValue = function()
            return npCore:GetValue(key)
        end,
        onChange = function(value)
            helpers.Set(key, value)
        end,
    }
end

helpers.FontDropdown = function(label, key, width)
    local field = helpers.Dropdown(label, key, function()
        local options = {}
        if LSM then
            for _, font in ipairs(LSM:List('font')) do
                options[font] = font
            end
        end
        return options
    end, width)
    field.isFontDropdown = true
    return field
end

helpers.TextureDropdown = function(label, key, width)
    local field = helpers.Dropdown(label, key, function()
        local options = {}
        if LSM then
            for _, texture in ipairs(LSM:List('statusbar')) do
                options[texture] = texture
            end
        end
        return options
    end, width)
    field.isTextureDropdown = true
    return field
end

helpers.Anchor = function(label, key, width)
    return {
        type = 'anchor-point',
        label = label,
        name = key,
        width = width or 25,
        currentValue = function()
            return npCore:GetValue(key)
        end,
        onChange = function(value)
            helpers.Set(key, value)
        end,
    }
end

helpers.TextOptions = function(prefix)
    return {
        helpers.Toggle('Enable', prefix .. 'Enable'),
        { type = 'title', label = 'Font Style', width = 100, size = 18 },
        helpers.FontDropdown('Font', prefix .. 'Font', 23),
        helpers.Dropdown('Font Flag', prefix .. 'FontFlag', function()
            return EXUI.const.fontFlags
        end, 23),
        helpers.Range('Size', prefix .. 'FontSize', 1, 40, 1, 20),
        helpers.Color('Color', prefix .. 'FontColor', 20),
        { type = 'title', label = 'Position', width = 100, size = 18 },
        helpers.Anchor('Anchor Point', prefix .. 'AnchorPoint', 23),
        helpers.Anchor('Relative Anchor Point', prefix .. 'RelativeAnchorPoint', 23),
        { type = 'spacer', width = 54 },
        helpers.Range('X Offset', prefix .. 'XOffset', -200, 200, 1, 23),
        helpers.Range('Y Offset', prefix .. 'YOffset', -200, 200, 1, 23),
    }
end
