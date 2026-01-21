---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

local buffs = EXUI:GetModule('uf-element-buffs')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

buffs.CountdownFontName = 'ExalityUI_Buffs_CountdownFont'
buffs.CountdownFont = CreateFont(buffs.CountdownFontName)

buffs.Create = function(self, frame, filters)
    local Buffs = CreateFrame('Frame', nil, frame.ElementFrame)
    Buffs.PostCreateButton = buffs.PostCreateButton
    if (filters) then
        Buffs.filter = filters
    end
    return Buffs
end

buffs.Update = function(self, frame)
    local db = frame.db
    local Buffs = frame.Buffs

    if (not db.debuffsEnable and not db.buffsEnable) then
        core:DisableElementForFrame(frame, 'Auras')
        return
    end
    if (not db.buffsEnable) then
        Buffs.num = 0
        if (Buffs.ForceUpdate) then
            Buffs:ForceUpdate()
        end
        return
    end
    core:EnableElementForFrame(frame, 'Auras')

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
    Buffs.onlyShowPlayer = db.buffsOnlyShowPlayer

    local col = db.buffsColNum or 6
    local width = (db.buffsIconWidth + db.buffsSpacing) * col - db.buffsSpacing
    local height = (db.buffsIconHeight + db.buffsSpacing) * (math.ceil(db.buffsNum / db.buffsColNum))
    Buffs:SetSize(width, height)
    local anchorFrame = frame.ElementFrame
    if (db.buffsAnchorToDebuffs and not db.debuffsAnchorToBuffs and frame.Debuffs and db.debuffsEnable) then
        anchorFrame = frame.Debuffs
    end
    Buffs:SetPoint(db.buffsAnchorPoint, anchorFrame, db.buffsRelativeAnchorPoint, db.buffsXOff, db.buffsYOff)
    self:UpdateAspectRatio(Buffs, db.buffsIconWidth, db.buffsIconHeight)
    self:UpdateAllTexts(Buffs)
    self:UpdateCountdownFont(db)
    if (Buffs.ForceUpdate) then
        Buffs:ForceUpdate()
    end
end

buffs.PostCreateButton = function(Buffs, button)
    local icon = button.Icon
    local db = Buffs.__owner.db
    icon:SetTexCoord(EXUI.utils.getTexCoords(db.buffsIconWidth, db.buffsIconHeight, 5))
    buffs:UpdateCountText(button, db)
    buffs:UpdateDurationText(button)
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

buffs.UpdateCountdownFont = function(self, db)
    self.CountdownFont:SetFont(LSM:Fetch('font', db.buffsDurationFont), db.buffsDurationFontSize,
        db.buffsDurationFontFlag)
end

buffs.UpdateDurationText = function(self, button)
    button.Cooldown:SetCountdownFont(self.CountdownFontName)
end
