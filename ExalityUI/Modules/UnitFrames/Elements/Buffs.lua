---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local buffs = EXUI:GetModule('uf-element-buffs')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

buffs.GetFont = function(self, unit)
    local fontName = 'ExalityUI_Buffs_CD_' .. unit
    local font = _G[fontName]
    if (not font) then
        font = CreateFont(fontName)
    end

    return font, fontName
end

buffs.Create = function(self, frame, filters, unit)
    local Buffs = CreateFrame('Frame', nil, frame.ElementFrame)
    Buffs.PostCreateButton = buffs.PostCreateButton
    Buffs.baseUnit = unit

    Buffs.filter = filters
    Buffs.originalFilter = filters
    return Buffs
end

local function GetFilter(filters)
    local filter = ''
    for filterName, value in pairs(filters) do
        if (value) then
            filter = filter .. '|' .. filterName
        end
    end

    return filter
end

buffs.Update = function(self, frame)
    local db = frame.db
    local Buffs = frame.Buffs

    local filters = GetFilter(db.buffsFilters)
    Buffs.filter = filters or Buffs.filter
    Buffs.originalFilter = Buffs.filter

    if (not db.debuffsEnable and not db.buffsEnable and not db.aurasEnable) then
        core:DisableElementForFrame(frame, 'Auras')
        return
    elseif (not frame:IsEventRegistered('UNIT_AURA')) then
        core:EnableElementForFrame(frame, 'Auras')
    end

    if (not db.buffsEnable) then
        Buffs.num = 0
        Buffs.filter = 'NONE'
        if (Buffs.ForceUpdate) then
            Buffs:ForceUpdate()
        end
        Buffs:Hide()
        return
    end
    Buffs:Show()

    Buffs.width = db.buffsIconWidth
    Buffs.height = db.buffsIconHeight
    Buffs.spacing = db.buffsSpacing
    Buffs.num = db.buffsNum

    local growthX = string.find(db.buffsAnchorPoint, 'RIGHT') and 'LEFT' or 'RIGHT'
    local growthY = string.find(db.buffsAnchorPoint, 'TOP') and 'DOWN' or 'UP'
    Buffs.growthX = growthX
    Buffs.growthY = growthY
    if (growthX == 'LEFT' and growthY == 'UP') then
        Buffs.initialAnchor = 'BOTTOMRIGHT'
    elseif (growthX == 'RIGHT' and growthY == 'UP') then
        Buffs.initialAnchor = 'BOTTOMLEFT'
    elseif (growthX == 'LEFT' and growthY == 'DOWN') then
        Buffs.initialAnchor = 'TOPRIGHT'
    elseif (growthX == 'RIGHT' and growthY == 'DOWN') then
        Buffs.initialAnchor = 'TOPLEFT'
    end

    local col = db.buffsColNum or 6
    local width = (db.buffsIconWidth + db.buffsSpacing) * col - db.buffsSpacing
    local height = (db.buffsIconHeight + db.buffsSpacing) * (math.ceil(db.buffsNum / db.buffsColNum))
    Buffs:SetSize(width, height)
    local anchorFrame = frame.ElementFrame
    if (db.buffsAnchorToDebuffs and not db.debuffsAnchorToBuffs and frame.Debuffs and db.debuffsEnable) then
        anchorFrame = frame.Debuffs
    end
    Buffs:ClearAllPoints()
    Buffs:SetPoint(db.buffsAnchorPoint, anchorFrame, db.buffsRelativeAnchorPoint, db.buffsXOff, db.buffsYOff)
    self:UpdateAspectRatio(Buffs, db.buffsIconWidth, db.buffsIconHeight)
    self:UpdateAllTexts(Buffs)
    self:UpdateCountdownFont(Buffs.baseUnit, db)

    if (frame.isFake) then
        Buffs.filter = 'NONE'
    end

    if (frame:IsElementPreviewEnabled('buffs')) then
        self:CreateOrUpdatePreview(frame)
    else
        self:HidePreview(frame)
    end

    if (Buffs.ForceUpdate) then
        Buffs:ForceUpdate()
    end
end

buffs.CreateOrUpdatePreview = function(self, frame)
    local Buffs = frame.Buffs
    local num = math.min(5, Buffs.num)
    if (not frame.BuffsPreviews) then
        frame.BuffsPreviews = EXUI:GetModule('uf-preview-util'):GetFakeAuras(Buffs, num)
    else
        for _, button in ipairs(frame.BuffsPreviews) do
            if (button) then
                EXUI:GetModule('uf-preview-util'):DestroyAura(button)
            end
        end

        frame.BuffsPreviews = EXUI:GetModule('uf-preview-util'):GetFakeAuras(Buffs, num)
    end
    local element = frame.BuffsPreviews
    local width = Buffs.width or Buffs.size or 16
    local height = Buffs.height or Buffs.size or 16
    local sizeX = width + (Buffs.spacingX or Buffs.spacing or 0)
    local sizeY = height + (Buffs.spacingY or Buffs.spacing or 0)
    local anchor = Buffs.initialAnchor or 'BOTTOMLEFT'
    local growthX = (Buffs.growthX == 'LEFT' and -1) or 1
    local growthY = (Buffs.growthY == 'DOWN' and -1) or 1
    local cols = Buffs.maxCols or math.floor(Buffs:GetWidth() / sizeX + 0.5)
    for i = 1, num do
        local button = element[i]
        if (not button) then break end

        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        button:SetSize(width, height)

        self:UpdateDurationText(button, Buffs.baseUnit)
        self:UpdateCountText(button, Buffs.__owner.db)

        button:ClearAllPoints()
        button:SetPoint(anchor, Buffs, anchor, col * sizeX * growthX, row * sizeY * growthY)
        button:Show()
    end
    self:UpdateAspectRatio(element, width, height)
end

buffs.HidePreview = function(self, frame)
    if (not frame.BuffsPreviews) then return end

    for _, button in ipairs(frame.BuffsPreviews) do
        if (button) then
            button:Hide()
        end
    end
end

buffs.PostCreateButton = function(Buffs, button)
    local icon = button.Icon
    local db = Buffs.__owner.db
    icon:SetTexCoord(EXUI.utils.getTexCoords(db.buffsIconWidth, db.buffsIconHeight, 5))
    buffs:UpdateCountText(button, db)
    buffs:UpdateDurationText(button, Buffs.baseUnit)
end

buffs.UpdateAspectRatio = function(self, Buffs, width, height)
    local left, right, top, bottom = EXUI.utils.getTexCoords(width, height, 5)
    for _, button in ipairs(Buffs) do
        local icon = button.Icon
        icon:SetTexCoord(left, right, top, bottom)
    end
end

buffs.UpdateAllTexts = function(self, Buffs)
    if (not Buffs.__owner) then return end
    local db = Buffs.__owner.db
    for _, button in ipairs(Buffs) do
        self:UpdateCountText(button, db)
    end
end

buffs.UpdateCountText = function(self, button, db)
    local count = button.Count
    count:SetFont(LSM:Fetch('font', db.buffsCountFont), db.buffsCountFontSize, db.buffsCountFontFlag)
    count:SetVertexColor(
        db.buffsCountFontColor.r,
        db.buffsCountFontColor.g,
        db.buffsCountFontColor.b,
        db.buffsCountFontColor.a
    )
    count:ClearAllPoints()
    count:SetPoint(
        db.buffsCountAnchorPoint,
        count:GetParent(),
        db.buffsCountRelativeAnchorPoint,
        db.buffsCountXOff,
        db.buffsCountYOff
    )
end

buffs.UpdateCountdownFont = function(self, unit, db)
    local font = self:GetFont(unit)
    font:SetFont(LSM:Fetch('font', db.buffsDurationFont), db.buffsDurationFontSize,
        db.buffsDurationFontFlag)
end

buffs.UpdateDurationText = function(self, button, unit)
    local _, fontName = self:GetFont(unit)
    button.Cooldown:SetCountdownFont(fontName)
end
