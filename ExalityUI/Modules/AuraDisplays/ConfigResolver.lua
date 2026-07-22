---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysDefaults
local defaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUIAuraDisplaysConfigResolver
local resolver = EXUI:GetModule('aura-displays-config-resolver')

---@class EXUIAuraDisplaysSpellIndex
local spellIndex = EXUI:GetModule('aura-displays-spell-index')

local SORT_METHOD_MAP = {
    Default = 0,
    BigDefensive = 1,
    UnitFrameDebuff = 2,
    ImportantOnly = 3,
    Expiration = 4,
    ExpirationOnly = 5,
    Name = 6,
    NameOnly = 7,
}

-- AnchorUtil.FlowDirection: Left=-1, Right=1, Up=1, Down=-1
local GROWTH_MAP = {
    LEFT = -1,
    RIGHT = 1,
    UP = 1,
    DOWN = -1,
}

local PROCESSED_AURA_TYPE_MAP = {
    Buff = 1,
    Debuff = 2,
    Dispel = 3,
}

local function AppendSerialized(parts, value)
    local valueType = type(value)
    if valueType == 'table' then
        parts[#parts + 1] = '{'
        local keys = {}
        for key in pairs(value) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)
        for _, key in ipairs(keys) do
            parts[#parts + 1] = tostring(key)
            parts[#parts + 1] = '='
            AppendSerialized(parts, value[key])
            parts[#parts + 1] = ';'
        end
        parts[#parts + 1] = '}'
    elseif valueType == 'boolean' then
        parts[#parts + 1] = value and 't' or 'f'
    elseif value == nil then
        parts[#parts + 1] = 'n'
    else
        parts[#parts + 1] = tostring(value)
    end
end

function resolver:SerializeValue(value)
    local parts = {}
    AppendSerialized(parts, value)
    return table.concat(parts)
end

function resolver:ParseSpellIDList(text)
    local map = {}
    if not text or text == '' then
        return nil
    end
    for token in string.gmatch(text, '[^,]+') do
        local spellID = spellIndex:ResolveToken(token)
        if spellID then
            map[spellID] = true
        end
    end
    if not next(map) then
        return nil
    end
    return map
end

function resolver:ParseDispelTypeList(list)
    if not list or not next(list) then
        return nil
    end
    local map = {}
    for _, dispelType in ipairs(list) do
        map[dispelType] = true
    end
    return map
end

function resolver:BuildFilterString(filterTokens)
    if not filterTokens or #filterTokens == 0 then
        return 'HELPFUL'
    end
    local parts = {}
    for _, entry in ipairs(filterTokens) do
        if entry.token and entry.token ~= '' then
            if entry.negated then
                table.insert(parts, '!' .. entry.token)
            else
                table.insert(parts, entry.token)
            end
        end
    end
    if #parts == 0 then
        return 'HELPFUL'
    end
    return table.concat(parts, '|')
end

function resolver:BuildCandidateFilters(conditions)
    local filters = {}
    local includeSpellIDs = self:ParseSpellIDList(conditions.includeSpellIDs)
    local excludeSpellIDs = self:ParseSpellIDList(conditions.excludeSpellIDs)
    local includeDispelTypes = self:ParseDispelTypeList(conditions.includeDispelTypes)
    local excludeDispelTypes = self:ParseDispelTypeList(conditions.excludeDispelTypes)

    if includeSpellIDs then filters.includeSpellIDs = includeSpellIDs end
    if excludeSpellIDs then filters.excludeSpellIDs = excludeSpellIDs end
    if includeDispelTypes then filters.includeDispelTypes = includeDispelTypes end
    if excludeDispelTypes then filters.excludeDispelTypes = excludeDispelTypes end
    if conditions.maxDuration and conditions.maxDuration > 0 then
        filters.maxDuration = conditions.maxDuration
    end
    if conditions.processedAuraType and PROCESSED_AURA_TYPE_MAP[conditions.processedAuraType] then
        filters.processedAuraType = PROCESSED_AURA_TYPE_MAP[conditions.processedAuraType]
    end

    for _, field in ipairs(defaults.BOOL_CONDITION_FIELDS) do
        local value = conditions[field]
        if value ~= nil then
            filters[field] = value and true or false
        end
    end

    if not next(filters) then
        return nil
    end
    return filters
end

function resolver:GetSortMethod(conditions)
    return SORT_METHOD_MAP[conditions.sortMethod] or SORT_METHOD_MAP.Default
end

function resolver:GetSortDirection(conditions)
    if conditions.sortDirection == 'Reverse' then
        return 1
    end
    return 0
end

function resolver:GetGroupLayout(visual, layoutIndex)
    visual = visual or {}
    local elementWidth, elementHeight

    if visual.displayStyle == 'bar' then
        local barWidth = visual.barWidth or 160
        local barHeight = visual.barHeight or 20
        local iconSize = visual.showBarIcon ~= false and barHeight or 0
        local iconGap = iconSize > 0 and (visual.barIconGap or 0) or 0
        elementWidth = barWidth + iconSize + iconGap
        elementHeight = barHeight
    else
        elementWidth = visual.elementWidth and visual.elementWidth > 0 and visual.elementWidth or nil
        elementHeight = visual.elementHeight and visual.elementHeight > 0 and visual.elementHeight or nil
    end

    return {
        elementSpacingX = visual.elementSpacingX or 0,
        elementSpacingY = visual.elementSpacingY or 0,
        gapX = visual.gapX or 0,
        gapY = visual.gapY or 0,
        forceNewRow = visual.forceNewRow or false,
        elementWidth = elementWidth,
        elementHeight = elementHeight,
        layoutIndex = layoutIndex,
    }
end

function resolver:GetGrowthDirection(value)
    if AnchorUtil and AnchorUtil.FlowDirection and value then
        local key = value:sub(1, 1) .. string.lower(value:sub(2))
        local direction = AnchorUtil.FlowDirection[key]
        if direction ~= nil then
            return direction
        end
    end
    return GROWTH_MAP[value] or GROWTH_MAP.RIGHT
end

function resolver:ConditionsNeedProcessAura(conditions)
    return conditions
        and conditions.processedAuraType
        and PROCESSED_AURA_TYPE_MAP[conditions.processedAuraType] ~= nil
end

function resolver:DisplayNeedsProcessAura(display, shouldLoadGroup)
    if not display or not display.groups then
        return false
    end
    for _, groupID in ipairs(display.groupOrder or {}) do
        local group = display.groups[groupID]
        if group and group.conditions and group.conditions.enable then
            if not shouldLoadGroup or shouldLoadGroup(group.load) then
                if self:ConditionsNeedProcessAura(group.conditions) then
                    return true
                end
            end
        end
    end
    return false
end

-- Spell ID filters always apply to NeverSecret auras on any unit. For other auras,
-- Blizzard still restricts identity filters by unit reaction / helpful-harmful.
-- Always allow configuring the lists; show a notice when the unit/filter combo is restricted.
function resolver:CanApplySpellIDFilters(unit, filterString)
    if C_Secrets and C_Secrets.ShouldAurasBeSecret and not C_Secrets.ShouldAurasBeSecret() then
        return true
    end
    if not unit or unit == '' then
        return true
    end
    filterString = filterString or ''
    local isHarmful = filterString:find('HARMFUL') and not filterString:find('!HARMFUL')
    local isHelpful = filterString:find('HELPFUL') and not filterString:find('!HELPFUL')
    if UnitCanAssist('player', unit) and isHarmful and not isHelpful then
        return false
    end
    if not UnitCanAssist('player', unit) and isHelpful and not isHarmful then
        return false
    end
    return true
end

function resolver:ResolveGroupOptions(displayID, display, groupID, group, buttonStyle, layoutIndex, getGroupKey)
    local filterString = self:BuildFilterString(group.conditions.filterTokens)
    local groupKey = getGroupKey and getGroupKey(displayID, groupID) or defaults:GetGroupKey(displayID, groupID)
    return {
        groupKey = groupKey,
        filterString = filterString,
        maxFrameCount = group.conditions.maxFrameCount or 10,
        sortMethod = self:GetSortMethod(group.conditions),
        sortDirection = self:GetSortDirection(group.conditions),
        candidateFilters = self:BuildCandidateFilters(group.conditions),
        layout = self:GetGroupLayout(group.visual, layoutIndex),
        initializeFrame = function(auraButton)
            buttonStyle:Apply(auraButton, group.visual)
        end,
    }
end

function resolver:CanUpdateGroupsInPlace(container)
    return container
        and container.SetAuraGroupFilterString
        and container.SetAuraGroupCandidateFilters
        and container.SetAuraGroupSortMethod
        and container.SetAuraGroupMaxFrameCount
        and container.SetAuraGroupLayout
end

function resolver:ApplyGroupOptions(container, options)
    if not container or not options or not options.groupKey then
        return
    end
    local groupKey = options.groupKey
    if container.SetAuraGroupFilterString then
        container:SetAuraGroupFilterString(groupKey, options.filterString)
    end
    if container.SetAuraGroupMaxFrameCount then
        container:SetAuraGroupMaxFrameCount(groupKey, options.maxFrameCount)
    end
    if container.SetAuraGroupCandidateFilters then
        container:SetAuraGroupCandidateFilters(groupKey, options.candidateFilters)
    end
    if container.SetAuraGroupSortMethod then
        container:SetAuraGroupSortMethod(groupKey, options.sortMethod, options.sortDirection)
    end
    if container.SetAuraGroupLayout then
        container:SetAuraGroupLayout(groupKey, options.layout)
    end
end

function resolver:IterActiveGroups(display, shouldLoadGroup)
    local active = {}
    for layoutIndex, groupID in ipairs(display.groupOrder or {}) do
        local group = display.groups and display.groups[groupID]
        if group and group.conditions and group.conditions.enable then
            if not shouldLoadGroup or shouldLoadGroup(group.load) then
                active[#active + 1] = {
                    layoutIndex = layoutIndex,
                    groupID = groupID,
                    group = group,
                }
            end
        end
    end
    return active
end

-- Signature of config that requires discarding/recreating the container
-- (visual chrome, group membership, item enchants, process-aura policy).
function resolver:BuildHardSignature(displayID, display, groupKeyBuilder, shouldLoadGroup)
    local parts = { displayID or '' }
    local container = display.container or {}
    AppendSerialized(parts, {
        itemEnchantEnable = container.itemEnchantEnable,
        itemEnchantPlacement = container.itemEnchantPlacement,
        itemEnchantMainHand = container.itemEnchantMainHand,
        itemEnchantOffHand = container.itemEnchantOffHand,
        itemEnchantRanged = container.itemEnchantRanged,
        itemEnchantHidePermanent = container.itemEnchantHidePermanent,
        itemEnchantSpacingX = container.itemEnchantSpacingX,
        itemEnchantSpacingY = container.itemEnchantSpacingY,
        itemEnchantGapX = container.itemEnchantGapX,
        itemEnchantGapY = container.itemEnchantGapY,
        itemEnchantWidth = container.itemEnchantWidth,
        itemEnchantHeight = container.itemEnchantHeight,
        processAuraOptions = container.processAuraOptions,
    })

    for _, entry in ipairs(self:IterActiveGroups(display, shouldLoadGroup)) do
        parts[#parts + 1] = '|'
        parts[#parts + 1] = groupKeyBuilder(displayID, entry.groupID)
        parts[#parts + 1] = ':'
        AppendSerialized(parts, entry.group.visual)
    end

    return table.concat(parts)
end
