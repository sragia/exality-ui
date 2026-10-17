---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUICooldownDisplay
local cooldownDisplay = EXUI:GetModule('cooldown-display')

---@class EXUICooldownsDefaults
local defaults = EXUI:GetModule('cooldowns-defaults')

---@class EXUICooldownsGeneralOptions
local generalOptions = EXUI:GetModule('cooldowns-general-options')

---@class EXUICooldownsSourceOptions
local sourceOptions = EXUI:GetModule('cooldowns-source-options')

---@class EXUICooldownsDisplayOptions
local displayOptions = EXUI:GetModule('cooldowns-display-options')

---@class EXUICooldownsLoadOptions
local loadOptions = EXUI:GetModule('cooldowns-load-options')

---@class EXUIShare
local share = EXUI:GetModule('share')

---@class EXUICooldownsModule
local cooldowns = EXUI:GetModule('cooldowns')

cooldowns.framePool = CreateFramePool('Frame', UIParent, 'BackdropTemplate')
cooldowns.frames = {}

local EQUIPMENT_SLOTS = {
    1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19,
}
local SLOTNAME_BY_ID = {
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

cooldowns.useTabs = false
cooldowns.useSplitView = true
cooldowns.useInnerTabs = true
cooldowns.splitViewItemStyle = 'advanced'

local QUESTION_MARK_ICON = 134400

local function CooldownSource(cdDB)
    local source = cdDB.cooldownSource
    if source == 'spell' or source == 'item' or source == 'equipment' then
        return source
    end
    return cdDB.isItem and 'item' or 'spell'
end

local function EmptySlotTexture(slotID)
    local token = SLOTNAME_BY_ID[tonumber(slotID)]
    if not token or not GetInventorySlotInfo then
        return nil
    end
    local _, texture = GetInventorySlotInfo(token)
    return texture
end

local function SlotLabel(slotID)
    slotID = tonumber(slotID)
    if slotID == 11 then
        return 'Finger 1'
    end
    if slotID == 12 then
        return 'Finger 2'
    end
    if slotID == 13 then
        return 'Trinket 1'
    end
    if slotID == 14 then
        return 'Trinket 2'
    end
    local token = SLOTNAME_BY_ID[slotID]
    local label = token and _G[token] or nil
    if label and label ~= '' then
        return label
    end
    return slotID and string.format('Slot %d', slotID) or 'Equipment'
end

function cooldowns:GetListIcon(cdDB)
    local source = CooldownSource(cdDB)
    if source == 'spell' then
        local spellID = tonumber(cdDB.spellID)
        if spellID then
            local texture
            if C_Spell and C_Spell.GetSpellTexture then
                texture = C_Spell.GetSpellTexture(spellID)
            elseif GetSpellTexture then
                texture = GetSpellTexture(spellID)
            end
            if texture then
                return texture, 'Spell'
            end
        end
        return QUESTION_MARK_ICON, 'Spell'
    end
    if source == 'item' then
        local itemID = tonumber(cdDB.itemID)
        if itemID and C_Item and C_Item.GetItemInfoInstant then
            local _, _, _, _, texture = C_Item.GetItemInfoInstant(itemID)
            if texture then
                return texture, 'Item'
            end
        end
        return QUESTION_MARK_ICON, 'Item'
    end
    if source == 'equipment' then
        local texture = EmptySlotTexture(cdDB.equipmentSlot or defaults.DISPLAY.equipmentSlot)
        return texture or QUESTION_MARK_ICON, SlotLabel(cdDB.equipmentSlot or defaults.DISPLAY.equipmentSlot)
    end
    return QUESTION_MARK_ICON, 'Spell'
end

cooldowns.eventHandler = CreateFrame('Frame')
cooldowns.eventHandler:RegisterEvent('PLAYER_ENTERING_WORLD')
cooldowns.eventHandler:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_ENTERING_WORLD' then
        cooldowns:InitFrames()
    end
end)

cooldowns.splitViewExtraButton = {
    actions = {
        {
            icon = 'plus',
            text = 'Create',
            onClick = function()
                local frame = cooldowns:CreateNew()
                cooldowns:UpdateAll()
                optionsFields:Refresh()
                optionsFields:SetItemID(frame.ID)
            end,
        },
        share:ImportAction('cooldowns'),
        {
            icon = 'folderPlus',
            align = 'right',
            tooltip = 'Create Group',
            onClick = function()
                local groupID = cooldowns:CreateGroup()
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

function cooldowns:Init()
    self:EnsureDB()
    EXUI:GetModule('cooldowns-spell-index'):Init()
    EXUI:GetModule('cooldowns-item-index'):Init()
    optionsController:RegisterModule(self)
end

function cooldowns:GetName()
    return 'Cooldowns'
end

function cooldowns:GetOrder()
    return 50
end

function cooldowns:GetProfileExportSpec()
    return { id = 'cooldowns', keys = { 'cooldowns' } }
end

function cooldowns:IsCooldownEntry(ID, cdDB)
    if defaults:IsMetadataKey(ID) then
        return false
    end
    return type(cdDB) == 'table'
end

function cooldowns:GetGroups()
    local db = self:EnsureDB()
    return db.__groups or {}
end

function cooldowns:GetGroup(groupID)
    if not groupID then
        return nil
    end
    return self:GetGroups()[groupID]
end

function cooldowns:IsGroupEnabled(groupID)
    local seen = {}
    while groupID do
        if seen[groupID] then
            return true
        end
        seen[groupID] = true
        local group = self:GetGroup(groupID)
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

local function ParentMatches(parentID, nodeParent)
    if not parentID then
        return not nodeParent
    end
    return nodeParent == parentID
end

local function CompareOrder(a, b)
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

function cooldowns:GroupParent(group)
    if not group then
        return nil
    end
    local parentID = group.parentID
    if parentID and self:GetGroup(parentID) then
        return parentID
    end
    return nil
end

function cooldowns:CooldownParent(cdDB)
    if not cdDB then
        return nil
    end
    local groupID = cdDB.groupID
    if groupID and self:GetGroup(groupID) then
        return groupID
    end
    return nil
end

function cooldowns:GroupContains(ancestorID, nodeID)
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
        local group = self:GetGroup(current)
        if not group then
            return false
        end
        current = group.parentID
    end
    return false
end

function cooldowns:CollectSiblings(parentID, skipID, skipIsGroup)
    local nodes = {}
    for groupID, group in pairs(self:GetGroups()) do
        if not (skipIsGroup and groupID == skipID) and ParentMatches(parentID, self:GroupParent(group)) then
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
    for id, entry in pairs(db) do
        if self:IsCooldownEntry(id, entry) and not (skipIsGroup == false and id == skipID) and ParentMatches(parentID, self:CooldownParent(entry)) then
            nodes[#nodes + 1] = {
                ref = entry,
                isGroup = false,
                id = id,
                order = entry.order,
                createdAt = entry.createdAt,
                name = entry.name,
            }
        end
    end
    table.sort(nodes, CompareOrder)
    return nodes
end

function cooldowns:WriteSiblingOrder(nodes)
    for index, node in ipairs(nodes) do
        node.ref.order = index
    end
end

function cooldowns:NextOrder(parentID)
    local nodes = self:CollectSiblings(parentID)
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
        self:WriteSiblingOrder(nodes)
        return #nodes + 1
    end
    return maxOrder + 1
end

function cooldowns:CreateGroup()
    local db = self:EnsureDB()
    db.__groups = db.__groups or {}
    local groupID = EXUI.utils.generateRandomString(10)
    db.__groups[groupID] = {
        name = 'New Group',
        icon = QUESTION_MARK_ICON,
        enable = true,
        createdAt = time(),
        parentID = nil,
        order = self:NextOrder(nil),
    }
    self:SaveBaseDB(db)
    return groupID
end

function cooldowns:UpdateGroupValue(groupID, key, value)
    local db = self:EnsureDB()
    local group = db.__groups and db.__groups[groupID]
    if not group then
        return
    end
    group[key] = value
    self:SaveBaseDB(db)
end

function cooldowns:DeleteGroup(groupID)
    local db = self:EnsureDB()
    local group = db.__groups and db.__groups[groupID]
    if not group then
        return
    end
    local parentID = self:GroupParent(group)
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
    for id, entry in pairs(db) do
        if self:IsCooldownEntry(id, entry) and entry.groupID == groupID then
            moved[#moved + 1] = {
                ref = entry,
                order = entry.order,
                createdAt = entry.createdAt,
                name = entry.name,
                isGroup = false,
            }
        end
    end
    table.sort(moved, CompareOrder)
    local nextOrder = self:NextOrder(parentID)
    for _, node in ipairs(moved) do
        if node.isGroup then
            node.ref.parentID = parentID
        else
            node.ref.groupID = parentID
        end
        node.ref.order = nextOrder
        nextOrder = nextOrder + 1
    end
    db.__groups[groupID] = nil
    self:SaveBaseDB(db)
    self:UpdateAll()
end

function cooldowns:Reorder(id, isGroup, parentID, index)
    local db = self:EnsureDB()
    if parentID and not self:GetGroup(parentID) then
        parentID = nil
    end
    local ref
    local oldParent
    if isGroup then
        ref = db.__groups and db.__groups[id]
        if not ref then
            return
        end
        if id == parentID or self:GroupContains(id, parentID) then
            return
        end
        oldParent = self:GroupParent(ref)
        ref.parentID = parentID
    else
        ref = db[id]
        if not self:IsCooldownEntry(id, ref) then
            return
        end
        oldParent = self:CooldownParent(ref)
        ref.groupID = parentID
    end
    local siblings = self:CollectSiblings(parentID, id, isGroup and true or false)
    index = math.floor(tonumber(index) or (#siblings + 1))
    if index < 1 then
        index = 1
    end
    if index > #siblings + 1 then
        index = #siblings + 1
    end
    table.insert(siblings, index, {
        ref = ref,
        order = ref.order,
        createdAt = ref.createdAt,
        name = ref.name,
    })
    self:WriteSiblingOrder(siblings)
    if not ParentMatches(oldParent, parentID) then
        self:WriteSiblingOrder(self:CollectSiblings(oldParent))
    end
    self:SaveBaseDB(db)
    optionsFields:RefreshItemList()
end

function cooldowns:GetGroupOptions(groupID)
    return optionsFields:GetGroupFields({
        get = function(key)
            local group = cooldowns:GetGroup(groupID)
            return group and group[key]
        end,
        set = function(key, value)
            cooldowns:UpdateGroupValue(groupID, key, value)
        end,
        onChange = function(key)
            if key == 'enable' then
                cooldowns:UpdateAll()
                optionsFields:RefreshItemList()
            else
                optionsFields:RefreshItemList()
            end
        end,
    })
end

function cooldowns:CooldownContextMenu()
    return {
        share:ExportMenuItem('cooldowns', 'item'),
        {
            label = 'Duplicate',
            color = { 2 / 255, 145 / 255, 227 / 255, 1 },
            onClick = function(itemID)
                local newID = self:DuplicateCD(itemID)
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
                self:DeleteById(itemID)
                optionsFields:Refresh()
            end,
        },
    }
end

function cooldowns:GroupContextMenu()
    return {
        share:ExportMenuItem('cooldowns', 'group'),
        {
            label = 'Delete',
            color = EXUI.EXFrames.Theme.danger,
            onClick = function(itemID)
                local selected = optionsFields.currItemID == itemID
                self:DeleteGroup(itemID)
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

function cooldowns:GetSplitViewItems()
    local items = {}
    local seen = {}

    local function emit(parentID, depth)
        if parentID and seen[parentID] then
            return
        end
        if parentID then
            seen[parentID] = true
        end
        for _, node in ipairs(self:CollectSiblings(parentID)) do
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
                        contextMenuItems = self:GroupContextMenu(),
                    }
                    if not self:IsGroupEnabled(node.id) then
                        row.statusIcon = 'inactive'
                    end
                    items[#items + 1] = row
                    emit(node.id, depth + 1)
                end
            else
                local icon, sublabel = self:GetListIcon(node.ref)
                local row = {
                    label = node.ref.name or node.id,
                    sublabel = sublabel,
                    icon = icon,
                    ID = node.id,
                    depth = depth,
                    parentID = parentID,
                    contextMenuItems = self:CooldownContextMenu(),
                }
                if node.ref.enable == false or not self:IsGroupEnabled(node.ref.groupID) then
                    row.statusIcon = 'inactive'
                end
                items[#items + 1] = row
            end
        end
    end

    emit(nil, 0)
    return items
end

function cooldowns:GetSectionTabs(itemId)
    if not itemId or self:GetGroup(itemId) then
        return {}
    end

    return {
        { ID = 'general', label = 'General' },
        { ID = 'source', label = 'Source' },
        { ID = 'display', label = 'Display' },
        { ID = 'load', label = 'Load' },
    }
end

function cooldowns:GetOptions(currTabID, currItemID)
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
    if self:GetGroup(currItemID) then
        return self:GetGroupOptions(currItemID)
    end

    local db = self:GetCDDBByID(currItemID)
    if not db or next(db) == nil then
        return {}
    end

    local section = currTabID or 'general'
    if section == 'general' then
        return generalOptions:GetOptions(currItemID)
    end
    if section == 'source' then
        return sourceOptions:GetOptions(currItemID)
    end
    if section == 'display' then
        return displayOptions:GetOptions(currItemID)
    end
    if section == 'load' then
        return loadOptions:GetOptions(currItemID)
    end

    return {}
end

function cooldowns:GetEquipmentSlotOptions()
    local options = {}
    for _, slotID in ipairs(EQUIPMENT_SLOTS) do
        local slotName = SLOTNAME_BY_ID[slotID]
        local label = slotName and _G[slotName] or nil
        if slotID == 11 then
            label = 'Finger 1'
        elseif slotID == 12 then
            label = 'Finger 2'
        elseif slotID == 13 then
            label = 'Trinket 1'
        elseif slotID == 14 then
            label = 'Trinket 2'
        end
        if not label then
            label = string.format('Slot %d', slotID)
        end
        options[slotID] = label
    end
    return options
end

function cooldowns:CreateFrame()
    local frame = self.framePool:Acquire()
    frame.Destroy = function(selfRef)
        cooldowns.framePool:Release(selfRef)
    end

    EXUI:ApplySolidBorder(frame, 1, { 0, 0, 0, 1 }, { 0, 0, 0, 0.4 }, { register = false })
    EXUI:RegisterSnapFrame(frame)
    return frame
end

function cooldowns:ClearFrame(frame)
    frame:ClearAllPoints()
    frame:UnregisterAllEvents()
    frame:Destroy()
end

function cooldowns:CreateNew()
    local newDisplay = defaults:BuildNewDisplay()
    local db = self:EnsureDB()
    newDisplay.groupID = nil
    newDisplay.order = self:NextOrder(nil)
    db[newDisplay.ID] = newDisplay
    self:SaveBaseDB(db)
    return self:Create(newDisplay.ID)
end

function cooldowns:Create(ID)
    local frame = self.frames[ID]
    if frame then
        return frame
    end

    frame = self:CreateFrame()
    frame.ID = ID
    self.frames[ID] = frame
    cooldownDisplay:Create(frame)
    return frame
end

function cooldowns:UpdateById(ID)
    local frame = self.frames[ID]
    if not frame then
        return
    end

    self:SetDefaults(ID)

    if not self:CheckLoadConditions(ID) then
        frame:Hide()
        frame:UnregisterAllEvents()
        return
    end

    frame:Show()
    frame.db = self:GetCDDBByID(ID)
    cooldownDisplay:Update(frame)

    if not editor:IsFrameRegistered(frame) then
        editor:RegisterFrameForEditor(frame, 'CD: ' .. frame.db.name, function(refFrame)
            local point, _, relativePoint, XOff, YOff = refFrame:GetPoint(1)
            self:UpdateValueForCD(ID, 'anchorPoint', point)
            self:UpdateValueForCD(ID, 'relativePoint', relativePoint)
            self:UpdateValueForCD(ID, 'XOff', XOff)
            self:UpdateValueForCD(ID, 'YOff', YOff)
        end)
    else
        editor:UpdateFrameLabel(frame, 'CD: ' .. frame.db.name)
    end
end

function cooldowns:CheckLoadConditions(ID)
    local db = self:GetCDDBByID(ID)
    if not db or not db.hasLoadConditions then
        return true
    end

    local playerName = UnitName('player')
    local onlyLoadOnPlayer = db.onlyLoadOnPlayer
    if onlyLoadOnPlayer ~= '' then
        local players = { strsplit(',', onlyLoadOnPlayer) }
        if not tContains(players, playerName) then
            return false
        end
    end

    local dontLoadOnPlayer = db.dontLoadOnPlayer
    if dontLoadOnPlayer ~= '' then
        local players = { strsplit(',', dontLoadOnPlayer) }
        if tContains(players, playerName) then
            return false
        end
    end

    return true
end

function cooldowns:UpdateAll()
    for ID in pairs(self.frames) do
        self:UpdateById(ID)
    end
end

function cooldowns:DeleteById(ID)
    local frame = self.frames[ID]
    if frame then
        self:ClearFrame(frame)
        self.frames[ID] = nil
    end
    self:DeleteCDFromDB(ID)
end

function cooldowns:InitFrames()
    local db = self:EnsureDB()
    for ID, entry in pairs(db) do
        if self:IsCooldownEntry(ID, entry) then
            self:Create(ID)
        end
    end
    self:UpdateAll()
end

function cooldowns:GetBaseDB()
    local db = data:GetDataByKey('cooldowns')
    if not db then
        db = {}
        data:SetDataByKey('cooldowns', db)
    end
    return db
end

function cooldowns:SaveBaseDB(db)
    data:SetDataByKey('cooldowns', db)
end

function cooldowns:EnsureDB()
    local db = self:GetBaseDB()
    if db.__exuiDefaultsVersion ~= defaults.SCHEMA_VERSION then
        defaults:MergeIntoDB(db)
        self:SaveBaseDB(db)
    end
    return db
end

function cooldowns:GetCDDBByID(cdID)
    local db = self:EnsureDB()
    return db[cdID]
end

function cooldowns:UpdateValueForCD(cdID, key, value)
    local db = self:EnsureDB()
    db[cdID] = db[cdID] or defaults:CopyTable(defaults.DISPLAY)
    db[cdID][key] = value
    if key == 'cooldownSource' then
        db[cdID].isItem = value == 'item'
    end
    self:SaveBaseDB(db)
end

function cooldowns:GetValueForCD(cdID, key)
    local cdDB = self:GetCDDBByID(cdID)
    return cdDB and cdDB[key]
end

function cooldowns:DeleteCDFromDB(cdID)
    local db = self:EnsureDB()
    db[cdID] = nil
    self:SaveBaseDB(db)
end

function cooldowns:SetDefaults(cdID)
    local db = self:EnsureDB()
    db[cdID] = db[cdID] or {}
    if not db[cdID].createdAt then
        db[cdID].createdAt = time()
    end
    defaults:MergeDisplayDefaults(db[cdID])
    self:SaveBaseDB(db)
end

function cooldowns:DuplicateCD(cdID)
    local db = self:EnsureDB()
    if not db[cdID] then
        return nil
    end

    local newID = EXUI.utils.generateRandomString(10)
    local parentID = self:CooldownParent(db[cdID])
    db[newID] = EXUI.utils.deepCloneTable(db[cdID])
    db[newID].name = (db[newID].name or 'Cooldown') .. ' (Copy)'
    db[newID].createdAt = time()
    db[newID].ID = newID
    db[newID].groupID = parentID
    db[newID].order = self:NextOrder(parentID)
    self:SaveBaseDB(db)

    self:Create(newID)
    self:UpdateById(newID)
    return newID
end

share:Register({
    id = 'cooldowns',
    parentKey = 'groupID',
    idLength = 10,
    ownsItemID = true,
    getGroup = function(id)
        return cooldowns:GetGroup(id)
    end,
    eachGroup = function(callback)
        for id, group in pairs(cooldowns:GetGroups()) do
            callback(id, group)
        end
    end,
    getItem = function(id)
        local entry = cooldowns:GetCDDBByID(id)
        if cooldowns:IsCooldownEntry(id, entry) then
            return entry
        end
        return nil
    end,
    eachItem = function(callback)
        local db = cooldowns:EnsureDB()
        for id, entry in pairs(db) do
            if cooldowns:IsCooldownEntry(id, entry) then
                callback(id, entry)
            end
        end
    end,
    nextOrder = function(parentID)
        return cooldowns:NextOrder(parentID)
    end,
    addGroup = function(id, group)
        local db = cooldowns:EnsureDB()
        db.__groups = db.__groups or {}
        db.__groups[id] = group
        cooldowns:SaveBaseDB(db)
    end,
    addItem = function(id, item)
        local db = cooldowns:EnsureDB()
        db[id] = item
        cooldowns:SaveBaseDB(db)
    end,
    finish = function(selectID)
        cooldowns:InitFrames()
        optionsFields:Refresh()
        optionsFields:SetItemID(selectID)
    end,
})
