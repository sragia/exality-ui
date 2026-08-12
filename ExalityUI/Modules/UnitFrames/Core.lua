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
local RAID_MEMBERS_PER_GROUP = 5
local PARTY_MEMBERS = 5

-- Party editor/position target is a plain container; secure SpawnHeader is the child.
core.GetPartySecureHeader = function(self, header)
    if not header then
        return nil
    end
    return header.partyHeader or header
end

core.Init = function(self)
    tags:RegisterCustomTags()
    EXUI.oUF:RegisterStyle("ExalityUI", self.SharedStyle)
    EXUI.oUF:Factory(self.Factory)
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

    if (frameFactory and frameFactory.Create) then
        frameFactory:Create(frame, unit)
    end


    if (unit == 'party') then
        frame.exuiUnitType = 'party'
        table.insert(core.partyFrames, frame)
        if (frame.Update) then
            -- Update on next frame to update with correct unit
            EXUI.utils.nextFrame(function()
                frame:Update()
            end)
        end
    end
    if (unit == 'raid') then
        frame.exuiUnitType = 'raid'
        table.insert(core.raidFrames, frame)
        if (frame.Update) then
            -- Update on next frame to update with correct unit
            EXUI.utils.nextFrame(function()
                frame:Update()
            end)
        end
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
            -- Container owns edit-mode size/position (like raid). SpawnHeader
            -- auto-sizes to children, so the overlay must not live on it.
            header = CreateFrame('Frame', 'ExalityUI_PartyContainer', UIParent)
            local unitWidth = self:GetValueForUnit('party', 'sizeWidth')
            local unitHeight = self:GetValueForUnit('party', 'sizeHeight')
            data.attributes['oUF-initialConfigFunction'] =
                string.format([[
if not unit then
    local header = self:GetParent()
    if header:GetAttribute('EXUI-forcedUnit') then
        unit = header:GetAttribute('EXUI-forcedUnit')
        self:SetAttribute('oUF-guessUnit', unit)
        self:SetAttribute('unit', unit)
    end
end
self:SetWidth(%d); self:SetHeight(%d);]], unitWidth, unitHeight)
            local partyHeader = oUF:SpawnHeader(nil, nil, data.attributes)
            partyHeader:SetPoint('TOPLEFT', header, 'TOPLEFT', 0, 0)
            if (data.visibility) then
                partyHeader.originalVisibility = data.visibility
                partyHeader:SetVisibility(data.visibility)
            end
            local auraCount = EXUI:GetModule('uf-auras-apply'):GetRequiredAuraContainerCount('party')
            if partyHeader.SetNumAuraContainers then
                partyHeader:SetNumAuraContainers(auraCount)
            end
            header.partyHeader = partyHeader
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
            local auraCount = EXUI:GetModule('uf-auras-apply'):GetRequiredAuraContainerCount('raid')
            for i = 1, 8 do
                local groupHeader = oUF:SpawnHeader(nil, nil, {
                    groupFilter = i,
                    showRaid = true,
                    showPlayer = true,
                    showParty = false
                })
                if groupHeader.SetNumAuraContainers then
                    groupHeader:SetNumAuraContainers(auraCount)
                end
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
    editor:RegisterFrameForEditor(header, EXUI.utils.capitalize(unit) .. ' Frames', function(frame)
        core:PersistEditorFramePosition(frame, unit)
    end, function(frame)
        frame.editor:SetEditorAsMovable()
    end)
end

core.SnapUnitFrame = function(self, frame)
    EXUI:SnapFrameToPixels(frame)
    local elementFrame = frame.ElementFrame
    if elementFrame and elementFrame.PPBorder then
        elementFrame.PPBorder:SetBorderThickness(1)
    end
end

core.ApplyUnitFrameLayout = function(self, frame, db)
    local editorModule = EXUI:GetModule('editor')
    if editorModule and editorModule.enabled and frame.editor then
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint(db.positionAnchorPoint, UIParent, db.positionRelativePoint, db.positionXOff, db.positionYOff)
    EXUI:SetSize(frame, db.sizeWidth, db.sizeHeight)
    self:SnapUnitFrame(frame)
end

core.ApplyContainerLayout = function(self, container, db, width, height)
    local editorModule = EXUI:GetModule('editor')
    if editorModule and editorModule.enabled and container.editor then
        return
    end
    container:ClearAllPoints()
    EXUI:SetSize(container, width, height)
    container:SetPoint(db.positionAnchorPoint, UIParent, db.positionRelativePoint, db.positionXOff, db.positionYOff)
    EXUI:SnapFrameToPixels(container)
end

core.Base = function(self, frame)
    local elementFrame = CreateFrame('Frame', '$parent_ElementFrame', frame)
    elementFrame:SetAllPoints()
    elementFrame:SetFrameLevel(frame:GetFrameLevel() + 100)
    elementFrame.PPBorder = EXUI:AddPixelPerfectBorder(elementFrame, 1, { register = false })
    elementFrame.PPBorder:SetBorderColor(0, 0, 0, 1)

    frame.ElementFrame = elementFrame
    EXUI:RegisterSnapFrame(frame)

    if (not self.groupUnitMap[frame.__unit]) then
        frame.db = self:GetDBForUnit(frame.__unit)
    else
        frame.db = self:GetDBForUnit(self.groupUnitMap[frame.__unit])
    end

    frame.generalDB = self:GetDBForUnit('general')

    frame.IsElementPreviewEnabled = function(self, element)
        local isFake = self.originalUnit == nil or self.isFake
        return isFake and self.elementPreviews and self.elementPreviews[element]
    end

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

    EXUI:GetModule('uf-auras-apply'):UpdateFrame(frame)

    if (frame.Offline) then
        EXUI:GetModule('uf-element-offline'):Update(frame)
    end

    if (frame.ResurrectIndicator) then
        EXUI:GetModule('uf-element-ressurect-indicator'):Update(frame)
    end

    if (frame.SummonIndicator) then
        EXUI:GetModule('uf-element-summon-indicator'):Update(frame)
    end

    if (frame.CustomTexts) then
        EXUI:GetModule('uf-element-custom-texts'):Update(frame)
    end

    if (frame.GroupRoleIndicator) then
        EXUI:GetModule('uf-element-group-role-indicator'):Update(frame)
    end

    if (frame.PhaseIndicator) then
        EXUI:GetModule('uf-element-phase-indicator'):Update(frame)
    end

    if (frame.DispelOverlay) then
        EXUI:GetModule('uf-element-dispel-overlay'):Update(frame)
    end

    if (frame.SelectionHighlight) then
        EXUI:GetModule('uf-element-selection-highlight'):Update(frame)
    end

    frame:UpdateTags()
    frame:UpdateAllElements('RefreshUnit')

    if (frame:IsElementPreviewEnabled('castbar') and frame.Castbar) then
        EXUI:GetModule('uf-element-cast-bar'):Update(frame) -- Reupdate castbar for preview. Kind of a bandaid fix
    end
end

core.AddTooltip = function(self, frame)
    frame:SetScript('OnEnter', function(self)
        if (GameTooltip:IsForbidden()) then return end

        GameTooltip:SetOwner(self, 'ANCHOR_NONE')
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetUnit(self.__unit)
        self.UpdateTooltip = function(self)
            GameTooltip:SetUnit(self.__unit)
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

core.PersistEditorFramePosition = function(self, frame, unit)
    if not frame or frame:GetNumPoints() == 0 then
        return
    end

    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    self:UpdateValueForUnit(unit, 'positionAnchorPoint', point)
    self:UpdateValueForUnit(unit, 'positionRelativePoint', relativePoint)
    self:UpdateValueForUnit(unit, 'positionXOff', xOfs or 0)
    self:UpdateValueForUnit(unit, 'positionYOff', yOfs or 0)

    local editorModule = EXUI:GetModule('editor')
    if editorModule and editorModule.enabled then
        return
    end

    if unit == 'party' or unit == 'raid' then
        self:UpdateHeader(unit)
    else
        self:UpdateFrameForUnit(unit)
    end
end

core.UpdateHeader = function(self, unit)
    local editorModule = EXUI:GetModule('editor')
    if editorModule and editorModule.enabled then
        return
    end

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
            self:DisableHeader(self:GetPartySecureHeader(header))
            header:Hide()
        end
        return
    end
    if (header.isDisabled) then
        -- Re-enable header
        if (not header.groupHeaders) then
            local partyHeader = self:GetPartySecureHeader(header)
            if (not partyHeader.isFake) then
                partyHeader:SetAttribute('showPlayer', true)
                partyHeader:SetAttribute('showSolo', true)
                partyHeader:SetAttribute('showParty', true)
                partyHeader:SetAttribute('showRaid', false)
                if partyHeader.originalVisibility then
                    partyHeader:SetVisibility(partyHeader.originalVisibility)
                end
            end
            header:Show()
        end
    end
    header.isDisabled = false

    header:ClearAllPoints()
    header:SetPoint(db.positionAnchorPoint, UIParent, db.positionRelativePoint, db.positionXOff, db.positionYOff)

    if (header.groupHeaders) then
        -- Raid
        self:UpdateRaidLayout(header)
        local editorModule = EXUI:GetModule('editor')
        if not (editorModule and editorModule.enabled) then
            EXUI:SnapFrameToPixels(header)
        end
    else
        local partyHeader = self:GetPartySecureHeader(header)
        if (not partyHeader.isFake) then
            partyHeader:SetAttribute('showPlayer', true)
            partyHeader:SetAttribute('showSolo', true)
            partyHeader:SetAttribute('showParty', true)
            partyHeader:SetAttribute('showRaid', false)
            if partyHeader.originalVisibility then
                partyHeader:SetVisibility(partyHeader.originalVisibility)
            end
        end
        self:UpdatePartyLayout(header)
        local editorModule = EXUI:GetModule('editor')
        if not (editorModule and editorModule.enabled) then
            EXUI:SnapFrameToPixels(header)
        end
    end
end

core.UpdatePartyLayout = function(self, header)
    if not header then
        return
    end

    local unitWidth = self:GetValueForUnit('party', 'sizeWidth')
    local unitHeight = self:GetValueForUnit('party', 'sizeHeight')
    local spacing = EXUI:ScalePixel(self:GetValueForUnit('party', 'spacing'), header)
    local partyHeader = self:GetPartySecureHeader(header)
    partyHeader:SetAttribute('yOffset', -spacing)
    local containerHeight = unitHeight * PARTY_MEMBERS + spacing * math.max(0, PARTY_MEMBERS - 1)
    -- Size the container (edit overlay target), not the SpawnHeader child.
    EXUI:SetSize(header, unitWidth, containerHeight)
end

core.ApplyEditorGroupLayout = function(self, unit, options)
    local header = self.headers[unit]
    if not header then
        return
    end

    options = options or {}
    if unit == 'party' then
        self:UpdatePartyLayout(header)
    elseif unit == 'raid' then
        if options.sizeOnly then
            -- Edit Mode overlays only need the container footprint.
            self:UpdateRaidContainerSize(header)
        else
            self:UpdateRaidLayout(header)
        end
    end
end

-- Edit Mode: make party/raid headers selectable without ForceShow fakes.
-- ForceShow(startingIndex=-4) is what freezes Edit Mode open.
core.PrepareGroupHeaderForEditor = function(self, unit)
    if InCombatLockdown() then
        return
    end

    local header = self.headers[unit]
    if not header then
        return
    end

    if unit == 'party' then
        header:Show()
        local partyHeader = self:GetPartySecureHeader(header)
        if IsInGroup() and not IsInRaid() then
            -- Already in party: re-assert visibility so roster configures children.
            if partyHeader.originalVisibility then
                partyHeader:SetVisibility(partyHeader.originalVisibility)
            end
            return
        end
        if partyHeader._editorVisibility then
            return
        end
        partyHeader._editorVisibility = true
        -- Show the secure header only; do not touch startingIndex (no fake members).
        partyHeader:SetVisibility('solo')
    elseif unit == 'raid' then
        -- Editor is registered on the plain container, not the secure groups.
        header:Show()
    end
end

core.RestoreGroupHeadersAfterEditor = function(self)
    if InCombatLockdown() then
        return
    end

    local party = self.headers.party
    local partyHeader = party and self:GetPartySecureHeader(party)
    if partyHeader and partyHeader._editorVisibility then
        partyHeader._editorVisibility = nil
        partyHeader:SetVisibility(partyHeader.originalVisibility or 'party')
    end
end

core.UpdateRaidContainerSize = function(self, container)
    if not container then
        return
    end

    local unitWidth = self:GetValueForUnit('raid', 'sizeWidth')
    local unitHeight = self:GetValueForUnit('raid', 'sizeHeight')
    local spacingX = EXUI:ScalePixel(self:GetValueForUnit('raid', 'spacingX'), container)
    local spacingY = EXUI:ScalePixel(self:GetValueForUnit('raid', 'spacingY'), container)
    local columnCount = #container.groupHeaders
    local containerWidth = unitWidth * columnCount + spacingX * math.max(0, columnCount - 1)
    local containerHeight = unitHeight * RAID_MEMBERS_PER_GROUP + spacingY * math.max(0, RAID_MEMBERS_PER_GROUP - 1)
    EXUI:SetSize(container, containerWidth, containerHeight)
end

core.UpdateRaidLayout = function(self, container)
    if (not container) then return end
    local unitWidth = self:GetValueForUnit('raid', 'sizeWidth')
    local unitHeight = self:GetValueForUnit('raid', 'sizeHeight')
    local spacingX = EXUI:ScalePixel(self:GetValueForUnit('raid', 'spacingX'), container)
    local spacingY = EXUI:ScalePixel(self:GetValueForUnit('raid', 'spacingY'), container)
    local maxGroups = MAX_GROUPS
    self:UpdateRaidContainerSize(container)

    local groupDirection = self:GetValueForUnit('raid', 'groupDirection') -- LEFT / RIGHT
    for i = 1, #container.groupHeaders do
        container.groupHeaders[i]:SetAttribute('yOffset', -spacingY)
        container.groupHeaders[i]:ClearAllPoints()
    end
    local prev = nil
    for i = 1, #container.groupHeaders do
        local groupHeader = container.groupHeaders[i]
        groupHeader:SetAttribute('oUF-initialConfigFunction',
            string.format([[
if not unit then
    local header = self:GetParent()
    if header:GetAttribute('EXUI-forcedUnit') then
        unit = header:GetAttribute('EXUI-forcedUnit')
        self:SetAttribute('oUF-guessUnit', unit)
        self:SetAttribute('unit', unit)
    end
end
self:SetWidth(%d); self:SetHeight(%d);]], unitWidth, unitHeight))
        if (i <= maxGroups) then
            if (not groupHeader.isFake) then
                groupHeader:SetVisibility(groupHeader.originalVisibility)
                groupHeader:SetAttribute('showRaid', true)
                groupHeader:SetAttribute('showPlayer', true)
                groupHeader:SetAttribute('showSolo', true)
                groupHeader:SetAttribute('showParty', true)
                groupHeader:SetAttribute('groupFilter', i)
            end
            groupHeader:SetAttribute('yOffset', -spacingY)
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

    local maxGroups = 8
    if (instanceType == 'raid' and difficulty == 16) then
        -- Mythic raid: only groups 1-4 are used
        maxGroups = 4
    end

    if (MAX_GROUPS ~= maxGroups) then
        MAX_GROUPS = maxGroups
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

core.UpdateHealthColor = function(self)
    local generalDB = self:GetDBForUnit('general')
    if (not generalDB) then return end
    local healthCurve = generalDB.healthCurve
    if (healthCurve) then
        local color = EXUI.oUF.colors.health
        local curveValues = {}
        for breakpoint, color in pairs(healthCurve) do
            curveValues[breakpoint] = CreateColor(color.r, color.g, color.b, color.a)
        end
        color:SetCurve(curveValues)
    end
end

EXUI:RegisterEventHandler(
    { 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED_NEW_AREA' },
    'raid-check-difficulty',
    function()
        core:CheckRaidDificulty()
    end
)

EXUI:RegisterEventHandler(
    { 'GROUP_ROSTER_UPDATE' },
    'uf-party-header-refresh',
    function()
        if InCombatLockdown() then
            return
        end
        -- Re-assert party secure visibility so roster can configure children
        -- (SecureGroupHeader_Update only runs while the header IsVisible).
        if core.headers.party then
            core:UpdateHeader('party')
        end
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
    if (frame.__unit == 'party' or frame.__unit == 'raid') then return end
    frame:EnableElement(element)
end

core.DisableElementForFrame = function(self, frame, element)
    frame:DisableElement(element)
end

-- Spread ForceFrame work across frames so Edit Mode / preview open stays responsive.
local FORCE_SHOW_BATCH = 5

core.CancelPendingForceShow = function(self)
    self.forceShowGeneration = (self.forceShowGeneration or 0) + 1
end

core.ForceShowFramesDeferred = function(self, frames, isStillForced)
    self.forceShowGeneration = (self.forceShowGeneration or 0) + 1
    local gen = self.forceShowGeneration
    local index = 1

    local function forceBatch()
        if gen ~= self.forceShowGeneration then
            return
        end
        if isStillForced and not isStillForced() then
            return
        end

        local last = math.min(index + FORCE_SHOW_BATCH - 1, #frames)
        for i = index, last do
            if gen ~= self.forceShowGeneration then
                return
            end
            local frame = frames[i]
            if frame then
                self.forcedFrames[frame.__unit] = frame
                self:ForceFrame(frame)
            end
        end

        index = last + 1
        if index <= #frames then
            C_Timer.After(0, forceBatch)
        end
    end

    C_Timer.After(0, forceBatch)
end

-- For Options. Force Show frames for editting
core.ForceShow = function(self, unit, options)
    options = options or {}
    if (InCombatLockdown()) then return end
    if (unit == 'party') then
        if not options.editorPreview and IsInGroup() and not IsInRaid() then return end
        local container = core.headers[unit]
        if (not container) then return end
        local header = self:GetPartySecureHeader(container)
        header:SetAttribute('EXUI-forcedUnit', 'party')
        header:SetAttribute('showSolo', nil)
        header:SetAttribute('showParty', nil)
        header:SetAttribute('showRaid', nil)
        header:SetAttribute('startingIndex', -4)
        header:SetVisibility('solo')
        header.isFake = true
        container:Show()
        self.forcedHeaders[unit] = header
        self:ForceShowFramesDeferred(core.partyFrames, function()
            return header.isFake
        end)
    elseif (unit == 'raid') then
        if not options.editorPreview and IsInRaid() then return end
        local header = core.headers[unit]
        if (not header) then return end
        for _, groupHeader in ipairs(header.groupHeaders) do
            if (groupHeader) then
                groupHeader:SetAttribute('EXUI-forcedUnit', 'raid')
                groupHeader:SetAttribute('showSolo', nil)
                groupHeader:SetAttribute('showParty', nil)
                groupHeader:SetAttribute('showRaid', nil)
                groupHeader:SetAttribute('startingIndex', -4)
                groupHeader:SetVisibility('solo')
                groupHeader.isFake = true
                self.forcedHeaders[unit .. groupHeader.group] = groupHeader
            end
        end
        -- Raid can be ~40 frames; never Update them all in one EnableEditor call.
        self:ForceShowFramesDeferred(core.raidFrames, function()
            local first = header.groupHeaders and header.groupHeaders[1]
            return first and first.isFake
        end)
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
    frame.originalUnit = frame.__unit
    frame.__unit = 'player'
    frame.isFake = true

    frame:EnableMouse(false)
    frame:Show()

    UnregisterUnitWatch(frame)
    RegisterUnitWatch(frame, true)

    if (frame.Update) then
        frame:Update()
    end

    UnregisterUnitWatch(frame)
    RegisterUnitWatch(frame, true)
    frame:Show()
end

core.Unforce = function(self, unit)
    if (InCombatLockdown()) then return end

    if (unit == 'party' or unit == 'raid') then
        self:CancelPendingForceShow()
    end

    if (unit == 'party') then
        local container = core.headers[unit]
        if (not container) then return end
        local header = self:GetPartySecureHeader(container)
        header.isFake = false
        header:SetAttribute('showSolo', true)
        header:SetAttribute('showParty', true)
        header:SetAttribute('showRaid', false)
        header:SetAttribute('startingIndex', 1)
        if header.originalVisibility then
            header:SetVisibility(header.originalVisibility)
        end
        self.forcedHeaders[unit] = nil
        for _, frame in ipairs(core.partyFrames) do
            if (frame) then
                self.forcedFrames[frame.__unit] = nil
                self:UnforceFrame(frame)
            end
        end
    elseif (unit == 'raid') then
        local header = core.headers[unit]
        if (not header) then return end
        for _, groupHeader in ipairs(header.groupHeaders) do
            if (groupHeader) then
                groupHeader:SetAttribute('showSolo', true)
                groupHeader:SetAttribute('showParty', true)
                groupHeader:SetAttribute('showRaid', true)
                groupHeader:SetAttribute('startingIndex', 1)
                groupHeader:SetVisibility(groupHeader.originalVisibility)
                groupHeader.isFake = false
                self.forcedHeaders[unit .. groupHeader.group] = nil
            end
        end
        for _, frame in ipairs(core.raidFrames) do
            if (frame) then
                self.forcedFrames[frame.__unit] = nil
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
    frame.__unit = frame.originalUnit
    frame:EnableMouse(true)

    if (frame.elementPreviews) then
        for element in pairs(frame.elementPreviews) do
            frame.elementPreviews[element] = false
        end
    end

    frame.isFake = false
    if (frame.Update) then
        frame:Update()
    end

    UnregisterUnitWatch(frame)
    RegisterUnitWatch(frame)
end

core.UnforceAll = function(self)
    self:CancelPendingForceShow()
    for _, frame in pairs(self.forcedFrames) do
        if (frame) then
            self:UnforceFrame(frame)
        end
    end
    -- Special case for player
    local playerFrame = self.frames['player']
    if (playerFrame and playerFrame.elementPreviews) then
        for element in pairs(playerFrame.elementPreviews) do
            playerFrame.elementPreviews[element] = false
        end
        if (playerFrame.Update) then
            playerFrame:Update()
        end
    end
    for unit in pairs(self.forcedHeaders) do
        local normalizedUnit = unit:match('^%a+')
        self:Unforce(normalizedUnit)
    end
    self.forcedFrames = {}
    self.forcedHeaders = {}
end

core.ToggleElementPreview = function(self, unit, element)
    if (unit == 'party') then
        for _, frame in ipairs(core.partyFrames) do
            if (frame and frame.isFake) then
                frame.elementPreviews = frame.elementPreviews or {}
                frame.elementPreviews[element] = not frame.elementPreviews[element]

                if (frame.Update) then
                    frame:Update()
                end
            end
        end
    elseif (unit == 'raid') then
        for _, frame in ipairs(core.raidFrames) do
            if (frame and frame.isFake) then
                frame.elementPreviews = frame.elementPreviews or {}
                frame.elementPreviews[element] = not frame.elementPreviews[element]

                if (frame.Update) then
                    frame:Update()
                end
            end
        end
    elseif (self.forcedFrames[unit]) then
        local frame = self.forcedFrames[unit]
        if (frame and frame.isFake) then
            frame.elementPreviews = frame.elementPreviews or {}
            frame.elementPreviews[element] = not frame.elementPreviews[element]

            if (frame.Update) then
                frame:Update()
            end
        end
    elseif (unit == 'player') then
        local frame = core.frames[unit]
        if (frame) then
            frame.elementPreviews = frame.elementPreviews or {}
            frame.elementPreviews[element] = not frame.elementPreviews[element]

            if (frame.Update) then
                frame:Update()
            end
        end
    elseif (self.groupUnits[unit]) then
        for i = 1, self.groupUnits[unit] do
            local forcedFrame = self.forcedFrames[unit .. i]
            if (forcedFrame and forcedFrame.isFake) then
                forcedFrame.elementPreviews = forcedFrame.elementPreviews or {}
                forcedFrame.elementPreviews[element] = not forcedFrame.elementPreviews[element]

                if (forcedFrame.Update) then
                    forcedFrame:Update()
                end
            end
        end
    end
end
