---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

local function refreshEditorOptions()
    local editor = EXUI:GetModule('np-aura-editor')
    if editor and editor.RefreshOptions then
        editor:RefreshOptions()
    end
end

local function refreshEditorList()
    local editor = EXUI:GetModule('np-aura-editor')
    if editor and editor.RefreshItemList then
        editor:RefreshItemList()
    end
end

---@class EXUIAuraDisplaysDefaults
local defaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUIAuraDisplaysConfigResolver
local resolver = EXUI:GetModule('aura-displays-config-resolver')

---@class EXUINameplatesAuras
local auraDisplays = EXUI:GetModule('np-auras')

---@class EXUINPAuraEditorGroupNav
local groupNav = EXUI:GetModule('np-aura-editor-group-nav')

---@class EXUINPAuraEditorConditionsOptions
local conditionsOptions = EXUI:GetModule('np-aura-editor-conditions-options')

---@class EXUINameplatesAurasDefaults
local ufDefaults = EXUI:GetModule('np-auras-defaults')

local append = EXUI.utils.append

local function EscapeFontString(text)
    return (text or ''):gsub('|', '||')
end

local function ResolvePrimaryUnit(display)
    if not display or not display.units then
        return 'player'
    end
    for _, unitKey in ipairs(ufDefaults.UNIT_ORDER) do
        if display.units[unitKey] then
            if unitKey == 'party' or unitKey == 'raid' then
                return 'player'
            end
            if unitKey == 'boss' then
                return 'boss1'
            end
            if unitKey == 'arena' then
                return 'arena1'
            end
            return unitKey
        end
    end
    return 'player'
end

function conditionsOptions:GetFilterPreview(displayID, groupID)
    local tokens = auraDisplays:GetGroupConditions(displayID, groupID, 'filterTokens') or {}
    return resolver:BuildFilterString(tokens)
end

function conditionsOptions:GetFilterPreviewText(displayID, groupID)
    return EscapeFontString(self:GetFilterPreview(displayID, groupID))
end

function conditionsOptions:ShouldShowSpellIdNotice(displayID, groupID)
    local display = auraDisplays:GetDisplay(displayID)
    local resolvedUnit = ResolvePrimaryUnit(display)
    local filterString = self:GetFilterPreview(displayID, groupID)
    return not resolver:CanApplySpellIDFilters(resolvedUnit, filterString)
end

function conditionsOptions:ToggleFilterToken(displayID, groupID, token, negated)
    local tokens = auraDisplays:GetGroupConditions(displayID, groupID, 'filterTokens') or {}
    for _, entry in ipairs(tokens) do
        if entry.token == token and entry.negated == negated then
            return
        end
    end
    table.insert(tokens, { token = token, negated = negated })
    auraDisplays:UpdateGroupConditions(displayID, groupID, 'filterTokens', tokens)
end

function conditionsOptions:RemoveFilterToken(displayID, groupID, token, negated)
    local tokens = auraDisplays:GetGroupConditions(displayID, groupID, 'filterTokens') or {}
    for i = #tokens, 1, -1 do
        local entry = tokens[i]
        if entry.token == token and entry.negated == negated then
            table.remove(tokens, i)
        end
    end
    auraDisplays:UpdateGroupConditions(displayID, groupID, 'filterTokens', tokens)
end

function conditionsOptions:HasFilterToken(displayID, groupID, token, negated)
    local tokens = auraDisplays:GetGroupConditions(displayID, groupID, 'filterTokens') or {}
    for _, entry in ipairs(tokens) do
        if entry.token == token and entry.negated == negated then
            return true
        end
    end
    return false
end

function conditionsOptions:ClearFilterToken(displayID, groupID, token)
    local tokens = auraDisplays:GetGroupConditions(displayID, groupID, 'filterTokens') or {}
    for i = #tokens, 1, -1 do
        if tokens[i].token == token then
            table.remove(tokens, i)
        end
    end
    auraDisplays:UpdateGroupConditions(displayID, groupID, 'filterTokens', tokens)
end

function conditionsOptions:GetFilterTokenState(displayID, groupID, token)
    if self:HasFilterToken(displayID, groupID, token, true) then
        return 2
    end
    if self:HasFilterToken(displayID, groupID, token, false) then
        return 1
    end
    return 0
end

function conditionsOptions:SetFilterTokenState(displayID, groupID, token, state)
    self:ClearFilterToken(displayID, groupID, token)
    if state == 1 then
        self:ToggleFilterToken(displayID, groupID, token, false)
    elseif state == 2 then
        self:ToggleFilterToken(displayID, groupID, token, true)
    end
end

function conditionsOptions:GetFilterFields(displayID, groupID)
    local fields = {
        { type = 'title', label = 'Filter Tokens', width = 100 }
    }
    for _, token in ipairs(defaults.FILTER_TOKENS) do
        table.insert(fields, {
            type = 'tri-state-checkbox',
            label = token,
            name = 'filter_' .. token,
            width = 33,
            tooltip = {
                text = defaults.FILTER_TOKEN_TOOLTIPS[token],
            },
            currentValue = function()
                return self:GetFilterTokenState(displayID, groupID, token)
            end,
            onChange = function(state)
                self:SetFilterTokenState(displayID, groupID, token, state)
                auraDisplays:RefreshDisplay(displayID)
                refreshEditorOptions()
            end,
        })
    end
    table.insert(fields, {
        type = 'description',
        label = 'Filter Preview: ' .. self:GetFilterPreviewText(displayID, groupID),
        name = 'filterPreview',
        width = 100,
    })
    return fields
end

function conditionsOptions:GetOptions(displayID, groupID)
    groupNav:EnsureGroupSelected(displayID)
    groupID = groupID or auraDisplays.currGroupID
    if not groupID then return {} end

    local fields = {}
    append(fields, groupNav:GetFields(displayID))

    append(fields, {
        { type = 'title', label = 'Group', width = 100 },
        {
            type = 'toggle',
            label = 'Enable Group',
            name = 'groupEnable',
            width = 100,
            currentValue = function() return auraDisplays:GetGroupConditions(displayID, groupID, 'enable') end,
            onChange = function(v)
                auraDisplays:UpdateGroupConditions(displayID, groupID, 'enable', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'range',
            label = 'Max Auras',
            name = 'maxFrameCount',
            min = 1,
            max = 40,
            step = 1,
            width = 50,
            currentValue = function() return auraDisplays:GetGroupConditions(displayID, groupID, 'maxFrameCount') end,
            onChange = function(v)
                auraDisplays:UpdateGroupConditions(displayID, groupID, 'maxFrameCount', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Sort Method',
            name = 'sortMethod',
            width = 50,
            getOptions = function() return defaults.SORT_METHODS end,
            currentValue = function() return auraDisplays:GetGroupConditions(displayID, groupID, 'sortMethod') end,
            onChange = function(v)
                auraDisplays:UpdateGroupConditions(displayID, groupID, 'sortMethod', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Sort Direction',
            name = 'sortDirection',
            width = 50,
            getOptions = function() return { Normal = 'Normal', Reverse = 'Reverse' } end,
            currentValue = function() return auraDisplays:GetGroupConditions(displayID, groupID, 'sortDirection') end,
            onChange = function(v)
                auraDisplays:UpdateGroupConditions(displayID, groupID, 'sortDirection', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
    })

    append(fields, self:GetFilterFields(displayID, groupID))

    append(fields, {
        { type = 'title', label = 'Spell IDs',  width = 100 },
        {
            type = 'disclaimer',
            label =
            'Spell ID filters always apply to non-secret auras on any unit. For other auras they only apply to HELPFUL on friendly units and HARMFUL on enemy units.',
            name = 'spellIdNotice',
            width = 100,
            depends = function()
                return conditionsOptions:ShouldShowSpellIdNotice(displayID, groupID)
            end,
        },
        {
            type = 'spell-id-input',
            label = 'Include SpellIDs',
            name = 'includeSpellIDs',
            width = 50,
            align = 'TOP',
            getFilterString = function() return conditionsOptions:GetFilterPreview(displayID, groupID) end,
            currentValue = function() return auraDisplays:GetGroupConditions(displayID, groupID, 'includeSpellIDs') end,
            onChange = function(v)
                auraDisplays:UpdateGroupConditions(displayID, groupID, 'includeSpellIDs', v); auraDisplays
                    :RefreshDisplay(displayID)
            end,
        },
        {
            type = 'spell-id-input',
            label = 'Exclude SpellIDs',
            name = 'excludeSpellIDs',
            width = 50,
            align = 'TOP',
            getFilterString = function() return conditionsOptions:GetFilterPreview(displayID, groupID) end,
            currentValue = function() return auraDisplays:GetGroupConditions(displayID, groupID, 'excludeSpellIDs') end,
            onChange = function(v)
                auraDisplays:UpdateGroupConditions(displayID, groupID, 'excludeSpellIDs', v); auraDisplays
                    :RefreshDisplay(displayID)
            end,
        },
        {
            type = 'checkbox',
            label = 'Show spell IDs in aura tooltips',
            name = 'tooltipShowAuraSpellIDs',
            width = 100,
            tooltip = {
                text = 'Session only. Stays enabled until you exit the game.',
            },
            currentValue = function()
                if C_CVar and C_CVar.GetCVarBool then
                    return C_CVar.GetCVarBool('tooltipShowAuraSpellIDs')
                end
                return GetCVarBool and GetCVarBool('tooltipShowAuraSpellIDs')
            end,
            onChange = function(v)
                local value = v and '1' or '0'
                if C_CVar and C_CVar.SetCVar then
                    C_CVar.SetCVar('tooltipShowAuraSpellIDs', value)
                elseif SetCVar then
                    SetCVar('tooltipShowAuraSpellIDs', value)
                end
                refreshEditorOptions()
            end,
        },
        {
            type = 'range',
            label = 'Max Duration (0=off)',
            name = 'maxDuration',
            min = 0,
            max = 600,
            step = 1,
            width = 50,
            currentValue = function() return auraDisplays:GetGroupConditions(displayID, groupID, 'maxDuration') end,
            onChange = function(v)
                auraDisplays:UpdateGroupConditions(displayID, groupID, 'maxDuration', v); auraDisplays:RefreshDisplay(
                    displayID)
            end,
        },
        { type = 'title', label = 'Aura Flags', width = 100 },
    })

    for _, entry in ipairs(defaults.BOOL_CONDITION_FIELDS) do
        table.insert(fields, {
            type = 'tri-state-checkbox',
            label = defaults.BOOL_CONDITION_LABELS[entry] or entry,
            name = entry,
            width = 33,
            tooltip = {
                text = defaults.BOOL_CONDITION_TOOLTIPS[entry],
            },
            currentValue = function()
                local value = auraDisplays:GetGroupConditions(displayID, groupID, entry)
                if value == true then return 1 end
                if value == false then return 2 end
                return 0
            end,
            onChange = function(state)
                local value
                if state == 1 then
                    value = true
                elseif state == 2 then
                    value = false
                else
                    value = nil
                end
                auraDisplays:UpdateGroupConditions(displayID, groupID, entry, value)
                auraDisplays:RefreshDisplay(displayID)
                refreshEditorOptions()
            end,
        })
    end

    return fields
end
