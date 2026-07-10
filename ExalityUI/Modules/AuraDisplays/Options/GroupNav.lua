---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIAuraDisplaysModule
local auraDisplays = EXUI:GetModule('aura-displays')

---@class EXUIAuraDisplaysGroupNav
local groupNav = EXUI:GetModule('aura-displays-group-nav')

function groupNav:GetGroupLabel(display, index)
    return 'Group ' .. tostring(index)
end

function groupNav:GetGroupOptions(displayID)
    local display = auraDisplays:GetDisplay(displayID)
    local options = {}
    for index, groupID in ipairs(display.groupOrder or {}) do
        options[groupID] = self:GetGroupLabel(display, index)
    end
    return options
end

function groupNav:EnsureGroupSelected(displayID)
    local display = auraDisplays:GetDisplay(displayID)
    if not display or not display.groupOrder or #display.groupOrder == 0 then
        auraDisplays.currGroupID = nil
        return
    end
    if not auraDisplays.currGroupID or not display.groups[auraDisplays.currGroupID] then
        auraDisplays.currGroupID = display.groupOrder[1]
    end
end

function groupNav:GetFields(displayID)
    self:EnsureGroupSelected(displayID)
    local display = auraDisplays:GetDisplay(displayID)
    if not display then
        return {}
    end

    return {
        { type = 'title', label = 'Groups', width = 100 },
        {
            type = 'dropdown',
            label = 'Active Group',
            name = 'activeGroup',
            width = 40,
            getOptions = function()
                return self:GetGroupOptions(displayID)
            end,
            currentValue = function()
                return auraDisplays.currGroupID
            end,
            onChange = function(value)
                auraDisplays.currGroupID = value
                auraDisplays:RefreshDisplay(displayID)
                optionsFields:RefreshOptions()
            end,
        },
        {
            type = 'button',
            label = 'Add Group',
            name = 'addGroup',
            width = 20,
            onClick = function()
                local groupID = auraDisplays:AddGroup(displayID)
                auraDisplays.currGroupID = groupID
                auraDisplays:RefreshDisplay(displayID)
                optionsFields:RefreshOptions()
            end,
        },
        {
            type = 'button',
            label = 'Remove',
            name = 'removeGroup',
            width = 20,
            onClick = function()
                if #display.groupOrder <= 1 then
                    return
                end
                auraDisplays:RemoveGroup(displayID, auraDisplays.currGroupID)
                self:EnsureGroupSelected(displayID)
                auraDisplays:RefreshDisplay(displayID)
                optionsFields:RefreshOptions()
            end,
        },
        {
            type = 'button',
            label = 'Duplicate',
            name = 'duplicateGroup',
            width = 20,
            onClick = function()
                local newGroupID = auraDisplays:DuplicateGroup(displayID, auraDisplays.currGroupID)
                auraDisplays.currGroupID = newGroupID
                auraDisplays:RefreshDisplay(displayID)
                optionsFields:RefreshOptions()
            end,
        },
        { type = 'spacer', width = 100 },
    }
end
