---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

local function refreshEditorOptions()
    local editor = EXUI:GetModule('uf-aura-editor')
    if editor and editor.RefreshOptions then
        editor:RefreshOptions()
    end
end

local function refreshEditorList()
    local editor = EXUI:GetModule('uf-aura-editor')
    if editor and editor.RefreshItemList then
        editor:RefreshItemList()
    end
end

---@class EXUIUnitFramesAuras
local auraDisplays = EXUI:GetModule('uf-auras')

---@class EXUIUFAuraEditorGroupNav
local groupNav = EXUI:GetModule('uf-aura-editor-group-nav')

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
                refreshEditorOptions()
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
                refreshEditorOptions()
            end,
        },
        {
            type = 'button',
            label = 'Remove',
            name = 'removeGroup',
            width = 20,
            color = EXUI.EXFrames.Theme.danger,
            hoverColor = EXUI.EXFrames.Theme.dangerHover,
            onClick = function()
                if #display.groupOrder <= 1 then
                    return
                end
                auraDisplays:RemoveGroup(displayID, auraDisplays.currGroupID)
                self:EnsureGroupSelected(displayID)
                auraDisplays:RefreshDisplay(displayID)
                refreshEditorOptions()
            end,
        },
        {
            type = 'button',
            label = 'Duplicate',
            name = 'duplicateGroup',
            width = 20,
            color = { 2 / 255, 145 / 255, 227 / 255, 1 },
            hoverColor = { 32 / 255, 165 / 255, 240 / 255, 1 },
            onClick = function()
                local newGroupID = auraDisplays:DuplicateGroup(displayID, auraDisplays.currGroupID)
                auraDisplays.currGroupID = newGroupID
                auraDisplays:RefreshDisplay(displayID)
                refreshEditorOptions()
            end,
        },
        { type = 'spacer', width = 100 },
    }
end
