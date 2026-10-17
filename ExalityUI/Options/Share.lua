---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIShare
local share = EXUI:GetModule('share')

local PREFIX = 'EXUISHARE1:'
local EXPORT_COLOR = { 178 / 255, 102 / 255, 255 / 255, 1 }

share.adapters = {}

local function cloneData(value, seen)
    local kind = type(value)
    if kind == 'number' or kind == 'string' or kind == 'boolean' then
        return value
    end
    if kind ~= 'table' then
        return nil
    end
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        local copyKey = cloneData(key, seen)
        local copyChild = cloneData(child, seen)
        if copyKey ~= nil and copyChild ~= nil then
            copy[copyKey] = copyChild
        end
    end
    return copy
end

local function compareNodes(a, b)
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

function share:Register(adapter)
    if adapter and adapter.id then
        self.adapters[adapter.id] = adapter
    end
end

function share:GetAdapter(moduleID)
    return self.adapters[moduleID]
end

function share:Encode(payload)
    local serialized = C_EncodingUtil.SerializeCBOR(payload)
    local compressed = C_EncodingUtil.CompressString(serialized)
    return PREFIX .. C_EncodingUtil.EncodeBase64(compressed)
end

function share:Decode(text)
    text = (text or ''):gsub('%s+', '')
    if text == '' or text:sub(1, #PREFIX) ~= PREFIX then
        return nil
    end
    local body = text:sub(#PREFIX + 1)
    local ok, data = pcall(function()
        local decoded = C_EncodingUtil.DecodeBase64(body)
        local decompressed = C_EncodingUtil.DecompressString(decoded)
        return C_EncodingUtil.DeserializeCBOR(decompressed)
    end)
    if not ok or type(data) ~= 'table' or data.v ~= 1 or type(data.module) ~= 'string' then
        return nil
    end
    if data.kind ~= 'item' and data.kind ~= 'group' then
        return nil
    end
    return data
end

function share:AllocateID(adapter, used)
    used = used or {}
    local length = adapter.idLength or 12
    for _ = 1, 24 do
        local id = EXUI.utils.generateRandomString(length)
        if not used[id] and not adapter.getGroup(id) and not adapter.getItem(id) then
            used[id] = true
            return id
        end
    end
    local id = EXUI.utils.generateRandomString(length + 4)
    used[id] = true
    return id
end

function share:BuildItemPayload(adapter, itemID)
    local live = adapter.getItem(itemID)
    if type(live) ~= 'table' then
        return nil
    end
    local item = cloneData(live, {})
    item[adapter.parentKey] = nil
    return {
        v = 1,
        module = adapter.id,
        kind = 'item',
        item = item,
    }
end

local function groupIsUnder(groupID, rootID, groups)
    local seen = {}
    local current = groupID
    while current do
        if current == rootID then
            return true
        end
        if seen[current] then
            return false
        end
        seen[current] = true
        local group = groups[current]
        if type(group) ~= 'table' then
            return false
        end
        current = group.parentID
    end
    return false
end

function share:BuildGroupPayload(adapter, rootID)
    if type(adapter.getGroup(rootID)) ~= 'table' then
        return nil
    end
    local liveGroups = {}
    adapter.eachGroup(function(id, group)
        if type(id) == 'string' and type(group) == 'table' then
            liveGroups[id] = group
        end
    end)
    if type(liveGroups[rootID]) ~= 'table' then
        return nil
    end

    local groups = {}
    for id, group in pairs(liveGroups) do
        if groupIsUnder(id, rootID, liveGroups) then
            groups[id] = cloneData(group, {})
        end
    end
    groups[rootID].parentID = nil

    local parentKey = adapter.parentKey
    local items = {}
    adapter.eachItem(function(id, item)
        if type(id) == 'string' and type(item) == 'table' then
            local parentID = item[parentKey]
            if type(parentID) == 'string' and groups[parentID] then
                items[id] = cloneData(item, {})
            end
        end
    end)

    return {
        v = 1,
        module = adapter.id,
        kind = 'group',
        rootID = rootID,
        groups = groups,
        items = items,
    }
end

function share:ApplyItem(adapter, source)
    if type(source) ~= 'table' then
        return nil
    end
    local item = cloneData(source, {})
    local id = self:AllocateID(adapter)
    item[adapter.parentKey] = nil
    item.order = adapter.nextOrder(nil)
    if adapter.ownsItemID then
        item.ID = id
    end
    adapter.addItem(id, item)
    return id
end

function share:ApplyGroup(adapter, data)
    local groups = data.groups
    local items = data.items or {}
    local rootID = data.rootID
    if type(groups) ~= 'table' or type(rootID) ~= 'string' or type(groups[rootID]) ~= 'table' then
        return nil
    end
    if type(items) ~= 'table' then
        return nil
    end

    local idMap = {}
    local used = {}
    local function mapID(oldID)
        if not idMap[oldID] then
            idMap[oldID] = self:AllocateID(adapter, used)
        end
        return idMap[oldID]
    end

    for oldID, group in pairs(groups) do
        if type(oldID) == 'string' and type(group) == 'table' then
            mapID(oldID)
        end
    end
    for oldID, item in pairs(items) do
        if type(oldID) == 'string' and type(item) == 'table' then
            mapID(oldID)
        end
    end
    if not idMap[rootID] then
        return nil
    end

    local parentKey = adapter.parentKey
    local function childrenOf(oldParentID)
        local nodes = {}
        for oldID, group in pairs(groups) do
            if type(oldID) == 'string' and type(group) == 'table' and oldID ~= rootID and group.parentID == oldParentID then
                nodes[#nodes + 1] = {
                    kind = 'group',
                    id = oldID,
                    order = group.order,
                    createdAt = group.createdAt,
                    name = group.name,
                }
            end
        end
        for oldID, item in pairs(items) do
            if type(oldID) == 'string' and type(item) == 'table' and item[parentKey] == oldParentID then
                nodes[#nodes + 1] = {
                    kind = 'item',
                    id = oldID,
                    order = item.order,
                    createdAt = item.createdAt,
                    name = item.name,
                }
            end
        end
        table.sort(nodes, compareNodes)
        return nodes
    end

    local function insertGroup(oldID, parentNewID)
        local source = groups[oldID]
        if type(source) ~= 'table' then
            return
        end
        local group = cloneData(source, {})
        local newID = idMap[oldID]
        group.parentID = parentNewID
        group.order = adapter.nextOrder(parentNewID)
        adapter.addGroup(newID, group)
        for _, node in ipairs(childrenOf(oldID)) do
            if node.kind == 'group' then
                insertGroup(node.id, newID)
            else
                local itemSource = items[node.id]
                if type(itemSource) == 'table' then
                    local item = cloneData(itemSource, {})
                    local itemID = idMap[node.id]
                    item[parentKey] = newID
                    item.order = adapter.nextOrder(newID)
                    if adapter.ownsItemID then
                        item.ID = itemID
                    end
                    adapter.addItem(itemID, item)
                end
            end
        end
    end

    insertGroup(rootID, nil)
    return idMap[rootID]
end

function share:Apply(adapter, data)
    if data.kind == 'item' then
        return self:ApplyItem(adapter, data.item)
    end
    if data.kind == 'group' then
        return self:ApplyGroup(adapter, data)
    end
    return nil
end

function share:Export(moduleID, kind, id)
    local adapter = self:GetAdapter(moduleID)
    if not adapter then
        return
    end
    local payload
    if kind == 'group' then
        payload = self:BuildGroupPayload(adapter, id)
    else
        payload = self:BuildItemPayload(adapter, id)
    end
    if not payload then
        EXUI.utils.printOut('Nothing to export.')
        return
    end
    local ok, encoded = pcall(function()
        return self:Encode(payload)
    end)
    if not ok or type(encoded) ~= 'string' or encoded == '' then
        EXUI.utils.printOut('Export failed.')
        return
    end
    self:ShowExport(encoded)
end

function share:OpenImport(moduleID)
    if not self:GetAdapter(moduleID) then
        return
    end
    self.importModule = moduleID
    self:ShowDialog('import')
end

function share:ImportMenu()
    local moduleID = self.importModule
    local adapter = moduleID and self:GetAdapter(moduleID)
    if not adapter or not self.dialog then
        return
    end
    local data = self:Decode(self.dialog:GetText())
    if not data then
        EXUI.utils.printOut('Invalid export string.')
        return
    end
    if data.module ~= moduleID then
        EXUI.utils.printOut('This export is for a different list.')
        return
    end
    local selectID = self:Apply(adapter, data)
    if not selectID then
        EXUI.utils.printOut('Invalid export string.')
        return
    end
    self:HideDialog()
    if adapter.finish then
        adapter.finish(selectID)
    end
end

function share:ExportMenuItem(moduleID, kind)
    return {
        label = 'Export',
        color = EXPORT_COLOR,
        onClick = function(itemID)
            share:Export(moduleID, kind, itemID)
        end,
    }
end

function share:ImportAction(moduleID)
    return {
        icon = 'import',
        align = 'right',
        tooltip = 'Import',
        onClick = function()
            share:OpenImport(moduleID)
        end,
    }
end

local function WrapExport(text, dialog)
    if dialog and dialog.WrapText then
        return dialog:WrapText(text)
    end
    return text or ''
end

function share:EnsureDialog()
    if self.dialog then
        return self.dialog
    end
    self.dialog = EXFrames:GetFrame('text-dialog-frame'):Create()
    return self.dialog
end

function share:ShowDialog(mode, text)
    local dialog = self:EnsureDialog()
    local isExport = mode == 'export'
    local buttons
    if isExport then
        buttons = {
            { text = 'Close', onClick = function() dialog:Close() end },
        }
    else
        buttons = {
            { text = 'Import', onClick = function() self:ImportMenu() end },
            { text = 'Cancel', onClick = function() dialog:Close() end },
        }
    end
    dialog:Open({
        title = isExport and 'Export' or 'Import',
        hint = isExport and 'Press Ctrl+C to copy.' or 'Paste an export string.',
        text = isExport and WrapExport(text, dialog) or (text or ''),
        highlight = isExport,
        buttons = buttons,
        onReady = isExport and function()
            dialog:SetText(WrapExport(text, dialog))
        end or nil,
    })
end

function share:ShowExport(text)
    self:ShowDialog('export', text)
end

function share:HideDialog()
    if self.dialog then
        self.dialog:Close()
    end
end
