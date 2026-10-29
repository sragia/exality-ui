---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysConfigResolver
local resolver = EXUI:GetModule('aura-displays-config-resolver')

---@class EXUIAuraDisplaysButtonStyle
local buttonStyle = EXUI:GetModule('aura-displays-button-style')

---@class EXUIAuraDisplaysLoadConditions
local loadConditions = EXUI:GetModule('aura-displays-load-conditions')

---@class EXUIAuraDisplaysLayout
local layout = EXUI:GetModule('aura-displays-layout')

---@class EXUIUnitFramesAurasDefaults
local defaults = EXUI:GetModule('uf-auras-defaults')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesAuras
local ufAuras = EXUI:GetModule('uf-auras')

---@class EXUIUnitFramesAurasApply
local apply = EXUI:GetModule('uf-auras-apply')

local ITEM_ENCHANT_SLOT = {
    MainHand = 0,
    OffHand = 1,
    Ranged = 2,
}

-- Units outside the player's instance/zone only get group-feed auras, which Blizzard's
-- filter strings can't classify, so every aura passes. These fire on both transitions.
local VISIBILITY_UNIT_EVENTS = {
    'PARTY_MEMBER_ENABLE',
    'PARTY_MEMBER_DISABLE',
    'UNIT_PHASE',
    'UNIT_AREA_CHANGED',
    'UNIT_CONNECTION',
}

local function OnVisibilityEvent(frame)
    apply:ApplyVisibilityGate(frame)
    C_Timer.After(0, function()
        apply:ApplyVisibilityGate(frame)
    end)
end

apply.pendingFrames = {}
apply.pendingLiveRefresh = {}
apply.sigCache = {}
apply.containerGraveyard = {}
apply.PREWARM_MIN = 40
apply.PREWARM_PER_FRAME = 2

function apply:InvalidateHardSignatures()
    wipe(self.sigCache)
    if self.encounterSigCache then
        wipe(self.encounterSigCache)
    end
end

function apply:InvalidateSignatures()
    self:InvalidateHardSignatures()
    buttonStyle:InvalidateStyleSignatures()
end

function apply:Init()
    if self.eventHandler then
        return
    end
    self.eventHandler = CreateFrame('Frame')
    self.eventHandler:RegisterEvent('PLAYER_REGEN_ENABLED')
    self.eventHandler:RegisterEvent('PLAYER_ENTERING_WORLD')
    self.eventHandler:RegisterEvent('PLAYER_TARGET_CHANGED')
    self.eventHandler:RegisterEvent('PLAYER_FOCUS_CHANGED')
    self.eventHandler:RegisterEvent('INSTANCE_ENCOUNTER_ENGAGE_UNIT')
    self.eventHandler:RegisterEvent('ARENA_OPPONENT_UPDATE')
    self.eventHandler:RegisterUnitEvent('UNIT_TARGETABLE_CHANGED', 'boss1', 'boss2', 'boss3', 'boss4', 'boss5')
    self.eventHandler:RegisterUnitEvent('UNIT_TARGET', 'target')
    self.eventHandler:RegisterUnitEvent('UNIT_PET', 'player')
    self.eventHandler:RegisterEvent('GROUP_ROSTER_UPDATE')
    self.eventHandler:RegisterEvent('ZONE_CHANGED_NEW_AREA')
    self.eventHandler:SetScript('OnEvent', function(_, event)
        if event == 'GROUP_ROSTER_UPDATE' or event == 'ZONE_CHANGED_NEW_AREA' or event == 'PLAYER_ENTERING_WORLD' then
            self:QueueVisibilityGateAll()
            if event ~= 'PLAYER_ENTERING_WORLD' then
                return
            end
        end
        if event == 'PLAYER_TARGET_CHANGED' then
            self:QueueLiveAuraRefresh('target')
            self:QueueLiveAuraRefresh('targettarget')
            return
        end
        if event == 'PLAYER_FOCUS_CHANGED' then
            self:QueueLiveAuraRefresh('focus')
            return
        end
        if event == 'INSTANCE_ENCOUNTER_ENGAGE_UNIT' or event == 'UNIT_TARGETABLE_CHANGED' then
            self:QueueLiveAuraRefresh('boss')
            return
        end
        if event == 'ARENA_OPPONENT_UPDATE' then
            self:QueueLiveAuraRefresh('arena')
            return
        end
        if event == 'UNIT_TARGET' then
            self:QueueLiveAuraRefresh('targettarget')
            return
        end
        if event == 'UNIT_PET' then
            self:QueueLiveAuraRefresh('pet')
            return
        end
        if event == 'PLAYER_REGEN_ENABLED' then
            self:FlushPending()
        end
        if event == 'PLAYER_REGEN_ENABLED' or event == 'PLAYER_ENTERING_WORLD' then
            self:PrewarmPool()
        end
    end)
end

function apply:QueueLiveAuraRefresh(unitType)
    if not unitType then
        return
    end
    self.pendingLiveRefresh[unitType] = true
    if self.liveRefreshQueued then
        return
    end
    self.liveRefreshQueued = true
    C_Timer.After(0, function()
        self.liveRefreshQueued = false
        local pending = self.pendingLiveRefresh
        self.pendingLiveRefresh = {}
        for pendingUnitType in pairs(pending) do
            self:RefreshLiveAurasForUnit(pendingUnitType)
        end
    end)
end

function apply:RefreshLiveAurasOnFrame(frame)
    if not frame or frame.isFake or not frame.UFAuraContainers then
        return
    end
    local unit = frame.__unit
    if not unit or not UnitExists(unit) then
        return
    end
    for _, container in pairs(frame.UFAuraContainers) do
        if container.SetUnit then
            container:SetUnit(unit)
        end
        if container.UpdateAllAuras then
            container:UpdateAllAuras()
        end
    end
    self:ApplyVisibilityGate(frame)
end

function apply:IsUnitAuraVisible(frame)
    local unit = frame and frame.__unit
    if not unit or frame.isFake or unit == 'player' or not UnitExists(unit) then
        return true
    end
    return UnitIsVisible(unit) and true or false
end

function apply:IsDisplayGated(displayID)
    local display = ufAuras:GetDisplay(displayID)
    return not display or display.hideWhenUnitNotVisible ~= false
end

function apply:ShouldShowContainer(frame, displayID)
    return not self:IsDisplayGated(displayID) or self:IsUnitAuraVisible(frame)
end

function apply:ApplyVisibilityGate(frame)
    if not frame then
        return
    end
    local visible = self:IsUnitAuraVisible(frame)
    if frame._exuiAuraVisible == visible then
        return
    end
    frame._exuiAuraVisible = visible

    if frame.UFAuraContainers then
        for displayID, container in pairs(frame.UFAuraContainers) do
            if self:IsDisplayGated(displayID) then
                container:SetShown(visible)
                if visible and container.UpdateAllAuras then
                    container:UpdateAllAuras()
                end
            end
        end
    end
    if frame.UFEncounterContainers then
        local encounterID = loadConditions:GetActiveEncounter()
        for displayID, container in pairs(frame.UFEncounterContainers) do
            if encounterID and not container._exuiEncounterDisabled
                and container._exuiEncounterID == encounterID
                and self:IsDisplayGated(displayID) then
                container:SetShown(visible)
                if visible and container.UpdateAllAuras then
                    container:UpdateAllAuras()
                end
            end
        end
    end
    EXUI:GetModule('uf-element-dispel-overlay'):SetUnitVisible(frame, visible)
end

function apply:RegisterVisibilityEvents(frame)
    if frame._exuiVisibilityEvents or frame.__unit == 'player' then
        return
    end
    frame._exuiVisibilityEvents = true
    for _, event in ipairs(VISIBILITY_UNIT_EVENTS) do
        frame:RegisterEvent(event, OnVisibilityEvent)
    end
end

function apply:ApplyVisibilityGateAll()
    for _, frame in pairs(ufCore.frames) do
        self:ApplyVisibilityGate(frame)
    end
    for _, frame in ipairs(ufCore.partyFrames) do
        self:ApplyVisibilityGate(frame)
    end
    for _, frame in ipairs(ufCore.raidFrames) do
        self:ApplyVisibilityGate(frame)
    end
end

function apply:QueueVisibilityGateAll()
    if self.visibilityGateQueued then
        return
    end
    self.visibilityGateQueued = true
    C_Timer.After(0, function()
        self.visibilityGateQueued = false
        self:ApplyVisibilityGateAll()
    end)
end

function apply:RefreshLiveAurasForUnit(unitType)
    if not ufCore.frames then
        return
    end
    if ufCore.groupUnits and ufCore.groupUnits[unitType] then
        for i = 1, ufCore.groupUnits[unitType] do
            local frame = ufCore.frames[unitType .. i]
            if frame then
                self:RefreshLiveAurasOnFrame(frame)
            end
        end
        return
    end
    local frame = ufCore.frames[unitType]
    if frame then
        self:RefreshLiveAurasOnFrame(frame)
    end
end

function apply:FlushPending()
    local frames = self.pendingFrames
    self.pendingFrames = {}
    for frame in pairs(frames) do
        if frame then
            self:UpdateFrame(frame)
        end
    end
end

function apply:QueueFrame(frame)
    self.pendingFrames[frame] = true
end

function apply:GetPoolHolder()
    if not self.poolHolder then
        local holder = CreateFrame('Frame')
        holder:Hide()
        self.poolHolder = holder
    end
    return self.poolHolder
end

function apply:DestroyContainer(container)
    if not container then
        return
    end
    if container.SetEnabled then
        container:SetEnabled(false)
    end
    container:Hide()
    container:ClearAllPoints()
    container:SetParent(nil)
end

function apply:ReturnContainerToPool(container)
    if not container then
        return
    end
    if container.SetEnabled then
        container:SetEnabled(false)
    end
    container:Hide()
    container:ClearAllPoints()
    container:SetParent(self:GetPoolHolder())
    self.containerGraveyard[#self.containerGraveyard + 1] = container
end

function apply:ReleaseContainer(container, hardSig)
    if not container then
        return
    end
    if hardSig and container._exuiHardSig == hardSig then
        self:ReturnContainerToPool(container)
        return
    end
    self:DestroyContainer(container)
end

function apply:PurgeYard(displayID)
    local yard = self.containerGraveyard
    if #yard == 0 then
        return
    end
    if not displayID then
        for i = 1, #yard do
            self:DestroyContainer(yard[i])
        end
        wipe(yard)
        return
    end
    local kept = {}
    for i = 1, #yard do
        local container = yard[i]
        if container._exuiDisplayID ~= displayID then
            kept[#kept + 1] = container
        else
            self:DestroyContainer(container)
        end
    end
    self.containerGraveyard = kept
end

function apply:PopPooledContainer(hardSig)
    local yard = self.containerGraveyard
    for i = #yard, 1, -1 do
        if yard[i]._exuiHardSig == hardSig then
            return table.remove(yard, i)
        end
    end
end

function apply:CountPooledContainers(hardSig)
    local count = 0
    for _, container in ipairs(self.containerGraveyard) do
        if container._exuiHardSig == hardSig then
            count = count + 1
        end
    end
    return count
end

function apply:GetRequiredAuraContainerCount(unitType)
    local num = ufAuras:GetMaxDisplaysForUnitType(unitType)
    local db = ufCore:GetDBForUnit(unitType)
    if db and db.dispelOverlayEnable then
        num = num + 1
    end
    return num
end

function apply:EnsureHeaderContainers(unitType)
    local headers = ufCore.headers
    if not headers then return end

    local num = self:GetRequiredAuraContainerCount(unitType)
    if unitType == 'party' then
        local header = ufCore:GetPartySecureHeader(headers.party)
        if header and header.SetNumAuraContainers then
            header:SetNumAuraContainers(num)
        end
    elseif unitType == 'raid' then
        local container = headers.raid
        if container and container.groupHeaders then
            for _, groupHeader in ipairs(container.groupHeaders) do
                if groupHeader.SetNumAuraContainers then
                    groupHeader:SetNumAuraContainers(num)
                end
            end
        end
    end
end

-- ClearAuraGroups is private/forbidden to addons, so rebuild like Aura Displays:
-- disable + detach the old container, then create a fresh one.
function apply:DiscardContainer(frame, displayID)
    if not frame.UFAuraContainers then
        return
    end
    local container = frame.UFAuraContainers[displayID]
    if not container then
        return
    end
    frame.UFAuraContainers[displayID] = nil
    self:ReturnContainerToPool(container)
end

function apply:IsGlowOnlyDisplay(display)
    local groups = display and display.groups
    if type(groups) ~= 'table' then
        return false
    end
    local found = false
    for _, group in pairs(groups) do
        local style = group and group.visual and group.visual.displayStyle
        if style then
            found = true
            if style ~= 'glow' then
                return false
            end
        end
    end
    return found
end

function apply:AnchorContainer(container, frame, display)
    local parent = frame.ElementFrame or frame
    if self:IsGlowOnlyDisplay(display) then
        parent = frame
    end
    container:SetParent(parent)
    container:ClearAllPoints()
    container:SetPoint(
        display.anchorPoint or 'BOTTOMLEFT',
        parent,
        display.relativePoint or 'TOPLEFT',
        display.XOff or 0,
        display.YOff or 0
    )
    buttonStyle:FinishPendingFrameGlows()
end

-- Keep auras above the unit-frame border (ElementFrame is frame+100 with PPBorder).
-- frameLevel is an offset above ElementFrame.
function apply:ApplyFrameLayer(container, frame, display)
    if not container or not frame then
        return
    end

    -- Glow art stays above the health bar and under ElementFrame texts.
    if self:IsGlowOnlyDisplay(display) then
        local strata = frame:GetFrameStrata()
        if strata then
            container:SetFrameStrata(strata)
        end
        local base = frame:GetFrameLevel()
        local health = frame.Health
        if health and health.GetFrameLevel then
            local healthLevel = health:GetFrameLevel()
            if healthLevel and healthLevel > base then
                base = healthLevel
            end
        end
        container:SetFrameLevel(base + 6)
        return
    end

    container:SetFrameStrata(display.frameStrata or 'MEDIUM')

    local elementFrame = frame.ElementFrame
    local baseLevel = elementFrame and elementFrame:GetFrameLevel() or frame:GetFrameLevel()
    local offset = display.frameLevel
    if offset == nil then
        offset = 10
    end
    container:SetFrameLevel(baseLevel + offset)
end

function apply:ApplyLayout(container, display)
    layout:ApplyContainerLayout(container, display)
end

function apply:ApplyProcessingPolicy(container, display)
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

function apply:ApplyItemEnchantments(container, containerConfig, display)
    if not container or not container.AddItemEnchantment or not containerConfig then
        return
    end
    if not containerConfig.itemEnchantEnable then
        return
    end

    layout:ApplyItemEnchantmentLayout(container, containerConfig, display)

    local slots = {
        { key = 'itemEnchantMainHand', slot = ITEM_ENCHANT_SLOT.MainHand },
        { key = 'itemEnchantOffHand',  slot = ITEM_ENCHANT_SLOT.OffHand },
        { key = 'itemEnchantRanged',   slot = ITEM_ENCHANT_SLOT.Ranged },
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

local function groupKey(id, groupID)
    return defaults:GetGroupKey(id, groupID)
end

local function shouldIncludeGroup(load)
    return loadConditions:ShouldIncludeGroup(load)
end

local function matchesCombat(load)
    return loadConditions:MatchesCombat(load)
end

function apply:ApplyCombatEnabled(container, displayID, display)
    resolver:ApplyCombatEnabled(container, displayID, display, groupKey, shouldIncludeGroup, matchesCombat)
end

function apply:ApplyCombatState()
    local function applyFrame(frame)
        if not frame or frame.isFake or not frame.UFAuraContainers then
            return
        end
        for displayID, container in pairs(frame.UFAuraContainers) do
            local display = ufAuras:GetDisplay(displayID)
            if container and display then
                self:ApplyCombatEnabled(container, displayID, display)
            end
        end
    end

    for _, frame in pairs(ufCore.frames or {}) do
        applyFrame(frame)
    end
    for _, frame in ipairs(ufCore.partyFrames or {}) do
        applyFrame(frame)
    end
    for _, frame in ipairs(ufCore.raidFrames or {}) do
        applyFrame(frame)
    end
end

function apply:RebuildGroups(container, displayID, display, frame)
    resolver:RebuildGroups(
        container,
        displayID,
        display,
        buttonStyle,
        groupKey,
        shouldIncludeGroup,
        matchesCombat
    )
end

function apply:UpdateGroupsInPlace(container, displayID, display)
    if not resolver:CanUpdateGroupsInPlace(container) then
        return false
    end
    for _, entry in ipairs(resolver:IterActiveGroups(display, shouldIncludeGroup)) do
        local options = resolver:ResolveGroupOptions(
            displayID, display, entry.groupID, entry.group, buttonStyle, entry.layoutIndex, groupKey
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

function apply:GetHardSignature(displayID, display)
    local cached = self.sigCache[displayID]
    if cached then
        return cached
    end
    local sig = resolver:BuildHardSignature(displayID, display, function(id, groupID)
        return defaults:GetGroupKey(id, groupID)
    end, function(load)
        return loadConditions:ShouldIncludeGroup(load)
    end)
    self.sigCache[displayID] = sig
    return sig
end

function apply:CreateContainer(frame, display)
    if not frame.CreateAuras then
        return nil
    end

    local adContainer = EXUI:GetModule('aura-displays-container')
    if adContainer and adContainer.IsAvailable and not adContainer:IsAvailable() then
        return nil
    end

    local container = frame:CreateAuras({
        maxWidth = self:GetRowWidth(frame, display),
        initialAnchor = display.containerAnchorPoint or 'TOPLEFT',
        growthX = display.horizontalGrowth or 'RIGHT',
        growthY = display.verticalGrowth or 'DOWN',
        paddingLeft = display.paddingLeft or 0,
        paddingRight = display.paddingRight or 0,
        paddingTop = display.paddingTop or 0,
        paddingBottom = display.paddingBottom or 0,
    })
    return container
end

function apply:PrepareContainer(container, displayID, display, hardSig, frame)
    container._exuiHardSig = hardSig
    container._exuiDisplayID = displayID
    if container.SetFlowLayoutMaximumLineSize then
        container:SetFlowLayoutMaximumLineSize(self:GetRowWidth(frame, display))
    end
    if container.SetEnabled then
        container:SetEnabled(ufAuras:IsDisplayEnabled(display))
    end
    self:ApplyProcessingPolicy(container, display)
    self:RebuildGroups(container, displayID, display, frame)
    self:ApplyItemEnchantments(container, display.container, display)
    container:SetParent(self:GetPoolHolder())
    container:Hide()
end

function apply:BindPreparedContainer(frame, displayID, display, container)
    self:AnchorContainer(container, frame, display)
    self:ApplyFrameLayer(container, frame, display)
    self:ApplyLayout(container, display)
    if container.SetFlowLayoutMaximumLineSize then
        container:SetFlowLayoutMaximumLineSize(self:GetRowWidth(frame, display))
    end
    if container.SetUnit and frame.__unit then
        container:SetUnit(frame.__unit)
    end
    if container.SetEnabled then
        container:SetEnabled(ufAuras:IsDisplayEnabled(display))
    end
    self:ApplyProcessingPolicy(container, display)
    layout:ApplyItemEnchantmentLayout(container, display.container, display)
    if not self:UpdateGroupsInPlace(container, displayID, display) then
        self:RebuildGroups(container, displayID, display, frame)
    end
    container:SetShown(self:ShouldShowContainer(frame, displayID))
    if container.UpdateAllAuras then
        container:UpdateAllAuras()
    end
end

-- Container creation is expensive; spread the refill across frames instead of one hitch
function apply:PrewarmPool()
    if self.prewarmQueued then
        return
    end
    self:PrewarmStep()
end

function apply:PrewarmStep()
    self.prewarmQueued = false
    if InCombatLockdown() then
        return
    end

    local budget = self.PREWARM_PER_FRAME
    local perDisplay = self.PREWARM_MIN
    local poolHolder = self:GetPoolHolder()
    if not self.prewarmFrame then
        self.prewarmFrame = CreateFrame('Frame', nil, poolHolder)
        self.prewarmFrame:SetSize(200, 40)
    end

    for _, unitType in ipairs(defaults.UNIT_ORDER) do
        local displays = ufAuras:GetDisplaysForUnitType(unitType)
        for displayID, display in pairs(displays) do
            if ufAuras:IsDisplayEnabled(display) and ufAuras:DisplayHasLoadableGroup(display) then
                local hardSig = self:GetHardSignature(displayID, display)
                while self:CountPooledContainers(hardSig) < perDisplay do
                    if budget <= 0 then
                        self.prewarmQueued = true
                        C_Timer.After(0, function()
                            self:PrewarmStep()
                        end)
                        return
                    end
                    budget = budget - 1
                    local container = self:CreateContainer(self.prewarmFrame, display)
                    if not container then
                        break
                    end
                    self:PrepareContainer(container, displayID, display, hardSig, self.prewarmFrame)
                    self.containerGraveyard[#self.containerGraveyard + 1] = container
                end
            end
        end
    end
end

function apply:GetRowWidth(frame, display)
    if display.matchUnitFrameWidth ~= false then
        return math.max(1, frame:GetWidth() or 1)
    end
    if display.rowWidth and display.rowWidth > 0 then
        return display.rowWidth
    end
    return math.max(1, frame:GetWidth() or 1)
end

function apply:ConfigureContainer(frame, displayID, display, container)
    container._exuiDisplayID = displayID
    self:AnchorContainer(container, frame, display)
    self:ApplyFrameLayer(container, frame, display)
    self:ApplyLayout(container, display)
    if container.SetFlowLayoutMaximumLineSize then
        container:SetFlowLayoutMaximumLineSize(self:GetRowWidth(frame, display))
    end

    if container.SetUnit and frame.__unit then
        container:SetUnit(frame.__unit)
    end
    if container.SetEnabled then
        container:SetEnabled(ufAuras:IsDisplayEnabled(display))
    end

    self:ApplyProcessingPolicy(container, display)
    container:SetShown(self:ShouldShowContainer(frame, displayID))
    self:RebuildGroups(container, displayID, display, frame)
    self:ApplyItemEnchantments(container, display.container, display)

    if container.UpdateAllAuras then
        container:UpdateAllAuras()
    end
end

function apply:SuppressLiveAurasOnFakeFrame(frame)
    if not frame.UFAuraContainers then
        frame.UFAuraContainers = {}
        return
    end
    local ids = {}
    for displayID in pairs(frame.UFAuraContainers) do
        table.insert(ids, displayID)
    end
    for _, displayID in ipairs(ids) do
        self:DiscardContainer(frame, displayID)
    end
end

apply.encounterStale = {}

function apply:ForEachLiveFrame(callback)
    local seen = {}
    local function visit(frame)
        if not frame or frame.isFake or seen[frame] then
            return
        end
        seen[frame] = true
        callback(frame)
    end
    for _, frame in pairs(ufCore.frames or {}) do
        visit(frame)
    end
    for _, frame in ipairs(ufCore.partyFrames or {}) do
        visit(frame)
    end
    for _, frame in ipairs(ufCore.raidFrames or {}) do
        visit(frame)
    end
end

function apply:DisableEncounterContainer(container)
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

function apply:DestroyEncounterContainer(container)
    if not container then
        return
    end
    self:DisableEncounterContainer(container)
    pcall(function()
        container:ClearAllPoints()
        container:SetParent(nil)
    end)
end

function apply:QueueStaleEncounterContainer(container)
    if not container or container._exuiEncounterStale then
        return
    end
    container._exuiEncounterStale = true
    self:DisableEncounterContainer(container)
    self.encounterStale[#self.encounterStale + 1] = container
end

function apply:ReleaseStaleEncounterContainers()
    if InCombatLockdown() then
        return
    end
    for _, container in ipairs(self.encounterStale) do
        self:DestroyEncounterContainer(container)
    end
    wipe(self.encounterStale)
end

function apply:DisableFrameEncounterContainers(frame)
    for displayID, container in pairs(frame.UFEncounterContainers or {}) do
        frame.UFEncounterContainers[displayID] = nil
        self:QueueStaleEncounterContainer(container)
    end
end

function apply:HideKeptEncounterContainers()
    self:ForEachLiveFrame(function(frame)
        for _, container in pairs(frame.UFEncounterContainers or {}) do
            if not container._exuiEncounterDisabled then
                pcall(function()
                    container:Hide()
                end)
            end
        end
    end)
end

function apply:DisableAllEncounterContainers()
    self:ForEachLiveFrame(function(frame)
        self:DisableFrameEncounterContainers(frame)
    end)
end

function apply:ReleaseAllEncounterContainers()
    if InCombatLockdown() then
        return
    end
    self:ForEachLiveFrame(function(frame)
        for displayID, container in pairs(frame.UFEncounterContainers or {}) do
            frame.UFEncounterContainers[displayID] = nil
            self:DestroyEncounterContainer(container)
        end
    end)
    self:ReleaseStaleEncounterContainers()
end

function apply:CreateEncounterContainer(frame, displayID, display, encounterID, include, sig)
    local adContainer = EXUI:GetModule('aura-displays-container')
    if adContainer and adContainer.IsAvailable and not adContainer:IsAvailable() then
        return nil
    end
    local parent = frame.ElementFrame or frame
    local container
    if frame.CreateAuras then
        local ok, created = pcall(frame.CreateAuras, frame, {
            maxWidth = self:GetRowWidth(frame, display),
            initialAnchor = display.containerAnchorPoint or 'TOPLEFT',
            growthX = display.horizontalGrowth or 'RIGHT',
            growthY = display.verticalGrowth or 'DOWN',
            paddingLeft = display.paddingLeft or 0,
            paddingRight = display.paddingRight or 0,
            paddingTop = display.paddingTop or 0,
            paddingBottom = display.paddingBottom or 0,
        })
        if ok then
            container = created
        end
    end
    if not container then
        local ok, created = pcall(CreateFrame, 'AuraContainer', nil, parent, 'CustomAuraContainerTemplate')
        if ok then
            container = created
        end
    end
    if not container then
        return nil
    end

    container._exuiEncounterID = encounterID
    container._exuiEncounterSig = sig
    container._exuiDisplayID = displayID
    local configured = pcall(function()
        self:AnchorContainer(container, frame, display)
        self:ApplyFrameLayer(container, frame, display)
        self:ApplyLayout(container, display)
        if container.SetFlowLayoutMaximumLineSize then
            container:SetFlowLayoutMaximumLineSize(self:GetRowWidth(frame, display))
        end
        if container.SetUnit and frame.__unit then
            container:SetUnit(frame.__unit)
        end
        if container.SetEnabled then
            container:SetEnabled(ufAuras:IsDisplayEnabled(display))
        end
        if container.SetAuraProcessingPolicy then
            if resolver:DisplayNeedsProcessAura(display, include) then
                local processAuraOptions = display.container and display.container.processAuraOptions or {}
                container:SetAuraProcessingPolicy(1, processAuraOptions)
            else
                container:SetAuraProcessingPolicy(0)
            end
        end
        container:SetShown(self:ShouldShowContainer(frame, displayID))
        resolver:RebuildGroups(container, displayID, display, buttonStyle, groupKey, include)
        if container.UpdateAllAuras then
            container:UpdateAllAuras()
        end
    end)
    if not configured then
        self:QueueStaleEncounterContainer(container)
        return nil
    end
    return container
end

function apply:GetEncounterSignature(displayID, display, encounterID, include)
    self.encounterSigCache = self.encounterSigCache or {}
    local byDisplay = self.encounterSigCache[displayID]
    local sig = byDisplay and byDisplay[encounterID]
    if sig then
        return sig
    end
    sig = resolver:BuildHardSignature(displayID, display, function(id, groupID)
        return defaults:GetGroupKey(id, groupID)
    end, include)
    if not byDisplay then
        byDisplay = {}
        self.encounterSigCache[displayID] = byDisplay
    end
    byDisplay[encounterID] = sig
    return sig
end

function apply:EnsureEncounterContainer(frame, displayID, display, encounterID)
    local include = function(load)
        return loadConditions:ShouldIncludeEncounterGroup(load, encounterID)
    end
    local sig = self:GetEncounterSignature(displayID, display, encounterID, include)
    frame.UFEncounterContainers = frame.UFEncounterContainers or {}
    local existing = frame.UFEncounterContainers[displayID]
    if existing and not existing._exuiEncounterDisabled
        and existing._exuiEncounterID == encounterID
        and existing._exuiEncounterSig == sig then
        pcall(function()
            existing:SetShown(self:ShouldShowContainer(frame, displayID))
            if existing:IsShown() and existing.UpdateAllAuras then
                existing:UpdateAllAuras()
            end
        end)
        return
    end
    if existing then
        frame.UFEncounterContainers[displayID] = nil
        self:QueueStaleEncounterContainer(existing)
    end
    frame.UFEncounterContainers[displayID] = self:CreateEncounterContainer(
        frame, displayID, display, encounterID, include, sig
    )
end

function apply:EnsureEncounterContainers(frame, encounterID)
    if not frame or frame.isFake then
        return
    end
    local unitType = ufAuras:GetUnitTypeForFrame(frame)
    if not unitType then
        return
    end
    local displays = ufAuras:GetDisplaysForUnitType(unitType)
    local keep = {}
    for displayID, display in pairs(displays) do
        if ufAuras:IsDisplayEnabled(display) and loadConditions:DisplayHasEncounterGroups(display, encounterID) then
            keep[displayID] = true
            self:EnsureEncounterContainer(frame, displayID, display, encounterID)
        end
    end
    for displayID, container in pairs(frame.UFEncounterContainers or {}) do
        if not keep[displayID] then
            frame.UFEncounterContainers[displayID] = nil
            self:QueueStaleEncounterContainer(container)
        end
    end
end

function apply:OnEncounterStart(encounterID)
    self:ForEachLiveFrame(function(frame)
        self:EnsureEncounterContainers(frame, encounterID)
    end)
end

function apply:UpdateFrame(frame)
    if not frame then
        return
    end

    frame.UFAuraContainers = frame.UFAuraContainers or {}

    -- ForceShow remaps fake frames to player; without this, party/raid preview
    -- shows your helpful auras on every slot. UF Aura Editor uses its own
    -- scenario preview instead of live containers.
    if frame.isFake then
        self:SuppressLiveAurasOnFakeFrame(frame)
        return
    end

    local unitType = ufAuras:GetUnitTypeForFrame(frame)
    if not unitType then
        return
    end

    local encounterID = loadConditions:GetActiveEncounter()
    if encounterID then
        self:EnsureEncounterContainers(frame, encounterID)
    end

    self:RegisterVisibilityEvents(frame)

    local displays = ufAuras:GetDisplaysForUnitType(unitType)
    local keep = {}

    for displayID, display in pairs(displays) do
        local shouldShow = ufAuras:IsDisplayEnabled(display) and ufAuras:DisplayHasLoadableGroup(display)

        if shouldShow then
            keep[displayID] = true
            local hardSig = self:GetHardSignature(displayID, display)
            local container = frame.UFAuraContainers[displayID]
            if container and container._exuiHardSig == hardSig and self:UpdateGroupsInPlace(container, displayID, display) then
                self:AnchorContainer(container, frame, display)
                self:ApplyFrameLayer(container, frame, display)
                self:ApplyLayout(container, display)
                if container.SetFlowLayoutMaximumLineSize then
                    container:SetFlowLayoutMaximumLineSize(self:GetRowWidth(frame, display))
                end
                if container.SetUnit and frame.__unit then
                    container:SetUnit(frame.__unit)
                end
                if container.SetEnabled then
                    container:SetEnabled(ufAuras:IsDisplayEnabled(display))
                end
                self:ApplyProcessingPolicy(container, display)
                layout:ApplyItemEnchantmentLayout(container, display.container, display)
                container:SetShown(self:ShouldShowContainer(frame, displayID))
            else
                if container then
                    frame.UFAuraContainers[displayID] = nil
                    self:ReleaseContainer(container, hardSig)
                    container = nil
                end
                if not container then
                    container = self:PopPooledContainer(hardSig)
                end
                if not container then
                    container = self:CreateContainer(frame, display)
                end
                if not container then
                    if InCombatLockdown() then
                        self:QueueFrame(frame)
                    end
                    return
                end
                frame.UFAuraContainers[displayID] = container
                container._exuiDisplayID = displayID
                if container._exuiHardSig == hardSig then
                    self:BindPreparedContainer(frame, displayID, display, container)
                else
                    container._exuiHardSig = hardSig
                    self:ConfigureContainer(frame, displayID, display, container)
                end
            end
        elseif frame.UFAuraContainers[displayID] then
            self:DiscardContainer(frame, displayID)
        end
    end

    for displayID in pairs(frame.UFAuraContainers) do
        if not keep[displayID] then
            self:DiscardContainer(frame, displayID)
        end
    end

    self:ApplyVisibilityGate(frame)
end

function apply:RefreshDisplay(displayID)
    self:InvalidateSignatures()
    local display = ufAuras:GetDisplay(displayID)
    if not display then
        self:RefreshAll()
        return
    end

    self:PurgeYard(displayID)
    for unitType in pairs(display.units or {}) do
        self:EnsureHeaderContainers(unitType)
        ufCore:UpdateFrameForUnit(unitType)
    end
end

function apply:RefreshAll()
    self:InvalidateSignatures()
    self:PurgeYard()
    for _, unitType in ipairs(defaults.UNIT_ORDER) do
        self:EnsureHeaderContainers(unitType)
    end
    for _, unitType in ipairs(defaults.UNIT_ORDER) do
        ufCore:UpdateFrameForUnit(unitType)
    end
end
