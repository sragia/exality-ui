---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesCVars
local cvars = EXUI:GetModule('np-cvars')

local function stackIndex(which)
    local e = Enum and Enum.NamePlateStackType
    if which == 'enemy' then
        return e and e.Enemy or 1
    end
    return e and e.Friendly or 2
end

cvars.SPEC = {
    stackEnemies = { cvar = 'nameplateStackingTypes', kind = 'bit', index = function()
        return stackIndex('enemy')
    end },
    stackFriendlies = { cvar = 'nameplateStackingTypes', kind = 'bit', index = function()
        return stackIndex('friendly')
    end },
    overlapH = { cvar = 'nameplateOverlapH', kind = 'number' },
    overlapV = { cvar = 'nameplateOverlapV', kind = 'number' },
    showAll = { cvar = 'nameplateShowAll', kind = 'bool' },
    showEnemies = { cvar = 'nameplateShowEnemies', kind = 'bool' },
    showEnemyMinions = { cvar = 'nameplateShowEnemyMinions', kind = 'bool' },
    showEnemyMinus = { cvar = 'nameplateShowEnemyMinus', kind = 'bool' },
    showEnemyPets = { cvar = 'nameplateShowEnemyPets', kind = 'bool' },
    showEnemyGuardians = { cvar = 'nameplateShowEnemyGuardians', kind = 'bool' },
    showEnemyTotems = { cvar = 'nameplateShowEnemyTotems', kind = 'bool' },
    showFriendlyPlayers = { cvar = 'nameplateShowFriendlyPlayers', kind = 'bool' },
    showFriendlyPlayerMinions = { cvar = 'nameplateShowFriendlyPlayerMinions', kind = 'bool' },
    showFriendlyNpcs = { cvar = 'nameplateShowFriendlyNpcs', kind = 'bool' },
    showOffscreen = { cvar = 'nameplateShowOffscreen', kind = 'bool' },
    targetRadialPosition = { cvar = 'nameplateTargetRadialPosition', kind = 'number' },
    targetBehindMaxDistance = { cvar = 'nameplateTargetBehindMaxDistance', kind = 'number' },
    maxDistance = { cvar = 'nameplateMaxDistance', kind = 'number' },
    playerMaxDistance = { cvar = 'nameplatePlayerMaxDistance', kind = 'number' },
    selectedScale = { cvar = 'nameplateSelectedScale', kind = 'number' },
    minScale = { cvar = 'nameplateMinScale', kind = 'number' },
    maxScale = { cvar = 'nameplateMaxScale', kind = 'number' },
    occludedAlphaMult = { cvar = 'nameplateOccludedAlphaMult', kind = 'number' },
}

local function cvarExists(name)
    return C_CVar and C_CVar.GetCVar(name) ~= nil
end

local function readBool(name)
    if C_CVar and C_CVar.GetCVarBool then
        return C_CVar.GetCVarBool(name) and true or false
    end
    return GetCVarBool(name) and true or false
end

local function readNumber(name)
    local raw
    if C_CVar and C_CVar.GetCVar then
        raw = C_CVar.GetCVar(name)
    else
        raw = GetCVar(name)
    end
    return tonumber(raw)
end

local function readBit(name, index)
    local getter = C_CVar and C_CVar.GetCVarBitfield or GetCVarBitfield
    local ok, value = pcall(getter, name, index)
    if not ok then
        return nil
    end
    return value and true or false
end

local function writeBool(name, value)
    local setter = C_CVar and C_CVar.SetCVar or SetCVar
    pcall(setter, name, value and '1' or '0')
end

local function writeNumber(name, value)
    local setter = C_CVar and C_CVar.SetCVar or SetCVar
    pcall(setter, name, tostring(value))
end

local function writeBit(name, index, value)
    local setter = C_CVar and C_CVar.SetCVarBitfield or SetCVarBitfield
    pcall(setter, name, index, value and true or false)
end

cvars.Exists = function(self, key)
    local spec = self.SPEC[key]
    return spec and cvarExists(spec.cvar) or false
end

cvars.Read = function(self, key)
    local spec = self.SPEC[key]
    if not spec or not cvarExists(spec.cvar) then
        return nil
    end
    if spec.kind == 'bool' then
        return readBool(spec.cvar)
    end
    if spec.kind == 'number' then
        return readNumber(spec.cvar)
    end
    if spec.kind == 'bit' then
        return readBit(spec.cvar, spec.index())
    end
end

cvars.ApplyKey = function(self, key, value)
    local spec = self.SPEC[key]
    if not spec then
        return
    end
    if spec.kind == 'bool' then
        writeBool(spec.cvar, value)
        return
    end
    if spec.kind == 'number' then
        writeNumber(spec.cvar, value)
        return
    end
    if spec.kind == 'bit' then
        writeBit(spec.cvar, spec.index(), value)
    end
end

cvars.ApplyAll = function(self, db)
    if not db then
        return
    end
    for key in pairs(self.SPEC) do
        local value = db[key]
        if value ~= nil then
            self:ApplyKey(key, value)
        end
    end
end

cvars.SeedMissing = function(self, db)
    if not db then
        return
    end
    for key in pairs(self.SPEC) do
        if db[key] == nil then
            local value = self:Read(key)
            if value ~= nil then
                db[key] = value
            end
        end
    end
end
