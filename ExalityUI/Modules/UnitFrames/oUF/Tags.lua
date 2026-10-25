---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')


---@class EXUIoUFTags
local tags = EXUI:GetModule('oUF-Tags')

tags.DESCRIPTIONS = {
    ['smartlevel'] = 'Level with Classification',
    ['powercolor'] = 'Power Color, can be used as modified before other tags',
    ['rare'] = 'Shows "Rare" if the unit is rare or rare elite',
    ['status'] = 'Status of the unit. E.g. Dead/Ghost/Offline',
    ['level'] = 'Unit Level',
    ['runes'] = 'Active Rune Count',
    ['curpp'] = 'Current Power in %',
    ['missingpp'] = 'Missing Power in %',
    ['affix'] = 'Affixed mobs',
    ['name'] = 'Unit Name',
    ['pvp'] = 'Unit is flagged for PvP',
    ['curhp'] = 'Unit Health',
    ['leaderlong'] = 'Leader Text',
    ['threatcolor'] = 'Threat Color, can be used as modified before other tags',
    ['group'] = 'Group Number',
    ['leader'] = 'Leader Text Short',
    ['resting'] = 'Shows "zzz" if the player is resting',
    ['shortclassification'] = 'Unit Classification Short',
    ['threat'] = 'Threat level',
    ['soulshards'] = 'Soul Shards Count',
    ['holypower'] = 'Holy Power Count',
    ['dead'] = 'Shows "Dead" if the unit is dead or "Ghost" if the unit is a ghost',
    ['cpoints'] = 'Combo Points Count',
    ['arenaspec'] = 'Arena Opponent Specialization',
    ['perpp'] = 'Unit Power in %',
    ['maxhp'] = 'Max Health',
    ['perhp'] = 'Health in %',
    ['perhp:decimal'] = 'Health in %, up to 2 decimals',
    ['perhp:1'] = 'Health in %, 1 decimal',
    ['perhp:2'] = 'Health in %, 2 decimals',
    ['offline'] = 'Shows "Offline" if the unit is not connected to the server',
    ['missinghp'] = 'Missing Health',
    ['chi'] = 'Chi Count',
    ['difficulty'] = 'Add difficulty color (attackable units only) to the next tag. e.g [difficulty][level]',
    ['arcanecharges'] = 'Arcane Charges Count',
    ['plus'] = 'Shows "+" if the unit is elite or rare elite',
    ['faction'] = 'Unit Faction',
    ['maxmana'] = 'Max Mana',
    ['maxpp'] = 'Max Power',
    ['curmana'] = 'Current Mana',
    ['classification'] = 'Unit Classification',

    -- Custom
    ['curhp:formatted'] = 'Current Health in abbreviated format',
    ['classcolor'] = 'Add Class Color to the next tag. e.g [classcolor][name]',
    ['difficultycolor'] = 'Add level difficulty color to the next tag for any unit. e.g [difficultycolor][level]',
    ['nsrt-name'] = 'Nickname provided by Northern Sky Raid Tools addon'
}

local classMarkup = {}
local whiteMarkup

local function formatPerhp(unit, decimals)
    local pct = UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
    local text = string.format('%.' .. decimals .. 'f', pct)
    if decimals > 0 then
        text = text:gsub('0+$', ''):gsub('%.$', '')
    end
    return text
end

tags.TAGS = {
    {
        name = 'perhp:decimal',
        method = function(unit)
            return formatPerhp(unit, 2)
        end,
        events = 'UNIT_HEALTH UNIT_MAXHEALTH',
    },
    {
        name = 'perhp:1',
        method = function(unit)
            return string.format('%.1f', UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
        end,
        events = 'UNIT_HEALTH UNIT_MAXHEALTH',
    },
    {
        name = 'perhp:2',
        method = function(unit)
            return string.format('%.2f', UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
        end,
        events = 'UNIT_HEALTH UNIT_MAXHEALTH',
    },
    {
        name = 'curhp:formatted',
        method = function(unit)
            return AbbreviateNumbers(UnitHealth(unit))
        end,
        events = 'UNIT_HEALTH UNIT_MAXHEALTH'
    },
    {
        name = 'classcolor',
        method = function(unit)
            local _, class = UnitClass(unit)
            if (class) then
                local markup = classMarkup[class]
                if not markup then
                    markup = C_ClassColor.GetClassColor(class):GenerateHexColorMarkup()
                    classMarkup[class] = markup
                end
                return markup
            end
            if not whiteMarkup then
                whiteMarkup = CreateColor(1, 1, 1):GenerateHexColorMarkup()
            end
            return whiteMarkup
        end,
        events = 'UNIT_NAME_UPDATE'
    },
    {
        name = 'difficultycolor',
        method = function(unit)
            local level = UnitEffectiveLevel(unit)
            local color = GetCreatureDifficultyColor((level and level > 0) and level or 999)
            return string.format('|cff%02x%02x%02x', color.r * 255, color.g * 255, color.b * 255)
        end,
        events = 'UNIT_LEVEL PLAYER_LEVEL_UP'
    },
    {
        name = 'nsrt-name',
        method = function(unit)
            local name, surnameF = UnitName(unit)
            local nameFormatted = name
            if (EXUI:IsForever()) then
                nameFormatted = string.format('%s %s', name, surnameF)
            end
            if (not NSAPI) then
                return nameFormatted
            end
            return NSAPI:GetName(nameFormatted, 'GlobalNickNames')
        end,
        events = 'UNIT_NAME_UPDATE'
    }
}

-- Mirrors oUF's bracket parsing ([prefix$>tag<$suffix(args)]) so options can skip invalid tags
local function GetBracketTagName(bracket)
    local prefixEnd, prefixOffset = bracket:match('()$>'), 1
    if (not prefixEnd) then
        prefixEnd = 1
    else
        prefixEnd = prefixEnd - 1
        prefixOffset = 3
    end

    local suffixEnd = (bracket:match('()%(', prefixOffset + 1) or -1) - 1
    local suffixStart, suffixOffset = bracket:match('<$()', prefixEnd), 1
    if (not suffixStart) then
        suffixStart = suffixEnd + 1
    else
        suffixOffset = 3
    end

    return bracket:sub(prefixEnd + prefixOffset, suffixStart - suffixOffset)
end

tags.IsValidTagString = function(self, tagString)
    if (not tagString) then
        return true
    end
    local methods = EXUI.oUF.Tags.Methods
    for bracket in tagString:gmatch('%[..-%]+') do
        if (not methods[bracket:sub(2, -2)] and not methods[GetBracketTagName(bracket)]) then
            return false
        end
    end
    return true
end

tags.Init = function(self)
    self:RegisterNSRTCallback()
end

EXUI:RegisterEventHandler('ADDON_LOADED', 'NSRT-Loaded', function(event, addonName)
    if (addonName == 'NorthernSkyRaidTools') then
        tags:RegisterNSRTCallback()
    end
end)

local callbackRegistered = false
tags.RegisterNSRTCallback = function(self)
    if (not callbackRegistered and NSAPI and NSAPI.RegisterCallback) then
        callbackRegistered = true
        NSAPI:RegisterCallback("NSRT_NICKNAME_UPDATED", function()
            ufCore:UpdateAllFrames()
        end, 'ExalityUI')
    end
end

tags.RegisterCustomTags = function(self)
    for _, tag in ipairs(self.TAGS) do
        EXUI.oUF.Tags.Methods[tag.name] = tag.method
        EXUI.oUF.Tags.Events[tag.name] = tag.events
    end
end


-- Expose oUF Tags table to allow for custom tags to be added
ExalityUI.oUF = {
    Tags = EXUI.oUF.Tags,
    TagDescriptions = tags.DESCRIPTIONS,
}
