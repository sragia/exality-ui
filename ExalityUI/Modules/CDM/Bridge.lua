---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local profileData = EXUI:GetModule('data')

---@class EXUICDMBridge
local bridge = EXUI:GetModule('cdm-bridge')

-- Reads "is this aura / effect active" from Blizzard's Cooldown Manager. Its item frames work out aura
-- presence in Blizzard code and keep plain flags (isActive on buff viewer items, wasSetFromAura on cooldown
-- viewer items), which addons cannot get any other way while auras are secret. Read only: hooks and reads.
-- The only calls into Blizzard frames are SetAlpha / SetMouseMotionEnabled to keep the viewers out of sight.

local VIEWERS = {
    { name = 'BuffIconCooldownViewer', kind = 'buff' },
    { name = 'BuffBarCooldownViewer', kind = 'buff' },
    { name = 'EssentialCooldownViewer', kind = 'cooldown' },
    { name = 'UtilityCooldownViewer', kind = 'cooldown' },
}

local CVAR = 'cooldownViewerEnabled'

bridge.enabled = false
bridge.states = {}
bridge.frameIDs = setmetatable({}, { __mode = 'k' })
bridge.frameKinds = setmetatable({}, { __mode = 'k' })
bridge.savedAlpha = {}
bridge.spellsByCooldown = {}

local function eachViewer(callback)
    for _, entry in ipairs(VIEWERS) do
        local viewer = _G[entry.name]
        if viewer then
            callback(viewer, entry.kind)
        end
    end
end

------------------------------------------------------------
-- Static info per cooldownID: the spells it stands for and whether its aura is hidden

local function cooldownSpells(cooldownID)
    local cached = bridge.spellsByCooldown[cooldownID]
    if cached then
        return cached
    end
    local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
    cached = { spells = {} }
    if info then
        for _, spellID in pairs({ info.spellID, info.overrideSpellID }) do
            cached.spells[spellID] = true
        end
        for _, linked in ipairs(info.linkedSpellIDs) do
            cached.spells[linked] = true
        end
        cached.hideAura = bit.band(info.flags, Enum.CooldownSetSpellFlags.HideAura) ~= 0
    end
    bridge.spellsByCooldown[cooldownID] = cached
    return cached
end

------------------------------------------------------------
-- Change notifications, coalesced to one refresh per frame

local flusher = CreateFrame('Frame')
flusher:Hide()
flusher:SetScript('OnUpdate', function(self)
    self:Hide()
    if bridge.enabled and bridge.onChange then
        bridge.onChange()
    end
end)

function bridge:Notify()
    flusher:Show()
end

local function setState(cooldownID, value)
    if bridge.states[cooldownID] ~= value then
        bridge.states[cooldownID] = value
        bridge:Notify()
    end
end

------------------------------------------------------------
-- Reading the viewers

function bridge:Unpublish(frame)
    local cooldownID = self.frameIDs[frame]
    if cooldownID then
        self.frameIDs[frame] = nil
        setState(cooldownID, nil)
    end
end

function bridge:PublishFrame(frame)
    local kind = self.frameKinds[frame]
    if not self.enabled or not kind or frame:IsEditing() then
        return
    end
    -- Hidden viewers stop listening to events, so their frames would only hold stale data.
    if not frame:GetParent():IsVisible() then
        self:Unpublish(frame)
        return
    end
    local cooldownID = frame.cooldownID
    -- Frames are reused for other cooldowns without a reset, so the old entry goes first.
    if self.frameIDs[frame] ~= cooldownID then
        self:Unpublish(frame)
    end
    if not cooldownID then
        return
    end
    local value
    if kind == 'buff' then
        value = frame.isActive
    elseif cooldownSpells(cooldownID).hideAura then
        return
    else
        value = frame.wasSetFromAura
    end
    self.frameIDs[frame] = cooldownID
    setState(cooldownID, value and true or false)
end

-- Hidden viewers stop updating their frames, so their data is dropped until they show again.
function bridge:UnpublishViewer(viewer)
    for frame in pairs(self.frameIDs) do
        if frame:GetParent() == viewer then
            self:Unpublish(frame)
        end
    end
end

function bridge:Attach(frame, kind)
    if self.frameKinds[frame] then
        return
    end
    self.frameKinds[frame] = kind
    hooksecurefunc(frame, 'SetIsActive', function(itemFrame)
        bridge:PublishFrame(itemFrame)
    end)
    hooksecurefunc(frame, 'ResetCooldownData', function(itemFrame)
        bridge:Unpublish(itemFrame)
    end)
    -- Invisible viewers must not show tooltips; Blizzard re-enables mouse motion when it applies the setting.
    hooksecurefunc(frame, 'SetTooltipsShown', function(itemFrame)
        if bridge.enabled then
            itemFrame:SetMouseMotionEnabled(false)
        end
    end)
end

------------------------------------------------------------
-- Keeping Blizzard's display out of sight while it works for us

local settingAlpha = false

local function setViewerAlpha(viewer, alpha)
    settingAlpha = true
    viewer:SetAlpha(alpha)
    settingAlpha = false
end

-- Edit Mode opacity and the managed frame system (UI re-shown, override bars) both set the alpha; that value
-- is kept for restoring and replaced with 0 while enabled.
function bridge:OnViewerAlpha(viewer, alpha)
    if settingAlpha or not self.enabled then
        return
    end
    self.savedAlpha[viewer] = alpha
    setViewerAlpha(viewer, 0)
end

function bridge:ApplyHidden(viewer)
    if self.enabled then
        if self.savedAlpha[viewer] == nil then
            self.savedAlpha[viewer] = viewer:GetAlpha()
        end
        setViewerAlpha(viewer, 0)
        for frame in viewer.itemFramePool:EnumerateActive() do
            frame:SetMouseMotionEnabled(false)
        end
    elseif self.savedAlpha[viewer] ~= nil then
        setViewerAlpha(viewer, self.savedAlpha[viewer])
        self.savedAlpha[viewer] = nil
        for frame in viewer.itemFramePool:EnumerateActive() do
            frame:SetMouseMotionEnabled(viewer.tooltipsShown)
        end
    end
end

function bridge:InstallHooks()
    if self.hooksInstalled then
        return
    end
    self.hooksInstalled = true
    eachViewer(function(viewer, kind)
        hooksecurefunc(viewer, 'OnAcquireItemFrame', function(_, frame)
            if bridge.enabled then
                bridge:Attach(frame, kind)
                frame:SetMouseMotionEnabled(false)
            end
        end)
        hooksecurefunc(viewer, 'SetAlpha', function(selfViewer, alpha)
            bridge:OnViewerAlpha(selfViewer, alpha)
        end)
        viewer:HookScript('OnHide', function(selfViewer)
            bridge:UnpublishViewer(selfViewer)
        end)
    end)
end

------------------------------------------------------------
-- Blizzard's Cooldown Manager setting. Turned on only when the user had it off, and turned off again when
-- nothing needs it. Kept account wide (outside profiles and exports); dropped if the user changes it.

local settingCVar = false

local function setCVar(value)
    settingCVar = true
    C_CVar.SetCVar(CVAR, value)
    settingCVar = false
end

local function ownsCVar()
    return profileData.data.cdmBridgeOwnsCVar == true
end

local function setOwnsCVar(owns)
    profileData.data.cdmBridgeOwnsCVar = owns or nil
    if owns then
        EXUI:RegisterEventHandler('CVAR_UPDATE', 'cdm-bridge-cvar', function(_, name)
            if name == CVAR and not settingCVar then
                setOwnsCVar(false)
            end
        end)
    else
        EXUI:UnregisterEventHandler('CVAR_UPDATE', 'cdm-bridge-cvar')
    end
end

-- Whether the CVar has to change for this state (it shows or hides managed frames, so not in combat).
local function cvarChange(enabled)
    if enabled then
        return not C_CVar.GetCVarBool(CVAR)
    end
    return ownsCVar()
end

------------------------------------------------------------
-- Enable / disable (only while a loaded CDM item relies on it)

function bridge:SetEnabled(enabled, onChange)
    self.wanted = enabled
    self.onChange = onChange
    local change = cvarChange(enabled)
    if enabled == self.enabled and not change then
        return
    end
    if change and InCombatLockdown() then
        EXUI:RegisterEventHandler('PLAYER_REGEN_ENABLED', 'cdm-bridge-combat', function()
            EXUI:UnregisterEventHandler('PLAYER_REGEN_ENABLED', 'cdm-bridge-combat')
            bridge:SetEnabled(bridge.wanted, bridge.onChange)
        end)
        return
    end
    self.enabled = enabled
    if enabled then
        if change then
            setCVar('1')
            setOwnsCVar(true)
        elseif ownsCVar() then
            setOwnsCVar(true)
        end
        self:InstallHooks()
        EXUI:RegisterEventHandler('COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED', 'cdm-bridge-override', function()
            wipe(bridge.spellsByCooldown)
            bridge:Notify()
        end)
        eachViewer(function(viewer, kind)
            for frame in viewer.itemFramePool:EnumerateActive() do
                self:Attach(frame, kind)
                self:PublishFrame(frame)
            end
        end)
    else
        EXUI:UnregisterEventHandler('COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED', 'cdm-bridge-override')
        wipe(self.states)
        wipe(self.frameIDs)
        if change then
            setOwnsCVar(false)
            setCVar('0')
        end
    end
    eachViewer(function(viewer)
        self:ApplyHidden(viewer)
    end)
end

------------------------------------------------------------
-- Queries

-- true / false when one of these spells has a live Blizzard Cooldown Manager entry, nil when none does.
function bridge:IsActive(spellIDs)
    if not self.enabled then
        return nil
    end
    local tracked = nil
    for cooldownID, state in pairs(self.states) do
        local spells = cooldownSpells(cooldownID).spells
        for _, spellID in ipairs(spellIDs) do
            if spells[spellID] then
                if state then
                    return true
                end
                tracked = false
            end
        end
    end
    return tracked
end

-- For option notices: whether Blizzard's Cooldown Manager has a live entry for these spells, nil while unknown.
-- kind: 'buff' or 'cooldown', the viewers the entry is expected in.
function bridge:IsTracked(spellIDs, kind)
    if not self.enabled then
        return nil
    end
    -- Viewers hidden by their Edit Mode visibility have no data, which says nothing about the spell.
    local shown = false
    eachViewer(function(viewer, viewerKind)
        if viewerKind == kind and viewer:IsShown() then
            shown = true
        end
    end)
    if not shown then
        return nil
    end
    return self:IsActive(spellIDs) ~= nil
end
