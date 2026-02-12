---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local auras = EXUI:GetModule('uf-element-auras')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

auras.GetFont = function(self, unit)
    local fontName = 'ExalityUI_Auras_CD_' .. unit
    local font = _G[fontName]
    if (not font) then
        font = CreateFont(fontName)
    end

    return font, fontName
end

auras.Create = function(self, frame, unit)
    local Auras = CreateFrame('Frame', nil, frame.ElementFrame)
    Auras.PostCreateButton = auras.PostCreateButton
    Auras.baseUnit = unit

    return Auras
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

auras.Update = function(self, frame)
    local db = frame.db
    local Auras = frame.Auras

    local filters = GetFilter(db.aurasFilters)
    Auras.filter = filters or Auras.filter
    Auras.originalFilter = Auras.filter

    if (not db.debuffsEnable and not db.buffsEnable and not db.aurasEnable) then
        core:DisableElementForFrame(frame, 'Auras')
        return
    elseif (not frame:IsEventRegistered('UNIT_AURA')) then
        core:EnableElementForFrame(frame, 'Auras')
    end
    if (not db.aurasEnable) then
        Auras.num = 0
        Auras.filter = 'NONE'
        if (Auras.ForceUpdate) then
            Auras:ForceUpdate()
        end
        Auras:Hide()
        return
    end
    Auras:Show()

    Auras.width = db.aurasIconWidth
    Auras.height = db.aurasIconHeight
    Auras.spacing = db.aurasSpacing
    if (frame.isFake) then
        Auras.filter = 'HELPFUL'
        Auras.num = 3
    else
        Auras.num = db.aurasNum
        Auras.filter = Auras.originalFilter
    end

    local growthX = string.find(db.aurasAnchorPoint, 'RIGHT') and 'LEFT' or 'RIGHT'
    local growthY = string.find(db.aurasAnchorPoint, 'TOP') and 'DOWN' or 'UP'
    Auras.growthX = growthX
    Auras.growthY = growthY
    if (growthX == 'LEFT' and growthY == 'UP') then
        Auras.initialAnchor = 'BOTTOMRIGHT'
    elseif (growthX == 'RIGHT' and growthY == 'UP') then
        Auras.initialAnchor = 'BOTTOMLEFT'
    elseif (growthX == 'LEFT' and growthY == 'DOWN') then
        Auras.initialAnchor = 'TOPRIGHT'
    elseif (growthX == 'RIGHT' and growthY == 'DOWN') then
        Auras.initialAnchor = 'TOPLEFT'
    end

    local col = db.aurasColNum or 6
    local width = (db.aurasIconWidth + db.aurasSpacing) * col - db.aurasSpacing
    local height = (db.aurasIconHeight + db.aurasSpacing) * (math.ceil(db.aurasNum / db.aurasColNum))
    Auras:SetSize(width, height)
    Auras:ClearAllPoints()
    Auras:SetPoint(db.aurasAnchorPoint, frame.ElementFrame, db.aurasRelativeAnchorPoint, db.aurasXOff, db.aurasYOff)
    self:UpdateAspectRatio(Auras, db.aurasIconWidth, db.aurasIconHeight)
    self:UpdateAllTexts(Auras)
    self:UpdateCountdownFont(Auras.baseUnit, db)
    if (Auras.ForceUpdate) then
        Auras:ForceUpdate()
    end
end

auras.PostCreateButton = function(Auras, button)
    local icon = button.Icon
    local db = Auras.__owner.db
    icon:SetTexCoord(EXUI.utils.getTexCoords(db.aurasIconWidth, db.aurasIconHeight, 5))
    auras:UpdateCountText(button, db)
    auras:UpdateDurationText(button, Auras.baseUnit)
end

auras.UpdateAspectRatio = function(self, Auras, width, height)
    local left, right, top, bottom = EXUI.utils.getTexCoords(width, height, 5)
    for _, button in ipairs(Auras) do
        local icon = button.Icon
        icon:SetTexCoord(left, right, top, bottom)
    end
end

auras.UpdateAllTexts = function(self, Auras)
    if (not Auras.__owner) then return end
    local db = Auras.__owner.db
    for _, button in ipairs(Auras) do
        self:UpdateCountText(button, db)
    end
end

auras.UpdateCountText = function(self, button, db)
    local count = button.Count
    count:SetFont(LSM:Fetch('font', db.aurasCountFont), db.aurasCountFontSize, db.aurasCountFontFlag)
    count:SetVertexColor(
        db.aurasCountFontColor.r,
        db.aurasCountFontColor.g,
        db.aurasCountFontColor.b,
        db.aurasCountFontColor.a
    )
    count:ClearAllPoints()
    count:SetPoint(
        db.aurasCountAnchorPoint,
        count:GetParent(),
        db.aurasCountRelativeAnchorPoint,
        db.aurasCountXOff,
        db.aurasCountYOff
    )
end

auras.UpdateCountdownFont = function(self, unit, db)
    local font = self:GetFont(unit)
    font:SetFont(LSM:Fetch('font', db.aurasDurationFont), db.aurasDurationFontSize,
        db.aurasDurationFontFlag)
end

auras.UpdateDurationText = function(self, button, unit)
    local _, fontName = self:GetFont(unit)
    button.Cooldown:SetCountdownFont(fontName)
end
