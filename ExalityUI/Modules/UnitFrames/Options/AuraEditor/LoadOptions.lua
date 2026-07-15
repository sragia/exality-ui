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

---@class EXUIUFAuraEditorLoadOptions
local loadOptions = EXUI:GetModule('uf-aura-editor-load-options')

local CLASS_OPTIONS = {
    'Warrior', 'Paladin', 'Hunter', 'Rogue', 'Priest', 'Death Knight',
    'Shaman', 'Mage', 'Warlock', 'Monk', 'Druid', 'Demon Hunter', 'Evoker',
}

local INSTANCE_OPTIONS = {
    ['Open World'] = 'Open World',
    Dungeon = 'Dungeon',
    Raid = 'Raid',
    Battleground = 'Battleground',
    Arena = 'Arena',
    ['Mythic+'] = 'Mythic+',
    Scenario = 'Scenario',
}

local ROLE_OPTIONS = { Tank = 'Tank', Healer = 'Healer', DPS = 'DPS' }

local function append(target, source)
    for _, field in ipairs(source) do
        table.insert(target, field)
    end
end

function loadOptions:SetListValue(displayID, groupID, key, value, enabled)
    local list = auraDisplays:GetGroupLoad(displayID, groupID, key) or {}
    if enabled then
        if not tContains(list, value) then
            table.insert(list, value)
        end
    else
        tDeleteItem(list, value)
    end
    auraDisplays:UpdateGroupLoad(displayID, groupID, key, list)
end

function loadOptions:HasListValue(displayID, groupID, key, value)
    local list = auraDisplays:GetGroupLoad(displayID, groupID, key) or {}
    return tContains(list, value)
end

function loadOptions:GetClassFields(displayID, groupID)
    local fields = { { type = 'title', label = 'Class', width = 100 } }
    for _, className in ipairs(CLASS_OPTIONS) do
        table.insert(fields, {
            type = 'checkbox',
            label = className,
            name = 'class_' .. className,
            width = 33,
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return self:HasListValue(displayID, groupID, 'loadClasses', className) end,
            onChange = function(value)
                self:SetListValue(displayID, groupID, 'loadClasses', className, value)
                auraDisplays:RefreshDisplay(displayID)
            end,
        })
    end
    return fields
end

function loadOptions:GetInstanceFields(displayID, groupID)
    local fields = { { type = 'title', label = 'Instance', width = 100 } }
    for key, label in pairs(INSTANCE_OPTIONS) do
        table.insert(fields, {
            type = 'checkbox',
            label = label,
            name = 'instance_' .. key,
            width = 33,
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return self:HasListValue(displayID, groupID, 'loadInstances', key) end,
            onChange = function(value)
                self:SetListValue(displayID, groupID, 'loadInstances', key, value)
                auraDisplays:RefreshDisplay(displayID)
            end,
        })
    end
    return fields
end

function loadOptions:GetRoleFields(displayID, groupID)
    local fields = { { type = 'title', label = 'Role', width = 100 } }
    for key, label in pairs(ROLE_OPTIONS) do
        table.insert(fields, {
            type = 'checkbox',
            label = label,
            name = 'role_' .. key,
            width = 33,
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return self:HasListValue(displayID, groupID, 'loadRoles', key) end,
            onChange = function(value)
                self:SetListValue(displayID, groupID, 'loadRoles', key, value)
                auraDisplays:RefreshDisplay(displayID)
            end,
        })
    end
    return fields
end

function loadOptions:GetOptions(displayID, groupID)
    groupNav:EnsureGroupSelected(displayID)
    groupID = groupID or auraDisplays.currGroupID
    if not groupID then return {} end

    local fields = {}
    append(fields, groupNav:GetFields(displayID))
    append(fields, {
        {
            type = 'toggle', label = 'Enable Load Conditions', name = 'hasLoadConditions', width = 100,
            currentValue = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            onChange = function(v)
                auraDisplays:UpdateGroupLoad(displayID, groupID, 'hasLoadConditions', v)
                auraDisplays:RefreshDisplay(displayID)
                refreshEditorOptions()
                refreshEditorList()
            end,
        },
        {
            type = 'edit-box', label = 'Only Load On Player', name = 'onlyLoadOnPlayer', width = 50,
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'onlyLoadOnPlayer') end,
            onChange = function(v) auraDisplays:UpdateGroupLoad(displayID, groupID, 'onlyLoadOnPlayer', v); auraDisplays:RefreshDisplay(displayID) end,
        },
        {
            type = 'edit-box', label = 'Dont Load On Player', name = 'dontLoadOnPlayer', width = 50,
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'dontLoadOnPlayer') end,
            onChange = function(v) auraDisplays:UpdateGroupLoad(displayID, groupID, 'dontLoadOnPlayer', v); auraDisplays:RefreshDisplay(displayID) end,
        },
        {
            type = 'toggle', label = 'In Combat Only', name = 'loadInCombat', width = 100,
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'loadInCombat') == true end,
            onChange = function(v)
                auraDisplays:UpdateGroupLoad(displayID, groupID, 'loadInCombat', v and true or nil)
                if v then auraDisplays:UpdateGroupLoad(displayID, groupID, 'loadOutOfCombat', nil) end
                auraDisplays:RefreshDisplay(displayID)
                refreshEditorList()
            end,
        },
        {
            type = 'toggle', label = 'Out Of Combat Only', name = 'loadOutOfCombat', width = 100,
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'loadOutOfCombat') == true end,
            onChange = function(v)
                auraDisplays:UpdateGroupLoad(displayID, groupID, 'loadOutOfCombat', v and true or nil)
                if v then auraDisplays:UpdateGroupLoad(displayID, groupID, 'loadInCombat', nil) end
                auraDisplays:RefreshDisplay(displayID)
                refreshEditorList()
            end,
        },
    })

    append(fields, self:GetClassFields(displayID, groupID))
    append(fields, self:GetInstanceFields(displayID, groupID))
    append(fields, self:GetRoleFields(displayID, groupID))

    return fields
end
