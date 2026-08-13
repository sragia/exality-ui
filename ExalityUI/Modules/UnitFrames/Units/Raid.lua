---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIUnitFramesRaid
local raid = EXUI:GetModule('uf-unit-raid')

raid.unit = 'raid'
raid.container = nil
raid.frames = {}

raid.Init = function(self)
    core:SetDefaultsForUnit(self.unit, {
        -- General
        ['enable'] = true,
        ['showBlizzardFrame'] = false,
        ['overrideStatusBarTexture'] = '',
        ['overrideDamageAbsorbTexture'] = '',
        ['overrideHealAbsorbTexture'] = '',
        ['overrideHealthColor'] = true,
        ['useCustomHealthColor'] = false,
        ['useSmoothHealthColor'] = false,
        ['customHealthColor'] = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
        ['useClassColoredBackdrop'] = false,
        ['useCustomBackdropColor'] = true,
        ['customBackdropColor'] = { r = 0.07, g = 0.07, b = 0.07, a = 1 },
        ['useCustomHealthAbsorbsColor'] = false,
        ['healAbsorbColor'] = { r = 100 / 255, g = 100 / 255, b = 100 / 255, a = 0.8 },
        ['damageAbsorbColor'] = { r = 0, g = 133 / 255, b = 163 / 255, a = 1 },
        -- Header Specific
        ['sizeWidth'] = 120,
        ['sizeHeight'] = 45,
        ['positionAnchorPoint'] = 'LEFT',
        ['positionRelativePoint'] = 'LEFT',
        ['positionXOff'] = 87.40,
        ['positionYOff'] = 113.00,
        ['spacingY'] = 1,
        ['spacingX'] = 1,
        ['groupDirection'] = 'LEFT',
        -- Name
        ['nameEnable'] = true,
        ['nameFont'] = 'DMSans',
        ['nameFontSize'] = 12,
        ['nameFontFlag'] = 'OUTLINE',
        ['nameFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['nameAnchorPoint'] = 'BOTTOMLEFT',
        ['nameRelativeAnchorPoint'] = 'BOTTOMLEFT',
        ['nameTag'] = '[name]',
        ['nameXOffset'] = 3,
        ['nameYOffset'] = 0,
        ['nameMaxWidth'] = 70,
        -- Health Text
        ['healthEnable'] = false,
        ['healthFont'] = 'DMSans',
        ['healthFontSize'] = 12,
        ['healthFontFlag'] = 'OUTLINE',
        ['healthFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['healthAnchorPoint'] = 'RIGHT',
        ['healthRelativeAnchorPoint'] = 'RIGHT',
        ['healthXOffset'] = -5,
        ['healthYOffset'] = -10,
        ['healthTag'] = '[curhp:formatted]',
        -- Health Percentage
        ['healthpercEnable'] = true,
        ['healthpercFont'] = 'DMSans',
        ['healthpercFontSize'] = 12,
        ['healthpercFontFlag'] = 'OUTLINE',
        ['healthpercFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['healthpercAnchorPoint'] = 'BOTTOMRIGHT',
        ['healthpercRelativeAnchorPoint'] = 'BOTTOMRIGHT',
        ['healthpercXOffset'] = -1,
        ['healthpercYOffset'] = 3,
        ['healthpercTag'] = '[perhp]%',
        -- Raid Roles
        ['raidRolesEnable'] = true,
        ['raidRolesAnchorPoint'] = 'LEFT',
        ['raidRolesRelativeAnchorPoint'] = 'TOPLEFT',
        ['raidRolesXOff'] = 0,
        ['raidRolesYOff'] = 0,
        ['raidRolesScale'] = 1,
        -- Raid Target Indicator
        ['raidTargetIndicatorEnable'] = true,
        ['raidTargetIndicatorAnchorPoint'] = 'CENTER',
        ['raidTargetIndicatorRelativeAnchorPoint'] = 'TOP',
        ['raidTargetIndicatorXOff'] = 0,
        ['raidTargetIndicatorYOff'] = 0,
        ['raidTargetIndicatorScale'] = 1,
        -- Health Percentage
        ['offlineEnable'] = true,
        ['offlineFont'] = 'DMSans',
        ['offlineFontSize'] = 10,
        ['offlineFontFlag'] = 'OUTLINE',
        ['offlineFontColor'] = { r = 171 / 255, g = 0, b = 0, a = 1 },
        ['offlineAnchorPoint'] = 'TOP',
        ['offlineRelativeAnchorPoint'] = 'TOP',
        ['offlineXOffset'] = 0,
        ['offlineYOffset'] = -2,
        ['offlineTag'] = '[offline]',
        -- Resurrect Indicator
        ['ressurectEnable'] = true,
        ['ressurectAnchorPoint'] = 'CENTER',
        ['ressurectRelativeAnchorPoint'] = 'TOP',
        ['ressurectXOff'] = 0,
        ['ressurectYOff'] = 0,
        ['ressurectScale'] = 1,
        -- Summon Indicator
        ['summonEnable'] = true,
        ['summonAnchorPoint'] = 'CENTER',
        ['summonRelativeAnchorPoint'] = 'TOP',
        ['summonXOff'] = 0,
        ['summonYOff'] = 0,
        ['summonScale'] = 1,
        -- Absorbs
        ['damageAbsorbEnable'] = true,
        ['damageAbsorbShowOverIndicator'] = false,
        ['damageAbsorbShowAt'] = 'AS_EXTENSION',
        ['healAbsorbEnable'] = true,
        ['healAbsorbShowOverIndicator'] = true,
        -- Phase Indicator
        ['phaseIndicatorEnable'] = true,
        ['phaseIndicatorAnchorPoint'] = 'CENTER',
        ['phaseIndicatorRelativeAnchorPoint'] = 'CENTER',
        ['phaseIndicatorXOff'] = 0,
        ['phaseIndicatorYOff'] = 0,
        ['phaseIndicatorScale'] = 1,
        -- Power
        ['powerEnable'] = false,
        ['powerHeight'] = 3,
        -- Group Role Indicator
        ['groupRoleIndicatorEnable'] = true,
        ['groupRoleIndicatorAnchorPoint'] = 'TOPLEFT',
        ['groupRoleIndicatorRelativeAnchorPoint'] = 'TOPLEFT',
        ['groupRoleIndicatorXOff'] = 2,
        ['groupRoleIndicatorYOff'] = -2,
        ['groupRoleIndicatorScale'] = 1,
        ['groupRoleIndicatorHideTank'] = true,
        ['groupRoleIndicatorHideHealer'] = false,
        ['groupRoleIndicatorHideDamager'] = true,
        -- Dispel Overlay
        ['dispelOverlayEnable'] = true,
        ['dispelOverlayFilter'] = 'RAID',
        ['dispelOverlayAlpha'] = 1,
        ['dispelOverlayShowOverlay'] = true,
        ['dispelOverlayShowIcon'] = false,
        ['dispelOverlayIconSize'] = 16,
        ['dispelOverlayAnchorPoint'] = 'CENTER',
        ['dispelOverlayRelativeAnchorPoint'] = 'CENTER',
        ['dispelOverlayXOff'] = 0,
        ['dispelOverlayYOff'] = 0,
        -- Targeting
        ['targetBorderEnable'] = true,
        ['targetBorderColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['mouseoverBorderEnable'] = false,
        ['mouseoverBorderColor'] = { r = 1, g = 1, b = 1, a = 0.7 },
    })

    local shouldShowBlizzardFrame = core:GetValueForUnit('raid', 'showBlizzardFrame') and
        not core:GetValueForUnit('raid', 'enable')
    if (shouldShowBlizzardFrame) then
        return;
    end

    self:DisableBlizzard()
end

-- Hide Blizzard compact raid/party frames by reparenting them to a permanently
-- hidden frame. Show/Hide hooks alone fail mid-combat on roster updates.
raid.DisableBlizzard = function(self)
    if self._blizzardDisabled then
        return
    end
    self._blizzardDisabled = true

    local hiddenParent = CreateFrame('Frame')
    hiddenParent:Hide()

    local pending = {}

    local function safeReparent(frame)
        if not frame then
            return
        end
        if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
            pending[frame] = true
            return
        end
        frame:SetParent(hiddenParent)
        pending[frame] = nil
    end

    local function handleFrame(frame, skipReparent)
        if not frame then
            return
        end

        frame:UnregisterAllEvents()
        pcall(frame.Hide, frame)

        if not skipReparent then
            safeReparent(frame)
            hooksecurefunc(frame, 'SetParent', function(hooked, parent)
                if parent ~= hiddenParent then
                    safeReparent(hooked)
                end
            end)
        end

        local health = frame.healthBar or frame.healthbar or frame.HealthBar
            or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)
        if health then
            health:UnregisterAllEvents()
        end
        local power = frame.manabar or frame.ManaBar
        if power then
            power:UnregisterAllEvents()
        end
        local castbar = frame.castBar or frame.spellbar or frame.CastingBarFrame
        if castbar then
            castbar:UnregisterAllEvents()
        end
        local altpower = frame.powerBarAlt or frame.PowerBarAlt
        if altpower then
            altpower:UnregisterAllEvents()
        end
        local buffs = frame.BuffFrame or frame.AurasFrame
        if buffs then
            buffs:UnregisterAllEvents()
        end
        local debuffs = frame.DebuffFrame
        if debuffs then
            debuffs:UnregisterAllEvents()
        end
        local pet = frame.petFrame or frame.PetFrame
        if pet then
            pet:UnregisterAllEvents()
        end
    end

    handleFrame(_G.CompactRaidFrameContainer)
    if _G.CompactRaidFrameContainer then
        _G.CompactRaidFrameContainer:HookScript('OnShow', function(frame)
            frame:Hide()
        end)
    end

    handleFrame(_G.CompactRaidFrameManager)
    if CompactRaidFrameManager_SetSetting then
        CompactRaidFrameManager_SetSetting('IsShown', '0')
    end

    -- Party / raid-style party (re-shown by Blizzard on GROUP_ROSTER_UPDATE).
    if _G.PartyFrame then
        handleFrame(_G.PartyFrame)
        if _G.PartyFrame.PartyMemberFramePool then
            for memberFrame in _G.PartyFrame.PartyMemberFramePool:EnumerateActive() do
                handleFrame(memberFrame, true)
            end
        end
    end
    handleFrame(_G.CompactPartyFrame)
    local membersPerGroup = _G.MEMBERS_PER_RAID_GROUP or 5
    for i = 1, membersPerGroup do
        handleFrame(_G['CompactPartyFrameMember' .. i])
    end

    EXUI:RegisterEventHandler(
        { 'PLAYER_REGEN_ENABLED' },
        'uf-blizzard-disable',
        function()
            for frame in pairs(pending) do
                safeReparent(frame)
            end
        end
    )
end

raid.Create = function(self, frame, unit)
    core:Base(frame)

    frame.Health = EXUI:GetModule('uf-element-health'):Create(frame)
    frame.Name = EXUI:GetModule('uf-element-name'):Create(frame)
    frame.Range = EXUI:GetModule('uf-element-range'):Create(frame)
    frame.HealthText = EXUI:GetModule('uf-element-health-text'):Create(frame)
    frame.HealthPerc = EXUI:GetModule('uf-element-health-perc'):Create(frame)
    frame.RaidTargetIndicator = EXUI:GetModule('uf-element-raid-target-indicator'):Create(frame)
    frame.RaidRoles = EXUI:GetModule('uf-element-raid-roles'):Create(frame)
    frame.PhaseIndicator = EXUI:GetModule('uf-element-phase-indicator'):Create(frame)
    frame.Offline = EXUI:GetModule('uf-element-offline'):Create(frame)
    frame.HealthPrediction = EXUI:GetModule('uf-element-healthprediction'):Create(frame)
    frame.ReadyCheckIndicator = EXUI:GetModule('uf-element-ready-check-indicator'):Create(frame)
    frame.ResurrectIndicator = EXUI:GetModule('uf-element-ressurect-indicator'):Create(frame)
    frame.SummonIndicator = EXUI:GetModule('uf-element-summon-indicator'):Create(frame)
    frame.Power = EXUI:GetModule('uf-element-power'):Create(frame)
    frame.CustomTexts = EXUI:GetModule('uf-element-custom-texts'):Create(frame)
    frame.GroupRoleIndicator = EXUI:GetModule('uf-element-group-role-indicator'):Create(frame)
    frame.DispelOverlay = EXUI:GetModule('uf-element-dispel-overlay'):Create(frame)
    frame.SelectionHighlight = EXUI:GetModule('uf-element-selection-highlight'):Create(frame)

    frame.Update = function(self) raid:Update(self) end

    self:Update(frame)
end

raid.Update = function(self, frame)
    local db = frame.db
    if (not InCombatLockdown()) then
        EXUI:SetSize(frame, db.sizeWidth, db.sizeHeight)
    end
    core:UpdateFrame(frame)
end

core:RegisterPlayerGroupUnit('raid', 'raid', {
    showParty = true,
    showPlayer = true,
    showSolo = true,
    showRaid = true,
})
