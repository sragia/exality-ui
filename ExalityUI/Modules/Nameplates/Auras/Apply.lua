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

---@class EXUINameplatesAurasDefaults
local defaults = EXUI:GetModule('np-auras-defaults')

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUINameplatesAuras
local npAuras = EXUI:GetModule('np-auras')

---@class EXUINameplatesAurasApply
local apply = EXUI:GetModule('np-auras-apply')

apply.pendingFrames = {}
apply.sigCache = {}
apply.containerGraveyard = {}
apply.PREWARM_MIN = 40
apply.PREWARM_PER_FRAME = 2

function apply:Init()
    if self.eventHandler then
        return
    end
    self.eventHandler = CreateFrame('Frame')
    self.eventHandler:RegisterEvent('PLAYER_REGEN_ENABLED')
    self.eventHandler:RegisterEvent('PLAYER_ENTERING_WORLD')
    self.eventHandler:SetScript('OnEvent', function(_, event)
        if event == 'PLAYER_REGEN_ENABLED' then
            self:FlushPending()
        end
        if event == 'PLAYER_REGEN_ENABLED' or event == 'PLAYER_ENTERING_WORLD' then
            self:PrewarmPool()
        end
    end)
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

function apply:PurgeStaleYard()
    local yard = self.containerGraveyard
    if #yard == 0 then
        return
    end
    local displays = npAuras:GetDisplays()
    local kept = {}
    for i = 1, #yard do
        local container = yard[i]
        local displayID = container._exuiDisplayID
        local display = displayID and displays[displayID]
        if display
            and npAuras:IsDisplayEnabled(display)
            and npAuras:DisplayHasLoadableGroup(display)
            and container._exuiHardSig == self:GetHardSignature(displayID, display) then
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

function apply:DiscardContainer(frame, displayID)
    if not frame.NPAuraContainers then
        return
    end
    local container = frame.NPAuraContainers[displayID]
    if not container then
        return
    end
    frame.NPAuraContainers[displayID] = nil
    self:ReturnContainerToPool(container)
end

function apply:SetContainerUnit(container, unit)
    if container and container.SetUnit and type(unit) == 'string' then
        container:SetUnit(unit)
    end
end

function apply:DetachFrame(frame)
    if not frame then
        return
    end
    if frame.NPAuraContainers then
        for _, container in pairs(frame.NPAuraContainers) do
            if container.SetEnabled then
                container:SetEnabled(false)
            end
            container:Hide()
        end
    end
    for _, container in pairs(frame.NPEncounterContainers or {}) do
        if not container._exuiEncounterDisabled then
            if container.SetEnabled then
                container:SetEnabled(false)
            end
            container:Hide()
        end
    end
end

function apply:ClearFrame(frame)
    self:DetachFrame(frame)
end

function apply:BindFrame(frame)
    if not frame then
        return
    end
    if frame.isPreview or npCore:IsFriendlyNameOnly(frame) then
        self:DetachFrame(frame)
        return
    end
    if not frame.NPAuraContainers or not next(frame.NPAuraContainers) then
        self:UpdateFrame(frame)
        return
    end
    local unit = frame.unit or frame.__unit
    for _, container in pairs(frame.NPAuraContainers) do
        self:SetContainerUnit(container, unit)
        if container.SetEnabled then
            container:SetEnabled(true)
        end
        container:Show()
        if container.UpdateAllAuras then
            container:UpdateAllAuras()
        end
    end
    local encounterID = loadConditions:GetActiveEncounter()
    for _, container in pairs(frame.NPEncounterContainers or {}) do
        if encounterID and not container._exuiEncounterDisabled and container._exuiEncounterID == encounterID then
            pcall(function()
                self:SetContainerUnit(container, unit)
                if container.SetEnabled then
                    container:SetEnabled(true)
                end
                container:Show()
                if container.UpdateAllAuras then
                    container:UpdateAllAuras()
                end
            end)
        end
    end
end

function apply:AnchorContainer(container, frame, display)
    local parent = frame.ElementFrame or frame
    container:SetParent(parent)
    container:ClearAllPoints()
    container:SetPoint(
        display.anchorPoint or 'BOTTOMLEFT',
        parent,
        display.relativePoint or 'TOPLEFT',
        display.XOff or 0,
        display.YOff or 0
    )
end

function apply:ApplyFrameLayer(container, frame, display)
    if not container or not frame then
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
    if not npCore.ForEachPlate then
        return
    end
    npCore:ForEachPlate(function(frame)
        if not frame.NPAuraContainers then
            return
        end
        for displayID, container in pairs(frame.NPAuraContainers) do
            local display = npAuras:GetDisplay(displayID)
            if container and display then
                self:ApplyCombatEnabled(container, displayID, display)
            end
        end
    end)
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

function apply:GetRowWidth(frame, display)
    if display.matchUnitFrameWidth ~= false then
        return math.max(1, (frame.db and frame.db.sizeWidth) or frame:GetWidth() or 1)
    end
    if display.rowWidth and display.rowWidth > 0 then
        return display.rowWidth
    end
    return math.max(1, (frame.db and frame.db.sizeWidth) or frame:GetWidth() or 1)
end

function apply:CreateContainer(frame, display, parent)
    local adContainer = EXUI:GetModule('aura-displays-container')
    if adContainer and adContainer.IsAvailable and not adContainer:IsAvailable() then
        return nil
    end

    parent = parent or frame.ElementFrame or frame
    local container
    if frame and frame.CreateAuras then
        container = frame:CreateAuras({
            maxWidth = self:GetRowWidth(frame, display),
            initialAnchor = display.containerAnchorPoint or 'TOPLEFT',
            growthX = display.horizontalGrowth or 'RIGHT',
            growthY = display.verticalGrowth or 'DOWN',
            paddingLeft = display.paddingLeft or 0,
            paddingRight = display.paddingRight or 0,
            paddingTop = display.paddingTop or 0,
            paddingBottom = display.paddingBottom or 0,
        })
    end
    if not container then
        local ok, created = pcall(CreateFrame, 'AuraContainer', nil, parent, 'CustomAuraContainerTemplate')
        if ok then
            container = created
        end
    end
    return container
end

function apply:PrepareContainer(container, displayID, display, hardSig, frame)
    container._exuiHardSig = hardSig
    container._exuiDisplayID = displayID
    if container.SetFlowLayoutMaximumLineSize then
        container:SetFlowLayoutMaximumLineSize(self:GetRowWidth(frame, display))
    end
    if container.SetEnabled then
        container:SetEnabled(npAuras:IsDisplayEnabled(display))
    end
    self:ApplyProcessingPolicy(container, display)
    self:RebuildGroups(container, displayID, display, frame)
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
    self:SetContainerUnit(container, frame.unit or frame.__unit)
    if container.SetEnabled then
        container:SetEnabled(npAuras:IsDisplayEnabled(display))
    end
    self:ApplyProcessingPolicy(container, display)
    if not self:UpdateGroupsInPlace(container, displayID, display) then
        self:RebuildGroups(container, displayID, display, frame)
    end
    container:Show()
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
    if InCombatLockdown() or not npCore.enabled then
        return
    end

    local targetCount = self.PREWARM_MIN
    if C_NamePlate and C_NamePlate.GetNamePlates then
        targetCount = math.max(targetCount, #C_NamePlate.GetNamePlates() + 10)
    end

    local displays = npAuras:GetDisplays()
    local displayCount = 0
    for _, display in pairs(displays) do
        if npAuras:IsDisplayEnabled(display) and npAuras:DisplayHasLoadableGroup(display) then
            displayCount = displayCount + 1
        end
    end
    if displayCount == 0 then
        return
    end

    local perDisplay = math.max(1, math.ceil(targetCount / displayCount))
    local poolHolder = self:GetPoolHolder()
    local templateFrame = self.prewarmFrame
    if not templateFrame then
        templateFrame = CreateFrame('Frame', nil, poolHolder)
        templateFrame:SetSize(200, 40)
        self.prewarmFrame = templateFrame
    end

    local budget = self.PREWARM_PER_FRAME
    for displayID, display in pairs(displays) do
        if npAuras:IsDisplayEnabled(display) and npAuras:DisplayHasLoadableGroup(display) then
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
                local container = self:CreateContainer(templateFrame, display, poolHolder)
                if not container then
                    break
                end
                self:PrepareContainer(container, displayID, display, hardSig, templateFrame)
                self.containerGraveyard[#self.containerGraveyard + 1] = container
            end
        end
    end
end

function apply:ConfigureContainer(frame, displayID, display, container)
    container._exuiDisplayID = displayID
    self:AnchorContainer(container, frame, display)
    self:ApplyFrameLayer(container, frame, display)
    self:ApplyLayout(container, display)
    if container.SetFlowLayoutMaximumLineSize then
        container:SetFlowLayoutMaximumLineSize(self:GetRowWidth(frame, display))
    end
    self:SetContainerUnit(container, frame.unit or frame.__unit)
    if container.SetEnabled then
        container:SetEnabled(npAuras:IsDisplayEnabled(display))
    end
    self:ApplyProcessingPolicy(container, display)
    container:Show()
    self:RebuildGroups(container, displayID, display, frame)
    if container.UpdateAllAuras then
        container:UpdateAllAuras()
    end
end

apply.encounterStale = {}

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

function apply:ForgetEncounterContainer(container)
    local tracked = self.encounterTracked
    if not tracked or not container then
        return
    end
    for i = #tracked, 1, -1 do
        if tracked[i] == container then
            table.remove(tracked, i)
        end
    end
end

function apply:UnslotEncounterContainer(container)
    local frame = container and container._exuiEncounterFrame
    local displayID = container and container._exuiDisplayID
    if frame and displayID and frame.NPEncounterContainers and frame.NPEncounterContainers[displayID] == container then
        frame.NPEncounterContainers[displayID] = nil
    end
end

function apply:QueueStaleEncounterContainer(container)
    if not container or container._exuiEncounterStale then
        return
    end
    container._exuiEncounterStale = true
    self:ForgetEncounterContainer(container)
    self:UnslotEncounterContainer(container)
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
    for displayID, container in pairs(frame.NPEncounterContainers or {}) do
        frame.NPEncounterContainers[displayID] = nil
        self:QueueStaleEncounterContainer(container)
    end
end

function apply:ForEachEncounterFrame(callback)
    if not npCore.ForEachPlate then
        return
    end
    npCore:ForEachPlate(function(frame)
        if frame and not frame.isPreview then
            callback(frame)
        end
    end)
end

function apply:HideKeptEncounterContainers()
    for _, container in ipairs(self.encounterTracked or {}) do
        if not container._exuiEncounterDisabled then
            pcall(function()
                container:Hide()
            end)
        end
    end
end

function apply:DisableAllEncounterContainers()
    local tracked = self.encounterTracked
    self.encounterTracked = {}
    for _, container in ipairs(tracked or {}) do
        self:UnslotEncounterContainer(container)
        self:QueueStaleEncounterContainer(container)
    end
end

function apply:ReleaseAllEncounterContainers()
    if InCombatLockdown() then
        return
    end
    local tracked = self.encounterTracked
    self.encounterTracked = {}
    for _, container in ipairs(tracked or {}) do
        self:UnslotEncounterContainer(container)
        self:DestroyEncounterContainer(container)
    end
    self:ReleaseStaleEncounterContainers()
end

function apply:CreateEncounterContainer(frame, displayID, display, encounterID, include, sig)
    local createdOk, container = pcall(self.CreateContainer, self, frame, display)
    if not createdOk then
        container = nil
    end
    if not container then
        local parent = frame.ElementFrame or frame
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
    container._exuiEncounterFrame = frame
    container._exuiEncounterUnit = frame.unit or frame.__unit
    self.encounterTracked = self.encounterTracked or {}
    self.encounterTracked[#self.encounterTracked + 1] = container
    local configured = pcall(function()
        self:AnchorContainer(container, frame, display)
        self:ApplyFrameLayer(container, frame, display)
        self:ApplyLayout(container, display)
        if container.SetFlowLayoutMaximumLineSize then
            container:SetFlowLayoutMaximumLineSize(self:GetRowWidth(frame, display))
        end
        self:SetContainerUnit(container, frame.unit or frame.__unit)
        if container.SetEnabled then
            container:SetEnabled(npAuras:IsDisplayEnabled(display))
        end
        if container.SetAuraProcessingPolicy then
            if resolver:DisplayNeedsProcessAura(display, include) then
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
    end)
    if not configured then
        self:QueueStaleEncounterContainer(container)
        return nil
    end
    return container
end

function apply:ReuseEncounterContainer(frame, display, container)
    local parent = frame.ElementFrame or frame
    local unit = frame.unit or frame.__unit
    if container:GetParent() == parent and container:IsShown() and container._exuiEncounterUnit == unit then
        return true
    end
    local ok = pcall(function()
        if container:GetParent() ~= parent then
            self:AnchorContainer(container, frame, display)
            self:ApplyFrameLayer(container, frame, display)
        end
        self:SetContainerUnit(container, unit)
        container._exuiEncounterUnit = unit
        if container.SetEnabled then
            container:SetEnabled(npAuras:IsDisplayEnabled(display))
        end
        container:Show()
        if container.UpdateAllAuras then
            container:UpdateAllAuras()
        end
    end)
    return ok
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
    frame.NPEncounterContainers = frame.NPEncounterContainers or {}
    local existing = frame.NPEncounterContainers[displayID]
    if existing and not existing._exuiEncounterDisabled
        and existing._exuiEncounterID == encounterID
        and existing._exuiEncounterSig == sig
        and self:ReuseEncounterContainer(frame, display, existing) then
        return
    end
    if existing then
        frame.NPEncounterContainers[displayID] = nil
        self:QueueStaleEncounterContainer(existing)
    end
    frame.NPEncounterContainers[displayID] = self:CreateEncounterContainer(
        frame, displayID, display, encounterID, include, sig
    )
end

function apply:EnsureEncounterContainers(frame, encounterID)
    if not frame or frame.isPreview or npCore:IsFriendlyNameOnly(frame) then
        return
    end
    local displays = npAuras:GetDisplays()
    local keep = {}
    for displayID, display in pairs(displays) do
        if npAuras:IsDisplayEnabled(display) and loadConditions:DisplayHasEncounterGroups(display, encounterID) then
            keep[displayID] = true
            self:EnsureEncounterContainer(frame, displayID, display, encounterID)
        end
    end
    for displayID, container in pairs(frame.NPEncounterContainers or {}) do
        if not keep[displayID] then
            frame.NPEncounterContainers[displayID] = nil
            self:QueueStaleEncounterContainer(container)
        end
    end
end

function apply:OnEncounterStart(encounterID)
    self:ForEachEncounterFrame(function(frame)
        self:EnsureEncounterContainers(frame, encounterID)
    end)
end

function apply:UpdateFrame(frame)
    if not frame then
        return
    end
    if frame.isPreview or npCore:IsFriendlyNameOnly(frame) then
        self:ClearFrame(frame)
        return
    end

    frame.NPAuraContainers = frame.NPAuraContainers or {}
    local encounterID = loadConditions:GetActiveEncounter()
    if encounterID then
        self:EnsureEncounterContainers(frame, encounterID)
    end
    local displays = npAuras:GetDisplays()
    local keep = {}

    for displayID, display in pairs(displays) do
        local shouldShow = npAuras:IsDisplayEnabled(display) and npAuras:DisplayHasLoadableGroup(display)
        if shouldShow then
            keep[displayID] = true
            local hardSig = self:GetHardSignature(displayID, display)
            local container = frame.NPAuraContainers[displayID]
            if container and container._exuiHardSig == hardSig and self:UpdateGroupsInPlace(container, displayID, display) then
                self:AnchorContainer(container, frame, display)
                self:ApplyFrameLayer(container, frame, display)
                self:ApplyLayout(container, display)
                if container.SetFlowLayoutMaximumLineSize then
                    container:SetFlowLayoutMaximumLineSize(self:GetRowWidth(frame, display))
                end
                self:SetContainerUnit(container, frame.unit or frame.__unit)
                if container.SetEnabled then
                    container:SetEnabled(npAuras:IsDisplayEnabled(display))
                end
                self:ApplyProcessingPolicy(container, display)
                container:Show()
            else
                if container then
                    frame.NPAuraContainers[displayID] = nil
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
                frame.NPAuraContainers[displayID] = container
                container._exuiDisplayID = displayID
                if container._exuiHardSig == hardSig then
                    self:BindPreparedContainer(frame, displayID, display, container)
                else
                    container._exuiHardSig = hardSig
                    self:ConfigureContainer(frame, displayID, display, container)
                end
            end
        elseif frame.NPAuraContainers[displayID] then
            self:DiscardContainer(frame, displayID)
        end
    end

    for displayID in pairs(frame.NPAuraContainers) do
        if not keep[displayID] then
            self:DiscardContainer(frame, displayID)
        end
    end
end

function apply:RefreshDisplay(displayID)
    self:InvalidateSignatures()
    self:PurgeYard(displayID)
    npCore:UpdateAllPlates()
end

function apply:RefreshAll()
    self:InvalidateSignatures()
    self:PurgeStaleYard()
    npCore:UpdateAllPlates()
    self:PrewarmPool()
end
