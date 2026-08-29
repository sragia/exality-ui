---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIBagsWindow
local window = EXUI:GetModule('bags-window')

---@class EXUIBags
local bags

---@class EXUIBagsSlots
local slots = EXUI:GetModule('bags-slots')

---@class EXUIBagsViews
local views = EXUI:GetModule('bags-views')

---@class EXUIBagsPins
local pins = EXUI:GetModule('bags-pins')

local TAB_WIDTH = 92
local TAB_HEIGHT = 26
local TAB_GAP = 2
local HEADER_HEIGHT = 40
local FOOTER_HEIGHT = 32
local PAD = 10
local CLIP_INSET = 2
local SCROLL_GUTTER = 16
local BAR_GAP = 5
local SLICE = 16
local MAX_CURRENCIES = 8

local TABS = {
    { id = 'bags', label = 'Bags' },
    { id = 'gear', label = 'Gear' },
    { id = 'consumables', label = 'Consumables' },
    { id = 'reagents', label = 'Reagents' },
    { id = 'quest', label = 'Quest' },
}

window.frame = nil
window.activeTab = 'bags'
window.layoutSignature = nil
window.tabButtons = {}
window.currencyButtons = {}
window.crestButtons = {}

local function GetBags()
    bags = bags or EXUI:GetModule('bags')
    return bags
end

local function ApplyPanelTextures(frame)
    local bg = frame:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetTexture(EXUI.const.textures.bags.bg)
    bg:SetTextureSliceMargins(SLICE, SLICE, SLICE, SLICE)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    frame.Background = bg

    local border = frame:CreateTexture(nil, 'BORDER')
    border:SetAllPoints()
    border:SetTexture(EXUI.const.textures.bags.border)
    border:SetTextureSliceMargins(SLICE, SLICE, SLICE, SLICE)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    frame.Border = border
end

local function StyleTab(button, active, hovered)
    local theme = EXUI.const.theme
    button.Glow:Show()
    if active then
        button.Glow:SetVertexColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.85)
        button.Line:SetColorTexture(1, 1, 1, 1)
        button.Label:SetTextColor(1, 1, 1, 1)
    else
        button.Glow:SetVertexColor(theme.background[1], theme.background[2], theme.background[3], 1)
        local r, g, b = unpack(theme.border)
        button.Line:SetColorTexture(r, g, b, 1)
        if hovered then
            button.Label:SetTextColor(1, 1, 1, 1)
        else
            button.Label:SetTextColor(unpack(theme.textMuted))
        end
    end
end

window.CreateTabs = function(self, parent)
    local lineWidth = EXUI:ScalePixels(1, parent)
    for i, tab in ipairs(TABS) do
        local button = CreateFrame('Button', nil, parent)
        button:SetSize(TAB_WIDTH, TAB_HEIGHT)
        button.tabID = tab.id

        local glow = button:CreateTexture(nil, 'BACKGROUND')
        button.Glow = glow
        glow:SetAllPoints()
        glow:SetTexture(EXUI.const.textures.bags.glow)

        local label = button:CreateFontString(nil, 'OVERLAY')
        button.Label = label
        label:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        label:SetPoint('RIGHT', -8, 0)
        label:SetJustifyH('RIGHT')
        label:SetText(tab.label)

        local line = button:CreateTexture(nil, 'OVERLAY')
        button.Line = line
        line:SetWidth(lineWidth)
        line:SetPoint('TOPRIGHT')
        line:SetPoint('BOTTOMRIGHT')

        button:SetScript('OnClick', function()
            self:SetTab(tab.id)
        end)
        button:SetScript('OnEnter', function()
            StyleTab(button, self.activeTab == tab.id, true)
        end)
        button:SetScript('OnLeave', function()
            StyleTab(button, self.activeTab == tab.id, false)
        end)

        if i == 1 then
            button:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
        else
            button:SetPoint('TOPLEFT', self.tabButtons[i - 1], 'BOTTOMLEFT', 0, -TAB_GAP)
        end

        self.tabButtons[i] = button
        StyleTab(button, tab.id == self.activeTab, false)
    end
end

window.UpdateTabs = function(self)
    for i = 1, #self.tabButtons do
        local button = self.tabButtons[i]
        StyleTab(button, button.tabID == self.activeTab, false)
    end
end

window.SetTab = function(self, tabID)
    if self.activeTab == tabID then
        return
    end
    self.activeTab = tabID
    self:UpdateTabs()
    GetBags():Refresh()
end

window.CreateBagBar = function(self, parent)
    local bar = CreateFrame('Frame', nil, parent)
    self.bagBar = bar
    bar:SetPoint('TOPLEFT', PAD, 0)
    bar:SetPoint('BOTTOMRIGHT', -PAD, 0)

    slots:CreateBagBar(bar)

    local sortBtn = CreateFrame('Button', nil, bar)
    self.sortButton = sortBtn
    sortBtn:SetPoint('RIGHT', 0, 0)

    local muted = EXUI.const.theme.textMuted

    local label = sortBtn:CreateFontString(nil, 'OVERLAY')
    sortBtn.Label = label
    label:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    label:SetPoint('LEFT')
    label:SetText('Sort')
    label:SetTextColor(unpack(muted))

    local icon = sortBtn:CreateTexture(nil, 'ARTWORK')
    sortBtn.Icon = icon
    icon:SetTexture(EXUI.const.textures.bags.sort)
    icon:SetPoint('LEFT', label, 'RIGHT', 4, 0)
    icon:SetSize(18, 18)
    icon:SetVertexColor(unpack(muted))

    sortBtn:SetScript('OnClick', function()
        C_Container.SortBags()
    end)
    sortBtn:SetScript('OnEnter', function()
        icon:SetVertexColor(1, 1, 1, 1)
        label:SetTextColor(1, 1, 1, 1)
    end)
    sortBtn:SetScript('OnLeave', function()
        icon:SetVertexColor(unpack(muted))
        label:SetTextColor(unpack(muted))
    end)

    self.searchBox = slots:CreateSearchBox(bar, 'bags')
    self.searchBox:SetPoint('RIGHT', sortBtn, 'LEFT', -10, 0)
end

window.LayoutBagBar = function(self, bagSize, spacing)
    local buttons = slots.bagButtons
    local x = 0
    for i = 1, #buttons do
        local button = buttons[i]
        if button.isReagent and i > 1 then
            x = x + 6
        end
        button:SetSize(bagSize, bagSize)
        button:ClearAllPoints()
        button:SetPoint('LEFT', self.bagBar, 'LEFT', x, 0)
        x = x + bagSize + spacing
    end
    slots:UpdateBagBar()

    local iconSize = math.max(12, bagSize - 8)
    self.sortButton.Icon:SetSize(iconSize, iconSize)
    local textWidth = self.sortButton.Label:GetStringWidth()
    self.sortButton:SetSize(iconSize + 4 + textWidth, bagSize)

    local searchHeight = math.max(20, bagSize)
    self.searchBox:SetSize(150, searchHeight)
end

local function FormatMoney(copper)
    copper = copper or 0
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperLeft = copper % 100
    return string.format(
        '%s|cffffd100g|r %d|cffc7c7cfs|r %d|cffeda55fc|r',
        EXUI.utils.formatNumberWithCommas(gold),
        silver,
        copperLeft
    )
end

window.CreateFooter = function(self, parent)
    local footer = CreateFrame('Frame', nil, parent)
    self.footerContent = footer
    footer:SetPoint('TOPLEFT', PAD, 0)
    footer:SetPoint('BOTTOMRIGHT', -PAD, 0)

    local gold = footer:CreateFontString(nil, 'OVERLAY')
    self.goldText = gold
    gold:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    gold:SetPoint('LEFT', 0, 0)
    gold:SetTextColor(unpack(EXUI.const.theme.text))

    local function CreateCurrencyButton()
        local button = CreateFrame('Button', nil, footer)
        button:SetSize(16, 16)

        local icon = button:CreateTexture(nil, 'ARTWORK')
        button.Icon = icon
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local count = button:CreateFontString(nil, 'OVERLAY')
        button.Count = count
        count:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
        count:SetPoint('LEFT', button, 'RIGHT', 4, 0)
        count:SetTextColor(unpack(EXUI.const.theme.text))

        button:SetScript('OnEnter', function()
            if button.currencyID then
                GameTooltip:SetOwner(button, 'ANCHOR_TOP')
                GameTooltip:SetCurrencyByID(button.currencyID)
                GameTooltip:Show()
            end
        end)
        button:SetScript('OnLeave', function()
            GameTooltip:Hide()
        end)
        return button
    end

    for i = 1, #EXUI.const.crestCurrencyIDs do
        local button = CreateCurrencyButton()
        button.currencyID = EXUI.const.crestCurrencyIDs[i]
        self.crestButtons[i] = button
    end

    for i = 1, MAX_CURRENCIES do
        local button = CreateCurrencyButton()
        button:Hide()
        self.currencyButtons[i] = button
    end
end

local CURRENCY_ICON = 16
local CURRENCY_TEXT_GAP = 4
local CURRENCY_GAP = 12

local function CurrencyWidth(button)
    return CURRENCY_ICON + CURRENCY_TEXT_GAP + (button.Count:GetStringWidth() or 0)
end

local function IsCrestCurrency(currencyID)
    local ids = EXUI.const.crestCurrencyIDs
    for i = 1, #ids do
        if ids[i] == currencyID then
            return true
        end
    end
    return false
end

window.UpdateFooter = function(self)
    self.goldText:SetText(FormatMoney(GetMoney()))

    local left = self.goldText:GetStringWidth() + CURRENCY_GAP
    for i = 1, #self.crestButtons do
        local button = self.crestButtons[i]
        local info = C_CurrencyInfo.GetCurrencyInfo(button.currencyID)
        if info then
            button.Icon:SetTexture(info.iconFileID)
            button.Count:SetText(EXUI.utils.formatNumberWithCommas(info.quantity or 0))
        else
            button.Count:SetText('0')
        end
        button:Show()
        button:ClearAllPoints()
        button:SetPoint('LEFT', self.footerContent, 'LEFT', left, 0)
        left = left + CurrencyWidth(button) + CURRENCY_GAP
    end

    local shown = 0
    local i = 1
    while shown < MAX_CURRENCIES do
        local info = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
        if not info then
            break
        end
        i = i + 1
        if not IsCrestCurrency(info.currencyTypesID) then
            shown = shown + 1
            local button = self.currencyButtons[shown]
            button.currencyID = info.currencyTypesID
            button.Icon:SetTexture(info.iconFileID)
            button.Count:SetText(EXUI.utils.formatNumberWithCommas(info.quantity or 0))
            button:Show()
        end
    end

    for j = shown + 1, MAX_CURRENCIES do
        self.currencyButtons[j]:Hide()
        self.currencyButtons[j].currencyID = nil
    end

    local right = 0
    for j = shown, 1, -1 do
        local button = self.currencyButtons[j]
        local countWidth = button.Count:GetStringWidth() or 0
        button:ClearAllPoints()
        button:SetPoint('RIGHT', self.footerContent, 'RIGHT', -(right + CURRENCY_TEXT_GAP + countWidth), 0)
        right = right + CurrencyWidth(button) + CURRENCY_GAP
    end
end

window.Create = function(self)
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame('Frame', 'EXUIBagsFrame', UIParent)
    self.frame = frame
    frame:SetSize(480, 320)
    frame:SetFrameStrata('HIGH')
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:Hide()
    frame:SetAlpha(0)

    local main = CreateFrame('Frame', nil, frame)
    self.main = main
    main:SetPoint('TOPLEFT', TAB_WIDTH, 0)
    main:SetPoint('BOTTOMRIGHT')
    main:EnableMouse(true)
    main:RegisterForDrag('LeftButton')

    local function startDrag()
        frame:StartMoving()
    end
    local function stopDrag()
        frame:StopMovingOrSizing()
        self:SavePosition()
    end
    frame:SetScript('OnDragStart', startDrag)
    frame:SetScript('OnDragStop', stopDrag)
    main:SetScript('OnDragStart', startDrag)
    main:SetScript('OnDragStop', stopDrag)

    local header = CreateFrame('Frame', nil, main)
    self.header = header
    header:SetHeight(HEADER_HEIGHT)
    header:SetPoint('TOPLEFT')
    header:SetPoint('TOPRIGHT')
    ApplyPanelTextures(header)
    header:EnableMouse(true)
    header:RegisterForDrag('LeftButton')
    header:SetScript('OnDragStart', startDrag)
    header:SetScript('OnDragStop', stopDrag)

    local body = CreateFrame('Frame', nil, main)
    self.body = body
    body:SetPoint('TOPLEFT', header, 'BOTTOMLEFT', 0, -BAR_GAP)
    body:SetPoint('TOPRIGHT', header, 'BOTTOMRIGHT', 0, -BAR_GAP)
    body:SetPoint('BOTTOMLEFT', 0, FOOTER_HEIGHT + BAR_GAP)
    body:SetPoint('BOTTOMRIGHT', 0, FOOTER_HEIGHT + BAR_GAP)
    ApplyPanelTextures(body)
    body:EnableMouse(true)
    body:RegisterForDrag('LeftButton')
    body:SetScript('OnDragStart', startDrag)
    body:SetScript('OnDragStop', stopDrag)

    local footer = CreateFrame('Frame', nil, main)
    self.footer = footer
    footer:SetHeight(FOOTER_HEIGHT)
    footer:SetPoint('BOTTOMLEFT')
    footer:SetPoint('BOTTOMRIGHT')
    ApplyPanelTextures(footer)
    footer:EnableMouse(true)
    footer:RegisterForDrag('LeftButton')
    footer:SetScript('OnDragStart', startDrag)
    footer:SetScript('OnDragStop', stopDrag)

    self.tabs = CreateFrame('Frame', nil, frame)
    self.tabs:SetWidth(TAB_WIDTH)
    self.tabs:SetPoint('TOPLEFT', 0, -HEADER_HEIGHT - BAR_GAP - PAD)
    self.tabs:SetPoint('BOTTOMLEFT', 0, FOOTER_HEIGHT + BAR_GAP)
    self:CreateTabs(self.tabs)

    self:CreateBagBar(header)

    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    self.scroll = scroll
    scroll:SetParent(body)
    scroll:ClearAllPoints()
    scroll:SetPoint('TOPLEFT', 0, -(PAD - CLIP_INSET))
    scroll:SetPoint('BOTTOMRIGHT', -(PAD - CLIP_INSET), PAD - CLIP_INSET)
    self.content = scroll.child
    self.content:EnableMouseWheel(true)
    self.content:SetScript('OnMouseWheel', scroll:GetScript('OnMouseWheel'))

    self.pinRail = CreateFrame('Frame', nil, frame)
    self.pinRail:SetWidth(40)
    self.pinRail:SetPoint('TOPLEFT', body, 'TOPRIGHT', 6, 0)
    self.pinRail:SetPoint('BOTTOMLEFT', body, 'BOTTOMRIGHT', 6, 0)

    self:CreateFooter(footer)
    views:CreateHeaders(self.content)
    pins:Create(self.pinRail)
    slots:EnsurePool(self.content)

    frame.fadeIn = EXFrames.utils.animation.fade(frame, 0.15, 0, 1)
    frame.fadeOut = EXFrames.utils.animation.fade(frame, 0.12, 1, 0)
    EXFrames.utils.animation.diveIn(frame, 0.15, 0, 12, 'IN', frame.fadeIn)
    frame.fadeOut:SetScript('OnFinished', function()
        frame:Hide()
        frame:SetAlpha(0)
    end)

    frame:SetScript('OnShow', function()
        GetBags():OnShown()
    end)
    frame:SetScript('OnHide', function()
        GetBags():OnHidden()
    end)

    tinsert(UISpecialFrames, 'EXUIBagsFrame')
    self:RestorePosition()
    return frame
end

window.GetTabStackHeight = function(self)
    return #TABS * TAB_HEIGHT + (#TABS - 1) * TAB_GAP
end

window.GetContentWidth = function(self, layout)
    return layout.columns * layout.slotSize + (layout.columns - 1) * layout.spacing
end

window.GetChildWidth = function(self, layout)
    return PAD + self:GetContentWidth(layout) + CLIP_INSET
end

window.GetScrollGutter = function(self)
    local scroll = self.scroll
    if not scroll then
        return SCROLL_GUTTER
    end
    local barSpace = (scroll.scrollbarWidth or 4) + (scroll.scrollbarPadding or 2) * 2
    return math.max(SCROLL_GUTTER, barSpace + 8)
end

window.ApplySize = function(self, bagsHeight, pinWidth)
    local layout = GetBags():GetLayoutSettings()
    local contentWidth = self:GetContentWidth(layout)
    local mainWidth = contentWidth + PAD * 2 + self:GetScrollGutter()
    local bodyInner = math.max(bagsHeight, self:GetTabStackHeight())
    local height = HEADER_HEIGHT + BAR_GAP + bodyInner + PAD * 2 + BAR_GAP + FOOTER_HEIGHT

    self.pinRail:Show()
    self.pinRail:SetWidth(math.max(pinWidth, 1))

    local totalWidth = TAB_WIDTH + mainWidth + 6 + pinWidth
    self.frame:SetSize(totalWidth, height)
    self.main:ClearAllPoints()
    self.main:SetPoint('TOPLEFT', TAB_WIDTH, 0)
    self.main:SetPoint('BOTTOMRIGHT', -(6 + pinWidth), 0)
    self:ClampToScreen()

    local bagSize = math.max(20, math.floor(layout.slotSize * 0.62))
    self:LayoutBagBar(bagSize, math.max(2, math.floor(layout.spacing * 0.75)))
end

window.ClampToScreen = function(self)
    local left, bottom, width, height = self.frame:GetRect()
    if not left then
        return
    end
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    if left < 0 then
        left = 0
    end
    if bottom < 0 then
        bottom = 0
    end
    if left + width > screenW then
        left = screenW - width
    end
    if bottom + height > screenH then
        bottom = screenH - height
    end
    self.frame:ClearAllPoints()
    self.frame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', left, bottom)
end

window.SavePosition = function(self)
    if not self.frame or not self.frame:GetLeft() then
        return
    end
    local left, bottom = self.frame:GetLeft(), self.frame:GetBottom()
    GetBags().Data:SetValue('posX', left)
    GetBags().Data:SetValue('posY', bottom)
end

window.RestorePosition = function(self)
    local x = GetBags().Data:GetValue('posX')
    local y = GetBags().Data:GetValue('posY')
    self.frame:ClearAllPoints()
    if x and y then
        self.frame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', x, y)
    else
        self.frame:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -80, 140)
    end
end

window.GetLayoutSignature = function(self)
    local layout = GetBags():GetLayoutSettings()
    local parts = { self.activeTab, layout.slotSize, layout.columns, layout.spacing }
    for bag = Enum.BagIndex.Backpack, Enum.BagIndex.ReagentBag do
        parts[#parts + 1] = C_Container.GetContainerNumSlots(bag) or 0
    end
    return table.concat(parts, ':')
end

window.NeedsLayout = function(self)
    if not self.layoutSignature or self.activeTab ~= 'bags' then
        return true
    end
    return self.layoutSignature ~= self:GetLayoutSignature()
end

window.RefreshContents = function(self)
    slots:UpdateVisible()
    slots:UpdateBagBar()
    local layout = GetBags():GetLayoutSettings()
    pins:Layout(self.pinRail, layout.slotSize, layout.spacing)
    self:UpdateFooter()
end

window.LayoutIfNeeded = function(self)
    if self:NeedsLayout() then
        self:Layout()
    else
        self:RefreshContents()
    end
end

window.Layout = function(self)
    if not self.frame then
        return
    end
    local layout = GetBags():GetLayoutSettings()
    if self.laidOutTab ~= self.activeTab and self.scroll then
        self.scroll:SetVerticalScroll(0)
        self.laidOutTab = self.activeTab
    end
    local contentHeight = views:Layout(self.content, self.activeTab)
    local pinWidth = pins:Layout(self.pinRail, layout.slotSize, layout.spacing)
    local bagsHeight = views:MeasureBagsHeight()
    self:ApplySize(bagsHeight, pinWidth)
    if self.scroll then
        self.content:SetHeight(math.max(contentHeight, 1))
        self.scroll:UpdateScrollChild(self:GetChildWidth(layout), math.max(contentHeight, 1))
    end
    self:UpdateFooter()
    self.layoutSignature = self:GetLayoutSignature()
end

window.Show = function(self)
    self:Create()
    if self.frame:IsShown() then
        self.frame.fadeOut:Stop()
        self.frame:SetAlpha(1)
        self:LayoutIfNeeded()
        return
    end
    self.frame.fadeOut:Stop()
    self.frame:SetAlpha(0)
    self.frame:Show()
    self:LayoutIfNeeded()
    self.frame.fadeIn:Play()
end

window.Hide = function(self, immediate)
    if not self.frame or not self.frame:IsShown() then
        return
    end
    self.frame.fadeIn:Stop()
    if self.searchBox then
        self.searchBox:ClearFocus()
        self.searchBox:SetText('')
    end
    if immediate then
        self.frame:Hide()
        self.frame:SetAlpha(0)
        return
    end
    self.frame.fadeOut:Play()
end

window.IsShown = function(self)
    return self.frame and self.frame:IsShown()
end
