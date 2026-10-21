---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsNavIcons
local navIcons = EXUI:GetModule('options-nav-icons')

local DEFAULT_ICON = 'Interface/Icons/INV_Misc_QuestionMark'

local SPRITE = [[Interface/Addons/ExalityUI/Assets/Images/Menu/menu-icons-sprite.png]]
local SHEET_W = 261
local SHEET_H = 1171
local CELL = 64
local ORIGIN = 1
local STRIDE = 65

local function CellCoords(col, row)
    local left = (ORIGIN + col * STRIDE) / SHEET_W
    local top = (ORIGIN + row * STRIDE) / SHEET_H
    return { left, left + CELL / SHEET_W, top, top + CELL / SHEET_H }
end

local function SpriteIcon(row)
    return {
        texture = SPRITE,
        inactive = CellCoords(0, row),
        active = CellCoords(1, row),
    }
end

local function SpriteIconAt(col, row)
    return {
        texture = SPRITE,
        inactive = CellCoords(col, row),
        active = CellCoords(col + 1, row),
    }
end

-- Row order matches the collapsed options menu.
local icons = {
    ['General'] = SpriteIcon(0),
    ['Unit Frames'] = SpriteIcon(1),
    ['Nameplates'] = SpriteIcon(2),
    ['Action Bars'] = SpriteIcon(3),
    ['Resource Displays'] = SpriteIcon(4),
    ['Aura Displays'] = SpriteIcon(5),
    ['Damage Meters'] = SpriteIcon(6),
    ['Cooldowns'] = SpriteIcon(7),
    ['Bags'] = SpriteIcon(8),
    ['Chat'] = SpriteIconAt(2, 0),
    ['Minimap'] = SpriteIcon(9),
    ['Data Brokers'] = SpriteIcon(10),
    ['Raid Tools'] = SpriteIcon(11),
    ['XP Bar'] = SpriteIcon(12),
    ['Objective Tracker'] = SpriteIcon(13),
    ['M+ Timer'] = SpriteIcon(14),
    ['Notifications'] = SpriteIcon(15),
    ['Tweaks/Bugfixes'] = SpriteIcon(16),
    ['Custom Windows'] = SpriteIcon(17),
}

navIcons.Get = function(self, name, module)
    local icon = icons[name]
    if (icon) then
        return icon
    end
    if (module and module.GetIcon) then
        local moduleIcon = module:GetIcon()
        if (moduleIcon) then
            return moduleIcon
        end
    end
    return DEFAULT_ICON
end
