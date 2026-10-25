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

---@class EXUICharacterFrameReputation
local reputation = EXUI:GetModule('character-frame-reputation')

---@class ExalityFramesTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

---@class EXUICharacterFrameInspect
local inspect = EXUI:GetModule('character-frame-inspect')

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
local TAB_GAP = 0
local TAB_BAR_PAD = 3
local TAB_CONTENT_GAP = 4

local LEFT_SLOTS = {
    1, 2, 3, 15, 5, 4, 19, 9
}
local RIGHT_SLOTS = {
    10, 6, 7, 8, 11, 12, 13, 14
}
local BOTTOM_SLOTS = {
    16, 17
}
local SLOT_SIZE = 36
local SLOT_GAP = 6
local WINDOW_BG = [[Interface/Addons/ExalityUI/Options/Assets/main-bg_2.png]]
local WINDOW_CORNER = 24
local BG_CROP_TOP = 0.05
local BG_CROP_BOTTOM = 0.04

local function BottomSlotIds()
    if not EXUI.IsForever() then
        return BOTTOM_SLOTS
    end
    return { 16, 17, INVSLOT_RANGED, INVSLOT_AMMO }
end

local function ShouldShowBottomSlot(slotId)
    if slotId == INVSLOT_RANGED then
        return C_PaperDollInfo.IsRangedSlotShown()
    end
    if slotId == INVSLOT_AMMO then
        return C_PaperDollInfo.AmmoNeeded() and UnitUsesAmmo('player')
    end
    return true
end

characterFrame.MoveFrameNextTo = function(self, frame, window)
    if (window and window:IsShown()) then
        local left, bottom, width, height = window:GetRect()
        frame:ClearAllPoints()
        local x = left + width + 10
        local y = bottom + height
        frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
    end
end

local function MoveFrameNextToWindow(frame)
    characterFrame:MoveFrameNextTo(frame, characterFrame.window)
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
    local created = {}
    local prev = nil
    if (not self.equipmentSlots) then
        self.equipmentSlots = {}
    end
    for index, slotId in ipairs(slots) do
        local slot = equipmentSlot:Create(slotId, side, index, parent)
        table.insert(self.equipmentSlots, slot)
        if (side == 'BOTTOM') then
            if (prev) then
                slot:SetPoint('LEFT', prev, 'RIGHT', SLOT_GAP, 0)
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
        table.insert(created, slot)
    end
    return created
end

characterFrame.RefreshEquipment = function(self)
    if (not self.equipmentSlots) then
        return
    end
    for _, slot in ipairs(self.equipmentSlots) do
        slot:Update()
    end
end

characterFrame.UpdateBottomSlots = function(self)
    if not self.bottomSlotButtons or not self.bottomSlots then
        return
    end
    if InCombatLockdown() then
        self.bottomSlotsDirty = true
        return
    end
    self.bottomSlotsDirty = false
    local prev = nil
    local count = 0
    for _, slot in ipairs(self.bottomSlotButtons) do
        slot:ClearAllPoints()
        if ShouldShowBottomSlot(slot:GetID()) then
            slot:Show()
            if prev then
                slot:SetPoint('LEFT', prev, 'RIGHT', SLOT_GAP, 0)
            else
                slot:SetPoint('LEFT', self.bottomSlots, 'LEFT', 0, 0)
            end
            prev = slot
            count = count + 1
        else
            slot:Hide()
        end
    end
    local width = count > 0 and (count * SLOT_SIZE + (count - 1) * SLOT_GAP) or SLOT_SIZE
    self.bottomSlots:SetSize(width, SLOT_SIZE)
end

characterFrame.UpdateHeader = function(self)
    local level = UnitLevel('player')
    local class, englishClass = UnitClass('player')
    local specName
    if not EXUI.IsForever() then
        local specIndex = C_SpecializationInfo.GetSpecialization()
        specName = specIndex and select(2, C_SpecializationInfo.GetSpecializationInfo(specIndex))
    end
    local avgIlvl, avgEquipped = GetAverageItemLevel()

    self.window.Header.LevelText:SetText(level)
    local classColor = C_ClassColor.GetClassColor(englishClass)
    local classText = classColor:WrapTextInColorCode(class)
    if not EXUI.IsForever() and specName and specName ~= '' then
        self.window.Header.ClassSpecText:SetText(string.format('%s %s', specName, classText))
    else
        self.window.Header.ClassSpecText:SetText(classText)
    end

    local avgIlvlString = WrapTextInColorCode(string.format('%.2f', avgIlvl), EXUI.utils.getIlvlColor(avgIlvl))
    local avgEquippedString = WrapTextInColorCode(string.format('%.2f', avgEquipped),
        EXUI.utils.getIlvlColor(avgEquipped))
    if (avgIlvl ~= avgEquipped) then
        self.window.Header.Ilvl:SetText(string.format('%s / %s', avgEquippedString, avgIlvlString))
    else
        self.window.Header.Ilvl:SetText(avgEquippedString)
    end

    self.window:SetTitle(UnitPVPName("player"))
    self.window.CharacterGlow:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.5)
    self:UpdateBackground()
end

characterFrame.FitBackground = function(self)
    self:FitAtlas(self.background, self.backgroundAtlas)
end

characterFrame.FitAtlas = function(self, texture, atlas)
    if (not texture or not atlas) then
        return
    end
    local info = C_Texture.GetAtlasInfo(atlas)
    local file = info and (info.file or info.filename)
    if (not info or not file) then
        texture:SetAtlas(atlas, true)
        texture:ClearAllPoints()
        texture:SetAllPoints()
        texture:SetVertexColor(1, 1, 1, 1)
        return
    end

    local parent = texture:GetParent()
    local frameWidth = parent:GetWidth()
    local frameHeight = parent:GetHeight()
    if (frameWidth <= 1 or frameHeight <= 1) then
        return
    end

    local left, right = info.leftTexCoord, info.rightTexCoord
    local top, bottom = info.topTexCoord, info.bottomTexCoord
    local vSpan = bottom - top
    top = top + vSpan * BG_CROP_TOP
    bottom = bottom - vSpan * BG_CROP_BOTTOM

    local artWidth = info.width
    local artHeight = info.height * (1 - BG_CROP_TOP - BG_CROP_BOTTOM)
    local frameAspect = frameWidth / frameHeight
    local artAspect = artWidth / artHeight
    if (artWidth > 0 and artHeight > 0) then
        if (artAspect > frameAspect) then
            local keep = frameAspect / artAspect
            local trim = (1 - keep) / 2
            local uSpan = right - left
            left = left + uSpan * trim
            right = right - uSpan * trim
        else
            local keep = artAspect / frameAspect
            local trim = (1 - keep) / 2
            vSpan = bottom - top
            top = top + vSpan * trim
            bottom = bottom - vSpan * trim
        end
    end

    texture:ClearAllPoints()
    texture:SetSize(frameWidth, frameHeight)
    texture:SetPoint('CENTER')
    texture:SetTexture(file)
    texture:SetTexCoord(left, right, top, bottom)
    texture:SetVertexColor(1, 1, 1, 1)
end

characterFrame.UpdateBackground = function(self)
    local art = self.background
    local window = self.window
    if (not art or not window) then
        return
    end
    if (EXUI.IsForever()) then
        art:Hide()
        if (self.backgroundBacking) then
            self.backgroundBacking:Hide()
        end
        if (window.Texture) then
            window.Texture:Show()
        end
        return
    end
    if (not ClassTalentUtil and not self.spellBookLoadTried and C_AddOns and C_AddOns.LoadAddOn) then
        self.spellBookLoadTried = true
        C_AddOns.LoadAddOn('Blizzard_PlayerSpells')
    end
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specID = specIndex and select(1, C_SpecializationInfo.GetSpecializationInfo(specIndex))
    local visuals = specID and ClassTalentUtil and ClassTalentUtil.GetVisualsForSpecID and
        ClassTalentUtil.GetVisualsForSpecID(specID)
    local atlas = visuals and visuals.background
    if (not atlas or not C_Texture.GetAtlasInfo(atlas)) then
        art:Hide()
        if (self.backgroundBacking) then
            self.backgroundBacking:Hide()
        end
        if (window.Texture) then
            window.Texture:Show()
        end
        return
    end
    if (window.Texture) then
        window.Texture:Hide()
    end
    if (window.PPBorder) then
        window.PPBorder:Hide()
    end
    if (self.backgroundBacking) then
        self.backgroundBacking:Show()
    end
    art:Show()
    self.backgroundAtlas = atlas
    self:FitBackground()
end

EXUI:RegisterEventHandler('ACTIVE_PLAYER_SPECIALIZATION_CHANGED', 'character-frame-background', function()
    if (characterFrame.window and characterFrame.window:IsShown()) then
        characterFrame:UpdateBackground()
    end
end)

EXUI:RegisterEventHandler({
    'PLAYER_EQUIPMENT_CHANGED',
    'PLAYER_AVG_ITEM_LEVEL_UPDATE',
}, 'char-frame-update-header', function()
    if (characterFrame.window and characterFrame.window:IsShown()) then
        characterFrame:UpdateHeader()
        characterFrame:UpdateBottomSlots()
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

characterFrame.SetupRotatingModel = function(self, characterModel, window)
    characterModel:SetCamDistanceScale(1.2)
    if characterModel.SetKeepModelOnHide then
        characterModel:SetKeepModelOnHide(true)
    end
    local rotation = math.rad(20)
    local ROTATION_SENSITIVITY = 0.05

    characterModel:SetRotation(rotation)

    characterModel:EnableMouse(true)

    -- PlayerModel does not follow parent Translation animations; hide during window dive/fade.
    local function HideModelForWindowAnim()
        characterModel:Hide()
    end

    local function ShowModelAfterWindowAnim()
        if (characterModel.unavailable) then
            return
        end
        characterModel:Show()
        characterModel:SetCamDistanceScale(1.2)
        characterModel:SetRotation(rotation)
        if characterModel.RefreshUnit then
            characterModel:RefreshUnit()
        end
    end

    if window.fadeIn then
        window.fadeIn:HookScript('OnPlay', HideModelForWindowAnim)
        window.fadeIn:HookScript('OnFinished', ShowModelAfterWindowAnim)
    end
    if window.fadeOut then
        window.fadeOut:HookScript('OnPlay', HideModelForWindowAnim)
    end

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
end

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

    button.bg:SetColorTexture(0, 0, 0, 0)
    button.underline:Show()

    if active then
        button.Text:SetVertexColor(unpack(theme.white))
        button.underline:SetColorTexture(theme.accent[1], theme.accent[2], theme.accent[3], 1)
        button.glow:SetVertexColor(theme.accent[1], theme.accent[2], theme.accent[3], 1)
        button.glow:Show()
    elseif hovered then
        button.Text:SetVertexColor(unpack(theme.white))
        button.underline:SetColorTexture(theme.border[1], theme.border[2], theme.border[3], 1)
        button.glow:Hide()
    else
        button.Text:SetVertexColor(unpack(theme.textMuted))
        button.underline:SetColorTexture(theme.border[1], theme.border[2], theme.border[3], 1)
        button.glow:Hide()
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
        button.bg:SetColorTexture(0, 0, 0, 0)

        button.Text = button:CreateFontString(nil, 'OVERLAY')
        button.Text:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
        button.Text:SetPoint('CENTER', 0, 0)
        button.Text:SetText(tabInfo.label)

        button.underline = button:CreateTexture(nil, 'OVERLAY')
        button.underline:SetHeight(1)
        button.underline:SetPoint('BOTTOMLEFT', button.Text, 'BOTTOMLEFT', -5, -6)
        button.underline:SetPoint('BOTTOMRIGHT', button.Text, 'BOTTOMRIGHT', 5, -6)

        button.glow = button:CreateTexture(nil, 'ARTWORK')
        button.glow:SetTexture(EXUI.const.textures.characterFrame.tabGlow)
        button.glow:SetHeight(20)
        button.glow:SetPoint('BOTTOMLEFT', button.underline, 'TOPLEFT', 0, 0)
        button.glow:SetPoint('BOTTOMRIGHT', button.underline, 'TOPRIGHT', 0, 0)
        button.glow:Hide()

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
    local theme = EXUI.const.theme
    local window = windowConstruct:Create({
        name = 'ExalityUICharacterFrame',
        size = {
            800,
            470
        },
        title = 'Exality',
        legacyChrome = {
            hideHeaderBar = true,
            close = {
                width = 38,
                height = 28,
                inset = { 8, 5 },
                buttonBg = EXUI.const.textures.characterFrame.input.buttonBg,
                closeIcon = EXUI.const.textures.frame.closeIcon,
                iconSize = 14,
                normalColor = theme.faded,
                hoverColor = theme.dangerHover,
            },
        },
    });
    self.window = window

    local cornerMask = window:CreateMaskTexture()
    cornerMask:SetAllPoints()
    cornerMask:SetTexture(WINDOW_BG, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    cornerMask:SetTextureSliceMargins(WINDOW_CORNER, WINDOW_CORNER, WINDOW_CORNER, WINDOW_CORNER)
    cornerMask:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)

    local backing = window:CreateTexture(nil, 'BACKGROUND', nil, 0)
    backing:SetAllPoints()
    backing:SetColorTexture(unpack(theme.backgroundDeep))
    backing:AddMaskTexture(cornerMask)
    backing:Hide()
    self.backgroundBacking = backing

    local background = window:CreateTexture(nil, 'BACKGROUND', nil, 1)
    background:SetAllPoints()
    background:Hide()
    self.background = background
    background:AddMaskTexture(cornerMask)
    window:HookScript('OnSizeChanged', function()
        characterFrame:FitBackground()
    end)

    local container = window.container
    local escapeHandler = CreateFrame('Button', nil, container)
    escapeHandler:EnableKeyboard(true)
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
    glow:SetVertexColor(1, 1, 1, 0.5)
    glow:SetAlpha(0.5)
    self.window.CharacterGlow = glow

    local characterModel = CreateFrame('PlayerModel', nil, modelFrame)
    self.window.CharacterModel = characterModel
    characterModel:SetAllPoints()
    characterModel:SetUnit('player')
    self:SetupRotatingModel(characterModel, window)

    local rightSlots = CreateFrame('Frame', nil, container)
    rightSlots:SetSize(38, 350)
    rightSlots:SetPoint('TOPLEFT', modelFrame, 'TOPRIGHT', 10, 0)

    local bottomSlots = CreateFrame('Frame', nil, container)
    bottomSlots:SetSize(82, SLOT_SIZE)
    bottomSlots:SetPoint('TOP', modelFrame, 'BOTTOM', 0, 0)
    self.bottomSlots = bottomSlots

    self:AddSlots(LEFT_SLOTS, leftSlots, 'LEFT')
    self:AddSlots(RIGHT_SLOTS, rightSlots, 'RIGHT')
    self.bottomSlotButtons = self:AddSlots(BottomSlotIds(), bottomSlots, 'BOTTOM')
    self:UpdateBottomSlots()

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

    -- Content inset from before the window chrome rework.
    container:ClearAllPoints()
    container:SetPoint('TOPLEFT', 15, -42)
    container:SetPoint('BOTTOMRIGHT', -15, 15)

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
    reputation:Create(window)

    window.onClose = function()
        sets:HideCreatePopup()
        currencies:Hide()
        reputation:Hide()
    end

    self:SetSideTab('stats')

    local toBlizzIcon = self:CreateToBlizzIcon(window)
    toBlizzIcon:SetPoint('TOPRIGHT', window.close, 'TOPLEFT', -5, 0)
    window:Hide()
end

characterFrame.OnShow = function(self)
    if (not characterFrame.isCreated) then
        self:Create()
        characterFrame.isCreated = true
    end
    self:UpdateHeader()
    self:UpdateBottomSlots()
    self:RefreshEquipment()
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
    inspect:Enable()
end

characterFrame.Disable = function(self)
    self.enabled = false
    inspect:Disable()
end

EXUI:RegisterEventHandler('PLAYER_REGEN_ENABLED', 'character-frame-bottom-slots', function()
    if characterFrame.bottomSlotsDirty then
        characterFrame:UpdateBottomSlots()
    end
end)

EXUI:RegisterEventHandler('PLAYER_REGEN_DISABLED', 'character-frame-hide', function()
    if (characterFrame.window and characterFrame.window:IsShown()) then
        characterFrame.window:HideWindowImmediate()
    end
end)
