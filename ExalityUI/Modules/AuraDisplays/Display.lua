---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIAuraDisplaysContainer
local containerModule = EXUI:GetModule('aura-displays-container')

---@class EXUIAuraDisplaysUnitResolver
local unitResolver = EXUI:GetModule('aura-displays-unit-resolver')

---@class EXUIAuraDisplaysDisplay
local displayModule = EXUI:GetModule('aura-displays-display')

---@class EXUIAuraDisplaysModule
local auraDisplays = EXUI:GetModule('aura-displays')

displayModule.frames = {}

function displayModule:CreateFrame(displayID)
    local frame = CreateFrame('Frame', 'EXUIAuraDisplay_' .. displayID, UIParent)
    frame:EnableMouse(false)
    frame.displayID = displayID
    self.frames[displayID] = frame
    return frame
end

function displayModule:DestroyFrame(displayID)
    local frame = self.frames[displayID]
    if not frame then
        return
    end
    if editor:IsFrameRegistered(frame) then
        editor:UnregisterFrameForEditor(frame)
    end
    containerModule:ClearContainer(frame)
    frame:Hide()
    frame:SetParent(nil)
    self.frames[displayID] = nil
end

function displayModule:RegisterEditor(frame, display)
    local function onEditModeChange(editMode)
        local currentDisplay = auraDisplays:GetDisplay(frame.displayID)
        if currentDisplay then
            containerModule:SetEditMode(frame, currentDisplay, editMode)
        end
    end

    if not editor:IsFrameRegistered(frame) then
        editor:RegisterFrameForEditor(
            frame,
            display.name or 'Aura Display',
            function(movedFrame)
                local point, _, relativePoint, x, y = movedFrame:GetPoint(1)
                auraDisplays:UpdateDisplayValue(frame.displayID, 'anchorPoint', point)
                auraDisplays:UpdateDisplayValue(frame.displayID, 'relativePoint', relativePoint)
                auraDisplays:UpdateDisplayValue(frame.displayID, 'XOff', x)
                auraDisplays:UpdateDisplayValue(frame.displayID, 'YOff', y)
            end,
            function()
                onEditModeChange(true)
                frame.editor:SetEditorAsMovable()
            end,
            function()
                onEditModeChange(false)
            end
        )
    else
        editor:UpdateFrameLabel(frame, display.name or 'Aura Display')
    end
end

function displayModule:SyncAllFrameSizes()
    local db = auraDisplays:GetDB()
    for displayID, frame in pairs(self.frames) do
        local display = db.displays and db.displays[displayID]
        if display then
            if containerModule:IsEditMode(frame) then
                containerModule:SetEditMode(frame, display, true)
            else
                containerModule:SyncFrameSize(frame, display, displayID)
            end
        end
    end
end

function displayModule:ShouldSyncDisplayUnit(containerUnit, unitKeys)
    if not containerUnit then
        return false
    end

    for _, key in ipairs(unitKeys) do
        if containerUnit == key then
            return true
        end
    end

    return containerUnit == unitResolver.CUSTOM
end

function displayModule:SyncUnitsForKeys(unitKeys)
    if not unitKeys or #unitKeys == 0 then
        return
    end

    local db = auraDisplays:GetDB()
    for displayID, frame in pairs(self.frames) do
        local display = db.displays and db.displays[displayID]
        if display and display.enable and display.container then
            local containerUnit = display.container.unit or 'player'
            if self:ShouldSyncDisplayUnit(containerUnit, unitKeys) then
                containerModule:SyncUnit(frame, display)
            end
        end
    end
end

function displayModule:SyncCoTankUnits()
    self:SyncUnitsForKeys({ unitResolver.CO_TANK })
end

function displayModule:Refresh(displayID, display)
    if not display or not display.enable then
        self:DestroyFrame(displayID)
        return
    end

    local frame = self.frames[displayID] or self:CreateFrame(displayID)
    frame:Show()
    self:RegisterEditor(frame, display)
    containerModule:Refresh(frame, displayID, display)
end

function displayModule:RefreshAll()
    local db = auraDisplays:GetDB()
    for displayID, display in pairs(db.displays or {}) do
        self:Refresh(displayID, display)
    end
end

function displayModule:DestroyAll()
    for displayID in pairs(self.frames) do
        self:DestroyFrame(displayID)
    end
end

EXUI:RegisterEventHandler('PLAYER_REGEN_ENABLED', 'aura-displays-display', function()
    for displayID, frame in pairs(displayModule.frames) do
        if frame._pendingRefresh then
            frame._pendingRefresh = nil
            local display = auraDisplays:GetDisplay(displayID)
            if display then
                containerModule:Refresh(frame, displayID, display)
            end
        end
    end
end)

hooksecurefunc(editor, 'EnableEditor', function()
    displayModule:SyncAllFrameSizes()
end)
