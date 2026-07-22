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
        if group and group.conditions and group.conditions.enable and loadConditions:ShouldLoad(group.load) then
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
        return loadConditions:ShouldLoad(load)
    end)
    if not needsProcessAura then
        container:SetAuraProcessingPolicy(0)
        return
    end
    local processAuraOptions = display.container and display.container.processAuraOptions or {}
    container:SetAuraProcessingPolicy(1, processAuraOptions)
end

function containerModule:RebuildGroups(frame, displayID, display)
    local container = frame.AuraContainer
    if not container then
        return
    end

    for _, entry in ipairs(resolver:IterActiveGroups(display, function(load)
        return loadConditions:ShouldLoad(load)
    end)) do
        local options = resolver:ResolveGroupOptions(
            displayID, display, entry.groupID, entry.group, buttonStyle, entry.layoutIndex
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

function containerModule:UpdateGroupsInPlace(frame, displayID, display)
    local container = frame.AuraContainer
    if not resolver:CanUpdateGroupsInPlace(container) then
        return false
    end

    for _, entry in ipairs(resolver:IterActiveGroups(display, function(load)
        return loadConditions:ShouldLoad(load)
    end)) do
        local options = resolver:ResolveGroupOptions(
            displayID, display, entry.groupID, entry.group, buttonStyle, entry.layoutIndex
        )
        resolver:ApplyGroupOptions(container, options)
    end

    if container.UpdateAllAuras then
        container:UpdateAllAuras()
    end
    return true
end

function containerModule:GetHardSignature(displayID, display)
    return resolver:BuildHardSignature(displayID, display, function(id, groupID)
        return defaults:GetGroupKey(id, groupID)
    end, function(load)
        return loadConditions:ShouldLoad(load)
    end)
end

function containerModule:ApplyItemEnchantments(frame, containerConfig)
    local container = frame.AuraContainer
    if not container or not container.AddItemEnchantment then
        return
    end

    if not containerConfig.itemEnchantEnable then
        return
    end

    layout:ApplyItemEnchantmentLayout(container, containerConfig)

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
        frame.unavailableText = frame.unavailableText or frame:CreateFontString(nil, 'OVERLAY')
        frame.unavailableText:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        frame.unavailableText:SetPoint('CENTER')
        frame.unavailableText:SetText('Aura Containers require WoW 12.1')
        frame.unavailableText:Show()
        return
    end

    if frame.unavailableText then
        frame.unavailableText:Hide()
    end

    if InCombatLockdown() then
        frame._pendingRefresh = true
        return
    end

    local hardSig = self:GetHardSignature(displayID, display)
    if frame.AuraContainer and frame._exuiHardSig == hardSig and self:UpdateGroupsInPlace(frame, displayID, display) then
        layout:ApplyDisplayPosition(frame, display)
        self:AnchorContainer(frame.AuraContainer, frame, display)
        layout:ApplyContainerLayout(frame.AuraContainer, display)
        self:ApplyUnit(frame.AuraContainer, display.container, display.enable)
        self:ApplyProcessingPolicy(frame.AuraContainer, display)
        layout:ApplyItemEnchantmentLayout(frame.AuraContainer, display.container)
        self:BindContainerSize(frame, display, displayID)
        if self:IsEditMode(frame) then
            self:SetEditMode(frame, display, true)
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
    self:ApplyItemEnchantments(frame, display.container)

    if container.UpdateAllAuras then
        container:UpdateAllAuras()
    end

    self:BindContainerSize(frame, display, displayID)

    if self:IsEditMode(frame) then
        self:SetEditMode(frame, display, true)
    end
end
