---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIObjectiveTrackerDefaults
local defaults = EXUI:GetModule('objective-tracker-defaults')

defaults.FILTER_ALL = 'all'

defaults.MODULE_ENTRIES = {
    { id = 'scenario',    frameName = 'ScenarioObjectiveTracker',           label = 'Scenario',     shortLabel = 'S',  canUntrack = false, chipEnabled = true },
    { id = 'widget',      frameName = 'UIWidgetObjectiveTracker',           label = 'Widget',       shortLabel = 'W',  canUntrack = false, chipEnabled = false },
    { id = 'world',       frameName = 'WorldQuestObjectiveTracker',         label = 'World',        shortLabel = 'WQ', canUntrack = false, chipEnabled = true },
    { id = 'campaign',    frameName = 'CampaignQuestObjectiveTracker',      label = 'Campaign',     shortLabel = 'C',  canUntrack = true,  chipEnabled = true,  untrackType = 'quest' },
    { id = 'quests',      frameName = 'QuestObjectiveTracker',              label = 'Quests',       shortLabel = 'Q',  canUntrack = true,  chipEnabled = true,  untrackType = 'quest' },
    { id = 'adventure',   frameName = 'AdventureObjectiveTracker',          label = 'Adventure',    shortLabel = 'A',  canUntrack = true,  chipEnabled = true,  untrackType = 'adventure' },
    { id = 'achievement', frameName = 'AchievementObjectiveTracker',        label = 'Achievements', shortLabel = 'Ach', canUntrack = true, chipEnabled = true,  untrackType = 'achievement' },
    { id = 'activities',  frameName = 'MonthlyActivitiesObjectiveTracker',  label = 'Activities',   shortLabel = 'Act', canUntrack = true, chipEnabled = false, untrackType = 'activities' },
    { id = 'initiative',  frameName = 'InitiativeTasksObjectiveTracker',    label = 'Initiative',   shortLabel = 'I',  canUntrack = true,  chipEnabled = false, untrackType = 'initiative' },
    { id = 'recipes',     frameName = 'ProfessionsRecipeTracker',           label = 'Recipes',      shortLabel = 'R',  canUntrack = true,  chipEnabled = true,  untrackType = 'recipe' },
    { id = 'bonus',       frameName = 'BonusObjectiveTracker',              label = 'Bonus',        shortLabel = 'B',  canUntrack = false, chipEnabled = true },
}

defaults.DEFAULT_COLORS = {
    Normal = { r = 0.8, g = 0.8, b = 0.8, a = 1 },
    NormalHighlight = { r = 1, g = 1, b = 1, a = 1 },
    Failed = { r = 0.5, g = 0.1, b = 0.1, a = 1 },
    FailedHighlight = { r = 1, g = 0.1, b = 0.1, a = 1 },
    Header = { r = 0.75, g = 0.61, b = 0, a = 1 },
    HeaderHighlight = { r = 1, g = 1, b = 1, a = 1 },
    CategoryHeader = { r = 0.75, g = 0.61, b = 0, a = 1 },
    CategoryHeaderHighlight = { r = 1, g = 1, b = 1, a = 1 },
    BlockHeader = { r = 0.75, g = 0.61, b = 0, a = 1 },
    BlockHeaderHighlight = { r = 1, g = 1, b = 1, a = 1 },
    Complete = { r = 0.6, g = 0.6, b = 0.6, a = 1 },
    TimeLeft = { r = 0.5, g = 0.1, b = 0.1, a = 1 },
    TimeLeftHighlight = { r = 1, g = 0.1, b = 0.1, a = 1 },
}

defaults.SPACING_DEFAULTS = {
    lineSpacing = 4,
    fromHeaderOffsetY = -10,
    fromBlockOffsetY = -10,
    blockOffsetX = 0,
    headerHeight = 25,
    headerPaddingX = 6,
    headerPaddingY = 4,
    moduleSpacing = 10,
}

function defaults:CopyTable(value)
    return EXUI.utils.deepCloneTable(value)
end

function defaults:GetModuleFrame(entry)
    if type(entry) == 'string' then
        for _, moduleEntry in ipairs(self.MODULE_ENTRIES) do
            if moduleEntry.id == entry then
                entry = moduleEntry
                break
            end
        end
    end
    if type(entry) ~= 'table' then
        return nil
    end
    return _G[entry.frameName]
end

function defaults:GetModuleEntry(id)
    for _, entry in ipairs(self.MODULE_ENTRIES) do
        if entry.id == id then
            return entry
        end
    end
end

function defaults:GetDefaults()
    local categoryTitles = {}
    local chipEnabled = {}
    for _, entry in ipairs(self.MODULE_ENTRIES) do
        categoryTitles[entry.id] = ''
        chipEnabled[entry.id] = entry.chipEnabled
    end

    return {
        enable = false,
        activeFilter = self.FILTER_ALL,
        anchorPoint = 'TOPRIGHT',
        relativeAnchor = 'TOPRIGHT',
        xOffset = -10,
        yOffset = -200,
        maxHeight = 800,
        width = 260,
        categorySpacing = 10,
        textAlign = 'LEFT',
        hideContainerHeader = false,
        hideCollapseButtons = false,
        hideModuleMinimizeButtons = false,
        showCategoryChips = true,
        showBackground = true,
        backgroundOpacity = 85,
        panelBackgroundColor = { r = 23 / 255, g = 20 / 255, b = 18 / 255, a = 0.85 },
        panelBorderColor = { r = 61 / 255, g = 53 / 255, b = 48 / 255, a = 1 },
        panelBorderThickness = 1,
        autoHideWhenEmpty = false,
        hideOnEncounter = false,
        hideInMythicPlus = false,
        hideQuestPOI = false,
        rememberCollapsedModules = false,
        containerCollapsed = false,
        collapsedModules = {},
        superTrackColor = { r = 1, g = 0.82, b = 0, a = 1 },
        containerTitle = '',
        categoryTitles = categoryTitles,
        chipEnabled = chipEnabled,
        customHeaderStyle = true,
        headerBackgroundColor = { r = 23 / 255, g = 20 / 255, b = 18 / 255, a = 0.85 },
        headerBorderColor = { r = 61 / 255, g = 53 / 255, b = 48 / 255, a = 1 },
        headerBorderThickness = 1,
        showCategoryHeaderLine = true,
        categoryHeaderLineColor = {
            r = EXUI.const.theme.accent[1],
            g = EXUI.const.theme.accent[2],
            b = EXUI.const.theme.accent[3],
            a = EXUI.const.theme.accent[4] or 1,
        },
        categoryHeaderLineThickness = 1,
        containerFont = 'DMSans',
        containerFontSize = 14,
        containerFontFlag = 'OUTLINE',
        moduleHeaderFont = 'DMSans',
        moduleHeaderFontSize = 14,
        moduleHeaderFontFlag = 'OUTLINE',
        blockHeaderFont = 'DMSans',
        blockHeaderFontSize = 13,
        blockHeaderFontFlag = 'OUTLINE',
        lineFont = 'DMSans',
        lineFontSize = 12,
        lineFontFlag = 'OUTLINE',
        progressBarHeight = 12,
        progressBarBorderThickness = 1,
        progressBarFillColor = {
            r = EXUI.const.theme.accent[1],
            g = EXUI.const.theme.accent[2],
            b = EXUI.const.theme.accent[3],
            a = EXUI.const.theme.accent[4] or 1,
        },
        progressBarBackgroundColor = {
            r = EXUI.const.theme.backgroundDeep[1],
            g = EXUI.const.theme.backgroundDeep[2],
            b = EXUI.const.theme.backgroundDeep[3],
            a = EXUI.const.theme.backgroundDeep[4] or 1,
        },
        progressBarBorderColor = {
            r = EXUI.const.theme.border[1],
            g = EXUI.const.theme.border[2],
            b = EXUI.const.theme.border[3],
            a = EXUI.const.theme.border[4] or 1,
        },
        colors = self:CopyTable(self.DEFAULT_COLORS),
    }
end
