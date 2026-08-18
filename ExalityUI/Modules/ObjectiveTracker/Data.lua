---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIObjectiveTrackerDefaults
local defaults = EXUI:GetModule('objective-tracker-defaults')

---@class EXUIObjectiveTrackerData
local trackerData = EXUI:GetModule('objective-tracker-data')

local tablePool = {}

local function acquireTable()
    local item = tablePool[#tablePool]
    if item then
        tablePool[#tablePool] = nil
        return item
    end
    return {}
end

local function releaseTable(item)
    if not item then
        return
    end
    wipe(item)
    tablePool[#tablePool + 1] = item
end

local function recycleObjectives(objectives)
    if not objectives then
        return
    end
    for i = 1, #objectives do
        releaseTable(objectives[i])
        objectives[i] = nil
    end
    releaseTable(objectives)
end

local function recycleCurrencies(currencies)
    if not currencies then
        return
    end
    for i = 1, #currencies do
        releaseTable(currencies[i])
        currencies[i] = nil
    end
    releaseTable(currencies)
end

local function recycleCategoryBlocks(blocks)
    if not blocks then
        return
    end
    for i = 1, #blocks do
        local block = blocks[i]
        if block and not block.isAutoQuestPopUp then
            recycleObjectives(block.objectives)
            block.objectives = nil
            if block.delve then
                recycleCurrencies(block.delve.currencies)
                releaseTable(block.delve)
                block.delve = nil
            end
            if block.stage then
                if block.stage.headerTimer then
                    releaseTable(block.stage.headerTimer)
                    block.stage.headerTimer = nil
                end
                releaseTable(block.stage)
                block.stage = nil
            end
        end
        blocks[i] = nil
    end
    releaseTable(blocks)
end

local function addBlock(blocks, block)
    blocks[#blocks + 1] = block
end

local function addQuestObjectiveEntry(objectives, text, objectiveType, finished)
    local showProgressBar = objectiveType == 'progressbar' and not finished
    if (text and text ~= '') or showProgressBar then
        local entry = acquireTable()
        entry.text = (text and text ~= '') and text or nil
        entry.finished = finished
        entry.objectiveType = objectiveType
        entry.showProgressBar = showProgressBar
        objectives[#objectives + 1] = entry
    end
end

local function getQuestObjectives(questID)
    local objectives = acquireTable()
    local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    if not questLogIndex then
        return objectives
    end

    local numObjectives = GetNumQuestLeaderBoards(questLogIndex)
    for objectiveIndex = 1, numObjectives do
        local text, objectiveType, finished = GetQuestLogLeaderBoard(objectiveIndex, questLogIndex, true)
        addQuestObjectiveEntry(objectives, text, objectiveType, finished)
    end

    if #objectives == 0 and C_QuestLog.IsComplete(questID) then
        local entry = acquireTable()
        entry.text = QUEST_WATCH_QUEST_READY or 'Ready for turn-in'
        entry.finished = true
        objectives[1] = entry
    end

    return objectives
end

local function getQuestClassification(questID)
    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
        return C_QuestInfoSystem.GetQuestClassification(questID)
    end
    if QuestCache then
        local quest = QuestCache:Get(questID)
        if quest and quest.GetQuestClassification then
            return quest:GetQuestClassification()
        end
    end
end

local function isCampaignQuest(questID)
    return getQuestClassification(questID) == Enum.QuestClassification.Campaign
end

local function isWorldQuest(questID)
    if QuestUtils_IsQuestWorldQuest then
        return QuestUtils_IsQuestWorldQuest(questID)
    end
    return C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID)
end

local function isQuestWatched(questID)
    if QuestUtils_IsQuestWatched then
        return QuestUtils_IsQuestWatched(questID)
    end
    return questID and C_QuestLog.GetQuestWatchType and C_QuestLog.GetQuestWatchType(questID) ~= nil
end

local function getQuestTitle(questID, taskName)
    if taskName and taskName ~= '' then
        return taskName
    end
    if QuestUtils_GetQuestName then
        local title = QuestUtils_GetQuestName(questID)
        if title and title ~= '' then
            return title
        end
    end
    if C_TaskQuest and C_TaskQuest.GetQuestInfoByQuestID then
        local title = C_TaskQuest.GetQuestInfoByQuestID(questID)
        if title and title ~= '' then
            return title
        end
    end
    return C_QuestLog.GetTitleForQuestID(questID) or ('World Quest ' .. questID)
end

local function getTaskQuestObjectives(questID, numObjectives)
    local objectives = acquireTable()
    if numObjectives and numObjectives > 0 and GetQuestObjectiveInfo then
        for objectiveIndex = 1, numObjectives do
            local text, objectiveType, finished = GetQuestObjectiveInfo(questID, objectiveIndex, false)
            addQuestObjectiveEntry(objectives, text, objectiveType, finished)
        end
    end
    if #objectives == 0 then
        recycleObjectives(objectives)
        objectives = getQuestObjectives(questID)
    end
    return objectives
end

local function isWorldQuestOnBanner(questID)
    if ObjectiveTrackerTopBannerFrame and ObjectiveTrackerTopBannerFrame.GetQuestID then
        return questID == ObjectiveTrackerTopBannerFrame:GetQuestID()
    end
    return false
end

local function getTaskQuestObjectiveCount(questID, knownCount)
    if knownCount and knownCount > 0 then
        return knownCount
    end
    if GetTaskInfo then
        local _, _, numObjectives = GetTaskInfo(questID)
        if numObjectives and numObjectives > 0 then
            return numObjectives
        end
    end
    if C_QuestLog.GetNumQuestObjectives then
        local count = C_QuestLog.GetNumQuestObjectives(questID)
        if count and count > 0 then
            return count
        end
    end
end

local function collectAutomaticWorldQuestCandidates()
    local candidates = acquireTable()

    if not GetTasksTable then
        return candidates
    end

    local tasksTable = GetTasksTable()
    for i = 1, #tasksTable do
        local questID = tasksTable[i]
        if questID and isWorldQuest(questID) and not isWorldQuestOnBanner(questID) then
            candidates[#candidates + 1] = questID
        end
    end

    return candidates
end

local function sortWorldQuestIDs(questIDs)
    if not GetTaskInfo then
        table.sort(questIDs)
        return
    end
    table.sort(questIDs, function(questID1, questID2)
        local inArea1, onMap1 = GetTaskInfo(questID1)
        local inArea2, onMap2 = GetTaskInfo(questID2)
        if inArea1 ~= inArea2 then
            return inArea1
        end
        if onMap1 ~= onMap2 then
            return onMap1
        end
        return questID1 < questID2
    end)
end

local function makeWorldQuestBlock(questID, treatAsInArea)
    if not questID or not isWorldQuest(questID) or isWorldQuestOnBanner(questID) or not GetTaskInfo then
        return nil
    end

    local isInArea, _, numObjectives, taskName = GetTaskInfo(questID)
    if not treatAsInArea and not isInArea then
        return nil
    end

    if treatAsInArea then
        numObjectives = getTaskQuestObjectiveCount(questID, numObjectives)
    end
    if not numObjectives or numObjectives == 0 then
        return nil
    end

    return {
        id = questID,
        categoryId = 'world',
        title = getQuestTitle(questID, taskName),
        canUntrack = isQuestWatched(questID),
        untrackType = 'quest',
        untrackId = questID,
        isSuperTracked = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID() == questID,
        isComplete = C_QuestLog.IsComplete(questID),
        isWorldQuest = true,
        objectives = getTaskQuestObjectives(questID, numObjectives),
    }
end

local function isQuestAutoComplete(questID)
    if QuestCache then
        local quest = QuestCache:Get(questID)
        if quest then
            return quest.isAutoComplete
        end
    end
    return false
end

local function shouldShowStandardQuest(questID)
    if C_QuestLog.IsQuestTask and C_QuestLog.IsQuestTask(questID) then
        return false
    end
    if isCampaignQuest(questID) then
        return false
    end
    if isWorldQuest(questID) then
        return false
    end
    if QuestCache then
        local quest = QuestCache:Get(questID)
        if quest and quest:IsDisabledForSession() then
            return false
        end
    end
    return true
end

function trackerData:ShouldDisplayAutoQuest(questID)
    if not questID then
        return false
    end
    if C_QuestLog.IsQuestBounty and C_QuestLog.IsQuestBounty(questID) then
        return false
    end
    if QuestCache then
        local quest = QuestCache:Get(questID)
        if quest and quest.IsDisabledForSession and quest:IsDisabledForSession() then
            return false
        end
    end
    return true
end

function trackerData:CollectAutoQuestPopUpBlocks()
    local blocks = {}
    if SplashFrame and SplashFrame:IsShown() then
        return blocks
    end
    if not GetNumAutoQuestPopUps or not GetAutoQuestPopUp then
        return blocks
    end

    for i = 1, GetNumAutoQuestPopUps() do
        local questID, popUpType = GetAutoQuestPopUp(i)
        if questID and self:ShouldDisplayAutoQuest(questID) then
            local questTitle = C_QuestLog.GetTitleForQuestID(questID)
            if questTitle and questTitle ~= '' then
                local isCompletePopUp = popUpType == 'COMPLETE'
                local headerText
                local instructionText
                if isCompletePopUp then
                    if C_QuestLog.IsQuestTask and C_QuestLog.IsQuestTask(questID) then
                        headerText = QUEST_WATCH_POPUP_CLICK_TO_COMPLETE_TASK or 'Click to complete task'
                    else
                        headerText = QUEST_WATCH_POPUP_CLICK_TO_COMPLETE or 'Click to complete quest'
                    end
                else
                    headerText = QUEST_WATCH_POPUP_QUEST_DISCOVERED or 'Quest Discovered!'
                    instructionText = QUEST_WATCH_POPUP_CLICK_TO_VIEW or 'Click to view quest'
                end

                local objectives = {
                    { text = questTitle, colorKey = 'NormalHighlight' },
                }
                if instructionText then
                    objectives[#objectives + 1] = { text = instructionText }
                end

                addBlock(blocks, {
                    id = 'autoquest:' .. questID .. ':' .. (popUpType or ''),
                    title = headerText,
                    canUntrack = false,
                    untrackType = 'quest',
                    untrackId = questID,
                    isAutoQuestPopUp = true,
                    autoQuestPopUpType = popUpType,
                    isComplete = isCompletePopUp,
                    isAutoComplete = isCompletePopUp,
                    objectives = objectives,
                })
            end
        end
    end

    return blocks
end

function trackerData:GetAutoQuestPopUpBlocks()
    if not self.autoQuestPopUpBlocks then
        self.autoQuestPopUpBlocks = self:CollectAutoQuestPopUpBlocks()
    end
    return self.autoQuestPopUpBlocks
end

function trackerData:CollectQuestBlocks(categoryId, filterFn)
    local blocks = {}
    local popupQuestIDs = {}

    for _, popup in ipairs(self:GetAutoQuestPopUpBlocks()) do
        local questID = popup.untrackId
        if questID then
            local isCampaign = isCampaignQuest(questID)
            local belongsHere = (categoryId == 'campaign' and isCampaign)
                or (categoryId == 'quests' and not isCampaign)
            if belongsHere then
                popup.categoryId = categoryId
                addBlock(blocks, popup)
                popupQuestIDs[questID] = true
            end
        end
    end

    for i = 1, C_QuestLog.GetNumQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if questID and filterFn(questID) and not popupQuestIDs[questID] then
            local title = C_QuestLog.GetTitleForQuestID(questID) or ('Quest ' .. questID)
            local isComplete = C_QuestLog.IsComplete(questID)
            local isAutoComplete = isQuestAutoComplete(questID)
            local objectives = getQuestObjectives(questID)
            if isComplete and isAutoComplete then
                recycleObjectives(objectives)
                objectives = acquireTable()
                local completeEntry = acquireTable()
                completeEntry.text = QUEST_WATCH_QUEST_COMPLETE or 'Quest complete'
                completeEntry.finished = true
                objectives[1] = completeEntry
                local clickEntry = acquireTable()
                clickEntry.text = QUEST_WATCH_CLICK_TO_COMPLETE or 'Click to complete'
                clickEntry.colorKey = 'NormalHighlight'
                objectives[2] = clickEntry
            end
            addBlock(blocks, {
                id = questID,
                categoryId = categoryId,
                title = title,
                canUntrack = true,
                untrackType = 'quest',
                untrackId = questID,
                isSuperTracked = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID() == questID,
                isComplete = isComplete,
                isAutoComplete = isAutoComplete,
                isWorldQuest = isWorldQuest(questID),
                objectives = objectives,
            })
        end
    end
    return blocks
end

function trackerData:CollectAchievementBlocks()
    local blocks = {}
    local tracked = C_ContentTracking.GetTrackedIDs(Enum.ContentTrackingType.Achievement)
    for _, achievementID in ipairs(tracked) do
        local _, name, _, completed = GetAchievementInfo(achievementID)
        if name and not completed then
            local objectives = {}
            local numCriteria = GetAchievementNumCriteria(achievementID)
            local shown = 0
            for criteriaIndex = 1, numCriteria do
                local criteriaString, _, criteriaCompleted = GetAchievementCriteriaInfo(achievementID, criteriaIndex)
                if criteriaString and not criteriaCompleted and shown < 5 then
                    shown = shown + 1
                    objectives[#objectives + 1] = {
                        text = criteriaString,
                        finished = false,
                    }
                end
            end
            addBlock(blocks, {
                id = achievementID,
                categoryId = 'achievement',
                title = name,
                canUntrack = true,
                untrackType = 'achievement',
                untrackId = achievementID,
                objectives = objectives,
            })
        end
    end
    return blocks
end

local function getReagentName(reagent)
    if reagent.itemID then
        return C_Item.GetItemNameByID(reagent.itemID) or select(1, GetItemInfo(reagent.itemID))
    end
    if reagent.currencyID then
        local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(reagent.currencyID)
        return currencyInfo and currencyInfo.name
    end
end

local recipeSchematicCache = {}

local function getRecipeSchematicCacheKey(recipeID, isRecraft)
    return (isRecraft and 'r:' or 'n:') .. tostring(recipeID)
end

local function getRecipeSchematic(recipeID, isRecraft)
    local cacheKey = getRecipeSchematicCacheKey(recipeID, isRecraft)
    local cached = recipeSchematicCache[cacheKey]
    if cached ~= nil then
        return cached or nil
    end

    local schematic
    if ProfessionsUtil and ProfessionsUtil.GetRecipeSchematic then
        schematic = ProfessionsUtil.GetRecipeSchematic(recipeID, isRecraft)
    else
        schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, isRecraft)
    end
    recipeSchematicCache[cacheKey] = schematic or false
    return schematic
end

function trackerData:InvalidateRecipeSchematicCache()
    wipe(recipeSchematicCache)
end

local function getReagentQuantityRequired(reagentSlotSchematic, reagent)
    if reagentSlotSchematic.GetQuantityRequired then
        return reagentSlotSchematic:GetQuantityRequired(reagent)
    end
    return reagentSlotSchematic.quantityRequired
end

local function isReagentSlotRequired(reagentSlotSchematic)
    if ProfessionsUtil and ProfessionsUtil.IsReagentSlotRequired then
        return ProfessionsUtil.IsReagentSlotRequired(reagentSlotSchematic)
    end
    return reagentSlotSchematic.required
end

local function isReagentSlotBasicRequired(reagentSlotSchematic)
    if ProfessionsUtil and ProfessionsUtil.IsReagentSlotBasicRequired then
        return ProfessionsUtil.IsReagentSlotBasicRequired(reagentSlotSchematic)
    end
    return reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Basic and reagentSlotSchematic.required
end

local function isReagentSlotModifyingRequired(reagentSlotSchematic)
    if ProfessionsUtil and ProfessionsUtil.IsReagentSlotModifyingRequired then
        return ProfessionsUtil.IsReagentSlotModifyingRequired(reagentSlotSchematic)
    end
    return reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Modifying and reagentSlotSchematic.required
end

local function getReagentQuantityInPossession(reagents)
    if ProfessionsUtil and ProfessionsUtil.AccumulateReagentsInPossession then
        return ProfessionsUtil.AccumulateReagentsInPossession(reagents)
    end

    local total = 0
    for _, reagent in ipairs(reagents) do
        if reagent.itemID then
            if ItemUtil and ItemUtil.GetCraftingReagentCount then
                total = total + ItemUtil.GetCraftingReagentCount(reagent.itemID, false)
            else
                total = total + (C_Item.GetItemCount(reagent.itemID, false, false, true) or 0)
            end
        elseif reagent.currencyID then
            local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(reagent.currencyID)
            total = total + (currencyInfo and currencyInfo.quantity or 0)
        end
    end
    return total
end

local function getRecipeObjectives(recipeID, isRecraft)
    local objectives = {}
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeSchematic then
        return objectives
    end

    local recipeSchematic = getRecipeSchematic(recipeID, isRecraft)
    if not recipeSchematic or not recipeSchematic.reagentSlotSchematics then
        return objectives
    end

    local eligibleSlots = {}
    for slotIndex, reagentSlotSchematic in ipairs(recipeSchematic.reagentSlotSchematics) do
        if isReagentSlotRequired(reagentSlotSchematic) then
            local entry = { slotIndex = slotIndex, reagentSlotSchematic = reagentSlotSchematic }
            if isReagentSlotModifyingRequired(reagentSlotSchematic) then
                table.insert(eligibleSlots, 1, entry)
            else
                eligibleSlots[#eligibleSlots + 1] = entry
            end
        end
    end

    local reagentFormat = PROFESSIONS_TRACKER_REAGENT_FORMAT or '%s %s'
    local countFormat = PROFESSIONS_TRACKER_REAGENT_COUNT_FORMAT or '%d/%d'
    local rangeFormat = PROFESSIONS_TRACKER_REAGENT_RANGE_FORMAT or '%d-%d'

    for _, slot in ipairs(eligibleSlots) do
        local reagentSlotSchematic = slot.reagentSlotSchematic
        local reagent = reagentSlotSchematic.reagents and reagentSlotSchematic.reagents[1]
        if reagent then
            local name
            if isReagentSlotBasicRequired(reagentSlotSchematic) then
                name = getReagentName(reagent)
            elseif isReagentSlotModifyingRequired(reagentSlotSchematic) and reagentSlotSchematic.slotInfo then
                name = reagentSlotSchematic.slotInfo.slotText
            end

            if name and name ~= '' then
                local text
                local finished = false
                if reagentSlotSchematic.IsVariableQuantityReagent
                    and reagentSlotSchematic:IsVariableQuantityReagent(reagent) then
                    local minQuantity, maxQuantity = reagentSlotSchematic:GetVariableQuantityRange(reagent)
                    text = reagentFormat:format(rangeFormat:format(minQuantity, maxQuantity), name)
                else
                    local quantityRequired = getReagentQuantityRequired(reagentSlotSchematic, reagent)
                    local quantity = getReagentQuantityInPossession(reagentSlotSchematic.reagents)
                    text = reagentFormat:format(countFormat:format(quantity, quantityRequired), name)
                    finished = quantity >= quantityRequired
                end

                objectives[#objectives + 1] = {
                    text = text,
                    finished = finished,
                }
            end
        end
    end

    return objectives
end

function trackerData:CollectRecipeBlocks()
    local blocks = {}
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipesTracked then
        return blocks
    end

    local function addRecipes(isRecraft)
        local recipes = C_TradeSkillUI.GetRecipesTracked(isRecraft)
        for _, recipeID in ipairs(recipes) do
            local schematic = getRecipeSchematic(recipeID, isRecraft)
            local name = schematic and schematic.name or ('Recipe ' .. recipeID)
            if isRecraft then
                name = PROFESSIONS_CRAFTING_FORM_RECRAFTING_HEADER and
                    PROFESSIONS_CRAFTING_FORM_RECRAFTING_HEADER:format(name) or name
            end
            addBlock(blocks, {
                id = isRecraft and -recipeID or recipeID,
                categoryId = 'recipes',
                title = name,
                canUntrack = true,
                untrackType = 'recipe',
                untrackId = recipeID,
                untrackRecraft = isRecraft,
                objectives = getRecipeObjectives(recipeID, isRecraft),
            })
        end
    end
    addRecipes(true)
    addRecipes(false)
    return blocks
end

function trackerData:CollectAdventureBlocks()
    local blocks = {}
    if not C_ContentTracking.GetCollectableSourceTypes then
        return blocks
    end
    for _, trackableType in ipairs(C_ContentTracking.GetCollectableSourceTypes()) do
        local trackedIDs = C_ContentTracking.GetTrackedIDs(trackableType)
        for _, trackableID in ipairs(trackedIDs) do
            local title = C_ContentTracking.GetTitle(trackableType, trackableID) or ('Trackable ' .. trackableID)
            addBlock(blocks, {
                id = trackableID,
                categoryId = 'adventure',
                title = title,
                canUntrack = true,
                untrackType = 'adventure',
                untrackTrackableType = trackableType,
                untrackId = trackableID,
                objectives = {},
            })
        end
    end
    return blocks
end

function trackerData:CollectActivitiesBlocks()
    local blocks = {}
    if not C_PerksActivities or not C_PerksActivities.GetTrackedPerksActivities then
        return blocks
    end
    local tracked = C_PerksActivities.GetTrackedPerksActivities().trackedIDs
    for _, activityID in ipairs(tracked) do
        local info = C_PerksActivities.GetPerksActivityInfo(activityID)
        if info and not info.completed then
            local objectives = {}
            if info.requirementsList then
                for _, req in ipairs(info.requirementsList) do
                    if not req.completed and req.requirementText then
                        objectives[#objectives + 1] = {
                            text = req.requirementText,
                            finished = false,
                        }
                    end
                end
            end
            addBlock(blocks, {
                id = activityID,
                categoryId = 'activities',
                title = info.activityName or ('Activity ' .. activityID),
                canUntrack = true,
                untrackType = 'activities',
                untrackId = activityID,
                objectives = objectives,
            })
        end
    end
    return blocks
end

function trackerData:CollectInitiativeBlocks()
    local blocks = {}
    if not C_NeighborhoodInitiative or not C_NeighborhoodInitiative.GetTrackedInitiativeTasks then
        return blocks
    end
    local tracked = C_NeighborhoodInitiative.GetTrackedInitiativeTasks().trackedIDs
    for _, taskID in ipairs(tracked) do
        local info = C_NeighborhoodInitiative.GetInitiativeTaskInfo(taskID)
        if info and not info.completed then
            local objectives = {}
            if info.requirementsList then
                for _, req in ipairs(info.requirementsList) do
                    if not req.completed and req.requirementText then
                        objectives[#objectives + 1] = {
                            text = req.requirementText,
                            finished = false,
                        }
                    end
                end
            end
            addBlock(blocks, {
                id = taskID,
                categoryId = 'initiative',
                title = info.taskName or ('Task ' .. taskID),
                canUntrack = true,
                untrackType = 'initiative',
                untrackId = taskID,
                objectives = objectives,
            })
        end
    end
    return blocks
end

function trackerData:GetChallengeModeTimerID()
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

function trackerData:IsInMythicPlus()
    return C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
end

function trackerData:GetChallengeModeInfo()
    if not self:IsInMythicPlus() then
        return nil
    end

    local mapID = C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID()
    if not mapID then
        return nil
    end

    local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
    if not timeLimit or timeLimit <= 0 then
        return nil
    end

    local level = C_ChallengeMode.GetActiveKeystoneInfo and select(1, C_ChallengeMode.GetActiveKeystoneInfo()) or 0
    local levelText
    if CHALLENGE_MODE_POWER_LEVEL then
        levelText = CHALLENGE_MODE_POWER_LEVEL:format(level)
    else
        levelText = string.format('+%d', level)
    end

    return {
        level = level,
        levelText = levelText,
        timerID = self:GetChallengeModeTimerID(),
        timeLimit = timeLimit,
    }
end

function trackerData:FormatDelveTierText(tierText, tier)
    if tierText and tierText ~= '' then
        local numericTier = tonumber(tierText)
        if numericTier then
            if RECENT_ALLY_DELVE_TIER_LABEL then
                return RECENT_ALLY_DELVE_TIER_LABEL:format(numericTier)
            end
            return string.format('Tier %d', numericTier)
        end
        return tierText
    end

    if tier then
        if RECENT_ALLY_DELVE_TIER_LABEL then
            return RECENT_ALLY_DELVE_TIER_LABEL:format(tier)
        end
        return string.format('Tier %d', tier)
    end

    return nil
end

function trackerData:CollectDelveCurrencies(info)
    local currencies = acquireTable()
    if not info or not info.currencies then
        return currencies
    end

    for _, currencyInfo in ipairs(info.currencies) do
        local hasText = (currencyInfo.text and currencyInfo.text ~= '')
            or (currencyInfo.leadingText and currencyInfo.leadingText ~= '')
        local hasIcon = currencyInfo.iconFileID and currencyInfo.iconFileID ~= 0
        if hasText or hasIcon then
            local currency = acquireTable()
            currency.iconFileID = currencyInfo.iconFileID
            currency.text = currencyInfo.text
            currency.leadingText = currencyInfo.leadingText
            currency.tooltip = currencyInfo.tooltip
            currency.isCurrencyMaxed = currencyInfo.isCurrencyMaxed
            currencies[#currencies + 1] = currency
        end
    end

    return currencies
end

function trackerData:GetScenarioHeaderDelvesInfo(widgetSetID)
    if not widgetSetID
        or not C_UIWidgetManager
        or not C_UIWidgetManager.GetAllWidgetsBySetID
        or not C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo
        or not Enum
        or not Enum.UIWidgetVisualizationType
        or not Enum.WidgetShownState then
        return nil
    end

    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(widgetSetID)
    if not widgets then
        return nil
    end

    for _, widget in ipairs(widgets) do
        if widget.widgetType == Enum.UIWidgetVisualizationType.ScenarioHeaderDelves then
            local info = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(widget.widgetID)
            if info and info.shownState ~= Enum.WidgetShownState.Hidden then
                local tierText = self:FormatDelveTierText(info.tierText)
                local currencies = self:CollectDelveCurrencies(info)
                if tierText or #currencies > 0 then
                    local delve = acquireTable()
                    delve.widgetID = widget.widgetID
                    delve.tierText = tierText
                    delve.currencies = currencies
                    return delve
                end
                recycleCurrencies(currencies)
            end
        end
    end

    return nil
end

function trackerData:GetScenarioHeaderDelvesInfoByWidgetID(widgetID)
    if not widgetID
        or not C_UIWidgetManager
        or not C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo
        or not Enum
        or not Enum.WidgetShownState then
        return nil
    end

    local info = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(widgetID)
    if not info or info.shownState == Enum.WidgetShownState.Hidden then
        return nil
    end

    local tierText = self:FormatDelveTierText(info.tierText)
    local currencies = self:CollectDelveCurrencies(info)
    if tierText or #currencies > 0 then
        local delve = acquireTable()
        delve.widgetID = widgetID
        delve.tierText = tierText
        delve.currencies = currencies
        return delve
    end

    recycleCurrencies(currencies)
    return nil
end

function trackerData:GetActiveDelveInfo()
    if not C_DelvesUI or not C_DelvesUI.HasActiveDelve or not C_DelvesUI.HasActiveDelve() then
        return nil
    end

    local tierInfo = C_DelvesUI.GetActiveDelveTier and C_DelvesUI.GetActiveDelveTier()
    if not tierInfo or not tierInfo.tier then
        return nil
    end

    local tierText = self:FormatDelveTierText(nil, tierInfo.tier)
    if not tierText then
        return nil
    end

    return {
        tier = tierInfo.tier,
        tierText = tierText,
    }
end

function trackerData:GetScenarioHeaderTimerInfo(widgetSetID)
    if not widgetSetID
        or not C_UIWidgetManager
        or not C_UIWidgetManager.GetAllWidgetsBySetID
        or not C_UIWidgetManager.GetScenarioHeaderTimerWidgetVisualizationInfo
        or not Enum
        or not Enum.UIWidgetVisualizationType
        or not Enum.WidgetShownState then
        return nil
    end

    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(widgetSetID)
    if not widgets then
        return nil
    end

    for _, widget in ipairs(widgets) do
        if widget.widgetType == Enum.UIWidgetVisualizationType.ScenarioHeaderTimer then
            local info = C_UIWidgetManager.GetScenarioHeaderTimerWidgetVisualizationInfo(widget.widgetID)
            if info and info.shownState ~= Enum.WidgetShownState.Hidden then
                local timerValue = math.max(info.timerMin, math.min(info.timerMax, info.timerValue))
                return {
                    widgetID = widget.widgetID,
                    timeRemaining = math.max(0, timerValue - info.timerMin),
                }
            end
        end
    end

    return nil
end

function trackerData:CollectScenarioBlocks()
    local blocks = {}
    if not C_Scenario or not C_Scenario.IsInScenario or not C_Scenario.IsInScenario() then
        return blocks
    end

    local name, currentStage, numStages = C_Scenario.GetInfo()
    if not name then
        return blocks
    end

    local stageName, stageDescription, numCriteria, _, _, _, _, _, _, weightedProgress, _, widgetSetID = C_Scenario.GetStepInfo()
    local showCriteria = not C_Scenario.ShouldShowCriteria or C_Scenario.ShouldShowCriteria()
    local objectives = {}

    if showCriteria and not weightedProgress and numCriteria and numCriteria > 0
        and C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo then
        for criteriaIndex = 1, numCriteria do
            local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
            if criteriaInfo then
                local criteriaString = criteriaInfo.description
                if not criteriaInfo.isWeightedProgress and not criteriaInfo.isFormatted then
                    criteriaString = string.format('%d/%d %s', criteriaInfo.quantity, criteriaInfo.totalQuantity, criteriaInfo.description)
                end

                local showProgressBar = criteriaInfo.isWeightedProgress and not criteriaInfo.completed
                objectives[#objectives + 1] = {
                    text = criteriaString,
                    finished = criteriaInfo.completed,
                    failed = criteriaInfo.failed,
                    showProgressBar = showProgressBar,
                    progressPercent = showProgressBar and criteriaInfo.quantity or nil,
                }
            end
        end
    end

    local headerTimer = self:GetScenarioHeaderTimerInfo(widgetSetID)
    local delve = self:GetScenarioHeaderDelvesInfo(widgetSetID) or self:GetActiveDelveInfo()
    local stage
    if (currentStage and numStages and numStages > 0) or headerTimer then
        stage = {
            current = currentStage,
            total = numStages,
            title = stageName,
            description = stageDescription,
            weightedProgress = showCriteria and weightedProgress or nil,
            headerTimer = headerTimer,
        }
    end

    addBlock(blocks, {
        id = 'scenario',
        categoryId = 'scenario',
        title = name,
        canUntrack = false,
        widgetSetID = widgetSetID,
        stage = stage,
        delve = delve,
        challengeMode = self:GetChallengeModeInfo(),
        objectives = objectives,
    })

    return blocks
end

function trackerData:CollectBonusBlocks()
    local blocks = {}
    -- Bonus/world content often appears via scenario or task quests; keep minimal for now.
    return blocks
end

function trackerData:CollectWorldBlocks()
    local blocks = {}
    local seen = {}
    local candidates = collectAutomaticWorldQuestCandidates()

    for _, questID in ipairs(candidates) do
        if not isQuestWatched(questID) then
            local block = makeWorldQuestBlock(questID, false)
            if block and not seen[questID] then
                seen[questID] = true
                blocks[#blocks + 1] = block
            end
        end
    end
    releaseTable(candidates)

    local trackedQuestIDs = {}
    if C_QuestLog.GetNumWorldQuestWatches then
        for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
            local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
            if questID and not seen[questID] then
                trackedQuestIDs[#trackedQuestIDs + 1] = questID
            end
        end
    end

    sortWorldQuestIDs(trackedQuestIDs)
    for _, questID in ipairs(trackedQuestIDs) do
        local block = makeWorldQuestBlock(questID, true)
        if block then
            seen[questID] = true
            blocks[#blocks + 1] = block
        end
    end

    return blocks
end

local COLLECTORS = {
    scenario = function(self) return self:CollectScenarioBlocks() end,
    widget = function() return {} end,
    campaign = function(self) return self:CollectQuestBlocks('campaign', isCampaignQuest) end,
    quests = function(self) return self:CollectQuestBlocks('quests', shouldShowStandardQuest) end,
    adventure = function(self) return self:CollectAdventureBlocks() end,
    achievement = function(self) return self:CollectAchievementBlocks() end,
    activities = function(self) return self:CollectActivitiesBlocks() end,
    initiative = function(self) return self:CollectInitiativeBlocks() end,
    recipes = function(self) return self:CollectRecipeBlocks() end,
    bonus = function(self) return self:CollectBonusBlocks() end,
    world = function(self) return self:CollectWorldBlocks() end,
}

function trackerData:GetScenarioCategoryLabel()
    if not C_Scenario or not C_Scenario.IsInScenario or not C_Scenario.IsInScenario() then
        return nil
    end

    local scenarioType = select(10, C_Scenario.GetInfo())
    local isDungeonScenario = scenarioType == LE_SCENARIO_TYPE_USE_DUNGEON_DISPLAY
        or scenarioType == LE_SCENARIO_TYPE_CHALLENGE_MODE
    local isChallengeModeActive = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive
        and C_ChallengeMode.IsChallengeModeActive()

    if isDungeonScenario or isChallengeModeActive then
        return TRACKER_HEADER_DUNGEON or 'Dungeon'
    end

    return nil
end

function trackerData:GetCategoryTitle(entry, db)
    local override = db.categoryTitles and db.categoryTitles[entry.id]
    if override and override ~= '' then
        return override
    end
    if entry.id == 'scenario' then
        local scenarioLabel = self:GetScenarioCategoryLabel()
        if scenarioLabel then
            return scenarioLabel
        end
    end
    return entry.label
end

function trackerData:ShouldShowCategory(entry, db)
    if db.activeFilter ~= defaults.FILTER_ALL and db.activeFilter ~= entry.id then
        return false
    end
    return true
end

local QUEST_COLLECTORS = { 'campaign', 'quests', 'world', 'bonus' }
local EVENT_COLLECTORS = {
    QUEST_LOG_UPDATE = QUEST_COLLECTORS,
    QUEST_WATCH_LIST_CHANGED = QUEST_COLLECTORS,
    QUEST_ACCEPTED = QUEST_COLLECTORS,
    QUEST_AUTOCOMPLETE = QUEST_COLLECTORS,
    QUEST_TURNED_IN = QUEST_COLLECTORS,
    QUEST_REMOVED = QUEST_COLLECTORS,
    QUEST_POI_UPDATE = QUEST_COLLECTORS,
    TASK_PROGRESS_UPDATE = QUEST_COLLECTORS,
    SUPER_TRACKING_CHANGED = QUEST_COLLECTORS,
    SUPER_TRACKING_PATH_UPDATED = QUEST_COLLECTORS,
    CONTENT_TRACKING_UPDATE = { 'achievement', 'adventure' },
    TRACKED_ACHIEVEMENT_LIST_CHANGED = { 'achievement' },
    TRACKED_ACHIEVEMENT_UPDATE = { 'achievement' },
    TRACKED_RECIPE_UPDATE = { 'recipes' },
    BAG_UPDATE_DELAYED = { 'recipes' },
    CURRENCY_DISPLAY_UPDATE = { 'recipes', 'scenario' },
    SCENARIO_UPDATE = { 'scenario' },
    SCENARIO_CRITERIA_UPDATE = { 'scenario' },
    UPDATE_UI_WIDGET = { 'scenario' },
    ACTIVE_DELVE_DATA_UPDATE = { 'scenario' },
    CHALLENGE_MODE_START = { 'scenario' },
    CHALLENGE_MODE_COMPLETED = { 'scenario' },
    CHALLENGE_MODE_RESET = { 'scenario' },
    WORLD_STATE_TIMER_START = { 'scenario' },
    WORLD_STATE_TIMER_STOP = { 'scenario' },
    PERKS_ACTIVITIES_TRACKED_LIST_CHANGED = { 'activities' },
    PERKS_ACTIVITIES_TRACKED_UPDATED = { 'activities' },
}

function trackerData:InvalidateCategoryCache()
    if self.blocksByCategory then
        for _, blocks in pairs(self.blocksByCategory) do
            recycleCategoryBlocks(blocks)
        end
    end
    if self.autoQuestPopUpBlocks then
        for i = 1, #self.autoQuestPopUpBlocks do
            local block = self.autoQuestPopUpBlocks[i]
            if block then
                recycleObjectives(block.objectives)
                block.objectives = nil
            end
        end
        releaseTable(self.autoQuestPopUpBlocks)
    end
    self.categoryCacheValid = false
    self.blocksByCategory = nil
    self.autoQuestPopUpBlocks = nil
    self.cachedPresent = nil
    self.cachedPresentCount = 0
    self.staleCollectors = nil
    self.cachedCategories = nil
    self.cachedCategoriesFilter = nil
    self.cachedCategoriesTitles = nil
    self.cacheGeneration = (self.cacheGeneration or 0) + 1
end

function trackerData:InvalidateCollectors(collectorIds)
    if not collectorIds then
        self:InvalidateCategoryCache()
        return
    end

    self.staleCollectors = self.staleCollectors or {}
    for _, collectorId in ipairs(collectorIds) do
        self.staleCollectors[collectorId] = true
    end

    self.categoryCacheValid = false
    self.cachedPresent = nil
    self.cachedPresentCount = 0
    self.cachedCategories = nil
end

function trackerData:InvalidateForEvent(event)
    if not event then
        self:InvalidateCategoryCache()
        return
    end

    local collectors = EVENT_COLLECTORS[event]
    if collectors then
        self:InvalidateCollectors(collectors)
        return
    end

    if event == 'ENCOUNTER_START' or event == 'ENCOUNTER_END' then
        self.cachedCategories = nil
        return
    end

    self:InvalidateCategoryCache()
end

function trackerData:RefreshCategoryCache()
    if self.categoryCacheValid and self.blocksByCategory then
        return
    end

    local blocksByCategory = self.blocksByCategory or {}
    local stale = self.staleCollectors
    local refreshAll = not stale or not next(stale)
    local refreshQuests = refreshAll or (stale and (stale.campaign or stale.quests or stale.world or stale.bonus))

    if refreshQuests and self.autoQuestPopUpBlocks then
        for i = 1, #self.autoQuestPopUpBlocks do
            local block = self.autoQuestPopUpBlocks[i]
            if block then
                recycleObjectives(block.objectives)
                block.objectives = nil
            end
        end
        releaseTable(self.autoQuestPopUpBlocks)
        self.autoQuestPopUpBlocks = nil
    end

    local present = {}
    local count = 0
    for _, entry in ipairs(defaults.MODULE_ENTRIES) do
        local shouldRefresh = refreshAll or (stale and stale[entry.id])
        if shouldRefresh or not blocksByCategory[entry.id] then
            recycleCategoryBlocks(blocksByCategory[entry.id])
            local collector = COLLECTORS[entry.id]
            blocksByCategory[entry.id] = collector and collector(self) or {}
        end
        local blocks = blocksByCategory[entry.id]
        if blocks and #blocks > 0 then
            present[entry.id] = true
            count = count + 1
        end
    end

    self.blocksByCategory = blocksByCategory
    self.cachedPresent = present
    self.cachedPresentCount = count
    self.staleCollectors = nil
    self.categoryCacheValid = true
    self.cacheGeneration = (self.cacheGeneration or 0) + 1
end

function trackerData:GetPresentCategoryIds()
    self:RefreshCategoryCache()
    return self.cachedPresent, self.cachedPresentCount
end

function trackerData:GetCachedScenarioBlocks()
    self:RefreshCategoryCache()
    return self.blocksByCategory and self.blocksByCategory.scenario
end

function trackerData:GetCategories(db)
    self:RefreshCategoryCache()
    local filter = db.activeFilter
    local titles = db.categoryTitles
    if self.cachedCategories
        and self.cachedCategoriesFilter == filter
        and self.cachedCategoriesTitles == titles
        and self.cachedCategoriesGeneration == self.cacheGeneration then
        for _, category in ipairs(self.cachedCategories) do
            if category.id == 'scenario' then
                local entry = defaults:GetModuleEntry('scenario')
                if entry then
                    category.label = self:GetCategoryTitle(entry, db)
                end
            end
        end
        return self.cachedCategories
    end

    local categories = self.cachedCategories or {}
    wipe(categories)
    for _, entry in ipairs(defaults.MODULE_ENTRIES) do
        if self:ShouldShowCategory(entry, db) then
            local blocks = self.blocksByCategory[entry.id] or {}
            if #blocks > 0 then
                categories[#categories + 1] = {
                    id = entry.id,
                    label = self:GetCategoryTitle(entry, db),
                    blocks = blocks,
                }
            end
        end
    end

    self.cachedCategories = categories
    self.cachedCategoriesFilter = filter
    self.cachedCategoriesTitles = titles
    self.cachedCategoriesGeneration = self.cacheGeneration
    return categories
end

function trackerData:UntrackBlock(block)
    if not block or not block.canUntrack then
        return
    end

    if block.untrackType == 'quest' then
        if block.isWorldQuest and QuestUtil and QuestUtil.UntrackWorldQuest then
            QuestUtil.UntrackWorldQuest(block.untrackId)
        elseif QuestUtil and QuestUtil.CanRemoveQuestWatch and QuestUtil.CanRemoveQuestWatch() then
            C_QuestLog.RemoveQuestWatch(block.untrackId)
        end
    elseif block.untrackType == 'achievement' then
        C_ContentTracking.StopTracking(Enum.ContentTrackingType.Achievement, block.untrackId, Enum.ContentTrackingStopType.Manual)
    elseif block.untrackType == 'recipe' then
        C_TradeSkillUI.SetRecipeTracked(block.untrackId, false, block.untrackRecraft)
    elseif block.untrackType == 'adventure' then
        C_ContentTracking.StopTracking(block.untrackTrackableType, block.untrackId, Enum.ContentTrackingStopType.Manual)
    elseif block.untrackType == 'activities' then
        C_PerksActivities.RemoveTrackedPerksActivity(block.untrackId)
    elseif block.untrackType == 'initiative' then
        C_NeighborhoodInitiative.RemoveTrackedInitiativeTask(block.untrackId)
    end

    self:InvalidateCategoryCache()
end
