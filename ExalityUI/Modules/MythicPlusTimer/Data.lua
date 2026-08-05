---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIMythicPlusTimerDefaults
local defaults = EXUI:GetModule('mythic-plus-timer-defaults')

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
    self:InvalidateStructuralCache()
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
    wipe(self.bossList)

    if not self:IsActive() or not C_ScenarioInfo or not C_ScenarioInfo.GetCriteriaInfo then
        return
    end

    local bossCount = self:GetBossCriteriaCount()
    for index = 1, bossCount do
        local criteria = C_ScenarioInfo.GetCriteriaInfo(index)
        if criteria then
            local name = self:ParseBossNameFromCriteria(criteria.description)
            self.bossList[#self.bossList + 1] = {
                criteriaIndex = index,
                name = name or ('Boss ' .. index),
                killTime = self:GetBossKillTime(criteria),
                order = index,
            }
        end
    end

    table.sort(self.bossList, function(a, b)
        return a.order < b.order
    end)
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
    if not C_Scenario or not C_Scenario.IsInScenario or not C_Scenario.IsInScenario() then
        self.cachedForces = nil
        return nil
    end

    if not C_ScenarioInfo or not C_ScenarioInfo.GetCriteriaInfo then
        self.cachedForces = nil
        return nil
    end

    local criteriaIndex = self:GetForcesCriteriaIndex()
    if not criteriaIndex then
        self.cachedForces = nil
        return nil
    end

    local criteria = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
    if not criteria then
        self.cachedForces = nil
        return nil
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

    local forces = self.cachedForces
    if not forces then
        forces = {}
        self.cachedForces = forces
    end
    forces.percent = percent
    forces.current = math.floor(current + 0.5)
    forces.total = total
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
    snapshot.keyLevel = self.cachedKeyLevel
    snapshot.levelText = self.cachedLevelText
    snapshot.deathCount = deathCount
    snapshot.timeLost = timeLost
    snapshot.showDeathPenalty = self.cachedKeyLevel >= 12 and timeLost > 0
    snapshot.elapsedPercent = math.min(1, elapsed / timeLimit)
    snapshot.milestoneIndex = milestoneIndex
    snapshot.milestoneRemaining = milestoneRemaining
    snapshot.forces = self.cachedForces or self:GetForcesInfo()
    snapshot.bosses = self.bossList

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

    if event == 'CHALLENGE_MODE_START' then
        self:ResetRunState()
        self:OnChallengeActivated()
        return
    end

    if event == 'CHALLENGE_MODE_RESET' or event == 'CHALLENGE_MODE_COMPLETED' then
        self:ResetRunState()
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
