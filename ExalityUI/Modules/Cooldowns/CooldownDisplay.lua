---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUICooldownDisplay
local cooldownDisplay = EXUI:GetModule('cooldown-display')
---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

local ZERO_DURATION_OBJECT = C_DurationUtil.CreateDuration()
ZERO_DURATION_OBJECT:SetTimeSpan(0, 0)

local function getCooldownSource(db)
    local source = db.cooldownSource
    if source == 'spell' or source == 'item' or source == 'equipment' then
        return source
    end
    return db.isItem and 'item' or 'spell'
end

local function ensureDurationObject(frame)
    if not frame._durationObject then
        frame._durationObject = C_DurationUtil.CreateDuration()
    end
    return frame._durationObject
end

local function setDurationFromStart(frame, start, duration, modRate)
    local durationObject = ensureDurationObject(frame)
    -- Only replace missing returns; never branch on present values (may be secret).
    if start == nil then
        start = 0
    end
    if duration == nil then
        duration = 0
    end
    if modRate == nil then
        modRate = 1
    end
    durationObject:SetTimeFromStart(start, duration, modRate)
    return durationObject
end

function cooldownDisplay:GetSpellChargeData(spellID)
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    local chargeDuration = C_Spell.GetSpellChargeDuration(spellID)
    if not chargeInfo and not chargeDuration then
        return nil
    end

    return {
        charges = chargeInfo and chargeInfo.currentCharges or nil,
        durationObject = chargeDuration or ZERO_DURATION_OBJECT,
    }
end

function cooldownDisplay:GetSpellCooldownData(spellID, ignoreGCD)
    local duration = C_Spell.GetSpellCooldownDuration(spellID, ignoreGCD and true or false)
    if not duration then
        return nil
    end

    return {
        durationObject = duration,
    }
end

function cooldownDisplay:GetItemCooldownData(frame, itemID, opts)
    local start, duration = C_Item.GetItemCooldown(itemID)

    if start == nil or duration == nil then
        start, duration = C_Container.GetItemCooldown(itemID)
    end

    local count
    if opts and opts.includeCount then
        count = C_Item.GetItemCount(itemID, false, true)
    end

    local result = frame._itemCooldownData
    if not result then
        result = {}
        frame._itemCooldownData = result
    end
    result.durationObject = setDurationFromStart(frame, start, duration, 1)
    result.count = count
    result.start = start
    result.duration = duration
    return result
end

function cooldownDisplay:GetEquipmentCooldownData(frame, slotID)
    local start, duration = GetInventoryItemCooldown('player', slotID)
    local result = frame._equipmentCooldownData
    if not result then
        result = {}
        frame._equipmentCooldownData = result
    end
    result.durationObject = setDurationFromStart(frame, start, duration, 1)
    result.start = start
    result.duration = duration
    return result
end

function cooldownDisplay:GetTexture(db, cachedSourceID)
    local source = getCooldownSource(db)
    if source == 'spell' then
        local spellID = cachedSourceID or tonumber(db.spellID)
        if spellID then
            local texture = C_Spell.GetSpellTexture(spellID)
            if texture then
                return texture, true
            end
        end
    elseif source == 'item' then
        local itemID = cachedSourceID or tonumber(db.itemID)
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
        local slotID = cachedSourceID or tonumber(db.equipmentSlot)
        if slotID then
            local texture = GetInventoryItemTexture('player', slotID)
            if texture then
                return texture, true
            end
        end
    end

    return 'Interface\\Icons\\INV_Misc_QuestionMark', false
end

local function applyCooldownVisual(frame, durationObject, shouldDesaturate, chargesText, timingKey, setCharges)
    if timingKey == nil or frame._lastCooldownTimingKey ~= timingKey then
        frame._lastCooldownTimingKey = timingKey
        frame.Cooldown:SetCooldownFromDurationObject(durationObject, true)
        if frame.CooldownTextBinding then
            frame.CooldownTextBinding:SetDuration(durationObject)
        end
    end
    -- Pass desaturate straight through (may be a secret boolean).
    frame.Texture:SetDesaturated(shouldDesaturate)
    frame.Texture:SetVertexColor(1, 1, 1, 1)
    -- Charge/stack counts are secret under combat restrictions — never compare them.
    if setCharges then
        frame.StackText:SetText(chargesText)
    end
end

local function clearCooldownVisual(frame, clearStacks)
    if frame._lastCooldownTimingKey ~= 'zero' then
        frame._lastCooldownTimingKey = 'zero'
        frame.Cooldown:SetCooldownFromDurationObject(ZERO_DURATION_OBJECT, true)
        if frame.CooldownTextBinding then
            frame.CooldownTextBinding:SetDuration(ZERO_DURATION_OBJECT)
        end
    end
    frame.Texture:SetDesaturated(false)
    frame.Texture:SetVertexColor(1, 1, 1, 1)
    if clearStacks then
        frame.StackText:SetText('')
    end
    frame.currentCooldownInfo = nil
end

local function timingKeyFromStartDuration(start, duration)
    if start == nil or duration == nil then
        return nil
    end
    return tostring(start) .. ':' .. tostring(duration)
end

function cooldownDisplay:CacheSourceIDs(frame, db)
    local source = getCooldownSource(db)
    frame._cooldownSource = source
    if source == 'spell' then
        frame._sourceID = tonumber(db.spellID)
    elseif source == 'item' then
        frame._sourceID = tonumber(db.itemID)
    elseif source == 'equipment' then
        frame._sourceID = tonumber(db.equipmentSlot)
    else
        frame._sourceID = nil
    end
end

function cooldownDisplay:ShouldHandleEvent(frame, event, ...)
    if event == 'FORCE' then
        return true, true
    end

    local source = frame._cooldownSource
    local sourceID = frame._sourceID
    if not source then
        return true, true
    end

    if event == 'ITEM_DATA_LOAD_RESULT' then
        if source ~= 'item' then
            return false, false
        end
        local itemID = ...
        return sourceID and itemID and tonumber(itemID) == sourceID, false
    end

    if event == 'SPELL_UPDATE_COOLDOWN' or event == 'SPELL_UPDATE_CHARGES' then
        if source ~= 'spell' then
            return false, false
        end
        local spellID = ...
        -- Nil spellID means a broad refresh; otherwise only matching icons.
        if spellID == nil then
            return true, false
        end
        return sourceID and tonumber(spellID) == sourceID, false
    end

    if event == 'BAG_UPDATE_COOLDOWN' then
        if source == 'item' then
            return true, true
        end
        return false, false
    end

    if event == 'PLAYER_EQUIPMENT_CHANGED' then
        if source == 'equipment' then
            local slotID = ...
            if slotID == nil or sourceID == nil then
                return true, false
            end
            return tonumber(slotID) == sourceID, false
        end
        if source == 'item' then
            -- Bags/equipment moves can change usable item counts.
            return true, true
        end
        return false, false
    end

    return true, source == 'item'
end

function cooldownDisplay:RenderCooldown(frame, db, opts)
    local source = frame._cooldownSource or getCooldownSource(db)
    local sourceID = frame._sourceID
    if sourceID == nil then
        if source == 'spell' then
            sourceID = tonumber(db.spellID)
        elseif source == 'item' then
            sourceID = tonumber(db.itemID)
        elseif source == 'equipment' then
            sourceID = tonumber(db.equipmentSlot)
        end
        frame._sourceID = sourceID
        frame._cooldownSource = source
    end

    local cooldownInfo = nil
    local shouldDesaturate = false
    local chargesText = nil
    local setCharges = false
    local timingKey = nil
    local includeItemCount = db.showStacks and (not opts or opts.refreshCount ~= false)

    if source == 'spell' then
        if sourceID then
            if db.showStacks then
                local chargeInfo = self:GetSpellChargeData(sourceID)
                setCharges = true
                if chargeInfo then
                    cooldownInfo = chargeInfo
                    -- charges may be secret; pass through to SetText only.
                    chargesText = chargeInfo.charges
                    timingKey = nil
                else
                    chargesText = ''
                end
            else
                cooldownInfo = self:GetSpellCooldownData(sourceID, db.ignoreGlobalCooldown ~= false)
                timingKey = nil
            end
        end
    elseif source == 'item' then
        if sourceID then
            cooldownInfo = self:GetItemCooldownData(frame, sourceID, { includeCount = includeItemCount })
            timingKey = timingKeyFromStartDuration(cooldownInfo.start, cooldownInfo.duration)
            if db.showStacks then
                setCharges = true
                if includeItemCount then
                    chargesText = cooldownInfo.count
                    frame._cachedItemCount = cooldownInfo.count
                else
                    chargesText = frame._cachedItemCount
                end
            end
        end
    elseif source == 'equipment' then
        if sourceID then
            cooldownInfo = self:GetEquipmentCooldownData(frame, sourceID)
            timingKey = timingKeyFromStartDuration(cooldownInfo.start, cooldownInfo.duration)
        end
    end

    if not cooldownInfo then
        clearCooldownVisual(frame, source ~= 'item' or not db.showStacks)
        return
    end

    if db.desaturateOnCooldown and source == 'spell' and sourceID then
        ---@diagnostic disable-next-line:undefined-field
        local info = C_Spell.GetSpellCooldown(sourceID)
        if info then
            -- Pass secret boolean through to SetDesaturated; do not AND/NOT/branch on it.
            ---@diagnostic disable-next-line:undefined-field
            shouldDesaturate = info.isActive
        end
    end

    frame.currentCooldownInfo = cooldownInfo
    applyCooldownVisual(frame, cooldownInfo.durationObject, shouldDesaturate, chargesText, timingKey, setCharges)
end

local function applyContentInsets(frame)
    if frame.PPBorder then
        frame.PPBorder:SetBorderThickness(1)
    end

    -- Bottom PP border is nudged 1px outside the frame; keep bottom flush (inset 0).
    local inset = EXUI:GetBorderInset(frame, 1)
    frame.Texture:ClearAllPoints()
    frame.Texture:SetPoint('TOPLEFT', inset, -inset)
    frame.Texture:SetPoint('BOTTOMRIGHT', -inset, 0)
    frame.Cooldown:ClearAllPoints()
    frame.Cooldown:SetPoint('TOPLEFT', inset, -inset)
    frame.Cooldown:SetPoint('BOTTOMRIGHT', -inset, 0)
end

function cooldownDisplay:Create(frame)
    local Cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
    Cooldown:SetAllPoints()
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
    Texture:SetAllPoints()
    frame.Texture = Texture
    frame.ApplyContentInsets = applyContentInsets

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
    frame._durationObject = C_DurationUtil.CreateDuration()
    frame.CooldownTextBinding = C_DurationUtil.CreateDurationTextBinding()
    frame.CooldownTextBinding:SetFontString(CooldownText)
    frame.CooldownTextBinding:SetExpiredText('')
    frame.CooldownTextBinding:SetZeroDurationText('')
    frame.CooldownTextBinding:SetDuration(ZERO_DURATION_OBJECT)
    frame.CooldownTextBinding:SetEnabled(false)

    frame.RegisterFrameEvents = function(selfRef)
        selfRef:UnregisterAllEvents()
        local source = selfRef._cooldownSource
        if source == 'spell' then
            selfRef:RegisterEvent('SPELL_UPDATE_COOLDOWN')
            selfRef:RegisterEvent('SPELL_UPDATE_CHARGES')
        elseif source == 'item' then
            selfRef:RegisterEvent('ITEM_DATA_LOAD_RESULT')
            selfRef:RegisterEvent('BAG_UPDATE_COOLDOWN')
            selfRef:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
        elseif source == 'equipment' then
            selfRef:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
            selfRef:RegisterEvent('BAG_UPDATE_COOLDOWN')
        else
            selfRef:RegisterEvent('SPELL_UPDATE_COOLDOWN')
            selfRef:RegisterEvent('SPELL_UPDATE_CHARGES')
            selfRef:RegisterEvent('BAG_UPDATE_COOLDOWN')
            selfRef:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
            selfRef:RegisterEvent('ITEM_DATA_LOAD_RESULT')
        end
    end

    frame.OnChange = function(selfRef, event, ...)
        local db = selfRef.db
        if not db or not db.enable then
            return
        end

        local shouldHandle, refreshCount = cooldownDisplay:ShouldHandleEvent(selfRef, event, ...)
        if not shouldHandle then
            return
        end

        if event == 'ITEM_DATA_LOAD_RESULT' then
            local itemID = ...
            local trackedItemID = selfRef._sourceID or tonumber(db.itemID)
            if trackedItemID and itemID and tonumber(itemID) == trackedItemID then
                local texture, isCorrect = cooldownDisplay:GetTexture(db, trackedItemID)
                selfRef.invalidTexture = isCorrect
                selfRef.Texture:SetTexture(texture)
            end
            return
        end

        if not selfRef.invalidTexture then
            local texture, isCorrect = cooldownDisplay:GetTexture(db, selfRef._sourceID)
            selfRef.invalidTexture = isCorrect
            selfRef.Texture:SetTexture(texture)
        end

        cooldownDisplay:RenderCooldown(selfRef, db, { refreshCount = refreshCount })
    end

    frame:SetScript('OnEvent', frame.OnChange)
end

function cooldownDisplay:Update(frame)
    local db = frame.db
    if not db or not db.enable then
        frame:Hide()
        return
    end

    frame:Show()
    self:CacheSourceIDs(frame, db)
    frame:RegisterFrameEvents()

    EXUI:SetSize(frame, db.width, db.height)
    frame:ClearAllPoints()
    frame:SetPoint(db.anchorPoint, UIParent, db.relativePoint, db.XOff, db.YOff)
    EXUI:SnapFrameToPixels(frame)
    frame:SetFrameStrata(db.frameStrata)
    frame:SetFrameLevel(db.frameLevel)
    frame.Cooldown:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.ElementFrame:SetFrameLevel(frame.Cooldown:GetFrameLevel() + 10)
    if frame.PPBorder then
        frame.PPBorder:SetBorderColor(db.borderColor.r, db.borderColor.g, db.borderColor.b, db.borderColor.a)
    end
    frame:SetBackdropColor(0, 0, 0, 0)
    applyContentInsets(frame)

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
    frame.CooldownTextBinding:SetFontString(frame.CooldownText)
    local formatter = durationFormat and durationFormat.GetFormatter and
        durationFormat:GetFormatter(db.cooldownTextFormat or 'mmss')
    if formatter then
        frame.CooldownTextBinding:SetFormatter(formatter)
    end
    frame.CooldownTextBinding:SetUpdateInterval(tonumber(db.cooldownTextUpdateInterval) or 0.05)
    frame.CooldownTextBinding:SetEnabled(db.showCooldownText)

    local texture, isCorrect = self:GetTexture(db, frame._sourceID)
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

    local source = frame._cooldownSource or getCooldownSource(db)
    if db.showStacks and source ~= 'equipment' then
        frame.StackText:Show()
    else
        frame.StackText:Hide()
    end

    frame:OnChange('FORCE')
end
