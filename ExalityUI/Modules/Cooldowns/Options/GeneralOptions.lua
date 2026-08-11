---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICooldownsModule
local cooldowns = EXUI:GetModule('cooldowns')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUICooldownsGeneralOptions
local generalOptions = EXUI:GetModule('cooldowns-general-options')

function generalOptions:GetOptions(cdID)
    return {
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'enable', value)
                cooldowns:UpdateById(cdID)
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'enable')
            end,
            width = 100,
        },
        {
            type = 'edit-box',
            label = 'Name',
            name = 'name',
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'name')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'name', value)
                cooldowns:UpdateById(cdID)
                optionsFields:RefreshItemList()
            end,
            width = 50,
        },
        {
            type = 'spacer',
            width = 50,
        },
        {
            type = 'toggle',
            label = 'Show Stacks',
            name = 'showStacks',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'cooldownSource') ~= 'equipment'
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'showStacks', value)
                cooldowns:UpdateById(cdID)
                optionsFields:RefreshOptions()
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'showStacks')
            end,
            width = 100,
        },
    }
end
