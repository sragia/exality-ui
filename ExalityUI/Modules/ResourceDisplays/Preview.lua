---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIOptionsMain
local optionsMain = EXUI:GetModule('options-main')

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

local MODULE_NAME = 'Resource Displays'

preview.toggled = {}
preview.manual = {}
preview.userDisabled = {}
preview.scenario = 'mid'

-- Legacy flag kept in sync for existing call sites.
preview.enabled = false

preview.MOCK_VALUES = {
    ['Energy'] = { empty = 0, mid = 50, full = 100 },
    ['Mana'] = { empty = 0, mid = 50, full = 100 },
    ['Rage'] = { empty = 0, mid = 50, full = 100 },
    ['Focus'] = { empty = 0, mid = 50, full = 100 },
    ['Runic Power'] = { empty = 0, mid = 50, full = 100 },
    ['Fury'] = { empty = 0, mid = 50, full = 100 },
    ['Insanity'] = { empty = 0, mid = 50, full = 100 },
    ['Astral Power'] = { empty = 0, mid = 50, full = 100 },
    ['Arcane Charges'] = { empty = 0, mid = 2, full = 4 },
    ['Combo Points'] = { empty = 0, mid = 3, full = 5 },
    ['Holy Power'] = { empty = 0, mid = 3, full = 5 },
    ['Chi'] = { empty = 0, mid = 3, full = 6 },
    ['DK Runes'] = { empty = 0, mid = 3, full = 6 },
    ['Soul Shards'] = { empty = 0, mid = 25, full = 50 },
    ['Stagger'] = { empty = 0, mid = 35, full = 80 },
    ['Maelstrom'] = { empty = 0, mid = 5, full = 10 },
    ['Soul Fragments'] = { empty = 0, mid = 15, full = 30 },
    ['Essence'] = { empty = 0, mid = 3, full = 6 },
    ['Ebon Might'] = { empty = 0, mid = 50, full = 100 },
    ['Devourer Fury'] = { empty = 0, mid = 50, full = 100 },
    ['Balance Eclipse'] = { empty = 0, mid = 50, full = 100 },
    ['Tip of the Spear'] = { empty = 0, mid = 2, full = 5 },
}

function preview:IsOptionsOpen()
    return optionsMain.window and optionsMain.window:IsShown()
end

function preview:IsConfiguring()
    return self:IsOptionsOpen() and optionsController:GetSelectedModuleName() == MODULE_NAME
end

function preview:HasAnyToggled()
    return next(self.toggled) ~= nil
end

function preview:HasActivePreviews()
    return self:IsConfiguring() and self:HasAnyToggled()
end

function preview:IsToggled(displayID)
    return self.toggled[displayID] == true
end

function preview:IsActive(displayID)
    return self:HasActivePreviews() and self:IsToggled(displayID)
end

function preview:ShouldUsePreview(frame)
    if not frame or not frame.displayID then
        return false
    end
    return self:IsActive(frame.displayID)
end

function preview:SyncEnabledFlag()
    self.enabled = self:HasActivePreviews()
end

function preview:Activate(displayID)
    self.scenario = 'mid'
    core:RefreshDisplayByID(displayID)
end

function preview:Deactivate(displayID)
    core:RefreshDisplayByID(displayID)
end

function preview:SetToggled(displayID, enabled, manual)
    if enabled then
        self.userDisabled[displayID] = nil
        self.toggled[displayID] = true
        if manual then
            self.manual[displayID] = true
        end
        self:SyncEnabledFlag()
        self:Activate(displayID)
        self:RefreshNonPreviewFrames()
        return
    end

    self.toggled[displayID] = nil
    self.manual[displayID] = nil
    if manual then
        self.userDisabled[displayID] = true
    end
    self:SyncEnabledFlag()
    self:Deactivate(displayID)
    self:RefreshNonPreviewFrames()
end

function preview:ClearAutoPreviews(exceptID)
    local remove = {}
    for displayID in pairs(self.toggled) do
        if displayID ~= exceptID and not self.manual[displayID] then
            remove[#remove + 1] = displayID
        end
    end
    for _, displayID in ipairs(remove) do
        self:SetToggled(displayID, false)
    end
end

function preview:RefreshNonPreviewFrames()
    for displayID in pairs(core.frames) do
        if not self.toggled[displayID] then
            core:RefreshDisplayByID(displayID)
        end
    end
end

function preview:Clear()
    local hadAny = self:HasAnyToggled()
    wipe(self.toggled)
    wipe(self.manual)
    wipe(self.userDisabled)
    self:SyncEnabledFlag()
    if hadAny then
        -- Drop mock values and re-apply live visibility/load rules.
        core:RefreshAllFrames()
    end
    core:TeardownOptionsChrome()
end

function preview:SyncPreviewToggles()
    if optionsFields.splitView and optionsFields.splitView.SyncPreviewToggles then
        optionsFields.splitView:SyncPreviewToggles(function(id)
            return preview:IsToggled(id)
        end)
    end
end

function preview:HookSplitViewSelection(splitView)
    if not splitView or splitView._exuiResourcePreviewSelectHooked then
        return
    end
    splitView._exuiResourcePreviewSelectHooked = true

    local previous = splitView.onItemChange
    splitView.onItemChange = function(id)
        preview.userDisabled[id] = nil
        if previous then
            previous(id)
        end
    end
end

function preview:Sync()
    if not self:IsConfiguring() then
        self:Clear()
        return
    end

    local itemID = optionsFields.currItemID
    self:ClearAutoPreviews(itemID)

    local currentDisplay = itemID and core:GetDBByDisplayID(itemID)
    if itemID and currentDisplay and currentDisplay.resourceType and not self.userDisabled[itemID] then
        if not self.toggled[itemID] then
            self:SetToggled(itemID, true)
        end
    end

    for displayID in pairs(self.toggled) do
        local display = core:GetDBByDisplayID(displayID)
        if not display or not display.resourceType then
            self.toggled[displayID] = nil
            self.manual[displayID] = nil
            self:Deactivate(displayID)
        else
            self:Activate(displayID)
        end
    end

    self:SyncEnabledFlag()
    self:SyncPreviewToggles()
end

-- Kept for older call sites; prefer SetToggled.
function preview:SetActiveDisplay(_displayID)
end

function preview:SetEnabled(enabled)
    if not enabled then
        self:Clear()
        return
    end

    local itemID = optionsFields.currItemID
    if itemID then
        self:SetToggled(itemID, true)
    end
end

function preview:GetPreviewDisplayID()
    return optionsFields.currItemID
end

function preview:GetMockValue(resourceType, scenario)
    local values = self.MOCK_VALUES[resourceType]
    if not values then
        return 50
    end
    scenario = scenario or self.scenario
    return values[scenario] or values.mid or 50
end

function preview:GetMockMax(resourceType)
    local values = self.MOCK_VALUES[resourceType]
    if not values then
        return 100
    end
    return values.full or 100
end

function preview:ApplyBarPreview(frame, resourceType)
    if not self:ShouldUsePreview(frame) then
        return false
    end
    local current = self:GetMockValue(resourceType)
    local max = self:GetMockMax(resourceType)
    if frame.StatusBar then
        frame.StatusBar:SetMinMaxValues(0, max)
        frame.StatusBar:SetValue(current)
    end
    if frame.Text and frame.db and frame.db.showText then
        local helpers = EXUI:GetModule('resource-displays-helpers')
        frame.Text:SetText(helpers:FormatPowerText(frame.db.textFormat, current, max))
        frame.Text:Show()
    end
    return true
end

function preview:ApplySegmentPreview(frame, resourceType, config)
    if not self:ShouldUsePreview(frame) then
        return false
    end
    local count = self:GetMockValue(resourceType)
    local segmentBase = EXUI:GetModule('resource-displays-segment-base')
    segmentBase:UpdateSegmentRow(frame, config, function()
        return self:GetMockMax(resourceType)
    end, nil, function(f, maxCount)
        segmentBase:SetSegmentValues(f.ActiveFrames, count, nil, f.db, config)
    end)
    return true
end

function preview:Init()
    if self.initialized then
        return
    end

    if not optionsController.observable then
        optionsController:Init()
    end

    optionsController:Observe('selectedModule', function()
        preview:Sync()
    end)

    hooksecurefunc(optionsFields, 'AddSplitView', function(self, module)
        if module and module.GetName and module:GetName() == MODULE_NAME then
            preview:HookSplitViewSelection(self.splitView)
        end
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
    if window.exuiResourceDisplaysPreviewHooked then
        return
    end
    window.exuiResourceDisplaysPreviewHooked = true

    local previousOnClose = window.onClose
    window.onClose = function()
        preview:Clear()
        if previousOnClose then
            previousOnClose()
        end
    end

    -- HideWindow fades out first; onClose runs while still shown. Re-clear on
    -- actual hide so mock preview can't stick after the options window is gone.
    window:HookScript('OnHide', function()
        preview:Clear()
    end)
end
