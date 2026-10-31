---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesElementsPortrait
local portrait = EXUI:GetModule('uf-element-portrait')

local SPRITE_WIDTH, SPRITE_HEIGHT = 157, 458
-- Sprite crops are the mask rect padded by this many px on each side (shadow)
local SPRITE_PAD = 8
local TEXTURE_INSET = 0.08

local SHAPES = {
    circle = {
        mask = 'portraitMaskCircle',
        maskWidth = 128,
        maskHeight = 128,
        sprite = { 2, 146, 146, 290 },
    },
    hexagon = {
        mask = 'portraitMaskHexagon',
        maskWidth = 126,
        maskHeight = 109,
        sprite = { 3, 6, 145, 131 },
    },
    square = {
        mask = 'portraitMaskSquare',
        maskWidth = 128,
        maskHeight = 128,
        sprite = { 2, 304, 146, 448 },
    },
}

local function SupportsModel(style)
    return style == 'square' or style == 'attached'
end

portrait.SupportsModel = function(self, style)
    return SupportsModel(style)
end

local function CropToAspect(width, height, left, right, top, bottom)
    if width > height then
        local visible = (bottom - top) * height / width
        local mid = (top + bottom) / 2
        top, bottom = mid - visible / 2, mid + visible / 2
    elseif height > width then
        local visible = (right - left) * width / height
        local mid = (left + right) / 2
        left, right = mid - visible / 2, mid + visible / 2
    end
    return left, right, top, bottom
end

local function ApplyTexCoords(texture, unit)
    local width, height = texture.cropWidth, texture.cropHeight
    if not width or not height then
        return
    end

    local left, right, top, bottom = TEXTURE_INSET, 1 - TEXTURE_INSET, TEXTURE_INSET, 1 - TEXTURE_INSET
    if texture.showClass and unit then
        local _, class = UnitClass(unit)
        local info = class and C_Texture.GetAtlasInfo('classicon-' .. class)
        if info and (info.file or info.filename) then
            -- Swap the atlas for its raw file so tex coords are absolute
            texture:SetTexture(info.file or info.filename)
            left, right = info.leftTexCoord, info.rightTexCoord
            top, bottom = info.topTexCoord, info.bottomTexCoord
        end
    end

    texture:SetTexCoord(CropToAspect(width, height, left, right, top, bottom))
end

local function ApplyBorderColor(holder, unit)
    local color = holder.borderColor
    if not color then
        return
    end

    local r, g, b, a = color.r, color.g, color.b, color.a
    if holder.useClassColor and unit and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local classColor = class and EXUI.oUF.colors.class[class]
        if classColor then
            r, g, b = classColor:GetRGB()
        end
    end

    holder.Border:SetVertexColor(r, g, b, a)
    holder.Separator:SetColorTexture(r, g, b, a)
end

local function PreUpdate(self, unit)
    self.showClass = self.classIconEnabled and UnitIsPlayer(unit)
end

local function TexturePostUpdate(self, unit)
    ApplyTexCoords(self, unit)
    ApplyBorderColor(self:GetParent(), unit)
end

local function ModelPostUpdate(self, unit)
    ApplyBorderColor(self:GetParent(), unit)
end

portrait.Create = function(self, frame)
    local holder = CreateFrame('Frame', '$parent_Portrait', frame)
    holder:SetFrameLevel(frame:GetFrameLevel() + 50)

    local mask = holder:CreateMaskTexture()
    mask:SetAllPoints()
    holder.Mask = mask

    local bg = holder:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 1)
    bg:AddMaskTexture(mask)
    holder.Bg = bg

    local texture = holder:CreateTexture(nil, 'ARTWORK')
    texture:SetAllPoints()
    texture:AddMaskTexture(mask)
    texture.PreUpdate = PreUpdate
    texture.PostUpdate = TexturePostUpdate
    holder.Texture = texture

    local model = CreateFrame('PlayerModel', nil, holder)
    model:SetAllPoints()
    model.PostUpdate = ModelPostUpdate
    model:Hide()
    holder.Model = model

    local borderFrame = CreateFrame('Frame', nil, holder)
    borderFrame:SetAllPoints()
    borderFrame:SetFrameLevel(holder:GetFrameLevel() + 5)
    holder.BorderFrame = borderFrame

    local border = borderFrame:CreateTexture(nil, 'OVERLAY')
    border:SetTexture(EXUI.const.textures.unitFrames.portraitSprite)
    holder.Border = border

    local separator = borderFrame:CreateTexture(nil, 'OVERLAY')
    holder.Separator = separator

    frame.PortraitHolder = holder
    return texture
end

portrait.GetBarInsets = function(self, frame)
    local db = frame.db
    if not frame.Portrait or not db or not db.portraitEnable or db.portraitStyle ~= 'attached' then
        return 0, 0
    end
    local inset = EXUI:ScalePixel(db.portraitAttachedWidth, frame) + EXUI:ScalePixels(1, frame)
    if db.portraitAttachedSide == 'RIGHT' then
        return 0, inset
    end
    return inset, 0
end

local function LayoutShaped(frame, holder, db, shape)
    local size = db.portraitSize
    local width = size
    local height = size * shape.maskHeight / shape.maskWidth

    holder:ClearAllPoints()
    EXUI:SetSize(holder, width, height)
    EXUI:SetPoint(holder, db.portraitAnchorPoint, frame.ElementFrame, db.portraitRelativeAnchorPoint,
        db.portraitXOff, db.portraitYOff)

    local sprite = shape.sprite
    local border = holder.Border
    border:SetTexCoord(sprite[1] / SPRITE_WIDTH, sprite[3] / SPRITE_WIDTH, sprite[2] / SPRITE_HEIGHT,
        sprite[4] / SPRITE_HEIGHT)
    local outsetX = SPRITE_PAD * width / shape.maskWidth
    local outsetY = SPRITE_PAD * height / shape.maskHeight
    border:ClearAllPoints()
    border:SetPoint('TOPLEFT', holder, 'TOPLEFT', -outsetX, outsetY)
    border:SetPoint('BOTTOMRIGHT', holder, 'BOTTOMRIGHT', outsetX, -outsetY)
    border:Show()
    holder.Separator:Hide()

    return width, height
end

local function LayoutAttached(frame, holder, db)
    local width = EXUI:ScalePixel(db.portraitAttachedWidth, frame)
    local separatorWidth = EXUI:ScalePixels(1, frame)
    local isRight = db.portraitAttachedSide == 'RIGHT'
    local side = isRight and 'RIGHT' or 'LEFT'

    holder:ClearAllPoints()
    holder:SetPoint('TOP' .. side, frame, 'TOP' .. side, 0, 0)
    holder:SetPoint('BOTTOM' .. side, frame, 'BOTTOM' .. side, 0, 0)
    holder:SetWidth(width)

    local separator = holder.Separator
    separator:ClearAllPoints()
    separator:SetPoint(isRight and 'TOPRIGHT' or 'TOPLEFT', holder, isRight and 'TOPLEFT' or 'TOPRIGHT', 0, 0)
    separator:SetPoint(isRight and 'BOTTOMRIGHT' or 'BOTTOMLEFT', holder, isRight and 'BOTTOMLEFT' or 'BOTTOMRIGHT',
        0, 0)
    separator:SetWidth(separatorWidth)
    separator:Show()
    holder.Border:Hide()

    return db.portraitAttachedWidth, db.sizeHeight
end

portrait.Update = function(self, frame)
    local db = frame.db
    local holder = frame.PortraitHolder
    if (not db.portraitEnable) then
        core:DisableElementForFrame(frame, 'Portrait')
        holder:Hide()
        return
    end

    local style = db.portraitStyle
    local useModel = db.portraitType == 'model' and SupportsModel(style)
    local widget = useModel and holder.Model or holder.Texture
    if (frame.Portrait ~= widget) then
        core:DisableElementForFrame(frame, 'Portrait')
        frame.Portrait:Hide()
        frame.Portrait = widget
    end

    -- Shaped portraits float above the UF border, attached ones sit beneath it
    local level = style == 'attached' and frame:GetFrameLevel() + 50 or
        frame.ElementFrame:GetFrameLevel() + (db.portraitFrameLevel or 5)
    holder:SetFrameLevel(level)
    holder.Model:SetFrameLevel(level + 1)
    holder.BorderFrame:SetFrameLevel(level + 2)

    local width, height
    if (style == 'attached') then
        holder.Mask:SetTexture(EXUI.const.textures.unitFrames.portraitMaskSquare, 'CLAMPTOBLACKADDITIVE',
            'CLAMPTOBLACKADDITIVE')
        width, height = LayoutAttached(frame, holder, db)
    else
        local shape = SHAPES[style] or SHAPES.circle
        holder.Mask:SetTexture(EXUI.const.textures.unitFrames[shape.mask], 'CLAMPTOBLACKADDITIVE',
            'CLAMPTOBLACKADDITIVE')
        width, height = LayoutShaped(frame, holder, db, shape)
    end

    local texture = holder.Texture
    texture.classIconEnabled = db.portraitClassIcon and not useModel
    texture.cropWidth = width
    texture.cropHeight = height

    holder.borderColor = db.portraitBorderColor
    holder.useClassColor = db.portraitBorderClassColor
    ApplyBorderColor(holder, frame.__unit)

    holder:Show()
    core:EnableElementForFrame(frame, 'Portrait')
end
