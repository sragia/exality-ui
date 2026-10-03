---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

local ICON_SIZE = 36
local BORDER_SIZE = ICON_SIZE * (96 / 82)
local ROW_HEIGHT = 56
local HEADER_HEIGHT = BORDER_SIZE
local ROW_GAP = 8
local COLUMNS = 3
local COL_GAP = 16
local SECTION_GAP = 6
local HEADER_GAP = 4
local PAD_X = 4
local TEXT_GAP = 8
local TAB_HEIGHT = 26
local TAB_GAP = 8
local UNPICKED_COLOR = 0.4
local TAB_ORDER = { 'class', 'general', 'pet' }

local TEX = {
    available = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-available.png]],
    selected = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-selected.png]],
    unselected = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-unselected.png]],
    missing = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-missing.png]],
    mask = [[Interface/Addons/ExalityUI/Assets/Images/Talents/talent-mask.png]],
    hover = [[Interface/Addons/ExalityUI/Assets/Images/Talents/hover-glow.png]],
    multiRight = [[Interface/Addons/ExalityUI/Assets/Images/Talents/multi-right.png]],
}

local ARROW_WIDTH = 16
local ARROW_HEIGHT = 17
local FLYOUT_GAP = 6
local PASSIVE_NAME = { 196 / 255, 188 / 255, 178 / 255, 1 }

local CD_FONT = CreateFont('ExalityUI_SpellBook_CD_Font')
CD_FONT:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')

local HideFlyout
local ToggleFlyout
local SetArrowOpen

---@class EXUITalentsSpellBook
local spellBook = EXUI:GetModule('talents-spellbook')

spellBook.rows = {}
spellBook.headers = {}
spellBook.scrollChild = nil
spellBook.activeTab = 'class'
spellBook.refreshing = false

local function PickupRow(row)
    if (not row.slotIndex) then
        return
    end
    C_SpellBook.PickupSpellBookItem(row.slotIndex, row.spellBank)
end

local function ShowRowTooltip(row)
    if (not row.slotIndex) then
        return
    end
    GameTooltip:SetOwner(row.IconFrame, 'ANCHOR_RIGHT')
    GameTooltip:SetSpellBookItem(row.slotIndex, row.spellBank)
    GameTooltip:Show()
end

local HOVER_FADE = 0.12

local function PrepareHover(highlight)
    highlight:SetAlpha(0)
    highlight:Show()
    local group = highlight:CreateAnimationGroup()
    local anim = group:CreateAnimation('Alpha')
    anim:SetDuration(HOVER_FADE)
    group:SetScript('OnFinished', function()
        highlight:SetAlpha(highlight.hoverTarget or 0)
    end)
    highlight.hoverTarget = 0
    highlight.HoverGroup = group
    highlight.HoverAnim = anim
end

local function SetHover(highlight, shown)
    local target = shown and 1 or 0
    local group = highlight.HoverGroup
    local anim = highlight.HoverAnim
    local from = highlight:GetAlpha()
    if (group:IsPlaying()) then
        local progress = group:GetProgress() or 0
        from = anim:GetFromAlpha() + (anim:GetToAlpha() - anim:GetFromAlpha()) * progress
        group:Stop()
    end
    highlight.hoverTarget = target
    if (math.abs(from - target) < 0.01) then
        highlight:SetAlpha(target)
        return
    end
    highlight:SetAlpha(from)
    anim:SetFromAlpha(from)
    anim:SetToAlpha(target)
    anim:SetSmoothing(shown and 'IN' or 'OUT')
    group:Play()
end

local function PlaceCooldownText(cooldown)
    local countdown = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
    local borderFrame = cooldown.borderFrame
    if (not countdown or not borderFrame) then
        return
    end
    if (countdown:GetParent() ~= borderFrame) then
        countdown:SetParent(borderFrame)
        countdown:SetDrawLayer('OVERLAY', 7)
    end
    if (cooldown.textAnchored) then
        return
    end
    countdown:ClearAllPoints()
    countdown:SetPoint('BOTTOMLEFT', cooldown, 'BOTTOMLEFT', 3, 2)
    countdown:SetJustifyH('LEFT')
    cooldown.textAnchored = true
end

local function CreateIconCooldown(iconFrame)
    local cooldown = CreateFrame('Cooldown', nil, iconFrame, 'CooldownFrameTemplate')
    cooldown:ClearAllPoints()
    cooldown:SetSize(ICON_SIZE, ICON_SIZE)
    cooldown:SetPoint('CENTER')
    cooldown:SetFrameLevel(iconFrame:GetFrameLevel() + 1)
    cooldown:EnableMouse(false)
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawBling(false)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:SetCountdownFont('ExalityUI_SpellBook_CD_Font')

    local borderFrame = CreateFrame('Frame', nil, iconFrame)
    borderFrame:SetAllPoints()
    borderFrame:SetFrameLevel(cooldown:GetFrameLevel() + 2)
    borderFrame:EnableMouse(false)
    local hover = borderFrame:CreateTexture(nil, 'ARTWORK', nil, 1)
    hover:SetSize(ICON_SIZE, ICON_SIZE)
    hover:SetPoint('CENTER')
    hover:SetTexture(TEX.hover)
    hover:SetBlendMode('ADD')
    local hoverMask = borderFrame:CreateMaskTexture()
    hoverMask:SetAllPoints(hover)
    hoverMask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    hover:AddMaskTexture(hoverMask)
    PrepareHover(hover)

    local border = borderFrame:CreateTexture(nil, 'OVERLAY')
    border:SetAllPoints()
    border:SetTexture(TEX.selected)
    cooldown.borderFrame = borderFrame
    cooldown.Hover = hover
    cooldown:HookScript('OnHide', function(self)
        local countdown = self.GetCountdownFontString and self:GetCountdownFontString()
        if (countdown) then
            countdown:Hide()
        end
    end)
    PlaceCooldownText(cooldown)

    return cooldown, border
end

local function SetCooldownDuration(cooldown, duration)
    if (not cooldown) then
        return
    end
    if (duration) then
        cooldown:SetCooldownFromDurationObject(duration)
    else
        cooldown:Clear()
    end
    PlaceCooldownText(cooldown)
end

local function ClearCastAttributes(button)
    if (InCombatLockdown()) then
        return
    end
    button:SetAttribute('type1', nil)
    button:SetAttribute('spell', nil)
    button:SetAttribute('action', nil)
    button:SetAttribute('type2', nil)
    button:SetAttribute('macrotext2', nil)
end

local function ApplyCastAttributes(button, info, bank, unusable)
    ClearCastAttributes(button)
    if (InCombatLockdown() or not info) then
        return
    end
    local isFlyout = info.itemType == Enum.SpellBookItemType.Flyout
    if (unusable or info.isPassive or isFlyout) then
        return
    end
    if (info.itemType == Enum.SpellBookItemType.PetAction and info.actionID) then
        button:SetAttribute('type1', 'pet')
        button:SetAttribute('action', info.actionID)
    elseif (info.spellID and info.spellID ~= 0) then
        button:SetAttribute('type1', 'spell')
        button:SetAttribute('spell', info.spellID)
    end
    if (bank == Enum.SpellBookSpellBank.Pet and info.name and info.name ~= '') then
        button:SetAttribute('type2', 'macro')
        button:SetAttribute('macrotext2', '/petautocasttoggle ' .. info.name)
    end
end

local function PrepareSecureButton(button)
    button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    button:RegisterForDrag('LeftButton')
    if (InCombatLockdown()) then
        return
    end
    button:SetAttribute('useOnKeyDown', false)
    button:SetAttribute('checkselfcast', true)
    button:SetAttribute('shift-type1', ATTRIBUTE_NOOP)
    button:SetAttribute('shift-type2', ATTRIBUTE_NOOP)
end

local function UpdateRowCooldown(row)
    if (not row.Cooldown) then
        return
    end
    if (not row:IsShown() or not row.slotIndex or not row.spellBank or row.isPassive) then
        row.Cooldown:Clear()
        return
    end
    local duration = C_SpellBook.GetSpellBookItemCooldownDuration(row.slotIndex, row.spellBank, true)
    SetCooldownDuration(row.Cooldown, duration)
end

local function UpdateSpellCooldown(cooldown, spellID)
    if (not cooldown) then
        return
    end
    if (not spellID) then
        cooldown:Clear()
        return
    end
    local duration = C_Spell.GetSpellCooldownDuration(spellID, true)
    SetCooldownDuration(cooldown, duration)
end

local function ApplyTabVisual(button, active, hovered)
    local theme = EXUI.const.theme
    button.tabActive = active
    local textColor = theme.textMuted
    local lineColor = theme.border
    if (active) then
        textColor = theme.text
        lineColor = hovered and theme.accentLight or theme.accent
    elseif (hovered) then
        textColor = theme.text
        lineColor = theme.accentLight
    end
    button.Text:SetTextColor(textColor[1], textColor[2], textColor[3], 1)
    button.Underline:SetColorTexture(lineColor[1], lineColor[2], lineColor[3], 1)
    button.Glow:SetVertexColor(lineColor[1], lineColor[2], lineColor[3], 1)
    button.Glow:SetShown(active or hovered)
end

local function ResizeTab(button)
    local label = button.Text:GetText() or ''
    local textWidth = button.Text:GetStringWidth()
    if (type(textWidth) ~= 'number' or textWidth < 8) then
        textWidth = #label * 7
    end
    button:SetSize(math.max(80, textWidth + 24), TAB_HEIGHT)
end

local function CreateTabButton(parent, id)
    local theme = EXUI.const.theme
    local button = CreateFrame('Button', nil, parent)
    button:SetSize(80, TAB_HEIGHT)
    local text = button:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    text:SetPoint('CENTER', 0, 2)
    text:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    button.Text = text
    local underline = button:CreateTexture(nil, 'OVERLAY')
    underline:SetHeight(2)
    underline:SetPoint('BOTTOMLEFT', 8, 0)
    underline:SetPoint('BOTTOMRIGHT', -8, 0)
    underline:SetColorTexture(theme.border[1], theme.border[2], theme.border[3], 1)
    button.Underline = underline
    local glow = button:CreateTexture(nil, 'ARTWORK')
    glow:SetTexture(EXUI.const.textures.characterFrame.tabGlow)
    glow:SetHeight(20)
    glow:SetPoint('BOTTOMLEFT', underline, 'TOPLEFT', 0, 0)
    glow:SetPoint('BOTTOMRIGHT', underline, 'TOPRIGHT', 0, 0)
    glow:Hide()
    button.Glow = glow
    button.tabID = id
    ApplyTabVisual(button, false, false)
    button:SetScript('OnEnter', function(self)
        ApplyTabVisual(self, self.tabActive, true)
    end)
    button:SetScript('OnLeave', function(self)
        ApplyTabVisual(self, self.tabActive, false)
    end)
    button:SetScript('OnClick', function(self)
        spellBook.activeTab = self.tabID
        spellBook:Refresh()
    end)
    return button
end

local function CreateRow(parent)
    local row = CreateFrame('Button', nil, parent, 'SecureActionButtonTemplate')
    row:SetHeight(ROW_HEIGHT)
    PrepareSecureButton(row)

    local iconFrame = CreateFrame('Frame', nil, row)
    iconFrame:SetSize(BORDER_SIZE, BORDER_SIZE)
    iconFrame:SetPoint('LEFT', PAD_X, 0)
    iconFrame:EnableMouse(false)
    row.IconFrame = iconFrame

    local icon = iconFrame:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint('CENTER')
    local mask = iconFrame:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)
    row.Icon = icon

    local cooldown, border = CreateIconCooldown(iconFrame)
    row.Cooldown = cooldown
    row.Border = border
    row.Highlight = cooldown.Hover

    local name = row:CreateFontString(nil, 'OVERLAY')
    name:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    name:SetPoint('TOPLEFT', iconFrame, 'TOPRIGHT', TEXT_GAP, -2)
    name:SetJustifyH('LEFT')
    name:SetJustifyV('TOP')
    name:SetWordWrap(false)
    name:SetMaxLines(1)
    row.Name = name

    local description = row:CreateFontString(nil, 'OVERLAY')
    description:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    description:SetPoint('TOPLEFT', name, 'BOTTOMLEFT', 0, -2)
    description:SetJustifyH('LEFT')
    description:SetJustifyV('TOP')
    description:SetWordWrap(true)
    description:SetMaxLines(2)
    row.Description = description

    local arrow = CreateFrame('Button', nil, row)
    arrow:SetSize(ARROW_WIDTH, ARROW_HEIGHT)
    arrow:SetPoint('RIGHT', icon, 'RIGHT', 8, 0)
    arrow:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    arrow:RegisterForDrag('LeftButton')
    local arrowTex = arrow:CreateTexture(nil, 'OVERLAY')
    arrowTex:SetAllPoints()
    arrowTex:SetTexture(TEX.multiRight)
    arrow.Texture = arrowTex
    arrow:SetFrameLevel(row:GetFrameLevel() + 10)
    arrow:SetScript('OnClick', function()
        ToggleFlyout(row)
    end)
    arrow:SetScript('OnDragStart', function()
        PickupRow(row)
    end)
    arrow:SetScript('OnEnter', function()
        SetHover(row.Highlight, true)
        ShowRowTooltip(row)
    end)
    arrow:SetScript('OnLeave', function()
        if (not row.missing and not row:IsMouseOver()) then
            SetHover(row.Highlight, false)
        end
        GameTooltip:Hide()
    end)
    arrow:Hide()
    row.Arrow = arrow

    row:SetScript('OnEnter', function(self)
        SetHover(self.Highlight, true)
        ShowRowTooltip(self)
    end)
    row:SetScript('OnLeave', function(self)
        if (not self.missing and not self.Arrow:IsMouseOver()) then
            SetHover(self.Highlight, false)
        end
        GameTooltip:Hide()
    end)
    row:SetScript('PreClick', function(self, button, down)
        if (down) then
            return
        end
        if (IsModifiedClick('CHATLINK')) then
            local link = self.slotIndex and C_SpellBook.GetSpellBookItemLink(self.slotIndex, self.spellBank)
            if (link and ChatFrameUtil) then
                ChatFrameUtil.InsertLink(link)
            end
            return
        end
        if (IsModifiedClick('PICKUPACTION')) then
            PickupRow(self)
            return
        end
        if (self.isFlyout) then
            ToggleFlyout(self)
            return
        end
        HideFlyout()
    end)
    row:SetScript('OnDragStart', function(self)
        PickupRow(self)
    end)

    return row
end

local function CreateHeader(parent)
    local header = CreateFrame('Frame', nil, parent)
    header:SetHeight(HEADER_HEIGHT)

    local iconFrame = CreateFrame('Frame', nil, header)
    iconFrame:SetSize(BORDER_SIZE, BORDER_SIZE)
    iconFrame:SetPoint('LEFT', 0, 0)

    local icon = iconFrame:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint('CENTER')
    local mask = iconFrame:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)
    header.Icon = icon

    local border = iconFrame:CreateTexture(nil, 'OVERLAY')
    border:SetSize(BORDER_SIZE, BORDER_SIZE)
    border:SetPoint('CENTER')
    border:SetTexture(TEX.selected)
    header.Border = border

    local name = header:CreateFontString(nil, 'OVERLAY')
    name:SetFont(EXUI.const.fonts.DEFAULT, 14, 'OUTLINE')
    name:SetPoint('LEFT', iconFrame, 'RIGHT', TEXT_GAP, 0)
    name:SetPoint('RIGHT', -4, 0)
    name:SetJustifyH('LEFT')
    name:SetWordWrap(false)
    name:SetMaxLines(1)
    local theme = EXUI.const.theme
    name:SetTextColor(theme.accent[1], theme.accent[2], theme.accent[3], 1)
    header.Name = name
    return header
end

local function AcquireRow(self)
    local index = self.rowCount + 1
    local row = self.rows[index]
    if (not row) then
        row = CreateRow(self.scrollChild)
        self.rows[index] = row
    end
    row:Show()
    self.rowCount = index
    return row
end

local function AcquireHeader(self)
    local index = self.headerCount + 1
    local header = self.headers[index]
    if (not header) then
        header = CreateHeader(self.scrollChild)
        self.headers[index] = header
    end
    header:Show()
    self.headerCount = index
    return header
end

local function SetDescription(row, spellID)
    row.spellID = spellID
    if (not spellID) then
        row.Description:SetText('')
        return
    end
    local spell = Spell:CreateFromSpellID(spellID)
    if (spell:IsSpellEmpty()) then
        row.Description:SetText('')
        return
    end
    if (not spell:IsSpellDataCached()) then
        row.Description:SetText('')
        spell:ContinueOnSpellLoad(function()
            if (row.spellID ~= spellID) then
                return
            end
            row.Description:SetText(C_Spell.GetSpellDescription(spellID) or '')
        end)
        return
    end
    row.Description:SetText(C_Spell.GetSpellDescription(spellID) or '')
end

local function CollectSpells(line, bank)
    local spells = {}
    if (not line or line.shouldHide or line.isGuild or line.numSpellBookItems <= 0) then
        return spells
    end
    local firstSlot = line.itemIndexOffset + 1
    local lastSlot = line.itemIndexOffset + line.numSpellBookItems
    for slot = firstSlot, lastSlot do
        local info = C_SpellBook.GetSpellBookItemInfo(slot, bank)
        if (info and not info.isOffSpec and info.itemType ~= Enum.SpellBookItemType.FutureSpell and info.name and info.name ~= '') then
            spells[#spells + 1] = {
                slot = slot,
                info = info,
                isOffSpec = line.offSpecID ~= nil,
                specID = line.specID,
            }
        end
    end
    return spells
end

local function PetBookAvailable()
    return C_SpellBook.HasPetSpells() and PetHasSpellbook
end

local function ClassIcon()
    local _, classFile = UnitClass('player')
    if (classFile and GetClassAtlas) then
        return GetClassAtlas(classFile)
    end
end

local function SpecIcon(specID, fallback)
    if (specID and C_SpecializationInfo.GetSpecializationInfoForSpecID) then
        local _, _, _, icon = C_SpecializationInfo.GetSpecializationInfoForSpecID(specID)
        if (icon and icon ~= 0) then
            return icon
        end
    end
    return fallback
end

local function SetBorderIcon(icon, border, image, dimmed)
    if (type(image) == 'string') then
        icon:SetAtlas(image)
    else
        icon:SetTexture(image)
    end
    icon:SetDesaturated(dimmed and true or false)
    if (dimmed) then
        icon:SetVertexColor(UNPICKED_COLOR, UNPICKED_COLOR, UNPICKED_COLOR)
        border:SetTexture(TEX.unselected)
    else
        icon:SetVertexColor(1, 1, 1)
        border:SetTexture(TEX.selected)
    end
    border:SetVertexColor(1, 1, 1)
end

local function BuildSections(tab)
    local sections = {}
    local bank = Enum.SpellBookSpellBank.Player
    if (tab == 'pet') then
        bank = Enum.SpellBookSpellBank.Pet
        local count = C_SpellBook.HasPetSpells() or 0
        local spells = {}
        for slot = 1, count do
            local info = C_SpellBook.GetSpellBookItemInfo(slot, bank)
            if (info and info.itemType ~= Enum.SpellBookItemType.FutureSpell and info.name and info.name ~= '') then
                spells[#spells + 1] = {
                    slot = slot,
                    info = info,
                }
            end
        end
        if (#spells > 0) then
            sections[1] = { spells = spells }
        end
        return sections, bank
    end

    if (tab == 'general') then
        local line = C_SpellBook.GetSpellBookSkillLineInfo(Enum.SpellBookSkillLineIndex.General)
        local spells = CollectSpells(line, bank)
        if (#spells > 0) then
            sections[1] = { spells = spells }
        end
        return sections, bank
    end

    local classLine = C_SpellBook.GetSpellBookSkillLineInfo(Enum.SpellBookSkillLineIndex.Class)
    local classSpells = CollectSpells(classLine, bank)
    if (#classSpells > 0) then
        sections[#sections + 1] = {
            name = classLine.name,
            icon = ClassIcon() or classLine.iconID,
            spells = classSpells,
        }
    end

    local numSpecializations = GetNumSpecializations(false, false)
    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    local firstSpec = Enum.SpellBookSkillLineIndex.MainSpec
    local maxSpec = math.min(numLines, firstSpec + numSpecializations)
    for skillLineIndex = firstSpec, maxSpec do
        local line = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
        if (line and line.offSpecID ~= nil) then
            line = nil
        end
        local spells = CollectSpells(line, bank)
        if (#spells > 0) then
            sections[#sections + 1] = {
                name = line.name,
                icon = SpecIcon(line.specID, line.iconID),
                isOffSpec = line.offSpecID ~= nil,
                spells = spells,
            }
        end
    end
    return sections, bank
end

local function TabLabel(id)
    if (id == 'class') then
        return PlayerUtil.GetClassName() or 'Class'
    end
    if (id == 'general') then
        return GENERAL_SPELLS
    end
    return PET
end

local function LayoutTabs(self)
    local x = 0
    local height = 1
    for _, id in ipairs(TAB_ORDER) do
        local button = self.tabButtons[id]
        if (button:IsShown()) then
            button:ClearAllPoints()
            button:SetPoint('LEFT', self.tabBar, 'LEFT', x, 0)
            x = x + button:GetWidth() + TAB_GAP
            height = button:GetHeight()
        end
    end
    if (x > 0) then
        x = x - TAB_GAP
    end
    self.tabBar:SetSize(math.max(x, 1), height)
end

local function UpdateTabs(self)
    local petAvailable = PetBookAvailable()
    if (self.activeTab == 'pet' and not petAvailable) then
        self.activeTab = 'class'
    end
    for _, id in ipairs(TAB_ORDER) do
        local button = self.tabButtons[id]
        local shown = id ~= 'pet' or petAvailable
        button:SetShown(shown)
        if (shown) then
            button.Text:SetText(TabLabel(id))
            ResizeTab(button)
            ApplyTabVisual(button, id == self.activeTab, button:IsMouseOver())
        end
    end
    LayoutTabs(self)
end

local function IsMissingFromBars(info)
    if (not info or info.isPassive or info.isOffSpec or not ActionButtonUtil) then
        return false
    end
    local status
    local itemType = info.itemType
    if (itemType == Enum.SpellBookItemType.Spell) then
        if (C_Spell.IsAutoAttackSpell(info.spellID) or C_Spell.IsRangedAutoAttackSpell(info.spellID)) then
            return false
        end
        status = ActionButtonUtil.GetActionBarStatusForSpell(info.actionID, true, false)
    elseif (itemType == Enum.SpellBookItemType.PetAction) then
        status = ActionButtonUtil.GetActionBarStatusForPetAction(info.actionID)
    elseif (itemType == Enum.SpellBookItemType.Flyout) then
        status = ActionButtonUtil.GetActionBarStatusForFlyout(info.actionID)
    end
    return status == ActionButtonUtil.ActionBarActionStatus.MissingFromAllBars
end

local MISSING_HOVER = { 0.25, 0.82, 1 }

local function ApplyHoverColor(row, missing)
    local highlight = row.Highlight
    if (not highlight) then
        return
    end
    row.missing = missing
    highlight.HoverGroup:Stop()
    if (missing) then
        highlight:SetDesaturated(true)
        highlight:SetVertexColor(MISSING_HOVER[1], MISSING_HOVER[2], MISSING_HOVER[3])
        highlight.hoverTarget = 1
        highlight:SetAlpha(1)
        return
    end
    highlight:SetDesaturated(false)
    highlight:SetVertexColor(1, 1, 1)
    local overArrow = row.Arrow and row.Arrow:IsShown() and row.Arrow:IsMouseOver()
    if (row:IsMouseOver() or overArrow) then
        highlight.hoverTarget = 1
        highlight:SetAlpha(1)
    else
        highlight.hoverTarget = 0
        highlight:SetAlpha(0)
    end
end

local function ApplyRowBorder(row)
    local missing = not row.unusable and not row.isPassive and IsMissingFromBars(row.spellInfo)
    if (row.unusable) then
        row.Border:SetTexture(TEX.unselected)
    elseif (row.isPassive) then
        row.Border:SetTexture(TEX.available)
    elseif (missing) then
        row.Border:SetTexture(TEX.missing)
    else
        row.Border:SetTexture(TEX.selected)
    end
    row.Border:SetVertexColor(1, 1, 1)
    ApplyHoverColor(row, missing)
end

local function ApplySpell(row, entry, bank, textWidth)
    local info = entry.info
    local theme = EXUI.const.theme
    row.slotIndex = entry.slot
    row.spellBank = bank
    local unusable = info.isOffSpec or entry.isOffSpec
    row.spellInfo = info
    row.Icon:SetTexture(info.iconID)
    row.Icon:SetDesaturated(unusable)
    if (unusable) then
        row.Icon:SetVertexColor(UNPICKED_COLOR, UNPICKED_COLOR, UNPICKED_COLOR)
    else
        row.Icon:SetVertexColor(1, 1, 1)
    end
    local isFlyout = info.itemType == Enum.SpellBookItemType.Flyout
    row.isFlyout = isFlyout
    row.isPassive = info.isPassive
    row.unusable = unusable
    ApplyRowBorder(row)
    row.flyoutID = isFlyout and info.actionID or nil
    row.offSpecID = entry.isOffSpec and entry.specID or nil
    row.Arrow:SetShown(isFlyout)
    local nameGap = isFlyout and (TEXT_GAP + 10) or TEXT_GAP
    row.Name:ClearAllPoints()
    row.Name:SetPoint('TOPLEFT', row.IconFrame, 'TOPRIGHT', nameGap, -2)
    SetArrowOpen(row, false)
    row.Name:SetWidth(textWidth)
    row.Description:SetWidth(textWidth)
    row.Name:SetText(info.name)
    if (unusable) then
        row.Name:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    elseif (info.isPassive) then
        row.Name:SetTextColor(PASSIVE_NAME[1], PASSIVE_NAME[2], PASSIVE_NAME[3], 1)
    else
        row.Name:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    end
    row.Description:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    SetDescription(row, info.spellID)
    ApplyCastAttributes(row, info, bank, unusable)
    UpdateRowCooldown(row)
end

local function CreateFlyoutButton(parent)
    local button = CreateFrame('Button', nil, parent, 'SecureActionButtonTemplate')
    button:SetSize(BORDER_SIZE, BORDER_SIZE)
    PrepareSecureButton(button)

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint('CENTER')
    local mask = button:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)
    button.Icon = icon

    local cooldown, border = CreateIconCooldown(button)
    button.Cooldown = cooldown
    button.Border = border
    button.Highlight = cooldown.Hover

    button:SetScript('OnEnter', function(self)
        SetHover(self.Highlight, true)
        if (not self.spellID) then
            return
        end
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetSpellByID(self.spellID)
        GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function(self)
        SetHover(self.Highlight, false)
        GameTooltip:Hide()
    end)
    button:SetScript('OnDragStart', function(self)
        if (self.spellID) then
            C_Spell.PickupSpell(self.spellID)
        end
    end)
    button:SetScript('PreClick', function(self, _, down)
        if (down or not self.spellID) then
            return
        end
        if (IsModifiedClick('CHATLINK')) then
            local link = C_Spell.GetSpellLink(self.spellID)
            if (link and ChatFrameUtil) then
                ChatFrameUtil.InsertLink(link)
            end
            return
        end
        if (IsModifiedClick('PICKUPACTION')) then
            C_Spell.PickupSpell(self.spellID)
        end
    end)
    button:SetScript('PostClick', function(self, _, down)
        if (down or not self.spellID) then
            return
        end
        if (IsModifiedClick('CHATLINK') or IsModifiedClick('PICKUPACTION')) then
            return
        end
        HideFlyout()
    end)
    return button
end

local function CollectFlyoutSpells(flyoutID, offSpec, specID)
    local spells = {}
    if (not flyoutID or not GetFlyoutInfo or not GetFlyoutSlotInfo) then
        return spells
    end
    local _, _, numSlots, isKnown = GetFlyoutInfo(flyoutID)
    if (not numSlots or numSlots == 0 or (not isKnown and not offSpec)) then
        return spells
    end
    for index = 1, numSlots do
        local spellID, overrideSpellID, isKnownSlot, _, slotSpecID = GetFlyoutSlotInfo(flyoutID, index)
        local show = false
        if (offSpec) then
            show = slotSpecID == specID
        else
            show = isKnownSlot and (not slotSpecID or slotSpecID == 0)
        end
        local displayID = (overrideSpellID and overrideSpellID ~= 0) and overrideSpellID or spellID
        if (show and displayID) then
            spells[#spells + 1] = {
                spellID = displayID,
                icon = C_Spell.GetSpellTexture(displayID),
            }
        end
    end
    return spells
end

SetArrowOpen = function(row, open)
    if (not row or not row.Arrow) then
        return
    end
    local texture = row.Arrow.Texture
    if (row.unusable) then
        texture:SetDesaturated(true)
        texture:SetVertexColor(UNPICKED_COLOR, UNPICKED_COLOR, UNPICKED_COLOR)
        return
    end
    texture:SetDesaturated(false)
    if (open) then
        local accent = EXUI.const.theme.accent
        texture:SetVertexColor(accent[1], accent[2], accent[3], 1)
    else
        texture:SetVertexColor(1, 1, 1)
    end
end

HideFlyout = function()
    local popup = spellBook.flyoutPopup
    if (not popup) then
        return
    end
    if (popup.row) then
        SetArrowOpen(popup.row, false)
    end
    popup.row = nil
    popup:Hide()
end

ToggleFlyout = function(row)
    local popup = spellBook.flyoutPopup
    if (not popup or not row or not row.isFlyout) then
        return
    end
    if (popup:IsShown() and popup.row == row) then
        HideFlyout()
        return
    end

    local spells = CollectFlyoutSpells(row.flyoutID, row.unusable, row.offSpecID)
    if (#spells == 0) then
        HideFlyout()
        return
    end

    if (popup.row) then
        SetArrowOpen(popup.row, false)
    end

    popup.count = 0
    for index, spell in ipairs(spells) do
        local button = popup.buttons[index]
        if (not button) then
            button = CreateFlyoutButton(popup)
            popup.buttons[index] = button
        end
        popup.count = index
        button.spellID = spell.spellID
        if (not InCombatLockdown()) then
            button:SetAttribute('type1', 'spell')
            button:SetAttribute('spell', spell.spellID)
        end
        button.Icon:SetTexture(spell.icon)
        UpdateSpellCooldown(button.Cooldown, spell.spellID)
        button:ClearAllPoints()
        button:SetPoint('LEFT', (index - 1) * (BORDER_SIZE + FLYOUT_GAP), 0)
        button:Show()
    end
    for index = popup.count + 1, #popup.buttons do
        local button = popup.buttons[index]
        ClearCastAttributes(button)
        button.spellID = nil
        button:Hide()
    end

    local width = (popup.count * BORDER_SIZE) + ((popup.count - 1) * FLYOUT_GAP)
    popup:SetSize(width, BORDER_SIZE)
    popup.row = row
    popup.scrollOffset = spellBook.scroll and spellBook.scroll.scrollOffset or 0
    popup:ClearAllPoints()

    local panel = spellBook.panel
    local arrow = row.Arrow
    local panelLeft = panel and panel:GetLeft()
    local panelBottom = panel and panel:GetBottom()
    local arrowLeft = arrow and arrow:GetLeft()
    local arrowRight = arrow and arrow:GetRight()
    local arrowTop = arrow and arrow:GetTop()
    local arrowBottom = arrow and arrow:GetBottom()
    if (panel and panelLeft and panelBottom and arrowLeft and arrowRight and arrowTop and arrowBottom) then
        local y = ((arrowTop + arrowBottom) / 2) - panelBottom - (BORDER_SIZE / 2)
        local panelRight = panel:GetRight()
        local x
        if (panelRight and (arrowRight + 6 + width) > panelRight) then
            x = arrowLeft - 6 - width - panelLeft
        else
            x = arrowRight + 6 - panelLeft
        end
        popup:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', x, y)
    end
    popup:Show()
    SetArrowOpen(row, true)
end

spellBook.Create = function(self, parent)
    local tabBar = CreateFrame('Frame', nil, parent)
    tabBar:SetPoint('TOPLEFT', parent, 'TOPLEFT', 8, -4)
    tabBar:SetSize(1, 1)
    self.tabBar = tabBar
    self.tabButtons = {}
    for _, id in ipairs(TAB_ORDER) do
        self.tabButtons[id] = CreateTabButton(tabBar, id)
    end

    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scroll:SetParent(parent)
    scroll:SetPoint('TOPLEFT', tabBar, 'BOTTOMLEFT', 0, -6)
    scroll:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', -8, 8)
    self.scroll = scroll
    self.scrollChild = scroll.child

    scroll:HookScript('OnSizeChanged', function(frame, width)
        width = width or frame:GetWidth()
        if (math.abs((width or 0) - (spellBook.layoutWidth or -1)) < 1) then
            return
        end
        spellBook:Refresh()
    end)

    self.panel = parent
    local popup = CreateFrame('Frame', nil, parent)
    popup:SetFrameLevel(scroll:GetFrameLevel() + 20)
    popup:EnableMouse(true)
    popup:Hide()
    popup.buttons = {}
    popup:SetScript('OnUpdate', function(self)
        if (not self:IsShown()) then
            return
        end
        local offset = spellBook.scroll and spellBook.scroll.scrollOffset or 0
        if (self.scrollOffset ~= offset) then
            HideFlyout()
        end
    end)
    self.flyoutPopup = popup

    return scroll
end

local function MeasureHeight(sections)
    local y = 0
    local col = 0
    local function CloseRow()
        if (col > 0) then
            y = y + ROW_HEIGHT + ROW_GAP
            col = 0
        end
    end
    for sectionIndex, section in ipairs(sections) do
        if (section.name) then
            if (sectionIndex > 1) then
                CloseRow()
                y = y + SECTION_GAP
            elseif (col > 0) then
                CloseRow()
            end
            y = y + HEADER_HEIGHT + HEADER_GAP
        end
        for _ = 1, #section.spells do
            col = col + 1
            if (col == COLUMNS) then
                col = 0
                y = y + ROW_HEIGHT + ROW_GAP
            end
        end
    end
    CloseRow()
    if (y < 1) then
        y = 1
    end
    return y
end

local function LayoutWidth(scroll, contentHeight)
    local width = scroll:GetWidth()
    local viewport = scroll:GetHeight() or 0
    if (contentHeight > viewport + 1) then
        local gutter = (scroll.scrollbarWidth or 0) + (scroll.scrollbarPadding or 0) * 2
        width = width - gutter
    end
    return math.max(width, 1)
end

spellBook.Refresh = function(self)
    if (self.refreshing or not self.scrollChild or not self.tabButtons) then
        return
    end
    local width = self.scroll:GetWidth()
    if (width < 20) then
        return
    end

    if (InCombatLockdown()) then
        return
    end

    self.refreshing = true
    HideFlyout()
    UpdateTabs(self)
    local tabChanged = self.laidOutTab ~= self.activeTab
    width = self.scroll:GetWidth()
    if (width < 20) then
        self.refreshing = false
        return
    end

    local sections, bank = BuildSections(self.activeTab)
    width = LayoutWidth(self.scroll, MeasureHeight(sections))
    local colWidth = (width - COL_GAP * (COLUMNS - 1)) / COLUMNS
    local textWidth = colWidth - PAD_X - BORDER_SIZE - TEXT_GAP - 8
    if (textWidth < 20) then
        textWidth = 20
    end
    self.rowCount = 0
    self.headerCount = 0

    local y = 0
    local col = 0
    local function CloseRow()
        if (col > 0) then
            y = y + ROW_HEIGHT + ROW_GAP
            col = 0
        end
    end

    for sectionIndex, section in ipairs(sections) do
        if (section.name) then
            if (sectionIndex > 1) then
                CloseRow()
                y = y + SECTION_GAP
            elseif (col > 0) then
                CloseRow()
            end
            local header = AcquireHeader(self)
            header:ClearAllPoints()
            header:SetPoint('TOPLEFT', self.scrollChild, 'TOPLEFT', 0, -y)
            header:SetPoint('RIGHT', self.scrollChild, 'RIGHT', 0, 0)
            header.Name:SetText(section.name)
            SetBorderIcon(header.Icon, header.Border, section.icon, false)
            y = y + HEADER_HEIGHT + HEADER_GAP
        end
        for _, entry in ipairs(section.spells) do
            local row = AcquireRow(self)
            local x = col * (colWidth + COL_GAP)
            row:ClearAllPoints()
            row:SetSize(colWidth, ROW_HEIGHT)
            row:SetPoint('TOPLEFT', self.scrollChild, 'TOPLEFT', x, -y)
            ApplySpell(row, entry, bank, textWidth)
            col = col + 1
            if (col == COLUMNS) then
                col = 0
                y = y + ROW_HEIGHT + ROW_GAP
            end
        end
    end

    CloseRow()

    for index = self.rowCount + 1, #self.rows do
        local row = self.rows[index]
        row.spellID = nil
        ClearCastAttributes(row)
        row:Hide()
    end
    for index = self.headerCount + 1, #self.headers do
        self.headers[index]:Hide()
    end

    local height = y
    if (height < 1) then
        height = 1
    end
    self.scroll:UpdateScrollChild(nil, height)
    if (tabChanged) then
        self.scroll:SetVerticalScroll(0)
    end
    self.laidOutTab = self.activeTab
    self.layoutWidth = self.scroll:GetWidth()
    self.refreshing = false
end

local function UpdateVisibleCooldowns()
    if (not spellBook.scroll or not spellBook.scroll:IsVisible()) then
        return
    end
    for index = 1, spellBook.rowCount or 0 do
        local row = spellBook.rows[index]
        if (row and row:IsShown()) then
            UpdateRowCooldown(row)
        end
    end
    local popup = spellBook.flyoutPopup
    if (popup and popup:IsShown()) then
        for index = 1, popup.count or 0 do
            local button = popup.buttons[index]
            if (button and button:IsShown()) then
                UpdateSpellCooldown(button.Cooldown, button.spellID)
            end
        end
    end
end

local function UpdateVisibleBarBorders()
    if (not spellBook.scroll or not spellBook.scroll:IsVisible()) then
        return
    end
    for index = 1, spellBook.rowCount or 0 do
        local row = spellBook.rows[index]
        if (row and row:IsShown()) then
            ApplyRowBorder(row)
        end
    end
end

EXUI:RegisterEventHandler({
    'SPELL_UPDATE_COOLDOWN',
    'SPELL_UPDATE_CHARGES',
}, 'talents-spellbook-cooldowns', UpdateVisibleCooldowns)

EXUI:RegisterEventHandler({
    'ACTIONBAR_SLOT_CHANGED',
    'PET_BAR_UPDATE',
}, 'talents-spellbook-bar-borders', UpdateVisibleBarBorders)

EXUI:RegisterEventHandler('PLAYER_REGEN_DISABLED', 'talents-spellbook-lock', function()
    local scroll = spellBook.scroll
    if (not scroll) then
        return
    end
    scroll.draggingThumb = false
    scroll.targetScroll = scroll.scrollOffset
    scroll:SetScript('OnUpdate', nil)
    scroll.smoothUpdateActive = false
end)
