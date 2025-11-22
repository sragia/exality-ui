---@class ExalityUI
local EXUI = select(2, ...)

local debuffs = EXUI:GetModule('uf-element-debuffs')

debuffs.Create = function(self, frame)
    local debuffs = CreateFrame('Frame', nil, frame)

    return debuffs
end

debuffs.Update = function(self, frame)
    local db = frame.db
    local debuffs = frame.Debuffs

    if (not db.debuffsEnable and not db.buffsEnable) then
        frame:DisableElement('Auras')
        return
    end
    if (not db.debuffsEnable) then
        debuffs.num = 0
        debuffs:ForceUpdate()
        return
    end
    frame:EnableElement('Auras')

    debuffs.width = db.debuffsIconWidth
    debuffs.height = db.debuffsIconHeight
    debuffs.spacing = db.debuffsSpacing
    debuffs.num = db.debuffsNum

    local growthX = string.find(db.debuffsAnchorPoint, 'RIGHT') and 'LEFT' or 'RIGHT'
    local growthY = string.find(db.debuffsAnchorPoint, 'TOP') and 'DOWN' or 'UP'

    debuffs['growth-x'] = growthX
    debuffs['growth-y'] = growthY
    debuffs.onlyShowPlayer = db.debuffsOnlyShowPlayer

    local col = db.debuffsColNum or 6
    local width = (db.debuffsIconWidth + db.debuffsSpacing) * col - db.debuffsSpacing
    local height = (db.debuffsIconHeight + db.debuffsSpacing) * (math.ceil(db.debuffsNum / db.debuffsColNum))
    debuffs:SetSize(width, height)
    local anchorFrame = frame
    if (db.debuffsAnchorToBuffs and frame.Buffs and db.buffsEnable) then
        anchorFrame = frame.Buffs
    end
    debuffs:SetPoint(db.debuffsAnchorPoint, anchorFrame, db.debuffsRelativeAnchorPoint, db.debuffsXOff, db.debuffsYOff)
    debuffs:ForceUpdate()
end