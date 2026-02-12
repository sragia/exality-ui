---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIoUFTags
local tags = EXUI:GetModule('oUF-Tags')

----------------

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

core.units = {}
core.groupUnits = {}
core.groupUnitMap = {}
core.frames = {}
core.headers = {}
core.partyFrames = {}
core.raidFrames = {}
core.forcedFrames = {}
core.forcedHeaders = {}
core.playerGroupUnits = {}
core.framesToUpdate = {}

core.POWER_COLORS = {
    Enum.PowerType.Mana,
    Enum.PowerType.Rage,
    Enum.PowerType.Focus,
    Enum.PowerType.Energy,
    Enum.PowerType.Fury,
    Enum.PowerType.Pain,
    Enum.PowerType.RunicPower,
}

local MAX_GROUPS = 8

core.Init = function(self)
    tags:RegisterCustomTags()
    EXUI.oUF:RegisterStyle("ExalityUI", self.SharedStyle)
    EXUI.oUF:Factory(self.Factory)
    self:UpdatePowerColors()
end

core.RegisterUnit = function(self, unit, isGroup, numUnits)
    if (isGroup) then
        self.groupUnits[unit] = numUnits
        for i = 1, numUnits do
            self.groupUnitMap[unit .. i] = unit
        end
    else
        table.insert(self.units, unit)
    end
end

core.RegisterPlayerGroupUnit = function(self, unit, visibility, attributes)
    self.playerGroupUnits[unit] = {
        unit = unit,
        visibility = visibility,
        attributes = attributes,
    }
end

core.SharedStyle = function(frame, unit)
    local frameFactory = nil
    if (not core.groupUnitMap[unit]) then
        frameFactory = EXUI:GetModule('uf-unit-' .. unit)
    elseif (core.groupUnitMap[unit]) then -- Boss/Arena
        frameFactory = EXUI:GetModule('uf-unit-' .. core.groupUnitMap[unit])
    end

    if (unit == 'party') then
        table.insert(core.partyFrames, frame)
    end
    if (unit == 'raid') then
        table.insert(core.raidFrames, frame)
    end

    if (frameFactory and frameFactory.Create) then
        frameFactory:Create(frame, unit)
    end
end

core.Factory = function(oUF)
    oUF:SetActiveStyle("ExalityUI")

    for _, unit in ipairs(core.units) do
        core:CreateOrUpdate(oUF, unit)
    end

    for group, numUnits in pairs(core.groupUnits) do
        core:CreateOrUpdateGroup(oUF, group, numUnits)
    end

    for unit, data in pairs(core.playerGroupUnits) do
        core:CreateOrUpdatePlayerGroup(oUF, unit, data)
    end
end

core.CreateOrUpdate = function(self, oUF, unit)
    local shouldShowBlizzardFrame = self:GetValueForUnit(unit, 'showBlizzardFrame') and
        not self:GetValueForUnit(unit, 'enable')
    if (shouldShowBlizzardFrame) then
        return;
    end
    local frame = core.frames[unit]
    if (not frame) then
        frame = oUF:Spawn(unit, 'ExalityUI_' .. unit, 'SecureUnitButtonTemplate, PingableUnitFrameTemplate')
        core.frames[unit] = frame
    end

    if not frame.Update then
        frame.Update = function() EXUI:GetModule('uf-unit-' .. unit):Update(frame) end
    end

    frame:Update()
end

core.CreateOrUpdateGroup = function(self, oUF, group, numUnits)
    local shouldShowBlizzardFrame = self:GetValueForUnit(group, 'showBlizzardFrame') and
        not self:GetValueForUnit(group, 'enable')
    if (shouldShowBlizzardFrame) then
        return;
    end
    for i = 1, numUnits do
        local unit = group .. i
        local frame = core.frames[unit]
        if (not frame) then
            frame = oUF:Spawn(unit, 'ExalityUI_' .. unit, 'SecureUnitButtonTemplate, PingableUnitFrameTemplate')
            core.frames[unit] = frame
            frame.index = i
        end

        if not frame.Update then
            frame.Update = function() EXUI:GetModule('uf-unit-' .. group):Update(frame) end
        end

        frame:Update()
    end
end

core.CreateOrUpdatePlayerGroup = function(self, oUF, unit, data)
    local header
    if (unit == 'party') then
        local shouldShowBlizzardFrame = self:GetValueForUnit('party', 'showBlizzardFrame') and
            not self:GetValueForUnit('party', 'enable')
        if (shouldShowBlizzardFrame) then
            return;
        end
        header = core.headers[unit]
        if (not header) then
            local unitWidth = self:GetValueForUnit('party', 'sizeWidth')
            local unitHeight = self:GetValueForUnit('party', 'sizeHeight')
            data.attributes['oUF-initialConfigFunction'] =
                string.format('self:SetWidth(%d); self:SetHeight(%d);', unitWidth, unitHeight)
            header = oUF:SpawnHeader(nil, nil, data.attributes)
            if (data.visibility) then
                header.originalVisibility = data.visibility
                header:SetVisibility(data.visibility)
            end
            core.headers[unit] = header
        end
    elseif (unit == 'raid') then
        local shouldShowBlizzardFrame = self:GetValueForUnit('raid', 'showBlizzardFrame') and
            not self:GetValueForUnit('raid', 'enable')
        if (shouldShowBlizzardFrame) then
            return;
        end
        header = core.headers[unit]
        if (not header) then
            header = CreateFrame('Frame', 'ExalityUI_RaidContainer', UIParent, 'SecureHandlerStateTemplate')
            header.groupHeaders = {}

            -- Spawnheader for each raid group
            for i = 1, 8 do
                local groupHeader = oUF:SpawnHeader(nil, nil, {
                    groupFilter = i,
                    showRaid = true,
                    showPlayer = true,
                    showParty = false
                })
                table.insert(header.groupHeaders, groupHeader)
                groupHeader.group = i
                groupHeader:SetPoint('TOPLEFT', header, 'TOPLEFT', 0, 0) --  Adjust later
                groupHeader.originalVisibility = data.visibility
                groupHeader:SetVisibility(data.visibility)
            end
            core.headers[unit] = header
        end
    end

    header:SetPoint('CENTER', -500, 0)
    header:Show()

    self:UpdateHeader(unit)
    editor:RegisterFrameForEditor(header, unit .. ' Frames', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        self:UpdateValueForUnit(unit, 'positionAnchorPoint', point)
        self:UpdateValueForUnit(unit, 'positionRelativePoint', relativePoint)
        self:UpdateValueForUnit(unit, 'positionXOff', xOfs)
        self:UpdateValueForUnit(unit, 'positionYOff', yOfs)
        self:UpdateHeader(unit)
    end, function(frame)
        frame.editor:SetEditorAsMovable()
    end)
end

core.Base = function(self, frame)
    local elementFrame = CreateFrame('Frame', '$parent_ElementFrame', frame, 'BackdropTemplate')
    elementFrame:SetAllPoints()
    elementFrame:SetFrameLevel(frame:GetFrameLevel() + 100)
    -- Add Border
    elementFrame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    elementFrame:SetBackdropBorderColor(0, 0, 0, 1)
    elementFrame:SetBackdropColor(0, 0, 0, 0)

    frame.ElementFrame = elementFrame

    if (not self.groupUnitMap[frame.unit]) then
        frame.db = self:GetDBForUnit(frame.unit)
    else
        frame.db = self:GetDBForUnit(self.groupUnitMap[frame.unit])
    end

    frame.generalDB = self:GetDBForUnit('general')

    self:AddTooltip(frame)

    if (not InCombatLockdown()) then
        frame:RegisterForClicks('AnyUp')
    else
        -- TODO, register once out of combat
        table.insert(core.framesToUpdate, frame)
    end
end

core.UpdateFrame = function(self, frame)
    -- Update All Elements on frame
    if (frame.Name) then
        EXUI:GetModule('uf-element-name'):Update(frame)
    end

    if (frame.HealthText) then
        EXUI:GetModule('uf-element-health-text'):Update(frame)
    end
    if (frame.HealthPerc) then
        EXUI:GetModule('uf-element-health-perc'):Update(frame)
    end

    if (frame.Power) then
        EXUI:GetModule('uf-element-power'):Update(frame)
    end

    if (frame.Health) then
        EXUI:GetModule('uf-element-health'):Update(frame)
    end

    if (frame.HealthPrediction) then
        EXUI:GetModule('uf-element-healthprediction'):Update(frame)
    end

    if (frame.RaidTargetIndicator) then
        EXUI:GetModule('uf-element-raid-target-indicator'):Update(frame)
    end

    if (frame.RaidRoles) then
        EXUI:GetModule('uf-element-raid-roles'):Update(frame)
    end

    if (frame.CombatIndicator) then
        EXUI:GetModule('uf-element-combat-indicator'):Update(frame)
    end

    if (frame.Castbar) then
        EXUI:GetModule('uf-element-cast-bar'):Update(frame)
    end

    if (frame.Buffs) then
        EXUI:GetModule('uf-element-buffs'):Update(frame)
    end

    if (frame.Debuffs) then
        EXUI:GetModule('uf-element-debuffs'):Update(frame)
    end

    if (frame.Auras) then
        EXUI:GetModule('uf-element-auras'):Update(frame)
    end

    if (frame.Offline) then
        EXUI:GetModule('uf-element-offline'):Update(frame)
    end

    if (frame.ResurrectIndicator) then
        EXUI:GetModule('uf-element-ressurect-indicator'):Update(frame)
    end

    if (frame.SummonIndicator) then
        EXUI:GetModule('uf-element-summon-indicator'):Update(frame)
    end

    if (frame.PrivateAuras) then
        EXUI:GetModule('uf-element-private-auras'):Update(frame)
    end

    if (frame.CustomTexts) then
        EXUI:GetModule('uf-element-custom-texts'):Update(frame)
    end

    if (frame.GroupRoleIndicator) then
        EXUI:GetModule('uf-element-group-role-indicator'):Update(frame)
    end

    frame:UpdateTags()
    frame:UpdateAllElements('RefreshUnit')
end

core.AddTooltip = function(self, frame)
    frame:SetScript('OnEnter', function(self)
        if (GameTooltip:IsForbidden()) then return end

        GameTooltip:SetOwner(self, 'ANCHOR_NONE')
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetUnit(self.unit)
        self.UpdateTooltip = function(self)
            GameTooltip:SetUnit(frame.unit)
        end
    end)
    frame:SetScript('OnLeave', function(self)
        if (GameTooltip:IsForbidden()) then return end
        self.UpdateTooltip = nil
        GameTooltip:Hide()
    end)
end

core.UpdateFrameForUnit = function(self, unit)
    if (unit == 'party') then
        -- Party Frames
        for _, frame in ipairs(core.partyFrames) do
            if (frame) then
                frame:Update()
            end
        end
        self:UpdateHeader(unit)
    elseif (unit == 'raid') then
        -- Raid Frames
        for _, frame in ipairs(core.raidFrames) do
            if (frame) then
                frame:Update()
            end
        end
        self:UpdateHeader(unit)
    elseif (not self.groupUnits[unit]) then
        local frame = core.frames[unit]
        if (frame) then
            frame:Update()
        end
    else
        for i = 1, self.groupUnits[unit] do
            local frame = core.frames[unit .. i]
            if (frame) then
                frame:Update()
            end
        end
    end
end

core.UpdateAllFrames = function(self)
    for _, unit in ipairs(self.units) do
        self:UpdateFrameForUnit(unit)
    end
    -- Boss Frames
    self:UpdateFrameForUnit('boss')
    -- Party Frames
    self:UpdateFrameForUnit('party')
    -- Raid Frames
    self:UpdateFrameForUnit('raid')
end

core.DisableHeader = function(self, header)
    header:SetVisibility('custom [@player] hide')
    header:SetAttribute('showPlayer', true)
    header:SetAttribute('showSolo', true)
    header:SetAttribute('showParty', true)
    header:SetAttribute('showRaid', true)
    header:SetAttribute('groupFilter', nil)
    header:SetAttribute('yOffset', nil)
    header:Hide()
end

core.UpdateHeader = function(self, unit)
    local header = core.headers[unit]
    if (not header) then return end

    local db = self:GetDBForUnit(unit)
    if (not db) then return end

    if (not db.enable) then
        header.isDisabled = true
        if (header.groupHeaders) then
            -- Raid
            for _, groupHeader in ipairs(header.groupHeaders) do
                self:DisableHeader(groupHeader)
            end
        else
            -- Party
            self:DisableHeader(header)
        end
        return
    end
    if (header.isDisabled) then
        -- Re-enable header
        if (not header.groupHeaders) then
            -- Party, raid is going to be re-enabled in UpdateRaidLayout
            header:SetAttribute('showPlayer', true)
            header:SetAttribute('showSolo', true)
            header:SetAttribute('showParty', true)
            header:SetAttribute('showRaid', false)
            header:SetVisibility(header.originalVisibility)
            header:Show()
        end
    end
    header.isDisabled = false

    header:ClearAllPoints()
    EXUI:SetPoint(header, db.positionAnchorPoint, UIParent, db.positionRelativePoint, db.positionXOff, db.positionYOff)

    if (header.groupHeaders) then
        -- Raid
        self:UpdateRaidLayout(header)
    else
        -- Party
        header:SetAttribute('yOffset', -db.spacing)
    end
end

core.UpdateRaidLayout = function(self, container)
    if (not container) then return end
    local unitWidth = self:GetValueForUnit('raid', 'sizeWidth')
    local unitHeight = self:GetValueForUnit('raid', 'sizeHeight')
    local spacingX = self:GetValueForUnit('raid', 'spacingX')
    local spacingY = self:GetValueForUnit('raid', 'spacingY')
    local numGroups = #container.groupHeaders
    local totalHeight = unitHeight * numGroups + spacingY * (numGroups - 1)
    EXUI:SetSize(container, unitWidth * 8 + spacingX * 7, totalHeight)
    EXUI:SetPoint(container, 'CENTER', 0, 0)

    local groupDirection = self:GetValueForUnit('raid', 'groupDirection') -- LEFT / RIGHT
    local maxGroups = MAX_GROUPS
    for i = 1, #container.groupHeaders do
        container.groupHeaders[i]:SetAttribute('yOffset', -spacingY)
        container.groupHeaders[i]:ClearAllPoints()
    end
    local prev = nil
    for i = 1, #container.groupHeaders do
        local groupHeader = container.groupHeaders[i]
        groupHeader:SetAttribute('oUF-initialConfigFunction',
            string.format('self:SetWidth(%d); self:SetHeight(%d);', unitWidth, unitHeight))
        if (i <= maxGroups) then
            groupHeader:SetVisibility(groupHeader.originalVisibility)
            groupHeader:SetAttribute('showRaid', true)
            groupHeader:SetAttribute('showPlayer', true)
            groupHeader:SetAttribute('showSolo', true)
            groupHeader:SetAttribute('showParty', true)
            groupHeader:SetAttribute('groupFilter', i)
            groupHeader:SetAttribute('yOffset', -spacingY)
            groupHeader:Show()
            if (prev) then
                EXUI:SetPoint(
                    groupHeader,
                    groupDirection == 'RIGHT' and 'TOPLEFT' or 'TOPRIGHT',
                    prev,
                    groupDirection == 'RIGHT' and 'TOPRIGHT' or 'TOPLEFT',
                    groupDirection == 'RIGHT' and spacingX or -spacingX,
                    0
                )
            else
                -- 1st group
                EXUI:SetPoint(
                    groupHeader,
                    groupDirection == 'RIGHT' and 'TOPLEFT' or 'TOPRIGHT',
                    container,
                    groupDirection == 'RIGHT' and 'TOPLEFT' or 'TOPRIGHT',
                    0,
                    0
                )
            end
            prev = groupHeader
        else
            -- Hide
            groupHeader:SetAttribute('showPlayer', true)
            groupHeader:SetAttribute('showSolo', true)
            groupHeader:SetAttribute('showParty', true)
            groupHeader:SetAttribute('showRaid', true)
            groupHeader:SetAttribute('groupFilter', nil)
            groupHeader:SetAttribute('yOffset', nil)
            groupHeader:Hide()
        end
    end
end

core.CheckRaidDificulty = function(self)
    if (InCombatLockdown()) then return end
    local _, instanceType, difficulty = GetInstanceInfo()
    local raidHeader = core.headers['raid']
    if (not raidHeader) then return end
    if (instanceType == 'raid') then
        if (difficulty == 16) then
            -- Mythic
            MAX_GROUPS = 4
        else
            -- Flex
            MAX_GROUPS = 8
        end
        self:UpdateRaidLayout(raidHeader)
    end
end

core.UpdatePowerColors = function(self)
    local generalDB = self:GetDBForUnit('general')
    if (not generalDB) then return end
    for _, powerType in ipairs(core.POWER_COLORS) do
        local powerColor = generalDB[string.format('powerColor%s', powerType)]
        if (powerColor) then
            EXUI.oUF.colors.power[powerType]:SetRGBA(powerColor.r, powerColor.g, powerColor.b, powerColor.a)
        end
    end
end

EXUI:RegisterEventHandler(
    { 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED_NEW_AREA' },
    'raid-check-difficulty',
    function()
        core:CheckRaidDificulty()
    end
)

core.ReconfigureFrames = function(self)
    for _, frame in ipairs(core.framesToUpdate) do
        frame:RegisterForClicks('AnyUp')
    end
    core.framesToUpdate = {}
end

EXUI:RegisterEventHandler(
    { 'PLAYER_REGEN_ENABLED' },
    'uf-update-frames',
    function() core:ReconfigureFrames() end
)

-- DB Data
core.SetDefaultsForUnit = function(self, unit, defaults)
    local db = data:GetDataByKey('UF')
    db = db or {}
    db[unit] = db[unit] or {}
    for key, value in pairs(defaults) do
        if (db[unit][key] == nil) then
            db[unit][key] = value
        end
    end
    data:SetDataByKey('UF', db)
end

core.GetDBForUnit = function(self, unit)
    local UFDB = data:GetDataByKey('UF')
    if (not UFDB) then
        UFDB = {}
        data:SetDataByKey('UF', UFDB)
    end
    UFDB[unit] = UFDB[unit] or {}

    return UFDB[unit]
end

core.UpdateValueForUnit = function(self, unit, key, value)
    local UFDB = data:GetDataByKey('UF')
    UFDB[unit] = UFDB[unit] or {}
    UFDB[unit][key] = value
    data:SetDataByKey('UF', UFDB)
end

core.GetValueForUnit = function(self, unit, key)
    local db = self:GetDBForUnit(unit)
    return db[key]
end

core.EnableElementForFrame = function(self, frame, element)
    if (frame.unit == 'party' or frame.unit == 'raid') then return end
    frame:EnableElement(element)
end

core.DisableElementForFrame = function(self, frame, element)
    if (frame.unit == 'party' or frame.unit == 'raid') then return end
    frame:DisableElement(element)
end

-- For Options. Force Show frames for editting
core.ForceShow = function(self, unit)
    if (InCombatLockdown()) then return end
    if (unit == 'party') then
        if (IsInGroup() and not IsInRaid()) then return end
        local header = core.headers[unit]
        if (not header) then return end
        header:SetVisibility('solo')
        header.isFake = true
        self.forcedHeaders[unit] = header
        for _, frame in ipairs(core.partyFrames) do
            if (frame) then
                self.forcedFrames[frame.unit] = frame
                self:ForceFrame(frame)
            end
        end
    elseif (unit == 'raid') then
        if (IsInRaid()) then return end
        local header = core.headers[unit]
        if (not header) then return end
        for _, groupHeader in ipairs(header.groupHeaders) do
            if (groupHeader) then
                groupHeader:SetVisibility('solo')
                groupHeader.isFake = true
                self.forcedHeaders[unit .. groupHeader.group] = groupHeader
            end
        end
        for _, frame in ipairs(core.raidFrames) do
            if (frame) then
                self.forcedFrames[frame.unit] = frame
                self:ForceFrame(frame)
            end
        end
    elseif (self.groupUnits[unit]) then
        for i = 1, self.groupUnits[unit] do
            local frame = self.frames[unit .. i]
            if (frame) then
                self.forcedFrames[unit .. i] = frame
                self:ForceFrame(frame)
            end
        end
    elseif (self.frames[unit]) then
        local frame = self.frames[unit]
        if (frame) then
            self.forcedFrames[unit] = frame
            self:ForceFrame(frame)
        end
    end
end

core.ForceFrame = function(self, frame)
    if (frame.isFake) then return end
    frame.originalUnit = frame.unit
    frame.unit = 'player'
    frame.isFake = true

    frame:EnableMouse(false)
    frame:Show()

    UnregisterUnitWatch(frame)
    RegisterUnitWatch(frame, true)

    if (frame.Update) then
        frame:Update()
    end
end

core.Unforce = function(self, unit)
    if (InCombatLockdown()) then return end

    if (unit == 'party') then
        local header = core.headers[unit]
        if (not header) then return end
        header.isFake = false
        header:SetVisibility(header.originalVisibility)
        self.forcedHeaders[unit] = nil
        for _, frame in ipairs(core.partyFrames) do
            if (frame) then
                self.forcedFrames[frame.unit] = nil
                self:UnforceFrame(frame)
            end
        end
    elseif (unit == 'raid') then
        local header = core.headers[unit]
        if (not header) then return end
        for _, groupHeader in ipairs(header.groupHeaders) do
            if (groupHeader) then
                groupHeader:SetVisibility(groupHeader.originalVisibility)
                groupHeader.isFake = false
                self.forcedHeaders[unit .. groupHeader.group] = nil
            end
        end
        for _, frame in ipairs(core.raidFrames) do
            if (frame) then
                self.forcedFrames[frame.unit] = nil
                self:UnforceFrame(frame)
            end
        end
    end
    if (self.groupUnits[unit]) then
        for i = 1, self.groupUnits[unit] do
            local frame = self.frames[unit .. i]
            if (frame) then
                self.forcedFrames[unit .. i] = nil
                self:UnforceFrame(frame)
            end
        end
    elseif (self.frames[unit]) then
        local frame = self.frames[unit]
        if (frame) then
            self.forcedFrames[unit] = nil
            self:UnforceFrame(frame)
        end
    end
end

core.UnforceFrame = function(self, frame)
    if (not frame.isFake) then return end
    frame.unit = frame.originalUnit
    frame:EnableMouse(true)

    frame.isFake = false
    if (frame.Update) then
        frame:Update()
    end

    UnregisterUnitWatch(frame)
    RegisterUnitWatch(frame)
end

core.UnforceAll = function(self)
    for _, frame in pairs(self.forcedFrames) do
        if (frame) then
            self:UnforceFrame(frame)
        end
    end
    for _, header in pairs(self.forcedHeaders) do
        if (header) then
            header:SetVisibility(header.originalVisibility)
            header.isFake = false
        end
    end
    self.forcedFrames = {}
    self.forcedHeaders = {}
end
