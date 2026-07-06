---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsKeybind
local keybind = EXUI:GetModule('action-bars-keybind')

keybind.buttons = {}
keybind.hooked = false

keybind.RegisterButton = function(self, button)
    if not button or self.buttons[button] then return end
    self.buttons[button] = true
    self:EnsureQuickKeybindTexture(button)
end

keybind.EnsureQuickKeybindTexture = function(self, button)
    if button.QuickKeybindHighlightTexture then return end
    local tex = button:CreateTexture(nil, 'OVERLAY')
    tex:SetAtlas('UI-HUD-ActionBar-IconFrame-Mouseover')
    if tex.SetBlendMode then
        tex:SetBlendMode('ADD')
    end
    tex:SetAlpha(0)
    tex:SetAllPoints()
    button.QuickKeybindHighlightTexture = tex

    if QuickKeybindButtonTemplateMixin then
        button.QuickKeybindButtonOnEnter = QuickKeybindButtonTemplateMixin.QuickKeybindButtonOnEnter
        button.QuickKeybindButtonOnLeave = QuickKeybindButtonTemplateMixin.QuickKeybindButtonOnLeave
        button.QuickKeybindButtonOnClick = QuickKeybindButtonTemplateMixin.QuickKeybindButtonOnClick
        button.QuickKeybindButtonSetTooltip = QuickKeybindButtonTemplateMixin.QuickKeybindButtonSetTooltip
        button.DoModeChange = QuickKeybindButtonTemplateMixin.DoModeChange
        button.UpdateMouseWheelHandler = QuickKeybindButtonTemplateMixin.UpdateMouseWheelHandler
    end

    button:HookScript('OnEnter', function(self)
        if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then
            if self.QuickKeybindButtonOnEnter then
                self:QuickKeybindButtonOnEnter()
            end
        end
    end)
    button:HookScript('OnLeave', function(self)
        if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then
            if self.QuickKeybindButtonOnLeave then
                self:QuickKeybindButtonOnLeave()
            end
        end
    end)
    button:HookScript('OnClick', function(self, clickButton)
        if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then
            if self.QuickKeybindButtonOnClick then
                self:QuickKeybindButtonOnClick(clickButton)
            end
        end
    end)
end

keybind.SetAllHighlights = function(self, show)
    for button in pairs(self.buttons) do
        if button.QuickKeybindHighlightTexture then
            if show then
                button.QuickKeybindHighlightTexture:Show()
                button.QuickKeybindHighlightTexture:SetAlpha(0.5)
            else
                button.QuickKeybindHighlightTexture:Hide()
            end
        end
        if button.DoModeChange then
            button:DoModeChange(show)
        end
    end
end

keybind.HookActionButtonUtil = function(self)
    if self.hooked or not ActionButtonUtil then return end
    self.hooked = true

    ActionButtonUtil.SetAllQuickKeybindButtonHighlights = function(show)
        keybind:SetAllHighlights(show)
        if ActionButtonUtil._EXUIOriginalSetHighlights then
            -- no-op: blizzard bars are hidden
        end
    end
end

keybind.EnterQuickKeybindMode = function(self)
    self:HookActionButtonUtil()
    if KeybindFrames_ToggleQuickKeybindMode then
        KeybindFrames_ToggleQuickKeybindMode()
    elseif QuickKeybindFrame then
        QuickKeybindFrame:Show()
    end
end

keybind.Init = function(self)
    self:HookActionButtonUtil()
end

keybind.Clear = function(self)
    wipe(self.buttons)
end
