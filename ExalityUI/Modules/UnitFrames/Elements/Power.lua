---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')


local power = EXUI:GetModule('uf-element-power')

power.Create = function(self, frame)
    local power = CreateFrame('StatusBar', '$parent_Power', frame)
    power:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    -- Background
    local background = power:CreateTexture(nil, 'BACKGROUND')
    background:SetTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    background:SetVertexColor(0, 0, 0, 1)
    background:SetAllPoints()
    background.multiplier = 0.2
    power.bg = background
    power.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut

    -- Options
    power.colorPower = true

    return power
end

power.Update = function(self, frame)
    local db = frame.db
    local generalDB = frame.generalDB
    local powerBar = frame.Power
    if (not db.powerEnable) then
        frame:DisableElement('Power')
        return
    end
    frame:EnableElement('Power')
    powerBar:SetHeight(db.powerHeight)
    powerBar:SetStatusBarTexture(LSM:Fetch('statusbar', generalDB.statusBarTexture))
end
