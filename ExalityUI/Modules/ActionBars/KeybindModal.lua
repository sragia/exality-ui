---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIActionBarsKeybind
local keybind = EXUI:GetModule('action-bars-keybind')

local DIALOG_WIDTH = 480
local SECTION_GAP = 10
local CHECKBOX_HEIGHT = 20

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

keybind.LayoutModalBody = function(self)
    local dialog = self.modal
    local checkbox = self.characterCheckbox
    local status = self.statusText
    if not dialog or not checkbox or not status then
        return
    end
    local width = dialog:GetContentWidth()
    status:SetWidth(width)
    checkbox:ClearAllPoints()
    checkbox:SetFrameWidth(width)
    local hasStatus = status:GetText() and status:GetText() ~= ''
    local height = CHECKBOX_HEIGHT
    if hasStatus then
        status:Show()
        status:ClearAllPoints()
        status:SetPoint('TOPLEFT', dialog.content, 'TOPLEFT', 0, 0)
        status:SetPoint('TOPRIGHT', dialog.content, 'TOPRIGHT', 0, 0)
        local statusHeight = status:GetStringHeight()
        if not statusHeight or statusHeight < 1 then
            statusHeight = 14
        end
        checkbox:SetPoint('TOPLEFT', status, 'BOTTOMLEFT', 0, -SECTION_GAP)
        height = statusHeight + SECTION_GAP + CHECKBOX_HEIGHT
    else
        status:Hide()
        checkbox:SetPoint('TOPLEFT', dialog.content, 'TOPLEFT', 0, 0)
    end
    dialog:SetContentHeight(height)
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
    local checkboxFrame = EXFrames:GetFrame('checkbox')

    local description = QUICK_KEYBIND_DESCRIPTION or ''
    local cancelDescription = QUICK_KEYBIND_CANCEL_DESCRIPTION or ''
    local body = description
    if cancelDescription ~= '' then
        if body ~= '' then
            body = body .. '\n\n' .. cancelDescription
        else
            body = cancelDescription
        end
    end

    local window = EXFrames:GetFrame('dialog-frame'):Create()
    window:SetWidth(DIALOG_WIDTH)
    window:ClearAllPoints()
    window:SetPoint('CENTER', UIParent, 'CENTER', 0, 120)
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
    window:SetTitle(QUICK_KEYBIND_MODE or 'Quick Keybind Mode')
    window:SetText(body)
    window:ShowClose(function()
        if keybind.usingCustomModal and QuickKeybindFrame and QuickKeybindFrame:IsShown() then
            keybind:CancelSession()
        end
    end)

    local status = window.content:CreateFontString(nil, 'OVERLAY')
    status:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    status:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    status:SetJustifyH('LEFT')
    status:SetWordWrap(true)
    status:SetText('')
    status:Hide()
    self.statusText = status

    local checkbox = checkboxFrame:Create()
    checkbox:SetParent(window.content)
    checkbox:SetLabel(CHARACTER_SPECIFIC_KEYBINDINGS or 'Character Specific Keybindings')
    checkbox.Label:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
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

    window:SetButtons({
        {
            text = OKAY,
            borderColor = theme.success,
            hoverBorderColor = theme.success,
            onClick = function()
                keybind:CommitSession()
            end,
        },
        {
            text = RESET_TO_DEFAULT,
            borderColor = theme.border,
            hoverBorderColor = theme.accent,
            onClick = function()
                StaticPopup_Show('CONFIRM_RESET_TO_DEFAULT_KEYBINDINGS')
            end,
        },
        {
            text = CANCEL,
            borderColor = theme.danger,
            hoverBorderColor = theme.dangerHover,
            onClick = function()
                keybind:CancelSession()
            end,
        },
    })

    self.modal = window
    self:HookModalEvents()
    return window
end

keybind.ShowModal = function(self)
    local window = self:EnsureModal()
    local isCharacterSet = GetCurrentBindingSet() == Enum.BindingSet.Character
    self:SetCharacterCheckbox(isCharacterSet)
    self:ClearModalStatus()
    window:ShowDialog()
    window:EnableKeyboard(true)
    window:Raise()
end

keybind.HideModal = function(self)
    local window = self.modal
    if not window or not window:IsShown() then
        return
    end
    window:HideDialog()
end
