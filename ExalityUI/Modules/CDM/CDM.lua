---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIStyles
local styles = EXUI:GetModule('styles')

---@class EXUICDMData
local data = EXUI:GetModule('cdm-data')

---@class EXUICDMMigration
local migration = EXUI:GetModule('cdm-migration')

---@class EXUICDMSources
local sources = EXUI:GetModule('cdm-sources')

---@class EXUICDMElement
local element = EXUI:GetModule('cdm-element')

---@class EXUICDMLayout
local layout = EXUI:GetModule('cdm-layout')

---@class EXUICDMAuras
local auras = EXUI:GetModule('cdm-auras')

---@class EXUICDMPreview
local preview = EXUI:GetModule('cdm-preview')

---@class EXUICDMBridge
local bridge = EXUI:GetModule('cdm-bridge')

---@class EXUIAuraDisplaysLoadConditions
local loadConditions = EXUI:GetModule('aura-displays-load-conditions')

---@class EXUICDMModule
local cdm = EXUI:GetModule('cdm')

cdm.frames = {}
cdm.freeItems = {}
cdm.freeGroups = {}

local MODULE_EVENTS = {
    'PLAYER_ENTERING_WORLD',
    'PLAYER_REGEN_DISABLED',
    'PLAYER_REGEN_ENABLED',
    'ZONE_CHANGED_NEW_AREA',
    'CHALLENGE_MODE_START',
    'CHALLENGE_MODE_COMPLETED',
    'GROUP_ROSTER_UPDATE',
    'PLAYER_ROLES_ASSIGNED',
    'PLAYER_SPECIALIZATION_CHANGED',
    'PLAYER_TARGET_CHANGED',
    'PLAYER_FOCUS_CHANGED',
    'UNIT_PET',
}

local UNIT_EVENTS = {
    PLAYER_TARGET_CHANGED = 'target',
    PLAYER_FOCUS_CHANGED = 'focus',
    UNIT_PET = 'pet',
}

function cdm:Init()
    data:GetDB()
    migration:Run()
    optionsController:RegisterModule(self)

    styles:RegisterCallback(function()
        if self.enabled then
            self:Rebuild()
        end
    end)
    styles:RegisterTarget('cdm', {
        label = 'Cooldown Manager',
        order = 30,
        get = function()
            local shared
            for _, node in pairs(data:GetNodes()) do
                for _, style in ipairs({ node.iconAppearance.style, node.barAppearance.style }) do
                    if shared and shared ~= style then
                        return nil
                    end
                    shared = style
                end
            end
            return shared
        end,
        set = function(styleID)
            for _, node in pairs(data:GetNodes()) do
                node.iconAppearance.style = styleID
                node.barAppearance.style = styleID
            end
            self:Refresh()
        end,
    })

    self:Enable()
end

function cdm:GetName()
    return 'Cooldown Manager'
end

function cdm:GetOrder()
    return 50
end

function cdm:GetProfileExportSpec()
    return { id = 'cdm', keys = { 'cdm' } }
end

function cdm:Enable()
    if not self.enabled then
        self.enabled = true
        EXUI:RegisterEventHandler(MODULE_EVENTS, 'cdm', function(event, ...)
            cdm:OnModuleEvent(event, ...)
        end)
    end
    if IsLoggedIn() then
        self:Rebuild()
    end
end

function cdm:OnModuleEvent(event, eventUnit)
    if event == 'PLAYER_REGEN_DISABLED' or event == 'PLAYER_REGEN_ENABLED' then
        self.inCombat = event == 'PLAYER_REGEN_DISABLED'
        self:RefreshVisibility()
        return
    end
    if event == 'PLAYER_TARGET_CHANGED' then
        self:RefreshRanges()
    end
    local changedUnit = UNIT_EVENTS[event]
    if event == 'UNIT_PET' and eventUnit ~= 'player' then
        return
    end
    if changedUnit then
        auras:OnUnitChanged(self.frames, changedUnit)
        return
    end
    if event == 'PLAYER_ENTERING_WORLD' or self:LoadStateChanged() then
        self:Rebuild()
    end
end

-- Options fire on every slider step; aura slots cannot be reused, so rebuilds wait for the edit to settle.
function cdm:Refresh()
    if not self.enabled or self.refreshPending then
        return
    end
    self.refreshPending = true
    C_Timer.After(0.2, function()
        self.refreshPending = false
        self:Rebuild()
    end)
end

------------------------------------------------------------
-- Frames

local function acquire(list, create)
    local frame = table.remove(list)
    return frame or create()
end

function cdm:CreateItemFrame()
    local frame = element:Create(UIParent)
    frame.Cooldown:HookScript('OnCooldownDone', function()
        if frame.nodeID and not frame.previewing then
            cdm:RefreshItem(frame)
        end
    end)
    return frame
end

function cdm:CreateGroupFrame()
    local frame = CreateFrame('Frame', nil, UIParent)
    EXUI:RegisterSnapFrame(frame)
    frame:SetSize(1, 1)
    return frame
end

function cdm:ReleaseFrame(id)
    local frame = self.frames[id]
    if not frame then
        return
    end
    self.frames[id] = nil
    if editor:IsFrameRegistered(frame) then
        editor:UnregisterFrameForEditor(frame)
    end
    frame.nodeID = nil
    frame.present = nil
    if frame.isGroup then
        auras:Clear(frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent(UIParent)
        table.insert(self.freeGroups, frame)
    else
        element:Reset(frame)
        frame:SetParent(UIParent)
        table.insert(self.freeItems, frame)
    end
end

function cdm:GetFrame(id)
    return self.frames[id]
end

------------------------------------------------------------
-- Loading

function cdm:PassesLoad(node)
    local load = node.load
    return not load.hasLoadConditions or loadConditions:MatchesStatic(load)
end

local function inAuraRow(id, ignorePreviewed)
    local seen = {}
    local parentID = data:GetParentID(data:GetNode(id))
    while parentID and not seen[parentID] do
        seen[parentID] = true
        local parent = data:GetNode(parentID)
        if layout:IsAuraRow(parent) and not (ignorePreviewed and preview:IsShownForPreview(parentID)) then
            return true
        end
        parentID = data:GetParentID(parent)
    end
    return false
end

-- Everything inside an Aura Row lives in its Blizzard container; frames exist only while the row is previewed.
function cdm:IsFlowChild(id)
    return inAuraRow(id, true)
end

function cdm:IsFlowEligible(node, row)
    return node.kind == 'item' and node.source.type == 'aura' and node.source.unit == row.layout.flowUnit
        and #node.source.spellIDs > 0
end

function cdm:ShouldLoad(id)
    if not data:IsEnabled(id) or not data:IsOwnedHere(id) or self:IsFlowChild(id) then
        return false
    end
    local seen = {}
    local node = data:GetNode(id)
    while node and not seen[node] do
        seen[node] = true
        if not self:PassesLoad(node) then
            return false
        end
        node = data:GetParent(node)
    end
    return true
end

function cdm:IsPositionedByParent(node)
    local parent = data:GetParent(node)
    return parent ~= nil and not layout:IsFree(parent)
end

local function depthOf(id)
    local depth = 0
    local node = data:GetNode(id)
    local seen = {}
    while node and not seen[node] do
        seen[node] = true
        node = data:GetParent(node)
        depth = depth + 1
    end
    return depth
end

function cdm:GetWanted()
    local wanted = {}
    for id in pairs(data:GetNodes()) do
        if self:ShouldLoad(id) then
            wanted[id] = true
        end
    end
    return wanted
end

-- Aura Row children have no frames, so their load state is tracked separately.
function cdm:GetFlowLoadKey()
    local loaded = {}
    for id, node in pairs(data:GetNodes()) do
        if node.kind == 'item' and self:IsFlowChild(id) and self:PassesLoad(node) then
            loaded[#loaded + 1] = id
        end
    end
    table.sort(loaded)
    return table.concat(loaded, ',')
end

function cdm:LoadStateChanged()
    if self:GetFlowLoadKey() ~= self.flowLoadKey then
        return true
    end
    local wanted = self:GetWanted()
    for id in pairs(wanted) do
        if not self.frames[id] then
            return true
        end
    end
    for id in pairs(self.frames) do
        if not wanted[id] then
            return true
        end
    end
    return false
end

local function byDepth(ids, deepestFirst)
    local depths = {}
    for _, id in ipairs(ids) do
        depths[id] = depthOf(id)
    end
    table.sort(ids, function(a, b)
        if deepestFirst then
            return depths[a] > depths[b]
        end
        return depths[a] < depths[b]
    end)
    return ids
end

function cdm:Rebuild()
    if not self.enabled then
        return
    end
    self.inCombat = UnitAffectingCombat('player')

    local wanted = self:GetWanted()
    self.flowLoadKey = self:GetFlowLoadKey()
    bridge:SetEnabled(self:NeedsBridge(wanted), function()
        cdm:OnBridgeChanged()
    end)
    for id in pairs(self.frames) do
        local frame = self.frames[id]
        local node = data:GetNode(id)
        if not wanted[id] or not node or frame.isGroup ~= (node.kind == 'group') then
            self:ReleaseFrame(id)
        end
    end

    for id in pairs(wanted) do
        if not self.frames[id] then
            local node = data:GetNode(id)
            local frame
            if node.kind == 'group' then
                frame = acquire(self.freeGroups, function() return self:CreateGroupFrame() end)
                frame.isGroup = true
            else
                frame = acquire(self.freeItems, function() return self:CreateItemFrame() end)
                frame.isGroup = false
            end
            frame.nodeID = id
            self.frames[id] = frame
        end
    end

    local ids = {}
    for id in pairs(self.frames) do
        ids[#ids + 1] = id
    end
    for _, id in ipairs(byDepth(ids)) do
        local frame = self.frames[id]
        local node = data:GetNode(id)
        local parentFrame = self.frames[data:GetParentID(node)]
        frame:SetParent(parentFrame or UIParent)
        if frame.isGroup then
            self:ApplyGroup(frame, node)
        else
            self:ApplyItem(frame, node)
        end
    end

    self:RefreshVisibility()
    EXUI:GetModule('cdm-designer'):RefreshShown()
end

function cdm:LayoutAll()
    local groups = {}
    for id, frame in pairs(self.frames) do
        if frame.isGroup then
            groups[#groups + 1] = id
        end
    end
    for _, id in ipairs(byDepth(groups, true)) do
        self:LayoutGroup(id, true)
    end
end

function cdm:ApplyPosition(frame, node)
    local strata, level = node.frameStrata, node.frameLevel
    local parent = data:GetParent(node)
    if self:IsPositionedByParent(node) then
        local parentFrame = self.frames[data:GetParentID(node)]
        frame:SetFrameStrata(parentFrame:GetFrameStrata())
        frame:SetFrameLevel(parentFrame:GetFrameLevel() + 1)
        self:SetEditable(frame, node, false)
        return
    end
    frame:SetFrameStrata(strata)
    frame:SetFrameLevel(level)
    if node.kind == 'group' and layout:IsFree(node) then
        frame:ClearAllPoints()
        frame:SetPoint('CENTER', parent and self.frames[data:GetParentID(node)] or UIParent, 'CENTER')
        self:SetEditable(frame, node, false)
        return
    end
    local pos = node.position
    frame:ClearAllPoints()
    frame:SetPoint(pos.anchorPoint, UIParent, pos.relativePoint, pos.XOff, pos.YOff)
    EXUI:SnapFrameToPixels(frame)
    self:SetEditable(frame, node, true)
end

function cdm:SetEditable(frame, node, editable)
    local registered = editor:IsFrameRegistered(frame)
    local label = 'CDM: ' .. (node.name or '')
    if not editable then
        if registered then
            editor:UnregisterFrameForEditor(frame)
        end
        return
    end
    if registered then
        editor:UpdateFrameLabel(frame, label)
        return
    end
    editor:RegisterFrameForEditor(frame, label, function(refFrame)
        local id = refFrame.nodeID
        if not id then
            return
        end
        local point, _, relativePoint, x, y = refFrame:GetPoint(1)
        data:SetValue(id, 'position', { anchorPoint = point, relativePoint = relativePoint, XOff = x, YOff = y })
    end, function()
        cdm:SetPreviewAll(true)
    end, function()
        cdm:SetPreviewAll(false)
    end)
end

function cdm:SetPreviewAll(enabled)
    if self.previewAll == enabled then
        return
    end
    self.previewAll = enabled
    self:RefreshVisibility()
end

function cdm:ApplyGroup(frame, node)
    self:ApplyPosition(frame, node)
    frame.flow = layout:IsAuraRow(node) and self:BuildAuraRow(frame, node) or nil
    frame.previewing = preview:IsShownForPreview(frame.nodeID)
    frame:Show()
end

-- Aura Rows switch between Blizzard's flow and normal frames, so preview changes rebuild.
function cdm:ApplyPreview()
    self:Rebuild()
end

function cdm:RestartPreviews()
    for _, frame in pairs(self.frames) do
        if frame.previewing and not frame.isGroup then
            element:RestartPreview(frame)
        end
    end
end

function cdm:ApplyItem(frame, node)
    self:ApplyPosition(frame, node)
    local look
    if node.display == 'bar' then
        look = data:ResolveBar(node)
        element:ApplyBar(frame, look)
    else
        look = data:ResolveIcon(node)
        element:ApplyIcon(frame, look)
    end
    local texts = data:ResolveTexts(node)
    element:ApplyTexts(frame, texts, node.source.type == 'aura' and node.visibility.auraState or nil)
    element:SetSource(frame, node.source)
    element:ApplyProcGlow(frame, look)
    sources:WatchSpell(frame.state, node.source)
    element:ApplyAuras(frame, node, look, texts)
    local visibility = node.visibility
    if visibility.cooldownState == 'threshold' and node.source.type ~= 'aura' then
        element:SetThreshold(frame, visibility.threshold, visibility.hiddenAlpha)
    else
        element:SetThreshold(frame, nil)
    end
    element:SetPreview(frame, preview:IsPreviewed(frame.nodeID))

    frame:UnregisterAllEvents()
    for _, event in ipairs(sources.EVENTS[node.source.type] or {}) do
        frame:RegisterEvent(event)
    end
    frame:SetScript('OnEvent', function(selfFrame, event, ...)
        cdm:OnItemEvent(selfFrame, event, ...)
    end)
    self:RefreshItem(frame, true)
end

function cdm:OnItemEvent(frame, event, ...)
    if event == 'SPELL_RANGE_CHECK_UPDATE' then
        local spellID, isInRange, checksRange = ...
        if not sources:MatchesSpell(frame.source, spellID) then
            return
        end
        frame.state.inRange = not checksRange or isInRange
    elseif event == 'SPELL_ACTIVATION_OVERLAY_GLOW_SHOW' or event == 'SPELL_ACTIVATION_OVERLAY_GLOW_HIDE' then
        local spellID = ...
        if not sources:MatchesSpell(frame.source, spellID) then
            return
        end
        frame.state.procActive = event == 'SPELL_ACTIVATION_OVERLAY_GLOW_SHOW'
    elseif event == 'SPELLS_CHANGED' or event == 'PLAYER_EQUIPMENT_CHANGED' then
        element:InvalidateTexture(frame)
    elseif event == 'ITEM_DATA_LOAD_RESULT' then
        local itemID = ...
        if itemID ~= sources:GetSourceID(frame.source) then
            return
        end
        element:InvalidateTexture(frame)
    end
    self:RefreshItem(frame)
end

function cdm:RefreshRanges()
    for _, frame in pairs(self.frames) do
        if not frame.isGroup and frame.source and frame.source.type == 'spell' then
            sources:WatchRange(frame.state, frame.source)
            self:RefreshItem(frame, true)
        end
    end
    self:LayoutAll()
end

function cdm:RefreshItem(frame, skipLayout)
    element:Refresh(frame)
    self:UpdateFrameVisibility(frame, skipLayout)
end

------------------------------------------------------------
-- Blizzard Cooldown Manager bridge (aura / effect state that is secret elsewhere)

local function spellIDsOf(source)
    local spellID = tonumber(source.spellID)
    return spellID and { spellID, C_Spell.GetOverrideSpell(spellID) } or {}
end

-- Only switched on while a loaded item relies on it.
function cdm:NeedsBridge(wanted)
    for id in pairs(wanted) do
        local node = data:GetNode(id)
        -- Aura Row children are only loaded while previewed and never use it.
        if node.kind == 'item' and not inAuraRow(id, false) then
            if node.source.type == 'aura' and node.visibility.auraState == 'active' then
                return true
            end
            if node.visibility.cooldownState == 'effect' and node.source.type == 'spell' then
                return true
            end
            for _, linked in ipairs(node.source.type ~= 'aura' and node.linkedAuras or {}) do
                if linked.missingEffect ~= 'none' then
                    return true
                end
            end
        end
    end
    return false
end

-- Whether a linked aura with this missing effect is known to be down.
function cdm:LinkedMissing(node, effect)
    if node.source.type == 'aura' then
        return false
    end
    for _, linked in ipairs(node.linkedAuras or {}) do
        if linked.missingEffect == effect and bridge:IsActive(linked.spellIDs) == false then
            return true
        end
    end
    return false
end

function cdm:OnBridgeChanged()
    for _, frame in pairs(self.frames) do
        if not frame.isGroup and frame.source then
            element:Refresh(frame)
        end
    end
    self:RefreshVisibility()
end

------------------------------------------------------------
-- Visibility

function cdm:EvaluateVisibility(node, state)
    if self.previewAll then
        return true
    end
    local visibility = node.visibility
    if visibility.combat == 'in' and not self.inCombat then
        return false
    end
    if visibility.combat == 'out' and self.inCombat then
        return false
    end
    if node.kind == 'item' then
        if node.source.type == 'aura' and visibility.auraState == 'active'
            and bridge:IsActive(node.source.spellIDs) == false then
            return false
        end
        if self:LinkedMissing(node, 'hide') then
            return false
        end
        if visibility.cooldownState == 'effect' and node.source.type == 'spell'
            and bridge:IsActive(spellIDsOf(node.source)) == false then
            return false
        end
    end
    if node.kind == 'item' and state and node.source.type ~= 'aura' then
        if visibility.cooldownState == 'cooldown' and not state.onCooldown then
            return false
        end
        if visibility.cooldownState == 'ready' and state.onCooldown then
            return false
        end
        if visibility.cooldownState == 'usable' and not state.usable then
            return false
        end
    end
    return true
end

function cdm:UpdateFrameVisibility(frame, skipLayout)
    local id = frame.nodeID
    local node = data:GetNode(id)
    if not node then
        return
    end
    local visible = frame.previewing or self:EvaluateVisibility(node, not frame.isGroup and frame.state or nil)
    local hiddenAlpha = node.visibility.hiddenAlpha
    local present = visible or hiddenAlpha > 0
    -- "Last Seconds" frames get their alpha from the threshold curve, but only while visibility rules pass
    -- and nothing is being previewed.
    local curveDriven = visible and frame.thresholdEnabled and not frame.previewing and not self.previewAll or false
    if not frame.isGroup then
        element:SetThresholdActive(frame, curveDriven)
    end
    if not curveDriven then
        frame:SetAlpha(visible and 1 or hiddenAlpha)
    end
    frame:SetShown(present)
    if frame.present ~= present then
        frame.present = present
        local parentID = data:GetParentID(node)
        local parent = data:GetNode(parentID)
        if not skipLayout and parent and parent.layout.collapse then
            self:LayoutGroup(parentID)
        end
    end
end

function cdm:RefreshVisibility()
    for _, frame in pairs(self.frames) do
        self:UpdateFrameVisibility(frame, true)
    end
    self:LayoutAll()
end

------------------------------------------------------------
-- Layout

-- Same wrap rule as Blizzard's flow layout: a line breaks when the next element would pass lineSize.
local function measureFlow(entries, horizontal, lineSize, gapMain, gapCross)
    local longest, crossTotal, lines = 0, 0, 0
    local lineMain, lineCross = 0, 0
    for index, entry in ipairs(entries) do
        local main = horizontal and entry.content.width or entry.content.height
        local cross = horizontal and entry.content.height or entry.content.width
        if index > 1 and lineMain + gapMain + main > lineSize then
            longest = math.max(longest, lineMain)
            crossTotal = crossTotal + lineCross
            lines = lines + 1
            lineMain, lineCross = 0, 0
        end
        lineMain = lineMain + (lineMain > 0 and gapMain or 0) + main
        lineCross = math.max(lineCross, cross)
    end
    longest = math.max(longest, lineMain)
    crossTotal = crossTotal + lineCross + gapCross * lines
    return longest, crossTotal
end

-- Built on Rebuild and cached: the row keeps the size it has with every aura up (so parent layouts stay put),
-- and Blizzard collapses and aligns the auras that are actually up inside it.
function cdm:BuildAuraRow(frame, node)
    local settings = node.layout
    local horizontal = settings.direction == 'horizontal'
    local gapMain = math.max(0, horizontal and settings.spacingX or settings.spacingY)
    local gapCross = math.max(0, horizontal and settings.spacingY or settings.spacingX)
    local entries = {}
    local maxMain = 1
    for _, child in ipairs(data:GetChildren(frame.nodeID)) do
        local childNode = child.node
        if self:IsFlowEligible(childNode, node) and data:IsEnabled(child.id) and self:PassesLoad(childNode) then
            local content = element:BuildFlowContent(childNode, frame)
            maxMain = math.max(maxMain, horizontal and content.width or content.height)
            entries[#entries + 1] = {
                key = child.id,
                filter = childNode.source.filter,
                onlyMine = childNode.source.onlyMine,
                spellIDs = childNode.source.spellIDs,
                content = content,
            }
        end
    end
    local lineSize = math.max(1, settings.perLine) * (maxMain + gapMain) - gapMain
    local main, cross = measureFlow(entries, horizontal, lineSize, gapMain, gapCross)
    local flow = {
        width = math.max(1, horizontal and main or cross),
        height = math.max(1, horizontal and cross or main),
        unit = settings.flowUnit,
        settings = settings,
        lineSize = lineSize,
        gapMain = gapMain,
        gapCross = gapCross,
        entries = entries,
    }
    flow.signature = auras:FlowSignature(flow)
    return flow
end

function cdm:LayoutAuraRow(frame)
    local flow = frame.flow
    frame:SetSize(flow.width, flow.height)
    auras:SyncFlow(frame, flow)
end

function cdm:LayoutGroup(id, skipParents)
    local frame = self.frames[id]
    local node = data:GetNode(id)
    if not frame or not node then
        return
    end
    local flowActive = frame.flow and not preview:IsShownForPreview(id)
    if not flowActive then
        if frame.flow then
            auras:SuspendFlow(frame)
        else
            auras:Clear(frame)
        end
    end
    if flowActive then
        self:LayoutAuraRow(frame)
    elseif not layout:IsFree(node) then
        local cells = {}
        for _, child in ipairs(data:GetChildren(id)) do
            local childFrame = self.frames[child.id]
            if childFrame and (childFrame.present or not node.layout.collapse) then
                local width, height = childFrame:GetSize()
                cells[#cells + 1] = { frame = childFrame, width = width, height = height, line = child.node.line }
            end
        end
        local width, height = layout:Arrange(frame, cells, node.layout)
        frame:SetSize(width, height)
    end
    if not skipParents and self:IsPositionedByParent(node) then
        self:LayoutGroup(data:GetParentID(node))
    end
end

