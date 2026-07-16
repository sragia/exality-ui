---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIDeathRecapSkin
local deathRecapSkin = EXUI:GetModule('skin-DeathRecap')

local FONT_PATH = EXUI.const.fonts.DEFAULT
local TITLE_SIZE = 13
local TEXT_SIZE = 12
local SMALL_SIZE = 11
local PANEL_BG_ALPHA = 0.9
local DIVIDER_HEIGHT = 1

local function GetTheme()
    return EXUI.const.theme
end

local function StyleFont(fontString, fontSize, color)
    if (not fontString) then return end
    fontString:SetFont(FONT_PATH, fontSize, 'OUTLINE')
    if (color) then
        fontString:SetTextColor(unpack(color))
    end
end

local function StyleDivider(divider)
    if (not divider) then return end
    local th = GetTheme()
    divider:SetTexture(EXUI.const.textures.frame.solidBg)
    divider:SetVertexColor(unpack(th.border))
    divider:SetAlpha(1)
    divider:SetHeight(EXUI:ScalePixel(DIVIDER_HEIGHT, divider:GetParent() or divider, 1))
    divider:Show()
end

function deathRecapSkin:SkinEntry(entry)
    if (not entry) then return end

    local th = GetTheme()
    local spellInfo = entry.SpellInfo
    if (spellInfo) then
        StyleFont(spellInfo.Name, TEXT_SIZE, th.text)
        StyleFont(spellInfo.Caster, SMALL_SIZE, th.textMuted)
        if (spellInfo.IconBorder) then
            skins:StripTexture(spellInfo.IconBorder)
        end
    end

    local damageInfo = entry.DamageInfo
    if (damageInfo) then
        StyleFont(damageInfo.Amount, TEXT_SIZE, th.danger)
        StyleFont(damageInfo.AmountLarge, TEXT_SIZE + 1, th.danger)
    end
end

function deathRecapSkin:SkinFrame(frame)
    if (not frame or frame.exuiSkinned) then return end
    frame.exuiSkinned = true

    local th = GetTheme()

    -- Raid-border chrome is plain named textures (no NineSlice).
    skins:StripAllTextures(frame)
    skins:AddBackdrop(frame, { color = th.backgroundDeep, alpha = PANEL_BG_ALPHA })
    skins:AddBorder(frame)

    if (frame.Title) then
        StyleFont(frame.Title, TITLE_SIZE, th.text)
        frame.Title:ClearAllPoints()
        frame.Title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 8, -5)
    end
    StyleFont(frame.Unavailable, TEXT_SIZE, th.textMuted)
    StyleDivider(frame.Divider)

    -- X close is CloseXButton; CloseButton is the bottom UIPanelButton.
    if (frame.CloseXButton) then
        skins:SkinCloseButton(frame.CloseXButton)
    end
    if (frame.CloseButton) then
        skins:SkinPanelButton(frame.CloseButton)
    end
    if (frame.ScrollBar) then
        skins:SkinMinimalScrollBar(frame.ScrollBar)
    end
end

function deathRecapSkin:InstallHooks()
    if (self.hooksInstalled) then return end
    self.hooksInstalled = true

    if (DeathRecapEntryMixin and DeathRecapEntryMixin.Init) then
        hooksecurefunc(DeathRecapEntryMixin, 'Init', function(entry)
            deathRecapSkin:SkinEntry(entry)
        end)
    end

    if (DeathRecapMixin and DeathRecapMixin.OpenRecap) then
        hooksecurefunc(DeathRecapMixin, 'OpenRecap', function(frame)
            deathRecapSkin:SkinFrame(frame)
            StyleDivider(frame.Divider)
            StyleFont(frame.Title, TITLE_SIZE, GetTheme().text)
            StyleFont(frame.Unavailable, TEXT_SIZE, GetTheme().textMuted)
        end)
    end
end

function deathRecapSkin:Install()
    if (self.installed or not DeathRecapFrame) then return end
    self.installed = true

    self:InstallHooks()
    self:SkinFrame(DeathRecapFrame)
end

deathRecapSkin.Init = function(self)
    if (DeathRecapFrame) then
        self:Install()
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-DeathRecap', function(_, addon)
        if (addon ~= 'Blizzard_DeathRecap') then return end
        self:Install()
    end)
end
