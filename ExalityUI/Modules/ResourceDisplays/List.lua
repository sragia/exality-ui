---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIResourceDisplaysDefaults
local defaults = EXUI:GetModule('resource-displays-defaults')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

---@class EXUIResourceDisplaysGeneralOptions
local generalOptions = EXUI:GetModule('resource-displays-general-options')

---@class EXUIResourceDisplaysDisplayOptions
local displayOptions = EXUI:GetModule('resource-displays-display-options')

---@class EXUIResourceDisplaysLoadOptions
local loadOptions = EXUI:GetModule('resource-displays-load-options')

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

local QUESTION_MARK_ICON = 134400

core.splitViewItemStyle = 'advanced'
core.splitViewExtraButton = {
    actions = {
        {
            icon = 'plus',
            text = 'Create',
            onClick = function()
                local displayID = core:CreateNewDisplay()
                core:InitFrames()
                optionsFields:Refresh()
                optionsFields:SetItemID(displayID)
            end,
        },
        {
            icon = 'folderPlus',
            align = 'right',
            tooltip = 'Create Group',
            onClick = function()
                local groupID = core:CreateListGroup()
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

local function SaveDB(db)
    data:SetDataByKey('resource-displays', db)
end

function core:GetListGroups()
    local db = self:GetDB()
    return db and db.__groups or {}
end

function core:GetListGroup(groupID)
    if not groupID then
        return nil
    end
    return self:GetListGroups()[groupID]
end

function core:ListGroupParent(group)
    if not group then
        return nil
    end
    local parentID = group.parentID
    if parentID and self:GetListGroup(parentID) then
        return parentID
    end
    return nil
end

function core:DisplayListParent(display)
    if type(display) ~= 'table' then
        return nil
    end
    local groupID = display.listGroupID
    if groupID and self:GetListGroup(groupID) then
        return groupID
    end
    return nil
end

function core:IsListGroupEnabled(groupID)
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

function core:IsDisplayShown(display)
    if type(display) ~= 'table' or not display.enable then
        return false
    end
    return self:IsListGroupEnabled(display.listGroupID)
end

function core:ListGroupContains(ancestorID, nodeID)
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

function core:CollectListSiblings(parentID, skipID, skipIsGroup)
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
    local db = self:GetDB() or {}
    for id, display in pairs(db) do
        if self:IsDisplayEntry(id, display) and not (skipIsGroup == false and id == skipID) and ParentMatches(parentID, self:DisplayListParent(display)) then
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

function core:WriteListSiblingOrder(nodes)
    for index, node in ipairs(nodes) do
        node.ref.order = index
    end
end

function core:NextListOrder(parentID)
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

function core:CreateListGroup()
    self:EnsureDB()
    local db = self:GetDB()
    db.__groups = db.__groups or {}
    local groupID = EXUI.utils.generateRandomString(10)
    db.__groups[groupID] = {
        name = 'New Group',
        icon = QUESTION_MARK_ICON,
        enable = true,
        createdAt = time(),
        parentID = nil,
        order = self:NextListOrder(nil),
    }
    SaveDB(db)
    return groupID
end

function core:UpdateListGroupValue(groupID, key, value)
    local db = self:GetDB()
    local group = db and db.__groups and db.__groups[groupID]
    if not group then
        return
    end
    group[key] = value
    SaveDB(db)
end

function core:DeleteListGroup(groupID)
    local db = self:GetDB()
    local group = db and db.__groups and db.__groups[groupID]
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
    for id, display in pairs(db) do
        if self:IsDisplayEntry(id, display) and display.listGroupID == groupID then
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
    SaveDB(db)
    self:RefreshAllFrames()
end

function core:Reorder(id, isGroup, parentID, index)
    local db = self:GetDB()
    if not db then
        return
    end
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
        ref = db[id]
        if not self:IsDisplayEntry(id, ref) then
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
    SaveDB(db)
    optionsFields:RefreshItemList()
    self:RefreshAllFrames()
end

function core:GetListGroupOptions(groupID)
    return optionsFields:GetGroupFields({
        get = function(key)
            local group = core:GetListGroup(groupID)
            return group and group[key]
        end,
        set = function(key, value)
            core:UpdateListGroupValue(groupID, key, value)
        end,
        onChange = function(key)
            if key == 'enable' then
                core:RefreshAllFrames()
                preview:Sync()
                optionsFields:RefreshItemList()
            else
                optionsFields:RefreshItemList()
            end
        end,
    })
end

function core:GetListIcon(display)
    local subtitle = display.resourceType or 'Resource'
    return display.icon or QUESTION_MARK_ICON, subtitle
end

function core:DisplayContextMenu()
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

function core:ListGroupContextMenu()
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

function core:GetSplitViewItems()
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
                    label = node.ref.name or node.id,
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

function core:GetSectionTabs(itemId)
    if not itemId or self:GetListGroup(itemId) then
        return {}
    end
    local db = self:GetDB()
    if not self:IsDisplayEntry(itemId, db and db[itemId]) then
        return {}
    end
    return {
        { ID = 'general', label = 'General' },
        { ID = 'display', label = 'Display' },
        { ID = 'load', label = 'Load' },
    }
end

function core:GetOptions(currTabID, currItemID)
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
    if not currItemID then
        return {}
    end
    if self:GetListGroup(currItemID) then
        return self:GetListGroupOptions(currItemID)
    end

    self:EnsureDB()
    local db = self:GetDB()
    if not self:IsDisplayEntry(currItemID, db and db[currItemID]) then
        return {}
    end

    local section = currTabID or 'general'
    if section == 'general' then
        return generalOptions:GetOptions(currItemID)
    elseif section == 'display' then
        return displayOptions:GetOptions(currItemID)
    elseif section == 'load' then
        return loadOptions:GetOptions(currItemID)
    end
    return {}
end

function core:CreateNewDisplay(resourceType)
    self:EnsureDB()
    local display = defaults:BuildNewDisplay(resourceType)
    display.listGroupID = nil
    display.order = self:NextListOrder(nil)
    self:SetDisplayToDB(display)
    return display.ID
end

local previousDuplicateDisplay = core.DuplicateDisplay
function core:DuplicateDisplay(displayID)
    local db = self:GetDB()
    local source = db and db[displayID]
    if not self:IsDisplayEntry(displayID, source) then
        return previousDuplicateDisplay(self, displayID)
    end

    local newID = EXUI.utils.generateRandomString(10)
    local parentID = self:DisplayListParent(source)
    local order = self:NextListOrder(parentID)
    db[newID] = EXUI.utils.deepCloneTable(source)
    db[newID].ID = newID
    db[newID].name = (db[newID].name or 'Display') .. ' (Copy)'
    db[newID].createdAt = time()
    db[newID].XOff = (db[newID].XOff or 0) + 20
    db[newID].YOff = (db[newID].YOff or 0) - 20
    db[newID].listGroupID = parentID
    db[newID].order = order
    SaveDB(db)

    local display = db[newID]
    local frame = self:Create(display.resourceType)
    self.frames[newID] = frame
    frame.displayID = newID
    frame.db = display
    self:RefreshDisplayByID(newID)
    return newID
end

local previousShouldShow = core.ShouldShowDisplay
function core:ShouldShowDisplay(displayID, frame)
    local db = self:GetDB()
    local display = db and db[displayID]
    if type(display) == 'table' and not self:IsListGroupEnabled(display.listGroupID) then
        return false
    end
    return previousShouldShow(self, displayID, frame)
end
