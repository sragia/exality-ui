---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---------

---@class EXUICopyLinkDialog
local copyLinkDialog = EXUI:GetModule('copy-link-dialog')

copyLinkDialog.window = nil
copyLinkDialog.editBox = nil

copyLinkDialog.Init = function(self)
    local window = EXFrames:GetFrame('window-frame'):Create({
        size = { 440, 130 },
        title = 'Copy link',
        disableLogoAndVersion = true,
    })

    local hint = window.container:CreateFontString(nil, 'OVERLAY')
    hint:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    hint:SetTextColor(0.85, 0.85, 0.85, 1)
    hint:SetJustifyH('LEFT')
    hint:SetText('Select the link below and press Ctrl+C to copy.')
    hint:SetPoint('TOPLEFT', window.container, 'TOPLEFT', 10, -10)
    hint:SetPoint('TOPRIGHT', window.container, 'TOPRIGHT', -10, -10)

    local editBox = CreateFrame('EditBox', nil, window.container, 'BackdropTemplate')
    editBox:SetAutoFocus(false)
    editBox:SetBackdrop(EXUI.const.backdrop.DEFAULT)
    editBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    editBox:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    editBox:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    editBox:SetTextInsets(8, 8, 6, 6)
    editBox:SetHeight(28)
    editBox:SetPoint('TOPLEFT', hint, 'BOTTOMLEFT', 0, -8)
    editBox:SetPoint('TOPRIGHT', hint, 'BOTTOMRIGHT', 0, -8)
    editBox:SetScript('OnEscapePressed', function(box)
        box:ClearFocus()
        window:HideWindow()
    end)

    self.window = window
    self.editBox = editBox
end

---@param url string
---@param title string|nil
copyLinkDialog.Show = function(self, url, title)
    if not self.window then
        return
    end
    self.window:SetTitle(title or 'Copy link')
    self.editBox:SetText(url or '')
    self.window:ShowWindow()
    C_Timer.After(0, function()
        if self.editBox and self.window and self.window:IsShown() then
            self.editBox:SetFocus()
            self.editBox:HighlightText()
        end
    end)
end
