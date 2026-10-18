---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysDefaults
local defaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUIAuraDisplaysConfigResolver
local resolver = EXUI:GetModule('aura-displays-config-resolver')

---@class EXUIAuraDisplaysLayout
local layout = EXUI:GetModule('aura-displays-layout')

---@class EXUIAuraDisplaysButtonStyle
local buttonStyle = EXUI:GetModule('aura-displays-button-style')

---@class EXUIAuraDisplaysLoadConditions
local loadConditions = EXUI:GetModule('aura-displays-load-conditions')

---@class EXUIAuraDisplaysUnitResolver
local unitResolver = EXUI:GetModule('aura-displays-unit-resolver')

---@class EXUIAuraDisplaysContainer
local containerModule = EXUI:GetModule('aura-displays-container')

-- AuraContainerItemEnchantmentSlot enum: MainHand=0, OffHand=1, Ranged=2
local ITEM_ENCHANT_SLOT = {
    MainHand = 0,
    OffHand = 1,
    Ranged = 2,
}

function containerModule:IsAvailable()
    if self._available ~= nil then
        return self._available
    end
    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn('Blizzard_AuraContainer')
    end
    local ok = pcall(function()
        local test = CreateFrame('AuraContainer', 'EXUIAuraContainerTest', UIParent, 'CustomAuraContainerTemplate')
        test:Hide()
        test:SetParent(nil)
    end)
    self._available = ok
    return ok
end

function containerModule:ClearContainer(frame)
    if frame.AuraContainer then
        if frame.AuraContainer.SetEnabled then
            frame.AuraContainer:SetEnabled(false)
        end
        frame.AuraContainer:Hide()
        frame.AuraContainer:SetParent(nil)
        frame.AuraContainer = nil
    end
end

function containerModule:AnchorContainer(container, frame, display)
    local anchor = display.containerAnchorPoint or 'TOPLEFT'
    container:ClearAllPoints()
    container:SetPoint(anchor, frame, anchor, 0, 0)
end

function containerModule:GetPlaceholderSize(display)
    local width, height = 32, 32
    for _, groupID in ipairs(display.groupOrder or {}) do
        local group = display.groups and display.groups[groupID]
        if group and group.conditions and group.conditions.enable and loadConditions:ShouldIncludeGroup(group.load) then
            local visual = group.visual or {}
            if visual.displayStyle == 'bar' then
                local barWidth = visual.barWidth or 160
                local barHeight = visual.barHeight or 20
                local iconSize = visual.showBarIcon ~= false and barHeight or 0
                local iconGap = iconSize > 0 and (visual.barIconGap or 0) or 0
                width = barWidth + iconSize + iconGap
                height = barHeight
            else
                width = visual.iconWidth or 32
                height = visual.iconHeight or 32
            end
            break
        end
    end
    return width, height
end

function containerModule:EnsureEditPlaceholder(frame, display)
    if frame.EditPlaceholder then
        return frame.EditPlaceholder
    end

    local placeholder = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    EXUI:ApplySolidBorder(placeholder, 1, { 1, 1, 1, 0.75 }, { 0.15, 0.35, 0.65, 0.45 }, { register = false })

    local icon = placeholder:CreateTexture(nil, 'ARTWORK')
    icon:SetTexture(134400)
    icon:SetPoint('TOPLEFT', 2, -2)
    icon:SetPoint('BOTTOMRIGHT', -2, 2)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.EditPlaceholder = placeholder
    return placeholder
end

function containerModule:IsEditMode(frame)
    return frame and frame.editor and frame.editor:IsShown()
end

function containerModule:SyncEditorOverlay(frame)
    local editor = EXUI:GetModule('editor')
    if editor and editor.SyncEditorOverlay then
        editor:SyncEditorOverlay(frame)
        editor:RefreshEditorOverlayBorder(frame)
    elseif frame and frame.editor then
        frame.editor:ClearAllPoints()
        frame.editor:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
        frame.editor:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
    end
end

function containerModule:SetEditMode(frame, display, enabled)
    if not frame or not display then
        return
    end

    local width, height = self:GetPlaceholderSize(display)
    local anchor = display.containerAnchorPoint or 'TOPLEFT'
    frame:SetSize(width, height)
    self:SyncEditorOverlay(frame)

    if enabled then
        if frame.AuraContainer then
            frame.AuraContainer:Hide()
        end
        for _, container in pairs(frame.EncounterContainers or {}) do
            container:Hide()
        end
        local placeholder = self:EnsureEditPlaceholder(frame, display)
        placeholder:SetSize(width, height)
        placeholder:ClearAllPoints()
        placeholder:SetPoint(anchor, frame, anchor, 0, 0)
        placeholder:Show()
        if placeholder.PPBorder then
            placeholder.PPBorder:SetBorderThickness(1)
        end
        self:SyncEditorOverlay(frame)
        return
    end

    if frame.EditPlaceholder then
        frame.EditPlaceholder:Hide()
    end
    if frame.AuraContainer then
        frame.AuraContainer:Show()
    end
    local encounterID = loadConditions:GetActiveEncounter()
    for _, container in pairs(frame.EncounterContainers or {}) do
        if encounterID and not container._exuiEncounterDisabled and container._exuiEncounterID == encounterID then
            container:Show()
        end
    end
end

function containerModule:SyncFrameSize(frame, display, _displayID)
    if not frame then
        return
    end

    local width, height = self:GetPlaceholderSize(display)
    frame:SetSize(width, height)
    self:SyncEditorOverlay(frame)
end

function containerModule:BindContainerSize(frame, display, displayID)
    self:SyncFrameSize(frame, display, displayID)
end

function containerModule:ApplyUnit(container, containerConfig, displayEnabled)
    if not container or not container.SetUnit then
        return false
    end

    local resolvedUnit, isValid = unitResolver:Resolve(containerConfig)
    if resolvedUnit and isValid then
        container:SetUnit(resolvedUnit)
        if container.SetEnabled then
            container:SetEnabled(displayEnabled ~= false)
        end
        return true
    end

    if container.SetEnabled then
        container:SetEnabled(false)
    end
    return false
end

function containerModule:SyncUnit(frame, display)
    local container = frame.AuraContainer
    if not container or not display then
        return
    end

    self:ApplyUnit(container, display.container, display.enable)
    if container.UpdateAllAuras then
        container:UpdateAllAuras()
    end
end

function containerModule:ApplyProcessingPolicy(container, display)
    if not container.SetAuraProcessingPolicy then
        return
    end
    local needsProcessAura = resolver:DisplayNeedsProcessAura(display, function(load)
        return loadConditions:ShouldIncludeGroup(load)
    end)
    if not needsProcessAura then
        container:SetAuraProcessingPolicy(0)
        return
    end
    local processAuraOptions = display.container and display.container.processAuraOptions or {}
    container:SetAuraProcessingPolicy(1, processAuraOptions)
end

local function groupKey(id, groupID)
    return defaults:GetGroupKey(id, groupID)
end

local function shouldIncludeGroup(load)
    return loadConditions:ShouldIncludeGroup(load)
end

local function matchesCombat(load)
    return loadConditions:MatchesCombat(load)
end

function containerModule:ApplyCombatEnabled(container, displayID, display)
    resolver:ApplyCombatEnabled(container, displayID, display, groupKey, shouldIncludeGroup, matchesCombat)
end

function containerModule:ApplyCombatState()
    local displayModule = EXUI:GetModule('aura-displays-display')
    local auraDisplays = EXUI:GetModule('aura-displays')
    for displayID, frame in pairs(displayModule.frames or {}) do
        local display = auraDisplays:GetDisplay(displayID)
        if frame.AuraContainer and display then
            self:ApplyCombatEnabled(frame.AuraContainer, displayID, display)
        end
    end
end

function containerModule:RebuildGroups(frame, displayID, display)
    resolver:RebuildGroups(
        frame.AuraContainer,
        displayID,
        display,
        buttonStyle,
        groupKey,
        shouldIncludeGroup,
        matchesCombat
    )
end

function containerModule:UpdateGroupsInPlace(frame, displayID, display)
    local container = frame.AuraContainer
    if not resolver:CanUpdateGroupsInPlace(container) then
        return false
    end

    for _, entry in ipairs(resolver:IterActiveGroups(display, shouldIncludeGroup)) do
        local options = resolver:ResolveGroupOptions(
            displayID, display, entry.groupID, entry.group, buttonStyle, entry.layoutIndex
        )
        resolver:ApplyGroupOptions(container, options)
        resolver:ApplyInitializeFrame(container, options)
    end

    self:ApplyCombatEnabled(container, displayID, display)

    if container.UpdateAllAuras then
        container:UpdateAllAuras()
    end
    return true
end

containerModule.encounterStale = {}

function containerModule:DisableEncounterContainer(container)
    if not container or container._exuiEncounterDisabled then
        return
    end
    container._exuiEncounterDisabled = true
    pcall(function()
        if container.SetEnabled then
            container:SetEnabled(false)
        end
        container:Hide()
    end)
end

function containerModule:DestroyEncounterContainer(container)
    if not container then
        return
    end
    self:DisableEncounterContainer(container)
    pcall(function()
        container:SetParent(nil)
    end)
end

function containerModule:QueueStaleEncounterContainer(container)
    if not container or container._exuiEncounterStale then
        return
    end
    container._exuiEncounterStale = true
    self:DisableEncounterContainer(container)
    self.encounterStale[#self.encounterStale + 1] = container
end

function containerModule:ReleaseStaleEncounterContainers()
    if InCombatLockdown() then
        return
    end
    for _, container in ipairs(self.encounterStale) do
        self:DestroyEncounterContainer(container)
    end
    wipe(self.encounterStale)
end

function containerModule:ReleaseAllEncounterContainers()
    if InCombatLockdown() then
        return
    end
    local displayModule = EXUI:GetModule('aura-displays-display')
    for _, frame in pairs(displayModule.frames or {}) do
        for encounterID, container in pairs(frame.EncounterContainers or {}) do
            frame.EncounterContainers[encounterID] = nil
            self:DestroyEncounterContainer(container)
        end
    end
    self:ReleaseStaleEncounterContainers()
end

function containerModule:HideKeptEncounterContainers()
    local displayModule = EXUI:GetModule('aura-displays-display')
    for _, frame in pairs(displayModule.frames or {}) do
        for _, container in pairs(frame.EncounterContainers or {}) do
            if not container._exuiEncounterDisabled then
                pcall(function()
                    container:Hide()
                end)
            end
        end
    end
end

function containerModule:DisableAllEncounterContainers()
    local displayModule = EXUI:GetModule('aura-displays-display')
    for _, frame in pairs(displayModule.frames or {}) do
        for encounterID, container in pairs(frame.EncounterContainers or {}) do
            frame.EncounterContainers[encounterID] = nil
            self:QueueStaleEncounterContainer(container)
        end
    end
end

function containerModule:ReleaseFrameEncounterContainers(frame)
    if not frame or not frame.EncounterContainers then
        return
    end
    for encounterID, container in pairs(frame.EncounterContainers) do
        frame.EncounterContainers[encounterID] = nil
        if InCombatLockdown() then
            self:QueueStaleEncounterContainer(container)
        else
            self:DestroyEncounterContainer(container)
        end
    end
end

function containerModule:EncounterInclude(encounterID)
    return function(load)
        return loadConditions:ShouldIncludeEncounterGroup(load, encounterID)
    end
end

function containerModule:EncounterSignature(displayID, display, encounterID)
    return resolver:BuildHardSignature(displayID, display, function(id, groupID)
        return defaults:GetGroupKey(id, groupID)
    end, self:EncounterInclude(encounterID))
end

function containerModule:CreateEncounterContainer(frame, displayID, display, encounterID)
    if not self:IsAvailable() then
        return nil
    end
    local include = self:EncounterInclude(encounterID)
    local ok, container = pcall(CreateFrame, 'AuraContainer', nil, frame, 'CustomAuraContainerTemplate')
    if not ok or not container then
        return nil
    end
    container._exuiEncounterID = encounterID
    container._exuiDisplayID = displayID
    container._exuiEncounterSig = self:EncounterSignature(displayID, display, encounterID)
    frame.EncounterContainers = frame.EncounterContainers or {}
    frame.EncounterContainers[encounterID] = container

    local configured = pcall(function()
        self:AnchorContainer(container, frame, display)
        layout:ApplyContainerLayout(container, display)
        self:ApplyUnit(container, display.container, display.enable)
        if container.SetAuraProcessingPolicy then
            local needsProcessAura = resolver:DisplayNeedsProcessAura(display, include)
            if needsProcessAura then
                local processAuraOptions = display.container and display.container.processAuraOptions or {}
                container:SetAuraProcessingPolicy(1, processAuraOptions)
            else
                container:SetAuraProcessingPolicy(0)
            end
        end
        container:Show()
        resolver:RebuildGroups(container, displayID, display, buttonStyle, groupKey, include)
        if container.UpdateAllAuras then
            container:UpdateAllAuras()
        end
        if self:IsEditMode(frame) then
            container:Hide()
        end
    end)
    if not configured then
        frame.EncounterContainers[encounterID] = nil
        self:QueueStaleEncounterContainer(container)
        return nil
    end
    return container
end

function containerModule:EnsureEncounterContainer(frame, displayID, display, encounterID)
    if not frame or not display then
        return
    end
    frame.EncounterContainers = frame.EncounterContainers or {}
    local existing = frame.EncounterContainers[encounterID]
    local staleIDs = {}
    for id in pairs(frame.EncounterContainers) do
        if id ~= encounterID then
            staleIDs[#staleIDs + 1] = id
        end
    end
    for _, id in ipairs(staleIDs) do
        local container = frame.EncounterContainers[id]
        frame.EncounterContainers[id] = nil
        self:QueueStaleEncounterContainer(container)
    end

    local auraDisplays = EXUI:GetModule('aura-displays')
    if not auraDisplays:IsDisplayShown(display) or not loadConditions:DisplayHasEncounterGroups(display, encounterID) then
        if existing and frame.EncounterContainers[encounterID] then
            frame.EncounterContainers[encounterID] = nil
            self:QueueStaleEncounterContainer(existing)
        end
        return
    end

    existing = frame.EncounterContainers[encounterID]
    local sig = self:EncounterSignature(displayID, display, encounterID)
    if existing and not existing._exuiEncounterDisabled and existing._exuiEncounterSig == sig then
        if not self:IsEditMode(frame) then
            pcall(function()
                existing:Show()
                if existing.UpdateAllAuras then
                    existing:UpdateAllAuras()
                end
            end)
        end
        return
    end
    if existing then
        frame.EncounterContainers[encounterID] = nil
        self:QueueStaleEncounterContainer(existing)
    end
    self:CreateEncounterContainer(frame, displayID, display, encounterID)
end

function containerModule:OnEncounterStart(encounterID)
    local displayModule = EXUI:GetModule('aura-displays-display')
    local auraDisplays = EXUI:GetModule('aura-displays')
    for displayID, frame in pairs(displayModule.frames or {}) do
        self:EnsureEncounterContainer(frame, displayID, auraDisplays:GetDisplay(displayID), encounterID)
    end
end

function containerModule:GetHardSignature(displayID, display)
    return resolver:BuildHardSignature(displayID, display, function(id, groupID)
        return defaults:GetGroupKey(id, groupID)
    end, function(load)
        return loadConditions:ShouldIncludeGroup(load)
    end)
end

function containerModule:ApplyItemEnchantments(frame, containerConfig, display)
    local container = frame.AuraContainer
    if not container or not container.AddItemEnchantment then
        return
    end

    if not containerConfig.itemEnchantEnable then
        return
    end

    layout:ApplyItemEnchantmentLayout(container, containerConfig, display)

    local slots = {
        { key = 'itemEnchantMainHand', slot = ITEM_ENCHANT_SLOT.MainHand },
        { key = 'itemEnchantOffHand', slot = ITEM_ENCHANT_SLOT.OffHand },
        { key = 'itemEnchantRanged', slot = ITEM_ENCHANT_SLOT.Ranged },
    }

    for _, entry in ipairs(slots) do
        if containerConfig[entry.key] then
            container:AddItemEnchantment(entry.slot, {
                hidePermanent = containerConfig.itemEnchantHidePermanent,
                initializeFrame = function(auraButton)
                    if auraButton.EnableMouse then auraButton:EnableMouse(false) end
                    if auraButton.SetMouseMotionEnabled then auraButton:SetMouseMotionEnabled(false) end
                end,
            })
        end
    end
end

function containerModule:Refresh(frame, displayID, display)
    if not self:IsAvailable() then
        return
    end

    local hardSig = self:GetHardSignature(displayID, display)
    if frame.AuraContainer and frame._exuiHardSig == hardSig and self:UpdateGroupsInPlace(frame, displayID, display) then
        layout:ApplyDisplayPosition(frame, display)
        self:AnchorContainer(frame.AuraContainer, frame, display)
        layout:ApplyContainerLayout(frame.AuraContainer, display)
        self:ApplyUnit(frame.AuraContainer, display.container, display.enable)
        self:ApplyProcessingPolicy(frame.AuraContainer, display)
        layout:ApplyItemEnchantmentLayout(frame.AuraContainer, display.container, display)
        self:BindContainerSize(frame, display, displayID)
        if self:IsEditMode(frame) then
            self:SetEditMode(frame, display, true)
        else
            frame.AuraContainer:Show()
        end
        return
    end

    self:ClearContainer(frame)

    local ok, container = pcall(CreateFrame, 'AuraContainer', nil, frame, 'CustomAuraContainerTemplate')
    if not ok or not container then
        return
    end
    frame.AuraContainer = container
    frame._exuiHardSig = hardSig

    layout:ApplyDisplayPosition(frame, display)
    self:AnchorContainer(container, frame, display)
    layout:ApplyContainerLayout(container, display)

    self:ApplyUnit(container, display.container, display.enable)

    self:ApplyProcessingPolicy(container, display)
    container:Show()

    self:RebuildGroups(frame, displayID, display)
    self:ApplyItemEnchantments(frame, display.container, display)

    if container.UpdateAllAuras then
        container:UpdateAllAuras()
    end

    self:BindContainerSize(frame, display, displayID)

    if self:IsEditMode(frame) then
        self:SetEditMode(frame, display, true)
    end
end
