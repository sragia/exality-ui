---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIDamageMetersViews
local views = EXUI:GetModule('damage-meters-views')

---@class EXUIDamageMetersData
local meterData = EXUI:GetModule('damage-meters-data')

meterData.blizzardHooked = false

function meterData:IsSecret(value)
    return issecretvalue and issecretvalue(value) and true or false
end

function meterData:HasSecretRestrictions()
    return C_Secrets and C_Secrets.HasSecretRestrictions and C_Secrets.HasSecretRestrictions() or false
end

function meterData:FormatPlayerName(name)
    if name == nil then
        return ''
    end
    if Ambiguate then
        return Ambiguate(name, 'all')
    end
    return name
end

local function clampDecimals(decimals)
    decimals = tonumber(decimals)
    if decimals == nil then
        decimals = 1
    end
    return math.max(0, math.min(2, math.floor(decimals + 0.5)))
end

local function buildAbbreviateOptions(decimals)
    local fractionDivisor = 1
    if decimals == 1 then
        fractionDivisor = 10
    elseif decimals >= 2 then
        fractionDivisor = 100
    end

    local function breakpoint(magnitude, abbreviation)
        return {
            breakpoint = magnitude,
            abbreviation = abbreviation,
            significandDivisor = magnitude / fractionDivisor,
            fractionDivisor = fractionDivisor,
            abbreviationIsGlobal = false,
        }
    end

    return {
        breakpointData = {
            breakpoint(1e12, 'T'),
            breakpoint(1e9, 'B'),
            breakpoint(1e6, 'M'),
            breakpoint(1e3, 'K'),
        },
    }
end

function meterData:GetAbbreviateOptions(decimals)
    decimals = clampDecimals(decimals)
    self.abbreviateOptions = self.abbreviateOptions or {}
    if not self.abbreviateOptions[decimals] then
        self.abbreviateOptions[decimals] = buildAbbreviateOptions(decimals)
    end
    return self.abbreviateOptions[decimals]
end

local function formatPlainAmount(value, decimals)
    local absNum = math.abs(value)
    local format = '%.' .. decimals .. 'f%s'
    if absNum >= 1e12 then
        return string.format(format, value / 1e12, 'T')
    end
    if absNum >= 1e9 then
        return string.format(format, value / 1e9, 'B')
    end
    if absNum >= 1e6 then
        return string.format(format, value / 1e6, 'M')
    end
    if absNum >= 1e3 then
        return string.format(format, value / 1e3, 'K')
    end
    return string.format('%.' .. decimals .. 'f', value)
end

function meterData:FormatAmount(value, decimals)
    if value == nil then
        return ''
    end

    decimals = clampDecimals(decimals)
    if not self:IsSecret(value) then
        return formatPlainAmount(value, decimals)
    end

    if AbbreviateNumbers then
        if not self.abbreviateOptionsFailed then
            local ok, result = pcall(AbbreviateNumbers, value, self:GetAbbreviateOptions(decimals))
            if ok then
                return result
            end
            self.abbreviateOptionsFailed = true
        end
        return AbbreviateNumbers(value)
    end

    return value
end

function meterData:FormatPercent(value, total)
    if value == nil or total == nil then
        return nil
    end
    if self:IsSecret(value) or self:IsSecret(total) then
        return nil
    end
    if total == 0 then
        return nil
    end
    return string.format('%d%%', math.floor((value / total) * 100 + 0.5))
end

function meterData:FormatDuration(seconds)
    if seconds == nil then
        return ''
    end
    if self:IsSecret(seconds) then
        return nil
    end
    if seconds <= 0 then
        return ''
    end
    seconds = math.floor(seconds + 0.5)
    if SecondsToClock then
        return SecondsToClock(seconds)
    end
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format('%d:%02d', minutes, secs)
end

function meterData:FormatRecapTime(seconds)
    if seconds == nil then
        return ''
    end
    if self:IsSecret(seconds) then
        return seconds
    end
    if seconds <= 0 then
        return '0.0s'
    end
    if seconds < 60 then
        return string.format('%.1fs', seconds)
    end
    return self:FormatDeathTime(seconds)
end

function meterData:GetDeathRecap(recapID)
    if not recapID or recapID == 0 or not C_DeathRecap then
        return nil
    end
    if self:IsSecret(recapID) then
        return nil
    end

    if C_DeathRecap.HasRecapEvents then
        local hasOk, hasEvents = pcall(C_DeathRecap.HasRecapEvents, recapID)
        if hasOk and hasEvents == false then
            return nil
        end
    end

    if not C_DeathRecap.GetRecapEvents then
        return nil
    end

    local ok, events = pcall(C_DeathRecap.GetRecapEvents, recapID)
    if not ok or type(events) ~= 'table' or #events == 0 then
        return nil
    end

    local maxHealth
    if C_DeathRecap.GetRecapMaxHealth then
        local healthOk, health = pcall(C_DeathRecap.GetRecapMaxHealth, recapID)
        if healthOk then
            maxHealth = health
        end
    end

    return events, maxHealth
end

function meterData:FormatDeathTime(seconds)
    if seconds == nil then
        return ''
    end
    if self:IsSecret(seconds) then
        return seconds
    end
    if seconds == -1 then
        return ''
    end
    seconds = math.max(0, math.floor(seconds + 0.5))
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    if minutes > 0 then
        return string.format('%dm %ds', minutes, secs)
    end
    return string.format('%ds', secs)
end

function meterData:ValuesDiffer(a, b)
    if self:IsSecret(a) or self:IsSecret(b) then
        return true
    end
    return a ~= b
end

function meterData:IsAvailable()
    if not C_DamageMeter or not C_DamageMeter.IsDamageMeterAvailable then
        return false, 'Damage meter API is not available.'
    end
    return C_DamageMeter.IsDamageMeterAvailable()
end

function meterData:GetSession(sessionType, sessionID, meterType)
    if not C_DamageMeter then
        return nil
    end
    if sessionType ~= nil and C_DamageMeter.GetCombatSessionFromType then
        return C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
    end
    if sessionID ~= nil and C_DamageMeter.GetCombatSessionFromID then
        return C_DamageMeter.GetCombatSessionFromID(sessionID, meterType)
    end
    return nil
end

function meterData:GetSessionSource(sessionType, sessionID, meterType, sourceGUID, sourceCreatureID)
    if not C_DamageMeter then
        return nil
    end
    if self:IsSecret(sourceGUID) or self:IsSecret(sourceCreatureID) then
        return nil
    end

    local ok, result = pcall(function()
        if sessionType ~= nil and C_DamageMeter.GetCombatSessionSourceFromType then
            return C_DamageMeter.GetCombatSessionSourceFromType(sessionType, meterType, sourceGUID, sourceCreatureID)
        end
        if sessionID ~= nil and C_DamageMeter.GetCombatSessionSourceFromID then
            return C_DamageMeter.GetCombatSessionSourceFromID(sessionID, meterType, sourceGUID, sourceCreatureID)
        end
        return nil
    end)
    if ok then
        return result
    end
    return nil
end

function meterData:IsSessionEmpty(session)
    if not session then
        return true
    end
    local sources = session.combatSources
    if type(sources) ~= 'table' or #sources == 0 then
        return true
    end
    local duration = session.durationSeconds
    if duration ~= nil and not self:IsSecret(duration) and duration <= 0 then
        return true
    end
    return false
end

function meterData:IsAvailableSessionEmpty(available)
    if not available then
        return true
    end
    if available.sessionID == 0 then
        return true
    end
    local duration = available.durationSeconds
    if duration ~= nil and not self:IsSecret(duration) and duration <= 0 then
        return true
    end
    return false
end

function meterData:SessionFingerprint(session)
    if not session then
        return nil
    end
    local total = session.totalAmount
    local maxAmount = session.maxAmount
    local duration = session.durationSeconds
    if self:IsSecret(total) or self:IsSecret(maxAmount) or self:IsSecret(duration) then
        return nil
    end
    return string.format('%s:%s:%s', tostring(total or 0), tostring(maxAmount or 0), tostring(duration or 0))
end

function meterData:SessionsMatch(a, b)
    local left = self:SessionFingerprint(a)
    local right = self:SessionFingerprint(b)
    if not left or not right then
        return false
    end
    return left == right
end

function meterData:IsOverallLike(session, meterType)
    if not session or meterType == nil then
        return false
    end
    return self:SessionsMatch(session, self:GetSession(views.Session.Overall, nil, meterType))
end

function meterData:GetAvailableSessions()
    if not C_DamageMeter or not C_DamageMeter.GetAvailableCombatSessions then
        return {}
    end

    local sessions = C_DamageMeter.GetAvailableCombatSessions() or {}
    local filtered = {}
    for _, session in ipairs(sessions) do
        if not self:IsAvailableSessionEmpty(session) then
            filtered[#filtered + 1] = session
        end
    end
    return filtered
end

function meterData:GetHistoricSessions(meterType)
    local overall = self:GetSession(views.Session.Overall, nil, meterType)
    local current = self:GetSession(views.Session.Current, nil, meterType)
    local overallFP = self:SessionFingerprint(overall)
    local currentFP = self:SessionFingerprint(current)
    local filtered = {}
    for _, available in ipairs(self:GetAvailableSessions()) do
        local sessionID = available.sessionID
        if sessionID and sessionID > 0 then
            local session = self:GetSession(nil, sessionID, meterType)
            if session and not self:IsSessionEmpty(session) then
                local fingerprint = self:SessionFingerprint(session)
                local isDuplicate = fingerprint and (fingerprint == overallFP or fingerprint == currentFP)
                if not isDuplicate then
                    filtered[#filtered + 1] = available
                end
            end
        end
    end
    table.sort(filtered, function(a, b)
        return (a.sessionID or 0) < (b.sessionID or 0)
    end)
    return filtered
end

function meterData:GetLatestHistoricSession(meterType)
    local latestID
    for _, available in ipairs(self:GetAvailableSessions()) do
        local sessionID = available.sessionID
        if sessionID and (latestID == nil or sessionID > latestID) then
            latestID = sessionID
        end
    end
    if latestID == nil then
        return nil
    end
    local session = self:GetSession(nil, latestID, meterType)
    if self:IsSessionEmpty(session) then
        return nil
    end
    return session, latestID
end

function meterData:GetSessionDuration(sessionType)
    if not C_DamageMeter or not C_DamageMeter.GetSessionDurationSeconds or sessionType == nil then
        return nil
    end
    return C_DamageMeter.GetSessionDurationSeconds(sessionType)
end

function meterData:ResetAllSessions()
    if C_DamageMeter and C_DamageMeter.ResetAllCombatSessions then
        C_DamageMeter.ResetAllCombatSessions()
    end
end

function meterData:MatchesWindowSession(window, sessionID)
    if window.sessionID ~= nil then
        return window.sessionID == sessionID
    end
    return sessionID == 0 or sessionID == nil
end

local DUMMY_CLASSES = {
    'DEATHKNIGHT', 'MAGE', 'WARLOCK', 'SHAMAN', 'PALADIN',
    'HUNTER', 'DRUID', 'PRIEST', 'ROGUE', 'WARRIOR',
    'MONK', 'DEMONHUNTER', 'EVOKER',
}

local DUMMY_NAMES = {
    'Vexira', 'Thorgrim', 'Liriel', 'Dunric', 'Saelune',
    'Brammek', 'Ysoria', 'Falkor', 'Nerissa', 'Gorrim',
    'Elowyn', 'Miravel', 'Haldrin', 'Iskara', 'Tavian',
    'Orinna', 'Jorund', 'Selthara', 'Caelum', 'Elandra',
}

local DUMMY_SPELLS = {
    116, 133, 30451, 44614, 11366, 2948, 5143, 2136, 1449, 122,
    585, 589, 403, 5176, 12294, 23881, 49998, 348,
}

local DUMMY_SPELL_WEIGHTS = { 0.42, 0.24, 0.15, 0.1, 0.06, 0.03 }

local function buildDummySpells(total, index)
    local count = 4 + ((index - 1) % 3)
    local spells = {}
    local assigned = 0
    for n = 1, count do
        local amount
        if n == count then
            amount = math.max(1, total - assigned)
        else
            amount = math.max(1, math.floor(total * DUMMY_SPELL_WEIGHTS[n]))
            assigned = assigned + amount
        end
        spells[n] = {
            spellID = DUMMY_SPELLS[((index + n - 2) % #DUMMY_SPELLS) + 1],
            totalAmount = amount,
            amountPerSecond = amount / 84,
            creatureName = '',
            overkillAmount = 0,
            isAvoidable = false,
            isDeadly = false,
            combatSpellDetails = {
                unitName = '',
                unitClassFilename = '',
                classification = '',
                isPet = false,
                isMob = true,
                amount = amount,
                specIconID = 0,
            },
        }
    end
    return spells
end

function meterData:GetDummySession()
    local sources = {}
    local totalAmount = 0
    local maxAmount = 0
    for i = 1, 20 do
        local total = math.floor(120000 - (i - 1) * 5400 - (i % 3) * 800)
        local amountPerSecond = total / 84
        totalAmount = totalAmount + total
        if total > maxAmount then
            maxAmount = total
        end
        sources[i] = {
            name = DUMMY_NAMES[((i - 1) % #DUMMY_NAMES) + 1],
            classFilename = DUMMY_CLASSES[((i - 1) % #DUMMY_CLASSES) + 1],
            totalAmount = total,
            amountPerSecond = amountPerSecond,
            isLocalPlayer = false,
            deathRecapID = 0,
            deathTimeSeconds = 0,
            classification = '',
            sourceDisplayType = views.SourceDisplay.Ally,
            specIconID = 0,
            combatSpells = buildDummySpells(total, i),
        }
    end

    local _, classFilename = UnitClass('player')
    local playerName = UnitName('player') or 'You'
    local insertAt = math.max(1, #sources - 2)
    local above = sources[insertAt - 1]
    local below = sources[insertAt]
    local playerTotal = 4200
    if above and below then
        playerTotal = math.floor(((above.totalAmount or 0) + (below.totalAmount or 0)) / 2)
    end
    totalAmount = totalAmount + playerTotal
    table.insert(sources, insertAt, {
        name = playerName,
        classFilename = classFilename or 'MAGE',
        totalAmount = playerTotal,
        amountPerSecond = playerTotal / 84,
        isLocalPlayer = true,
        deathRecapID = 0,
        deathTimeSeconds = 0,
        classification = '',
        sourceDisplayType = views.SourceDisplay.Ally,
        specIconID = 0,
        combatSpells = buildDummySpells(playerTotal, insertAt),
    })

    return {
        maxAmount = maxAmount,
        totalAmount = totalAmount,
        durationSeconds = 84,
        combatSources = sources,
    }
end

function meterData:HideBlizzardMeter()
    if not DamageMeter then
        return
    end

    DamageMeter:Hide()

    if self.blizzardHooked then
        return
    end

    self.blizzardHooked = true
    hooksecurefunc(DamageMeter, 'Show', function()
        local meters = EXUI:GetModule('damage-meters')
        if meters.enabled then
            DamageMeter:Hide()
        end
    end)
end

function meterData:RestoreBlizzardMeter()
    if DamageMeter and not meterData:ShouldHideBlizzard() then
        local available = self:IsAvailable()
        if available and DamageMeter.UpdateShownState then
            DamageMeter:UpdateShownState()
        elseif available then
            DamageMeter:Show()
        end
    end
end

function meterData:ShouldHideBlizzard()
    local meters = EXUI:GetModule('damage-meters')
    return meters.enabled
end

function meterData:UpdateBlizzardVisibility()
    if self:ShouldHideBlizzard() then
        self:HideBlizzardMeter()
    else
        self:RestoreBlizzardMeter()
    end
end
