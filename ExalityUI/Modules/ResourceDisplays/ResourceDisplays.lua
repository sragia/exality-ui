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

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

core.powerTypes = {}

core.useSplitView = true
core.useTabs = false
core.frames = {}
core.splitViewExtraButton = {
    text = 'Create New Display',
    color = { 249 / 255, 95 / 255, 9 / 255, 1 },
    onClick = function()
        core:CreateNewDisplay()
        core:InitFrames()
        optionsFields:Refresh()
    end
}

core.DEFAULTS = {
    enable = true,
    name = 'New Display',
    width = 200,
    height = 20,
    anchorPoint = 'CENTER',
    relativeAnchorPoint = 'CENTER',
    XOff = 0,
    YOff = 0,
    showOverride = false,
    hasLoadConditions = false,
    onlyLoadOnPlayer = '',
    dontLoadOnPlayer = '',
}

core.eventHandler = CreateFrame('Frame')
core.eventHandler:RegisterEvent('PLAYER_ENTERING_WORLD')
core.eventHandler:SetScript('OnEvent', function(self)
    core:InitFrames()
end)

core.Init = function(self)
    optionsController:RegisterModule(self)
end

core.GetName = function(self)
    return 'Resource Displays'
end

core.GetOrder = function(self)
    return 20
end

core.GetSplitViewItems = function(self)
    local displayDB = data:GetDataByKey('resource-displays')
    local items = {}

    for displayID, display in pairs(displayDB) do
        if (display) then
            table.insert(items, {
                label = display.name,
                ID = displayID
            })
        end
    end

    return items
end

--- Get options to show for current display options
---@param currTabID? string Always nil for this module
---@param currItemID? string ID of the display
---@return table
core.GetOptions = function(self, currTabID, currItemID)
    if (not currItemID) then
        return {}
    end

    local currentItem = self:GetDBByDisplayID(currItemID)

    local options = {
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            onObserve = function(value)
                self:UpdateValueForDisplay(currItemID, 'enable', value)
                self:RefreshDisplayByID(currItemID)
            end,
            currentValue = function()
                return self:GetValueForDisplay(currItemID, 'enable')
            end,
            width = 100
        },
        {
            type = 'edit-box',
            label = 'Name',
            name = 'name',
            currentValue = function()
                return self:GetValueForDisplay(currItemID, 'name')
            end,
            onChange = function(_, value)
                self:UpdateValueForDisplay(currItemID, 'name', value)
                self:RefreshDisplayByID(currItemID)
            end,
            width = 50
        },
        {
            type = 'spacer',
            width = 50
        },
        {
            type = 'dropdown',
            label = 'Resource Type',
            name = 'resourceType',
            getOptions = function()
                return self:GetPowerTypes()
            end,
            currentValue = function()
                return self:GetValueForDisplay(currItemID, 'resourceType')
            end,
            onChange = function(value)
                self:UpdateValueForDisplay(currItemID, 'resourceType', value)
                self:RecreateFrame(currItemID)
                optionsFields:RefreshFields()
            end,
            width = 50
        },
        {
            type = 'toggle',
            label = 'Show Always when Available',
            name = 'showOverride',
            onObserve = function(value)
                self:UpdateValueForDisplay(currItemID, 'showOverride', value)
                self:RefreshDisplayByID(currItemID)
            end,
            currentValue = function()
                return self:GetValueForDisplay(currItemID, 'showOverride')
            end,
            width = 100
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
                return self:GetValueForDisplay(currItemID, 'width')
            end,
            onChange = function(f, value)
                self:UpdateValueForDisplay(currItemID, 'width', value)
                self:RefreshDisplayByID(currItemID)
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
                return self:GetValueForDisplay(currItemID, 'height')
            end,
            onChange = function(f, value)
                self:UpdateValueForDisplay(currItemID, 'height', value)
                self:RefreshDisplayByID(currItemID)
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
                return self:GetValueForDisplay(currItemID, 'anchorPoint')
            end,
            onChange = function(value)
                self:UpdateValueForDisplay(currItemID, 'anchorPoint', value)
                self:RefreshDisplayByID(currItemID)
            end,
            width = 22
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'relativeAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return self:GetValueForDisplay(currItemID, 'relativeAnchorPoint')
            end,
            onChange = function(value)
                self:UpdateValueForDisplay(currItemID, 'relativeAnchorPoint', value)
                self:RefreshDisplayByID(currItemID)
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
                return self:GetValueForDisplay(currItemID, 'XOff')
            end,
            onChange = function(f, value)
                self:UpdateValueForDisplay(currItemID, 'XOff', value)
                self:RefreshDisplayByID(currItemID)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'positionYOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return self:GetValueForDisplay(currItemID, 'YOff')
            end,
            onChange = function(f, value)
                self:UpdateValueForDisplay(currItemID, 'YOff', value)
                self:RefreshDisplayByID(currItemID)
            end,
            width = 20
        }
    }

    local control = self:GetPowerTypeControl(currentItem.resourceType)
    if (control) then
        tAppendAll(options, control:GetOptions(currItemID))
    end

    tAppendAll(options, {
        {
            type = 'title',
            label = 'Actions',
            size = 14,
            width = 100
        },
        {
            type = 'toggle',
            label = 'Enable Load Condtions',
            name = 'hasLoadConditions',
            currentValue = function()
                return self:GetValueForDisplay(currItemID, 'hasLoadConditions')
            end,
            onObserve = function(value)
                self:UpdateValueForDisplay(currItemID, 'hasLoadConditions', value)
                self:RefreshDisplayByID(currItemID)
            end,
            width = 100
        },
        {
            type = 'edit-box',
            label = 'Load Only on Player/s',
            name = 'onlyLoadOnPlayer',
            tooltip = {
                text = 'Comma separated list of players to load the display on.'
            },
            depends = function()
                return self:GetValueForDisplay(currItemID, 'hasLoadConditions')
            end,
            currentValue = function()
                return self:GetValueForDisplay(currItemID, 'onlyLoadOnPlayer')
            end,
            onChange = function(_, value)
                self:UpdateValueForDisplay(currItemID, 'onlyLoadOnPlayer', value)
                self:RefreshDisplayByID(currItemID)
            end,
            width = 40
        },
        {
            type = 'spacer',
            width = 60
        },
        {
            type = 'edit-box',
            label = 'Dont Load on Player/s',
            name = 'dontLoadOnPlayer',
            tooltip = {
                text = 'Comma separated list of players to not load the display on.'
            },
            depends = function()
                return self:GetValueForDisplay(currItemID, 'hasLoadConditions')
            end,
            currentValue = function()
                return self:GetValueForDisplay(currItemID, 'dontLoadOnPlayer')
            end,
            onChange = function(_, value)
                self:UpdateValueForDisplay(currItemID, 'dontLoadOnPlayer', value)
                self:RefreshDisplayByID(currItemID)
            end,
            width = 40
        },
        {
            type = 'spacer',
            width = 60
        },
        {
            type = 'button',
            label = 'Delete',
            onClick = function()
                self:DeleteDisplay(currItemID)
                optionsFields:Refresh()
            end,
            width = 16,
            color = { 171 / 255, 0, 20 / 255, 1 }
        }
    })

    return options
end

core.GetPowerTypes = function(self)
    local options = {}

    for _, powerType in ipairs(self.powerTypes) do
        options[powerType.name] = powerType.name
    end
    return options
end

core.CreateNewDisplay = function(self)
    local display = {
        ID = EXUI.utils.generateRandomString(10),
        name = 'New Display',
        enable = true,
        width = 200,
        height = 20,
        anchorPoint = 'CENTER',
        relativeAnchorPoint = 'CENTER',
        XOff = 0,
        YOff = 0,
        hasLoadConditions = false,
        onlyLoadOnPlayer = '',
        dontLoadOnPlayer = '',
    }

    self:SetDisplayToDB(display)
end

core.Create = function(self, resourceType)
    local frame = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
    frame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:SetBackdropColor(0, 0, 0, 0.5)

    local control = self:GetPowerTypeControl(resourceType)


    local elementFrame = CreateFrame('Frame', nil, frame)
    elementFrame:SetAllPoints()
    elementFrame:SetFrameLevel(frame:GetFrameLevel() + 50)
    elementFrame:Show()
    frame.ElementFrame = elementFrame
    if (control) then
        control:Create(frame)
    end

    return frame
end

core.InitFrames = function(self)
    local displayDB = data:GetDataByKey('resource-displays')
    for displayID, display in pairs(displayDB) do
        self:UpdateDefaultByPowerType(displayID, display.resourceType)
        if (not self.frames[displayID]) then
            local frame = self:Create(display.resourceType)
            self.frames[displayID] = frame
            frame.displayID = displayID
            frame.db = display
        end
    end

    self:RefreshAllFrames()
end

core.ClearFrame = function(self, frame)
    frame:Hide()
    frame:SetScript('OnEvent', nil)
    frame:UnregisterAllEvents()
    frame:ClearAllPoints()
end

core.RecreateFrame = function(self, displayID)
    local display = self:GetDBByDisplayID(displayID)
    if (self.frames[displayID]) then
        -- Clear old frame
        self.frames[displayID]:Hide()
        self.frames[displayID]:SetScript('OnEvent', nil)
        self.frames[displayID]:UnregisterAllEvents()
        self.frames[displayID]:ClearAllPoints()
        -- Create new one
        local frame = self:Create(display.resourceType)
        frame.displayID = displayID
        frame.db = display
        self.frames[displayID] = frame
        self:UpdateDefaultByPowerType(displayID, display.resourceType)
    end

    self:RefreshDisplayByID(displayID)
end

core.RefreshAllFrames = function(self)
    for displayID in pairs(self.frames) do
        self:RefreshDisplayByID(displayID)
    end
end

core.UpdateFrame = function(self, frame)
    if (frame.StatusBar) then
        EXUI:GetModule('resource-displays-elements-status-bar'):Update(frame)
    end

    if (frame.Text) then
        EXUI:GetModule('resource-displays-elements-text'):Update(frame)
    end
end

core.RefreshDisplayByID = function(self, displayID)
    local frame = self.frames[displayID]
    if (not frame) then
        return
    end

    if (not frame.IsActive or not frame:IsActive() or not self:CheckLoadConditions(displayID)) then
        frame:Hide()
        return;
    end

    if (not editor:IsFrameRegistered(frame)) then
        editor:RegisterFrameForEditor(frame, frame.db.name, function(f)
            local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
            core:UpdateValueForDisplay(displayID, 'anchorPoint', point)
            core:UpdateValueForDisplay(displayID, 'relativeAnchorPoint', relativePoint)
            core:UpdateValueForDisplay(displayID, 'XOff', xOfs)
            core:UpdateValueForDisplay(displayID, 'YOff', yOfs)
            core:RefreshDisplayByID(displayID)
        end)
    end

    frame:Show()
    local displayDB = self:GetDBByDisplayID(displayID)
    frame.db = displayDB
    EXUI:SetSize(frame, displayDB.width, displayDB.height)
    EXUI:SetPoint(
        frame,
        displayDB.anchorPoint,
        UIParent,
        displayDB.relativeAnchorPoint,
        displayDB.XOff,
        displayDB.YOff
    )

    if (not frame.Update) then
        frame.Update = function(self)
            local control = core:GetPowerTypeControl(self.db.resourceType)
            if (control) then
                control.Update(self)
            end
        end
    end
    frame:Update()

    self:UpdateFrame(frame)
end

core.CheckLoadConditions = function(self, ID)
    local db = self:GetDBByDisplayID(ID)
    if (not db.hasLoadConditions) then
        return true
    end
    local playerName = UnitName('player')

    local onlyLoadOnPlayer = db.onlyLoadOnPlayer
    if (onlyLoadOnPlayer ~= '') then
        local players = {}
        for _, name in ipairs({ strsplit(',', onlyLoadOnPlayer) }) do
            name = strtrim(name)
            if name ~= "" then
                table.insert(players, name)
            end
        end
        if (not tContains(players, playerName)) then
            return false
        end
    end

    local dontLoadOnPlayer = db.dontLoadOnPlayer
    if (dontLoadOnPlayer ~= '') then
        local players = {}
        for _, name in ipairs({ strsplit(',', dontLoadOnPlayer) }) do
            name = strtrim(name)
            if name ~= "" then
                table.insert(players, name)
            end
        end
        if (tContains(players, playerName)) then
            return false
        end
    end

    return true
end

core.RegisterPowerType = function(self, powerType)
    table.insert(self.powerTypes, powerType)
end

core.UpdateDefaultByPowerType = function(self, displayID, powerTypeName)
    local powerTypeControl = self:GetPowerTypeControl(powerTypeName)
    self:UpdateDefaultValuesForDisplay(displayID, self.DEFAULTS)
    if (powerTypeControl) then
        powerTypeControl:UpdateDefault(displayID)
    end
end

core.GetPowerTypeControl = function(self, powerTypeName)
    for _, powerType in ipairs(self.powerTypes) do
        if (powerType.name == powerTypeName) then
            return powerType.control
        end
    end
    return nil
end


----------------------------
------------ DB ------------
----------------------------

core.GetDBByDisplayID = function(self, displayID)
    local displayDB = data:GetDataByKey('resource-displays')
    if (not displayDB) then
        displayDB = {}
        data:SetDataByKey('resource-displays', displayDB)
    end
    displayDB[displayID] = displayDB[displayID] or {}
    return displayDB[displayID]
end

core.SetDisplayToDB = function(self, display)
    local displayDB = data:GetDataByKey('resource-displays')
    displayDB[display.ID] = display
    data:SetDataByKey('resource-displays', displayDB)
end

core.UpdateValueForDisplay = function(self, displayID, key, value)
    local displayDB = data:GetDataByKey('resource-displays')
    displayDB[displayID] = displayDB[displayID] or {}
    displayDB[displayID][key] = value
    data:SetDataByKey('resource-displays', displayDB)
end

core.UpdateDefaultValuesForDisplay = function(self, displayID, defaultValues)
    local displayDB = data:GetDataByKey('resource-displays')
    local display = displayDB[displayID] or {}
    for key, value in pairs(defaultValues) do
        if (display[key] == nil) then
            display[key] = value
        end
    end
    displayDB[displayID] = display
    data:SetDataByKey('resource-displays', displayDB)
end

core.GetValueForDisplay = function(self, displayID, key)
    local db = self:GetDBByDisplayID(displayID)
    return db[key]
end

core.DeleteDisplay = function(self, displayID)
    local displayDB = data:GetDataByKey('resource-displays')
    displayDB[displayID] = nil
    data:SetDataByKey('resource-displays', displayDB)
    self:ClearFrame(self.frames[displayID])
    self.frames[displayID] = nil
end

----------------------------
