---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesElementsShape
local shape = EXUI:GetModule('uf-element-shape')

---@class EXUIStyles
local styles = EXUI:GetModule('styles')

local function SetMasked(state, texture, enabled)
    if not texture or (state.masked[texture] or false) == enabled then
        return
    end
    if enabled then
        texture:AddMaskTexture(state.Mask)
    else
        texture:RemoveMaskTexture(state.Mask)
    end
    state.masked[texture] = enabled
end

local function SetBarMasked(state, bar, enabled)
    if bar then
        SetMasked(state, bar:GetStatusBarTexture(), enabled)
        SetMasked(state, bar.bg, enabled)
    end
end

local function ApplyTextures(state, style)
    local mask = state.Mask
    mask:SetTexture(style.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    -- Forever squeezes some masked icons into the mask's corner slice, so icon masks stretch whole there.
    if state.isIcon and EXUI.IsForever() then
        mask:ClearTextureSlice()
    else
        styles:ApplySlices(mask, style.margins)
    end

    local border = state.Border
    if border then
        border:SetTexture(style.border)
        styles:ApplySlices(border, style.margins)
    end
end

local function SelectStyle(state, styleKey)
    local style = styles:Get(styleKey)
    local version = styles:GetVersion()
    if style and (state.styleKey ~= styleKey or state.styleVersion ~= version) then
        ApplyTextures(state, style)
    end
    state.styleKey = styleKey
    state.styleVersion = version
    return style ~= nil
end

-- Masking is shared with Nameplates and aura icons
shape.SelectStyle = function(self, state, styleKey)
    return SelectStyle(state, styleKey)
end

shape.SetMasked = function(self, state, texture, enabled)
    SetMasked(state, texture, enabled)
end

shape.SetBarMasked = function(self, state, bar, enabled)
    SetBarMasked(state, bar, enabled)
end

local function UsesClassColor(frame)
    if frame.db.overrideFrameBorderColor then
        return frame.db.frameBorderClassColor
    end
    return frame.generalDB.frameBorderClassColor
end

local function GetUnitColor(unit)
    if not unit then
        return nil
    end
    local colors = EXUI.oUF.colors
    if UnitIsPlayer(unit) or UnitInPartyIsAI(unit) then
        local _, class = UnitClass(unit)
        if not class or issecretvalue(class) then
            return nil
        end
        return colors.class[class]
    end
    local reaction = UnitReaction(unit, 'player')
    if not reaction or issecretvalue(reaction) then
        return nil
    end
    return colors.reaction[reaction]
end

local function ApplyBorderColor(frame, color)
    frame.FrameShape.Border:SetVertexColor(color.r, color.g, color.b, color.a)
    frame.ElementFrame.PPBorder:SetBorderColor(color.r, color.g, color.b, color.a)
end

shape.GetBorderColor = function(self, frame)
    local unitColor = UsesClassColor(frame) and GetUnitColor(frame.__unit)
    if unitColor then
        return unitColor
    end
    if frame.db.overrideFrameBorderColor then
        return frame.db.frameBorderColor
    end
    return frame.generalDB.frameBorderColor
end

-- Unit on the frame can change without a frame:Update
shape.RefreshBorderColor = function(self, frame)
    if not UsesClassColor(frame) then
        return
    end
    local state = frame.FrameShape
    local color = self:GetBorderColor(frame)
    if state.borderColor == color then
        return
    end
    state.borderColor = color
    if frame.SelectionHighlight then
        EXUI:GetModule('uf-element-selection-highlight'):Update(frame)
    else
        ApplyBorderColor(frame, color)
    end
end

-- For textures that can only be masked when created
shape.GetActiveMask = function(self, frame)
    local state = frame.FrameShape
    return styles:IsStyle(state.styleKey) and state.Mask or nil
end

shape.Create = function(self, frame)
    local mask = frame:CreateMaskTexture()
    mask:SetAllPoints(frame)

    local border = frame.ElementFrame:CreateTexture(nil, 'BORDER', nil, 1)
    border:SetAllPoints(frame.ElementFrame)
    border:SetVertexColor(0, 0, 0, 1)
    border:Hide()

    return { Mask = mask, Border = border, masked = {} }
end

-- Regions live on the bar since the container stays shown between casts
shape.CreateCastbar = function(self, bar, container)
    local mask = bar:CreateMaskTexture()
    mask:SetAllPoints(container)

    -- Lowest OVERLAY sublevel keeps it over the fill and icon but under the bar's texts.
    local border = bar:CreateTexture(nil, 'OVERLAY', nil, -8)
    border:SetAllPoints(container)
    border:Hide()

    local state = { Mask = mask, Border = border, masked = {} }
    -- Forever squeezes the icon into the bar mask's slices, so the icon gets its own mask there.
    if EXUI.IsForever() then
        state.Icon = { Mask = bar:CreateMaskTexture(), masked = {}, isIcon = true }
    end
    return state
end

shape.MaskPip = function(self, bar, pip)
    local state = bar.Shape
    SetMasked(state, pip.line, styles:IsStyle(state.styleKey))
end

shape.ApplyCastbarShape = function(self, bar, styleKey, color, showBorder)
    local state = bar.Shape
    local enabled = SelectStyle(state, styleKey)

    SetBarMasked(state, bar, enabled)
    if state.Icon and bar.Icon then
        state.Icon.Mask:SetAllPoints(bar.Icon)
        SetMasked(state.Icon, bar.Icon, SelectStyle(state.Icon, styleKey))
    else
        SetMasked(state, bar.Icon, enabled)
    end
    SetMasked(state, bar.Spark, enabled)
    SetMasked(state, bar.Uninterruptible, enabled)
    for _, pip in pairs(bar.Pips or {}) do
        self:MaskPip(bar, pip)
    end

    state.Border:SetVertexColor(color.r, color.g, color.b, color.a)
    state.Border:SetShown(enabled and showBorder)
    return enabled
end

shape.UpdateCastbar = function(self, frame)
    local db = frame.db
    local bar = frame.Castbar
    local styleKey = db.castbarStyle ~= '' and db.castbarStyle or frame.generalDB.castbarStyle
    local enabled = self:ApplyCastbarShape(bar, styleKey, db.castbarBackgroundBorderColor, true)

    if enabled then
        bar.PPBorder:Hide()
    else
        bar.PPBorder:Show()
    end
end

shape.Update = function(self, frame)
    local db = frame.db
    local state = frame.FrameShape
    local styleKey = db.overrideFrameStyle ~= '' and db.overrideFrameStyle or frame.generalDB.frameStyle
    local enabled = SelectStyle(state, styleKey)

    local health = frame.Health
    SetBarMasked(state, health, enabled)
    SetBarMasked(state, frame.Power, enabled)
    SetMasked(state, frame.DispelOverlay, enabled)

    local absorbs = frame.HealthPrediction
    if absorbs then
        SetBarMasked(state, absorbs.DamageAbsorbOriginal, enabled)
        SetBarMasked(state, absorbs.HealAbsorbOriginal, enabled)
        SetMasked(state, absorbs.OverDamageAbsorbIndicatorOriginal, enabled)
    end

    local holder = frame.PortraitHolder
    if holder then
        local maskPortrait = enabled and db.portraitEnable and db.portraitStyle == 'attached'
        SetMasked(state, holder.Bg, maskPortrait or false)
        SetMasked(state, holder.Texture, maskPortrait or false)
    end

    state.borderColor = self:GetBorderColor(frame)
    ApplyBorderColor(frame, state.borderColor)

    local defaultBorder = frame.ElementFrame.PPBorder
    state.Border:SetShown(enabled)
    if enabled then
        defaultBorder:Hide()
    else
        defaultBorder:Show()
    end
end
