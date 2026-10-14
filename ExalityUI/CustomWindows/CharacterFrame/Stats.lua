---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUICharacterFrameStats
local stats = EXUI:GetModule('character-frame-stats')

stats.frames = {}
stats.container = nil

-- Gate once: tainted code cannot arithmetic/compare secret unit-stat numbers in M+/raids.
local function AreUnitStatsSecret()
    return C_Secrets and C_Secrets.ShouldUnitStatsBeSecret and C_Secrets.ShouldUnitStatsBeSecret()
end

local function IsInaccessibleValue(value)
    return issecretvalue(value)
        or (canaccessvalue and not canaccessvalue(value))
end

local function IsPositiveStat(value)
    if IsInaccessibleValue(value) then
        return true
    end
    return value > 0
end

local function IsNonZeroStat(value)
    if IsInaccessibleValue(value) then
        return true
    end
    return value ~= 0
end

local function SetPercentageStatText(fontString, value)
    fontString:SetFormattedText('%.2f%%', value)
end

local function SetLargeNumberStatText(fontString, value)
    fontString:SetText(BreakUpLargeNumbers(value))
end

local function ClearStatTooltip(frame)
    frame.tooltipLines = {}
end

local function GetSecondaryBonus(rating, base, bonusCoeff)
    -- Timerunners: bonuses come from auras. Secret envs: cannot multiply rating bonus.
    if PlayerIsTimerunning() or AreUnitStatsSecret() then
        return base;
    end

    if not bonusCoeff then
        bonusCoeff = 1;
    end
    return (GetCombatRatingBonus(rating) * bonusCoeff);
end

local function GetSecretSafeCritInfo()
    local _, class = UnitClass('player')
    local spec = C_SpecializationInfo.GetSpecialization()
    local primaryStatId = spec and select(6, C_SpecializationInfo.GetSpecializationInfo(spec))

    if class == 'HUNTER' then
        return CR_CRIT_RANGED, GetRangedCritChance()
    end
    if primaryStatId == LE_UNIT_STAT_INTELLECT then
        return CR_CRIT_SPELL, GetSpellCritChance(2)
    end
    return CR_CRIT_MELEE, GetCritChance()
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

stats.CreateCrest = function(self, currencyId, parent)
    local crest = CreateFrame('Frame', nil, parent)
    crest.currencyId = currencyId
    crest:SetSize(26, 26)

    local icon = crest:CreateTexture(nil, 'ARTWORK')
    icon:SetPoint('TOP')
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetSize(26, 26)
    crest.Icon = icon

    local text = crest:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    text:SetPoint('TOP', icon, 'BOTTOM', 0, -2)
    text:SetText('0')
    crest.Text = text

    crest.Update = function(self)
        local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(self.currencyId)
        if (not currencyInfo) then
            return
        end
        self.Icon:SetTexture(currencyInfo.iconFileID)
        self.Text:SetText(currencyInfo.quantity)

        if (currencyInfo.maxQuantity > 0 and currencyInfo.quantity >= currencyInfo.maxQuantity) then
            self.Text:SetVertexColor(0, 1, 0, 1)
        else
            self.Text:SetVertexColor(1, 1, 1, 1)
        end
    end

    crest:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 2, 2);
        GameTooltip:SetCurrencyByID(self.currencyId);
    end)

    crest:SetScript('OnLeave', function(self)
        GameTooltip:Hide()
    end)

    crest:RegisterEvent('CURRENCY_DISPLAY_UPDATE')
    crest:SetScript('OnEvent', function(self, event, ...)
        self:Update()
    end)

    crest:Update()
    return crest
end

stats.CreateCrestDisplay = function(self, parent)
    local crestIds = EXUI.const.crestCurrencyIDs
    local container = CreateFrame('Frame', nil, parent)
    local centerContainer = CreateFrame('Frame', nil, container)
    centerContainer:SetSize(26 * #crestIds + 10 * (#crestIds - 1), 16)
    centerContainer:SetPoint('TOP')
    container.CenterContainer = centerContainer

    container:SetHeight(30)
    for i, currencyId in ipairs(crestIds) do
        local crest = self:CreateCrest(currencyId, container)
        crest:SetPoint('LEFT', centerContainer, 'LEFT', (26 + 10) * (i - 1), 0)
    end

    return container
end

local PROXY_OWNED = {
    Label = true,
    Value = true,
    Show = true,
    Hide = true,
    _hidden = true,
}

local function CreateProxyText()
    return {
        text = '',
        SetText = function(self, text)
            self.text = text or ''
        end,
    }
end

local function CreatePaperDollProxy()
    local proxy = {
        Label = CreateProxyText(),
        Value = CreateProxyText(),
    }
    function proxy:Show()
        self._hidden = false
    end

    function proxy:Hide()
        self._hidden = true
    end

    return proxy
end

local function ResetPaperDollProxy(proxy)
    proxy._hidden = false
    proxy.Label.text = ''
    proxy.Value.text = ''
    for key in pairs(proxy) do
        if not PROXY_OWNED[key] then
            proxy[key] = nil
        end
    end
end

local function StripStatLabel(text)
    if not text or text == '' then
        return ''
    end
    return text:gsub(':%s*$', '')
end

local function CopyProxyFields(frame, proxy)
    if frame._copiedProxyKeys then
        for _, key in ipairs(frame._copiedProxyKeys) do
            frame[key] = nil
        end
    end
    frame.onEnterFunc = nil
    local keys = {}
    for key, value in pairs(proxy) do
        if not PROXY_OWNED[key] and key ~= 'numericValue' then
            frame[key] = value
            keys[#keys + 1] = key
        end
    end
    frame._copiedProxyKeys = keys
end

local function ApplyPaperDollTooltip(frame)
    if frame.onEnterFunc then
        frame.onEnterFunc(frame)
        return
    end
    if not frame.tooltipLines or #frame.tooltipLines == 0 then
        return
    end
    GameTooltip:SetOwner(frame, 'ANCHOR_RIGHT')
    GameTooltip:SetText(frame.tooltipLines[1])
    for i = 2, #frame.tooltipLines do
        local line = frame.tooltipLines[i]
        if line then
            GameTooltip:AddLine(line, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
        end
    end
    GameTooltip:Show()
end

local RESISTANCE_STATS = {
    { global = 'DAMAGE_SCHOOL7', damageClass = Enum.Damageclass and Enum.Damageclass.Arcane },
    { global = 'DAMAGE_SCHOOL3', damageClass = Enum.Damageclass and Enum.Damageclass.Fire },
    { global = 'DAMAGE_SCHOOL5', damageClass = Enum.Damageclass and Enum.Damageclass.Frost },
    { global = 'DAMAGE_SCHOOL4', damageClass = Enum.Damageclass and Enum.Damageclass.Nature },
    { global = 'DAMAGE_SCHOOL6', damageClass = Enum.Damageclass and Enum.Damageclass.Shadow },
}

stats.BuildForeverFrames = function(self, container)
    local frames = {}
    if not PAPERDOLL_STATCATEGORIES or not PAPERDOLL_STATINFO then
        return frames
    end

    for _, category in ipairs(PAPERDOLL_STATCATEGORIES) do
        if category.unit == 'player' and category.stats then
            local header = self:CreateHeader(category.categoryName or '', container)
            local categoryRows = {}
            table.insert(frames, header)

            for _, stat in ipairs(category.stats) do
                local info = PAPERDOLL_STATINFO[stat.stat]
                if info and info.updateFunc then
                    local proxy = CreatePaperDollProxy()
                    local row = self:CreateStat(stat.stat, {
                        update = function(frame)
                            ResetPaperDollProxy(proxy)
                            local ok, numericValue = pcall(info.updateFunc, proxy, 'player', stat.id)
                            frame._proxyHidden = not ok or proxy._hidden
                            frame.numericValue = ok and numericValue or nil
                            if not ok then
                                return
                            end
                            frame.Name:SetText(StripStatLabel(proxy.Label.text))
                            frame.StatRating:SetText(proxy.Value.text or '')
                            CopyProxyFields(frame, proxy)
                            frame.tooltipLines = {}
                            if proxy.tooltip then
                                table.insert(frame.tooltipLines, proxy.tooltip)
                            end
                            if proxy.tooltip2 then
                                table.insert(frame.tooltipLines, proxy.tooltip2)
                            end
                            if proxy.tooltip3 then
                                table.insert(frame.tooltipLines, proxy.tooltip3)
                            end
                            if proxy.tooltip4 then
                                table.insert(frame.tooltipLines, proxy.tooltip4)
                            end
                        end,
                        shouldShow = function(frame)
                            if stat.showFunc then
                                local showOk, showResult = pcall(stat.showFunc)
                                if not showOk or not showResult then
                                    return false
                                end
                            end
                            if frame._proxyHidden then
                                return false
                            end
                            if stat.hideAt ~= nil and frame.numericValue == stat.hideAt then
                                return false
                            end
                            return true
                        end,
                        onEnter = ApplyPaperDollTooltip,
                    }, container)
                    table.insert(frames, row)
                    table.insert(categoryRows, row)
                end
            end

            header.ShouldShow = function()
                for _, row in ipairs(categoryRows) do
                    if not row.ShouldShow or row:ShouldShow() then
                        return true
                    end
                end
                return false
            end
        end
    end

    local resistanceRows = {}
    for _, entry in ipairs(RESISTANCE_STATS) do
        local name = _G[entry.global]
        if name and entry.damageClass ~= nil then
            local row = self:CreateStat(name, {
                update = function(frame)
                    local _, _, effectiveResistance, bonusResistance = UnitResistance('player', entry.damageClass)
                    effectiveResistance = effectiveResistance or 0
                    bonusResistance = bonusResistance or 0
                    local tooltipData = {}
                    if PaperDollFrame_SetResistanceTooltips then
                        PaperDollFrame_SetResistanceTooltips(tooltipData, name, effectiveResistance, 'player',
                            entry.damageClass)
                    end
                    local valueText = BreakUpLargeNumbers(effectiveResistance)
                    if PaperDollFrame_FormatBonusValue then
                        valueText = PaperDollFrame_FormatBonusValue(valueText, bonusResistance)
                    end
                    frame.Name:SetText(name)
                    frame.StatRating:SetText(valueText)
                    frame.tooltipLines = {}
                    frame.onEnterFunc = nil
                    if tooltipData.tooltip then
                        table.insert(frame.tooltipLines, tooltipData.tooltip)
                    end
                    if tooltipData.tooltip2 then
                        table.insert(frame.tooltipLines, tooltipData.tooltip2)
                    end
                    if tooltipData.tooltip3 then
                        table.insert(frame.tooltipLines, tooltipData.tooltip3)
                    end
                end,
                onEnter = ApplyPaperDollTooltip,
            }, container)
            table.insert(resistanceRows, row)
        end
    end

    if #resistanceRows > 0 then
        table.insert(frames, self:CreateHeader(_G['STAT_CATEGORY_RESISTANCE'] or 'Resistances', container))
        for _, row in ipairs(resistanceRows) do
            table.insert(frames, row)
        end
    end

    return frames
end

stats.Create = function(self, container)
    self.container = container

    local generalEvents = {
        "COMBAT_RATING_UPDATE",
        "MASTERY_UPDATE",
        "SPEED_UPDATE",
        "LIFESTEAL_UPDATE",
        "AVOIDANCE_UPDATE",
        "PLAYER_TARGET_CHANGED",
        "PLAYER_TALENT_UPDATE",
        "ACTIVE_TALENT_GROUP_CHANGED",
        "SPELL_POWER_CHANGED",
    }

    local unitEvents = {
        "UNIT_DAMAGE",
        "UNIT_ATTACK_SPEED",
        "UNIT_RANGEDDAMAGE",
        "UNIT_ATTACK",
        "UNIT_STATS",
        "UNIT_RANGED_ATTACK_POWER",
        "UNIT_SPELL_HASTE",
        "UNIT_MAXHEALTH",
    }

    if EXUI.IsForever() then
        table.insert(unitEvents, 'UNIT_RESISTANCES')
        table.insert(unitEvents, 'UNIT_ATTACK_POWER')
        table.insert(unitEvents, 'UNIT_MAXPOWER')
        table.insert(generalEvents, 'PLAYER_EQUIPMENT_CHANGED')
    end

    container.RegisterStatsEvents = function(self)
        for _, event in ipairs(generalEvents) do
            self:RegisterEvent(event)
        end
        for _, event in ipairs(unitEvents) do
            self:RegisterUnitEvent(event, 'player')
        end
    end

    container.UnregisterStatsEvents = function(self)
        self:UnregisterAllEvents()
    end

    container.RequestUpdate = function(self)
        if self._exuiUpdatePending then
            return
        end
        self._exuiUpdatePending = true
        C_Timer.After(0, function()
            self._exuiUpdatePending = nil
            if self:IsShown() then
                self:Update()
            end
        end)
    end

    self.container:SetScript('OnEvent', function(self, event, ...)
        self:RequestUpdate()
    end)

    container:SetScript('OnShow', function(self)
        self:RegisterStatsEvents()
        self:Update()
    end)

    container:SetScript('OnHide', function(self)
        self:UnregisterStatsEvents()
        self._exuiUpdatePending = nil
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
            pcall(config.update, config.parent)
        end
        stats:PositionFrames()
    end

    local scrollFrame = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scrollFrame:SetParent(container)
    scrollFrame:SetPoint('TOPLEFT', 0, 0)
    scrollFrame:SetPoint('BOTTOMRIGHT', 0, 0)
    self.scrollFrame = scrollFrame
    self.content = scrollFrame.child

    scrollFrame:HookScript('OnSizeChanged', function()
        stats:UpdateScroll()
    end)

    if EXUI.IsForever() then
        self.frames = self:BuildForeverFrames(self.content)
    else
        local container = self.content
        self.frames = {
            self:CreateHeader('Secondaries', container),
            self:CreateStat(STAT_CRITICAL_STRIKE, {
                update = function(frame)
                    if AreUnitStatsSecret() then
                        local _, critChance = GetSecretSafeCritInfo()
                        SetPercentageStatText(frame.StatRating, critChance)
                        ClearStatTooltip(frame)
                        return
                    end

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

                    SetPercentageStatText(frame.StatRating, critChance)
                    frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                        format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_CRITICAL_STRIKE) .. FONT_COLOR_CODE_CLOSE;
                    local extraCritChance = GetSecondaryBonus(rating, critChance);
                    local extraCritRating = GetCombatRating(rating);
                    if (GetCritChanceProvidesParryEffect()) then
                        frame.tooltipLines[2] = format(CR_CRIT_PARRY_RATING_TOOLTIP, BreakUpLargeNumbers(extraCritRating),
                            extraCritChance, GetCombatRatingBonusForCombatRatingValue(CR_PARRY, extraCritRating));
                    else
                        frame.tooltipLines[2] = format(CR_CRIT_TOOLTIP, BreakUpLargeNumbers(extraCritRating),
                            extraCritChance);
                    end
                end
            }, container),
            self:CreateStat(STAT_HASTE, {
                update = function(frame)
                    local haste = GetHaste();
                    local rating = CR_HASTE_MELEE;

                    if AreUnitStatsSecret() then
                        SetPercentageStatText(frame.StatRating, haste)
                        ClearStatTooltip(frame)
                        return
                    end

                    local hastePerc = string.format('%.2f%%', haste)

                    if (haste < 0 and not GetPVPGearStatRules()) then
                        hastePerc = WrapTextInColorCode(tostring(haste + 0.5), 'fffc0041')
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
                    SetPercentageStatText(frame.StatRating, mastery)
                end,
                onEnter = function(frame)
                    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
                    if AreUnitStatsSecret() then
                        local primaryTalentTree = C_SpecializationInfo.GetSpecialization();
                        if primaryTalentTree then
                            local masterySpells = C_SpecializationInfo.GetSpecializationMasterySpells(primaryTalentTree)
                            local hasAddedAnyMasterySpell = false;
                            for _, masterySpell in ipairs(masterySpells) do
                                if hasAddedAnyMasterySpell then
                                    GameTooltip:AppendInfoWithSpacer("GetSpellByID", masterySpell);
                                else
                                    GameTooltip:AppendInfo("GetSpellByID", masterySpell);
                                    hasAddedAnyMasterySpell = true;
                                end
                            end
                        end
                        frame.UpdateTooltip = frame.onEnterFunc;
                        GameTooltip:Show();
                        return
                    end

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
                    if AreUnitStatsSecret() then
                        SetPercentageStatText(frame.StatRating, GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE))
                        ClearStatTooltip(frame)
                        return
                    end

                    local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
                    local versatilityDamageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) +
                        GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
                    local versatilityDamageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) +
                        GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN);
                    SetPercentageStatText(frame.StatRating, versatilityDamageBonus)
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
                    local statName = _G["SPELL_STAT" .. primaryStatId .. "_NAME"];

                    frame.Name:SetText(statName)

                    if AreUnitStatsSecret() then
                        SetLargeNumberStatText(frame.StatRating, effectiveStat)
                        ClearStatTooltip(frame)
                        return
                    end

                    local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat);
                    local tooltipText = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " ";

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

                    if AreUnitStatsSecret() then
                        SetLargeNumberStatText(frame.StatRating, effectiveStat)
                        ClearStatTooltip(frame)
                        return
                    end

                    local statName = _G["SPELL_STAT" .. LE_UNIT_STAT_STAMINA .. "_NAME"]
                    local tooltipText = HIGHLIGHT_FONT_COLOR_CODE ..
                    format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName) .. " ";
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

                    if AreUnitStatsSecret() then
                        SetLargeNumberStatText(frame.StatRating, effectiveArmor)
                        ClearStatTooltip(frame)
                        return
                    end

                    local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, UnitEffectiveLevel('player'));
                    local armorReductionAgainstTarget = PaperDollFrame_GetArmorReductionAgainstTarget(effectiveArmor);
                    SetLargeNumberStatText(frame.StatRating, effectiveArmor)
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
                    if (not IsNonZeroStat(avoidance)) then
                        return
                    end
                    SetPercentageStatText(frame.StatRating, avoidance)
                    if AreUnitStatsSecret() then
                        ClearStatTooltip(frame)
                        return
                    end
                    frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                        format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_AVOIDANCE) ..
                        " " .. format("%.2F%%", avoidance) .. FONT_COLOR_CODE_CLOSE;

                    frame.tooltipLines[2] = format(CR_AVOIDANCE_TOOLTIP,
                        BreakUpLargeNumbers(GetCombatRating(CR_AVOIDANCE)),
                        GetCombatRatingBonus(CR_AVOIDANCE));
                end,
                shouldShow = function()
                    return IsPositiveStat(GetAvoidance())
                end
            }, container),
            self:CreateStat(STAT_LIFESTEAL, {
                update = function(frame)
                    local lifesteal = GetLifesteal();
                    SetPercentageStatText(frame.StatRating, lifesteal)
                    if AreUnitStatsSecret() then
                        ClearStatTooltip(frame)
                        return
                    end
                    frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                        format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_LIFESTEAL) ..
                        " " .. format("%.2F%%", lifesteal) .. FONT_COLOR_CODE_CLOSE;

                    frame.tooltipLines[2] = format(CR_LIFESTEAL_TOOLTIP,
                        BreakUpLargeNumbers(GetCombatRating(CR_LIFESTEAL)),
                        GetCombatRatingBonus(CR_LIFESTEAL));
                end,
                shouldShow = function()
                    return IsPositiveStat(GetLifesteal())
                end
            }, container),
            self:CreateStat(STAT_DODGE, {
                update = function(frame)
                    local chance = GetDodgeChance();
                    SetPercentageStatText(frame.StatRating, chance)
                    if AreUnitStatsSecret() then
                        ClearStatTooltip(frame)
                        return
                    end
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
                    SetPercentageStatText(frame.StatRating, chance)
                    if AreUnitStatsSecret() then
                        ClearStatTooltip(frame)
                        return
                    end
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
                    SetPercentageStatText(frame.StatRating, chance)
                    if AreUnitStatsSecret() then
                        ClearStatTooltip(frame)
                        return
                    end
                    frame.tooltipLines[1] = HIGHLIGHT_FONT_COLOR_CODE ..
                        format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE) ..
                        " " .. string.format("%.2F", chance) .. "%" .. FONT_COLOR_CODE_CLOSE;

                    local shieldBlockArmor = GetShieldBlock();
                    local blockArmorReduction = PaperDollFrame_GetArmorReduction(shieldBlockArmor,
                        UnitEffectiveLevel('player'));
                    local blockArmorReductionAgainstTarget = PaperDollFrame_GetArmorReductionAgainstTarget(
                    shieldBlockArmor);

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
                        return GetSpecializationRoleEnum(spec) == 0 and
                        (class == "WARRIOR" or class == "PALADIN")                                             -- Tank
                    end
                    return false
                end
            }, container), -- Block
            self:CreateStat(STAT_STAGGER, {
                update = function(frame)
                    local stagger, staggerAgainstTarget = C_PaperDollInfo.GetStaggerPercentage('player');
                    SetPercentageStatText(frame.StatRating, stagger)
                    if AreUnitStatsSecret() then
                        ClearStatTooltip(frame)
                        return
                    end
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

            self:CreateHeader('Crests', container),
            self:CreateCrestDisplay(container),
        }
    end

    self.container:Update()
end

local STATS_SCROLL_PAD = 10

stats.UpdateScroll = function(self)
    if not self.scrollFrame or not self.content then
        return
    end
    local width = math.max(1, self.scrollFrame:GetWidth())
    local height = math.max(1, self.contentHeight or 1)
    self.scrollFrame:UpdateScrollChild(width, height)
end

stats.PositionFrames = function(self)
    local anchor = self.content or self.container
    local prev = nil
    local prevIsHeader = false
    local contentHeight = 0
    for _, frame in ipairs(self.frames) do
        local shouldShow = true
        if (frame.ShouldShow) then
            local ok, result = pcall(frame.ShouldShow, frame)
            shouldShow = ok and result
        end
        if (shouldShow) then
            frame:Show()
            local isHeader = frame.isHeader
            local gap = isHeader and -14 or prevIsHeader and -8 or -2
            if (prev) then
                frame:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, gap)
                frame:SetPoint('TOPRIGHT', prev, 'BOTTOMRIGHT', 0, gap)
                contentHeight = contentHeight + (-gap) + frame:GetHeight()
            else
                frame:SetPoint('TOPLEFT', anchor, 'TOPLEFT', 0, 0)
                frame:SetPoint('TOPRIGHT', anchor, 'TOPRIGHT', -STATS_SCROLL_PAD, 0)
                contentHeight = frame:GetHeight()
            end
            prevIsHeader = isHeader
            prev = frame
        else
            frame:Hide()
        end
    end
    self.contentHeight = contentHeight + 4
    self:UpdateScroll()
end
