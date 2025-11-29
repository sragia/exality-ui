---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

---@class EXUICooldownDisplay
local cooldownDisplay = EXUI:GetModule('cooldown-display')

cooldownDisplay.Create = function(self, frame)
    local Cooldown = CreateFrame('Cooldown', nil, frame)
    Cooldown:SetSize(1, 1)
    Cooldown:SetPoint('CENTER')
    frame.Cooldown = Cooldown

    local CooldownSwipe = CreateFrame('Cooldown', nil, frame)
    CooldownSwipe:SetPoint('TOPLEFT', -1, 1)
    CooldownSwipe:SetPoint('BOTTOMRIGHT', 1, -1)
    CooldownSwipe:SetHideCountdownNumbers(true)
    CooldownSwipe:SetSwipeColor(0, 0, 0, 0.6)
    CooldownSwipe:SetSwipeTexture(EXUI.const.textures.frame.bg)
    frame.CooldownSwipe = CooldownSwipe

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

    frame.OnChange = function(self, event, ...)
        local db = self.db
        if (not db.enable) then
            return
        end
        if (event == 'ITEM_DATA_LOAD_RESULT') then
            local itemID = ...
            if (itemID == db.itemID) then
                self.Texture:SetTexture(cooldownDisplay:GetTexture(db))
            end
        else
            if (db.isItem and db.itemID ~= '') then
                -- Item
                local start, duration, count = cooldownDisplay:GetItemData(db.itemID)
                if (start) then
                    self.Cooldown:SetCooldown(start, duration)
                    self.CooldownSwipe:SetCooldown(start, duration)
                    self.StackText:SetText(count)
                end
            elseif (not db.isItem and db.spellID ~= '') then
                -- Spell
                if (db.showStacks) then
                    local charges, start, duration, modRate = cooldownDisplay:GetChargeData(db.spellID)
                    if (charges) then
                        self.Cooldown:SetCooldown(start, duration, modRate)
                        self.CooldownSwipe:SetCooldown(start, duration, modRate)
                        self.StackText:SetText(charges)
                    end
                else
                    local start, duration, modRate = cooldownDisplay:GetCooldownData(db.spellID)
                    if (start) then
                        self.Cooldown:SetCooldown(start, duration, modRate)
                        self.CooldownSwipe:SetCooldown(start, duration, modRate)
                    end
                end
            end
        end
    end

    frame.Events = {
        'ITEM_DATA_LOAD_RESULT',
        'SPELL_UPDATE_COOLDOWN'
    }

    frame.RegisterFrameEvents = function(self)
        for _, event in ipairs(self.Events) do
            self:RegisterEvent(event)
        end
    end

    frame:SetScript('OnEvent', frame.OnChange)
end

cooldownDisplay.GetChargeData = function(self, spellID)
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    if (chargeInfo) then
        return chargeInfo.currentCharges, chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration,
            chargeInfo.chargeModRate
    end

    return 0, 0, 0, 1
end

cooldownDisplay.GetCooldownData = function(self, spellID)
    local spellCooldown = C_Spell.GetSpellCooldown(spellID)

    if (spellCooldown) then
        return spellCooldown.startTime, spellCooldown.duration, spellCooldown.modRate
    end
    return 0, 0, 1
end

cooldownDisplay.GetItemData = function(self, itemID)
    local count = C_Item.GetItemCount(itemID, false, true)
    local start, duration = C_Container.GetItemCooldown(itemID)

    return start, duration, count
end

cooldownDisplay.GetTexture = function(self, db)
    if (db.isItem and db.itemID ~= '') then
        -- Item
        local _, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(db.itemID)
        -- We might not be able to get info about this item
        -- TODO: We might get it with a event callback?
        if (itemTexture) then
            return itemTexture
        end
    elseif (db.spellID ~= '') then
        -- Spell
        return C_Spell.GetSpellTexture(db.spellID)
    end

    return 'Interface\\Icons\\INV_Misc_QuestionMark'
end

cooldownDisplay.Update = function(self, frame)
    local db = frame.db
    if (not db.enable) then
        frame:Hide()
        return
    end

    frame:Show()

    if (db.isItem and db.showStacks and not tContains(frame.Events, 'ITEM_COUNT_CHANGED')) then
        table.insert(frame.Events, 'ITEM_COUNT_CHANGED')
    else
        tDeleteItem(frame.Events, 'ITEM_COUNT_CHANGED')
    end
    frame:RegisterFrameEvents()



    frame:SetSize(db.width, db.height)
    frame:ClearAllPoints()
    frame:SetPoint(db.anchorPoint, UIParent, db.relativePoint, db.XOff, db.YOff)
    frame:SetFrameStrata(db.frameStrata)
    frame:SetFrameLevel(db.frameLevel)
    frame:SetBackdropBorderColor(db.borderColor.r, db.borderColor.g, db.borderColor.b, db.borderColor.a)
    frame:SetBackdropColor(0, 0, 0, 0)

    frame.Cooldown:ClearAllPoints()
    frame.Cooldown:SetPoint(db.fontAnchorPoint, frame, db.fontRelativePoint, db.fontXOff, db.fontYOff)
    frame.CooldownFont:SetFont(LSM:Fetch('font', db.font), db.fontSize, db.fontFlag)

    frame.Texture:SetTexture(self:GetTexture(db))

    local zoomReduction = (db.zoom / 100) / 2
    if (db.width > db.height) then
        local ratio = 1 - (db.height / db.width)
        frame.Texture:SetTexCoord(0 + zoomReduction, 1 - zoomReduction, 0 + zoomReduction + ratio / 2,
            1 - zoomReduction - ratio / 2)
    elseif (db.width < db.height) then
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
    if (db.showStacks) then
        frame.StackText:Show()
    else
        frame.StackText:Hide()
    end

    frame:OnChange('FORCE')
end
