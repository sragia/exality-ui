---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIAuraDisplaysModule
local auraDisplays = EXUI:GetModule('aura-displays')

---@class EXUIAuraDisplaysGroupNav
local groupNav = EXUI:GetModule('aura-displays-group-nav')

local ICONS = nil
local function getIcons()
    if not ICONS then
        local icons = EXUI.const.textures.frame.icons
        ICONS = {
            plus = icons.plus,
            duplicate = icons.duplicate,
            delete = icons.delete,
        }
    end
    return ICONS
end

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

    local icons = getIcons()
    local theme = EXUI.const.theme

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
            name = 'addGroup',
            width = 5,
            square = true,
            align = 'BOTTOM',
            tooltip = { text = 'Add Group' },
            icon = { file = icons.plus, width = 16, height = 16 },
            onClick = function()
                local groupID = auraDisplays:AddGroup(displayID)
                auraDisplays.currGroupID = groupID
                auraDisplays:RefreshDisplay(displayID)
                optionsFields:RefreshOptions()
            end,
        },
        {
            type = 'button',
            name = 'removeGroup',
            width = 5,
            square = true,
            align = 'BOTTOM',
            tooltip = { text = 'Remove Group' },
            icon = { file = icons.delete, width = 16, height = 16 },
            color = theme.danger,
            hoverColor = theme.dangerHover,
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
            name = 'duplicateGroup',
            width = 5,
            square = true,
            align = 'BOTTOM',
            tooltip = { text = 'Duplicate Group' },
            icon = { file = icons.duplicate, width = 16, height = 16 },
            color = { 2 / 255, 145 / 255, 227 / 255, 1 },
            hoverColor = { 32 / 255, 165 / 255, 240 / 255, 1 },
            onClick = function()
                local newGroupID = auraDisplays:DuplicateGroup(displayID, auraDisplays.currGroupID)
                auraDisplays.currGroupID = newGroupID
                auraDisplays:RefreshDisplay(displayID)
                optionsFields:RefreshOptions()
            end,
        },
        { type = 'spacer', width = 45 },
        { type = 'spacer', width = 100 },
    }
end
