---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

---@class EXUIResourceDisplaysVisibility
local visibility = EXUI:GetModule('resource-displays-visibility')

visibility.eventFrame = CreateFrame('Frame')
visibility.pendingRefresh = false
visibility.pendingCombat = false
visibility.pendingTarget = false

local function ruleCaresAboutCombat(rule)
    return rule == 'inCombat' or rule == 'combatOrTarget'
end

local function ruleCaresAboutTarget(rule)
    return rule == 'withTarget' or rule == 'combatOrTarget'
end

function visibility:Init()
    if self.initialized then
        return
    end
    self.initialized = true
    self.eventFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
    self.eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
    self.eventFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
    self.eventFrame:SetScript('OnEvent', function(_, event)
        visibility:QueueRefresh(event)
    end)
end

function visibility:QueueRefresh(event)
    if event == 'PLAYER_REGEN_DISABLED' or event == 'PLAYER_REGEN_ENABLED' then
        self.pendingCombat = true
    elseif event == 'PLAYER_TARGET_CHANGED' then
        self.pendingTarget = true
    else
        return
    end

    if self.pendingRefresh then
        return
    end

    self.pendingRefresh = true
    C_Timer.After(0, function()
        local combatChanged = visibility.pendingCombat
        local targetChanged = visibility.pendingTarget
        visibility.pendingRefresh = false
        visibility.pendingCombat = false
        visibility.pendingTarget = false

        local core = EXUI:GetModule('resource-displays-core')
        if core.RefreshFramesForVisibility then
            core:RefreshFramesForVisibility(combatChanged, targetChanged)
        else
            core:RefreshAllFrames()
        end
    end)
end

function visibility:ShouldShowDisplay(db)
    if not db then
        return false
    end
    return helpers:ShouldShowByVisibilityRule(db.visibilityRule or 'always')
end

function visibility:DisplayNeedsVisibilityRefresh(db, combatChanged, targetChanged)
    if not db then
        return false
    end
    local rule = db.visibilityRule or 'always'
    if rule == 'always' or rule == 'hidden' then
        return false
    end
    if combatChanged and ruleCaresAboutCombat(rule) then
        return true
    end
    if targetChanged and ruleCaresAboutTarget(rule) then
        return true
    end
    return false
end
