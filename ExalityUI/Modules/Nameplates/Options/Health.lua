---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesOptionsHelpers
local helpers = EXUI:GetModule('np-options-helpers')

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUINameplatesOptionsHealth
local health = EXUI:GetModule('np-options-health')

local function curveColor(label, name, breakpoint)
    return {
        type = 'color-picker',
        label = label,
        name = name,
        width = 20,
        depends = function()
            return npCore:GetValue('healthColorMode') == 'curve'
        end,
        currentValue = function()
            local curve = npCore:GetValue('healthCurve')
            return curve and curve[breakpoint]
        end,
        onChange = function(value)
            local curve = npCore:GetValue('healthCurve') or {}
            curve[breakpoint] = value
            helpers.Set('healthCurve', curve)
            npCore:UpdateHealthCurve()
        end,
    }
end

function health:GetMenu()
    return {
        {
            id = 'base',
            name = 'Base Color',
            options = function()
                return {
                    helpers.Dropdown('Color Mode', 'healthColorMode', function()
                        return {
                            custom = 'Custom',
                            reaction = 'Reaction',
                            curve = 'Health Curve',
                        }
                    end, 33),
                    helpers.Color('Custom Color', 'customHealthColor', 33),
                    helpers.Color('Backdrop', 'healthBackdropColor', 33),
                    curveColor('0%', 'healthCurve0', 0),
                    curveColor('25%', 'healthCurve025', 0.25),
                    curveColor('50%', 'healthCurve05', 0.5),
                    curveColor('75%', 'healthCurve075', 0.75),
                    curveColor('100%', 'healthCurve1', 1),
                }
            end,
        },
        {
            id = 'conditional',
            name = 'Colors',
            options = function()
                local function colorWhen(label, key, width, dependsKey)
                    local field = helpers.Color(label, key, width)
                    field.depends = function()
                        return helpers.Get(dependsKey)
                    end
                    return field
                end
                local playerColor = helpers.Color('Enemy Player Color', 'enemyPlayerColor', 50)
                playerColor.depends = function()
                    return helpers.Get('colorEnemyPlayer') and not helpers.Get('enemyPlayerUseClassColor')
                end
                local classColorToggle = helpers.Toggle('Use Class Color', 'enemyPlayerUseClassColor')
                classColorToggle.depends = function()
                    return helpers.Get('colorEnemyPlayer')
                end
                local classificationDepends = function()
                    return helpers.Get('colorClassification')
                end
                local elite = helpers.Color('Elite', 'classificationElite', 25)
                elite.depends = classificationDepends
                local rare = helpers.Color('Rare', 'classificationRare', 25)
                rare.depends = classificationDepends
                local rareElite = helpers.Color('Rare Elite', 'classificationRareElite', 25)
                rareElite.depends = classificationDepends
                local worldBoss = helpers.Color('World Boss', 'classificationWorldBoss', 25)
                worldBoss.depends = classificationDepends
                local minus = helpers.Color('Minus', 'classificationMinus', 25)
                minus.depends = classificationDepends
                local trivial = helpers.Color('Trivial', 'classificationTrivial', 25)
                trivial.depends = classificationDepends
                return {
                    { type = 'title', label = 'State', width = 100 },
                    helpers.Toggle('Color Tapped', 'colorTapped'),
                    colorWhen('Tapped Color', 'tappedColor', 50, 'colorTapped'),
                    helpers.Toggle('Color Quest', 'colorQuest'),
                    colorWhen('Quest Color', 'questColor', 50, 'colorQuest'),
                    helpers.Toggle('Color While Casting', 'colorCasting'),
                    colorWhen('Casting Color', 'castingColor', 50, 'colorCasting'),
                    { type = 'title', label = 'Combat', width = 100 },
                    helpers.Toggle('Color Threat', 'colorThreat'),
                    colorWhen('Have Aggro', 'threatHaveAggro', 25, 'colorThreat'),
                    colorWhen('No Aggro', 'threatNoAggro', 25, 'colorThreat'),
                    helpers.Toggle('Color Co-Tank Aggro', 'colorCoTank'),
                    colorWhen('Co-Tank Aggro', 'threatCoTank', 50, 'colorCoTank'),
                    { type = 'title', label = 'Units', width = 100 },
                    helpers.Toggle('Color Encounter Boss', 'colorEncounterBoss'),
                    colorWhen('Encounter Boss Color', 'encounterBossColor', 50, 'colorEncounterBoss'),
                    helpers.Toggle('Color Enemy Players', 'colorEnemyPlayer'),
                    classColorToggle,
                    playerColor,
                    helpers.Toggle('Color Pets', 'colorPet'),
                    colorWhen('Pet Color', 'petColor', 50, 'colorPet'),
                    helpers.Toggle('Color Mana Users', 'colorMana'),
                    colorWhen('Mana Color', 'manaUnitColor', 50, 'colorMana'),
                    { type = 'title', label = 'Rank', width = 100 },
                    helpers.Toggle('Color by Classification', 'colorClassification'),
                    elite,
                    rare,
                    rareElite,
                    worldBoss,
                    minus,
                    trivial,
                }
            end,
        },
        {
            id = 'absorbs',
            name = 'Absorbs',
            options = function()
                local damageEnable = function()
                    return helpers.Get('damageAbsorbEnable')
                end
                local healEnable = function()
                    return helpers.Get('healAbsorbEnable')
                end
                local showAt = helpers.Dropdown('Show Damage Absorb', 'damageAbsorbShowAt', function()
                    return {
                        AS_EXTENSION = 'As Extension of Health',
                        AT_END = 'At the End of the Health Bar',
                        AT_START = 'At the Start of the Health Bar',
                    }
                end, 50)
                showAt.depends = damageEnable
                local overDamage = helpers.Toggle('Show Over Damage Absorb Indicator', 'damageAbsorbShowOverIndicator')
                overDamage.depends = function()
                    return helpers.Get('damageAbsorbEnable') and helpers.Get('damageAbsorbShowAt') == 'AS_EXTENSION'
                end
                local damageTexture = helpers.TextureDropdown('Damage Absorb Texture', 'damageAbsorbTexture', 50)
                damageTexture.depends = damageEnable
                local damageColor = helpers.Color('Damage Absorb Color', 'damageAbsorbColor', 50)
                damageColor.depends = damageEnable
                local overHeal = helpers.Toggle('Show Over Heal Absorb Indicator', 'healAbsorbShowOverIndicator')
                overHeal.depends = healEnable
                local healTexture = helpers.TextureDropdown('Heal Absorb Texture', 'healAbsorbTexture', 50)
                healTexture.depends = healEnable
                local healColor = helpers.Color('Heal Absorb Color', 'healAbsorbColor', 50)
                healColor.depends = healEnable
                return {
                    { type = 'title', label = 'Damage Absorb', width = 100 },
                    helpers.Toggle('Enable', 'damageAbsorbEnable'),
                    showAt,
                    overDamage,
                    damageTexture,
                    damageColor,
                    { type = 'title', label = 'Heal Absorb', width = 100 },
                    helpers.Toggle('Enable', 'healAbsorbEnable'),
                    overHeal,
                    healTexture,
                    healColor,
                }
            end,
        },
    }
end
