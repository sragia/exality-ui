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

apply.pendingFrames = {}

function apply:Init()
    if not ufAuras:IsSupported() then
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

function apply:GetRequiredAuraContainerCount(unitType)
    if not ufAuras:IsSupported() then
        return 0
    end
    local num = ufAuras:GetMaxDisplaysForUnitType(unitType)
    local db = ufCore:GetDBForUnit(unitType)
    if db and db.dispelOverlayEnable then
        num = num + 1
    end
    return num
end

function apply:EnsureHeaderContainers(unitType)
    if not ufAuras:IsSupported() then
        return
    end
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
    if container.SetEnabled then
        container:SetEnabled(false)
    end
    container:Hide()
    container:ClearAllPoints()
    container:SetParent(nil)
    frame.UFAuraContainers[displayID] = nil
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

-- Keep auras above the unit-frame border (ElementFrame is frame+100 with PPBorder).
-- frameLevel is an offset above ElementFrame.
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

function apply:CreateContainer(frame, display)
    if not ufAuras:IsSupported() or not frame.CreateAuras then
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
        container:SetEnabled(display.enable ~= false)
    end

    self:ApplyProcessingPolicy(container, display)
    container:Show()
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

function apply:UpdateFrame(frame)
    if not frame or not ufAuras:IsSupported() then
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

    local displays = ufAuras:GetDisplaysForUnitType(unitType)
    local keep = {}

    for displayID, display in pairs(displays) do
        local shouldShow = display.enable ~= false and ufAuras:DisplayHasLoadableGroup(display)

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
                    container:SetEnabled(display.enable ~= false)
                end
                self:ApplyProcessingPolicy(container, display)
                layout:ApplyItemEnchantmentLayout(container, display.container, display)
                container:Show()
            else
                -- CreateAuras / CustomAuraContainer may still fail under lockdown for
                -- non-aura parenting; queue and retry if create fails in combat.
                self:DiscardContainer(frame, displayID)
                container = self:CreateContainer(frame, display)
                if not container then
                    if InCombatLockdown() then
                        self:QueueFrame(frame)
                    end
                    return
                end
                container._exuiHardSig = hardSig
                frame.UFAuraContainers[displayID] = container
                self:ConfigureContainer(frame, displayID, display, container)
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
end

function apply:RefreshDisplay(displayID)
    if not ufAuras:IsSupported() then
        return
    end
    local display = ufAuras:GetDisplay(displayID)
    if not display then
        self:RefreshAll()
        return
    end

    for unitType in pairs(display.units or {}) do
        self:EnsureHeaderContainers(unitType)
        ufCore:UpdateFrameForUnit(unitType)
    end
end

function apply:RefreshAll()
    if not ufAuras:IsSupported() then
        return
    end
    for _, unitType in ipairs(defaults.UNIT_ORDER) do
        self:EnsureHeaderContainers(unitType)
    end
    for _, unitType in ipairs(defaults.UNIT_ORDER) do
        ufCore:UpdateFrameForUnit(unitType)
    end
end
