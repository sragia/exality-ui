---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUICDMData
local data = EXUI:GetModule('cdm-data')

---@class EXUICDMDefaults
local defaults = EXUI:GetModule('cdm-defaults')

---@class EXUICDMSources
local sources = EXUI:GetModule('cdm-sources')

---@class EXUICDMNodeOptions
local nodeOptions = EXUI:GetModule('cdm-node-options')

---@class EXUICDMModule
local cdm = EXUI:GetModule('cdm')

---@class EXUIShare
local share = EXUI:GetModule('share')

cdm.useTabs = false
cdm.useSplitView = true
cdm.useInnerTabs = true
cdm.splitViewItemStyle = 'advanced'

local SOURCE_LABELS = { spell = 'Spell', item = 'Item' }

local function sourceLabel(source)
    if source.type == 'equipment' then
        return sources:GetSlotLabel(source.slot)
    elseif source.type == 'aura' then
        return source.filter == 'HARMFUL' and 'Debuff' or 'Buff'
    end
    return SOURCE_LABELS[source.type]
end

local function selectedParentID()
    local current = optionsFields.currItemID
    if data:IsGroup(current) then
        return current
    end
    return data:GetParentID(data:GetNode(current))
end


function cdm:CreateNode(kind, parentID)
    local id = data:Create(kind, parentID)
    self:Refresh()
    optionsFields:Refresh()
    optionsFields:SetItemID(id)
    return id
end

cdm.splitViewExtraButton = {
    actions = {
        {
            icon = 'plus',
            text = 'Create',
            onClick = function()
                cdm:CreateNode('item', selectedParentID())
            end,
        },
        share:ImportAction('cdm'),
        {
            icon = 'folderPlus',
            align = 'right',
            tooltip = 'Create Group',
            onClick = function()
                cdm:CreateNode('group', selectedParentID())
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

function cdm:Reorder(id, _, parentID, index)
    if data:Reorder(id, parentID, index) then
        self:Refresh()
    end
    optionsFields:RefreshItemList()
end

local function deleteNode(id)
    data:Delete(id)
    cdm:Refresh()
    -- The selection may have been inside the deleted group.
    if not data:GetNode(optionsFields.currItemID) then
        optionsFields.currItemID = nil
    end
    optionsFields:Refresh()
end

function cdm:ContextMenu(kind)
    local menu = { share:ExportMenuItem('cdm', kind) }
    if kind == 'item' then
        menu[#menu + 1] = {
            label = 'Duplicate',
            color = { 2 / 255, 145 / 255, 227 / 255, 1 },
            onClick = function(id)
                local newID = data:Duplicate(id)
                if newID then
                    cdm:Refresh()
                    optionsFields:Refresh()
                    optionsFields:SetItemID(newID)
                end
            end,
        }
    end
    menu[#menu + 1] = {
        label = 'Delete',
        color = EXUI.EXFrames.Theme.danger,
        onClick = deleteNode,
    }
    return menu
end

local function listIcon(node)
    if node.kind == 'group' then
        return node.icon or defaults.QUESTION_MARK_ICON
    end
    return (sources:GetTexture(node.source))
end

function cdm:GetSplitViewItems()
    local items = {}
    local seen = {}

    local function emit(parentID, depth)
        for _, child in ipairs(data:GetChildren(parentID)) do
            local id, node = child.id, child.node
            if not seen[id] then
                seen[id] = true
                local row = {
                    ID = id,
                    label = node.name or id,
                    icon = listIcon(node),
                    depth = depth,
                    parentID = parentID,
                    contextMenuItems = self:ContextMenu(node.kind),
                }
                if node.kind == 'group' then
                    row.type = 'group'
                    row.selectable = true
                else
                    row.sublabel = sourceLabel(node.source)
                end
                if not data:IsEnabled(id) or not data:IsOwnedHere(id) then
                    row.statusIcon = 'inactive'
                end
                items[#items + 1] = row
                if node.kind == 'group' then
                    emit(id, depth + 1)
                end
            end
        end
    end

    emit(nil, 0)
    return items
end

function cdm:GetSectionTabs(id)
    local node = data:GetNode(id)
    if not node then
        return {}
    end
    if node.kind == 'group' then
        return {
            { ID = 'general', label = 'General' },
            { ID = 'layout', label = 'Layout' },
            { ID = 'appearance', label = 'Appearance' },
            { ID = 'texts', label = 'Texts' },
            { ID = 'visibility', label = 'Visibility' },
            { ID = 'load', label = 'Load' },
        }
    end
    local tabs = {
        { ID = 'general', label = 'General' },
        { ID = 'appearance', label = 'Appearance' },
        { ID = 'texts', label = 'Texts' },
    }
    if node.source.type ~= 'aura' then
        tabs[#tabs + 1] = { ID = 'linked', label = 'Linked Auras' }
    end
    tabs[#tabs + 1] = { ID = 'visibility', label = 'Visibility' }
    tabs[#tabs + 1] = { ID = 'load', label = 'Load' }
    return tabs
end

function cdm:GetOptions(tabID, id)
    if not id then
        return {
            { type = 'description', label = 'Use Create to add a cooldown, or the folder button to add a group.', width = 100 },
        }
    end
    local node = data:GetNode(id)
    if not node then
        return {}
    end
    local tab = tabID or 'general'
    if tab == 'general' then
        if node.kind == 'group' then
            return nodeOptions:GetGroupGeneral(id)
        end
        local fields = nodeOptions:GetItemGeneral(id)
        EXUI.utils.append(fields, nodeOptions:GetPositionFields(id))
        return fields
    elseif tab == 'layout' then
        return nodeOptions:GetLayoutFields(id)
    elseif tab == 'appearance' then
        return nodeOptions:GetAppearanceFields(id)
    elseif tab == 'texts' then
        return nodeOptions:GetTextFields(id)
    elseif tab == 'linked' then
        return nodeOptions:GetLinkedAuraFields(id)
    elseif tab == 'visibility' then
        return nodeOptions:GetVisibilityFields(id)
    elseif tab == 'load' then
        return nodeOptions:GetLoadFields(id)
    end
    return {}
end

local function nodeOfKind(id, kind)
    local node = data:GetNode(id)
    return node and node.kind == kind and node or nil
end

local function eachOfKind(kind, callback)
    for id, node in pairs(data:GetNodes()) do
        if node.kind == kind then
            callback(id, node)
        end
    end
end

-- Imported nodes belong to whoever imports them; scope is only kept on top-level nodes.
local function insertImported(id, node)
    node.scope = not node.parentID and data:BuildScope('character') or nil
    if not node.parentID then
        node.line = nil
    end
    data:Insert(id, node)
end

share:Register({
    id = 'cdm',
    parentKey = 'parentID',
    idLength = 10,
    getGroup = function(id) return nodeOfKind(id, 'group') end,
    getItem = function(id) return nodeOfKind(id, 'item') end,
    eachGroup = function(callback) eachOfKind('group', callback) end,
    eachItem = function(callback) eachOfKind('item', callback) end,
    nextOrder = function(parentID) return data:NextOrder(parentID) end,
    addGroup = insertImported,
    addItem = insertImported,
    convert = function(payload)
        return EXUI:GetModule('cdm-migration'):ConvertSharePayload(payload)
    end,
    finish = function(selectID)
        cdm:Refresh()
        optionsFields:Refresh()
        optionsFields:SetItemID(selectID)
    end,
})
