---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIMythicPlusTimerHistory
local history = EXUI:GetModule('mythic-plus-timer-history')

history.sessionKey = nil
history.sessionComparison = nil
history.sessionSourceLevel = nil

local function hasEntries(tbl)
    if not tbl then
        return false
    end
    return next(tbl) ~= nil
end

function history:GetStore()
    return data:GetMythicPlusHistory()
end

function history:IsPracticeRun()
    if not C_ChallengeMode or not C_ChallengeMode.GetChallengeCompletionInfo then
        return false
    end
    local info = C_ChallengeMode.GetChallengeCompletionInfo()
    return info and info.practiceRun
end

function history:HasRecordData(record)
    if not record then
        return false
    end
    return hasEntries(record.bosses) or hasEntries(record.forces)
end

function history:GetRecord(mapID, level)
    if not mapID or not level then
        return nil
    end
    local mapStore = self:GetStore()[mapID]
    if not mapStore then
        return nil
    end
    return mapStore[level]
end

function history:GetOrCreateRecord(mapID, level)
    local store = self:GetStore()
    local mapStore = store[mapID]
    if not mapStore then
        mapStore = {}
        store[mapID] = mapStore
    end

    local record = mapStore[level]
    if not record then
        record = {
            bosses = {},
            forces = {},
        }
        mapStore[level] = record
        return record
    end

    record.bosses = record.bosses or {}
    record.forces = record.forces or {}
    return record
end

function history:CloneRecord(record)
    if not record then
        return nil
    end

    local clone = {
        bosses = {},
        forces = {},
    }
    if record.bosses then
        for order, elapsed in pairs(record.bosses) do
            clone.bosses[tonumber(order) or order] = elapsed
        end
    end
    if record.forces then
        for bucket, elapsed in pairs(record.forces) do
            clone.forces[tonumber(bucket) or bucket] = elapsed
        end
    end
    return clone
end

function history:GetComparisonRecord(mapID, level, includePreviousLevel)
    local record = self:GetRecord(mapID, level)
    if self:HasRecordData(record) then
        return record, level
    end

    if includePreviousLevel and level and level > 1 then
        local fallback = self:GetRecord(mapID, level - 1)
        if self:HasRecordData(fallback) then
            return fallback, level - 1
        end
    end

    return record, level
end

function history:ClearSession()
    self.sessionKey = nil
    self.sessionComparison = nil
    self.sessionSourceLevel = nil
end

function history:EnsureSessionComparison(mapID, level, includePreviousLevel)
    local key = string.format('%s:%s:%s', tostring(mapID), tostring(level), includePreviousLevel and '1' or '0')
    if self.sessionKey == key then
        return self.sessionComparison, self.sessionSourceLevel
    end

    local record, sourceLevel = self:GetComparisonRecord(mapID, level, includePreviousLevel)
    self.sessionKey = key
    self.sessionComparison = self:CloneRecord(record)
    self.sessionSourceLevel = sourceLevel
    return self.sessionComparison, sourceLevel
end

function history:RecordBoss(mapID, level, order, elapsed)
    if self:IsPracticeRun() then
        return
    end
    if not mapID or not level or not order or not elapsed or elapsed <= 0 then
        return
    end

    local record = self:GetOrCreateRecord(mapID, level)
    local current = record.bosses[order]
    if not current or elapsed < current then
        record.bosses[order] = elapsed
    end
end

function history:RecordForcesPercent(mapID, level, percent, elapsed)
    if self:IsPracticeRun() then
        return
    end
    if not mapID or not level or not percent or not elapsed or elapsed <= 0 or percent <= 0 then
        return
    end

    local bucket = math.floor(percent)
    if bucket < 1 then
        return
    end
    if bucket > 100 then
        bucket = 100
    end

    local record = self:GetOrCreateRecord(mapID, level)
    local current = record.forces[bucket]
    if not current or elapsed < current then
        record.forces[bucket] = elapsed
    end
end

function history:RecordRunProgress(mapID, level, bosses, forces, elapsed)
    if not mapID or not level then
        return
    end

    if bosses then
        for _, boss in ipairs(bosses) do
            if boss.killTime then
                self:RecordBoss(mapID, level, boss.order or boss.criteriaIndex, boss.killTime)
            end
        end
    end

    if forces and elapsed then
        self:RecordForcesPercent(mapID, level, forces.percent, elapsed)
    end
end

function history:GetForcesHistoricTime(record, percent)
    if not record or not record.forces or not percent or percent <= 0 then
        return nil
    end

    local lowerKey, lowerVal, upperKey, upperVal
    for key, value in pairs(record.forces) do
        local bucket = tonumber(key)
        if bucket and value then
            if bucket <= percent and (not lowerKey or bucket > lowerKey) then
                lowerKey = bucket
                lowerVal = value
            end
            if bucket >= percent and (not upperKey or bucket < upperKey) then
                upperKey = bucket
                upperVal = value
            end
        end
    end

    if lowerKey and upperKey then
        if lowerKey == upperKey then
            return lowerVal
        end
        local t = (percent - lowerKey) / (upperKey - lowerKey)
        return lowerVal + (upperVal - lowerVal) * t
    end

    if upperKey and not lowerKey then
        return upperVal * (percent / upperKey)
    end

    return lowerVal
end

function history:AttachComparison(snapshot, db)
    if not snapshot then
        return
    end

    snapshot.comparison = nil
    if db and db.showSplitComparison == false then
        return
    end

    local mapID = snapshot.mapID
    local level = snapshot.keyLevel
    if not mapID or not level then
        return
    end

    local record, sourceLevel = self:EnsureSessionComparison(mapID, level, db and db.comparePreviousKeyLevel)
    if not self:HasRecordData(record) then
        return
    end

    snapshot.comparison = {
        bosses = record.bosses,
        forcesHistoric = self:GetForcesHistoricTime(record, snapshot.forces and snapshot.forces.percent),
        sourceLevel = sourceLevel,
    }
end
