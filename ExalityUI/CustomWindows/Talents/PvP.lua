---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUITalentsPvP
local pvp = EXUI:GetModule('talents-pvp')

local SIDEBAR_WIDTH = 290
local SIDEBAR_GAP = 6
local CONTENT_PAD = 10
local SLOT_COUNT = 3
local SLOT_WIDTH = 86
local SLOT_GAP = 6
local SLOT_ICON = 32
local SLOT_BORDER = SLOT_ICON * (96 / 82)
local SLOT_ROW_HEIGHT = 64
local WARMODE_ON = [[Interface/Addons/ExalityUI/Assets/Images/Talents/warmode-on.png]]
local WARMODE_OFF = [[Interface/Addons/ExalityUI/Assets/Images/Talents/warmode-off.png]]
local WARMODE_ICON = 36
local WARMODE_ROW = 40
local WARMODE_TOP = -30
local SLOT_TOP = WARMODE_TOP - WARMODE_ROW - 8
local ROW_ICON = 32
local ROW_BORDER = ROW_ICON * (96 / 82)
local ROW_HEIGHT = 40
local ROW_GAP = 2

local TEX = {
    selected = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-selected.png]],
    unselected = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-unselected.png]],
    mask = [[Interface/Addons/ExalityUI/Assets/Images/Talents/talent-mask.png]],
}

pvp.rows = {}
pvp.slots = {}
pvp.selectedSlot = nil
pvp.expectWarMode = nil

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function SafeText(value, fallback)
    if (value == nil or value == '' or IsSecret(value)) then
        return fallback or ''
    end
    return value
end

local function ThemeColor(key)
    return EXUI.const.theme[key]
end

local function Contains(list, id)
    if (not list) then
        return false
    end
    for index = 1, #list do
        if (list[index] == id) then
            return true
        end
    end
    return false
end

local function ActiveSpecGroup()
    return C_SpecializationInfo.GetActiveSpecGroup(true)
end

local function SlotInfo(index)
    return C_SpecializationInfo.GetPvpTalentSlotInfo(index)
end

local function UnlockLevel(index, info)
    local level = C_SpecializationInfo.GetPvpTalentSlotUnlockLevel and
        C_SpecializationInfo.GetPvpTalentSlotUnlockLevel(index)
    if (level == nil and info) then
        level = info.level
    end
    if (level == nil or IsSecret(level)) then
        return nil
    end
    return level
end

local function LockedLabel(level)
    if (type(level) ~= 'number') then
        return 'Locked'
    end
    if (PVP_TALENT_SLOT_LOCKED) then
        return PVP_TALENT_SLOT_LOCKED:format(level)
    end
    return 'Unlocks at level ' .. level
end

local function StyleIcon(parent, iconSize, borderSize)
    local icon = parent:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(iconSize, iconSize)
    icon:SetPoint('CENTER')
    parent.Icon = icon
    local mask = parent:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)
    local border = parent:CreateTexture(nil, 'OVERLAY')
    border:SetSize(borderSize, borderSize)
    border:SetPoint('CENTER')
    border:SetTexture(TEX.unselected)
    parent.Border = border
end

local function ApplyRowVisual(row, hovered)
    local theme = EXUI.const.theme
    if (row.selectedHere) then
        row.border:SetBorderColor(0.85, 0.7, 0.2, 1)
        row.bg:SetVertexColor(0.28, 0.22, 0.05, 0.75)
    elseif (hovered and row.canPick) then
        row.border:SetBorderColor(0.55, 0.55, 0.55, 1)
        row.bg:SetVertexColor(0.2, 0.2, 0.2, 0.7)
    else
        row.border:SetBorderColor(unpack(theme.border))
        row.bg:SetVertexColor(0, 0, 0, 0.55)
    end
end

local function WarModeDesired()
    if (pvp.expectWarMode ~= nil) then
        return pvp.expectWarMode
    end
    return C_PvP.IsWarModeDesired()
end

local function CanToggleWarMode()
    return C_PvP.CanToggleWarMode(not C_PvP.IsWarModeDesired())
end

local function ShowWarModeTooltip(owner)
    GameTooltip:SetOwner(owner, 'ANCHOR_RIGHT')
    local title = (type(PVP_LABEL_WAR_MODE) == 'string') and PVP_LABEL_WAR_MODE or 'War Mode'
    GameTooltip:SetText(title)

    local desired = WarModeDesired()
    if (C_PvP.IsWarModeActive() or desired) then
        if (type(PVP_WAR_MODE_ENABLED) == 'string') then
            GameTooltip:AddLine(PVP_WAR_MODE_ENABLED, 0.1, 1, 0.1, true)
        end
    end

    if (type(PVP_WAR_MODE_DESCRIPTION_FORMAT) == 'string') then
        local bonus = C_PvP.GetWarModeRewardBonus()
        if (type(bonus) == 'number') then
            GameTooltip:AddLine(PVP_WAR_MODE_DESCRIPTION_FORMAT:format(bonus), 1, 1, 1, true)
        end
    end

    local canOn = C_PvP.CanToggleWarMode(true)
    local canOff = C_PvP.CanToggleWarMode(false)
    if (not canOn or not canOff) then
        if (not C_PvP.ArePvpTalentsUnlocked()) then
            GameTooltip:AddLine(LockedLabel(C_PvP.GetPvpTalentsUnlockedLevel()), 1, 0.2, 0.2, true)
        else
            local warmodeErrorText
            if (not C_PvP.CanToggleWarModeInArea()) then
                local horde = PLAYER_FACTION_GROUP and UnitFactionGroup('player') == PLAYER_FACTION_GROUP[0]
                if (desired) then
                    if (not canOff and not IsResting()) then
                        warmodeErrorText = horde and PVP_WAR_MODE_NOT_NOW_HORDE_RESTAREA or
                            PVP_WAR_MODE_NOT_NOW_ALLIANCE_RESTAREA
                    end
                elseif (not canOn) then
                    warmodeErrorText = horde and PVP_WAR_MODE_NOT_NOW_HORDE or PVP_WAR_MODE_NOT_NOW_ALLIANCE
                end
            end
            if (type(warmodeErrorText) == 'string') then
                GameTooltip:AddLine(warmodeErrorText, 1, 0.2, 0.2, true)
            elseif (UnitAffectingCombat('player')) then
                GameTooltip:AddLine(SPELL_FAILED_AFFECTING_COMBAT or 'You are in combat', 1, 0.2, 0.2, true)
            end
        end
    end

    GameTooltip:Show()
end

local function BlizzardWarModeButton()
    if (not PlayerSpellsFrame and C_AddOns and C_AddOns.LoadAddOn) then
        C_AddOns.LoadAddOn('Blizzard_PlayerSpells')
    end
    local talents = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    return talents and talents.WarmodeButton
end

local function SyncWarModeClick(button)
    if (not button or InCombatLockdown()) then
        return
    end
    local delegate = BlizzardWarModeButton()
    if (delegate and CanToggleWarMode()) then
        button:SetAttribute('type', 'click')
        button:SetAttribute('clickbutton', delegate)
    else
        button:SetAttribute('type', nil)
        button:SetAttribute('clickbutton', nil)
    end
end

local function ApplyWarModeIcon(button)
    if (button and button.Icon) then
        button.Icon:SetTexture(WarModeDesired() and WARMODE_ON or WARMODE_OFF)
    end
end

local function CopyIds(source)
    local ids = {}
    if (not source) then
        return ids
    end
    for index = 1, #source do
        ids[index] = source[index]
    end
    return ids
end

local function SortTalents(ids, info, selectedIds)
    table.sort(ids, function(a, b)
        local infoA = C_SpecializationInfo.GetPvpTalentInfo(a)
        local infoB = C_SpecializationInfo.GetPvpTalentInfo(b)
        local unlockedA = infoA and infoA.unlocked and true or false
        local unlockedB = infoB and infoB.unlocked and true or false
        if (unlockedA ~= unlockedB) then
            return unlockedA and true or false
        end
        if (not unlockedA) then
            local levelA = C_SpecializationInfo.GetPvpTalentUnlockLevel(a) or 0
            local levelB = C_SpecializationInfo.GetPvpTalentUnlockLevel(b) or 0
            if (levelA ~= levelB) then
                return levelA < levelB
            end
        end
        local selectedA = Contains(selectedIds, a) and info.selectedTalentID ~= a
        local selectedB = Contains(selectedIds, b) and info.selectedTalentID ~= b
        if (selectedA ~= selectedB) then
            return selectedB and true or false
        end
        return a < b
    end)
end

pvp.SetButtonOpen = function(self, open)
    local button = self.button
    if (not button) then
        return
    end
    button.isOpen = open and true or false
    if (button.isOpen or button:IsMouseOver()) then
        button.Text:SetTextColor(1, 1, 1, 1)
        button.Icon:SetAlpha(1)
    else
        button.Text:SetTextColor(unpack(EXUI.const.theme.text))
        button.Icon:SetAlpha(0.85)
    end
end

pvp.Hide = function(self)
    if (self.sidebar) then
        self.sidebar:Hide()
    end
end

pvp.EnsureSelection = function(self)
    if (self.selectedSlot) then
        local info = SlotInfo(self.selectedSlot)
        if (info and info.enabled) then
            return
        end
    end
    self.selectedSlot = nil
    for index = 1, SLOT_COUNT do
        local info = SlotInfo(index)
        if (info and info.enabled) then
            self.selectedSlot = index
            return
        end
    end
end

pvp.UpdateButton = function(self)
    local button = self.button
    if (not button) then
        return
    end
    local canUse = true
    if (C_SpecializationInfo.CanPlayerUsePVPTalentUI) then
        canUse = C_SpecializationInfo.CanPlayerUsePVPTalentUI() and true or false
    end
    button:SetShown(canUse)
    if (not canUse) then
        self:Hide()
    end
    local talents = EXUI:GetModule('talents-window')
    local status = talents.statusText
    local anchor = canUse and button or self.importButton
    if (status and anchor and talents.resetButton) then
        status:ClearAllPoints()
        status:SetPoint('LEFT', talents.resetButton, 'RIGHT', 16, 0)
        status:SetPoint('RIGHT', anchor, 'LEFT', -8, 0)
        status:SetJustifyH('LEFT')
    end
end

pvp.UpdateWarMode = function(self)
    if (self.expectWarMode ~= nil and C_PvP.IsWarModeDesired() == self.expectWarMode) then
        self.expectWarMode = nil
    end
    ApplyWarModeIcon(self.warMode)
    SyncWarModeClick(self.warMode)
    if (GameTooltip:GetOwner() == self.warMode) then
        ShowWarModeTooltip(self.warMode)
    end
end

pvp.UpdateSlots = function(self)
    for index = 1, SLOT_COUNT do
        local button = self.slots[index]
        if (button) then
            local info = SlotInfo(index)
            local enabled = info and info.enabled
            local selected = self.selectedSlot == index
            local talent
            if (info and info.selectedTalentID) then
                talent = C_SpecializationInfo.GetPvpTalentInfo(info.selectedTalentID)
            end

            button.Border:SetTexture(selected and TEX.selected or TEX.unselected)
            button.Bg:SetVertexColor(0.2, 0.2, 0.2, selected and 0.85 or 0.35)

            if (talent) then
                if (talent.icon and not IsSecret(talent.icon)) then
                    button.Icon:SetTexture(talent.icon)
                    button.Icon:SetAlpha(1)
                else
                    button.Icon:SetAlpha(0)
                end
                button.Icon:SetDesaturated(false)
                if (talent.dependenciesUnmet) then
                    button.Icon:SetVertexColor(0.9, 0, 0)
                else
                    button.Icon:SetVertexColor(1, 1, 1)
                end
                button.Name:SetText(SafeText(talent.name, 'PvP Talent'))
                button.Name:SetTextColor(1, 1, 1, 1)
            elseif (enabled) then
                button.Icon:SetAlpha(0)
                button.Name:SetText(PVP_TALENT_SLOT_EMPTY or 'Empty')
                button.Name:SetTextColor(unpack(ThemeColor('text')))
            else
                button.Icon:SetAlpha(0)
                local level = UnlockLevel(index, info)
                button.Name:SetText(type(level) == 'number' and ('Lv ' .. level) or 'Locked')
                button.Name:SetTextColor(unpack(ThemeColor('textMuted')))
            end

            if (GameTooltip:GetOwner() == button) then
                button:GetScript('OnEnter')(button)
            end
        end
    end
end

pvp.AcquireRow = function(self, index)
    local row = self.rows[index]
    if (row) then
        return row
    end

    row = CreateFrame('Button', nil, self.scrollChild)
    row:SetHeight(ROW_HEIGHT)
    row:RegisterForClicks('LeftButtonUp')
    row.bg = row:CreateTexture(nil, 'BACKGROUND')
    row.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    row.bg:SetAllPoints()
    row.border = EXUI:AddPixelPerfectBorder(row, 1, { register = false, outwardBottom = false })
    row.border:SetBorderColor(unpack(ThemeColor('border')))

    local iconButton = CreateFrame('Frame', nil, row)
    StyleIcon(iconButton, ROW_ICON, ROW_BORDER)
    iconButton:SetSize(ROW_BORDER, ROW_BORDER)
    iconButton:SetPoint('LEFT', 6, 0)
    row.IconButton = iconButton

    local name = row:CreateFontString(nil, 'OVERLAY')
    name:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    name:SetPoint('LEFT', iconButton, 'RIGHT', 6, 0)
    name:SetPoint('RIGHT', -8, 0)
    name:SetJustifyH('LEFT')
    name:SetWordWrap(false)
    name:SetTextColor(unpack(ThemeColor('text')))
    row.Name = name

    row:SetScript('OnEnter', function(self)
        ApplyRowVisual(self, true)
        if (not self.talentID) then
            return
        end
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetPvpTalent(self.talentID, false, ActiveSpecGroup(), pvp.selectedSlot)
        if (self.dependenciesUnmet) then
            local reason = self.unmetReason
            if (IsSecret(reason) or type(reason) ~= 'string' or reason == '') then
                reason = TALENT_BUTTON_TOOLTIP_PVP_TALENT_REQUIREMENT_ERROR
            end
            if (type(reason) == 'string') then
                GameTooltip:AddLine(reason, 1, 0.2, 0.2, true)
            end
        end
        GameTooltip:Show()
    end)
    row:SetScript('OnLeave', function(self)
        ApplyRowVisual(self, false)
        GameTooltip:Hide()
    end)
    row:SetScript('OnClick', function(self)
        if (not self.canPick or self.selectedHere or not self.talentID or not pvp.selectedSlot) then
            return
        end
        if (LearnPvpTalent) then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            LearnPvpTalent(self.talentID, pvp.selectedSlot)
        end
        pvp:Refresh()
    end)

    self.rows[index] = row
    return row
end

pvp.UpdateList = function(self)
    if (not self.scrollChild) then
        return
    end

    local info = self.selectedSlot and SlotInfo(self.selectedSlot) or nil
    local selectedIds = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
    local ids = {}
    if (info and info.enabled) then
        ids = CopyIds(info.availableTalentIDs)
        SortTalents(ids, info, selectedIds)
    end

    local y = -2
    local rowIndex = 0
    if (#ids == 0) then
        local message = 'No PvP talents for this slot.'
        if (not info or not info.enabled) then
            message = LockedLabel(UnlockLevel(self.selectedSlot or 1, info))
        end
        self.emptyText:SetText(message)
        self.emptyText:ClearAllPoints()
        self.emptyText:SetPoint('TOPLEFT', 8, y - 8)
        self.emptyText:Show()
        local textHeight = self.emptyText:GetStringHeight()
        if (type(textHeight) ~= 'number' or textHeight < 14) then
            textHeight = 14
        end
        y = y - textHeight - 16
    else
        self.emptyText:Hide()
    end

    for _, talentID in ipairs(ids) do
        local talent = C_SpecializationInfo.GetPvpTalentInfo(talentID)
        if (talent) then
            rowIndex = rowIndex + 1
            local selectedHere = info.selectedTalentID == talentID
            local selectedOther = not selectedHere and Contains(selectedIds, talentID)
            local row = self:AcquireRow(rowIndex)
            row.talentID = talentID
            row.selectedHere = selectedHere
            row.canPick = talent.unlocked and not selectedOther
            row.dependenciesUnmet = talent.dependenciesUnmet
            row.unmetReason = talent.dependenciesUnmetReason

            if (talent.icon and not IsSecret(talent.icon)) then
                row.IconButton.Icon:SetTexture(talent.icon)
            end
            row.IconButton.Icon:SetDesaturated(not talent.unlocked)
            if (talent.dependenciesUnmet and talent.unlocked) then
                row.IconButton.Icon:SetVertexColor(0.9, 0, 0)
            else
                row.IconButton.Icon:SetVertexColor(1, 1, 1)
            end
            row.IconButton.Border:SetTexture(selectedHere and TEX.selected or TEX.unselected)
            row.Name:SetText(SafeText(talent.name, 'PvP Talent'))
            if (not talent.unlocked) then
                row.Name:SetTextColor(unpack(ThemeColor('textMuted')))
            elseif (selectedHere or selectedOther) then
                row.Name:SetTextColor(1, 0.82, 0, 1)
            else
                row.Name:SetTextColor(unpack(ThemeColor('text')))
            end
            row:SetAlpha(selectedOther and 0.4 or 1)
            ApplyRowVisual(row, false)
            row:ClearAllPoints()
            row:SetPoint('TOPLEFT', 2, y)
            row:SetPoint('RIGHT', -2, 0)
            row:Show()
            y = y - ROW_HEIGHT - ROW_GAP
        end
    end

    for index = rowIndex + 1, #self.rows do
        self.rows[index]:Hide()
    end

    local height = math.max(-y + 8, 1)
    self.scrollChild:SetHeight(height)
    if (self.listScroll) then
        local slotChanged = self.listSlot ~= self.selectedSlot
        self.listSlot = self.selectedSlot
        self.listScroll:UpdateScrollChild(nil, height)
        if (slotChanged and self.listScroll.SetVerticalScroll) then
            self.listScroll:SetVerticalScroll(0)
        end
    end
end

pvp.Refresh = function(self)
    if (not self.sidebar) then
        return
    end
    self:EnsureSelection()
    self:UpdateWarMode()
    self:UpdateSlots()
    self:UpdateList()
end

pvp.Toggle = function(self)
    if (not self.sidebar) then
        return
    end
    if (self.sidebar:IsShown()) then
        self.sidebar:Hide()
        return
    end
    local builds = EXUI:GetModule('talents-builds')
    if (builds.sidebar and builds.sidebar:IsShown()) then
        builds.sidebar:Hide()
        if (builds.HideEdit) then
            builds:HideEdit()
        end
    end
    self.sidebar:Show()
end

local function CreateSlotButton(parent, index)
    local button = CreateFrame('Button', nil, parent)
    button:SetSize(SLOT_WIDTH, SLOT_ROW_HEIGHT)
    button:SetClipsChildren(true)
    button.slotIndex = index

    local bg = button:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.35)
    button.Bg = bg

    local iconAnchor = CreateFrame('Frame', nil, button)
    iconAnchor:SetSize(SLOT_BORDER, SLOT_BORDER)
    iconAnchor:SetPoint('TOP', 0, -2)
    StyleIcon(iconAnchor, SLOT_ICON, SLOT_BORDER)
    button.Icon = iconAnchor.Icon
    button.Border = iconAnchor.Border

    local name = button:CreateFontString(nil, 'OVERLAY')
    name:SetFont(EXFrames.assets.font.default(), 10, 'OUTLINE')
    name:SetPoint('TOPLEFT', 2, -(SLOT_BORDER + 4))
    name:SetPoint('TOPRIGHT', -2, -(SLOT_BORDER + 4))
    name:SetJustifyH('CENTER')
    name:SetWordWrap(false)
    name:SetTextColor(unpack(ThemeColor('text')))
    button.Name = name

    button:SetScript('OnClick', function(self)
        local info = SlotInfo(self.slotIndex)
        if (not info or not info.enabled) then
            return
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        pvp.selectedSlot = self.slotIndex
        pvp:Refresh()
    end)
    button:SetScript('OnEnter', function(self)
        local info = SlotInfo(self.slotIndex)
        if (not info) then
            return
        end
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        if (info.selectedTalentID) then
            GameTooltip:SetPvpTalent(info.selectedTalentID, false, ActiveSpecGroup(), self.slotIndex)
            local talent = C_SpecializationInfo.GetPvpTalentInfo(info.selectedTalentID)
            if (talent and talent.dependenciesUnmet) then
                local reason = talent.dependenciesUnmetReason
                if (IsSecret(reason) or type(reason) ~= 'string' or reason == '') then
                    reason = TALENT_BUTTON_TOOLTIP_PVP_TALENT_REQUIREMENT_ERROR
                end
                if (type(reason) == 'string') then
                    GameTooltip:AddLine(reason, 1, 0.2, 0.2, true)
                end
            end
        else
            GameTooltip:SetText(PVP_TALENT_SLOT or 'PvP Talent')
            if (not info.enabled) then
                GameTooltip:AddLine(LockedLabel(UnlockLevel(self.slotIndex, info)), 1, 0.2, 0.2, true)
            elseif (type(PVP_TALENT_SLOT_EMPTY) == 'string') then
                GameTooltip:AddLine(PVP_TALENT_SLOT_EMPTY, 0.1, 1, 0.1, true)
            end
        end
        GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    button:SetPoint('LEFT', (index - 1) * (SLOT_WIDTH + SLOT_GAP), 0)
    return button
end

pvp.Create = function(self, window)
    local sidebar = CreateFrame('Frame', nil, window)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetPoint('TOPLEFT', window, 'TOPRIGHT', SIDEBAR_GAP, 0)
    sidebar:SetPoint('BOTTOMLEFT', window, 'BOTTOMRIGHT', SIDEBAR_GAP, 0)
    sidebar:SetFrameLevel(window:GetFrameLevel() + 5)
    sidebar:EnableMouse(true)
    sidebar:Hide()
    sidebar:SetScript('OnShow', function()
        pvp:SetButtonOpen(true)
        pvp:EnsureSelection()
        pvp:Refresh()
    end)
    sidebar:SetScript('OnHide', function()
        pvp:SetButtonOpen(false)
        if (GameTooltip:GetOwner() == pvp.warMode) then
            GameTooltip:Hide()
        end
    end)
    self.sidebar = sidebar

    local theme = EXUI.const.theme
    local bg = sidebar:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXFrames.assets.textures.ui.panelBg)
    bg:SetVertexColor(unpack(theme.backgroundDeep))
    bg:SetAlpha(0.8)
    bg:SetTextureSliceMargins(8, 8, 8, 8)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAllPoints()

    local border = sidebar:CreateTexture(nil, 'OVERLAY', nil, 1)
    border:SetTexture(EXFrames.assets.textures.ui.panelBorder)
    border:SetVertexColor(0, 0, 0)
    border:SetAlpha(0.8)
    border:SetTextureSliceMargins(8, 8, 8, 8)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    border:SetAllPoints()

    local title = sidebar:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    title:SetPoint('TOPLEFT', CONTENT_PAD, -10)
    title:SetText('PvP')
    title:SetTextColor(unpack(theme.text))

    local warMode = CreateFrame('Button', nil, sidebar, 'SecureActionButtonTemplate')
    warMode:SetHeight(WARMODE_ROW)
    warMode:SetPoint('TOPLEFT', CONTENT_PAD, WARMODE_TOP)
    warMode:SetPoint('RIGHT', sidebar, 'RIGHT', -CONTENT_PAD, 0)
    warMode:RegisterForClicks('LeftButtonUp')
    if (not InCombatLockdown()) then
        warMode:SetAttribute('useOnKeyDown', false)
    end

    local warModeIcon = warMode:CreateTexture(nil, 'ARTWORK')
    warModeIcon:SetTexture(WARMODE_OFF)
    warModeIcon:SetSize(WARMODE_ICON, WARMODE_ICON)
    warModeIcon:SetPoint('LEFT', 0, 0)
    warMode.Icon = warModeIcon

    local warModeLabel = warMode:CreateFontString(nil, 'OVERLAY')
    warModeLabel:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    warModeLabel:SetPoint('LEFT', warModeIcon, 'RIGHT', 8, 0)
    warModeLabel:SetText((type(PVP_LABEL_WAR_MODE) == 'string') and PVP_LABEL_WAR_MODE or 'War Mode')
    warModeLabel:SetTextColor(unpack(theme.text))
    warMode.Label = warModeLabel

    warMode:SetScript('PreClick', function(self)
        if (not CanToggleWarMode()) then
            self.pendingWarMode = nil
            return
        end
        self.pendingWarMode = not C_PvP.IsWarModeDesired()
    end)
    warMode:SetScript('PostClick', function(self)
        local pending = self.pendingWarMode
        self.pendingWarMode = nil
        if (pending ~= nil and C_PvP.IsWarModeDesired() ~= pending) then
            pvp.expectWarMode = pending
        else
            pvp.expectWarMode = nil
        end
        pvp:UpdateWarMode()
    end)
    warMode:SetScript('OnEnter', function(self)
        self.Label:SetTextColor(1, 1, 1, 1)
        ShowWarModeTooltip(self)
    end)
    warMode:SetScript('OnLeave', function(self)
        self.Label:SetTextColor(unpack(EXUI.const.theme.text))
        GameTooltip:Hide()
    end)
    self.warMode = warMode
    SyncWarModeClick(warMode)
    ApplyWarModeIcon(warMode)

    local slotRow = CreateFrame('Frame', nil, sidebar)
    slotRow:SetPoint('TOPLEFT', CONTENT_PAD, SLOT_TOP)
    slotRow:SetSize(SLOT_COUNT * SLOT_WIDTH + (SLOT_COUNT - 1) * SLOT_GAP, SLOT_ROW_HEIGHT)
    for index = 1, SLOT_COUNT do
        self.slots[index] = CreateSlotButton(slotRow, index)
    end

    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scroll:SetParent(sidebar)
    scroll:SetPoint('TOPLEFT', CONTENT_PAD, SLOT_TOP - SLOT_ROW_HEIGHT - 8)
    scroll:SetPoint('BOTTOMRIGHT', -CONTENT_PAD, CONTENT_PAD)
    self.listScroll = scroll
    self.scrollChild = scroll.child

    local emptyText = scroll.child:CreateFontString(nil, 'OVERLAY')
    emptyText:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')
    emptyText:SetTextColor(unpack(ThemeColor('textMuted')))
    emptyText:SetJustifyH('LEFT')
    emptyText:SetWidth(SIDEBAR_WIDTH - CONTENT_PAD * 2 - 16)
    emptyText:SetWordWrap(true)
    emptyText:Hide()
    self.emptyText = emptyText
end

local function OnPvpEvent(event)
    if (event == 'PLAYER_FLAGS_CHANGED' or event == 'WAR_MODE_STATUS_UPDATE') then
        pvp.expectWarMode = nil
    end
    if (not pvp.button) then
        return
    end
    pvp:UpdateButton()
    if (pvp.sidebar and pvp.sidebar:IsVisible()) then
        pvp:Refresh()
    end
end

EXUI:RegisterEventHandler({
    'PLAYER_PVP_TALENT_UPDATE',
    'WAR_MODE_STATUS_UPDATE',
    'PLAYER_FLAGS_CHANGED',
    'ZONE_CHANGED',
    'ZONE_CHANGED_NEW_AREA',
    'ACTIVE_PLAYER_SPECIALIZATION_CHANGED',
    'PLAYER_LEVEL_CHANGED',
    'TRAIT_CONFIG_UPDATED',
}, 'talents-pvp-refresh', OnPvpEvent)
