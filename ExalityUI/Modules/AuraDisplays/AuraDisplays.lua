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
auraDisplays.currGroupID = nil

auraDisplays.splitViewExtraButton = {
    text = 'Create Display',
    color = { 249 / 255, 95 / 255, 9 / 255, 1 },
    onClick = function()
        local displayID = auraDisplays:CreateNewDisplay()
        auraDisplays:RefreshAll()
        optionsFields:Refresh()
        optionsFields:SetItemID(displayID)
    end,
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
    if db.__exuiDefaultsVersion ~= defaults.SCHEMA_VERSION then
        defaults:MergeIntoDB(db)
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
    local display = EXUI.utils.deepCloneTable(source)
    display.name = (display.name or 'Aura Display') .. ' Copy'
    display.createdAt = time()

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

function auraDisplays:GetSplitViewItems()
    local db = self:EnsureDB()
    local items = {}
    for displayID, display in EXUI.utils.spairs(db.displays or {}, function(t, a, b)
        return (t[a].createdAt or 0) < (t[b].createdAt or 0)
    end) do
        table.insert(items, {
            ID = displayID,
            label = display.name or 'Aura Display',
            contextMenuItems = {
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
            },
        })
    end
    return items
end

function auraDisplays:GetSectionTabs(itemId)
    if not itemId then return {} end
    groupNav:EnsureGroupSelected(itemId)
    return {
        { ID = 'container', label = 'Container' },
        { ID = 'visual', label = 'Visual' },
        { ID = 'conditions', label = 'Conditions' },
        { ID = 'load', label = 'Load' },
    }
end

function auraDisplays:GetOptions(currTabID, currItemID)
    if not currItemID then return {} end
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
        if not display or not display.enable then
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
