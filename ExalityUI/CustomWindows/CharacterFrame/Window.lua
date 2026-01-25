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

---@class ExalityFramesTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

-------------------------

---@class EXUICharacterFrameWindow
local characterFrame = EXUI:GetModule('character-frame-window')

characterFrame.isCreated = false
characterFrame.window = nil

local LEFT_SLOTS = {
    1, 2, 3, 15, 5, 4, 19, 9
}
local RIGHT_SLOTS = {
    10, 6, 7, 8, 11, 12, 13, 14
}
local BOTTOM_SLOTS = {
    16, 17
}

local blizzFunc = nil

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


characterFrame.ReplaceBlizzFunc = function(self)
    if (not blizzFunc) then
        blizzFunc = ToggleCharacter
        ToggleCharacter = function(frameName)
            if (not CharacterFrame:IsShown() and frameName == 'PaperDollFrame') then
                self:OnShow()
            else
                blizzFunc(frameName)
            end
        end
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
end

characterFrame.RestoreBlizzFunc = function(self)
    if (blizzFunc) then
        ToggleCharacter = blizzFunc
        blizzFunc = nil
    end
end

characterFrame.Init = function(self)
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

    local avgIlvlString = WrapTextInColorCode(string.format('%.2f', avgEquipped), EXUI.utils.getIlvlColor(avgEquipped))
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
            if (blizzFunc) then
                blizzFunc('PaperDollFrame')
            end
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

characterFrame.Create = function(self)
    local window = windowConstruct:Create({
        size = {
            800,
            450
        },
        title = 'Exality'
    });
    self.window = window

    local container = window.container

    window:SetScript('OnKeyDown', function(self, key)
        if (key == 'ESCAPE') then
            self:HideWindow()
            return
        end
    end)
    window:SetPropagateKeyboardInput(true)
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
    modelFrame:SetSize(380, 350)
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
    bottomSlots:SetPoint('CENTER', modelFrame, 'BOTTOM', 0, 0)

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

    local statsFrame = CreateFrame('Frame', nil, container)
    statsFrame:SetPoint('TOPLEFT', rightSlots, 'TOPRIGHT', 25, 0)
    statsFrame:SetPoint('BOTTOMRIGHT')

    stats:Create(statsFrame)

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
    self:ReplaceBlizzFunc()
end

characterFrame.Disable = function(self)
    self:RestoreBlizzFunc()
end
