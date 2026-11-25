---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUICharacterFrameWindow
local characterFrame = EXUI:GetModule('character-frame-window')

---@class EXUITalentsWindow
local talentsWindow = EXUI:GetModule('talents-window')

---@class EXUIQuestLogWindow
local questLogWindow = EXUI:GetModule('quest-log-window')

---@class EXUIMerchantWindow
local merchantWindow = EXUI:GetModule('merchant-window')

---@class EXUILootRolls
local lootRolls = EXUI:GetModule('loot-rolls')

---@class EXUILootWindow
local lootWindow = EXUI:GetModule('loot-window')

------------------

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')

customWindows.useSplitView = true

local REPLACE_NOTICE =
'Replaces the Blizzard window, so other addons cannot customize it unless they add support specifically for ExalityUI.'

customWindows.Init = function(self)
    optionsController:RegisterModule(self)
    self.Data:UpdateDefaults(self:GetDefaults())
end

customWindows.GetName = function(self)
    return 'Custom Windows'
end

customWindows.GetCategory = function(self)
    return 'Quality of Life'
end

customWindows.GetOrder = function(self)
    return 100
end

customWindows.GetProfileExportSpec = function(self)
    return { id = 'custom-windows', keys = { 'custom-windows' } }
end

customWindows.GetDefaults = function(self)
    return {
        TalentsEnabled = false,
        QuestLogEnabled = false,
        QuestLogSide = 'right',
        QuestLogMapHeight = questLogWindow.mapHeightDefault or 533,
        QuestLogCoordinates = true,
        MerchantEnabled = false,
        LootRollsEnabled = false,
        LootRollsGrowth = 'up',
        LootRollsResultHold = 2,
        LootRollsAnchor = 'TOP',
        LootRollsRelativeAnchor = 'CENTER',
        LootRollsXOff = 0,
        LootRollsYOff = -150,
        LootWindowEnabled = false,
    }
end

local function HasQuestLog()
    return EXUI.IsRetail() or EXUI.IsForever()
end

customWindows.GetSplitViewItems = function(self)
    local items = {
        { label = 'Character Frame', ID = 'characterFrame' },
        { label = 'Talents', ID = 'talents' },
        { label = 'Merchant', ID = 'merchant' },
    }
    if (HasQuestLog()) then
        table.insert(items, { label = 'Map & Quest Log', ID = 'questLog' })
    end
    table.insert(items, { label = 'Loot', ID = 'loot' })
    return items
end

local function Disclaimer(text)
    return {
        type = 'disclaimer',
        label = text .. ' ' .. REPLACE_NOTICE,
        name = 'disclaimer',
        width = 100,
    }
end

local function EnableToggle(label, name, key, window, strict)
    return {
        label = label,
        name = name,
        type = 'toggle',
        onChange = function(value)
            customWindows.Data:SetValue(key, value)
            if (value) then
                window:Enable()
            else
                window:Disable()
            end
        end,
        currentValue = function()
            local value = customWindows.Data:GetValue(key)
            if (strict) then
                return value == true
            end
            return value
        end,
        width = 100,
    }
end

local function Group(label, name, children)
    return {
        type = 'optionGroup',
        label = label,
        name = name,
        width = 100,
        collapsible = true,
        expanded = true,
        children = children,
    }
end

local function GetQuestLogOptions()
    return {
        Disclaimer('Minimal map window with quest log.'),
        EnableToggle('Enable', 'questLogEnabled', 'QuestLogEnabled', questLogWindow, true),
        Group('Settings', 'questLogSettings', {
            {
                label = 'Quest Log Side',
                name = 'questLogSide',
                type = 'dropdown',
                width = 50,
                getOptions = function()
                    return {
                        right = { label = 'Right', order = 1 },
                        left = { label = 'Left', order = 2 },
                    }
                end,
                currentValue = function()
                    return customWindows.Data:GetValue('QuestLogSide') or 'right'
                end,
                onChange = function(value)
                    customWindows.Data:SetValue('QuestLogSide', value)
                    if (questLogWindow.Layout and questLogWindow.isCreated) then
                        questLogWindow:Layout()
                    end
                end,
            },
            {
                label = 'Map Height',
                name = 'questLogMapHeight',
                type = 'range',
                width = 50,
                min = questLogWindow.mapHeightMin or 400,
                max = questLogWindow.mapHeightMax or 1100,
                step = 1,
                currentValue = function()
                    return customWindows.Data:GetValue('QuestLogMapHeight') or questLogWindow.mapHeightDefault or 533
                end,
                onChange = function(value)
                    customWindows.Data:SetValue('QuestLogMapHeight', value)
                    if (questLogWindow.Layout and questLogWindow.isCreated) then
                        questLogWindow:Layout()
                    end
                end,
            },
            {
                label = 'Show Coordinates',
                name = 'questLogCoordinates',
                type = 'toggle',
                width = 50,
                currentValue = function()
                    return customWindows.Data:GetValue('QuestLogCoordinates') ~= false
                end,
                onChange = function(value)
                    customWindows.Data:SetValue('QuestLogCoordinates', value)
                    questLogWindow:ApplyCoordinatesSetting()
                end,
            },
        }),
    }
end

local function PositionOption(fieldType, label, name, key)
    return {
        type = fieldType,
        label = label,
        name = name,
        width = 25,
        min = -1500,
        max = 1500,
        step = 1,
        currentValue = function()
            return customWindows.Data:GetValue(key)
        end,
        onChange = function(value)
            customWindows.Data:SetValue(key, value)
            lootRolls:UpdatePosition()
        end,
    }
end

local function GetLootOptions()
    return {
        Disclaimer(
            'Loot roll frames showing who picked Need, Greed, Transmog or Pass, and a loot window for /loot with roll winners per encounter.'),
        Group('Roll Frames', 'lootRollsGroup', {
            EnableToggle('Enable Roll Frames', 'lootRollsEnabled', 'LootRollsEnabled', lootRolls, true),
            {
                label = 'Grow Direction',
                name = 'lootRollsGrowth',
                type = 'dropdown',
                width = 50,
                getOptions = function()
                    return {
                        up = { label = 'Up', order = 1 },
                        down = { label = 'Down', order = 2 },
                    }
                end,
                currentValue = function()
                    return customWindows.Data:GetValue('LootRollsGrowth') or 'up'
                end,
                onChange = function(value)
                    customWindows.Data:SetValue('LootRollsGrowth', value)
                    lootRolls:Layout()
                end,
            },
            {
                label = 'Result Duration',
                name = 'lootRollsResultHold',
                type = 'range',
                width = 50,
                min = 0,
                max = 30,
                step = 0.5,
                currentValue = function()
                    return customWindows.Data:GetValue('LootRollsResultHold') or 2
                end,
                onChange = function(value)
                    customWindows.Data:SetValue('LootRollsResultHold', value)
                end,
            },
            {
                label = 'Toggle Preview',
                name = 'lootRollsPreview',
                type = 'button',
                width = 50,
                onClick = function()
                    lootRolls:TogglePreview()
                end,
            },
        }),
        Group('Roll Frames Position', 'lootRollsPosition', {
            PositionOption('anchor-point', 'Anchor Point', 'lootRollsAnchor', 'LootRollsAnchor'),
            PositionOption('anchor-point', 'Relative Anchor Point', 'lootRollsRelativeAnchor', 'LootRollsRelativeAnchor'),
            PositionOption('range', 'X Offset', 'lootRollsXOff', 'LootRollsXOff'),
            PositionOption('range', 'Y Offset', 'lootRollsYOff', 'LootRollsYOff'),
        }),
        Group('Loot Window', 'lootWindowGroup', {
            EnableToggle('Enable Loot Window', 'lootWindowEnabled', 'LootWindowEnabled', lootWindow, true),
        }),
    }
end

customWindows.GetOptions = function(self, _, currItemID)
    if (currItemID == 'characterFrame') then
        return {
            Disclaimer('Character frame with updated visuals without reskinning existing frames.'),
            EnableToggle('Enable', 'paperDollEnabled', 'CharacterFrameEnabled', characterFrame),
        }
    elseif (currItemID == 'talents') then
        return {
            Disclaimer('Talents & Spellbook reimagined (not really but buzzwords you know).'),
            EnableToggle('Enable', 'talentsEnabled', 'TalentsEnabled', talentsWindow, true),
        }
    elseif (currItemID == 'merchant') then
        return {
            Disclaimer('Vendor window with a paged item grid and bulk buying.'),
            EnableToggle('Enable', 'merchantEnabled', 'MerchantEnabled', merchantWindow, true),
        }
    elseif (currItemID == 'questLog' and HasQuestLog()) then
        return GetQuestLogOptions()
    elseif (currItemID == 'loot') then
        return GetLootOptions()
    end
    return {}
end

customWindows.Data = data:GetControlsForKey('custom-windows')
