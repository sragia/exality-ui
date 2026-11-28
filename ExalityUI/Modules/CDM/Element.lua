---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUICDMSources
local sources = EXUI:GetModule('cdm-sources')

---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

---@class EXUIUnitFramesElementsShape
local ufShape = EXUI:GetModule('uf-element-shape')

---@class EXUIStyles
local styles = EXUI:GetModule('styles')

---@class EXUICDMAuras
local auras = EXUI:GetModule('cdm-auras')

---@class EXUICDMElement
local element = EXUI:GetModule('cdm-element')

local function data()
    return EXUI:GetModule('cdm-data')
end

---@class EXUIGlowTextureGlow
local textureGlow = EXUI:GetModule('texture-glow')


local function createText(frame)
    local text = frame.Overlay:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    return { FontString = text }
end

local function releaseTexts(frame, fromIndex)
    for index = fromIndex, #frame.Texts do
        local entry = frame.Texts[index]
        entry.FontString:SetText('')
        entry.FontString:Hide()
        if entry.Binding then
            entry.Binding:SetEnabled(false)
        end
        entry.config = nil
    end
end

local function ensureBinding(entry)
    if not entry.Binding then
        entry.Binding = C_DurationUtil.CreateDurationTextBinding()
        entry.Binding:SetFontString(entry.FontString)
        entry.Binding:SetExpiredText('')
        entry.Binding:SetZeroDurationText('')
        entry.Binding:SetDuration(sources.ZERO_DURATION)
    end
    return entry.Binding
end

function element:Create(parent)
    local frame = CreateFrame('Frame', nil, parent)
    frame:Hide()

    frame.Background = frame:CreateTexture(nil, 'BACKGROUND')
    frame.Background:SetAllPoints()
    frame.Background:SetTexture(EXUI.const.textures.frame.solidBg)

    frame.BarBackground = frame:CreateTexture(nil, 'BACKGROUND', nil, 1)
    frame.BarBackground:SetTexture(EXUI.const.textures.frame.solidBg)
    frame.Bar = CreateFrame('StatusBar', nil, frame)
    frame.Bar:SetMinMaxValues(0, 1)
    frame.BarReady = frame.Bar:CreateTexture(nil, 'ARTWORK', nil, 1)
    frame.BarReady:SetAllPoints()

    frame.Texture = frame:CreateTexture(nil, 'ARTWORK')

    frame.Cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
    frame.Cooldown:SetHideCountdownNumbers(true)

    frame.BorderFrame = CreateFrame('Frame', nil, frame)
    frame.BorderFrame:SetAllPoints()
    frame.PPBorder = EXUI:AddPixelPerfectBorder(frame.BorderFrame, 1, { register = false, layer = 'OVERLAY' })

    frame.ProcGlow = CreateFrame('Frame', nil, frame)
    frame.ProcGlow:SetAllPoints()
    frame.ProcGlow:Hide()

    frame.Overlay = CreateFrame('Frame', nil, frame)
    frame.Overlay:SetAllPoints()

    frame.Shape = {
        Mask = frame:CreateMaskTexture(),
        Border = frame.BorderFrame:CreateTexture(nil, 'OVERLAY'),
        masked = {},
        isIcon = true,
    }
    frame.Shape.Border:SetAllPoints()
    -- A bar's icon gets its own icon mask; Forever needs icon masks unsliced.
    frame.IconShape = { Mask = frame:CreateMaskTexture(), masked = {}, isIcon = true }

    frame.Texts = {}
    frame.state = {}
    EXUI:RegisterSnapFrame(frame)
    return frame
end

-- Border, background, style mask and cooldown look shared by icons and bars. Returns the border inset.
local function applyFrame(frame, look)
    EXUI:SetSize(frame, look.width, look.height)
    frame.look = look
    -- Border +2, proc glow +3, aura slots +4 and up, texts +20 (see auras:Sync).
    frame.Bar:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.Cooldown:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.BorderFrame:SetFrameLevel(frame:GetFrameLevel() + 2)
    frame.ProcGlow:SetFrameLevel(frame:GetFrameLevel() + 3)
    frame.Overlay:SetFrameLevel(frame:GetFrameLevel() + 20)

    local isIcon = not frame.isBar
    if frame.Shape.isIcon ~= isIcon then
        frame.Shape.isIcon = isIcon
        frame.Shape.styleKey = nil
    end
    local shaped = ufShape:SelectStyle(frame.Shape, look.style)
    frame.Shape.Mask:SetAllPoints(frame)
    ufShape:SetMasked(frame.Shape, frame.Background, shaped)
    ufShape:SetMasked(frame.Shape, frame.BarBackground, shaped)
    ufShape:SetMasked(frame.Shape, frame.BarReady, shaped)
    ufShape:SetBarMasked(frame.Shape, frame.Bar, shaped)

    local border = look.borderColor
    if shaped then
        frame.PPBorder:Hide()
        frame.Shape.Border:SetVertexColor(border.r, border.g, border.b, border.a)
        frame.Shape.Border:SetShown(look.borderSize > 0)
        frame.Cooldown:SetSwipeTexture((styles:GetArt(look.style)))
    else
        frame.Shape.Border:Hide()
        frame.PPBorder:SetBorderColor(border.r, border.g, border.b, border.a)
        if look.borderSize > 0 then
            frame.PPBorder:SetBorderThickness(look.borderSize)
            frame.PPBorder:Show()
        else
            frame.PPBorder:Hide()
        end
        frame.Cooldown:SetSwipeTexture(EXUI.const.textures.frame.solidBg)
    end

    local swipe = look.swipeColor
    frame.Cooldown:SetDrawSwipe(look.showSwipe)
    frame.Cooldown:SetSwipeColor(swipe.r, swipe.g, swipe.b, swipe.a)
    frame.Cooldown:SetReverse(look.reverseSwipe or false)
    frame.Cooldown:SetDrawEdge(look.showEdge or false)
    frame.Cooldown:SetDrawBling(look.showBling or false)
    return shaped and 0 or EXUI:GetBorderInset(frame, look.borderSize)
end

local function placeRect(region, frame, rect)
    region:ClearAllPoints()
    region:SetPoint('TOPLEFT', frame, 'TOPLEFT', rect.x, -rect.y)
    region:SetSize(rect.w, rect.h)
end

function element:ApplyIcon(frame, look)
    frame.isBar = false
    local inset = applyFrame(frame, look)
    ufShape:SetMasked(frame.IconShape, frame.Texture, false)
    ufShape:SetMasked(frame.Shape, frame.Texture, styles:IsStyle(look.style))
    frame.contentWidth = math.max(1, look.width - inset * 2)
    frame.contentHeight = math.max(1, look.height - inset * 2)
    frame.slotAnchor = frame.Texture
    frame.iconRect = nil
    frame.barRect = nil
    frame.Texture:Show()
    frame.Texture:ClearAllPoints()
    frame.Texture:SetPoint('TOPLEFT', inset, -inset)
    frame.Texture:SetPoint('BOTTOMRIGHT', -inset, inset)
    frame.Cooldown:ClearAllPoints()
    frame.Cooldown:SetAllPoints(frame.Texture)
    frame.Bar:Hide()
    frame.BarBackground:Hide()

    local bg = look.backgroundColor
    frame.Background:SetVertexColor(bg.r, bg.g, bg.b, bg.a)
    frame.Texture:SetTexCoord(EXUI.utils.getTexCoords(look.width, look.height, look.zoom))
end

-- Icon and bar rects inside the border, relative to the frame's top left corner.
local function barRects(look, inset)
    local innerW = math.max(1, look.width - inset * 2)
    local innerH = math.max(1, look.height - inset * 2)
    local horizontal = look.orientation == 'horizontal'
    local size = math.min(horizontal and innerH or innerW, horizontal and innerW or innerH)
    local bar = { x = inset, y = inset, w = innerW, h = innerH }
    if look.iconPosition == 'none' then
        return nil, bar
    end
    local icon = { x = inset, y = inset, w = size, h = size }
    local used = math.min(size + look.gap, (horizontal and innerW or innerH) - 1)
    if horizontal then
        bar.w = math.max(1, innerW - used)
        if look.iconPosition == 'start' then
            bar.x = inset + used
        else
            icon.x = inset + innerW - size
        end
    else
        bar.h = math.max(1, innerH - used)
        if look.iconPosition == 'start' then
            bar.y = inset + used
        else
            icon.y = inset + innerH - size
        end
    end
    return icon, bar
end

element.BarRects = barRects

-- Full slot content for an aura item laid out by an Aura Row: the slot is the whole element, so it carries
-- its own background and border and needs no item frame.
function element:BuildFlowContent(node, region)
    local isBar = node.display == 'bar'
    local look = isBar and data():ResolveBar(node) or data():ResolveIcon(node)
    local source = node.source
    local styled = styles:IsStyle(look.style)
    local inset = styled and 0 or EXUI:GetBorderInset(region, look.borderSize)
    local iconRect, barRect
    if isBar then
        iconRect, barRect = barRects(look, inset)
    else
        iconRect = { x = inset, y = inset, w = math.max(1, look.width - inset * 2), h = math.max(1, look.height - inset * 2) }
    end
    return {
        width = look.width,
        height = look.height,
        inset = 0,
        iconRect = iconRect,
        isBar = isBar,
        zoom = look.zoom,
        style = look.style,
        background = not isBar and look.backgroundColor or nil,
        baseBorderColor = look.borderColor,
        baseBorderSize = look.borderSize,
        icon = 'aura',
        ownBorder = true,
        durationBar = isBar and {
            rect = barRect,
            texture = LSM:Fetch('statusbar', look.texture),
            color = look.color,
            orientation = look.orientation,
            reverseFill = look.reverseFill,
            backgroundColor = look.backgroundColor,
        } or nil,
        swipe = look.showSwipe,
        swipeColor = look.swipeColor,
        reverseSwipe = look.reverseSwipe,
        glow = source.glow,
        glowKind = source.glowKind,
        glowColor = source.glowColor,
        glowSize = source.glowSize,
        glowPulse = source.glowPulse,
        border = source.border,
        borderColor = source.borderColor,
        borderSize = source.borderSize,
        pandemic = source.pandemic,
        pandemicColor = source.pandemicColor,
        pandemicPulse = source.pandemicPulse,
        texts = data():ResolveTexts(node),
    }
end

function element:ApplyBar(frame, look)
    frame.isBar = true
    local inset = applyFrame(frame, look)
    local iconRect, barRect = barRects(look, inset)
    frame.contentWidth = look.width
    frame.contentHeight = look.height
    frame.slotAnchor = frame
    frame.iconRect = iconRect
    frame.barRect = barRect

    ufShape:SetMasked(frame.Shape, frame.Texture, false)
    if iconRect then
        placeRect(frame.Texture, frame, iconRect)
        frame.IconShape.Mask:SetAllPoints(frame.Texture)
        ufShape:SetMasked(frame.IconShape, frame.Texture, ufShape:SelectStyle(frame.IconShape, look.style))
        frame.Texture:SetTexCoord(EXUI.utils.getTexCoords(iconRect.w, iconRect.h, look.zoom))
        frame.Texture:Show()
        frame.Cooldown:ClearAllPoints()
        frame.Cooldown:SetAllPoints(frame.Texture)
    else
        frame.Texture:Hide()
        frame.Cooldown:SetDrawSwipe(false)
    end

    local texture = LSM:Fetch('statusbar', look.texture)
    placeRect(frame.Bar, frame, barRect)
    placeRect(frame.BarBackground, frame, barRect)
    frame.Bar:SetStatusBarTexture(texture)
    frame.Bar:SetOrientation(look.orientation == 'horizontal' and 'HORIZONTAL' or 'VERTICAL')
    frame.Bar:SetReverseFill(look.reverseFill)
    local color = look.color
    frame.Bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
    frame.BarReady:SetTexture(texture)
    local bg = look.backgroundColor
    frame.BarBackground:SetVertexColor(bg.r, bg.g, bg.b, bg.a)
    frame.Background:SetVertexColor(0, 0, 0, 0)
    frame.Bar:Show()
    frame.BarBackground:Show()
end

-- Remaining time and stacks of an aura item come from its slot; with "Only When Active" every text does.
local AURA_TEXT_KINDS = { cooldown = true, charges = true }

local function inSlot(config, auraMode)
    return auraMode == 'active' or (auraMode == 'always' and AURA_TEXT_KINDS[config.kind])
end

function element:ApplyTexts(frame, texts, auraMode)
    local used = 0
    for _, config in ipairs(texts) do
        if config.enable and not inSlot(config, auraMode) then
            used = used + 1
            local entry = frame.Texts[used] or createText(frame)
            frame.Texts[used] = entry
            entry.config = config

            local fontString = entry.FontString
            fontString:SetFont(LSM:Fetch('font', config.font), config.fontSize, config.fontFlag)
            fontString:SetTextColor(config.color.r, config.color.g, config.color.b, config.color.a)
            fontString:SetJustifyH(config.justify)
            fontString:ClearAllPoints()
            fontString:SetPoint(config.anchorPoint, frame.Overlay, config.relativePoint, config.XOff, config.YOff)
            EXUI.utils.applyFontShadow(fontString, config.textShadow, config.textShadowX, config.textShadowY,
                config.textShadowColor)
            fontString:Show()

            if config.kind == 'cooldown' then
                local binding = ensureBinding(entry)
                binding:SetFormatter(durationFormat:GetFormatter(config.format))
                binding:SetUpdateInterval(config.updateInterval)
                binding:SetTextColorCurve(auras:TextColorCurve(config), Enum.DurationTextBindingProperty.RemainingDuration)
                binding:SetEnabled(true)
            elseif entry.Binding then
                entry.Binding:SetEnabled(false)
            end
            if config.kind == 'custom' then
                fontString:SetText(config.text)
            end
        end
    end
    releaseTexts(frame, used + 1)
end

local function slotContent(frame, look, overrides)
    local content = {
        width = frame.contentWidth,
        height = frame.contentHeight,
        inset = (look.width - frame.contentWidth) / 2,
        iconRect = frame.iconRect,
        isBar = frame.isBar,
        zoom = look.zoom,
        style = look.style,
        baseBorderColor = look.borderColor,
        baseBorderSize = look.borderSize,
    }
    for key, value in pairs(overrides) do
        content[key] = value
    end
    return content
end

function element:ApplyAuras(frame, node, look, texts)
    local watches = {}
    local source = node.source
    local spellTexture = sources:GetTexture(source)
    -- Aura items draw everything inside the slot, so "Only When Active" hides them completely.
    if source.type == 'aura' then
        local auraMode = node.visibility.auraState == 'active' and 'active' or 'always'
        local slotTexts = {}
        for _, config in ipairs(texts) do
            if inSlot(config, auraMode) then
                slotTexts[#slotTexts + 1] = config
            end
        end
        watches[#watches + 1] = {
            key = 'source',
            unit = source.unit,
            filter = source.filter,
            onlyMine = source.onlyMine,
            spellIDs = source.spellIDs,
            content = slotContent(frame, look, {
                icon = 'aura',
                ownBorder = auraMode == 'active',
                durationBar = frame.isBar and {
                    rect = frame.barRect,
                    texture = LSM:Fetch('statusbar', look.texture),
                    color = look.color,
                    orientation = look.orientation,
                    reverseFill = look.reverseFill,
                    backgroundColor = look.backgroundColor,
                } or nil,
                swipe = look.showSwipe,
                swipeColor = look.swipeColor,
                reverseSwipe = look.reverseSwipe,
                glow = source.glow,
                glowKind = source.glowKind,
                glowColor = source.glowColor,
                glowSize = source.glowSize,
                glowPulse = source.glowPulse,
                border = source.border,
                borderColor = source.borderColor,
                borderSize = source.borderSize,
                pandemic = source.pandemic,
                pandemicColor = source.pandemicColor,
                pandemicPulse = source.pandemicPulse,
                texts = slotTexts,
            }),
        }
    end
    for _, linked in ipairs(node.source.type ~= 'aura' and node.linkedAuras or {}) do
        watches[#watches + 1] = {
            key = linked.id,
            unit = linked.unit,
            filter = linked.filter,
            onlyMine = linked.onlyMine,
            spellIDs = linked.spellIDs,
            content = slotContent(frame, look, {
                icon = linked.icon,
                spellTexture = spellTexture,
                swipe = linked.swipe,
                swipeColor = linked.swipeColor,
                reverseSwipe = linked.reverseSwipe,
                glow = linked.glow,
                glowKind = linked.glowKind,
                glowColor = linked.glowColor,
                glowSize = linked.glowSize,
                glowPulse = linked.glowPulse,
                border = linked.border,
                borderColor = linked.borderColor,
                borderSize = linked.borderSize,
                pandemic = linked.pandemic,
                pandemicColor = linked.pandemicColor,
                pandemicPulse = linked.pandemicPulse,
                texts = linked.texts,
            }),
        }
    end
    frame.auraArgs = { node = node, look = look, texts = texts, spellTexture = spellTexture }
    auras:Sync(frame, frame.slotAnchor, watches)
    local placeholderAlpha = 1
    if source.type == 'aura' then
        placeholderAlpha = node.visibility.auraState == 'active' and 0 or source.missingAlpha
    end
    -- Vertex alpha and SetAlpha are one value on textures, so background colour and placeholder alpha are
    -- written together; the icon texture picks placeholderAlpha up in Refresh.
    frame.placeholderAlpha = placeholderAlpha
    local bg = look.backgroundColor
    if frame.isBar then
        frame.Background:SetVertexColor(0, 0, 0, 0)
        frame.BarBackground:SetVertexColor(bg.r, bg.g, bg.b, bg.a * placeholderAlpha)
    else
        frame.Background:SetVertexColor(bg.r, bg.g, bg.b, bg.a * placeholderAlpha)
    end
    frame.BorderFrame:SetAlpha(source.type == 'aura' and node.visibility.auraState == 'active' and 0 or 1)
end

-- Proc glow around the whole element; shown from Refresh while the spell is highlighted.
function element:ApplyProcGlow(frame, look)
    local holder = frame.ProcGlow
    if holder.TextureGlow then
        textureGlow:Hide(holder.TextureGlow)
    end
    for _, texture in pairs(holder.TargetGlow or {}) do
        texture:Hide()
    end
    if not look.procGlow then
        return
    end
    local color = look.procGlowColor
    if look.procGlowKind == 'style' then
        EXUI:GetModule('np-element-target-highlight'):ApplyGlow(holder, frame, look.style, color)
        return
    end
    local glow = textureGlow:Ensure(holder)
    textureGlow:Apply(glow, frame, {
        kind = look.procGlowKind,
        color = { r = color.r, g = color.g, b = color.b, a = color.a },
        size = 10,
    })
    glow:Show()
end

local THRESHOLD_INTERVAL = 0.05

-- "Last Seconds": a step curve over the remaining cooldown drives the frame alpha (1 inside the window and
-- when ready, hiddenAlpha before it). The remaining time may be secret, so only the curve result is used,
-- and only by SetAlpha.
local function onThresholdUpdate(frame, elapsed)
    frame.thresholdElapsed = frame.thresholdElapsed + elapsed
    if frame.thresholdElapsed < THRESHOLD_INTERVAL then
        return
    end
    frame.thresholdElapsed = 0
    local state = frame.state
    frame:SetAlpha((state.cooldownDuration or state.duration):EvaluateRemainingDuration(frame.thresholdCurve))
end

function element:SetThreshold(frame, seconds, hiddenAlpha)
    frame.thresholdEnabled = seconds ~= nil
    if not seconds then
        return
    end
    frame.thresholdCurve = frame.thresholdCurve or C_CurveUtil.CreateCurve()
    frame.thresholdCurve:SetType(Enum.LuaCurveType.Step)
    frame.thresholdCurve:ClearPoints()
    frame.thresholdCurve:AddPoint(0, 1)
    frame.thresholdCurve:AddPoint(seconds, hiddenAlpha)
end

-- Visibility decides whether the curve drives the alpha; hidden and preview states keep their own alpha.
function element:SetThresholdActive(frame, active)
    if active == (frame.thresholdActive or false) then
        return
    end
    frame.thresholdActive = active
    frame.thresholdElapsed = THRESHOLD_INTERVAL
    frame:SetScript('OnUpdate', active and onThresholdUpdate or nil)
end

function element:SetSource(frame, source)
    frame.source = source
    frame.state.textureFinal = false
    self:RefreshTexture(frame)
end

function element:RefreshTexture(frame)
    if frame.state.textureFinal then
        return
    end
    local texture, final = sources:GetTexture(frame.source)
    frame.Texture:SetTexture(texture)
    frame.state.textureFinal = final
end

-- "Full Color Icon" slots copy the base texture, so they follow it when it really changes.
function element:InvalidateTexture(frame)
    frame.state.textureFinal = false
    self:RefreshTexture(frame)
    local args = frame.auraArgs
    if args and args.spellTexture ~= sources:GetTexture(frame.source) then
        self:ApplyAuras(frame, args.node, args.look, args.texts)
    end
end

element.PREVIEW_LOOP = 12

local function readPreview(frame)
    local state = frame.state
    state.duration = frame.source.type == 'aura' and sources.ZERO_DURATION or frame.previewDuration
    state.onCooldown = frame.source.type ~= 'aura'
    state.usable = true
    state.count = '2'
    return state
end

-- Sample values while the item is selected in options; the preview ticker restarts them.
function element:RestartPreview(frame)
    local now = GetTime()
    frame.previewDuration:SetTimeFromStart(now, self.PREVIEW_LOOP, 1)
    frame.previewAuraDuration:SetTimeFromStart(now, self.PREVIEW_LOOP, 1)
    auras:RestartPreview(frame)
    self:Refresh(frame)
end

function element:SetPreview(frame, enabled)
    if (frame.previewing or false) == enabled then
        return
    end
    frame.previewing = enabled
    if enabled then
        frame.previewDuration = frame.previewDuration or C_DurationUtil.CreateDuration()
        frame.previewAuraDuration = frame.previewAuraDuration or C_DurationUtil.CreateDuration()
        local now = GetTime()
        frame.previewDuration:SetTimeFromStart(now, self.PREVIEW_LOOP, 1)
        frame.previewAuraDuration:SetTimeFromStart(now, self.PREVIEW_LOOP, 1)
    end
    auras:SyncPreview(frame)
    self:Refresh(frame)
end

function element:Refresh(frame)
    local state = frame.previewing and readPreview(frame) or sources:Read(frame.state, frame.source)
    self:RefreshTexture(frame)
    frame.Cooldown:SetCooldownFromDurationObject(state.duration, true)
    local look = frame.look
    local outOfRange = look.rangeTint and state.inRange == false
    local tint = outOfRange and look.rangeColor or nil
    -- Vertex alpha replaces SetAlpha on textures, so the aura placeholder alpha has to ride along.
    local alpha = frame.placeholderAlpha or 1
    if tint then
        frame.Texture:SetVertexColor(tint.r, tint.g, tint.b, tint.a * alpha)
    else
        frame.Texture:SetVertexColor(1, 1, 1, alpha)
    end
    local procPreview = frame.previewing and frame.source.type == 'spell'
    frame.ProcGlow:SetShown(look.procGlow and (procPreview or state.procActive) or false)
    if frame.isBar then
        local barColor = tint or look.color
        frame.Bar:SetStatusBarColor(barColor.r, barColor.g, barColor.b, barColor.a)
        frame.BarReady:SetVertexColor(barColor.r, barColor.g, barColor.b, barColor.a)
        frame.Bar:SetTimerDuration(state.duration, Enum.StatusBarInterpolation.Immediate,
            Enum.StatusBarTimerDirection.RemainingTime)
        frame.BarReady:SetShown(frame.look.fillWhenReady and not state.onCooldown and not state.recharging
            and frame.source.type ~= 'aura')
    end
    local isAura = frame.source.type == 'aura'
    local node = frame.auraArgs and frame.auraArgs.node
    local missing = node ~= nil and not frame.previewing and EXUI:GetModule('cdm'):LinkedMissing(node, 'desaturate')
    frame.Texture:SetDesaturated(isAura or missing or (frame.look.desaturateOnCooldown and state.onCooldown))

    for _, entry in ipairs(frame.Texts) do
        local config = entry.config
        if config then
            if config.kind == 'cooldown' and entry.Binding then
                entry.Binding:SetDuration(state.duration)
            elseif config.kind == 'charges' then
                entry.FontString:SetText(state.count)
            elseif config.kind == 'name' then
                entry.FontString:SetText(sources:GetName(frame.source))
            end
        end
    end
    return state
end

function element:Reset(frame)
    self:SetThreshold(frame, nil)
    self:SetThresholdActive(frame, false)
    frame.previewing = false
    frame.placeholderAlpha = nil
    auras:ClearPreview(frame)
    auras:Clear(frame)
    frame.auraWatches = nil
    frame.auraArgs = nil
    frame:UnregisterAllEvents()
    frame:SetScript('OnEvent', nil)
    releaseTexts(frame, 1)
    frame.Cooldown:Clear()
    frame:Hide()
    frame:ClearAllPoints()
    frame.state = {}
    frame.source = nil
end
