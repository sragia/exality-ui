---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIOptionsMain
local optionsMain = EXUI:GetModule('options-main')

---@class EXUIAuraDisplaysModule
local auraDisplays = EXUI:GetModule('aura-displays')

---@class EXUIAuraDisplaysDisplay
local displayModule = EXUI:GetModule('aura-displays-display')

---@class EXUIAuraDisplaysContainer
local containerModule = EXUI:GetModule('aura-displays-container')

---@class EXUIAuraDisplaysLayout
local layout = EXUI:GetModule('aura-displays-layout')

---@class EXUIAuraDisplaysButtonStyle
local buttonStyle = EXUI:GetModule('aura-displays-button-style')

---@class EXUIAuraDisplaysGroupNav
local groupNav = EXUI:GetModule('aura-displays-group-nav')

---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

---@class EXUIAuraDisplaysPreview
local preview = EXUI:GetModule('aura-displays-preview')

local MODULE_NAME = 'Aura Displays'
local PREVIEW_STRATA = 'DIALOG'
local PREVIEW_FRAME_LEVEL = 500

-- Known-good icon file IDs (same pool style as unit frame aura previews).
local PREVIEW_ICON_POOL = {
    236265,
    135959,
    135926,
    135874,
    135875,
    135897,
    1360764,
    236279,
    236247,
    1305150,
    237545,
    135735,
    135817,
    236205,
    1100170,
    135799,
    413586,
    237537,
    136224,
    879926,
    1380372,
    7455385,
    132306,
}

local PREVIEW_SCENARIOS = {
    {
        spellID = 17,
        spellName = 'Power Word: Shield',
        isHelpful = true,
        stacks = 0,
        remaining = 332,
        total = 600,
    },
    {
        spellID = 589,
        spellName = 'Shadow Word: Pain',
        isHarmful = true,
        stacks = 8,
        remaining = 12,
        total = 18,
        dispelName = 'Magic',
    },
    {
        spellID = 1943,
        spellName = 'Rupture',
        isHarmful = true,
        stacks = 3,
        remaining = 4.5,
        total = 16,
        dispelName = 'Curse',
    },
    {
        spellID = 1126,
        spellName = 'Mark of the Wild',
        isHelpful = true,
        stacks = 1,
        remaining = 3720,
        total = 3600,
    },
    {
        spellID = 2818,
        spellName = 'Deadly Poison',
        isHarmful = true,
        stacks = 1,
        remaining = 2.1,
        total = 12,
        dispelName = 'Poison',
    },
    {
        spellID = 774,
        spellName = 'Rejuvenation',
        isHelpful = true,
        stacks = 0,
        remaining = 0,
        total = 12,
        expired = true,
    },
    {
        spellID = 465,
        spellName = 'Devotion Aura',
        isHelpful = true,
        stacks = 0,
        remaining = 0,
        total = 0,
        permanent = true,
    },
}

preview.toggled = {}
preview.manual = {}
preview.userDisabled = {}
preview.states = {}

local function getSpellTexture(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    end
    return GetSpellTexture(spellID)
end

local function pickRandomPreviewIcons(count)
    local pool = {}
    for i = 1, #PREVIEW_ICON_POOL do
        pool[i] = PREVIEW_ICON_POOL[i]
    end

    local icons = {}
    for i = 1, math.min(count, #pool) do
        local index = math.random(1, #pool)
        icons[i] = pool[index]
        table.remove(pool, index)
    end
    return icons
end

local function getScenarioIcon(state, index, scenario)
    if state.previewIcons and state.previewIcons[index] then
        return state.previewIcons[index]
    end
    if scenario.icon then
        return scenario.icon
    end
    if scenario.spellID then
        return getSpellTexture(scenario.spellID)
    end
    return PREVIEW_ICON_POOL[((index - 1) % #PREVIEW_ICON_POOL) + 1]
end

local function resolveButton(button)
    if button.GetObjectTable then
        return button:GetObjectTable()
    end
    return button
end

function preview:EnsureState(stateKey)
    self.states[stateKey] = self.states[stateKey] or {
        container = nil,
        buttons = {},
        previewIcons = nil,
        savedStrata = nil,
        savedLevel = nil,
    }
    return self.states[stateKey]
end

local function ensureState(displayID)
    return preview:EnsureState(displayID)
end

function preview:GetScenarios()
    return PREVIEW_SCENARIOS
end

function preview:PickRandomIcons(count)
    return pickRandomPreviewIcons(count)
end

function preview:IsOptionsOpen()
    return optionsMain.window and optionsMain.window:IsShown()
end

function preview:IsToggled(displayID)
    return self.toggled[displayID] == true
end

function preview:IsConfiguring(displayID)
    return self.toggled[displayID] == true and self:IsOptionsOpen()
end

function preview:SetToggled(displayID, enabled, manual)
    if enabled then
        self.userDisabled[displayID] = nil
        self.toggled[displayID] = true
        if manual then
            self.manual[displayID] = true
        end
        self:Activate(displayID)
        self:Refresh(displayID)
        return
    end

    self.toggled[displayID] = nil
    self.manual[displayID] = nil
    if manual then
        self.userDisabled[displayID] = true
    end
    self:Deactivate(displayID)
end

function preview:ClearAutoPreviews(exceptID)
    local remove = {}
    for displayID in pairs(self.toggled) do
        if displayID ~= exceptID and not self.manual[displayID] then
            remove[#remove + 1] = displayID
        end
    end
    for _, displayID in ipairs(remove) do
        self:SetToggled(displayID, false)
    end
end

function preview:SyncPreviewToggles()
    if optionsFields.splitView and optionsFields.splitView.SyncPreviewToggles then
        optionsFields.splitView:SyncPreviewToggles(function(id)
            return preview:IsToggled(id)
        end)
    end
end

function preview:HookSplitViewSelection(splitView)
    if not splitView or splitView._exuiAuraPreviewSelectHooked then
        return
    end
    splitView._exuiAuraPreviewSelectHooked = true

    local previous = splitView.onItemChange
    splitView.onItemChange = function(id)
        preview.userDisabled[id] = nil
        if previous then
            previous(id)
        end
    end
end

function preview:Init()
    optionsController:Observe('selectedModule', function()
        self:Sync()
    end)

    hooksecurefunc(optionsFields, 'AddSplitView', function(self, module)
        if module and module.GetName and module:GetName() == MODULE_NAME then
            preview:HookSplitViewSelection(self.splitView)
        end
    end)

    hooksecurefunc(optionsFields, 'RefreshFields', function()
        self:Sync()
    end)

    hooksecurefunc(optionsFields, 'Refresh', function()
        self:Sync()
    end)

    hooksecurefunc(optionsMain, 'Show', function()
        C_Timer.After(0, function()
            preview:Sync()
        end)
    end)

    if optionsMain.window then
        self:HookOptionsWindow(optionsMain.window)
    end

    hooksecurefunc(optionsMain, 'CreateWindow', function(self)
        if self.window then
            preview:HookOptionsWindow(self.window)
        end
    end)
end

function preview:HookOptionsWindow(window)
    if window.exuiAuraPreviewHooked then
        return
    end
    window.exuiAuraPreviewHooked = true

    local previousOnClose = window.onClose
    window.onClose = function()
        preview:Clear()
        if previousOnClose then
            previousOnClose()
        end
    end
end

function preview:Sync()
    if not self:IsOptionsOpen() or optionsController:GetSelectedModuleName() ~= MODULE_NAME then
        self:Clear()
        return
    end

    local itemID = optionsFields.currItemID
    self:ClearAutoPreviews(itemID)

    if itemID and auraDisplays:GetDisplay(itemID) and not self.userDisabled[itemID] then
        if not self.toggled[itemID] then
            self:SetToggled(itemID, true)
        end
    end

    for displayID in pairs(self.toggled) do
        if not auraDisplays:GetDisplay(displayID) then
            self.toggled[displayID] = nil
            self.manual[displayID] = nil
            self:Deactivate(displayID)
        else
            self:Activate(displayID)
            self:Refresh(displayID)
        end
    end

    self:SyncPreviewToggles()
end

function preview:Activate(displayID)
    self:EnsureDisplayFrame(displayID)
    self:ElevateDisplayFrame(displayID)
    self:SuppressAuras(displayID)
end

function preview:Clear()
    for displayID in pairs(self.toggled) do
        self:Deactivate(displayID)
    end
    wipe(self.toggled)
    wipe(self.manual)
    wipe(self.userDisabled)
end

function preview:Deactivate(displayID)
    self:HidePreview(displayID)
    self:RestoreDisplayFrame(displayID)
    self:RestoreAuras(displayID)
end

function preview:EnsureDisplayFrame(displayID)
    local display = auraDisplays:GetDisplay(displayID)
    if not display or not display.enable then
        return
    end

    if not displayModule.frames[displayID] then
        displayModule:Refresh(displayID, display)
    end

    local frame = displayModule.frames[displayID]
    if frame then
        layout:ApplyDisplayPosition(frame, display)
        frame:Show()
    end
end

function preview:ElevateDisplayFrame(displayID)
    local frame = displayModule.frames[displayID]
    if not frame then
        return
    end

    local state = ensureState(displayID)
    if not state.savedStrata then
        state.savedStrata = frame:GetFrameStrata()
        state.savedLevel = frame:GetFrameLevel()
    end

    frame:SetFrameStrata(PREVIEW_STRATA)
    frame:SetFrameLevel(PREVIEW_FRAME_LEVEL)
end

function preview:RestoreDisplayFrame(displayID)
    local frame = displayModule.frames[displayID]
    local state = self.states[displayID]
    if not frame or not state or not state.savedStrata then
        return
    end

    frame:SetFrameStrata(state.savedStrata)
    frame:SetFrameLevel(state.savedLevel)
    state.savedStrata = nil
    state.savedLevel = nil
end

function preview:SuppressAuras(displayID)
    local frame = displayModule.frames[displayID]
    if not frame then
        return
    end

    if frame.AuraContainer then
        if frame.AuraContainer.SetEnabled then
            frame.AuraContainer:SetEnabled(false)
        end
        frame.AuraContainer:Hide()
    end

    if frame.EditPlaceholder then
        frame.EditPlaceholder:Hide()
    end
end

function preview:RestoreAuras(displayID)
    local display = auraDisplays:GetDisplay(displayID)
    if not display or not display.enable then
        return
    end

    local frame = displayModule.frames[displayID]
    displayModule:Refresh(displayID, display)

    if frame and containerModule:IsEditMode(frame) then
        containerModule:SetEditMode(frame, display, true)
    end
end

function preview:PositionPreviewContainer(container, frame, display)
    local anchor = display.containerAnchorPoint or 'TOPLEFT'
    container:ClearAllPoints()
    container:SetPoint(anchor, frame, anchor, 0, 0)
end

function preview:EnsurePreviewContainer(stateKey, frame, display, positionFn)
    local state = self:EnsureState(stateKey)
    if state.container then
        state.container:ClearAllPoints()
        if positionFn then
            positionFn(state.container, frame, display)
        else
            state.container:SetParent(frame)
            self:PositionPreviewContainer(state.container, frame, display)
        end
        return state.container
    end

    if not containerModule:IsAvailable() then
        return nil
    end

    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn('Blizzard_AuraContainer')
    end

    local ok, container = pcall(CreateFrame, 'AuraContainer', nil, frame, 'CustomAuraContainerTemplate')
    if not ok or not container then
        return nil
    end

    if container.SetEnabled then
        container:SetEnabled(false)
    end

    container:Show()
    state.container = container
    if positionFn then
        positionFn(container, frame, display)
    else
        self:PositionPreviewContainer(container, frame, display)
    end
    return container
end

function preview:DestroyButtons(state)
    for _, button in ipairs(state.buttons) do
        local btn = resolveButton(button)
        if btn.ClearAuraInstance then
            btn:ClearAuraInstance()
        end
        buttonStyle:Clear(btn)
        -- AuraButton forbids ChangeParent; leave parented and hide.
        button:Hide()
        button:ClearAllPoints()
    end
    wipe(state.buttons)
end

function preview:CreatePreviewButton(parent)
    if not parent then
        return nil
    end

    local ok, button = pcall(CreateFrame, 'AuraButton', nil, parent, 'CustomAuraButtonTemplate')
    if not ok or not button then
        return nil
    end

    local btn = resolveButton(button)
    btn.exuiIsPreview = true
    if btn.EnableMouse then
        btn:EnableMouse(false)
    end
    if btn.SetMouseMotionEnabled then
        btn:SetMouseMotionEnabled(false)
    end

    if btn.UpdateAuraDisplay then
        btn:UpdateAuraDisplay()
    end

    return button
end

function preview:FormatDuration(remaining, visual)
    if remaining <= 0 then
        return visual and visual.durationExpiredText or ''
    end

    local formatKey = visual and visual.durationFormat or durationFormat.FORMAT_FALLBACK
    if formatKey == durationFormat.FORMAT_MMSS then
        if remaining >= 3600 then
            return string.format('%dh', math.floor(remaining / 3600))
        end
        if remaining >= 180 then
            return string.format('%dm', math.floor(remaining / 60))
        end
        if remaining >= 60 then
            return string.format('%d:%02d', math.floor(remaining / 60), math.floor(remaining % 60))
        end
        if remaining >= 5 then
            return string.format('%d', math.floor(remaining))
        end
        return string.format('%.1f', remaining)
    end

    if remaining >= 60 then
        return string.format('%d:%02d', math.floor(remaining / 60), math.floor(remaining % 60))
    end
    if remaining >= 10 then
        return string.format('%d', math.floor(remaining + 0.5))
    end
    return string.format('%.1f', remaining)
end

function preview:ApplyIcon(btn, scenario, visual, state, index)
    local icon = btn.GetIcon and btn:GetIcon() or btn.Icon
    if not icon then
        return
    end

    icon:SetTexture(getScenarioIcon(state, index, scenario))
    buttonStyle:ApplyIconTexCoord(icon, visual)
    icon:Show()
end

function preview:ApplyStacks(btn, scenario, visual)
    if not visual.showStacks then
        return
    end

    local stackText = btn.GetApplicationCount and btn:GetApplicationCount() or btn.ApplicationCount
    if not stackText then
        return
    end

    local stacks = scenario.stacks or 0
    if stacks > 1 then
        stackText:SetText(tostring(stacks))
    else
        stackText:SetText('')
    end
    stackText:Show()
end

function preview:ApplyDuration(btn, scenario, visual)
    local remaining = scenario.remaining or 0
    local total = scenario.total or 60
    local now = GetTime()

    if visual.showDurationCooldown and visual.displayStyle ~= 'bar' then
        local cooldown = btn.GetDurationCooldown and btn:GetDurationCooldown() or btn.DurationCooldownFrame
        if cooldown then
            if scenario.expired then
                cooldown:Clear()
            else
                cooldown:SetCooldown(now - (total - remaining), total)
            end
            cooldown:Show()
        end
    end

    if not visual.showDurationText then
        return
    end

    local durationText = btn.GetDurationText and btn:GetDurationText() or btn.DurationText
    if not durationText then
        return
    end

    if scenario.expired then
        durationText:SetText(visual.durationExpiredText or '')
        durationText:Show()
        return
    end

    if scenario.permanent then
        durationText:SetText(visual.durationZeroText or '')
        durationText:Show()
        return
    end

    if btn.DurationTextBinding and C_DurationUtil then
        local duration = C_DurationUtil.CreateDuration()
        duration:SetTimeFromEnd(now + remaining, total, 1)
        btn.DurationTextBinding:SetDuration(duration)
        btn.DurationTextBinding:SetEnabled(true)
    else
        durationText:SetText(self:FormatDuration(remaining, visual))
    end
    durationText:Show()
end

function preview:ApplyDurationBar(btn, scenario, visual)
    if visual.displayStyle ~= 'bar' then
        return
    end

    local statusBar = btn.BarStatusBar
    if not statusBar and btn.GetDurationBar then
        statusBar = btn:GetDurationBar()
    end
    if not statusBar or not statusBar.SetTimerDuration or not C_DurationUtil then
        return
    end

    if scenario.expired then
        return
    end

    local remaining = scenario.remaining or 0
    local total = scenario.total or 60
    local now = GetTime()
    local duration = C_DurationUtil.CreateDuration()

    if scenario.permanent or (remaining == 0 and total == 0) then
        duration:SetTimeSpan(0, 0)
    else
        duration:SetTimeFromEnd(now + remaining, total, 1)
    end

    local direction = visual.barTimerDirection == 'ElapsedTime'
        and Enum.StatusBarTimerDirection.ElapsedTime
        or Enum.StatusBarTimerDirection.RemainingTime
    statusBar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, direction)
end

function preview:ApplyDispelBorder(btn, scenario, visual)
    local typeBorder = btn.AuraTypeBorderTexture
    local atlasBorder = btn.AuraBorderTexture
    local auraTypeDispel = btn.DispelAuraTypeTexture
    local iconTexture = btn.DispelIconTexture
    local iconHost = btn.DispelIconHost

    if buttonStyle:UsesAuraTypeIconBorder(visual) then
        typeBorder = typeBorder or buttonStyle:CreateAuraTypeBorder(btn)
        if scenario.dispelName and AuraUtil and AuraUtil.SetAuraBorderColor then
            AuraUtil.SetAuraBorderColor(typeBorder, scenario.dispelName)
            typeBorder:Show()
        else
            typeBorder:Hide()
        end
    elseif typeBorder then
        typeBorder:Hide()
    end

    local showBorder = buttonStyle:ShouldShowDispelBorder(visual)
    local showIcon = buttonStyle:ShouldShowDispelIcon(visual)
    if showBorder and buttonStyle:GetDispelBorderKind(visual) == 'Minimal'
        and buttonStyle:UsesAuraTypeIconBorder(visual) then
        showBorder = false
    end

    if visual.displayStyle == 'bar' or not scenario.dispelName then
        showBorder = false
        showIcon = false
    end

    if atlasBorder then
        atlasBorder:Hide()
    end
    if auraTypeDispel then
        auraTypeDispel:Hide()
    end
    if iconHost then
        iconHost:Hide()
    elseif iconTexture then
        iconTexture:Hide()
    end

    if showBorder then
        if buttonStyle:GetDispelBorderKind(visual) == 'Minimal' then
            auraTypeDispel = auraTypeDispel or buttonStyle:CreateDispelAuraTypeTexture(btn)
            buttonStyle:ApplyDispelMinimalBorderLayout(btn)
            if AuraUtil and AuraUtil.SetAuraBorderColor then
                AuraUtil.SetAuraBorderColor(auraTypeDispel, scenario.dispelName)
            end
            auraTypeDispel:Show()
        else
            atlasBorder = atlasBorder or buttonStyle:CreateDispelBorderTexture(btn)
            buttonStyle:ApplyDispelBorderLayout(btn, visual)
            if AuraUtil and AuraUtil.SetAuraBorderAtlas then
                AuraUtil.SetAuraBorderAtlas(atlasBorder, scenario.dispelName, visual.dispelBorderShowIcon)
            elseif AuraUtil and AuraUtil.SetAuraBorderColor then
                AuraUtil.SetAuraBorderColor(atlasBorder, scenario.dispelName)
            end
            atlasBorder:Show()
        end
    end

    if showIcon then
        iconTexture = iconTexture or buttonStyle:CreateDispelIconHost(btn, visual)
        if btn.DispelIconHost then
            btn.DispelIconHost:Show()
        end
        if AuraUtil and AuraUtil.SetAuraDispelTypeIcon then
            AuraUtil.SetAuraDispelTypeIcon(iconTexture, scenario.dispelName)
        elseif AuraUtil and AuraUtil.SetAuraBorderAtlas then
            AuraUtil.SetAuraBorderAtlas(iconTexture, scenario.dispelName, true)
        end
        iconTexture:Show()
    end
end

function preview:ApplySpellName(btn, scenario, visual)
    local spellName = btn.GetSpellName and btn:GetSpellName() or btn.SpellNameText
    if not spellName then
        return
    end

    if visual.showSpellName then
        spellName:SetText(scenario.spellName or '')
        spellName:Show()
    else
        spellName:Hide()
    end
end

function preview:ApplyScenario(button, scenario, visual, state, index)
    local btn = resolveButton(button)

    local function applyPreview()
        if btn.ClearAuraInstance then
            btn:ClearAuraInstance()
        end

        buttonStyle:Apply(btn, visual)
        button:Show()

        preview:ApplyIcon(btn, scenario, visual, state, index)
        preview:ApplyStacks(btn, scenario, visual)
        preview:ApplyDuration(btn, scenario, visual)
        preview:ApplyDurationBar(btn, scenario, visual)
        preview:ApplyDispelBorder(btn, scenario, visual)
        preview:ApplySpellName(btn, scenario, visual)
    end

    if securecallfunction then
        securecallfunction(applyPreview)
    else
        applyPreview()
    end
end

function preview:LayoutButtons(container, buttons, display, visual)
    layout:ApplyPreviewFlowLayout(container, display, buttons, visual)
end

function preview:HidePreview(stateKey)
    local state = self.states[stateKey]
    if not state then
        return
    end

    self:DestroyButtons(state)
    state.previewIcons = nil

    if state.container then
        state.container:Hide()
        state.container:ClearAllPoints()
        state.container:SetSize(1, 1)
    end
end

function preview:GetPreviewCount(group)
    local conditions = group and group.conditions
    if not conditions then
        return #PREVIEW_SCENARIOS
    end
    local maxCount = conditions.maxFrameCount
    if not maxCount or maxCount <= 0 then
        return #PREVIEW_SCENARIOS
    end
    return math.min(#PREVIEW_SCENARIOS, maxCount)
end

--- Build fake aura buttons on any parent frame (Aura Displays or Unit Frames).
---@param stateKey string
---@param frame Frame parent unit/display frame
---@param display table display config (layout/growth/rowWidth)
---@param visual table group visual config
---@param positionFn function|nil optional (container, frame, display) anchor helper
---@param maxCount number|nil optional cap (Max Auras); defaults to all scenarios
function preview:BuildPreviewOnFrame(stateKey, frame, display, visual, positionFn, maxCount)
    if not frame or not display or not visual then
        return
    end

    local needed = #PREVIEW_SCENARIOS
    if maxCount and maxCount > 0 then
        needed = math.min(needed, maxCount)
    end
    if needed <= 0 then
        self:HidePreview(stateKey)
        return
    end

    local state = self:EnsureState(stateKey)
    if not state.previewIcons or #state.previewIcons < needed then
        state.previewIcons = pickRandomPreviewIcons(#PREVIEW_SCENARIOS)
    end

    local container = self:EnsurePreviewContainer(stateKey, frame, display, positionFn)
    if not container then
        return
    end

    while #state.buttons < needed do
        local button = self:CreatePreviewButton(container)
        if button then
            table.insert(state.buttons, button)
        else
            break
        end
    end

    for index = 1, #state.buttons do
        local button = state.buttons[index]
        if index <= needed then
            local scenario = PREVIEW_SCENARIOS[index]
            if button and scenario then
                -- Created under container already; AuraButton cannot be reparented.
                self:ApplyScenario(button, scenario, visual, state, index)
            end
        else
            local btn = resolveButton(button)
            if btn.ClearAuraInstance then
                btn:ClearAuraInstance()
            end
            buttonStyle:Clear(btn)
            button:Hide()
            button:ClearAllPoints()
        end
    end

    if needed == 0 or #state.buttons == 0 then
        container:Hide()
        return
    end

    local activeButtons = {}
    for index = 1, needed do
        activeButtons[index] = state.buttons[index]
    end
    self:LayoutButtons(container, activeButtons, display, visual)
    container:Show()
    -- Show / layout can reset strata and level; re-apply so UF auras stay in front.
    if positionFn then
        positionFn(container, frame, display)
    end
end

function preview:GetPreviewGroup(displayID, display)
    if optionsFields.currItemID == displayID then
        groupNav:EnsureGroupSelected(displayID)
        local groupID = auraDisplays.currGroupID
        return groupID and display.groups and display.groups[groupID]
    end

    local groupID = display.groupOrder and display.groupOrder[1]
    return groupID and display.groups and display.groups[groupID]
end

function preview:Refresh(displayID)
    if not self:IsConfiguring(displayID) then
        return
    end

    local display = auraDisplays:GetDisplay(displayID)
    if not display or not display.enable then
        self:HidePreview(displayID)
        return
    end

    self:EnsureDisplayFrame(displayID)
    self:ElevateDisplayFrame(displayID)
    self:SuppressAuras(displayID)

    local frame = displayModule.frames[displayID]
    if not frame then
        return
    end

    layout:ApplyDisplayPosition(frame, display)

    local group = self:GetPreviewGroup(displayID, display)
    if not group then
        self:HidePreview(displayID)
        return
    end

    local visual = group.visual or {}
    self:BuildPreviewOnFrame(displayID, frame, display, visual, nil, self:GetPreviewCount(group))
end
