---@class ExalityUI
local EXUI = select(2, ...)

------------

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

editor.frames = {}
editor.activeFrame = nil

editor.SyncEditorOverlay = function(self, frame)
    if not frame or not frame.editor then
        return
    end
    frame.editor:ClearAllPoints()
    frame.editor:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    frame.editor:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
end

editor.RefreshEditorOverlayBorder = function(self, frame)
    local overlay = frame and frame.editor
    if not overlay or not overlay.PPBorder then
        return
    end
    overlay.PPBorder:SetBorderThickness(1)
    overlay.PPBorder:SetBorderColor(1, 1, 1, 1)
end

editor.FinalizeFrameMove = function(self, frame)
    if not frame then
        return
    end

    local ufCore = EXUI:GetModule('uf-core')
    if ufCore and ufCore.SnapUnitFrame and frame.ElementFrame then
        ufCore:SnapUnitFrame(frame)
    elseif frame:GetNumPoints() == 1 then
        EXUI:SnapFrameToPixels(frame)
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

editor.RegisterFrameForEditor = function(self, frame, label, onChange, onShow, onHide)
    table.insert(self.frames, {
        label = label,
        frame = frame,
        onShow = onShow,
        onHide = onHide
    })
    self:AddEditorOverlay(frame, label, onChange)
end

editor.IsFrameRegistered = function(self, frame)
    for _, f in ipairs(self.frames) do
        if (f.frame == frame) then
            return true
        end
    end
    return false
end

editor.UpdateFrameLabel = function(self, frame, label)
    for _, f in ipairs(self.frames) do
        if (f.frame == frame) then
            f.label = label
            f.frame.editor.labelText:SetText(label)
            break
        end
    end
end

editor.UnregisterFrameForEditor = function(self, frame)
    local index = nil
    for i, f in ipairs(self.frames) do
        if (f.frame == frame) then
            index = i
            break
        end
    end

    if (index) then
        table.remove(self.frames, index)
    end
end

editor.SetActiveFrame = function(self, frame)
    if (self.activeFrame) then
        self.activeFrame.editor:HideArrows()
    end
    self.activeFrame = frame
    frame.editor:ShowArrows()
end

editor.AddEditorOverlay = function(self, frame, label, onChange)
    if (frame.editor) then return end
    frame.editor = CreateFrame('Frame', nil, UIParent, "BackdropTemplate")
    frame.editor.__owner = frame
    frame.editor.onChange = onChange

    frame.editor.SetEditorAsMovable = function(self)
        self.__owner.editorMoveOverride = true
        self:SetMovable(true)
        self.__owner:SetMovable(false)
        self:EnableMouse(true)
        self:SetPropagateMouseClicks(false)
        self:RegisterForDrag("LeftButton")
        self:SetScript('OnDragStart', function(self)
            self:StartMoving()
        end)
        self:SetScript('OnDragStop', function(self)
            self:StopMovingOrSizing()
            local owner = self.__owner
            local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1)
            owner:ClearAllPoints()
            owner:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
            if self.onChange then
                self.onChange(owner)
            end
            editor:FinalizeFrameMove(owner)
        end)
    end

    frame.isMovable = false
    frame:SetMovable(false) -- remove, only enable when the editor is visible
    frame.editor.isMouseEnabledByDefault = frame:IsMouseEnabled()
    frame:RegisterForDrag("LeftButton")
    frame:SetScript('OnDragStart', function(self)
        if (frame.isMovable) then
            self:StartMoving()
        end
    end)
    frame:SetScript('OnDragStop', function(self)
        if (frame.isMovable) then
            self:StopMovingOrSizing()
            if self.editor.onChange then
                self.editor.onChange(self)
            end
            editor:FinalizeFrameMove(self)
        end
    end)

    frame.editor:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    frame.editor:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
    frame.editor:SetFrameStrata('FULLSCREEN_DIALOG')
    EXUI:ApplySolidBorder(frame.editor, 1, { 1, 1, 1, 1 }, { 0, 0, 0, 0.7 }, { register = false })

    frame.editor:SetPropagateMouseClicks(true)
    frame.editor:SetScript('OnMouseDown', function(self)
        editor:SetActiveFrame(frame)
    end)

    local labelText = frame.editor:CreateFontString(nil, 'OVERLAY')
    labelText:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    labelText:SetPoint('LEFT', EXUI:GetBorderInset(frame.editor, 1, 3), 0)
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
    local texture = arrow:CreateTexture(nil, 'BACKGROUND')
    texture:SetTexture(EXUI.const.textures.frame.editor.arrowInactive)
    texture:SetVertexColor(1, 1, 1, 1)

    arrow:SetSize(18, 12)

    EXUI.utils.switch(direction, {
        ['X'] = function()
            texture:SetRotation(EXUI.utils.degToRad(90 * sign))
            if (sign > 0) then
                arrow:SetPoint('LEFT', frame.editor, 'RIGHT', 2, 0)
            else
                arrow:SetPoint('RIGHT', frame.editor, 'LEFT', -2, 0)
            end
        end,
        ['Y'] = function()
            if (sign > 0) then
                texture:SetRotation(EXUI.utils.degToRad(180))
            end
            if (sign > 0) then
                arrow:SetPoint('BOTTOM', frame.editor, 'TOP', 0, 3)
            else
                arrow:SetPoint('TOP', frame.editor, 'BOTTOM', 0, -3)
            end
        end,
    })

    texture:SetAllPoints()
    arrow:SetScript('OnEnter', function(self)
        texture:SetTexture(EXUI.const.textures.frame.editor.arrowActive)
    end)
    arrow:SetScript('OnLeave', function(self)
        texture:SetTexture(EXUI.const.textures.frame.editor.arrowInactive)
    end)

    arrow:SetScript('OnClick', function(self)
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        local nudge = EXUI:ScalePixel(1, frame)
        frame:ClearAllPoints()
        if (direction == 'X') then
            frame:SetPoint(point, relativeTo, relativePoint, xOfs + sign * nudge, yOfs)
        else
            frame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs + sign * nudge)
        end

        if (frame.editor.onChange) then
            frame.editor.onChange(frame)
        end
        editor:FinalizeFrameMove(frame)
    end)

    arrow:Hide()

    return arrow
end

editor.EnableEditor = function(self)
    for _, f in ipairs(self.frames) do
        if not f.frame:IsShown() then
            f.frame:Show()
        end
        if (f.onShow) then
            f.onShow(f.frame)
        end
        f.frame.editor:Show()
        f.frame.editor:EnableMouse(true)
        editor:FinalizeFrameMove(f.frame)
        if (not f.frame.editorMoveOverride) then
            f.frame.isMovable = true
            f.frame:SetMovable(true)
            f.frame:EnableMouse(true)
        end
    end
end

editor.DisableEditor = function(self)
    for _, f in ipairs(self.frames) do
        f.frame.editor:Hide()
        if (f.onHide) then
            f.onHide(f.frame)
        end
        f.frame.isMovable = false
        f.frame:SetMovable(false)
        f.frame.editorMoveOverride = nil
        f.frame:EnableMouse(f.frame.editor.isMouseEnabledByDefault)
    end
end
