---@class ExalityUI
local EXUI = select(2, ...)

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

tags.TAGS = {
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
