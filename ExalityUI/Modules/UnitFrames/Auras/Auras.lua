---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIUnitFramesAurasDefaults
local defaults = EXUI:GetModule('uf-auras-defaults')

---@class EXUIAuraDisplaysDefaults
local adDefaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUIAuraDisplaysLoadConditions
local loadConditions = EXUI:GetModule('aura-displays-load-conditions')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIShare
local share = EXUI:GetModule('share')

---@class EXUIUnitFramesAuras
local ufAuras = EXUI:GetModule('uf-auras')

ufAuras.currGroupID = nil
ufAuras.contextUnit = nil
ufAuras.skipScreenPosition = true

function ufAuras:Init()
    self:EnsureDB()
    EXUI:GetModule('uf-auras-apply'):Init()
    EXUI:GetModule('uf-auras-preview'):Init()
end

function ufAuras:GetDB()
    local uf = data:GetDataByKey('UF')
    if not uf then
        uf = {}
        data:SetDataByKey('UF', uf)
    end
    if not uf.auraDisplays then
        uf.auraDisplays = { displays = {}, __exuiDefaultsVersion = defaults.SCHEMA_VERSION }
        data:SetDataByKey('UF', uf)
    end
    return uf.auraDisplays
end

function ufAuras:SaveDB(db)
    local uf = data:GetDataByKey('UF') or {}
    uf.auraDisplays = db
    data:SetDataByKey('UF', uf)
end

function ufAuras:EnsureDB()
    local db = self:GetDB()
    local dirty = false
    -- Merge every session so keys added after the last schema bump still get defaults.
    if db.__exuiDefaultsVersion ~= defaults.SCHEMA_VERSION or self.mergedDB ~= db then
        defaults:MergeIntoDB(db)
        self.mergedDB = db
        dirty = true
    end
    if defaults:SeedStarterDisplays(db) then
        defaults:MergeIntoDB(db)
        dirty = true
    end
    if defaults:SeedAnkhDisplay(db) then
        defaults:MergeIntoDB(db)
        dirty = true
    end
    if dirty then
        self:SaveDB(db)
    end
    return db
end

function ufAuras:GetDisplay(displayID)
    local db = self:EnsureDB()
    return db.displays and db.displays[displayID]
end

function ufAuras:UpdateDisplay(displayID, display)
    local db = self:EnsureDB()
    db.displays[displayID] = display
    self:SaveDB(db)
end

function ufAuras:GetDisplayValue(displayID, key)
    local display = self:GetDisplay(displayID)
    return display and display[key]
end

function ufAuras:UpdateDisplayValue(displayID, key, value)
    local display = self:GetDisplay(displayID)
    if not display then return end
    display[key] = value
    self:UpdateDisplay(displayID, display)
end

function ufAuras:GetContainerValue(displayID, key)
    local display = self:GetDisplay(displayID)
    return display and display.container and display.container[key]
end

function ufAuras:UpdateContainerValue(displayID, key, value)
    local display = self:GetDisplay(displayID)
    if not display then return end
    display.container = display.container or defaults:CopyTable(adDefaults.CONTAINER)
    display.container[key] = value
    self:UpdateDisplay(displayID, display)
end

function ufAuras:GetGroup(displayID, groupID)
    local display = self:GetDisplay(displayID)
    return display and display.groups and display.groups[groupID]
end

function ufAuras:GetGroupVisual(displayID, groupID, key)
    local group = self:GetGroup(displayID, groupID)
    return group and group.visual and group.visual[key]
end

function ufAuras:UpdateGroupVisual(displayID, groupID, key, value)
    local group = self:GetGroup(displayID, groupID)
    if not group then return end
    group.visual = group.visual or defaults:CopyTable(adDefaults.GROUP_VISUAL)
    group.visual[key] = value
    self:UpdateDisplay(displayID, self:GetDisplay(displayID))
end

function ufAuras:GetGroupConditions(displayID, groupID, key)
    local group = self:GetGroup(displayID, groupID)
    return group and group.conditions and group.conditions[key]
end

function ufAuras:UpdateGroupConditions(displayID, groupID, key, value)
    local group = self:GetGroup(displayID, groupID)
    if not group then return end
    group.conditions = group.conditions or defaults:CopyTable(adDefaults.GROUP_CONDITIONS)
    group.conditions[key] = value
    self:UpdateDisplay(displayID, self:GetDisplay(displayID))
end

function ufAuras:GetGroupLoad(displayID, groupID, key)
    local group = self:GetGroup(displayID, groupID)
    return group and group.load and group.load[key]
end

function ufAuras:UpdateGroupLoad(displayID, groupID, key, value)
    local group = self:GetGroup(displayID, groupID)
    if not group then return end
    group.load = group.load or defaults:CopyTable(adDefaults.GROUP_LOAD)
    group.load[key] = value
    self:UpdateDisplay(displayID, self:GetDisplay(displayID))
end

function ufAuras:CreateNewDisplay(contextUnit)
    local db = self:EnsureDB()
    local displayID, display = defaults:BuildNewDisplay(contextUnit or self.contextUnit)
    display.listGroupID = nil
    display.order = self:NextListOrder(nil)
    db.displays[displayID] = display
    self:SaveDB(db)
    self.currGroupID = display.groupOrder[1]
    return displayID
end

function ufAuras:DeleteDisplay(displayID)
    local db = self:EnsureDB()
    db.displays[displayID] = nil
    self:SaveDB(db)
    if self.currGroupID then
        self.currGroupID = nil
    end
    EXUI:GetModule('uf-auras-apply'):RefreshAll()
end

function ufAuras:DuplicateDisplay(displayID)
    local source = self:GetDisplay(displayID)
    if not source then return end
    local db = self:EnsureDB()
    local newID = EXUI.utils.generateRandomString(12)
    local copy = defaults:CopyTable(source)
    copy.name = (source.name or 'Aura') .. ' Copy'
    copy.createdAt = time()
    local newGroups = {}
    local newOrder = {}
    for _, groupID in ipairs(copy.groupOrder or {}) do
        local newGroupID = EXUI.utils.generateRandomString(12)
        newGroups[newGroupID] = copy.groups[groupID]
        table.insert(newOrder, newGroupID)
    end
    copy.groups = newGroups
    copy.groupOrder = newOrder
    local parentID = self:DisplayListParent(source)
    copy.listGroupID = parentID
    copy.order = self:NextListOrder(parentID)
    db.displays[newID] = copy
    self:SaveDB(db)
    self.currGroupID = newOrder[1]
    return newID
end

function ufAuras:AddGroup(displayID)
    local display = self:GetDisplay(displayID)
    if not display then return end
    local groupID = EXUI.utils.generateRandomString(12)
    display.groups = display.groups or {}
    display.groupOrder = display.groupOrder or {}
    display.groups[groupID] = defaults:BuildNewGroup()
    table.insert(display.groupOrder, groupID)
    self:UpdateDisplay(displayID, display)
    return groupID
end

function ufAuras:RemoveGroup(displayID, groupID)
    local display = self:GetDisplay(displayID)
    if not display or not display.groups or not display.groups[groupID] then return end
    if #(display.groupOrder or {}) <= 1 then return end
    display.groups[groupID] = nil
    for i = #display.groupOrder, 1, -1 do
        if display.groupOrder[i] == groupID then
            table.remove(display.groupOrder, i)
        end
    end
    self:UpdateDisplay(displayID, display)
end

function ufAuras:DuplicateGroup(displayID, groupID)
    local display = self:GetDisplay(displayID)
    local group = display and display.groups and display.groups[groupID]
    if not group then return end
    local newGroupID = EXUI.utils.generateRandomString(12)
    display.groups[newGroupID] = defaults:CopyTable(group)
    local insertAt = #display.groupOrder + 1
    for i, id in ipairs(display.groupOrder) do
        if id == groupID then
            insertAt = i + 1
            break
        end
    end
    table.insert(display.groupOrder, insertAt, newGroupID)
    self:UpdateDisplay(displayID, display)
    return newGroupID
end

function ufAuras:DisplayAppliesToUnit(display, unitType)
    return display and display.units and display.units[unitType] == true
end

function ufAuras:DisplayHasLoadableGroup(display)
    if not display or not display.groups then
        return false
    end
    for _, groupID in ipairs(display.groupOrder or {}) do
        local group = display.groups[groupID]
        if group and group.conditions and group.conditions.enable and loadConditions:ShouldIncludeGroup(group.load) then
            return true
        end
    end
    return false
end

function ufAuras:IsDisplayEnabled(display)
    if not display or display.enable == false then
        return false
    end
    return self:IsListGroupEnabled(display.listGroupID)
end

function ufAuras:IsDisplayActiveForUnit(displayID, unitType)
    local display = self:GetDisplay(displayID)
    if not self:IsDisplayEnabled(display) then
        return false
    end
    if not self:DisplayAppliesToUnit(display, unitType) then
        return false
    end
    return self:DisplayHasLoadableGroup(display)
end

function ufAuras:GetDisplaysForUnitType(unitType)
    local db = self:EnsureDB()
    local result = {}
    for displayID, display in pairs(db.displays or {}) do
        if self:DisplayAppliesToUnit(display, unitType) then
            result[displayID] = display
        end
    end
    return result
end

function ufAuras:CountDisplaysForUnitType(unitType)
    local count = 0
    for _ in pairs(self:GetDisplaysForUnitType(unitType)) do
        count = count + 1
    end
    return count
end

function ufAuras:GetMaxDisplaysForUnitType(unitType)
    return math.max(3, self:CountDisplaysForUnitType(unitType) + 2)
end

function ufAuras:GetOrderedDisplays()
    local db = self:EnsureDB()
    local list = {}
    for displayID, display in pairs(db.displays or {}) do
        table.insert(list, { ID = displayID, display = display })
    end
    table.sort(list, function(a, b)
        local aTime = a.display.createdAt or 0
        local bTime = b.display.createdAt or 0
        if aTime ~= bTime then
            return aTime < bTime
        end
        return (a.display.name or '') < (b.display.name or '')
    end)
    return list
end

local LIST_ICON = 134400

local function ListParentMatches(parentID, nodeParent)
    if not parentID then
        return not nodeParent
    end
    return nodeParent == parentID
end

local function CompareListOrder(a, b)
    local aInactive = a.inactive and true or false
    local bInactive = b.inactive and true or false
    if aInactive ~= bInactive then
        return not aInactive
    end
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

function ufAuras:GetListGroups()
    local db = self:EnsureDB()
    return db.__groups or {}
end

function ufAuras:GetListGroup(groupID)
    if not groupID then
        return nil
    end
    return self:GetListGroups()[groupID]
end

function ufAuras:ListGroupParent(group)
    if not group then
        return nil
    end
    local parentID = group.parentID
    if parentID and self:GetListGroup(parentID) then
        return parentID
    end
    return nil
end

function ufAuras:DisplayListParent(display)
    if type(display) ~= 'table' then
        return nil
    end
    local groupID = display.listGroupID
    if groupID and self:GetListGroup(groupID) then
        return groupID
    end
    return nil
end

function ufAuras:IsListGroupEnabled(groupID)
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

function ufAuras:ListGroupContains(ancestorID, nodeID)
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

function ufAuras:CollectListSiblings(parentID, skipID, skipIsGroup)
    local nodes = {}
    for groupID, group in pairs(self:GetListGroups()) do
        if not (skipIsGroup and groupID == skipID) and ListParentMatches(parentID, self:ListGroupParent(group)) then
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
        if type(display) == 'table' and not (skipIsGroup == false and id == skipID) and ListParentMatches(parentID, self:DisplayListParent(display)) then
            nodes[#nodes + 1] = {
                ref = display,
                isGroup = false,
                id = id,
                order = display.order,
                createdAt = display.createdAt,
                name = display.name,
                inactive = not self:IsDisplayActiveForUnit(id, self.contextUnit),
            }
        end
    end
    table.sort(nodes, CompareListOrder)
    return nodes
end

function ufAuras:WriteListSiblingOrder(nodes)
    for index, node in ipairs(nodes) do
        node.ref.order = index
    end
end

function ufAuras:NextListOrder(parentID)
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

function ufAuras:CreateListGroup()
    local db = self:EnsureDB()
    db.__groups = db.__groups or {}
    local groupID = EXUI.utils.generateRandomString(12)
    db.__groups[groupID] = {
        name = 'New Group',
        icon = LIST_ICON,
        enable = true,
        createdAt = time(),
        parentID = nil,
        order = self:NextListOrder(nil),
    }
    self:SaveDB(db)
    return groupID
end

function ufAuras:UpdateListGroupValue(groupID, key, value)
    local db = self:EnsureDB()
    local group = db.__groups and db.__groups[groupID]
    if not group then
        return
    end
    group[key] = value
    self:SaveDB(db)
end

function ufAuras:DeleteListGroup(groupID)
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

function ufAuras:Reorder(id, isGroup, parentID, index)
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
    if not ListParentMatches(oldParent, parentID) then
        self:WriteListSiblingOrder(self:CollectListSiblings(oldParent))
    end
    self:SaveDB(db)
    self:RefreshEditorList()
    self:RefreshAll()
end

function ufAuras:GetListGroupOptions(groupID)
    return optionsFields:GetGroupFields({
        get = function(key)
            local group = ufAuras:GetListGroup(groupID)
            return group and group[key]
        end,
        set = function(key, value)
            ufAuras:UpdateListGroupValue(groupID, key, value)
        end,
        onChange = function(key)
            if key == 'enable' then
                ufAuras:RefreshAll()
            end
            ufAuras:RefreshEditorList()
        end,
    })
end

function ufAuras:DisplayContextMenu()
    return {
        share:ExportMenuItem('uf-auras', 'item'),
        {
            label = 'Duplicate',
            onClick = function(id)
                local newID = self:DuplicateDisplay(id)
                self:RefreshDisplay(newID)
                local editor = EXUI:GetModule('uf-aura-editor')
                if editor and editor.Refresh then
                    editor:Refresh(newID)
                end
            end,
        },
        {
            label = 'Delete',
            color = EXUI.EXFrames and EXUI.EXFrames.Theme.danger,
            onClick = function(id)
                self:DeleteDisplay(id)
                local editor = EXUI:GetModule('uf-aura-editor')
                if editor and editor.Refresh then
                    editor:Refresh()
                end
            end,
        },
    }
end

function ufAuras:ListGroupContextMenu()
    return {
        share:ExportMenuItem('uf-auras', 'group'),
        {
            label = 'Delete',
            color = EXUI.EXFrames and EXUI.EXFrames.Theme.danger,
            onClick = function(itemID)
                local editor = EXUI:GetModule('uf-aura-editor')
                local selected = editor and editor.currItemID == itemID
                self:DeleteListGroup(itemID)
                if editor and editor.Refresh then
                    if selected then
                        editor.currItemID = nil
                    end
                    editor:Refresh()
                end
            end,
        },
    }
end

function ufAuras:GetSplitViewItems(contextUnit)
    contextUnit = contextUnit or self.contextUnit
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
                        icon = group.icon or LIST_ICON,
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
                local item = {
                    ID = node.id,
                    label = node.ref.name or 'Aura Display',
                    sublabel = defaults:FormatUnitsSubtitle(node.ref.units),
                    icon = node.ref.icon or LIST_ICON,
                    depth = depth,
                    parentID = parentID,
                    contextMenuItems = self:DisplayContextMenu(),
                }
                if not self:IsDisplayActiveForUnit(node.id, contextUnit) then
                    item.statusIcon = 'inactive'
                end
                items[#items + 1] = item
            end
        end
    end

    emit(nil, 0)
    return items
end

function ufAuras:RefreshDisplay(displayID)
    EXUI:GetModule('uf-auras-apply'):RefreshDisplay(displayID)
    local preview = EXUI:GetModule('uf-auras-preview')
    if preview and preview.OnDisplayChanged then
        preview:OnDisplayChanged(displayID)
    end
end

function ufAuras:RefreshAll()
    EXUI:GetModule('uf-auras-apply'):RefreshAll()
    local preview = EXUI:GetModule('uf-auras-preview')
    if preview and preview.IsEditorOpen and preview:IsEditorOpen() then
        preview:Sync()
    end
end

function ufAuras:RefreshEditorList()
    local editor = EXUI:GetModule('uf-aura-editor')
    if editor and editor.window and editor.window:IsShown() and editor.RefreshItemList then
        editor:RefreshItemList()
    end
end

function ufAuras:GetUnitTypeForFrame(frame)
    if not frame then return nil end

    -- Party/raid header children keep this even when showPlayer sets unit to "player".
    if frame.exuiUnitType then
        return frame.exuiUnitType
    end
    for _, partyFrame in ipairs(ufCore.partyFrames or {}) do
        if partyFrame == frame then
            return 'party'
        end
    end
    for _, raidFrame in ipairs(ufCore.raidFrames or {}) do
        if raidFrame == frame then
            return 'raid'
        end
    end

    -- ForceShow remaps frame.__unit to 'player'; prefer the real unit token.
    local unit = (frame.isFake and frame.originalUnit) or frame.__unit or frame.originalUnit
    if not unit then return nil end
    if ufCore.groupUnitMap and ufCore.groupUnitMap[unit] then
        return ufCore.groupUnitMap[unit]
    end
    if unit:match('^boss%d') then
        return 'boss'
    end
    if unit:match('^arena%d') then
        return 'arena'
    end
    if unit:match('^party%d') then
        return 'party'
    end
    if unit:match('^raid%d') then
        return 'raid'
    end
    return unit
end

share:Register({
    id = 'uf-auras',
    parentKey = 'listGroupID',
    idLength = 12,
    getGroup = function(id)
        return ufAuras:GetListGroup(id)
    end,
    eachGroup = function(callback)
        for id, group in pairs(ufAuras:GetListGroups()) do
            callback(id, group)
        end
    end,
    getItem = function(id)
        return ufAuras:GetDisplay(id)
    end,
    eachItem = function(callback)
        local db = ufAuras:EnsureDB()
        for id, display in pairs(db.displays or {}) do
            if type(display) == 'table' then
                callback(id, display)
            end
        end
    end,
    nextOrder = function(parentID)
        return ufAuras:NextListOrder(parentID)
    end,
    addGroup = function(id, group)
        local db = ufAuras:EnsureDB()
        db.__groups = db.__groups or {}
        db.__groups[id] = group
        ufAuras:SaveDB(db)
    end,
    addItem = function(id, item)
        local db = ufAuras:EnsureDB()
        db.displays = db.displays or {}
        db.displays[id] = item
        ufAuras:SaveDB(db)
    end,
    finish = function(selectID)
        ufAuras:RefreshAll()
        local editor = EXUI:GetModule('uf-aura-editor')
        if editor and editor.Refresh then
            editor:Refresh(selectID)
        end
    end,
})
