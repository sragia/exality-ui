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

---@class EXUIAuraDisplaysButtonStyle
local buttonStyle = EXUI:GetModule('aura-displays-button-style')

---@class EXUIUnitFramesAurasPreview
local preview = EXUI:GetModule('uf-auras-preview')

preview.contextUnit = nil
preview.activeDisplayID = nil
preview.forcedUnit = nil
preview.activeStateKeys = {}
preview.toggled = {}
preview.manual = {}
preview.userDisabled = {}
preview._pendingSync = false

local function frameStateKey(frame, displayID)
    -- One preview container per display on each unit frame so several can show at once.
    local name = frame.GetName and frame:GetName()
    return ('uf:%s:%s'):format(name or tostring(frame), displayID)
end

local function previewGrave()
    if not preview._grave then
        local grave = CreateFrame('Frame', nil, UIParent)
        grave:Hide()
        preview._grave = grave
    end
    return preview._grave
end

local function ensurePreviewHost(frame, displayID)
    frame._exuiAuraPreviewHosts = frame._exuiAuraPreviewHosts or {}
    local host = frame._exuiAuraPreviewHosts[displayID]
    if host then
        return host
    end
    host = CreateFrame('Frame', nil, frame)
    host:EnableMouse(false)
    if host.SetMouseMotionEnabled then
        host:SetMouseMotionEnabled(false)
    end
    if host.SetMouseClickEnabled then
        host:SetMouseClickEnabled(false)
    end
    host._exuiAuraPreviewHost = true
    host:Hide()
    frame._exuiAuraPreviewHosts[displayID] = host
    return host
end

-- The aura container stays on a plain host. Live aura updates only manage
-- AuraContainer children of the unit frame, so parking this host off the
-- unit frame while testing leaves the editor preview intact.
local function positionPreviewContainer(container, frame, display)
    local host = ensurePreviewHost(frame, display.displayID)
    if host:GetParent() ~= frame then
        host:SetParent(frame)
    end

    local anchorParent = frame
    if not apply:IsGlowOnlyDisplay(display) then
        anchorParent = frame.ElementFrame or frame
    end
    host:ClearAllPoints()
    host:SetPoint(
        display.anchorPoint or 'BOTTOMLEFT',
        anchorParent,
        display.relativePoint or 'TOPLEFT',
        display.XOff or 0,
        display.YOff or 0
    )
    host:SetSize(1, 1)
    apply:ApplyFrameLayer(host, frame, display)

    local anchor = display.anchorPoint or 'BOTTOMLEFT'
    if not container._exuiPreviewHosted or container._exuiPreviewAnchor ~= anchor then
        container:SetParent(host)
        container:ClearAllPoints()
        container:SetPoint(anchor, host, anchor, 0, 0)
        container._exuiPreviewHosted = true
        container._exuiPreviewAnchor = anchor
    end
    host:Show()
    buttonStyle:FinishPendingFrameGlows()
end

function preview:ParkHosts(unitType)
    local grave = previewGrave()
    for _, frame in ipairs(self:GetFramesForUnit(unitType)) do
        for _, host in pairs(frame._exuiAuraPreviewHosts or {}) do
            host:Hide()
            host:SetParent(grave)
        end
    end
end

local function layoutDisplayForFrame(display, frame, displayID)
    return {
        displayID = displayID,
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
        groups = display.groups,
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

function preview:HasNaturalGroupFrames(unitType)
    if unitType == 'party' then
        return IsInGroup() and not IsInRaid()
    end
    if unitType == 'raid' then
        return IsInRaid()
    end
    return false
end

function preview:EnsureForceShow(unitType)
    if not unitType or InCombatLockdown() then
        return
    end

    if self.forcedUnit and self.forcedUnit ~= unitType then
        ufCore:Unforce(self.forcedUnit)
        self.forcedUnit = nil
    end

    -- Already in party/raid: keep real frames and only overlay scenario auras.
    if self:HasNaturalGroupFrames(unitType) then
        if self.forcedUnit == unitType then
            ufCore:Unforce(unitType)
            self.forcedUnit = nil
        end
        return
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
    -- fake previews are readable.
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

function preview:HideDisplay(displayID)
    for stateKey, activeID in pairs(self.activeStateKeys) do
        if activeID == displayID then
            adPreview:HidePreview(stateKey)
            self.activeStateKeys[stateKey] = nil
        end
    end
end

function preview:IsToggled(displayID)
    return self.toggled[displayID] == true
end

function preview:SetToggled(displayID, enabled)
    self.toggled[displayID] = enabled or nil
    self.manual[displayID] = enabled or nil
    self.userDisabled[displayID] = not enabled or nil
    self:Sync()
end

function preview:ClearUserDisabled(displayID)
    self.userDisabled[displayID] = nil
end

function preview:ClearAutoPreviews(exceptID)
    for displayID in pairs(self.toggled) do
        if displayID ~= exceptID and not self.manual[displayID] then
            self.toggled[displayID] = nil
        end
    end
end

function preview:SyncPreviewToggles()
    local editor = EXUI:GetModule('uf-aura-editor')
    if editor and editor.splitView and editor.splitView.SyncPreviewToggles then
        editor.splitView:SyncPreviewToggles(function(displayID)
            return self:IsToggled(displayID)
        end)
    end
end

function preview:SetContext(unitType)
    self.contextUnit = unitType
end

function preview:Clear()
    local unitType = self.contextUnit
    local forcedUnit = self.forcedUnit

    self:ClearPreviewStates()
    self:ParkHosts(forcedUnit or unitType)
    wipe(self.toggled)
    wipe(self.manual)
    wipe(self.userDisabled)
    self.activeDisplayID = nil
    self.forcedUnit = nil
    self.contextUnit = nil

    if InCombatLockdown() then
        return
    end

    if forcedUnit then
        ufCore:Unforce(forcedUnit)
    elseif unitType then
        -- Natural party/raid frames: recreate live auras after preview suppress.
        ufCore:UpdateFrameForUnit(unitType)
    end
end

local function getPreviewGroup(displayID, display)
    local editor = EXUI:GetModule('uf-aura-editor')
    local groupID = editor and editor.currItemID == displayID and ufAuras.currGroupID
    local group = groupID and display.groups and display.groups[groupID]
    if group and group.visual then
        return group
    end
    -- Fall back to first group if editor has not selected one yet.
    local firstID = display.groupOrder and display.groupOrder[1]
    group = firstID and display.groups and display.groups[firstID]
    return group and group.visual and group or nil
end

function preview:RefreshDisplay(displayID)
    local display = ufAuras:GetDisplay(displayID)
    local group = display and display.enable ~= false and getPreviewGroup(displayID, display)
    if not group then
        self:HideDisplay(displayID)
        return
    end

    for _, frame in ipairs(self:GetFramesForUnit(self.contextUnit)) do
        if frame:IsShown() or frame.isFake then
            self:SuppressRealAuras(frame, displayID)
            local stateKey = frameStateKey(frame, displayID)
            local layoutDisplay = layoutDisplayForFrame(display, frame, displayID)
            adPreview:BuildPreviewOnFrame(
                stateKey,
                frame,
                layoutDisplay,
                group.visual,
                positionPreviewContainer,
                adPreview:GetPreviewCount(group)
            )
            self.activeStateKeys[stateKey] = displayID
        end
    end
end

function preview:Refresh()
    if not self:IsEditorOpen() then
        self:Clear()
        return
    end

    if not self.contextUnit then
        self:ClearPreviewStates()
        return
    end

    for _, displayID in pairs(self.activeStateKeys) do
        if not self.toggled[displayID] then
            self:HideDisplay(displayID)
        end
    end

    for displayID in pairs(self.toggled) do
        if ufAuras:GetDisplay(displayID) then
            self:RefreshDisplay(displayID)
        else
            self.toggled[displayID] = nil
            self.manual[displayID] = nil
            self:HideDisplay(displayID)
        end
    end
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

    self:ClearAutoPreviews(displayID)
    if displayID and not self.userDisabled[displayID] then
        self.toggled[displayID] = true
    end
    self:SyncPreviewToggles()

    if not next(self.toggled) then
        self:ClearPreviewStates()
        self.activeDisplayID = displayID
        return
    end

    self._queuedDisplayID = displayID

    local function doRefresh()
        if not self:IsEditorOpen() or self.contextUnit ~= unitType then
            return
        end
        self:Refresh()
        self.activeDisplayID = self._queuedDisplayID
    end

    -- Defer when ForceShowing party, or when switching displays so anchors
    -- apply against settled frame sizes (avoids stale preview positioning).
    local switchingDisplay = self.activeDisplayID and displayID and self.activeDisplayID ~= displayID
    local deferPartyForce = unitType == 'party' and not self:HasNaturalGroupFrames('party')
    if switchingDisplay or deferPartyForce then
        if self._pendingSync then
            return
        end
        self._pendingSync = true
        C_Timer.After(0, function()
            if deferPartyForce then
                C_Timer.After(0, function()
                    self._pendingSync = false
                    doRefresh()
                end)
            else
                self._pendingSync = false
                doRefresh()
            end
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
