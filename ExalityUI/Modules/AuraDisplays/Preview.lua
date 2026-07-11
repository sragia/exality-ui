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

preview.activeDisplayID = nil
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

local function ensureState(displayID)
    preview.states[displayID] = preview.states[displayID] or {
        container = nil,
        buttons = {},
        previewIcons = nil,
        savedStrata = nil,
        savedLevel = nil,
    }
    return preview.states[displayID]
end

function preview:IsOptionsOpen()
    return optionsMain.window and optionsMain.window:IsShown()
end

function preview:IsConfiguring(displayID)
    return self.activeDisplayID == displayID and self:IsOptionsOpen()
end

function preview:Init()
    optionsController:Observe('selectedModule', function()
        self:Sync()
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
    if not self:IsOptionsOpen()
        or optionsController:GetSelectedModuleName() ~= MODULE_NAME
        or not optionsFields.currItemID then
        self:Clear()
        return
    end

    self:SetActive(optionsFields.currItemID)
    self:Refresh(optionsFields.currItemID)
end

function preview:SetActive(displayID)
    if self.activeDisplayID and self.activeDisplayID ~= displayID then
        self:Deactivate(self.activeDisplayID)
    end

    self.activeDisplayID = displayID
    self:EnsureDisplayFrame(displayID)
    self:ElevateDisplayFrame(displayID)
    self:SuppressAuras(displayID)
end

function preview:Clear()
    if self.activeDisplayID then
        self:Deactivate(self.activeDisplayID)
    end
    self.activeDisplayID = nil
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

function preview:EnsurePreviewContainer(frame, display)
    local state = ensureState(frame.displayID)
    if state.container then
        self:PositionPreviewContainer(state.container, frame, display)
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
    self:PositionPreviewContainer(container, frame, display)
    return container
end

function preview:DestroyButtons(state)
    for _, button in ipairs(state.buttons) do
        local btn = resolveButton(button)
        if btn.ClearAuraInstance then
            btn:ClearAuraInstance()
        end
        buttonStyle:Clear(btn)
        button:Hide()
        button:SetParent(nil)
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
    if visual.displayStyle == 'bar' or not visual.showDispelBorder or not scenario.dispelName then
        local border = btn.GetAuraBorder and btn:GetAuraBorder() or btn.AuraBorder or btn.AuraBorderTexture
        if border then
            border:Hide()
        end
        return
    end

    local border = btn.GetAuraBorder and btn:GetAuraBorder() or btn.AuraBorder or btn.AuraBorderTexture
    if not border then
        return
    end

    buttonStyle:ApplyDispelBorderLayout(btn, visual)

    if AuraUtil and AuraUtil.SetAuraBorderAtlas then
        AuraUtil.SetAuraBorderAtlas(border, scenario.dispelName, visual.dispelBorderShowIcon)
    elseif AuraUtil and AuraUtil.SetAuraBorderColor then
        AuraUtil.SetAuraBorderColor(border, scenario.dispelName)
    end
    border:Show()
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

function preview:HidePreview(displayID)
    local state = self.states[displayID]
    if not state then
        return
    end

    self:DestroyButtons(state)
    state.previewIcons = nil

    if state.container then
        state.container:Hide()
    end
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

    groupNav:EnsureGroupSelected(displayID)
    local groupID = auraDisplays.currGroupID
    local group = groupID and display.groups and display.groups[groupID]
    if not group then
        self:HidePreview(displayID)
        return
    end

    local visual = group.visual or {}
    local state = ensureState(displayID)
    if not state.previewIcons then
        state.previewIcons = pickRandomPreviewIcons(#PREVIEW_SCENARIOS)
    end

    local container = self:EnsurePreviewContainer(frame, display)
    if not container then
        return
    end

    local needed = #PREVIEW_SCENARIOS
    while #state.buttons < needed do
        local button = self:CreatePreviewButton(container)
        if button then
            table.insert(state.buttons, button)
        else
            break
        end
    end
    while #state.buttons > needed do
        local button = table.remove(state.buttons)
        local btn = resolveButton(button)
        if btn.ClearAuraInstance then
            btn:ClearAuraInstance()
        end
        buttonStyle:Clear(btn)
        button:Hide()
        button:SetParent(nil)
    end

    for index, scenario in ipairs(PREVIEW_SCENARIOS) do
        local button = state.buttons[index]
        if button then
            button:SetParent(container)
            self:ApplyScenario(button, scenario, visual, state, index)
        end
    end

    if #state.buttons == 0 then
        container:Hide()
        return
    end

    self:LayoutButtons(container, state.buttons, display, visual)
    container:Show()
end
