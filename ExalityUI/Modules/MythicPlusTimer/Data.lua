---@class ExalityUI

local EXUI = select(2, ...)



---@class EXUIMythicPlusTimerDefaults

local defaults = EXUI:GetModule('mythic-plus-timer-defaults')



---@class EXUIMythicPlusTimerData

local timerData = EXUI:GetModule('mythic-plus-timer-data')



timerData.bossList = {}

timerData.timerID = nil

timerData.bossListRetryAttempt = 0



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



function timerData:ResetRunState()

    self.bossList = {}

    self.timerID = nil

    self.bossListRetryAttempt = 0

end



function timerData:GetScenarioCriteriaCount()

    if not C_Scenario or not C_Scenario.GetStepInfo then

        return 0

    end



    local _, _, numCriteria = C_Scenario.GetStepInfo()

    return numCriteria or 0

end



function timerData:GetForcesCriteriaIndex(numCriteria)

    numCriteria = numCriteria or self:GetScenarioCriteriaCount()

    if numCriteria <= 0 or not C_ScenarioInfo or not C_ScenarioInfo.GetCriteriaInfo then

        return nil

    end



    local criteria = C_ScenarioInfo.GetCriteriaInfo(numCriteria)

    if criteria and criteria.isWeightedProgress then

        return numCriteria

    end



    for index = numCriteria, 1, -1 do

        criteria = C_ScenarioInfo.GetCriteriaInfo(index)

        if criteria and criteria.isWeightedProgress then

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

    self.bossList = {}



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

        return nil

    end



    if not C_ScenarioInfo or not C_ScenarioInfo.GetCriteriaInfo then

        return nil

    end



    local criteriaIndex = self:GetForcesCriteriaIndex()

    if not criteriaIndex then

        return nil

    end



    local criteria = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)

    if not criteria then

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

    return {
        percent = percent,
        current = math.floor(current + 0.5),
        total = total,
    }
end



function timerData:GetTimerSnapshot()

    if not self:IsActive() then

        return nil

    end



    local mapChallengeModeID = C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID()

    if not mapChallengeModeID then

        return nil

    end



    local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)

    if not timeLimit or timeLimit <= 0 then

        return nil

    end



    local keyLevel = 0

    if C_ChallengeMode.GetActiveKeystoneInfo then

        keyLevel = select(1, C_ChallengeMode.GetActiveKeystoneInfo()) or 0

    end



    local timerID = self.timerID or self:GetChallengeModeTimerID()

    local elapsed = 0

    if timerID and GetWorldElapsedTime then

        _, elapsed = GetWorldElapsedTime(timerID)

        elapsed = elapsed or 0

    end



    local deathCount, timeLost = 0, 0

    if C_ChallengeMode.GetDeathCount then

        deathCount, timeLost = C_ChallengeMode.GetDeathCount()

        deathCount = deathCount or 0

        timeLost = timeLost or 0

    end



    local levelText = string.format('+%d', keyLevel)



    local thresholds = defaults.UPGRADE_THRESHOLDS

    local milestoneIndex, milestoneRemaining

    local plus3Time = timeLimit * thresholds.plus3

    local plus2Time = timeLimit * thresholds.plus2



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



    self:BuildBossList()



    return {

        timerID = timerID,

        timeLimit = timeLimit,

        elapsed = elapsed,

        keyLevel = keyLevel,

        levelText = levelText,

        deathCount = deathCount,

        timeLost = timeLost,

        showDeathPenalty = keyLevel >= 12 and timeLost > 0,

        elapsedPercent = math.min(1, elapsed / timeLimit),

        milestoneIndex = milestoneIndex,

        milestoneRemaining = milestoneRemaining,

        forces = self:GetForcesInfo(),

        bosses = self.bossList,

    }

end



function timerData:OnChallengeActivated()

    self.timerID = self:GetChallengeModeTimerID()

    self.bossListRetryAttempt = 0

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



    if event == 'SCENARIO_UPDATE'

        or event == 'SCENARIO_CRITERIA_UPDATE'

        or event == 'SCENARIO_CRITERIA_SHOW_STATE_UPDATE'

        or event == 'SCENARIO_POI_UPDATE' then

        if self:IsActive() then

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


