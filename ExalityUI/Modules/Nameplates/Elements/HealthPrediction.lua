---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUINameplatesElementHealthPrediction
local healthPrediction = EXUI:GetModule('np-element-health-prediction')

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
    overDamageAbsorbIndicator:SetTexture([[Interface\RaidFrame\Shield-Overshield]])
    overDamageAbsorbIndicator:SetBlendMode('ADD')
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
    overHealAbsorbIndicator:SetTexture([[Interface\RaidFrame\Absorb-Overabsorb]])
    overHealAbsorbIndicator:SetBlendMode('ADD')
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
    health[key] = original
    if enabled then
        original:Show()
    else
        original:Hide()
    end
end

healthPrediction.Update = function(self, frame)
    local db = frame.db
    local health = frame.Health
    local originals = frame.HealthPrediction
    if not health or not originals then
        return
    end

    local dmgAbsorbShowAt = db.damageAbsorbShowAt or 'AS_EXTENSION'
    local dmgAbsorbEnable = not frame.isFriendly and (db.damageAbsorbEnable ~= false)
    local dmgAbsorbShowOverIndicator = db.damageAbsorbShowOverIndicator ~= false
    local healAbsorbEnable = not frame.isFriendly and (db.healAbsorbEnable ~= false)
    local healAbsorbShowOverIndicator = db.healAbsorbShowOverIndicator ~= false

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
        health.DamageAbsorb:SetStatusBarTexture(LSM:Fetch('statusbar', db.damageAbsorbTexture or 'ExalityUI Status Bar'))
        EXUI:SetWidth(health.DamageAbsorb, db.sizeWidth or 140)
        local c = db.damageAbsorbColor or { r = 0, g = 133 / 255, b = 163 / 255, a = 1 }
        health.DamageAbsorb:SetStatusBarColor(c.r, c.g, c.b, c.a or 1)
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
        else
            health.DamageAbsorb:SetPoint('LEFT', health:GetStatusBarTexture(), 'LEFT')
            health.damageAbsorbClampMode = Enum.UnitDamageAbsorbClampMode.MaximumHealth
        end
        if health.values then
            health.values:SetDamageAbsorbClampMode(health.damageAbsorbClampMode)
        end
    end

    if healAbsorbEnable and health.HealAbsorb then
        health.HealAbsorb:SetStatusBarTexture(LSM:Fetch('statusbar', db.healAbsorbTexture or 'ExalityUI Status Bar'))
        EXUI:SetWidth(health.HealAbsorb, db.sizeWidth or 140)
        local c = db.healAbsorbColor or { r = 100 / 255, g = 100 / 255, b = 100 / 255, a = 0.8 }
        health.HealAbsorb:SetStatusBarColor(c.r, c.g, c.b, c.a or 1)
    end

    if health.ForceUpdate then
        health:ForceUpdate()
    end
end
