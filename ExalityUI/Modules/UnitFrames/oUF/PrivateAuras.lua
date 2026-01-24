--[[

## Options
.maxNum = Maximum auras shown (Defaults: 5)
.iconWidth = Icon Width (Defaults:  16)
.iconHeight = Icon Height (Defaults: 16)
.spacing = Spacing between auras (Defaults: 2)
.growthX = Growth direction for the auras (Defaults: 'RIGHT')

]]

---@class ExalityUI
local EXUI = select(2, ...)

local oUF = EXUI.oUF

local function ClearAnchors(element)
    if (element.anchors) then
        for i, anchor in ipairs(element.anchors) do
            if (anchor) then
                C_UnitAuras.RemovePrivateAuraAnchor(anchor)
            end
        end
        wipe(element.anchors)
    end
end

local function Update(self, event, unit)
    if (not unit or not UnitIsUnit(self.unit, unit)) then return end
    local element = self.PrivateAuras

    ClearAnchors(element)

    local maxNum = element.maxNum or 5
    local iconWidth = element.iconWidth or 16
    local iconHeight = element.iconHeight or 16
    local spacing = element.spacing or 2
    local growthX = element.growthX or 'RIGHT'
    local direction = growthX == 'RIGHT' and 1 or -1

    for auraIndex = 1, maxNum do
        local args = {
            unitToken = unit,
            auraIndex = auraIndex,
            parent = element,
            showCountdownFrame = true,
            showCountdownNumbers = true,
            iconInfo = {
                iconAnchor = {
                    point = 'CENTER',
                    relativeTo = element,
                    relativePoint = 'CENTER',
                    offsetX = (auraIndex - 1) * direction * (iconWidth + spacing),
                    offsetY = 0,
                },
                iconWidth = iconWidth,
                iconHeight = iconHeight,
            }
        }

        local anchorID = C_UnitAuras.AddPrivateAuraAnchor(args)
        table.insert(element.anchors, anchorID)
    end
end

local function Enable(self, unit)
    local element = self.PrivateAuras
    if (element) then
        element.__owner = self
        element.anchors = {}

        element:Show()

        return true
    end
end

local function Disable(self)
    local element = self.PrivateAuras
    if (element) then
        ClearAnchors(element)
        element:Hide()
    end
end

oUF:AddElement('PrivateAuras', Update, Enable, Disable)
