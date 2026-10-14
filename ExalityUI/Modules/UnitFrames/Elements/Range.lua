---@class ExalityUI
local EXUI = select(2, ...)

local range = EXUI:GetModule('uf-element-range')

local INSIDE_ALPHA = 1
local OUTSIDE_ALPHA = 0.5
local BG_INSIDE_ALPHA = 1
local BG_OUTSIDE_ALPHA = 0.1
local UPDATE_INTERVAL = 0.1
local MAX_SPELL_RANGE = 100

range.Create = function(self, frame)
    return {
        insideAlpha = INSIDE_ALPHA,
        outsideAlpha = OUTSIDE_ALPHA,
        PostUpdate = range.PostUpdate
    }
end

range.PostUpdate = function(rangeElement, frame, inRange, isEligible)
    if (frame.Health and frame.Health.bg and type(inRange) == 'boolean') then
        frame.Health.bg:SetAlphaFromBoolean(inRange, BG_INSIDE_ALPHA, BG_OUTSIDE_ALPHA)
    end
end

range.Update = function(self, frame)
end

local function CanQuerySpells()
    return C_Spell and C_Spell.GetSpellInfo and C_Spell.IsSpellHarmful and C_Spell.SpellHasRange
        and C_Spell.IsSpellInRange and C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines
        and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemInfo
        and Enum and Enum.SpellBookSpellBank and Enum.SpellBookItemType
end

local function ConsiderSpell(spellID, bestRange)
    if (not spellID or spellID == 0) then
        return bestRange
    end
    if (C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellID)) then
        return bestRange
    end
    if (C_Spell.IsAutoAttackSpell and C_Spell.IsAutoAttackSpell(spellID)) then
        return bestRange
    end
    if (C_Spell.IsRangedAutoAttackSpell and C_Spell.IsRangedAutoAttackSpell(spellID)) then
        return bestRange
    end
    if (not C_Spell.IsSpellHarmful(spellID) or not C_Spell.SpellHasRange(spellID)) then
        return bestRange
    end

    local info = C_Spell.GetSpellInfo(spellID)
    local maxRange = info and info.maxRange
    if (not maxRange or maxRange <= 0 or maxRange > MAX_SPELL_RANGE or maxRange <= bestRange) then
        return bestRange
    end

    range.hostileSpellID = info.spellID or spellID
    return maxRange
end

range.RefreshHostileSpell = function(self)
    self.hostileSpellID = nil
    if (not CanQuerySpells()) then
        return
    end

    local bestRange = 0
    local bank = Enum.SpellBookSpellBank.Player
    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for line = 1, numLines do
        local skillLine = C_SpellBook.GetSpellBookSkillLineInfo(line)
        if (skillLine and not skillLine.shouldHide and not skillLine.offSpecID and not skillLine.isGuild) then
            local firstSlot = skillLine.itemIndexOffset + 1
            local lastSlot = skillLine.itemIndexOffset + skillLine.numSpellBookItems
            for slot = firstSlot, lastSlot do
                local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
                if (item and not item.isPassive and not item.isOffSpec) then
                    if (item.itemType == Enum.SpellBookItemType.Spell) then
                        bestRange = ConsiderSpell(item.spellID, bestRange)
                    elseif (item.itemType == Enum.SpellBookItemType.Flyout and GetFlyoutInfo and GetFlyoutSlotInfo) then
                        local _, _, numSlots, isKnown = GetFlyoutInfo(item.actionID)
                        if (isKnown and numSlots and numSlots > 0) then
                            for flyoutIndex = 1, numSlots do
                                local flyoutSpellID, _, isKnownSlot = GetFlyoutSlotInfo(item.actionID, flyoutIndex)
                                if (isKnownSlot) then
                                    bestRange = ConsiderSpell(flyoutSpellID, bestRange)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function RestoreAlpha(frame)
    frame:SetAlpha(INSIDE_ALPHA)
    if (frame.Health and frame.Health.bg) then
        frame.Health.bg:SetAlpha(BG_INSIDE_ALPHA)
    end
end

local function ApplyRangeAlpha(frame, inRange)
    frame:SetAlphaFromBoolean(inRange, INSIDE_ALPHA, OUTSIDE_ALPHA)
    if (frame.Health and frame.Health.bg) then
        frame.Health.bg:SetAlphaFromBoolean(inRange, BG_INSIDE_ALPHA, BG_OUTSIDE_ALPHA)
    end
end

local function UpdateBossFrame(frame)
    local unit = frame.__unit
    local spellID = range.hostileSpellID
    if (not spellID or not unit or not UnitExists(unit)) then
        RestoreAlpha(frame)
        return
    end

    local inRange = C_Spell.IsSpellInRange(spellID, unit)
    if (type(inRange) == 'boolean') then
        ApplyRangeAlpha(frame, inRange)
    else
        RestoreAlpha(frame)
    end
end

local function OnBossRangeUpdate(container, elapsed)
    container.rangeElapsed = (container.rangeElapsed or 0) + elapsed
    if (container.rangeElapsed < UPDATE_INTERVAL) then
        return
    end
    container.rangeElapsed = 0

    local boss = EXUI:GetModule('uf-unit-boss')
    for _, frame in pairs(boss.frames) do
        UpdateBossFrame(frame)
    end
end

range.UpdateBoss = function(self, bossUnit)
    local container = bossUnit.container
    if (not container) then
        return
    end

    local enabled = false
    for _, frame in pairs(bossUnit.frames) do
        if (frame.db and frame.db.fadeOutOfRange) then
            enabled = true
            break
        end
    end

    if (not enabled or not CanQuerySpells()) then
        container:SetScript('OnUpdate', nil)
        container.rangeElapsed = 0
        for _, frame in pairs(bossUnit.frames) do
            RestoreAlpha(frame)
        end
        return
    end

    self:RefreshHostileSpell()
    container:SetScript('OnUpdate', OnBossRangeUpdate)
end

range.Init = function(self)
    EXUI:RegisterEventHandler({
        'SPELLS_CHANGED',
        'PLAYER_SPECIALIZATION_CHANGED',
        'PLAYER_ENTERING_WORLD',
    }, 'uf-element-range', function()
        range:RefreshHostileSpell()
    end)
end
