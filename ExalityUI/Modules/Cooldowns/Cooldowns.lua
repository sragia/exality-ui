---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUICooldownDisplay
local cooldownDisplay = EXUI:GetModule('cooldown-display')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUICooldownsModule
local cooldowns = EXUI:GetModule('cooldowns')

cooldowns.framePool = CreateFramePool('Frame', UIParent, 'BackdropTemplate')
cooldowns.frames = {}

cooldowns.eventHandler = CreateFrame('Frame')
cooldowns.eventHandler:RegisterEvent('PLAYER_ENTERING_WORLD')
cooldowns.eventHandler:SetScript('OnEvent', function(self, event, ...)
    if (event == 'PLAYER_ENTERING_WORLD') then
        cooldowns:InitFrames()
    end
end)

cooldowns.DEFAULTS = {
    enable = true,
    name = 'New Cooldown',
    showStacks = false,
    isItem = false,
    spellID = '',
    itemID = '',
    -- Size
    width = 80,
    height = 80,
    zoom = 0,
    -- Border
    borderColor = { r = 0, g = 0, b = 0, a = 1 },
    -- Position
    anchorPoint = 'CENTER',
    relativePoint = 'CENTER',
    XOff = 0,
    YOff = 0,
    frameStrata = 'LOW',
    frameLevel = 10,
    -- CD Text
    font = 'DMSans',
    fontSize = 12,
    fontFlag = 'OUTLINE',
    fontAnchorPoint = 'CENTER',
    fontRelativePoint = 'CENTER',
    fontXOff = 0,
    fontYOff = 0,
    -- Charge Text
    chargeFont = 'DMSans',
    chargeFontSize = 12,
    chargeFontFlag = 'OUTLINE',
    chargeFontAnchorPoint = 'CENTER',
    chargeFontRelativePoint = 'CENTER',
    chargeFontXOff = 0,
    chargeFontYOff = 0,
}


----------------------------
--------- Options ----------
----------------------------

cooldowns.useTabs = false
cooldowns.useSplitView = true
cooldowns.splitViewExtraButton = {
    text = 'Create New Cooldown',
    color = { 249 / 255, 95 / 255, 9 / 255, 1 },
    onClick = function()
        local frame = cooldowns:CreateNew()
        cooldowns:UpdateAll()
        optionsFields:Refresh()
        optionsFields:SetItemID(frame.ID)
    end
}

cooldowns.Init = function(self)
    optionsController:RegisterModule(self)
end

cooldowns.GetName = function(self)
    return 'Cooldowns'
end

cooldowns.GetOrder = function(self)
    return 40
end

cooldowns.GetSplitViewItems = function(self)
    local items = {}
    local db = cooldowns:GetBaseDB()

    for ID, cdDB in pairs(db) do
        table.insert(items, {
            label = cdDB.name,
            ID = ID
        })
    end

    return items
end

cooldowns.GetOptions = function(self, currTabID, currItemID)
    if (not currItemID) then
        return {}
    end

    local db = self:GetCDDBByID(currItemID)
    if (not db) then
        return {}
    end

    return {
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            onObserve = function(value)
                self:UpdateValueForCD(currItemID, 'enable', value)
                self:UpdateById(currItemID)
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'enable')
            end,
            width = 100
        },
        {
            type = 'edit-box',
            label = 'Name',
            name = 'name',
            currentValue = function()
                return self:GetValueForCD(currItemID, 'name')
            end,
            onChange = function(_, value)
                self:UpdateValueForCD(currItemID, 'name', value)
                self:UpdateById(currItemID)
                optionsFields:RefreshItemList()
            end,
            width = 50
        },
        {
            type = 'spacer',
            width = 50
        },
        {
            type = 'dropdown',
            label = 'Cooldown Type',
            name = 'cooldownType',
            getOptions = function()
                return {
                    ['item'] = 'Item',
                    ['spell'] = 'Spell',
                }
            end,
            currentValue = function()
                local isItem = self:GetValueForCD(currItemID, 'isItem')
                return isItem and 'item' or 'spell'
            end,
            onChange = function(value)
                if (value == 'item') then
                    self:UpdateValueForCD(currItemID, 'isItem', true)
                else
                    self:UpdateValueForCD(currItemID, 'isItem', false)
                end
                self:UpdateById(currItemID)
                optionsFields:RefreshOptions()
            end,
            width = 50,
        },
        {
            type = 'toggle',
            label = 'Show Stacks',
            name = 'showStacks',
            onObserve = function(value)
                self:UpdateValueForCD(currItemID, 'showStacks', value)
                self:UpdateById(currItemID)
                optionsFields:RefreshOptions()
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'showStacks')
            end,
            width = 100,
        },
        {
            type = 'edit-box',
            label = 'Item ID',
            name = 'itemID',
            depends = function()
                return self:GetValueForCD(currItemID, 'isItem')
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'itemID')
            end,
            onChange = function(_, value)
                self:UpdateValueForCD(currItemID, 'itemID', value)
                self:UpdateById(currItemID)
            end,
            width = 50
        },
        {
            type = 'edit-box',
            label = 'Spell ID',
            name = 'spellID',
            depends = function()
                return not self:GetValueForCD(currItemID, 'isItem')
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'spellID')
            end,
            onChange = function(_, value)
                self:UpdateValueForCD(currItemID, 'spellID', value)
                self:UpdateById(currItemID)
            end,
            width = 50
        },
        {
            type = 'title',
            label = 'Size & Position',
            width = 100,
            size = 14
        },
        {
            type = 'range',
            label = 'Width',
            name = 'width',
            min = 1,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'width')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'width', value)
                self:UpdateById(currItemID)
            end
        },
        {
            type = 'range',
            label = 'Height',
            name = 'height',
            min = 1,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'height')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'height', value)
                self:UpdateById(currItemID)
            end
        },
        {
            type = 'spacer',
            width = 60
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = 'anchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'anchorPoint')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'anchorPoint', value)
                self:UpdateById(currItemID)
            end,
            width = 22
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'relativePoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'relativePoint')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'relativePoint', value)
                self:UpdateById(currItemID)
            end,
            width = 22
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'XOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'XOff')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'XOff', value)
                self:UpdateById(currItemID)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'YOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'YOff')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'YOff', value)
                self:UpdateById(currItemID)
            end,
            width = 20
        },
        {
            type = 'spacer',
            width = 16
        },
        {
            type = 'dropdown',
            label = 'Frame Strata',
            name = 'frameStrata',
            getOptions = function()
                return EXUI.const.frameStrata
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'frameStrata')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'frameStrata', value)
                self:UpdateById(currItemID)
            end,
            width = 22
        },
        {
            type = 'range',
            label = 'Frame Level',
            name = 'frameLevel',
            min = 0,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'frameLevel')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'frameLevel', value)
                self:UpdateById(currItemID)
            end
        },
        {
            type = 'title',
            label = 'Style',
            size = 14,
            width = 100
        },
        {
            type = 'range',
            label = 'Zoom',
            name = 'zoom',
            min = 0,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'zoom')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'zoom', value)
                self:UpdateById(currItemID)
            end
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = 'borderColor',
            currentValue = function()
                return self:GetValueForCD(currItemID, 'borderColor')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'borderColor', value)
                self:UpdateById(currItemID)
            end,
            width = 80
        },
        {
            type = 'dropdown',
            label = 'CD Font',
            name = 'font',
            getOptions = function()
                local fonts = LSM:List('font')
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'font')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'font', value)
                self:UpdateById(currItemID)
            end,
            width = 23
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'fontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'fontFlag')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'fontFlag', value)
                self:UpdateById(currItemID)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'Size',
            name = 'fontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 20,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'fontSize')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'fontSize', value)
                self:UpdateById(currItemID)
            end
        },
        {
            type = 'spacer',
            width = 34
        },
        {
            type = 'dropdown',
            label = 'CD Anchor Point',
            name = 'fontAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'fontAnchorPoint')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'fontAnchorPoint', value)
                self:UpdateById(currItemID)
            end,
            width = 23
        },
        {
            type = 'dropdown',
            label = 'CR Relative Anchor Point',
            name = 'fontRelativePoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'fontRelativePoint')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'fontRelativePoint', value)
                self:UpdateById(currItemID)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'fontXOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'fontXOff')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'fontXOff', value)
                self:UpdateById(currItemID)
            end
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'fontYOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 20,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'fontYOff')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'fontYOff', value)
                self:UpdateById(currItemID)
            end
        },

        --------------- Stack Text ---------------
        {
            type = 'title',
            label = 'Stacks Text',
            width = 100,
            size = 14,
            depends = function()
                return self:GetValueForCD(currItemID, 'showStacks')
            end
        },
        {
            type = 'dropdown',
            label = 'Stacks Font',
            name = 'chargeFont',
            depends = function()
                return self:GetValueForCD(currItemID, 'showStacks')
            end,
            getOptions = function()
                local fonts = LSM:List('font')
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'chargeFont')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'chargeFont', value)
                self:UpdateById(currItemID)
            end,
            width = 23
        },
        {
            type = 'dropdown',
            label = 'Stacks Font Flag',
            name = 'chargeFontFlag',
            depends = function()
                return self:GetValueForCD(currItemID, 'showStacks')
            end,
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'chargeFontFlag')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'chargeFontFlag', value)
                self:UpdateById(currItemID)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'Stacks Font Size',
            name = 'chargeFontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 20,
            depends = function()
                return self:GetValueForCD(currItemID, 'showStacks')
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'chargeFontSize')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'chargeFontSize', value)
                self:UpdateById(currItemID)
            end
        },
        {
            type = 'spacer',
            width = 34,
            depends = function()
                return self:GetValueForCD(currItemID, 'showStacks')
            end
        },
        {
            type = 'dropdown',
            label = 'Stacks Anchor Point',
            name = 'chargeFontAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return self:GetValueForCD(currItemID, 'showStacks')
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'chargeFontAnchorPoint')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'chargeFontAnchorPoint', value)
                self:UpdateById(currItemID)
            end,
            width = 23
        },
        {
            type = 'dropdown',
            label = 'Stacks Relative Anchor Point',
            name = 'chargeFontRelativePoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            depends = function()
                return self:GetValueForCD(currItemID, 'showStacks')
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'chargeFontRelativePoint')
            end,
            onChange = function(value)
                self:UpdateValueForCD(currItemID, 'chargeFontRelativePoint', value)
                self:UpdateById(currItemID)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'Stacks X Offset',
            name = 'chargeFontXOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 20,
            depends = function()
                return self:GetValueForCD(currItemID, 'showStacks')
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'chargeFontXOff')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'chargeFontXOff', value)
                self:UpdateById(currItemID)
            end
        },
        {
            type = 'range',
            label = 'Stacks Y Offset',
            name = 'chargeFontYOff',
            min = -1000,
            max = 1000,
            step = 1,
            width = 20,
            depends = function()
                return self:GetValueForCD(currItemID, 'showStacks')
            end,
            currentValue = function()
                return self:GetValueForCD(currItemID, 'chargeFontYOff')
            end,
            onChange = function(f, value)
                self:UpdateValueForCD(currItemID, 'chargeFontYOff', value)
                self:UpdateById(currItemID)
            end
        },
        {
            type = 'title',
            label = 'Actions',
            size = 14,
            width = 100
        },
        {
            type = 'button',
            label = 'Duplicate',
            onClick = function()
                local newID = self:DuplicateCD(currItemID)
                optionsFields:Refresh()
                optionsFields:SetItemID(newID)
            end,
            width = 16,
            color = { 2 / 255, 145 / 255, 227 / 255, 1 }
        },
        {
            type = 'button',
            label = 'Delete',
            onClick = function()
                self:DeleteById(currItemID)
                optionsFields:Refresh()
            end,
            width = 16,
            color = { 171 / 255, 0, 20 / 255, 1 }
        }
    }
end



----------------------------
------ Display Control -----
----------------------------

cooldowns.CreateFrame = function(self)
    local frame = self.framePool:Acquire()
    frame.Destroy = function(self)
        cooldowns.framePool:Release(self)
    end

    frame:SetBackdrop(EXUI.const.backdrop.DEFAULT)
    frame:SetBackdropColor(0, 0, 0, 0.4)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    return frame
end

cooldowns.ClearFrame = function(self, frame)
    frame:ClearAllPoints()
    frame:UnregisterAllEvents()
    frame:Destroy()
end

cooldowns.CreateNew = function(self)
    local ID = EXUI.utils.generateRandomString(10)

    return self:Create(ID)
end

cooldowns.Create = function(self, ID)
    local frame = self:CreateFrame()
    frame.ID = ID
    self.frames[ID] = frame

    cooldownDisplay:Create(frame)

    return frame
end

cooldowns.UpdateById = function(self, ID)
    local frame = self.frames[ID]
    if (frame) then
        self:SetDefaults(ID)
        frame.db = self:GetCDDBByID(ID)
        cooldownDisplay:Update(frame)

        if (not editor:IsFrameRegistered(frame)) then
            editor:RegisterFrameForEditor(frame, 'CD: ' .. frame.db.name, function(frame)
                local point, _, relativePoint, XOff, YOff = frame:GetPoint(1)
                self:UpdateValueForCD(ID, 'anchorPoint', point)
                self:UpdateValueForCD(ID, 'relativePoint', relativePoint)
                self:UpdateValueForCD(ID, 'XOff', XOff)
                self:UpdateValueForCD(ID, 'YOff', YOff)
            end)
        else
            editor:UpdateFrameLabel(frame, 'CD: ' .. frame.db.name)
        end
    end
end

cooldowns.UpdateAll = function(self)
    for ID in pairs(self.frames) do
        self:UpdateById(ID)
    end
end

cooldowns.DeleteById = function(self, ID)
    local frame = self.frames[ID]
    if (frame) then
        self:ClearFrame(frame)
        self.frames[ID] = nil
    end
    self:DeleteCDFromDB(ID)
end

cooldowns.InitFrames = function(self)
    local db = self:GetBaseDB()
    for ID in pairs(db) do
        self:Create(ID)
    end

    self:UpdateAll()
end

----------------------------
------------ DB ------------
----------------------------

cooldowns.GetBaseDB = function(self)
    local db = data:GetDataByKey('cooldowns') or {}
    return db
end

cooldowns.SaveBaseDB = function(self, db)
    data:SetDataByKey('cooldowns', db)
end

cooldowns.GetCDDBByID = function(self, cdID)
    local db = self:GetBaseDB()
    return db[cdID] or {}
end

cooldowns.UpdateValueForCD = function(self, cdID, key, value)
    local db = self:GetBaseDB()
    db[cdID] = db[cdID] or {}
    db[cdID][key] = value
    self:SaveBaseDB(db)
end

cooldowns.GetValueForCD = function(self, cdID, key)
    local cdDB = self:GetCDDBByID(cdID)
    return cdDB[key]
end

cooldowns.DeleteCDFromDB = function(self, cdID)
    local db = self:GetBaseDB()
    db[cdID] = nil
    self:SaveBaseDB(db)
end

cooldowns.SetDefaults = function(self, cdID)
    local db = self:GetBaseDB()
    db[cdID] = db[cdID] or {}
    for key, value in pairs(self.DEFAULTS) do
        if (db[cdID][key] == nil) then
            db[cdID][key] = value
        end
    end
    self:SaveBaseDB(db)
end

cooldowns.DuplicateCD = function(self, cdID)
    local newID = EXUI.utils.generateRandomString(10)
    local db = self:GetBaseDB()
    db[newID] = EXUI.utils.deepCloneTable(db[cdID])
    db[newID].name = db[newID].name .. ' (Copy)'
    self:SaveBaseDB(db)
    self:Create(newID)
    self:UpdateById(newID)

    return newID
end
