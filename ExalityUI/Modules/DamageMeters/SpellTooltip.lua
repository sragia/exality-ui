---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIDamageMetersViews
local views = EXUI:GetModule('damage-meters-views')

---@class EXUIDamageMetersData
local meterData = EXUI:GetModule('damage-meters-data')

---@class EXUIDamageMetersBars
local bars = EXUI:GetModule('damage-meters-bars')

---@class EXUIDamageMetersDefaults
local defaults = EXUI:GetModule('damage-meters-defaults')

---@class EXUIDamageMetersSpellTooltip
local tooltip = EXUI:GetModule('damage-meters-spell-tooltip')

local MAX_SPELL_ROWS = 12
local PADDING = 8
local ANCHOR_GAP = 4
local DAMAGE_BAR_COLOR = { 0.8, 0.15, 0.15, 1 }
local HEAL_BAR_COLOR = { 0.15, 0.7, 0.25, 1 }

local ENVIRONMENT_ICONS = {
    DROWNING = [[Interface\Icons\spell_shadow_demonbreath]],
    FALLING = [[Interface\Icons\ability_rogue_quickrecovery]],
    FIRE = [[Interface\Icons\spell_fire_fire]],
    LAVA = [[Interface\Icons\spell_fire_fire]],
    SLIME = [[Interface\Icons\inv_misc_slime_01]],
    FATIGUE = [[Interface\Icons\ability_creature_cursed_05]],
}

local function colorRGBA(color, fallback)
    color = color or fallback
    if not color then
        return 0, 0, 0, 1
    end
    return color.r or 0, color.g or 0, color.b or 0, color.a or 1
end

function tooltip:GetWidth(db)
    return math.max(360, (db and db.width or 240) * 1.5)
end

function tooltip:ApplyChrome(frame, db)
    local backdrop = (db and db.backdropColor) or defaults.WINDOW.backdropColor
    local br, bg, bb, ba = colorRGBA(backdrop)
    frame:SetBackdropColor(br, bg, bb, ba)

    local border = (db and db.borderColor) or defaults.WINDOW.borderColor
    local cr, cg, cb, ca = colorRGBA(border)
    if frame.PPBorder then
        frame.PPBorder:SetBorderColor(cr, cg, cb, ca)
        frame.PPBorder:SetBorderThickness(1)
        if ca <= 0 then
            frame.PPBorder:Hide()
        else
            frame.PPBorder:Show()
        end
    end
end

function tooltip:AnchorToBar(frame, anchor)
    frame:ClearAllPoints()
    frame:SetPoint('BOTTOMRIGHT', anchor, 'TOPLEFT', -ANCHOR_GAP, ANCHOR_GAP)
end

function tooltip:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame('Frame', 'ExalityUIDamageMeterSpellTooltip', UIParent, 'BackdropTemplate')
    frame:SetFrameStrata('TOOLTIP')
    frame:SetClampedToScreen(true)
    frame:EnableMouse(false)
    frame:Hide()
    local backdrop = defaults.WINDOW.backdropColor
    local border = defaults.WINDOW.borderColor
    EXUI:ApplySolidBorder(frame, 1, { border.r, border.g, border.b, border.a }, { backdrop.r, backdrop.g, backdrop.b, backdrop.a }, { register = false })

    frame.titleIcon = frame:CreateTexture(nil, 'ARTWORK')
    frame.titleIcon:SetPoint('TOPLEFT', PADDING, -PADDING)

    frame.title = frame:CreateFontString(nil, 'OVERLAY')
    frame.title:SetJustifyH('LEFT')
    frame.title:SetWordWrap(false)
    frame.title:SetWidth(0)

    frame.titleHint = frame:CreateFontString(nil, 'OVERLAY')
    frame.titleHint:SetJustifyH('LEFT')
    frame.titleHint:SetWordWrap(false)
    frame.titleHint:SetWidth(0)

    frame.rows = {}
    for i = 1, MAX_SPELL_ROWS do
        local row = bars:CreateRow(frame)
        row:EnableMouse(false)
        frame.rows[i] = row
    end

    self.frame = frame
    return frame
end

function tooltip:GetSpellName(spell)
    local spellID = spell.spellID
    if spellID and not meterData:IsSecret(spellID) and C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end
    return nil
end

function tooltip:GetSpellTexture(spell)
    local details = spell.combatSpellDetails
    if details and details.specIconID and details.specIconID ~= 0 then
        return details.specIconID, false
    end

    local spellID = spell.spellID
    if spellID and not meterData:IsSecret(spellID) and C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID), false
    end

    local classFilename = details and details.unitClassFilename
    if classFilename and classFilename ~= '' and GetClassAtlas then
        return GetClassAtlas(classFilename), true
    end

    return nil, false
end

function tooltip:GetSpellLabel(spell, meterType)
    local spellName = self:GetSpellName(spell)
    local details = spell.combatSpellDetails
    local creatureName = spell.creatureName
    local unitName = details and details.unitName

    if creatureName and not meterData:IsSecret(creatureName) and creatureName ~= '' and spellName then
        return string.format('%s (%s)', spellName, creatureName)
    end

    if unitName and not meterData:IsSecret(unitName) and unitName ~= '' then
        unitName = meterData:FormatPlayerName(unitName)
        if spellName then
            return string.format('%s (%s)', spellName, unitName)
        end
        return unitName
    end

    return spellName or ''
end

function tooltip:IsHealEvent(event)
    local eventName = event and event.event
    if eventName == nil or meterData:IsSecret(eventName) or type(eventName) ~= 'string' then
        return false
    end
    return eventName:find('HEAL', 1, true) ~= nil
end

function tooltip:GetDeathEventInfo(event)
    local spellName = event.spellName
    local spellID = event.spellID or event.spellId
    local texture
    local eventName = event.event
    if eventName and not meterData:IsSecret(eventName) and type(eventName) == 'string' then
        if eventName == 'SWING_DAMAGE' then
            spellID = spellID or 88163
            spellName = spellName or _G.ACTION_SWING or 'Melee'
        elseif eventName == 'ENVIRONMENTAL_DAMAGE' then
            local environmentalType = event.environmentalType
            if environmentalType and not meterData:IsSecret(environmentalType) then
                environmentalType = string.upper(environmentalType)
                spellName = spellName or _G['ACTION_ENVIRONMENTAL_DAMAGE_' .. environmentalType] or environmentalType
                texture = ENVIRONMENT_ICONS[environmentalType] or [[Interface\Icons\ability_creature_cursed_05]]
            end
        end
    end

    if spellID and not meterData:IsSecret(spellID) and not texture and C_Spell and C_Spell.GetSpellTexture then
        texture = C_Spell.GetSpellTexture(spellID)
    end
    if (not spellName or spellName == '') and spellID and not meterData:IsSecret(spellID) and C_Spell and C_Spell.GetSpellName then
        spellName = C_Spell.GetSpellName(spellID)
    end

    local sourceName = event.sourceName
    if sourceName and not meterData:IsSecret(sourceName) and sourceName ~= '' then
        sourceName = meterData:FormatPlayerName(sourceName)
        if spellName and not meterData:IsSecret(spellName) then
            spellName = string.format('%s (%s)', spellName, sourceName)
        elseif not spellName or spellName == '' then
            spellName = sourceName
        end
    elseif (not spellName or spellName == '') and sourceName then
        spellName = meterData:FormatPlayerName(sourceName)
    end

    return spellName or '', texture
end

function tooltip:GetDeathTimestamp(events)
    local latest
    for _, event in ipairs(events) do
        local timestamp = event.timestamp
        if timestamp ~= nil then
            if meterData:IsSecret(timestamp) then
                return nil
            end
            if latest == nil or timestamp > latest then
                latest = timestamp
            end
        end
    end
    return latest
end

function tooltip:Hide()
    if self.frame then
        self.frame:Hide()
    end
    self.owner = nil
end

function tooltip:LayoutHeader(frame, source, extraText)
    local fontPath, fontSize, fontFlag = bars:GetFont(self.db)
    frame.title:SetFont(fontPath, fontSize, fontFlag)
    frame.title:SetWidth(0)
    frame.titleHint:SetFont(fontPath, fontSize, fontFlag)
    frame.titleHint:SetTextColor(unpack(EXUI.const.theme.text))
    frame.titleHint:SetWidth(0)

    local iconSize = math.max(14, fontSize + 1)
    local specIconID = source and source.specIconID
    local classFilename = source and source.classFilename
    local showIcon = specIconID and specIconID ~= 0
    local classAtlas
    if not showIcon and classFilename and classFilename ~= '' and GetClassAtlas then
        classAtlas = GetClassAtlas(classFilename)
        showIcon = classAtlas ~= nil
    end

    frame.titleIcon:ClearAllPoints()
    frame.title:ClearAllPoints()
    frame.titleHint:ClearAllPoints()

    if showIcon then
        EXUI:SetSize(frame.titleIcon, iconSize, iconSize)
        frame.titleIcon:SetPoint('TOPLEFT', frame, 'TOPLEFT', PADDING, -PADDING)
        if specIconID and specIconID ~= 0 then
            frame.titleIcon:SetTexture(specIconID)
        else
            frame.titleIcon:SetAtlas(classAtlas)
        end
        bars:ApplyIconCrop(frame.titleIcon, iconSize, iconSize, 8)
        frame.titleIcon:Show()
        frame.title:SetPoint('LEFT', frame.titleIcon, 'RIGHT', 4, 0)
        frame.title:SetPoint('TOP', frame.titleIcon, 'TOP', 0, 0)
        frame.title:SetPoint('BOTTOM', frame.titleIcon, 'BOTTOM', 0, 0)
    else
        frame.titleIcon:Hide()
        frame.title:SetPoint('TOPLEFT', frame, 'TOPLEFT', PADDING, -PADDING)
    end

    if source and source.name ~= nil then
        frame.title:SetText(meterData:FormatPlayerName(source.name))
    else
        frame.title:SetText('')
    end

    local r, g, b, a = bars:GetClassColor(source)
    if r then
        frame.title:SetTextColor(r, g, b, a)
    else
        frame.title:SetTextColor(unpack(EXUI.const.theme.text))
    end

    if extraText and extraText ~= '' then
        frame.titleHint:SetText(extraText)
        frame.titleHint:SetPoint('LEFT', frame.title, 'RIGHT', 4, 0)
        if showIcon then
            frame.titleHint:SetPoint('TOP', frame.titleIcon, 'TOP', 0, 0)
            frame.titleHint:SetPoint('BOTTOM', frame.titleIcon, 'BOTTOM', 0, 0)
        else
            frame.titleHint:SetPoint('TOP', frame.title, 'TOP', 0, 0)
            frame.titleHint:SetPoint('BOTTOM', frame.title, 'BOTTOM', 0, 0)
        end
        frame.titleHint:Show()
    else
        frame.titleHint:SetText('')
        frame.titleHint:Hide()
    end

    return math.max(showIcon and iconSize or 0, fontSize) + 6
end

function tooltip:GetTooltipDB(db, width)
    local tooltipDB = EXUI.utils.deepCloneTable(db)
    tooltipDB.barHeight = math.max(16, (db.barHeight or 18))
    tooltipDB.showRank = true
    tooltipDB.showIcon = true
    tooltipDB.classColorName = false
    tooltipDB.icon = tooltipDB.icon or {}
    tooltipDB.icon.show = true
    tooltipDB.width = width
    tooltipDB.texts = tooltipDB.texts or {}
    tooltipDB.texts.name = tooltipDB.texts.name or {}
    tooltipDB.texts.name.show = true
    tooltipDB.texts.name.width = 0
    tooltipDB.texts.value = tooltipDB.texts.value or {}
    tooltipDB.texts.value.show = true
    tooltipDB.texts.secondary = tooltipDB.texts.secondary or {}
    tooltipDB.texts.secondary.show = true
    tooltipDB.texts.percent = tooltipDB.texts.percent or {}
    tooltipDB.texts.percent.show = false
    return tooltipDB
end

function tooltip:PlaceRow(frame, row, titleHeight, barHeight, spacing, index)
    row:ClearAllPoints()
    row:SetPoint('LEFT', frame, 'LEFT', PADDING, 0)
    row:SetPoint('RIGHT', frame, 'RIGHT', -PADDING, 0)
    row:SetPoint('TOP', frame, 'TOP', 0, -(PADDING + titleHeight + (index - 1) * (barHeight + spacing)))
    EXUI:SetHeight(row, barHeight)
end

function tooltip:ShowDeathHint(anchor, source)
    local events, maxHealth = meterData:GetDeathRecap(source and source.deathRecapID)
    if not events then
        local frame = self:EnsureFrame()
        self:ApplyChrome(frame, self.db)
        for _, row in ipairs(frame.rows) do
            row:Hide()
        end

        local titleHeight = self:LayoutHeader(frame, source, '— Click for death recap')
        EXUI:SetSize(frame, self:GetWidth(self.db), titleHeight + PADDING * 2)
        self:AnchorToBar(frame, anchor)
        frame:Show()
        self.owner = anchor
        return
    end

    local frame = self:EnsureFrame()
    self:ApplyChrome(frame, self.db)
    local titleHeight = self:LayoutHeader(frame, source, '— Click for death recap')
    local barHeight = math.max(16, (self.db.barHeight or 18))
    local spacing = 2
    local width = self:GetWidth(self.db)
    local tooltipDB = self:GetTooltipDB(self.db, width)
    tooltipDB.showRank = false

    local deathTimestamp = self:GetDeathTimestamp(events)
    local decimals = self.db.valueDecimals
    if decimals == nil then
        decimals = 1
    end

    local shown = 0
    local last = math.min(#events, MAX_SPELL_ROWS)
    for i = last, 1, -1 do
        local event = events[i]
        shown = shown + 1
        local row = frame.rows[shown]
        local name, texture = self:GetDeathEventInfo(event)
        local isHeal = self:IsHealEvent(event)
        local amount = event.amount
        local currentHP = event.currentHP
        local rowMaxHealth = maxHealth
        if rowMaxHealth == nil or (not meterData:IsSecret(rowMaxHealth) and rowMaxHealth == 0) then
            rowMaxHealth = event.maxHealth
        end

        local rowData = {
            name = name,
            classFilename = source.classFilename,
            specIconID = 0,
            totalAmount = amount,
            barColor = isHeal and HEAL_BAR_COLOR or DAMAGE_BAR_COLOR,
            barMax = rowMaxHealth,
            barValue = currentHP,
        }

        bars:UpdateRow(row, rowData, tooltipDB, views.Type.DamageTaken, shown)
        if texture then
            row.icon:SetTexture(texture)
            local icon = tooltipDB.icon
            bars:ApplyIconCrop(row.icon, icon and icon.width, icon and icon.height, icon and icon.zoom)
            row.icon:Show()
        end

        if amount ~= nil then
            row.value:SetText(meterData:FormatAmount(amount, decimals))
            row.value:Show()
        else
            row.value:SetText('')
            row.value:Hide()
        end

        local timeText
        if deathTimestamp ~= nil and event.timestamp ~= nil and not meterData:IsSecret(event.timestamp) then
            timeText = meterData:FormatRecapTime(deathTimestamp - event.timestamp)
        end
        if timeText and timeText ~= '' then
            row.secondary:SetText(timeText)
            row.secondary:Show()
        else
            row.secondary:SetText('')
            row.secondary:Hide()
        end

        row.percent:SetText('')
        row.percent:Hide()

        self:PlaceRow(frame, row, titleHeight, barHeight, spacing, shown)
    end

    for i = shown + 1, MAX_SPELL_ROWS do
        frame.rows[i]:Hide()
    end

    local height = PADDING * 2 + titleHeight + shown * barHeight + math.max(0, shown - 1) * spacing
    EXUI:SetSize(frame, width + PADDING * 2, height)
    self:AnchorToBar(frame, anchor)
    frame:Show()
    self.owner = anchor
end

function tooltip:GetSessionLookup(windowDB)
    local db = windowDB and windowDB.db or windowDB
    local sessionType = windowDB and windowDB.lookupSessionType
    local sessionID = windowDB and windowDB.lookupSessionID
    if sessionID == nil and sessionType == nil and db then
        sessionType = db.sessionType
        sessionID = db.sessionID
    end
    local meterType = db and db.damageMeterType or (windowDB and windowDB.damageMeterType)
    return sessionType, sessionID, meterType
end

function tooltip:ShowForSource(anchor, db, windowDB, source)
    self.db = db
    if not source then
        self:Hide()
        return
    end

    local sessionType, sessionID, meterType = self:GetSessionLookup(windowDB)
    if views:IsDeaths(meterType) then
        self:ShowDeathHint(anchor, source)
        return
    end

    local sessionSource = meterData:GetSessionSource(
        sessionType,
        sessionID,
        meterType,
        source.sourceGUID,
        source.sourceCreatureID
    )
    local spells = sessionSource and sessionSource.combatSpells or {}
    if #spells == 0 then
        self:Hide()
        return
    end

    local frame = self:EnsureFrame()
    self:ApplyChrome(frame, db)
    local titleHeight = self:LayoutHeader(frame, source)
    local width = self:GetWidth(db)
    local tooltipDB = self:GetTooltipDB(db, width)
    local barHeight = tooltipDB.barHeight
    local spacing = 2
    local shown = 0

    local maxAmount = sessionSource.maxAmount or 0
    local totalAmount = sessionSource.totalAmount or 0

    for i, spell in ipairs(spells) do
        if shown >= MAX_SPELL_ROWS then
            break
        end
        shown = shown + 1
        local row = frame.rows[shown]
        spell.maxAmount = maxAmount
        spell.sessionTotalAmount = totalAmount
        spell.classFilename = source.classFilename
        spell.name = self:GetSpellLabel(spell, meterType)

        local texture, isAtlas = self:GetSpellTexture(spell)
        bars:UpdateRow(row, spell, tooltipDB, meterType, i)
        if texture then
            if isAtlas then
                row.icon:SetAtlas(texture)
            else
                row.icon:SetTexture(texture)
            end
            local icon = tooltipDB.icon
            bars:ApplyIconCrop(row.icon, icon and icon.width, icon and icon.height, icon and icon.zoom)
            row.icon:Show()
        end

        self:PlaceRow(frame, row, titleHeight, barHeight, spacing, shown)
    end

    for i = shown + 1, MAX_SPELL_ROWS do
        frame.rows[i]:Hide()
    end

    local height = PADDING * 2 + titleHeight + shown * barHeight + math.max(0, shown - 1) * spacing
    EXUI:SetSize(frame, width + PADDING * 2, height)
    self:AnchorToBar(frame, anchor)
    frame:Show()
    self.owner = anchor
end
