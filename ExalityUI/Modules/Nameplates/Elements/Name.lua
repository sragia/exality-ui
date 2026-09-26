---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUINameplatesElementName
local name = EXUI:GetModule('np-element-name')

local nameTagReady = false

local function ensureNameTag()
    if nameTagReady then
        return
    end
    local oUF = EXUI.oUF
    if not oUF or not oUF.Tags then
        return
    end
    oUF.Tags.Methods['np:name'] = function(unit)
        local unitName, realm = UnitName(unit)
        local db = npCore:GetDB()
        if db and db.friendlyShowRealm and realm and unitName
            and not (issecretvalue and (issecretvalue(realm) or issecretvalue(unitName)))
            and realm ~= ''
        then
            return unitName .. '-' .. realm
        end
        return unitName
    end
    oUF.Tags.Events['np:name'] = 'UNIT_NAME_UPDATE'
    nameTagReady = true
end

local function applyClassColor(fontString, unit)
    local _, class = UnitClass(unit)
    if not class or not C_ClassColor or not C_ClassColor.GetClassColor then
        return false
    end
    local classColor = C_ClassColor.GetClassColor(class)
    if not classColor then
        return false
    end
    fontString:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
    return true
end

name.Create = function(self, frame)
    local fontString = frame.ElementFrame:CreateFontString(nil, 'OVERLAY')
    fontString:SetFont(EXUI.const.fonts.DEFAULT, 10, 'OUTLINE')
    return fontString
end

local CLASSIFICATION_COLORS = {
    elite = 'classificationElite',
    rare = 'classificationRare',
    rareelite = 'classificationRareElite',
    worldboss = 'classificationWorldBoss',
    minus = 'classificationMinus',
}

local function applyFriendlyName(frame, fontString, db)
    ensureNameTag()
    local unit = frame.unit or frame.__unit
    fontString:Show()
    fontString:SetFont(LSM:Fetch('font', db.nameFont), db.nameFontSize, db.nameFontFlag)
    fontString:SetWidth(db.sizeWidth or 140)
    fontString:SetHeight(db.nameFontSize + db.nameFontSize / 2)
    fontString:SetJustifyH('CENTER')
    fontString:ClearAllPoints()
    fontString:SetPoint('CENTER', frame.ElementFrame, 'CENTER', 0, 0)

    local override = unit and npCore:GetFriendlyPlayerColor(unit)
    local tag = '[np:name]'
    if override then
        fontString:SetVertexColor(override.r, override.g, override.b, override.a or 1)
    elseif unit and UnitIsPlayer(unit) and db.friendlyNameClassColor ~= false then
        tag = '[classcolor][np:name]'
        fontString:SetVertexColor(1, 1, 1, 1)
    elseif unit and UnitIsPlayer(unit) then
        fontString:SetVertexColor(1, 1, 1, 1)
    else
        local color = db.friendlyNpcColor
        if unit then
            local key = CLASSIFICATION_COLORS[UnitClassification(unit)]
            if key and db[key] then
                color = db[key]
            end
        end
        if color then
            fontString:SetVertexColor(color.r, color.g, color.b, color.a or 1)
        end
    end
    frame:Tag(fontString, tag)
end

local function applyFriendlyBarName(frame, fontString, db)
    local unit = frame.unit or frame.__unit
    if not unit then
        return
    end
    ensureNameTag()
    local override = npCore:GetFriendlyPlayerColor(unit)
    local useClass = not override and UnitIsPlayer(unit) and db.friendlyNameClassColor ~= false
    if override then
        fontString:SetVertexColor(override.r, override.g, override.b, override.a or 1)
    elseif useClass then
        applyClassColor(fontString, unit)
    end
    local tag = db.nameTag or '[name]'
    if db.friendlyShowRealm and UnitIsPlayer(unit) then
        tag = tag:gsub('%[name%]', '[np:name]')
    end
    if override or useClass then
        tag = tag:gsub('%[classcolor%]', '')
    end
    if tag ~= (db.nameTag or '[name]') then
        if tag == '' then
            tag = '[np:name]'
        end
        frame:Tag(fontString, tag)
    end
end

name.Update = function(self, frame)
    local db = frame.db
    local fontString = frame.Name
    if npCore:IsFriendlyNameOnly(frame) then
        applyFriendlyName(frame, fontString, db)
        return
    end
    if not db.nameEnable then
        fontString:Hide()
        frame:Untag(fontString)
        return
    end
    fontString:Show()
    fontString:SetFont(LSM:Fetch('font', db.nameFont), db.nameFontSize, db.nameFontFlag)
    local width = db.sizeWidth
    if db.nameMaxWidth then
        width = Round(db.sizeWidth * db.nameMaxWidth / 100)
    end
    fontString:SetWidth(width)
    fontString:SetHeight(db.nameFontSize + db.nameFontSize / 2)
    fontString:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(db.nameAnchorPoint))
    fontString:ClearAllPoints()
    fontString:SetPoint(db.nameAnchorPoint, frame.ElementFrame, db.nameRelativeAnchorPoint, db.nameXOffset, db.nameYOffset)
    fontString:SetVertexColor(db.nameFontColor.r, db.nameFontColor.g, db.nameFontColor.b, db.nameFontColor.a)
    frame:Tag(fontString, db.nameTag)
    if frame.isFriendly then
        applyFriendlyBarName(frame, fontString, db)
    end
end
