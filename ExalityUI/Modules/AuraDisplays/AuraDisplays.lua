---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIAuraDisplaysDefaults
local defaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUIAuraDisplaysDisplay
local displayModule = EXUI:GetModule('aura-displays-display')

---@class EXUIAuraDisplaysVisualOptions
local visualOptions = EXUI:GetModule('aura-displays-visual-options')

---@class EXUIAuraDisplaysConditionsOptions
local conditionsOptions = EXUI:GetModule('aura-displays-conditions-options')

---@class EXUIAuraDisplaysContainerOptions
local containerOptions = EXUI:GetModule('aura-displays-container-options')

---@class EXUIAuraDisplaysLoadOptions
local loadOptions = EXUI:GetModule('aura-displays-load-options')

---@class EXUIAuraDisplaysGroupNav
local groupNav = EXUI:GetModule('aura-displays-group-nav')

---@class EXUIAuraDisplaysPreview
local preview = EXUI:GetModule('aura-displays-preview')

---@class EXUIAuraDisplaysModule
local auraDisplays = EXUI:GetModule('aura-displays')

auraDisplays.useTabs = false
auraDisplays.useSplitView = true
auraDisplays.useInnerTabs = true
auraDisplays.splitViewItemStyle = 'advanced'
auraDisplays.currGroupID = nil

local QUESTION_MARK_ICON = 134400

auraDisplays.splitViewExtraButton = {
    actions = {
        {
            icon = 'plus',
            text = 'Create',
            onClick = function()
                local displayID = auraDisplays:CreateNewDisplay()
                auraDisplays:RefreshAll()
                optionsFields:Refresh()
                optionsFields:SetItemID(displayID)
            end,
        },
        {
            icon = 'folderPlus',
            align = 'right',
            tooltip = 'Create Group',
            onClick = function()
                local groupID = auraDisplays:CreateListGroup()
                optionsFields:Refresh()
                optionsFields:SetItemID(groupID)
            end,
        },
        {
            icon = 'lock',
            align = 'right',
            tooltip = 'Unlock',
            onClick = function(button)
                local splitView = optionsFields.splitView
                if not splitView or not splitView.SetReorderEnabled then
                    return
                end
                local enabled = not splitView:IsReorderEnabled()
                splitView:SetReorderEnabled(enabled)
                button:SetIcon(enabled and 'unlock' or 'lock')
                button:SetTooltip(enabled and 'Lock' or 'Unlock')
            end,
        },
    },
}

auraDisplays.eventHandler = CreateFrame('Frame')
auraDisplays.eventHandler:RegisterEvent('PLAYER_ENTERING_WORLD')
auraDisplays.eventHandler:SetScript('OnEvent', function(self, event)
    if event == 'PLAYER_ENTERING_WORLD' then
        auraDisplays:RefreshAll()
    end
end)

function auraDisplays:Init()
    self:EnsureDB()
    EXUI:GetModule('aura-displays-load-conditions'):Init()
    EXUI:GetModule('aura-displays-unit-resolver'):Init()
    EXUI:GetModule('aura-displays-spell-index'):Init()
    preview:Init()
    optionsController:RegisterModule(self)
    self:RefreshAll()
end

function auraDisplays:GetName()
    return 'Aura Displays'
end

function auraDisplays:GetOrder()
    return 45
end

function auraDisplays:GetProfileExportSpec()
    return { id = 'aura-displays', keys = { 'aura-displays' } }
end

function auraDisplays:GetDB()
    local db = data:GetDataByKey('aura-displays')
    if not db then
        db = { displays = {}, __exuiDefaultsVersion = defaults.SCHEMA_VERSION }
        data:SetDataByKey('aura-displays', db)
    end
    return db
end

function auraDisplays:SaveDB(db)
    data:SetDataByKey('aura-displays', db)
end

function auraDisplays:EnsureDB()
    local db = self:GetDB()
    -- Merge every session so keys added after the last schema bump still get defaults.
    if db.__exuiDefaultsVersion ~= defaults.SCHEMA_VERSION or self.mergedDB ~= db then
        defaults:MergeIntoDB(db)
        self.mergedDB = db
        self:SaveDB(db)
    end
    return db
end

function auraDisplays:GetDisplay(displayID)
    local db = self:EnsureDB()
    return db.displays and db.displays[displayID]
end

function auraDisplays:UpdateDisplay(displayID, display)
    local db = self:EnsureDB()
    db.displays[displayID] = display
    self:SaveDB(db)
end

function auraDisplays:GetDisplayValue(displayID, key)
    local display = self:GetDisplay(displayID)
    return display and display[key]
end

function auraDisplays:UpdateDisplayValue(displayID, key, value)
    local display = self:GetDisplay(displayID)
    if not display then return end
    display[key] = value
    self:UpdateDisplay(displayID, display)
end

function auraDisplays:GetContainerValue(displayID, key)
    local display = self:GetDisplay(displayID)
    return display and display.container and display.container[key]
end

function auraDisplays:UpdateContainerValue(displayID, key, value)
    local display = self:GetDisplay(displayID)
    if not display then return end
    display.container = display.container or defaults:CopyTable(defaults.CONTAINER)
    display.container[key] = value
    self:UpdateDisplay(displayID, display)
end

function auraDisplays:GetGroup(displayID, groupID)
    local display = self:GetDisplay(displayID)
    return display and display.groups and display.groups[groupID]
end

function auraDisplays:GetGroupVisual(displayID, groupID, key)
    local group = self:GetGroup(displayID, groupID)
    return group and group.visual and group.visual[key]
end

function auraDisplays:UpdateGroupVisual(displayID, groupID, key, value)
    local group = self:GetGroup(displayID, groupID)
    if not group then return end
    group.visual = group.visual or defaults:CopyTable(defaults.GROUP_VISUAL)
    group.visual[key] = value
    self:UpdateDisplay(displayID, self:GetDisplay(displayID))
end

function auraDisplays:GetGroupConditions(displayID, groupID, key)
    local group = self:GetGroup(displayID, groupID)
    return group and group.conditions and group.conditions[key]
end

function auraDisplays:UpdateGroupConditions(displayID, groupID, key, value)
    local group = self:GetGroup(displayID, groupID)
    if not group then return end
    group.conditions = group.conditions or defaults:CopyTable(defaults.GROUP_CONDITIONS)
    group.conditions[key] = value
    self:UpdateDisplay(displayID, self:GetDisplay(displayID))
end

function auraDisplays:GetGroupLoad(displayID, groupID, key)
    local group = self:GetGroup(displayID, groupID)
    return group and group.load and group.load[key]
end

function auraDisplays:UpdateGroupLoad(displayID, groupID, key, value)
    local group = self:GetGroup(displayID, groupID)
    if not group then return end
    group.load = group.load or defaults:CopyTable(defaults.GROUP_LOAD)
    group.load[key] = value
    self:UpdateDisplay(displayID, self:GetDisplay(displayID))
end

function auraDisplays:CreateNewDisplay()
    local db = self:EnsureDB()
    local displayID, display = defaults:BuildNewDisplay()
    display.listGroupID = nil
    display.order = self:NextListOrder(nil)
    db.displays[displayID] = display
    self:SaveDB(db)
    self.currGroupID = display.groupOrder[1]
    return displayID
end

function auraDisplays:DeleteDisplay(displayID)
    local db = self:EnsureDB()
    db.displays[displayID] = nil
    self:SaveDB(db)
    displayModule:DestroyFrame(displayID)
    if self.currGroupID and not db.displays[displayID] then
        self.currGroupID = nil
    end
end

function auraDisplays:DuplicateDisplay(displayID)
    local db = self:EnsureDB()
    local source = db.displays and db.displays[displayID]
    if not source then return end

    local newDisplayID = EXUI.utils.generateRandomString(12)
    local parentID = self:DisplayListParent(source)
    local display = EXUI.utils.deepCloneTable(source)
    display.name = (display.name or 'Aura Display') .. ' Copy'
    display.createdAt = time()
    display.listGroupID = parentID
    display.order = self:NextListOrder(parentID)

    db.displays[newDisplayID] = display
    self:SaveDB(db)
    self.currGroupID = display.groupOrder and display.groupOrder[1]
    self:RefreshAll()

    return newDisplayID
end

function auraDisplays:AddGroup(displayID)
    local display = self:GetDisplay(displayID)
    if not display then return end
    local groupID = EXUI.utils.generateRandomString(12)
    display.groups[groupID] = defaults:BuildNewGroup()
    table.insert(display.groupOrder, groupID)
    self:UpdateDisplay(displayID, display)
    return groupID
end

function auraDisplays:RemoveGroup(displayID, groupID)
    local display = self:GetDisplay(displayID)
    if not display or #display.groupOrder <= 1 then return end
    for i, id in ipairs(display.groupOrder) do
        if id == groupID then
            table.remove(display.groupOrder, i)
            break
        end
    end
    display.groups[groupID] = nil
    self:UpdateDisplay(displayID, display)
end

function auraDisplays:DuplicateGroup(displayID, groupID)
    local display = self:GetDisplay(displayID)
    local source = display and display.groups[groupID]
    if not source then return end
    local newGroupID = EXUI.utils.generateRandomString(12)
    display.groups[newGroupID] = EXUI.utils.deepCloneTable(source)
    table.insert(display.groupOrder, newGroupID)
    self:UpdateDisplay(displayID, display)
    return newGroupID
end

local function ParentMatches(parentID, nodeParent)
    if not parentID then
        return not nodeParent
    end
    return nodeParent == parentID
end

local function CompareListOrder(a, b)
    local aOrder = a.order or math.huge
    local bOrder = b.order or math.huge
    if aOrder ~= bOrder then
        return aOrder < bOrder
    end
    local aTime = a.createdAt or 0
    local bTime = b.createdAt or 0
    if aTime ~= bTime then
        return aTime < bTime
    end
    return (a.name or '') < (b.name or '')
end

function auraDisplays:GetListGroups()
    local db = self:EnsureDB()
    return db.__groups or {}
end

function auraDisplays:GetListGroup(groupID)
    if not groupID then
        return nil
    end
    return self:GetListGroups()[groupID]
end

function auraDisplays:ListGroupParent(group)
    if not group then
        return nil
    end
    local parentID = group.parentID
    if parentID and self:GetListGroup(parentID) then
        return parentID
    end
    return nil
end

function auraDisplays:DisplayListParent(display)
    if not display then
        return nil
    end
    local groupID = display.listGroupID
    if groupID and self:GetListGroup(groupID) then
        return groupID
    end
    return nil
end

function auraDisplays:IsListGroupEnabled(groupID)
    if not groupID then
        return true
    end
    local seen = {}
    while groupID do
        if seen[groupID] then
            return true
        end
        seen[groupID] = true
        local group = self:GetListGroup(groupID)
        if not group then
            return true
        end
        if group.enable == false then
            return false
        end
        groupID = group.parentID
    end
    return true
end

function auraDisplays:IsDisplayShown(display)
    if not display or not display.enable then
        return false
    end
    return self:IsListGroupEnabled(display.listGroupID)
end

function auraDisplays:ListGroupContains(ancestorID, nodeID)
    if not ancestorID or not nodeID then
        return false
    end
    local seen = {}
    local current = nodeID
    while current do
        if current == ancestorID then
            return true
        end
        if seen[current] then
            return false
        end
        seen[current] = true
        local group = self:GetListGroup(current)
        if not group then
            return false
        end
        current = group.parentID
    end
    return false
end

function auraDisplays:CollectListSiblings(parentID, skipID, skipIsGroup)
    local nodes = {}
    for groupID, group in pairs(self:GetListGroups()) do
        if not (skipIsGroup and groupID == skipID) and ParentMatches(parentID, self:ListGroupParent(group)) then
            nodes[#nodes + 1] = {
                ref = group,
                isGroup = true,
                id = groupID,
                order = group.order,
                createdAt = group.createdAt,
                name = group.name,
            }
        end
    end
    local db = self:EnsureDB()
    for id, display in pairs(db.displays or {}) do
        if type(display) == 'table' and not (skipIsGroup == false and id == skipID) and ParentMatches(parentID, self:DisplayListParent(display)) then
            nodes[#nodes + 1] = {
                ref = display,
                isGroup = false,
                id = id,
                order = display.order,
                createdAt = display.createdAt,
                name = display.name,
            }
        end
    end
    table.sort(nodes, CompareListOrder)
    return nodes
end

function auraDisplays:WriteListSiblingOrder(nodes)
    for index, node in ipairs(nodes) do
        node.ref.order = index
    end
end

function auraDisplays:NextListOrder(parentID)
    local nodes = self:CollectListSiblings(parentID)
    local needsWrite = false
    local maxOrder = 0
    for _, node in ipairs(nodes) do
        if not node.ref.order then
            needsWrite = true
        elseif node.ref.order > maxOrder then
            maxOrder = node.ref.order
        end
    end
    if needsWrite then
        self:WriteListSiblingOrder(nodes)
        return #nodes + 1
    end
    return maxOrder + 1
end

function auraDisplays:CreateListGroup()
    local db = self:EnsureDB()
    db.__groups = db.__groups or {}
    local groupID = EXUI.utils.generateRandomString(12)
    db.__groups[groupID] = {
        name = 'New Group',
        icon = QUESTION_MARK_ICON,
        enable = true,
        createdAt = time(),
        parentID = nil,
        order = self:NextListOrder(nil),
    }
    self:SaveDB(db)
    return groupID
end

function auraDisplays:UpdateListGroupValue(groupID, key, value)
    local db = self:EnsureDB()
    local group = db.__groups and db.__groups[groupID]
    if not group then
        return
    end
    group[key] = value
    self:SaveDB(db)
end

function auraDisplays:DeleteListGroup(groupID)
    local db = self:EnsureDB()
    local group = db.__groups and db.__groups[groupID]
    if not group then
        return
    end
    local parentID = self:ListGroupParent(group)
    local moved = {}
    for id, child in pairs(db.__groups) do
        if id ~= groupID and child.parentID == groupID then
            moved[#moved + 1] = {
                ref = child,
                order = child.order,
                createdAt = child.createdAt,
                name = child.name,
                isGroup = true,
            }
        end
    end
    for _, display in pairs(db.displays or {}) do
        if type(display) == 'table' and display.listGroupID == groupID then
            moved[#moved + 1] = {
                ref = display,
                order = display.order,
                createdAt = display.createdAt,
                name = display.name,
                isGroup = false,
            }
        end
    end
    table.sort(moved, CompareListOrder)
    local nextOrder = self:NextListOrder(parentID)
    for _, node in ipairs(moved) do
        if node.isGroup then
            node.ref.parentID = parentID
        else
            node.ref.listGroupID = parentID
        end
        node.ref.order = nextOrder
        nextOrder = nextOrder + 1
    end
    db.__groups[groupID] = nil
    self:SaveDB(db)
    self:RefreshAll()
end

function auraDisplays:Reorder(id, isGroup, parentID, index)
    local db = self:EnsureDB()
    if parentID and not self:GetListGroup(parentID) then
        parentID = nil
    end
    local ref
    local oldParent
    if isGroup then
        ref = db.__groups and db.__groups[id]
        if not ref then
            return
        end
        if id == parentID or self:ListGroupContains(id, parentID) then
            return
        end
        oldParent = self:ListGroupParent(ref)
        ref.parentID = parentID
    else
        ref = db.displays and db.displays[id]
        if type(ref) ~= 'table' then
            return
        end
        oldParent = self:DisplayListParent(ref)
        ref.listGroupID = parentID
    end
    local siblings = self:CollectListSiblings(parentID, id, isGroup and true or false)
    index = math.floor(tonumber(index) or (#siblings + 1))
    if index < 1 then
        index = 1
    end
    if index > #siblings + 1 then
        index = #siblings + 1
    end
    table.insert(siblings, index, { ref = ref })
    self:WriteListSiblingOrder(siblings)
    if not ParentMatches(oldParent, parentID) then
        self:WriteListSiblingOrder(self:CollectListSiblings(oldParent))
    end
    self:SaveDB(db)
    optionsFields:RefreshItemList()
    self:RefreshAll()
end

function auraDisplays:GetListGroupOptions(groupID)
    return optionsFields:GetGroupFields({
        get = function(key)
            local group = auraDisplays:GetListGroup(groupID)
            return group and group[key]
        end,
        set = function(key, value)
            auraDisplays:UpdateListGroupValue(groupID, key, value)
        end,
        onChange = function(key)
            if key == 'enable' then
                auraDisplays:RefreshAll()
                preview:Sync()
                optionsFields:RefreshItemList()
            else
                optionsFields:RefreshItemList()
            end
        end,
    })
end

function auraDisplays:GetListIcon(display)
    local subtitle = 'Player'
    local unit = display.container and display.container.unit or 'player'
    if defaults.UNIT_OPTIONS[unit] then
        subtitle = defaults.UNIT_OPTIONS[unit]
    elseif unit and unit ~= '' then
        subtitle = unit
    end

    if display.icon then
        return display.icon, subtitle
    end

    for _, groupID in ipairs(display.groupOrder or {}) do
        local group = display.groups and display.groups[groupID]
        local text = group and group.conditions and group.conditions.includeSpellIDs
        local spellID = text and tonumber(tostring(text):match('%d+'))
        if spellID then
            local texture
            if C_Spell and C_Spell.GetSpellTexture then
                texture = C_Spell.GetSpellTexture(spellID)
            elseif GetSpellTexture then
                texture = GetSpellTexture(spellID)
            end
            if texture then
                return texture, subtitle
            end
        end
    end
    return QUESTION_MARK_ICON, subtitle
end

function auraDisplays:DisplayContextMenu()
    return {
        {
            label = 'Duplicate',
            color = { 2 / 255, 145 / 255, 227 / 255, 1 },
            onClick = function(itemID)
                local newID = self:DuplicateDisplay(itemID)
                if newID then
                    optionsFields:Refresh()
                    optionsFields:SetItemID(newID)
                end
            end,
        },
        {
            label = 'Delete',
            color = EXUI.EXFrames.Theme.danger,
            onClick = function(itemID)
                self:DeleteDisplay(itemID)
                optionsFields:Refresh()
            end,
        },
    }
end

function auraDisplays:ListGroupContextMenu()
    return {
        {
            label = 'Delete',
            color = EXUI.EXFrames.Theme.danger,
            onClick = function(itemID)
                local selected = optionsFields.currItemID == itemID
                self:DeleteListGroup(itemID)
                if selected then
                    optionsFields.currItemID = nil
                    optionsFields:Refresh()
                else
                    optionsFields:RefreshItemList()
                end
            end,
        },
    }
end

function auraDisplays:GetSplitViewItems()
    local icons = EXUI.const.textures.frame.icons
    local items = {}
    local seen = {}

    local function emit(parentID, depth)
        if parentID and seen[parentID] then
            return
        end
        if parentID then
            seen[parentID] = true
        end
        for _, node in ipairs(self:CollectListSiblings(parentID)) do
            if node.isGroup then
                if not seen[node.id] then
                    local group = node.ref
                    local row = {
                        type = 'group',
                        selectable = true,
                        ID = node.id,
                        label = group.name or 'Group',
                        icon = group.icon or QUESTION_MARK_ICON,
                        depth = depth,
                        parentID = parentID,
                        contextMenuItems = self:ListGroupContextMenu(),
                    }
                    if not self:IsListGroupEnabled(node.id) then
                        row.statusIcon = 'inactive'
                    end
                    items[#items + 1] = row
                    emit(node.id, depth + 1)
                end
            else
                local icon, sublabel = self:GetListIcon(node.ref)
                local row = {
                    ID = node.id,
                    label = node.ref.name or 'Aura Display',
                    sublabel = sublabel,
                    icon = icon,
                    depth = depth,
                    parentID = parentID,
                    preview = {
                        enabled = preview:IsToggled(node.id),
                        iconOn = icons.eye,
                        iconOff = icons.eyeOff,
                        onToggle = function(itemID, enabled)
                            preview:SetToggled(itemID, enabled, true)
                        end,
                    },
                    contextMenuItems = self:DisplayContextMenu(),
                }
                if not self:IsDisplayShown(node.ref) then
                    row.statusIcon = 'inactive'
                end
                items[#items + 1] = row
            end
        end
    end

    emit(nil, 0)
    return items
end

function auraDisplays:GetSectionTabs(itemId)
    if not itemId or self:GetListGroup(itemId) or not self:GetDisplay(itemId) then
        return {}
    end
    groupNav:EnsureGroupSelected(itemId)
    return {
        { ID = 'container', label = 'Container' },
        { ID = 'visual', label = 'Visual' },
        { ID = 'conditions', label = 'Conditions' },
        { ID = 'load', label = 'Load' },
    }
end

function auraDisplays:GetOptions(currTabID, currItemID)
    if not currItemID then
        local groupID
        for _, item in ipairs(self:GetSplitViewItems()) do
            if item.ID and item.type ~= 'category' then
                if item.type ~= 'group' then
                    currItemID = item.ID
                    break
                elseif item.selectable and not groupID then
                    groupID = item.ID
                end
            end
        end
        currItemID = currItemID or groupID
    end
    if not currItemID then return {} end
    if self:GetListGroup(currItemID) then
        return self:GetListGroupOptions(currItemID)
    end
    local display = self:GetDisplay(currItemID)
    if not display then return {} end
    groupNav:EnsureGroupSelected(currItemID)
    local section = currTabID or 'container'
    local groupID = self.currGroupID

    local fields = {}
    if section == 'container' then
        fields = containerOptions:GetOptions(currItemID)
    elseif section == 'visual' then
        fields = visualOptions:GetOptions(currItemID, groupID)
    elseif section == 'conditions' then
        fields = conditionsOptions:GetOptions(currItemID, groupID)
    elseif section == 'load' then
        fields = loadOptions:GetOptions(currItemID, groupID)
    end

    return fields
end

function auraDisplays:RefreshDisplay(displayID)
    local display = self:GetDisplay(displayID)

    if preview:IsConfiguring(displayID) then
        if not self:IsDisplayShown(display) then
            preview:HidePreview(displayID)
            displayModule:Refresh(displayID, display)
            return
        end

        -- Keep the real container in sync while options are open; preview stays visible instead.
        displayModule:Refresh(displayID, display)
        preview:Refresh(displayID)
        return
    end

    if display then
        displayModule:Refresh(displayID, display)
    end
end

function auraDisplays:RefreshAll()
    displayModule:RefreshAll()
end
