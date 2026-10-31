---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesElementsShape
local shape = EXUI:GetModule('uf-element-shape')

local STYLES = {
    ['round-4'] = { label = 'Rounded (4px)', order = 2, mask = 'shapeRound4', border = 'shapeRound4Border', margin = 5, size = 4 },
    ['round-6'] = { label = 'Rounded (6px)', order = 3, mask = 'shapeRound6', border = 'shapeRound6Border', margin = 7, size = 6 },
    ['round-10'] = { label = 'Rounded (10px)', order = 4, mask = 'shapeRound10', border = 'shapeRound10Border', margin = 11, size = 10 },
    ['cut-4'] = { label = 'Cut (4px)', order = 5, mask = 'shapeCut4', border = 'shapeCut4Border', margin = 5, size = 4 },
    ['cut-6'] = { label = 'Cut (6px)', order = 6, mask = 'shapeCut6', border = 'shapeCut6Border', margin = 7, size = 6 },
    ['cut-10'] = { label = 'Cut (10px)', order = 7, mask = 'shapeCut10', border = 'shapeCut10Border', margin = 11, size = 10 },
}

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
    local textures = EXUI.const.textures.unitFrames
    local margin = style.margin

    local mask = state.Mask
    mask:SetTexture(textures[style.mask], 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    mask:SetTextureSliceMargins(margin, margin, margin, margin)
    mask:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)

    local border = state.Border
    border:SetTexture(textures[style.border])
    border:SetTextureSliceMargins(margin, margin, margin, margin)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
end

local function SelectStyle(state, styleKey)
    local style = STYLES[styleKey]
    if style and state.styleKey ~= styleKey then
        ApplyTextures(state, style)
    end
    state.styleKey = styleKey
    return style ~= nil
end

-- Styles and masking are shared with Nameplates
shape.IsStyle = function(self, styleKey)
    return STYLES[styleKey] ~= nil
end

shape.GetStyleSize = function(self, styleKey)
    local style = STYLES[styleKey]
    return style and style.size
end

shape.SelectStyle = function(self, state, styleKey)
    return SelectStyle(state, styleKey)
end

shape.SetMasked = function(self, state, texture, enabled)
    SetMasked(state, texture, enabled)
end

shape.SetBarMasked = function(self, state, bar, enabled)
    SetBarMasked(state, bar, enabled)
end

shape.GetStyleOptions = function(self, includeUseDefault)
    local options = {
        ['default'] = { label = 'Default', order = 1 },
    }
    if includeUseDefault then
        options[''] = { label = 'Use Default', order = 0 }
    end
    for key, style in pairs(STYLES) do
        options[key] = { label = style.label, order = style.order }
    end
    return options
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
    return STYLES[state.styleKey] and state.Mask or nil
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

    local borderFrame = CreateFrame('Frame', nil, bar)
    borderFrame:SetAllPoints(container)
    borderFrame:SetFrameLevel(bar:GetFrameLevel() + 5)

    local border = borderFrame:CreateTexture(nil, 'OVERLAY')
    border:SetAllPoints()
    border:Hide()

    return { Mask = mask, Border = border, masked = {} }
end

shape.MaskPip = function(self, bar, pip)
    local state = bar.Shape
    SetMasked(state, pip.line, STYLES[state.styleKey] ~= nil)
end

shape.ApplyCastbarShape = function(self, bar, styleKey, color, showBorder)
    local state = bar.Shape
    local enabled = SelectStyle(state, styleKey)

    SetBarMasked(state, bar, enabled)
    SetMasked(state, bar.Icon, enabled)
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
