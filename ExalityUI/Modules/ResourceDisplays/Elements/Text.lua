---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

local textElement = EXUI:GetModule('resource-displays-elements-text')

textElement.Create = function(self, frame)
    local text = frame.ElementFrame:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')

    return text
end

textElement.Update = function(self, frame)
    local db = frame.db
    local text = frame.Text

    if (not db.showText) then
        text:Hide()
        return
    end

    text:Show()

    if (db.font) then
        local font = LSM:Fetch('font', db.font)
        text:SetFont(font, db.fontSize, db.fontFlag)
    end

    if (db.textColor) then
        text:SetVertexColor(db.textColor.r, db.textColor.g, db.textColor.b, db.textColor.a)
    end

    text:ClearAllPoints()
    text:SetPoint(db.textAnchorPoint, frame.ElementFrame, db.textRelativeAnchorPoint, db.textXOff, db.textYOff)
end

textElement.GetOptions = function(self, displayID)
    return {
        {
            type = 'title',
            label = 'Text',
            size = 14,
            width = 100
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
            width = 100
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
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'font')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'font', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'fontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'fontFlag')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'fontFlag', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 25
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
                return RDCore:GetValueForDisplay(displayID, 'fontSize')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'fontSize', value)
                RDCore:RefreshDisplayByID(displayID)
            end
        },
        {
            type = 'color-picker',
            label = 'Text Color',
            name = 'textColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        },
        {
            type = 'spacer',
            width = 4
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            name = 'textAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textAnchorPoint')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textAnchorPoint', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 22
        },
        {
            type = 'dropdown',
            label = 'Relative Anchor Point',
            name = 'textRelativeAnchorPoint',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textRelativeAnchorPoint')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textRelativeAnchorPoint', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 22
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'textXOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textXOff')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textXOff', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 20
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'textYOff',
            min = -1000,
            max = 1000,
            step = 1,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'textYOff')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'textYOff', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 20
        }
    }
end
