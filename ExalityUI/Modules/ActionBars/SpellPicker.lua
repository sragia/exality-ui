---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIActionBarsSpellPicker
local spellPicker = EXUI:GetModule('action-bars-spell-picker')

local PICKER_WIDTH = 220
local PICKER_HEIGHT = 280
local SEARCH_HEIGHT = 24
local ROW_HEIGHT = 26
local ROW_ICON = 16
local PAD = 6
local LIST_GAP = 4
local ICON_ZOOM = 15
local FILTER_SIZE = 26
local FILTER_GAP = 4
local FILTER_COL = FILTER_SIZE + 4
local CONSUMABLE_ICON = 136000

-- Same row art as the quest log rewards
local ATLAS_W, ATLAS_H = 472, 329
local SLICE = 4
local RECTS = {
    simpleBg = { 6, 117, 199, 140 },
    simpleBorderOff = { 6, 144, 199, 167 },
    simpleGlowOff = { 6, 171, 135, 194 },
    simpleGlowOn = { 6, 225, 135, 248 },
}
local GLOW_ALPHA = 0.65
local GLOW_HOVER_ALPHA = 0.8
local MISSING_COLOR = { 0.3, 0.65, 1 }
local MISSING_FILL_ALPHA = 0.45
local MISSING_ALPHA = 1
local MISSING_HOVER_ALPHA = 1

local function applyAtlas(tex, key)
    local rect = RECTS[key]
    tex:SetTexture(EXFrames.assets.textures.splitOptions.atlas)
    EXFrames.utils.texture.applySlice(tex, SLICE, tex:GetParent(), Enum.UITextureSliceMode.Stretched)
    tex:SetTexCoord(rect[1] / ATLAS_W, (rect[3] + 1) / ATLAS_W, rect[2] / ATLAS_H, (rect[4] + 1) / ATLAS_H)
end

-- Spellbook rule: highlight spells that aren't in any action slot; stances live on their own bar.
local function isMissingFromBars(spellID)
    local slots = C_ActionBar.FindSpellActionButtons(spellID)
    if slots and #slots > 0 then
        return false
    end
    if C_ActionBar.IsHighestSpellRank and not C_ActionBar.IsHighestSpellRank(spellID) then
        return false
    end
    for index = 1, GetNumShapeshiftForms() do
        if select(4, GetShapeshiftFormInfo(index)) == spellID then
            return false
        end
    end
    return true
end

-- Spec first, then class, then general, then other spells, then bag consumables.
local CATEGORY_SPEC = 1
local CATEGORY_CLASS = 2
local CATEGORY_GENERAL = 3
local CATEGORY_OTHER = 4
local CATEGORY_CONSUMABLE = 5

local function getSkillLineCategory(skillLineIndex, skillLineInfo)
    local indices = Enum.SpellBookSkillLineIndex
    if skillLineInfo.specID or (indices and skillLineIndex == indices.MainSpec) then
        return CATEGORY_SPEC
    end
    if indices and skillLineIndex == indices.Class then
        return CATEGORY_CLASS
    end
    if indices and skillLineIndex == indices.General then
        return CATEGORY_GENERAL
    end
    return CATEGORY_OTHER
end

local function getBagIndices()
    local bags = {}
    local first = Enum.BagIndex and Enum.BagIndex.Backpack or 0
    local last = NUM_TOTAL_BAG_FRAMES or NUM_BAG_SLOTS or 4
    for bag = first, last do
        bags[#bags + 1] = bag
    end
    return bags
end

local function isWantedConsumable(classID, subClassID, name)
    local consumableClass = Enum.ItemClass and Enum.ItemClass.Consumable
    if classID ~= consumableClass then
        return false
    end

    local sub = Enum.ItemConsumableSubclass
    if sub then
        if subClassID == sub.Potion
            or subClassID == sub.Elixir
            or subClassID == sub.Flasksphials
            or subClassID == sub.Fooddrink
        then
            return true
        end
    end

    -- Augment runes sit under Consumable/Other; match by name so we skip the rest of Other.
    if name and string.find(string.lower(name), 'augment rune', 1, true) then
        return true
    end

    return false
end

spellPicker.frame = nil
spellPicker.targetButton = nil
spellPicker.spells = nil
spellPicker.consumables = nil
spellPicker.filtered = nil
spellPicker.rowPool = nil
spellPicker.eventsRegistered = false
spellPicker.showSpells = true
spellPicker.showConsumables = true

local function isActivateClick(button, down)
    local useOnKeyDown = button:GetAttribute('useOnKeyDown')
    if useOnKeyDown then
        return down and true or false
    end
    return not down
end

local function trim(text)
    if not text then
        return ''
    end
    return (text:gsub('^%s+', ''):gsub('%s+$', ''))
end

spellPicker.RestoreButtonType = function(self, button)
    if not button or not button._exuiSpellPickerSavedType then
        return
    end
    if not InCombatLockdown() then
        button:SetAttribute('type', button._exuiSpellPickerSavedType)
    end
    button._exuiSpellPickerSavedType = nil
end

spellPicker.BlankButtonType = function(self, button)
    if button._exuiSpellPickerSavedType == nil then
        button._exuiSpellPickerSavedType = button._state_type or button:GetAttribute('type') or 'action'
    end
    button:SetAttribute('type', nil)
end

spellPicker.EnsureSpellList = function(self)
    if self.spells then
        return
    end

    local spells = {}
    local seen = {}

    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        local spellType = Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
        local playerBank = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
        local numLines = C_SpellBook.GetNumSpellBookSkillLines()
        for skillLineIndex = 1, numLines do
            local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
            if skillLineInfo and not skillLineInfo.shouldHide and not skillLineInfo.offSpecID then
                local category = getSkillLineCategory(skillLineIndex, skillLineInfo)
                for i = 1, skillLineInfo.numSpellBookItems do
                    local slotIndex = i + skillLineInfo.itemIndexOffset
                    local itemInfo = C_SpellBook.GetSpellBookItemInfo(slotIndex, playerBank)
                    if itemInfo
                        and itemInfo.itemType == spellType
                        and not itemInfo.isPassive
                        and not itemInfo.isOffSpec
                        and itemInfo.spellID
                        and itemInfo.name
                        and itemInfo.name ~= ''
                    then
                        local existing = seen[itemInfo.spellID]
                        if not existing then
                            local entry = {
                                entryType = 'spell',
                                spellID = itemInfo.spellID,
                                name = itemInfo.name,
                                nameLower = string.lower(itemInfo.name),
                                icon = itemInfo.iconID,
                                category = category,
                            }
                            seen[itemInfo.spellID] = entry
                            spells[#spells + 1] = entry
                        elseif category < existing.category then
                            existing.category = category
                        end
                    end
                end
            end
        end
    end

    table.sort(spells, function(a, b)
        if a.category ~= b.category then
            return a.category < b.category
        end
        return a.name < b.name
    end)

    self.spells = spells
end

spellPicker.EnsureConsumableList = function(self)
    if self.consumables then
        return
    end

    local consumables = {}
    local byItemID = {}
    local consumableClass = Enum.ItemClass and Enum.ItemClass.Consumable

    if C_Container and C_Container.GetContainerNumSlots and consumableClass then
        for _, bag in ipairs(getBagIndices()) do
            local slots = C_Container.GetContainerNumSlots(bag) or 0
            for slot = 1, slots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID then
                    local _, _, _, _, icon, classID, subClassID = C_Item.GetItemInfoInstant(info.itemID)
                    local name = info.itemName
                    if not name or name == '' then
                        name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(info.itemID) or tostring(info.itemID)
                    end
                    if isWantedConsumable(classID, subClassID, name) then
                        local existing = byItemID[info.itemID]
                        local count = info.stackCount or 1
                        if existing then
                            existing.count = existing.count + count
                        else
                            local entry = {
                                entryType = 'item',
                                itemID = info.itemID,
                                name = name,
                                nameLower = string.lower(name),
                                icon = info.iconFileID or icon,
                                count = count,
                                category = CATEGORY_CONSUMABLE,
                            }
                            byItemID[info.itemID] = entry
                            consumables[#consumables + 1] = entry
                        end
                    end
                end
            end
        end
    end

    table.sort(consumables, function(a, b)
        return a.name < b.name
    end)

    self.consumables = consumables
end

spellPicker.InvalidateSpellList = function(self)
    self.spells = nil
end

spellPicker.InvalidateConsumableList = function(self)
    self.consumables = nil
end

spellPicker.EnsureEvents = function(self)
    if self.eventsRegistered then
        return
    end
    self.eventsRegistered = true

    EXUI:RegisterEventHandler('SPELLS_CHANGED', 'action-bars-spell-picker', function()
        spellPicker:InvalidateSpellList()
    end)

    EXUI:RegisterEventHandler('BAG_UPDATE', 'action-bars-spell-picker', function()
        spellPicker:InvalidateConsumableList()
        if spellPicker.frame and spellPicker.frame:IsShown() then
            local text = spellPicker.frame.search and spellPicker.frame.search:GetText() or ''
            spellPicker:RefreshList(text)
        end
    end)

    EXUI:RegisterEventHandler('PLAYER_REGEN_DISABLED', 'action-bars-spell-picker', function()
        if spellPicker.frame and spellPicker.frame:IsShown() then
            spellPicker:Hide()
        end
    end)
end

spellPicker.AcquireRow = function(self)
    local row = self.rowPool:Acquire()
    if not row.configured then
        row:SetHeight(ROW_HEIGHT)
        row:RegisterForClicks('LeftButtonUp')

        local bg = row:CreateTexture(nil, 'BACKGROUND')
        bg:SetAllPoints()
        row.bg = bg

        local glow = row:CreateTexture(nil, 'BACKGROUND', nil, 1)
        glow:SetAllPoints()
        row.glow = glow

        -- Inset keeps the square fill inside the rounded border
        local missingFill = row:CreateTexture(nil, 'BACKGROUND', nil, 2)
        missingFill:SetPoint('TOPLEFT', 2, -2)
        missingFill:SetPoint('BOTTOMRIGHT', -2, 2)
        missingFill:SetColorTexture(1, 1, 1, 1)
        missingFill:SetGradient('HORIZONTAL',
            CreateColor(MISSING_COLOR[1], MISSING_COLOR[2], MISSING_COLOR[3], MISSING_FILL_ALPHA),
            CreateColor(MISSING_COLOR[1], MISSING_COLOR[2], MISSING_COLOR[3], 0))
        missingFill:Hide()
        row.missingFill = missingFill

        local border = row:CreateTexture(nil, 'OVERLAY')
        border:SetAllPoints()
        row.border = border

        local icon = row:CreateTexture(nil, 'ARTWORK')
        icon:SetSize(ROW_ICON, ROW_ICON)
        icon:SetPoint('LEFT', 6, 0)
        icon:SetTexCoord(EXUI.utils.getTexCoords(1, 1, ICON_ZOOM))
        row.icon = icon

        local count = row:CreateFontString(nil, 'OVERLAY')
        count:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        count:SetPoint('RIGHT', -8, 0)
        count:SetJustifyH('RIGHT')
        count:SetTextColor(unpack(EXUI.const.theme.text))
        row.count = count

        local name = row:CreateFontString(nil, 'OVERLAY')
        name:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        name:SetPoint('LEFT', icon, 'RIGHT', 6, 0)
        name:SetJustifyH('LEFT')
        name:SetWordWrap(false)
        row.name = name

        row:SetScript('OnEnter', function(self)
            applyAtlas(self.glow, 'simpleGlowOn')
            self.glow:SetAlpha(self.glowHoverAlpha)
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            if self.entryType == 'item' and self.itemID then
                GameTooltip:SetItemByID(self.itemID)
            elseif self.spellID then
                GameTooltip:SetSpellByID(self.spellID)
            end
            GameTooltip:Show()
        end)

        row:SetScript('OnLeave', function(self)
            applyAtlas(self.glow, 'simpleGlowOff')
            self.glow:SetAlpha(self.glowAlpha)
            GameTooltip:Hide()
        end)

        row:SetScript('OnClick', function(self)
            spellPicker:SelectEntry(self.entryType, self.spellID, self.itemID)
        end)

        row.configured = true
    end
    row:Show()
    return row
end

spellPicker.UpdateFilterButtons = function(self)
    local frame = self.frame
    if not frame then
        return
    end

    local theme = EXUI.const.theme
    local function apply(btn, enabled)
        btn.icon:SetAlpha(enabled and 1 or 0.35)
        btn.normalBg = enabled and theme.backgroundLight or theme.backgroundDeep
        btn.normalBorder = enabled and theme.accent or theme.border
        btn.bg:SetVertexColor(unpack(btn.normalBg))
        btn.border:SetVertexColor(unpack(btn.normalBorder))
    end

    apply(frame.spellFilter, self.showSpells)
    apply(frame.consumableFilter, self.showConsumables)
end

spellPicker.ToggleFilter = function(self, which)
    if which == 'spells' then
        self.showSpells = not self.showSpells
    elseif which == 'consumables' then
        self.showConsumables = not self.showConsumables
    end
    self:UpdateFilterButtons()
    local text = self.frame and self.frame.search and self.frame.search:GetText() or ''
    self:RefreshList(text)
end

spellPicker.CreateFilterButton = function(self, parent, tooltip)
    local theme = EXUI.const.theme
    local btn = EXFrames:GetFrame('simple-button'):Create(parent)
    btn:SetSize(FILTER_SIZE, FILTER_SIZE)
    btn:SetOptionData({
        square = true,
        color = theme.backgroundDeep,
    })
    btn.icon:ClearAllPoints()
    btn.icon:SetPoint('TOPLEFT', 2, -2)
    btn.icon:SetPoint('BOTTOMRIGHT', -2, 2)
    btn.icon:SetTexCoord(EXUI.utils.getTexCoords(1, 1, ICON_ZOOM))
    btn.icon:Show()

    btn:HookScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetText(tooltip)
        GameTooltip:Show()
    end)
    btn:HookScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    return btn
end

spellPicker.RefreshList = function(self, filterText)
    if not self.frame then
        return
    end

    self:EnsureSpellList()
    self:EnsureConsumableList()
    self.rowPool:ReleaseAll()

    filterText = string.lower(trim(filterText or ''))
    local filtered = {}
    if self.showSpells then
        for _, entry in ipairs(self.spells) do
            if filterText == '' or entry.nameLower:find(filterText, 1, true) then
                filtered[#filtered + 1] = entry
            end
        end
    end
    if self.showConsumables then
        for _, entry in ipairs(self.consumables) do
            if filterText == '' or entry.nameLower:find(filterText, 1, true) then
                filtered[#filtered + 1] = entry
            end
        end
    end
    self.filtered = filtered

    local scroll = self.frame.scroll
    local content = scroll.child
    local y = 0
    for _, entry in ipairs(filtered) do
        local row = self:AcquireRow()
        row:SetParent(content)
        row:ClearAllPoints()
        row:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -y)
        row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', 0, -y)
        row.entryType = entry.entryType or 'spell'
        row.spellID = entry.spellID
        row.itemID = entry.itemID
        row.icon:SetTexture(entry.icon)
        row.name:SetText(entry.name)
        row.name:SetTextColor(unpack(EXUI.const.theme.text))
        row.name:ClearAllPoints()
        row.name:SetPoint('LEFT', row.icon, 'RIGHT', 6, 0)
        if row.entryType == 'item' and entry.count and entry.count > 1 then
            row.count:SetText(entry.count)
            row.count:Show()
            row.name:SetPoint('RIGHT', row.count, 'LEFT', -6, 0)
        else
            row.count:Hide()
            row.name:SetPoint('RIGHT', -8, 0)
        end

        -- Slice margins clamp to the row size, so apply once the row is anchored
        local missing = row.entryType == 'spell' and isMissingFromBars(entry.spellID)
        applyAtlas(row.bg, 'simpleBg')
        applyAtlas(row.border, 'simpleBorderOff')
        applyAtlas(row.glow, 'simpleGlowOff')
        if missing then
            row.glow:SetVertexColor(unpack(MISSING_COLOR))
            row.glow:SetBlendMode('ADD')
            row.border:SetVertexColor(unpack(MISSING_COLOR))
            row.missingFill:Show()
            row.glowAlpha, row.glowHoverAlpha = MISSING_ALPHA, MISSING_HOVER_ALPHA
        else
            row.glow:SetVertexColor(1, 1, 1)
            row.glow:SetBlendMode('BLEND')
            row.border:SetVertexColor(1, 1, 1)
            row.missingFill:Hide()
            row.glowAlpha, row.glowHoverAlpha = GLOW_ALPHA, GLOW_HOVER_ALPHA
        end
        row.glow:SetAlpha(row.glowAlpha)
        y = y + ROW_HEIGHT + LIST_GAP
    end

    local height = math.max(y - LIST_GAP, 1)
    content:SetHeight(height)
    scroll:UpdateScrollChild(math.max(1, scroll:GetWidth()), height)
    scroll:SetVerticalScroll(0)
end

spellPicker.EnsureFrame = function(self)
    if self.frame then
        return
    end

    local theme = EXUI.const.theme

    local frame = CreateFrame('Frame', 'EXUIActionBarSpellPicker', UIParent, 'BackdropTemplate')
    frame:SetSize(PICKER_WIDTH + FILTER_COL + PAD, PICKER_HEIGHT)
    frame:SetFrameStrata('DIALOG')
    frame:SetFrameLevel(200)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    frame:SetBackdropColor(theme.backgroundDeep[1], theme.backgroundDeep[2], theme.backgroundDeep[3], 0.95)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:Hide()
    frame:SetScript('OnHide', function()
        spellPicker:OnFrameHide()
    end)

    tinsert(UISpecialFrames, frame:GetName())

    local search = CreateFrame('EditBox', nil, frame)
    search:SetAutoFocus(false)
    search:SetHeight(SEARCH_HEIGHT)
    search:SetPoint('TOPLEFT', PAD, -PAD)
    search:SetPoint('TOPRIGHT', -(PAD + FILTER_COL), -PAD)
    search:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    search:SetTextColor(unpack(theme.text))
    search:SetTextInsets(8, 8, 0, 0)
    search:SetMaxLetters(64)

    local searchBg = search:CreateTexture(nil, 'BACKGROUND')
    searchBg:SetAllPoints()
    searchBg:SetColorTexture(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 1)

    local searchBorder = EXUI:AddPixelPerfectBorder(search, 1, { register = false })
    searchBorder:SetBorderColor(theme.border[1], theme.border[2], theme.border[3], 1)

    local placeholder = search:CreateFontString(nil, 'OVERLAY')
    placeholder:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    placeholder:SetPoint('LEFT', 8, 0)
    placeholder:SetText('Search')
    placeholder:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    search.placeholder = placeholder

    search:SetScript('OnTextChanged', function(editBox, userInput)
        local text = editBox:GetText() or ''
        editBox.placeholder:SetShown(text == '')
        if userInput then
            spellPicker:RefreshList(text)
        end
    end)
    search:SetScript('OnEscapePressed', function()
        spellPicker:Hide()
    end)
    search:SetScript('OnEditFocusGained', function()
        searchBorder:SetBorderColor(theme.accent[1], theme.accent[2], theme.accent[3], 1)
    end)
    search:SetScript('OnEditFocusLost', function()
        searchBorder:SetBorderColor(theme.border[1], theme.border[2], theme.border[3], 1)
    end)
    frame.search = search

    local spellFilter = self:CreateFilterButton(frame, 'Spells')
    spellFilter:SetPoint('TOPRIGHT', -PAD, -PAD)
    local _, classFile = UnitClass('player')
    if classFile and GetClassAtlas then
        spellFilter.icon:SetAtlas(GetClassAtlas(string.lower(classFile)))
        spellFilter.icon:SetTexCoord(0, 1, 0, 1)
    elseif classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile] then
        spellFilter.icon:SetTexture([[Interface\GLUES\CHARACTERCREATE\UI-CHARACTERCREATE-CLASSES]])
        spellFilter.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFile]))
    end
    spellFilter:SetScript('OnClick', function()
        spellPicker:ToggleFilter('spells')
    end)
    frame.spellFilter = spellFilter

    local consumableFilter = self:CreateFilterButton(frame, 'Consumables')
    consumableFilter:SetPoint('TOP', spellFilter, 'BOTTOM', 0, -FILTER_GAP)
    consumableFilter.icon:SetTexture(CONSUMABLE_ICON)
    consumableFilter:SetScript('OnClick', function()
        spellPicker:ToggleFilter('consumables')
    end)
    frame.consumableFilter = consumableFilter

    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scroll:SetParent(frame)
    scroll:SetPoint('TOPLEFT', search, 'BOTTOMLEFT', 0, -4)
    scroll:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -(PAD + FILTER_COL), PAD)
    scroll.scrollStep = (ROW_HEIGHT + LIST_GAP) * 3
    frame.scroll = scroll

    self.rowPool = CreateFramePool('Button', scroll.child)
    self.frame = frame
    self:UpdateFilterButtons()
end

spellPicker.OnFrameHide = function(self)
    local button = self.targetButton
    self.targetButton = nil
    if self.frame and self.frame.search then
        self.frame.search:ClearFocus()
        self.frame.search:SetText('')
    end
    if self.frame and self.frame.scroll and self.frame.scroll.Reset then
        self.frame.scroll:Reset()
    end
    if button then
        self:RestoreButtonType(button)
    end
    if self.mouseFrame then
        self.mouseFrame:UnregisterEvent('GLOBAL_MOUSE_DOWN')
    end
end

spellPicker.EnsureMouseDismiss = function(self)
    if self.mouseFrame then
        return
    end
    local mouseFrame = CreateFrame('Frame')
    mouseFrame:SetScript('OnEvent', function(_, event, button)
        if event ~= 'GLOBAL_MOUSE_DOWN' then
            return
        end
        local frame = spellPicker.frame
        if not frame or not frame:IsShown() then
            return
        end
        if frame:IsMouseOver() then
            return
        end
        spellPicker:Hide()
    end)
    self.mouseFrame = mouseFrame
end

spellPicker.ShowForButton = function(self, button)
    if not button or InCombatLockdown() then
        return
    end

    self:EnsureEvents()
    self:EnsureFrame()
    self:EnsureMouseDismiss()

    if self.targetButton and self.targetButton ~= button then
        self:RestoreButtonType(self.targetButton)
    end

    self:BlankButtonType(button)
    self.targetButton = button

    local frame = self.frame
    frame:ClearAllPoints()
    frame:SetPoint('BOTTOMLEFT', button, 'TOPLEFT', 0, 4)
    frame:Show()
    frame:Raise()

    frame.search:SetText('')
    frame.search.placeholder:Show()
    self:RefreshList('')
    frame.search:SetFocus()

    -- Defer so the opening Ctrl+RightClick does not immediately dismiss the picker.
    C_Timer.After(0, function()
        if spellPicker.frame and spellPicker.frame:IsShown() and spellPicker.mouseFrame then
            spellPicker.mouseFrame:RegisterEvent('GLOBAL_MOUSE_DOWN')
        end
    end)
end

spellPicker.Hide = function(self)
    if self.frame then
        self.frame:Hide()
    end
end

spellPicker.IsShown = function(self)
    return self.frame and self.frame:IsShown()
end

spellPicker.SelectEntry = function(self, entryType, spellID, itemID)
    local button = self.targetButton
    if not button or InCombatLockdown() then
        self:Hide()
        return
    end

    local slot = button:GetAttribute('action') or button._state_action
    if not slot then
        self:Hide()
        return
    end

    if entryType == 'item' then
        if not itemID then
            self:Hide()
            return
        end
        C_Item.PickupItem(itemID)
    else
        if not spellID then
            self:Hide()
            return
        end
        if C_Spell and C_Spell.PickupSpell then
            C_Spell.PickupSpell(spellID)
        else
            PickupSpell(spellID)
        end
    end

    PlaceAction(slot)
    ClearCursor()
    self:Hide()
end

spellPicker.RegisterButton = function(self, button)
    if not button or button._exuiSpellPickerHooked then
        return
    end
    button._exuiSpellPickerHooked = true

    button:HookScript('PreClick', function(btn, mouseButton, down)
        if mouseButton ~= 'RightButton' or not IsControlKeyDown() then
            return
        end
        if not isActivateClick(btn, down) then
            return
        end
        if InCombatLockdown() then
            return
        end
        spellPicker:ShowForButton(btn)
    end)
end
