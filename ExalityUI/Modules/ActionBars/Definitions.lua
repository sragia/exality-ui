---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

definitions.PLAYER_BAR_IDS = { 'bar1', 'bar2', 'bar3', 'bar4', 'bar5', 'bar6', 'bar7', 'bar8' }

definitions.SPECIAL_BAR_IDS = { 'stance', 'pet', 'extra', 'vehicleLeave', 'override' }

definitions.ALL_BAR_IDS = {}

definitions.BARS = {
    bar1 = {
        id = 'bar1',
        label = 'Bar 1',
        blizzardFrame = 'MainActionBar',
        barType = 'action',
        numButtons = 12,
        baseSlot = 1,
        dynamicPage = true,
        commandPrefix = 'ACTIONBUTTON',
        defaultEnabled = true,
        defaultAnchor = { point = 'BOTTOM', relativePoint = 'BOTTOM', x = 0, y = 4 },
    },
    bar2 = {
        id = 'bar2',
        label = 'Bar 2',
        blizzardFrame = 'MultiBarBottomLeft',
        barType = 'action',
        numButtons = 12,
        baseSlot = 13,
        dynamicPage = false,
        commandPrefix = 'MULTIACTIONBAR1BUTTON',
        defaultEnabled = true,
        defaultAnchor = { point = 'BOTTOM', relativePoint = 'BOTTOM', x = 0, y = 44 },
    },
    bar3 = {
        id = 'bar3',
        label = 'Bar 3',
        blizzardFrame = 'MultiBarBottomRight',
        barType = 'action',
        numButtons = 12,
        baseSlot = 25,
        dynamicPage = false,
        commandPrefix = 'MULTIACTIONBAR2BUTTON',
        defaultEnabled = true,
        defaultAnchor = { point = 'BOTTOM', relativePoint = 'BOTTOM', x = 0, y = 84 },
    },
    bar4 = {
        id = 'bar4',
        label = 'Bar 4',
        blizzardFrame = 'MultiBarLeft',
        barType = 'action',
        numButtons = 12,
        baseSlot = 37,
        dynamicPage = false,
        commandPrefix = 'MULTIACTIONBAR3BUTTON',
        defaultEnabled = false,
        defaultAnchor = { point = 'RIGHT', relativePoint = 'RIGHT', x = -4, y = 0 },
    },
    bar5 = {
        id = 'bar5',
        label = 'Bar 5',
        blizzardFrame = 'MultiBarRight',
        barType = 'action',
        numButtons = 12,
        baseSlot = 49,
        dynamicPage = false,
        commandPrefix = 'MULTIACTIONBAR4BUTTON',
        defaultEnabled = false,
        defaultAnchor = { point = 'RIGHT', relativePoint = 'RIGHT', x = -44, y = 0 },
    },
    bar6 = {
        id = 'bar6',
        label = 'Bar 6',
        blizzardFrame = 'MultiBar5',
        barType = 'action',
        numButtons = 12,
        baseSlot = 61,
        dynamicPage = false,
        commandPrefix = 'MULTIACTIONBAR5BUTTON',
        defaultEnabled = false,
        defaultAnchor = { point = 'BOTTOM', relativePoint = 'BOTTOM', x = 0, y = 124 },
    },
    bar7 = {
        id = 'bar7',
        label = 'Bar 7',
        blizzardFrame = 'MultiBar6',
        barType = 'action',
        numButtons = 12,
        baseSlot = 73,
        dynamicPage = false,
        commandPrefix = 'MULTIACTIONBAR6BUTTON',
        defaultEnabled = false,
        defaultAnchor = { point = 'BOTTOM', relativePoint = 'BOTTOM', x = 0, y = 164 },
    },
    bar8 = {
        id = 'bar8',
        label = 'Bar 8',
        blizzardFrame = 'MultiBar7',
        barType = 'action',
        numButtons = 12,
        baseSlot = 85,
        dynamicPage = false,
        commandPrefix = 'MULTIACTIONBAR7BUTTON',
        defaultEnabled = false,
        defaultAnchor = { point = 'BOTTOM', relativePoint = 'BOTTOM', x = 0, y = 204 },
    },
    stance = {
        id = 'stance',
        label = 'Stance Bar',
        blizzardFrame = 'StanceBar',
        barType = 'stance',
        numButtons = 10,
        commandPrefix = 'SHAPESHIFT',
        defaultEnabled = true,
        defaultAnchor = { point = 'BOTTOMLEFT', relativePoint = 'BOTTOMLEFT', x = 4, y = 4 },
    },
    pet = {
        id = 'pet',
        label = 'Pet Bar',
        blizzardFrame = 'PetActionBar',
        barType = 'pet',
        numButtons = 10,
        commandPrefix = 'BONUSACTIONBUTTON',
        defaultEnabled = true,
        defaultAnchor = { point = 'CENTER', relativePoint = 'CENTER', x = 0, y = 0 },
    },
    extra = {
        id = 'extra',
        label = 'Extra Abilities',
        blizzardFrame = 'ExtraAbilityContainer',
        barType = 'extraAbilities',
        numButtons = 1,
        commandPrefix = 'EXTRAACTIONBUTTON',
        defaultEnabled = true,
        defaultAnchor = { point = 'BOTTOM', relativePoint = 'BOTTOM', x = 0, y = 160 },
    },
    vehicleLeave = {
        id = 'vehicleLeave',
        label = 'Leave Vehicle',
        blizzardFrame = 'MainMenuBarVehicleLeaveButton',
        barType = 'leaveVehicle',
        numButtons = 1,
        commandPrefix = 'VEHICLEEXIT',
        defaultEnabled = true,
        defaultAnchor = { point = 'BOTTOM', relativePoint = 'BOTTOM', x = -220, y = 4 },
    },
    override = {
        id = 'override',
        label = 'Override Bar',
        blizzardFrame = 'OverrideActionBar',
        barType = 'override',
        numButtons = 6,
        commandPrefix = 'MULTIACTIONBAR1BUTTON',
        defaultEnabled = true,
        defaultAnchor = { point = 'BOTTOM', relativePoint = 'BOTTOM', x = 0, y = 60 },
    },
}

for _, id in ipairs(definitions.PLAYER_BAR_IDS) do
    table.insert(definitions.ALL_BAR_IDS, id)
end
for _, id in ipairs(definitions.SPECIAL_BAR_IDS) do
    table.insert(definitions.ALL_BAR_IDS, id)
end

definitions.Get = function(self, barId)
    return self.BARS[barId]
end

definitions.GetCommandName = function(self, barId, buttonIndex)
    local def = self.BARS[barId]
    if not def or not def.commandPrefix then
        return nil
    end
    local prefix = def.commandPrefix
    if prefix == 'SHAPESHIFT' then
        return 'SHAPESHIFTBUTTON' .. buttonIndex
    end
    if prefix == 'VEHICLEEXIT' then
        return 'VEHICLEEXIT'
    end
    return prefix .. buttonIndex
end

definitions.GetActionSlot = function(self, barId, buttonIndex, page)
    local def = self.BARS[barId]
    if not def or def.barType ~= 'action' then
        return nil
    end
    if def.dynamicPage and page then
        return (page - 1) * 12 + buttonIndex
    end
    if def.baseSlot then
        return def.baseSlot + buttonIndex - 1
    end
    return buttonIndex
end

definitions.IsPlayerBar = function(self, barId)
    for _, id in ipairs(self.PLAYER_BAR_IDS) do
        if id == barId then
            return true
        end
    end
    return false
end
