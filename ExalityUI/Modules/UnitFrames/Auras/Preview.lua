---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysPreview
local adPreview = EXUI:GetModule('aura-displays-preview')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesAuras
local ufAuras = EXUI:GetModule('uf-auras')

---@class EXUIUnitFramesAurasApply
local apply = EXUI:GetModule('uf-auras-apply')

---@class EXUIUnitFramesAurasPreview
local preview = EXUI:GetModule('uf-auras-preview')

preview.contextUnit = nil
preview.activeDisplayID = nil
preview.forcedUnit = nil
preview.activeStateKeys = {}
preview._pendingSync = false

local function frameStateKey(displayID, frame)
    local name = frame.GetName and frame:GetName()
    return ('uf:%s:%s'):format(tostring(displayID), name or tostring(frame))
end

local function positionPreviewContainer(container, frame, display)
    apply:AnchorContainer(container, frame, display)
    apply:ApplyFrameLayer(container, frame, display)
end

local function layoutDisplayForFrame(display, frame)
    return {
        containerAnchorPoint = display.containerAnchorPoint,
        horizontalGrowth = display.horizontalGrowth,
        verticalGrowth = display.verticalGrowth,
        paddingLeft = display.paddingLeft,
        paddingRight = display.paddingRight,
        paddingTop = display.paddingTop,
        paddingBottom = display.paddingBottom,
        rowWidth = apply:GetRowWidth(frame, display),
        anchorPoint = display.anchorPoint,
        relativePoint = display.relativePoint,
        XOff = display.XOff,
        YOff = display.YOff,
        matchUnitFrameWidth = display.matchUnitFrameWidth,
        frameStrata = display.frameStrata,
        frameLevel = display.frameLevel,
    }
end

function preview:Init()
    -- Editor hooks itself when the window is created.
end

function preview:IsEditorOpen()
    local editor = EXUI:GetModule('uf-aura-editor')
    return editor and editor.window and editor.window:IsShown()
end

function preview:HookEditorWindow(window)
    if not window or window.exuiUFAuraPreviewHooked then
        return
    end
    window.exuiUFAuraPreviewHooked = true

    local previousOnClose = window.onClose
    window.onClose = function()
        preview:Clear()
        if previousOnClose then
            previousOnClose()
        end
    end
end

function preview:GetFramesForUnit(unitType)
    local frames = {}
    if not unitType then
        return frames
    end

    if unitType == 'party' then
        for _, frame in ipairs(ufCore.partyFrames or {}) do
            if frame then
                table.insert(frames, frame)
            end
        end
    elseif unitType == 'raid' then
        for _, frame in ipairs(ufCore.raidFrames or {}) do
            if frame then
                table.insert(frames, frame)
            end
        end
    elseif ufCore.groupUnits and ufCore.groupUnits[unitType] then
        for i = 1, ufCore.groupUnits[unitType] do
            local frame = ufCore.frames[unitType .. i]
            if frame then
                table.insert(frames, frame)
            end
        end
    else
        local frame = ufCore.frames and ufCore.frames[unitType]
        if frame then
            table.insert(frames, frame)
        end
    end

    return frames
end

function preview:EnsureForceShow(unitType)
    if not unitType or InCombatLockdown() then
        return
    end

    if self.forcedUnit and self.forcedUnit ~= unitType then
        ufCore:Unforce(self.forcedUnit)
        self.forcedUnit = nil
    end

    ufCore:ForceShow(unitType, { editorPreview = true })
    if unitType == 'party' or unitType == 'raid' then
        ufCore:ApplyEditorGroupLayout(unitType)
    end
    self.forcedUnit = unitType
end

function preview:SuppressRealAuras(frame, displayID)
    if not frame or not frame.UFAuraContainers then
        return
    end
    -- Hide all live UF aura containers on this frame while editing so the
    -- selected display's fake preview is readable.
    for id, container in pairs(frame.UFAuraContainers) do
        if container then
            if container.SetEnabled then
                container:SetEnabled(false)
            end
            container:Hide()
        end
    end
end

function preview:ClearPreviewStates()
    for stateKey in pairs(self.activeStateKeys) do
        adPreview:HidePreview(stateKey)
    end
    wipe(self.activeStateKeys)
end

function preview:SetContext(unitType)
    self.contextUnit = unitType
end

function preview:Clear()
    self:ClearPreviewStates()
    self.activeDisplayID = nil

    if self.forcedUnit and not InCombatLockdown() then
        ufCore:Unforce(self.forcedUnit)
    end
    self.forcedUnit = nil
    self.contextUnit = nil
end

function preview:Refresh(displayID)
    if not self:IsEditorOpen() then
        self:Clear()
        return
    end

    local unitType = self.contextUnit
    if not unitType or not displayID then
        self:ClearPreviewStates()
        self.activeDisplayID = nil
        return
    end

    local display = ufAuras:GetDisplay(displayID)
    if not display or display.enable == false then
        self:ClearPreviewStates()
        self.activeDisplayID = displayID
        return
    end

    local groupID = ufAuras.currGroupID
    local group = groupID and display.groups and display.groups[groupID]
    if not group or not group.visual then
        -- Fall back to first group if editor has not selected one yet.
        local firstID = display.groupOrder and display.groupOrder[1]
        group = firstID and display.groups and display.groups[firstID]
        if not group or not group.visual then
            self:ClearPreviewStates()
            self.activeDisplayID = displayID
            return
        end
    end

    local frames = self:GetFramesForUnit(unitType)
    local nextKeys = {}
    local visual = group.visual

    for _, frame in ipairs(frames) do
        if frame:IsShown() or frame.isFake then
            self:SuppressRealAuras(frame, displayID)
            local stateKey = frameStateKey(displayID, frame)
            local layoutDisplay = layoutDisplayForFrame(display, frame)
            adPreview:BuildPreviewOnFrame(
                stateKey,
                frame,
                layoutDisplay,
                visual,
                positionPreviewContainer,
                adPreview:GetPreviewCount(group)
            )
            nextKeys[stateKey] = true
            self.activeStateKeys[stateKey] = true
        end
    end

    for stateKey in pairs(self.activeStateKeys) do
        if not nextKeys[stateKey] then
            adPreview:HidePreview(stateKey)
            self.activeStateKeys[stateKey] = nil
        end
    end

    self.activeDisplayID = displayID
end

function preview:Sync(displayID)
    displayID = displayID or self.activeDisplayID
    if not self:IsEditorOpen() then
        self:Clear()
        return
    end

    local unitType = self.contextUnit
    if not unitType then
        return
    end

    self:EnsureForceShow(unitType)

    if not displayID then
        self:ClearPreviewStates()
        self.activeDisplayID = nil
        return
    end

    self._queuedDisplayID = displayID

    local function doRefresh()
        if not self:IsEditorOpen() or self.contextUnit ~= unitType then
            return
        end
        local editor = EXUI:GetModule('uf-aura-editor')
        self:Refresh(self._queuedDisplayID or (editor and editor.currItemID))
    end

    -- Party ForceShow creates child frames next frame; wait one more so they are forced.
    if unitType == 'party' then
        if self._pendingSync then
            return
        end
        self._pendingSync = true
        C_Timer.After(0, function()
            C_Timer.After(0, function()
                self._pendingSync = false
                doRefresh()
            end)
        end)
        return
    end

    doRefresh()
end

function preview:OnDisplayChanged(displayID)
    if not self:IsEditorOpen() then
        return
    end
    local editor = EXUI:GetModule('uf-aura-editor')
    self:Sync(editor and editor.currItemID or displayID)
end
