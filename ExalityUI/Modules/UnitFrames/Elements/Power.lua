---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

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
    if (frame.unit ~= 'party') then
        if (not db.powerEnable) then
            core:DisableElementForFrame(frame, 'Power')
            return
        end
        core:EnableElementForFrame(frame, 'Power')
    end
    powerBar:SetPoint('BOTTOMLEFT')
    powerBar:SetPoint('BOTTOMRIGHT')
    powerBar:SetHeight(db.powerHeight)
    powerBar:SetStatusBarTexture(LSM:Fetch('statusbar', generalDB.statusBarTexture))

    powerBar:SetFrameLevel(frame.Health:GetFrameLevel() + 5)
end
