---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local profileData = EXUI:GetModule('data')

---@class EXUICDMDefaults
local defaults = EXUI:GetModule('cdm-defaults')

---@class EXUICDMData
local data = EXUI:GetModule('cdm-data')

local DB_KEY = 'cdm'

function data:GetDB()
    local db = profileData:GetDataByKey(DB_KEY)
    if not db.nodes then
        db.nodes = {}
        profileData:SetDataByKey(DB_KEY, db)
    end
    if db.__version ~= defaults.SCHEMA_VERSION then
        local oldVersion = db.__version or 0
        for _, node in pairs(db.nodes) do
            defaults:MergeNode(node)
            -- Range tint and proc glow were briefly merged in switched on; they are opt-in.
            if oldVersion < 9 then
                for _, look in ipairs({ node.iconAppearance, node.barAppearance }) do
                    look.rangeTint = false
                    look.procGlow = false
                end
            end
        end
        db.__version = defaults.SCHEMA_VERSION
    end
    return db
end

function data:GetModuleValue(key)
    return self:GetDB()['__' .. key]
end

function data:SetModuleValue(key, value)
    self:GetDB()['__' .. key] = value
end

function data:GetNodes()
    return self:GetDB().nodes
end

function data:GetNode(id)
    return id and self:GetNodes()[id]
end

function data:IsGroup(id)
    local node = self:GetNode(id)
    return node ~= nil and node.kind == 'group'
end

function data:EachItem(callback)
    for id, node in pairs(self:GetNodes()) do
        if node.kind == 'item' then
            callback(id, node)
        end
    end
end

function data:GetParentID(node)
    local parentID = node and node.parentID
    if parentID and self:IsGroup(parentID) then
        return parentID
    end
    return nil
end

function data:GetParent(node)
    return self:GetNode(self:GetParentID(node))
end

function data:GetRoot(id)
    local seen = {}
    local node = self:GetNode(id)
    while node and not seen[node] do
        seen[node] = true
        local parent = self:GetParent(node)
        if not parent then
            return node
        end
        node = parent
    end
    return node
end

function data:Contains(ancestorID, id)
    local seen = {}
    while id and not seen[id] do
        if id == ancestorID then
            return true
        end
        seen[id] = true
        id = self:GetParentID(self:GetNode(id))
    end
    return false
end

------------------------------------------------------------
-- Scope

function data:GetCharacterKey()
    if self.characterKey then
        return self.characterKey
    end
    local name, suffix = UnitNameUnmodified('player')
    if EXUI.IsForever() then
        self.characterKey = suffix and suffix ~= '' and (name .. ' ' .. suffix) or name
    else
        local realm = GetNormalizedRealmName()
        if not realm then
            return name
        end
        self.characterKey = name .. '-' .. realm
    end
    return self.characterKey
end

function data:BuildScope(mode)
    local _, classFile = UnitClass('player')
    return {
        mode = mode or 'character',
        owner = self:GetCharacterKey(),
        class = classFile,
    }
end

function data:ScopeMatches(scope)
    if not scope or scope.mode == 'all' then
        return true
    end
    if scope.mode == 'class' then
        local _, classFile = UnitClass('player')
        return scope.class == classFile
    end
    return scope.owner == self:GetCharacterKey()
end

function data:IsOwnedHere(id)
    local root = self:GetRoot(id)
    return root ~= nil and self:ScopeMatches(root.scope)
end

function data:GetScope(id)
    local root = self:GetRoot(id)
    return root and root.scope
end

function data:SetScopeMode(id, mode)
    local root = self:GetRoot(id)
    if not root then
        return
    end
    local scope = self:BuildScope(mode)
    if root.scope and mode == 'class' then
        scope.class = root.scope.class or scope.class
    end
    root.scope = scope
end

------------------------------------------------------------
-- Enable state and appearance inheritance

function data:IsEnabled(id)
    local seen = {}
    local node = self:GetNode(id)
    while node and not seen[node] do
        seen[node] = true
        if node.enable == false then
            return false
        end
        node = self:GetParent(node)
    end
    return true
end

function data:InheritsFrom(node, section)
    local parent = self:GetParent(node)
    if not parent or node.kind == 'group' then
        return nil
    end
    if node.override and node.override[section] then
        return nil
    end
    return parent
end

function data:ResolveIcon(node)
    local resolved = {}
    local look = node.iconAppearance
    local inheritLook = self:InheritsFrom(node, 'icon')
    local inheritSize = self:InheritsFrom(node, 'size')
    for key, value in pairs(look) do
        resolved[key] = value
    end
    if inheritLook then
        for key, value in pairs(inheritLook.iconAppearance) do
            if key ~= 'width' and key ~= 'height' then
                resolved[key] = value
            end
        end
    end
    if inheritSize then
        resolved.width = inheritSize.iconAppearance.width
        resolved.height = inheritSize.iconAppearance.height
    end
    return resolved
end

function data:ResolveBar(node)
    local parent = self:InheritsFrom(node, 'bar')
    return parent and parent.barAppearance or node.barAppearance
end

function data:ResolveTexts(node)
    local parent = self:InheritsFrom(node, 'texts')
    return parent and parent.texts or node.texts
end

------------------------------------------------------------
-- Ordering

local function compareOrder(a, b)
    local aOrder = a.node.order or math.huge
    local bOrder = b.node.order or math.huge
    if aOrder ~= bOrder then
        return aOrder < bOrder
    end
    local aTime = a.node.createdAt or 0
    local bTime = b.node.createdAt or 0
    if aTime ~= bTime then
        return aTime < bTime
    end
    return a.id < b.id
end

function data:GetChildren(parentID, skipID)
    local children = {}
    for id, node in pairs(self:GetNodes()) do
        if id ~= skipID and self:GetParentID(node) == parentID then
            children[#children + 1] = { id = id, node = node }
        end
    end
    table.sort(children, compareOrder)
    return children
end

local function writeOrder(children)
    for index, child in ipairs(children) do
        child.node.order = index
    end
end

function data:NextOrder(parentID)
    local children = self:GetChildren(parentID)
    writeOrder(children)
    return #children + 1
end

------------------------------------------------------------
-- CRUD

function data:Create(kind, parentID)
    if parentID and not self:IsGroup(parentID) then
        parentID = nil
    end
    local id = EXUI.utils.generateRandomString(10)
    local node = defaults:BuildNode(kind)
    node.parentID = parentID
    node.order = self:NextOrder(parentID)
    if not parentID then
        node.scope = self:BuildScope('character')
    end
    self:GetNodes()[id] = node
    return id, node
end

function data:Insert(id, node)
    defaults:MergeNode(node)
    self:GetNodes()[id] = node
end

-- Deleting a group deletes everything inside it.
function data:Delete(id)
    local nodes = self:GetNodes()
    if not nodes[id] then
        return
    end
    local children = self:GetChildren(id)
    nodes[id] = nil
    for _, child in ipairs(children) do
        self:Delete(child.id)
    end
end

function data:Duplicate(id)
    local node = self:GetNode(id)
    if not node or node.kind ~= 'item' then
        return nil
    end
    local newID = EXUI.utils.generateRandomString(10)
    local copy = EXUI.utils.deepCloneTable(node)
    copy.name = (copy.name or 'Cooldown') .. ' (Copy)'
    copy.createdAt = time()
    copy.order = self:NextOrder(self:GetParentID(node))
    self:GetNodes()[newID] = copy
    return newID
end

-- Highest line used by a custom-layout group's children.
function data:LastLine(groupID)
    local last = 1
    for _, child in ipairs(self:GetChildren(groupID)) do
        last = math.max(last, child.node.line or 1)
    end
    return last
end

function data:Reorder(id, parentID, index)
    local node = self:GetNode(id)
    if not node then
        return false
    end
    if parentID and not self:IsGroup(parentID) then
        parentID = nil
    end
    if node.kind == 'group' and parentID and self:Contains(id, parentID) then
        return false
    end
    local oldParentID = self:GetParentID(node)
    if not parentID and oldParentID then
        node.scope = EXUI.utils.deepCloneTable(self:GetScope(id))
    end
    if oldParentID ~= parentID then
        node.line = nil
    end
    node.parentID = parentID

    local siblings = self:GetChildren(parentID, id)
    index = math.max(1, math.min(math.floor(tonumber(index) or (#siblings + 1)), #siblings + 1))
    table.insert(siblings, index, { id = id, node = node })
    writeOrder(siblings)
    if oldParentID ~= parentID then
        writeOrder(self:GetChildren(oldParentID))
    end
    return true
end

------------------------------------------------------------
-- Path access: 'iconAppearance.width', 'source.spellID', ...

local function splitPath(path)
    return { strsplit('.', path) }
end

function data:GetValue(id, path)
    local value = self:GetNode(id)
    for _, key in ipairs(splitPath(path)) do
        if type(value) ~= 'table' then
            return nil
        end
        value = value[tonumber(key) or key]
    end
    return value
end

function data:SetValue(id, path, newValue)
    local target = self:GetNode(id)
    if not target then
        return
    end
    local keys = splitPath(path)
    for i = 1, #keys - 1 do
        local key = tonumber(keys[i]) or keys[i]
        if type(target[key]) ~= 'table' then
            target[key] = {}
        end
        target = target[key]
    end
    local last = keys[#keys]
    target[tonumber(last) or last] = newValue
end
