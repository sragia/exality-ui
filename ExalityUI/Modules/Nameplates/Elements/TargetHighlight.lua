---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesElementTargetHighlight
local highlight = EXUI:GetModule('np-element-target-highlight')

local LCG = LibStub('LibCustomGlow-1.0', true)
local ARROW_SIZE = 14
local GLOW_SLICE = 16
local GLOW_OUTSET = 6

local function stopPixelGlow(frame)
    if LCG and LCG.PixelGlow_Stop then
        LCG.PixelGlow_Stop(frame)
    end
end

local function hideGlow(frame)
    if frame.TargetGlow then
        frame.TargetGlow:Hide()
    end
end

local function ensureGlow(frame)
    if frame.TargetGlow then
        return frame.TargetGlow
    end
    local tex = frame:CreateTexture(nil, 'BACKGROUND')
    tex:SetTexture(EXUI.const.textures.nameplates.glow)
    tex:SetBlendMode('ADD')
    tex:SetTextureSliceMargins(GLOW_SLICE, GLOW_SLICE, GLOW_SLICE, GLOW_SLICE)
    frame.TargetGlow = tex
    return tex
end

local function showGlow(frame, db)
    local host = frame.HealthHost or frame
    local tex = ensureGlow(frame)
    local c = db.targetHighlightColor or { r = 1, g = 0.82, b = 0.2, a = 1 }
    tex:ClearAllPoints()
    tex:SetPoint('TOPLEFT', host, 'TOPLEFT', -GLOW_OUTSET, GLOW_OUTSET)
    tex:SetPoint('BOTTOMRIGHT', host, 'BOTTOMRIGHT', GLOW_OUTSET, -GLOW_OUTSET)
    tex:SetVertexColor(c.r, c.g, c.b, c.a or 1)
    tex:Show()
end

local function stopGlow(frame)
    stopPixelGlow(frame)
    hideGlow(frame)
end

local function clearDim(frame)
    if not frame._exuiDimmed then
        return
    end
    frame._exuiDimmed = nil
    frame:SetAlpha(1)
end

local function ensureArrows(frame)
    if frame.TargetArrows then
        return frame.TargetArrows
    end
    local parent = frame.ElementFrame or frame
    local tex = EXUI.const.textures.frame.icons.chevronRight
    local left = parent:CreateTexture(nil, 'OVERLAY')
    left:SetTexture(tex)
    left:SetSize(ARROW_SIZE, ARROW_SIZE)
    left:SetPoint('RIGHT', frame, 'LEFT', -2, 0)
    local right = parent:CreateTexture(nil, 'OVERLAY')
    right:SetTexture(tex)
    right:SetTexCoord(1, 0, 0, 1)
    right:SetSize(ARROW_SIZE, ARROW_SIZE)
    right:SetPoint('LEFT', frame, 'RIGHT', 2, 0)
    frame.TargetArrows = { left = left, right = right }
    return frame.TargetArrows
end

local function hideArrows(frame)
    local arrows = frame.TargetArrows
    if not arrows then
        return
    end
    arrows.left:Hide()
    arrows.right:Hide()
end

local function showArrows(frame, db)
    local arrows = ensureArrows(frame)
    local c = db.targetHighlightColor or { r = 1, g = 0.82, b = 0.2, a = 1 }
    arrows.left:SetVertexColor(c.r, c.g, c.b, c.a or 1)
    arrows.right:SetVertexColor(c.r, c.g, c.b, c.a or 1)
    arrows.left:Show()
    arrows.right:Show()
end

local function resetChrome(frame)
    stopGlow(frame)
    hideArrows(frame)
    clearDim(frame)
    EXUI:GetModule('np-core'):ApplyHealthChrome(frame)
end

local STICKY_GRACE = 0.5

local function isMouseoverUnit(unit)
    return unit and UnitExists('mouseover') and UnitIsUnit(unit, 'mouseover')
end

local function isCurrentTargetUnit(unit)
    return unit and UnitExists('target') and UnitIsUnit(unit, 'target')
end

local function refreshHealthColor(frame, unit)
    local bar = frame.Health
    if not bar then
        return
    end
    EXUI:GetModule('np-element-health').PostUpdateColor(bar, unit)
end

local function isStickyHover(self, frame)
    return frame and self.stickyHoverFrame == frame
end

highlight.ClearStickyHover = function(self)
    self.stickyHoverFrame = nil
    self.stickyHoverAt = nil
end

highlight.RememberHover = function(self, frame)
    if frame and frame:IsShown() then
        self.hoverFrame = frame
    end
end

highlight.HoldHover = function(self)
    local frame = self.hoverFrame
    if not frame or not frame:IsShown() then
        return false
    end
    local unit = EXUI:GetModule('np-core'):GetPlateUnit(frame)
    if isCurrentTargetUnit(unit) then
        return false
    end
    self.stickyHoverFrame = frame
    self.stickyHoverAt = GetTime()
    return true
end

highlight.StartMouseoverWatch = function(self)
    if not self.watch then
        self.watch = CreateFrame('Frame')
    end
    self.watch:SetScript('OnUpdate', function()
        if UnitExists('mouseover') then
            return
        end
        local frame = highlight.stickyHoverFrame
        if not frame then
            highlight:StopMouseoverWatch()
            return
        end
        local unit = EXUI:GetModule('np-core'):GetPlateUnit(frame)
        if isCurrentTargetUnit(unit) then
            highlight:ClearStickyHover()
            EXUI:GetModule('np-core'):UpdateTargetHighlight()
            highlight:StopMouseoverWatch()
            return
        end
        if IsMouseButtonDown('LeftButton') then
            highlight.stickyHoverAt = GetTime()
            return
        end
        if highlight.stickyHoverAt and (GetTime() - highlight.stickyHoverAt) < STICKY_GRACE then
            return
        end
        highlight:ClearStickyHover()
        highlight:StopMouseoverWatch()
        EXUI:GetModule('np-core'):UpdateTargetHighlight()
    end)
end

highlight.StopMouseoverWatch = function(self)
    if not self.watch then
        return
    end
    self.watch:SetScript('OnUpdate', nil)
end

highlight.OnPlateRemoved = function(self, frame)
    if self.hoverFrame == frame then
        self.hoverFrame = nil
    end
    if self.stickyHoverFrame == frame then
        self:ClearStickyHover()
        self:StopMouseoverWatch()
    end
end

highlight.OnTargetChanged = function(self)
    self:ClearStickyHover()
    EXUI:GetModule('np-core'):UpdateTargetHighlight()
end

highlight.OnMouseoverChanged = function(self)
    if UnitExists('mouseover') then
        self:ClearStickyHover()
        if self.pendingMouseover then
            return
        end
        self.pendingMouseover = true
        C_Timer.After(0, function()
            self.pendingMouseover = false
            EXUI:GetModule('np-core'):UpdateTargetHighlight()
            if UnitExists('mouseover') then
                self:StartMouseoverWatch()
            else
                if self:HoldHover() then
                    EXUI:GetModule('np-core'):UpdateTargetHighlight()
                    self:StartMouseoverWatch()
                else
                    self:StopMouseoverWatch()
                end
            end
        end)
        return
    end

    self:HoldHover()
    EXUI:GetModule('np-core'):UpdateTargetHighlight()
    self:StartMouseoverWatch()
end

highlight.ShouldLightenHealth = function(self, frame)
    local db = frame and frame.db
    if not db or not db.mouseoverHighlightEnable or not db.mouseoverLightenHealth then
        return false
    end
    if frame.isPreview then
        return false
    end
    local unit = EXUI:GetModule('np-core'):GetPlateUnit(frame)
    if isCurrentTargetUnit(unit) then
        return false
    end
    return isMouseoverUnit(unit) or isStickyHover(self, frame)
end

highlight.ApplyHealthLighten = function(self, frame, bar)
    bar = bar or (frame and frame.Health)
    if not bar or not self:ShouldLightenHealth(frame) then
        return
    end
    local amount = frame.db.mouseoverLightenAmount or 0.25
    if amount <= 0 then
        return
    end
    local r, g, b, a = bar:GetStatusBarColor()
    bar:SetStatusBarColor(r + (1 - r) * amount, g + (1 - g) * amount, b + (1 - b) * amount, a)
end

highlight.Update = function(self, frame)
    local db = frame.db
    local npCore = EXUI:GetModule('np-core')
    if frame.isFriendly or not db then
        if self.hoverFrame == frame then
            self.hoverFrame = nil
        end
        if self.stickyHoverFrame == frame then
            self:ClearStickyHover()
        end
        resetChrome(frame)
        return
    end

    local unit = npCore:GetPlateUnit(frame)
    if isMouseoverUnit(unit) then
        self:RememberHover(frame)
    end

    local isCurrentTarget = frame.isPreview or isCurrentTargetUnit(unit)
    local isTarget = db.targetHighlightEnable and isCurrentTarget
    local isMouseover = db.mouseoverHighlightEnable and not isCurrentTarget and (
        isMouseoverUnit(unit) or isStickyHover(self, frame)
    )

    if db.targetHighlightEnable and db.targetHighlightDimOthers and UnitExists('target') and not isTarget then
        frame._exuiDimmed = true
        frame:SetAlpha(db.targetHighlightDimAlpha or 0.45)
    else
        clearDim(frame)
    end

    if isTarget then
        local style = db.targetHighlightStyle or 'glow'
        if style == 'glow' then
            npCore:ApplyHealthChrome(frame)
            hideArrows(frame)
            stopPixelGlow(frame)
            showGlow(frame, db)
        elseif style == 'arrows' then
            npCore:ApplyHealthChrome(frame)
            stopGlow(frame)
            showArrows(frame, db)
        else
            stopGlow(frame)
            hideArrows(frame)
            npCore:ApplyHealthChrome(frame, db.targetHighlightColor)
        end
        refreshHealthColor(frame, unit)
        return
    end

    stopGlow(frame)
    hideArrows(frame)
    if isMouseover then
        npCore:ApplyHealthChrome(frame, db.mouseoverHighlightColor)
    else
        npCore:ApplyHealthChrome(frame)
    end
    refreshHealthColor(frame, unit)
end
