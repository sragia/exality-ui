---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

local textElement = EXUI:GetModule('resource-displays-elements-text')

textElement.JUSTIFY_MAP = {
    LEFT = 'LEFT',
    CENTER = 'CENTER',
    RIGHT = 'RIGHT',
}

textElement.Create = function(self, frame)
    local text = frame.ElementFrame:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    return text
end

textElement.Update = function(self, frame)
    local db = frame.db
    local text = frame.Text
    if not text then
        return
    end

    if not db.showText then
        text:Hide()
        return
    end

    text:Show()

    if db.font then
        local font = LSM:Fetch('font', db.font)
        text:SetFont(font, db.fontSize, db.fontFlag)
    end

    if db.textColor then
        text:SetVertexColor(db.textColor.r, db.textColor.g, db.textColor.b, db.textColor.a)
    end

    local justify = db.textJustify or 'CENTER'
    text:SetJustifyH(justify)

    text:ClearAllPoints()
    text:SetPoint(db.textAnchorPoint, frame.ElementFrame, db.textRelativeAnchorPoint, db.textXOff, db.textYOff)
end

textElement.SetPowerText = function(self, frame, current, max)
    local db = frame.db
    local text = frame.Text
    if not text or not db.showText then
        return
    end
    text:SetText(helpers:FormatPowerText(db.textFormat, current, max))
    text:Show()
end

textElement.GetOptions = function(self, displayID)
    return {
        {
            type = 'title',
            label = 'Text',
            size = 14,
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Show',
            name = 'showText',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'showText', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
        {
            type = 'dropdown',
            label = 'Format',
            name = 'textFormat',
            getOptions = function()
                return {
                    current = 'Current',
                    ['current/max'] = 'Current / Max',
                }
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            currentValue = function()
                local format = RDCore:GetValueForDisplay(displayID, 'textFormat') or 'current'
                if format ~= 'current/max' then
                    return 'current'
                end
                return format
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textFormat', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 50,
        },
        {
            type = 'dropdown',
            label = 'Alignment',
            name = 'textJustify',
            getOptions = function()
                return {
                    LEFT = 'Left',
                    CENTER = 'Center',
                    RIGHT = 'Right',
                }
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textJustify') or 'CENTER'
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textJustify', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 50,
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = 'font',
            getOptions = function()
                local list = LSM:List('font')
                local options = {}
                for _, texture in pairs(list) do
                    options[texture] = texture
                end
                return options
            end,
            isFontDropdown = true,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'font')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'font', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'fontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'fontFlag')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'fontFlag', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25,
        },
        {
            type = 'range',
            label = 'Size',
            name = 'fontSize',
            min = 1,
            max = 40,
            step = 1,
            width = 20,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'fontSize')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'fontSize', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
        },
        {
            type = 'color-picker',
            label = 'Text Color',
            name = 'textColor',
            align = 'BOTTOM',
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16,
        },
        {
            type = 'spacer',
            width = 4,
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'textAnchorPoint',
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textAnchorPoint')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textAnchorPoint', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 23,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'textRelativeAnchorPoint',
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textRelativeAnchorPoint')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textRelativeAnchorPoint', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 23,
        },
        {
            type = 'spacer',
            width = 54,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'textXOff',
            min = -1000,
            max = 1000,
            step = 1,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textXOff')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textXOff', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 23,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'textYOff',
            min = -1000,
            max = 1000,
            step = 1,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'showText')
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textYOff')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textYOff', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 23,
        },
    }
end
