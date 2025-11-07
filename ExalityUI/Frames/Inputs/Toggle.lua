---@class ExalityUI
local EXUI = select(2, ...)

---@class ToggleOptions : {text: string, value:boolean, secondaryText: string, onChange: function}

---@class EXUIToggleInput
local toggle = EXUI:GetModule('toggle')

toggle.pool = {}

toggle.Init = function(self)
    self.pool = CreateFramePool('Frame', UIParent)
end

---@param f Frame
---@param options ToggleOptions
local function ConfigureFrame(f, options)
    EXUI.utils.addObserver(f)
    f:SetSize(49, 20)

    local base = f:CreateTexture(nil, 'ARTWORK')
    base:SetTexture(EXUI.const.textures.frame.inputs.toggle)
    base:SetTexCoord(1 / 256, 167 / 256, 181 / 256, 248 / 256)
    base:SetAllPoints()

    local borderDisabled = f:CreateTexture(nil, 'ARTWORK')
    borderDisabled:SetTexture(EXUI.const.textures.frame.inputs.toggle)
    borderDisabled:SetTexCoord(1 / 256, 167 / 256, 90 / 256, 157 / 256)
    borderDisabled:SetAllPoints()

    local borderEnabled = f:CreateTexture(nil, 'ARTWORK')
    borderEnabled:SetTexture(EXUI.const.textures.frame.inputs.toggle)
    borderEnabled:SetTexCoord(1 / 256, 167 / 256, 1 / 256, 68 / 256)
    borderEnabled:SetAllPoints()
    borderEnabled:SetAlpha(0)

    local thumbDisabled = f:CreateTexture(nil, 'OVERLAY')
    thumbDisabled:SetTexture(EXUI.const.textures.frame.inputs.toggle)
    thumbDisabled:SetTexCoord(176 / 256, 255 / 256, 84 / 256, 163 / 256)
    thumbDisabled:SetSize(25, 25)
    thumbDisabled:SetPoint('CENTER', base, 'LEFT', 10, 0)

    local thumbEnabled = f:CreateTexture(nil, 'OVERLAY')
    thumbEnabled:SetTexture(EXUI.const.textures.frame.inputs.toggle)
    thumbEnabled:SetTexCoord(176 / 256, 255 / 256, 1 / 256, 80 / 256)
    thumbEnabled:SetSize(25, 25)
    thumbEnabled:SetPoint('CENTER', base, 'LEFT', 10, 0)
    thumbEnabled:SetAlpha(0)

    local duration = 0.2
    local moveBy = 29

    -- KMS part
    local thumbEnabledEnableGroup = EXUI.utils.animation.getAnimationGroup(thumbEnabled)
    EXUI.utils.animation.fade(thumbEnabled, duration, 0, 1, thumbEnabledEnableGroup)
    EXUI.utils.animation.move(thumbEnabled, duration, moveBy, 0, thumbEnabledEnableGroup)

    local thumbEnabledDisableGroup = EXUI.utils.animation.getAnimationGroup(thumbEnabled)
    EXUI.utils.animation.fade(thumbEnabled, duration, 1, 0, thumbEnabledDisableGroup)
    EXUI.utils.animation.move(thumbEnabled, duration, -moveBy, 0, thumbEnabledDisableGroup)

    local thumbDisabledEnableGroup = EXUI.utils.animation.getAnimationGroup(thumbDisabled)
    EXUI.utils.animation.fade(thumbDisabled, duration, 1, 0, thumbDisabledEnableGroup)
    EXUI.utils.animation.move(thumbDisabled, duration, moveBy, 0, thumbDisabledEnableGroup)

    local thumbDisabledDisableGroup = EXUI.utils.animation.getAnimationGroup(thumbDisabled)
    EXUI.utils.animation.fade(thumbDisabled, duration, 0, 1, thumbDisabledDisableGroup)
    EXUI.utils.animation.move(thumbDisabled, duration, -moveBy, 0, thumbDisabledDisableGroup)

    local borderDisabledDisableGroup = EXUI.utils.animation.getAnimationGroup(borderDisabled)
    EXUI.utils.animation.fade(borderDisabled, duration, 0, 1, borderDisabledDisableGroup)
    local borderDisabledEnableGroup = EXUI.utils.animation.getAnimationGroup(borderDisabled)
    EXUI.utils.animation.fade(borderDisabled, duration, 1, 0, borderDisabledEnableGroup)

    local borderEnabledDisableGroup = EXUI.utils.animation.getAnimationGroup(borderEnabled)
    EXUI.utils.animation.fade(borderEnabled, duration, 1, 0, borderEnabledDisableGroup)
    local borderEnabledEnableGroup = EXUI.utils.animation.getAnimationGroup(borderEnabled)
    EXUI.utils.animation.fade(borderEnabled, duration, 0, 1, borderEnabledEnableGroup)


    f.Enable = function(self)
        self.enabled = true
        thumbEnabledEnableGroup:Play(false, self.disableAnim and duration or 0)
        thumbDisabledEnableGroup:Play(false, self.disableAnim and duration or 0)
        borderDisabledEnableGroup:Play(false, self.disableAnim and duration or 0)
        borderEnabledEnableGroup:Play(false, self.disableAnim and duration or 0)
    end

    f.Disable = function(self)
        self.enabled = false
        thumbEnabledDisableGroup:Play(false, self.disableAnim and duration or 0)
        thumbDisabledDisableGroup:Play(false, self.disableAnim and duration or 0)
        borderDisabledDisableGroup:Play(false, self.disableAnim and duration or 0)
        borderEnabledDisableGroup:Play(false, self.disableAnim and duration or 0)
    end

    f.Toggle = function(self)
        f:SetValue('value', not f.value)
    end

    f:SetScript('OnMouseDown', function(self)
        self:Toggle()
    end)

    local text = f:CreateFontString(nil, 'OVERLAY')
    text:SetWidth(0)
    text:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    text:SetPoint('LEFT', base, 'RIGHT', 10, 0)
    text:SetText(options.text)
    f.label = text

    local secondaryText = f:CreateFontString(nil, 'OVERLAY')
    secondaryText:SetWidth(0)
    secondaryText:SetFont(EXUI.const.fonts.DEFAULT, 8, 'OUTLINE')
    secondaryText:SetPoint('TOPLEFT', text, 'BOTTOMLEFT', 0, -3)
    secondaryText:SetVertexColor(0.8, 0.8, 0.8, 1)
    secondaryText:SetText(options.secondaryText or "")
    f.secondaryText = secondaryText

    f.SetSecondaryText = function(self, text)
        self.label:ClearAllPoints()
        if (not text or text == '') then
            self.label:SetPoint('LEFT', base, 'RIGHT', 10, 0)
            return
        end
        self.label:SetPoint('TOPLEFT', base, 'TOPRIGHT', 10, 0)
        self.secondaryText:SetText(text)
    end

    f.SetOptionData = function(self, option)
        self.optionData = option
        self.label:SetText(option.label)
        if (option.onClick) then
            self.onClick = option.onClick
        end
    end

    f.SetFrameWidth = function(self, width)
       --noop
    end

    f.isConfigured = true
end

---@param self EXUIToggleInput
---@param options ToggleOptions
---@param parent FRAME
---@return FRAME
toggle.Create = function(self, options, parent)
    ---@type FRAME
    local input = self.pool:Acquire()
    input.value = false
    if (not input.isConfigured) then
        ConfigureFrame(input, options)
    end

    if (parent) then
        input:SetParent(parent)
    else
        input:SetParent(nil)
    end

    input.Destroy = function(self)
        self:ClearObservable()
        toggle.pool:Release(self)
    end

    if (options.text) then
        input.label:SetText(options.text)
    end

    if (options.secondaryText) then
        input:SetSecondaryText(options.secondaryText)
    end

    input:Observe('value', function(value, oldValue)
        if (value and not input.enabled) then
            input:Enable()
        elseif (not value and input.enabled) then
            input:Disable();
        end
    end)

    input.disableAnim = true
    input:SetValue('value', options.value)
    input.disableAnim = false

    input:Show()
    return input
end
