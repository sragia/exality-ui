---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICooldownsModule
local cooldowns = EXUI:GetModule('cooldowns')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUICooldownsLoadOptions
local loadOptions = EXUI:GetModule('cooldowns-load-options')

function loadOptions:GetOptions(cdID)
    return {
        {
            type = 'toggle',
            label = 'Enable Load Conditions',
            name = 'hasLoadConditions',
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'hasLoadConditions')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'hasLoadConditions', value)
                cooldowns:UpdateById(cdID)
                optionsFields:RefreshOptions()
            end,
            width = 100,
        },
        {
            type = 'edit-box',
            label = 'Load Only on Player/s',
            name = 'onlyLoadOnPlayer',
            tooltip = {
                text = 'Comma separated list of players to load the cooldown on.',
            },
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'hasLoadConditions')
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'onlyLoadOnPlayer')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'onlyLoadOnPlayer', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 40,
        },
        {
            type = 'spacer',
            width = 60,
        },
        {
            type = 'edit-box',
            label = 'Dont Load on Player/s',
            name = 'dontLoadOnPlayer',
            tooltip = {
                text = 'Comma separated list of players to not load the cooldown on.',
            },
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'hasLoadConditions')
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'dontLoadOnPlayer')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'dontLoadOnPlayer', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 40,
        },
    }
end
