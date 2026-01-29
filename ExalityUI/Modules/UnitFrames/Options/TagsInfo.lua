---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIUnitFramesOptionsTagsInfo
local tagsInfo = EXUI:GetModule('uf-options-tags-info')

tagsInfo.window = nil
tagsInfo.descriptions = {
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
    ['classcolor:name'] = 'Name colored by their class',
}

-- Expose tag descriptions to allow for custom tags descriptions to be added
ExalityUI.oUF.TagDescriptions = tagsInfo.descriptions

local function CreateItem(tagName, parent)
    local item = CreateFrame('Frame', nil, parent)
    item:SetHeight(20)
    local modifiedTag = string.format('[%s]', tagName)
    local editBox
    local function onChange()
        editBox:SetEditorValue(modifiedTag) -- Prevent changing
    end
    editBox = EXFrames:GetFrame('edit-box-input'):Create({
        label = '',
        initial = modifiedTag,
        onChange = onChange
    }, item)
    editBox:SetHeight(40)
    editBox:SetWidth(160)
    editBox:SetPoint('LEFT')

    if (tagsInfo.descriptions[tagName]) then
        local description = item:CreateFontString(nil, 'OVERLAY')
        description:SetFont(EXFrames.assets.font.default(), 10, 'OUTLINE')
        description:SetText(tagsInfo.descriptions[tagName])
        description:SetPoint('LEFT', editBox, 'RIGHT', 10, -7)
        description:SetWidth(0)
        item.description = description
    end
    item:Show()
    return item
end


tagsInfo.Create = function(self)
    self.window = EXFrames:GetFrame('window-frame'):Create({
        size = { 600, 600 },
        title = 'Tags Info'
    })
    local container = self.window.container
    local scrollFrame = EXFrames:GetFrame('scroll-frame'):Create()
    scrollFrame:SetParent(container)
    scrollFrame:SetPoint('TOPLEFT', 0, -10)
    scrollFrame:SetPoint('BOTTOMRIGHT', -30, 10)
    self.window.scrollFrame = scrollFrame

    local child = scrollFrame.child

    local items = {}

    for tagName in pairs(EXUI.oUF.Tags.Events) do
        table.insert(items, CreateItem(tagName, child))
    end

    EXUI.utils.organizeFramesInList(items, 10, child)
end

tagsInfo.Show = function(self)
    if (not self.window) then
        self:Create()
    end

    self.window:ShowWindow()
    self.window.scrollFrame:UpdateScrollChild(self.window.container:GetWidth() - 30,
        self.window.container:GetHeight() - 20)
end
