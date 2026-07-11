---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUIAuraDisplaysButtonStyle
local buttonStyle = EXUI:GetModule('aura-displays-button-style')

---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

local styledButtons = {}

local BORDER_STYLE_MAP = {
    Atlas = 0,
    Color = 1,
}

local BAR_TIMER_DIRECTION_MAP = {
    RemainingTime = Enum.StatusBarTimerDirection.RemainingTime,
    ElapsedTime = Enum.StatusBarTimerDirection.ElapsedTime,
}

-- Blizzard buff frames use a border ~1/3 larger than the icon (30 -> 40).
local DISPEL_BORDER_EXTRA_RATIO = 1 / 3
local DISPEL_BORDER_INSET = 1

function buttonStyle:GetBarDimensions(visual)
    visual = visual or {}
    local barWidth = visual.barWidth or 160
    local barHeight = visual.barHeight or 20
    local iconSize = visual.showBarIcon ~= false and barHeight or 0
    local iconGap = iconSize > 0 and (visual.barIconGap or 0) or 0
    local totalWidth = barWidth + iconSize + iconGap
    return totalWidth, barHeight, barWidth, barHeight
end

function buttonStyle:GetBarTexture(visual)
    local textureName = visual and visual.barTexture or 'ExalityUI Status Bar'
    if LSM then
        return LSM:Fetch('statusbar', textureName) or EXUI.const.textures.frame.statusBar
    end
    return EXUI.const.textures.frame.statusBar
end

function buttonStyle:ApplyBarInsets(statusBar, parent)
    statusBar:ClearAllPoints()
    statusBar:SetAllPoints(parent)
end

function buttonStyle:ApplyBarBorderChrome(borderFrame, visual, useSafeChrome)
    local thickness = visual.barBorderThickness or 1
    local borderColor = visual.barBorderColor or { r = 0, g = 0, b = 0, a = 1 }

    if useSafeChrome then
        if not borderFrame.BarPPBorder then
            borderFrame.BarPPBorder = EXUI:AddPixelPerfectBorder(borderFrame, thickness, { register = false, layer = 'OVERLAY' })
        end
        borderFrame.BarPPBorder:SetBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        borderFrame.BarPPBorder:SetBorderThickness(thickness)
        self:SetIconBorderVisibility(borderFrame.BarPPBorder, true)
        if borderFrame.SetBackdrop then
            borderFrame:SetBackdrop(nil)
        end
        return
    end

    borderFrame:SetBackdrop(EXUI.const.backdrop.pixelPerfect(thickness, borderFrame))
    borderFrame:SetBackdropColor(0, 0, 0, 0)
    borderFrame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    if borderFrame.BarPPBorder then
        self:SetIconBorderVisibility(borderFrame.BarPPBorder, false)
    end
end

function buttonStyle:ApplyBarTrackChrome(container, borderFrame, visual, useSafeChrome)
    local thickness = visual.barBorderThickness or 1
    local inset = EXUI:GetBorderInset(borderFrame, thickness, 0)
    local bgColor = visual.barBackgroundColor or { r = 0, g = 0, b = 0, a = 0.5 }

    container:ClearAllPoints()
    container:SetPoint('TOPLEFT', borderFrame, 'TOPLEFT', inset, -inset)
    container:SetPoint('BOTTOMRIGHT', borderFrame, 'BOTTOMRIGHT', -inset, inset)

    if useSafeChrome then
        if not container.BarTrackBg then
            container.BarTrackBg = container:CreateTexture(nil, 'BACKGROUND')
            container.BarTrackBg:SetAllPoints()
        end
        container.BarTrackBg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
        container.BarTrackBg:Show()
        if container.SetBackdrop then
            container:SetBackdrop(nil)
        end
        return
    end

    container:SetBackdrop(EXUI.const.backdrop.backgroundOnly)
    container:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    if container.BarTrackBg then
        container.BarTrackBg:Hide()
    end
end

function buttonStyle:UsesSafeBarChrome(button)
    return button.exuiIsPreview == true
end

function buttonStyle:ApplyBarPixelPerfect(button, visual)
    local borderFrame = button.BarBorderFrame
    local container = button.BarContainer
    if not borderFrame or not container then
        return
    end

    local totalWidth, totalHeight, barWidth, barHeight = self:GetBarDimensions(visual)
    EXUI:SetSize(button, totalWidth, totalHeight)
    EXUI:SetSize(borderFrame, barWidth, barHeight)

    self:ApplyBarBorderChrome(borderFrame, visual, self:UsesSafeBarChrome(button))
    self:ApplyBarTrackChrome(container, borderFrame, visual, self:UsesSafeBarChrome(button))

    if button.BarStatusBar then
        self:ApplyBarInsets(button.BarStatusBar, container)
    end

    if self:UsesSafeBarChrome(button) and borderFrame.BarPPBorder then
        borderFrame.BarPPBorder:SetBorderThickness(visual.barBorderThickness or 1)
        self:SetIconBorderVisibility(borderFrame.BarPPBorder, true)
    end
end

function buttonStyle:GetDispelBorderSize(visual)
    visual = visual or {}
    local iconW = visual.iconWidth or 32
    local iconH = visual.iconHeight or 32
    local extraW = math.floor(iconW * DISPEL_BORDER_EXTRA_RATIO + 0.5)
    local extraH = math.floor(iconH * DISPEL_BORDER_EXTRA_RATIO + 0.5)
    local borderW = iconW + extraW - (DISPEL_BORDER_INSET * 2)
    local borderH = iconH + extraH - (DISPEL_BORDER_INSET * 2)
    return math.max(borderW, iconW), math.max(borderH, iconH)
end

function buttonStyle:GetFontPath(fontName)
    if LSM then
        return LSM:Fetch('font', fontName) or EXUI.const.fonts.DEFAULT
    end
    return EXUI.const.fonts.DEFAULT
end

function buttonStyle:ApplyIconTexCoord(icon, visual)
    if not icon then
        return
    end
    local width, height, zoom
    if visual.displayStyle == 'bar' then
        width = visual.barHeight or 20
        height = width
        zoom = visual.iconZoom or 0
    else
        width = visual.iconWidth or 32
        height = visual.iconHeight or 32
        zoom = visual.iconZoom or 0
    end
    icon:SetTexCoord(EXUI.utils.getTexCoords(width, height, zoom))
end

function buttonStyle:CreateIcon(button, visual)
    if button.Icon then
        return button.Icon
    end
    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(visual.iconWidth or 32, visual.iconHeight or 32)
    icon:SetPoint('CENTER')
    if not self:UsesSafeBarChrome(button) and button.SetIcon then
        button:SetIcon(icon)
    end
    button.Icon = icon
    return icon
end

function buttonStyle:GetAuraButtonFrame(button)
    if button.BarContainer then
        return button.BarContainer
    end
    if button.Icon and button.Icon.GetParent then
        return button.Icon:GetParent()
    end
    return button
end

function buttonStyle:EnsureTextOverlay(button)
    if button.TextOverlay then
        return button.TextOverlay
    end
    local parent = self:GetAuraButtonFrame(button)
    local overlay = CreateFrame('Frame', nil, parent)
    overlay:SetAllPoints(parent)
    button.TextOverlay = overlay
    return overlay
end

function buttonStyle:EnsureIconBorderOverlay(button)
    if button.IconBorderOverlay then
        return button.IconBorderOverlay
    end
    local parent = self:GetAuraButtonFrame(button)
    local overlay = CreateFrame('Frame', nil, parent)
    overlay:EnableMouse(false)
    overlay:SetAllPoints(parent)
    button.IconBorderOverlay = overlay
    return overlay
end

function buttonStyle:EnsureDispelBorderOverlay(button)
    if button.DispelBorderOverlay then
        return button.DispelBorderOverlay
    end
    local parent = self:GetAuraButtonFrame(button)
    local overlay = CreateFrame('Frame', nil, parent)
    overlay:EnableMouse(false)
    overlay:SetAllPoints(parent)
    button.DispelBorderOverlay = overlay
    return overlay
end

function buttonStyle:RaiseDispelBorderLayer(button, border)
    if not border or not border.SetParent then
        return
    end
    border:SetParent(self:EnsureDispelBorderOverlay(button))
end

function buttonStyle:ApplyLayering(button)
    if button.BarBorderFrame then
        local base = button.BarBorderFrame:GetFrameLevel()
        if button.BarContainer then
            button.BarContainer:SetFrameLevel(base + 1)
        end
        if button.BarStatusBar and button.BarStatusBar.SetFrameLevel then
            button.BarStatusBar:SetFrameLevel(base + 2)
        end
        if button.TextOverlay then
            button.TextOverlay:SetFrameLevel(base + 5)
        end
        if button.IconBorderOverlay then
            button.IconBorderOverlay:SetFrameLevel(button:GetFrameLevel() + 2)
        end
        return
    end

    local parent = self:GetAuraButtonFrame(button)
    if not parent or not parent.GetFrameLevel then
        return
    end
    local base = parent:GetFrameLevel()
    local cooldown = button.DurationCooldownFrame
    if not cooldown and button.GetDurationCooldown then
        cooldown = button:GetDurationCooldown()
    end
    if cooldown and cooldown.SetFrameLevel then
        cooldown:SetFrameLevel(base + 1)
    end
    if button.IconBorderOverlay then
        button.IconBorderOverlay:SetFrameLevel(base + 2)
    end
    if button.DispelBorderOverlay then
        button.DispelBorderOverlay:SetFrameLevel(base + 3)
    end
    if button.TextOverlay then
        button.TextOverlay:SetFrameLevel(base + 5)
    end
end

function buttonStyle:RaiseTextLayer(button, region)
    if region and region.SetParent then
        region:SetParent(self:EnsureTextOverlay(button))
    end
end

function buttonStyle:CreateFontString(button, key, visualKey, visual, defaults)
    visual = visual or {}
    local anchorParent = self:GetAuraButtonFrame(button)
    local fontString = button[key]
    if not fontString then
        fontString = button:CreateFontString(nil, 'OVERLAY')
        button[key] = fontString
    end

    fontString:SetFont(
        self:GetFontPath(visual[visualKey .. 'Font'] or defaults.font),
        visual[visualKey .. 'FontSize'] or defaults.size,
        visual[visualKey .. 'FontFlag'] or 'OUTLINE'
    )
    local color = visual[visualKey .. 'Color'] or defaults.color
    fontString:SetTextColor(color.r, color.g, color.b, color.a or 1)
    fontString:ClearAllPoints()
    fontString:SetPoint(
        visual[visualKey .. 'AnchorPoint'] or defaults.anchor,
        anchorParent,
        visual[visualKey .. 'RelativePoint'] or defaults.relative,
        visual[visualKey .. 'XOff'] or 0,
        visual[visualKey .. 'YOff'] or 0
    )
    return fontString
end

function buttonStyle:CreateCooldown(button)
    if button.DurationCooldownFrame then
        return button.DurationCooldownFrame
    end
    local parent = self:GetAuraButtonFrame(button)
    local cooldown = CreateFrame('Cooldown', nil, parent, 'CooldownFrameTemplate')
    cooldown:SetAllPoints(parent)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(true)
    button.DurationCooldownFrame = cooldown
    return cooldown
end

local ICON_BORDER_DRAW_LEVEL = 1
local DISPEL_BORDER_DRAW_LEVEL = 2

function buttonStyle:SetIconBorderVisibility(iconBorder, show)
    if not iconBorder then
        return
    end
    for _, edge in ipairs({ 'Top', 'Bottom', 'Left', 'Right' }) do
        local texture = iconBorder[edge]
        if texture then
            if show then
                texture:Show()
            else
                texture:Hide()
            end
        end
    end
end

function buttonStyle:CreateBorder(button)
    if button.AuraBorderTexture then
        return button.AuraBorderTexture
    end
    local parent = self:GetAuraButtonFrame(button)
    local border = button:CreateTexture(nil, 'OVERLAY')
    border:SetDrawLayer('OVERLAY', DISPEL_BORDER_DRAW_LEVEL)
    border:SetPoint('CENTER', parent, 'CENTER')
    button.AuraBorderTexture = border
    return border
end

function buttonStyle:ApplyDispelBorderLayout(button, visual)
    local border = button.AuraBorderTexture
    if not border and button.GetAuraBorder then
        border = button:GetAuraBorder()
    end
    if not border then
        return
    end

    local parent = self:GetAuraButtonFrame(button)
    local borderW, borderH = self:GetDispelBorderSize(visual)
    border:ClearAllPoints()
    border:SetSize(borderW, borderH)
    border:SetPoint('CENTER', parent, 'CENTER')
    if border.SetDrawLayer then
        border:SetDrawLayer('OVERLAY', DISPEL_BORDER_DRAW_LEVEL)
    end
    self:RaiseDispelBorderLayer(button, border)
end

function buttonStyle:GetDurationFormatter(visual)
    return durationFormat:GetFormatter(visual and visual.durationFormat or durationFormat.FORMAT_FALLBACK)
end

function buttonStyle:ApplyIconBorder(button, visual)
    local parent = self:GetAuraButtonFrame(button)
    if not parent then
        return
    end

    if visual.showIconBorder == false then
        self:SetIconBorderVisibility(button.IconPPBorder, false)
        if button.IconBorderOverlay then
            button.IconBorderOverlay:Hide()
        end
        return
    end

    local borderParent = self:EnsureIconBorderOverlay(button)
    borderParent:Show()

    if not button.IconPPBorder or button.IconPPBorder.anchor ~= borderParent then
        if button.IconPPBorder then
            self:SetIconBorderVisibility(button.IconPPBorder, false)
        end
        button.IconPPBorder = EXUI:AddPixelPerfectBorder(borderParent, 1, { register = false, layer = 'OVERLAY' })
        for _, edge in ipairs({ 'Top', 'Bottom', 'Left', 'Right' }) do
            local texture = button.IconPPBorder[edge]
            if texture and texture.SetDrawLayer then
                texture:SetDrawLayer('OVERLAY', ICON_BORDER_DRAW_LEVEL)
            end
        end
    end

    local color = visual.iconBorderColor or { r = 0, g = 0, b = 0, a = 1 }
    local thickness = visual.iconBorderThickness or 1
    button.IconPPBorder:SetBorderColor(color.r, color.g, color.b, color.a or 1)
    button.IconPPBorder:SetBorderThickness(thickness)
    self:SetIconBorderVisibility(button.IconPPBorder, true)
end

function buttonStyle:CreateBarContainer(button, visual)
    local useSafeChrome = self:UsesSafeBarChrome(button)

    if not button.BarBorderFrame then
        if useSafeChrome then
            button.BarBorderFrame = CreateFrame('Frame', nil, button)
        else
            button.BarBorderFrame = CreateFrame('Frame', nil, button, 'BackdropTemplate')
        end
    end
    if not button.BarContainer then
        if useSafeChrome then
            button.BarContainer = CreateFrame('Frame', nil, button.BarBorderFrame)
        else
            button.BarContainer = CreateFrame('Frame', nil, button.BarBorderFrame, 'BackdropTemplate')
        end
    end

    button.BarBorderFrame:Show()
    button.BarContainer:Show()

    if button.BarBorderOverlay then
        button.BarBorderOverlay:Hide()
    end
    if button.BarPPBorder then
        self:SetIconBorderVisibility(button.BarPPBorder, false)
    end

    self:ApplyBarBorderChrome(button.BarBorderFrame, visual, useSafeChrome)
    self:ApplyBarTrackChrome(button.BarContainer, button.BarBorderFrame, visual, useSafeChrome)

    if not button.BarStatusBar then
        button.BarStatusBar = CreateFrame('StatusBar', nil, button.BarContainer)
    end

    local statusBar = button.BarStatusBar
    self:ApplyBarInsets(statusBar, button.BarContainer)
    statusBar:SetStatusBarTexture(self:GetBarTexture(visual))
    local fillColor = visual.barColor or { r = 0.2, g = 0.6, b = 1, a = 1 }
    statusBar:SetStatusBarColor(fillColor.r, fillColor.g, fillColor.b, fillColor.a or 1)

    if button.SetDurationBar and not useSafeChrome then
        local direction = BAR_TIMER_DIRECTION_MAP[visual.barTimerDirection or 'RemainingTime']
            or BAR_TIMER_DIRECTION_MAP.RemainingTime
        button:SetDurationBar(statusBar, { direction = direction })
    end

    return button.BarBorderFrame
end

function buttonStyle:ApplyBarIconLayout(button, visual)
    local _, totalHeight, barWidth, barHeight = self:GetBarDimensions(visual)
    local borderFrame = button.BarBorderFrame
    local showIcon = visual.showBarIcon ~= false
    local gap = visual.barIconGap or 0
    local position = visual.barIconPosition or 'LEFT'

    borderFrame:ClearAllPoints()
    EXUI:SetSize(borderFrame, barWidth, barHeight)

    if showIcon then
        local icon = self:CreateIcon(button, visual)
        icon:ClearAllPoints()
        EXUI:SetSize(icon, barHeight, barHeight)
        self:ApplyIconTexCoord(icon, visual)

        if position == 'RIGHT' then
            borderFrame:SetPoint('TOPLEFT', button, 'TOPLEFT', 0, 0)
            icon:SetPoint('TOPRIGHT', button, 'TOPRIGHT', 0, 0)
        else
            icon:SetPoint('TOPLEFT', button, 'TOPLEFT', 0, 0)
            EXUI:SetPoint(borderFrame, 'TOPLEFT', button, 'TOPLEFT', barHeight + gap, 0)
        end

        icon:Show()
        if button.SetIcon and not self:UsesSafeBarChrome(button) then
            button:SetIcon(icon)
        end

        local borderOverlay = self:EnsureIconBorderOverlay(button)
        borderOverlay:ClearAllPoints()
        EXUI:SetSize(borderOverlay, barHeight, barHeight)
        if position == 'RIGHT' then
            borderOverlay:SetPoint('TOPRIGHT', button, 'TOPRIGHT', 0, 0)
        else
            borderOverlay:SetPoint('TOPLEFT', button, 'TOPLEFT', 0, 0)
        end
        borderOverlay:Show()
        self:ApplyIconBorder(button, visual)
    else
        if button.ClearIcon then
            button:ClearIcon()
        elseif button.Icon then
            button.Icon:Hide()
        end
        self:SetIconBorderVisibility(button.IconPPBorder, false)
        if button.IconBorderOverlay then
            button.IconBorderOverlay:Hide()
        end
        borderFrame:SetPoint('TOPLEFT', button, 'TOPLEFT', 0, 0)
    end
end

function buttonStyle:ApplyBarStyle(button, visual)
    styledButtons[button] = visual
    local useSafeChrome = self:UsesSafeBarChrome(button)

    if not useSafeChrome then
        if button.EnableMouse then
            button:EnableMouse(false)
        end
        if button.SetMouseMotionEnabled then
            button:SetMouseMotionEnabled(false)
        end
    end

    self:CreateBarContainer(button, visual)
    self:ApplyBarIconLayout(button, visual)
    self:ApplyBarPixelPerfect(button, visual)

    if not useSafeChrome then
        if button.ClearDurationCooldown then
            button:ClearDurationCooldown()
        end
        if button.ClearAuraBorder then
            button:ClearAuraBorder()
        end
        if button.ClearAuraSymbol then
            button:ClearAuraSymbol()
        end
    end

    if visual.showStacks then
        local stackText = self:CreateFontString(button, 'ApplicationCount', 'stack', visual, {
            font = 'DMSans', size = 12, color = { r = 1, g = 1, b = 1, a = 1 }, anchor = 'BOTTOMRIGHT', relative =
        'BOTTOMRIGHT',
        })
        if useSafeChrome then
            self:RaiseTextLayer(button, stackText)
        elseif button.SetApplicationCount then
            button:SetApplicationCount(stackText)
            self:RaiseTextLayer(button, stackText)
        end
    elseif not useSafeChrome and button.ClearApplicationCount then
        button:ClearApplicationCount()
    end

    if visual.showDurationText then
        local durationText = self:CreateFontString(button, 'DurationText', 'duration', visual, {
            font = 'DMSans', size = 12, color = { r = 1, g = 1, b = 1, a = 1 }, anchor = 'CENTER', relative = 'CENTER',
        })
        if useSafeChrome then
            self:RaiseTextLayer(button, durationText)
        elseif button.SetDurationText then
            local durationOptions = {
                expiredText = visual.durationExpiredText,
                zeroDurationText = visual.durationZeroText,
            }
            if visual.durationUpdateInterval and visual.durationUpdateInterval > 0 then
                durationOptions.updateInterval = visual.durationUpdateInterval
            end
            local formatter = self:GetDurationFormatter(visual)
            if formatter then
                durationOptions.formatter = formatter
            end
            button:SetDurationText(durationText, durationOptions)
            self:RaiseTextLayer(button, durationText)
        end
    elseif not useSafeChrome and button.ClearDurationText then
        button:ClearDurationText()
    end

    if visual.showSpellName then
        local spellName = self:CreateFontString(button, 'SpellNameText', 'spellName', visual, {
            font = 'DMSans', size = 10, color = { r = 1, g = 1, b = 1, a = 1 }, anchor = 'LEFT', relative = 'LEFT',
        })
        if useSafeChrome then
            self:RaiseTextLayer(button, spellName)
        elseif button.SetSpellName then
            button:SetSpellName(spellName)
            self:RaiseTextLayer(button, spellName)
        end
    elseif not useSafeChrome and button.ClearSpellName then
        button:ClearSpellName()
    end

    self:ApplyLayering(button)
end

function buttonStyle:Apply(button, visual)
    if not visual then
        return
    end

    if visual.displayStyle == 'bar' then
        self:ApplyBarStyle(button, visual)
        return
    end

    if button.BarBorderFrame then
        button.BarBorderFrame:Hide()
    end
    if button.BarContainer then
        button.BarContainer:Hide()
    end

    styledButtons[button] = visual

    button:SetSize(visual.iconWidth or 32, visual.iconHeight or 32)
    if button.EnableMouse then
        button:EnableMouse(false)
    end
    if button.SetMouseMotionEnabled then
        button:SetMouseMotionEnabled(false)
    end

    local icon = self:CreateIcon(button, visual)
    icon:SetSize(visual.iconWidth or 32, visual.iconHeight or 32)
    self:ApplyIconTexCoord(icon, visual)
    self:ApplyIconBorder(button, visual)

    if visual.showStacks and button.SetApplicationCount then
        local stackText = self:CreateFontString(button, 'ApplicationCount', 'stack', visual, {
            font = 'DMSans', size = 12, color = { r = 1, g = 1, b = 1, a = 1 }, anchor = 'BOTTOMRIGHT', relative =
        'BOTTOMRIGHT',
        })
        button:SetApplicationCount(stackText)
        self:RaiseTextLayer(button, stackText)
    elseif button.ClearApplicationCount then
        button:ClearApplicationCount()
    end

    if visual.showDurationCooldown and button.SetDurationCooldown then
        button:SetDurationCooldown(self:CreateCooldown(button))
    elseif button.ClearDurationCooldown then
        button:ClearDurationCooldown()
    end

    if visual.showDurationText and button.SetDurationText then
        local durationText = self:CreateFontString(button, 'DurationText', 'duration', visual, {
            font = 'DMSans', size = 12, color = { r = 1, g = 1, b = 1, a = 1 }, anchor = 'CENTER', relative = 'CENTER',
        })
        local durationOptions = {
            expiredText = visual.durationExpiredText,
            zeroDurationText = visual.durationZeroText,
        }
        if visual.durationUpdateInterval and visual.durationUpdateInterval > 0 then
            durationOptions.updateInterval = visual.durationUpdateInterval
        end
        local formatter = self:GetDurationFormatter(visual)
        if formatter then
            durationOptions.formatter = formatter
        end
        button:SetDurationText(durationText, durationOptions)
        self:RaiseTextLayer(button, durationText)
    elseif button.ClearDurationText then
        button:ClearDurationText()
    end

    if visual.showSpellName and button.SetSpellName then
        local spellName = self:CreateFontString(button, 'SpellNameText', 'spellName', visual, {
            font = 'DMSans', size = 10, color = { r = 1, g = 1, b = 1, a = 1 }, anchor = 'BOTTOM', relative = 'TOP',
        })
        button:SetSpellName(spellName)
        self:RaiseTextLayer(button, spellName)
    elseif button.ClearSpellName then
        button:ClearSpellName()
    end

    if visual.showDispelBorder and button.SetAuraBorder then
        local border = self:CreateBorder(button)
        self:ApplyDispelBorderLayout(button, visual)
        button:SetAuraBorder(border, {
            showIcon = visual.dispelBorderShowIcon,
            showWhenHarmful = visual.dispelBorderHarmful,
            showWhenHelpful = visual.dispelBorderHelpful,
            style = BORDER_STYLE_MAP[visual.dispelBorderStyle] or 0,
        })
    elseif button.ClearAuraBorder then
        button:ClearAuraBorder()
    end

    if button.ClearAuraSymbol then
        button:ClearAuraSymbol()
    end

    self:ApplyLayering(button)
end

function buttonStyle:Clear(button)
    styledButtons[button] = nil
end
