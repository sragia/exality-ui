---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)
local statusBarElement = EXUI:GetModule('resource-displays-elements-status-bar')

---@class EXUIResourceDisplaysSegmentBase
local segmentBase = EXUI:GetModule('resource-displays-segment-base')

function segmentBase:CreateSingleSegment(parent)
    local frame = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    EXUI:SetSize(frame, 30, 16)

    local statusBar = CreateFrame('StatusBar', nil, frame)
    statusBarElement:ApplyInsets(statusBar, frame)
    statusBar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(0)
    statusBar:SetStatusBarColor(1, 0, 0, 1)
    frame.StatusBar = statusBar

    return frame
end

function segmentBase:ApplySegmentVisuals(segment, db, config, index, isCharged)
    local width = db[config.widthKey] or 30
    local height = db[config.heightKey] or 16
    local textureKey = config.textureKey
    local sharedColorKey = config.colorKey
    local colorsKey = config.colorsKey or (config.prefix .. 'Colors')
    local bgKey = config.backgroundKey
    local borderKey = config.borderKey

    EXUI:SetSize(segment, width, height)
    local color = helpers:GetSegmentColor(db, index, sharedColorKey, colorsKey, config.capColorKey, false)
    if isCharged and db.chargedColor then
        color = db.chargedColor
    end
    if color then
        segment.StatusBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
    end
    if textureKey and db[textureKey] then
        segment.StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', db[textureKey]))
    end
    core:ApplySegmentChrome(segment, db[bgKey], db[borderKey])
    segment.FillAnimation = db.fillAnimation or db.smoothFill
end

function segmentBase:UpdateSegmentRow(frame, config, getMaxCount, powerTypeEnum, onApplyValues)
    local db = frame.db
    local poolKey = config.poolKey
    local maxCount = getMaxCount()

    if not frame[poolKey] then
        frame[poolKey] = {}
    end
    if not frame.ActiveFrames then
        frame.ActiveFrames = {}
    end

    for _, segment in pairs(frame[poolKey]) do
        segment:Hide()
    end
    wipe(frame.ActiveFrames)

    for i = 1, maxCount do
        local segment = frame[poolKey][i]
        if not segment then
            segment = self:CreateSingleSegment(frame)
            frame[poolKey][i] = segment
        end
        segment.index = i
        table.insert(frame.ActiveFrames, segment)
        segment:Show()
        self:ApplySegmentVisuals(segment, db, config, i, false)
    end

    local groupWidth, groupHeight = helpers:LayoutSegments(
        frame,
        frame.ActiveFrames,
        db,
        config.widthKey,
        config.heightKey,
        config.spacingKey
    )
    EXUI:SetSize(frame, groupWidth, groupHeight)

    if onApplyValues then
        onApplyValues(frame, maxCount)
    end
end

function segmentBase:GetCommonOptions(displayID, config, RDCore)
    local prefix = config.prefix
    local label = config.label or 'Segments'
    local options = {
        {
            type = 'title',
            size = 14,
            width = 100,
            label = label,
        },
        {
            type = 'range',
            label = 'Width',
            name = config.widthKey,
            min = 1,
            max = 300,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, config.widthKey)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, config.widthKey, value)
                RDCore:RefreshDisplayByID(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Height',
            name = config.heightKey,
            min = 1,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, config.heightKey)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, config.heightKey, value)
                RDCore:RefreshDisplayByID(displayID)
            end,
        },
        {
            type = 'range',
            label = 'Spacing',
            name = config.spacingKey,
            min = -3,
            max = 100,
            step = 1,
            width = 20,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, config.spacingKey)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, config.spacingKey, value)
                RDCore:RefreshDisplayByID(displayID)
            end,
        },
        {
            type = 'dropdown',
            label = 'Layout',
            name = 'segmentLayout',
            getOptions = function()
                return {
                    horizontal = 'Horizontal',
                    vertical = 'Vertical',
                }
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'segmentLayout') or 'horizontal'
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'segmentLayout', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Reverse Order',
            name = 'segmentReverse',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'segmentReverse')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'segmentReverse', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'Bar Texture',
            name = config.textureKey,
            getOptions = function()
                local list = LSM:List('statusbar')
                local textureOptions = {}
                for _, texture in pairs(list) do
                    textureOptions[texture] = texture
                end
                return textureOptions
            end,
            isTextureDropdown = true,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, config.textureKey)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, config.textureKey, value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 40,
        },
        { type = 'spacer', width = 60 },
        {
            type = 'color-picker',
            label = 'Color',
            name = config.colorKey,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, config.colorKey)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, config.colorKey, value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 15,
        },
        {
            type = 'color-picker',
            label = 'Background Color',
            name = config.backgroundKey,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, config.backgroundKey)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, config.backgroundKey, value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'color-picker',
            label = 'Border Color',
            name = config.borderKey,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, config.borderKey)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, config.borderKey, value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'toggle',
            label = 'Use Fill Animation',
            name = 'fillAnimation',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'fillAnimation')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'fillAnimation', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
    }

    local colorExtras = {}
    if config.chargedColorKey then
        table.insert(colorExtras, {
            type = 'color-picker',
            label = config.chargedColorLabel or 'Charged Color',
            name = config.chargedColorKey,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, config.chargedColorKey)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, config.chargedColorKey, value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 20,
        })
    end
    if config.partialColorKey then
        table.insert(colorExtras, {
            type = 'color-picker',
            label = config.partialColorLabel or 'Color (Partial)',
            name = config.partialColorKey,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, config.partialColorKey)
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, config.partialColorKey, value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 20,
        })
    end
    if #colorExtras > 0 then
        for i, option in ipairs(options) do
            if option.name == config.backgroundKey then
                for j = #colorExtras, 1, -1 do
                    table.insert(options, i, colorExtras[j])
                end
                break
            end
        end
    end

    if config.individualColorCount then
        local colorFields = helpers:BuildIndividualColorOptions(
            displayID,
            config.prefix,
            config.individualColorCount,
            config.colorKey,
            config.colorsKey or (config.prefix .. 'Colors'),
            RDCore
        )
        for _, field in ipairs(colorFields) do
            table.insert(options, field)
        end
    end

    return options
end

function segmentBase:SetSegmentValues(activeFrames, count, chargedPoints, db, config)
    local interpolation = helpers:GetInterpolation(db.fillAnimation or db.smoothFill)
    local maxCount = #activeFrames
    local isAtCap = count >= maxCount and maxCount > 0

    for _, segment in ipairs(activeFrames) do
        local value = segment.index <= count and 1 or 0
        local isCharged = helpers:IsChargedSegment(segment.index, chargedPoints)
        local color = helpers:GetSegmentColor(db, segment.index, config.colorKey,
            config.colorsKey or (config.prefix .. 'Colors'), config.capColorKey, value == 1 and isAtCap)
        if isCharged and db.chargedColor then
            color = db.chargedColor
        end
        if color then
            segment.StatusBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
        end
        if segment.StatusBar:GetValue() ~= value then
            segment.StatusBar:SetValue(value, interpolation)
        end
    end
end
