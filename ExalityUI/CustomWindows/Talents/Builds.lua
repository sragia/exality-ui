---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')

---@class EXUITalentsBuilds
local builds = EXUI:GetModule('talents-builds')

local SIDEBAR_WIDTH = 290
local SIDEBAR_GAP = 6
local CONTENT_PAD = 10
local HEADER_HEIGHT = 22
local ROW_ICON = 32
local ROW_BORDER = ROW_ICON * (96 / 82)
local ROW_HEIGHT = 40
local ROW_GAP = 2
local HEADER_GOLD = { 235 / 255, 183 / 255, 52 / 255, 1 }
local RECENT_LIMIT = 5
local ICON_SIZE = 30
local ICON_PAD = 4
local ICON_COLUMNS = 7
local ICON_POOL_EXTRA_ROWS = 2

local TEX = {
    selected = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-selected.png]],
    unselected = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-unselected.png]],
    mask = [[Interface/Addons/ExalityUI/Assets/Images/Talents/talent-mask.png]],
    save = [[Interface/Addons/ExalityUI/Assets/Images/Talents/save-build.png]],
    load = [[Interface/Addons/ExalityUI/Assets/Images/Talents/load-build.png]],
}

builds.rows = {}
builds.iconButtons = {}
builds.iconColumns = ICON_COLUMNS
builds.iconCount = 0
builds.lastIconScrollOffset = -1
builds.lastIconStartRow = -1

local function ThemeColor(key)
    return EXUI.const.theme[key]
end

local function CurrentSpecID()
    local specIndex = C_SpecializationInfo.GetSpecialization()
    if (not specIndex) then
        return nil
    end
    return (select(1, C_SpecializationInfo.GetSpecializationInfo(specIndex)))
end

local function CurrentSpecIcon()
    local specIndex = C_SpecializationInfo.GetSpecialization()
    if (not specIndex) then
        return 134400
    end
    return select(4, C_SpecializationInfo.GetSpecializationInfo(specIndex)) or 134400
end

local function CurrentSpecName()
    local specIndex = C_SpecializationInfo.GetSpecialization()
    if (not specIndex) then
        return 'Talents'
    end
    return select(2, C_SpecializationInfo.GetSpecializationInfo(specIndex)) or 'Talents'
end

local function LoadStore()
    local store = customWindows.Data:GetValue('TalentBuilds')
    if (type(store) ~= 'table') then
        store = {}
    end
    return store
end

local function CellSize()
    return ICON_SIZE + ICON_PAD
end

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function IsSavedImport(bucket, importString)
    for _, entry in ipairs(bucket.saved) do
        if (entry.importString == importString) then
            return true
        end
    end
    return false
end

local function KeyActivity(mapID)
    if (not mapID and C_ChallengeMode.GetActiveChallengeMapID) then
        mapID = C_ChallengeMode.GetActiveChallengeMapID()
    end
    if (not mapID or IsSecret(mapID) or not C_ChallengeMode.GetMapUIInfo) then
        return nil
    end
    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    if (not name or name == '' or IsSecret(name)) then
        return nil
    end
    local level = C_ChallengeMode.GetActiveKeystoneInfo and C_ChallengeMode.GetActiveKeystoneInfo()
    if (level and level > 0 and not IsSecret(level)) then
        return '+' .. level .. ' ' .. name
    end
    return name
end

local function RaidActivity(encounterName)
    if (not encounterName or encounterName == '' or IsSecret(encounterName)) then
        return nil
    end
    local _, instanceType, _, difficultyName = GetInstanceInfo()
    if (IsSecret(instanceType) or instanceType ~= 'raid') then
        return nil
    end
    if (difficultyName and difficultyName ~= '' and not IsSecret(difficultyName)) then
        return difficultyName .. ' · ' .. encounterName
    end
    return encounterName
end

local function DelveActivity()
    if (not C_DelvesUI or not C_DelvesUI.HasActiveDelve or not C_DelvesUI.HasActiveDelve()) then
        return nil
    end
    local name = GetInstanceInfo()
    if (not name or name == '' or IsSecret(name)) then
        return nil
    end
    local tierInfo = C_DelvesUI.GetActiveDelveTier and C_DelvesUI.GetActiveDelveTier()
    local tier = tierInfo and tierInfo.tier
    if (tier and tier > 0 and not IsSecret(tier)) then
        return name .. ' · ' .. tier
    end
    return name
end

local function ActiveHero(specID)
    local configID = C_ClassTalents.GetActiveConfigID()
    if (not configID or not specID or not C_ClassTalents.GetHeroTalentSpecsForClassSpec) then
        return nil
    end
    local subTreeIDs = C_ClassTalents.GetHeroTalentSpecsForClassSpec(configID, specID)
    if (not subTreeIDs) then
        return nil
    end
    for _, subTreeID in ipairs(subTreeIDs) do
        local info = C_Traits.GetSubTreeInfo(configID, subTreeID)
        if (info and info.isActive and info.name and info.name ~= '' and not IsSecret(info.name)) then
            local icon = info.iconElementID
            if (not icon or icon == '' or IsSecret(icon)) then
                icon = nil
            end
            return info.name, icon
        end
    end
end

local function CurrentActivity()
    local key = KeyActivity()
    if (key) then
        return key
    end
    if (builds.activeEncounterName and IsEncounterInProgress and IsEncounterInProgress()) then
        local raid = RaidActivity(builds.activeEncounterName)
        if (raid) then
            return raid
        end
    end
    return DelveActivity()
end

builds.Bucket = function(self, specID)
    local store = LoadStore()
    local key = tostring(specID)
    local bucket = store[key]
    if (type(bucket) ~= 'table') then
        bucket = { saved = {}, recent = {} }
        store[key] = bucket
    end
    if (type(bucket.saved) ~= 'table') then
        bucket.saved = {}
    end
    if (type(bucket.recent) ~= 'table') then
        bucket.recent = {}
    end
    self.store = store
    return bucket
end

builds.Save = function(self)
    if (self.store) then
        customWindows.Data:SetValue('TalentBuilds', self.store)
    end
end

builds.CurrentImportString = function(self)
    local configID = C_ClassTalents.GetActiveConfigID()
    if (not configID or not C_Traits.GenerateImportString) then
        return nil
    end
    return C_Traits.GenerateImportString(configID)
end

builds.RecordApplied = function(self, importString)
    local specID = CurrentSpecID()
    if (not specID or not importString or importString == '') then
        return
    end
    local bucket = self:Bucket(specID)
    if (IsSavedImport(bucket, importString)) then
        return
    end
    local recent = bucket.recent
    if (recent[1] and recent[1].importString == importString) then
        return
    end
    local heroName, heroIcon = ActiveHero(specID)
    local entry = {
        name = (heroName or CurrentSpecName()) .. ' ' .. date('%H:%M'),
        icon = heroIcon or CurrentSpecIcon(),
        importString = importString,
    }
    local activity = CurrentActivity()
    if (activity) then
        entry.activity = activity
    end
    table.insert(recent, 1, entry)
    while (#recent > RECENT_LIMIT) do
        table.remove(recent)
    end
    self:Save()
    self:Refresh()
end

builds.NoteActivity = function(self, label)
    if (not label or label == '' or IsSecret(label)) then
        return
    end
    local specID = CurrentSpecID()
    local importString = self:CurrentImportString()
    if (not specID or not importString or importString == '') then
        return
    end
    local bucket = self:Bucket(specID)
    for _, entry in ipairs(bucket.recent) do
        if (entry.importString == importString) then
            if (entry.activity == label) then
                return
            end
            entry.activity = label
            self:Save()
            self:Refresh()
            return
        end
    end
end

builds.SaveCurrent = function(self, name, icon)
    local specID = CurrentSpecID()
    local importString = self:CurrentImportString()
    if (not specID or not importString or importString == '') then
        return false
    end
    local bucket = self:Bucket(specID)
    bucket.saved[#bucket.saved + 1] = {
        id = tostring(time()) .. tostring(math.random(1000, 9999)),
        name = name,
        icon = icon or CurrentSpecIcon(),
        importString = importString,
    }
    self:Save()
    self:Refresh()
    return true
end

builds.UpdateMeta = function(self, id, name, icon)
    local specID = CurrentSpecID()
    if (not specID) then
        return
    end
    local bucket = self:Bucket(specID)
    for _, entry in ipairs(bucket.saved) do
        if (entry.id == id) then
            entry.name = name
            entry.icon = icon or entry.icon
            break
        end
    end
    self:Save()
    self:Refresh()
end

builds.Resave = function(self, id)
    local specID = CurrentSpecID()
    local importString = self:CurrentImportString()
    if (not specID or not importString or importString == '') then
        return
    end
    local bucket = self:Bucket(specID)
    for _, entry in ipairs(bucket.saved) do
        if (entry.id == id) then
            entry.importString = importString
            break
        end
    end
    self:Save()
    self:Refresh()
end

builds.Delete = function(self, id)
    local specID = CurrentSpecID()
    if (not specID) then
        return
    end
    local bucket = self:Bucket(specID)
    for index, entry in ipairs(bucket.saved) do
        if (entry.id == id) then
            table.remove(bucket.saved, index)
            break
        end
    end
    self:Save()
    self:Refresh()
end

builds.ConsumePendingConfig = function()
end

local TEMP_CONFIG_NAME = '^EXUI%d+$'

local function IsTempConfigName(name)
    return type(name) == 'string' and name:match(TEMP_CONFIG_NAME) ~= nil
end

builds.RemoveTempConfigs = function()
    local classID = select(3, UnitClass('player'))
    if (not classID or not C_ClassTalents.GetConfigIDsBySpecID or not GetSpecializationInfoForClassID) then
        return
    end
    local numSpecs = C_SpecializationInfo.GetNumSpecializationsForClassID(classID) or 0
    for index = 1, numSpecs do
        local specID = GetSpecializationInfoForClassID(classID, index)
        if (specID) then
            local selectedID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
            local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
            if (configIDs) then
                for _, configID in ipairs(configIDs) do
                    local info = C_Traits.GetConfigInfo(configID)
                    if (info and IsTempConfigName(info.name)) then
                        if (selectedID == configID) then
                            C_ClassTalents.UpdateLastSelectedSavedConfigID(specID, nil)
                            selectedID = nil
                        end
                        C_ClassTalents.DeleteConfig(configID)
                    end
                end
            end
        end
    end
end

local function NotifyTalents()
    local talents = EXUI:GetModule('talents-window')
    if (talents.QueueRefresh) then
        talents:QueueRefresh()
    end
end

builds.ShowStageError = function(self, message)
    if (self.importDialog and self.importDialog:IsShown()) then
        self.importDialog.errorText:SetText(message or '')
        return
    end
    UIErrorsFrame:AddMessage(message or 'Import failed.', 1, 0.2, 0.2, 1)
end

builds.AfterStage = function(self)
    if (self.importDialog) then
        self.importDialog:Hide()
    end
    NotifyTalents()
end

local function DesiredNodes(entries)
    local desired = {}
    for _, entry in ipairs(entries) do
        local goal = desired[entry.nodeID]
        if (not goal) then
            goal = { ranks = 0 }
            desired[entry.nodeID] = goal
        end
        goal.ranks = goal.ranks + (entry.ranksPurchased or 0)
        if (entry.selectionEntryID) then
            goal.selectionEntryID = entry.selectionEntryID
        end
    end
    return desired
end

local function StageEntries(configID, treeID, entries)
    if (not C_ClassTalents.CanEditTalents()) then
        return 'Talents cannot be edited right now.'
    end
    C_Traits.RollbackConfig(configID)
    if (not C_Traits.ResetTree(configID, treeID)) then
        return 'Could not stage that talent build.'
    end

    local desired = DesiredNodes(entries)
    local guard = 0
    local changed = true
    while (changed and guard < 80) do
        changed = false
        guard = guard + 1
        for nodeID, goal in pairs(desired) do
            local info = C_Traits.GetNodeInfo(configID, nodeID)
            if (info) then
                local isChoice = info.type == Enum.TraitNodeType.Selection or
                info.type == Enum.TraitNodeType.SubTreeSelection
                local activeEntry = info.activeEntry and info.activeEntry.entryID
                if (isChoice and goal.selectionEntryID and activeEntry ~= goal.selectionEntryID) then
                    if (C_Traits.SetSelection(configID, nodeID, goal.selectionEntryID)) then
                        changed = true
                        info = C_Traits.GetNodeInfo(configID, nodeID) or info
                    end
                end
                if (info.type ~= Enum.TraitNodeType.SubTreeSelection and (info.ranksPurchased or 0) < goal.ranks) then
                    if (C_Traits.PurchaseRank(configID, nodeID)) then
                        changed = true
                    end
                end
            end
        end
    end

    for nodeID, goal in pairs(desired) do
        local info = C_Traits.GetNodeInfo(configID, nodeID)
        local activeEntry = info and info.activeEntry and info.activeEntry.entryID
        local missingChoice = info and goal.selectionEntryID and
        (info.type == Enum.TraitNodeType.Selection or info.type == Enum.TraitNodeType.SubTreeSelection) and
        activeEntry ~= goal.selectionEntryID
        local missingRanks = info and info.type ~= Enum.TraitNodeType.SubTreeSelection and
        (info.ranksPurchased or 0) < goal.ranks
        if (not info or missingChoice or missingRanks) then
            C_Traits.RollbackConfig(configID)
            return 'Could not stage that talent build.'
        end
    end
    return nil
end

builds.StageImportString = function(self, importText)
    C_AddOns.LoadAddOn('Blizzard_PlayerSpells')
    if (not ClassTalentImportExportMixin or not ExportUtil) then
        return 'Import is not available yet.'
    end
    importText = (importText or ''):gsub('%s+', '')
    if (importText == '') then
        return 'Paste a talent string first.'
    end

    local configID = C_ClassTalents.GetActiveConfigID()
    local specID = CurrentSpecID()
    local treeID = specID and C_ClassTalents.GetTraitTreeForSpec(specID)
    if (not configID or not treeID) then
        return 'Talents are not available yet.'
    end

    local importer = CreateFromMixins(ClassTalentImportExportMixin)
    importer.GetConfigID = function()
        return configID
    end
    importer.GetTreeInfo = function()
        return C_Traits.GetTreeInfo(configID, treeID) or { ID = treeID }
    end
    local streamOk, importStream = pcall(ExportUtil.MakeImportDataStream, importText)
    if (not streamOk or not importStream) then
        return 'That talent string is not valid.'
    end
    local headerOk, headerValid, serializationVersion, headerSpecID, treeHash = pcall(importer.ReadLoadoutHeader,
        importer, importStream)
    if (not headerOk or not headerValid) then
        return 'That talent string is not valid.'
    end
    if (serializationVersion ~= C_Traits.GetLoadoutSerializationVersion()) then
        return 'That talent string is out of date.'
    end
    if (headerSpecID ~= specID) then
        return 'That talent string is for a different specialization.'
    end
    local currentHash = C_Traits.GetTreeHash(treeID)
    if (currentHash and not importer:IsHashEmpty(treeHash) and not importer:HashEquals(treeHash, currentHash)) then
        return 'That talent string does not match the current talent tree.'
    end

    local ok, loadoutContent = pcall(importer.ReadLoadoutContent, importer, importStream, treeID)
    if (not ok or not loadoutContent) then
        return 'That talent string is not valid.'
    end
    local converted, entries = pcall(importer.ConvertToImportLoadoutEntryInfo, importer, configID, treeID, loadoutContent)
    if (not converted or not entries) then
        return 'That talent string is not valid.'
    end
    local stageError = StageEntries(configID, treeID, entries)
    if (stageError) then
        return stageError
    end
    self:AfterStage()
    return nil
end

local function ApplyBuildRowVisual(row, hovered)
    local theme = EXUI.const.theme
    if (hovered) then
        row.border:SetBorderColor(0.55, 0.55, 0.55, 1)
        row.bg:SetVertexColor(0.2, 0.2, 0.2, 0.7)
    else
        row.border:SetBorderColor(unpack(theme.border))
        row.bg:SetVertexColor(0, 0, 0, 0.55)
    end
end

local function IconAction(parent, texture, tooltipText, size)
    local button = CreateFrame('Button', nil, parent)
    button:SetSize(size, size)
    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    icon:SetTexture(texture)
    icon:SetAlpha(0.85)
    button.Icon = icon
    button:SetScript('OnEnter', function(self)
        self.Icon:SetAlpha(1)
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetText(tooltipText)
        GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function(self)
        self.Icon:SetAlpha(0.85)
        GameTooltip:Hide()
    end)
    return button
end

local function SmallButton(parent, label)
    local button = CreateFrame('Button', nil, parent)
    button:SetSize(52, 22)
    local bg = button:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXUI.const.textures.frame.inputs.buttonBg)
    bg:SetTextureSliceMargins(20, 20, 20, 20)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
    bg:SetAllPoints()
    button.bg = bg
    local text = button:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')
    text:SetPoint('CENTER')
    text:SetText(label)
    button.Text = text
    button:SetScript('OnEnter', function(self)
        self.bg:SetVertexColor(60 / 255, 60 / 255, 60 / 255, 1)
    end)
    button:SetScript('OnLeave', function(self)
        self.bg:SetVertexColor(40 / 255, 40 / 255, 40 / 255, 1)
    end)
    return button
end

local function StyleIcon(button, size)
    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(ROW_ICON, ROW_ICON)
    icon:SetPoint('CENTER')
    button.Icon = icon
    local mask = button:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)
    local border = button:CreateTexture(nil, 'OVERLAY')
    border:SetSize(ROW_BORDER, ROW_BORDER)
    border:SetPoint('CENTER')
    border:SetTexture(TEX.unselected)
    button.Border = border
    button:SetSize(size or ROW_BORDER, size or ROW_BORDER)
end

builds.AcquireRow = function(self, index)
    local row = self.rows[index]
    if (row) then
        return row
    end
    local parent = self.scrollChild
    row = CreateFrame('Frame', nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row.bg = row:CreateTexture(nil, 'BACKGROUND')
    row.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    row.bg:SetAllPoints()
    row.border = EXUI:AddPixelPerfectBorder(row, 1, { register = false, outwardBottom = false })
    row.border:SetBorderColor(unpack(ThemeColor('border')))
    ApplyBuildRowVisual(row, false)

    local function ShowRowHover()
        ApplyBuildRowVisual(row, true)
    end
    local function HideRowHover()
        ApplyBuildRowVisual(row, false)
    end

    local iconButton = CreateFrame('Button', nil, row)
    StyleIcon(iconButton)
    iconButton:SetPoint('LEFT', 6, 0)
    row.IconButton = iconButton

    local loadButton = IconAction(row, TEX.load, 'Load', 22)
    loadButton:SetPoint('RIGHT', -8, 0)
    row.LoadButton = loadButton

    local resaveButton = IconAction(row, TEX.save, 'Resave', 16)
    resaveButton:SetPoint('RIGHT', loadButton, 'LEFT', -8, 0)
    row.ResaveButton = resaveButton

    local nameButton = CreateFrame('Button', nil, row)
    nameButton:SetPoint('LEFT', iconButton, 'RIGHT', 6, 0)
    nameButton:SetPoint('RIGHT', resaveButton, 'LEFT', -6, 0)
    nameButton:SetHeight(ROW_HEIGHT)
    local nameText = nameButton:CreateFontString(nil, 'OVERLAY')
    nameText:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    nameText:SetPoint('LEFT')
    nameText:SetPoint('RIGHT')
    nameText:SetJustifyH('LEFT')
    nameText:SetWordWrap(false)
    nameText:SetTextColor(unpack(ThemeColor('text')))
    nameButton.Text = nameText
    local activityText = nameButton:CreateFontString(nil, 'OVERLAY')
    activityText:SetFont(EXFrames.assets.font.default(), 10, 'OUTLINE')
    activityText:SetPoint('BOTTOMLEFT', 0, 4)
    activityText:SetPoint('BOTTOMRIGHT', 0, 4)
    activityText:SetJustifyH('LEFT')
    activityText:SetWordWrap(false)
    activityText:SetTextColor(unpack(ThemeColor('textMuted')))
    activityText:Hide()
    nameButton.Activity = activityText
    row.NameButton = nameButton

    iconButton:SetScript('OnEnter', ShowRowHover)
    iconButton:SetScript('OnLeave', HideRowHover)
    nameButton:SetScript('OnEnter', ShowRowHover)
    nameButton:SetScript('OnLeave', HideRowHover)
    loadButton:HookScript('OnEnter', ShowRowHover)
    loadButton:HookScript('OnLeave', HideRowHover)
    resaveButton:HookScript('OnEnter', ShowRowHover)
    resaveButton:HookScript('OnLeave', HideRowHover)
    iconButton:SetScript('OnClick', function()
        if (row.entry and row.entry.id) then
            builds:ShowEdit(row.entry)
        end
    end)
    nameButton:SetScript('OnClick', function()
        if (row.entry and row.entry.id) then
            builds:ShowEdit(row.entry)
        end
    end)
    loadButton:SetScript('OnClick', function()
        if (row.entry) then
            local err = builds:StageImportString(row.entry.importString)
            if (err) then
                builds:ShowStageError(err)
            end
        end
    end)
    resaveButton:SetScript('OnClick', function()
        if (row.entry and row.entry.id) then
            builds:Resave(row.entry.id)
        end
    end)

    self.rows[index] = row
    return row
end

local function ApplyIcon(texture, icon)
    if (type(icon) == 'string' and not icon:find('\\', 1, true) and not icon:find('/', 1, true)) then
        texture:SetAtlas(icon)
    else
        texture:SetTexture(icon or 134400)
    end
end

local function SetRowIcon(icon, value)
    ApplyIcon(icon, value)
    icon:SetSize(ROW_ICON, ROW_ICON)
end

local function AddUniqueIcon(list, seen, icon)
    if (not icon or icon == '' or icon == 'Interface\\EncounterJournal\\UI-EJ-BOSS-Default' or seen[icon] or IsSecret(icon)) then
        return
    end
    seen[icon] = true
    list[#list + 1] = icon
end

local function CollectHeroIcons(list, seen)
    local classID = select(3, UnitClass('player'))
    if (not classID or not GetSpecializationInfoForClassID or not C_ClassTalents.GetHeroTalentSpecsForClassSpec) then
        return
    end
    local configID = C_ClassTalents.GetActiveConfigID()
    local numSpecs = C_SpecializationInfo.GetNumSpecializationsForClassID(classID) or 0
    for specIndex = 1, numSpecs do
        local specID = GetSpecializationInfoForClassID(classID, specIndex)
        local subTreeIDs = specID and C_ClassTalents.GetHeroTalentSpecsForClassSpec(configID, specID)
        if (subTreeIDs) then
            for _, subTreeID in ipairs(subTreeIDs) do
                local info = configID and C_Traits.GetSubTreeInfo(configID, subTreeID)
                if (info) then
                    AddUniqueIcon(list, seen, info.iconElementID)
                end
            end
        end
    end
end

local RAID_BOSS_ICONS = {
    7966621, -- Nek'zali the Soulcoiler
    7966620, -- Entombed Sentinels
    7966622, -- The Lost Explorers
    7966618, -- Vashnik the Malignant
    7966619, -- Sszorak
    7966623, -- The Twin Fangs
    7966625, -- The Coiled Altar
    7966624, -- Ula'tek
    3012069, -- Nymrissa Wavecaller
}

local function CollectRaidBossIcons(list, seen)
    for _, icon in ipairs(RAID_BOSS_ICONS) do
        AddUniqueIcon(list, seen, icon)
    end
end

local function PickerPrefix()
    if (builds.pickerPrefix) then
        return builds.pickerPrefix
    end
    local list = {}
    local seen = {}
    CollectHeroIcons(list, seen)
    CollectRaidBossIcons(list, seen)
    builds.pickerPrefix = list
    return list
end

local function PickerIconAt(index)
    local prefix = builds.pickerPrefix
    local prefixCount = prefix and #prefix or 0
    if (index <= prefixCount) then
        return prefix[index]
    end
    return builds.iconProvider:GetIconByIndex(index - prefixCount)
end

local function ShowRowActivity(row, activity)
    local text = row.NameButton.Text
    local sub = row.NameButton.Activity
    text:ClearAllPoints()
    if (activity and activity ~= '') then
        text:SetPoint('TOPLEFT', 0, -8)
        text:SetPoint('TOPRIGHT', 0, -8)
        sub:ClearAllPoints()
        sub:SetPoint('TOPLEFT', text, 'BOTTOMLEFT', 0, -1)
        sub:SetPoint('TOPRIGHT', text, 'BOTTOMRIGHT', 0, -1)
        sub:SetText(activity)
        sub:Show()
    else
        text:SetPoint('LEFT')
        text:SetPoint('RIGHT')
        sub:Hide()
    end
end

builds.UpdateCurrentBorder = function(self)
    if (not self.sidebar or not self.sidebar:IsShown()) then
        return
    end
    local current = self:CurrentImportString()
    for _, row in ipairs(self.rows) do
        if (row:IsShown() and row.IconButton) then
            local active = row.entry and current and row.entry.importString == current
            row.IconButton.Border:SetTexture(active and TEX.selected or TEX.unselected)
        end
    end
end

builds.Refresh = function(self)
    if (not self.scrollChild) then
        return
    end
    local specID = CurrentSpecID()
    local saved, recent = {}, {}
    if (specID) then
        local bucket = self:Bucket(specID)
        saved = bucket.saved
        recent = bucket.recent
    end

    local y = -2
    self.savedHeader:ClearAllPoints()
    self.savedHeader:SetPoint('TOPLEFT', 2, y)
    self.savedHeader:SetPoint('TOPRIGHT', -2, y)
    self.savedHeader:Show()
    y = y - HEADER_HEIGHT - ROW_GAP

    local rowIndex = 0
    if (#saved == 0) then
        y = y - 8
        self.emptySaved:ClearAllPoints()
        self.emptySaved:SetPoint('TOPLEFT', 8, y)
        self.emptySaved:Show()
        y = y - 18
    else
        self.emptySaved:Hide()
    end

    for _, entry in ipairs(saved) do
        rowIndex = rowIndex + 1
        local row = self:AcquireRow(rowIndex)
        row.entry = entry
        SetRowIcon(row.IconButton.Icon, entry.icon)
        row.NameButton.Text:SetText(entry.name or 'Build')
        ShowRowActivity(row, nil)
        row.ResaveButton:Show()
        row.NameButton:SetPoint('RIGHT', row.ResaveButton, 'LEFT', -6, 0)
        row:ClearAllPoints()
        row:SetPoint('TOPLEFT', 2, y)
        row:SetPoint('RIGHT', -2, 0)
        row:Show()
        y = y - ROW_HEIGHT - ROW_GAP
    end

    y = y - 6
    self.recentHeader:ClearAllPoints()
    self.recentHeader:SetPoint('TOPLEFT', 2, y)
    self.recentHeader:SetPoint('TOPRIGHT', -2, y)
    self.recentHeader:Show()
    y = y - HEADER_HEIGHT - ROW_GAP

    if (#recent == 0) then
        self.emptyRecent:SetPoint('TOPLEFT', 8, y)
        self.emptyRecent:Show()
        y = y - 18
    else
        self.emptyRecent:Hide()
    end

    for _, entry in ipairs(recent) do
        rowIndex = rowIndex + 1
        local row = self:AcquireRow(rowIndex)
        row.entry = entry
        SetRowIcon(row.IconButton.Icon, entry.icon)
        row.NameButton.Text:SetText(entry.name or 'Recent')
        ShowRowActivity(row, entry.activity)
        row.ResaveButton:Hide()
        row.NameButton:SetPoint('RIGHT', row.LoadButton, 'LEFT', -6, 0)
        row:ClearAllPoints()
        row:SetPoint('TOPLEFT', 2, y)
        row:SetPoint('RIGHT', -2, 0)
        row:Show()
        y = y - ROW_HEIGHT - ROW_GAP
    end

    for index = rowIndex + 1, #self.rows do
        self.rows[index]:Hide()
    end

    local height = math.max(-y + 8, 1)
    self.scrollChild:SetHeight(height)
    if (self.listScroll) then
        self.listScroll:UpdateScrollChild(nil, height)
    end
    self:UpdateCurrentBorder()
end

builds.HideEdit = function(self)
    if (self.editDialog) then
        self.editDialog:Hide()
    end
    if (self.iconProvider) then
        self.iconProvider:Release()
        self.iconProvider = nil
    end
    self.iconCount = 0
    self.lastIconScrollOffset = -1
    self.lastIconStartRow = -1
end

builds.AcquireIconButton = function(self, index)
    local button = self.iconButtons[index]
    if (button) then
        return button
    end
    local popup = self.editDialog
    button = CreateFrame('Button', nil, popup.iconScroll.child)
    button:SetSize(ICON_SIZE, ICON_SIZE)
    button.Texture = button:CreateTexture(nil, 'ARTWORK')
    button.Texture:SetAllPoints()
    button.border = EXUI:AddPixelPerfectBorder(button, 1, { register = false })
    button.border:SetBorderColor(unpack(ThemeColor('border')))
    button:SetScript('OnClick', function(btn)
        builds.selectedIcon = btn.iconValue
        ApplyIcon(popup.selectedIconTex, btn.iconValue)
        builds:RefreshVisibleIcons(true)
    end)
    self.iconButtons[index] = button
    return button
end

builds.RefreshVisibleIcons = function(self, force)
    local popup = self.editDialog
    local scroll = popup and popup.iconScroll
    if (not scroll or not self.iconProvider or self.iconCount <= 0) then
        return
    end
    local offset = scroll.scrollOffset or 0
    local viewHeight = scroll:GetHeight()
    if (viewHeight < 1 and scroll.content) then
        viewHeight = scroll.content:GetHeight()
    end
    if (viewHeight < 1) then
        viewHeight = 1
    end
    local cell = CellSize()
    local columns = self.iconColumns
    local startRow = math.max(0, math.floor(offset / cell) - 1)
    if (not force and startRow == self.lastIconStartRow and viewHeight == self.lastIconViewHeight) then
        return
    end
    self.lastIconStartRow = startRow
    self.lastIconScrollOffset = offset
    self.lastIconViewHeight = viewHeight
    local visibleRows = math.ceil(viewHeight / cell) + ICON_POOL_EXTRA_ROWS
    local startIndex = startRow * columns + 1
    local endIndex = math.min(self.iconCount, (startRow + visibleRows) * columns)
    local poolSize = visibleRows * columns

    for poolIndex = 1, poolSize do
        local iconIndex = startIndex + poolIndex - 1
        local button = self:AcquireIconButton(poolIndex)
        if (iconIndex <= endIndex) then
            local icon = PickerIconAt(iconIndex)
            button.iconValue = icon
            ApplyIcon(button.Texture, icon)
            button.Texture:SetAllPoints()
            local col = (iconIndex - 1) % columns
            local row = math.floor((iconIndex - 1) / columns)
            button:ClearAllPoints()
            button:SetPoint('TOPLEFT', scroll.child, 'TOPLEFT', col * cell, -row * cell)
            button:Show()
            if (icon == self.selectedIcon) then
                button.border:SetBorderColor(unpack(ThemeColor('accent')))
            else
                button.border:SetBorderColor(unpack(ThemeColor('border')))
            end
        else
            button:Hide()
        end
    end
    for index = poolSize + 1, #self.iconButtons do
        self.iconButtons[index]:Hide()
    end
end

builds.BuildIcons = function(self, selectedIcon)
    local popup = self.editDialog
    if (self.iconProvider) then
        self.iconProvider:Release()
    end
    local provider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Equipment)
    self.iconProvider = provider
    local prefix = PickerPrefix()
    self.iconCount = #prefix + provider:GetNumIcons()
    self.selectedIcon = selectedIcon or prefix[1] or provider:GetIconByIndex(1)
    ApplyIcon(popup.selectedIconTex, self.selectedIcon)

    local cell = CellSize()
    local rows = math.max(1, math.ceil(self.iconCount / self.iconColumns))
    local contentHeight = rows * cell
    local scroll = popup.iconScroll
    if (not scroll.iconExtent) then
        local extent = CreateFrame('Frame', nil, scroll.child)
        extent:SetWidth(1)
        scroll.iconExtent = extent
    end
    scroll:Reset()
    scroll.iconExtent:ClearAllPoints()
    scroll.iconExtent:SetPoint('TOPLEFT', scroll.child, 'TOPLEFT', 0, 0)
    scroll.iconExtent:SetHeight(contentHeight)
    scroll.iconExtent:Show()
    scroll.child:SetHeight(contentHeight)
    scroll:UpdateScrollChild(self.iconColumns * cell, contentHeight)
    self.lastIconScrollOffset = -1
    self.lastIconStartRow = -1
    self.lastIconViewHeight = nil
    self:RefreshVisibleIcons(true)
end

builds.ShowEdit = function(self, entry)
    local popup = self.editDialog
    if (not popup) then
        return
    end
    self.editingId = entry and entry.id or nil
    popup.title:SetText(entry and 'Edit build' or 'Save build')
    popup.nameEdit:SetText(entry and entry.name or '')
    popup.deleteButton:SetShown(entry ~= nil)
    popup:Show()
    popup.nameEdit:SetFocus()
    self:BuildIcons(entry and entry.icon or CurrentSpecIcon())
end

builds.ConfirmEdit = function(self)
    local popup = self.editDialog
    local name = strtrim(popup.nameEdit:GetText() or '')
    if (name == '') then
        return
    end
    if (self.editingId) then
        self:UpdateMeta(self.editingId, name, self.selectedIcon)
    else
        if (not self:SaveCurrent(name, self.selectedIcon)) then
            return
        end
    end
    self:HideEdit()
end

builds.CreateEditDialog = function(self)
    local theme = EXUI.const.theme
    local popup = CreateFrame('Frame', nil, UIParent)
    popup:SetSize(300, 420)
    popup:SetPoint('CENTER')
    popup:SetFrameStrata('DIALOG')
    popup:SetFrameLevel(200)
    popup:EnableMouse(true)
    popup:Hide()
    self.editDialog = popup

    local bg = popup:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXFrames.assets.textures.ui.panelBg)
    bg:SetVertexColor(unpack(theme.backgroundDeep))
    bg:SetTextureSliceMargins(8, 8, 8, 8)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAllPoints()

    local border = popup:CreateTexture(nil, 'OVERLAY', nil, 1)
    border:SetTexture(EXFrames.assets.textures.ui.panelBorder)
    border:SetVertexColor(unpack(theme.border))
    border:SetTextureSliceMargins(8, 8, 8, 8)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    border:SetAllPoints()

    local title = popup:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXFrames.assets.font.default(), 14, 'OUTLINE')
    title:SetPoint('TOPLEFT', 14, -14)
    title:SetTextColor(unpack(theme.text))
    popup.title = title

    local nameEdit = CreateFrame('EditBox', nil, popup)
    nameEdit:SetAutoFocus(false)
    nameEdit:SetSize(200, 24)
    nameEdit:SetPoint('TOPLEFT', 14, -48)
    nameEdit:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    nameEdit:SetTextInsets(8, 8, 0, 0)
    nameEdit:SetMaxLetters(32)
    local nameBg = nameEdit:CreateTexture(nil, 'BACKGROUND')
    nameBg:SetColorTexture(0.05, 0.05, 0.05, 1)
    nameBg:SetAllPoints()
    local nameBorder = EXUI:AddPixelPerfectBorder(nameEdit, 1, { register = false })
    nameBorder:SetBorderColor(unpack(theme.border))
    nameEdit:SetScript('OnEnterPressed', function()
        builds:ConfirmEdit()
    end)
    nameEdit:SetScript('OnEscapePressed', function()
        builds:HideEdit()
    end)
    nameEdit:SetScript('OnEditFocusGained', function()
        nameBorder:SetBorderColor(unpack(theme.accent))
    end)
    nameEdit:SetScript('OnEditFocusLost', function()
        nameBorder:SetBorderColor(unpack(theme.border))
    end)
    popup.nameEdit = nameEdit

    local selectedIconHolder = CreateFrame('Frame', nil, popup)
    selectedIconHolder:SetSize(ROW_BORDER, ROW_BORDER)
    selectedIconHolder:SetPoint('LEFT', nameEdit, 'RIGHT', 12, 0)
    local selectedIconButton = CreateFrame('Frame', nil, selectedIconHolder)
    StyleIcon(selectedIconButton, ROW_BORDER)
    selectedIconButton:SetAllPoints()
    popup.selectedIconTex = selectedIconButton.Icon

    local iconScroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    iconScroll:SetParent(popup)
    iconScroll:SetPoint('TOPLEFT', 14, -88)
    iconScroll:SetPoint('BOTTOMRIGHT', -14, 48)
    popup.iconScroll = iconScroll
    iconScroll.onScroll = function()
        if (builds.iconProvider) then
            builds:RefreshVisibleIcons(false)
        end
    end

    local watcher = CreateFrame('Frame', nil, popup)
    watcher:SetScript('OnUpdate', function()
        if (popup:IsShown() and builds.iconProvider) then
            builds:RefreshVisibleIcons(false)
        end
    end)

    local function DialogButton(label, onClick)
        local button = EXFrames:GetFrame('simple-button'):Create(popup)
        button:SetText(label)
        EXUI:SetSize(button, button.text:GetStringWidth() + 20, 24)
        if (button.PPBorder) then
            button.PPBorder:SetBorderThickness(1)
        end
        button:SetOnClick(onClick)
        return button
    end

    local saveButton = DialogButton('Save', function()
        builds:ConfirmEdit()
    end)
    saveButton:SetPoint('BOTTOMLEFT', 14, 12)

    local deleteButton = DialogButton('Delete', function()
        if (builds.editingId) then
            builds:Delete(builds.editingId)
        end
        builds:HideEdit()
    end)
    deleteButton:SetPoint('LEFT', saveButton, 'RIGHT', 8, 0)
    popup.deleteButton = deleteButton

    local cancelButton = DialogButton('Cancel', function()
        builds:HideEdit()
    end)
    cancelButton:SetPoint('BOTTOMRIGHT', -14, 12)
end

builds.ShowImport = function(self)
    if (not self.importDialog) then
        return
    end
    self.importDialog.errorText:SetText('')
    self.importDialog.editBox:SetText('')
    self.importDialog:Show()
    self.importDialog.editBox:SetFocus()
end

builds.CreateImportDialog = function(self)
    local theme = EXUI.const.theme
    local popup = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
    popup:SetSize(420, 240)
    popup:SetPoint('CENTER')
    popup:SetFrameStrata('DIALOG')
    popup:SetFrameLevel(200)
    popup:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    popup:SetBackdropColor(0.05, 0.05, 0.05, 0.96)
    popup:SetBackdropBorderColor(0, 0, 0, 1)
    popup:EnableMouse(true)
    popup:Hide()
    self.importDialog = popup

    local title = popup:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXFrames.assets.font.default(), 14, 'OUTLINE')
    title:SetPoint('TOPLEFT', 14, -14)
    title:SetText('Import talents')

    local editBox = CreateFrame('EditBox', nil, popup)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    editBox:SetPoint('TOPLEFT', 14, -44)
    editBox:SetPoint('BOTTOMRIGHT', -14, 72)
    editBox:SetTextInsets(8, 8, 8, 8)
    editBox:SetMaxLetters(8000)
    local editBg = editBox:CreateTexture(nil, 'BACKGROUND')
    editBg:SetColorTexture(0.04, 0.04, 0.04, 1)
    editBg:SetAllPoints()
    local editBorder = EXUI:AddPixelPerfectBorder(editBox, 1, { register = false })
    editBorder:SetBorderColor(unpack(theme.border))
    editBox:SetScript('OnEscapePressed', function()
        popup:Hide()
    end)
    editBox:SetScript('OnEditFocusGained', function()
        editBorder:SetBorderColor(unpack(theme.accent))
    end)
    editBox:SetScript('OnEditFocusLost', function()
        editBorder:SetBorderColor(unpack(theme.border))
    end)
    popup.editBox = editBox

    local errorText = popup:CreateFontString(nil, 'OVERLAY')
    errorText:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')
    errorText:SetPoint('BOTTOMLEFT', 14, 44)
    errorText:SetPoint('BOTTOMRIGHT', -14, 44)
    errorText:SetJustifyH('LEFT')
    errorText:SetTextColor(1, 0.35, 0.35, 1)
    popup.errorText = errorText

    local importButton = SmallButton(popup, 'Import')
    importButton:SetSize(80, 24)
    importButton:SetPoint('BOTTOMLEFT', 14, 12)
    importButton:SetScript('OnClick', function()
        local err = builds:StageImportString(editBox:GetText())
        if (err) then
            errorText:SetText(err)
        else
            errorText:SetText('')
        end
    end)

    local cancelButton = SmallButton(popup, 'Cancel')
    cancelButton:SetSize(80, 24)
    cancelButton:SetPoint('BOTTOMRIGHT', -14, 12)
    cancelButton:SetScript('OnClick', function()
        popup:Hide()
    end)
end

builds.Toggle = function(self)
    if (not self.sidebar) then
        return
    end
    if (self.sidebar:IsShown()) then
        self.sidebar:Hide()
        self:HideEdit()
    else
        local pvp = EXUI:GetModule('talents-pvp')
        if (pvp.Hide) then
            pvp:Hide()
        end
        self.sidebar:Show()
        self:Refresh()
    end
end

builds.HideDialogs = function(self)
    self:HideEdit()
    if (self.importDialog) then
        self.importDialog:Hide()
    end
end

builds.Create = function(self, window)
    local sidebar = CreateFrame('Frame', nil, window)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetPoint('TOPLEFT', window, 'TOPRIGHT', SIDEBAR_GAP, 0)
    sidebar:SetPoint('BOTTOMLEFT', window, 'BOTTOMRIGHT', SIDEBAR_GAP, 0)
    sidebar:SetFrameLevel(window:GetFrameLevel() + 5)
    sidebar:EnableMouse(true)
    sidebar:Hide()
    sidebar:SetScript('OnShow', function()
        builds:Refresh()
    end)
    self.sidebar = sidebar

    local theme = EXUI.const.theme
    local bg = sidebar:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXFrames.assets.textures.ui.panelBg)
    bg:SetVertexColor(unpack(theme.backgroundDeep))
    bg:SetAlpha(0.8)
    bg:SetTextureSliceMargins(8, 8, 8, 8)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bg:SetAllPoints()

    local border = sidebar:CreateTexture(nil, 'OVERLAY', nil, 1)
    border:SetTexture(EXFrames.assets.textures.ui.panelBorder)
    border:SetVertexColor(0, 0, 0)
    border:SetAlpha(0.8)
    border:SetTextureSliceMargins(8, 8, 8, 8)
    border:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    border:SetAllPoints()

    local title = sidebar:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXUI.const.fonts.DEFAULT, 13, 'OUTLINE')
    title:SetPoint('TOPLEFT', CONTENT_PAD, -10)
    title:SetText('Builds')
    title:SetTextColor(unpack(theme.text))

    local saveButton = CreateFrame('Button', nil, sidebar)
    local saveText = saveButton:CreateFontString(nil, 'OVERLAY')
    saveText:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    saveText:SetPoint('LEFT', 0, 0)
    saveText:SetText('Create')
    saveText:SetTextColor(unpack(theme.text))
    local saveIcon = saveButton:CreateTexture(nil, 'ARTWORK')
    saveIcon:SetTexture(TEX.save)
    saveIcon:SetSize(16, 16)
    saveIcon:SetPoint('LEFT', saveText, 'RIGHT', 6, 0)
    saveIcon:SetAlpha(0.85)
    local saveWidth = saveText:GetStringWidth()
    if (saveWidth < 20) then
        saveWidth = 42
    end
    saveButton:SetSize(saveWidth + 22, 18)
    saveButton:SetPoint('TOPRIGHT', -CONTENT_PAD, -11)
    saveButton:SetScript('OnEnter', function()
        saveText:SetTextColor(1, 1, 1, 1)
        saveIcon:SetAlpha(1)
    end)
    saveButton:SetScript('OnLeave', function()
        saveText:SetTextColor(unpack(theme.text))
        saveIcon:SetAlpha(0.85)
    end)
    saveButton:SetScript('OnClick', function()
        builds:ShowEdit(nil)
    end)

    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scroll:SetParent(sidebar)
    scroll:SetPoint('TOPLEFT', CONTENT_PAD, -40)
    scroll:SetPoint('BOTTOMRIGHT', -CONTENT_PAD, CONTENT_PAD)
    self.listScroll = scroll
    self.scrollChild = scroll.child

    local function CreateSectionHeader(label)
        local header = CreateFrame('Frame', nil, scroll.child)
        header:SetHeight(HEADER_HEIGHT)
        local headerBg = header:CreateTexture(nil, 'BACKGROUND')
        headerBg:SetTexture(EXUI.const.textures.frame.solidBg)
        headerBg:SetAllPoints()
        headerBg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 0.55)
        local headerText = header:CreateFontString(nil, 'OVERLAY')
        headerText:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
        headerText:SetPoint('LEFT', 8, 0)
        headerText:SetText(label)
        headerText:SetTextColor(unpack(HEADER_GOLD))
        return header
    end

    self.savedHeader = CreateSectionHeader('Saved')
    self.recentHeader = CreateSectionHeader('Recent')

    local emptySaved = scroll.child:CreateFontString(nil, 'OVERLAY')
    emptySaved:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')
    emptySaved:SetText('No saved builds yet.')
    emptySaved:SetTextColor(unpack(ThemeColor('textMuted')))
    self.emptySaved = emptySaved

    local emptyRecent = scroll.child:CreateFontString(nil, 'OVERLAY')
    emptyRecent:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')
    emptyRecent:SetText('No recent builds yet.')
    emptyRecent:SetTextColor(unpack(ThemeColor('textMuted')))
    self.emptyRecent = emptyRecent

    self:CreateEditDialog()
    self:CreateImportDialog()
end

EXUI:RegisterEventHandler('PLAYER_ENTERING_WORLD', 'talents-builds-cleanup', function()
    builds:RemoveTempConfigs()
end)

EXUI:RegisterEventHandler('ACTIVE_PLAYER_SPECIALIZATION_CHANGED', 'talents-builds-spec', function()
    if (builds.sidebar and builds.sidebar:IsShown()) then
        builds:Refresh()
    end
end)

EXUI:RegisterEventHandler('CHALLENGE_MODE_START', 'talents-builds-key', function(_, mapID)
    builds:NoteActivity(KeyActivity(mapID))
    local level = C_ChallengeMode.GetActiveKeystoneInfo and C_ChallengeMode.GetActiveKeystoneInfo()
    if (not level or level < 1 or IsSecret(level)) then
        C_Timer.After(1, function()
            builds:NoteActivity(KeyActivity(mapID))
        end)
    end
end)

EXUI:RegisterEventHandler('ENCOUNTER_START', 'talents-builds-encounter', function(_, _, encounterName)
    local label = RaidActivity(encounterName)
    if (not label) then
        return
    end
    builds.activeEncounterName = encounterName
    builds:NoteActivity(label)
end)

EXUI:RegisterEventHandler('ENCOUNTER_END', 'talents-builds-encounter-end', function()
    builds.activeEncounterName = nil
end)

EXUI:RegisterEventHandler({ 'ACTIVE_DELVE_DATA_UPDATE', 'WALK_IN_DATA_UPDATE' }, 'talents-builds-delve', function()
    builds:NoteActivity(DelveActivity())
end)
