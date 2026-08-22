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

function apply:Init()
    if self.eventHandler then
        return
    end
    if not npAuras:IsSupported() then
        return
    end
    self.eventHandler = CreateFrame('Frame')
    self.eventHandler:RegisterEvent('PLAYER_REGEN_ENABLED')
    self.eventHandler:SetScript('OnEvent', function(_, event)
        if event == 'PLAYER_REGEN_ENABLED' then
            self:FlushPending()
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

function apply:DiscardContainer(frame, displayID)
    if not frame.NPAuraContainers then
        return
    end
    local container = frame.NPAuraContainers[displayID]
    if not container then
        return
    end
    if container.SetEnabled then
        container:SetEnabled(false)
    end
    container:Hide()
    container:ClearAllPoints()
    container:SetParent(nil)
    frame.NPAuraContainers[displayID] = nil
end

function apply:SetContainerUnit(container, unit)
    if container and container.SetUnit and type(unit) == 'string' then
        container:SetUnit(unit)
    end
end

function apply:DetachFrame(frame)
    if not frame or not frame.NPAuraContainers then
        return
    end
    for _, container in pairs(frame.NPAuraContainers) do
        if container.SetEnabled then
            container:SetEnabled(false)
        end
        container:Hide()
    end
end

function apply:ClearFrame(frame)
    self:DetachFrame(frame)
end

function apply:BindFrame(frame)
    if not frame or not npAuras:IsSupported() then
        return
    end
    if frame.isPreview or frame.isFriendly then
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
        return loadConditions:ShouldLoad(load)
    end)
    if not needsProcessAura then
        container:SetAuraProcessingPolicy(0)
        return
    end
    local processAuraOptions = display.container and display.container.processAuraOptions or {}
    container:SetAuraProcessingPolicy(1, processAuraOptions)
end

function apply:RebuildGroups(container, displayID, display, frame)
    local getGroupKey = function(id, groupID)
        return defaults:GetGroupKey(id, groupID)
    end
    for _, entry in ipairs(resolver:IterActiveGroups(display, function(load)
        return loadConditions:ShouldLoad(load)
    end)) do
        local options = resolver:ResolveGroupOptions(
            displayID, display, entry.groupID, entry.group, buttonStyle, entry.layoutIndex, getGroupKey
        )
        if container.AddAuraGroup then
            container:AddAuraGroup(options.groupKey, options.filterString, {
                maxFrameCount = options.maxFrameCount,
                sortMethod = options.sortMethod,
                sortDirection = options.sortDirection,
                candidateFilters = options.candidateFilters,
                layout = options.layout,
                initializeFrame = options.initializeFrame,
            })
        end
    end
end

function apply:UpdateGroupsInPlace(container, displayID, display)
    if not resolver:CanUpdateGroupsInPlace(container) then
        return false
    end
    local getGroupKey = function(id, groupID)
        return defaults:GetGroupKey(id, groupID)
    end
    for _, entry in ipairs(resolver:IterActiveGroups(display, function(load)
        return loadConditions:ShouldLoad(load)
    end)) do
        local options = resolver:ResolveGroupOptions(
            displayID, display, entry.groupID, entry.group, buttonStyle, entry.layoutIndex, getGroupKey
        )
        resolver:ApplyGroupOptions(container, options)
    end
    if container.UpdateAllAuras then
        container:UpdateAllAuras()
    end
    return true
end

function apply:GetHardSignature(displayID, display)
    return resolver:BuildHardSignature(displayID, display, function(id, groupID)
        return defaults:GetGroupKey(id, groupID)
    end, function(load)
        return loadConditions:ShouldLoad(load)
    end)
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

function apply:CreateContainer(frame, display)
    if not npAuras:IsSupported() then
        return nil
    end
    local adContainer = EXUI:GetModule('aura-displays-container')
    if adContainer and adContainer.IsAvailable and not adContainer:IsAvailable() then
        return nil
    end

    local parent = frame.ElementFrame or frame
    local container
    if frame.CreateAuras then
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

function apply:ConfigureContainer(frame, displayID, display, container)
    self:AnchorContainer(container, frame, display)
    self:ApplyFrameLayer(container, frame, display)
    self:ApplyLayout(container, display)
    if container.SetFlowLayoutMaximumLineSize then
        container:SetFlowLayoutMaximumLineSize(self:GetRowWidth(frame, display))
    end
    self:SetContainerUnit(container, frame.unit or frame.__unit)
    if container.SetEnabled then
        container:SetEnabled(display.enable ~= false)
    end
    self:ApplyProcessingPolicy(container, display)
    container:Show()
    self:RebuildGroups(container, displayID, display, frame)
    if container.UpdateAllAuras then
        container:UpdateAllAuras()
    end
end

function apply:UpdateFrame(frame)
    if not frame or not npAuras:IsSupported() then
        return
    end
    if frame.isPreview or frame.isFriendly then
        self:ClearFrame(frame)
        return
    end

    frame.NPAuraContainers = frame.NPAuraContainers or {}
    local displays = npAuras:GetDisplays()
    local keep = {}

    for displayID, display in pairs(displays) do
        local shouldShow = display.enable ~= false and npAuras:DisplayHasLoadableGroup(display)
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
                    container:SetEnabled(display.enable ~= false)
                end
                self:ApplyProcessingPolicy(container, display)
                container:Show()
            else
                self:DiscardContainer(frame, displayID)
                container = self:CreateContainer(frame, display)
                if not container then
                    if InCombatLockdown() then
                        self:QueueFrame(frame)
                    end
                    return
                end
                container._exuiHardSig = hardSig
                frame.NPAuraContainers[displayID] = container
                self:ConfigureContainer(frame, displayID, display, container)
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
    npCore:UpdateAllPlates()
end

function apply:RefreshAll()
    npCore:UpdateAllPlates()
end
