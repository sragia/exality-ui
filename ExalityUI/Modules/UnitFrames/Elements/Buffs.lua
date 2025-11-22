---@class ExalityUI
local EXUI = select(2, ...)

local buffs = EXUI:GetModule('uf-element-buffs')

buffs.Create = function(self, frame)
    local buffs = CreateFrame('Frame', nil, frame)

    return buffs
end

buffs.Update = function(self, frame)
    local db = frame.db
    local buffs = frame.Buffs
    
    if (not db.debuffsEnable and not db.buffsEnable) then
        frame:DisableElement('Auras')
        return
    end
    if (not db.buffsEnable) then
        buffs.num = 0
        buffs:ForceUpdate()
        return
    end
    frame:EnableElement('Auras')

    buffs.width = db.buffsIconWidth
    buffs.height = db.buffsIconHeight
    buffs.spacing = db.buffsSpacing
    buffs.num = db.buffsNum

    local growthX = string.find(db.buffsAnchorPoint, 'RIGHT') and 'LEFT' or 'RIGHT'
    local growthY = string.find(db.buffsAnchorPoint, 'TOP') and 'DOWN' or 'UP'
    buffs['growth-x'] = growthX
    buffs['growth-y'] = growthY
    buffs.onlyShowPlayer = db.buffsOnlyShowPlayer

    local col = db.buffsColNum or 6
    local width = (db.buffsIconWidth + db.buffsSpacing) * col - db.buffsSpacing
    local height = (db.buffsIconHeight + db.buffsSpacing) * (math.ceil(db.buffsNum / db.buffsColNum))
    buffs:SetSize(width, height)
    local anchorFrame = frame
    if (db.buffsAnchorToDebuffs and not db.debuffsAnchorToBuffs and frame.Debuffs and db.debuffsEnable) then
        anchorFrame = frame.Debuffs
    end
    buffs:SetPoint(db.buffsAnchorPoint, anchorFrame, db.buffsRelativeAnchorPoint, db.buffsXOff, db.buffsYOff)
    buffs:ForceUpdate()
end