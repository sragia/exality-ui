---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

---@class EXUIResourceDisplaysVisibility
local visibility = EXUI:GetModule('resource-displays-visibility')

visibility.eventFrame = CreateFrame('Frame')
visibility.pendingRefresh = false

function visibility:Init()
    if self.initialized then
        return
    end
    self.initialized = true
    self.eventFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
    self.eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
    self.eventFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
    self.eventFrame:RegisterEvent('UNIT_FLAGS')
    self.eventFrame:SetScript('OnEvent', function()
        local core = EXUI:GetModule('resource-displays-core')
        core:RefreshAllFrames()
    end)
end

function visibility:ShouldShowDisplay(db)
    if not db then
        return false
    end
    return helpers:ShouldShowByVisibilityRule(db.visibilityRule or 'always')
end
