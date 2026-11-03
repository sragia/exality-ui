---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

-- Registry of mask/border styles shared by everything that supports shapes.
---@class EXUIStyles
local styles = EXUI:GetModule('styles')

styles.NONE = 'default'
styles.CUSTOM_PATH = [[Interface\Styles\]]
styles.Data = data:GetControlsForKey('styles')

local registered = {}
local callbacks = {}
local version = 0

local function changed()
    version = version + 1
    for _, callback in ipairs(callbacks) do
        callback()
    end
end

-- File names go in the custom folder, anything with a path separator is used as is.
local function resolvePath(file)
    if not file or file == '' then
        return nil
    end
    if file:find('[\\/]') then
        return file
    end
    return styles.CUSTOM_PATH .. file
end

local function registerBuiltIns()
    local frames = EXUI.const.textures.unitFrames
    local glows = EXUI.const.textures.nameplates
    local builtIns = {
        { 'round-4', 'Rounded (4px)', frames.shapeRound4, frames.shapeRound4Border, 5, glows.glow4 },
        { 'round-6', 'Rounded (6px)', frames.shapeRound6, frames.shapeRound6Border, 7, glows.glow6 },
        { 'round-10', 'Rounded (10px)', frames.shapeRound10, frames.shapeRound10Border, 11, glows.glow10 },
        { 'cut-4', 'Cut (4px)', frames.shapeCut4, frames.shapeCut4Border, 5, glows.glow4 },
        { 'cut-6', 'Cut (6px)', frames.shapeCut6, frames.shapeCut6Border, 7, glows.glow6 },
        { 'cut-10', 'Cut (10px)', frames.shapeCut10, frames.shapeCut10Border, 11, glows.glow10 },
    }
    for order, style in ipairs(builtIns) do
        registered[style[1]] = {
            id = style[1],
            name = style[2],
            mask = style[3],
            border = style[4],
            margins = { style[5], style[5], style[5], style[5] },
            glow = style[6],
            glowBand = 14,
            builtin = true,
            order = order,
        }
    end
end

registerBuiltIns()

styles.Init = function(self)
    for id in pairs(self:GetCustomDB()) do
        self:RegisterCustom(id)
    end
end

styles.GetProfileExportSpec = function(self)
    return { id = 'styles', keys = { 'styles' } }
end

styles.Register = function(self, id, def)
    def.id = id
    registered[id] = def
    changed()
end

styles.Unregister = function(self, id)
    registered[id] = nil
    changed()
end

styles.RegisterCallback = function(self, callback)
    table.insert(callbacks, callback)
end

styles.Get = function(self, id)
    return id and registered[id]
end

styles.IsStyle = function(self, id)
    return id ~= nil and registered[id] ~= nil
end

-- Bumps whenever a style is added, edited or removed so cached textures can be re-applied.
styles.GetVersion = function(self)
    return version
end

-- Margins are left, top, right, bottom like SetTextureSliceMargins.
styles.GetArt = function(self, id)
    local style = self:Get(id)
    if not style then
        return nil
    end
    return style.mask, style.border, style.margins
end

styles.ApplySlices = function(self, texture, margins)
    texture:SetTextureSliceMargins(margins[1], margins[2], margins[3], margins[4])
    texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
end

styles.GetGlow = function(self, id)
    local style = self:Get(id)
    if not style or not style.glow then
        return nil
    end
    return style.glow, style.glowBand or 14
end

styles.List = function(self)
    local list = {}
    for _, style in pairs(registered) do
        table.insert(list, style)
    end
    table.sort(list, function(a, b)
        if (a.builtin == true) ~= (b.builtin == true) then
            return b.builtin == true
        end
        if a.builtin then
            return a.order < b.order
        end
        return (a.name or '') < (b.name or '')
    end)
    return list
end

------------------------------------------------------------
-- Targets: settings that pick a style, so styles can be applied to them from one place.

local targets = {}

-- def: label, order, get() returning the style ID in use, set(styleID)
styles.RegisterTarget = function(self, id, def)
    def.id = id
    targets[id] = def
end

styles.GetTargets = function(self)
    local list = {}
    for _, target in pairs(targets) do
        table.insert(list, target)
    end
    table.sort(list, function(a, b) return (a.order or 0) < (b.order or 0) end)
    return list
end

styles.GetDropdownOptions = function(self, includeUseDefault)
    local options = {
        [self.NONE] = { label = 'None', order = 1 },
    }
    if includeUseDefault then
        options[''] = { label = 'Use Default', order = 0 }
    end
    for index, style in ipairs(self:List()) do
        options[style.id] = {
            label = style.name,
            order = index + 1,
            icon = { texture = style.mask, width = 16, height = 16 },
        }
    end
    return options
end

------------------------------------------------------------
-- Custom styles. Saved with file names, registered with full paths.

styles.GetCustomDB = function(self)
    local custom = self.Data:GetValue('custom')
    if not custom then
        custom = {}
        self.Data:SetValue('custom', custom)
    end
    return custom
end

styles.GetCustom = function(self, id)
    return self:GetCustomDB()[id]
end

-- Older custom styles saved one margin for all sides.
styles.GetCustomMargins = function(self, id)
    local custom = self:GetCustom(id)
    if not custom.margins then
        local margin = custom.margin or 5
        custom.margins = { margin, margin, margin, margin }
        custom.margin = nil
    end
    return custom.margins
end

styles.RegisterCustom = function(self, id)
    local custom = self:GetCustom(id)
    if not custom then
        return
    end
    self:Register(id, {
        name = custom.name,
        mask = resolvePath(custom.mask),
        border = resolvePath(custom.border),
        margins = self:GetCustomMargins(id),
        glow = resolvePath(custom.glow),
        glowBand = custom.glowBand or 14,
    })
end

styles.CreateCustom = function(self, fromID)
    local id = 'custom-' .. EXUI.utils.generateRandomString(10)
    local source = self:Get(fromID)
    local custom
    if source then
        custom = {
            name = source.name .. ' (Copy)',
            mask = source.mask,
            border = source.border,
            margins = CopyTable(source.margins),
            glow = source.glow,
            glowBand = source.glowBand,
        }
        if not source.builtin then
            local raw = self:GetCustom(fromID)
            custom.mask, custom.border, custom.glow = raw.mask, raw.border, raw.glow
        end
    else
        custom = { name = 'New Style', mask = '', border = '', margins = { 5, 5, 5, 5 }, glow = '', glowBand = 14 }
    end
    self:GetCustomDB()[id] = custom
    self:RegisterCustom(id)
    return id
end

styles.UpdateCustom = function(self, id, key, value)
    local custom = self:GetCustom(id)
    if not custom then
        return
    end
    custom[key] = value
    self:RegisterCustom(id)
end

styles.DeleteCustom = function(self, id)
    self:GetCustomDB()[id] = nil
    self:Unregister(id)
end
