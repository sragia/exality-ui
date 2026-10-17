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
preview._pendingSync = false

local function frameStateKey(frame)
    -- One preview container per unit frame so switching displays always
    -- re-anchors/relayouts instead of stacking stale per-display containers.
    local name = frame.GetName and frame:GetName()
    return ('uf:%s'):format(name or tostring(frame))
end

local function previewGrave()
    if not preview._grave then
        local grave = CreateFrame('Frame', nil, UIParent)
        grave:Hide()
        preview._grave = grave
    end
    return preview._grave
end

local function ensurePreviewHost(frame)
    local host = frame._exuiAuraPreviewHost
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
    frame._exuiAuraPreviewHost = host
    return host
end

-- The aura container stays on a plain host. Live aura updates only manage
-- AuraContainer children of the unit frame, so parking this host off the
-- unit frame while testing leaves the editor preview intact.
local function positionPreviewContainer(container, frame, display)
    local host = ensurePreviewHost(frame)
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
        local host = frame._exuiAuraPreviewHost
        if host then
            host:Hide()
            host:SetParent(grave)
        end
    end
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
    local unitType = self.contextUnit
    local forcedUnit = self.forcedUnit

    self:ClearPreviewStates()
    self:ParkHosts(forcedUnit or unitType)
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
    local visual = group.visual

    -- Same display keeps its preview buttons. Clearing here used to abandon
    -- them on every color change.
    if self.activeDisplayID ~= displayID then
        self:ClearPreviewStates()
    end

    for _, frame in ipairs(frames) do
        if frame:IsShown() or frame.isFake then
            self:SuppressRealAuras(frame, displayID)
            local stateKey = frameStateKey(frame)
            local layoutDisplay = layoutDisplayForFrame(display, frame)
            adPreview:BuildPreviewOnFrame(
                stateKey,
                frame,
                layoutDisplay,
                visual,
                positionPreviewContainer,
                adPreview:GetPreviewCount(group)
            )
            self.activeStateKeys[stateKey] = true
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
