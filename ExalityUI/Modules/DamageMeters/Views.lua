---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIDamageMetersViews
local views = EXUI:GetModule('damage-meters-views')

local function enumValue(enumTable, name, fallback)
    if enumTable and enumTable[name] ~= nil then
        return enumTable[name]
    end
    return fallback
end

local MeterType = Enum and Enum.DamageMeterType
local SessionType = Enum and Enum.DamageMeterSessionType
local SourceDisplayType = Enum and Enum.DamageMeterSourceDisplayType

views.Type = {
    DamageDone = enumValue(MeterType, 'DamageDone', 0),
    Dps = enumValue(MeterType, 'Dps', 1),
    HealingDone = enumValue(MeterType, 'HealingDone', 2),
    Hps = enumValue(MeterType, 'Hps', 3),
    Absorbs = enumValue(MeterType, 'Absorbs', 4),
    Interrupts = enumValue(MeterType, 'Interrupts', 5),
    Dispels = enumValue(MeterType, 'Dispels', 6),
    DamageTaken = enumValue(MeterType, 'DamageTaken', 7),
    AvoidableDamageTaken = enumValue(MeterType, 'AvoidableDamageTaken', 8),
    Deaths = enumValue(MeterType, 'Deaths', 9),
    EnemyDamageTaken = enumValue(MeterType, 'EnemyDamageTaken', 10),
}

views.Session = {
    Overall = enumValue(SessionType, 'Overall', 0),
    Current = enumValue(SessionType, 'Current', 1),
    Expired = enumValue(SessionType, 'Expired', 2),
}

views.SourceDisplay = {
    None = enumValue(SourceDisplayType, 'None', 0),
    Ally = enumValue(SourceDisplayType, 'Ally', 1),
    Enemy = enumValue(SourceDisplayType, 'Enemy', 2),
}

local FALLBACK_NAMES = {
    [views.Type.DamageDone] = 'Damage Done',
    [views.Type.Dps] = 'DPS',
    [views.Type.HealingDone] = 'Healing Done',
    [views.Type.Hps] = 'HPS',
    [views.Type.Absorbs] = 'Absorbs',
    [views.Type.Interrupts] = 'Interrupts',
    [views.Type.Dispels] = 'Dispels',
    [views.Type.DamageTaken] = 'Damage Taken',
    [views.Type.AvoidableDamageTaken] = 'Avoidable Damage Taken',
    [views.Type.Deaths] = 'Deaths',
    [views.Type.EnemyDamageTaken] = 'Enemy Damage Taken',
}

local GLOBAL_NAMES = {
    [views.Type.DamageDone] = 'DAMAGE_METER_TYPE_DAMAGE_DONE',
    [views.Type.Dps] = 'DAMAGE_METER_TYPE_DPS',
    [views.Type.HealingDone] = 'DAMAGE_METER_TYPE_HEALING_DONE',
    [views.Type.Hps] = 'DAMAGE_METER_TYPE_HPS',
    [views.Type.Absorbs] = 'DAMAGE_METER_TYPE_ABSORBS',
    [views.Type.Interrupts] = 'DAMAGE_METER_TYPE_INTERRUPTS',
    [views.Type.Dispels] = 'DAMAGE_METER_TYPE_DISPELS',
    [views.Type.DamageTaken] = 'DAMAGE_METER_TYPE_DAMAGE_TAKEN',
    [views.Type.AvoidableDamageTaken] = 'DAMAGE_METER_TYPE_AVOIDABLE_DAMAGE_TAKEN',
    [views.Type.Deaths] = 'DAMAGE_METER_TYPE_DEATHS',
    [views.Type.EnemyDamageTaken] = 'DAMAGE_METER_TYPE_ENEMY_DAMAGE_TAKEN',
}

local PRIMARY_PER_SECOND = {
    [views.Type.Dps] = true,
    [views.Type.Hps] = true,
}

local SUPPRESS_PER_SECOND = {
    [views.Type.Interrupts] = true,
    [views.Type.Dispels] = true,
}

function views:GetTypeName(meterType)
    local globalName = GLOBAL_NAMES[meterType]
    if globalName and _G[globalName] then
        return _G[globalName]
    end
    return FALLBACK_NAMES[meterType] or 'Unknown'
end

function views:GetCategories()
    return {
        {
            name = _G.DAMAGE_METER_CATEGORY_DAMAGE or 'Damage',
            types = {
                views.Type.DamageDone,
                views.Type.Dps,
                views.Type.DamageTaken,
                views.Type.AvoidableDamageTaken,
                views.Type.EnemyDamageTaken,
            },
        },
        {
            name = _G.DAMAGE_METER_CATEGORY_HEALING or 'Healing',
            types = {
                views.Type.HealingDone,
                views.Type.Hps,
                views.Type.Absorbs,
            },
        },
        {
            name = _G.DAMAGE_METER_CATEGORY_ACTIONS or 'Actions',
            types = {
                views.Type.Interrupts,
                views.Type.Dispels,
                views.Type.Deaths,
            },
        },
    }
end

function views:ShowsValuePerSecondAsPrimary(meterType)
    return PRIMARY_PER_SECOND[meterType] == true
end

function views:SuppressValuePerSecond(meterType)
    return SUPPRESS_PER_SECOND[meterType] == true
end

function views:UsesWholeNumbers(meterType)
    return meterType == views.Type.Interrupts or meterType == views.Type.Dispels
end

function views:IsDeaths(meterType)
    return meterType == views.Type.Deaths
end

function views:GetSessionName(sessionType, sessionID)
    if sessionType == views.Session.Current then
        return _G.DAMAGE_METER_CURRENT_SESSION or 'Current'
    end
    if sessionType == views.Session.Overall then
        return _G.DAMAGE_METER_OVERALL_SESSION or 'Overall'
    end
    if sessionID then
        local format = _G.DAMAGE_METER_COMBAT_NUMBER
        if format then
            return format:format(sessionID)
        end
        return 'Combat ' .. tostring(sessionID)
    end
    return 'Current'
end

function views:GetSessionShortName(sessionType, sessionID)
    if sessionType == views.Session.Current then
        return _G.DAMAGE_METER_CURRENT_SESSION_SHORT or 'C'
    end
    if sessionType == views.Session.Overall then
        return _G.DAMAGE_METER_OVERALL_SESSION_SHORT or 'O'
    end
    return sessionID and tostring(sessionID) or '?'
end
