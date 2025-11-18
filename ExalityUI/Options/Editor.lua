---@class ExalityUI
local EXUI = select(2, ...)

------------

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

editor.frames = {}

editor.RegisterFrameForEditor = function(self, frame, label, onChange, onShow, onHide)
    table.insert(self.frames, {
        label = label,
        frame = frame,
        onShow = onShow,
        onHide = onHide
    })
    self:AddEditorOverlay(frame, label, onChange)
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
        self:RegisterForDrag("LeftButton")
        self:SetScript('OnDragStart', function(self)
            self:StartMoving()
        end)
        self:SetScript('OnDragStop', function(self)
            self:StopMovingOrSizing()
            self.onChange(self)
        end)
    end

    frame.isMovable = false
    frame:SetMovable(false) -- remove, only enable when the editor is visible
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript('OnDragStart', function(self)
        if (frame.isMovable) then
            self:StartMoving()
        end
    end)
    frame:SetScript('OnDragStop', function(self)
        if (frame.isMovable) then
            self:StopMovingOrSizing()
            self.editor.onChange(self)
        end
    end)

    frame.editor:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    frame.editor:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
    frame.editor:SetFrameStrata('FULLSCREEN_DIALOG')
    frame.editor:SetBackdrop(EXUI.const.backdrop.DEFAULT)
    frame.editor:SetBackdropBorderColor(1, 1, 1, 1)
    frame.editor:SetBackdropColor(0, 0, 0, 0.7)

    local labelText = frame.editor:CreateFontString(nil, 'OVERLAY')
    labelText:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    labelText:SetPoint('LEFT', 3, 0)
    labelText:SetWidth(0)
    labelText:SetText(label)

    self:AddOffsetArrow(frame, 'X', 1)
    self:AddOffsetArrow(frame, 'X', -1)
    self:AddOffsetArrow(frame, 'Y', 1)
    self:AddOffsetArrow(frame, 'Y', -1)
    
    frame.editor:Hide()
end

editor.AddOffsetArrow = function(self, frame, direction, sign)
    local arrow = CreateFrame('Button', nil, frame.editor)
    local texture = arrow:CreateTexture(nil, 'BACKGROUND')
    texture:SetTexture(EXUI.const.textures.frame.editor.arrowInactive)
    texture:SetVertexColor(1, 1, 1, 1)

    arrow:SetSize(18,12)

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
        frame:ClearAllPoints()
        if (direction == 'X') then
            frame:SetPoint(point, relativeTo, relativePoint, xOfs + sign * 1, yOfs)
            frame.editor:SetPoint(point, relativeTo, relativePoint, xOfs + sign * 1, yOfs)
        else
            frame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs + 1 * sign)
            frame.editor:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs + 1 * sign)
        end

        if (frame.editor.onChange) then
            frame.editor.onChange(frame)
        end
    end)
end

editor.EnableEditor = function(self)
    for _, f in ipairs(self.frames) do
        f.frame.editor:Show()
        if (f.onShow) then
            f.onShow(f.frame)
        end
        if (not f.frame.editorMoveOverride) then
            f.frame.isMovable = true
            f.frame:SetMovable(true)
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
    end
end