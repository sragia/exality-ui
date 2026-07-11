---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUICooldownDisplay
local cooldownDisplay = EXUI:GetModule('cooldown-display')

local function formatCooldownDuration(remaining, formatKey)
    if remaining <= 0 then
        return ''
    end

    if formatKey == 'default' then
        if remaining >= 3600 then
            return string.format('%dh', math.floor(remaining / 3600))
        end
        if remaining >= 180 then
            return string.format('%dm', math.floor(remaining / 60))
        end
        if remaining >= 60 then
            return string.format('%d:%02d', math.floor(remaining / 60), math.floor(remaining % 60))
        end
        if remaining >= 5 then
            return string.format('%d', math.floor(remaining))
        end
        return string.format('%.1f', remaining)
    end

    -- MM:SS (<3m) variant used by Aura Displays
    if remaining >= 3600 then
        return string.format('%dh', math.floor(remaining / 3600))
    end
    if remaining >= 180 then
        return string.format('%dm', math.floor(remaining / 60))
    end
    if remaining >= 60 then
        return string.format('%d:%02d', math.floor(remaining / 60), math.floor(remaining % 60))
    end
    if remaining >= 10 then
        return string.format('%d', math.floor(remaining + 0.5))
    end
    return string.format('%.1f', remaining)
end

local function isSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function isTrue(value)
    if value == nil or isSecret(value) then
        return false
    end
    return value and true or false
end

local function safeNumber(value)
    if value == nil or isSecret(value) then
        return nil
    end
    return tonumber(value)
end

local function getCooldownSource(db)
    local source = db.cooldownSource
    if source == 'spell' or source == 'item' or source == 'equipment' then
        return source
    end
    return db.isItem and 'item' or 'spell'
end

local function shouldHideSpellCooldown(spellID)
    if C_Secrets and C_Secrets.ShouldSpellCooldownBeSecret then
        local ok, hidden = pcall(C_Secrets.ShouldSpellCooldownBeSecret, spellID)
        if ok and hidden then
            return true
        end
    end
    if C_Secrets and C_Secrets.ShouldCooldownsBeSecret then
        local ok, hidden = pcall(C_Secrets.ShouldCooldownsBeSecret)
        if ok and hidden then
            return true
        end
    end
    return false
end

function cooldownDisplay:GetSpellChargeData(spellID)
    local ok, chargeInfo = pcall(C_Spell.GetSpellCharges, spellID)
    if not ok or not chargeInfo then
        return nil
    end

    local cooldownStartTimeRaw = chargeInfo.cooldownStartTime
    local cooldownDurationRaw = chargeInfo.cooldownDuration
    local chargeModRateRaw = chargeInfo.chargeModRate

    local currentCharges = safeNumber(chargeInfo.currentCharges)
    local cooldownStartTime = safeNumber(cooldownStartTimeRaw)
    local cooldownDuration = safeNumber(cooldownDurationRaw)
    local chargeModRate = safeNumber(chargeModRateRaw) or 1

    if not currentCharges or cooldownStartTime == nil or cooldownDuration == nil then
        return {
            charges = nil,
            start = cooldownStartTimeRaw,
            duration = cooldownDurationRaw,
            modRate = chargeModRateRaw,
            remaining = nil,
            isSecret = true,
        }
    end

    return {
        charges = currentCharges,
        start = cooldownStartTimeRaw,
        duration = cooldownDurationRaw,
        modRate = chargeModRateRaw,
        remaining = math.max(0, (cooldownStartTime + cooldownDuration) - GetTime()),
        isSecret = false,
    }
end

function cooldownDisplay:GetSpellCooldownData(spellID)
    local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
    if not ok or not info then
        return nil
    end

    local startRaw = info.startTime
    local durationRaw = info.duration
    local modRateRaw = info.modRate or 1

    local start = safeNumber(startRaw)
    local duration = safeNumber(durationRaw)
    local modRate = safeNumber(modRateRaw) or 1
    if start == nil or duration == nil then
        return {
            start = startRaw,
            duration = durationRaw,
            modRate = modRateRaw,
            remaining = nil,
            isOnCooldown = false,
            isSecret = shouldHideSpellCooldown(spellID),
        }
    end

    local remaining = math.max(0, (start + duration) - GetTime())
    local isOnGCD = isTrue(info.isOnGCD)
    local isOnCooldown = duration > 0 and remaining > 0 and not isOnGCD

    return {
        start = startRaw,
        duration = durationRaw,
        modRate = modRateRaw,
        remaining = remaining,
        isOnCooldown = isOnCooldown,
        isSecret = false,
    }
end

function cooldownDisplay:GetItemCooldownData(itemID)
    local start, duration, enable = C_Item.GetItemCooldown(itemID)
    start = safeNumber(start)
    duration = safeNumber(duration)
    local isEnabled = isTrue(enable)
    local count = safeNumber(C_Item.GetItemCount(itemID, false, true)) or 0

    if start == nil or duration == nil then
        local legacyStart, legacyDuration = C_Container.GetItemCooldown(itemID)
        start = safeNumber(legacyStart) or 0
        duration = safeNumber(legacyDuration) or 0
    end

    local remaining = math.max(0, ((start or 0) + (duration or 0)) - GetTime())
    return {
        start = start or 0,
        duration = duration or 0,
        modRate = 1,
        count = count,
        remaining = remaining,
        isOnCooldown = isEnabled and duration and duration > 0 and remaining > 0,
    }
end

function cooldownDisplay:GetEquipmentCooldownData(slotID)
    local start, duration, enable = GetInventoryItemCooldown('player', slotID)
    start = safeNumber(start) or 0
    duration = safeNumber(duration) or 0
    enable = safeNumber(enable) or 1

    local remaining = math.max(0, (start + duration) - GetTime())
    return {
        start = start,
        duration = duration,
        modRate = 1,
        count = nil,
        remaining = remaining,
        isOnCooldown = enable > 0 and duration > 0 and remaining > 0,
    }
end

function cooldownDisplay:GetTexture(db)
    local source = getCooldownSource(db)
    if source == 'spell' then
        local spellID = tonumber(db.spellID)
        if spellID then
            local texture = C_Spell.GetSpellTexture(spellID)
            if texture then
                return texture, true
            end
        end
    elseif source == 'item' then
        local itemID = tonumber(db.itemID)
        if itemID then
            local _, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemID)
            if itemTexture then
                return itemTexture, true
            end
            if C_Item.GetItemInfoInstant then
                local _, _, _, _, _, _, _, _, _, instantTexture = C_Item.GetItemInfoInstant(itemID)
                if instantTexture then
                    return instantTexture, true
                end
            end
            if C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(itemID)
            end
        end
    elseif source == 'equipment' then
        local slotID = tonumber(db.equipmentSlot)
        if slotID then
            local texture = GetInventoryItemTexture('player', slotID)
            if texture then
                return texture, true
            end
        end
    end

    return 'Interface\\Icons\\INV_Misc_QuestionMark', false
end

function cooldownDisplay:RenderCooldown(frame, db)
    local source = getCooldownSource(db)
    local cooldownInfo = nil
    local sourceID = nil

    if source == 'spell' then
        sourceID = tonumber(db.spellID)
        if sourceID then
            if db.showStacks then
                local chargeInfo = self:GetSpellChargeData(sourceID)
                if chargeInfo then
                    cooldownInfo = {
                        start = chargeInfo.start,
                        duration = chargeInfo.duration,
                        modRate = chargeInfo.modRate,
                        remaining = chargeInfo.remaining,
                        isOnCooldown = chargeInfo.remaining > 0,
                    }
                    frame.StackText:SetText(chargeInfo.charges or '')
                else
                    frame.StackText:SetText('')
                end
            else
                cooldownInfo = self:GetSpellCooldownData(sourceID)
            end
        end
    elseif source == 'item' then
        sourceID = tonumber(db.itemID)
        if sourceID then
            cooldownInfo = self:GetItemCooldownData(sourceID)
            if db.showStacks then
                frame.StackText:SetText(cooldownInfo.count or '')
            end
        end
    elseif source == 'equipment' then
        sourceID = tonumber(db.equipmentSlot)
        if sourceID then
            cooldownInfo = self:GetEquipmentCooldownData(sourceID)
        end
    end

    if not cooldownInfo then
        frame.currentCooldownInfo = nil
        frame.Cooldown:SetCooldown(0, 0)
        frame.Texture:SetVertexColor(1, 1, 1, 1)
        if source ~= 'item' or not db.showStacks then
            frame.StackText:SetText('')
        end
        return
    end

    local ok = false
    if cooldownInfo.start ~= nil and cooldownInfo.duration ~= nil then
        ok = pcall(frame.Cooldown.SetCooldown, frame.Cooldown, cooldownInfo.start, cooldownInfo.duration, cooldownInfo.modRate)
    end
    if not ok then
        frame.Cooldown:SetCooldown(0, 0)
    end
    frame.currentCooldownInfo = cooldownInfo
    frame.Texture:SetVertexColor(1, 1, 1, 1)
end

function cooldownDisplay:Create(frame)
    local Cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
    Cooldown:SetPoint('TOPLEFT', -1, 1)
    Cooldown:SetPoint('BOTTOMRIGHT', 1, -1)
    Cooldown:SetHideCountdownNumbers(true)
    Cooldown:SetDrawSwipe(true)
    Cooldown:SetDrawBling(false)
    Cooldown:SetDrawEdge(false)
    frame.Cooldown = Cooldown

    local CooldownFont = CreateFont('ExalityUI_CD_Font_' .. frame.ID)
    CooldownFont:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    frame.CooldownFont = CooldownFont
    Cooldown:SetCountdownFont('ExalityUI_CD_Font_' .. frame.ID)

    local ElementFrame = CreateFrame('Frame', nil, frame)
    ElementFrame:SetAllPoints()
    ElementFrame:SetFrameLevel(Cooldown:GetFrameLevel() + 10)
    frame.ElementFrame = ElementFrame

    local Texture = frame:CreateTexture(nil, 'BACKGROUND')
    Texture:SetPoint('TOPLEFT', 1, -1)
    Texture:SetPoint('BOTTOMRIGHT', -1, 1)
    frame.Texture = Texture

    local StackText = ElementFrame:CreateFontString(nil, 'OVERLAY')
    StackText:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    StackText:SetPoint('CENTER', ElementFrame, 'TOPRIGHT', -5, -2)
    StackText:SetText('')
    StackText:Hide()
    frame.StackText = StackText

    local CooldownText = ElementFrame:CreateFontString(nil, 'OVERLAY')
    CooldownText:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    CooldownText:SetPoint('CENTER', ElementFrame, 'CENTER', 0, 0)
    CooldownText:SetText('')
    frame.CooldownText = CooldownText
    frame.cooldownTextElapsed = 0
    frame.readyPollElapsed = 0

    frame.Events = {
        'ITEM_DATA_LOAD_RESULT',
        'SPELL_UPDATE_COOLDOWN',
        'SPELL_UPDATE_CHARGES',
        'BAG_UPDATE_COOLDOWN',
        'PLAYER_EQUIPMENT_CHANGED',
    }

    frame.RegisterFrameEvents = function(selfRef)
        selfRef:UnregisterAllEvents()
        for _, event in ipairs(selfRef.Events) do
            selfRef:RegisterEvent(event)
        end
    end

    frame.OnChange = function(selfRef, event, ...)
        local db = selfRef.db
        if not db or not db.enable then
            return
        end

        if event == 'ITEM_DATA_LOAD_RESULT' then
            local itemID = ...
            local trackedItemID = tonumber(db.itemID)
            if trackedItemID and itemID and tonumber(itemID) == trackedItemID then
                local texture, isCorrect = cooldownDisplay:GetTexture(db)
                selfRef.invalidTexture = isCorrect
                selfRef.Texture:SetTexture(texture)
            end
            return
        end

        if not selfRef.invalidTexture then
            local texture, isCorrect = cooldownDisplay:GetTexture(db)
            selfRef.invalidTexture = isCorrect
            selfRef.Texture:SetTexture(texture)
        end

        cooldownDisplay:RenderCooldown(selfRef, db)
    end

    frame:SetScript('OnEvent', frame.OnChange)
    frame:SetScript('OnUpdate', function(selfRef, elapsed)
        local db = selfRef.db
        if not db or not db.enable or not selfRef:IsShown() then
            return
        end

        selfRef.readyPollElapsed = (selfRef.readyPollElapsed or 0) + elapsed
        local readyPollInterval = tonumber(db.readyPollInterval) or 1
        if selfRef.readyPollElapsed >= readyPollInterval then
            selfRef.readyPollElapsed = 0
            cooldownDisplay:RenderCooldown(selfRef, db)
        end

        if not db.showCooldownText then
            if selfRef.CooldownText then
                selfRef.CooldownText:SetText('')
            end
            return
        end

        local interval = tonumber(db.cooldownTextUpdateInterval) or 0.05
        selfRef.cooldownTextElapsed = (selfRef.cooldownTextElapsed or 0) + elapsed
        if selfRef.cooldownTextElapsed < interval then
            return
        end
        selfRef.cooldownTextElapsed = 0

        local info = selfRef.currentCooldownInfo
        if not info then
            selfRef.CooldownText:SetText('')
            return
        end

        local start = safeNumber(info.start)
        local duration = safeNumber(info.duration)
        local modRate = safeNumber(info.modRate)
        if start == nil or duration == nil then
            selfRef.CooldownText:SetText('')
            return
        end
        modRate = modRate and modRate > 0 and modRate or 1
        local remaining = math.max(0, ((start + duration) - GetTime()) / modRate)

        if remaining <= 0 then
            selfRef.CooldownText:SetText('')
            return
        end

        selfRef.CooldownText:SetText(formatCooldownDuration(remaining, db.cooldownTextFormat or 'mmss'))
    end)
end

function cooldownDisplay:Update(frame)
    local db = frame.db
    if not db or not db.enable then
        frame:Hide()
        return
    end

    frame:Show()
    frame:RegisterFrameEvents()

    frame:SetSize(db.width, db.height)
    frame:ClearAllPoints()
    frame:SetPoint(db.anchorPoint, UIParent, db.relativePoint, db.XOff, db.YOff)
    frame:SetFrameStrata(db.frameStrata)
    frame:SetFrameLevel(db.frameLevel)
    frame.Cooldown:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.ElementFrame:SetFrameLevel(frame.Cooldown:GetFrameLevel() + 10)
    frame:SetBackdropBorderColor(db.borderColor.r, db.borderColor.g, db.borderColor.b, db.borderColor.a)
    frame:SetBackdropColor(0, 0, 0, 0)

    frame.CooldownFont:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)
    frame.Cooldown:SetHideCountdownNumbers(true)
    frame.CooldownText:ClearAllPoints()
    frame.CooldownText:SetPoint(db.fontAnchorPoint, frame, db.fontRelativePoint, db.fontXOff, db.fontYOff)
    frame.CooldownText:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)
    if db.showCooldownText then
        frame.CooldownText:Show()
    else
        frame.CooldownText:Hide()
        frame.CooldownText:SetText('')
    end
    frame.readyPollElapsed = 0
    frame.cooldownTextElapsed = 0

    local texture, isCorrect = self:GetTexture(db)
    frame.Texture:SetTexture(texture)
    frame.invalidTexture = isCorrect

    local zoomReduction = (db.zoom / 100) / 2
    if db.width > db.height then
        local ratio = 1 - (db.height / db.width)
        frame.Texture:SetTexCoord(0 + zoomReduction, 1 - zoomReduction, 0 + zoomReduction + ratio / 2,
            1 - zoomReduction - ratio / 2)
    elseif db.width < db.height then
        local ratio = 1 - (db.width / db.height)
        frame.Texture:SetTexCoord(0 + zoomReduction + ratio / 2, 1 - zoomReduction - ratio / 2, 0 + zoomReduction,
            1 - zoomReduction)
    else
        frame.Texture:SetTexCoord(0 + zoomReduction, 1 - zoomReduction, 0 + zoomReduction, 1 - zoomReduction)
    end

    frame.StackText:ClearAllPoints()
    frame.StackText:SetPoint(
        db.chargeFontAnchorPoint,
        frame.ElementFrame,
        db.chargeFontRelativePoint,
        db.chargeFontXOff,
        db.chargeFontYOff
    )
    frame.StackText:SetFont(
        LSM:Fetch('font', db.chargeFont),
        db.chargeFontSize,
        db.chargeFontFlag
    )

    local source = getCooldownSource(db)
    if db.showStacks and source ~= 'equipment' then
        frame.StackText:Show()
    else
        frame.StackText:Hide()
    end

    frame:OnChange('FORCE')
end
