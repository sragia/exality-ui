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

------------------

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')


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
        MerchantEnabled = false,
    }
end

customWindows.GetOptions = function(self)
    local options = {
        {
            type = 'disclaimer',
            label =
            'These replace Blizzard windows, so other addons cannot customize them unless they add support specifically for ExalityUI.',
            name = 'customWindowsNotice',
            width = 100,
        },
        {
            label = 'Character Frame',
            name = 'paperDollEnabled',
            type = 'toggle',
            onChange = function(value)
                customWindows.Data:SetValue('CharacterFrameEnabled', value)
                if (value) then
                    characterFrame:Enable()
                else
                    characterFrame:Disable()
                end
            end,
            currentValue = function()
                return customWindows.Data:GetValue('CharacterFrameEnabled')
            end,
            width = 100,
        },
        {
            type = 'description',
            label =
            "Character frame with updated visuals without reskinning existing frames.",
            width = 100,
        },
        {
            label = 'Talents',
            name = 'talentsEnabled',
            type = 'toggle',
            onChange = function(value)
                customWindows.Data:SetValue('TalentsEnabled', value)
                if (value) then
                    talentsWindow:Enable()
                else
                    talentsWindow:Disable()
                end
            end,
            currentValue = function()
                return customWindows.Data:GetValue('TalentsEnabled') == true
            end,
            width = 100,
        },
        {
            type = 'description',
            label =
            "Talents & Spellbook reimagined (not really but buzzwords you know).",
            width = 100,
        },
        {
            label = 'Merchant',
            name = 'merchantEnabled',
            type = 'toggle',
            onChange = function(value)
                customWindows.Data:SetValue('MerchantEnabled', value)
                if (value) then
                    merchantWindow:Enable()
                else
                    merchantWindow:Disable()
                end
            end,
            currentValue = function()
                return customWindows.Data:GetValue('MerchantEnabled') == true
            end,
            width = 100,
        },
        {
            type = 'description',
            label =
            'Vendor window with a paged item grid and bulk buying.',
            width = 100,
        },
    }

    if (EXUI.IsRetail() or EXUI.IsForever()) then
        table.insert(options, {
            label = 'Map & Quest Log',
            name = 'questLogEnabled',
            type = 'toggle',
            onChange = function(value)
                customWindows.Data:SetValue('QuestLogEnabled', value)
                if (value) then
                    questLogWindow:Enable()
                else
                    questLogWindow:Disable()
                end
            end,
            currentValue = function()
                return customWindows.Data:GetValue('QuestLogEnabled') == true
            end,
            width = 100,
        })
        table.insert(options, {
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
        })
        table.insert(options, {
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
        })
        table.insert(options, {
            type = 'description',
            label =
            'Minimal map window with quest log.',
            width = 100,
        })
    end

    return options
end

customWindows.Data = data:GetControlsForKey('custom-windows')
