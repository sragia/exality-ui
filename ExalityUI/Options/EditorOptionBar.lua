---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

local BAR_WIDTH = 220
local PADDING = 12
local ROW_GAP = 10
local INPUT_WIDTH = 64
local INPUT_HEIGHT = 22
local EXIT_HEIGHT = 28
local FRAME_VALUE_HEIGHT = 16

local function createCompactInput(parent, width, onCommit)
    local theme = EXUI.const.theme
    local container = CreateFrame('Frame', nil, parent)
    container:SetSize(width, INPUT_HEIGHT)

    local bg = container:CreateTexture(nil, 'BACKGROUND')
    bg:SetColorTexture(theme.backgroundDeep[1], theme.backgroundDeep[2], theme.backgroundDeep[3], 1)
    bg:SetAllPoints()
    EXUI:AddPixelPerfectBorder(container, 1, { register = false })
    if container.PPBorder then
        container.PPBorder:SetBorderColor(theme.border[1], theme.border[2], theme.border[3], theme.border[4] or 1)
    end

    local editBox = CreateFrame('EditBox', nil, container)
    editBox:SetAutoFocus(false)
    editBox:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    editBox:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    editBox:SetPoint('TOPLEFT', EXUI:GetBorderInset(container, 1, 4), -EXUI:GetBorderInset(container, 1, 2))
    editBox:SetPoint('BOTTOMRIGHT', -EXUI:GetBorderInset(container, 1, 4), EXUI:GetBorderInset(container, 1, 2))
    editBox:SetTextInsets(4, 4, 0, 0)

    editBox:SetScript('OnEscapePressed', function(self)
        self:ClearFocus()
        if onCommit then
            onCommit(self, true)
        end
    end)

    editBox:SetScript('OnEnterPressed', function(self)
        self:ClearFocus()
        if onCommit then
            onCommit(self, false)
        end
    end)

    editBox:SetScript('OnEditFocusLost', function(self)
        if onCommit then
            onCommit(self, false)
        end
    end)

    container.editBox = editBox
    return container
end

local function setupDragRegion(region, bar)
    region:EnableMouse(true)
    region:SetScript('OnEnter', function(self)
        self:SetScript('OnUpdate', function()
            if IsMouseButtonDown('LeftButton') then
                local cx, cy = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                cx, cy = cx / scale, cy / scale
                if not self.dragging then
                    self.dragging = true
                    self.startX, self.startY = cx, cy
                    local point, _, _, x, y = bar:GetPoint(1)
                    self.anchorPoint = point
                    self.startOffX, self.startOffY = x, y
                else
                    bar:ClearAllPoints()
                    bar:SetPoint(self.anchorPoint or 'TOP', UIParent, self.anchorPoint or 'TOP',
                        (self.startOffX or 0) + cx - self.startX,
                        (self.startOffY or 0) + cy - self.startY)
                end
            elseif self.dragging then
                self.dragging = false
                self:SetScript('OnUpdate', nil)
            end
        end)
    end)
    region:SetScript('OnLeave', function(self)
        if not self.dragging then
            self:SetScript('OnUpdate', nil)
        end
    end)
end

editor.EnsureOptionBar = function(self)
    if self.optionBar then
        self.optionBar:HideBar()
        self.optionBar = nil
    end

    local theme = EXUI.const.theme
    local buttonFrame = EXFrames:GetFrame('button')
    local checkbox = EXFrames:GetFrame('checkbox')

    local contentWidth = BAR_WIDTH - PADDING * 2
    local totalHeight = PADDING + 18 + 6 + 20 + ROW_GAP + 12 + 4 + FRAME_VALUE_HEIGHT + ROW_GAP + INPUT_HEIGHT + ROW_GAP + EXIT_HEIGHT + PADDING

    local bar = CreateFrame('Frame', 'ExalityUIEditorOptionBar', UIParent, 'BackdropTemplate')
    bar:SetFrameStrata('FULLSCREEN_DIALOG')
    bar:SetFrameLevel(5000)
    bar:SetClampedToScreen(true)
    bar:SetSize(BAR_WIDTH, totalHeight)
    bar:SetPoint('TOP', UIParent, 'TOP', 0, -8)
    EXUI:ApplySolidBorder(bar, 1, theme.border, theme.backgroundDeep, { register = false })

    local lastGoodX, lastGoodY = 0, 0

    local title = bar:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 14, 'OUTLINE')
    title:SetPoint('TOPLEFT', PADDING, -PADDING)
    title:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    title:SetText('Edit Mode')
    bar.title = title

    local snapCheck = checkbox:Create()
    snapCheck:SetParent(bar)
    snapCheck:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -6)
    snapCheck:SetFrameWidth(52)
    snapCheck:SetLabel('Snap')
    snapCheck:SetValue('value', editor.snapEnabled)
    snapCheck.onChange = function(value)
        editor.snapEnabled = value and true or false
    end
    bar.snapCheck = snapCheck

    local frameLabel = bar:CreateFontString(nil, 'OVERLAY')
    frameLabel:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    frameLabel:SetPoint('TOPLEFT', snapCheck, 'BOTTOMLEFT', 0, -ROW_GAP)
    frameLabel:SetText('Selected Frame')
    frameLabel:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)

    local frameValue = bar:CreateFontString(nil, 'OVERLAY')
    frameValue:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    frameValue:SetPoint('TOPLEFT', frameLabel, 'BOTTOMLEFT', 0, -4)
    frameValue:SetPoint('TOPRIGHT', bar, 'TOPRIGHT', -PADDING, 0)
    frameValue:SetJustifyH('LEFT')
    frameValue:SetHeight(FRAME_VALUE_HEIGHT)
    frameValue:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    bar.frameValue = frameValue

    local offsetRow = CreateFrame('Frame', nil, bar)
    offsetRow:SetPoint('TOPLEFT', frameValue, 'BOTTOMLEFT', 0, -ROW_GAP)
    offsetRow:SetSize(contentWidth, INPUT_HEIGHT)

    local xLabel = offsetRow:CreateFontString(nil, 'OVERLAY')
    xLabel:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    xLabel:SetPoint('LEFT', 0, 0)
    xLabel:SetText('X')
    xLabel:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)

    local function commitInput(editBox, reverted)
        local frame = editor.activeFrame
        if not frame or bar.updatingFields then
            return
        end
        if reverted then
            editBox:SetText(tostring(editBox == bar.xInput.editBox and lastGoodX or lastGoodY))
            return
        end
        local pos = editor:GetFramePosition(frame)
        if not pos then
            return
        end
        local xVal = tonumber(bar.xInput.editBox:GetText())
        local yVal = tonumber(bar.yInput.editBox:GetText())
        if not xVal or not yVal then
            bar.xInput.editBox:SetText(tostring(lastGoodX))
            bar.yInput.editBox:SetText(tostring(lastGoodY))
            return
        end
        lastGoodX, lastGoodY = xVal, yVal
        editor:ApplyPositionFromBar(frame, pos.point, pos.relativePoint, xVal, yVal)
    end

    local xInput = createCompactInput(offsetRow, INPUT_WIDTH, commitInput)
    xInput:SetPoint('LEFT', xLabel, 'RIGHT', 6, 0)
    bar.xInput = xInput

    local yLabel = offsetRow:CreateFontString(nil, 'OVERLAY')
    yLabel:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    yLabel:SetPoint('LEFT', xInput, 'RIGHT', 14, 0)
    yLabel:SetText('Y')
    yLabel:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)

    local yInput = createCompactInput(offsetRow, INPUT_WIDTH, commitInput)
    yInput:SetPoint('LEFT', yLabel, 'RIGHT', 6, 0)
    bar.yInput = yInput

    local exitBtn = buttonFrame:Create({
        text = 'Exit Edit Mode',
        size = { contentWidth, EXIT_HEIGHT },
        color = theme.danger,
        onClick = function()
            editor:DisableEditor()
        end,
    }, bar)
    exitBtn:SetPoint('TOPLEFT', offsetRow, 'BOTTOMLEFT', 0, -ROW_GAP)
    exitBtn:SetPoint('TOPRIGHT', offsetRow, 'BOTTOMRIGHT', 0, -ROW_GAP)
    exitBtn:SetHeight(EXIT_HEIGHT)
    bar.exitBtn = exitBtn

    local dragRegion = CreateFrame('Frame', nil, bar)
    dragRegion:SetPoint('TOPLEFT', PADDING, -PADDING)
    dragRegion:SetPoint('BOTTOMRIGHT', frameValue, 'BOTTOMRIGHT', PADDING, 0)
    dragRegion:SetFrameLevel(bar:GetFrameLevel())
    setupDragRegion(dragRegion, bar)
    bar.dragRegion = dragRegion

    bar.RefreshPosition = function(f, overlapCount)
        local frame = editor.activeFrame
        if not frame then
            f.frameValue:SetText('None')
            f.updatingFields = true
            f.xInput.editBox:SetText('')
            f.yInput.editBox:SetText('')
            f.xInput.editBox:EnableMouse(false)
            f.yInput.editBox:EnableMouse(false)
            f.updatingFields = false
            return
        end

        local entry = nil
        for _, e in ipairs(editor.frames) do
            if e.frame == frame then
                entry = e
                break
            end
        end

        local label = entry and entry.label or 'Frame'
        if overlapCount and overlapCount > 1 then
            label = string.format('%d/%d · %s', editor.cycleIndex, overlapCount, label)
        end
        f.frameValue:SetText(label)

        local pos = editor:GetFramePosition(frame)
        if not pos then
            return
        end

        if not f.xInput.editBox:HasFocus() and not f.yInput.editBox:HasFocus() then
            f.updatingFields = true
            lastGoodX = editor:FormatOffset(pos.x)
            lastGoodY = editor:FormatOffset(pos.y)
            f.xInput.editBox:SetText(tostring(lastGoodX))
            f.yInput.editBox:SetText(tostring(lastGoodY))
            f.xInput.editBox:EnableMouse(true)
            f.yInput.editBox:EnableMouse(true)
            f.updatingFields = false
        end
    end

    bar.RefreshSnapToggle = function(f)
        if not f.snapCheck then
            return
        end
        local enabled = editor.snapEnabled and true or false
        if f.snapCheck.value == enabled then
            return
        end
        f.snapCheck.value = enabled
        if enabled then
            f.snapCheck.Mark:SetAlpha(1)
        else
            f.snapCheck.Mark:SetAlpha(0)
        end
    end

    bar.ShowBar = function(f)
        f:SetShown(true)
        f:RefreshPosition()
        f:RefreshSnapToggle()
    end

    bar.HideBar = function(f)
        f:SetShown(false)
    end

    self.optionBar = bar
end
