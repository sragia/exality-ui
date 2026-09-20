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

---@class EXUIDamageMetersDefaults
local defaults = EXUI:GetModule('damage-meters-defaults')

---@class EXUIDamageMetersData
local meterData = EXUI:GetModule('damage-meters-data')

---@class EXUIDamageMetersWindow
local windowMod = EXUI:GetModule('damage-meters-window')

---@class EXUIDamageMetersGeneralOptions
local generalOptions = EXUI:GetModule('damage-meters-general-options')

---@class EXUIDamageMetersStyleOptions
local styleOptions = EXUI:GetModule('damage-meters-style-options')

---@class EXUIDamageMetersTextOptions
local textOptions = EXUI:GetModule('damage-meters-text-options')

---@class EXUIDamageMetersViews
local views = EXUI:GetModule('damage-meters-views')

---@class EXUIDamageMetersModule
local meters = EXUI:GetModule('damage-meters')

meters.framePool = CreateFramePool('Frame', UIParent, 'BackdropTemplate')
meters.frames = {}
meters.enabled = false
meters.editorShowing = false
meters.optionsItemID = nil
meters.testBarsByID = {}
meters.dirtyByID = {}
meters.lastRefreshByID = {}
meters.updateTicker = nil
meters.useTabs = false
meters.useSplitView = true
meters.useInnerTabs = true
meters.encounterActive = false
meters.liveSessionID = nil
meters.committedSessionID = nil
meters.leaveCombatTimer = nil
meters.ignoreNewCombatUntil = 0
meters.holdLiveDisplay = false
meters.displayMode = 'pull'

local COMBAT_GRACE_SECONDS = 8
local MODE_PULL = 'pull'
local MODE_ENCOUNTER = 'encounter'
local MODE_KEY_OVERALL = 'keyOverall'

local function getMeterEvents()
    local events = {
        'PLAYER_REGEN_DISABLED',
        'PLAYER_REGEN_ENABLED',
        'ENCOUNTER_START',
        'ENCOUNTER_END',
        'CHALLENGE_MODE_START',
        'CHALLENGE_MODE_COMPLETED',
        'CHALLENGE_MODE_RESET',
        'PLAYER_DEAD',
        'GROUP_ROSTER_UPDATE',
        'PLAYER_ENTERING_WORLD',
        'ADDON_LOADED',
    }
    if C_DamageMeter then
        table.insert(events, 'DAMAGE_METER_COMBAT_SESSION_UPDATED')
        table.insert(events, 'DAMAGE_METER_CURRENT_SESSION_UPDATED')
        table.insert(events, 'DAMAGE_METER_RESET')
    end
    return events
end

meters.splitViewExtraButton = {
    text = 'Create New',
    color = { 249 / 255, 95 / 255, 9 / 255, 1 },
    onClick = function()
        local frame = meters:CreateNew()
        meters:UpdateAll()
        optionsFields:Refresh()
        optionsFields:SetItemID(frame.ID)
    end,
}

function meters:Init()
    self:EnsureDB()
    self:ClearTransientSessions()
    if defaults:CountWindows(self:GetBaseDB()) == 0 then
        self:CreateNew()
    end
    optionsController:RegisterModule(self)

    if self:GetModuleValue('enable') then
        self:Enable()
    else
        self:Disable()
    end
end

function meters:GetName()
    return 'Damage Meters'
end

function meters:GetOrder()
    return 48
end

function meters:GetIcon()
    return [[Interface/Addons/ExalityUI/Assets/Images/Menu/damage-meters.png]]
end

function meters:GetProfileExportSpec()
    return { id = 'damage-meters', keys = { 'damageMeters' } }
end

function meters:IsWindowEntry(ID, entry)
    if defaults:IsMetadataKey(ID) then
        return false
    end
    return type(entry) == 'table'
end

function meters:GetSplitViewItems()
    local db = self:EnsureDB()
    local items = {}

    for ID, windowDB in EXUI.utils.spairs(db, function(t, a, b)
        local windowA = t[a]
        local windowB = t[b]
        if type(windowA) ~= 'table' or type(windowB) ~= 'table' then
            return tostring(a) < tostring(b)
        end
        return (windowA.createdAt or 0) < (windowB.createdAt or 0)
    end) do
        if self:IsWindowEntry(ID, windowDB) then
            table.insert(items, {
                label = windowDB.name or ID,
                ID = ID,
                contextMenuItems = {
                    {
                        label = 'Duplicate',
                        color = { 2 / 255, 145 / 255, 227 / 255, 1 },
                        onClick = function(itemID)
                            local newID = self:DuplicateWindow(itemID)
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

function meters:GetSectionTabs(itemId)
    if not itemId then
        return {}
    end
    return {
        { ID = 'general', label = 'General' },
        { ID = 'style',   label = 'Style' },
        { ID = 'texts',   label = 'Texts' },
    }
end

function meters:GetOptions(currTabID, currItemID)
    self.optionsItemID = currItemID
    if not currItemID then
        return generalOptions:GetModuleOptions()
    end

    local db = self:GetWindowDB(currItemID)
    if not db then
        return generalOptions:GetModuleOptions()
    end

    if currTabID == 'style' then
        return styleOptions:GetOptions(currItemID)
    end
    if currTabID == 'texts' then
        return textOptions:GetOptions(currItemID)
    end
    return generalOptions:GetOptions(currItemID)
end

function meters:UpdateOptionsChrome()
    self:UpdateAll()
end

function meters:IsShowingTestBars(ID)
    return self.testBarsByID[ID] == true
end

function meters:SetShowTestBars(ID, show)
    self.testBarsByID[ID] = show and true or nil
    self:UpdateById(ID)
end

function meters:TeardownOptionsChrome()
    self.optionsItemID = nil
    wipe(self.testBarsByID)
    self:UpdateAll()
end

function meters:CreateFrame()
    local frame = self.framePool:Acquire()
    frame.Destroy = function(selfRef)
        meters.framePool:Release(selfRef)
    end
    windowMod:Create(frame)
    return frame
end

function meters:CreateNew()
    local db = self:GetBaseDB()
    local window = defaults:BuildNewWindow(db)
    db[window.ID] = window
    self:SaveBaseDB(db)
    return self:Create(window.ID)
end

function meters:Create(ID)
    local frame = self.frames[ID]
    if frame then
        return frame
    end

    frame = self:CreateFrame()
    frame.ID = ID
    self.frames[ID] = frame
    return frame
end

function meters:RegisterEditor(frame)
    if not frame or editor:IsFrameRegistered(frame) then
        return
    end

    editor:RegisterFrameForEditor(frame, 'Meter: ' .. (frame.db and frame.db.name or frame.ID), function(refFrame)
        local point, _, relativePoint, xOfs, yOfs = refFrame:GetPoint(1)
        self:UpdateValue(frame.ID, 'anchorPoint', point)
        self:UpdateValue(frame.ID, 'relativePoint', relativePoint)
        self:UpdateValue(frame.ID, 'XOff', xOfs)
        self:UpdateValue(frame.ID, 'YOff', yOfs)
    end, function()
        self.editorShowing = true
        frame:Show()
        if frame.editor then
            frame.editor:SetEditorAsMovable()
        end
    end, function()
        self.editorShowing = false
        self:UpdateAll()
    end)
end

local function getUpdateInterval(db)
    local value = db and db.updateInterval
    if type(value) ~= 'number' then
        value = defaults.WINDOW.updateInterval or 0.2
    end
    return math.max(0.1, math.min(5, value))
end

function meters:ArePlayersInCombat()
    if UnitAffectingCombat and UnitAffectingCombat('player') then
        return true
    end
    if IsInRaid and IsInRaid() then
        local count = GetNumGroupMembers()
        for i = 1, count do
            if UnitAffectingCombat('raid' .. i) then
                return true
            end
        end
    elseif IsInGroup and IsInGroup() then
        local count = GetNumGroupMembers()
        for i = 1, count - 1 do
            if UnitAffectingCombat('party' .. i) then
                return true
            end
        end
    end
    return false
end

function meters:IsLiveCombat()
    if self.encounterActive then
        return true
    end
    return self:ArePlayersInCombat()
end

function meters:IgnoreNewCombat(seconds)
    local untilTime = GetTime() + (seconds or COMBAT_GRACE_SECONDS)
    if untilTime > (self.ignoreNewCombatUntil or 0) then
        self.ignoreNewCombatUntil = untilTime
    end
end

function meters:IsInCombatGrace()
    return GetTime() < (self.ignoreNewCombatUntil or 0)
end

function meters:IsRealPullSession(session, meterType)
    if meterData:IsSessionEmpty(session) then
        return false
    end
    return not meterData:IsOverallLike(session, meterType or views.Type.DamageDone)
end

function meters:SetDisplayMode(mode)
    self.displayMode = mode or MODE_PULL
end

function meters:IsEncounterMode()
    return self.displayMode == MODE_ENCOUNTER
end

function meters:IsKeyOverallMode()
    return self.displayMode == MODE_KEY_OVERALL
end

function meters:HasLiveCurrentSources()
    local current = meterData:GetSession(views.Session.Current, nil, views.Type.DamageDone)
    return not meterData:IsSessionEmpty(current)
end

function meters:TryLeaveKeyOverall()
    if self.displayMode ~= MODE_KEY_OVERALL then
        return false
    end
    if self:IsInCombatGrace() then
        return false
    end
    if not self:ArePlayersInCombat() then
        return false
    end
    local current = meterData:GetSession(views.Session.Current, nil, views.Type.DamageDone)
    if not self:IsRealPullSession(current, views.Type.DamageDone) then
        return false
    end
    self:SetDisplayMode(MODE_PULL)
    self.holdLiveDisplay = false
    return true
end

function meters:ShouldAdoptLiveCurrent(meterType)
    if self.displayMode == MODE_KEY_OVERALL then
        return self:TryLeaveKeyOverall()
    end
    if self.displayMode == MODE_ENCOUNTER then
        return self:HasLiveCurrentSources()
    end
    if self:IsInCombatGrace() then
        return false
    end
    if not self:IsLiveCombat() then
        self.holdLiveDisplay = false
        return false
    end

    local checkType = views.Type.DamageDone
    local current = meterData:GetSession(views.Session.Current, nil, checkType)
    if not self:IsRealPullSession(current, checkType) then
        return false
    end

    if self.holdLiveDisplay then
        self.holdLiveDisplay = false
    end
    return true
end

function meters:RememberLiveSession(sessionID)
    if not sessionID or sessionID <= 0 then
        return
    end
    local session = meterData:GetSession(nil, sessionID, views.Type.DamageDone)
    if not self:IsRealPullSession(session, views.Type.DamageDone) then
        return
    end
    self.liveSessionID = sessionID
end

function meters:CommitLiveSession()
    if not self.liveSessionID then
        return
    end
    local session = meterData:GetSession(nil, self.liveSessionID, views.Type.DamageDone)
    if not self:IsRealPullSession(session, views.Type.DamageDone) then
        return
    end
    self.committedSessionID = self.liveSessionID
end

function meters:CancelLeaveCombatTimer()
    if self.leaveCombatTimer then
        self.leaveCombatTimer:Cancel()
        self.leaveCombatTimer = nil
    end
end

function meters:ClearSessionTracking()
    self.liveSessionID = nil
    self.committedSessionID = nil
    self.holdLiveDisplay = false
    self.ignoreNewCombatUntil = 0
    self:SetDisplayMode(MODE_PULL)
    self:CancelLeaveCombatTimer()
end

function meters:OnCombatEnded(clearEncounter)
    if clearEncounter then
        self.encounterActive = false
        if self.displayMode == MODE_ENCOUNTER then
            self:SetDisplayMode(MODE_PULL)
        end
    end
    self:CancelLeaveCombatTimer()
    self:IgnoreNewCombat(COMBAT_GRACE_SECONDS)
    self:CommitLiveSession()
    self:UpdateAll()
end

function meters:ScheduleCommitLeaveCombat()
    self:CancelLeaveCombatTimer()
    local delay = (IsInGroup and IsInGroup()) and 1 or 0
    local function finish()
        meters.leaveCombatTimer = nil
        if meters:IsLiveCombat() then
            return
        end
        meters:CommitLiveSession()
        meters:UpdateAll()
    end
    if delay > 0 and C_Timer and C_Timer.NewTimer then
        self.leaveCombatTimer = C_Timer.NewTimer(delay, finish)
        return
    end
    finish()
end

function meters:MarkDirty(ID)
    if ID then
        self.dirtyByID[ID] = true
    end
end

function meters:EnsureUpdateTicker()
    if self.updateTicker or not C_Timer then
        return
    end
    self.updateTicker = C_Timer.NewTicker(0.1, function()
        meters:ProcessPendingUpdates()
    end)
end

function meters:StopUpdateTicker()
    if self.updateTicker then
        self.updateTicker:Cancel()
        self.updateTicker = nil
    end
end

function meters:ProcessPendingUpdates()
    local now = GetTime()
    for ID, frame in pairs(self.frames) do
        if self.dirtyByID[ID] then
            local last = self.lastRefreshByID[ID] or 0
            if (now - last) >= getUpdateInterval(frame.db) then
                self.dirtyByID[ID] = nil
                self.lastRefreshByID[ID] = now
                windowMod:Refresh(frame)
            end
        elseif frame:IsShown() and frame.db and frame.db.showTimer ~= false and not self:IsShowingTestBars(ID) then
            windowMod:UpdateHeader(frame, frame.db, nil, false)
        end
    end
end

function meters:UpdateById(ID)
    local frame = self.frames[ID]
    if not frame then
        frame = self:Create(ID)
    end

    self:SetDefaults(ID)
    frame.db = self:GetWindowDB(ID)
    self.dirtyByID[ID] = nil
    self.lastRefreshByID[ID] = GetTime()
    windowMod:Refresh(frame)

    if frame.db then
        if editor:IsFrameRegistered(frame) then
            editor:UpdateFrameLabel(frame, 'Meter: ' .. (frame.db.name or ID))
        else
            self:RegisterEditor(frame)
        end
    end
end

function meters:UpdateAll()
    for ID in pairs(self.frames) do
        self:UpdateById(ID)
    end
    meterData:UpdateBlizzardVisibility()
end

function meters:ClearFrame(frame)
    if editor:IsFrameRegistered(frame) then
        editor:UnregisterFrameForEditor(frame)
    end
    if frame.editor then
        frame.editor:Hide()
        frame.editor:SetParent(nil)
        frame.editor = nil
    end
    frame:Hide()
    frame:ClearAllPoints()
    frame.db = nil
    frame._posKey = nil
    frame:Destroy()
end

function meters:DeleteById(ID)
    local frame = self.frames[ID]
    if frame then
        self:ClearFrame(frame)
        self.frames[ID] = nil
    end
    local db = self:EnsureDB()
    db[ID] = nil
    self:SaveBaseDB(db)
end

function meters:DuplicateWindow(ID)
    local db = self:EnsureDB()
    if not db[ID] then
        return nil
    end

    local newID = EXUI.utils.generateRandomString(10)
    db[newID] = EXUI.utils.deepCloneTable(db[ID])
    db[newID].name = (db[newID].name or 'Meter') .. ' (Copy)'
    db[newID].createdAt = time()
    db[newID].ID = newID
    db[newID].XOff = (db[newID].XOff or 200) + 40
    db[newID].YOff = (db[newID].YOff or -240) - 40
    self:SaveBaseDB(db)

    self:Create(newID)
    self:UpdateById(newID)
    return newID
end

function meters:InitFrames()
    local db = self:EnsureDB()
    for ID, entry in pairs(db) do
        if self:IsWindowEntry(ID, entry) then
            self:Create(ID)
        end
    end
    self:UpdateAll()
end

function meters:OnEvent(event, ...)
    if event == 'ADDON_LOADED' then
        local addonName = ...
        if addonName == 'Blizzard_DamageMeter' then
            meterData:UpdateBlizzardVisibility()
        end
        return
    end

    if event == 'ENCOUNTER_START' then
        self.encounterActive = true
        self.holdLiveDisplay = false
        self.ignoreNewCombatUntil = 0
        self:SetDisplayMode(MODE_ENCOUNTER)
        self:CancelLeaveCombatTimer()
        self:UpdateAll()
        return
    end

    if event == 'ENCOUNTER_END' then
        self:OnCombatEnded(true)
        return
    end

    if event == 'CHALLENGE_MODE_START' or event == 'CHALLENGE_MODE_RESET' then
        meterData:ResetAllSessions()
        self:ClearSessionTracking()
        self:UpdateAll()
        return
    end

    if event == 'CHALLENGE_MODE_COMPLETED' then
        self.encounterActive = false
        self.holdLiveDisplay = false
        self:CancelLeaveCombatTimer()
        self:IgnoreNewCombat(COMBAT_GRACE_SECONDS)
        self:SetDisplayMode(MODE_KEY_OVERALL)
        self:UpdateAll()
        return
    end

    if event == 'PLAYER_DEAD' then
        if self.displayMode == MODE_ENCOUNTER then
            return
        end
        self:CancelLeaveCombatTimer()
        self:IgnoreNewCombat(COMBAT_GRACE_SECONDS)
        self:CommitLiveSession()
        self:UpdateAll()
        return
    end

    if event == 'PLAYER_REGEN_DISABLED' then
        self:CancelLeaveCombatTimer()
        self:TryLeaveKeyOverall()
        self:UpdateAll()
        return
    end

    if event == 'PLAYER_REGEN_ENABLED' then
        self:ScheduleCommitLeaveCombat()
        return
    end

    if event == 'DAMAGE_METER_RESET' then
        self:ClearSessionTracking()
        self:UpdateAll()
        return
    end

    if event == 'DAMAGE_METER_COMBAT_SESSION_UPDATED' then
        local meterType, sessionID = ...
        if not self:IsInCombatGrace() and self:IsLiveCombat() and sessionID and sessionID > 0 then
            self:RememberLiveSession(sessionID)
        end
        local current = views.Session.Current
        local adoptLive = self:ShouldAdoptLiveCurrent()
        for ID, frame in pairs(self.frames) do
            local db = frame.db
            if db and db.damageMeterType == meterType then
                if meterData:MatchesWindowSession(db, sessionID) then
                    self:MarkDirty(ID)
                elseif db.sessionType == current and adoptLive then
                    self:MarkDirty(ID)
                end
            end
        end
        return
    end

    if event == 'DAMAGE_METER_CURRENT_SESSION_UPDATED' then
        if not self:ShouldAdoptLiveCurrent() then
            return
        end
        local current = views.Session.Current
        for ID, frame in pairs(self.frames) do
            local db = frame.db
            if db and db.sessionType == current then
                self:MarkDirty(ID)
            end
        end
        return
    end

    self:UpdateAll()
end

function meters:Enable()
    if self.enabled then
        self:InitFrames()
        self:EnsureUpdateTicker()
        meterData:UpdateBlizzardVisibility()
        return
    end

    self.enabled = true
    self.registeredEvents = getMeterEvents()
    EXUI:RegisterEventHandler(self.registeredEvents, 'damage-meters', function(event, ...)
        meters:OnEvent(event, ...)
    end)
    self:InitFrames()
    self:EnsureUpdateTicker()
    meterData:UpdateBlizzardVisibility()
end

function meters:Disable()
    self.enabled = false
    self:StopUpdateTicker()
    self:CancelLeaveCombatTimer()
    wipe(self.dirtyByID)
    if self.registeredEvents then
        EXUI:UnregisterEventHandler(self.registeredEvents, 'damage-meters')
        self.registeredEvents = nil
    end
    for _, frame in pairs(self.frames) do
        frame:Hide()
    end
    meterData:UpdateBlizzardVisibility()
end

function meters:ClearTransientSessions()
    local db = self:EnsureDB()
    local current = EXUI:GetModule('damage-meters-views').Session.Current
    local changed = false
    for ID, entry in pairs(db) do
        if self:IsWindowEntry(ID, entry) and entry.sessionID ~= nil then
            entry.sessionType = current
            entry.sessionID = nil
            changed = true
        end
    end
    if changed then
        self:SaveBaseDB(db)
    end
end

function meters:GetBaseDB()
    local db = data:GetDataByKey('damageMeters')
    if not db then
        db = {}
        data:SetDataByKey('damageMeters', db)
    end
    return db
end

function meters:SaveBaseDB(db)
    data:SetDataByKey('damageMeters', db)
end

function meters:EnsureDB()
    local db = self:GetBaseDB()
    if db.__exuiDefaultsVersion ~= defaults.SCHEMA_VERSION then
        defaults:MergeIntoDB(db)
        self:SaveBaseDB(db)
    else
        defaults:MergeModuleDefaults(db)
        for key, entry in pairs(db) do
            if self:IsWindowEntry(key, entry) then
                defaults:MergeWindowDefaults(entry)
            end
        end
    end
    return db
end

function meters:GetWindowDB(ID)
    local db = self:EnsureDB()
    return db[ID]
end

function meters:UpdateValue(ID, key, value)
    local db = self:EnsureDB()
    db[ID] = db[ID] or defaults:CopyTable(defaults.WINDOW)
    db[ID][key] = value
    self:SaveBaseDB(db)
end

function meters:SetWindowSession(ID, sessionType, sessionID)
    local db = self:EnsureDB()
    db[ID] = db[ID] or defaults:CopyTable(defaults.WINDOW)
    db[ID].sessionType = sessionType
    db[ID].sessionID = sessionID
    self:SaveBaseDB(db)
    local frame = self.frames[ID]
    if frame then
        frame.db = db[ID]
    end
end

function meters:GetValue(ID, key)
    local windowDB = self:GetWindowDB(ID)
    return windowDB and windowDB[key]
end

function meters:GetTextValue(ID, textKey, field)
    local texts = self:GetValue(ID, 'texts')
    local entry = texts and texts[textKey]
    if type(entry) == 'table' and entry[field] ~= nil then
        return entry[field]
    end
    local fallback = defaults.WINDOW.texts[textKey]
    return fallback and fallback[field]
end

function meters:UpdateTextValue(ID, textKey, field, value)
    local db = self:EnsureDB()
    db[ID] = db[ID] or defaults:CopyTable(defaults.WINDOW)
    db[ID].texts = db[ID].texts or defaults:CopyTable(defaults.WINDOW.texts)
    db[ID].texts[textKey] = db[ID].texts[textKey] or defaults:CopyTable(defaults.WINDOW.texts[textKey])
    db[ID].texts[textKey][field] = value
    self:SaveBaseDB(db)
end

function meters:GetIconValue(ID, field)
    local icon = self:GetValue(ID, 'icon')
    if type(icon) == 'table' and icon[field] ~= nil then
        return icon[field]
    end
    return defaults.WINDOW.icon[field]
end

function meters:UpdateIconValue(ID, field, value)
    local db = self:EnsureDB()
    db[ID] = db[ID] or defaults:CopyTable(defaults.WINDOW)
    db[ID].icon = db[ID].icon or defaults:CopyTable(defaults.WINDOW.icon)
    db[ID].icon[field] = value
    self:SaveBaseDB(db)
end

function meters:SetDefaults(ID)
    local db = self:EnsureDB()
    db[ID] = db[ID] or {}
    if not db[ID].createdAt then
        db[ID].createdAt = time()
    end
    defaults:MergeWindowDefaults(db[ID])
    self:SaveBaseDB(db)
end

function meters:GetModuleValue(key)
    local db = self:EnsureDB()
    return db['__' .. key]
end

function meters:SetModuleValue(key, value)
    local db = self:EnsureDB()
    db['__' .. key] = value
    self:SaveBaseDB(db)
end

function meters:GetFavoriteViews()
    local favorites = self:GetModuleValue('favoriteViews')
    if type(favorites) ~= 'table' then
        favorites = {}
        self:SetModuleValue('favoriteViews', favorites)
    end
    return favorites
end

function meters:ToggleFavorite(meterType)
    local favorites = self:GetFavoriteViews()
    if favorites[meterType] then
        favorites[meterType] = nil
    else
        favorites[meterType] = true
    end
    self:SetModuleValue('favoriteViews', favorites)
end
