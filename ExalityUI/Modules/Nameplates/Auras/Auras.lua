---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUINameplatesAurasDefaults
local defaults = EXUI:GetModule('np-auras-defaults')

---@class EXUIAuraDisplaysDefaults
local adDefaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUIAuraDisplaysLoadConditions
local loadConditions = EXUI:GetModule('aura-displays-load-conditions')

---@class EXUINameplatesAuras
local npAuras = EXUI:GetModule('np-auras')

local MIN_SUPPORTED_BUILD = 120100

npAuras.currGroupID = nil
npAuras.skipScreenPosition = true

function npAuras:IsSupported()
    return select(4, GetBuildInfo()) >= MIN_SUPPORTED_BUILD
end

function npAuras:Init()
    if not self:IsSupported() then
        return
    end
    self:EnsureDB()
    EXUI:GetModule('np-auras-preview'):Init()
end

function npAuras:GetDB()
    local np = data:GetDataByKey('nameplates')
    if not np then
        np = {}
        data:SetDataByKey('nameplates', np)
    end
    if not np.auraDisplays then
        np.auraDisplays = { displays = {}, __exuiDefaultsVersion = defaults.SCHEMA_VERSION }
        data:SetDataByKey('nameplates', np)
    end
    return np.auraDisplays
end

function npAuras:SaveDB(db)
    local np = data:GetDataByKey('nameplates') or {}
    np.auraDisplays = db
    data:SetDataByKey('nameplates', np)
end

function npAuras:EnsureDB()
    local db = self:GetDB()
    local dirty = false
    if db.__exuiDefaultsVersion ~= defaults.SCHEMA_VERSION then
        defaults:MergeIntoDB(db)
        dirty = true
    end
    if defaults:SeedStarterDisplays(db) then
        defaults:MergeIntoDB(db)
        dirty = true
    end
    if dirty then
        self:SaveDB(db)
    end
    return db
end

function npAuras:GetDisplay(displayID)
    local db = self:EnsureDB()
    return db.displays and db.displays[displayID]
end

function npAuras:UpdateDisplay(displayID, display)
    local db = self:EnsureDB()
    db.displays[displayID] = display
    self:SaveDB(db)
end

function npAuras:GetDisplayValue(displayID, key)
    local display = self:GetDisplay(displayID)
    return display and display[key]
end

function npAuras:UpdateDisplayValue(displayID, key, value)
    local display = self:GetDisplay(displayID)
    if not display then return end
    display[key] = value
    self:UpdateDisplay(displayID, display)
end

function npAuras:GetContainerValue(displayID, key)
    local display = self:GetDisplay(displayID)
    return display and display.container and display.container[key]
end

function npAuras:UpdateContainerValue(displayID, key, value)
    local display = self:GetDisplay(displayID)
    if not display then return end
    display.container = display.container or defaults:CopyTable(adDefaults.CONTAINER)
    display.container[key] = value
    self:UpdateDisplay(displayID, display)
end

function npAuras:GetGroup(displayID, groupID)
    local display = self:GetDisplay(displayID)
    return display and display.groups and display.groups[groupID]
end

function npAuras:GetGroupVisual(displayID, groupID, key)
    local group = self:GetGroup(displayID, groupID)
    return group and group.visual and group.visual[key]
end

function npAuras:UpdateGroupVisual(displayID, groupID, key, value)
    local group = self:GetGroup(displayID, groupID)
    if not group then return end
    group.visual = group.visual or defaults:CopyTable(adDefaults.GROUP_VISUAL)
    group.visual[key] = value
    self:UpdateDisplay(displayID, self:GetDisplay(displayID))
end

function npAuras:GetGroupConditions(displayID, groupID, key)
    local group = self:GetGroup(displayID, groupID)
    return group and group.conditions and group.conditions[key]
end

function npAuras:UpdateGroupConditions(displayID, groupID, key, value)
    local group = self:GetGroup(displayID, groupID)
    if not group then return end
    group.conditions = group.conditions or defaults:CopyTable(adDefaults.GROUP_CONDITIONS)
    group.conditions[key] = value
    self:UpdateDisplay(displayID, self:GetDisplay(displayID))
end

function npAuras:GetGroupLoad(displayID, groupID, key)
    local group = self:GetGroup(displayID, groupID)
    return group and group.load and group.load[key]
end

function npAuras:UpdateGroupLoad(displayID, groupID, key, value)
    local group = self:GetGroup(displayID, groupID)
    if not group then return end
    group.load = group.load or defaults:CopyTable(adDefaults.GROUP_LOAD)
    group.load[key] = value
    self:UpdateDisplay(displayID, self:GetDisplay(displayID))
end

function npAuras:CreateNewDisplay()
    local db = self:EnsureDB()
    local displayID, display = defaults:BuildNewDisplay()
    db.displays[displayID] = display
    self:SaveDB(db)
    self.currGroupID = display.groupOrder[1]
    return displayID
end

function npAuras:DeleteDisplay(displayID)
    local db = self:EnsureDB()
    db.displays[displayID] = nil
    self:SaveDB(db)
    self.currGroupID = nil
    EXUI:GetModule('np-auras-apply'):RefreshAll()
end

function npAuras:DuplicateDisplay(displayID)
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

function npAuras:AddGroup(displayID)
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

function npAuras:RemoveGroup(displayID, groupID)
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

function npAuras:DuplicateGroup(displayID, groupID)
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

function npAuras:DisplayHasLoadableGroup(display)
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

function npAuras:GetDisplays()
    local db = self:EnsureDB()
    return db.displays or {}
end

function npAuras:GetOrderedDisplays()
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

function npAuras:GetSplitViewItems()
    local active = {}
    local inactive = {}

    for _, entry in ipairs(self:GetOrderedDisplays()) do
        local displayID = entry.ID
        local display = entry.display
        local item = {
            ID = displayID,
            label = display.name or 'Aura Display',
            contextMenuItems = {
                {
                    label = 'Duplicate',
                    onClick = function(id)
                        local newID = self:DuplicateDisplay(id)
                        self:RefreshDisplay(newID)
                        local editor = EXUI:GetModule('np-aura-editor')
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
                        local editor = EXUI:GetModule('np-aura-editor')
                        if editor and editor.Refresh then
                            editor:Refresh()
                        end
                    end,
                },
            },
        }
        if display.enable ~= false and self:DisplayHasLoadableGroup(display) then
            table.insert(active, item)
        else
            table.insert(inactive, item)
        end
    end

    local theme = EXUI.const.theme
    local success = theme.success
    local danger = theme.danger
    local items = {
        {
            type = 'category',
            label = 'Active',
            bgColor = { success[1], success[2], success[3], 0.28 },
            textColor = { success[1], success[2], success[3], 1 },
        },
    }
    for _, item in ipairs(active) do
        table.insert(items, item)
    end
    table.insert(items, {
        type = 'category',
        label = 'Inactive',
        spacingAbove = 10,
        bgColor = { danger[1], danger[2], danger[3], 0.28 },
        textColor = { danger[1], danger[2], danger[3], 1 },
    })
    for _, item in ipairs(inactive) do
        table.insert(items, item)
    end
    return items
end

function npAuras:RefreshDisplay(displayID)
    EXUI:GetModule('np-auras-apply'):RefreshDisplay(displayID)
    local aurasPreview = EXUI:GetModule('np-auras-preview')
    if aurasPreview and aurasPreview.OnDisplayChanged then
        aurasPreview:OnDisplayChanged(displayID)
    end
end

function npAuras:RefreshAll()
    EXUI:GetModule('np-auras-apply'):RefreshAll()
    local aurasPreview = EXUI:GetModule('np-auras-preview')
    if aurasPreview and aurasPreview.Sync then
        aurasPreview:Sync()
    end
end

function npAuras:RefreshEditorList()
    local editor = EXUI:GetModule('np-aura-editor')
    if editor and editor.window and editor.window:IsShown() and editor.RefreshItemList then
        editor:RefreshItemList()
    end
end
