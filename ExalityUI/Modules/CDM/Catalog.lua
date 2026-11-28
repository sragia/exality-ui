---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICDMSources
local sources = EXUI:GetModule('cdm-sources')

---@class EXUICDMCatalog
local catalog = EXUI:GetModule('cdm-catalog')

local COOLDOWN_CATEGORIES = {
    { category = Enum.CooldownViewerCategory.Essential, label = 'Essential' },
    { category = Enum.CooldownViewerCategory.Utility, label = 'Utility' },
    { category = Enum.CooldownViewerCategory.SpecAgnosticEssential, label = 'General' },
    { category = Enum.CooldownViewerCategory.EquipSlotEssential, label = 'Equipment' },
}

-- Blizzard's Cooldown Manager list for the current spec, read when the picker opens.
-- Equipment entries are tracked by slot, like Blizzard does, so they survive item swaps.
local function buildEntry(info)
    if info.equipSlot then
        local itemID = GetInventoryItemID('player', info.equipSlot)
        return {
            source = { type = 'equipment', slot = info.equipSlot },
            name = itemID and C_Item.GetItemNameByID(itemID) or sources:GetSlotLabel(info.equipSlot),
            icon = GetInventoryItemTexture('player', info.equipSlot),
        }
    end
    if not info.spellID then
        return nil
    end
    local displayID = info.overrideSpellID or info.spellID
    return {
        source = { type = 'spell', spellID = info.spellID },
        name = C_Spell.GetSpellName(displayID) or tostring(info.spellID),
        icon = C_Spell.GetSpellTexture(displayID),
    }
end

local AURA_CATEGORIES = {
    { category = Enum.CooldownViewerCategory.TrackedBuff, label = 'Tracked Buffs' },
    { category = Enum.CooldownViewerCategory.TrackedBar, label = 'Tracked Bars' },
    { category = Enum.CooldownViewerCategory.Essential, label = 'Essential', auraOnly = true },
    { category = Enum.CooldownViewerCategory.Utility, label = 'Utility', auraOnly = true },
}

-- Same IDs Blizzard matches an aura against: linked spells, override and base spell.
local function buildAuraEntry(info)
    if not info.spellID then
        return nil
    end
    local spellIDs, seen = {}, {}
    local function add(spellID)
        if spellID and not seen[spellID] then
            seen[spellID] = true
            spellIDs[#spellIDs + 1] = spellID
        end
    end
    for _, linkedID in ipairs(info.linkedSpellIDs) do
        add(linkedID)
    end
    add(info.overrideSpellID)
    add(info.spellID)
    local displayID = info.overrideSpellID or info.spellID
    return {
        spellIDs = spellIDs,
        name = C_Spell.GetSpellName(displayID) or tostring(info.spellID),
        icon = C_Spell.GetSpellTexture(displayID),
    }
end

local function collect(categories, build)
    local available, reason = C_CooldownViewer.IsCooldownViewerAvailable()
    if not available then
        return nil, reason
    end
    local sections = {}
    for _, category in ipairs(categories) do
        local entries = {}
        for _, cooldownID in ipairs(C_CooldownViewer.GetCooldownViewerCategorySet(category.category, false)) do
            local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
            local entry = info and (not category.auraOnly or info.hasAura) and build(info)
            if entry then
                entries[#entries + 1] = entry
            end
        end
        table.sort(entries, function(a, b) return a.name < b.name end)
        if #entries > 0 then
            sections[#sections + 1] = { label = category.label, entries = entries }
        end
    end
    return sections
end

function catalog:GetCooldownSections()
    return collect(COOLDOWN_CATEGORIES, buildEntry)
end

function catalog:GetAuraSections()
    return collect(AURA_CATEGORIES, buildAuraEntry)
end

local function listMenu()
    return EXUI.EXFrames:GetFrame('list-menu-frame')
end

-- Categories first, then that category's entries, so a long spec list stays on screen.
-- onSelect receives the chosen entry (name, icon and source or spellIDs).
-- replace shows the picker in place of a list already open on the same anchor.
function catalog:ShowPicker(anchor, onSelect, auraPicker, replace)
    local sections, reason
    if auraPicker then
        sections, reason = self:GetAuraSections()
    else
        sections, reason = self:GetCooldownSections()
    end
    if not sections or #sections == 0 then
        local entries = {
            { text = reason and reason ~= '' and reason or 'No Cooldown Manager entries for this spec', isHeader = true },
        }
        if replace then
            listMenu():ShowAt(anchor, entries, 'drawer')
        else
            listMenu():ToggleAt(anchor, entries, 'drawer')
        end
        return
    end
    local categories = {}
    local function showCategories()
        listMenu():ShowAt(anchor, categories, 'drawer')
        return false
    end
    for _, section in ipairs(sections) do
        categories[#categories + 1] = {
            text = string.format('%s (%d)', section.label, #section.entries),
            onClick = function()
                local entries = {
                    { text = '< Back', color = EXUI.EXFrames.Theme.textMuted, onClick = showCategories },
                    { isDivider = true },
                }
                for _, entry in ipairs(section.entries) do
                    entries[#entries + 1] = {
                        text = entry.name,
                        icon = entry.icon,
                        onClick = function()
                            onSelect(entry)
                        end,
                    }
                end
                listMenu():ShowAt(anchor, entries, 'drawer')
                return false
            end,
        }
    end
    if replace then
        listMenu():ShowAt(anchor, categories, 'drawer')
    else
        listMenu():ToggleAt(anchor, categories, 'drawer')
    end
end

-- Comma separated spell IDs or names; unresolved parts are skipped.
function catalog:ResolveSpellList(text)
    local spellIDs = {}
    for part in string.gmatch(text or '', '[^,;]+') do
        local spellID = self:ResolveSpellInput(part)
        if spellID and not tContains(spellIDs, spellID) then
            spellIDs[#spellIDs + 1] = spellID
        end
    end
    return spellIDs
end

-- Spell ID, or a spell name the client can resolve (spellbook / known spells).
function catalog:ResolveSpellInput(text)
    text = strtrim(text or '')
    local spellID = tonumber(text:match('^%d+$'))
    if spellID then
        return spellID
    end
    local info = text ~= '' and C_Spell.GetSpellInfo(text)
    return info and info.spellID
end
