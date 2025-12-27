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

local LDB = LibStub("LibDataBroker-1.1")
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

----------------------------

---@class EXUIDataBrokers
local dataBrokers = EXUI:GetModule('data-brokers')

---------------
--- Options ---
---------------

dataBrokers.useTabs = false
dataBrokers.useSplitView = true
dataBrokers.splitViewExtraButton = {
    text = 'New',
    color = { 249 / 255, 95 / 255, 9 / 255, 1 },
    onClick = function()
        print('Create New Data Broker Display')
        local id = dataBrokers.Displays:CreateNew()
        optionsFields:Refresh()
        optionsFields:SetItemID(id)
    end
}

local function GetLDBBrokers()
    local options = {}
    for name, broker in LDB:DataObjectIterator() do
        options[name] = name
    end
    return options
end

dataBrokers.Init = function(self)
    optionsController:RegisterModule(self)
    self.Displays:Init()
end

dataBrokers.GetName = function(self)
    return 'Data Broker Displays'
end

dataBrokers.GetOrder = function(self)
    return 100
end

dataBrokers.GetSplitViewItems = function(self)
    local items = {}
    local db = dataBrokers.Data:GetBaseDB()
    for id, displayDB in pairs(db) do
        table.insert(items, {
            label = displayDB.brokerName,
            ID = id
        })
    end

    return items
end

dataBrokers.GetOptions = function(self, _, currItemId)
    if (not currItemId) then
        return {}
    end

    local db = dataBrokers.Data:GetById(currItemId)
    if (not db) then
        return {}
    end

    return {
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            onObserve = function(value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'enable', value)
                dataBrokers.Displays:UpdateById(currItemId)
            end,
            currentValue = function()
                return dataBrokers.Data:GetValueForBroker(currItemId, 'enable')
            end,
            width = 100
        },
        {
            type = 'dropdown',
            label = 'Broker Name',
            name = 'brokerName',
            getOptions = function()
                return GetLDBBrokers()
            end,
            currentValue = function()
                return dataBrokers.Data:GetValueForBroker(currItemId, 'brokerName')
            end,
            onChange = function(value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'brokerName', value)
                dataBrokers.Displays:UpdateById(currItemId)
            end,
            width = 50
        },
        {
            type = 'spacer',
            width = 50
        },
        {
            type = 'title',
            label = 'Size & Position',
            size = 14,
            width = 100
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
                return dataBrokers.Data:GetValueForBroker(currItemId, 'width')
            end,
            onChange = function(f, value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'width', value)
                dataBrokers.Displays:UpdateById(currItemId)
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
                return dataBrokers.Data:GetValueForBroker(currItemId, 'height')
            end,
            onChange = function(f, value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'height', value)
                dataBrokers.Displays:UpdateById(currItemId)
            end
        },
        {
            type = 'spacer',
            width = 50
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = 'anchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return dataBrokers.Data:GetValueForBroker(currItemId, 'anchor')
            end,
            onChange = function(value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'anchor', value)
                dataBrokers.Displays:UpdateById(currItemId)
            end,
            width = 22
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'relativeAnchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return dataBrokers.Data:GetValueForBroker(currItemId, 'relativeAnchor')
            end,
            onChange = function(value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'relativeAnchor', value)
                dataBrokers.Displays:UpdateById(currItemId)
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
                return dataBrokers.Data:GetValueForBroker(currItemId, 'XOff')
            end,
            onChange = function(f, value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'XOff', value)
                dataBrokers.Displays:UpdateById(currItemId)
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
                return dataBrokers.Data:GetValueForBroker(currItemId, 'YOff')
            end,
            onChange = function(f, value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'YOff', value)
                dataBrokers.Displays:UpdateById(currItemId)
            end,
            width = 20
        },
        {
            type = 'spacer',
            width = 50
        },
        {
            type = 'title',
            label = 'Font',
            size = 14,
            width = 100
        },
        {
            type = 'dropdown',
            label = 'Font',
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
                return dataBrokers.Data:GetValueForBroker(currItemId, 'font')
            end,
            onChange = function(value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'font', value)
                dataBrokers.Displays:UpdateById(currItemId)
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
                return dataBrokers.Data:GetValueForBroker(currItemId, 'fontFlag')
            end,
            onChange = function(value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'fontFlag', value)
                dataBrokers.Displays:UpdateById(currItemId)
            end,
            width = 23
        },
        {
            type = 'range',
            label = 'Font Size',
            name = 'fontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 20,
            currentValue = function()
                return dataBrokers.Data:GetValueForBroker(currItemId, 'fontSize')
            end,
            onChange = function(f, value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'fontSize', value)
                dataBrokers.Displays:UpdateById(currItemId)
            end
        },
        {
            type = 'spacer',
            width = 34
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = 'fontAnchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return dataBrokers.Data:GetValueForBroker(currItemId, 'fontAnchor')
            end,
            onChange = function(value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'fontAnchor', value)
                dataBrokers.Displays:UpdateById(currItemId)
            end,
            width = 23
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'fontRelativeAnchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return dataBrokers.Data:GetValueForBroker(currItemId, 'fontRelativeAnchor')
            end,
            onChange = function(value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'fontRelativeAnchor', value)
                dataBrokers.Displays:UpdateById(currItemId)
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
            currentValue = function()
                return dataBrokers.Data:GetValueForBroker(currItemId, 'fontXOff')
            end,
            onChange = function(f, value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'fontXOff', value)
                dataBrokers.Displays:UpdateById(currItemId)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'fontYOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return dataBrokers.Data:GetValueForBroker(currItemId, 'fontYOff')
            end,
            onChange = function(f, value)
                dataBrokers.Data:UpdateValueForBroker(currItemId, 'fontYOff', value)
                dataBrokers.Displays:UpdateById(currItemId)
            end,
            width = 20
        },
        {
            type = 'title',
            label = 'Actions',
            size = 14,
            width = 100
        },
        {
            type = 'button',
            label = 'Delete',
            onClick = function()
                dataBrokers.Displays:DeleteById(currItemId)
                optionsFields:Refresh()
            end,
            width = 16,
            color = { 171 / 255, 0, 20 / 255, 1 }
        },
    }
end

-----------------------
--- Display Control ---
-----------------------

dataBrokers.Displays = {
    frames = {},
    pool = CreateFramePool('Frame', UIParent),
    DEFAULTS = {
        brokerName = 'New',
        enable = true,
        width = 200,
        height = 20,
        anchor = 'CENTER',
        relativeAnchor = 'CENTER',
        XOff = 0,
        YOff = 0,
        font = 'DMSans',
        fontSize = 12,
        fontFlag = 'OUTLINE',
        fontAnchor = 'CENTER',
        fontRelativeAnchor = 'CENTER',
        fontXOff = 0,
        fontYOff = 0,
    },
    Init = function(self)
        local db = dataBrokers.Data:GetBaseDB()
        for id, obj in pairs(db) do
            if (obj) then
                self:Create(id)
                self:UpdateById(id)
            end
        end
        LDB.RegisterCallback(self, 'LibDataBroker_AttributeChanged__text', 'RefreshText')
    end,
    CreateNew = function(self)
        local id = EXUI.utils.generateRandomString(10)
        dataBrokers.Data:UpdateDefaults(id, self.DEFAULTS)
        self:Create(id)
        self:UpdateById(id)

        return id
    end,
    Create = function(self, id)
        local frame = self.pool:Acquire()
        frame.ID = id
        self.frames[id] = frame

        frame.Destroy = function(self)
            self.ID = nil
            self.broker = nil
            dataBrokers.Displays.pool:Release(self)
        end

        local text = frame:CreateFontString(nil, 'OVERLAY')
        text:SetPoint('CENTER')
        text:SetWidth(0)
        frame.Text = text

        frame:Show()
        editor:RegisterFrameForEditor(frame, 'Broker: ' .. id, function(frame)
            local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
            dataBrokers.Data:UpdateValueForBroker(id, 'anchor', point)
            dataBrokers.Data:UpdateValueForBroker(id, 'relativeAnchor', relativePoint)
            dataBrokers.Data:UpdateValueForBroker(id, 'XOff', xOfs)
            dataBrokers.Data:UpdateValueForBroker(id, 'YOff', yOfs)
            self:UpdateById(id)
        end)
        return frame
    end,
    UpdateById = function(self, id)
        local frame = self.frames[id]
        if (not frame) then return end
        local db = dataBrokers.Data:GetById(id)
        local broker = LDB:GetDataObjectByName(db.brokerName)
        if (not db or not db.enable or not broker) then
            frame:Hide()
            return
        end
        frame:Show()

        frame.broker = db.brokerName

        EXUI:SetSize(frame, db.width, db.height)
        frame:ClearAllPoints()
        EXUI:SetPoint(frame, db.anchor, UIParent, db.relativeAnchor, db.XOff, db.YOff)

        local text = frame.Text
        text:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)
        text:ClearAllPoints()
        text:SetPoint(db.fontAnchor, frame, db.fontRelativeAnchor, db.fontXOff, db.fontYOff)
        text:SetText(broker.text or db.brokerName)

        if (broker.OnClick) then
            frame:SetScript('OnMouseDown', broker.OnClick)
        else
            frame:SetScript('OnMouseDown', nil)
        end

        if (broker.OnEnter) then
            frame:SetScript('OnEnter', broker.OnEnter)
        else
            frame:SetScript('OnEnter', nil)
        end

        if (broker.OnLeave) then
            frame:SetScript('OnLeave', broker.OnLeave)
        else
            frame:SetScript('OnLeave', nil)
        end
    end,
    RefreshText = function(self, event, name, key, value, obj)
        for _, frame in pairs(self.frames) do
            if (frame.broker == name) then
                frame.Text:SetText(value)
            end
        end
    end,
    DeleteById = function(self, id)
        local frame = self.frames[id]
        if (not frame) then
            return
        end

        frame:Destroy()
        dataBrokers.Data:DeleteBroker(id)
    end,
}

------------
--- Data ---
------------

dataBrokers.Data = {
    GetBaseDB = function(self)
        local db = data:GetDataByKey('data-brokers') or {}
        return db
    end,
    SaveBaseDB = function(self, db)
        data:SetDataByKey('data-brokers', db)
    end,
    GetById = function(self, id)
        local db = self:GetBaseDB()
        return db[id] or {}
    end,
    UpdateValueForBroker = function(self, id, key, value)
        local db = self:GetBaseDB()
        db[id] = db[id] or {}
        db[id][key] = value
        self:SaveBaseDB(db)
    end,
    GetValueForBroker = function(self, id, key)
        local db = self:GetById(id)
        return db[key]
    end,
    UpdateDefaults = function(self, id, defaults)
        local db = self:GetBaseDB()
        db[id] = db[id] or {}
        for key, value in pairs(defaults) do
            if (db[id][key] == nil) then
                db[id][key] = value
            end
        end
        self:SaveBaseDB(db)
    end,
    DeleteBroker = function(self, id)
        local db = self:GetBaseDB()
        db[id] = nil
        self:SaveBaseDB(db)
    end
}
