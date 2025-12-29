---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIWindowFrame
local windowConstruct = EXUI:GetModule('window-frame')

---@class EXUICharacterFrameEquipmentSlot
local equipmentSlot = EXUI:GetModule('character-frame-equipment-slot')

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')

---@class EXUICharacterFrameStats
local stats = EXUI:GetModule('character-frame-stats')

---@class EXUITooltipInput
local tooltip = EXUI:GetModule('frame-input-tooltip')

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

characterFrame.ReplaceBlizzFunc = function(self)
    if (not blizzFunc) then
        blizzFunc = ToggleCharacter
        ToggleCharacter = function()
            self:OnShow()
        end
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
    for _, slotId in ipairs(slots) do
        local slot = equipmentSlot:Create(slotId, side, parent)
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
    self.window.Header.ClassSpecText:SetText(string.format('%s %s', specName,
        C_ClassColor.GetClassColor(englishClass):WrapTextInColorCode(class)))

    local avgIlvlString = WrapTextInColorCode(string.format('%.2f', avgEquipped), EXUI.utils.getIlvlColor(avgEquipped))
    local avgEquippedString = WrapTextInColorCode(string.format('%.2f', avgEquipped),
        EXUI.utils.getIlvlColor(avgEquipped))
    if (avgIlvl ~= avgEquipped) then
        self.window.Header.Ilvl:SetText(string.format('%s / %s', avgEquippedString, avgIlvlString))
    else
        self.window.Header.Ilvl:SetText(avgEquippedString)
    end

    self.window:SetTitle(UnitPVPName("player"))
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
            500
        },
        title = 'Exality'
    });
    self.window = window

    local container = window.container

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

    local characterModel = CreateFrame('PlayerModel', nil, modelFrame)
    characterModel:SetAllPoints()
    characterModel:SetUnit('player')


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
    self.window:ShowWindow()
end

-- /run REMOVE_SHOW_CHAR_FRAME()
REMOVE_SHOW_CHAR_FRAME = function()
    characterFrame:OnShow()
end

characterFrame.Enable = function(self)
    self:ReplaceBlizzFunc()
end

characterFrame.Disable = function(self)
    self:RestoreBlizzFunc()
end
