---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

---@class EXUICooldownDisplay
local cooldownDisplay = EXUI:GetModule('cooldown-display')
---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

local ZERO_DURATION_OBJECT = C_DurationUtil.CreateDuration()
ZERO_DURATION_OBJECT:SetTimeSpan(0, 0)

local function createDurationObject(start, duration, modRate)
    local durationObject = C_DurationUtil.CreateDuration()
    durationObject:SetTimeFromStart(start or 0, duration or 0, modRate or 1)
    return durationObject
end

local function getCooldownSource(db)
    local source = db.cooldownSource
    if source == 'spell' or source == 'item' or source == 'equipment' then
        return source
    end
    return db.isItem and 'item' or 'spell'
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
    local duration = C_Spell.GetSpellCooldownDuration(unpack({ spellID, ignoreGCD and true or false }))
    if not duration then
        return nil
    end

    return {
        durationObject = duration,
    }
end

function cooldownDisplay:GetSpellCooldownState(spellID)
    ---@diagnostic disable-next-line:undefined-field
    local info = C_Spell.GetSpellCooldown(spellID)
    if not info then
        return false, false
    end

    ---@diagnostic disable-next-line:undefined-field
    return info.isActive and true or false, info.isOnGCD and true or false
end

function cooldownDisplay:GetItemCooldownData(itemID)
    local start, duration = C_Item.GetItemCooldown(itemID)
    local count = C_Item.GetItemCount(itemID, false, true)

    if start == nil or duration == nil then
        local legacyStart, legacyDuration = C_Container.GetItemCooldown(itemID)
        start = legacyStart
        duration = legacyDuration
    end

    return {
        durationObject = createDurationObject(start, duration, 1),
        count = count,
    }
end

function cooldownDisplay:GetEquipmentCooldownData(slotID)
    local start, duration = GetInventoryItemCooldown('player', slotID)
    return {
        durationObject = createDurationObject(start, duration, 1),
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
    local shouldDesaturate = false

    if source == 'spell' then
        sourceID = tonumber(db.spellID)
        if sourceID then
            if db.showStacks then
                local chargeInfo = self:GetSpellChargeData(sourceID)
                if chargeInfo then
                    cooldownInfo = {
                        durationObject = chargeInfo.durationObject,
                    }
                    frame.StackText:SetText(chargeInfo.charges or '')
                else
                    frame.StackText:SetText('')
                end
            else
                cooldownInfo = self:GetSpellCooldownData(sourceID, db.ignoreGlobalCooldown ~= false)
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
        frame.Cooldown:SetCooldownFromDurationObject(ZERO_DURATION_OBJECT, true)
        if frame.CooldownTextBinding then
            frame.CooldownTextBinding:SetDuration(ZERO_DURATION_OBJECT)
        end
        frame.Texture:SetDesaturated(false)
        frame.Texture:SetVertexColor(1, 1, 1, 1)
        if source ~= 'item' or not db.showStacks then
            frame.StackText:SetText('')
        end
        return
    end

    if db.desaturateOnCooldown and source == 'spell' and sourceID then
        local isOnCooldown, isOnGCD = self:GetSpellCooldownState(sourceID)
        if db.ignoreGlobalCooldown ~= false then
            shouldDesaturate = isOnCooldown and not isOnGCD
        else
            shouldDesaturate = isOnCooldown
        end
    end

    frame.Cooldown:SetCooldownFromDurationObject(cooldownInfo.durationObject, true)
    if frame.CooldownTextBinding then
        frame.CooldownTextBinding:SetDuration(cooldownInfo.durationObject)
    end
    frame.currentCooldownInfo = cooldownInfo
    frame.Texture:SetDesaturated(shouldDesaturate)
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
    frame.readyPollElapsed = 0
    frame.CooldownTextBinding = C_DurationUtil.CreateDurationTextBinding()
    frame.CooldownTextBinding:SetFontString(CooldownText)
    frame.CooldownTextBinding:SetExpiredText('')
    frame.CooldownTextBinding:SetZeroDurationText('')
    frame.CooldownTextBinding:SetDuration(ZERO_DURATION_OBJECT)
    frame.CooldownTextBinding:SetEnabled(false)

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

        if not db.showCooldownText and selfRef.CooldownText then
            selfRef.CooldownText:SetText('')
        end
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
    frame.CooldownTextBinding:SetFontString(frame.CooldownText)
    local formatter = durationFormat and durationFormat.GetFormatter and
        durationFormat:GetFormatter(db.cooldownTextFormat or 'mmss')
    if formatter then
        frame.CooldownTextBinding:SetFormatter(formatter)
    end
    frame.CooldownTextBinding:SetUpdateInterval(tonumber(db.cooldownTextUpdateInterval) or 0.05)
    frame.CooldownTextBinding:SetEnabled(db.showCooldownText)
    frame.readyPollElapsed = 0

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
