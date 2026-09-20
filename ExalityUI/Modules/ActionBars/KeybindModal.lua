---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIActionBarsKeybind
local keybind = EXUI:GetModule('action-bars-keybind')

local WINDOW_SIZE = { 440, 196 }
local BUTTON_HEIGHT = 28
local TEXT_GAP = 6
local CHECKBOX_GAP = 8
local BUTTON_ROW_GAP = 10

local function bindingSetAdapter(checkbox)
    return {
        GetChecked = function()
            return checkbox.value and true or false
        end,
        SetChecked = function(_, checked)
            keybind:SetCharacterCheckbox(checked)
        end,
    }
end

keybind.SetCharacterCheckbox = function(self, checked)
    local checkbox = self.characterCheckbox
    if not checkbox then
        return
    end
    checkbox.suppressOnChange = true
    checkbox:SetValue('value', checked and true or false)
    checkbox.suppressOnChange = false
end

keybind.LayoutModalButtonRow = function(self)
    local checkbox = self.characterCheckbox
    local buttonRow = self.modalButtonRow
    local container = self.modal and self.modal.container
    if not checkbox or not buttonRow or not container then
        return
    end
    buttonRow:ClearAllPoints()
    buttonRow:SetPoint('TOP', checkbox, 'BOTTOM', 0, -BUTTON_ROW_GAP)
    buttonRow:SetPoint('LEFT', container, 'LEFT', 0, 0)
    buttonRow:SetPoint('RIGHT', container, 'RIGHT', 0, 0)
    buttonRow:SetHeight(BUTTON_HEIGHT)
end

keybind.RefreshModalButtonBorders = function(self)
    for _, btn in ipairs(self.modalButtons or {}) do
        if btn.PPBorder then
            btn.PPBorder:SetBorderThickness(btn.PPBorder.thicknessPixels or 1)
        end
    end
end

keybind.LayoutModalBody = function(self)
    local checkbox = self.characterCheckbox
    local status = self.statusText
    local cancelText = self.modalCancelText
    if not checkbox or not status or not cancelText then
        return
    end
    checkbox:ClearAllPoints()
    local hasStatus = status:GetText() and status:GetText() ~= ''
    if hasStatus then
        status:Show()
        status:SetHeight(14)
        checkbox:SetPoint('TOPLEFT', status, 'BOTTOMLEFT', 0, -TEXT_GAP)
    else
        status:Hide()
        status:SetHeight(0)
        checkbox:SetPoint('TOPLEFT', cancelText, 'BOTTOMLEFT', 0, -CHECKBOX_GAP)
    end
    self:LayoutModalButtonRow()
end

keybind.SetModalStatus = function(self, text, color)
    if not self.statusText then
        return
    end
    self.statusText:SetText(text or '')
    if color then
        self.statusText:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    else
        local theme = EXUI.const.theme
        self.statusText:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    end
    self:LayoutModalBody()
end

keybind.ClearModalStatus = function(self)
    self:SetModalStatus('')
end

keybind.ForwardModalKey = function(self, input)
    if QuickKeybindFrame and QuickKeybindFrame.OnKeyDown then
        QuickKeybindFrame:OnKeyDown(input)
    end
end

keybind.ForwardModalMouseWheel = function(self, delta)
    if QuickKeybindFrame and QuickKeybindFrame.OnMouseWheel then
        QuickKeybindFrame:OnMouseWheel(delta)
    end
end

keybind.HookModalEvents = function(self)
    if self.modalEventsHooked or not EventRegistry then
        return
    end
    self.modalEventsHooked = true

    EventRegistry:RegisterCallback('KeybindListener.UnbindFailed', function(_, action, unbindAction, unbindSlotIndex)
        local errorFormat = unbindSlotIndex == 1 and PRIMARY_KEY_UNBOUND_ERROR or KEY_UNBOUND_ERROR
        self:SetModalStatus(errorFormat:format(GetBindingName(unbindAction)), EXUI.const.theme.danger)
    end, self)

    EventRegistry:RegisterCallback('KeybindListener.RebindFailed', function()
        self:SetModalStatus(KEYBINDINGFRAME_MOUSEWHEEL_ERROR, EXUI.const.theme.danger)
    end, self)

    EventRegistry:RegisterCallback('KeybindListener.RebindSuccess', function()
        self:SetModalStatus(KEY_BOUND, EXUI.const.theme.success)
    end, self)

    if Settings and Settings.SetOnValueChangedCallback then
        Settings.SetOnValueChangedCallback('PROXY_CHARACTER_SPECIFIC_BINDINGS', function(_, setting, value)
            self:SetCharacterCheckbox(value)
        end, self)
    end
end

keybind.EnsureModal = function(self)
    if self.modal then
        return self.modal
    end

    local theme = EXUI.const.theme
    local simpleButton = EXFrames:GetFrame('simple-button')
    local checkboxFrame = EXFrames:GetFrame('checkbox')

    local window = EXFrames:GetFrame('window-frame'):Create({
        size = WINDOW_SIZE,
        title = QUICK_KEYBIND_MODE or 'Quick Keybind Mode',
        legacyChrome = true,
        disableResize = true,
        staticAnchor = { 'CENTER', UIParent, 'CENTER', 0, 120 },
        onClose = function()
            if keybind.usingCustomModal and QuickKeybindFrame and QuickKeybindFrame:IsShown() then
                keybind:CancelSession()
            end
        end,
    })
    window:SetFrameStrata('DIALOG')
    window:SetFrameLevel(200)
    window:EnableKeyboard(true)
    window:EnableMouseWheel(true)
    window:SetScript('OnKeyDown', function(frame, input)
        if not InCombatLockdown() then
            frame:SetPropagateKeyboardInput(false)
        end
        keybind:ForwardModalKey(input)
    end)
    window:SetScript('OnGamePadButtonDown', function(frame, input)
        if not InCombatLockdown() then
            frame:SetPropagateKeyboardInput(false)
        end
        keybind:ForwardModalKey(input)
    end)
    window:SetScript('OnMouseWheel', function(_, delta)
        keybind:ForwardModalMouseWheel(delta)
    end)

    local container = window.container

    local instruction = container:CreateFontString(nil, 'OVERLAY')
    instruction:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    instruction:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    instruction:SetJustifyH('LEFT')
    instruction:SetJustifyV('TOP')
    instruction:SetWordWrap(true)
    instruction:SetPoint('TOPLEFT', 0, 0)
    instruction:SetPoint('TOPRIGHT', 0, 0)
    instruction:SetHeight(32)
    instruction:SetText(QUICK_KEYBIND_DESCRIPTION or '')

    local cancelText = container:CreateFontString(nil, 'OVERLAY')
    self.modalCancelText = cancelText
    cancelText:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    cancelText:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    cancelText:SetJustifyH('LEFT')
    cancelText:SetJustifyV('TOP')
    cancelText:SetWordWrap(true)
    cancelText:SetPoint('TOPLEFT', instruction, 'BOTTOMLEFT', 0, -TEXT_GAP)
    cancelText:SetPoint('TOPRIGHT', instruction, 'BOTTOMRIGHT', 0, -TEXT_GAP)
    cancelText:SetHeight(18)
    cancelText:SetText(QUICK_KEYBIND_CANCEL_DESCRIPTION or '')

    local status = container:CreateFontString(nil, 'OVERLAY')
    status:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    status:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    status:SetJustifyH('LEFT')
    status:SetPoint('TOPLEFT', cancelText, 'BOTTOMLEFT', 0, -TEXT_GAP)
    status:SetPoint('TOPRIGHT', cancelText, 'BOTTOMRIGHT', 0, -TEXT_GAP)
    status:SetHeight(0)
    status:Hide()
    status:SetText('')
    self.statusText = status

    local checkbox = checkboxFrame:Create()
    checkbox:SetParent(container)
    checkbox:SetPoint('TOPLEFT', cancelText, 'BOTTOMLEFT', 0, -CHECKBOX_GAP)
    checkbox:SetLabel(CHARACTER_SPECIFIC_KEYBINDINGS or 'Character Specific Keybindings')
    checkbox.Label:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    checkbox.Label:SetTextColor(unpack(theme.text))
    checkbox.onChange = function()
        if checkbox.suppressOnChange then
            return
        end
        if Settings and Settings.TryChangeBindingSet then
            Settings.TryChangeBindingSet(bindingSetAdapter(checkbox))
        end
    end
    self.characterCheckbox = checkbox

    local buttonRow = CreateFrame('Frame', nil, container)
    buttonRow:SetHeight(BUTTON_HEIGHT)
    self.modalButtonRow = buttonRow

    local okay = simpleButton:Create(buttonRow)
    okay:SetOptionData({
        label = OKAY,
        borderColor = theme.success,
        hoverBorderColor = theme.success,
        onClick = function()
            keybind:CommitSession()
        end,
    })
    okay:SetSize(100, BUTTON_HEIGHT)
    okay:SetPoint('LEFT', buttonRow, 'LEFT', 0, 0)
    okay:SetPoint('TOP', buttonRow, 'TOP', 0, 0)
    okay:SetPoint('BOTTOM', buttonRow, 'BOTTOM', 0, 0)

    local reset = simpleButton:Create(buttonRow)
    reset:SetOptionData({
        label = RESET_TO_DEFAULT,
        borderColor = theme.border,
        hoverBorderColor = theme.accent,
        onClick = function()
            StaticPopup_Show('CONFIRM_RESET_TO_DEFAULT_KEYBINDINGS')
        end,
    })
    reset:SetSize(160, BUTTON_HEIGHT)
    reset:SetPoint('CENTER', buttonRow, 'CENTER', 0, 0)
    reset:SetPoint('TOP', buttonRow, 'TOP', 0, 0)
    reset:SetPoint('BOTTOM', buttonRow, 'BOTTOM', 0, 0)

    local cancel = simpleButton:Create(buttonRow)
    cancel:SetOptionData({
        label = CANCEL,
        borderColor = theme.danger,
        hoverBorderColor = theme.dangerHover,
        onClick = function()
            keybind:CancelSession()
        end,
    })
    cancel:SetSize(100, BUTTON_HEIGHT)
    cancel:SetPoint('RIGHT', buttonRow, 'RIGHT', 0, 0)
    cancel:SetPoint('TOP', buttonRow, 'TOP', 0, 0)
    cancel:SetPoint('BOTTOM', buttonRow, 'BOTTOM', 0, 0)

    self.modalButtons = { okay, reset, cancel }

    if window.logo then
        window.logo:Show()
    end

    self.modal = window
    self:HookModalEvents()
    return window
end

keybind.ShowModal = function(self)
    local window = self:EnsureModal()
    window:SetSize(WINDOW_SIZE[1], WINDOW_SIZE[2])
    if window.ApplyChromeLayout then
        window:ApplyChromeLayout()
    end
    if window.logo then
        window.logo:Show()
        if window.UpdateTitleAnchor then
            window:UpdateTitleAnchor()
        end
    end
    if self.characterCheckbox and window.container then
        self.characterCheckbox:SetFrameWidth(math.max(1, window.container:GetWidth()))
    end
    local isCharacterSet = GetCurrentBindingSet() == Enum.BindingSet.Character
    self:SetCharacterCheckbox(isCharacterSet)
    self:ClearModalStatus()
    self:LayoutModalBody()
    self:RefreshModalButtonBorders()
    if EXFrames.RefreshPixelPerfect then
        EXFrames:RefreshPixelPerfect()
    end
    window:ShowWindow()
    window:EnableKeyboard(true)
    window:Raise()
end

keybind.HideModal = function(self)
    local window = self.modal
    if not window or not window:IsShown() then
        return
    end
    local onClose = window.onClose
    window.onClose = nil
    window:HideWindow()
    window.onClose = onClose
end
