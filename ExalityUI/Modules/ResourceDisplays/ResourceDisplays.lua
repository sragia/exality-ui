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



---@class EXUIResourceDisplaysDefaults

local defaults = EXUI:GetModule('resource-displays-defaults')



---@class EXUIResourceDisplaysLoadConditions

local loadConditions = EXUI:GetModule('resource-displays-load-conditions')



---@class EXUIResourceDisplaysVisibility

local visibility = EXUI:GetModule('resource-displays-visibility')



---@class EXUIResourceDisplaysHelpers

local helpers = EXUI:GetModule('resource-displays-helpers')



---@class EXUIResourceDisplaysPreview

local preview = EXUI:GetModule('resource-displays-preview')



---@class EXUIResourceDisplaysGeneralOptions

local generalOptions = EXUI:GetModule('resource-displays-general-options')



---@class EXUIResourceDisplaysDisplayOptions

local displayOptions = EXUI:GetModule('resource-displays-display-options')



---@class EXUIResourceDisplaysLoadOptions

local loadOptions = EXUI:GetModule('resource-displays-load-options')



---@class EXUIResourceDisplaysCore

local core = EXUI:GetModule('resource-displays-core')



core.powerTypes = {}

core.pendingRecreates = {}

core.useSplitView = true

core.useTabs = false

core.useInnerTabs = true

core.frames = {}



core.GENERIC_RESOURCE_TYPES = {

    Energy = true,

    Mana = true,

    Rage = true,

    Focus = true,

    ['Runic Power'] = true,

    Fury = true,

    Insanity = true,

    ['Astral Power'] = true,

    ['Arcane Charges'] = true,

}



core.splitViewExtraButton = {

    text = 'Create New Display',

    color = { 249 / 255, 95 / 255, 9 / 255, 1 },

    onClick = function()

        core:CreateNewDisplay()

        core:InitFrames()

        optionsFields:Refresh()

    end,

}



core.eventHandler = CreateFrame('Frame')

core.eventHandler:RegisterEvent('PLAYER_ENTERING_WORLD')

core.eventHandler:SetScript('OnEvent', function()

    core:InitFrames()

end)



core.Init = function(self)

    self:EnsureDB()

    visibility:Init()

    preview:Init()

    optionsController:RegisterModule(self)

end



core.GetDB = function(self)

    return data:GetDataByKey('resource-displays')

end



core.EnsureDB = function(self)

    local db = self:GetDB()

    if db.__exuiDefaultsVersion == defaults.SCHEMA_VERSION then

        return db

    end

    defaults:MergeIntoDB(db)

    data:SetDataByKey('resource-displays', db)

    return db

end



core.IsDisplayEntry = function(self, displayID, display)

    if defaults:IsMetadataKey(displayID) then

        return false

    end

    return type(display) == 'table'

end



core.GetName = function(self)

    return 'Resource Displays'

end



core.GetOrder = function(self)

    return 40

end

core.GetProfileExportSpec = function(self)
    return { id = 'resource-displays', keys = { 'resource-displays' } }
end

core.IsGenericResourceType = function(self, resourceType)

    return resourceType and self.GENERIC_RESOURCE_TYPES[resourceType] or false

end



core.GetSplitViewItems = function(self)

    self:EnsureDB()

    local displayDB = self:GetDB()

    local items = {}

    local icons = EXUI.const.textures.frame.icons



    for displayID, display in EXUI.utils.spairs(displayDB, function(t, a, b)

        local aDisplay = t[a]

        local bDisplay = t[b]

        if type(aDisplay) ~= 'table' or type(bDisplay) ~= 'table' then

            return tostring(a) < tostring(b)

        end

        return (aDisplay.createdAt or 0) < (bDisplay.createdAt or 0)

    end) do

        if self:IsDisplayEntry(displayID, display) then

            table.insert(items, {

                label = display.name or displayID,

                ID = displayID,

                preview = {

                    enabled = preview:IsToggled(displayID),

                    iconOn = icons.eye,

                    iconOff = icons.eyeOff,

                    onToggle = function(itemID, enabled)

                        preview:SetToggled(itemID, enabled)

                    end,

                },

                contextMenuItems = {

                    {

                        label = 'Duplicate',

                        color = { 2 / 255, 145 / 255, 227 / 255, 1 },

                        onClick = function(itemID)

                            local newID = self:DuplicateDisplay(itemID)

                            optionsFields:Refresh()

                            optionsFields:SetItemID(newID)

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

    end



    return items

end



core.GetSectionTabs = function(self, itemId)

    if not itemId then

        return {}

    end

    return {

        { ID = 'general', label = 'General' },

        { ID = 'display', label = 'Display' },

        { ID = 'load', label = 'Load' },

    }

end



core.GetOptions = function(self, currTabID, currItemID)

    if not currItemID then

        return {}

    end



    self:EnsureDB()



    local currentItem = self:GetDBByDisplayID(currItemID)

    if not currentItem or next(currentItem) == nil then

        return {}

    end



    local section = currTabID or 'general'

    if section == 'general' then

        return generalOptions:GetOptions(currItemID)

    elseif section == 'display' then

        return displayOptions:GetOptions(currItemID)

    elseif section == 'load' then

        return loadOptions:GetOptions(currItemID)

    end



    return {}

end



core.GetPowerTypes = function(self)

    local options = {}

    for _, powerType in ipairs(self.powerTypes) do

        options[powerType.name] = powerType.name

    end

    return options

end



core.CreateNewDisplay = function(self, resourceType)

    self:EnsureDB()

    local display = defaults:BuildNewDisplay(resourceType)

    self:SetDisplayToDB(display)

    return display.ID

end



core.GetSegmentGroupSize = function(self, segmentWidth, segmentHeight, count, spacing, layout)

    if count <= 0 then

        return 0, segmentHeight

    end

    if layout == 'vertical' then

        return segmentWidth, segmentHeight * count + spacing * (count - 1)

    end

    return segmentWidth * count + spacing * (count - 1), segmentHeight

end



core.RefreshSegmentFrame = function(self, segmentFrame)

    EXUI:SnapFrameToPixels(segmentFrame)

    if segmentFrame.PPBorder then

        segmentFrame.PPBorder:SetBorderThickness(1)

    end

    if segmentFrame.StatusBar then

        EXUI:GetModule('resource-displays-elements-status-bar'):ApplyInsets(segmentFrame.StatusBar, segmentFrame)

    end

end



core.RefreshSegmentFrames = function(self, frame)

    if not frame.ActiveFrames then

        return

    end

    EXUI:SnapFrameToPixels(frame)

    for _, segmentFrame in ipairs(frame.ActiveFrames) do

        self:RefreshSegmentFrame(segmentFrame)

    end

end



core.ClearDisplayChrome = function(self, frame)

    frame:SetBackdrop(nil)

    if frame.PPBorder then

        frame.PPBorder.Top:Hide()

        frame.PPBorder.Bottom:Hide()

        frame.PPBorder.Left:Hide()

        frame.PPBorder.Right:Hide()

    end

end



core.ApplyDisplayChrome = function(self, frame, resourceType)

    resourceType = resourceType or (frame.db and frame.db.resourceType)

    if resourceType and self:IsSelfControlledSize(resourceType) then

        self:ClearDisplayChrome(frame)

        return

    end



    frame:SetBackdrop(EXUI.const.backdrop.backgroundOnly)

    frame:SetBackdropColor(0, 0, 0, 0.5)

    if not frame.PPBorder then

        frame.PPBorder = EXUI:AddPixelPerfectBorder(frame, 1)

    else

        frame.PPBorder:SetBorderThickness(1)

        frame.PPBorder.Top:Show()

        frame.PPBorder.Bottom:Show()

        frame.PPBorder.Left:Show()

        frame.PPBorder.Right:Show()

    end

    frame.PPBorder:SetBorderColor(0, 0, 0, 1)

end



core.ApplySegmentChrome = function(self, segmentFrame, bgColor, borderColor)

    segmentFrame:SetBackdrop(EXUI.const.backdrop.backgroundOnly)

    if bgColor then

        segmentFrame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)

    end

    if not segmentFrame.PPBorder then

        segmentFrame.PPBorder = EXUI:AddPixelPerfectBorder(segmentFrame, 1, { register = false })

    else

        segmentFrame.PPBorder:SetBorderThickness(1)

        segmentFrame.PPBorder.Top:Show()

        segmentFrame.PPBorder.Bottom:Show()

        segmentFrame.PPBorder.Left:Show()

        segmentFrame.PPBorder.Right:Show()

    end

    if borderColor then

        segmentFrame.PPBorder:SetBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    end

end



core.ApplyContentInsets = function(self, frame)

    if frame.StatusBar then

        EXUI:GetModule('resource-displays-elements-status-bar'):ApplyInsets(frame.StatusBar, frame)

    end

end



core.EnsurePlaceholder = function(self, frame)

    if not frame.Placeholder then

        frame.Placeholder = frame:CreateFontString(nil, 'OVERLAY')

        frame.Placeholder:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')

        frame.Placeholder:SetTextColor(1, 1, 1, 0.5)

        frame.Placeholder:SetPoint('CENTER')

    end

end



core.UpdatePlaceholder = function(self, frame, show)

    self:EnsurePlaceholder(frame)

    if show then

        frame.Placeholder:SetText(frame.db and frame.db.name or 'Resource Display')

        frame.Placeholder:Show()

        frame:SetAlpha(0.35)

    else

        frame.Placeholder:Hide()

    end

end



core.ApplyFramePresentation = function(self, frame, displayDB)

    local scale = displayDB.scale or 1

    frame:SetScale(scale)

    frame:SetFrameStrata(displayDB.frameStrata or 'MEDIUM')

    frame:SetFrameLevel(displayDB.frameLevel or 100)

end



core.ApplyFrameAlpha = function(self, frame, displayDB)

    if displayDB.fadeOnHide then

        UIFrameFadeIn(frame, 0.15, frame:GetAlpha(), 1)

    else

        frame:SetAlpha(1)

    end

end



core.Create = function(self, resourceType)

    local frame = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')

    local control = self:GetPowerTypeControl(resourceType)



    local elementFrame = CreateFrame('Frame', nil, frame)

    elementFrame:SetAllPoints()

    elementFrame:SetFrameLevel(frame:GetFrameLevel() + 50)

    elementFrame:Show()

    frame.ElementFrame = elementFrame



    if control then

        control:Create(frame)

    end



    self:ApplyDisplayChrome(frame, resourceType)

    EXUI:RegisterSnapFrame(frame)

    frame.ApplyContentInsets = function()

        if frame.db and core:IsSelfControlledSize(frame.db.resourceType) then

            core:RefreshSegmentFrames(frame)

        else

            core:ApplyContentInsets(frame)

        end

    end



    return frame

end



core.InitFrames = function(self)

    self:EnsureDB()

    local displayDB = self:GetDB()

    for displayID, display in pairs(displayDB) do

        if self:IsDisplayEntry(displayID, display) then

            self:UpdateDefaultByPowerType(displayID, display.resourceType)

            if not display.createdAt then

                self:UpdateValueForDisplay(displayID, 'createdAt', time())

            end

            if not self.frames[displayID] then

                local frame = self:Create(display.resourceType)

                self.frames[displayID] = frame

                frame.displayID = displayID

                frame.db = display

            end

        end

    end



    self:RefreshAllFrames()

end



core.ClearFrame = function(self, frame)

    frame:Hide()

    if frame.Disable then

        frame:Disable()

    else

        frame:SetScript('OnEvent', nil)

        frame:UnregisterAllEvents()

    end

    frame:ClearAllPoints()

end



core.RecreateFrame = function(self, displayID)

    if InCombatLockdown() then

        self.pendingRecreates[displayID] = true

        return

    end



    local display = self:GetDBByDisplayID(displayID)

    if self.frames[displayID] then

        self:ClearFrame(self.frames[displayID])

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



core.RefreshFramesForVisibility = function(self, combatChanged, targetChanged)

    if not combatChanged and not targetChanged then

        return

    end



    for displayID in pairs(self.frames) do

        local displayDB = self:GetDBByDisplayID(displayID)

        if visibility:DisplayNeedsVisibilityRefresh(displayDB, combatChanged, targetChanged) then

            self:RefreshDisplayByID(displayID)

        end

    end

end



EXUI:RegisterEventHandler({ 'PLAYER_SPECIALIZATION_CHANGED', 'UPDATE_SHAPESHIFT_FORM' }, 'resource-displays-core', function()

    core:RefreshAllFrames()

end)



EXUI:RegisterEventHandler('PLAYER_REGEN_ENABLED', 'resource-displays-core', function()

    for displayID in pairs(core.pendingRecreates) do

        core.pendingRecreates[displayID] = nil

        core:RecreateFrame(displayID)

    end

    core:RefreshAllFrames()

end)



core.UpdateFrame = function(self, frame)

    if frame.StatusBar then

        EXUI:GetModule('resource-displays-elements-status-bar'):Update(frame)

    end

    if frame.Text then

        EXUI:GetModule('resource-displays-elements-text'):Update(frame)

    end

end



core.ShouldShowDisplay = function(self, displayID, frame)

    local displayDB = self:GetDBByDisplayID(displayID)

    if not displayDB.enable then

        return false

    end

    if preview:HasAnyToggled() then

        return preview:IsToggled(displayID)

    end

    if not self:CheckLoadConditions(displayID) then

        return false

    end

    if not visibility:ShouldShowDisplay(displayDB) then

        return false

    end

    if frame.IsActive and not frame:IsActive() then
        return preview:IsActive(displayID)
    end

    return true
end



core.RefreshDisplayByID = function(self, displayID)

    local frame = self.frames[displayID]

    if not frame then

        return

    end



    local displayDB = self:GetDBByDisplayID(displayID)

    frame.db = displayDB

    if preview:IsToggled(displayID) then
        preview.scenario = 'mid'
    end



    local shouldShow = self:ShouldShowDisplay(displayID, frame)

    local inEditor = not preview:HasAnyToggled() and (editor.activeFrame == frame or (frame.editor and frame.editor:IsShown()))



    if not shouldShow and not inEditor then

        frame:Hide()

        if frame.editor then

            frame.editor:Hide()

        end

        if frame.Disable then

            frame:Disable()

        end

        self:UpdatePlaceholder(frame, false)

        return

    end



    if frame.Enable then

        frame:Enable()

    end



    if not editor:IsFrameRegistered(frame) then

        editor:RegisterFrameForEditor(frame, displayDB.name, function()

            local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)

            self:UpdateValueForDisplay(displayID, 'anchorPoint', point)

            self:UpdateValueForDisplay(displayID, 'relativeAnchorPoint', relativePoint)

            self:UpdateValueForDisplay(displayID, 'XOff', xOfs)

            self:UpdateValueForDisplay(displayID, 'YOff', yOfs)

            -- Persist only while editing: RefreshDisplayByID re-applies SetPoint +
            -- SnapFrameToPixels and can cancel 1px nudges.
        end)

    else

        editor:UpdateFrameLabel(frame, displayDB.name or 'Resource Display')

    end



    frame:Show()

    self:ApplyFramePresentation(frame, displayDB)



    if not self:IsSelfControlledSize(displayDB.resourceType) then

        EXUI:SetSize(frame, displayDB.width, displayDB.height)

    end



    EXUI:SetPoint(frame, displayDB.anchorPoint, UIParent, displayDB.relativeAnchorPoint, displayDB.XOff, displayDB.YOff)

    EXUI:SnapFrameToPixels(frame)

    self:ApplyDisplayChrome(frame)

    self:ApplyContentInsets(frame)



    if not frame.Update then

        frame.Update = function(self)

            local control = core:GetPowerTypeControl(self.db.resourceType)

            if control then

                control.Update(self)

            end

        end

    end

    frame:Update()



    if self:IsSelfControlledSize(displayDB.resourceType) then

        self:RefreshSegmentFrames(frame)

    end



    self:UpdateFrame(frame)



    if not shouldShow and inEditor then

        self:UpdatePlaceholder(frame, true)

    else

        self:UpdatePlaceholder(frame, false)

        self:ApplyFrameAlpha(frame, displayDB)

    end

end



core.CheckLoadConditions = function(self, ID)

    local db = self:GetDBByDisplayID(ID)

    return loadConditions:ShouldLoad(db)

end



core.RegisterPowerType = function(self, powerType)

    table.insert(self.powerTypes, powerType)

end



core.GetPowerTypeMeta = function(self, powerTypeName)

    for _, powerType in ipairs(self.powerTypes) do

        if powerType.name == powerTypeName then

            return powerType

        end

    end

    return nil

end



core.UpdateDefaultByPowerType = function(self, displayID, powerTypeName)

    local powerTypeControl = self:GetPowerTypeControl(powerTypeName)

    self:UpdateDefaultValuesForDisplay(displayID, defaults:GetDisplayDefaults())

    if powerTypeControl then

        powerTypeControl:UpdateDefault(displayID)

    end

end



core.GetPowerTypeControl = function(self, powerTypeName)

    for _, powerType in ipairs(self.powerTypes) do

        if powerType.name == powerTypeName then

            return powerType.control

        end

    end

    return nil

end



core.IsSelfControlledSize = function(self, powerTypeName)

    for _, powerType in ipairs(self.powerTypes) do

        if powerType.name == powerTypeName then

            return powerType.selfControlledSize

        end

    end

    return nil

end



----------------------------

------------ DB ------------

----------------------------



core.GetDBByDisplayID = function(self, displayID)

    local displayDB = data:GetDataByKey('resource-displays')

    if not displayDB then

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

    if key == 'resourceColorCurve'
        or key == 'resourceColorCurveEnabled'
        or key == 'barColor'
        or key == 'useClassColor'
        or key == 'lowResourceColor' then
        helpers:InvalidateResourceColorCurveCache(displayDB[displayID])
    end

    data:SetDataByKey('resource-displays', displayDB)

end



core.UpdateDefaultValuesForDisplay = function(self, displayID, defaultValues)

    local displayDB = data:GetDataByKey('resource-displays')

    local display = displayDB[displayID] or {}

    for key, value in pairs(defaultValues) do

        if display[key] == nil then

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

    if self.frames[displayID] then

        if editor:IsFrameRegistered(self.frames[displayID]) then

            editor:UnregisterFrameForEditor(self.frames[displayID])

        end

        self:ClearFrame(self.frames[displayID])

        self.frames[displayID] = nil

    end

end



core.previewButton = nil

core.previewDisplayID = nil



core.TeardownOptionsChrome = function(self)

    if self.previewButton then

        self.previewButton:Hide()

        self.previewButton:SetParent(nil)

        self.previewButton = nil

    end

    self.previewDisplayID = nil

end



core.EnsurePreviewButton = function(self, parent)

    if not self.previewButton then

        local EXFrames = EXUI.EXFrames

        local previewButton = CreateFrame('Button', nil, parent)

        previewButton:SetSize(140, 24)

        previewButton:SetPoint('RIGHT', parent, 'RIGHT', -10, 0)

        previewButton:SetAlpha(0.7)



        local previewIcon = previewButton:CreateTexture(nil, 'BACKGROUND')

        previewIcon:SetTexture(EXUI.const.textures.frame.previewIcon)

        previewIcon:SetSize(40 * 15 / 24, 15)

        previewIcon:SetPoint('RIGHT')



        local previewText = previewButton:CreateFontString(nil, 'OVERLAY')

        previewText:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')

        previewText:SetText('Toggle Preview')

        previewText:SetWidth(0)

        previewText:SetPoint('RIGHT', previewIcon, 'LEFT', -5, 0)

        previewText:SetJustifyH('RIGHT')



        previewButton:SetScript('OnEnter', function()

            previewButton:SetAlpha(1)

        end)

        previewButton:SetScript('OnLeave', function()

            previewButton:SetAlpha(0.7)

        end)



        previewButton:SetScript('OnClick', function()

            core:TogglePreview()

        end)



        self.previewButton = previewButton

    else

        self.previewButton:SetParent(parent)

        self.previewButton:ClearAllPoints()

        self.previewButton:SetPoint('RIGHT', parent, 'RIGHT', -10, 0)

    end

end



core.UpdatePreviewButton = function(self)

    local button = self.previewButton

    if not button then

        return

    end

    if preview.enabled then

        button:SetAlpha(1)

    else

        button:SetAlpha(0.7)

    end

end



core.TogglePreview = function(self)

    local displayID = optionsFields.currItemID

    if not displayID then

        return

    end

    if self.previewDisplayID ~= displayID then

        preview:SetEnabled(false)

        self.previewDisplayID = displayID

    end

    preview:SetActiveDisplay(displayID)

    preview:SetEnabled(not preview.enabled)

    self:UpdatePreviewButton()

end



core.UpdateOptionsChrome = function(self, optionsFieldsRef)

    self:TeardownOptionsChrome()

end



core.DuplicateDisplay = function(self, displayID)

    local newID = EXUI.utils.generateRandomString(10)

    local db = data:GetDataByKey('resource-displays')

    db[newID] = EXUI.utils.deepCloneTable(db[displayID])

    db[newID].ID = newID

    db[newID].name = db[newID].name .. ' (Copy)'

    db[newID].createdAt = time()

    db[newID].XOff = (db[newID].XOff or 0) + 20

    db[newID].YOff = (db[newID].YOff or 0) - 20

    data:SetDataByKey('resource-displays', db)

    local display = db[newID]

    local frame = self:Create(display.resourceType)

    self.frames[newID] = frame

    frame.displayID = newID

    frame.db = display

    self:RefreshDisplayByID(newID)

    return newID

end



----------------------------


