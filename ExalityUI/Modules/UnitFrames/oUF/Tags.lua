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
    ['difficulty'] = 'Shows the difficulty of the unit',
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
    ['nsrt-name'] = 'Nickname provided by Northern Sky Raid Tools addon'
}

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
            local currHP = UnitHealth(unit)

            return AbbreviateNumbers(currHP)
        end,
        events = 'UNIT_HEALTH UNIT_MAXHEALTH'
    },
    {
        name = 'classcolor',
        method = function(unit)
            local _, class = UnitClass(unit)
            if (class) then
                local classColor = C_ClassColor.GetClassColor(class)
                return classColor:GenerateHexColorMarkup()
            end
            local white = CreateColor(1, 1, 1)
            return white:GenerateHexColorMarkup()
        end,
        events = 'UNIT_NAME_UPDATE'
    },
    {
        name = 'nsrt-name',
        method = function(unit)
            local name = UnitName(unit)
            if (not NSAPI) then
                return name
            end
            return NSAPI:GetName(name, 'GlobalNickNames')
        end,
        events = 'UNIT_NAME_UPDATE'
    }
}

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
