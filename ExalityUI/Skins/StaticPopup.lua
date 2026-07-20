---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIStaticPopupSkin
local staticPopupSkin = EXUI:GetModule('skin-StaticPopup')

local FONT_PATH = EXUI.const.fonts.DEFAULT
local TEXT_SIZE = 12
local SUBTEXT_SIZE = 12
local BUTTON_FONT_SIZE = 12
local DIALOG_BG_ALPHA = 0.9
local STATIC_POPUP_COUNT = 4

local function GetTheme()
    return EXUI.const.theme
end

local function StyleDialogText(fontString, fontSize, color)
    if (not fontString) then return end
    fontString:SetFont(FONT_PATH, fontSize, 'OUTLINE')
    fontString:SetTextColor(unpack(color))
end

local function HideDialogBackground(dialog)
    local bg = dialog.BG
    if (not bg) then return end
    skins:StripTexture(bg.Top)
    skins:StripTexture(bg.Bottom)
end

function staticPopupSkin:SkinButtons(dialog)
    if (not dialog) then return end

    if (dialog.GetButtons) then
        for _, button in ipairs(dialog:GetButtons()) do
            skins:SkinDialogButton(button, { fontSize = BUTTON_FONT_SIZE })
        end
    end

    if (dialog.ExtraButton) then
        skins:SkinDialogButton(dialog.ExtraButton, { fontSize = BUTTON_FONT_SIZE })
    end
end

function staticPopupSkin:RefreshDialog(dialog)
    if (not dialog) then return end

    local th = GetTheme()
    HideDialogBackground(dialog)
    StyleDialogText(dialog.Text, TEXT_SIZE, th.text)
    StyleDialogText(dialog.SubText, SUBTEXT_SIZE, th.textMuted)
    self:SkinButtons(dialog)
end

function staticPopupSkin:SkinDialog(dialog)
    if (not dialog or dialog.exuiSkinned) then return end
    dialog.exuiSkinned = true

    local th = GetTheme()
    HideDialogBackground(dialog)
    skins:AddBackdrop(dialog, { color = th.backgroundDeep, alpha = DIALOG_BG_ALPHA })
    skins:AddBorder(dialog)

    if (dialog.CloseButton) then
        skins:SkinCloseButton(dialog.CloseButton)
    end

    self:RefreshDialog(dialog)

    if (not dialog.exuiShowHooked) then
        dialog.exuiShowHooked = true
        dialog:HookScript('OnShow', function(frame)
            staticPopupSkin:RefreshDialog(frame)
        end)
    end
end

function staticPopupSkin:SkinAllDialogs()
    for i = 1, STATIC_POPUP_COUNT do
        local dialog = _G['StaticPopup' .. i]
        if (dialog) then
            self:SkinDialog(dialog)
        end
    end
end

function staticPopupSkin:InstallHooks()
    if (self.hooksInstalled) then return end
    self.hooksInstalled = true

    if (GameDialogMixin and GameDialogMixin.Init) then
        hooksecurefunc(GameDialogMixin, 'Init', function(dialog)
            staticPopupSkin:SkinDialog(dialog)
            staticPopupSkin:RefreshDialog(dialog)
        end)
    end
end

function staticPopupSkin:Install()
    if (self.installed or not StaticPopup1) then return end
    self.installed = true

    self:InstallHooks()
    self:SkinAllDialogs()
end

staticPopupSkin.Init = function(self)
    if (not skins:IsEnabled('StaticPopup')) then return end

    if (StaticPopup1) then
        self:Install()
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-StaticPopup', function(_, addon)
        if (addon ~= 'Blizzard_StaticPopup_Game') then return end
        self:Install()
    end)
end
