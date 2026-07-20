---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesWindowFrame
local windowConstruct = EXFrames:GetFrame('window-frame')

---@class EXUICharacterFrameEquipmentSlot
local equipmentSlot = EXUI:GetModule('character-frame-equipment-slot')

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')

---@class EXUICharacterFrameStats
local stats = EXUI:GetModule('character-frame-stats')

---@class EXUICharacterFrameTitles
local titles = EXUI:GetModule('character-frame-titles')

---@class EXUICharacterFrameSets
local sets = EXUI:GetModule('character-frame-sets')

---@class EXUICharacterFrameCurrencies
local currencies = EXUI:GetModule('character-frame-currencies')

---@class ExalityFramesTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

-------------------------

---@class EXUICharacterFrameWindow
local characterFrame = EXUI:GetModule('character-frame-window')

characterFrame.enabled = false
characterFrame.isCreated = false
characterFrame.window = nil
characterFrame.override = false
characterFrame.activeSideTab = 'stats'
characterFrame.sidePanels = nil
characterFrame.sideTabButtons = nil

local SIDE_TABS = {
    { id = 'stats',  label = 'Stats' },
    { id = 'titles', label = 'Titles' },
    { id = 'sets',   label = 'Sets' },
}

local TAB_HEIGHT = 20
local TAB_PAD_X = 10
local TAB_GAP = 3
local TAB_BAR_PAD = 3
local TAB_CONTENT_GAP = 4

-- Must stay well under half of TAB_HEIGHT or top/bottom 9-slice edges collapse.
local TAB_SLICE = 4

local LEFT_SLOTS = {
    1, 2, 3, 15, 5, 4, 19, 9
}
local RIGHT_SLOTS = {
    10, 6, 7, 8, 11, 12, 13, 14
}
local BOTTOM_SLOTS = {
    16, 17
}

local function MoveFrameNextToWindow(frame)
    if (characterFrame.window and characterFrame.window:IsShown()) then
        local window = characterFrame.window
        local left, bottom, width, height = window:GetRect()
        frame:ClearAllPoints()
        local x = left + width + 10
        local y = bottom + height
        frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
    end
end

characterFrame.ReplaceItemSocketingFrameOnShow = function(self)
    if (ItemSocketingFrame) then
        local isfOnShow = ItemSocketingFrame:GetScript('OnShow')
        ItemSocketingFrame:SetScript('OnShow', function(self)
            if (isfOnShow) then
                isfOnShow(self)
            end
            MoveFrameNextToWindow(self)
        end)
    end
end

characterFrame.ReplaceItemUpgradeFrameOnShow = function(self)
    if (ItemUpgradeFrame) then
        local isfOnShow = ItemUpgradeFrame:GetScript('OnShow')
        ItemUpgradeFrame:SetScript('OnShow', function(self)
            if (isfOnShow) then
                isfOnShow(self)
            end
            MoveFrameNextToWindow(self)
        end)
    end
end

characterFrame.Init = function(self)
    hooksecurefunc("ToggleCharacter", function(frameName)
        if (InCombatLockdown() or not characterFrame.enabled or characterFrame.override or frameName ~= 'PaperDollFrame') then return end
        if (CharacterFrame and CharacterFrame:IsShown()) then
            ToggleCharacter('PaperDollFrame')
            characterFrame:OnShow()
        end
    end)

    if (customWindows.Data:GetValue('CharacterFrameEnabled')) then
        self:Enable()
    end
end

characterFrame.AddSlots = function(self, slots, parent, side)
    local prev = nil
    for index, slotId in ipairs(slots) do
        local slot = equipmentSlot:Create(slotId, side, index, parent)
        if (side == 'BOTTOM') then
            if (prev) then
                slot:SetPoint('LEFT', prev, 'RIGHT', 6, 0)
            else
                slot:SetPoint('LEFT', parent, 'LEFT', 0, 0)
            end
        else
            if (prev) then
                slot:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -6)
            else
                slot:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
            end
        end
        prev = slot
    end
end

characterFrame.UpdateHeader = function(self)
    local level = UnitLevel('player')
    local class, englishClass = UnitClass('player')
    local _, specName = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
    local avgIlvl, avgEquipped = GetAverageItemLevel()

    self.window.Header.LevelText:SetText(level)
    local classColor = C_ClassColor.GetClassColor(englishClass)
    self.window.Header.ClassSpecText:SetText(string.format('%s %s', specName,
        classColor:WrapTextInColorCode(class)))

    local avgIlvlString = WrapTextInColorCode(string.format('%.2f', avgIlvl), EXUI.utils.getIlvlColor(avgIlvl))
    local avgEquippedString = WrapTextInColorCode(string.format('%.2f', avgEquipped),
        EXUI.utils.getIlvlColor(avgEquipped))
    if (avgIlvl ~= avgEquipped) then
        self.window.Header.Ilvl:SetText(string.format('%s / %s', avgEquippedString, avgIlvlString))
    else
        self.window.Header.Ilvl:SetText(avgEquippedString)
    end

    self.window:SetTitle(UnitPVPName("player"))
    self.window.CharacterGlow:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
end

EXUI:RegisterEventHandler('PLAYER_EQUIPMENT_CHANGED', 'char-frame-update-header', function()
    if (characterFrame.window and characterFrame.window:IsShown()) then
        characterFrame:UpdateHeader()
    end
end)

characterFrame.UpdateModel = function(self)
    C_Timer.After(0.2, function() -- For some reason need to add some delay
        self.window.CharacterModel:RefreshUnit()
    end)
end

EXUI:RegisterEventHandler('PLAYER_EQUIPMENT_CHANGED', 'character-frame', function(event, ...)
    if (characterFrame.window and characterFrame.window:IsShown()) then
        characterFrame:UpdateModel()
    end
end)

characterFrame.CreateToBlizzIcon = function(self, window)
    local toBlizzIcon = CreateFrame("Button", nil, window)
    toBlizzIcon:SetSize(38, 28)
    toBlizzIcon:SetPoint("TOPRIGHT", -8, -5)

    local texture = toBlizzIcon:CreateTexture(nil, "BACKGROUND")
    texture:SetTexture(EXUI.const.textures.frame.inputs.buttonBg)
    texture:SetTextureSliceMargins(20, 20, 20, 20)
    texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    texture:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
    texture:SetAllPoints()

    local icon = toBlizzIcon:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(EXUI.const.textures.characterFrame.toBlizzIcon)
    icon:SetVertexColor(1, 1, 1, 1)
    icon:SetPoint("CENTER")
    icon:SetSize(17, 12)

    toBlizzIcon:EnableMouse(true)
    toBlizzIcon:SetMouseClickEnabled()
    toBlizzIcon:SetScript("OnClick", function()
        if (window:IsShown()) then
            window:HideWindow()
            characterFrame.override = true
            ToggleCharacter('PaperDollFrame')
            characterFrame.override = false
        end
    end)


    toBlizzIcon.Tooltip = tooltip:Get({
        text = 'Open Default Character Frame'
    }, toBlizzIcon)

    toBlizzIcon:SetScript("OnEnter", function(self)
        texture:SetVertexColor(60 / 255, 60 / 255, 60 / 255, 1)
        self.Tooltip:ShowTooltip()
    end)
    toBlizzIcon:SetScript("OnLeave", function(self)
        texture:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
        self.Tooltip:HideTooltip()
    end)

    return toBlizzIcon
end

local function ApplySideTabVisual(button, active, hovered)
    local theme = EXUI.const.theme
    local panel = EXUI.const.textures.characterFrame.panel

    button.bg:SetTexture(panel.bg)
    button.bg:SetTextureSliceMargins(TAB_SLICE, TAB_SLICE, TAB_SLICE, TAB_SLICE)
    button.bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)

    if button.border then
        button.border:Hide()
    end

    if active then
        button.bg:SetVertexColor(unpack(theme.accent))
        button.Text:SetVertexColor(1, 1, 1, 1)
    elseif hovered then
        button.bg:SetVertexColor(unpack(theme.accentLight))
        button.Text:SetVertexColor(1, 1, 1, 1)
    else
        button.bg:SetVertexColor(theme.backgroundDeep[1], theme.backgroundDeep[2], theme.backgroundDeep[3], 0.95)
        button.Text:SetVertexColor(unpack(theme.text))
    end
end

characterFrame.SetSideTab = function(self, tabId)
    if not self.sidePanels then
        return
    end

    self.activeSideTab = tabId

    for id, panel in pairs(self.sidePanels) do
        if id == tabId then
            panel:Show()
        else
            panel:Hide()
        end
    end

    if self.sideTabButtons then
        for _, button in ipairs(self.sideTabButtons) do
            ApplySideTabVisual(button, button.tabId == tabId, false)
        end
    end

    if tabId ~= 'sets' then
        sets:HideCreatePopup()
    end
end

characterFrame.CreateSideTabs = function(self, parent)
    local tabBar = CreateFrame('Frame', nil, parent)
    tabBar:SetHeight(TAB_HEIGHT + TAB_BAR_PAD * 2)
    tabBar:SetPoint('BOTTOMLEFT', parent, 'TOPLEFT', 0, 0)
    tabBar:SetPoint('BOTTOMRIGHT', parent, 'TOPRIGHT', 0, 0)

    local buttons = {}

    for i, tabInfo in ipairs(SIDE_TABS) do
        local button = CreateFrame('Button', nil, tabBar)
        button:SetHeight(TAB_HEIGHT)
        button.tabId = tabInfo.id

        button.bg = button:CreateTexture(nil, 'BACKGROUND')
        button.bg:SetAllPoints()

        button.Text = button:CreateFontString(nil, 'OVERLAY')
        button.Text:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
        button.Text:SetPoint('CENTER', 0, 0)
        button.Text:SetText(tabInfo.label)

        local textWidth = button.Text:GetStringWidth() + TAB_PAD_X * 2
        button:SetWidth(math.max(textWidth, 48))

        if i == #SIDE_TABS then
            button:SetPoint('RIGHT', tabBar, 'RIGHT', 0, 0)
        end

        buttons[#buttons + 1] = button
    end

    -- Right-align: chain leftward from the last tab
    for i = #buttons - 1, 1, -1 do
        buttons[i]:SetPoint('RIGHT', buttons[i + 1], 'LEFT', -TAB_GAP, 0)
    end

    for _, button in ipairs(buttons) do
        button:SetScript('OnEnter', function(btn)
            ApplySideTabVisual(btn, btn.tabId == characterFrame.activeSideTab, true)
        end)
        button:SetScript('OnLeave', function(btn)
            ApplySideTabVisual(btn, btn.tabId == characterFrame.activeSideTab, false)
        end)
        button:SetScript('OnClick', function(btn)
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            characterFrame:SetSideTab(btn.tabId)
        end)
        ApplySideTabVisual(button, button.tabId == 'stats', false)
    end

    self.sideTabButtons = buttons
    return tabBar
end

characterFrame.Create = function(self)
    local window = windowConstruct:Create({
        size = {
            800,
            470
        },
        title = 'Exality'
    });
    self.window = window

    local container = window.container
    local escapeHandler = CreateFrame('Button', nil, container)
    escapeHandler:EnableKeyboard(true)
    escapeHandler:SetPropagateKeyboardInput(true)
    escapeHandler:SetScript('OnKeyDown', function(self, key)
        if (key == 'ESCAPE') then
            if (not InCombatLockdown()) then
                self:SetPropagateKeyboardInput(false)
            end
            window:HideWindow()
            return
        end
        if (not InCombatLockdown()) then
            self:SetPropagateKeyboardInput(true)
        end
    end)

    -- Header --
    local headerFrame = CreateFrame('Frame', nil, container)
    headerFrame:SetHeight(30)
    headerFrame:SetPoint('TOPLEFT', 0, 20)
    headerFrame:SetPoint('TOPRIGHT', 0, 20)
    self.window.Header = headerFrame

    local levelText = headerFrame:CreateFontString(nil, 'OVERLAY')
    headerFrame.LevelText = levelText
    levelText:SetFont(EXUI.const.fonts.DEFAULT, 24, 'OUTLINE')
    levelText:SetPoint('TOPLEFT')

    local classSpecText = headerFrame:CreateFontString(nil, 'OVERLAY')
    headerFrame.ClassSpecText = classSpecText
    classSpecText:SetFont(EXUI.const.fonts.DEFAULT, 14, 'OUTLINE')
    classSpecText:SetPoint('BOTTOMLEFT', levelText, 'BOTTOMRIGHT', 5, 2)

    local separator = headerFrame:CreateTexture(nil, 'OVERLAY')
    headerFrame.Separator = separator
    separator:SetTexture(EXUI.const.textures.characterFrame.dot)
    separator:SetSize(4, 4)
    separator:SetPoint('CENTER', classSpecText, 'RIGHT', 10, 0)

    local ilvl = headerFrame:CreateFontString(nil, 'OVERLAY')
    headerFrame.Ilvl = ilvl
    ilvl:SetFont(EXUI.const.fonts.DEFAULT, 14, 'OUTLINE')
    ilvl:SetPoint('LEFT', separator, 'RIGHT', 10, 0)

    -- Gear Slots --
    local leftSlots = CreateFrame('Frame', nil, container)
    leftSlots:SetSize(38, 350)
    leftSlots:SetPoint('TOPLEFT', headerFrame, 'BOTTOMLEFT', 0, -10)

    local modelFrame = CreateFrame('Frame', nil, container)
    modelFrame:SetSize(380, 334)
    modelFrame:SetPoint('TOPLEFT', leftSlots, 'TOPRIGHT', 10, 0)

    local glow = modelFrame:CreateTexture(nil, "OVERLAY")
    glow:SetTexture(EXUI.const.textures.characterFrame.characterGlow)
    glow:SetSize(250, 350)
    glow:SetPoint('CENTER')
    glow:SetVertexColor(1, 1, 1, 1)
    glow:SetAlpha(0.5)
    self.window.CharacterGlow = glow

    local characterModel = CreateFrame('PlayerModel', nil, modelFrame)
    self.window.CharacterModel = characterModel
    characterModel:SetAllPoints()
    characterModel:SetUnit('player')
    characterModel:SetCamDistanceScale(1.2)
    local rotation = math.rad(20)
    local ROTATION_SENSITIVITY = 0.05

    characterModel:SetRotation(rotation)

    characterModel:EnableMouse(true)

    local function StopRotation(self)
        self.lastMouseX = nil
        self:SetScript("OnUpdate", nil)
    end

    local function OnRotationUpdate(self)
        if not IsMouseButtonDown("LeftButton") then
            StopRotation(self)
            return
        end

        if self.lastMouseX then
            local currentX = GetCursorPosition()
            local deltaX = currentX - self.lastMouseX
            self.lastMouseX = currentX

            rotation = rotation + (deltaX * ROTATION_SENSITIVITY)

            if rotation < 0 then
                rotation = rotation + (2 * math.pi)
            elseif rotation >= (2 * math.pi) then
                rotation = rotation - (2 * math.pi)
            end

            self:SetRotation(rotation)
        end
    end

    -- Handle mouse down
    characterModel:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local x = GetCursorPosition()
            self.lastMouseX = x
            self:SetScript("OnUpdate", OnRotationUpdate)
        end
    end)

    -- Handle mouse up
    characterModel:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            StopRotation(self)
        end
    end)

    local rightSlots = CreateFrame('Frame', nil, container)
    rightSlots:SetSize(38, 350)
    rightSlots:SetPoint('TOPLEFT', modelFrame, 'TOPRIGHT', 10, 0)

    local bottomSlots = CreateFrame('Frame', nil, container)
    bottomSlots:SetSize(82, 38)
    bottomSlots:SetPoint('TOP', modelFrame, 'BOTTOM', 0, 0)

    self:AddSlots(LEFT_SLOTS, leftSlots, 'LEFT')
    self:AddSlots(RIGHT_SLOTS, rightSlots, 'RIGHT')
    self:AddSlots(BOTTOM_SLOTS, bottomSlots, 'BOTTOM')

    self.window:Configure({
        staticAnchor = {
            'TOPLEFT',
            UIParent,
            'TOPLEFT',
            20,
            -150
        },
        titleSize = 14,
        disableLogoAndVersion = true,
        disableResize = true,
    })

    window.title:ClearAllPoints()
    window.title:SetPoint('CENTER', window, 'TOP', 0, 0)

    local sideColumn = CreateFrame('Frame', nil, container)
    sideColumn:SetPoint('TOPLEFT', rightSlots, 'TOPRIGHT', 25, 0)
    sideColumn:SetPoint('BOTTOMRIGHT')

    local tabBar = self:CreateSideTabs(sideColumn)

    local contentHost = CreateFrame('Frame', nil, sideColumn)
    contentHost:SetPoint('TOPLEFT', sideColumn, 'TOPLEFT', 0, 0)
    contentHost:SetPoint('BOTTOMRIGHT')

    local statsPanel = CreateFrame('Frame', nil, contentHost)
    statsPanel:SetAllPoints()
    local titlesPanel = CreateFrame('Frame', nil, contentHost)
    titlesPanel:SetAllPoints()
    local setsPanel = CreateFrame('Frame', nil, contentHost)
    setsPanel:SetAllPoints()

    self.sidePanels = {
        stats = statsPanel,
        titles = titlesPanel,
        sets = setsPanel,
    }

    stats:Create(statsPanel)
    titles:Create(titlesPanel)
    sets:Create(setsPanel)
    currencies:Create(window)

    window.onClose = function()
        sets:HideCreatePopup()
        currencies:Hide()
    end

    self:SetSideTab('stats')

    local toBlizzIcon = self:CreateToBlizzIcon(window)
    toBlizzIcon:SetPoint('TOPRIGHT', window.close, 'TOPLEFT', -5, 0)
end

characterFrame.OnShow = function(self)
    if (not characterFrame.isCreated) then
        self:Create()
        characterFrame.isCreated = true
    end
    self:UpdateHeader()
    if (not self.window:IsShown()) then
        self.window:ShowWindow()
        if (ItemUpgradeFrame and ItemUpgradeFrame:IsShown()) then
            MoveFrameNextToWindow(ItemUpgradeFrame)
        end
    end
end

characterFrame.Enable = function(self)
    self.enabled = true

    if (ItemSocketingFrame) then
        self:ReplaceItemSocketingFrameOnShow()
    end
    if (ItemUpgradeFrame) then
        self:ReplaceItemUpgradeFrameOnShow()
    end
    -- Addon not Loaded wait for event
    EXUI:RegisterEventHandler('ADDON_LOADED', 'character-frame', function(event, addonName)
        if (addonName == 'Blizzard_ItemSocketingUI') then
            self:ReplaceItemSocketingFrameOnShow()
        elseif (addonName == 'Blizzard_ItemUpgradeUI') then
            self:ReplaceItemUpgradeFrameOnShow()
        end
    end)
end

characterFrame.Disable = function(self)
    self.enabled = false
end

EXUI:RegisterEventHandler('PLAYER_REGEN_DISABLED', 'character-frame-hide', function()
    if (characterFrame.window and characterFrame.window:IsShown()) then
        characterFrame.window:HideWindowImmediate()
    end
end)
