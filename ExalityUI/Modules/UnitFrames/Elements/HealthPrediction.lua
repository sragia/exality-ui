---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local LSM = LibStub('LibSharedMedia-3.0')

local healthPrediction = EXUI:GetModule('uf-element-healthprediction')

-- Mandatory to be created AFTER Health element
healthPrediction.Create = function(self, frame)
    local damageAbsorb = CreateFrame('StatusBar', '$parent_DamageAbsorb', frame)
    damageAbsorb:SetPoint('TOP')
    damageAbsorb:SetPoint('BOTTOM')
    damageAbsorb:SetPoint('LEFT', frame.Health:GetStatusBarTexture(), 'RIGHT')
    damageAbsorb:SetWidth(200)
    damageAbsorb:SetFrameLevel(frame.Health:GetFrameLevel() + 1)

    local overDamageAbsorbIndicator = frame.ElementFrame:CreateTexture(nil, "OVERLAY")
    overDamageAbsorbIndicator:SetPoint('TOP')
    overDamageAbsorbIndicator:SetPoint('BOTTOM')
    overDamageAbsorbIndicator:SetPoint('LEFT', frame.Health, 'RIGHT', -4, 0)
    overDamageAbsorbIndicator:SetWidth(10)

    local healAbsorb = CreateFrame('StatusBar', '$parent_HealAbsorb', frame)
    healAbsorb:SetPoint('TOP')
    healAbsorb:SetPoint('BOTTOM')
    healAbsorb:SetPoint('RIGHT', frame.Health:GetStatusBarTexture())
    healAbsorb:SetWidth(200)
    healAbsorb:SetReverseFill(true)
    healAbsorb:SetFrameLevel(frame.Health:GetFrameLevel() + 1)

    local overHealAbsorbIndicator = frame.ElementFrame:CreateTexture(nil, "OVERLAY")
    overHealAbsorbIndicator:SetPoint('TOP')
    overHealAbsorbIndicator:SetPoint('BOTTOM')
    overHealAbsorbIndicator:SetPoint('RIGHT', frame.Health, 'LEFT')
    overHealAbsorbIndicator:SetWidth(10)


    return {
        damageAbsorb = damageAbsorb,
        damageAbsorbOriginal = damageAbsorb,
        overDamageAbsorbIndicator = overDamageAbsorbIndicator,
        overDamageAbsorbIndicatorOriginal = overDamageAbsorbIndicator,
        healAbsorb = healAbsorb,
        healAbsorbOriginal = healAbsorb,
        overHealAbsorbIndicator = overHealAbsorbIndicator,
        overHealAbsorbIndicatorOriginal = overHealAbsorbIndicator,
    }
end

healthPrediction.Update = function(self, frame)
    local generalDB = frame.generalDB
    local db = frame.db
    local HealthPrediction = frame.HealthPrediction

    local dmgAbsorbShowAt = db.damageAbsorbShowAt or 'AS_EXTENSION'
    local dmgAbsorbEnable = db.damageAbsorbEnable == nil or db.damageAbsorbEnable
    local dmgAbsorbShowOverIndicator = db.damageAbsorbShowOverIndicator == nil or db.damageAbsorbShowOverIndicator
    local healAbsorbEnable = db.healAbsorbEnable == nil or db.healAbsorbEnable
    local healAbsorbShowOverIndicator = db.healAbsorbShowOverIndicator == nil or db.healAbsorbShowOverIndicator

    if (dmgAbsorbEnable) then
        if (not HealthPrediction.damageAbsorb) then
            HealthPrediction.damageAbsorb = HealthPrediction.damageAbsorbOriginal
            HealthPrediction.damageAbsorb:Show()
        end
        if (not HealthPrediction.overDamageAbsorbIndicator) then
            HealthPrediction.overDamageAbsorbIndicator = HealthPrediction.overDamageAbsorbIndicatorOriginal
            HealthPrediction.overDamageAbsorbIndicator:Show()
        end
    else
        HealthPrediction.damageAbsorb:Hide()
        HealthPrediction.damageAbsorb = nil
        HealthPrediction.overDamageAbsorbIndicator:Hide()
        HealthPrediction.overDamageAbsorbIndicator = nil
    end

    if (healAbsorbEnable) then
        if (not HealthPrediction.healAbsorb) then
            HealthPrediction.healAbsorb = HealthPrediction.healAbsorbOriginal
            HealthPrediction.healAbsorb:Show()
        end
        if (not HealthPrediction.overHealAbsorbIndicator) then
            HealthPrediction.overHealAbsorbIndicator = HealthPrediction.overHealAbsorbIndicatorOriginal
            HealthPrediction.overHealAbsorbIndicator:Show()
        end
    else
        HealthPrediction.healAbsorb:Hide()
        HealthPrediction.healAbsorb = nil
        HealthPrediction.overHealAbsorbIndicator:Hide()
        HealthPrediction.overHealAbsorbIndicator = nil
    end

    if (dmgAbsorbShowOverIndicator and dmgAbsorbShowAt == 'AS_EXTENSION') then
        if (not HealthPrediction.overDamageAbsorbIndicator) then
            HealthPrediction.overDamageAbsorbIndicator = HealthPrediction.overDamageAbsorbIndicatorOriginal
            HealthPrediction.overDamageAbsorbIndicator:Show()
        end
    else
        HealthPrediction.overDamageAbsorbIndicator:Hide()
        HealthPrediction.overDamageAbsorbIndicator = nil
    end

    if (healAbsorbShowOverIndicator) then
        if (not HealthPrediction.overHealAbsorbIndicator) then
            HealthPrediction.overHealAbsorbIndicator = HealthPrediction.overHealAbsorbIndicatorOriginal
            HealthPrediction.overHealAbsorbIndicator:Show()
        end
    else
        HealthPrediction.overHealAbsorbIndicator:Hide()
        HealthPrediction.overHealAbsorbIndicator = nil
    end

    -- Damage Absorb
    if (dmgAbsorbEnable) then
        local damageAbsorbTexture = db.overrideDamageAbsorbTexture ~= '' and db.overrideDamageAbsorbTexture or
            generalDB.damageAbsorbTexture
        HealthPrediction.damageAbsorb:SetStatusBarTexture(LSM:Fetch('statusbar', damageAbsorbTexture))
        HealthPrediction.damageAbsorb:SetWidth(db.sizeWidth)
        if (db.useCustomHealthAbsorbsColor) then
            HealthPrediction.damageAbsorb:SetStatusBarColor(
                db.damageAbsorbColor.r,
                db.damageAbsorbColor.g,
                db.damageAbsorbColor.b,
                db.damageAbsorbColor.a
            )
        else
            HealthPrediction.damageAbsorb:SetStatusBarColor(
                generalDB.damageAbsorbColor.r,
                generalDB.damageAbsorbColor.g,
                generalDB.damageAbsorbColor.b,
                generalDB.damageAbsorbColor.a
            )
        end

        HealthPrediction.damageAbsorb:ClearAllPoints()
        HealthPrediction.damageAbsorb:SetPoint('TOP')
        HealthPrediction.damageAbsorb:SetPoint('BOTTOM')
        HealthPrediction.damageAbsorb:SetFillStyle(Enum.StatusBarFillStyle.Standard)
        if (dmgAbsorbShowAt == 'AS_EXTENSION') then
            HealthPrediction.damageAbsorb:SetPoint('LEFT', frame.Health:GetStatusBarTexture(), 'RIGHT')
            HealthPrediction.damageAbsorbClampMode = Enum.UnitDamageAbsorbClampMode.MissingHealth
        elseif (dmgAbsorbShowAt == 'AT_END') then
            HealthPrediction.damageAbsorb:SetPoint('RIGHT', frame.Health:GetStatusBarTexture(), 'RIGHT')
            HealthPrediction.damageAbsorbClampMode = Enum.UnitDamageAbsorbClampMode.MaximumHealth
            HealthPrediction.damageAbsorb:SetFillStyle(Enum.StatusBarFillStyle.Reverse)
        elseif (dmgAbsorbShowAt == 'AT_START') then
            HealthPrediction.damageAbsorb:SetPoint('LEFT', frame.Health:GetStatusBarTexture(), 'LEFT')
            HealthPrediction.damageAbsorbClampMode = Enum.UnitDamageAbsorbClampMode.MaximumHealth
        end

        if (HealthPrediction.values) then
            HealthPrediction.values:SetDamageAbsorbClampMode(HealthPrediction.damageAbsorbClampMode)
        end
    end

    -- Heal Absorb
    if (healAbsorbEnable) then
        local healAbsorbTexture = db.overrideHealAbsorbTexture ~= '' and db.overrideHealAbsorbTexture or
            generalDB.healAbsorbTexture
        HealthPrediction.healAbsorb:SetStatusBarTexture(LSM:Fetch('statusbar', healAbsorbTexture))
        HealthPrediction.healAbsorb:SetWidth(db.sizeWidth)
        if (db.useCustomHealthAbsorbsColor) then
            HealthPrediction.healAbsorb:SetStatusBarColor(
                db.healAbsorbColor.r,
                db.healAbsorbColor.g,
                db.healAbsorbColor.b,
                db.healAbsorbColor.a
            )
        else
            HealthPrediction.healAbsorb:SetStatusBarColor(
                generalDB.healAbsorbColor.r,
                generalDB.healAbsorbColor.g,
                generalDB.healAbsorbColor.b,
                generalDB.healAbsorbColor.a
            )
        end
    end
end
