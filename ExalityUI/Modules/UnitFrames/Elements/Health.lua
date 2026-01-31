---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')


local health = EXUI:GetModule('uf-element-health')

health.Create = function(self, frame)
    local health = CreateFrame('StatusBar', '$parent_Health', frame, 'BackdropTemplate')
    health:SetAllPoints()
    health:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    health.PostUpdateColor = self.PostUpdateColor

    -- Background
    local background = health:CreateTexture(nil, 'BACKGROUND')
    background:SetTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    background:SetAllPoints()
    background.multiplier = 0.2
    health.bg = background
    health.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut

    return health
end

health.PostUpdateColor = function(self, unit, color)
    local baseFrame = self:GetParent()
    local generalDB = baseFrame.generalDB
    local db = baseFrame.db
    local isOverriden = db.overrideHealthColor
    local useCustomColor = generalDB.useCustomHealthColor
    local customColor = generalDB.customHealthColor
    if (isOverriden) then
        useCustomColor = db.useCustomHealthColor
        customColor = db.customHealthColor
    end
    if (useCustomColor) then
        if (UnitIsConnected(unit)) then
            self:SetStatusBarColor(customColor.r, customColor.g, customColor.b)
        else
            self:SetStatusBarColor(color:GetRGB())
        end
    end
    local useCustomBackdropColor = generalDB.useCustomBackdropColor
    local customBackdropColor = generalDB.customBackdropColor
    local useClassColoredBackdrop = generalDB.useClassColoredBackdrop
    if (isOverriden) then
        useCustomBackdropColor = db.useCustomBackdropColor
        customBackdropColor = db.customBackdropColor
        useClassColoredBackdrop = db.useClassColoredBackdrop
    end
    if (useCustomBackdropColor) then
        self.bg:SetVertexColor(customBackdropColor.r, customBackdropColor.g, customBackdropColor.b)
    elseif (useClassColoredBackdrop and color) then
        self.bg:SetVertexColor(color:GetRGB())
    end
end

health.Update = function(self, frame)
    local db = frame.db
    local generalDB = frame.generalDB
    local health = frame.Health
    health.colorDisconnected = true
    health.colorTapping = true
    health.colorClass = true
    health.colorReaction = true

    health.bg.multiplier = generalDB.useClassColoredBackdrop and 1 or 0.2
    local statusBarTexture = db.overrideStatusBarTexture ~= '' and db.overrideStatusBarTexture or
        generalDB.statusBarTexture

    health:SetStatusBarTexture(LSM:Fetch('statusbar', statusBarTexture))
end
