---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsNavIcons
local navIcons = EXUI:GetModule('options-nav-icons')

local DEFAULT_ICON = 'Interface/Icons/INV_Misc_QuestionMark'

local icons = {
    ['General'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/general.png]],
    ['Unit Frames'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/unit-frames.png]],
    ['Action Bars'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/action-bars.png]],
    ['Resource Displays'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/resource-displays.png]],
    ['Cooldowns'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/cooldowns.png]],
    ['Minimap'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/minimap.png]],
    ['Data Brokers'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/data-brokers.png]],
    ['Quality of Life'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/quality-of-life.png]],
    ['Raid Tools'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/raid-tools.png]],
    ['XP Bar'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/xp-bar.png]],
    ['Notifications'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/notifications.png]],
    ['Tweaks/Bugfixes'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/tweaks-bugfixes.png]],
    ['Custom Windows'] = [[Interface/Addons/ExalityUI/Assets/Images/Menu/custom-windows.png]],
}

navIcons.Get = function(self, name, module)
    if (module and module.GetIcon) then
        local icon = module:GetIcon()
        if (icon) then
            return icon
        end
    end
    return icons[name] or DEFAULT_ICON
end
