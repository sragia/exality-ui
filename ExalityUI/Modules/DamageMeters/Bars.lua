---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIDamageMetersViews
local views = EXUI:GetModule('damage-meters-views')

---@class EXUIDamageMetersData
local meterData = EXUI:GetModule('damage-meters-data')

---@class EXUIDamageMetersDefaults
local defaults = EXUI:GetModule('damage-meters-defaults')

local LSM = LibStub('LibSharedMedia-3.0', true)

---@class EXUIDamageMetersBars
local bars = EXUI:GetModule('damage-meters-bars')

local CREATURE_COLOR = { 0.55, 0.55, 0.55, 1 }

function bars:GetBarTexture(db)
    local textureName = (db and db.barTexture) or defaults.BAR_TEXTURE
    if LSM and LSM:Fetch('statusbar', textureName) then
        return LSM:Fetch('statusbar', textureName)
    end
    return EXUI.const.textures.frame.statusBar
end

function bars:GetFont(db)
    local fontName = (db and db.font) or 'DMSans'
    local fontPath = (LSM and LSM:Fetch('font', fontName)) or EXUI.EXFrames.assets.font.default()
    return fontPath, (db and db.fontSize) or 11, (db and db.fontFlag) or 'OUTLINE'
end

function bars:GetTextSettings(db, textKey)
    local texts = db and db.texts
    local settings = texts and texts[textKey]
    local fallback = defaults.WINDOW.texts[textKey]
    if type(settings) ~= 'table' then
        return fallback
    end
    return settings
end

function bars:GetTextFont(db, textKey)
    local settings = self:GetTextSettings(db, textKey)
    if settings and settings.useDefaultFont == false then
        local fontName = settings.font or (db and db.font) or 'DMSans'
        local fontPath = (LSM and LSM:Fetch('font', fontName)) or EXUI.EXFrames.assets.font.default()
        return fontPath, settings.fontSize or 11, settings.fontFlag or 'OUTLINE'
    end
    return self:GetFont(db)
end

function bars:GetJustifyH(point)
    point = point or 'LEFT'
    if point:find('RIGHT', 1, true) then
        return 'RIGHT'
    end
    if point:find('LEFT', 1, true) then
        return 'LEFT'
    end
    return 'CENTER'
end

function bars:IsTextShown(db, textKey)
    local settings = self:GetTextSettings(db, textKey)
    return not settings or settings.show ~= false
end

function bars:ApplyTextLayout(fontString, row, db, textKey)
    local settings = self:GetTextSettings(db, textKey) or defaults.WINDOW.texts[textKey]
    local fontPath, fontSize, fontFlag = self:GetTextFont(db, textKey)
    fontString:SetFont(fontPath, fontSize, fontFlag)
    fontString:SetJustifyH(self:GetJustifyH(settings.relativePoint or settings.anchorPoint))
    fontString:SetWordWrap(false)

    local width = settings.width
    if type(width) == 'number' and width > 0 then
        EXUI:SetWidth(fontString, width)
    else
        fontString:SetWidth(0)
    end

    fontString:ClearAllPoints()
    EXUI:SetPoint(
        fontString,
        settings.anchorPoint or 'LEFT',
        row,
        settings.relativePoint or 'LEFT',
        settings.XOff or 0,
        settings.YOff or 0
    )
end

function bars:ApplyIconCrop(icon, width, height, zoomPercent)
    width = width or 16
    height = height or 16
    local zoom = math.max(0, math.min(45, tonumber(zoomPercent) or 8)) / 100

    local left, right, top, bottom = 0, 1, 0, 1
    if width > 0 and height > 0 and width ~= height then
        if width > height then
            local visibleH = height / width
            local pad = (1 - visibleH) / 2
            top = pad
            bottom = 1 - pad
        else
            local visibleW = width / height
            local pad = (1 - visibleW) / 2
            left = pad
            right = 1 - pad
        end
    end

    local spanX = right - left
    local spanY = bottom - top
    icon:SetTexCoord(
        left + spanX * zoom,
        right - spanX * zoom,
        top + spanY * zoom,
        bottom - spanY * zoom
    )
end

function bars:GetClassColor(source)
    local classFilename = source and source.classFilename
    if classFilename and classFilename ~= '' and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename] then
        local color = RAID_CLASS_COLORS[classFilename]
        return color.r, color.g, color.b, 1
    end
end

function bars:GetBarColor(source, db)
    local override = source and source.barColor
    if override then
        return override[1], override[2], override[3], override[4] or 1
    end

    if db.useClassColor then
        local r, g, b, a = self:GetClassColor(source)
        if r then
            return r, g, b, a
        end
        return unpack(CREATURE_COLOR)
    end

    local color = db.customBarColor or defaults.WINDOW.customBarColor
    return color.r or 0.8, color.g or 0.15, color.b or 0.15, color.a or 1
end

function bars:GetTextColor(db, textKey)
    local settings = self:GetTextSettings(db, textKey)
    local color = settings and settings.color
    if color then
        return color.r or 1, color.g or 1, color.b or 1, color.a or 1
    end
    local text = EXUI.const.theme.text
    return text[1], text[2], text[3], 1
end

function bars:GetNameColor(source, db)
    if db.classColorName ~= false then
        local r, g, b, a = self:GetClassColor(source)
        if r then
            return r, g, b, a
        end
    end

    return self:GetTextColor(db, 'name')
end

function bars:CreateRow(parent)
    local row = CreateFrame('Button', nil, parent)
    row:RegisterForClicks('LeftButtonDown', 'RightButtonDown')
    row:EnableMouse(true)

    row.bg = row:CreateTexture(nil, 'BACKGROUND')
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0.35)

    row.bar = CreateFrame('StatusBar', nil, row)
    row.bar:SetMinMaxValues(0, 1)
    row.bar:SetValue(0)
    row.bar:SetPoint('TOPLEFT', 0, 0)
    row.bar:SetPoint('BOTTOMRIGHT', 0, 0)
    row.bar:SetStatusBarTexture(self:GetBarTexture())
    row.bar:SetFrameLevel(row:GetFrameLevel())

    local overlay = CreateFrame('Frame', nil, row)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(row.bar:GetFrameLevel() + 1)
    row.overlay = overlay

    row.icon = overlay:CreateTexture(nil, 'ARTWORK')
    row.icon:SetPoint('LEFT', 1, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.rank = overlay:CreateFontString(nil, 'OVERLAY')
    row.rank:SetJustifyH('LEFT')
    row.rank:SetWordWrap(false)

    row.name = overlay:CreateFontString(nil, 'OVERLAY')
    row.name:SetJustifyH('LEFT')
    row.name:SetWordWrap(false)

    row.percent = overlay:CreateFontString(nil, 'OVERLAY')
    row.percent:SetJustifyH('RIGHT')
    row.percent:SetWordWrap(false)

    row.secondary = overlay:CreateFontString(nil, 'OVERLAY')
    row.secondary:SetJustifyH('RIGHT')
    row.secondary:SetWordWrap(false)

    row.value = overlay:CreateFontString(nil, 'OVERLAY')
    row.value:SetJustifyH('RIGHT')
    row.value:SetWordWrap(false)

    return row
end

local CLASSIFICATION_ATLAS = {
    elite = 'nameplates-icon-elite-gold',
    worldboss = 'nameplates-icon-elite-gold',
    rare = 'UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star',
    rareelite = 'nameplates-icon-elite-silver',
}

function bars:IsIconShown(db, meterType)
    local icon = db and db.icon
    if icon and icon.show == false then
        return false
    end
    if db and db.showIcon == false then
        return false
    end
    return true
end

function bars:ApplyStyle(row, db)
    local barHeight = db.barHeight or 18
    local icon = db.icon or defaults.WINDOW.icon
    local iconWidth = icon.width or 16
    local iconHeight = icon.height or 16

    EXUI:SetHeight(row, barHeight)
    row.bar:SetStatusBarTexture(self:GetBarTexture(db))
    if row.overlay then
        row.overlay:SetFrameLevel(row.bar:GetFrameLevel() + 1)
    end

    EXUI:SetSize(row.icon, iconWidth, iconHeight)
    row.icon:ClearAllPoints()
    EXUI:SetPoint(
        row.icon,
        icon.anchorPoint or 'LEFT',
        row,
        icon.relativePoint or 'LEFT',
        icon.XOff or 1,
        icon.YOff or 0
    )
    self:ApplyIconCrop(row.icon, iconWidth, iconHeight, icon.zoom)

    self:ApplyTextLayout(row.name, row, db, 'name')
    self:ApplyTextLayout(row.value, row, db, 'value')
    self:ApplyTextLayout(row.secondary, row, db, 'secondary')
    self:ApplyTextLayout(row.percent, row, db, 'percent')
    row.name:SetShown(self:IsTextShown(db, 'name'))
    row.value:SetShown(self:IsTextShown(db, 'value'))
    row.secondary:SetShown(self:IsTextShown(db, 'secondary'))
    row.percent:SetShown(self:IsTextShown(db, 'percent'))

    local showRank = db.showRank ~= false and self:IsTextShown(db, 'name')
    local nameFontPath, nameFontSize, nameFontFlag = self:GetTextFont(db, 'name')
    row.rank:SetFont(nameFontPath, nameFontSize, nameFontFlag)
    row.rank:SetJustifyH('LEFT')
    row.rank:SetWordWrap(false)
    row.rank:SetWidth(0)
    row.rank:ClearAllPoints()
    if showRank then
        local settings = self:GetTextSettings(db, 'name') or defaults.WINDOW.texts.name
        EXUI:SetPoint(
            row.rank,
            settings.anchorPoint or 'LEFT',
            row,
            settings.relativePoint or 'LEFT',
            settings.XOff or 0,
            settings.YOff or 0
        )
        row.name:ClearAllPoints()
        EXUI:SetPoint(row.name, 'LEFT', row.rank, 'RIGHT', 1, 0)
        row.rank:Show()
    else
        row.rank:Hide()
    end

    local nameR, nameG, nameB, nameA = self:GetTextColor(db, 'name')
    row.rank:SetTextColor(nameR, nameG, nameB, (nameA or 1) * 0.7)
    row.name:SetTextColor(nameR, nameG, nameB, nameA)
    row.value:SetTextColor(self:GetTextColor(db, 'value'))
    row.secondary:SetTextColor(self:GetTextColor(db, 'secondary'))
    row.percent:SetTextColor(self:GetTextColor(db, 'percent'))
end

function bars:UpdateIcon(row, source, db, meterType)
    if not self:IsIconShown(db, meterType) then
        row.icon:Hide()
        return
    end

    local icon = db.icon or defaults.WINDOW.icon
    local specIconID = source.specIconID
    if specIconID and specIconID ~= 0 then
        row.icon:SetTexture(specIconID)
        self:ApplyIconCrop(row.icon, icon.width, icon.height, icon.zoom)
        row.icon:Show()
        return
    end

    local classFilename = source.classFilename
    if classFilename and classFilename ~= '' and GetClassAtlas then
        local atlas = GetClassAtlas(classFilename)
        if atlas then
            row.icon:SetAtlas(atlas)
            self:ApplyIconCrop(row.icon, icon.width, icon.height, icon.zoom)
            row.icon:Show()
            return
        end
    end

    local classification = source.classification
    local classificationAtlas = classification and CLASSIFICATION_ATLAS[classification]
    if classificationAtlas then
        row.icon:SetAtlas(classificationAtlas)
        self:ApplyIconCrop(row.icon, icon.width, icon.height, icon.zoom)
        row.icon:Show()
        return
    end

    local fallback = EXUI.const.textures.raidTools and EXUI.const.textures.raidTools.skull
    if fallback then
        row.icon:SetTexture(fallback)
        self:ApplyIconCrop(row.icon, icon.width, icon.height, icon.zoom)
        row.icon:Show()
        return
    end

    row.icon:Hide()
end

function bars:UpdateValues(row, source, db, meterType)
    local isDeath = views:IsDeaths(meterType) and source.deathRecapID and source.deathRecapID ~= 0
    if isDeath or views:IsDeaths(meterType) then
        if self:IsTextShown(db, 'value') then
            row.value:SetText(meterData:FormatDeathTime(source.deathTimeSeconds))
            row.value:Show()
        else
            row.value:SetText('')
            row.value:Hide()
        end
        row.secondary:SetText('')
        row.percent:SetText('')
        row.secondary:Hide()
        row.percent:Hide()
        return
    end

    local primaryPerSecond = views:ShowsValuePerSecondAsPrimary(meterType)
    local suppressPerSecond = views:SuppressValuePerSecond(meterType)
    local primary = primaryPerSecond and source.amountPerSecond or source.totalAmount
    local secondary = primaryPerSecond and source.totalAmount or source.amountPerSecond
    if suppressPerSecond then
        secondary = nil
    end

    local decimals = 0
    if not views:UsesWholeNumbers(meterType) then
        decimals = db.valueDecimals
        if decimals == nil then
            decimals = 1
        end
    end

    if self:IsTextShown(db, 'value') then
        row.value:SetText(meterData:FormatAmount(primary, decimals))
        row.value:Show()
    else
        row.value:SetText('')
        row.value:Hide()
    end

    if self:IsTextShown(db, 'secondary') and secondary ~= nil then
        row.secondary:SetText(meterData:FormatAmount(secondary, decimals))
        row.secondary:Show()
    else
        row.secondary:SetText('')
        row.secondary:Hide()
    end

    if self:IsTextShown(db, 'percent') then
        local percent = meterData:FormatPercent(source.totalAmount, source.sessionTotalAmount)
        if percent then
            row.percent:SetText(percent)
            row.percent:Show()
        else
            row.percent:SetText('')
            row.percent:Hide()
        end
    else
        row.percent:SetText('')
        row.percent:Hide()
    end
end

function bars:UpdateRow(row, source, db, meterType, index)
    self:ApplyStyle(row, db)

    if db.showRank and self:IsTextShown(db, 'name') then
        row.rank:SetText(index .. '.')
        row.rank:Show()
    else
        row.rank:Hide()
    end

    row.name:SetText(meterData:FormatPlayerName(source.name))
    row.name:SetTextColor(self:GetNameColor(source, db))

    local r, g, b, a = self:GetBarColor(source, db)
    row.bar:GetStatusBarTexture():SetVertexColor(r, g, b, a)

    local isDeath = views:IsDeaths(meterType)
    if source.barMax ~= nil then
        row.bar:SetMinMaxValues(0, source.barMax)
        row.bar:SetValue(source.barValue or 0)
    elseif isDeath then
        row.bar:SetMinMaxValues(0, 1)
        row.bar:SetValue(1)
    else
        row.bar:SetMinMaxValues(0, source.maxAmount or 0)
        row.bar:SetValue(source.totalAmount or 0)
    end

    self:UpdateIcon(row, source, db, meterType)
    self:UpdateValues(row, source, db, meterType)

    row.source = source
    row:Show()
end
