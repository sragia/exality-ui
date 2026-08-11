---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysLoadOptions
local loadOptions = EXUI:GetModule('resource-displays-load-options')

local CLASS_OPTIONS = {
    'Warrior', 'Paladin', 'Hunter', 'Rogue', 'Priest', 'Death Knight',
    'Shaman', 'Mage', 'Warlock', 'Monk', 'Druid', 'Demon Hunter', 'Evoker',
}

local append = EXUI.utils.append

function loadOptions:SetListValue(displayID, key, value, enabled)
    local list = core:GetValueForDisplay(displayID, key) or {}
    if enabled then
        if not tContains(list, value) then
            table.insert(list, value)
        end
    else
        tDeleteItem(list, value)
    end
    core:UpdateValueForDisplay(displayID, key, list)
end

function loadOptions:HasListValue(displayID, key, value)
    local list = core:GetValueForDisplay(displayID, key) or {}
    return tContains(list, value)
end

function loadOptions:GetClassFields(displayID)
    local fields = { { type = 'title', label = 'Class', width = 100 } }
    for _, className in ipairs(CLASS_OPTIONS) do
        table.insert(fields, {
            type = 'checkbox',
            label = className,
            name = 'class_' .. className,
            width = 33,
            depends = function()
                return core:GetValueForDisplay(displayID, 'hasLoadConditions')
            end,
            currentValue = function()
                return self:HasListValue(displayID, 'loadClasses', className)
            end,
            onChange = function(value)
                self:SetListValue(displayID, 'loadClasses', className, value)
                core:RefreshDisplayByID(displayID)
            end,
        })
    end
    return fields
end

function loadOptions:GetSpecFields(displayID)
    local fields = { { type = 'title', label = 'Spec', width = 100 } }
    local sex = UnitSex('player')
    for classIndex = 1, GetNumClasses() do
        local className, _, classID = GetClassInfo(classIndex)
        if className and classID then
            table.insert(fields, {
                type = 'title',
                label = className,
                size = 12,
                width = 100,
                depends = function()
                    return core:GetValueForDisplay(displayID, 'hasLoadConditions')
                end,
            })
            for specIndex = 1, C_SpecializationInfo.GetNumSpecializationsForClassID(classID) do
                local _, specName = GetSpecializationInfoForClassID(classID, specIndex, sex)
                if specName then
                    table.insert(fields, {
                        type = 'checkbox',
                        label = specName,
                        name = 'spec_' .. classID .. '_' .. specIndex,
                        width = 33,
                        depends = function()
                            return core:GetValueForDisplay(displayID, 'hasLoadConditions')
                        end,
                        currentValue = function()
                            return self:HasListValue(displayID, 'loadSpecs', specName)
                        end,
                        onChange = function(value)
                            self:SetListValue(displayID, 'loadSpecs', specName, value)
                            core:RefreshDisplayByID(displayID)
                        end,
                    })
                end
            end
        end
    end
    return fields
end

function loadOptions:GetOptions(displayID)
    local fields = {
        {
            type = 'toggle',
            label = 'Enable Load Conditions',
            name = 'hasLoadConditions',
            width = 100,
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'hasLoadConditions')
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'hasLoadConditions', value)
                core:RefreshDisplayByID(displayID)
                optionsFields:RefreshOptionsDelayed()
            end,
        },
        {
            type = 'edit-box',
            label = 'Only Load On Player',
            name = 'onlyLoadOnPlayer',
            width = 50,
            tooltip = {
                text = 'Comma separated list of players to load the display on.',
            },
            depends = function()
                return core:GetValueForDisplay(displayID, 'hasLoadConditions')
            end,
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'onlyLoadOnPlayer')
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'onlyLoadOnPlayer', value)
                core:RefreshDisplayByID(displayID)
            end,
        },
        {
            type = 'edit-box',
            label = 'Dont Load On Player',
            name = 'dontLoadOnPlayer',
            width = 50,
            tooltip = {
                text = 'Comma separated list of players to not load the display on.',
            },
            depends = function()
                return core:GetValueForDisplay(displayID, 'hasLoadConditions')
            end,
            currentValue = function()
                return core:GetValueForDisplay(displayID, 'dontLoadOnPlayer')
            end,
            onChange = function(value)
                core:UpdateValueForDisplay(displayID, 'dontLoadOnPlayer', value)
                core:RefreshDisplayByID(displayID)
            end,
        },
    }

    append(fields, self:GetClassFields(displayID))
    append(fields, self:GetSpecFields(displayID))

    return fields
end
