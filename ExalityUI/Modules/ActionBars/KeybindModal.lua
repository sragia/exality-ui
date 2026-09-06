---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIActionBarsKeybind
local keybind = EXUI:GetModule('action-bars-keybind')

local WINDOW_SIZE = { 440, 250 }
local BUTTON_HEIGHT = 28

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
    local buttonFrame = EXFrames:GetFrame('button')
    local checkboxFrame = EXFrames:GetFrame('checkbox')

    local window = EXFrames:GetFrame('window-frame'):Create({
        size = WINDOW_SIZE,
        title = QUICK_KEYBIND_MODE or 'Quick Keybind Mode',
        onClose = function()
            if keybind.usingCustomModal and QuickKeybindFrame and QuickKeybindFrame:IsShown() then
                keybind:CancelSession()
            end
        end,
    })
    if window.Configure then
        window:Configure({
            disableResize = true,
            staticAnchor = { 'CENTER', UIParent, 'CENTER', 0, 120 },
        })
    else
        if window.DisableResize then
            window:DisableResize()
        end
        window.StaticAnchor = { 'CENTER', UIParent, 'CENTER', 0, 120 }
    end
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
    instruction:SetPoint('TOPLEFT', 0, -2)
    instruction:SetPoint('TOPRIGHT', 0, -2)
    instruction:SetHeight(48)
    instruction:SetText(QUICK_KEYBIND_DESCRIPTION or '')

    local cancelText = container:CreateFontString(nil, 'OVERLAY')
    cancelText:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    cancelText:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    cancelText:SetJustifyH('LEFT')
    cancelText:SetJustifyV('TOP')
    cancelText:SetWordWrap(true)
    cancelText:SetPoint('TOPLEFT', instruction, 'BOTTOMLEFT', 0, -8)
    cancelText:SetPoint('TOPRIGHT', instruction, 'BOTTOMRIGHT', 0, -8)
    cancelText:SetHeight(32)
    cancelText:SetText(QUICK_KEYBIND_CANCEL_DESCRIPTION or '')

    local status = container:CreateFontString(nil, 'OVERLAY')
    status:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    status:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    status:SetJustifyH('LEFT')
    status:SetPoint('TOPLEFT', cancelText, 'BOTTOMLEFT', 0, -6)
    status:SetPoint('TOPRIGHT', cancelText, 'BOTTOMRIGHT', 0, -6)
    status:SetHeight(16)
    status:SetText('')
    self.statusText = status

    local checkbox = checkboxFrame:Create()
    checkbox:SetParent(container)
    checkbox:SetPoint('TOPLEFT', status, 'BOTTOMLEFT', 0, -10)
    checkbox:SetFrameWidth(400)
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

    local okay = buttonFrame:Create({
        text = OKAY,
        size = { 100, BUTTON_HEIGHT },
        color = theme.success,
        onClick = function()
            keybind:CommitSession()
        end,
    }, container)
    okay:SetPoint('BOTTOMLEFT', container, 'BOTTOMLEFT', 0, 0)
    okay:SetHeight(BUTTON_HEIGHT)

    local reset = buttonFrame:Create({
        text = RESET_TO_DEFAULT,
        size = { 160, BUTTON_HEIGHT },
        color = theme.faded,
        onClick = function()
            StaticPopup_Show('CONFIRM_RESET_TO_DEFAULT_KEYBINDINGS')
        end,
    }, container)
    reset:SetPoint('BOTTOM', container, 'BOTTOM', 0, 0)
    reset:SetHeight(BUTTON_HEIGHT)

    local cancel = buttonFrame:Create({
        text = CANCEL,
        size = { 100, BUTTON_HEIGHT },
        color = theme.danger,
        onClick = function()
            keybind:CancelSession()
        end,
    }, container)
    cancel:SetPoint('BOTTOMRIGHT', container, 'BOTTOMRIGHT', 0, 0)
    cancel:SetHeight(BUTTON_HEIGHT)

    self.modal = window
    self:HookModalEvents()
    return window
end

keybind.ShowModal = function(self)
    local window = self:EnsureModal()
    local isCharacterSet = GetCurrentBindingSet() == Enum.BindingSet.Character
    self:SetCharacterCheckbox(isCharacterSet)
    self:ClearModalStatus()
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
