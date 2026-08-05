---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')


local health = EXUI:GetModule('uf-element-health')

health.Create = function(self, frame)
    local health = CreateFrame('StatusBar', '$parent_Health', frame, 'BackdropTemplate')
    health:SetAllPoints()
    health:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    health.PostUpdateColor = self.PostUpdateColor

    -- Background
    local background = health:CreateTexture(nil, 'BACKGROUND')
    background:SetTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    background:SetAllPoints()
    background.multiplier = 0.2
    health.bg = background
    health.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut

    return health
end

local function resolveHealthColorSettings(baseFrame)
    local generalDB = baseFrame.generalDB
    local db = baseFrame.db
    local cache = baseFrame._healthColorCache
    if not cache then
        cache = {}
        baseFrame._healthColorCache = cache
    end

    local isOverriden = db.overrideHealthColor
    if isOverriden then
        cache.useCustomColor = db.useCustomHealthColor
        cache.useSmoothHealthColor = db.useSmoothHealthColor
        cache.customColor = db.customHealthColor
        cache.useCustomBackdropColor = db.useCustomBackdropColor
        cache.customBackdropColor = db.customBackdropColor
        cache.useClassColoredBackdrop = db.useClassColoredBackdrop
    else
        cache.useCustomColor = generalDB.useCustomHealthColor
        cache.useSmoothHealthColor = generalDB.useSmoothHealthColor
        cache.customColor = generalDB.customHealthColor
        cache.useCustomBackdropColor = generalDB.useCustomBackdropColor
        cache.customBackdropColor = generalDB.customBackdropColor
        cache.useClassColoredBackdrop = generalDB.useClassColoredBackdrop
    end
    cache.valid = true
    return cache
end

health.PostUpdateColor = function(self, unit, color)
    local baseFrame = self:GetParent()
    local cache = baseFrame._healthColorCache
    if not cache or not cache.valid then
        cache = resolveHealthColorSettings(baseFrame)
    end

    if (cache.useCustomColor and not cache.useSmoothHealthColor) then
        local customColor = cache.customColor
        if (UnitIsConnected(unit)) then
            self:SetStatusBarColor(customColor.r, customColor.g, customColor.b)
        else
            self:SetStatusBarColor(color:GetRGB())
        end
    end

    if (cache.useCustomBackdropColor) then
        local customBackdropColor = cache.customBackdropColor
        self.bg:SetVertexColor(customBackdropColor.r, customBackdropColor.g, customBackdropColor.b)
    elseif (cache.useClassColoredBackdrop and color) then
        if (cache.useSmoothHealthColor) then
            if (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)) then
                local _, class = UnitClass(unit)
                color = self.__owner.colors.class[class]
            elseif (UnitReaction(unit, 'player')) then
                color = self.__owner.colors.reaction[UnitReaction(unit, 'player')]
            end
        end
        self.bg:SetVertexColor(color:GetRGB())
    end
end

health.Update = function(self, frame)
    local db = frame.db
    local generalDB = frame.generalDB
    local health = frame.Health

    resolveHealthColorSettings(frame)

    local useSmoothHealthColor = generalDB.useSmoothHealthColor
    if (db.overrideHealthColor) then
        useSmoothHealthColor = db.useSmoothHealthColor
    end

    if (useSmoothHealthColor) then
        health.colorSmooth = true
        health.colorDisconnected = true
        health.colorTapping = true
        health.colorClass = false
        health.colorReaction = false
    else
        health.colorSmooth = false
        health.colorDisconnected = true
        health.colorTapping = true
        health.colorClass = true
        health.colorReaction = true
    end

    health.bg.multiplier = generalDB.useClassColoredBackdrop and 1 or 0.2
    local statusBarTexture = db.overrideStatusBarTexture ~= '' and db.overrideStatusBarTexture or
        generalDB.statusBarTexture

    health:SetStatusBarTexture(LSM:Fetch('statusbar', statusBarTexture))
    health.bg:SetTexture(LSM:Fetch('statusbar', statusBarTexture))
end
