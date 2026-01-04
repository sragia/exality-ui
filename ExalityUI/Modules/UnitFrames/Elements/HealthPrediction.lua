---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

local healthPrediction = EXUI:GetModule('uf-element-healthprediction')

-- Mandatory to be created AFTER Health element
healthPrediction.Create = function(self, frame)
    local damageAbsorb = CreateFrame('StatusBar', '$parent_DamageAbsorb', frame.Health)
    damageAbsorb:SetPoint('TOP')
    damageAbsorb:SetPoint('BOTTOM')
    damageAbsorb:SetPoint('LEFT', frame.Health:GetStatusBarTexture(), 'RIGHT')
    damageAbsorb:SetWidth(200)

    local overDamageAbsorbIndicator = frame.ElementFrame:CreateTexture(nil, "OVERLAY")
    overDamageAbsorbIndicator:SetPoint('TOP')
    overDamageAbsorbIndicator:SetPoint('BOTTOM')
    overDamageAbsorbIndicator:SetPoint('LEFT', frame.Health, 'RIGHT', -4, 0)
    overDamageAbsorbIndicator:SetWidth(10)

    local healAbsorb = CreateFrame('StatusBar', '$parent_HealAbsorb', frame.Health)
    healAbsorb:SetPoint('TOP')
    healAbsorb:SetPoint('BOTTOM')
    healAbsorb:SetPoint('RIGHT', frame.Health:GetStatusBarTexture())
    healAbsorb:SetWidth(200)
    healAbsorb:SetReverseFill(true)

    local overHealAbsorbIndicator = frame.ElementFrame:CreateTexture(nil, "OVERLAY")
    overHealAbsorbIndicator:SetPoint('TOP')
    overHealAbsorbIndicator:SetPoint('BOTTOM')
    overHealAbsorbIndicator:SetPoint('RIGHT', frame.Health, 'LEFT')
    overHealAbsorbIndicator:SetWidth(10)


    return {
        damageAbsorb = damageAbsorb,
        overDamageAbsorbIndicator = overDamageAbsorbIndicator,
        healAbsorb = healAbsorb,
        overHealAbsorbIndicator = overHealAbsorbIndicator
    }
end

healthPrediction.Update = function(self, frame)
    local generalDB = frame.generalDB
    local db = frame.db
    local healthPredictionFrame = frame.HealthPrediction

    -- Damage Absorb
    healthPredictionFrame.damageAbsorb:SetStatusBarTexture(LSM:Fetch('statusbar', generalDB.statusBarTexture))
    healthPredictionFrame.damageAbsorb:SetWidth(db.sizeWidth)
    healthPredictionFrame.damageAbsorb:SetStatusBarColor(
        generalDB.damageAbsorbColor.r,
        generalDB.damageAbsorbColor.g,
        generalDB.damageAbsorbColor.b,
        generalDB.damageAbsorbColor.a
    )

    -- Heal Absorb
    healthPredictionFrame.healAbsorb:SetStatusBarTexture(LSM:Fetch('statusbar', generalDB.statusBarTexture))
    healthPredictionFrame.healAbsorb:SetWidth(db.sizeWidth)
    healthPredictionFrame.healAbsorb:SetStatusBarColor(
        generalDB.healAbsorbColor.r,
        generalDB.healAbsorbColor.g,
        generalDB.healAbsorbColor.b,
        generalDB.healAbsorbColor.a
    )
end
