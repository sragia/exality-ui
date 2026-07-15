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
    if db.__exuiDefaultsVersion ~= defaults.SCHEMA_VERSION then
        defaults:MergeIntoDB(db)
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
        if group and group.conditions and group.conditions.enable and loadConditions:ShouldLoad(group.load) then
            return true
        end
    end
    return false
end

function ufAuras:IsDisplayActiveForUnit(displayID, unitType)
    local display = self:GetDisplay(displayID)
    if not display then
        return false
    end
    if display.enable == false then
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

function ufAuras:GetSplitViewItems(contextUnit)
    contextUnit = contextUnit or self.contextUnit
    local active = {}
    local inactive = {}

    for _, entry in ipairs(self:GetOrderedDisplays()) do
        local displayID = entry.ID
        local display = entry.display
        local item = {
            ID = displayID,
            label = display.name or 'Aura Display',
            sublabel = defaults:FormatUnitsSubtitle(display.units),
            contextMenuItems = {
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
            },
        }
        if self:IsDisplayActiveForUnit(displayID, contextUnit) then
            table.insert(active, item)
        else
            table.insert(inactive, item)
        end
    end

    local items = {}
    table.insert(items, { type = 'category', label = 'Active' })
    if #active == 0 then
        -- keep category visible even when empty
    else
        for _, item in ipairs(active) do
            table.insert(items, item)
        end
    end
    table.insert(items, { type = 'category', label = 'Inactive' })
    for _, item in ipairs(inactive) do
        table.insert(items, item)
    end
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

    -- ForceShow remaps frame.unit to 'player'; prefer the real unit token.
    local unit = (frame.isFake and frame.originalUnit) or frame.unit or frame.originalUnit
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
