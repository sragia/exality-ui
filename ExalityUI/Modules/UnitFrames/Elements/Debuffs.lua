---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local debuffs = EXUI:GetModule('uf-element-debuffs')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

debuffs.GetFont = function(self, unit)
    local fontName = 'ExalityUI_Debuffs_CD_' .. unit
    local font = _G[fontName]
    if (not font) then
        font = CreateFont(fontName)
    end

    return font, fontName
end

debuffs.Create = function(self, frame, filters, unit)
    local Debuffs = CreateFrame('Frame', nil, frame.ElementFrame)
    Debuffs.PostCreateButton = debuffs.PostCreateButton
    Debuffs.baseUnit = unit

    Debuffs.filter = filters
    Debuffs.originalFilter = filters

    return Debuffs
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


debuffs.Update = function(self, frame)
    local db = frame.db
    local Debuffs = frame.Debuffs

    local filters = GetFilter(db.debuffsFilters)
    Debuffs.filter = filters or Debuffs.filter
    Debuffs.originalFilter = Debuffs.filter

    if (not db.debuffsEnable and not db.buffsEnable and not db.aurasEnable) then
        core:DisableElementForFrame(frame, 'Auras')
        return
    elseif (not frame:IsEventRegistered('UNIT_AURA')) then
        core:EnableElementForFrame(frame, 'Auras')
    end
    if (not db.debuffsEnable) then
        Debuffs.num = 0
        Debuffs.filter = 'NONE'
        if (Debuffs.ForceUpdate) then
            Debuffs:ForceUpdate()
        end
        Debuffs:Hide()
        return
    end
    Debuffs:Show()

    Debuffs.width = db.debuffsIconWidth
    Debuffs.height = db.debuffsIconHeight
    Debuffs.spacing = db.debuffsSpacing
    if (frame.isFake) then
        Debuffs.filter = 'HELPFUL'
        Debuffs.num = 3
    else
        Debuffs.num = db.debuffsNum
        Debuffs.filter = Debuffs.originalFilter
    end

    local growthX = string.find(db.debuffsAnchorPoint, 'RIGHT') and 'LEFT' or 'RIGHT'
    local growthY = string.find(db.debuffsAnchorPoint, 'TOP') and 'DOWN' or 'UP'

    Debuffs.growthX = growthX
    Debuffs.growthY = growthY
    if (growthX == 'LEFT' and growthY == 'UP') then
        Debuffs.initialAnchor = 'BOTTOMRIGHT'
    elseif (growthX == 'RIGHT' and growthY == 'UP') then
        Debuffs.initialAnchor = 'BOTTOMLEFT'
    elseif (growthX == 'LEFT' and growthY == 'DOWN') then
        Debuffs.initialAnchor = 'TOPRIGHT'
    elseif (growthX == 'RIGHT' and growthY == 'DOWN') then
        Debuffs.initialAnchor = 'TOPLEFT'
    end

    local col = db.debuffsColNum or 6
    local width = (db.debuffsIconWidth + db.debuffsSpacing) * col - db.debuffsSpacing
    local height = (db.debuffsIconHeight + db.debuffsSpacing) * (math.ceil(db.debuffsNum / db.debuffsColNum))
    Debuffs:SetSize(width, height)
    local anchorFrame = frame.ElementFrame
    if (db.debuffsAnchorToBuffs and frame.Buffs and db.buffsEnable) then
        anchorFrame = frame.Buffs
    end
    Debuffs:ClearAllPoints()
    Debuffs:SetPoint(db.debuffsAnchorPoint, anchorFrame, db.debuffsRelativeAnchorPoint, db.debuffsXOff, db.debuffsYOff)
    self:UpdateAspectRatio(Debuffs, db.debuffsIconWidth, db.debuffsIconHeight)
    self:UpdateAllTexts(Debuffs)
    self:UpdateCountdownFont(Debuffs.baseUnit, db)
    if (Debuffs.ForceUpdate) then
        Debuffs:ForceUpdate()
    end
end

debuffs.PostCreateButton = function(Debuffs, button)
    local icon = button.Icon
    local db = Debuffs.__owner.db
    icon:SetTexCoord(EXUI.utils.getTexCoords(db.debuffsIconWidth, db.debuffsIconHeight, 5))
    debuffs:UpdateCountText(button, db)
    debuffs:UpdateDurationText(button, Debuffs.baseUnit)
end

debuffs.UpdateAspectRatio = function(self, Debuffs, width, height)
    local left, right, top, bottom = EXUI.utils.getTexCoords(width, height)
    for _, button in ipairs(Debuffs) do
        local icon = button.Icon
        icon:SetTexCoord(left, right, top, bottom)
    end
end

debuffs.UpdateAllTexts = function(self, Debuffs)
    if (not Debuffs.__owner) then return end
    local db = Debuffs.__owner.db
    for _, button in ipairs(Debuffs) do
        self:UpdateCountText(button, db)
    end
end

debuffs.UpdateCountText = function(self, button, db)
    local count = button.Count
    count:SetFont(LSM:Fetch('font', db.debuffsCountFont), db.debuffsCountFontSize, db.debuffsCountFontFlag)
    count:SetVertexColor(
        db.debuffsCountFontColor.r,
        db.debuffsCountFontColor.g,
        db.debuffsCountFontColor.b,
        db.debuffsCountFontColor.a
    )
    count:ClearAllPoints()
    count:SetPoint(
        db.debuffsCountAnchorPoint,
        count:GetParent(),
        db.debuffsCountRelativeAnchorPoint,
        db.debuffsCountXOff,
        db.debuffsCountYOff
    )
end

debuffs.UpdateCountdownFont = function(self, unit, db)
    local font = self:GetFont(unit)
    font:SetFont(LSM:Fetch('font', db.debuffsDurationFont), db.debuffsDurationFontSize,
        db.debuffsDurationFontFlag)
end

debuffs.UpdateDurationText = function(self, button, unit)
    local _, fontName = self:GetFont(unit)
    button.Cooldown:SetCountdownFont(fontName)
end
