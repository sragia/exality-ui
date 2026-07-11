---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsDefaults
local barDefaults = EXUI:GetModule('action-bars-defaults')

---@class EXUIActionBarsGlow
---@field initialized boolean
---@field patched boolean
---@field customGlowKey string
---@field LBG table|nil
---@field LCG table|nil
---@field originalShowOverlayGlow function|nil
---@field originalHideOverlayGlow function|nil
local glow = EXUI:GetModule('action-bars-glow')

glow.initialized = false
glow.patched = false
glow.customGlowKey = 'ExalityUIActionBarGlow'

glow.Init = function(self)
    if self.initialized then
        return
    end
    self.initialized = true

    self.LBG = LibStub('LibButtonGlow-1.0', true)
    self.LCG = LibStub('LibCustomGlow-1.0', true)
    self:PatchOverlayGlow()
end

glow.PatchOverlayGlow = function(self)
    if self.patched or not self.LBG then
        return
    end

    self.originalShowOverlayGlow = self.LBG.ShowOverlayGlow
    self.originalHideOverlayGlow = self.LBG.HideOverlayGlow

    self.LBG.ShowOverlayGlow = function(button)
        glow:ShowOverlayGlow(button)
    end
    self.LBG.HideOverlayGlow = function(button)
        glow:HideOverlayGlow(button)
    end

    self.patched = true
end

glow.GetGlowType = function(self)
    local actionBars = EXUI:GetModule('action-bars')
    local db = actionBars and actionBars.GetDB and actionBars:GetDB() or nil
    local global = db and db.global or nil
    local defaultType = (barDefaults.GLOBAL and barDefaults.GLOBAL.glowType) or 'libbuttonglow'
    return (global and global.glowType) or defaultType
end

glow.GetGlowConfig = function(self)
    local actionBars = EXUI:GetModule('action-bars')
    local db = actionBars and actionBars.GetDB and actionBars:GetDB() or nil
    local global = db and db.global or {}
    local defaults = barDefaults.GLOBAL or {}

    local color = global.glowColor or defaults.glowColor or { r = 0.95, g = 0.95, b = 0.32, a = 1 }
    return {
        color = { color.r or 0.95, color.g or 0.95, color.b or 0.32, color.a or 1 },
        frequency = global.glowFrequency or defaults.glowFrequency or 0.25,
        frameLevel = global.glowFrameLevel or defaults.glowFrameLevel or 8,
        pixelLines = global.glowPixelLines or defaults.glowPixelLines or 8,
        pixelLength = global.glowPixelLength or defaults.glowPixelLength or 8,
        pixelThickness = global.glowPixelThickness or defaults.glowPixelThickness or 1,
        pixelBorder = global.glowPixelBorder ~= false,
        autoCastParticles = global.glowAutoCastParticles or defaults.glowAutoCastParticles or 4,
        autoCastScale = global.glowAutoCastScale or defaults.glowAutoCastScale or 1,
        procDuration = global.glowProcDuration or defaults.glowProcDuration or 1,
        procStartAnim = global.glowProcStartAnim ~= false,
    }
end

glow.IsManagedButton = function(self, button)
    if not button then
        return false
    end
    if button.exuiBarId or button.exuiUpdateHooked then
        return true
    end
    local name = button.GetName and button:GetName() or nil
    return type(name) == 'string' and string.find(name, '^EXUIActionBar_') ~= nil
end

glow.StopCustomGlow = function(self, button)
    if not self.LCG or not button then
        return
    end

    if self.LCG.PixelGlow_Stop then
        self.LCG.PixelGlow_Stop(button, self.customGlowKey)
    end
    if self.LCG.AutoCastGlow_Stop then
        self.LCG.AutoCastGlow_Stop(button, self.customGlowKey)
    end
    if self.LCG.ProcGlow_Stop then
        self.LCG.ProcGlow_Stop(button, self.customGlowKey)
    end
    if self.LCG.ButtonGlow_Stop then
        self.LCG.ButtonGlow_Stop(button)
    end
end

glow.StartCustomGlow = function(self, button, glowType)
    if not self.LCG or not button then
        return
    end

    local cfg = self:GetGlowConfig()
    local color = cfg.color

    if glowType == 'pixel' and self.LCG.PixelGlow_Start then
        self.LCG.PixelGlow_Start(
            button,
            color,
            cfg.pixelLines,
            cfg.frequency,
            cfg.pixelLength,
            cfg.pixelThickness,
            nil,
            nil,
            cfg.pixelBorder,
            self.customGlowKey,
            cfg.frameLevel
        )
        return
    end
    if glowType == 'autocast' and self.LCG.AutoCastGlow_Start then
        self.LCG.AutoCastGlow_Start(
            button,
            color,
            cfg.autoCastParticles,
            cfg.frequency,
            cfg.autoCastScale,
            nil,
            nil,
            self.customGlowKey,
            cfg.frameLevel
        )
        return
    end
    if glowType == 'proc' and self.LCG.ProcGlow_Start then
        self.LCG.ProcGlow_Start(button, {
            key = self.customGlowKey,
            color = color,
            frameLevel = cfg.frameLevel,
            duration = cfg.procDuration,
            startAnim = cfg.procStartAnim,
        })
        return
    end
    if glowType == 'button' and self.LCG.ButtonGlow_Start then
        self.LCG.ButtonGlow_Start(button, color, cfg.frequency, cfg.frameLevel)
    end
end

glow.ShowOverlayGlow = function(self, button)
    if not self.originalShowOverlayGlow or not self.originalHideOverlayGlow then
        return
    end

    if not self:IsManagedButton(button) then
        self.originalShowOverlayGlow(button)
        return
    end

    local glowType = self:GetGlowType()
    local useCustomGlow = self.LCG and glowType ~= 'libbuttonglow'

    if not useCustomGlow then
        self:StopCustomGlow(button)
        self.originalShowOverlayGlow(button)
        return
    end

    self.originalHideOverlayGlow(button)
    self:StopCustomGlow(button)
    self:StartCustomGlow(button, glowType)
end

glow.HideOverlayGlow = function(self, button)
    if not self.originalHideOverlayGlow then
        return
    end

    if not self:IsManagedButton(button) then
        self.originalHideOverlayGlow(button)
        return
    end

    self:StopCustomGlow(button)
    self.originalHideOverlayGlow(button)
end

glow.ApplySettings = function(self)
    local barMod = EXUI:GetModule('action-bars-bar')
    for _, frame in pairs(barMod.instances or {}) do
        for _, button in ipairs(frame.buttons or {}) do
            self:HideOverlayGlow(button)
        end
    end
end
