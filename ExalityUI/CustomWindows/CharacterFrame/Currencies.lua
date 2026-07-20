---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

---@class EXUICharacterFrameCurrencies
local currencies = EXUI:GetModule('character-frame-currencies')

currencies.panel = nil
currencies.toggle = nil
currencies.optionsPopup = nil
currencies.scrollFrame = nil
currencies.scrollChild = nil
currencies.headerRows = {}
currencies.currencyRows = {}
currencies.isOpen = false
currencies.useAnimation = true
currencies.selectedIndex = nil
currencies.selectedName = nil
currencies.selectedCurrencyID = nil

local PANEL_WIDTH = 290
local PANEL_GAP = 6
local OPTIONS_WIDTH = 200
local OPTIONS_GAP = 4
local BUTTON_SIZE = 30
local BUTTON_OUTSET_X = 0
local BUTTON_OFFSET_Y = -60
local TITLE_HEIGHT = 28
local ROW_HEIGHT = 24
local HEADER_HEIGHT = 22
local ROW_GAP = 2
local CONTENT_PAD = 10
local ANIM_DURATION = 0.18
local HEADER_GOLD = { 235 / 255, 183 / 255, 52 / 255, 1 } -- #ebb734
local TOGGLE_BG = { 112 / 255, 80 / 255, 0, 1 }           -- #705000
local TOGGLE_BG_HOVER = { 140 / 255, 100 / 255, 0, 1 }

local function ApplyRowVisual(button, selected, hovered)
    local theme = EXUI.const.theme
    if selected then
        button.border:SetBorderColor(unpack(theme.accent))
        button.border:SetBorderThickness(2)
        button.bg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 0.9)
    elseif hovered then
        button.border:SetBorderColor(0.55, 0.55, 0.55, 1)
        button.border:SetBorderThickness(1)
        button.bg:SetVertexColor(0.2, 0.2, 0.2, 0.7)
    else
        button.border:SetBorderColor(unpack(theme.border))
        button.border:SetBorderThickness(1)
        button.bg:SetVertexColor(0, 0, 0, 0.55)
    end
end

local function ApplyHeaderVisual(button, hovered)
    local theme = EXUI.const.theme
    if hovered then
        button.bg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 0.85)
    else
        button.bg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 0.55)
    end
end

local function ApplyToggleVisual(button, hovered)
    if hovered then
        button.bg:SetVertexColor(unpack(TOGGLE_BG_HOVER))
    else
        button.bg:SetVertexColor(unpack(TOGGLE_BG))
    end
end

local function SetHeaderTextColor(button, depth)
    if depth == 0 then
        button.Text:SetTextColor(unpack(HEADER_GOLD))
        button.Collapse:SetVertexColor(HEADER_GOLD[1], HEADER_GOLD[2], HEADER_GOLD[3], 0.95)
    else
        button.Text:SetTextColor(unpack(EXUI.const.theme.textMuted))
        button.Collapse:SetVertexColor(1, 1, 1, 0.85)
    end
end

currencies.CreateHeaderRow = function(self, parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(HEADER_HEIGHT)
    button.isHeader = true

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    button.bg:SetAllPoints()

    button.Collapse = button:CreateTexture(nil, 'OVERLAY')
    button.Collapse:SetTexture(EXUI.const.textures.frame.icons.chevronRight)
    button.Collapse:SetSize(10, 10)
    button.Collapse:SetPoint('LEFT', 6, 0)
    button.Collapse:SetVertexColor(1, 1, 1, 0.85)

    button.Text = button:CreateFontString(nil, 'OVERLAY')
    button.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Text:SetPoint('LEFT', button.Collapse, 'RIGHT', 4, 0)
    button.Text:SetPoint('RIGHT', -8, 0)
    button.Text:SetJustifyH('LEFT')
    button.Text:SetWordWrap(false)

    button:SetScript('OnEnter', function(btn)
        ApplyHeaderVisual(btn, true)
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyHeaderVisual(btn, false)
    end)
    button:SetScript('OnClick', function(btn)
        if not btn.currencyIndex then
            return
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        local expand = not btn.isExpanded
        C_CurrencyInfo.ExpandCurrencyList(btn.currencyIndex, expand)
        currencies:Update()
    end)

    return button
end

currencies.CreateCurrencyRow = function(self, parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(ROW_HEIGHT)
    button.isHeader = false

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    button.bg:SetAllPoints()

    button.border = EXUI:AddPixelPerfectBorder(button, 1, { register = false, outwardBottom = false })
    button.border:SetBorderColor(unpack(EXUI.const.theme.border))

    button.Icon = button:CreateTexture(nil, 'ARTWORK')
    button.Icon:SetSize(18, 18)
    button.Icon:SetPoint('LEFT', 6, 0)
    button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.Text = button:CreateFontString(nil, 'OVERLAY')
    button.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Text:SetPoint('LEFT', button.Icon, 'RIGHT', 6, 0)
    button.Text:SetPoint('RIGHT', button, 'RIGHT', -56, 0)
    button.Text:SetJustifyH('LEFT')
    button.Text:SetWordWrap(false)
    button.Text:SetTextColor(unpack(EXUI.const.theme.text))

    button.Count = button:CreateFontString(nil, 'OVERLAY')
    button.Count:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Count:SetPoint('RIGHT', -8, 0)
    button.Count:SetWidth(48)
    button.Count:SetJustifyH('RIGHT')
    button.Count:SetTextColor(unpack(EXUI.const.theme.text))

    button:SetScript('OnEnter', function(btn)
        ApplyRowVisual(btn, btn.currencyIndex == currencies.selectedIndex, true)
        if btn.currencyID then
            GameTooltip:SetOwner(btn, 'ANCHOR_RIGHT', 2, 2)
            GameTooltip:SetCurrencyByID(btn.currencyID)
            GameTooltip:Show()
        end
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyRowVisual(btn, btn.currencyIndex == currencies.selectedIndex, false)
        GameTooltip:Hide()
    end)
    button:SetScript('OnClick', function(btn)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        GameTooltip:Hide()
        if currencies.selectedIndex == btn.currencyIndex and currencies.optionsPopup and currencies.optionsPopup:IsShown() then
            currencies:HideOptions()
        else
            currencies:ShowOptions(btn)
        end
    end)

    return button
end

currencies.AcquireHeaderRow = function(self, index)
    local row = self.headerRows[index]
    if not row then
        row = self:CreateHeaderRow(self.scrollChild)
        self.headerRows[index] = row
    end
    return row
end

currencies.AcquireCurrencyRow = function(self, index)
    local row = self.currencyRows[index]
    if not row then
        row = self:CreateCurrencyRow(self.scrollChild)
        self.currencyRows[index] = row
    end
    return row
end

currencies.UpdateScroll = function(self)
    if not self.scrollFrame then
        return
    end
    local width = math.max(1, self.scrollFrame:GetWidth())
    local height = math.max(1, self.scrollChild:GetHeight())
    self.scrollFrame:UpdateScrollChild(width, height)
end

currencies.Update = function(self)
    if not self.panel or not self.isOpen then
        return
    end

    local content = self.scrollChild
    local y = -2
    local headerIndex = 0
    local currencyIndex = 0
    local listSize = C_CurrencyInfo.GetCurrencyListSize()

    for i = 1, listSize do
        local info = C_CurrencyInfo.GetCurrencyListInfo(i)
        if info then
            local depth = info.currencyListDepth or 0

            if info.isHeader then
                headerIndex = headerIndex + 1
                local row = self:AcquireHeaderRow(headerIndex)
                local indent = depth > 0 and 8 or 0

                row:ClearAllPoints()
                row:SetPoint('TOPLEFT', content, 'TOPLEFT', 2 + indent, y)
                row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -2, y)
                row:Show()

                row.currencyIndex = i
                row.isExpanded = info.isHeaderExpanded
                row.depth = depth
                row.Text:SetText(info.name or '')
                row.Collapse:SetTexture(EXUI.const.textures.frame.icons.chevronRight)
                if info.isHeaderExpanded then
                    row.Collapse:SetRotation(math.rad(-90))
                else
                    row.Collapse:SetRotation(0)
                end
                SetHeaderTextColor(row, depth)
                ApplyHeaderVisual(row, false)
                y = y - HEADER_HEIGHT - ROW_GAP
            else
                currencyIndex = currencyIndex + 1
                local row = self:AcquireCurrencyRow(currencyIndex)
                local indent = EXUI:ScalePixel(6 + depth * 10, row)
                local xPad = EXUI:ScalePixel(2, row)
                local yPos = EXUI:ScalePixel(y, row)

                row:ClearAllPoints()
                row:SetPoint('TOPLEFT', content, 'TOPLEFT', xPad + indent, yPos)
                row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -xPad, yPos)
                row:Show()

                row.currencyIndex = i
                row.currencyID = info.currencyID
                row.currencyName = info.name
                row.discovered = info.discovered
                row.isTypeUnused = info.isTypeUnused
                row.isShowInBackpack = info.isShowInBackpack
                row.Icon:SetTexture(info.iconFileID)
                row.Text:SetText(info.name or '')
                row.Count:SetText(BreakUpLargeNumbers(info.quantity or 0))
                ApplyRowVisual(row, i == self.selectedIndex, false)
                y = y - ROW_HEIGHT - ROW_GAP
            end
        end
    end

    for i = headerIndex + 1, #self.headerRows do
        self.headerRows[i]:Hide()
    end
    for i = currencyIndex + 1, #self.currencyRows do
        self.currencyRows[i]:Hide()
    end

    content:SetHeight(math.max((-y) + 4, 1))
    self:UpdateScroll()

    if self.optionsPopup and self.optionsPopup:IsShown() then
        self:RefreshOptionsPopup()
    end
end

currencies.ResolveSelectedIndex = function(self)
    if not self.selectedName then
        return nil
    end
    local listSize = C_CurrencyInfo.GetCurrencyListSize()
    for i = 1, listSize do
        local info = C_CurrencyInfo.GetCurrencyListInfo(i)
        if info and not info.isHeader and info.name == self.selectedName then
            return i, info
        end
    end
    return nil
end

currencies.HideOptions = function(self)
    self.selectedIndex = nil
    self.selectedName = nil
    self.selectedCurrencyID = nil
    if self.optionsPopup then
        self.optionsPopup:Hide()
    end
    for _, row in ipairs(self.currencyRows) do
        if row:IsShown() then
            ApplyRowVisual(row, false, false)
        end
    end
end

currencies.SetCheckboxValue = function(self, checkbox, value)
    if not checkbox then
        return
    end
    checkbox.suppressOnChange = true
    checkbox:SetValue('value', value and true or false)
    checkbox.suppressOnChange = false
end

currencies.RefreshOptionsPopup = function(self)
    local popup = self.optionsPopup
    if not popup or not popup:IsShown() then
        return
    end

    local index, info = self:ResolveSelectedIndex()
    if not index or not info then
        self:HideOptions()
        return
    end

    self.selectedIndex = index
    self.selectedCurrencyID = info.currencyID
    self.selectedName = info.name

    local showChecks = info.discovered and true or false
    popup.unusedCheckbox:SetShown(showChecks)
    popup.backpackCheckbox:SetShown(showChecks)
    self:SetCheckboxValue(popup.unusedCheckbox, info.isTypeUnused)
    self:SetCheckboxValue(popup.backpackCheckbox, info.isShowInBackpack)

    local showTransferNote = info.currencyID
        and C_CurrencyInfo.IsAccountTransferableCurrency(info.currencyID)
    popup.Disclaimer:SetShown(showTransferNote)

    local height = 50
    if showChecks then
        height = height + 40
    end
    if showTransferNote then
        height = height + 28
    end
    popup:SetHeight(height)
end

currencies.ShowOptions = function(self, row)
    if not self.optionsPopup or not row then
        return
    end

    self.selectedIndex = row.currencyIndex
    self.selectedName = row.currencyName
    self.selectedCurrencyID = row.currencyID

    for _, other in ipairs(self.currencyRows) do
        if other:IsShown() then
            ApplyRowVisual(other, other.currencyIndex == self.selectedIndex, false)
        end
    end

    self.optionsPopup:Show()
    self:RefreshOptionsPopup()
end

currencies.CreateOptionsCheckbox = function(self, parent, label, tooltipText)
    local checkbox = EXFrames:GetFrame('checkbox'):Create()
    checkbox:SetParent(parent)
    checkbox:SetHeight(22)
    checkbox:SetFrameWidth(OPTIONS_WIDTH - 24)
    checkbox:SetLabel(label)
    checkbox.Label:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    checkbox.Label:SetTextColor(unpack(EXUI.const.theme.text))

    checkbox:HookScript('OnEnter', function(cb)
        if tooltipText then
            GameTooltip:SetOwner(cb, 'ANCHOR_RIGHT')
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    checkbox:HookScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    return checkbox
end

currencies.CreateOptionsPopup = function(self, panel)
    local theme = EXUI.const.theme
    local popup = CreateFrame('Frame', nil, panel)
    popup:SetSize(OPTIONS_WIDTH, 120)
    popup:SetPoint('TOPLEFT', panel, 'TOPRIGHT', OPTIONS_GAP, -28)
    popup:SetFrameLevel(panel:GetFrameLevel() + 10)
    popup:EnableMouse(true)
    popup:Hide()

    local bg = popup:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXFrames.assets.textures.ui.panelBg)
    bg:SetVertexColor(unpack(theme.backgroundDeep))
    bg:SetTextureSliceMargins(8, 8, 8, 8)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAllPoints()

    local border = popup:CreateTexture(nil, 'OVERLAY', nil, 1)
    border:SetTexture(EXFrames.assets.textures.ui.panelBorder)
    border:SetVertexColor(unpack(theme.border))
    border:SetTextureSliceMargins(8, 8, 8, 8)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    border:SetAllPoints()

    local close = CreateFrame('Button', nil, popup)
    close:SetSize(22, 18)
    close:SetPoint('TOPRIGHT', -6, -6)
    local closeBg = close:CreateTexture(nil, 'BACKGROUND')
    closeBg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    closeBg:SetTextureSliceMargins(20, 20, 20, 20)
    closeBg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    closeBg:SetVertexColor(unpack(theme.faded))
    closeBg:SetAllPoints()
    local closeIcon = close:CreateTexture(nil, 'OVERLAY')
    closeIcon:SetTexture(EXUI.const.textures.frame.closeIcon)
    closeIcon:SetSize(10, 10)
    closeIcon:SetPoint('CENTER')
    close:SetScript('OnEnter', function()
        closeBg:SetVertexColor(unpack(theme.dangerHover))
    end)
    close:SetScript('OnLeave', function()
        closeBg:SetVertexColor(unpack(theme.faded))
    end)
    close:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        currencies:HideOptions()
    end)

    local title = popup:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    title:SetPoint('TOPLEFT', 12, -12)
    title:SetPoint('TOPRIGHT', close, 'TOPLEFT', -4, -1)
    title:SetJustifyH('CENTER')
    title:SetText(TOKEN_OPTIONS or 'Currency Options')
    title:SetTextColor(unpack(HEADER_GOLD))
    popup.Title = title

    local unusedCheckbox = self:CreateOptionsCheckbox(popup, UNUSED or 'Unused', TOKEN_MOVE_TO_UNUSED)
    unusedCheckbox:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', -2, -10)
    unusedCheckbox.onChange = function(value)
        if not currencies.selectedIndex then
            return
        end
        PlaySound(value and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        C_CurrencyInfo.SetCurrencyUnused(currencies.selectedIndex, value and true or false)
        local index = currencies:ResolveSelectedIndex()
        if index then
            currencies.selectedIndex = index
        end
        currencies:Update()
    end
    popup.unusedCheckbox = unusedCheckbox

    local backpackCheckbox = self:CreateOptionsCheckbox(popup, SHOW_ON_BACKPACK or 'Show on Backpack',
        TOKEN_SHOW_ON_BACKPACK)
    backpackCheckbox:SetPoint('TOPLEFT', unusedCheckbox, 'BOTTOMLEFT', 0, -4)
    backpackCheckbox.onChange = function(value)
        if not currencies.selectedIndex then
            return
        end
        if value and BackpackTokenFrame and BackpackTokenFrame.GetMaxTokensWatched then
            local maxWatched = BackpackTokenFrame:GetMaxTokensWatched()
            local watched = GetNumWatchedTokens and GetNumWatchedTokens() or 0
            if watched >= maxWatched then
                UIErrorsFrame:AddMessage(TOO_MANY_WATCHED_TOKENS:format(maxWatched), 1.0, 0.1, 0.1, 1.0)
                currencies:SetCheckboxValue(backpackCheckbox, false)
                return
            end
        end
        PlaySound(value and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        C_CurrencyInfo.SetCurrencyBackpack(currencies.selectedIndex, value and true or false)
        currencies:Update()
    end
    popup.backpackCheckbox = backpackCheckbox

    local disclaimer = popup:CreateFontString(nil, 'OVERLAY')
    disclaimer:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    disclaimer:SetPoint('BOTTOMLEFT', 12, 12)
    disclaimer:SetPoint('BOTTOMRIGHT', -12, 12)
    disclaimer:SetJustifyH('LEFT')
    disclaimer:SetWordWrap(true)
    disclaimer:SetText('To transfer, please use Default UI.')
    disclaimer:SetTextColor(unpack(theme.textMuted))
    popup.Disclaimer = disclaimer

    self.optionsPopup = popup
    return popup
end

currencies.StopAnimations = function(self)
    if self.panel and self.panel.fadeIn then
        self.panel.fadeIn:Stop()
    end
    if self.panel and self.panel.fadeOut then
        self.panel.fadeOut:Stop()
    end
    if self.toggle and self.toggle.fadeIn then
        self.toggle.fadeIn:Stop()
    end
end

currencies.RevealToggle = function(self, animated)
    if not self.toggle then
        return
    end
    ApplyToggleVisual(self.toggle, false)
    if animated and self.useAnimation and self.toggle.fadeIn then
        self.toggle:SetAlpha(0)
        self.toggle:Show()
        self.toggle.fadeIn:Play()
    else
        self.toggle:SetAlpha(1)
        self.toggle:Show()
    end
end

currencies.ShowPanel = function(self)
    if not self.panel then
        return
    end

    self.isOpen = true
    self:StopAnimations()
    if self.toggle then
        self.toggle:SetAlpha(1)
        self.toggle:Hide()
    end
    self.panel:Show()
    self:Update()

    if self.useAnimation and self.panel.fadeIn then
        self.panel:SetAlpha(0)
        self.panel.fadeIn:Play()
    else
        self.panel:SetAlpha(1)
    end
end

currencies.HidePanel = function(self, immediate)
    if not self.panel then
        return
    end

    self.isOpen = false
    self:HideOptions()
    self:StopAnimations()

    if immediate or not self.useAnimation or not self.panel.fadeOut then
        self.panel:SetAlpha(1)
        self.panel:Hide()
        self:RevealToggle(false)
        return
    end

    self.panel.fadeOut:SetScript('OnFinished', function()
        self.panel:Hide()
        self.panel:SetAlpha(1)
        self:RevealToggle(true)
    end)
    self.panel.fadeOut:Play()
end

currencies.Toggle = function(self)
    if self.isOpen then
        self:HidePanel()
    else
        self:ShowPanel()
    end
end

currencies.CreateToggle = function(self, window)
    local button = CreateFrame('Button', nil, window)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetPoint('TOPLEFT', window, 'TOPRIGHT', BUTTON_OUTSET_X, BUTTON_OFFSET_Y)
    button:SetFrameLevel(window:GetFrameLevel() + 20)

    local bg = button:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    bg:SetTextureSliceMargins(20, 20, 20, 20)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetAllPoints()
    button.bg = bg

    local icon = button:CreateTexture(nil, 'OVERLAY')
    icon:SetTexture(EXUI.const.textures.characterFrame.coins)
    icon:SetSize(18, 18)
    icon:SetPoint('CENTER')
    icon:SetVertexColor(1, 1, 1, 1)
    button.icon = icon

    button.Tooltip = tooltip:Get({
        text = 'Currencies'
    }, button)

    button:SetScript('OnEnter', function(btn)
        ApplyToggleVisual(btn, true)
        btn.Tooltip:ShowTooltip()
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyToggleVisual(btn, false)
        btn.Tooltip:HideTooltip()
    end)
    button:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        currencies:ShowPanel()
    end)

    button.fadeIn = EXUI.utils.animation.fade(button, ANIM_DURATION, 0, 1)

    ApplyToggleVisual(button, false)
    self.toggle = button
    return button
end

currencies.CreateCloseButton = function(self, panel)
    local theme = EXUI.const.theme
    local close = CreateFrame('Button', nil, panel)
    close:SetSize(28, 22)
    close:SetPoint('TOPRIGHT', -8, -6)
    close:SetFrameLevel(panel:GetFrameLevel() + 5)

    local bg = close:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    bg:SetTextureSliceMargins(20, 20, 20, 20)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetVertexColor(unpack(theme.faded))
    bg:SetAllPoints()

    local icon = close:CreateTexture(nil, 'OVERLAY')
    icon:SetTexture(EXUI.const.textures.frame.closeIcon)
    icon:SetSize(12, 12)
    icon:SetPoint('CENTER')
    icon:SetVertexColor(1, 1, 1, 1)

    close:SetScript('OnEnter', function()
        bg:SetVertexColor(unpack(theme.dangerHover))
    end)
    close:SetScript('OnLeave', function()
        bg:SetVertexColor(unpack(theme.faded))
    end)
    close:SetScript('OnClick', function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        currencies:HidePanel()
    end)

    panel.close = close
    return close
end

currencies.CreatePanel = function(self, window)
    local theme = EXUI.const.theme
    local panel = CreateFrame('Frame', nil, window)
    panel:SetWidth(PANEL_WIDTH)
    panel:SetPoint('TOPLEFT', window, 'TOPRIGHT', PANEL_GAP, 0)
    panel:SetPoint('BOTTOMLEFT', window, 'BOTTOMRIGHT', PANEL_GAP, 0)
    panel:SetFrameLevel(window:GetFrameLevel() + 5)
    panel:Hide()
    panel:SetAlpha(1)

    local bg = panel:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXFrames.assets.textures.ui.panelBg)
    bg:SetVertexColor(unpack(theme.backgroundDeep))
    bg:SetTextureSliceMargins(8, 8, 8, 8)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAllPoints()

    local border = panel:CreateTexture(nil, 'OVERLAY', nil, 1)
    border:SetTexture(EXFrames.assets.textures.ui.panelBorder)
    border:SetVertexColor(unpack(theme.border))
    border:SetTextureSliceMargins(8, 8, 8, 8)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    border:SetAllPoints()

    self:CreateCloseButton(panel)
    self:CreateOptionsPopup(panel)

    local title = panel:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    title:SetPoint('TOPLEFT', CONTENT_PAD, -10)
    title:SetPoint('TOPRIGHT', panel.close, 'TOPLEFT', -6, -2)
    title:SetJustifyH('LEFT')
    title:SetText(CURRENCY or 'Currencies')
    title:SetTextColor(unpack(theme.text))
    panel.Title = title

    local scrollFrame = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scrollFrame:SetParent(panel)
    scrollFrame:SetPoint('TOPLEFT', CONTENT_PAD, -(TITLE_HEIGHT + 4))
    scrollFrame:SetPoint('BOTTOMRIGHT', -CONTENT_PAD, CONTENT_PAD)
    self.scrollFrame = scrollFrame
    self.scrollChild = scrollFrame.child

    scrollFrame:HookScript('OnSizeChanged', function()
        if currencies.isOpen then
            currencies:Update()
        end
    end)

    -- Fade animation; horizontal diveIn tends to fight static anchors — fade only.
    panel.fadeIn = EXUI.utils.animation.fade(panel, ANIM_DURATION, 0, 1)
    panel.fadeOut = EXUI.utils.animation.fade(panel, ANIM_DURATION, 1, 0)

    panel:RegisterEvent('CURRENCY_DISPLAY_UPDATE')
    panel:SetScript('OnEvent', function()
        if currencies.isOpen then
            currencies:Update()
        end
    end)

    self.panel = panel
    return panel
end

currencies.Create = function(self, window)
    self:CreateToggle(window)
    self:CreatePanel(window)
end

currencies.Hide = function(self)
    self:HidePanel(true)
end
