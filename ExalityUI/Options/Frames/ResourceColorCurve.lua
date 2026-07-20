---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIOptionsResourceColorCurve
local curveEditor = EXUI:GetModule('options-resource-color-curve')

curveEditor.pool = nil

local ROW_HEIGHT = 48
local ROW_GAP = 4
local ADD_BUTTON_HEIGHT = 28
local PADDING = 6
local DELETE_BUTTON_SIZE = 28

local function cloneCurve(curve)
    return EXUI.utils.deepCloneTable(curve or {})
end

local function defaultPoint(percent)
    return {
        percent = percent or 0,
        color = { r = 1, g = 0.2, b = 0.2, a = 1 },
    }
end

local function minPercentForIndex(curve, index)
    if index <= 1 then
        return 0
    end
    return (curve[index - 1].percent or 0) + 1
end

local function maxPercentForIndex(curve, index)
    if index >= #curve then
        return 100
    end
    return math.max(minPercentForIndex(curve, index), (curve[index + 1].percent or 100) - 1)
end

local function normalizeCurve(curve)
    table.sort(curve, function(a, b)
        return (a.percent or 0) < (b.percent or 0)
    end)

    for index = 1, #curve do
        local min = minPercentForIndex(curve, index)
        local max = maxPercentForIndex(curve, index)
        local percent = curve[index].percent or 0
        curve[index].percent = math.min(math.max(percent, min), max)
    end

    for index = 2, #curve do
        local min = minPercentForIndex(curve, index)
        if (curve[index].percent or 0) < min then
            curve[index].percent = min
        end
    end

    return curve
end

local function applyPercentChange(curve, index, newPercent)
    if not curve[index] then
        return curve
    end
    local min = minPercentForIndex(curve, index)
    local max = maxPercentForIndex(curve, index)
    curve[index].percent = math.min(math.max(newPercent, min), max)

    for nextIndex = index + 1, #curve do
        local nextMin = minPercentForIndex(curve, nextIndex)
        if (curve[nextIndex].percent or 0) < nextMin then
            curve[nextIndex].percent = math.min(100, nextMin)
        end
    end

    return normalizeCurve(curve)
end

local function nextDefaultPercent(curve)
    if #curve == 0 then
        return 0
    end
    local min = minPercentForIndex(curve, #curve + 1)
    if min > 100 then
        return nil
    end
    return math.min(100, min + math.min(24, 100 - min))
end

local function relayoutOptions()
    C_Timer.After(0, function()
        local optionsFields = EXUI:GetModule('options-fields')
        if not optionsFields.fields or not optionsFields.container then
            return
        end
        EXUI.utils.organizeFramesInGrid('fields', optionsFields.fields, 10, optionsFields.container, 10, 10)
        if optionsFields.splitView and optionsFields.splitView.UpdateScroll then
            optionsFields.splitView:UpdateScroll()
        elseif optionsFields.innerTabs and optionsFields.innerTabs.UpdateScroll then
            optionsFields.innerTabs:UpdateScroll()
        elseif optionsFields.tabs and optionsFields.tabs.UpdateScroll then
            optionsFields.tabs:UpdateScroll()
        end
    end)
end

local function destroyRow(row)
    if not row then
        return
    end
    for _, key in ipairs({ 'PercentRange', 'ColorPicker', 'DeleteButton' }) do
        local widget = row[key]
        if widget then
            if widget.SetOnChange then
                widget:SetOnChange(nil)
            end
            widget.onChange = nil
            if widget.Destroy then
                widget:Destroy()
            end
        end
    end
    row:Hide()
    row:SetParent(nil)
end

local function createRow(editor, index)
    local row = CreateFrame('Frame', nil, editor.RowsContainer)
    row:SetHeight(ROW_HEIGHT)

    local bg = row:CreateTexture(nil, 'BACKGROUND', nil, -1)
    bg:SetTexture(EXFrames.assets.textures.input.buttonBg)
    bg:SetTextureSliceMargins(10, 10, 10, 10)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetVertexColor(0.16, 0.16, 0.16, 1)
    bg:SetAllPoints()
    row.bg = bg

    row.PercentRange = EXFrames:GetFrame('range-input'):Create()
    row.PercentRange:SetParent(row)
    row.PercentRange:SetPoint('LEFT', row, 'LEFT', 6, 0)
    row.PercentRange:SetPoint('TOP', row, 'TOP', 0, -6)
    row.PercentRange:SetFrameLevel(row:GetFrameLevel() + 2)

    row.ColorPicker = EXFrames:GetFrame('color-picker'):Create()
    row.ColorPicker:SetParent(row)
    row.ColorPicker:SetPoint('BOTTOMLEFT', row.PercentRange, 'BOTTOMRIGHT', 10, 0)
    row.ColorPicker:SetFrameLevel(row:GetFrameLevel() + 2)

    row.index = index

    row.DeleteButton = EXFrames:GetFrame('button'):Create({
        size = { DELETE_BUTTON_SIZE, DELETE_BUTTON_SIZE },
        color = EXUI.const.theme.faded,
        hoverColor = EXUI.const.theme.dangerHover,
        icon = {
            texture = EXUI.const.textures.frame.icons.delete,
            width = 14,
            height = 14,
        },
        onClick = function()
            editor:RemovePoint(row.index)
        end,
    }, row)
    row.DeleteButton:SetPoint('RIGHT', row, 'RIGHT', -4, 0)
    row.DeleteButton:SetFrameLevel(row:GetFrameLevel() + 2)

    return row
end

local function updateRow(editor, row, index, point, curve)
    local function commitCurve(nextCurve)
        nextCurve = normalizeCurve(nextCurve)
        if editor.optionData.onChange then
            editor.optionData.onChange(nextCurve)
        end
        editor:Refresh()
    end

    row.index = index

    row.PercentRange:SetOnChange(nil)
    row.PercentRange:SetOptionData({
        label = 'Min %',
        min = minPercentForIndex(curve, index),
        max = maxPercentForIndex(curve, index),
        step = 1,
        width = 60,
        currentValue = function()
            return point.percent or 0
        end,
    })
    row.PercentRange:SetOnChange(function(value)
        if row.index ~= index then
            return
        end
        local nextCurve = cloneCurve(editor.optionData.currentValue and editor.optionData.currentValue() or {})
        if not nextCurve[index] then
            return
        end
        applyPercentChange(nextCurve, index, value)
        commitCurve(nextCurve)
    end)

    row.ColorPicker.onChange = nil
    row.ColorPicker:SetOptionData({
        label = 'Color',
        width = 16,
        currentValue = function()
            return point.color or { r = 1, g = 1, b = 1, a = 1 }
        end,
        onChange = function(value)
            if row.index ~= index then
                return
            end
            local nextCurve = cloneCurve(editor.optionData.currentValue and editor.optionData.currentValue() or {})
            if not nextCurve[index] then
                return
            end
            nextCurve[index].color = value
            point.color = value
            -- Persist + live-preview the bar, but do not rebuild rows (that closes the picker).
            if editor.optionData.onChange then
                editor.optionData.onChange(normalizeCurve(nextCurve))
            end
        end,
    })
end

local function layoutRow(row, width)
    row:SetWidth(width)

    local deleteW = DELETE_BUTTON_SIZE + 4
    local colorW = 80
    local gaps = 20
    local rangeW = math.max(140, width - colorW - deleteW - gaps)

    row.PercentRange:SetFrameWidth(rangeW)
    row.ColorPicker:SetFrameWidth(colorW)
    row.DeleteButton:SetFrameWidth(DELETE_BUTTON_SIZE)
end

local function configureEditor(editor)
    editor.rows = {}

    editor.Description = editor:CreateFontString(nil, 'OVERLAY')
    editor.Description:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')
    editor.Description:SetPoint('TOPLEFT', editor, 'TOPLEFT', PADDING, -PADDING)
    editor.Description:SetPoint('TOPRIGHT', editor, 'TOPRIGHT', -PADDING, -PADDING)
    editor.Description:SetJustifyH('LEFT')
    editor.Description:SetText(
        'Each breakpoint is the minimum percent where its color starts. Below the first breakpoint uses the bar color.')

    editor.RowsContainer = CreateFrame('Frame', nil, editor)
    editor.RowsContainer:SetPoint('TOPLEFT', editor, 'TOPLEFT', PADDING, -28)
    editor.RowsContainer:SetPoint('TOPRIGHT', editor, 'TOPRIGHT', -PADDING, -28)

    editor.AddButton = EXFrames:GetFrame('button'):Create({
        text = 'Add Breakpoint',
        size = { 140, ADD_BUTTON_HEIGHT },
        color = { 30 / 255, 120 / 255, 0, 1 },
        onClick = function()
            editor:AddPoint()
        end,
    }, editor)
    editor.AddButton:SetPoint('TOPLEFT', editor.RowsContainer, 'BOTTOMLEFT', 0, -ROW_GAP)

    editor.RemovePoint = function(self, index)
        local curve = cloneCurve(self.optionData.currentValue and self.optionData.currentValue() or {})
        if #curve <= 1 then
            return
        end
        table.remove(curve, index)
        if self.optionData.onChange then
            self.optionData.onChange(normalizeCurve(curve))
        end
        self:Refresh()
        relayoutOptions()
    end

    editor.AddPoint = function(self)
        local curve = normalizeCurve(cloneCurve(self.optionData.currentValue and self.optionData.currentValue() or {}))
        local percent = nextDefaultPercent(curve)
        if not percent then
            return
        end
        table.insert(curve, defaultPoint(percent))
        normalizeCurve(curve)
        if self.optionData.onChange then
            self.optionData.onChange(curve)
        end
        self:Refresh()
        relayoutOptions()
    end

    editor.ClearRows = function(self)
        for _, row in ipairs(self.rows) do
            destroyRow(row)
        end
        wipe(self.rows)
    end

    editor.UpdateHeight = function(self)
        local rowsHeight = #self.rows * (ROW_HEIGHT + ROW_GAP)
        if #self.rows > 0 then
            rowsHeight = rowsHeight - ROW_GAP
        end
        local height = 28 + rowsHeight + ROW_GAP + ADD_BUTTON_HEIGHT + PADDING
        self:SetHeight(height)
        self.RowsContainer:SetHeight(rowsHeight)
    end

    editor.LayoutRows = function(self)
        local width = (self.RowsContainer and self.RowsContainer:GetWidth()) or self:GetWidth() or 0
        if width <= 0 then
            width = self:GetWidth() or 0
        end
        for _, row in ipairs(self.rows) do
            layoutRow(row, width)
        end
    end

    editor.Refresh = function(self)
        self:ClearRows()

        local curve = normalizeCurve(cloneCurve(self.optionData and self.optionData.currentValue and
            self.optionData.currentValue() or {}))
        local prev = nil
        for index, point in ipairs(curve) do
            local row = createRow(self, index)
            if prev then
                row:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -ROW_GAP)
                row:SetPoint('TOPRIGHT', prev, 'BOTTOMRIGHT', 0, -ROW_GAP)
            else
                row:SetPoint('TOPLEFT', self.RowsContainer, 'TOPLEFT', 0, 0)
                row:SetPoint('TOPRIGHT', self.RowsContainer, 'TOPRIGHT', 0, 0)
            end
            updateRow(self, row, index, point, curve)
            table.insert(self.rows, row)
            prev = row
        end

        self:UpdateHeight()
        self:LayoutRows()
    end

    editor.SetOptionData = function(self, option)
        self.optionData = option
        self:Refresh()
    end

    editor.SetFrameWidth = function(self, width)
        self:SetWidth(width)
        if self.RowsContainer then
            self.RowsContainer:SetWidth(math.max(1, width - PADDING * 2))
        end
        self:LayoutRows()
    end

    editor.GetState = function(self)
        return self.optionData and self.optionData.currentValue and self.optionData.currentValue()
    end

    editor.SetState = function(self)
        self:Refresh()
    end

    editor.configured = true
end

curveEditor.Init = function(self)
    self.pool = CreateFramePool('Frame', UIParent)
end

curveEditor.Create = function(self)
    local editor = self.pool:Acquire()
    if not editor.configured then
        configureEditor(editor)
    end

    editor.Destroy = function(self)
        self:ClearRows()
        curveEditor.pool:Release(self)
    end

    editor:Show()
    return editor
end
