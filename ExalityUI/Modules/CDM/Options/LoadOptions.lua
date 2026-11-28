---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICDMData
local data = EXUI:GetModule('cdm-data')

---@class EXUICDMOptionsBuilder
local B = EXUI:GetModule('cdm-options-builder')

---@class EXUICDMLoadOptions
local loadOptions = EXUI:GetModule('cdm-load-options')

local append = EXUI.utils.append

local CLASS_OPTIONS = {
    'Warrior', 'Paladin', 'Hunter', 'Rogue', 'Priest', 'Death Knight',
    'Shaman', 'Mage', 'Warlock', 'Monk', 'Druid', 'Demon Hunter', 'Evoker',
}

local INSTANCE_OPTIONS = { 'Open World', 'Dungeon', 'Raid', 'Battleground', 'Arena', 'Mythic+', 'Scenario' }

local ROLE_OPTIONS = { 'Tank', 'Healer', 'DPS' }

local function checkbox(id, key, value, label, name)
    return {
        type = 'checkbox',
        label = label,
        name = name,
        width = 33,
        depends = function() return data:GetValue(id, 'load.hasLoadConditions') end,
        currentValue = function()
            return tContains(data:GetValue(id, 'load.' .. key) or {}, value)
        end,
        onChange = function(checked)
            local current = data:GetValue(id, 'load.' .. key) or {}
            tDeleteItem(current, value)
            if checked then
                table.insert(current, value)
            end
            data:SetValue(id, 'load.' .. key, current)
            EXUI:GetModule('cdm'):Refresh()
        end,
    }
end

local function hasAny(id, key)
    local list = data:GetValue(id, 'load.' .. key)
    return list ~= nil and #list > 0
end

local function listFields(id, key, title, values)
    local fields = {
        B:Title(title, {
            expanded = hasAny(id, key),
            depends = function() return data:GetValue(id, 'load.hasLoadConditions') end,
        }),
    }
    for _, value in ipairs(values) do
        fields[#fields + 1] = checkbox(id, key, value, value, key .. '_' .. value)
    end
    return fields
end

local function classAccent(classFile)
    local color = C_ClassColor.GetClassColor(classFile)
    return color and { color.r, color.g, color.b, 1 }
end

local function specFields(id)
    local function enabled()
        return data:GetValue(id, 'load.hasLoadConditions')
    end
    local selected = data:GetValue(id, 'load.loadSpecs') or {}
    local fields = { B:Title('Spec', { expanded = #selected > 0, depends = enabled }) }
    local sex = UnitSex('player')
    for classIndex = 1, GetNumClasses() do
        local className, classFile, classID = GetClassInfo(classIndex)
        if className and classID then
            local specs = {}
            for specIndex = 1, C_SpecializationInfo.GetNumSpecializationsForClassID(classID) do
                local _, specName = GetSpecializationInfoForClassID(classID, specIndex, sex)
                if specName then
                    specs[#specs + 1] = { index = specIndex, name = specName }
                end
            end
            local expanded = false
            for _, spec in ipairs(specs) do
                expanded = expanded or tContains(selected, spec.name)
            end
            fields[#fields + 1] = B:Title(className, {
                size = 12,
                accent = classAccent(classFile),
                expanded = expanded,
                depends = enabled,
            })
            for _, spec in ipairs(specs) do
                fields[#fields + 1] = checkbox(id, 'loadSpecs', spec.name, spec.name,
                    'spec_' .. classID .. '_' .. spec.index)
            end
        end
    end
    return fields
end

function loadOptions:GetOptions(id)
    local function enabled()
        return data:GetValue(id, 'load.hasLoadConditions')
    end
    local fields = {
        B:Toggle(id, { path = 'load.hasLoadConditions', label = 'Enable Load Conditions', width = 100, refresh = true }),
        B:Edit(id, {
            path = 'load.onlyLoadOnPlayer',
            label = 'Only Load On Player',
            width = 50,
            depends = enabled,
            tooltip = { text = 'Comma separated list of player names.' },
        }),
        B:Edit(id, {
            path = 'load.dontLoadOnPlayer',
            label = 'Dont Load On Player',
            width = 50,
            depends = enabled,
            tooltip = { text = 'Comma separated list of player names.' },
        }),
    }
    append(fields, listFields(id, 'loadClasses', 'Class', CLASS_OPTIONS))
    append(fields, specFields(id))
    append(fields, listFields(id, 'loadInstances', 'Instance', INSTANCE_OPTIONS))
    append(fields, listFields(id, 'loadRoles', 'Role', ROLE_OPTIONS))
    return fields
end
