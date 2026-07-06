---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsCooldownDebug
local debugMod = EXUI:GetModule('action-bars-cooldown-debug')

debugMod.enabled = false
debugMod.lastPrint = 0
debugMod.throttle = 2
debugMod.lastCastSlot = nil

local function fmtBool(v)
    if v == nil then
        return 'nil'
    end
    if issecretvalue and issecretvalue(v) then
        return 'secret'
    end
    return v and 'true' or 'false'
end

local function safeBool(v)
    if v == nil then
        return nil
    end
    if issecretvalue and issecretvalue(v) then
        return nil
    end
    return v and true or false
end

local function getSlotLabel(slot)
    if not slot or not HasAction(slot) then
        return tostring(slot or '?')
    end
    local actionType, id = GetActionInfo(slot)
    local name = tostring(actionType or '?') .. ':' .. tostring(id or '?')
    if actionType == 'spell' and id and C_Spell and C_Spell.GetSpellName then
        name = C_Spell.GetSpellName(id) or name
    end
    return slot .. ' (' .. name .. ')'
end

debugMod.ScanActiveSlots = function(self)
    local active = {}
    if not C_ActionBar or not C_ActionBar.GetActionCooldown then
        return active
    end
    for slot = 1, 120 do
        if HasAction(slot) then
            local ok, cdInfo = pcall(C_ActionBar.GetActionCooldown, slot)
            if ok and cdInfo and safeBool(cdInfo.isActive) then
                table.insert(active, {
                    slot = slot,
                    name = getSlotLabel(slot),
                    isEnabled = cdInfo.isEnabled,
                    isOnGCD = safeBool(cdInfo.isOnGCD),
                })
            end
        end
    end
    table.sort(active, function(a, b)
        local aGcd = a.isOnGCD and 1 or 0
        local bGcd = b.isOnGCD and 1 or 0
        if aGcd ~= bGcd then
            return aGcd < bGcd
        end
        return a.slot < b.slot
    end)
    return active
end

debugMod.FindExuiButtonForSlot = function(self, slot)
    if not slot then
        return nil
    end
    local barMod = EXUI:GetModule('action-bars-bar')
    for _, frame in pairs(barMod.instances) do
        if frame.buttons then
            for _, btn in ipairs(frame.buttons) do
                local btnSlot = btn._state_action or btn.action
                if btnSlot == slot then
                    return btn, frame.barId or '?'
                end
            end
        end
    end
    return nil
end

debugMod.FindCooldownButton = function(self)
    local active = self:ScanActiveSlots()

    if self.lastCastSlot then
        local btn, barId = self:FindExuiButtonForSlot(self.lastCastSlot)
        if btn then
            return btn, barId, self.lastCastSlot, active
        end
    end

    local barMod = EXUI:GetModule('action-bars-bar')
    local activeBySlot = {}
    for _, entry in ipairs(active) do
        activeBySlot[entry.slot] = entry
    end

    for _, preferGcd in ipairs({ false, true }) do
        for _, frame in pairs(barMod.instances) do
            if frame.buttons then
                for _, btn in ipairs(frame.buttons) do
                    local slot = btn._state_action or btn.action
                    local entry = activeBySlot[slot]
                    if entry and entry.isOnGCD == preferGcd then
                        return btn, frame.barId or '?', slot, active
                    end
                end
            end
        end
    end

    for _, barId in ipairs({ 'bar1', 'bar2', 'bar3' }) do
        local frame = barMod:Get(barId)
        if frame and frame.buttons then
            for _, btn in ipairs(frame.buttons) do
                local slot = btn._state_action or btn.action
                if slot and slot > 0 and HasAction(slot) then
                    return btn, barId, slot, active
                end
            end
        end
    end
    return nil
end

debugMod.RememberCastSlot = function(self, spellID)
    if not spellID then
        return
    end
    for slot = 1, 120 do
        if HasAction(slot) then
            local actionType, id, subType = GetActionInfo(slot)
            if actionType == 'spell' and id == spellID then
                self.lastCastSlot = slot
                return
            end
            if actionType == 'macro' and subType == 'spell' and id == spellID then
                self.lastCastSlot = slot
                return
            end
            if actionType == 'macro' and GetMacroSpell then
                local macroSpell = GetMacroSpell(id)
                if macroSpell == spellID then
                    self.lastCastSlot = slot
                    return
                end
            end
        end
    end
end

debugMod.DumpDurationObject = function(self, lines, label, duration)
    if not duration then
        table.insert(lines, '  ' .. label .. ': nil')
        return
    end
    local isZero, isActive
    if duration.IsZero then
        local ok, value = pcall(duration.IsZero, duration)
        isZero = ok and value or 'err'
    end
    if duration.IsActive then
        local ok, value = pcall(duration.IsActive, duration)
        isActive = ok and value or 'err'
    end
    table.insert(lines, '  ' .. label .. ': isZero=' .. fmtBool(isZero) .. ' isActive=' .. fmtBool(isActive))
end

debugMod.DumpButton = function(self, button, label, slot, activeSlots)
    slot = slot or button._state_action or button.action
    local build = select(4, GetBuildInfo())
    local lines = {
        '|cff00ff00[EXUI CD Debug]|r ' .. (label or 'button') .. ' slot=' .. tostring(slot or '?'),
        '  build=' .. tostring(build),
        '  actionButtonUI config=' .. tostring(button.config and button.config.actionButtonUI),
        '  thisSlot=' .. getSlotLabel(slot),
    }

    if self.lastCastSlot then
        lines[#lines + 1] = '  lastCastSlot=' .. getSlotLabel(self.lastCastSlot)
    end

    activeSlots = activeSlots or self:ScanActiveSlots()
    local nonGcd = 0
    for _, entry in ipairs(activeSlots) do
        if not entry.isOnGCD then
            nonGcd = nonGcd + 1
        end
    end
    if #activeSlots == 0 then
        table.insert(lines, '  barCooldowns=0 (use an ability with a real cooldown, then re-check)')
    else
        local first = activeSlots[1]
        local suffix = first.isOnGCD and ' [GCD]' or ''
        table.insert(lines, string.format(
            '  barCooldowns=%d nonGcd=%d scanFirst=%s%s',
            #activeSlots,
            nonGcd,
            first.name,
            suffix
        ))
    end

    if slot and type(slot) == 'number' and C_ActionBar then
        local ok, cdInfo = pcall(C_ActionBar.GetActionCooldown, slot)
        if ok and cdInfo then
            table.insert(lines, '  GetActionCooldown isActive=' .. fmtBool(cdInfo.isActive)
                .. ' isEnabled=' .. fmtBool(cdInfo.isEnabled)
                .. ' isOnGCD=' .. fmtBool(cdInfo.isOnGCD))
            if cdInfo.duration and not (issecretvalue and issecretvalue(cdInfo.duration)) then
                table.insert(lines, '  cdInfo.duration=' .. tostring(cdInfo.duration))
            end
        else
            table.insert(lines, '  GetActionCooldown failed: ' .. tostring(cdInfo))
        end

        if C_ActionBar.GetActionCooldownDuration then
            local ok2, dur = pcall(C_ActionBar.GetActionCooldownDuration, slot)
            if ok2 then
                self:DumpDurationObject(lines, 'GetActionCooldownDuration', dur)
            else
                table.insert(lines, '  GetActionCooldownDuration failed: ' .. tostring(dur))
            end
        end
    end

    if button.cooldown then
        local cd = button.cooldown
        local frameDuration = cd.GetCooldownDuration and cd:GetCooldownDuration() or nil
        table.insert(lines, string.format(
            '  cooldown frame: shown=%s visible=%s alpha=%.2f drawSwipe=%s hideNumbers=%s frameDuration=%s',
            fmtBool(cd:IsShown()),
            fmtBool(cd:IsVisible()),
            cd:GetEffectiveAlpha(),
            cd.GetDrawSwipe and fmtBool(cd:GetDrawSwipe()) or '?',
            cd.GetHideCountdownNumbers and fmtBool(cd:GetHideCountdownNumbers()) or '?',
            frameDuration and tostring(frameDuration) or 'nil'
        ))
    end

    table.insert(lines, '  button.action=' .. tostring(button.action) .. ' _state_action=' .. tostring(button._state_action))

    for _, line in ipairs(lines) do
        print(line)
    end
end

debugMod.DumpOnce = function(self)
    local button, barId, slot, active = self:FindCooldownButton()
    if not button then
        print('|cff00ff00[EXUI CD Debug]|r no action bar button found')
        return
    end

    self:DumpButton(button, barId .. ' (before sync)', slot, active)

    local style = EXUI:GetModule('action-bars-style')
    style:SyncActionCooldown(button)

    self:DumpButton(button, barId .. ' (after sync)', slot, self:ScanActiveSlots())
end

debugMod.Toggle = function(self)
    self.enabled = not self.enabled
    print('|cff00ff00ExalityUI|r action bar cooldown debug:', self.enabled and 'ON' or 'OFF')
    if self.enabled then
        print('|cff00ff00[EXUI CD Debug]|r Cast an ability; debug tracks your last cast slot (non-GCD preferred)')
        self:DumpOnce()
    end
end

debugMod.Init = function(self)
    if self.eventFrame then
        return
    end

    local f = CreateFrame('Frame')
    f:RegisterEvent('ACTIONBAR_UPDATE_COOLDOWN')
    f:RegisterEvent('SPELL_UPDATE_COOLDOWN')
    f:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player')
    f:SetScript('OnEvent', function(_, event, unit, _, spellID)
        if event == 'UNIT_SPELLCAST_SUCCEEDED' then
            debugMod:RememberCastSlot(spellID)
            return
        end
        if not debugMod.enabled then
            return
        end
        local now = GetTime()
        if now - debugMod.lastPrint < debugMod.throttle then
            return
        end
        debugMod.lastPrint = now
        debugMod:DumpOnce()
    end)
    self.eventFrame = f
end

debugMod:Init()
