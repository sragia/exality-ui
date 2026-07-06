---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0', true)
local Masque = LibStub('Masque', true)
local LAB = LibStub('LibActionButton-1.0')

local useActionButtonUI = C_ActionBar and C_ActionBar.RegisterActionUIButton ~= nil

---@class EXUIActionBarsStyle
local style = EXUI:GetModule('action-bars-style')

---@param value any
---@return boolean|nil
local function safeBool(value)
    if value == nil then
        return nil
    end
    if issecretvalue and issecretvalue(value) then
        return nil
    end
    return value and true or false
end

---@param durationObject any
---@return boolean|nil confirmed true/false, or nil if unknown/secret
local function safeDurationIsZero(durationObject)
    if not durationObject or not durationObject.IsZero then
        return nil
    end
    local ok, isZero = pcall(durationObject.IsZero, durationObject)
    if not ok then
        return nil
    end
    return safeBool(isZero)
end

--- Secret-safe cooldown apply: always use duration objects, never branch on isActive.
---@param cooldownFrame Cooldown|nil
---@param durationObject any
style.ApplyDurationCooldown = function(self, cooldownFrame, durationObject)
    if not cooldownFrame or not durationObject then
        return
    end
    pcall(cooldownFrame.SetCooldownFromDurationObject, cooldownFrame, durationObject, false)
    if safeDurationIsZero(durationObject) == true then
        pcall(cooldownFrame.Clear, cooldownFrame)
    end
end

---@param cooldownFrame Cooldown|nil
---@param spellID number|nil
---@param ignoreGCD boolean|nil
style.ApplySpellCooldownDuration = function(self, cooldownFrame, spellID, ignoreGCD)
    if not cooldownFrame or not spellID or not C_Spell or not C_Spell.GetSpellCooldownDuration then
        return
    end
    local ok, durationObject = pcall(C_Spell.GetSpellCooldownDuration, spellID, ignoreGCD == true)
    if ok and durationObject then
        self:ApplyDurationCooldown(cooldownFrame, durationObject)
    end
end

---@param button any
style.RefreshActionButtonCooldown = function(self, button)
    if not button or button._state_type ~= 'action' or not button.cooldown then
        return
    end
    local slot = button._state_action or button.action
    if useActionButtonUI and slot and slot > 0 and C_ActionBar.RegisterActionUIButton then
        pcall(C_ActionBar.RegisterActionUIButton, button, slot, button.cooldown)
        button.action = slot
    end
    if button.RefreshCooldown then
        button:RefreshCooldown()
    end
end

style.masqueGroups = {}
style.initialized = false

style.Init = function(self)
    if self.initialized then return end
    self.initialized = true

    LAB.RegisterCallback(self, 'OnButtonUpdate', function(_, button)
        if button.exuiBarId and button.exuiBarConfig then
            self:OnLABButtonUpdate(button, button.exuiBarConfig)
        end
    end)

    local eventFrame = CreateFrame('Frame')
    eventFrame:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
    eventFrame:SetScript('OnEvent', function()
        if EXUI:GetModule('action-bars-manager').enabled then
            self:RefreshAllSlotBackdrops()
        end
    end)
end

style.GetMasqueGroup = function(self, barId, skinName)
    if not Masque then
        return nil
    end
    if not self.masqueGroups[barId] then
        self.masqueGroups[barId] = Masque:Group('ExalityUI', 'Action Bar ' .. barId)
    end
    local group = self.masqueGroups[barId]
    if skinName and group.__exuiSkin ~= skinName then
        group:SetSkin(skinName)
        group.__exuiSkin = skinName
    end
    return group
end

style.GetFontPath = function(self, fontName)
    if LSM then
        return LSM:Fetch('font', fontName) or EXUI.const.fonts.DEFAULT
    end
    return EXUI.const.fonts.DEFAULT
end

style.BuildLABTextBlock = function(self, textConfig)
    return {
        font = {
            font = self:GetFontPath(textConfig.font),
            size = textConfig.fontSize,
            flags = textConfig.fontFlag,
        },
        color = { textConfig.color.r, textConfig.color.g, textConfig.color.b },
        position = {
            anchor = textConfig.anchorPoint,
            relAnchor = textConfig.relativePoint,
            offsetX = textConfig.xOffset,
            offsetY = textConfig.yOffset,
        },
        justifyH = EXUI.utils.getJustifyHFromAnchor(textConfig.anchorPoint),
    }
end

style.ShouldUseMasque = function(self, barConfig)
    return barConfig and barConfig.useMasque and Masque ~= nil
end

style.BuildLABConfig = function(self, barConfig, commandName)
    local useMasque = self:ShouldUseMasque(barConfig)
    local hideLabBorder = useMasque and not barConfig.showBorder or not useMasque
    return {
        showGrid = true,
        outOfRangeColoring = 'button',
        tooltip = 'enabled',
        cooldownCount = barConfig.showCooldownText,
        -- Required on 12.0.1+ (build 66562): cooldown swipes use duration objects and
        -- C_ActionBar.RegisterActionUIButton, same as Blizzard action buttons.
        actionButtonUI = useActionButtonUI,
        assistedHighlight = false,
        hideElements = {
            macro = not barConfig.showMacro or not barConfig.macro.enabled,
            hotkey = not barConfig.showHotkey or not barConfig.hotkey.enabled,
            border = hideLabBorder,
            borderIfEmpty = hideLabBorder,
            equipped = true,
        },
        keyBoundTarget = commandName,
        text = {
            hotkey = self:BuildLABTextBlock(barConfig.hotkey),
            count = self:BuildLABTextBlock(barConfig.count),
            macro = self:BuildLABTextBlock(barConfig.macro),
        },
    }
end

style.ApplyIconTexCoords = function(self, button, width, height, zoom)
    if not button.icon then return end
    if zoom and zoom > 0 then
        button.icon:SetTexCoord(EXUI.utils.getTexCoords(width, height, zoom))
    elseif width ~= height then
        button.icon:SetTexCoord(EXUI.utils.getTexCoords(width, height, 0))
    end
end

style.EnsureBorderTexture = function(self, button)
    if button.exuiBorderTexture then
        return button.exuiBorderTexture
    end

    local border = button:CreateTexture(nil, 'BACKGROUND', nil, 2)
    border:SetAllPoints(button)
    button.exuiBorderTexture = border
    return border
end

style.ApplyCooldownSettings = function(self, button, barConfig)
    if not button.cooldown or not barConfig then
        return
    end

    local showSwipe = barConfig.showCooldownSwipe ~= false
    if button.cooldown.SetDrawSwipe then
        button.cooldown:SetDrawSwipe(showSwipe)
    end

    if button.cooldown.SetHideCountdownNumbers and barConfig.showCooldownText ~= nil then
        button.cooldown:SetHideCountdownNumbers(not barConfig.showCooldownText)
    end
end

style.SyncActionCooldown = function(self, button)
    if not button or button._state_type ~= 'action' then
        return
    end
    self:RefreshActionButtonCooldown(button)
    if button.exuiBarConfig then
        self:ApplyCooldownSettings(button, button.exuiBarConfig)
    end
end

-- Legacy name used by debug module.
style.RefreshActionCooldown = style.SyncActionCooldown

style.ApplyDefaultBorder = function(self, button, alpha)
    if button.NormalTexture then
        button.NormalTexture:SetAlpha(0)
    end

    local border = self:EnsureBorderTexture(button)
    border:SetTexture(EXUI.const.masque.rectangle.border)
    border:SetTexCoord(0, 1, 0, 1)
    border:SetVertexColor(0, 0, 0, 1)
    border:SetAlpha(alpha or 1)
    border:Show()
end

style.HideDefaultBorder = function(self, button)
    if button.NormalTexture then
        button.NormalTexture:SetAlpha(0)
    end
    if button.exuiBorderTexture then
        button.exuiBorderTexture:Hide()
    end
    if button.exuiBorderOverlay then
        button.exuiBorderOverlay:Hide()
    end
end

style.HideBlizzardButtonChrome = function(self, button)
    if button.SlotBackground then
        button.SlotBackground:Hide()
    end
    if button.SlotArt then
        button.SlotArt:Hide()
    end
    if button.NewActionTexture then
        button.NewActionTexture:Hide()
    end
end

style.ApplyIconLayout = function(self, button, barConfig)
    if not button.icon then
        return
    end

    local w, h = barConfig.width, barConfig.height
    if button.exuiLayoutWidth == w and button.exuiLayoutHeight == h then
        return
    end

    button.exuiLayoutWidth = w
    button.exuiLayoutHeight = h

    button.icon:ClearAllPoints()
    button.icon:SetAllPoints(button)
    if button.cooldown then
        button.cooldown:ClearAllPoints()
        button.cooldown:SetAllPoints(button.icon)
    end
    self:ApplyCooldownSettings(button, barConfig)
end

style.ApplyIconMask = function(self, button, barConfig)
    if not button.IconMask then
        return
    end
    if barConfig.width ~= barConfig.height then
        button.IconMask:Hide()
    else
        button.IconMask:Show()
    end
end

style.ApplyButtonHighlight = function(self, button)
    local highlightTexture = EXUI.const.masque.rectangle.highlight
    local accent = EXUI.const.theme.accentLight

    if not button.exuiHighlightConfigured then
        button.exuiHighlightConfigured = true
        if button.SetHighlightAtlas then
            button.SetHighlightAtlas = function() end
        end
        button:SetHighlightTexture(highlightTexture, 'ADD')
    end

    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:ClearAllPoints()
        highlight:SetAllPoints(button)
        highlight:SetTexture(highlightTexture)
        highlight:SetBlendMode('ADD')
        highlight:SetVertexColor(accent[1], accent[2], accent[3], 0.55)
    end

    local pushed = button.GetPushedTexture and button:GetPushedTexture()
    if pushed then
        if not button.exuiPushedConfigured then
            button.exuiPushedConfigured = true
            pushed:SetTexture(highlightTexture)
            pushed:SetBlendMode('ADD')
        end
        pushed:ClearAllPoints()
        pushed:SetAllPoints(button)
        pushed:SetVertexColor(EXUI.const.theme.accentDark[1], EXUI.const.theme.accentDark[2], EXUI.const.theme.accentDark[3], 0.65)
    end

    local checked = button.GetCheckedTexture and button:GetCheckedTexture()
    if checked then
        if not button.exuiCheckedConfigured then
            button.exuiCheckedConfigured = true
            checked:SetTexture(highlightTexture)
            checked:SetBlendMode('ADD')
        end
        checked:ClearAllPoints()
        checked:SetAllPoints(button)
        checked:SetVertexColor(accent[1], accent[2], accent[3], 0.45)
    end

    if button.Flash and not button.exuiFlashConfigured then
        button.exuiFlashConfigured = true
        button.Flash:ClearAllPoints()
        button.Flash:SetAllPoints(button)
    end
    if button.SpellHighlightTexture and not button.exuiSpellHighlightConfigured then
        button.exuiSpellHighlightConfigured = true
        button.SpellHighlightTexture:ClearAllPoints()
        button.SpellHighlightTexture:SetAllPoints(button)
    end
end

style.ButtonIsEmpty = function(self, button)
    if button._state_type == 'action' and button._state_action then
        return not HasAction(button._state_action)
    end
    if button.HasAction then
        local hasAction = button:HasAction()
        if hasAction ~= nil then
            return not hasAction
        end
    end
    if button.icon then
        return not button.icon:IsShown()
    end
    return true
end

style.EnsureSlotBackdrop = function(self, button)
    if button.exuiSlotBackdrop then
        return button.exuiSlotBackdrop
    end

    local backdrop = CreateFrame('Frame', nil, button, 'BackdropTemplate')
    backdrop:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
    backdrop:SetAllPoints()
    backdrop:SetBackdrop(EXUI.const.backdrop.backgroundOnly)
    button.exuiSlotBackdrop = backdrop
    return backdrop
end

style.UpdateSlotBackdrop = function(self, button, barConfig)
    if not barConfig.showBackdrop then
        if button.exuiSlotBackdrop then
            button.exuiSlotBackdrop:Hide()
        end
        return
    end

    local slotBackdrop = self:EnsureSlotBackdrop(button)
    if self:ButtonIsEmpty(button) then
        local c = barConfig.backdropColor or { r = 0, g = 0, b = 0, a = 0.55 }
        slotBackdrop:SetBackdropColor(c.r, c.g, c.b, c.a)
        slotBackdrop:Show()
    else
        slotBackdrop:Hide()
    end
end

style.StyleNonMasqueButtonChrome = function(self, button, barConfig)
    if button.MasqueSkinned or self:ShouldUseMasque(barConfig) then
        return
    end

    self:HideBlizzardButtonChrome(button)

    if button.Border then
        button.Border:Hide()
    end
    if button.IconBorder then
        button.IconBorder:Hide()
    end

    self:ApplyIconMask(button, barConfig)
    self:ApplyIconTexCoords(button, barConfig.width, barConfig.height, barConfig.zoom)
    self:ApplyButtonHighlight(button)

    if not barConfig.showBorder then
        self:HideDefaultBorder(button)
        return
    end

    local isEmpty = self:ButtonIsEmpty(button)
    self:ApplyDefaultBorder(button, isEmpty and 0.65 or 1)
end

style.StyleNonMasqueButton = function(self, button, barConfig)
    self:ApplyIconLayout(button, barConfig)
    self:StyleNonMasqueButtonChrome(button, barConfig)
end

style.FixMasqueNormalRegion = function(self, button)
    if not button.MasqueSkinned then
        return
    end

    if button.Border then
        button.Border:Hide()
    end

    local normal = Masque and Masque.GetNormal and Masque:GetNormal(button)
    if normal then
        normal:ClearAllPoints()
        normal:SetAllPoints()
        normal:Show()
    elseif button.NormalTexture then
        button.NormalTexture:ClearAllPoints()
        button.NormalTexture:SetAllPoints()
    end
end

style.NormalTextureIsQuickslot = function(self, button)
    if not button.NormalTexture then
        return false
    end
    local tex = button.NormalTexture:GetTexture()
    return type(tex) == 'string' and tex:find('Quickslot', 1, true) ~= nil
end

style.StyleMasqueButton = function(self, button, barConfig)
    if not button.MasqueSkinned or not self:ShouldUseMasque(barConfig) then
        return
    end

    local needsReskin = self:NormalTextureIsQuickslot(button)
    self:FixMasqueNormalRegion(button)

    local group = button.exuiBarId and self.masqueGroups[button.exuiBarId]
    if group and needsReskin then
        group:ReSkin(button)
        self:FixMasqueNormalRegion(button)
    end

    self:ApplyIconTexCoords(button, barConfig.width, barConfig.height, barConfig.zoom)

    if Masque and Masque.SetEmpty then
        Masque:SetEmpty(button, self:ButtonIsEmpty(button))
    end
end

style.ApplyButtonStyle = function(self, button, barConfig)
    if not barConfig then
        return
    end

    if self:ShouldUseMasque(barConfig) and button.MasqueSkinned then
        self:StyleMasqueButton(button, barConfig)
    else
        self:StyleNonMasqueButton(button, barConfig)
    end
    self:UpdateSlotBackdrop(button, barConfig)
end

style.OnLABButtonUpdate = function(self, button, barConfig)
    if not barConfig then
        return
    end

    if self:ShouldUseMasque(barConfig) and button.MasqueSkinned then
        self:StyleMasqueButton(button, barConfig)
    else
        self:StyleNonMasqueButtonChrome(button, barConfig)
        if button.cooldown and button.icon then
            button.cooldown:ClearAllPoints()
            button.cooldown:SetAllPoints(button.icon)
        end
    end
    self:UpdateSlotBackdrop(button, barConfig)
    if not self:ShouldUseMasque(barConfig) then
        self:ApplyCooldownSettings(button, barConfig)
    end
end

style.OnButtonUpdated = function(self, button, barConfig)
    self:ApplyButtonStyle(button, barConfig)
end

style.HookButtonUpdates = function(self, button, barId)
    if button.exuiUpdateHooked then return end
    button.exuiUpdateHooked = true
    button.exuiBarId = barId

    if not button.UpdateAction then
        return
    end

    -- LAB buttons fire OnButtonUpdate; special buttons only expose UpdateAction.
    if button.GetAction then
        return
    end

    local originalUpdateAction = button.UpdateAction
    button.UpdateAction = function(btn, force)
        originalUpdateAction(btn, force)
        local config = btn.exuiBarConfig
        if config then
            style:OnButtonUpdated(btn, config)
        end
    end
end

style.RefreshBarSlotBackdrops = function(self, frame, barConfig)
    if not frame or not frame.buttons then return end
    for _, button in ipairs(frame.buttons) do
        button.exuiBarConfig = barConfig
        self:OnButtonUpdated(button, barConfig)
    end
end

style.RefreshAllSlotBackdrops = function(self)
    local barMod = EXUI:GetModule('action-bars-bar')
    local resolver = EXUI:GetModule('action-bars-config-resolver')
    local db = EXUI:GetModule('action-bars'):GetDB()
    for barId, frame in pairs(barMod.instances) do
        local config = resolver:GetBarConfig(db, barId)
        self:RefreshBarSlotBackdrops(frame, config)
    end
end

style.ApplyToButton = function(self, button, barId, barConfig, commandName)
    button.exuiBarConfig = barConfig

    local labConfig = self:BuildLABConfig(barConfig, commandName)
    button:UpdateConfig(labConfig)

    if self:ShouldUseMasque(barConfig) then
        local group = self:GetMasqueGroup(barId, barConfig.masqueSkin)
        if group and not button.MasqueSkinned then
            button:AddToMasque(group)
        end
    end

    self:HookButtonUpdates(button, barId)

    if not self:ShouldUseMasque(barConfig) or not button.MasqueSkinned then
        self:ApplyIconLayout(button, barConfig)
    end

    if button.UpdateAction then
        button:UpdateAction(true)
    else
        self:OnButtonUpdated(button, barConfig)
    end

    self:ApplyCooldownSettings(button, barConfig)
    self:SyncActionCooldown(button)

    if not self:ShouldUseMasque(barConfig) or not button.MasqueSkinned then
        self:StyleNonMasqueButtonChrome(button, barConfig)
    end
end

style.RefreshMasqueSkin = function(self, barId, skinName)
    local group = self.masqueGroups[barId]
    if group and skinName and group.__exuiSkin ~= skinName then
        group:SetSkin(skinName)
        group.__exuiSkin = skinName
        group:ReSkin(true)
    end
end

style.ReleaseMasqueGroups = function(self)
    for barId, group in pairs(self.masqueGroups) do
        if group then
            group:Delete()
        end
        self.masqueGroups[barId] = nil
    end
end

style:Init()
