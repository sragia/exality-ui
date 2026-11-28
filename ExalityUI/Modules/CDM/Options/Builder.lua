---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUICDMData
local data = EXUI:GetModule('cdm-data')

---@class EXUICDMOptionsBuilder
local builder = EXUI:GetModule('cdm-options-builder')

-- spec: path, label, width, refresh (re-mount options), list (refresh split list), depends, name, tooltip
local function bind(id, spec, field)
    field.name = spec.name or spec.path
    field.label = spec.label
    field.width = spec.width or 25
    field.depends = spec.depends
    field.tooltip = spec.tooltip
    field.isTextureDropdown = spec.isTextureDropdown
    field.currentValue = function()
        return data:GetValue(id, spec.path)
    end
    field.onChange = function(value)
        data:SetValue(id, spec.path, value)
        EXUI:GetModule('cdm'):Refresh()
        if spec.list then
            optionsFields:RefreshItemList()
        end
        if spec.refresh then
            optionsFields:RefreshOptions()
        end
    end
    return field
end

function builder:Toggle(id, spec)
    return bind(id, spec, { type = 'toggle' })
end

function builder:Range(id, spec, min, max, step)
    return bind(id, spec, { type = 'range', min = min, max = max, step = step or 1 })
end

function builder:Dropdown(id, spec, options)
    local field = bind(id, spec, { type = 'dropdown' })
    field.getOptions = type(options) == 'function' and options or function() return options end
    return field
end

function builder:Color(id, spec)
    return bind(id, spec, { type = 'color-picker', hasOpacity = true })
end

function builder:Edit(id, spec)
    return bind(id, spec, { type = 'edit-box' })
end

function builder:Anchor(id, spec)
    return bind(id, spec, { type = 'anchor-point' })
end

function builder:Font(id, spec)
    return self:Dropdown(id, spec, function()
        local fonts = {}
        for _, font in ipairs(LSM:List('font')) do
            fonts[font] = font
        end
        return fonts
    end)
end

function builder:Title(label, extra)
    local field = { type = 'title', label = label, width = 100 }
    for key, value in pairs(extra or {}) do
        field[key] = value
    end
    return field
end

function builder:Description(label)
    return { type = 'description', label = label, width = 100 }
end

function builder:Disclaimer(name, label, depends)
    return { type = 'disclaimer', name = name, label = label, width = 100, depends = depends }
end

function builder:Button(name, label, onClick, width)
    return { type = 'button', name = name, label = label, onClick = onClick, width = width or 25 }
end

function builder:Spacer(width)
    return { type = 'spacer', width = width }
end
