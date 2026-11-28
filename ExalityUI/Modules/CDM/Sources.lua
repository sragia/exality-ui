---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICDMDefaults
local defaults = EXUI:GetModule('cdm-defaults')

---@class EXUICDMSources
local sources = EXUI:GetModule('cdm-sources')

local ZERO_DURATION = C_DurationUtil.CreateDuration()
ZERO_DURATION:SetTimeSpan(0, 0)

sources.ZERO_DURATION = ZERO_DURATION

local GCD_THRESHOLD = 1.5

sources.EQUIPMENT_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19 }

local SLOT_TOKENS = {
    [1] = 'HEADSLOT',
    [2] = 'NECKSLOT',
    [3] = 'SHOULDERSLOT',
    [5] = 'CHESTSLOT',
    [6] = 'WAISTSLOT',
    [7] = 'LEGSSLOT',
    [8] = 'FEETSLOT',
    [9] = 'WRISTSLOT',
    [10] = 'HANDSSLOT',
    [11] = 'FINGER0SLOT',
    [12] = 'FINGER1SLOT',
    [13] = 'TRINKET0SLOT',
    [14] = 'TRINKET1SLOT',
    [15] = 'BACKSLOT',
    [16] = 'MAINHANDSLOT',
    [17] = 'SECONDARYHANDSLOT',
    [19] = 'TABARDSLOT',
}

local SLOT_LABELS = {
    [11] = 'Finger 1',
    [12] = 'Finger 2',
    [13] = 'Trinket 1',
    [14] = 'Trinket 2',
}

sources.EVENTS = {
    spell = {
        'SPELL_UPDATE_COOLDOWN',
        'SPELL_UPDATE_CHARGES',
        'SPELL_UPDATE_USABLE',
        'SPELLS_CHANGED',
        'SPELL_RANGE_CHECK_UPDATE',
        'SPELL_ACTIVATION_OVERLAY_GLOW_SHOW',
        'SPELL_ACTIVATION_OVERLAY_GLOW_HIDE',
    },
    item = { 'BAG_UPDATE_COOLDOWN', 'BAG_UPDATE_DELAYED', 'ITEM_DATA_LOAD_RESULT', 'PLAYER_EQUIPMENT_CHANGED' },
    equipment = { 'BAG_UPDATE_COOLDOWN', 'PLAYER_EQUIPMENT_CHANGED' },
    aura = { 'SPELLS_CHANGED' },
}

function sources:GetSlotLabel(slotID)
    if SLOT_LABELS[slotID] then
        return SLOT_LABELS[slotID]
    end
    local token = SLOT_TOKENS[slotID]
    local label = token and _G[token]
    return label or string.format('Slot %d', slotID or 0)
end

function sources:GetSlotOptions()
    local options = {}
    for index, slotID in ipairs(self.EQUIPMENT_SLOTS) do
        options[slotID] = { label = self:GetSlotLabel(slotID), order = index }
    end
    return options
end

function sources:GetSourceID(source)
    if source.type == 'spell' then
        return tonumber(source.spellID)
    elseif source.type == 'item' then
        return tonumber(source.itemID)
    elseif source.type == 'equipment' then
        return tonumber(source.slot)
    elseif source.type == 'aura' then
        return source.spellIDs[1]
    end
    return nil
end

function sources:GetTexture(source)
    local id = self:GetSourceID(source)
    if not id then
        return defaults.QUESTION_MARK_ICON, true
    end
    if source.type == 'spell' or source.type == 'aura' then
        local texture = C_Spell.GetSpellTexture(id)
        return texture or defaults.QUESTION_MARK_ICON, texture ~= nil
    end
    if source.type == 'item' then
        local texture = C_Item.GetItemIconByID(id)
        if not texture then
            C_Item.RequestLoadItemDataByID(id)
        end
        return texture or defaults.QUESTION_MARK_ICON, texture ~= nil
    end
    local texture = GetInventoryItemTexture('player', id)
    if texture then
        return texture, true
    end
    local _, emptyTexture = GetInventorySlotInfo(SLOT_TOKENS[id])
    return emptyTexture or defaults.QUESTION_MARK_ICON, true
end

function sources:GetName(source)
    local id = self:GetSourceID(source)
    if not id then
        return ''
    end
    if source.type == 'spell' or source.type == 'aura' then
        return C_Spell.GetSpellName(id) or ''
    end
    if source.type == 'item' then
        return C_Item.GetItemNameByID(id) or ''
    end
    local itemID = GetInventoryItemID('player', id)
    return itemID and C_Item.GetItemNameByID(itemID) or self:GetSlotLabel(id)
end

local function setStartDuration(state, start, duration)
    state.recharging = false
    state.cooldownDuration = nil
    state.ownDuration = state.ownDuration or C_DurationUtil.CreateDuration()
    state.ownDuration:SetTimeFromStart(start or 0, duration or 0, 1)
    state.duration = state.ownDuration
    state.onCooldown = (start or 0) > 0 and (duration or 0) > GCD_THRESHOLD
end

-- isActive / isOnGCD / maxCharges are NeverSecret; counts and timings only go to widgets.
local function readSpell(state, spellID, source)
    local cooldown = C_Spell.GetSpellCooldown(spellID)
    state.onCooldown = cooldown ~= nil and cooldown.isActive and not cooldown.isOnGCD
    local charges = C_Spell.GetSpellCharges(spellID)
    state.recharging = charges ~= nil and charges.maxCharges > 1 and charges.isActive
    if charges and charges.maxCharges > 1 and not state.onCooldown then
        state.duration = C_Spell.GetSpellChargeDuration(spellID) or ZERO_DURATION
    else
        state.duration = C_Spell.GetSpellCooldownDuration(spellID, source.ignoreGCD ~= false) or ZERO_DURATION
    end
    -- Spell cooldown even for charge spells: inactive (remaining 0) while any charge can be cast.
    state.cooldownDuration = C_Spell.GetSpellCooldownDuration(spellID, source.ignoreGCD ~= false) or ZERO_DURATION
    state.count = C_Spell.GetSpellDisplayCount(spellID)
    state.usable = C_Spell.IsSpellUsable(spellID)
end

local function readItem(state, itemID)
    local start, duration = C_Item.GetItemCooldown(itemID)
    setStartDuration(state, start, duration)
    state.count = C_Item.GetItemCount(itemID, false, true)
    state.usable = C_Item.IsUsableItem(itemID)
end

local function readEquipment(state, slotID)
    local start, duration = GetInventoryItemCooldown('player', slotID)
    setStartDuration(state, start, duration)
    state.count = nil
    state.usable = GetInventoryItemID('player', slotID) ~= nil
end

-- Range checks are shared with Blizzard's Cooldown Manager, which switches them off when it re-lays out,
-- so they are switched on again on every rebuild and target change and never switched off here.
function sources:WatchRange(state, source)
    local spellID = source.type == 'spell' and tonumber(source.spellID)
    state.inRange = true
    if not spellID or not C_Spell.SpellHasRange(spellID) then
        return
    end
    C_Spell.EnableSpellRangeCheck(spellID, true)
    state.inRange = C_Spell.IsSpellInRange(spellID) ~= false
end

function sources:WatchSpell(state, source)
    self:WatchRange(state, source)
    local spellID = source.type == 'spell' and tonumber(source.spellID)
    state.procActive = spellID and (C_SpellActivationOverlay.IsSpellOverlayed(spellID)
        or C_SpellActivationOverlay.IsSpellOverlayed(C_Spell.GetOverrideSpell(spellID))) or false
end

-- Range and proc events can name the base spell or its current override.
function sources:MatchesSpell(source, spellID)
    local own = source.type == 'spell' and tonumber(source.spellID)
    return own and (spellID == own or spellID == C_Spell.GetOverrideSpell(own)) or false
end

function sources:Read(state, source)
    local id = self:GetSourceID(source)
    state.count = nil
    if not id or source.type == 'aura' then
        state.cooldownDuration = nil
        state.duration = ZERO_DURATION
        state.onCooldown = false
        state.usable = id ~= nil
        return state
    end
    if source.type == 'spell' then
        readSpell(state, id, source)
    elseif source.type == 'item' then
        readItem(state, id)
    else
        readEquipment(state, id)
    end
    return state
end
