---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUIResourceDisplaysCore
local RDCore = EXUI:GetModule('resource-displays-core')

local statusBar = EXUI:GetModule('resource-displays-elements-status-bar')

statusBar.ApplyInsets = function(self, statusBarFrame, parent)
    local inset = EXUI:ScalePixels(1, parent)
    statusBarFrame:ClearAllPoints()
    statusBarFrame:SetPoint('TOPLEFT', parent, 'TOPLEFT', inset, -inset)
    -- Bottom border is nudged down 1px for pixel alignment, so no bottom inset.
    statusBarFrame:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', -inset, 0)
end

statusBar.Create = function(self, frame)
    local bar = CreateFrame('StatusBar', nil, frame)

    bar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    self:ApplyInsets(bar, frame)

    return bar
end

statusBar.Update = function(self, frame)
    local db = frame.db
    local bar = frame.StatusBar

    self:ApplyInsets(bar, frame)

    if (db.barTexture) then
        local texture = LSM:Fetch('statusbar', db.barTexture)
        bar:SetStatusBarTexture(texture)
    end
    if (db.barColor and not self.NOCOLOR) then
        bar:SetStatusBarColor(db.barColor.r, db.barColor.g, db.barColor.b, db.barColor.a)
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
            isTextureDropdown = true,
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
