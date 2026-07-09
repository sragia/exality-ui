---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIProfessionsBookSkin
local professionsBookSkin = EXUI:GetModule('skin-ProfessionsBook')

local TITLE_SIZE = 13
local PANEL_BG_ALPHA = 0.95
local HEADER_HEIGHT = 26

local BOOK_BG_COLOR = { 179 / 255, 179 / 255, 179 / 255, 1 }
local ABILITY_BORDER_COLOR = { 154 / 255, 154 / 255, 154 / 255, 1 }

local PRIMARY_NAME_SIZE = 18
local SECONDARY_NAME_SIZE = 14
local RANK_TEXT_SIZE = 11
local SPELL_NAME_SIZE = 14
local SPELL_SUBTEXT_SIZE = 11
local BODY_TEXT_SIZE = 12

local HEADER_TEXT_COLOR = { 235 / 255, 232 / 255, 228 / 255, 1 }

local PRIMARY_PROFESSION_KEYS = { 'PrimaryProfession1', 'PrimaryProfession2' }
local SECONDARY_PROFESSION_KEYS = { 'SecondaryProfession1', 'SecondaryProfession2', 'SecondaryProfession3' }
local BOOK_PAGE_KEYS = { 'ProfessionsBookPage1', 'ProfessionsBookPage2' }

local STATUS_BAR_BG_KEYS = { 'BGLeft', 'BGRight', 'BGMiddle', 'Left', 'Right', 'capRight' }
local STATUS_BAR_HEIGHT = 18
local STATUS_BAR_WIDTH = 110
local STATUS_BAR_INSET = 1
local PRIMARY_NAME_X = 100
local PRIMARY_NAME_Y = -15
local PRIMARY_RANK_Y = -24
local SECONDARY_NAME_X = 4
local SECONDARY_NAME_Y = 6
local SECONDARY_RANK_Y = -14

local function GetTheme()
    return EXUI.const.theme
end

local function GetStatusBarColors()
    local th = GetTheme()
    return th.backgroundDeep, th.border
end

local function ApplyFontText(fontString, size, color)
    if (not fontString) then return end

    local alpha = fontString:GetAlpha()
    fontString:SetFont(EXUI.const.fonts.DEFAULT, size, 'OUTLINE')
    if (color) then
        fontString:SetTextColor(unpack(color))
    end
    fontString:SetAlpha(alpha)
end

local function ApplyFontOnly(fontString, size)
    ApplyFontText(fontString, size)
end

local function AdjustTitleBarLayout(frame)
    local titleContainer = frame.TitleContainer
    if (titleContainer and not titleContainer.exuiAdjusted) then
        titleContainer.exuiAdjusted = true
        titleContainer:ClearAllPoints()
        titleContainer:SetPoint('TOPLEFT', frame, 'TOPLEFT', 16, -1)
        titleContainer:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -48, -1)
    end
end

local function SkinHeaderBackdrop(frame)
    if (frame.exuiHeaderBackdrop) then return end
    local th = GetTheme()

    local header = CreateFrame('Frame', nil, frame)
    header:EnableMouse(false)
    header:SetFrameLevel(2)
    header:SetPoint('TOPLEFT', frame, 'TOPLEFT', 1, -1)
    header:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -1, -1)
    header:SetHeight(HEADER_HEIGHT)
    frame.exuiHeaderBackdrop = header

    skins:AddBackdrop(header, { color = th.background, alpha = 1 })
end

local function AdjustHelpButton(frame)
    local helpButton = frame.MainHelpButton
    if (not helpButton or helpButton.exuiAdjusted) then return end
    helpButton.exuiAdjusted = true

    helpButton:SetScale(0.55)
    helpButton:ClearAllPoints()
    helpButton:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -6)
end

local function ApplyBookBackgrounds()
    for _, key in ipairs(BOOK_PAGE_KEYS) do
        local texture = _G[key]
        if (texture) then
            texture:SetVertexColor(unpack(BOOK_BG_COLOR))
        end
    end
end

local function StripStatusBarChrome(statusBar)
    for _, key in ipairs(STATUS_BAR_BG_KEYS) do
        local region = statusBar[key]
        if (region) then skins:StripTexture(region) end
    end

    local barTexture = statusBar:GetStatusBarTexture()
    local trackBg = statusBar.exuiTrackBg
    local fillTex = statusBar.exuiFillTex
    for _, region in ipairs({ statusBar:GetRegions() }) do
        if (region:IsObjectType('Texture') and region ~= barTexture and region ~= trackBg and region ~= fillTex) then
            skins:StripTexture(region)
        end
    end
end

local function ApplyStatusBarBackground(statusBar)
    if (not statusBar.exuiTrackBg) then
        local bg = statusBar:CreateTexture(nil, 'BACKGROUND', nil, -8)
        bg:SetAllPoints()
        statusBar.exuiTrackBg = bg
    end

    local trackColor = GetStatusBarColors()
    local bg = statusBar.exuiTrackBg
    bg:SetTexture(EXUI.const.textures.frame.solidBg)
    bg:SetVertexColor(unpack(trackColor))
    bg:Show()
end

local function ApplyStatusBarLayout(statusBar)
    statusBar:SetSize(STATUS_BAR_WIDTH, STATUS_BAR_HEIGHT)
    statusBar:SetFrameLevel(statusBar:GetParent():GetFrameLevel() + 2)

    local rankText = statusBar.rankText
    if (rankText) then
        rankText:ClearAllPoints()
        rankText:SetPoint('CENTER', statusBar, 'CENTER', 0, 0)
        rankText:SetDrawLayer('OVERLAY', 15)
    end
end

local function ApplyStatusBarAnchor(frame)
    local statusBar = frame.statusBar
    local rank = frame.rank
    local professionName = frame.professionName
    if (not statusBar or not rank) then return end

    local isPrimary = frame.specialization ~= nil

    if (frame.exuiStatusBarAnchored) then
        statusBar:SetSize(STATUS_BAR_WIDTH, STATUS_BAR_HEIGHT)
        return
    end
    frame.exuiStatusBarAnchored = true

    if (isPrimary) then
        if (professionName) then
            professionName:ClearAllPoints()
            professionName:SetPoint('TOPLEFT', frame, 'TOPLEFT', PRIMARY_NAME_X, PRIMARY_NAME_Y)
        end
        if (frame.specialization and professionName) then
            frame.specialization:ClearAllPoints()
            frame.specialization:SetPoint('TOPLEFT', professionName, 'BOTTOMLEFT', 0, -1)
        end
        rank:ClearAllPoints()
        rank:SetPoint('BOTTOMLEFT', professionName, 'BOTTOMLEFT', 0, PRIMARY_RANK_Y)
        statusBar:ClearAllPoints()
        statusBar:SetPoint('TOPLEFT', rank, 'BOTTOMLEFT', 0, -5)
    else
        -- Blizzard chains professionName -> rank -> statusBar; break all three before re-anchoring.
        if (professionName) then professionName:ClearAllPoints() end
        rank:ClearAllPoints()
        statusBar:ClearAllPoints()

        if (professionName) then
            professionName:SetPoint('TOPLEFT', frame, 'TOPLEFT', SECONDARY_NAME_X, SECONDARY_NAME_Y)
            rank:SetPoint('BOTTOMLEFT', professionName, 'BOTTOMLEFT', 0, SECONDARY_RANK_Y)
        else
            rank:SetPoint('TOPLEFT', frame, 'TOPLEFT', SECONDARY_NAME_X, -18)
        end
        statusBar:SetPoint('TOPLEFT', rank, 'BOTTOMLEFT', 0, -5)
    end

    statusBar:SetSize(STATUS_BAR_WIDTH, STATUS_BAR_HEIGHT)
end

local function SuppressNativeStatusBarFill(statusBar)
    statusBar:SetStatusBarTexture(EXUI.const.textures.frame.solidBg)
    statusBar:SetStatusBarColor(0, 0, 0, 0)

    local nativeFill = statusBar:GetStatusBarTexture()
    if (nativeFill) then
        nativeFill:SetAlpha(0)
    end
end

local function EnsureStatusBarFillTexture(statusBar)
    if (statusBar.exuiFillTex) then return end

    local fillTex = statusBar:CreateTexture(nil, 'ARTWORK', nil, 2)
    fillTex:SetTexture(EXUI.const.textures.frame.solidBg)
    statusBar.exuiFillTex = fillTex

    if (statusBar.exuiFillFrame) then
        statusBar.exuiFillFrame:Hide()
        statusBar.exuiFillFrame = nil
    end
end

local function UpdateStatusBarFill(statusBar)
    if (not statusBar or not statusBar.exuiSkinned) then return end

    EnsureStatusBarFillTexture(statusBar)
    SuppressNativeStatusBarFill(statusBar)

    local _, fillColor = GetStatusBarColors()
    local min, max = statusBar:GetMinMaxValues()
    local value = statusBar:GetValue()
    local trackWidth = math.max(1, statusBar:GetWidth() - (STATUS_BAR_INSET * 2))
    local perc = 0

    if (max > min) then
        perc = (value - min) / (max - min)
    end
    perc = math.max(0, math.min(1, perc))

    local fillTex = statusBar.exuiFillTex
    local fillWidth = math.max(1, trackWidth * perc)
    fillTex:ClearAllPoints()
    fillTex:SetPoint('TOPLEFT', statusBar, 'TOPLEFT', STATUS_BAR_INSET, -STATUS_BAR_INSET)
    fillTex:SetPoint('BOTTOMLEFT', statusBar, 'BOTTOMLEFT', STATUS_BAR_INSET, STATUS_BAR_INSET)
    fillTex:SetWidth(fillWidth)
    fillTex:SetVertexColor(unpack(fillColor))
    fillTex:Show()
end

local function ApplyStatusBarFillStyle(statusBar)
    SuppressNativeStatusBarFill(statusBar)
    UpdateStatusBarFill(statusBar)
end

local function ApplyStatusBarText(frame)
    local statusBar = frame and frame.statusBar
    if (not statusBar or not statusBar.rankText or not statusBar.exuiSkinned) then return end

    ApplyFontOnly(statusBar.rankText, RANK_TEXT_SIZE)
end

local function SkinProfessionStatusBar(statusBar)
    if (not statusBar or statusBar.exuiSkinned) then return end
    statusBar.exuiSkinned = true

    StripStatusBarChrome(statusBar)
    ApplyStatusBarLayout(statusBar)
    ApplyStatusBarBackground(statusBar)
    ApplyStatusBarFillStyle(statusBar)
    skins:AddBorder(statusBar, { thickness = 1, level = 600 })

    if (not statusBar.exuiValueHooked) then
        statusBar.exuiValueHooked = true
        hooksecurefunc(statusBar, 'SetValue', function(bar)
            UpdateStatusBarFill(bar)
        end)
        hooksecurefunc(statusBar, 'SetMinMaxValues', function(bar)
            UpdateStatusBarFill(bar)
        end)
    end
end

local function ApplyStatusBarChrome(frame)
    if (not frame or not frame.statusBar) then return end

    ApplyStatusBarAnchor(frame)
    ApplyStatusBarBackground(frame.statusBar)
    ApplyStatusBarFillStyle(frame.statusBar)
end

local function SkinProfessionSpellButton(button)
    if (not button or button.exuiSkinned) then return end
    button.exuiSkinned = true
    local th = GetTheme()

    if (button.NameFrame) then
        skins:StripTexture(button.NameFrame)
    end

    skins:StripTexture(button:GetPushedTexture())
    if (button.highlightTexture) then
        button.highlightTexture:SetDesaturated(true)
        button.highlightTexture:SetVertexColor(th.accent[1], th.accent[2], th.accent[3], 0.35)
    end

    ApplyFontText(button.spellString, SPELL_NAME_SIZE)
    ApplyFontText(button.subSpellString, SPELL_SUBTEXT_SIZE)
end

local function ApplyProfessionSpellButtonText(button)
    if (not button or not button.exuiSkinned) then return end

    ApplyFontOnly(button.spellString, SPELL_NAME_SIZE)
    ApplyFontOnly(button.subSpellString, SPELL_SUBTEXT_SIZE)
end

local function SkinUnlearnButton(button)
    if (not button or button.exuiSkinned) then return end
    button.exuiSkinned = true

    skins:SkinIconButton(button, {
        strip = {},
        tint = { 'Icon' },
    })
end

local function ApplyPrimaryProfessionText(frame)
    if (not frame or not frame.exuiSkinned) then return end
    local th = GetTheme()

    ApplyFontText(frame.professionName, PRIMARY_NAME_SIZE, HEADER_TEXT_COLOR)
    ApplyFontText(frame.specialization, BODY_TEXT_SIZE, th.textMuted)
    ApplyFontText(frame.rank, RANK_TEXT_SIZE, th.text)
    ApplyFontText(frame.missingHeader, PRIMARY_NAME_SIZE, th.accentLight)
    ApplyFontText(frame.missingText, BODY_TEXT_SIZE, th.gray)
end

local function ApplySecondaryProfessionText(frame)
    if (not frame or not frame.exuiSkinned) then return end
    local th = GetTheme()

    ApplyFontText(frame.professionName, SECONDARY_NAME_SIZE, HEADER_TEXT_COLOR)
    ApplyFontText(frame.rank, RANK_TEXT_SIZE, th.text)
    ApplyFontText(frame.missingHeader, SECONDARY_NAME_SIZE, HEADER_TEXT_COLOR)
    ApplyFontText(frame.missingText, BODY_TEXT_SIZE, th.gray)
end

local function SkinPrimaryProfession(frame)
    if (not frame or frame.exuiSkinned) then return end
    frame.exuiSkinned = true

    if (frame.IconBorder) then
        frame.IconBorder:SetVertexColor(unpack(ABILITY_BORDER_COLOR))
    end

    SkinProfessionStatusBar(frame.statusBar)
    SkinProfessionSpellButton(frame.SpellButton1)
    SkinProfessionSpellButton(frame.SpellButton2)
    SkinUnlearnButton(frame.UnlearnButton)
    ApplyPrimaryProfessionText(frame)
end

local function SkinSecondaryProfession(frame)
    if (not frame or frame.exuiSkinned) then return end
    frame.exuiSkinned = true

    SkinProfessionStatusBar(frame.statusBar)
    SkinProfessionSpellButton(frame.SpellButton1)
    SkinProfessionSpellButton(frame.SpellButton2)
    ApplySecondaryProfessionText(frame)
end

local function SkinProfessionsContent()
    for _, key in ipairs(PRIMARY_PROFESSION_KEYS) do
        SkinPrimaryProfession(_G[key])
    end
    for _, key in ipairs(SECONDARY_PROFESSION_KEYS) do
        SkinSecondaryProfession(_G[key])
    end
end

local function ApplyProfessionVisuals(frame)
    if (not frame) then return end

    if (frame.professionName and frame.specialization ~= nil) then
        ApplyPrimaryProfessionText(frame)
    else
        ApplySecondaryProfessionText(frame)
    end

    if (frame.SpellButton1) then ApplyProfessionSpellButtonText(frame.SpellButton1) end
    if (frame.SpellButton2) then ApplyProfessionSpellButtonText(frame.SpellButton2) end
end

function professionsBookSkin:InstallContentHooks()
    if (self.contentHooksInstalled) then return end
    self.contentHooksInstalled = true

    hooksecurefunc('FormatProfession', function(frame, index)
        ApplyProfessionVisuals(frame)
        ApplyStatusBarChrome(frame)
        ApplyStatusBarText(frame)
    end)

    hooksecurefunc(ProfessionSpellButtonMixin, 'UpdateButton', function(button)
        ApplyProfessionSpellButtonText(button)
    end)
end

function professionsBookSkin:SkinFrame()
    local frame = ProfessionsBookFrame
    if (not frame) then return end

    skins:SkinPanelFrame(frame, {
        hidePortrait = true,
        titleSize = TITLE_SIZE,
        backdropAlpha = PANEL_BG_ALPHA,
    })

    SkinHeaderBackdrop(frame)
    AdjustTitleBarLayout(frame)
    AdjustHelpButton(frame)
    ApplyBookBackgrounds()
    SkinProfessionsContent()
    for _, key in ipairs(PRIMARY_PROFESSION_KEYS) do
        ApplyStatusBarChrome(_G[key])
    end
    for _, key in ipairs(SECONDARY_PROFESSION_KEYS) do
        ApplyStatusBarChrome(_G[key])
    end
end

function professionsBookSkin:Install()
    if (self.installed or not ProfessionsBookFrame) then return end
    self.installed = true

    self:InstallContentHooks()
    self:SkinFrame()
end

professionsBookSkin.Init = function(self)
    if (ProfessionsBookFrame) then
        self:Install()
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-ProfessionsBook', function(_, addon)
        if (addon ~= 'Blizzard_ProfessionsBook') then return end
        self:Install()
    end)
end
