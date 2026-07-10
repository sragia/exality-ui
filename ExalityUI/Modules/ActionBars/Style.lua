---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0', true)
local Masque = LibStub('Masque', true)
local LAB = LibStub('LibActionButton-1.0')

---@class EXUIActionBarsStyle
local style = EXUI:GetModule('action-bars-style')

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsButton
local buttonMod = EXUI:GetModule('action-bars-button')

style.masqueGroups = {}
style.initialized = false
style.pendingSlotRefresh = false
style.pendingSlotChanges = {}

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
    eventFrame:SetScript('OnEvent', function(_, _, slot)
        if EXUI:GetModule('action-bars-manager').enabled then
            if slot then
                style:QueueSlotBackdropRefresh(slot)
            else
                style:RefreshAllSlotBackdrops()
            end
        end
    end)
end

style.FindButtonForSlot = function(self, slot)
    if not slot or slot < 1 then
        return nil, nil, nil
    end

    local barMod = EXUI:GetModule('action-bars-bar')

    for _, barId in ipairs(definitions.PLAYER_BAR_IDS) do
        local def = definitions:Get(barId)
        if def and def.baseSlot and def.barType == 'action' then
            local index = slot - def.baseSlot + 1
            if index >= 1 and index <= (def.numButtons or 12) then
                local frame = barMod:Get(barId)
                if frame and frame.buttons and frame.buttons[index] then
                    return frame, frame.buttons[index], barId
                end
            end
        end
    end

    for page = 1, buttonMod.RETAIL_PAGES do
        local index = slot - (page - 1) * 12
        if index >= 1 and index <= 12 then
            local frame = barMod:Get('bar1')
            if frame and frame.buttons and frame.buttons[index] then
                return frame, frame.buttons[index], 'bar1'
            end
        end
    end

    return nil, nil, nil
end

style.RefreshSlotBackdrop = function(self, slot)
    local frame, button, barId = self:FindButtonForSlot(slot)
    if not frame or not button or not barId then
        return false
    end

    local resolver = EXUI:GetModule('action-bars-config-resolver')
    local db = EXUI:GetModule('action-bars'):GetDB()
    local config = resolver:GetBarConfig(db, barId)
    button.exuiBarConfig = config
    self:OnButtonUpdated(button, config)
    return true
end

style.QueueSlotBackdropRefresh = function(self, slot)
    if slot then
        self.pendingSlotChanges[slot] = true
    end
    if self.pendingSlotRefresh then
        return
    end
    self.pendingSlotRefresh = true
    C_Timer.After(0, function()
        style.pendingSlotRefresh = false
        local needsFullRefresh = false
        for changedSlot in pairs(style.pendingSlotChanges) do
            if not style:RefreshSlotBackdrop(changedSlot) then
                needsFullRefresh = true
            end
        end
        wipe(style.pendingSlotChanges)
        if needsFullRefresh then
            style:RefreshAllSlotBackdrops()
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
        cooldownCount = barConfig.showCooldownText ~= false and barConfig.cooldown.enabled ~= false,
        actionButtonUI = true,
        assistedHighlight = false,
        hideElements = {
            macro = not barConfig.macro.enabled,
            hotkey = not barConfig.hotkey.enabled,
            border = hideLabBorder,
            borderIfEmpty = hideLabBorder,
            equipped = true,
        },
        keyBoundTarget = commandName,
        keyBoundClickButton = 'Keybind',
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

style.ShouldShowCooldownText = function(self, barConfig)
    return barConfig
        and barConfig.showCooldownText ~= false
        and barConfig.cooldown
        and barConfig.cooldown.enabled ~= false
end

style.ApplyCooldownText = function(self, cooldown, button, barConfig)
    if not cooldown or not barConfig then
        return
    end

    local show = self:ShouldShowCooldownText(barConfig)
    if cooldown.SetHideCountdownNumbers then
        cooldown:SetHideCountdownNumbers(not show)
    end
    if not show or not cooldown.GetCountdownFontString then
        return
    end

    local textConfig = barConfig.cooldown
    local fontString = cooldown:GetCountdownFontString()
    if not fontString then
        return
    end

    fontString:SetFont(self:GetFontPath(textConfig.font), textConfig.fontSize, textConfig.fontFlag)
    local color = textConfig.color or { r = 1, g = 1, b = 1, a = 1 }
    fontString:SetTextColor(color.r, color.g, color.b, color.a or 1)

    local anchorParent = button.icon or button
    fontString:ClearAllPoints()
    fontString:SetPoint(
        textConfig.anchorPoint or 'CENTER',
        anchorParent,
        textConfig.relativePoint or textConfig.anchorPoint or 'CENTER',
        textConfig.xOffset or 0,
        textConfig.yOffset or 0
    )
    if fontString.SetJustifyH then
        fontString:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(textConfig.anchorPoint))
    end
    fontString:Show()
end

style.ApplyCooldownSettings = function(self, button, barConfig)
    if not button or not barConfig then
        return
    end

    local showSwipe = barConfig.showCooldownSwipe ~= false
    if button.cooldown and button.cooldown.SetDrawSwipe then
        button.cooldown:SetDrawSwipe(showSwipe)
    end

    self:ApplyCooldownText(button.cooldown, button, barConfig)

    if button.chargeCooldown then
        if barConfig.hideCooldownCharge then
            if button.chargeCooldown.SetHideCountdownNumbers then
                button.chargeCooldown:SetHideCountdownNumbers(true)
            end
        else
            self:ApplyCooldownText(button.chargeCooldown, button, barConfig)
        end
    end
end

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
    self:NormalizeAbilityButtonIcon(button)
    if not button.icon then
        return
    end

    local w, h = barConfig.width, barConfig.height
    local sizeChanged = button.exuiLayoutWidth ~= w or button.exuiLayoutHeight ~= h

    -- SmallActionButtonTemplate (stance/pet/possess) hardcodes mask/cooldown insets in OnLoad.
    button.icon:ClearAllPoints()
    button.icon:SetAllPoints(button)

    if button.IconMask then
        button.IconMask:ClearAllPoints()
        button.IconMask:SetAllPoints(button.icon)
    end

    if button.cooldown then
        button.cooldown:ClearAllPoints()
        button.cooldown:SetAllPoints(button.icon)
    end

    if button.Flash then
        button.Flash:ClearAllPoints()
        button.Flash:SetAllPoints(button)
    end

    if sizeChanged then
        button.exuiLayoutWidth = w
        button.exuiLayoutHeight = h
        self:ApplyCooldownSettings(button, barConfig)
    end
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
        pushed:SetVertexColor(EXUI.const.theme.accentDark[1], EXUI.const.theme.accentDark[2],
            EXUI.const.theme.accentDark[3], 0.65)
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
    if button.HasAction and button.index then
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
    if not barConfig.showBackdrop or not barConfig.showBorder or self:ShouldUseMasque(barConfig) then
        if button.exuiSlotBackdrop then
            button.exuiSlotBackdrop:Hide()
        end
        return
    end

    local slotBackdrop = self:EnsureSlotBackdrop(button)
    local c = barConfig.backdropColor or { r = 0, g = 0, b = 0, a = 0.55 }
    slotBackdrop:SetBackdropColor(c.r, c.g, c.b, c.a)
    slotBackdrop:Show()
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
    if isEmpty and not barConfig.showBackdrop then
        self:HideDefaultBorder(button)
        return
    end

    self:ApplyDefaultBorder(button, isEmpty and 0.65 or 1)
end

style.StyleNonMasqueButton = function(self, button, barConfig)
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

    self:ApplyIconLayout(button, barConfig)

    if self:ShouldUseMasque(barConfig) and button.MasqueSkinned then
        self:StyleMasqueButton(button, barConfig)
    else
        self:StyleNonMasqueButton(button, barConfig)
    end
    self:UpdateSlotBackdrop(button, barConfig)
end

style.ApplyTextVisibility = function(self, button, barConfig)
    if not button or not barConfig then
        return
    end

    if button.Count then
        if barConfig.count.enabled then
            button.Count:Show()
        else
            button.Count:Hide()
        end
    end
end

style.OnLABButtonUpdate = function(self, button, barConfig)
    if not barConfig then
        return
    end

    self:ApplyIconLayout(button, barConfig)

    if self:ShouldUseMasque(barConfig) and button.MasqueSkinned then
        self:StyleMasqueButton(button, barConfig)
    else
        self:StyleNonMasqueButtonChrome(button, barConfig)
    end
    self:UpdateSlotBackdrop(button, barConfig)
    self:ApplyCooldownSettings(button, barConfig)
    self:ApplyTextVisibility(button, barConfig)
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
    self:ApplyTextVisibility(button, barConfig)

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

style.ApplyFontString = function(self, fontString, textConfig)
    if not fontString then
        return
    end
    if not textConfig or textConfig.enabled == false then
        fontString:Hide()
        return
    end
    fontString:Show()
    fontString:SetFont(self:GetFontPath(textConfig.font), textConfig.fontSize, textConfig.fontFlag)
    local color = textConfig.color or { r = 1, g = 1, b = 1, a = 1 }
    fontString:SetTextColor(color.r, color.g, color.b, color.a or 1)
end

style.NormalizeAbilityButtonIcon = function(self, button)
    if not button then
        return nil
    end
    if button.icon then
        return button.icon
    end
    if button.Icon then
        button.icon = button.Icon
        return button.Icon
    end
    return nil
end

style.ApplyAbilityCooldowns = function(self, button, barConfig)
    local cooldowns = {
        button.cooldown,
        button.Cooldown,
        button.chargeCooldown,
        button.ChargeCooldown,
        button.lossOfControlCooldown,
    }
    local showSwipe = barConfig.showCooldownSwipe ~= false
    for _, cooldown in ipairs(cooldowns) do
        if cooldown then
            if cooldown.SetDrawSwipe then
                cooldown:SetDrawSwipe(showSwipe)
            end
            local isCharge = cooldown == button.chargeCooldown or cooldown == button.ChargeCooldown
            local isLossOfControl = cooldown == button.lossOfControlCooldown
            local hideChargeCooldown = barConfig.hideCooldownCharge == true

            if (isCharge and hideChargeCooldown) or isLossOfControl then
                if cooldown.SetHideCountdownNumbers then
                    cooldown:SetHideCountdownNumbers(true)
                end
            else
                self:ApplyCooldownText(cooldown, button, barConfig)
            end
        end
    end
end

style.StyleBlizzardAbilityButton = function(self, button, barId, barConfig)
    if not button or not barConfig then
        return
    end
    if InCombatLockdown() then
        return
    end
    self:Init()
    self:NormalizeAbilityButtonIcon(button)

    EXUI:SetSize(button, barConfig.width, barConfig.height)

    local icon = button.icon
    if icon then
        icon:ClearAllPoints()
        icon:SetAllPoints(button)
        self:ApplyIconTexCoords(button, barConfig.width, barConfig.height, barConfig.zoom)
    end

    self:ApplyIconMask(button, barConfig)
    self:ApplyIconLayout(button, barConfig)
    self:ApplyButtonHighlight(button)
    self:HideBlizzardButtonChrome(button)

    if button.style then
        button.style:SetShown(barConfig.showBlizzardArtwork == true)
    end
    if button.NormalTexture and barConfig.showBlizzardArtwork ~= true then
        button.NormalTexture:SetAlpha(0)
    end

    if self:ShouldUseMasque(barConfig) then
        local group = self:GetMasqueGroup(barId, barConfig.masqueSkin)
        if group and not button.MasqueSkinned then
            group:AddButton(button, nil, 'Action')
            button.MasqueSkinned = true
        end
        if button.MasqueSkinned then
            self:StyleMasqueButton(button, barConfig)
        end
    else
        self:StyleNonMasqueButton(button, barConfig)
        self:ApplyAbilityCooldowns(button, barConfig)
    end

    self:ApplyFontString(button.HotKey, barConfig.hotkey)
    self:ApplyFontString(button.Count, barConfig.count)

    if button.Flash then
        button.Flash:ClearAllPoints()
        button.Flash:SetAllPoints(button)
    end
end

style:Init()
