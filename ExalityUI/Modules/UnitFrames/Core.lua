---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

local LSM = LibStub('LibSharedMedia-3.0')

----------------

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('unit-frames-core')

core.options = {}

core.Init = function(self)
    optionsController:RegisterModule(self)
    data:UpdateDefaults(self:GetDefaults())
end

core.GetName = function(self)
    return 'Unit Frames'
end

core.GetDefaults = function(self)
    return {
        unitFramesEnabled = true,
    }
end

core.GetOptions = function(self)
    return self.options
end

core.GetOrder = function(self)
    return 50
end

core.SetupFrameForUnit = function(self, frame, unit)
    frame:SetAttribute('unit', unit)
    RegisterUnitWatch(frame)
    frame:RegisterForClicks('AnyUp')
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")

    frame:RegisterEvent('PLAYER_ENTERING_WORLD')
    frame:RegisterUnitEvent('UNIT_HEALTH', unit)
    frame:RegisterUnitEvent('UNIT_ABSORB_AMOUNT_CHANGED', unit)
    frame:RegisterUnitEvent('UNIT_MAXHEALTH', unit)
    if (frame.power) then
        frame:RegisterUnitEvent('UNIT_POWER_FREQUENT', unit)
    end

    frame:SetScript('OnEvent', function(self, event, ...)
        if (event == 'PLAYER_ENTERING_WORLD') then
            self.name:SetText(UnitName(unit))
            self.hp:SetMinMaxValues(0, UnitHealthMax(unit))
            self.hp:SetValue(UnitHealth(unit))
            self.hpText:SetText(AbbreviateNumbers(UnitHealth(unit)))
            self.hpPerc:SetText(string.format('%d%%', UnitHealthPercent(unit, true, true)))
        elseif (event == 'UNIT_HEALTH') then
            self.hp:SetValue(UnitHealth(unit))
            self.hpText:SetText(AbbreviateNumbers(UnitHealth(unit)))
            self.hp:SetMinMaxValues(0, UnitHealthMax(unit))
            self.hpPerc:SetText(string.format('%d%%', UnitHealthPercent(unit, true, true)))
        elseif (event == 'UNIT_POWER_FREQUENT' and self.power) then
            self.power:SetValue(UnitPower(unit))
            self.power:SetMinMaxValues(0, UnitPowerMax(unit))
        elseif (event == 'UNIT_MAXHEALTH') then
            self.hp:SetMinMaxValues(0, UnitHealthMax(unit))
            self.hp:SetValue(UnitHealth(unit))
            self.hpText:SetText(AbbreviateNumbers(UnitHealth(unit)))
            self.hpPerc:SetText(string.format('%d%%', UnitHealthPercent(unit, true, true)))
        elseif (event == 'UNIT_ABSORB_AMOUNT_CHANGED') then
            self.absorbBar:SetMinMaxValues(0, UnitHealthMax(unit))
            self.absorbBar:SetValue(UnitGetTotalAbsorbs(unit))
        end
        if (self.onUpdate) then
            self:onUpdate(event, ...)
        end
    end)
end

core.CreateBaseFrame = function(self, hasPower)
    local f = CreateFrame('Button', nil, UIParent, 'SecureUnitButtonTemplate, PingableUnitFrameTemplate, BackdropTemplate')
    f:SetBackdrop(EXUI.const.backdrop.DEFAULT)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    if (hasPower) then
        local power = CreateFrame('StatusBar', nil, f, 'BackdropTemplate')
        power:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
        power:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', 1, 1)
        power:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -1, 1)
        power:SetHeight(5)
        power:SetBackdrop(EXUI.const.backdrop.DEFAULT)
        power:SetBackdropColor(0, 0, 0, 1)
        power:SetBackdropBorderColor(0, 0, 0, 1)
        f.power = power
    end

    local hp = CreateFrame('StatusBar', nil, f, 'BackdropTemplate')
    hp:SetClipsChildren(true)
    hp:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    hp:SetPoint('TOPLEFT', 1, -1)
    if (hasPower) then
        hp:SetPoint('BOTTOMRIGHT', f.power, 'TOPRIGHT', 0, 0)
    else
        hp:SetPoint('BOTTOMRIGHT', -1, 1)
    end
    f.hp = hp

    local absorbBar = CreateFrame('StatusBar', nil, hp, 'BackdropTemplate')
    absorbBar:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    absorbBar:SetPoint('TOPLEFT', hp:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
    absorbBar:SetPoint('BOTTOMLEFT', f.hp:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
    absorbBar:SetStatusBarColor(52/255, 73/255, 235/255, 0.8)
    absorbBar:SetMinMaxValues(0, 1)
    absorbBar:SetValue(0)
    f.absorbBar = absorbBar

    local textFrame = CreateFrame('Frame', nil, f)
    textFrame:SetAllPoints()
    textFrame:SetFrameLevel(hp:GetFrameLevel() + 1)

    local name = textFrame:CreateFontString(nil, 'OVERLAY')
    name:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    name:SetWidth(100)
    name:SetJustifyH('LEFT')
    name:SetText('')
    f.name = name

    local hpPerc = textFrame:CreateFontString(nil, 'OVERLAY')
    hpPerc:SetFont(EXUI.const.fonts.DEFAULT, 16, 'OUTLINE')
    hpPerc:SetWidth(0)
    hpPerc:SetText('0%')
    f.hpPerc = hpPerc

    local hpText = textFrame:CreateFontString(nil, 'OVERLAY')
    hpText:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    hpText:SetWidth(0)
    hpText:SetText('0')
    f.hpText = hpText

    f.hp = hp

    return f
end

core.HideBlizzardFrame = function(self, frame)
    if (not frame) then return end
    frame:UnregisterAllEvents()
    frame:Hide()

    local health = frame.healthBar or frame.healthbar or frame.HealthBar
    if(health) then
        health:UnregisterAllEvents()
    end

    local power = frame.manabar or frame.ManaBar
    if(power) then
        power:UnregisterAllEvents()
    end

    local spell = frame.castBar or frame.spellbar or frame.CastingBarFrame
    if (spell) then
        spell:UnregisterAllEvents()
    end

    local altpowerbar = frame.powerBarAlt or frame.PowerBarAlt
    if (altpowerbar) then
        altpowerbar:UnregisterAllEvents()
    end

    local buffFrame = frame.BuffFrame
    if (buffFrame) then
        buffFrame:UnregisterAllEvents()
    end

    local petFrame = frame.petFrame or frame.PetFrame
    if (petFrame) then
        petFrame:UnregisterAllEvents()
    end

    local totFrame = frame.totFrame
    if (totFrame) then
        totFrame:UnregisterAllEvents()
    end

    local classPowerBar = frame.classPowerBar
    if (classPowerBar) then
        classPowerBar:UnregisterAllEvents()
    end

    local ccRemoverFrame = frame.CcRemoverFrame
    if (ccRemoverFrame) then
        ccRemoverFrame:UnregisterAllEvents()
    end

    local debuffFrame = frame.DebuffFrame
    if (debuffFrame) then
        debuffFrame:UnregisterAllEvents()
    end
end

core.AddOptions = function(self, options)
    for _, option in ipairs(options) do
        table.insert(self.options, option)
    end
end