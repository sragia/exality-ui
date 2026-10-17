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
    { key = 'Open World', label = 'Open World' },
    { key = 'Dungeon', label = 'Dungeon' },
    { key = 'Raid', label = 'Raid' },
    { key = 'Battleground', label = 'Battleground' },
    { key = 'Arena', label = 'Arena' },
    { key = 'Mythic+', label = 'Mythic+' },
    { key = 'Scenario', label = 'Scenario' },
}

local ROLE_OPTIONS = {
    { key = 'Tank', label = 'Tank' },
    { key = 'Healer', label = 'Healer' },
    { key = 'DPS', label = 'DPS' },
}

local append = EXUI.utils.append

local function classAccent(classFile)
    if not classFile then
        return nil
    end
    local color = C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(classFile)
    if not color and RAID_CLASS_COLORS then
        color = RAID_CLASS_COLORS[classFile]
    end
    if not color then
        return nil
    end
    return { color.r, color.g, color.b, 1 }
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

function loadOptions:HasAnyListValue(displayID, groupID, key)
    local list = auraDisplays:GetGroupLoad(displayID, groupID, key)
    return type(list) == 'table' and #list > 0
end

function loadOptions:GetClassFields(displayID, groupID)
    local fields = { {
        type = 'title',
        label = 'Class',
        width = 100,
        expanded = self:HasAnyListValue(displayID, groupID, 'loadClasses'),
    } }
    for _, className in ipairs(CLASS_OPTIONS) do
        local selectedClass = className
        table.insert(fields, {
            type = 'checkbox',
            label = selectedClass,
            name = 'class_' .. selectedClass,
            width = 33,
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return self:HasListValue(displayID, groupID, 'loadClasses', selectedClass) end,
            onChange = function(value)
                self:SetListValue(displayID, groupID, 'loadClasses', selectedClass, value)
                auraDisplays:RefreshDisplay(displayID)
            end,
        })
    end
    return fields
end

function loadOptions:GetInstanceFields(displayID, groupID)
    local fields = { {
        type = 'title',
        label = 'Instance',
        width = 100,
        expanded = self:HasAnyListValue(displayID, groupID, 'loadInstances'),
    } }
    for _, entry in ipairs(INSTANCE_OPTIONS) do
        local key, label = entry.key, entry.label
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
    local fields = { {
        type = 'title',
        label = 'Role',
        width = 100,
        expanded = self:HasAnyListValue(displayID, groupID, 'loadRoles'),
    } }
    for _, entry in ipairs(ROLE_OPTIONS) do
        local key, label = entry.key, entry.label
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

function loadOptions:GetSpecFields(displayID, groupID)
    local fields = { {
        type = 'title',
        label = 'Spec',
        width = 100,
        expanded = self:HasAnyListValue(displayID, groupID, 'loadSpecs'),
    } }
    local sex = UnitSex('player')
    for classIndex = 1, GetNumClasses() do
        local className, classFile, classID = GetClassInfo(classIndex)
        if className and classID then
            local classExpanded = false
            local numSpecs = C_SpecializationInfo.GetNumSpecializationsForClassID(classID)
            for specIndex = 1, numSpecs do
                local _, specName = GetSpecializationInfoForClassID(classID, specIndex, sex)
                if specName and self:HasListValue(displayID, groupID, 'loadSpecs', specName) then
                    classExpanded = true
                    break
                end
            end
            table.insert(fields, {
                type = 'title',
                label = className,
                size = 12,
                width = 100,
                accent = classAccent(classFile),
                expanded = classExpanded,
                depends = function()
                    return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions')
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
                            return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions')
                        end,
                        currentValue = function()
                            return self:HasListValue(displayID, groupID, 'loadSpecs', specName)
                        end,
                        onChange = function(value)
                            self:SetListValue(displayID, groupID, 'loadSpecs', specName, value)
                            auraDisplays:RefreshDisplay(displayID)
                        end,
                    })
                end
            end
        end
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
            tooltip = { text = 'Comma separated list of players to load the group on.' },
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'onlyLoadOnPlayer') end,
            onChange = function(v) auraDisplays:UpdateGroupLoad(displayID, groupID, 'onlyLoadOnPlayer', v); auraDisplays:RefreshDisplay(displayID) end,
        },
        {
            type = 'edit-box', label = 'Dont Load On Player', name = 'dontLoadOnPlayer', width = 50,
            tooltip = { text = 'Comma separated list of players to not load the group on.' },
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'dontLoadOnPlayer') end,
            onChange = function(v) auraDisplays:UpdateGroupLoad(displayID, groupID, 'dontLoadOnPlayer', v); auraDisplays:RefreshDisplay(displayID) end,
        },
        {
            type = 'toggle', label = 'In Combat Only', name = 'loadInCombat', width = 50,
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'loadInCombat') == true end,
            onChange = function(v)
                auraDisplays:UpdateGroupLoad(displayID, groupID, 'loadInCombat', v and true or nil)
                if v then auraDisplays:UpdateGroupLoad(displayID, groupID, 'loadOutOfCombat', nil) end
                auraDisplays:RefreshDisplay(displayID)
                refreshEditorOptions()
                refreshEditorList()
            end,
        },
        {
            type = 'toggle', label = 'Out Of Combat Only', name = 'loadOutOfCombat', width = 50,
            depends = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions') end,
            currentValue = function() return auraDisplays:GetGroupLoad(displayID, groupID, 'loadOutOfCombat') == true end,
            onChange = function(v)
                auraDisplays:UpdateGroupLoad(displayID, groupID, 'loadOutOfCombat', v and true or nil)
                if v then auraDisplays:UpdateGroupLoad(displayID, groupID, 'loadInCombat', nil) end
                auraDisplays:RefreshDisplay(displayID)
                refreshEditorOptions()
                refreshEditorList()
            end,
        },
    })

    append(fields, self:GetClassFields(displayID, groupID))
    append(fields, self:GetSpecFields(displayID, groupID))
    append(fields, self:GetInstanceFields(displayID, groupID))
    append(fields, self:GetRoleFields(displayID, groupID))
    append(fields, EXUI:GetModule('aura-displays-encounter-journal'):GetOptionFields({
        owner = 'uf-' .. tostring(displayID) .. '-' .. tostring(groupID),
        depends = function()
            return auraDisplays:GetGroupLoad(displayID, groupID, 'hasLoadConditions')
        end,
        getList = function()
            return auraDisplays:GetGroupLoad(displayID, groupID, 'loadEncounters')
        end,
        setList = function(list)
            auraDisplays:UpdateGroupLoad(displayID, groupID, 'loadEncounters', list)
        end,
        refreshDisplay = function()
            auraDisplays:RefreshDisplay(displayID)
        end,
        onChanged = function()
            auraDisplays:RefreshDisplay(displayID)
            refreshEditorOptions()
            refreshEditorList()
        end,
    }))

    return fields
end
