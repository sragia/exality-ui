---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUICharacterFrameSets
local sets = EXUI:GetModule('character-frame-sets')

sets.container = nil
sets.selectedSetID = nil
sets.buttons = {}
sets.createPopup = nil
sets.iconButtons = {}
sets.selectedIcon = nil
sets.iconProvider = nil
sets.iconCount = 0
sets.iconColumns = 7
sets.lastIconScrollOffset = -1

local ROW_HEIGHT = 28
local ROW_GAP = 3
local ACTION_HEIGHT = 28
local ICON_SIZE = 30
local ICON_PAD = 4
local ICON_POOL_EXTRA_ROWS = 2

local function ThemeColor(key)
    return EXUI.const.theme[key]
end

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

local function CreateActionButton(parent, label)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(ACTION_HEIGHT)

    local bg = button:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    bg:SetTextureSliceMargins(20, 20, 20, 20)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetAllPoints()
    bg:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
    button.bg = bg

    local text = button:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    text:SetPoint('CENTER')
    text:SetText(label)
    button.Text = text

    button:SetScript('OnEnter', function(self)
        if self:IsEnabled() then
            self.bg:SetVertexColor(60 / 255, 60 / 255, 60 / 255, 1)
        end
    end)
    button:SetScript('OnLeave', function(self)
        if self:IsEnabled() then
            self.bg:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
        end
    end)

    button.SetEnabledVisual = function(self, enabled)
        if enabled then
            self:Enable()
            self.Text:SetVertexColor(1, 1, 1, 1)
            self.bg:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
        else
            self:Disable()
            self.Text:SetVertexColor(0.45, 0.45, 0.45, 1)
            self.bg:SetVertexColor(25 / 255, 25 / 255, 25 / 255, 1)
        end
    end

    return button
end

local function CellSize()
    return ICON_SIZE + ICON_PAD
end

sets.CreateRow = function(self, parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(ROW_HEIGHT)

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    button.bg:SetAllPoints()

    button.border = EXUI:AddPixelPerfectBorder(button, 1, { register = false })

    button.Icon = button:CreateTexture(nil, 'ARTWORK')
    button.Icon:SetSize(20, 20)
    button.Icon:SetPoint('LEFT', 5, 0)

    button.Check = button:CreateTexture(nil, 'OVERLAY')
    button.Check:SetTexture(EXUI.const.textures.characterFrame.check)
    button.Check:SetSize(14, 14)
    button.Check:SetPoint('RIGHT', -6, 0)
    button.Check:SetVertexColor(unpack(ThemeColor('success')))
    button.Check:Hide()

    button.Text = button:CreateFontString(nil, 'OVERLAY')
    button.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Text:SetPoint('LEFT', button.Icon, 'RIGHT', 6, 0)
    button.Text:SetPoint('RIGHT', button.Check, 'LEFT', -6, 0)
    button.Text:SetJustifyH('LEFT')
    button.Text:SetWordWrap(false)

    button:SetScript('OnEnter', function(btn)
        ApplyRowVisual(btn, btn.setID == sets.selectedSetID, true)
        if btn.numLost and btn.numLost > 0 then
            GameTooltip:SetOwner(btn, 'ANCHOR_RIGHT')
            GameTooltip:SetText(btn.setName, 1, 1, 1)
            GameTooltip:AddLine(string.format('%d items missing', btn.numLost), 1, 0.2, 0.2)
            GameTooltip:Show()
        end
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyRowVisual(btn, btn.setID == sets.selectedSetID, false)
        GameTooltip:Hide()
    end)
    button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    button:SetScript('OnClick', function(btn)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        sets.selectedSetID = btn.setID
        sets:RefreshSelection()
        sets:UpdateActionButtons()
    end)
    button:SetScript('OnDoubleClick', function(btn)
        if not btn.setID then
            return
        end
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        sets.selectedSetID = btn.setID
        sets:RefreshSelection()
        sets:UpdateActionButtons()
        EquipmentManager_EquipSet(btn.setID)
    end)

    return button
end

sets.RefreshSelection = function(self)
    for _, button in ipairs(self.buttons) do
        if button:IsShown() then
            ApplyRowVisual(button, button.setID == self.selectedSetID, false)
        end
    end
end

sets.UpdateActionButtons = function(self)
    local hasSelection = self.selectedSetID ~= nil
    self.equipBtn:SetEnabledVisual(hasSelection)
    self.saveBtn:SetEnabledVisual(hasSelection)
    self.deleteBtn:SetEnabledVisual(hasSelection)

    local canCreate = C_EquipmentSet.GetNumEquipmentSets() < MAX_EQUIPMENT_SETS_PER_PLAYER
    self.createBtn:SetEnabledVisual(canCreate)
end

sets.UpdateScroll = function(self)
    if not self.scrollFrame then
        return
    end
    local width = math.max(1, self.scrollFrame:GetWidth())
    local height = math.max(1, self.scrollChild:GetHeight())
    self.scrollFrame:UpdateScrollChild(width, height)
end

sets.Update = function(self)
    if not self.container then
        return
    end

    local setIDs = C_EquipmentSet.GetEquipmentSetIDs()
    table.sort(setIDs)

    if self.selectedSetID then
        local stillExists = false
        for _, id in ipairs(setIDs) do
            if id == self.selectedSetID then
                stillExists = true
                break
            end
        end
        if not stillExists then
            self.selectedSetID = nil
        end
    end

    local content = self.scrollChild
    local y = -2

    if #setIDs == 0 then
        self.emptyText:Show()
    else
        self.emptyText:Hide()
    end

    for i, setID in ipairs(setIDs) do
        local button = self.buttons[i]
        if not button then
            button = self:CreateRow(content)
            self.buttons[i] = button
        end

        local name, iconFileID, _, isEquipped, _, _, _, numLost = C_EquipmentSet.GetEquipmentSetInfo(setID)
        button.setID = setID
        button.setName = name
        button.numLost = numLost or 0
        button.Icon:SetTexture(iconFileID)
        button.Text:SetText(name)
        if isEquipped then
            button.Check:Show()
        else
            button.Check:Hide()
        end
        if numLost and numLost > 0 then
            button.Text:SetVertexColor(1, 0.35, 0.35, 1)
        else
            button.Text:SetVertexColor(1, 1, 1, 1)
        end

        button:ClearAllPoints()
        button:SetPoint('TOPLEFT', content, 'TOPLEFT', 2, y)
        button:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -2, y)
        button:Show()
        ApplyRowVisual(button, setID == self.selectedSetID, false)

        y = y - ROW_HEIGHT - ROW_GAP
    end

    for i = #setIDs + 1, #self.buttons do
        self.buttons[i]:Hide()
    end

    content:SetHeight(math.max((-y) + 4, 1))
    self:UpdateScroll()
    self:UpdateActionButtons()
end

sets.HideCreatePopup = function(self)
    if self.createPopup then
        self.createPopup:Hide()
    end
    if self.iconProvider then
        self.iconProvider:Release()
        self.iconProvider = nil
    end
    self.iconCount = 0
    self.lastIconScrollOffset = -1
end

sets.AcquireIconButton = function(self, index)
    local popup = self.createPopup
    local button = self.iconButtons[index]
    if button then
        return button
    end

    button = CreateFrame('Button', nil, popup.iconScroll.child)
    button:SetSize(ICON_SIZE, ICON_SIZE)
    button.Texture = button:CreateTexture(nil, 'ARTWORK')
    button.Texture:SetAllPoints()
    button.border = EXUI:AddPixelPerfectBorder(button, 1, { register = false })
    button.border:SetBorderColor(unpack(ThemeColor('border')))
    button:SetScript('OnClick', function(btn)
        sets.selectedIcon = btn.iconValue
        popup.selectedIconTex:SetTexture(btn.iconValue)
        for _, other in ipairs(sets.iconButtons) do
            if other:IsShown() then
                if other == btn then
                    other.border:SetBorderColor(unpack(ThemeColor('accent')))
                else
                    other.border:SetBorderColor(unpack(ThemeColor('border')))
                end
            end
        end
    end)
    self.iconButtons[index] = button
    return button
end

sets.RefreshVisibleIcons = function(self, force)
    local popup = self.createPopup
    local scroll = popup and popup.iconScroll
    if not scroll or not self.iconProvider or self.iconCount <= 0 then
        return
    end

    local offset = scroll.scrollOffset or 0
    if not force and math.abs(offset - self.lastIconScrollOffset) < 0.5 then
        return
    end
    self.lastIconScrollOffset = offset

    local cell = CellSize()
    local columns = self.iconColumns
    local viewHeight = scroll.content:GetHeight() or scroll:GetHeight() or 1
    local startRow = math.max(0, math.floor(offset / cell) - 1)
    local visibleRows = math.ceil(viewHeight / cell) + ICON_POOL_EXTRA_ROWS
    local startIndex = startRow * columns + 1
    local endIndex = math.min(self.iconCount, (startRow + visibleRows) * columns)
    local poolSize = visibleRows * columns

    for poolIndex = 1, poolSize do
        local iconIndex = startIndex + poolIndex - 1
        local button = self:AcquireIconButton(poolIndex)
        if iconIndex <= endIndex then
            local icon = self.iconProvider:GetIconByIndex(iconIndex)
            button.iconValue = icon
            button.iconIndex = iconIndex
            button.Texture:SetTexture(icon)

            local col = (iconIndex - 1) % columns
            local row = math.floor((iconIndex - 1) / columns)
            button:ClearAllPoints()
            button:SetPoint('TOPLEFT', scroll.child, 'TOPLEFT', col * cell, -row * cell)
            button:Show()

            if icon == self.selectedIcon then
                button.border:SetBorderColor(unpack(ThemeColor('accent')))
            else
                button.border:SetBorderColor(unpack(ThemeColor('border')))
            end
        else
            button:Hide()
        end
    end

    for i = poolSize + 1, #self.iconButtons do
        self.iconButtons[i]:Hide()
    end
end

sets.BuildCreateIcons = function(self)
    local popup = self.createPopup
    local provider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Equipment)
    self.iconProvider = provider
    self.iconCount = provider:GetNumIcons()
    self.selectedIcon = provider:GetIconByIndex(1)
    popup.selectedIconTex:SetTexture(self.selectedIcon)

    local cell = CellSize()
    local columns = self.iconColumns
    local rows = math.max(1, math.ceil(self.iconCount / columns))
    local contentWidth = columns * cell
    local contentHeight = rows * cell

    local scroll = popup.iconScroll
    scroll:Reset()
    scroll.child:SetHeight(contentHeight)
    scroll:UpdateScrollChild(contentWidth, contentHeight)
    self.lastIconScrollOffset = -1
    self:RefreshVisibleIcons(true)
end

sets.ShowCreatePopup = function(self)
    if C_EquipmentSet.GetNumEquipmentSets() >= MAX_EQUIPMENT_SETS_PER_PLAYER then
        UIErrorsFrame:AddMessage(EQUIPMENT_SETS_TOO_MANY, 1.0, 0.1, 0.1, 1.0)
        return
    end

    if self.iconProvider then
        self.iconProvider:Release()
        self.iconProvider = nil
    end

    local popup = self.createPopup
    popup.nameEdit:SetText('')
    popup:Show()
    popup.nameEdit:SetFocus()
    self:BuildCreateIcons()
end

sets.ConfirmCreate = function(self)
    local name = strtrim(self.createPopup.nameEdit:GetText() or '')
    if name == '' then
        return
    end

    if C_EquipmentSet.GetNumEquipmentSets() >= MAX_EQUIPMENT_SETS_PER_PLAYER then
        UIErrorsFrame:AddMessage(EQUIPMENT_SETS_TOO_MANY, 1.0, 0.1, 0.1, 1.0)
        return
    end

    local existingID = C_EquipmentSet.GetEquipmentSetID(name)
    if existingID then
        UIErrorsFrame:AddMessage(EQUIPMENT_SETS_CANT_RENAME, 1.0, 0.1, 0.1, 1.0)
        return
    end

    local icon = self.selectedIcon
    if type(icon) == 'string' then
        icon = string.gsub(icon, [[INTERFACE\ICONS\]], '')
        icon = string.gsub(icon, [[Interface\Icons\]], '')
    end

    C_EquipmentSet.CreateEquipmentSet(name, icon)
    self:HideCreatePopup()
end

sets.CreatePopup = function(self, parent)
    local theme = EXUI.const.theme
    local inputTex = EXUI.const.textures.characterFrame.input

    local popup = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
    popup:SetSize(280, 360)
    popup:SetPoint('CENTER')
    popup:SetFrameStrata('DIALOG')
    popup:SetFrameLevel(200)
    popup:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    popup:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    popup:SetBackdropBorderColor(0, 0, 0, 1)
    popup:EnableMouse(true)
    popup:Hide()
    self.createPopup = popup

    local title = popup:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 14, 'OUTLINE')
    title:SetPoint('TOP', 0, -12)
    title:SetText('Create Equipment Set')

    local nameLabel = popup:CreateFontString(nil, 'OVERLAY')
    nameLabel:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    nameLabel:SetPoint('TOPLEFT', 14, -40)
    nameLabel:SetText('Name')

    local nameEdit = CreateFrame('EditBox', nil, popup)
    nameEdit:SetAutoFocus(false)
    nameEdit:SetSize(170, 24)
    nameEdit:SetPoint('TOPLEFT', nameLabel, 'BOTTOMLEFT', 0, -6)
    nameEdit:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    nameEdit:SetTextColor(unpack(theme.text))
    nameEdit:SetTextInsets(8, 8, 0, 0)
    nameEdit:SetMaxLetters(16)

    local nameBg = nameEdit:CreateTexture(nil, 'BACKGROUND')
    nameBg:SetTexture(inputTex.bg)
    nameBg:SetVertexColor(unpack(theme.backgroundDeep))
    nameBg:SetTextureSliceMargins(6, 6, 6, 6)
    nameBg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    nameBg:SetAllPoints()

    local nameBorder = nameEdit:CreateTexture(nil, 'OVERLAY', nil, 7)
    nameBorder:SetTexture(inputTex.border)
    nameBorder:SetVertexColor(unpack(theme.border))
    nameBorder:SetTextureSliceMargins(6, 6, 6, 6)
    nameBorder:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    nameBorder:SetAllPoints()

    nameEdit:SetScript('OnEnterPressed', function()
        sets:ConfirmCreate()
    end)
    nameEdit:SetScript('OnEscapePressed', function()
        sets:HideCreatePopup()
    end)
    nameEdit:SetScript('OnEditFocusGained', function()
        nameBorder:SetVertexColor(unpack(theme.accent))
    end)
    nameEdit:SetScript('OnEditFocusLost', function()
        nameBorder:SetVertexColor(unpack(theme.border))
    end)
    popup.nameEdit = nameEdit

    local selectedIconHolder = CreateFrame('Frame', nil, popup)
    selectedIconHolder:SetSize(32, 32)
    selectedIconHolder:SetPoint('LEFT', nameEdit, 'RIGHT', 12, 0)
    local selectedIconTex = selectedIconHolder:CreateTexture(nil, 'ARTWORK')
    selectedIconTex:SetPoint('TOPLEFT', 1, -1)
    selectedIconTex:SetPoint('BOTTOMRIGHT', -1, 1)
    popup.selectedIconTex = selectedIconTex
    local selectedIconBorder = selectedIconHolder:CreateTexture(nil, 'OVERLAY')
    selectedIconBorder:SetTexture(inputTex.border)
    selectedIconBorder:SetVertexColor(unpack(theme.border))
    selectedIconBorder:SetTextureSliceMargins(6, 6, 6, 6)
    selectedIconBorder:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    selectedIconBorder:SetAllPoints()

    local iconLabel = popup:CreateFontString(nil, 'OVERLAY')
    iconLabel:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    iconLabel:SetPoint('TOPLEFT', nameLabel, 'BOTTOMLEFT', 0, -42)
    iconLabel:SetText('Icon')

    local iconScroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    iconScroll:SetParent(popup)
    iconScroll:SetPoint('TOPLEFT', iconLabel, 'BOTTOMLEFT', 0, -8)
    iconScroll:SetPoint('BOTTOMRIGHT', popup, 'BOTTOMRIGHT', -14, 48)
    popup.iconScroll = iconScroll

    local originalUpdateScrollbar = iconScroll.UpdateScrollbar
    iconScroll.UpdateScrollbar = function(frame)
        originalUpdateScrollbar(frame)
        sets:RefreshVisibleIcons()
    end

    local iconWatcher = CreateFrame('Frame', nil, popup)
    popup.iconWatcher = iconWatcher
    iconWatcher:SetScript('OnUpdate', function()
        if popup:IsShown() and sets.iconProvider then
            sets:RefreshVisibleIcons()
        end
    end)

    local createBtn = CreateActionButton(popup, 'Create')
    createBtn:SetWidth(90)
    createBtn:SetPoint('BOTTOMLEFT', 14, 12)
    createBtn:SetScript('OnClick', function()
        sets:ConfirmCreate()
    end)

    local cancelBtn = CreateActionButton(popup, 'Cancel')
    cancelBtn:SetWidth(90)
    cancelBtn:SetPoint('BOTTOMRIGHT', -14, 12)
    cancelBtn:SetScript('OnClick', function()
        sets:HideCreatePopup()
    end)

    return popup
end

sets.Create = function(self, container)
    self.container = container

    local actions = CreateFrame('Frame', nil, container)
    actions:SetHeight(ACTION_HEIGHT)
    actions:SetPoint('BOTTOMLEFT', 0, 0)
    actions:SetPoint('BOTTOMRIGHT', 0, 0)
    self.actions = actions

    local gap = 4

    self.equipBtn = CreateActionButton(actions, 'Equip')
    self.saveBtn = CreateActionButton(actions, 'Save')
    self.deleteBtn = CreateActionButton(actions, 'Delete')
    self.createBtn = CreateActionButton(actions, 'Create')

    actions:SetScript('OnSizeChanged', function(frame, width)
        local w = (width - gap * 3) / 4
        self.equipBtn:ClearAllPoints()
        self.saveBtn:ClearAllPoints()
        self.deleteBtn:ClearAllPoints()
        self.createBtn:ClearAllPoints()

        self.equipBtn:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
        self.equipBtn:SetSize(w, ACTION_HEIGHT)

        self.saveBtn:SetPoint('LEFT', self.equipBtn, 'RIGHT', gap, 0)
        self.saveBtn:SetSize(w, ACTION_HEIGHT)

        self.deleteBtn:SetPoint('LEFT', self.saveBtn, 'RIGHT', gap, 0)
        self.deleteBtn:SetSize(w, ACTION_HEIGHT)

        self.createBtn:SetPoint('LEFT', self.deleteBtn, 'RIGHT', gap, 0)
        self.createBtn:SetSize(w, ACTION_HEIGHT)
    end)

    self.equipBtn:SetScript('OnClick', function()
        if not sets.selectedSetID then
            return
        end
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        EquipmentManager_EquipSet(sets.selectedSetID)
    end)

    self.saveBtn:SetScript('OnClick', function()
        if not sets.selectedSetID then
            return
        end
        local selectedSetName = C_EquipmentSet.GetEquipmentSetInfo(sets.selectedSetID)
        local dialog = StaticPopup_Show('CONFIRM_SAVE_EQUIPMENT_SET', selectedSetName, nil, sets.selectedSetID)
        if not dialog then
            UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0)
        end
    end)

    self.deleteBtn:SetScript('OnClick', function()
        if not sets.selectedSetID then
            return
        end
        local selectedSetName = C_EquipmentSet.GetEquipmentSetInfo(sets.selectedSetID)
        local dialog = StaticPopup_Show('CONFIRM_DELETE_EQUIPMENT_SET', selectedSetName, nil, sets.selectedSetID)
        if not dialog then
            UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0)
        end
    end)

    self.createBtn:SetScript('OnClick', function()
        sets:ShowCreatePopup()
    end)

    local scrollFrame = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scrollFrame:SetParent(container)
    scrollFrame:SetPoint('TOPLEFT', 0, 0)
    scrollFrame:SetPoint('BOTTOMRIGHT', actions, 'TOPRIGHT', 0, 8)
    self.scrollFrame = scrollFrame
    self.scrollChild = scrollFrame.child

    local emptyText = container:CreateFontString(nil, 'OVERLAY')
    emptyText:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    emptyText:SetPoint('CENTER', scrollFrame, 'CENTER', 0, 0)
    emptyText:SetText('No equipment sets yet.\nClick Create to add one.')
    emptyText:SetJustifyH('CENTER')
    emptyText:Hide()
    self.emptyText = emptyText

    scrollFrame:HookScript('OnSizeChanged', function()
        if container:IsShown() then
            sets:Update()
        end
    end)

    container:SetScript('OnShow', function()
        sets:Update()
    end)
    container:SetScript('OnHide', function()
        sets:HideCreatePopup()
    end)

    container:RegisterEvent('EQUIPMENT_SETS_CHANGED')
    container:RegisterEvent('EQUIPMENT_SWAP_FINISHED')
    container:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
    container:RegisterEvent('BAG_UPDATE')
    container:SetScript('OnEvent', function(_, event, ...)
        if event == 'EQUIPMENT_SWAP_FINISHED' then
            local completed, setID = ...
            if completed then
                if setID then
                    sets.selectedSetID = setID
                end
                -- isEquipped can lag the swap event by a frame
                C_Timer.After(0, function()
                    if sets.container then
                        sets:Update()
                    end
                end)
            end
            return
        end

        if event == 'EQUIPMENT_SETS_CHANGED' then
            sets:Update()
            return
        end

        -- Gear/bag changes: queue a single end-of-frame refresh for active checks
        if sets.container and sets.container:IsShown() then
            if not sets.queuedUpdate then
                sets.queuedUpdate = true
                C_Timer.After(0, function()
                    sets.queuedUpdate = false
                    if sets.container then
                        sets:Update()
                    end
                end)
            end
        end
    end)

    self:CreatePopup(container)
    self:UpdateActionButtons()
end
