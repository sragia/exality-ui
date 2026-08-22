---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub('LibSharedMedia-3.0')

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIOptionsMain
local optionsMain = EXUI:GetModule('options-main')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUINameplatesPreview
local preview = EXUI:GetModule('np-preview')

preview.frame = nil
preview.host = nil
preview.parent = nil
preview.castTicker = nil

local HOST_PAD_X = 48
local HOST_PAD_Y = 72

local function nop() end

local function stubOUF(frame)
    frame.Tag = nop
    frame.Untag = nop
    frame.EnableElement = nop
    frame.DisableElement = nop
end

local function ensureFrame(parent)
    if preview.frame and preview.frame:GetParent() == parent then
        return preview.frame
    end
    if preview.frame then
        preview.frame:Hide()
        preview.frame:SetParent(nil)
        preview.frame = nil
    end

    local frame = CreateFrame('Frame', nil, parent)
    frame:SetPoint('CENTER', parent, 'CENTER', 0, 4)
    frame.isPreview = true
    stubOUF(frame)
    npCore:BuildPlate(frame)

    preview.frame = frame
    return frame
end

local function startCastLoop(frame, db)
    if preview.castTicker then
        preview.castTicker:Cancel()
        preview.castTicker = nil
    end
    local bar = frame.Castbar
    if not db.castbarEnable or not bar or not bar.container then
        if bar and bar.container then
            bar.container:Hide()
        end
        return
    end
    bar.container:Show()
    bar.chrome:Show()
    bar:Show()
    local duration = 3
    local start = GetTime()
    bar:SetMinMaxValues(0, duration)
    bar.Icon:SetTexture(136096)
    bar.Text:SetText('Fireball')
    if bar.TargetText then
        if db.castbarShowTarget then
            bar.TargetText:SetText('Target')
            local shaman = C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor('SHAMAN')
            if shaman then
                bar.TargetText:SetVertexColor(shaman.r, shaman.g, shaman.b, shaman.a or 1)
            end
            bar.TargetText:Show()
        else
            bar.TargetText:Hide()
        end
    end
    preview.castTicker = C_Timer.NewTicker(0.05, function()
        if not preview.frame or not preview.frame:IsShown() then
            return
        end
        local elapsed = (GetTime() - start) % duration
        bar:SetValue(elapsed)
        bar.Time:SetFormattedText('%.1f', duration - elapsed)
    end)
end

preview.HookOptionsWindow = function(self, window)
    if not window or window.exuiNPPreviewHooked then
        return
    end
    window.exuiNPPreviewHooked = true
    window:HookScript('OnHide', function()
        preview:Hide()
    end)
    local previousOnClose = window.onClose
    window.onClose = function()
        preview:Hide()
        if previousOnClose then
            previousOnClose()
        end
    end
end

preview.Init = function(self)
    if self.initialized then
        return
    end
    if optionsMain.window then
        self:HookOptionsWindow(optionsMain.window)
    end
    hooksecurefunc(optionsMain, 'CreateWindow', function(main)
        if main.window then
            preview:HookOptionsWindow(main.window)
        end
    end)
    if optionsController.Observe then
        if not optionsController.observable then
            optionsController:Init()
        end
        optionsController:Observe('selectedModule', function(name)
            if name ~= 'Nameplates' then
                preview:Hide()
            end
        end)
    end
    self.initialized = true
end

preview.EnsureHost = function(self)
    local window = optionsMain.window
    if not window then
        return nil
    end
    if self.host and self.anchor == window then
        -- Same default strata as live nameplates so aura frameStrata/level can stack over texts.
        self.host:SetFrameStrata('MEDIUM')
        self.host:SetFrameLevel(2000)
        return self.host
    end
    if self.host then
        self.host:Hide()
        self.host:SetParent(nil)
        self.host = nil
        self.anchor = nil
    end

    -- Parent to UIParent so secret aura-button sizes cannot taint the options window.
    -- MEDIUM matches live nameplates; DIALOG would hide configured MEDIUM auras behind this panel.
    local host = CreateFrame('Frame', nil, UIParent)
    host:SetPoint('TOPLEFT', window, 'TOPRIGHT', 8, 0)
    host:SetFrameStrata('MEDIUM')
    host:SetFrameLevel(2000)
    self.anchor = window

    local title = host:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    title:SetPoint('TOP', 0, -10)
    title:SetText('Preview')
    host.title = title

    self.host = host
    return host
end

preview.Show = function(self)
    local host = self:EnsureHost()
    if not host then
        return
    end
    host:Show()
    self.parent = host
    local frame = ensureFrame(host)
    frame:Show()
    self:Refresh()
end

preview.Attach = function(self)
    self:Show()
end

preview.Hide = function(self)
    if self.castTicker then
        self.castTicker:Cancel()
        self.castTicker = nil
    end
    local aurasPreview = EXUI:GetModule('np-auras-preview')
    if aurasPreview and aurasPreview.ClearPreviewStates then
        aurasPreview:ClearPreviewStates()
    end
    if self.frame then
        self.frame:Hide()
    end
    if self.host then
        self.host:Hide()
    end
    self.parent = nil
end

preview.Refresh = function(self)
    if not self.parent or not self.parent:IsShown() then
        return
    end
    local db = npCore:GetDB()
    if not db then
        return
    end
    local frame = ensureFrame(self.parent)
    frame.db = db
    frame.isFriendly = false
    frame:SetSize(db.sizeWidth or 140, db.sizeHeight or 16)

    local hostWidth = (db.sizeWidth or 140) + HOST_PAD_X
    local hostHeight = (db.sizeHeight or 16) + (db.castbarEnable and (db.castbarHeight or 12) or 0) + HOST_PAD_Y
    self.host:SetSize(math.max(220, hostWidth), math.max(120, hostHeight))

    npCore:UpdatePlate(frame)

    local texture = LSM:Fetch('statusbar', db.statusBarTexture or 'ExalityUI Status Bar')
    frame.Health:SetStatusBarTexture(texture)
    if frame.Health.bg then
        frame.Health.bg:SetTexture(texture)
    end
    frame.Health:SetMinMaxValues(0, 100)
    frame.Health:SetValue(65)
    local c = db.customHealthColor or { r = 0.82, g = 0.2, b = 0.2 }
    if db.colorThreat then
        c = db.threatHaveAggro or c
    end
    frame.Health:SetStatusBarColor(c.r, c.g, c.b, c.a or 1)
    local backdrop = db.healthBackdropColor or { r = 0.12, g = 0.12, b = 0.12 }
    if frame.Health.bg then
        frame.Health.bg:SetVertexColor(backdrop.r, backdrop.g, backdrop.b, backdrop.a or 1)
    end

    if db.nameEnable then
        frame.Name:SetText('Preview Dummy')
    end
    if db.healthpercEnable then
        frame.HealthPerc:SetText('65%')
    end
    if db.healthEnable then
        frame.HealthText:SetText('65k')
    end

    if db.raidTargetIndicatorEnable then
        SetRaidTargetIconTexture(frame.RaidTargetIndicator, 8)
        frame.RaidTargetIndicator:Show()
        if frame.RaidTargetHost then
            frame.RaidTargetHost:Show()
        end
    end
    EXUI:GetModule('np-element-health-prediction'):Update(frame)
    local health = frame.Health
    if db.damageAbsorbEnable and health.DamageAbsorb then
        health.DamageAbsorb:SetMinMaxValues(0, 100)
        health.DamageAbsorb:SetValue(20)
        health.DamageAbsorb:Show()
        if health.OverDamageAbsorbIndicator and db.damageAbsorbShowOverIndicator and (db.damageAbsorbShowAt or 'AS_EXTENSION') == 'AS_EXTENSION' then
            health.OverDamageAbsorbIndicator:SetAlpha(1)
            health.OverDamageAbsorbIndicator:Show()
        end
    end
    if db.healAbsorbEnable and health.HealAbsorb then
        health.HealAbsorb:SetMinMaxValues(0, 100)
        health.HealAbsorb:SetValue(15)
        health.HealAbsorb:Show()
    end

    startCastLoop(frame, db)
    frame:Show()

    local aurasPreview = EXUI:GetModule('np-auras-preview')
    if aurasPreview and aurasPreview.RefreshOnPlate then
        aurasPreview:RefreshOnPlate(frame)
        local extraW, extraH = 0, 0
        if aurasPreview.GetHostExtra then
            extraW, extraH = aurasPreview:GetHostExtra()
        end
        hostWidth = hostWidth + extraW
        hostHeight = hostHeight + extraH
        self.host:SetSize(math.max(220, hostWidth), math.max(120, hostHeight))
    end
end
