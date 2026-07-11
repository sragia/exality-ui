---@class ExalityUI

local EXUI = select(2, ...)



---@class EXUIOptionsFields

local optionsFields = EXUI:GetModule('options-fields')



---@class EXUIResourceDisplaysCore

local core = EXUI:GetModule('resource-displays-core')



---@class EXUIResourceDisplaysDefaults

local defaults = EXUI:GetModule('resource-displays-defaults')



---@class EXUIResourceDisplaysGeneralOptions

local generalOptions = EXUI:GetModule('resource-displays-general-options')



function generalOptions:GetOptions(displayID)

    local resourceType = core:GetValueForDisplay(displayID, 'resourceType')

    local isGeneric = core:IsGenericResourceType(resourceType)



    local fields = {

        {

            type = 'toggle',

            label = 'Enable',

            name = 'enable',

            onChange = function(value)

                core:UpdateValueForDisplay(displayID, 'enable', value)

                core:RefreshDisplayByID(displayID)

            end,

            currentValue = function()

                return core:GetValueForDisplay(displayID, 'enable')

            end,

            width = 100,

        },

        {

            type = 'edit-box',

            label = 'Name',

            name = 'name',

            currentValue = function()

                return core:GetValueForDisplay(displayID, 'name')

            end,

            onChange = function(value)

                core:UpdateValueForDisplay(displayID, 'name', value)

                core:RefreshDisplayByID(displayID)

                optionsFields:RefreshItemList()

            end,

            width = 50,

        },

        {

            type = 'spacer',

            width = 50,

        },

        {

            type = 'dropdown',

            label = 'Resource Type',

            name = 'resourceType',

            getOptions = function()

                return core:GetPowerTypes()

            end,

            currentValue = function()

                return core:GetValueForDisplay(displayID, 'resourceType')

            end,

            onChange = function(value)

                local oldType = core:GetValueForDisplay(displayID, 'resourceType')

                if oldType ~= value then

                    defaults:ClearTypeSpecificKeys(core:GetDBByDisplayID(displayID))

                end

                core:UpdateValueForDisplay(displayID, 'resourceType', value)

                core:RecreateFrame(displayID)

                optionsFields:RefreshFields()

            end,

            width = 50,

        },

    }



    if isGeneric then

        table.insert(fields, {

            type = 'toggle',

            label = 'Show Always when Available',

            name = 'showOverride',

            onChange = function(value)

                core:UpdateValueForDisplay(displayID, 'showOverride', value)

                core:RefreshDisplayByID(displayID)

            end,

            currentValue = function()

                return core:GetValueForDisplay(displayID, 'showOverride')

            end,

            width = 100,

        })

    end



    return fields

end


