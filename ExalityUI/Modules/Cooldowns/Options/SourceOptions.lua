---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUICooldownsModule
local cooldowns = EXUI:GetModule('cooldowns')

---@class EXUICooldownsSourceOptions
local sourceOptions = EXUI:GetModule('cooldowns-source-options')

local function setCooldownSource(cdID, source)
    cooldowns:UpdateValueForCD(cdID, 'cooldownSource', source)
    cooldowns:UpdateValueForCD(cdID, 'isItem', source == 'item')
    if source == 'equipment' then
        cooldowns:UpdateValueForCD(cdID, 'showStacks', false)
    end
end

function sourceOptions:GetOptions(cdID)
    return {
        {
            type = 'dropdown',
            label = 'Cooldown Source',
            name = 'cooldownSource',
            getOptions = function()
                return {
                    spell = 'Spell',
                    item = 'Item',
                    equipment = 'Equipment Slot',
                }
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'cooldownSource')
            end,
            onChange = function(value)
                setCooldownSource(cdID, value)
                cooldowns:UpdateById(cdID)
                optionsFields:RefreshOptions()
            end,
            width = 50,
        },
        {
            type = 'spacer',
            width = 50,
        },
        {
            type = 'cooldowns-spell-id-input',
            label = 'Spell',
            name = 'spellID',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'cooldownSource') == 'spell'
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'spellID')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'spellID', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 50,
        },
        {
            type = 'cooldowns-item-id-input',
            label = 'Item',
            name = 'itemID',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'cooldownSource') == 'item'
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'itemID')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'itemID', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 50,
        },
        {
            type = 'dropdown',
            label = 'Equipment Slot',
            name = 'equipmentSlot',
            depends = function()
                return cooldowns:GetValueForCD(cdID, 'cooldownSource') == 'equipment'
            end,
            getOptions = function()
                return cooldowns:GetEquipmentSlotOptions()
            end,
            currentValue = function()
                return cooldowns:GetValueForCD(cdID, 'equipmentSlot')
            end,
            onChange = function(value)
                cooldowns:UpdateValueForCD(cdID, 'equipmentSlot', value)
                cooldowns:UpdateById(cdID)
            end,
            width = 50,
        },
    }
end
