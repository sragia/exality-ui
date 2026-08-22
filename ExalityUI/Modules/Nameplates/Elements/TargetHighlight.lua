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

local STICKY_GRACE = 0.2

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

local function plateBase(frame)
    return frame and frame:GetParent()
end

local function isCursorOverPlate(frame)
    if not frame or not frame:IsShown() or not GetMouseFoci then
        return false
    end
    local plate = plateBase(frame)
    local foci = GetMouseFoci()
    for i = 1, #foci do
        local node = foci[i]
        while node do
            if node == frame or node == plate then
                return true
            end
            node = node.GetParent and node:GetParent()
        end
    end
    return false
end

local function isStickyHover(self, frame)
    return frame and self.stickyHoverFrame == frame
end

local function isIgnoredHoverFrame(self, frame)
    return frame and self.ignoredHoverFrame == frame
end

local function isLiveMouseover(self, frame, unit)
    return isMouseoverUnit(unit) and not isIgnoredHoverFrame(self, frame)
end

local function isHoverVisual(self, frame, unit)
    return self.plateCursorFrame == frame or isStickyHover(self, frame) or isLiveMouseover(self, frame, unit)
end

highlight.ClearStickyHover = function(self)
    self.stickyHoverFrame = nil
    self.stickyHoverAt = nil
end

highlight.ForgetHover = function(self, frame)
    if not frame or self.hoverFrame == frame then
        self.hoverFrame = nil
    end
    if self.stickyHoverFrame == frame then
        self:ClearStickyHover()
    end
    if self.plateCursorFrame == frame then
        self.plateCursorFrame = nil
    end
    if self.ignoredHoverFrame == frame then
        self.ignoredHoverFrame = nil
    end
end

highlight.RememberHover = function(self, frame)
    if frame and frame:IsShown() then
        self.hoverFrame = frame
    end
end

highlight.HoldHover = function(self, frame)
    frame = frame or self.hoverFrame or self.plateCursorFrame
    if not frame or not frame:IsShown() then
        return false
    end
    local unit = EXUI:GetModule('np-core'):GetPlateUnit(frame)
    if isCurrentTargetUnit(unit) then
        return false
    end
    self.hoverFrame = frame
    self.stickyHoverFrame = frame
    self.stickyHoverAt = GetTime()
    return true
end

highlight.IgnoreCurrentMouseover = function(self, frame)
    self.ignoredHoverFrame = frame
end

highlight.RefreshHover = function(self)
    EXUI:GetModule('np-core'):UpdateTargetHighlight()
end

highlight.StartMouseoverWatch = function(self)
    if not self.watch then
        self.watch = CreateFrame('Frame')
    end
    self.watch:SetScript('OnUpdate', function()
        highlight:PollHover()
    end)
end

highlight.StopMouseoverWatch = function(self)
    if not self.watch then
        return
    end
    self.watch:SetScript('OnUpdate', nil)
end

highlight.LeavePlateCursor = function(self, frame)
    if IsMouseButtonDown('LeftButton') then
        self:HoldHover(frame)
        self:StartMouseoverWatch()
        return
    end
    self:IgnoreCurrentMouseover(frame)
    self:ClearStickyHover()
    self.plateCursorFrame = nil
    self:RememberHover(frame)
    self:RefreshHover()
    self:StartMouseoverWatch()
end

highlight.PollHover = function(self)
    local frame = self.plateCursorFrame or self.stickyHoverFrame or self.hoverFrame
    if not frame or not frame:IsShown() then
        self:ClearStickyHover()
        self.hoverFrame = nil
        self.plateCursorFrame = nil
        self:StopMouseoverWatch()
        self:RefreshHover()
        return
    end

    if isCursorOverPlate(frame) then
        self.plateCursorFrame = frame
        self:RememberHover(frame)
        self.ignoredHoverFrame = nil
        return
    end

    if IsMouseButtonDown('LeftButton') then
        self:HoldHover(frame)
        return
    end

    if self.plateCursorFrame == frame then
        self:LeavePlateCursor(frame)
        return
    end

    local unit = EXUI:GetModule('np-core'):GetPlateUnit(frame)
    if isLiveMouseover(self, frame, unit) then
        return
    end

    if self.stickyHoverAt and (GetTime() - self.stickyHoverAt) < STICKY_GRACE then
        return
    end

    if isIgnoredHoverFrame(self, frame) then
        return
    end

    self:ClearStickyHover()
    self.hoverFrame = nil
    self:StopMouseoverWatch()
    self:RefreshHover()
end

highlight.OnPlateRemoved = function(self, frame)
    self:ForgetHover(frame)
    if not self.hoverFrame and not self.stickyHoverFrame and not self.plateCursorFrame then
        self:StopMouseoverWatch()
    end
end

highlight.OnTargetChanged = function(self)
    self:ClearStickyHover()
    self:RefreshHover()
end

highlight.OnMouseoverChanged = function(self)
    if UnitExists('mouseover') then
        local ignoredUnit = self.ignoredHoverFrame and EXUI:GetModule('np-core'):GetPlateUnit(self.ignoredHoverFrame)
        if not ignoredUnit or not UnitIsUnit('mouseover', ignoredUnit) then
            self.ignoredHoverFrame = nil
            self:ClearStickyHover()
        end
        if self.pendingMouseover then
            return
        end
        self.pendingMouseover = true
        C_Timer.After(0, function()
            self.pendingMouseover = false
            self:RefreshHover()
            self:StartMouseoverWatch()
        end)
        return
    end

    if IsMouseButtonDown('LeftButton') then
        self:HoldHover()
    else
        self:ClearStickyHover()
    end
    self:RefreshHover()
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
    return isHoverVisual(self, frame, unit)
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
    if isHoverVisual(self, frame, unit) then
        self:RememberHover(frame)
    end

    local isCurrentTarget = frame.isPreview or isCurrentTargetUnit(unit)
    local isTarget = db.targetHighlightEnable and isCurrentTarget
    local isMouseover = db.mouseoverHighlightEnable and not isCurrentTarget and isHoverVisual(self, frame, unit)

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
