---@class ExalityUI
local EXUI = select(2, ...)


---@class EXUICharacterFrameStats
local stats = EXUI:GetModule('character-frame-stats')

stats.frames = {}
stats.container = nil

local function GetSecondaryBonus(rating, base, bonusCoeff)
    -- For Legion Remix Timerunners, secondary stat bonuses all come from auras not actual stats
    -- BonusCoeff is only from mastery, all other call sights should be 1
    -- default bonus coeff call sights where we don't use this
    if PlayerIsTimerunning() then
        return base;
    end

    if not bonusCoeff then
        bonusCoeff = 1;
    end
    return (GetCombatRatingBonus(rating) * bonusCoeff);
end

stats.CreateHeader = function(self, headerText, parent)
    local header = CreateFrame('Frame', nil, parent)
    header:SetHeight(20)

    local text = header:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 16, 'OUTLINE')
    text:SetPoint('LEFT')
    text:SetWidth(0)
    text:SetText(headerText)
    header.Text = text

    local bar = header:CreateTexture(nil, 'ARTWORK')
    bar:SetTexture(EXUI.const.textures.characterFrame.stats.bars.header)
    bar:SetTextureSliceMargins(2, 10, 2, 10)
    bar:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bar:SetPoint('LEFT', text, 'RIGHT', 8, 0)
    bar:SetPoint('RIGHT')


    header.isHeader = true
    return header
end

stats.CreateStat = function(self, statName, config, parent)
    local stat = CreateFrame('Frame', nil, parent)
    stat:SetHeight(15)

    stat.tooltipLines = {}

    local name = stat:CreateFontString(nil, 'OVERLAY')
    name:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    name:SetPoint('LEFT')
    name:SetWidth(0)
    name:SetText(statName)
    stat.Name = name

    local statRating = stat:CreateFontString(nil, 'OVERLAY')
    statRating:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    statRating:SetPoint('RIGHT')
    statRating:SetWidth(0)
    statRating:SetText('0') -- Until update
    stat.StatRating = statRating

    local bar = stat:CreateTexture(nil, 'ARTWORK')
    bar:SetTexture(EXUI.const.textures.characterFrame.stats.bars.stats)
    bar:SetTextureSliceMargins(2, 10, 2, 10)
    bar:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bar:SetPoint('LEFT', name, 'RIGHT', 8, 0)
    bar:SetPoint('RIGHT', statRating, 'LEFT', -8, 0)
    stat.Bar = bar


    if (config.update) then
        self.container.RegisterUpdateFunc(self.container, stat, statName, config.update)
    end

    if (config.shouldShow) then
        stat.ShouldShow = config.shouldShow
    end

    if (config.onEnter) then
        stat.onEnterFunc = config.onEnter
        stat:SetScript('OnEnter', config.onEnter)
    else
        stat:SetScript('OnEnter', function(self)
            if (self.tooltipLines and #self.tooltipLines > 0) then
                GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
                GameTooltip:SetText(self.tooltipLines[1])
                for i = 2, #self.tooltipLines do
                    local line = self.tooltipLines[i]
                    GameTooltip:AddLine(line, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
                end
                GameTooltip:Show()
            end
        end)
    end

    stat:SetScript('OnLeave', function(self)
        GameTooltip:Hide()
    end)

    return stat
end

stats.Create = function(self, container)
    self.container = container

    FrameUtil.RegisterFrameForEvents(self.container, {
        "COMBAT_RATING_UPDATE",
        "MASTERY_UPDATE",
        "SPEED_UPDATE",
        "LIFESTEAL_UPDATE",
        "AVOIDANCE_UPDATE",
        "PLAYER_TARGET_CHANGED",
        "UNIT_DAMAGE",
        "UNIT_ATTACK_SPEED",
        "UNIT_RANGEDDAMAGE",
        "UNIT_ATTACK",
        "UNIT_STATS",
        "UNIT_RANGED_ATTACK_POWER",
        "UNIT_SPELL_HASTE",
        "UNIT_MAXHEALTH",
        "PLAYER_TALENT_UPDATE",
        "ACTIVE_TALENT_GROUP_CHANGED",
        "SPELL_POWER_CHANGED",

    })

    self.container:SetScript('OnEvent', function(self, event, ...)
        C_Timer.After(0, function()
            self:Update()
        end)
    end)

    self.container.updateFuncs = {}
    self.container.RegisterUpdateFunc = function(self, parent, statName, updateFunc, shouldShowFunc)
        self.updateFuncs[statName] = {
            update = updateFunc,
            parent = parent,
        }
    end

    self.container.Update = function(self)
        for statName, config in pairs(self.updateFuncs) do
            config.update(config.parent)
        end
    end

    self.frames = {
        self:CreateHeader('Secondaries', container),
        self:CreateStat(STAT_CRITICAL_STRIKE, {
            update = function(frame)
                local school = 2
                local minCrit = GetSpellCritChance(school) -- 2 = holySchool
                for i = (school + 1), MAX_SPELL_SCHOOLS do
                    local spellCrit = GetSpellCritChance(i);
                    minCrit = min(minCrit, spellCrit);
                end
                local spellCritChance = minCrit
                local rangedCritChance = GetRangedCritChance()
                local meleeCritChance = GetCritChance()

                local rating, critChance

                if (spellCritChance >= rangedCritChance and spellCritChance >= meleeCritChance) then
                    rating = CR_CRIT_SPELL
                    critChance = spellCritChance
                elseif (rangedCritChance >= meleeCritChance) then
                    critChance = rangedCritChance;
                    rating = CR_CRIT_RANGED;
                else
                    critChance = meleeCritChance;
                    rating = CR_CRIT_MELEE;
                end

                frame.StatRating:SetText(string.format('%.2f%%', critChance))
                frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_CRITICAL_STRIKE) .. FONT_COLOR_CODE_CLOSE;
                local extraCritChance = GetSecondaryBonus(rating, critChance);
                local extraCritRating = GetCombatRating(rating);
                if (GetCritChanceProvidesParryEffect()) then
                    frame.tooltipLines[2] = format(CR_CRIT_PARRY_RATING_TOOLTIP, BreakUpLargeNumbers(extraCritRating),
                        extraCritChance, GetCombatRatingBonusForCombatRatingValue(CR_PARRY, extraCritRating));
                else
                    frame.tooltipLines[2] = format(CR_CRIT_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance);
                end
            end
        }, container),
        self:CreateStat(STAT_HASTE, {
            update = function(frame)
                local haste = GetHaste();
                local rating = CR_HASTE_MELEE;

                local hastePerc = string.format('%.2f%%', haste)

                if (haste < 0 and not GetPVPGearStatRules()) then
                    hastePerc = WrapTextInColorCode(hastePerc + 0.5, 'fffc0041')
                end

                frame.StatRating:SetText(hastePerc)

                frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_HASTE) .. FONT_COLOR_CODE_CLOSE;
                local _, class = UnitClass('player');
                frame.tooltipLines[2] = _G["STAT_HASTE_" .. class .. "_TOOLTIP"];
                if (not frame.tooltipLines[2]) then
                    frame.tooltipLines[2] = STAT_HASTE_TOOLTIP;
                end
                local hasteRating = GetCombatRating(rating);
                local hasteBonus = GetSecondaryBonus(rating, haste);
                frame.tooltipLines[2] = frame.tooltipLines[2] ..
                    format(STAT_HASTE_BASE_TOOLTIP, BreakUpLargeNumbers(hasteRating), hasteBonus);
            end
        }, container),
        self:CreateStat(STAT_MASTERY, {
            update = function(frame)
                local mastery = GetMasteryEffect();
                frame.StatRating:SetText(string.format('%.2f%%', mastery))
            end,
            onEnter = function(frame)
                GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
                local mastery, bonusCoeff = GetMasteryEffect();
                local masteryBonus = GetSecondaryBonus(CR_MASTERY, mastery, bonusCoeff);

                local primaryTalentTree = C_SpecializationInfo.GetSpecialization();
                if (primaryTalentTree) then
                    local masterySpells = C_SpecializationInfo.GetSpecializationMasterySpells(primaryTalentTree)
                    local hasAddedAnyMasterySpell = false;
                    for i, masterySpell in ipairs(masterySpells) do
                        if hasAddedAnyMasterySpell then
                            GameTooltip:AppendInfoWithSpacer("GetSpellByID", masterySpell);
                        else
                            GameTooltip:AppendInfo("GetSpellByID", masterySpell);
                            hasAddedAnyMasterySpell = true;
                        end
                    end
                    GameTooltip:AddLine(" ");
                    GameTooltip:AddLine(
                        format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_MASTERY)), masteryBonus),
                        NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
                else
                    GameTooltip:AddLine(
                        format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_MASTERY)), masteryBonus),
                        NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
                    GameTooltip:AddLine(" ");
                    GameTooltip:AddLine(STAT_MASTERY_TOOLTIP_NO_TALENT_SPEC, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g,
                        GRAY_FONT_COLOR.b, true);
                end
                frame.UpdateTooltip = frame.onEnterFunc;
                GameTooltip:Show();
            end
        }, container),
        self:CreateStat(STAT_VERSATILITY, {
            update = function(frame)
                local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
                local versatilityDamageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) +
                    GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
                local versatilityDamageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) +
                    GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN);
                frame.StatRating:SetText(string.format('%.2f%%', versatilityDamageBonus))
                frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_VERSATILITY) .. FONT_COLOR_CODE_CLOSE;

                frame.tooltipLines[2] = format(CR_VERSATILITY_TOOLTIP, versatilityDamageBonus,
                    versatilityDamageTakenReduction, BreakUpLargeNumbers(versatility), versatilityDamageBonus,
                    versatilityDamageTakenReduction);
            end
        }, container),


        self:CreateHeader('Primaries', container),
        self:CreateStat('Primary', {
            update = function(frame)
                local spec = C_SpecializationInfo.GetSpecialization()
                local primaryStatId = select(6, C_SpecializationInfo.GetSpecializationInfo(spec));
                local stat, effectiveStat, posBuff, negBuff = UnitStat('player', primaryStatId);

                local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat);

                local statName = _G["SPELL_STAT" .. primaryStatId .. "_NAME"];
                local tooltipText = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " ";

                if ((posBuff == 0) and (negBuff == 0)) then
                    frame.tooltipLines[1] = tooltipText .. effectiveStatDisplay .. FONT_COLOR_CODE_CLOSE;
                else
                    tooltipText = tooltipText .. effectiveStatDisplay;
                    if (posBuff > 0 or negBuff < 0) then
                        tooltipText = tooltipText ..
                            " (" .. BreakUpLargeNumbers(stat - posBuff - negBuff) .. FONT_COLOR_CODE_CLOSE;
                    end
                    if (posBuff > 0) then
                        tooltipText = tooltipText ..
                            FONT_COLOR_CODE_CLOSE ..
                            GREEN_FONT_COLOR_CODE .. "+" .. BreakUpLargeNumbers(posBuff) .. FONT_COLOR_CODE_CLOSE;
                    end
                    if (negBuff < 0) then
                        tooltipText = tooltipText ..
                            RED_FONT_COLOR_CODE .. " " .. BreakUpLargeNumbers(negBuff) .. FONT_COLOR_CODE_CLOSE;
                    end
                    if (posBuff > 0 or negBuff < 0) then
                        tooltipText = tooltipText .. HIGHLIGHT_FONT_COLOR_CODE .. ")" .. FONT_COLOR_CODE_CLOSE;
                    end
                    frame.tooltipLines[1] = tooltipText;

                    -- If there are any negative buffs then show the main number in red even if there are
                    -- positive buffs. Otherwise show in green.
                    if (negBuff < 0 and not GetPVPGearStatRules()) then
                        effectiveStatDisplay = RED_FONT_COLOR_CODE .. effectiveStatDisplay .. FONT_COLOR_CODE_CLOSE;
                    end
                end

                frame.Name:SetText(statName)
                frame.StatRating:SetText(effectiveStatDisplay)
                frame.tooltipLines[2] = _G["DEFAULT_STAT" .. primaryStatId .. "_TOOLTIP"];

                local _, unitClass = UnitClass("player");
                unitClass = strupper(unitClass);

                local role;
                if (spec) then
                    role = GetSpecializationRole(spec);
                end

                if (primaryStatId == LE_UNIT_STAT_STRENGTH) then
                    local attackPower = GetAttackPowerForStat(primaryStatId, effectiveStat);
                    if (HasAPEffectsSpellPower()) then
                        frame.tooltipLines[2] = STAT_TOOLTIP_BONUS_AP_SP;
                    end
                    frame.tooltipLines[2] = format(frame.tooltipLines[2], BreakUpLargeNumbers(attackPower));
                    if (role == "TANK") then
                        local increasedParryChance = GetParryChanceFromAttribute();
                        if (increasedParryChance > 0) then
                            frame.tooltipLines[2] = frame.tooltipLines[2] ..
                                "|n|n" .. format(CR_PARRY_BASE_STAT_TOOLTIP, increasedParryChance);
                        end
                    end
                elseif (primaryStatId == LE_UNIT_STAT_AGILITY) then
                    frame.tooltipLines[2] = HasAPEffectsSpellPower() and STAT_TOOLTIP_BONUS_AP_SP or
                        STAT_TOOLTIP_BONUS_AP;
                    if (role == "TANK") then
                        local increasedDodgeChance = GetDodgeChanceFromAttribute();
                        if (increasedDodgeChance > 0) then
                            frame.tooltipLines[2] = frame.tooltipLines[2] ..
                                "|n|n" .. format(CR_DODGE_BASE_STAT_TOOLTIP, increasedDodgeChance);
                        end
                    end
                elseif (primaryStatId == LE_UNIT_STAT_INTELLECT) then
                    if (HasAPEffectsSpellPower()) then
                        frame.tooltipLines[2] = STAT_NO_BENEFIT_TOOLTIP;
                    elseif (HasSPEffectsAttackPower()) then
                        frame.tooltipLines[2] = STAT_TOOLTIP_BONUS_AP_SP;
                    else
                        frame.tooltipLines[2] = format(frame.tooltipLines[2], max(0, effectiveStat));
                    end
                end
            end
        }, container),
        self:CreateStat(_G["SPELL_STAT" .. LE_UNIT_STAT_STAMINA .. "_NAME"], {
            update = function(frame)
                local stat, effectiveStat, posBuff, negBuff = UnitStat('player', LE_UNIT_STAT_STAMINA);
                local statName = _G["SPELL_STAT" .. LE_UNIT_STAT_STAMINA .. "_NAME"]
                local tooltipText = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " ";
                local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat);

                if ((posBuff == 0) and (negBuff == 0)) then
                    frame.tooltipLines[1] = tooltipText .. effectiveStatDisplay .. FONT_COLOR_CODE_CLOSE;
                else
                    tooltipText = tooltipText .. effectiveStatDisplay;
                    if (posBuff > 0 or negBuff < 0) then
                        tooltipText = tooltipText ..
                            " (" .. BreakUpLargeNumbers(stat - posBuff - negBuff) .. FONT_COLOR_CODE_CLOSE;
                    end
                    if (posBuff > 0) then
                        tooltipText = tooltipText ..
                            FONT_COLOR_CODE_CLOSE ..
                            GREEN_FONT_COLOR_CODE .. "+" .. BreakUpLargeNumbers(posBuff) .. FONT_COLOR_CODE_CLOSE;
                    end
                    if (negBuff < 0) then
                        tooltipText = tooltipText ..
                            RED_FONT_COLOR_CODE .. " " .. BreakUpLargeNumbers(negBuff) .. FONT_COLOR_CODE_CLOSE;
                    end
                    if (posBuff > 0 or negBuff < 0) then
                        tooltipText = tooltipText .. HIGHLIGHT_FONT_COLOR_CODE .. ")" .. FONT_COLOR_CODE_CLOSE;
                    end
                    frame.tooltipLines[1] = tooltipText;

                    -- If there are any negative buffs then show the main number in red even if there are
                    -- positive buffs. Otherwise show in green.
                    if (negBuff < 0 and not GetPVPGearStatRules()) then
                        effectiveStatDisplay = RED_FONT_COLOR_CODE .. effectiveStatDisplay .. FONT_COLOR_CODE_CLOSE;
                    end
                end

                frame.StatRating:SetText(effectiveStatDisplay)
                frame.tooltipLines[2] = _G["DEFAULT_STAT" .. LE_UNIT_STAT_STAMINA .. "_TOOLTIP"];

                frame.tooltipLines[2] = format(frame.tooltipLines[2],
                    BreakUpLargeNumbers(((effectiveStat * UnitHPPerStamina("player")) *
                        GetUnitMaxHealthModifier("player"))));
            end
        }, container),
        self:CreateStat(STAT_ARMOR, {
            update = function(frame)
                local baselineArmor, effectiveArmor, armor, bonusArmor = UnitArmor('player');
                local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, UnitEffectiveLevel('player'));
                local armorReductionAgainstTarget = PaperDollFrame_GetArmorReductionAgainstTarget(effectiveArmor);
                frame.StatRating:SetText(BreakUpLargeNumbers(effectiveArmor))
                frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ARMOR) ..
                    " " .. BreakUpLargeNumbers(effectiveArmor) .. FONT_COLOR_CODE_CLOSE;
                frame.tooltipLines[2] = format(STAT_ARMOR_TOOLTIP, armorReduction);
                if (armorReductionAgainstTarget) then
                    frame.tooltipLines[3] = format(STAT_ARMOR_TARGET_TOOLTIP, armorReductionAgainstTarget);
                else
                    frame.tooltipLines[3] = nil;
                end
            end
        }, container),
        self:CreateHeader('Other', container),
        self:CreateStat(STAT_AVOIDANCE, {
            update = function(frame)
                local avoidance = GetAvoidance();
                if (avoidance == 0) then
                    return
                end
                frame.StatRating:SetText(string.format('%.2f%%', avoidance))
                frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_AVOIDANCE) ..
                    " " .. format("%.2F%%", avoidance) .. FONT_COLOR_CODE_CLOSE;

                frame.tooltipLines[2] = format(CR_AVOIDANCE_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_AVOIDANCE)),
                    GetCombatRatingBonus(CR_AVOIDANCE));
            end,
            shouldShow = function()
                return GetAvoidance() > 0
            end
        }, container),
        self:CreateStat(STAT_LIFESTEAL, {
            update = function(frame)
                local lifesteal = GetLifesteal();
                frame.StatRating:SetText(string.format('%.2f%%', lifesteal))
                frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_LIFESTEAL) ..
                    " " .. format("%.2F%%", lifesteal) .. FONT_COLOR_CODE_CLOSE;

                frame.tooltipLines[2] = format(CR_LIFESTEAL_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_LIFESTEAL)),
                    GetCombatRatingBonus(CR_LIFESTEAL));
            end,
            shouldShow = function()
                return GetLifesteal() > 0
            end
        }, container),
        self:CreateStat(STAT_DODGE, {
            update = function(frame)
                local chance = GetDodgeChance();
                frame.StatRating:SetText(string.format("%.2f%%", chance))
                frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE) ..
                    " " .. string.format("%.2F", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
                frame.tooltipLines[2] = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE),
                    GetCombatRatingBonus(CR_DODGE));
            end,
            shouldShow = function()
                local spec = C_SpecializationInfo.GetSpecialization();
                if (spec) then
                    return GetSpecializationRoleEnum(spec) == 0 -- Tank
                end
                return false
            end
        }, container), -- Dodge
        self:CreateStat(STAT_PARRY, {
            update = function(frame)
                local chance = GetParryChance();
                frame.StatRating:SetText(string.format("%.2f%%", chance))
                frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE) ..
                    " " .. string.format("%.2F", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;
                frame.tooltipLines[2] = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY),
                    GetCombatRatingBonus(CR_PARRY));
            end,
            shouldShow = function()
                local spec = C_SpecializationInfo.GetSpecialization();
                if (spec) then
                    return GetSpecializationRoleEnum(spec) == 0 -- Tank
                end
                return false
            end
        }, container), -- Parry
        self:CreateStat(STAT_BLOCK, {
            update = function(frame)
                local chance = GetBlockChance();
                frame.StatRating:SetText(string.format("%.2f%%", chance))
                frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE) ..
                    " " .. string.format("%.2F", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;

                local shieldBlockArmor = GetShieldBlock();
                local blockArmorReduction = PaperDollFrame_GetArmorReduction(shieldBlockArmor,
                    UnitEffectiveLevel('player'));
                local blockArmorReductionAgainstTarget = PaperDollFrame_GetArmorReductionAgainstTarget(shieldBlockArmor);

                frame.tooltipLines[2] = CR_BLOCK_TOOLTIP:format(blockArmorReduction);
                if (blockArmorReductionAgainstTarget) then
                    frame.tooltipLines[3] = format(STAT_BLOCK_TARGET_TOOLTIP, blockArmorReductionAgainstTarget);
                else
                    frame.tooltipLines[3] = nil;
                end
            end,
            shouldShow = function()
                local spec = C_SpecializationInfo.GetSpecialization();
                local _, class = UnitClass('player');
                if (spec) then
                    return GetSpecializationRoleEnum(spec) == 0 and (class == "WARRIOR" or class == "PALADIN") -- Tank
                end
                return false
            end
        }, container), -- Block
        self:CreateStat(STAT_STAGGER, {
            update = function(frame)
                local stagger, staggerAgainstTarget = C_PaperDollInfo.GetStaggerPercentage('player');
                frame.StatRating:SetText(stagger)
                frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAGGER) ..
                    " " .. string.format("%.2F%%", stagger) .. FONT_COLOR_CODE_CLOSE;
                frame.tooltipLines[2] = format(STAT_STAGGER_TOOLTIP, stagger);
                if (staggerAgainstTarget) then
                    frame.tooltipLines[3] = format(STAT_STAGGER_TARGET_TOOLTIP, staggerAgainstTarget);
                else
                    frame.tooltipLines[3] = nil;
                end
            end,
            shouldShow = function()
                local spec = C_SpecializationInfo.GetSpecialization();
                local _, class = UnitClass('player');
                if (spec) then
                    return GetSpecializationRoleEnum(spec) == 0 and class == "MONK" -- Monk
                end
                return false
            end
        }, container), -- Stagger
    }

    self:PositionFrames()
    self.container:Update()
end

stats.PositionFrames = function(self)
    local prev = nil
    local prevIsHeader = false
    for _, frame in ipairs(self.frames) do
        if (not frame.ShouldShow or frame:ShouldShow()) then
            local isHeader = frame.isHeader
            local gap = isHeader and -14 or prevIsHeader and -8 or -2
            if (prev) then
                frame:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, gap)
                frame:SetPoint('TOPRIGHT', prev, 'BOTTOMRIGHT', 0, gap)
            else
                frame:SetPoint('TOPLEFT', self.container, 'TOPLEFT', 0, 0)
                frame:SetPoint('TOPRIGHT', self.container, 'TOPRIGHT', 0, 0)
            end
            prevIsHeader = isHeader
            prev = frame
        end
    end
end
