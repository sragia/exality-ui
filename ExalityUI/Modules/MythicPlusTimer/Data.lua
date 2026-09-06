---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIMythicPlusTimerDefaults
local defaults = EXUI:GetModule('mythic-plus-timer-defaults')

---@class EXUIMythicPlusTimerHistory
local history = EXUI:GetModule('mythic-plus-timer-history')

---@class EXUIMythicPlusTimerModule
local mythicPlusTimer = EXUI:GetModule('mythic-plus-timer')

---@class EXUIMythicPlusTimerData
local timerData = EXUI:GetModule('mythic-plus-timer-data')

timerData.bossList = {}
timerData.timerID = nil
timerData.bossListRetryAttempt = 0
timerData.forcesCriteriaIndex = nil
timerData.cachedForces = nil
timerData.cachedMapID = nil
timerData.cachedTimeLimit = nil
timerData.cachedKeyLevel = nil
timerData.cachedLevelText = nil
timerData.fullSnapshot = nil
timerData.tickerSnapshot = nil
timerData.structuralDirty = true
timerData.isCompletedLinger = false
timerData.lastGoodForces = nil
timerData.lastGoodBosses = nil
timerData.lastGoodComparison = nil
timerData.forcesCompleteTime = nil

timerData.EVENTS = {
    'PLAYER_ENTERING_WORLD',
    'WORLD_STATE_TIMER_START',
    'WORLD_STATE_TIMER_STOP',
    'CHALLENGE_MODE_START',
    'CHALLENGE_MODE_COMPLETED',
    'CHALLENGE_MODE_RESET',
    'CHALLENGE_MODE_DEATH_COUNT_UPDATED',
    'SCENARIO_UPDATE',
    'SCENARIO_CRITERIA_UPDATE',
    'SCENARIO_CRITERIA_SHOW_STATE_UPDATE',
    'SCENARIO_POI_UPDATE',
}

function timerData:IsActive()
    return C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
end

function timerData:ShouldDisplay()
    return self:IsActive() or self.isCompletedLinger
end

function timerData:GetChallengeModeTimerID()
    if not GetWorldElapsedTimers or not GetWorldElapsedTime or not Enum or not Enum.WorldElapsedTimerTypes then
        return nil
    end

    for i = 1, select('#', GetWorldElapsedTimers()) do
        local timerID = select(i, GetWorldElapsedTimers())
        local _, _, timerType = GetWorldElapsedTime(timerID)
        if timerType == Enum.WorldElapsedTimerTypes.ChallengeMode then
            return timerID
        end
    end

    return nil
end

function timerData:InvalidateStructuralCache()
    self.forcesCriteriaIndex = nil
    self.cachedForces = nil
    self.cachedMapID = nil
    self.cachedTimeLimit = nil
    self.cachedKeyLevel = nil
    self.cachedLevelText = nil
    self.structuralDirty = true
end

function timerData:ResetRunState()
    self.bossList = {}
    self.timerID = nil
    self.bossListRetryAttempt = 0
    self.fullSnapshot = nil
    self.tickerSnapshot = nil
    self.isCompletedLinger = false
    self.lastGoodForces = nil
    self.lastGoodBosses = nil
    self.lastGoodComparison = nil
    self.forcesCompleteTime = nil
    history:ClearSession()
    self:InvalidateStructuralCache()
end

local function copyForces(forces)
    if not forces then
        return nil
    end
    return {
        percent = forces.percent,
        current = forces.current,
        total = forces.total,
        completedTime = forces.completedTime,
    }
end

local function copyBosses(bosses)
    if not bosses then
        return {}
    end
    local copy = {}
    for index, boss in ipairs(bosses) do
        copy[index] = {
            criteriaIndex = boss.criteriaIndex,
            name = boss.name,
            killTime = boss.killTime,
            order = boss.order,
        }
    end
    return copy
end

local function copyComparison(comparison)
    if not comparison then
        return nil
    end
    local bosses = {}
    if comparison.bosses then
        for order, elapsed in pairs(comparison.bosses) do
            bosses[order] = elapsed
        end
    end
    return {
        bosses = bosses,
        forcesHistoric = comparison.forcesHistoric,
        forcesSplit = comparison.forcesSplit,
        sourceLevel = comparison.sourceLevel,
    }
end

local function countKillTimes(bosses)
    local count = 0
    if not bosses then
        return count
    end
    for _, boss in ipairs(bosses) do
        if boss.killTime and boss.killTime > 0 then
            count = count + 1
        end
    end
    return count
end

local function forcesCurrent(forces)
    return forces and forces.current or 0
end

function timerData:CaptureLastGoodObjectives()
    local forces = self.cachedForces
    if forces and forcesCurrent(forces) > 0 then
        if forcesCurrent(forces) >= forcesCurrent(self.lastGoodForces) then
            self.lastGoodForces = copyForces(forces)
        end
    end

    local killTimes = countKillTimes(self.bossList)
    if self.bossList and #self.bossList > 0 and killTimes >= countKillTimes(self.lastGoodBosses) then
        if killTimes > 0 or not self.lastGoodBosses then
            self.lastGoodBosses = copyBosses(self.bossList)
        end
    end

    if self.fullSnapshot and self.fullSnapshot.comparison then
        self.lastGoodComparison = copyComparison(self.fullSnapshot.comparison)
    end
end

function timerData:GetBestForces()
    local live = self.cachedForces
    local saved = self.lastGoodForces
    if forcesCurrent(live) >= forcesCurrent(saved) and forcesCurrent(live) > 0 then
        return live
    end
    return saved or live
end

function timerData:IsForcesComplete(forces)
    if not forces then
        return false
    end
    if (forces.percent or 0) >= 100 then
        return true
    end
    local total = forces.total or 0
    return total > 0 and (forces.current or 0) >= total
end

function timerData:GetBestBosses()
    local live = self.bossList
    local saved = self.lastGoodBosses
    if countKillTimes(live) >= countKillTimes(saved) and live and #live > 0 then
        if countKillTimes(live) > 0 or not saved then
            return live
        end
    end
    return saved or live
end

function timerData:FreezeCompletedRun()
    self:FlushHistory()

    local snapshot = self.fullSnapshot or {}
    local elapsed = self:GetCompletionElapsed(snapshot.elapsed or self:GetElapsedSeconds())
    snapshot.elapsed = elapsed
    snapshot.timeLimit = snapshot.timeLimit or self.cachedTimeLimit
    if snapshot.timeLimit and snapshot.timeLimit > 0 then
        snapshot.elapsedPercent = math.min(1, elapsed / snapshot.timeLimit)
    end
    snapshot.mapID = snapshot.mapID or self.cachedMapID
    snapshot.keyLevel = snapshot.keyLevel or self.cachedKeyLevel
    snapshot.levelText = snapshot.levelText or self.cachedLevelText
    snapshot.milestoneIndex = nil
    snapshot.milestoneRemaining = nil
    snapshot.forces = copyForces(self.lastGoodForces or self:GetBestForces() or snapshot.forces)
    snapshot.bosses = copyBosses(self.lastGoodBosses or self:GetBestBosses() or snapshot.bosses)
    snapshot.comparison = copyComparison(self.lastGoodComparison or snapshot.comparison)
    if snapshot.forces and self:IsForcesComplete(snapshot.forces) then
        snapshot.forces.completedTime = self.forcesCompleteTime
            or snapshot.forces.completedTime
            or elapsed
    end
    self.fullSnapshot = snapshot
    self.tickerSnapshot = nil
    self.isCompletedLinger = true
    history:ClearSession()
end

function timerData:GetCompletionElapsed(fallbackElapsed)
    if C_ChallengeMode and C_ChallengeMode.GetChallengeCompletionInfo then
        local info = C_ChallengeMode.GetChallengeCompletionInfo()
        if info and info.time and info.time > 0 then
            return info.time / 1000
        end
    end
    return fallbackElapsed or 0
end

function timerData:RecordCurrentProgress(elapsed)
    if not self.cachedMapID or self.cachedKeyLevel == nil then
        return
    end
    history:RecordRunProgress(self.cachedMapID, self.cachedKeyLevel, self.bossList, self.cachedForces, elapsed)
end

function timerData:FlushHistory()
    if history:IsPracticeRun() then
        return
    end
    if not self.cachedMapID or self.cachedKeyLevel == nil then
        self:EnsureRunMeta()
    end
    if not self.cachedMapID or self.cachedKeyLevel == nil then
        return
    end

    local elapsed = self:GetCompletionElapsed(self:GetElapsedSeconds())
    history:RecordRunProgress(
        self.cachedMapID,
        self.cachedKeyLevel,
        self:GetBestBosses(),
        self:GetBestForces(),
        elapsed
    )
end

function timerData:GetScenarioCriteriaCount()
    if not C_Scenario or not C_Scenario.GetStepInfo then
        return 0
    end

    local _, _, numCriteria = C_Scenario.GetStepInfo()
    return numCriteria or 0
end

function timerData:GetForcesCriteriaIndex(numCriteria)
    if self.forcesCriteriaIndex ~= nil then
        return self.forcesCriteriaIndex
    end

    numCriteria = numCriteria or self:GetScenarioCriteriaCount()
    if numCriteria <= 0 or not C_ScenarioInfo or not C_ScenarioInfo.GetCriteriaInfo then
        return nil
    end

    local criteria = C_ScenarioInfo.GetCriteriaInfo(numCriteria)
    if criteria and criteria.isWeightedProgress then
        self.forcesCriteriaIndex = numCriteria
        return numCriteria
    end

    for index = numCriteria, 1, -1 do
        criteria = C_ScenarioInfo.GetCriteriaInfo(index)
        if criteria and criteria.isWeightedProgress then
            self.forcesCriteriaIndex = index
            return index
        end
    end

    return nil
end

function timerData:GetBossCriteriaCount(numCriteria)
    numCriteria = numCriteria or self:GetScenarioCriteriaCount()
    local forcesIndex = self:GetForcesCriteriaIndex(numCriteria)
    if forcesIndex and forcesIndex > 0 then
        return math.max(0, forcesIndex - 1)
    end
    return numCriteria
end

function timerData:ParseBossNameFromCriteria(description)
    if not description or description == '' then
        return nil
    end

    local name = description:match('^(.+)%s+%S+$')
    return name or description
end

function timerData:GetBossKillTime(criteria)
    if not criteria or not criteria.completed then
        return nil
    end

    local timerID = self.timerID or self:GetChallengeModeTimerID()
    if not timerID or not GetWorldElapsedTime then
        return nil
    end

    local _, elapsedTime = GetWorldElapsedTime(timerID)
    elapsedTime = elapsedTime or 0

    if criteria.elapsed and criteria.elapsed > 0 then
        return math.max(0, elapsedTime - criteria.elapsed)
    end

    return elapsedTime
end

function timerData:BuildBossList()
    if not self:IsActive() or not C_ScenarioInfo or not C_ScenarioInfo.GetCriteriaInfo then
        return
    end

    local previousByOrder = {}
    for _, boss in ipairs(self.bossList) do
        previousByOrder[boss.order] = boss
    end
    if self.lastGoodBosses then
        for _, boss in ipairs(self.lastGoodBosses) do
            if not previousByOrder[boss.order] then
                previousByOrder[boss.order] = boss
            end
        end
    end

    local newList = {}
    local bossCount = self:GetBossCriteriaCount()
    for index = 1, bossCount do
        local criteria = C_ScenarioInfo.GetCriteriaInfo(index)
        if criteria then
            local name = self:ParseBossNameFromCriteria(criteria.description)
            local killTime = self:GetBossKillTime(criteria)
            local prev = previousByOrder[index]
            if (not killTime or killTime <= 0) and prev and prev.killTime and prev.killTime > 0 then
                killTime = prev.killTime
            end
            newList[#newList + 1] = {
                criteriaIndex = index,
                name = name or (prev and prev.name) or ('Boss ' .. index),
                killTime = killTime,
                order = index,
            }
        end
    end

    if #newList == 0 then
        return
    end

    if countKillTimes(newList) < countKillTimes(self.bossList)
        or countKillTimes(newList) < countKillTimes(self.lastGoodBosses) then
        return
    end

    wipe(self.bossList)
    for index, boss in ipairs(newList) do
        self.bossList[index] = boss
    end

    table.sort(self.bossList, function(a, b)
        return a.order < b.order
    end)
    self:CaptureLastGoodObjectives()
end

function timerData:ScheduleBossListRetry()
    if not self:IsActive() or #self.bossList > 0 or self.bossListRetryAttempt >= 4 then
        return
    end

    self.bossListRetryAttempt = self.bossListRetryAttempt + 1
    C_Timer.After(2, function()
        if not timerData:IsActive() then
            return
        end

        timerData:BuildBossList()
        timerData.structuralDirty = true
        if timerData.updateCallback then
            timerData.updateCallback()
        end
        timerData:ScheduleBossListRetry()
    end)
end

function timerData:ParseForcesCount(criteria)
    if not criteria then
        return nil, nil
    end

    local total = criteria.totalQuantity or 0

    if criteria.quantityString and criteria.quantityString ~= '' then
        local parsedCurrent, parsedTotal = criteria.quantityString:match('([%d%.]+)/([%d%.]+)')
        if parsedCurrent and parsedTotal then
            return tonumber(parsedCurrent), tonumber(parsedTotal)
        end

        local count = tonumber((criteria.quantityString:gsub('%%', '')))
        if count then
            return count, total
        end
    end

    if criteria.quantity and total > 0 and total ~= 100 then
        return criteria.quantity, total
    end

    return nil, total
end

function timerData:GetForcesInfo()
    local function keepExisting()
        return self.cachedForces or self.lastGoodForces
    end

    if not C_Scenario or not C_Scenario.IsInScenario or not C_Scenario.IsInScenario() then
        return keepExisting()
    end

    if not C_ScenarioInfo or not C_ScenarioInfo.GetCriteriaInfo then
        return keepExisting()
    end

    local criteriaIndex = self:GetForcesCriteriaIndex()
    if not criteriaIndex then
        return keepExisting()
    end

    local criteria = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
    if not criteria then
        return keepExisting()
    end

    local current, total = self:ParseForcesCount(criteria)
    current = current or 0
    total = total or 0

    local percent = 0
    if total > 0 and current > 0 then
        percent = (current / total) * 100
    else
        local _, _, _, _, _, _, _, _, _, weightedProgress = C_Scenario.GetStepInfo()
        percent = weightedProgress or 0
    end

    current = math.floor(current + 0.5)
    local existing = keepExisting()
    if current <= 0 and forcesCurrent(existing) > 0 then
        return existing
    end
    if forcesCurrent(existing) > current then
        return existing
    end
    if total <= 0 and existing and (existing.total or 0) > 0 then
        return existing
    end
    if total <= 0 and percent <= 0 then
        return existing
    end

    local forces = self.cachedForces
    if not forces then
        forces = {}
        self.cachedForces = forces
    end
    forces.percent = percent
    forces.current = current
    forces.total = total
    self:CaptureLastGoodObjectives()
    return forces
end

local function computeMilestones(timeLimit, elapsed)
    local thresholds = defaults.UPGRADE_THRESHOLDS
    local plus3Time = timeLimit * thresholds.plus3
    local plus2Time = timeLimit * thresholds.plus2
    local milestoneIndex, milestoneRemaining

    if elapsed < plus3Time then
        milestoneIndex = 1
        milestoneRemaining = plus3Time - elapsed
    elseif elapsed < plus2Time then
        milestoneIndex = 2
        milestoneRemaining = plus2Time - elapsed
    elseif elapsed < timeLimit then
        milestoneIndex = 3
        milestoneRemaining = timeLimit - elapsed
    end

    return milestoneIndex, milestoneRemaining
end

function timerData:EnsureRunMeta()
    local mapChallengeModeID = C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID()
    if not mapChallengeModeID then
        return false
    end

    if self.cachedMapID ~= mapChallengeModeID or not self.cachedTimeLimit then
        local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
        if not timeLimit or timeLimit <= 0 then
            return false
        end
        self.cachedMapID = mapChallengeModeID
        self.cachedTimeLimit = timeLimit
    end

    if self.cachedKeyLevel == nil or self.structuralDirty then
        local keyLevel = 0
        if C_ChallengeMode.GetActiveKeystoneInfo then
            keyLevel = select(1, C_ChallengeMode.GetActiveKeystoneInfo()) or 0
        end
        self.cachedKeyLevel = keyLevel
        self.cachedLevelText = string.format('+%d', keyLevel)
    end

    return true
end

function timerData:GetElapsedSeconds()
    local timerID = self.timerID or self:GetChallengeModeTimerID()
    local elapsed = 0
    if timerID and GetWorldElapsedTime then
        _, elapsed = GetWorldElapsedTime(timerID)
        elapsed = elapsed or 0
        self.timerID = timerID
    end
    return elapsed, timerID
end

function timerData:GetDisplaySnapshot(isTicker)
    if self.isCompletedLinger then
        return self.fullSnapshot
    end
    if isTicker then
        return self:GetTickerSnapshot()
    end
    return self:GetTimerSnapshot()
end

function timerData:GetTimerSnapshot()
    if not self:IsActive() then
        return nil
    end

    if not self:EnsureRunMeta() then
        return nil
    end

    local timeLimit = self.cachedTimeLimit
    local elapsed, timerID = self:GetElapsedSeconds()
    local deathCount, timeLost = 0, 0
    if C_ChallengeMode.GetDeathCount then
        deathCount, timeLost = C_ChallengeMode.GetDeathCount()
        deathCount = deathCount or 0
        timeLost = timeLost or 0
    end

    local milestoneIndex, milestoneRemaining = computeMilestones(timeLimit, elapsed)

    if self.structuralDirty then
        self.forcesCriteriaIndex = nil
        self:BuildBossList()
        self:GetForcesInfo()
        self.structuralDirty = false
    end

    local snapshot = self.fullSnapshot
    if not snapshot then
        snapshot = {}
        self.fullSnapshot = snapshot
    end

    snapshot.timerID = timerID
    snapshot.timeLimit = timeLimit
    snapshot.elapsed = elapsed
    snapshot.mapID = self.cachedMapID
    snapshot.keyLevel = self.cachedKeyLevel
    snapshot.levelText = self.cachedLevelText
    snapshot.deathCount = deathCount
    snapshot.timeLost = timeLost
    snapshot.showDeathPenalty = self.cachedKeyLevel >= 12 and timeLost > 0
    snapshot.elapsedPercent = math.min(1, elapsed / timeLimit)
    snapshot.milestoneIndex = milestoneIndex
    snapshot.milestoneRemaining = milestoneRemaining
    snapshot.forces = self:GetBestForces() or self:GetForcesInfo()
    snapshot.bosses = self:GetBestBosses()
    if snapshot.forces and self:IsForcesComplete(snapshot.forces) then
        self.forcesCompleteTime = self.forcesCompleteTime or snapshot.forces.completedTime or elapsed
        snapshot.forces.completedTime = self.forcesCompleteTime
    end

    history:AttachComparison(snapshot, mythicPlusTimer.Data and mythicPlusTimer.Data:GetDB())
    self:RecordCurrentProgress(elapsed)
    self:CaptureLastGoodObjectives()

    return snapshot
end

--- Cheap 10Hz path: elapsed/milestones only; reuses cached bosses/forces/meta.
function timerData:GetTickerSnapshot()
    if not self:IsActive() then
        return nil
    end

    if self.structuralDirty or not self.fullSnapshot then
        return self:GetTimerSnapshot()
    end

    if not self:EnsureRunMeta() then
        return nil
    end

    local timeLimit = self.cachedTimeLimit
    local elapsed, timerID = self:GetElapsedSeconds()
    local milestoneIndex, milestoneRemaining = computeMilestones(timeLimit, elapsed)

    local base = self.fullSnapshot
    local snapshot = self.tickerSnapshot
    if not snapshot then
        snapshot = {}
        self.tickerSnapshot = snapshot
    end

    snapshot.timerID = timerID
    snapshot.timeLimit = timeLimit
    snapshot.elapsed = elapsed
    snapshot.mapID = base.mapID
    snapshot.keyLevel = base.keyLevel
    snapshot.levelText = base.levelText
    snapshot.deathCount = base.deathCount
    snapshot.timeLost = base.timeLost
    snapshot.showDeathPenalty = base.showDeathPenalty
    snapshot.elapsedPercent = math.min(1, elapsed / timeLimit)
    snapshot.milestoneIndex = milestoneIndex
    snapshot.milestoneRemaining = milestoneRemaining
    snapshot.forces = base.forces
    snapshot.bosses = base.bosses
    snapshot.comparison = base.comparison

    -- Keep full snapshot elapsed fields current for consumers that read it.
    base.elapsed = elapsed
    base.elapsedPercent = snapshot.elapsedPercent
    base.milestoneIndex = milestoneIndex
    base.milestoneRemaining = milestoneRemaining
    base.timerID = timerID

    return snapshot
end

function timerData:OnChallengeActivated()
    self.timerID = self:GetChallengeModeTimerID()
    self.bossListRetryAttempt = 0
    self:InvalidateStructuralCache()
    self:BuildBossList()
    self:ScheduleBossListRetry()
end

function timerData:OnEvent(event, ...)
    if event == 'PLAYER_ENTERING_WORLD' then
        if not self:IsActive() then
            self:ResetRunState()
        else
            self:OnChallengeActivated()
        end
        return
    end

    if event == 'CHALLENGE_MODE_START' then
        self:ResetRunState()
        self:OnChallengeActivated()
        return
    end

    if event == 'CHALLENGE_MODE_COMPLETED' then
        self:FreezeCompletedRun()
        return
    end

    if event == 'CHALLENGE_MODE_RESET' then
        self:ResetRunState()
        return
    end

    if self.isCompletedLinger then
        return
    end

    if event == 'WORLD_STATE_TIMER_START' then
        local timerID = ...
        if timerID and GetWorldElapsedTime then
            local _, _, timerType = GetWorldElapsedTime(timerID)
            if timerType == Enum.WorldElapsedTimerTypes.ChallengeMode then
                self.timerID = timerID
                self.structuralDirty = true
                self:BuildBossList()
            end
        end
        return
    end

    if event == 'WORLD_STATE_TIMER_STOP' then
        local timerID = ...
        if self.timerID == timerID then
            self.timerID = nil
        end
        return
    end

    if event == 'CHALLENGE_MODE_DEATH_COUNT_UPDATED' then
        self.structuralDirty = true
        return
    end

    if event == 'SCENARIO_UPDATE'
        or event == 'SCENARIO_CRITERIA_UPDATE'
        or event == 'SCENARIO_CRITERIA_SHOW_STATE_UPDATE'
        or event == 'SCENARIO_POI_UPDATE' then
        if self:IsActive() then
            self.forcesCriteriaIndex = nil
            self.structuralDirty = true
            self:BuildBossList()
        end
        return
    end
end

function timerData:RegisterEvents(callback)
    if self.eventFrame then
        return
    end

    self.updateCallback = callback
    self.eventFrame = CreateFrame('Frame')
    for _, event in ipairs(self.EVENTS) do
        self.eventFrame:RegisterEvent(event)
    end

    self.eventFrame:SetScript('OnEvent', function(_, event, ...)
        timerData:OnEvent(event, ...)
        if timerData.updateCallback then
            timerData.updateCallback()
        end
    end)
end

function timerData:UnregisterEvents()
    if not self.eventFrame then
        return
    end

    self.eventFrame:UnregisterAllEvents()
    self.eventFrame:SetScript('OnEvent', nil)
    self.eventFrame = nil
    self.updateCallback = nil
end

function timerData:StartTicker(callback)
    self:StopTicker()
    self.tickerCallback = callback
    self.ticker = C_Timer.NewTicker(0.1, function()
        if timerData.tickerCallback then
            timerData.tickerCallback()
        end
    end)
end

function timerData:StopTicker()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    self.tickerCallback = nil
end
