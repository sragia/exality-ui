---@class ExalityUI
local EXUI = select(2, ...)

local EXFrames = EXUI.EXFrames

---@class EXUIChatUtil
local util = EXUI:GetModule('chat-util')

---@class EXUIChatFormat
local formatter = EXUI:GetModule('chat-format')

---@class EXUIChatHistory
local history = EXUI:GetModule('chat-history')

---@class EXUIChatMessages
local messages = EXUI:GetModule('chat-messages')

---@class EXUIChatComposer
local composer = EXUI:GetModule('chat-composer')

---@class EXUIChatWindow
local window = EXUI:GetModule('chat-window')

---@class EXUIChatPanels
local panels = EXUI:GetModule('chat-panels')

local Chat = util.Chat
local FontPath = util.FontPath
local IsSecret = util.IsSecret

local DELETE_ICON = 'Interface/Addons/ExalityUI/Assets/Images/Talents/delete-icon.png'
local LINE_RECT = { 7, 213, 70, 214 }
local GLOW_RECT = { 7, 231, 69, 259 }
local GLOW_HEIGHT = 20

panels.tabButtons = {}

local function TabColor(tab)
    local color = tab and tab.color
    if type(color) == 'table' then
        return color.r or 1, color.g or 0.5, color.b or 0.25
    end
    if DEFAULT_TAB_SELECTED_COLOR_TABLE then
        local fallback = DEFAULT_TAB_SELECTED_COLOR_TABLE
        return fallback.r or 1, fallback.g or 0.5, fallback.b or 0.25
    end
    return 1, 0.5, 0.25
end

local function MutedColor()
    local muted = EXFrames.Theme and EXFrames.Theme.textMuted
    if muted then
        return muted[1], muted[2], muted[3]
    end
    return 0.54, 0.50, 0.46
end

----------------------------------------------------------------
-- Tab bar
----------------------------------------------------------------

local function PlaceTabDecor(button)
    local line = button.line
    local glow = button.glow
    local label = button.label
    local tabTop = Chat():GetTabSide() ~= 'bottom'
    local left = GLOW_RECT[1] / util.SHEET
    local right = (GLOW_RECT[3] + 1) / util.SHEET
    local top = GLOW_RECT[2] / util.SHEET
    local bottom = (GLOW_RECT[4] + 1) / util.SHEET
    line:ClearAllPoints()
    glow:ClearAllPoints()
    label:ClearAllPoints()
    line:SetHeight(EXUI:ScalePixels(2, button))
    glow:SetHeight(GLOW_HEIGHT)
    if tabTop then
        line:SetPoint('BOTTOMLEFT', button, 'BOTTOMLEFT', 0, 0)
        line:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 0, 0)
        glow:SetPoint('BOTTOMLEFT', line, 'TOPLEFT', 0, 0)
        glow:SetPoint('BOTTOMRIGHT', line, 'TOPRIGHT', 0, 0)
        glow:SetTexCoord(left, right, bottom, top)
        label:SetPoint('BOTTOM', line, 'TOP', 0, EXUI:ScalePixels(1, button))
    else
        line:SetPoint('TOPLEFT', button, 'TOPLEFT', 0, 0)
        line:SetPoint('TOPRIGHT', button, 'TOPRIGHT', 0, 0)
        glow:SetPoint('TOPLEFT', line, 'BOTTOMLEFT', 0, 0)
        glow:SetPoint('TOPRIGHT', line, 'BOTTOMRIGHT', 0, 0)
        glow:SetTexCoord(left, right, top, bottom)
        label:SetPoint('TOP', line, 'BOTTOM', 0, -EXUI:ScalePixels(5, button))
    end
    local pulse = button.pulse
    pulse:ClearAllPoints()
    pulse:SetAllPoints(glow)
    if tabTop then
        pulse:SetTexCoord(left, right, bottom, top)
    else
        pulse:SetTexCoord(left, right, top, bottom)
    end
end

local function CreateTabPulse(button)
    local pulse = button:CreateTexture(nil, 'BACKGROUND', nil, -7)
    pulse:SetTexture(util.SPRITE)
    pulse:SetBlendMode('ADD')
    pulse:SetHeight(GLOW_HEIGHT)
    pulse:Hide()
    local group = button:CreateAnimationGroup()
    group:SetLooping('BOUNCE')
    local fade = group:CreateAnimation('Alpha')
    fade:SetTarget(pulse)
    fade:SetFromAlpha(0.2)
    fade:SetToAlpha(0.85)
    fade:SetDuration(0.7)
    fade:SetSmoothing('IN_OUT')
    button.pulse = pulse
    button.pulseGroup = group
end

local function SyncTabPulse(button, tab, selected)
    local pulse = button.pulse
    local group = button.pulseGroup
    local unread = not selected and history.whisperTabs and history.whisperTabs[tab.id]
    if not unread then
        if group:IsPlaying() then
            group:Stop()
        end
        pulse:Hide()
        return
    end
    local cr, cg, cb = TabColor(tab)
    pulse:SetVertexColor(cr, cg, cb, 1)
    pulse:Show()
    if not group:IsPlaying() then
        group:Play()
    end
end

local function ApplyTabHoverState(button)
    local glowAlpha
    if button.selected then
        glowAlpha = button.hovered and 1 or 0.85
    else
        glowAlpha = button.hovered and 0.55 or 0.28
    end
    button.glow:SetAlpha(glowAlpha)
    if button.selected or button.hovered then
        button.label:SetTextColor(Chat():GetActiveTabTextColor())
    else
        button.label:SetTextColor(Chat():GetInactiveTabTextColor())
    end
end

local function CreateTabButton(tabBar)
    local button = CreateFrame('Button', nil, tabBar)
    button:SetHeight(22)
    local line = button:CreateTexture(nil, 'BORDER', nil, 2)
    util.ApplySprite(line, LINE_RECT)
    line:SetPoint('BOTTOMLEFT', button, 'BOTTOMLEFT', 0, 0)
    line:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 0, 0)
    line:SetHeight(EXUI:ScalePixels(2, button))
    button.line = line
    local glow = button:CreateTexture(nil, 'BACKGROUND', nil, -8)
    glow:SetTexture(util.SPRITE)
    glow:SetHeight(GLOW_HEIGHT)
    button.glow = glow
    CreateTabPulse(button)
    local label = button:CreateFontString(nil, 'OVERLAY')
    label:SetDrawLayer('OVERLAY', 7)
    label:SetFont(FontPath(), 12, 'OUTLINE')
    label:SetJustifyH('CENTER')
    button.label = label
    button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    button:RegisterForDrag('LeftButton')
    button:SetScript('OnEnter', function(self)
        self.hovered = true
        ApplyTabHoverState(self)
    end)
    button:SetScript('OnLeave', function(self)
        self.hovered = false
        ApplyTabHoverState(self)
    end)
    button:SetScript('OnDragStart', function(self)
        panels:BeginTabDrag(self.tab)
    end)
    button:SetScript('OnClick', function(self, mouseButton)
        local suppressed = panels.suppressTabClick
        if mouseButton ~= 'RightButton' and type(suppressed) == 'number' and GetTime() - suppressed < 0.3 then
            panels.suppressTabClick = nil
            return
        end
        panels.suppressTabClick = nil
        if mouseButton == 'RightButton' then
            panels:OpenTabMenu(self)
        else
            panels:SelectTab(self.tab)
        end
    end)
    return button
end

function panels:RefreshTabs()
    local tabBar = window.tabBar
    if not tabBar then
        return
    end
    local tabs = history:EnsureTabs()
    local active = history:ActiveTab()
    local x = 5
    for index, tab in ipairs(tabs) do
        local button = self.tabButtons[index]
        if not button then
            button = CreateTabButton(tabBar)
            self.tabButtons[index] = button
        end
        button.tab = tab
        button.label:SetText(tab.name or 'Tab')
        local width = button.label:GetStringWidth()
        if not width or width < 8 then
            width = 8
        end
        local buttonWidth = width + 14
        button:SetWidth(buttonWidth)
        button:ClearAllPoints()
        if Chat():GetTabSide() == 'bottom' then
            button:SetPoint('TOPLEFT', tabBar, 'TOPLEFT', x, 0)
        else
            button:SetPoint('BOTTOMLEFT', tabBar, 'BOTTOMLEFT', x, 0)
        end
        x = x + buttonWidth + 10
        PlaceTabDecor(button)
        local selected = tab.id == active.id
        local cr, cg, cb = TabColor(tab)
        local lineAlpha = selected and 1 or 0.45
        button.selected = selected
        button.line:SetVertexColor(cr, cg, cb, lineAlpha)
        button.glow:SetVertexColor(cr, cg, cb, 1)
        ApplyTabHoverState(button)
        button.line:Show()
        button.glow:Show()
        SyncTabPulse(button, tab, selected)
        if window.clip then
            button:SetFrameLevel(window.clip:GetFrameLevel() + 5)
        end
        if self.dragTabId == tab.id then
            button:SetAlpha(0.55)
        else
            button:SetAlpha(1)
        end
        button:Show()
    end
    for index = #tabs + 1, #self.tabButtons do
        local extra = self.tabButtons[index]
        if extra.pulseGroup:IsPlaying() then
            extra.pulseGroup:Stop()
        end
        extra:Hide()
    end
end

function panels:BeginTabDrag(tab)
    if window:IsLocked() or not tab or not window.tabBar then
        return
    end
    self.dragTabId = tab.id
    self.suppressTabClick = GetTime()
    window.tabBar:SetScript('OnUpdate', function()
        panels:UpdateTabDrag()
    end)
end

function panels:EndTabDrag()
    if window.tabBar then
        window.tabBar:SetScript('OnUpdate', nil)
    end
    if self.dragTabId then
        history:SaveTabs()
    end
    self.dragTabId = nil
    self:RefreshTabs()
end

function panels:UpdateTabDrag()
    if not IsMouseButtonDown('LeftButton') then
        self:EndTabDrag()
        return
    end
    local id = self.dragTabId
    local tabs = history:EnsureTabs()
    local index
    for i, tab in ipairs(tabs) do
        if tab.id == id then
            index = i
            break
        end
    end
    if not index then
        self:EndTabDrag()
        return
    end
    local scale = window.tabBar:GetEffectiveScale()
    if type(scale) ~= 'number' or scale <= 0 then
        scale = 1
    end
    local cursorX = GetCursorPosition() / scale
    local function center(buttonIndex)
        local button = self.tabButtons[buttonIndex]
        if not button or not button:IsShown() then
            return nil
        end
        local x = button:GetCenter()
        if type(x) ~= 'number' then
            return nil
        end
        return x
    end
    if index > 1 then
        local previous = center(index - 1)
        if previous and cursorX < previous then
            tabs[index], tabs[index - 1] = tabs[index - 1], tabs[index]
            self:RefreshTabs()
            return
        end
    end
    if index < #tabs then
        local following = center(index + 1)
        if following and cursorX > following then
            tabs[index], tabs[index + 1] = tabs[index + 1], tabs[index]
            self:RefreshTabs()
        end
    end
end

----------------------------------------------------------------
-- Tab actions
----------------------------------------------------------------

function panels:SelectTab(tab)
    if history.whisperTabs then
        history.whisperTabs[tab.id] = nil
    end
    Chat().Data:SetValue('activeTab', tab.id)
    self:RefreshTabs()
    messages:ResetFade()
    messages:Layout()
end

function panels:AddTab()
    local tabs = history:EnsureTabs()
    local id = 1
    for _, tab in ipairs(tabs) do
        if tab.id >= id then
            id = tab.id + 1
        end
    end
    local tab = history.NewTab(id, 'Tab ' .. id)
    tabs[#tabs + 1] = tab
    history:SaveTabs()
    self:HideMenu()
    self:SelectTab(tab)
    self:OpenConfig(tab)
end

function panels:RemoveTab(tab)
    local tabs = history:EnsureTabs()
    if #tabs <= 1 then
        return
    end
    for index, entry in ipairs(tabs) do
        if entry == tab or entry.id == tab.id then
            table.remove(tabs, index)
            break
        end
    end
    history:SaveTabs()
    self:HideConfig()
    self:SelectTab(tabs[1])
end

function panels:OpenTabMenu(button)
    local tab = button and button.tab
    if not tab then
        return
    end
    self:HideConfig()
    local r, g, b = TabColor(tab)
    EXUI:GetModule('chat-menu'):ShowEntries(button, {
        {
            label = 'Edit Tab',
            sprite = 'channels',
            onClick = function()
                panels:OpenConfig(tab)
            end,
        },
        {
            label = 'Change Color',
            swatch = { r = r, g = g, b = b },
            onClick = function()
                panels:OpenColor(tab, button)
            end,
        },
    })
end

function panels:OpenColor(tab, anchor)
    self:OpenPalette(anchor, function()
        local cr, cg, cb = TabColor(tab)
        return { r = cr, g = cg, b = cb, a = 1 }
    end, function(color)
        tab.color = { r = color.r, g = color.g, b = color.b }
        history:SaveTabs()
        panels:RefreshTabs()
    end)
end

----------------------------------------------------------------
-- Color pickers
----------------------------------------------------------------

local function FlipPicker(picker)
    local popup = picker and picker.picker
    local box = picker and picker.colorBoxContainer
    if not popup or not box then
        return
    end
    local bottom = box:GetBottom()
    if IsSecret(bottom) or type(bottom) ~= 'number' then
        return
    end
    popup:ClearAllPoints()
    if bottom < 280 then
        popup:SetPoint('BOTTOMLEFT', box, 'TOPRIGHT', 4, 4)
    else
        popup:SetPoint('TOPLEFT', box, 'BOTTOMRIGHT', 4, -4)
    end
end

local function PreparePicker(picker)
    if picker.exuiFlipHook then
        return picker
    end
    hooksecurefunc(picker, 'OpenPicker', FlipPicker)
    picker.exuiFlipHook = true
    return picker
end

function panels:EnsurePicker()
    local picker = self.colorPicker
    if picker then
        return picker
    end
    picker = EXFrames:GetFrame('color-picker'):Create()
    picker:SetParent(UIParent)
    picker:SetFrameStrata('FULLSCREEN_DIALOG')
    picker:SetFrameWidth(20)
    picker:SetHeight(20)
    if picker.picker then
        picker.picker:HookScript('OnHide', function()
            if panels.colorPicker then
                panels.colorPicker:Hide()
            end
        end)
    end
    PreparePicker(picker)
    self.colorPicker = picker
    return picker
end

function panels:OpenPalette(anchor, currentValue, onChange)
    local picker = self:EnsurePicker()
    local upward = anchor and anchor.GetBottom and not IsSecret(anchor:GetBottom()) and anchor:GetBottom() < 280
    picker.onChange = nil
    picker:SetOptionData({
        label = '',
        hasOpacity = false,
        disableAlpha = true,
        currentValue = currentValue,
        onChange = onChange,
    })
    picker:ClearAllPoints()
    if anchor then
        if upward then
            picker:SetPoint('BOTTOMLEFT', anchor, 'TOPLEFT', 0, 4)
        else
            picker:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -4)
        end
    else
        picker:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
    end
    picker:Show()
    picker:OpenPicker()
    FlipPicker(picker)
end

----------------------------------------------------------------
-- Edit Tab panel
----------------------------------------------------------------

function panels:SetMessageColor(key, r, g, b)
    local colors = Chat().Data:GetValue('messageColors')
    if type(colors) ~= 'table' then
        colors = {}
    end
    colors[key] = { r = r, g = g, b = b }
    Chat().Data:SetValue('messageColors', colors)
    messages:Layout()
    if composer.editFocused then
        composer:RefreshHeader()
    end
end

function panels:HideConfig()
    local panel = self.channelWindow
    if panel and panel:IsShown() then
        panel:HideWindow()
    end
    self.configTab = nil
end

function panels:AcquireColor()
    self.colorCount = self.colorCount + 1
    local picker = self.colors[self.colorCount]
    if not picker then
        picker = EXFrames:GetFrame('color-picker'):Create()
        picker:SetParent(self.channelWindow.scroll.child)
        picker:SetFrameWidth(20)
        picker:SetHeight(20)
        PreparePicker(picker)
        self.colors[self.colorCount] = picker
    end
    picker:Show()
    return picker
end

function panels:AcquireCheck()
    self.checkCount = self.checkCount + 1
    local check = self.checks[self.checkCount]
    if not check then
        check = EXFrames:GetFrame('checkbox'):Create()
        check:SetParent(self.channelWindow.scroll.child)
        self.checks[self.checkCount] = check
    end
    check:Show()
    return check
end

local function JoinedChannels(tab)
    local found = {}
    local seen = {}
    local function Add(name)
        if type(name) ~= 'string' or name == '' or seen[name] then
            return
        end
        seen[name] = true
        found[#found + 1] = name
    end
    if GetChannelList then
        local list = { GetChannelList() }
        for _, value in ipairs(list) do
            Add(value)
        end
    end
    if type(tab.channels) == 'table' then
        for name in pairs(tab.channels) do
            Add(name)
        end
    end
    return found
end

function panels:BuildConfig()
    local tab = self.configTab
    local panel = self.channelWindow
    if not tab or not panel or self.buildingConfig then
        return
    end
    self.buildingConfig = true
    panel:SetTitle(tab.name or 'Edit Tab')

    self.checkCount = 0
    self.colorCount = 0

    local function ContentWidth()
        local width = panel.scroll:GetWidth()
        if type(width) == 'number' and width > 200 then
            return width
        end
        width = panel:GetWidth()
        if type(width) == 'number' and width > 200 then
            return width - 30
        end
        return 610
    end

    local function Layout(width)
        local child = panel.scroll.child
        local y = 0

        local function BindColor(picker, colorKey)
            local saved = util.StoredColor(colorKey)
            local fr, fg, fb = util.FallbackColor(colorKey)
            if saved then
                fr, fg, fb = saved.r or fr, saved.g or fg, saved.b or fb
            end
            picker.onChange = nil
            picker:SetOptionData({
                label = '',
                hasOpacity = false,
                disableAlpha = true,
                currentValue = function()
                    local current = util.StoredColor(colorKey)
                    if current then
                        return { r = current.r or fr, g = current.g or fg, b = current.b or fb, a = 1 }
                    end
                    return { r = fr, g = fg, b = fb, a = 1 }
                end,
                onChange = function(color)
                    panels:SetMessageColor(colorKey, color.r, color.g, color.b)
                end,
            })
        end

        local function Place(parent, columnWidth, check, column, colorKey, yOffset)
            local gutter = 16
            local colorSize = 20
            local half = (columnWidth - gutter) / 2
            local checkWidth = math.max(half - colorSize - 8, 40)
            local x = column == 0 and 0 or (half + gutter)
            check:SetParent(parent)
            check:ClearAllPoints()
            check:SetFrameWidth(checkWidth)
            if check.Label then
                check.Label:SetJustifyH('LEFT')
                check.Label:SetWordWrap(false)
                check.Label:SetWidth(math.max(checkWidth - 22, 20))
                if check.Base then
                    check.Label:ClearAllPoints()
                    check.Label:SetPoint('LEFT', check.Base, 'RIGHT', 3, -1)
                end
            end
            check:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, -yOffset)
            local picker = panels:AcquireColor()
            picker:SetParent(parent)
            picker:ClearAllPoints()
            picker:SetPoint('TOPRIGHT', parent, 'TOPLEFT', x + half, -yOffset)
            BindColor(picker, colorKey)
        end

        local function GroupInner(group)
            local pad = 8
            if EXFrames.ScalePixel then
                pad = EXFrames:ScalePixel(8, group)
            end
            return math.max(width - pad * 2, 40)
        end

        local function FinishGroup(group, measure, contentHeight)
            measure.contentHeight = math.max(contentHeight, 1)
            group:ClearAllPoints()
            group:SetPoint('TOPLEFT', child, 'TOPLEFT', 0, -y)
            group:SetFrameWidth(width)
            if group:IsExpanded() and contentHeight > 1 then
                local body = group:GetBody()
                local bodyHeight = body:GetHeight()
                if type(bodyHeight) ~= 'number' or bodyHeight < contentHeight - 1 then
                    body:SetHeight(contentHeight)
                    local headerHeight = group.header and group.header:GetHeight() or 32
                    group:SetHeight(headerHeight + contentHeight + 17)
                end
            end
            y = y + (group:GetHeight() or 0) + 10
        end

        local messageGroup = panel.messageGroup
        local messageBody = messageGroup:GetBody()
        local messageInner = GroupInner(messageGroup)
        local messageY = 0
        for index, entry in ipairs(util.PICK) do
            local check = self:AcquireCheck()
            local key = entry.key
            check:SetOptionData({
                label = entry.label,
                currentValue = function()
                    return tab.groups[key] and true or false
                end,
                onChange = function(value)
                    tab.groups[key] = value and true or false
                    history:SaveTabs()
                    messages:Layout()
                end,
            })
            Place(messageBody, messageInner, check, (index - 1) % 2, entry.key, messageY)
            if index % 2 == 0 then
                messageY = messageY + 28
            end
        end
        if #util.PICK % 2 == 1 then
            messageY = messageY + 28
        end
        FinishGroup(messageGroup, panel.messageMeasure, messageY)

        local group = panel.channelGroup
        local body = group:GetBody()
        local inner = GroupInner(group)
        local names = JoinedChannels(tab)
        local channelY = 0
        if #names == 0 then
            panel.channelEmpty:Show()
            channelY = 20
        else
            panel.channelEmpty:Hide()
            for index, name in ipairs(names) do
                local check = self:AcquireCheck()
                check:SetOptionData({
                    label = name,
                    currentValue = function()
                        return type(tab.channels) == 'table' and tab.channels[name] and true or false
                    end,
                    onChange = function(value)
                        tab.channels = tab.channels or {}
                        if value then
                            tab.channels[name] = true
                        else
                            tab.channels[name] = nil
                        end
                        history:SaveTabs()
                        messages:Layout()
                    end,
                })
                Place(body, inner, check, (index - 1) % 2, 'channel:' .. name, channelY)
                if index % 2 == 0 then
                    channelY = channelY + 28
                end
            end
            if #names % 2 == 1 then
                channelY = channelY + 28
            end
        end
        FinishGroup(group, panel.channelMeasure, channelY)
        return math.max(y + 8, 1)
    end

    local width = ContentWidth()
    local height = Layout(width)
    panel.scroll:UpdateScrollChild(width, height)
    local fitted = panel.scroll.child:GetWidth()
    if type(fitted) == 'number' and math.abs(fitted - width) > 1 then
        self.checkCount = 0
        self.colorCount = 0
        height = Layout(fitted)
        panel.scroll:UpdateScrollChild(fitted, height)
    end

    for index = self.checkCount + 1, #self.checks do
        self.checks[index]:Hide()
    end
    for index = self.colorCount + 1, #self.colors do
        self.colors[index]:Hide()
    end
    panel.deleteButton:SetShown(#history:EnsureTabs() > 1)
    self.buildingConfig = false
end

function panels:OpenConfig(tab)
    self:HideMenu()
    self:CreateConfig()
    self.configTab = tab
    local panel = self.channelWindow
    panel.nameBox:SetOptionData({
        label = 'Tab name',
        currentValue = function()
            return tab.name or ''
        end,
        onChange = function(value)
            if type(value) ~= 'string' or value == '' then
                return
            end
            tab.name = value
            history:SaveTabs()
            panels:RefreshTabs()
            panel:SetTitle(value)
        end,
    })
    self:BuildConfig()
    panel:ShowWindow()
end

function panels:CreateConfig()
    if self.channelWindow then
        return
    end

    local panel = EXFrames:GetFrame('window-frame'):Create({
        name = 'ExalityUIChatChannels',
        size = { 640, 560 },
        title = 'Edit Tab',
    })
    panel.onClose = function()
        panels.configTab = nil
    end

    local nameBox = EXFrames:GetFrame('edit-box-input'):Create({
        label = 'Tab name',
    }, panel.container)
    nameBox:SetHeight(48)
    nameBox:SetPoint('TOPLEFT', panel.container, 'TOPLEFT', 0, 0)
    nameBox:SetPoint('TOPRIGHT', panel.container, 'TOPRIGHT', 0, 0)
    panel.nameBox = nameBox

    local deleteButton = CreateFrame('Button', nil, panel.container)
    deleteButton:SetHeight(22)
    deleteButton:SetPoint('BOTTOMLEFT', panel.container, 'BOTTOMLEFT', 0, 0)
    local deleteIcon = deleteButton:CreateTexture(nil, 'ARTWORK')
    deleteIcon:SetTexture(DELETE_ICON)
    deleteIcon:SetSize(16, 18)
    deleteIcon:SetPoint('LEFT', 0, 0)
    local deleteLabel = deleteButton:CreateFontString(nil, 'OVERLAY')
    deleteLabel:SetFont(FontPath(), 12, 'OUTLINE')
    deleteLabel:SetPoint('LEFT', deleteIcon, 'RIGHT', 6, -1)
    deleteLabel:SetText('Delete Tab')
    local mutedR, mutedG, mutedB = MutedColor()
    deleteLabel:SetTextColor(mutedR, mutedG, mutedB)
    deleteButton:SetWidth(16 + 6 + deleteLabel:GetStringWidth() + 4)
    deleteButton:SetScript('OnEnter', function()
        deleteLabel:SetTextColor(1, 1, 1)
    end)
    deleteButton:SetScript('OnLeave', function()
        local r, g, b = MutedColor()
        deleteLabel:SetTextColor(r, g, b)
    end)
    deleteButton:SetScript('OnClick', function()
        if panels.configTab then
            panels:RemoveTab(panels.configTab)
        end
    end)
    panel.deleteButton = deleteButton

    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scroll:SetParent(panel.container)
    scroll:SetPoint('TOPLEFT', nameBox, 'BOTTOMLEFT', 0, -18)
    scroll:SetPoint('BOTTOMRIGHT', panel.container, 'BOTTOMRIGHT', 0, 32)
    panel.scroll = scroll

    local function CreateOptionGroup(label, sessionKey)
        local group = EXFrames:GetFrame('option-group'):Create(scroll.child)
        group:SetOptionData({
            label = label,
            collapsible = true,
            expanded = true,
            expandSessionKey = sessionKey,
        })
        group.onLayoutRequest = function()
            if panels.configTab and panels.channelWindow and not panels.buildingConfig then
                panels:BuildConfig()
            end
        end
        local measure = CreateFrame('Frame', nil, group:GetBody())
        measure:SetHeight(1)
        measure.contentHeight = 1
        measure.Layout = function(self)
            self:SetHeight(self.contentHeight or 1)
        end
        measure:EnableMouse(false)
        group:SetBodyLayout(measure)
        measure:EnableMouse(false)
        return group, measure
    end

    local messageGroup, messageMeasure = CreateOptionGroup('Messages', 'exui-chat-messages')
    panel.messageGroup = messageGroup
    panel.messageMeasure = messageMeasure

    local channelGroup, measure = CreateOptionGroup('Channels', 'exui-chat-channels')
    panel.channelGroup = channelGroup
    panel.channelMeasure = measure

    local empty = channelGroup:GetBody():CreateFontString(nil, 'OVERLAY')
    empty:SetFont(FontPath(), 12, 'OUTLINE')
    local emptyR, emptyG, emptyB = MutedColor()
    empty:SetTextColor(emptyR, emptyG, emptyB)
    empty:SetJustifyH('LEFT')
    empty:SetPoint('TOPLEFT', channelGroup:GetBody(), 'TOPLEFT', 0, 0)
    empty:SetText('No joined channels')
    empty:Hide()
    panel.channelEmpty = empty

    panel:HookScript('OnSizeChanged', function()
        if panels.configTab and panel:IsShown() and not panels.buildingConfig then
            panels:BuildConfig()
        end
    end)

    self.channelWindow = panel
    self.checks = {}
    self.checkCount = 0
    self.colors = {}
    self.colorCount = 0
end

----------------------------------------------------------------
-- Chat menu
----------------------------------------------------------------

local function JoinCopyText(format, left, right)
    if not window.frame then
        return nil
    end
    if not panels.copyJoin then
        local fontString = window.frame:CreateFontString(nil, 'OVERLAY')
        fontString:Hide()
        panels.copyJoin = fontString
    end
    local fontString = panels.copyJoin
    if not pcall(fontString.SetFormattedText, fontString, format, left, right) then
        return nil
    end
    local text = fontString:GetText()
    if IsSecret(text) then
        return text
    end
    if type(text) == 'string' and text ~= '' and text ~= format then
        return text
    end
end

function panels:CopyActiveTab()
    local entries = {}
    local pattern = Chat():GetTimestampPattern()
    for _, line in ipairs(history:MatchingLines()) do
        local message = line.message
        if formatter.IsStatusLine(line.chatType) then
            message = formatter.StripStatusLinks(message)
        end
        local secretMessage = IsSecret(message)
        local readable = not secretMessage and type(message) == 'string' and message ~= ''
        if readable or secretMessage then
            local r, g, b = 1, 1, 1
            if not line.plain then
                r, g, b = util.MessageColor(line.chatType, line.channel)
            end
            local text
            if readable then
                local parts = {}
                if pattern then
                    local ok, stamp = pcall(date, pattern, util.LineWhen(line))
                    if ok and type(stamp) == 'string' and stamp ~= '' then
                        parts[#parts + 1] = stamp
                    end
                end
                if not IsSecret(line.channel) and type(line.channel) == 'string' and line.channel ~= '' then
                    parts[#parts + 1] = '[' .. line.channel .. ']'
                elseif Chat():ShowChannelTags() then
                    local tag = util.TypeTag(line.chatType)
                    if tag then
                        parts[#parts + 1] = '[' .. tag .. ']'
                    end
                end
                if line.chatType ~= 'TEXT_EMOTE' and not IsSecret(line.sender) and type(line.sender) == 'string' and line.sender ~= '' then
                    local name = line.sender
                    if Ambiguate then
                        name = Ambiguate(name, 'short')
                    end
                    parts[#parts + 1] = name .. ':'
                end
                parts[#parts + 1] = message
                text = table.concat(parts, ' ')
            else
                local name = line.sender
                local hasName = IsSecret(name) or
                    (type(name) == 'string' and name ~= '' and line.chatType ~= 'TEXT_EMOTE')
                if hasName and not IsSecret(name) and Ambiguate then
                    name = Ambiguate(name, 'short')
                end
                if hasName then
                    text = JoinCopyText('%s: %s', name, message)
                end
                if not IsSecret(text) and type(text) ~= 'string' and pattern then
                    local ok, stamp = pcall(date, pattern, util.LineWhen(line))
                    if ok and type(stamp) == 'string' and stamp ~= '' then
                        text = JoinCopyText('%s %s', stamp, message)
                    end
                end
                if not IsSecret(text) and type(text) ~= 'string' then
                    text = message
                end
            end
            if IsSecret(text) or (type(text) == 'string' and text ~= '') then
                entries[#entries + 1] = {
                    text = text,
                    r = r,
                    g = g,
                    b = b,
                }
            end
        end
    end
    EXUI:GetModule('chat-menu'):ShowCopy(entries)
end

local function OpenChatChannels()
    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn('Blizzard_Channels')
    elseif LoadAddOn then
        LoadAddOn('Blizzard_Channels')
    end
    if ChannelFrame and ChannelFrame:IsShown() then
        return
    end
    if ChannelFrame and ShowUIPanel then
        ShowUIPanel(ChannelFrame)
        return
    end
    if ToggleChannelFrame then
        ToggleChannelFrame()
    end
end

function panels:MenuEntries()
    local locked = window:IsLocked()
    return {
        {
            label = 'Add Tab',
            sprite = 'plus',
            onClick = function()
                panels:AddTab()
            end,
        },
        {
            label = 'Copy Chat',
            sprite = 'copy',
            onClick = function()
                panels:CopyActiveTab()
            end,
        },
        {
            label = 'Open Chat Channels',
            sprite = 'channels',
            onClick = OpenChatChannels,
        },
        {
            label = locked and 'Unlock' or 'Lock',
            split = locked and 'unlock' or 'lock',
            onClick = function()
                Chat().Data:SetValue('locked', not locked)
                window:ApplyLock()
            end,
        },
    }
end

function panels:ToggleMenu()
    if not window.menuButton then
        return
    end
    self:HideConfig()
    EXUI:GetModule('chat-menu'):ShowEntries(window.menuButton, self:MenuEntries())
end

function panels:HideMenu()
    EXUI:GetModule('chat-menu'):Hide()
end
