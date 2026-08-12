---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

local healthPrediction = EXUI:GetModule('uf-element-healthprediction')

healthPrediction.Create = function(self, frame)
    local health = frame.Health

    local damageAbsorb = CreateFrame('StatusBar', '$parent_DamageAbsorb', health)
    damageAbsorb:SetPoint('TOP')
    damageAbsorb:SetPoint('BOTTOM')
    damageAbsorb:SetPoint('LEFT', health:GetStatusBarTexture(), 'RIGHT')
    damageAbsorb:SetWidth(200)
    damageAbsorb:SetFrameLevel(health:GetFrameLevel() + 1)
    damageAbsorb:SetMinMaxValues(0, 1)
    damageAbsorb:SetValue(0)

    local overDamageAbsorbIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    overDamageAbsorbIndicator:SetPoint('TOP')
    overDamageAbsorbIndicator:SetPoint('BOTTOM')
    overDamageAbsorbIndicator:SetPoint('LEFT', health, 'RIGHT', -4, 0)
    overDamageAbsorbIndicator:SetWidth(10)
    overDamageAbsorbIndicator:SetAlpha(0)

    local healAbsorb = CreateFrame('StatusBar', '$parent_HealAbsorb', health)
    healAbsorb:SetPoint('TOP')
    healAbsorb:SetPoint('BOTTOM')
    healAbsorb:SetPoint('RIGHT', health:GetStatusBarTexture())
    healAbsorb:SetWidth(200)
    healAbsorb:SetReverseFill(true)
    healAbsorb:SetFrameLevel(health:GetFrameLevel() + 1)
    healAbsorb:SetMinMaxValues(0, 1)
    healAbsorb:SetValue(0)

    local overHealAbsorbIndicator = frame.ElementFrame:CreateTexture(nil, 'OVERLAY')
    overHealAbsorbIndicator:SetPoint('TOP')
    overHealAbsorbIndicator:SetPoint('BOTTOM')
    overHealAbsorbIndicator:SetPoint('RIGHT', health, 'LEFT')
    overHealAbsorbIndicator:SetWidth(10)
    overHealAbsorbIndicator:SetAlpha(0)

    health.DamageAbsorb = damageAbsorb
    health.OverDamageAbsorbIndicator = overDamageAbsorbIndicator
    health.HealAbsorb = healAbsorb
    health.OverHealAbsorbIndicator = overHealAbsorbIndicator

    return {
        DamageAbsorbOriginal = damageAbsorb,
        OverDamageAbsorbIndicatorOriginal = overDamageAbsorbIndicator,
        HealAbsorbOriginal = healAbsorb,
        OverHealAbsorbIndicatorOriginal = overHealAbsorbIndicator,
    }
end

local function setWidget(health, key, original, enabled)
    if enabled then
        if not health[key] then
            health[key] = original
        end
        health[key]:Show()
    elseif health[key] then
        health[key]:Hide()
        health[key] = nil
    end
end

healthPrediction.Update = function(self, frame)
    local generalDB = frame.generalDB
    local db = frame.db
    local health = frame.Health
    local originals = frame.HealthPrediction

    local dmgAbsorbShowAt = db.damageAbsorbShowAt or 'AS_EXTENSION'
    local dmgAbsorbEnable = db.damageAbsorbEnable == nil or db.damageAbsorbEnable
    local dmgAbsorbShowOverIndicator = db.damageAbsorbShowOverIndicator == nil or db.damageAbsorbShowOverIndicator
    local healAbsorbEnable = db.healAbsorbEnable == nil or db.healAbsorbEnable
    local healAbsorbShowOverIndicator = db.healAbsorbShowOverIndicator == nil or db.healAbsorbShowOverIndicator

    setWidget(health, 'DamageAbsorb', originals.DamageAbsorbOriginal, dmgAbsorbEnable)
    setWidget(
        health,
        'OverDamageAbsorbIndicator',
        originals.OverDamageAbsorbIndicatorOriginal,
        dmgAbsorbEnable and dmgAbsorbShowOverIndicator and dmgAbsorbShowAt == 'AS_EXTENSION'
    )
    setWidget(health, 'HealAbsorb', originals.HealAbsorbOriginal, healAbsorbEnable)
    setWidget(
        health,
        'OverHealAbsorbIndicator',
        originals.OverHealAbsorbIndicatorOriginal,
        healAbsorbEnable and healAbsorbShowOverIndicator
    )

    if dmgAbsorbEnable and health.DamageAbsorb then
        local damageAbsorbTexture = db.overrideDamageAbsorbTexture ~= '' and db.overrideDamageAbsorbTexture
            or generalDB.damageAbsorbTexture
        health.DamageAbsorb:SetStatusBarTexture(LSM:Fetch('statusbar', damageAbsorbTexture))
        health.DamageAbsorb:SetWidth(db.sizeWidth)
        if db.useCustomHealthAbsorbsColor then
            health.DamageAbsorb:SetStatusBarColor(
                db.damageAbsorbColor.r,
                db.damageAbsorbColor.g,
                db.damageAbsorbColor.b,
                db.damageAbsorbColor.a
            )
        else
            health.DamageAbsorb:SetStatusBarColor(
                generalDB.damageAbsorbColor.r,
                generalDB.damageAbsorbColor.g,
                generalDB.damageAbsorbColor.b,
                generalDB.damageAbsorbColor.a
            )
        end

        health.DamageAbsorb:ClearAllPoints()
        health.DamageAbsorb:SetPoint('TOP')
        health.DamageAbsorb:SetPoint('BOTTOM')
        health.DamageAbsorb:SetFillStyle(Enum.StatusBarFillStyle.Standard)
        if dmgAbsorbShowAt == 'AS_EXTENSION' then
            health.DamageAbsorb:SetPoint('LEFT', health:GetStatusBarTexture(), 'RIGHT')
            health.damageAbsorbClampMode = Enum.UnitDamageAbsorbClampMode.MissingHealth
        elseif dmgAbsorbShowAt == 'AT_END' then
            health.DamageAbsorb:SetPoint('RIGHT', health:GetStatusBarTexture(), 'RIGHT')
            health.damageAbsorbClampMode = Enum.UnitDamageAbsorbClampMode.MaximumHealth
            health.DamageAbsorb:SetFillStyle(Enum.StatusBarFillStyle.Reverse)
        elseif dmgAbsorbShowAt == 'AT_START' then
            health.DamageAbsorb:SetPoint('LEFT', health:GetStatusBarTexture(), 'LEFT')
            health.damageAbsorbClampMode = Enum.UnitDamageAbsorbClampMode.MaximumHealth
        end

        if health.values then
            health.values:SetDamageAbsorbClampMode(health.damageAbsorbClampMode)
        end
    end

    if healAbsorbEnable and health.HealAbsorb then
        local healAbsorbTexture = db.overrideHealAbsorbTexture ~= '' and db.overrideHealAbsorbTexture
            or generalDB.healAbsorbTexture
        health.HealAbsorb:SetStatusBarTexture(LSM:Fetch('statusbar', healAbsorbTexture))
        health.HealAbsorb:SetWidth(db.sizeWidth)
        if db.useCustomHealthAbsorbsColor then
            health.HealAbsorb:SetStatusBarColor(
                db.healAbsorbColor.r,
                db.healAbsorbColor.g,
                db.healAbsorbColor.b,
                db.healAbsorbColor.a
            )
        else
            health.HealAbsorb:SetStatusBarColor(
                generalDB.healAbsorbColor.r,
                generalDB.healAbsorbColor.g,
                generalDB.healAbsorbColor.b,
                generalDB.healAbsorbColor.a
            )
        end
    end

    if health.ForceUpdate then
        health:ForceUpdate()
    end
end
