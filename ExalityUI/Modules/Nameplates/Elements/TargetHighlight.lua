---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesElementTargetHighlight
local highlight = EXUI:GetModule('np-element-target-highlight')

local LCG = LibStub('LibCustomGlow-1.0', true)
local ARROW_SIZE = 14

local function stopGlow(frame)
    if LCG and LCG.PixelGlow_Stop then
        LCG.PixelGlow_Stop(frame)
    end
end

local function startGlow(frame, db)
    if not LCG or not LCG.PixelGlow_Start then
        return
    end
    local c = db.targetHighlightColor or { r = 1, g = 0.82, b = 0.2, a = 1 }
    LCG.PixelGlow_Start(frame, { c.r, c.g, c.b, c.a or 1 }, 8, 0.25, nil, 1, 0, 0, false)
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

local function isMouseoverUnit(unit)
    return unit and UnitExists('mouseover') and UnitIsUnit(unit, 'mouseover')
end

highlight.StartMouseoverWatch = function(self)
    if not self.watch then
        self.watch = CreateFrame('Frame')
    end
    self.watch.elapsed = 0
    self.watch:SetScript('OnUpdate', function(watch, elapsed)
        watch.elapsed = watch.elapsed + elapsed
        if watch.elapsed < 0.05 then
            return
        end
        watch.elapsed = 0
        if UnitExists('mouseover') then
            return
        end
        highlight:StopMouseoverWatch()
        EXUI:GetModule('np-core'):UpdateTargetHighlight()
    end)
end

highlight.StopMouseoverWatch = function(self)
    if not self.watch then
        return
    end
    self.watch:SetScript('OnUpdate', nil)
    self.watch.elapsed = 0
end

highlight.OnMouseoverChanged = function(self)
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
            self:StopMouseoverWatch()
        end
    end)
end

highlight.Update = function(self, frame)
    local db = frame.db
    local npCore = EXUI:GetModule('np-core')
    if frame.isFriendly or not db then
        resetChrome(frame)
        return
    end

    local unit = npCore:GetPlateUnit(frame)
    local isTarget = db.targetHighlightEnable and unit and UnitExists('target') and UnitIsUnit(unit, 'target')
    local isMouseover = db.mouseoverHighlightEnable and isMouseoverUnit(unit)

    if db.targetHighlightEnable and db.targetHighlightDimOthers and UnitExists('target') and not isTarget then
        frame._exuiDimmed = true
        frame:SetAlpha(db.targetHighlightDimAlpha or 0.45)
    else
        clearDim(frame)
    end

    if isTarget then
        local style = db.targetHighlightStyle or 'glow'
        if style == 'glow' then
            npCore:ApplyHealthChrome(frame, isMouseover and db.mouseoverHighlightColor or nil)
            hideArrows(frame)
            startGlow(frame, db)
        elseif style == 'arrows' then
            npCore:ApplyHealthChrome(frame, isMouseover and db.mouseoverHighlightColor or nil)
            stopGlow(frame)
            showArrows(frame, db)
        else
            stopGlow(frame)
            hideArrows(frame)
            npCore:ApplyHealthChrome(frame, db.targetHighlightColor)
        end
        return
    end

    stopGlow(frame)
    hideArrows(frame)
    if isMouseover then
        npCore:ApplyHealthChrome(frame, db.mouseoverHighlightColor)
    else
        npCore:ApplyHealthChrome(frame)
    end
end
