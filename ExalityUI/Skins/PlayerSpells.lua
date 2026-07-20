---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIPlayerSpellsSkin
local playerSpellsSkin = EXUI:GetModule('skin-PlayerSpells')

local TITLE_SIZE = 13
local PANEL_BG_ALPHA = 0.95
local TAB_TEXT_SIZE = 11
local TAB_HEIGHT = 28
local TAB_ACTIVE_EXTRA = 4
local TAB_TEXT_PADDING = 20
local TAB_INSET = 1
local TAB_GRADIENT_HEIGHT = 18
local TAB_SLICE = 6
local TAB_TEXT_Y_INACTIVE = -2
local TAB_TEXT_Y_ACTIVE = 0
local TAB_TEXT_Y_TOP_INACTIVE = -3
local TAB_TEXT_Y_TOP_ACTIVE = 0
local SPELLBOOK_TOPBAR_SLICE = 6
local CATEGORY_TAB_X = 25
local CATEGORY_TAB_Y = -20
local TALENTS_SEARCH_PREVIEW_WIDTH = 184
local SPELLBOOK_BOOK_BG_COLOR = { 179 / 255, 179 / 255, 179 / 255, 1 }
local SPELLBOOK_ABILITY_BORDER_COLOR = { 154 / 255, 154 / 255, 154 / 255, 1 }
local SPELLBOOK_HEADER_BACKPLATE_COLOR = { 0.843, 0.843, 0.843, 1 }
local SPELLBOOK_HEADER_BACKPLATE_ALPHA = 0.647
local SPELLBOOK_HEADER_TEXT_SIZE = 24
local SPELLBOOK_HEADER_TEXT_COLOR = { 235 / 255, 232 / 255, 228 / 255, 1 }
local SPELLBOOK_NAME_TEXT_SIZE = 16
local SPELLBOOK_SUBTEXT_SIZE = 12
local SPELLBOOK_SPELL_TEXT_COLOR = { 205 / 255, 198 / 255, 190 / 255, 1 }
local MAX_MIN_ICON_SIZE = 14

local SPELLBOOK_BOOK_BG_KEYS = { 'BookBGHalved', 'BookBGLeft', 'BookBGRight', 'BookCornerFlipbook' }

local TAB_TEXTURE_KEYS = {
    'Left', 'Middle', 'Right',
    'LeftActive', 'MiddleActive', 'RightActive',
    'LeftHighlight', 'MiddleHighlight', 'RightHighlight',
}

local function GetTheme()
    return EXUI.const.theme
end

local function StripButtonTextures(button)
    skins:StripTexture(button:GetNormalTexture())
    skins:StripTexture(button:GetPushedTexture())
    if (button.GetDisabledTexture) then skins:StripTexture(button:GetDisabledTexture()) end
    if (button.GetHighlightTexture) then skins:StripTexture(button:GetHighlightTexture()) end
end

local function SkinMaxMinButton(button, mode)
    if (not button or button.exuiSkinned) then return end
    button.exuiSkinned = true

    StripButtonTextures(button)
    local th = GetTheme()

    local iconPath = mode == 'maximize'
        and EXUI.const.textures.frame.icons.fullscreen
        or EXUI.const.textures.frame.icons.minimize

    local icon = button:CreateTexture(nil, 'OVERLAY')
    icon:SetTexture(iconPath)
    icon:SetPoint('CENTER')
    icon:SetSize(MAX_MIN_ICON_SIZE, MAX_MIN_ICON_SIZE)
    icon:SetVertexColor(unpack(th.textMuted))

    local setGlyphColor = function(color)
        icon:SetVertexColor(unpack(color))
    end

    button:HookScript('OnEnter', function()
        setGlyphColor(GetTheme().accentLight)
    end)
    button:HookScript('OnLeave', function()
        setGlyphColor(GetTheme().textMuted)
    end)
end

local function EnsureTexturedBackground(button)
    if (not button.exuiBg) then
        local bg = button:CreateTexture(nil, 'BACKGROUND', nil, 1)
        bg:SetTexture(EXUI.const.textures.frame.whiteTextured)
        bg:SetAllPoints()
        button.exuiBg = bg
    end
end

local function ApplyTexturedBackground(button, hovered, pushed)
    EnsureTexturedBackground(button)
    local th = GetTheme()
    if (not button:IsEnabled()) then
        button.exuiBg:SetVertexColor(unpack(th.faded))
    elseif (pushed) then
        button.exuiBg:SetVertexColor(unpack(th.accentDark))
    elseif (hovered) then
        button.exuiBg:SetVertexColor(unpack(th.backgroundLight))
    else
        button.exuiBg:SetVertexColor(unpack(th.backgroundDeep))
    end
    button.exuiBg:Show()
end

local function SkinTexturedButton(button)
    if (not button or button.exuiTexturedSkinned) then return end
    button.exuiTexturedSkinned = true

    skins:StripThreeSliceButton(button, { keepHighlight = false })
    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if (highlight) then skins:StripTexture(highlight) end

    ApplyTexturedBackground(button, false, false)
    skins:StylePanelButtonText(button)
    skins:AddBorder(button, { thickness = 1 })

    if (not button.exuiTexturedHooked) then
        button.exuiTexturedHooked = true
        button:HookScript('OnEnter', function(btn)
            if (btn:IsEnabled()) then ApplyTexturedBackground(btn, true, false) end
        end)
        button:HookScript('OnLeave', function(btn)
            ApplyTexturedBackground(btn, false, false)
        end)
        button:HookScript('OnMouseDown', function(btn)
            if (btn:IsEnabled()) then ApplyTexturedBackground(btn, true, true) end
        end)
        button:HookScript('OnMouseUp', function(btn)
            ApplyTexturedBackground(btn, btn:IsMouseOver(), false)
        end)
        button:HookScript('OnDisable', function(btn)
            ApplyTexturedBackground(btn, false, false)
            skins:StylePanelButtonText(btn)
        end)
        button:HookScript('OnEnable', function(btn)
            ApplyTexturedBackground(btn, btn:IsMouseOver(), false)
            skins:StylePanelButtonText(btn)
        end)
        button:HookScript('OnShow', function(btn)
            ApplyTexturedBackground(btn, btn:IsMouseOver(), false)
            skins:StylePanelButtonText(btn)
        end)
    end
end

local function IsTabSelected(tab)
    return tab.isSelected == true
end

local function EnsureTabTextVisible(tab)
    local text = tab.Text
    if (not text) then return end
    text:SetDrawLayer('OVERLAY', 7)
    text:Show()
    text:SetAlpha(1)
end

local function IsTopTab(tab)
    return tab.exuiBottomTab == false
end

local function ApplyTabHeight(tab, selected)
    tab:SetHeight(selected and (TAB_HEIGHT + TAB_ACTIVE_EXTRA) or TAB_HEIGHT)
end

local function ConfigureTabBackgroundTexture(bg)
    bg:SetTexture(EXUI.const.textures.frame.whiteTextured)
    bg:SetTextureSliceMargins(TAB_SLICE, TAB_SLICE, TAB_SLICE, TAB_SLICE)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAlpha(1)
end

local function EnsureTabChrome(tab)
    local isTopTab = IsTopTab(tab)

    if (not tab.exuiTabBg) then
        local bgLayer = isTopTab and 'ARTWORK' or 'BACKGROUND'
        local bg = tab:CreateTexture(nil, bgLayer, nil, 0)
        ConfigureTabBackgroundTexture(bg)
        tab.exuiTabBg = bg
    else
        ConfigureTabBackgroundTexture(tab.exuiTabBg)
    end

    if (not tab.exuiTabGlow) then
        local glow = tab:CreateTexture(nil, 'ARTWORK', nil, 1)
        glow:SetTexture(isTopTab and EXUI.const.textures.frame.gradientTop or EXUI.const.textures.frame.gradientBottom)
        glow:SetBlendMode('BLEND')
        tab.exuiTabGlow = glow
    end
end

---Bottom-mounted tabs: top edge sits against the window, selected tab extends downward.
local function ApplyBottomTabLayout(tab, bg, glow, selected)
    bg:ClearAllPoints()
    bg:SetPoint('TOPLEFT', tab, 'TOPLEFT', TAB_INSET, -TAB_INSET)
    bg:SetPoint('BOTTOMRIGHT', tab, 'BOTTOMRIGHT', -TAB_INSET, TAB_INSET)

    glow:ClearAllPoints()
    if (selected) then
        local glowHeight = EXUI:ScalePixel(TAB_GRADIENT_HEIGHT, tab, 1)
        glow:SetPoint('BOTTOMLEFT', bg, 'BOTTOMLEFT')
        glow:SetPoint('BOTTOMRIGHT', bg, 'BOTTOMRIGHT')
        glow:SetPoint('TOPLEFT', bg, 'BOTTOMLEFT', 0, glowHeight)
        glow:SetPoint('TOPRIGHT', bg, 'BOTTOMRIGHT', 0, glowHeight)
        glow:SetVertexColor(unpack(GetTheme().accent))
        glow:SetAlpha(1)
        glow:Show()
    else
        glow:Hide()
    end
end

---Top-mounted tabs (spellbook categories): selected tab extends upward, highlight on top edge.
local function ApplyTopTabLayout(tab, bg, glow, selected)
    bg:ClearAllPoints()
    bg:SetPoint('TOPLEFT', tab, 'TOPLEFT', TAB_INSET, -TAB_INSET)
    bg:SetPoint('BOTTOMRIGHT', tab, 'BOTTOMRIGHT', -TAB_INSET, TAB_INSET)

    glow:ClearAllPoints()
    if (selected) then
        local glowHeight = EXUI:ScalePixel(TAB_GRADIENT_HEIGHT, tab, 1)
        glow:SetPoint('TOPLEFT', bg, 'TOPLEFT')
        glow:SetPoint('TOPRIGHT', bg, 'TOPRIGHT')
        glow:SetPoint('BOTTOMLEFT', bg, 'TOPLEFT', 0, -glowHeight)
        glow:SetPoint('BOTTOMRIGHT', bg, 'TOPRIGHT', 0, -glowHeight)
        glow:SetVertexColor(unpack(GetTheme().accent))
        glow:SetAlpha(1)
        glow:Show()
    else
        glow:Hide()
    end
end

local function ApplyTabChromeLayout(tab, bg, glow, selected)
    if (IsTopTab(tab)) then
        ApplyTopTabLayout(tab, bg, glow, selected)
    else
        ApplyBottomTabLayout(tab, bg, glow, selected)
    end
end

local function ApplyTabTextLayout(tab, selected)
    local text = tab.Text
    if (not text) then return end

    EnsureTabTextVisible(tab)
    text:SetFont(EXUI.const.fonts.DEFAULT, TAB_TEXT_SIZE, 'OUTLINE')
    text:ClearAllPoints()
    local yOffset
    if (IsTopTab(tab)) then
        yOffset = selected and TAB_TEXT_Y_TOP_ACTIVE or TAB_TEXT_Y_TOP_INACTIVE
    else
        yOffset = selected and TAB_TEXT_Y_ACTIVE or TAB_TEXT_Y_INACTIVE
    end
    text:SetPoint('CENTER', tab, 'CENTER', 0, yOffset)
end

local function ApplyTabTextColor(tab)
    local th = GetTheme()
    local text = tab.Text
    if (not text) then return end

    -- Selected tabs are disabled by the tab system; check selection before enabled state.
    if (IsTabSelected(tab)) then
        text:SetTextColor(unpack(th.white))
    elseif (not tab:IsEnabled()) then
        text:SetTextColor(unpack(th.textMuted))
    elseif (tab:IsMouseOver()) then
        text:SetTextColor(unpack(th.white))
    else
        text:SetTextColor(unpack(th.gray))
    end
    text:SetAlpha(1)
end

local function ApplyTabVisualState(tab)
    if (not tab.exuiTabSkinned) then return end

    EnsureTabChrome(tab)
    local th = GetTheme()
    local selected = IsTabSelected(tab)
    local bg = tab.exuiTabBg
    local glow = tab.exuiTabGlow

    ApplyTabHeight(tab, selected)

    if (selected) then
        if (IsTopTab(tab)) then
            -- Slightly darker than the TopBar (backgroundLight) so the active tab reads clearly.
            bg:SetVertexColor(unpack(th.background))
        else
            bg:SetVertexColor(unpack(th.backgroundLight))
        end
        bg:SetAlpha(1)
    else
        bg:SetVertexColor(unpack(th.backgroundDeep))
        bg:SetAlpha(1)
    end

    ApplyTabChromeLayout(tab, bg, glow, selected)
    bg:Show()
    ApplyTabTextLayout(tab, selected)
    ApplyTabTextColor(tab)
end

local function UpdateExuiTabWidth(tab)
    local tabSystem = tab:GetTabSystem()
    if (not tabSystem) then return end

    local minTabWidth, maxTabWidth = tabSystem:GetTabWidthConstraints()
    local width = (tab.Text:GetStringWidth() or 0) + TAB_TEXT_PADDING

    if (maxTabWidth and width > maxTabWidth) then
        width = maxTabWidth
    end
    if (minTabWidth and width < minTabWidth) then
        width = minTabWidth
    end

    local textWidth = math.max(0, width - TAB_TEXT_PADDING)
    if (textWidth > 0) then
        tab.Text:SetWidth(textWidth)
    end
    tab:SetWidth(width)
end

local function RefreshTabSystemVisuals(tabSystem)
    if (not tabSystem) then return end
    for _, tab in ipairs(tabSystem.tabs or {}) do
        if (tab.exuiTabSkinned) then
            if (tab.isSelected) then
                tab:Enable()
            end
            ApplyTabVisualState(tab)
            UpdateExuiTabWidth(tab)
        end
    end
    if (tabSystem.MarkDirty) then
        tabSystem:MarkDirty()
    end
end

local function EnsureTabSystemLayoutHook(tabSystem)
    if (not tabSystem or tabSystem.exuiLayoutHooked) then return end
    tabSystem.exuiLayoutHooked = true

    local originalLayout = tabSystem.Layout
    tabSystem.Layout = function(self, ...)
        if (self.exuiSkinned) then
            for _, tab in ipairs(self.tabs or {}) do
                if (tab.exuiTabSkinned) then
                    ApplyTabHeight(tab, IsTabSelected(tab))
                end
            end
        end
        return originalLayout(self, ...)
    end
end

local function SkinTabButton(tab, isBottomTab)
    if (not tab or tab.exuiTabSkinned) then return end
    tab.exuiTabSkinned = true
    tab.exuiBottomTab = isBottomTab
    tab.exuiTopTab = not isBottomTab

    if (IsTopTab(tab)) then
        tab.align = 'bottom'
    else
        tab.align = nil
    end

    for _, key in ipairs(TAB_TEXTURE_KEYS) do
        local region = tab[key]
        if (region) then skins:StripTexture(region) end
    end

    local highlight = tab.GetHighlightTexture and tab:GetHighlightTexture()
    if (highlight) then skins:StripTexture(highlight) end

    if (IsTopTab(tab)) then
        local tabSystem = tab:GetTabSystem()
        if (tabSystem) then
            tab:SetFrameLevel(tabSystem:GetFrameLevel() + 2)
        end
    end

    EnsureTabChrome(tab)
    ApplyTabVisualState(tab)
    UpdateExuiTabWidth(tab)

    tab:HookScript('OnEnter', function(btn)
        if (IsTabSelected(btn)) then return end
        ApplyTabTextColor(btn)
    end)
    tab:HookScript('OnLeave', function(btn)
        if (IsTabSelected(btn)) then return end
        ApplyTabTextColor(btn)
    end)
end

local function SkinTabSystem(tabSystem, isBottomTab)
    if (not tabSystem) then return end

    local isTopTabSystem = not isBottomTab
    if (not tabSystem.exuiSkinned) then
        tabSystem.exuiSkinned = true
        tabSystem.exuiTopTab = isTopTabSystem

        if (isTopTabSystem) then
            local parent = tabSystem:GetParent()
            if (parent) then
                tabSystem:SetFrameLevel(parent:GetFrameLevel() + 50)
            end
        end

        EnsureTabSystemLayoutHook(tabSystem)
    end

    for _, tab in ipairs(tabSystem.tabs or {}) do
        SkinTabButton(tab, isBottomTab)
        UpdateExuiTabWidth(tab)
    end
end

local function SkinAtlasIconButton(button)
    if (not button or button.exuiIconSkinned) then return end
    button.exuiIconSkinned = true

    local icon = button.Icon
    if (not icon) then return end

    icon:SetDesaturated(true)
    icon:SetVertexColor(unpack(GetTheme().textMuted))

    button:HookScript('OnEnter', function(btn)
        if (btn.Icon) then btn.Icon:SetVertexColor(unpack(GetTheme().accentLight)) end
    end)
    button:HookScript('OnLeave', function(btn)
        if (btn.Icon) then btn.Icon:SetVertexColor(unpack(GetTheme().textMuted)) end
    end)
end

local function SkinPagingControls(paging)
    if (not paging or paging.exuiSkinned) then return end
    paging.exuiSkinned = true

    for _, key in ipairs({ 'PrevPageButton', 'NextPageButton' }) do
        local button = paging[key]
        if (button) then
            skins:SkinIconButton(button, {
                strip = { 'HighlightTexture' },
                tint = { 'NormalTexture', 'PushedTexture', 'DisabledTexture' },
            })
        end
    end

    if (paging.PageText) then
        paging.PageText:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        paging.PageText:SetTextColor(unpack(GetTheme().text))
    end
end

local function SkinLoadoutDialog(dialog)
    if (not dialog or dialog.exuiSkinned) then return end
    dialog.exuiSkinned = true
    local th = GetTheme()

    if (dialog.Border) then
        skins:StripNineSlice(dialog.Border)
    end
    skins:AddBackdrop(dialog, { color = th.background, alpha = 0.95 })
    skins:AddBorder(dialog)

    if (dialog.Title) then
        dialog.Title:SetFont(EXUI.const.fonts.DEFAULT, TITLE_SIZE, 'OUTLINE')
        dialog.Title:SetTextColor(unpack(th.text))
    end

    for _, key in ipairs({ 'AcceptButton', 'CancelButton', 'DeleteButton' }) do
        local button = dialog[key]
        if (button) then SkinTexturedButton(button) end
    end
end

local function SkinHeroTalentsDialog(dialog)
    if (not dialog or dialog.exuiSkinned) then return end
    dialog.exuiSkinned = true

    skins:SkinPanelFrame(dialog, { titleSize = TITLE_SIZE, skipBackdrop = true })

    for _, key in ipairs({ 'ActivateButton', 'ApplyChangesButton' }) do
        local button = dialog[key]
        if (button) then SkinTexturedButton(button) end
    end
end

local function ApplyTalentsSearchPreviewLayout(container)
    if (not container) then return end

    local searchBox = container:GetParent() and container:GetParent().SearchBox
    if (not searchBox) then return end

    container:ClearAllPoints()
    container:SetPoint('TOPRIGHT', searchBox, 'BOTTOMRIGHT', 0, 0)
    container:SetWidth(TALENTS_SEARCH_PREVIEW_WIDTH)
    container.exuiPreviewWidth = TALENTS_SEARCH_PREVIEW_WIDTH

    if (container.OverflowCount) then
        container.OverflowCount:SetWidth(TALENTS_SEARCH_PREVIEW_WIDTH)
    end
end

local function SkinTalentsSearchPreview(frame)
    local container = frame and frame.SearchPreviewContainer
    if (not container) then return end

    skins:SkinSearchPreviewContainer(container)
    ApplyTalentsSearchPreviewLayout(container)

    if (not container.exuiTalentsLayoutHooked) then
        container.exuiTalentsLayoutHooked = true
        container:HookScript('OnShow', ApplyTalentsSearchPreviewLayout)
    end
end

local function ApplySpellBookSearchPreviewLayout(container)
    if (not container) then return end

    local searchBox = container:GetParent() and container:GetParent().SearchBox
    if (not searchBox) then return end

    container:ClearAllPoints()
    container:SetPoint('TOPLEFT', searchBox, 'BOTTOMLEFT', 0, 0)
    container:SetPoint('TOPRIGHT', searchBox, 'BOTTOMRIGHT', 0, 0)
    container.exuiPreviewWidth = container:GetWidth()

    if (container.OverflowCount) then
        container.OverflowCount:SetWidth(container:GetWidth())
    end
end

local function InstallSpellBookSearchPreviewHooks()
    if (playerSpellsSkin.spellBookPreviewHooksInstalled) then return end
    playerSpellsSkin.spellBookPreviewHooksInstalled = true

    hooksecurefunc(SpellSearchPreviewContainerMixin, 'UpdateResultsDisplay', function(container)
        if (not container.exuiSpellBookLayoutHooked) then return end

        container.exuiPreviewWidth = container:GetWidth()
        if (container.OverflowCount) then
            container.OverflowCount:SetWidth(container:GetWidth())
        end
    end)
end

local function SkinSpellBookSearchPreview(frame)
    local container = frame and frame.SearchPreviewContainer
    if (not container) then return end

    InstallSpellBookSearchPreviewHooks()
    skins:SkinSearchPreviewContainer(container)
    ApplySpellBookSearchPreviewLayout(container)

    if (not container.exuiSpellBookLayoutHooked) then
        container.exuiSpellBookLayoutHooked = true
        container:HookScript('OnShow', ApplySpellBookSearchPreviewLayout)
    end
end

local function ApplyLoadSystemDropdownLayout(loadSystem)
    local dropdown = loadSystem and loadSystem.Dropdown
    if (not dropdown) then return end

    dropdown:ClearAllPoints()
    dropdown:SetPoint('TOPLEFT', loadSystem, 'TOPLEFT', 0, 0)
    dropdown:SetPoint('BOTTOMRIGHT', loadSystem, 'BOTTOMRIGHT', 0, 0)
end

local function SkinTalentsFrame(frame)
    if (not frame or frame.exuiButtonsSkinned) then return end
    frame.exuiButtonsSkinned = true

    for _, key in ipairs({ 'ApplyButton', 'InspectCopyButton' }) do
        local button = frame[key]
        if (button) then SkinTexturedButton(button) end
    end

    for _, key in ipairs({ 'ResetButton', 'UndoButton' }) do
        SkinAtlasIconButton(frame[key])
    end

    if (frame.SearchBox) then
        skins:SkinSearchBox(frame.SearchBox)
    end

    SkinTalentsSearchPreview(frame)

    if (frame.LoadSystem and frame.LoadSystem.Dropdown) then
        ApplyLoadSystemDropdownLayout(frame.LoadSystem)
        skins:SkinModernDropdown(frame.LoadSystem.Dropdown)
    end
end

local function SkinSpecContentFrame(contentFrame)
    if (not contentFrame or not contentFrame.ActivateButton) then return end
    SkinTexturedButton(contentFrame.ActivateButton)
end

local function SkinSpecContentFrames(frame)
    if (not frame or not frame.SpecContentFramePool) then return end

    for contentFrame in frame.SpecContentFramePool:EnumerateActive() do
        SkinSpecContentFrame(contentFrame)
    end
end

local function InstallSpecFrameHooks()
    if (playerSpellsSkin.specFrameHooksInstalled) then return end
    playerSpellsSkin.specFrameHooksInstalled = true

    hooksecurefunc(ClassSpecFrameMixin, 'UpdateSpecContents', function(frame)
        SkinSpecContentFrames(frame)
    end)

    hooksecurefunc(ClassSpecFrameMixin, 'OnShow', function(frame)
        SkinSpecContentFrames(frame)
    end)
end

local function SkinSpecFrame(frame)
    if (not frame) then return end

    InstallSpecFrameHooks()
    SkinSpecContentFrames(frame)
end

local function ApplySpellBookTopBar(frame)
    local topBar = frame and frame.TopBar
    if (not topBar) then return end

    if (not topBar.exuiSkinned) then
        topBar.exuiSkinned = true
        skins:StripTexture(topBar)
    end

    local th = GetTheme()
    topBar:SetTexture(EXUI.const.textures.frame.whiteTextured)
    topBar:SetTextureSliceMargins(SPELLBOOK_TOPBAR_SLICE, SPELLBOOK_TOPBAR_SLICE, SPELLBOOK_TOPBAR_SLICE,
        SPELLBOOK_TOPBAR_SLICE)
    topBar:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    topBar:SetTexCoord(0, 1, 0, 1)
    topBar:SetVertexColor(unpack(th.backgroundLight))
    topBar:SetAlpha(1)
    topBar:Show()
end

local function ApplyCategoryTabSystemLayout(frame)
    local tabSystem = frame and frame.CategoryTabSystem
    if (not tabSystem) then return end

    tabSystem:ClearAllPoints()
    tabSystem:SetPoint('TOPLEFT', frame, 'TOPLEFT', CATEGORY_TAB_X, CATEGORY_TAB_Y)
end

local function ApplySpellBookBookBackgrounds(frame)
    if (not frame) then return end

    for _, key in ipairs(SPELLBOOK_BOOK_BG_KEYS) do
        local texture = frame[key]
        if (texture) then
            texture:SetVertexColor(unpack(SPELLBOOK_BOOK_BG_COLOR))
        end
    end
end

local function ApplySpellBookFontText(fontString, size, color)
    if (not fontString) then return end

    local alpha = fontString:GetAlpha()
    fontString:SetFont(EXUI.const.fonts.DEFAULT, size, 'OUTLINE')
    fontString:SetTextColor(unpack(color))
    fontString:SetAlpha(alpha)
end

local function ApplySpellBookItemVisuals(item)
    if (not item) then return end

    local button = item.Button
    if (button and button.Border) then
        button.Border:SetVertexColor(unpack(SPELLBOOK_ABILITY_BORDER_COLOR))
    end

    ApplySpellBookFontText(item.Name, SPELLBOOK_NAME_TEXT_SIZE, SPELLBOOK_SPELL_TEXT_COLOR)
    ApplySpellBookFontText(item.SubName, SPELLBOOK_SUBTEXT_SIZE, SPELLBOOK_SPELL_TEXT_COLOR)
    ApplySpellBookFontText(item.RequiredLevel, SPELLBOOK_SUBTEXT_SIZE, SPELLBOOK_SPELL_TEXT_COLOR)
end

local function ApplySpellBookHeaderVisuals(header)
    if (not header) then return end

    if (header.Backplate) then
        header.Backplate:SetVertexColor(unpack(SPELLBOOK_HEADER_BACKPLATE_COLOR))
        header.Backplate:SetAlpha(SPELLBOOK_HEADER_BACKPLATE_ALPHA)
    end

    ApplySpellBookFontText(header.Text, SPELLBOOK_HEADER_TEXT_SIZE, SPELLBOOK_HEADER_TEXT_COLOR)
end

local function InstallSpellBookContentHooks()
    if (playerSpellsSkin.spellBookContentHooksInstalled) then return end
    playerSpellsSkin.spellBookContentHooksInstalled = true

    hooksecurefunc(SpellBookItemMixin, 'UpdateVisuals', function(item)
        ApplySpellBookItemVisuals(item)
    end)

    hooksecurefunc(SpellBookHeaderMixin, 'Init', function(header)
        ApplySpellBookHeaderVisuals(header)
    end)
end

local function SkinSpellBookFrame(frame)
    if (not frame) then return end

    ApplySpellBookTopBar(frame)
    ApplyCategoryTabSystemLayout(frame)
    ApplySpellBookBookBackgrounds(frame)
    InstallSpellBookContentHooks()
    SkinTabSystem(frame.CategoryTabSystem, false)

    if (frame.exuiChromeSkinned) then return end
    frame.exuiChromeSkinned = true

    if (frame.SearchBox) then
        skins:SkinSearchBox(frame.SearchBox)
    end

    SkinSpellBookSearchPreview(frame)

    if (frame.PagedSpellsFrame and frame.PagedSpellsFrame.PagingControls) then
        SkinPagingControls(frame.PagedSpellsFrame.PagingControls)
    end
end

local function AdjustTitleBarLayout(frame)
    local titleContainer = frame.TitleContainer
    if (titleContainer and not titleContainer.exuiAdjusted) then
        titleContainer.exuiAdjusted = true
        titleContainer:ClearAllPoints()
        titleContainer:SetPoint('TOPLEFT', frame, 'TOPLEFT', 16, -1)
        titleContainer:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -60, -1)
    end
end

local HEADER_HEIGHT = 26

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

function playerSpellsSkin:RefreshTabs()
    local frame = PlayerSpellsFrame
    if (not frame) then return end

    RefreshTabSystemVisuals(frame.TabSystem)
    if (frame.SpellBookFrame) then
        RefreshTabSystemVisuals(frame.SpellBookFrame.CategoryTabSystem)
    end
end

function playerSpellsSkin:SkinFrame()
    local frame = PlayerSpellsFrame
    if (not frame) then return end

    skins:SkinPanelFrame(frame, {
        hidePortrait = true,
        titleSize = TITLE_SIZE,
        backdropAlpha = PANEL_BG_ALPHA,
    })

    SkinHeaderBackdrop(frame)
    AdjustTitleBarLayout(frame)

    local maxMin = frame.MaximizeMinimizeButton
    if (maxMin) then
        SkinMaxMinButton(maxMin.MaximizeButton, 'maximize')
        SkinMaxMinButton(maxMin.MinimizeButton, 'minimize')
    end

    SkinTabSystem(frame.TabSystem, true)
    SkinTalentsFrame(frame.TalentsFrame)
    SkinSpecFrame(frame.SpecFrame)
    SkinSpellBookFrame(frame.SpellBookFrame)

    SkinLoadoutDialog(ClassTalentLoadoutImportDialog)
    SkinLoadoutDialog(ClassTalentLoadoutEditDialog)
    SkinLoadoutDialog(ClassTalentLoadoutCreateDialog)
    SkinHeroTalentsDialog(HeroTalentsSelectionDialog)

    self:RefreshTabs()
end

function playerSpellsSkin:InstallTabHooks()
    if (self.tabHooksInstalled) then return end
    self.tabHooksInstalled = true

    hooksecurefunc(TabSystemButtonArtMixin, 'SetTabSelected', function(tab, isSelected)
        if (not tab.exuiTabSkinned) then return end
        -- Blizzard disables the selected tab which hides/dims the label.
        if (isSelected) then
            tab:Enable()
        end
        ApplyTabVisualState(tab)
    end)

    hooksecurefunc(TabSystemMixin, 'SetTabVisuallySelected', function(tabSystem)
        if (not tabSystem.exuiSkinned) then return end
        RefreshTabSystemVisuals(tabSystem)
    end)

    hooksecurefunc(TabSystemOwnerMixin, 'SetTab', function(owner)
        local tabSystem = owner.tabSystem
        if (tabSystem and tabSystem.exuiSkinned) then
            RefreshTabSystemVisuals(tabSystem)
        end
    end)

    hooksecurefunc(TabSystemButtonMixin, 'OnClick', function(tab)
        local tabSystem = tab:GetTabSystem()
        if (not tabSystem or not tabSystem.exuiSkinned) then return end
        RefreshTabSystemVisuals(tabSystem)
    end)

    hooksecurefunc(TabSystemButtonMixin, 'SetTabEnabled', function(tab)
        if (tab.exuiTabSkinned) then
            ApplyTabVisualState(tab)
        end
    end)

    hooksecurefunc(TabSystemButtonMixin, 'UpdateTabWidth', function(tab)
        if (tab.exuiTabSkinned) then
            UpdateExuiTabWidth(tab)
        end
    end)

    hooksecurefunc(TabSystemMixin, 'AddTab', function(tabSystem)
        if (not tabSystem.exuiSkinned) then return end
        local tab = tabSystem.tabs and tabSystem.tabs[#tabSystem.tabs]
        SkinTabButton(tab, not tabSystem.exuiTopTab)
        UpdateExuiTabWidth(tab)
    end)
end

function playerSpellsSkin:InstallHooks()
    if (self.hooksInstalled) then return end
    self.hooksInstalled = true

    self:InstallTabHooks()

    hooksecurefunc(PlayerSpellsFrame, 'SetMinimized', function()
        self:SkinFrame()
    end)

    if (PlayerSpellsFrame.SpellBookFrame) then
        hooksecurefunc(PlayerSpellsFrame.SpellBookFrame, 'SetMinimized', function(spellBook)
            ApplySpellBookTopBar(spellBook)
            ApplyCategoryTabSystemLayout(spellBook)
            ApplySpellBookBookBackgrounds(spellBook)
        end)

        if (not PlayerSpellsFrame.SpellBookFrame.exuiShowHooked) then
            PlayerSpellsFrame.SpellBookFrame.exuiShowHooked = true
            PlayerSpellsFrame.SpellBookFrame:HookScript('OnShow', function(spellBook)
                ApplyCategoryTabSystemLayout(spellBook)
                ApplySpellBookBookBackgrounds(spellBook)
                SkinTabSystem(spellBook.CategoryTabSystem, false)
                RefreshTabSystemVisuals(spellBook.CategoryTabSystem)
            end)
        end
    end

    hooksecurefunc(PlayerSpellsFrame, 'SetTab', function(frame)
        local spellBook = frame.SpellBookFrame
        if (spellBook and spellBook:IsShown() and spellBook.CategoryTabSystem) then
            SkinTabSystem(spellBook.CategoryTabSystem, false)
            RefreshTabSystemVisuals(spellBook.CategoryTabSystem)
        end
    end)

    if (not PlayerSpellsFrame.exuiShowHooked) then
        PlayerSpellsFrame.exuiShowHooked = true
        PlayerSpellsFrame:HookScript('OnShow', function()
            playerSpellsSkin:RefreshTabs()
        end)
    end
end

function playerSpellsSkin:Install()
    if (self.installed or not PlayerSpellsFrame) then return end
    self.installed = true

    self:InstallHooks()
    self:SkinFrame()
end

playerSpellsSkin.Init = function(self)
    if (not skins:IsEnabled('PlayerSpells')) then return end

    if (PlayerSpellsFrame) then
        self:Install()
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-PlayerSpells', function(_, addon)
        if (addon ~= 'Blizzard_PlayerSpells') then return end
        self:Install()
    end)
end
