---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

local statusBar = EXUI:GetModule('resource-displays-elements-status-bar')

statusBar.Create = function(self, frame)
    local statusBar = CreateFrame('StatusBar', nil, frame)

    statusBar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
    statusBar:SetMinMaxValues(0, 100)
    statusBar:SetValue(0)
    EXUI:SetPoint(statusBar, 'TOPLEFT', 1, -1)
    EXUI:SetPoint(statusBar, 'BOTTOMRIGHT', -1, 1)


    return statusBar
end

statusBar.Update = function(self, frame)
    local db = frame.db
    local statusBar = frame.StatusBar

    if (db.barTexture) then
        local texture = LSM:Fetch('statusbar', db.barTexture)
        statusBar:SetStatusBarTexture(texture)
    end
    if (db.barColor) then
        statusBar:SetStatusBarColor(db.barColor.r, db.barColor.g, db.barColor.b, db.barColor.a)
    end
end

statusBar.GetOptions = function(self, displayID)
    return {
        {
            type = 'title',
            label = 'Bar Style',
            size = 14,
            width = 100
        },
        {
            type = 'dropdown',
            label = 'Bar Texture',
            name = 'barTexture',
            getOptions = function()
                local list = LSM:List('statusbar')
                local options = {}
                for _, texture in pairs(list) do
                    options[texture] = texture
                end
                return options
            end,
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'barTexture')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'barTexture', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 40
        },
        {
            type = 'color-picker',
            label = 'Bar Color',
            name = 'barColor',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'barColor')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'barColor', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 16
        }
    }
end
