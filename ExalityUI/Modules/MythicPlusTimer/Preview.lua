---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIOptionsMain
local optionsMain = EXUI:GetModule('options-main')

---@class EXUIMythicPlusTimerModule
local mythicPlusTimer = EXUI:GetModule('mythic-plus-timer')

---@class EXUIMythicPlusTimerDisplay
local display = EXUI:GetModule('mythic-plus-timer-display')

---@class EXUIMythicPlusTimerPreview
local preview = EXUI:GetModule('mythic-plus-timer-preview')

local MODULE_NAME = 'M+ Timer'
local PREVIEW_STRATA = 'DIALOG'
local PREVIEW_FRAME_LEVEL = 500

preview.active = false
preview.savedStrata = nil
preview.savedLevel = nil

preview.MOCK = {
    timerID = 1,
    timeLimit = 36 * 60,
    elapsed = 20 * 60 + 30,
    keyLevel = 8,
    levelText = '+8',
    deathCount = 3,
    timeLost = 45,
    showDeathPenalty = true,
    elapsedPercent = (20 * 60 + 30) / (36 * 60),
    milestoneIndex = 1,
    milestoneRemaining = (36 * 60 * 0.60) - (20 * 60 + 30),
    forces = {
        percent = 20.54,
        current = 25,
        total = 100,
    },
    bosses = {
        { encounterID = 1, name = 'Boss 1', killTime = 10 * 60 + 34, order = 1 },
        { encounterID = 2, name = 'Boss 2', killTime = nil, order = 2 },
        { encounterID = 3, name = 'Boss 3', killTime = nil, order = 3 },
        { encounterID = 4, name = 'Boss With Long Name 4', killTime = nil, order = 4 },
    },
}

function preview:IsOptionsOpen()
    return optionsMain.window and optionsMain.window:IsShown()
end

function preview:IsActive()
    return self.active
end

function preview:GetSnapshot()
    if not self.active then
        return nil
    end
    return self.MOCK
end

function preview:ElevateFrame()
    if not display.frame then
        return
    end

    if not self.savedStrata then
        self.savedStrata = display.frame:GetFrameStrata()
        self.savedLevel = display.frame:GetFrameLevel()
    end

    display.frame:SetFrameStrata(PREVIEW_STRATA)
    display.frame:SetFrameLevel(PREVIEW_FRAME_LEVEL)
end

function preview:RestoreFrame()
    if not display.frame or not self.savedStrata then
        return
    end

    display.frame:SetFrameStrata(self.savedStrata)
    display.frame:SetFrameLevel(self.savedLevel or 10)
    self.savedStrata = nil
    self.savedLevel = nil
end

function preview:Activate()
    if not mythicPlusTimer.enabled then
        self:Deactivate()
        return
    end

    self.active = true
    display:CreateMainFrame()
    self:ElevateFrame()
    mythicPlusTimer:Update()
end

function preview:Deactivate()
    if not self.active then
        return
    end

    self.active = false
    self:RestoreFrame()
    mythicPlusTimer:Update()
end

function preview:Sync()
    if not self:IsOptionsOpen()
        or optionsController:GetSelectedModuleName() ~= MODULE_NAME
        or not mythicPlusTimer.enabled then
        self:Deactivate()
        return
    end

    self:Activate()
end

function preview:Init()
    if self.initialized then
        return
    end

    if not optionsController.observable then
        optionsController:Init()
    end

    if not optionsFields.observable and optionsFields.Init then
        optionsFields:Init()
    end

    optionsController:Observe('selectedModule', function()
        preview:Sync()
    end)

    hooksecurefunc(optionsFields, 'RefreshFields', function()
        preview:Sync()
    end)

    hooksecurefunc(optionsFields, 'Refresh', function()
        preview:Sync()
    end)

    hooksecurefunc(optionsMain, 'Show', function()
        C_Timer.After(0, function()
            preview:Sync()
        end)
    end)

    if optionsMain.window then
        self:HookOptionsWindow(optionsMain.window)
    end

    hooksecurefunc(optionsMain, 'CreateWindow', function(self)
        if self.window then
            preview:HookOptionsWindow(self.window)
        end
    end)

    self.initialized = true
end

function preview:HookOptionsWindow(window)
    if window.exuiMythicPlusTimerPreviewHooked then
        return
    end
    window.exuiMythicPlusTimerPreviewHooked = true

    local previousOnClose = window.onClose
    window.onClose = function()
        preview:Deactivate()
        if previousOnClose then
            previousOnClose()
        end
    end
end
