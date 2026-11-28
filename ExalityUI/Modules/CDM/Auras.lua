---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

---@class EXUIUnitFramesElementsShape
local ufShape = EXUI:GetModule('uf-element-shape')

---@class EXUIStyles
local styles = EXUI:GetModule('styles')

---@class EXUICDMAuras
local auras = EXUI:GetModule('cdm-auras')

-- Blizzard's aura container matches auras (secret ones too) and shows each slot only while its aura is up.
-- Everything we parent into a slot therefore appears only while that aura is active.
-- Slots are locked after setup, so any config change builds new containers.

local TRACKED_UNITS = { target = true, focus = true, pet = true }

auras.UNITS = {
    player = { label = 'Player', order = 1 },
    target = { label = 'Target', order = 2 },
    focus = { label = 'Focus', order = 3 },
    pet = { label = 'Pet', order = 4 },
}

auras.FILTERS = {
    HELPFUL = { label = 'Buff', order = 1 },
    HARMFUL = { label = 'Debuff', order = 2 },
}

function auras:IsAvailable()
    return EXUI:GetModule('aura-displays-container'):IsAvailable()
end

local function serialize(value, out)
    local valueType = type(value)
    if valueType ~= 'table' then
        out[#out + 1] = tostring(value)
        return
    end
    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    out[#out + 1] = '{'
    for _, key in ipairs(keys) do
        out[#out + 1] = tostring(key) .. '='
        serialize(value[key], out)
        out[#out + 1] = ','
    end
    out[#out + 1] = '}'
end

local function signature(value)
    local out = {}
    serialize(value, out)
    return table.concat(out)
end

function auras:BuildFilter(watch)
    return watch.filter .. (watch.onlyMine and '|PLAYER' or '')
end

local function spellMap(spellIDs)
    local map = {}
    for _, spellID in ipairs(spellIDs) do
        map[spellID] = true
    end
    return map
end

------------------------------------------------------------
-- Slot content (runs inside initializeFrame, before Blizzard locks the slot)

-- Remaining-time text colour: the urgent colour below urgentSeconds, the text colour above it.
-- Blizzard evaluates it against the (possibly secret) remaining time.
function auras:TextColorCurve(config)
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Step)
    local color = config.color
    if config.urgentSeconds > 0 then
        local urgent = config.urgentColor
        curve:AddPoint(0, CreateColor(urgent.r, urgent.g, urgent.b, urgent.a))
        curve:AddPoint(config.urgentSeconds, CreateColor(color.r, color.g, color.b, color.a))
    else
        curve:AddPoint(0, CreateColor(color.r, color.g, color.b, color.a))
    end
    return curve
end

local function createText(button, parent, config, kind)
    local fontString = parent:CreateFontString(nil, 'OVERLAY')
    fontString:SetFont(LSM:Fetch('font', config.font), config.fontSize, config.fontFlag)
    fontString:SetTextColor(config.color.r, config.color.g, config.color.b, config.color.a)
    fontString:SetJustifyH(config.justify)
    fontString:SetPoint(config.anchorPoint, button, config.relativePoint, config.XOff, config.YOff)
    EXUI.utils.applyFontShadow(fontString, config.textShadow, config.textShadowX, config.textShadowY,
        config.textShadowColor)
    if kind == 'cooldown' then
        local binding = C_DurationUtil.CreateDurationTextBinding()
        binding:SetFormatter(durationFormat:GetFormatter(config.format))
        binding:SetUpdateInterval(config.updateInterval)
        -- Blizzard copies the binding and then applies textColor, so the curve goes in both (the preview uses
        -- the binding directly).
        local textColor = {
            curve = auras:TextColorCurve(config),
            property = Enum.DurationTextBindingProperty.RemainingDuration,
        }
        binding:SetTextColorCurve(textColor.curve, textColor.property)
        button:SetDurationText(fontString, { binding = binding, textColor = textColor })
    elseif kind == 'charges' then
        button:SetApplicationCount(fontString)
    elseif kind == 'name' then
        button:SetSpellName(fontString)
    elseif kind == 'custom' then
        fontString:SetText(config.text)
    end
end

-- Blizzard drives one duration, count and name text per slot, so extra ones of those kinds are skipped.
local SINGLE_KINDS = { cooldown = true, charges = true, name = true }

local function applyTexts(button, texts)
    local overlay = CreateFrame('Frame', nil, button)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(button:GetFrameLevel() + 8)
    local used = {}
    for _, config in ipairs(texts) do
        local kind = config.kind
        if config.enable and not (used[kind] and SINGLE_KINDS[kind]) then
            used[kind] = true
            createText(button, overlay, config, kind)
        end
    end
end

-- Bars keep their icon in iconRect (slot coordinates); icons fill the whole slot.
local function placeInSlot(region, button, rect)
    if rect then
        region:SetPoint('TOPLEFT', button, 'TOPLEFT', rect.x, -rect.y)
        region:SetSize(rect.w, rect.h)
    else
        region:SetAllPoints(button)
    end
end

local function applyIcon(button, content)
    if content.icon == 'none' or (content.isBar and not content.iconRect) then
        return
    end
    local rect = content.iconRect
    local texture = button:CreateTexture(nil, 'ARTWORK')
    placeInSlot(texture, button, rect)
    texture:SetTexCoord(EXUI.utils.getTexCoords(rect and rect.w or content.width, rect and rect.h or content.height,
        content.zoom))
    local shape = { Mask = button:CreateMaskTexture(), masked = {}, isIcon = true }
    placeInSlot(shape.Mask, button, rect)
    local shaped = ufShape:SelectStyle(shape, content.style)
    ufShape:SetMasked(shape, texture, shaped)
    if content.icon == 'aura' then
        button:SetIcon(texture)
    else
        texture:SetTexture(content.spellTexture)
    end
end

local function applyDurationBar(button, content)
    local spec = content.durationBar
    if not spec then
        return
    end
    local bar = CreateFrame('StatusBar', nil, button)
    placeInSlot(bar, button, spec.rect)
    bar.bg = bar:CreateTexture(nil, 'BACKGROUND')
    bar.bg:SetAllPoints()
    bar.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    bar.bg:SetVertexColor(spec.backgroundColor.r, spec.backgroundColor.g, spec.backgroundColor.b,
        spec.backgroundColor.a)
    bar:SetStatusBarTexture(spec.texture)
    bar:SetOrientation(spec.orientation == 'horizontal' and 'HORIZONTAL' or 'VERTICAL')
    bar:SetReverseFill(spec.reverseFill)
    bar:SetStatusBarColor(spec.color.r, spec.color.g, spec.color.b, spec.color.a)
    local shape = { Mask = button:CreateMaskTexture(), masked = {} }
    shape.Mask:SetAllPoints()
    ufShape:SetBarMasked(shape, bar, ufShape:SelectStyle(shape, content.style))
    button:SetDurationBar(bar, {
        interpolation = Enum.StatusBarInterpolation.Immediate,
        direction = Enum.StatusBarTimerDirection.RemainingTime,
    })
end

local function applySwipe(button, content)
    if not content.swipe or (content.isBar and not content.iconRect) then
        return
    end
    local cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
    placeInSlot(cooldown, button, content.iconRect)
    cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawBling(false)
    cooldown:SetReverse(content.reverseSwipe)
    local color = content.swipeColor
    cooldown:SetSwipeColor(color.r, color.g, color.b, color.a)
    if styles:IsStyle(content.style) then
        cooldown:SetSwipeTexture((styles:GetArt(content.style)))
    end
    button:SetDurationCooldown(cooldown)
end

-- Drawn over the item's own border: the Style border art, or a pixel border grown outward.
local function applyBorder(button, content)
    if not content.border then
        return
    end
    local holder = CreateFrame('Frame', nil, button)
    holder:SetAllPoints()
    holder:SetFrameLevel(button:GetFrameLevel() + 6)
    local color = content.borderColor
    if styles:IsStyle(content.style) then
        local _, borderArt, margins = styles:GetArt(content.style)
        local texture = holder:CreateTexture(nil, 'OVERLAY')
        texture:SetAllPoints()
        texture:SetTexture(borderArt)
        styles:ApplySlices(texture, margins)
        texture:SetVertexColor(color.r, color.g, color.b, color.a)
        return
    end
    local border = EXUI:AddPixelPerfectBorder(holder, content.borderSize, {
        register = false,
        layer = 'OVERLAY',
        outwardSides = true,
        outwardBottom = true,
    })
    border:SetBorderColor(color.r, color.g, color.b, color.a)
end

local function applyGlow(button, content)
    if not content.glow then
        return
    end
    local holder = CreateFrame('Frame', nil, button)
    holder:SetAllPoints()
    holder:SetFrameLevel(button:GetFrameLevel() + 2)
    local color = content.glowColor
    local pulseTarget
    if content.glowKind == 'style' then
        EXUI:GetModule('np-element-target-highlight'):ApplyGlow(holder, button, content.style, color)
        pulseTarget = holder
    else
        local textureGlow = EXUI:GetModule('texture-glow')
        local glow = textureGlow:Ensure(holder)
        textureGlow:Apply(glow, button, {
            kind = content.glowKind,
            color = { r = color.r, g = color.g, b = color.b, a = color.a },
            size = content.glowSize,
        })
        glow:Show()
        pulseTarget = glow
    end
    if content.glowPulse then
        local pulse = holder:CreateAnimationGroup()
        pulse:SetLooping('BOUNCE')
        local fade = pulse:CreateAnimation('Alpha')
        fade:SetTarget(pulseTarget)
        fade:SetFromAlpha(1)
        fade:SetToAlpha(0.3)
        fade:SetDuration(0.6)
        button:AddAuraShownAnimation(pulse)
    end
end

-- Glow that Blizzard shows only inside the aura's pandemic (refresh) window.
local function applyPandemic(button, content)
    if not content.pandemic then
        return
    end
    local holder = CreateFrame('Frame', nil, button)
    holder:SetAllPoints()
    holder:SetFrameLevel(button:GetFrameLevel() + 2)
    EXUI:GetModule('np-element-target-highlight'):ApplyGlow(holder, button, content.style, content.pandemicColor)
    for _, texture in pairs(holder.TargetGlow) do
        button:AddPandemicRegion(texture)
    end
    if content.pandemicPulse then
        local pulse = holder:CreateAnimationGroup()
        pulse:SetLooping('BOUNCE')
        local fade = pulse:CreateAnimation('Alpha')
        fade:SetTarget(holder)
        fade:SetFromAlpha(1)
        fade:SetToAlpha(0.3)
        fade:SetDuration(0.5)
        button:AddPandemicActiveAnimation(pulse)
    end
end

-- A styled slot icon is as large as the item and would cover its border, so the slot repeats it.
-- "Only When Active" aura items (ownBorder) hide their own border while missing, so the slot repeats it
-- over the full item rect, exactly like the item's border.
local function applyItemBorder(button, content)
    if content.icon == 'none' or content.baseBorderSize <= 0 then
        return
    end
    local styled = styles:IsStyle(content.style)
    if not styled and not content.ownBorder then
        return
    end
    local holder = CreateFrame('Frame', nil, button)
    holder:SetPoint('TOPLEFT', -content.inset, content.inset)
    holder:SetPoint('BOTTOMRIGHT', content.inset, -content.inset)
    holder:SetFrameLevel(button:GetFrameLevel() + 3)
    local color = content.baseBorderColor
    if not styled then
        local border = EXUI:AddPixelPerfectBorder(holder, content.baseBorderSize, { register = false, layer = 'OVERLAY' })
        border:SetBorderColor(color.r, color.g, color.b, color.a)
        return
    end
    local _, borderArt, margins = styles:GetArt(content.style)
    local texture = holder:CreateTexture(nil, 'OVERLAY')
    texture:SetAllPoints()
    texture:SetTexture(borderArt)
    styles:ApplySlices(texture, margins)
    texture:SetVertexColor(color.r, color.g, color.b, color.a)
end

-- Aura Row slots are whole elements, so they draw the element background themselves.
local function applyBackground(button, content)
    if not content.background then
        return
    end
    local texture = button:CreateTexture(nil, 'BACKGROUND')
    texture:SetAllPoints()
    texture:SetTexture(EXUI.const.textures.frame.solidBg)
    local color = content.background
    texture:SetVertexColor(color.r, color.g, color.b, color.a)
    local shape = { Mask = button:CreateMaskTexture(), masked = {} }
    shape.Mask:SetAllPoints()
    ufShape:SetMasked(shape, texture, ufShape:SelectStyle(shape, content.style))
end

-- The slot is locked right after this runs, so anchoring happens here too. Aura Row slots have no anchor;
-- Blizzard's flow layout places them.
local function initializeSlot(button, content, anchor)
    button:SetSize(content.width, content.height)
    if anchor then
        button:SetPoint('CENTER', anchor, 'CENTER')
    end
    applyBackground(button, content)
    applyDurationBar(button, content)
    applyIcon(button, content)
    applySwipe(button, content)
    applyGlow(button, content)
    applyPandemic(button, content)
    applyItemBorder(button, content)
    applyBorder(button, content)
    applyTexts(button, content.texts)
end

------------------------------------------------------------
-- Containers per element frame

function auras:Clear(frame)
    for _, container in ipairs(frame.AuraContainers or {}) do
        container:SetEnabled(false)
        container:Hide()
    end
    frame.AuraContainers = nil
    frame.AuraUnits = nil
    frame.auraSignature = nil
end

-- watches: { { key, unit, filter, onlyMine, spellIDs, content } }, content as initializeSlot expects
function auras:Sync(frame, anchor, watches)
    local sig = #watches > 0 and (styles:GetVersion() .. signature(watches)) or nil
    frame.auraWatches = watches
    frame.auraAnchor = anchor
    frame.watchSignature = sig
    self:SyncPreview(frame)
    if sig == frame.auraSignature then
        return
    end
    self:Clear(frame)
    if not sig or not self:IsAvailable() then
        return
    end
    frame.auraSignature = sig

    local byUnit = {}
    for _, watch in ipairs(watches) do
        if #watch.spellIDs > 0 then
            byUnit[watch.unit] = byUnit[watch.unit] or {}
            table.insert(byUnit[watch.unit], watch)
        end
    end

    frame.AuraContainers = {}
    frame.AuraUnits = {}
    for unit, unitWatches in pairs(byUnit) do
        local container = CreateFrame('AuraContainer', nil, frame, 'CustomAuraContainerTemplate')
        container:SetAllPoints(anchor)
        container:SetFrameLevel(frame:GetFrameLevel() + 4)
        container:SetUnit(unit)
        frame.AuraUnits[container] = unit
        for _, watch in ipairs(unitWatches) do
            local content = watch.content
            container:AddAuraSlot(watch.key, self:BuildFilter(watch), {
                candidateFilters = { includeSpellIDs = spellMap(watch.spellIDs) },
                initializeFrame = function(button)
                    initializeSlot(button, content, anchor)
                end,
            })
        end
        container:SetEnabled(true)
        container:Show()
        table.insert(frame.AuraContainers, container)
    end
end

------------------------------------------------------------
-- Options preview: the same slot content on plain frames, fed with sample values.

local PREVIEW_STACKS = '3'

-- Mirrors the CustomAuraButton calls initializeSlot makes and keeps what it needs to restart.
local function createPreviewButton(parent, duration, spellID)
    local button = CreateFrame('Frame', nil, parent)
    button.previewCooldowns = {}
    button.previewBars = {}
    button.previewBindings = {}
    button.previewAnimations = {}
    button.SetIcon = function(_, texture)
        texture:SetTexture(C_Spell.GetSpellTexture(spellID))
    end
    button.SetDurationCooldown = function(_, cooldown)
        table.insert(button.previewCooldowns, cooldown)
    end
    button.SetDurationText = function(_, fontString, options)
        local binding = options.binding
        binding:SetFontString(fontString)
        binding:SetExpiredText('')
        binding:SetZeroDurationText('')
        binding:SetDuration(duration)
        table.insert(button.previewBindings, binding)
    end
    button.SetApplicationCount = function(_, fontString)
        fontString:SetText(PREVIEW_STACKS)
    end
    button.SetSpellName = function(_, fontString)
        fontString:SetText(C_Spell.GetSpellName(spellID) or '')
    end
    button.AddPandemicRegion = function() end
    button.AddPandemicActiveAnimation = function(_, group)
        table.insert(button.previewAnimations, group)
    end
    button.SetDurationBar = function(_, bar)
        table.insert(button.previewBars, bar)
    end
    button.AddAuraShownAnimation = function(_, group)
        table.insert(button.previewAnimations, group)
    end
    return button
end

local function setSlotActive(button, active, duration)
    for _, binding in ipairs(button.previewBindings) do
        binding:SetEnabled(active)
    end
    if active then
        for _, cooldown in ipairs(button.previewCooldowns) do
            cooldown:SetCooldownFromDurationObject(duration)
        end
        for _, bar in ipairs(button.previewBars) do
            bar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate,
                Enum.StatusBarTimerDirection.RemainingTime)
        end
        for _, group in ipairs(button.previewAnimations) do
            group:Play()
        end
        button:Show()
    else
        for _, group in ipairs(button.previewAnimations) do
            group:Stop()
        end
        button:Hide()
    end
end

function auras:HidePreview(frame)
    for _, button in ipairs(frame.PreviewSlots or {}) do
        setSlotActive(button, false)
    end
end

-- Slots are built once per aura setup; they cannot be freed, so they are only rebuilt when it changes.
function auras:ClearPreview(frame)
    self:HidePreview(frame)
    for _, button in ipairs(frame.PreviewSlots or {}) do
        button:SetParent(nil)
    end
    frame.PreviewSlots = nil
    frame.previewSignature = nil
end

function auras:SyncPreview(frame)
    if not frame.previewing then
        self:HidePreview(frame)
        return
    end
    if frame.previewSignature ~= frame.watchSignature then
        self:ClearPreview(frame)
        frame.previewSignature = frame.watchSignature
        frame.PreviewSlots = {}
        for _, watch in ipairs(frame.auraWatches or {}) do
            local spellID = watch.spellIDs[1]
            if spellID then
                local button = createPreviewButton(frame, frame.previewAuraDuration, spellID)
                button:SetFrameLevel(frame:GetFrameLevel() + 4)
                initializeSlot(button, watch.content, frame.auraAnchor)
                table.insert(frame.PreviewSlots, button)
            end
        end
    end
    self:RestartPreview(frame)
end

function auras:RestartPreview(frame)
    for _, button in ipairs(frame.PreviewSlots or {}) do
        setSlotActive(button, true, frame.previewAuraDuration)
    end
end

------------------------------------------------------------
-- Aura Row: one aura group per child, so each keeps its own look and the user's order, while Blizzard
-- collapses the ones that are not up (presence is secret, so only its layout can do this).

local FLOW_GROW_X = { RIGHT = 1, LEFT = -1 }
local FLOW_GROW_Y = { UP = 1, DOWN = -1 }

-- Main axis follows Align; the cross axis stays on the grow edge so lines never move when others empty.
local function flowAnchor(settings)
    local startX = settings.growX ~= 'LEFT' and 'LEFT' or 'RIGHT'
    local endX = startX == 'LEFT' and 'RIGHT' or 'LEFT'
    local startY = settings.growY ~= 'UP' and 'TOP' or 'BOTTOM'
    local endY = startY == 'TOP' and 'BOTTOM' or 'TOP'
    if settings.direction == 'horizontal' then
        local main = settings.align == 'center' and '' or (settings.align == 'start' and startX or endX)
        return startY .. main
    end
    local main = settings.align == 'center' and '' or (settings.align == 'start' and startY or endY)
    return main .. startX
end

-- Paused while the row is previewed with normal frames; buttons cannot be freed, so they are kept.
function auras:SuspendFlow(frame)
    for _, container in ipairs(frame.AuraContainers or {}) do
        container:SetEnabled(false)
        container:Hide()
    end
end

function auras:FlowSignature(flow)
    return #flow.entries > 0 and (styles:GetVersion() .. signature(flow)) or nil
end

-- flow: { unit, settings, lineSize, gapMain, gapCross, signature, entries = ordered
-- { key, filter, onlyMine, spellIDs, content } }
function auras:SyncFlow(frame, flow)
    local entries = flow.entries
    local sig = flow.signature
    if sig == frame.auraSignature then
        for _, container in ipairs(frame.AuraContainers or {}) do
            container:SetEnabled(true)
            container:Show()
        end
        return
    end
    self:Clear(frame)
    if not sig or not self:IsAvailable() then
        return
    end
    frame.auraSignature = sig

    local settings = flow.settings
    local unit = flow.unit
    local container = CreateFrame('AuraContainer', nil, frame, 'CustomAuraContainerTemplate')
    local point = flowAnchor(settings)
    container:SetPoint(point, frame, point)
    container:SetFrameLevel(frame:GetFrameLevel() + 1)
    container:SetUnit(unit)
    local horizontal = settings.direction == 'horizontal'
    container:SetFlowLayoutAxis(horizontal and AnchorUtil.FlowLayoutAxis.Horizontal or AnchorUtil.FlowLayoutAxis.Vertical)
    container:SetFlowLayoutAnchorPoint((settings.growY == 'UP' and 'BOTTOM' or 'TOP') .. (settings.growX == 'LEFT' and 'RIGHT' or 'LEFT'))
    container:SetFlowLayoutGrowthDirection(FLOW_GROW_X[settings.growX], FLOW_GROW_Y[settings.growY])
    container:SetFlowLayoutMaximumLineSize(flow.lineSize)

    for index, entry in ipairs(entries) do
        local content = entry.content
        container:AddAuraGroup(entry.key, self:BuildFilter(entry), {
            maxFrameCount = 1,
            candidateFilters = { includeSpellIDs = spellMap(entry.spellIDs) },
            layout = {
                layoutIndex = index,
                groupSpacing = flow.gapMain,
                lineSpacing = flow.gapCross,
                groupLineSpacing = flow.gapCross,
                elementWidth = content.width,
                elementHeight = content.height,
            },
            initializeFrame = function(button)
                initializeSlot(button, content)
            end,
        })
    end
    container:SetEnabled(true)
    container:Show()
    frame.AuraContainers = { container }
    frame.AuraUnits = { [container] = unit }
end

function auras:OnUnitChanged(frames, unit)
    if not TRACKED_UNITS[unit] then
        return
    end
    for _, frame in pairs(frames) do
        for _, container in ipairs(frame.AuraContainers or {}) do
            if frame.AuraUnits[container] == unit then
                container:UpdateAllAuras()
            end
        end
    end
end
