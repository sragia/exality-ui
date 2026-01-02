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

health.PostUpdateColor = function(self, unit, r, g, b)
    local baseFrame = self:GetParent()
    local generalDB = baseFrame.generalDB
    if (generalDB.useCustomHealthColor) then
        self:SetStatusBarColor(generalDB.customHealthColor.r, generalDB.customHealthColor.g,
            generalDB.customHealthColor.b)
    end

    if (generalDB.useCustomBackdropColor) then
        self.bg:SetVertexColor(generalDB.customBackdropColor.r, generalDB.customBackdropColor.g,
            generalDB.customBackdropColor.b)
    elseif (generalDB.useClassColoredBackdrop) then
        self.bg:SetVertexColor(r, g, b)
    end
end

health.Update = function(self, frame)
    local generalDB = frame.generalDB
    local health = frame.Health
    health.colorDisconnected = true
    health.colorTapping = true
    health.colorClass = true
    health.colorReaction = true

    health.bg.multiplier = generalDB.useClassColoredBackdrop and 1 or 0.2

    health:SetStatusBarTexture(LSM:Fetch('statusbar', generalDB.statusBarTexture))
end
