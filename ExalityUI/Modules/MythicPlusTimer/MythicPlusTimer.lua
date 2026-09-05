---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIMythicPlusTimerDefaults
local defaults = EXUI:GetModule('mythic-plus-timer-defaults')

---@class EXUIMythicPlusTimerDisplay
local display = EXUI:GetModule('mythic-plus-timer-display')

---@class EXUIMythicPlusTimerGeneralOptions
local generalOptions = EXUI:GetModule('mythic-plus-timer-general-options')

---@class EXUIMythicPlusTimerStyleOptions
local styleOptions = EXUI:GetModule('mythic-plus-timer-style-options')

---@class EXUIMythicPlusTimerPreview
local preview = EXUI:GetModule('mythic-plus-timer-preview')

---@class EXUIMythicPlusTimerData
local timerData = EXUI:GetModule('mythic-plus-timer-data')

---@class EXUIMythicPlusTimerModule
local mythicPlusTimer = EXUI:GetModule('mythic-plus-timer')

mythicPlusTimer.enabled = false
mythicPlusTimer.editorShowing = false
mythicPlusTimer.useTabs = true

mythicPlusTimer.Init = function(self)
    self.Data:UpdateDefaults(defaults:GetDefaults())
    optionsController:RegisterModule(self)
    preview:Init()

    if self.Data:GetValue('enable') then
        self:Enable()
    else
        self:Disable()
    end
end

mythicPlusTimer.Data = data:GetControlsForKey('mythicPlusTimer')

mythicPlusTimer.GetName = function(self)
    return 'M+ Timer'
end

mythicPlusTimer.GetCategory = function(self)
    return 'Quality of Life'
end

mythicPlusTimer.GetOrder = function(self)
    return 35
end

mythicPlusTimer.GetProfileExportSpec = function(self)
    return { id = 'mythic-plus-timer', keys = { 'mythicPlusTimer' } }
end

mythicPlusTimer.GetTabs = function(self)
    return {
        { ID = 'general', label = 'General' },
        { ID = 'style', label = 'Style' },
    }
end

mythicPlusTimer.GetOptions = function(self, currTabID)
    if currTabID == 'style' then
        return styleOptions:GetOptions()
    end
    return generalOptions:GetOptions()
end

mythicPlusTimer.UpdateOptionsChrome = function(self, optionsFieldsRef)
    preview:Sync()
end

mythicPlusTimer.TeardownOptionsChrome = function(self)
    preview:Deactivate()
end

mythicPlusTimer.RegisterEditor = function(self)
    display:CreateMainFrame()
    local frame = display.frame
    if not frame or editor:IsFrameRegistered(frame) then
        return
    end

    editor:RegisterFrameForEditor(frame, 'M+ Timer', function()
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        self.Data:SetValue('anchorPoint', point)
        self.Data:SetValue('relativeAnchor', relativePoint)
        self.Data:SetValue('xOffset', xOfs)
        self.Data:SetValue('yOffset', yOfs)
    end, function()
        self.editorShowing = true
        frame:Show()
        if frame.editor then
            frame.editor:SetEditorAsMovable()
        end
    end, function()
        self.editorShowing = false
        self:Update()
    end)
end

mythicPlusTimer.UnregisterEditor = function(self)
    if display.frame then
        editor:UnregisterFrameForEditor(display.frame)
    end
end

mythicPlusTimer.Update = function(self)
    if not self.enabled then
        return
    end
    display:InvalidateStyleCache()
    display:Update()
end

mythicPlusTimer.Configure = function(self)
    self:Update()
end

mythicPlusTimer.ShouldSuppressObjectiveTracker = function(self)
    if not self.enabled or self.editorShowing then
        return false
    end

    local db = self.Data:GetDB()
    if not db.hideObjectiveTracker then
        return false
    end

    return preview:IsActive() or timerData:ShouldDisplay()
end

mythicPlusTimer.Enable = function(self)
    if self.enabled then
        return
    end

    self.enabled = true
    display:Enable()
    self:RegisterEditor()
    preview:Sync()
    self:Update()
end

mythicPlusTimer.Disable = function(self)
    if not self.enabled then
        return
    end

    self.enabled = false
    preview:Deactivate()
    self:UnregisterEditor()
    display:Disable()
end
