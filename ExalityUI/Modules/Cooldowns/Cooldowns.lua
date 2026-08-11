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

cooldowns.eventHandler = CreateFrame('Frame')
cooldowns.eventHandler:RegisterEvent('PLAYER_ENTERING_WORLD')
cooldowns.eventHandler:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_ENTERING_WORLD' then
        cooldowns:InitFrames()
    end
end)

cooldowns.splitViewExtraButton = {
    text = 'Create New',
    color = { 249 / 255, 95 / 255, 9 / 255, 1 },
    onClick = function()
        local frame = cooldowns:CreateNew()
        cooldowns:UpdateAll()
        optionsFields:Refresh()
        optionsFields:SetItemID(frame.ID)
    end,
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

function cooldowns:GetSplitViewItems()
    local db = self:EnsureDB()
    local items = {}

    for ID, cdDB in EXUI.utils.spairs(db, function(t, a, b)
        local cdA = t[a]
        local cdB = t[b]
        if type(cdA) ~= 'table' or type(cdB) ~= 'table' then
            return tostring(a) < tostring(b)
        end
        return (cdA.createdAt or 0) < (cdB.createdAt or 0)
    end) do
        if self:IsCooldownEntry(ID, cdDB) then
            table.insert(items, {
                label = cdDB.name or ID,
                ID = ID,
                contextMenuItems = {
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
                },
            })
        end
    end

    return items
end

function cooldowns:GetSectionTabs(itemId)
    if not itemId then
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
        return {}
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
    local db = self:GetBaseDB()
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
    db[newID] = EXUI.utils.deepCloneTable(db[cdID])
    db[newID].name = (db[newID].name or 'Cooldown') .. ' (Copy)'
    db[newID].createdAt = time()
    db[newID].ID = newID
    self:SaveBaseDB(db)

    self:Create(newID)
    self:UpdateById(newID)
    return newID
end
