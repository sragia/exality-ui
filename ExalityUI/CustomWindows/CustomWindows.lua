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
    }
end

customWindows.GetOptions = function(self)
    return {
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
            "Replaces default Blizzard character frame (PaperDollFrame) with fully custom character frame. Unfortunately, this can't be used in combat and will be hidden on entering combat.",
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
            "Replaces the default talents and spellbook window out of combat. In combat it closes and the Blizzard window is used instead.",
            width = 100,
        }
    }
end

customWindows.Data = data:GetControlsForKey('custom-windows')
