---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIObjectiveTrackerDefaults
local defaults = EXUI:GetModule('objective-tracker-defaults')

---@class EXUIObjectiveTrackerDisplay
local display = EXUI:GetModule('objective-tracker-display')

---@class EXUIObjectiveTrackerGeneralOptions
local generalOptions = EXUI:GetModule('objective-tracker-general-options')

---@class EXUIObjectiveTrackerStyleOptions
local styleOptions = EXUI:GetModule('objective-tracker-style-options')

---@class EXUIObjectiveTrackerModule
local objectiveTracker = EXUI:GetModule('objective-tracker')

objectiveTracker.enabled = false
objectiveTracker.editorShowing = false
objectiveTracker.useTabs = true

objectiveTracker.Init = function(self)
    self.Data:UpdateDefaults(defaults:GetDefaults())
    optionsController:RegisterModule(self)

    if self.Data:GetValue('enable') then
        EXUI:RegisterEventHandler('PLAYER_ENTERING_WORLD', 'objective-tracker-enable', function()
            EXUI:UnregisterEventHandler('PLAYER_ENTERING_WORLD', 'objective-tracker-enable')
            C_Timer.After(0, function()
                if self.Data:GetValue('enable') then
                    self:Enable()
                end
            end)
        end)
    else
        self:Disable()
    end
end

objectiveTracker.Data = data:GetControlsForKey('objectiveTracker')

objectiveTracker.GetName = function(self)
    return 'Objective Tracker'
end

objectiveTracker.GetCategory = function(self)
    return 'Quality of Life'
end

objectiveTracker.GetOrder = function(self)
    return 30
end

objectiveTracker.GetProfileExportSpec = function(self)
    return { id = 'objective-tracker', keys = { 'objectiveTracker' } }
end

objectiveTracker.GetTabs = function(self)
    return {
        { ID = 'general', label = 'General' },
        { ID = 'style', label = 'Style' },
    }
end

objectiveTracker.GetOptions = function(self, currTabID)
    if currTabID == 'style' then
        return styleOptions:GetOptions()
    end
    return generalOptions:GetOptions()
end

objectiveTracker.RegisterEditor = function(self)
    display:CreateMainFrame()
    local frame = display.frame
    if not frame or editor:IsFrameRegistered(frame) then
        return
    end

    editor:RegisterFrameForEditor(frame, 'Objective Tracker', function()
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

objectiveTracker.UnregisterEditor = function(self)
    if display.frame then
        editor:UnregisterFrameForEditor(display.frame)
    end
end

objectiveTracker.Update = function(self)
    if not self.enabled then
        return
    end
    display:Update()
end

objectiveTracker.Configure = function(self)
    self:Update()
end

objectiveTracker.Enable = function(self)
    if self.enabled then
        return
    end

    self.enabled = true
    display:Enable()
    self:RegisterEditor()
    self:Update()
end

objectiveTracker.Disable = function(self)
    if not self.enabled then
        return
    end

    self.enabled = false
    self:UnregisterEditor()
    display:Disable()
end

objectiveTracker.ManagesObjectiveTrackerFonts = function(self)
    return self.enabled
end
