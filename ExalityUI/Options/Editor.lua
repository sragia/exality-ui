---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

------------

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

local ANCHOR_POINTS = {
    'TOPLEFT', 'TOP', 'TOPRIGHT',
    'LEFT', 'CENTER', 'RIGHT',
    'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT',
}

local ANCHOR_COORDS = {
    TOPLEFT = function(left, bottom, width, height)
        return left, bottom + height
    end,
    TOP = function(left, bottom, width, height)
        return left + width * 0.5, bottom + height
    end,
    TOPRIGHT = function(left, bottom, width, height)
        return left + width, bottom + height
    end,
    LEFT = function(left, bottom, width, height)
        return left, bottom + height * 0.5
    end,
    CENTER = function(left, bottom, width, height)
        return left + width * 0.5, bottom + height * 0.5
    end,
    RIGHT = function(left, bottom, width, height)
        return left + width, bottom + height * 0.5
    end,
    BOTTOMLEFT = function(left, bottom, width, height)
        return left, bottom
    end,
    BOTTOM = function(left, bottom, width, height)
        return left + width * 0.5, bottom
    end,
    BOTTOMRIGHT = function(left, bottom, width, height)
        return left + width, bottom
    end,
}

local function getAnchorCoord(left, bottom, width, height, anchor)
    local fn = ANCHOR_COORDS[anchor]
    if not fn then
        return left, bottom
    end
    return fn(left, bottom, width, height)
end

local function getRelativeAnchorCoord(relativeTo, relativePoint)
    local left, bottom, width, height = relativeTo:GetRect()
    if not left or not bottom or not width or not height then
        return 0, 0
    end
    return getAnchorCoord(left, bottom, width, height, relativePoint)
end

local function roundOffset(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

local function getEntryForFrame(frame)
    for _, entry in ipairs(editor.frames) do
        if entry.frame == frame then
            return entry
        end
    end
end

editor.frames = {}
editor.activeFrame = nil
editor.enabled = false
editor.snapEnabled = false
editor.lastClickX = nil
editor.lastClickY = nil
editor.cycleIndex = 1
editor.lastHitsCount = 0
editor.cachedHits = nil
editor.positionClipboard = nil
editor.onExitEditMode = nil

editor.IsEditorEnabled = function(self)
    return self.enabled
end

editor.GetActiveFrame = function(self)
    return self.activeFrame
end

editor.GetFramePosition = function(self, frame)
    if not frame or frame:GetNumPoints() == 0 then
        return nil
    end
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    return {
        point = point,
        relativeTo = relativeTo or UIParent,
        relativePoint = relativePoint or point,
        x = xOfs or 0,
        y = yOfs or 0,
    }
end

local function copyHits(hits)
    local copy = {}
    for i, entry in ipairs(hits) do
        copy[i] = entry
    end
    return copy
end

local function getRegistrationIndex(entry)
    for i, registered in ipairs(editor.frames) do
        if registered == entry then
            return i
        end
    end
    return 9999
end

local function sortHitsByRegistration(hits)
    table.sort(hits, function(a, b)
        return getRegistrationIndex(a) < getRegistrationIndex(b)
    end)
end

local function isUnitFrameEnabled(ufCore, unit)
    local db = ufCore:GetDBForUnit(unit)
    return db and db.enable ~= false
end

local function getFrameHitRect(frame)
    if frame:IsShown() then
        local left, bottom, width, height = frame:GetRect()
        if left and bottom and width and height and width > 0 and height > 0 then
            return left, bottom, width, height
        end
    end
    if frame.editor and frame.editor:IsShown() then
        return frame.editor:GetRect()
    end
end

local function hitsSameSet(a, b)
    if not a or not b or #a ~= #b then
        return false
    end
    for _, entryA in ipairs(a) do
        local found = false
        for _, entryB in ipairs(b) do
            if entryA.frame == entryB.frame then
                found = true
                break
            end
        end
        if not found then
            return false
        end
    end
    return true
end

local function getTopmostHit(hits)
    local top = hits[1]
    for _, entry in ipairs(hits) do
        if entry.frame.editor:GetFrameLevel() > top.frame.editor:GetFrameLevel() then
            top = entry
        end
    end
    return top
end

editor.GetFramesAtPoint = function(self, x, y)
    local hits = {}
    for _, entry in ipairs(self.frames) do
        local frame = entry.frame
        if frame.editor and frame.editor:IsShown() then
            local left, bottom, width, height = getFrameHitRect(frame)
            if left and bottom and width and height and width > 0 and height > 0 then
                if x >= left and x <= left + width and y >= bottom and y <= bottom + height then
                    table.insert(hits, entry)
                end
            end
        end
    end
    return hits
end

editor.SyncUnitFrameEditVisibility = function(self, enabled)
    local ufCore = EXUI:GetModule('uf-core')
    if not ufCore or not ufCore.ForceShow or InCombatLockdown() then
        return
    end

    if not enabled then
        ufCore:UnforceAll()
        if ufCore.RestoreGroupHeadersAfterEditor then
            ufCore:RestoreGroupHeadersAfterEditor()
        end
        return
    end

    local editorPreview = { editorPreview = true }

    -- Single units are cheap; force-show so target/focus/etc. are visible while editing.
    for _, unit in ipairs(ufCore.units or {}) do
        if isUnitFrameEnabled(ufCore, unit) then
            ufCore:ForceShow(unit, editorPreview)
        end
    end

    -- Party/raid: never ForceShow (startingIndex=-4 spawns ~40 secure children).
    -- Size the edit overlay to the real grid and only flip visibility if needed.
    for _, unit in ipairs({ 'party', 'raid' }) do
        if isUnitFrameEnabled(ufCore, unit) then
            if ufCore.PrepareGroupHeaderForEditor then
                ufCore:PrepareGroupHeaderForEditor(unit)
            end
            ufCore:ApplyEditorGroupLayout(unit, { sizeOnly = true })
        end
    end
end

editor.HandleSelectionClick = function(self, x, y)
    local hits = self:GetFramesAtPoint(x, y)
    if #hits == 0 then
        return
    end

    local threshold = EXUI:ScalePixel(4, UIParent)
    local sameSpot = self.lastClickX and self.lastClickY
        and math.abs(x - self.lastClickX) <= threshold
        and math.abs(y - self.lastClickY) <= threshold
        and hitsSameSet(self.cachedHits, hits)

    if sameSpot and #hits > 1 then
        self.cycleIndex = (self.cycleIndex % #self.cachedHits) + 1
    else
        self.lastClickX = x
        self.lastClickY = y
        self.lastHitsCount = #hits
        self.cachedHits = copyHits(hits)
        sortHitsByRegistration(self.cachedHits)

        if #hits > 1 then
            local top = getTopmostHit(hits)
            self.cycleIndex = 1
            for i, entry in ipairs(self.cachedHits) do
                if entry.frame == top.frame then
                    self.cycleIndex = i
                    break
                end
            end
        else
            self.cycleIndex = 1
        end
    end

    self:SetActiveFrame(self.cachedHits[self.cycleIndex].frame, #hits)
end

editor.HandleOverlayMouseDown = function(self, x, y)
    if not self.enabled then
        return
    end

    local hits = self:GetFramesAtPoint(x, y)
    if #hits == 0 then
        return
    end

    for _, entry in ipairs(hits) do
        if entry.frame == self.activeFrame then
            self.pendingSelectionClick = { x = x, y = y }
            self:FocusKeyboardCapture()
            return
        end
    end

    self:HandleSelectionClick(x, y)
    self:FocusKeyboardCapture()
end

editor.HandleOverlayMouseUp = function(self, x, y, frame, overlay, button)
    if button == 'RightButton' then
        self:ShowContextMenu(frame, overlay)
        return
    end
    if button ~= 'LeftButton' or not self.pendingSelectionClick then
        return
    end

    local pending = self.pendingSelectionClick
    self.pendingSelectionClick = nil

    local threshold = EXUI:ScalePixel(4, UIParent)
    if math.abs(x - pending.x) <= threshold and math.abs(y - pending.y) <= threshold then
        self:HandleSelectionClick(pending.x, pending.y)
    end
end

editor.CycleAllFrames = function(self)
    if #self.frames == 0 then
        return
    end

    local nextIndex = 1
    if self.activeFrame then
        for i, entry in ipairs(self.frames) do
            if entry.frame == self.activeFrame then
                nextIndex = (i % #self.frames) + 1
                break
            end
        end
    end

    self.cycleIndex = 1
    self.lastHitsCount = 1
    self:SetActiveFrame(self.frames[nextIndex].frame, 1)
end

editor.RefreshEditorOverlayBorder = function(self, frame, isActive)
    local overlay = frame and frame.editor
    if not overlay or not overlay.PPBorder then
        return
    end

    local theme = EXUI.const.theme
    if isActive == nil then
        isActive = self.activeFrame == frame
    end

    if isActive then
        local accent = theme.borderActive or theme.accent
        overlay.PPBorder:SetBorderThickness(2)
        overlay.PPBorder:SetBorderColor(accent[1], accent[2], accent[3], accent[4] or 1)
        if overlay.labelText then
            overlay.labelText:SetTextColor(theme.accent[1], theme.accent[2], theme.accent[3], 1)
        end
        if overlay.backdropTint then
            overlay.backdropTint:SetVertexColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.12)
        end
    else
        local border = theme.borderInactive or theme.textMuted
        overlay.PPBorder:SetBorderThickness(1)
        overlay.PPBorder:SetBorderColor(border[1], border[2], border[3], border[4] or 0.8)
        if overlay.labelText then
            overlay.labelText:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
        end
        if overlay.backdropTint then
            overlay.backdropTint:SetVertexColor(0, 0, 0, 0.7)
        end
    end
end

editor.RefreshAllOverlayStyles = function(self)
    for _, entry in ipairs(self.frames) do
        self:RefreshEditorOverlayBorder(entry.frame)
    end
    self:RefreshArrowStyles()
end

editor.RefreshArrowStyles = function(self)
    local theme = EXUI.const.theme
    for _, entry in ipairs(self.frames) do
        local overlay = entry.frame.editor
        if overlay and overlay.arrows then
            local isActive = entry.frame == self.activeFrame
            for _, arrow in ipairs(overlay.arrows) do
                if arrow.texture then
                    if isActive then
                        arrow.texture:SetVertexColor(theme.accent[1], theme.accent[2], theme.accent[3], 1)
                    else
                        arrow.texture:SetVertexColor(1, 1, 1, 1)
                    end
                end
            end
        end
    end
end

editor.RefreshMouseRouting = function(self)
    local baseLevel = 2000
    for _, entry in ipairs(self.frames) do
        local frame = entry.frame
        local isActive = frame == self.activeFrame
        local overlay = frame.editor

        if overlay and overlay:IsShown() then
            overlay:SetFrameLevel(isActive and baseLevel + 20 or baseLevel)
            overlay:EnableMouse(true)
            if isActive and not frame.editorMoveOverride then
                overlay:SetPropagateMouseClicks(true)
            else
                overlay:SetPropagateMouseClicks(false)
            end
        end

        if frame.editorMoveOverride then
            overlay:SetMovable(false)
            frame:SetMovable(false)
            frame:EnableMouse(false)
        else
            frame.isMovable = isActive
            frame:SetMovable(isActive)
            frame:EnableMouse(isActive)
        end
    end

    if self.optionBar then
        self.optionBar:SetFrameLevel(5000)
    end
end

editor.SyncEditorOverlay = function(self, frame)
    if not frame or not frame.editor then
        return
    end
    frame.editor:ClearAllPoints()
    frame.editor:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    frame.editor:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
end

editor.ConvertAnchor = function(self, frame, newPoint, newRelativePoint)
    local point, relativeTo, relativePoint, _, _ = frame:GetPoint(1)
    if not point then
        return
    end
    relativeTo = relativeTo or UIParent
    newRelativePoint = newRelativePoint or relativePoint or point
    newPoint = newPoint or point

    local left, bottom, width, height = frame:GetRect()
    if not left or not bottom or not width or not height then
        return point, relativeTo, relativePoint, 0, 0
    end

    local anchorX, anchorY = getAnchorCoord(left, bottom, width, height, newPoint)
    local relX, relY = getRelativeAnchorCoord(relativeTo, newRelativePoint)
    return newPoint, relativeTo, newRelativePoint, anchorX - relX, anchorY - relY
end

editor.ApplyPosition = function(self, frame, point, relativeTo, relativePoint, x, y, options)
    if not frame then
        return
    end
    options = options or {}

    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo or UIParent, relativePoint or point, x or 0, y or 0)

    if self.snapEnabled and not options.skipMagnetism then
        self:ApplyEdgeMagnetism(frame)
    end

    if frame.editor and frame.editor.onChange then
        frame.editor.onChange(frame)
    end

    if not options.skipFinalize then
        self:FinalizeFrameMove(frame)
    end

    self:RefreshOptionBarPosition()
end

editor.ApplyEdgeMagnetism = function(self, frame, options)
    options = options or {}
    if not frame or frame:GetNumPoints() == 0 then
        return
    end

    local left, bottom, width, height = frame:GetRect()
    if not left or not bottom or not width or not height then
        return
    end

    local threshold = EXUI:ScalePixel(8, frame)
    local screenW, screenH = GetScreenWidth(), GetScreenHeight()
    local right = left + width
    local top = bottom + height
    local centerX = left + width * 0.5
    local centerY = bottom + height * 0.5
    local screenCenterX = screenW * 0.5
    local screenCenterY = screenH * 0.5

    local dx, dy = 0, 0

    if math.abs(left) <= threshold then
        dx = -left
    elseif math.abs(right - screenW) <= threshold then
        dx = screenW - right
    elseif math.abs(centerX - screenCenterX) <= threshold then
        dx = screenCenterX - centerX
    end

    if math.abs(bottom) <= threshold then
        dy = -bottom
    elseif math.abs(top - screenH) <= threshold then
        dy = screenH - top
    elseif math.abs(centerY - screenCenterY) <= threshold then
        dy = screenCenterY - centerY
    end

    if dx == 0 and dy == 0 then
        return
    end

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, xOfs + dx, yOfs + dy)
end

editor.ShouldSkipPixelSnap = function(self, frame)
    if not frame then
        return true
    end
    if frame.editorMoveOverride or frame.groupHeaders then
        return true
    end
    if self.enabled and frame.editor then
        return true
    end
    return false
end

---Persist anchor offsets from a moved frame. saveFn receives the frame's current x/y offsets.
editor.PersistAnchoredPosition = function(self, frame, saveFn, applyLayout)
    if not frame or frame:GetNumPoints() == 0 or not saveFn then
        return
    end

    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    saveFn(point, relativePoint, xOfs or 0, yOfs or 0)

    if applyLayout and not self.enabled then
        applyLayout()
    end
end

editor.FocusKeyboardCapture = function(self)
    if not self.enabled or not self.keyboardCapture or not self.keyboardCapture:IsShown() then
        return
    end
    if self.optionBar and self.optionBar.xInput and self.optionBar.xInput.editBox:HasFocus() then
        return
    end
    if self.optionBar and self.optionBar.yInput and self.optionBar.yInput.editBox:HasFocus() then
        return
    end
    self.keyboardCapture:Show()
    self.keyboardCapture:SetFocus()
end

editor.NudgeFrame = function(self, frame, deltaX, deltaY)
    if not frame or frame:GetNumPoints() == 0 then
        return
    end
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, xOfs + deltaX, yOfs + deltaY)
    self:FinalizeFrameMove(frame)
    if frame.editor and frame.editor.onChange then
        frame.editor.onChange(frame)
    end
    self:RefreshOptionBarPosition()
end

editor.FinalizeFrameMove = function(self, frame)
    if not frame then
        return
    end

    if not self.enabled then
        local ufCore = EXUI:GetModule('uf-core')
        if ufCore and ufCore.SnapUnitFrame and frame.ElementFrame then
            ufCore:SnapUnitFrame(frame)
        elseif frame:GetNumPoints() == 1 and not self:ShouldSkipPixelSnap(frame) then
            EXUI:SnapFrameToPixels(frame)
        end
    end

    if frame.PPBorder then
        frame.PPBorder:SetBorderThickness(frame.PPBorder.thicknessPixels or 1)
    end
    if frame.EditPlaceholder and frame.EditPlaceholder.PPBorder then
        frame.EditPlaceholder.PPBorder:SetBorderThickness(1)
    end

    self:SyncEditorOverlay(frame)
    self:RefreshEditorOverlayBorder(frame)

    C_Timer.After(0, function()
        if not frame.editor or not frame.editor:IsShown() then
            return
        end
        self:SyncEditorOverlay(frame)
        self:RefreshEditorOverlayBorder(frame)
    end)
end

editor.OnFrameDragStop = function(self, frame)
    if self.snapEnabled then
        self:ApplyEdgeMagnetism(frame)
    end
    if frame.editor and frame.editor.onChange then
        frame.editor.onChange(frame)
    end
    self:FinalizeFrameMove(frame)
    self:RefreshOptionBarPosition()
end

editor.RegisterFrameForEditor = function(self, frame, label, onChange, onShow, onHide, meta)
    table.insert(self.frames, {
        label = label,
        frame = frame,
        onShow = onShow,
        onHide = onHide,
        meta = meta,
    })
    self:AddEditorOverlay(frame, label, onChange)
end

editor.IsFrameRegistered = function(self, frame)
    for _, f in ipairs(self.frames) do
        if f.frame == frame then
            return true
        end
    end
    return false
end

editor.UpdateFrameLabel = function(self, frame, label)
    for _, f in ipairs(self.frames) do
        if f.frame == frame then
            f.label = label
            f.frame.editor.labelText:SetText(label)
            break
        end
    end
    self:RefreshOptionBarPosition()
end

editor.UnregisterFrameForEditor = function(self, frame)
    local index = nil
    for i, f in ipairs(self.frames) do
        if f.frame == frame then
            index = i
            break
        end
    end

    if index then
        table.remove(self.frames, index)
    end
    if self.activeFrame == frame then
        self.activeFrame = nil
        self:RefreshOptionBarPosition()
    end
end

editor.SetActiveFrame = function(self, frame, overlapCount)
    if not frame then
        return
    end

    if self.activeFrame and self.activeFrame.editor then
        self.activeFrame.editor:HideArrows()
    end

    self.activeFrame = frame
    frame.editor:ShowArrows()
    self:RefreshAllOverlayStyles()
    self:RefreshMouseRouting()
    self:RefreshOptionBarPosition(overlapCount)
    self:FocusKeyboardCapture()
end

editor.EnsureClickCatcher = function(self)
    if self.clickCatcher then
        return
    end

    local catcher = CreateFrame('Frame', 'ExalityUIEditorClickCatcher', UIParent)
    catcher:SetFrameStrata('FULLSCREEN_DIALOG')
    catcher:SetAllPoints(UIParent)
    catcher:EnableMouse(true)
    catcher:Hide()

    catcher:SetScript('OnMouseDown', function(_, button)
        if button ~= 'LeftButton' or not editor.enabled then
            return
        end
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        editor:HandleSelectionClick(x / scale, y / scale)
    end)

    self.clickCatcher = catcher
end

editor.EnsureKeyboardCapture = function(self)
    if self.keyboardCapture then
        return
    end

    local capture = CreateFrame('EditBox', 'ExalityUIEditorKeyboardCapture', UIParent)
    capture:SetAutoFocus(false)
    capture:EnableKeyboard(true)
    capture:EnableMouse(false)
    capture:SetSize(1, 1)
    capture:SetAlpha(0)
    capture:SetText('')
    capture:Hide()

    capture:SetScript('OnEscapePressed', function(self)
        self:ClearFocus()
    end)

    capture:SetScript('OnKeyDown', function(_, key)
        if not editor.enabled then
            return
        end

        if key == 'TAB' then
            editor:CycleAllFrames()
            return
        end

        local frame = editor.activeFrame
        if not frame then
            return
        end

        local nudge = EXUI:ScalePixel(1, frame)
        if IsShiftKeyDown() then
            nudge = nudge * 10
        end

        if key == 'UP' then
            editor:NudgeFrame(frame, 0, nudge)
        elseif key == 'DOWN' then
            editor:NudgeFrame(frame, 0, -nudge)
        elseif key == 'LEFT' then
            editor:NudgeFrame(frame, -nudge, 0)
        elseif key == 'RIGHT' then
            editor:NudgeFrame(frame, nudge, 0)
        else
            return
        end
    end)

    self.keyboardCapture = capture
end

editor.ShowContextMenu = function(self, frame, anchor)
    if not frame then
        return
    end

    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(anchor, function(_, rootDescription)
            rootDescription:CreateTitle(frame.editor.labelText and frame.editor.labelText:GetText() or 'Frame')

            rootDescription:CreateButton('Next Overlapping Frame', function()
                local x, y = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                editor:HandleSelectionClick(x / scale, y / scale)
            end)

            rootDescription:CreateDivider()

            rootDescription:CreateButton('Center on Screen', function()
                editor:ApplyPosition(frame, 'CENTER', UIParent, 'CENTER', 0, 0)
            end)

            rootDescription:CreateButton('Align Top', function()
                local left = select(1, frame:GetRect())
                local inset = EXUI:ScalePixel(4, frame)
                editor:ApplyPosition(frame, 'TOP', UIParent, 'TOP', left or 0, -inset)
            end)

            rootDescription:CreateButton('Align Bottom', function()
                local left = select(1, frame:GetRect())
                local inset = EXUI:ScalePixel(4, frame)
                editor:ApplyPosition(frame, 'BOTTOM', UIParent, 'BOTTOM', left or 0, inset)
            end)

            local anchorMenu = rootDescription:CreateButton('Anchor Point')
            for _, anchorPoint in ipairs(ANCHOR_POINTS) do
                anchorMenu:CreateButton(anchorPoint, function()
                    local pos = editor:GetFramePosition(frame)
                    if not pos then return end
                    local point, relativeTo, relativePoint, x, y = editor:ConvertAnchor(frame, anchorPoint,
                        pos.relativePoint)
                    editor:ApplyPosition(frame, point, relativeTo, relativePoint, x, y)
                end)
            end

            rootDescription:CreateDivider()

            rootDescription:CreateButton('Copy Position', function()
                editor.positionClipboard = editor:GetFramePosition(frame)
            end)

            rootDescription:CreateButton('Paste Position', function()
                local clip = editor.positionClipboard
                if not clip then return end
                editor:ApplyPosition(frame, clip.point, clip.relativeTo, clip.relativePoint, clip.x, clip.y)
            end)

            local entry = getEntryForFrame(frame)
            local meta = entry and entry.meta
            if meta and meta.getDefaults then
                rootDescription:CreateButton('Reset to Default', function()
                    local defaults = meta.getDefaults(frame)
                    if defaults then
                        editor:ApplyPosition(
                            frame,
                            defaults.anchorPoint or defaults.point,
                            defaults.relativeTo or UIParent,
                            defaults.relativeAnchorPoint or defaults.relativePoint or defaults.anchorPoint,
                            defaults.XOff or defaults.x or defaults.xOff or 0,
                            defaults.YOff or defaults.y or defaults.yOff or 0
                        )
                    end
                    if meta.resetPosition then
                        meta.resetPosition(frame)
                    end
                end)
            end

            if meta and meta.openSettings then
                rootDescription:CreateButton('Open Settings', function()
                    meta.openSettings(frame)
                end)
            end
        end)
        return
    end

    if EXFrames and EXFrames.GetFrame then
        local listMenu = EXFrames:GetFrame('list-menu-frame')
        if listMenu then
            local entries = {
                {
                    label = 'Center on Screen',
                    onClick = function()
                        editor:ApplyPosition(frame, 'CENTER', UIParent, 'CENTER', 0, 0)
                    end
                },
                {
                    label = 'Copy Position',
                    onClick = function()
                        editor.positionClipboard = editor:GetFramePosition(frame)
                    end
                },
                {
                    label = 'Paste Position',
                    onClick = function()
                        local clip = editor.positionClipboard
                        if clip then
                            editor:ApplyPosition(frame, clip.point, clip.relativeTo, clip.relativePoint, clip.x, clip.y)
                        end
                    end
                },
            }
            listMenu:ShowAt(anchor, entries)
        end
    end
end

editor.AddEditorOverlay = function(self, frame, label, onChange)
    if frame.editor then
        return
    end

    frame.editor = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
    frame.editor.__owner = frame
    frame.editor.onChange = onChange

    frame.editor.SetEditorAsMovable = function(self)
        self.__owner.editorMoveOverride = true
        self:SetMovable(false)
        self.__owner:SetMovable(false)
        self:EnableMouse(true)
        self:SetPropagateMouseClicks(false)
        self:RegisterForDrag('LeftButton')
        self:SetScript('OnDragStart', function(overlay)
            editor.pendingSelectionClick = nil
            local owner = overlay.__owner
            if owner ~= editor.activeFrame then
                editor:SetActiveFrame(owner, 1)
            end
            owner:SetMovable(true)
            owner:StartMoving()
        end)
        self:SetScript('OnDragStop', function(overlay)
            local owner = overlay.__owner
            if owner:IsMovable() then
                owner:StopMovingOrSizing()
                owner:SetMovable(false)
            end
            editor:SyncEditorOverlay(owner)
            editor:OnFrameDragStop(owner)
        end)
    end

    frame.isMovable = false
    frame:SetMovable(false)
    frame.editor.isMouseEnabledByDefault = frame:IsMouseEnabled()
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', function(self)
        editor.pendingSelectionClick = nil
        if self.isMovable then
            self:StartMoving()
        end
    end)
    frame:SetScript('OnDragStop', function(self)
        if self.isMovable then
            self:StopMovingOrSizing()
            editor:OnFrameDragStop(self)
        end
    end)

    frame.editor:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    frame.editor:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
    frame.editor:SetFrameStrata('FULLSCREEN_DIALOG')
    EXUI:ApplySolidBorder(frame.editor, 1, { 1, 1, 1, 1 }, { 0, 0, 0, 0.7 }, { register = false })

    local backdropTint = frame.editor:CreateTexture(nil, 'BACKGROUND', nil, -1)
    backdropTint:SetAllPoints()
    backdropTint:SetColorTexture(0, 0, 0, 0.7)
    frame.editor.backdropTint = backdropTint

    frame.editor:SetPropagateMouseClicks(true)
    frame.editor:SetScript('OnMouseDown', function(_, button)
        if button ~= 'LeftButton' then
            return
        end
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        editor:HandleOverlayMouseDown(x / scale, y / scale)
    end)
    frame.editor:SetScript('OnMouseUp', function(_, button)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        editor:HandleOverlayMouseUp(x / scale, y / scale, frame, frame.editor, button)
    end)

    local labelText = frame.editor:CreateFontString(nil, 'OVERLAY')
    labelText:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    labelText:SetPoint('TOPLEFT', EXUI:GetBorderInset(frame.editor, 1, 3), EXUI:GetBorderInset(frame.editor, -1, -3))
    labelText:SetWidth(0)
    labelText:SetText(label)
    frame.editor.labelText = labelText

    frame.editor.arrows = {}
    table.insert(frame.editor.arrows, self:AddOffsetArrow(frame, 'X', 1))
    table.insert(frame.editor.arrows, self:AddOffsetArrow(frame, 'X', -1))
    table.insert(frame.editor.arrows, self:AddOffsetArrow(frame, 'Y', 1))
    table.insert(frame.editor.arrows, self:AddOffsetArrow(frame, 'Y', -1))

    frame.editor.ShowArrows = function(self)
        for _, arrow in ipairs(self.arrows) do
            arrow:Show()
        end
    end
    frame.editor.HideArrows = function(self)
        for _, arrow in ipairs(self.arrows) do
            arrow:Hide()
        end
    end

    frame.editor:Hide()
end

editor.AddOffsetArrow = function(self, frame, direction, sign)
    local arrow = CreateFrame('Button', nil, frame.editor)
    arrow:SetFrameStrata('FULLSCREEN_DIALOG')
    arrow:SetFrameLevel(frame.editor:GetFrameLevel() + 10)
    local texture = arrow:CreateTexture(nil, 'BACKGROUND')
    texture:SetTexture(EXUI.const.textures.frame.editor.arrowInactive)
    texture:SetVertexColor(1, 1, 1, 1)
    arrow.texture = texture

    arrow:SetSize(18, 12)

    EXUI.utils.switch(direction, {
        ['X'] = function()
            texture:SetRotation(EXUI.utils.degToRad(90 * sign))
            if sign > 0 then
                arrow:SetPoint('LEFT', frame.editor, 'RIGHT', 2, 0)
            else
                arrow:SetPoint('RIGHT', frame.editor, 'LEFT', -2, 0)
            end
        end,
        ['Y'] = function()
            if sign > 0 then
                texture:SetRotation(EXUI.utils.degToRad(180))
            end
            if sign > 0 then
                arrow:SetPoint('BOTTOM', frame.editor, 'TOP', 0, 3)
            else
                arrow:SetPoint('TOP', frame.editor, 'BOTTOM', 0, -3)
            end
        end,
    })

    texture:SetAllPoints()
    arrow:SetScript('OnEnter', function()
        texture:SetTexture(EXUI.const.textures.frame.editor.arrowActive)
    end)
    arrow:SetScript('OnLeave', function()
        texture:SetTexture(EXUI.const.textures.frame.editor.arrowInactive)
        editor:RefreshArrowStyles()
    end)

    arrow:SetScript('OnClick', function()
        editor:SetActiveFrame(frame, 1)
        local nudge = EXUI:ScalePixel(1, frame)
        if direction == 'X' then
            editor:NudgeFrame(frame, sign * nudge, 0)
        else
            editor:NudgeFrame(frame, 0, sign * nudge)
        end
    end)

    arrow:Hide()
    return arrow
end

editor.EnableEditor = function(self)
    self.enabled = true
    self.cycleIndex = 1
    self.lastHitsCount = 0
    self.cachedHits = nil
    self.pendingSelectionClick = nil
    self:EnsureKeyboardCapture()
    self.keyboardCapture:Show()
    self.keyboardCapture:SetPropagateKeyboardInput(false)
    self:FocusKeyboardCapture()

    self:SyncUnitFrameEditVisibility(true)

    for _, f in ipairs(self.frames) do
        if not f.frame:IsShown() then
            f.frame:Show()
        end
        if f.onShow then
            f.onShow(f.frame)
        end
        f.frame.editor:Show()
        self:SyncEditorOverlay(f.frame)
        self:RefreshEditorOverlayBorder(f.frame)
    end

    if #self.frames > 0 and not self.activeFrame then
        self:SetActiveFrame(self.frames[1].frame, 1)
    elseif self.activeFrame then
        self:SetActiveFrame(self.activeFrame, 1)
    else
        self:RefreshAllOverlayStyles()
    end

    self:ShowOptionBar()
end

editor.CommitAllFramePositions = function(self)
    for _, entry in ipairs(self.frames) do
        local frame = entry.frame
        if frame and frame.editor and frame.editor.onChange and frame:GetNumPoints() > 0 then
            frame.editor.onChange(frame)
        end
    end
end

editor.DisableEditor = function(self)
    self.pendingSelectionClick = nil

    if self.activeFrame and self.activeFrame.editor then
        self.activeFrame.editor:HideArrows()
    end
    self.activeFrame = nil

    for _, f in ipairs(self.frames) do
        f.frame.editor:Hide()
        if f.onHide then
            f.onHide(f.frame)
        end
        f.frame.isMovable = false
        f.frame:SetMovable(false)
        f.frame.editorMoveOverride = nil
        f.frame:EnableMouse(f.frame.editor.isMouseEnabledByDefault)
    end

    if self.keyboardCapture then
        self.keyboardCapture:ClearFocus()
        self.keyboardCapture:Hide()
    end

    self:HideOptionBar()

    self.enabled = false
    self:CommitAllFramePositions()

    self:SyncUnitFrameEditVisibility(false)

    local stateController = EXUI:GetModule('action-bars-state')
    if stateController and stateController.ApplyAll then
        stateController:ApplyAll()
    end

    if self.onExitEditMode then
        self.onExitEditMode()
    end
end

-- Option bar UI is defined in EditorOptionBar.lua
editor.RefreshOptionBarPosition = function(self, overlapCount)
    if self.optionBar and self.optionBar.RefreshPosition then
        self.optionBar:RefreshPosition(overlapCount)
    end
end

editor.ShowOptionBar = function(self)
    if self.EnsureOptionBar then
        self:EnsureOptionBar()
    end
    if self.optionBar then
        self.optionBar:ShowBar()
    end
end

editor.HideOptionBar = function(self)
    if self.optionBar then
        self.optionBar:HideBar()
    end
end

editor.SetSnapEnabled = function(self, enabled)
    self.snapEnabled = enabled and true or false
end

editor.GetRegisteredFrameEntries = function(self)
    return self.frames
end

editor.SelectRegisteredFrame = function(self, frame)
    self.cycleIndex = 1
    self.lastHitsCount = 1
    self:SetActiveFrame(frame, 1)
end

editor.ApplyPositionFromBar = function(self, frame, point, relativePoint, x, y)
    local pos = self:GetFramePosition(frame)
    if not pos then
        return
    end

    x = tonumber(x) or 0
    y = tonumber(y) or 0

    if point ~= pos.point or relativePoint ~= pos.relativePoint then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.x, pos.y)
        point, pos.relativeTo, relativePoint, x, y = self:ConvertAnchor(frame, point, relativePoint)
    end

    self:ApplyPosition(frame, point, pos.relativeTo, relativePoint, x, y)
end

editor.GetAnchorPoints = function()
    return ANCHOR_POINTS
end

editor.FormatOffset = function(_, value)
    return roundOffset(value)
end
