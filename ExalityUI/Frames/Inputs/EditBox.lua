---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIEditBoxInput
local editBox = EXUI:GetModule('edit-box-input')

editBox.pool = {}

editBox.Init = function(self)
    self.pool = CreateFramePool('Frame', UIParent)
end

local function ConfigureFrame(f, options)
    EXUI.utils.addObserver(f)
    f.onChange = options.onChange
    local input = CreateFrame('EditBox', nil, f)
    f.editBox = input
    input:SetAutoFocus(false)
    input:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    input:SetPoint('TOPLEFT', 0, -12)
    input:SetPoint('BOTTOMRIGHT')
    input:SetTextInsets(10, 10, 0, 0)
    local bgTex = input:CreateTexture(nil, 'BACKGROUND')
    bgTex:SetTexture(EXUI.const.textures.frame.inputs.editboxBg)
    bgTex:SetVertexColor(0.25, 0.25, 0.25, 0.6)
    bgTex:SetTexCoord(6 / 512, 506 / 512, 5 / 64, 58 / 64)
    bgTex:SetAllPoints()

    f.SetInputValue = function(self, value)
        self:SetValue('inputValue', value)
        if (f.onChange) then
            f:onChange(value)
        end
    end

    input:SetScript('OnTextChanged', function(editbox, changed)
        if (changed) then
            f:SetInputValue(editbox:GetText())
        end
    end)

    input:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)

    local label = f:CreateFontString(nil, 'OVERLAY')
    label:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    label:SetPoint('BOTTOMLEFT', input, 'TOPLEFT', 0, 2)
    label:SetWidth(0)
    f.label = label

    f.SetLabel = function(self, text)
        self.label:SetText(text)
    end

    f.SetEditorValue = function(self, value)
        input:SetText(value)
    end

    f.GetEditorValue = function(self)
        return input:GetText()
    end

    local hoverContainer = CreateFrame('Frame', nil, input)
    hoverContainer:SetAllPoints()
    local hoverBorder = hoverContainer:CreateTexture()
    hoverBorder:SetTexture(EXUI.const.textures.frame.inputs.editboxHover)
    hoverBorder:SetTexCoord(6 / 512, 506 / 512, 5 / 64, 58 / 64)
    hoverBorder:SetVertexColor(1, 1, 1, 1)
    hoverBorder:SetAllPoints()
    hoverContainer:SetAlpha(0.1)

    local onHover = EXUI.utils.animation.fade(hoverContainer, 0.15, 0.1, 1)
    local onLeave = EXUI.utils.animation.fade(hoverContainer, 0.15, 1, 0.1)

    input:SetScript('OnEnter', function(self)
        onHover:Play()
    end)

    input:SetScript('OnLeave', function(self)
        if (not self:HasFocus()) then
            onLeave:Play()
        end
    end)

    input:SetScript('OnEditFocusLost', function(self)
        if (not self:IsMouseOver()) then
            onLeave:Play()
        end
        if (self.onFocusLost) then
            self.onFocusLost(self:GetText())
        end
    end)
    hoverContainer:Show()

    f.SetOptionData = function(self, option)
        self.optionData = option
        self:SetLabel(option.label)
        self:SetEditorValue(option.currentValue and option.currentValue() or '')
        self.onChange = option.onChange
    end

    f.SetMultiLine = function(self)
        input:SetMultiLine(true)  
    end

    f.SetFrameWidth = function(self, width)
        self:SetWidth(width)
    end

    f.configured = true
end

---comment
---@param self EXUIEditBoxInput
---@param options any
editBox.Create = function(self, options, parent)
    local f = self.pool:Acquire()
    if (not f.configured) then
        ConfigureFrame(f, options)
    end

    if (options.label) then
        f:SetLabel(options.label)
    end

    if (parent) then
        f:SetParent(parent)
    end

    if (options.initial) then
        f:SetEditorValue(options.initial)
    end

    if (options.onFocusLost) then
        f.editBox.onFocusLost = options.onFocusLost
    end

    f.Destroy = function(self)
        editBox.pool:Release(self)
    end

    f:Show()
    return f
end
