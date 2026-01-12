---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUICharacterFrameWindow
local characterFrame = EXUI:GetModule('character-frame-window')

------------------

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')


customWindows.Init = function(self)
    optionsController:RegisterModule(self)
end

customWindows.GetName = function(self)
    return 'Custom Windows'
end

customWindows.GetOrder = function(self)
    return 110
end

customWindows.GetDefaults = function(self)
    return {}
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
            label = 'Replaces default Blizzard character frame (PaperDollFrame) with fully custom character frame.',
            width = 100,
        }
    }
end

customWindows.Data = data:GetControlsForKey('custom-windows')
