---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIData
local data = EXUI:GetModule('data')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

----------------
local _, screenHeight = GetPhysicalScreenSize()
local defaultUIScale = 768 / screenHeight

---@class EXUIGeneralModule
local generalModule = EXUI:GetModule('general-module')

generalModule.bottomVignette = nil

generalModule.Init = function(self)
    optionsController:RegisterModule(self)
    data:UpdateDefaults(self:GetDefaults())

    self:SetupUIScale()
    self.paperDoll:Init()
    self.fonts:Init()
    self:Refresh()
end

generalModule.GetName = function(self)
    return 'General'
end

generalModule.GetDefaults = function(self)
    return {
        uiScale = defaultUIScale,
        paperDollEnabled = true,
        replaceFonts = true,
        font = 'DMSans',
        bottomVignette = false,
    }
end

generalModule.GetOptions = function(self)
    return {
        {
            label = 'UI Scale',
            name = 'uiScale',
            type = 'range',
            min = 0.2,
            max = 1,
            step = 0.001,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('uiScale')
            end,
            onChange = function(f, value)
                data:SetDataByKey('uiScale', value)
                -- EXUI:GetModule('options-reload-dialog'):ShowDialog()
            end
        },
        {
            label = 'Auto Scale',
            name = 'autoScale',
            type = 'button',
            onClick = function()
                local _, screenHeight = GetPhysicalScreenSize()
                local uiScale = 768 / screenHeight
                data:SetDataByKey('uiScale', uiScale)
                EXUI:GetModule('options-reload-dialog'):ShowDialog()
            end,
            width = 16,
            color = { 219/255, 73/255, 0 , 1 }
        },
        {
            label = 'Paper Doll Improvements',
            name = 'paperDollEnabled',
            type = 'toggle',
            onObserve = function(value, oldValue)
                data:SetDataByKey('paperDollEnabled', value)
                EXUI:GetModule('options-reload-dialog'):ShowDialog()
            end,
            currentValue = function()
                return data:GetDataByKey('paperDollEnabled')
            end,
            width = 100,
        },
        {
            label = 'Replace All Fonts',
            name = 'replaceFonts',
            type = 'toggle',
            onObserve = function(value, oldValue)
                data:SetDataByKey('replaceFonts', value)
                EXUI:GetModule('options-reload-dialog'):ShowDialog()
            end,
            currentValue = function()
                return data:GetDataByKey('replaceFonts')
            end,
            width = 100,
        },
        {
            label = 'Add Bottom Vignette',
            name = 'bottomVignette',
            type = 'toggle',
            onObserve = function(value, oldValue)
                data:SetDataByKey('bottomVignette', value)
                generalModule:Refresh()
            end,
            currentValue = function()
                return data:GetDataByKey('bottomVignette')
            end,
            width = 100,
        },
        {
            label = 'Font',
            name = 'font',
            type = 'dropdown',
            getOptions = function()
                local fonts = LSM:List('font')
                table.sort(fonts)
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            onChange = function(value)
                data:SetDataByKey('font', value)
                EXUI:GetModule('options-reload-dialog'):ShowDialog()
            end,
            currentValue = function()
                return data:GetDataByKey('font')
            end,
            width = 33,
        }
    }
end

generalModule.UpdateUIScale = function(self)
    local uiScale = data:GetDataByKey('uiScale') or defaultUIScale
    UIParent:SetScale(uiScale)
end

-- Only called on load
generalModule.SetupUIScale = function(self)
    EXUI:RegisterEventHandler('PLAYER_ENTERING_WORLD', 'general-module', function(event, scale)
        EXUI:UnregisterEventHandler('PLAYER_ENTERING_WORLD', 'general-module')
        generalModule:UpdateUIScale()
    end)
    EXUI:RegisterEventHandler('UI_SCALE_CHANGED', 'general-module', function(event, scale)
        generalModule:UpdateUIScale()
    end)
    EXUI:RegisterEventHandler('DISPLAY_SIZE_CHANGED', 'general-module', function(event, scale)
        generalModule:UpdateUIScale()
    end)
end

generalModule.UpdatePaperDoll = function(self)

end

generalModule.paperDoll = {
    Init = function(self)
        if (not data:GetDataByKey('paperDollEnabled')) then return end
        local callback = function() 
            C_Timer.After(1, function() generalModule.paperDoll:Refresh() end)
            generalModule.paperDoll:Refresh()
        end
        EXUI:RegisterEventHandler('PLAYER_EQUIPMENT_CHANGED', 'paper-doll', callback)
        EXUI:RegisterEventHandler('PLAYER_ENTERING_WORLD', 'paper-doll', callback)
        EXUI:RegisterEventHandler('ENCHANT_SPELL_COMPLETED', 'paper-doll', callback)
        hooksecurefunc(CharacterFrame, 'Show', function() generalModule.paperDoll:Refresh() end)
        hooksecurefunc("PaperDollFrame_SetItemLevel", function() generalModule.paperDoll:Refresh() end)
    end,
    gearMap = {
        {
            -- Head
            frameName = 'CharacterHeadSlot',
            slotId = 1,
            point = 'BOTTOMLEFT',
            relativePoint = 'BOTTOMRIGHT',
            gemAlign = 'LEFT',
            maxWidth = 100,
            offsetX = 10,
            offsetY = 8
        },
        {
            -- Neck
            frameName = 'CharacterNeckSlot',
            slotId = 2,
            point = 'BOTTOMLEFT',
            relativePoint = 'BOTTOMRIGHT',
            gemAlign = 'LEFT',
            maxWidth = 100,
            offsetX = 10,
            offsetY = 8
        },
        {
            -- Shoulders
            frameName = 'CharacterShoulderSlot',
            slotId = 3,
            point = 'BOTTOMLEFT',
            relativePoint = 'BOTTOMRIGHT',
            gemAlign = 'LEFT',
            offsetX = 10,
            maxWidth = 100,
            offsetY = 8
        },
        {
            -- Cloak
            frameName = 'CharacterBackSlot',
            slotId = 15,
            point = 'BOTTOMLEFT',
            relativePoint = 'BOTTOMRIGHT',
            gemAlign = 'LEFT',
            maxWidth = 100,
            offsetX = 10,
            offsetY = 8
        },
        {
            -- Chest
            frameName = 'CharacterChestSlot',
            slotId = 5,
            point = 'BOTTOMLEFT',
            relativePoint = 'BOTTOMRIGHT',
            gemAlign = 'LEFT',
            maxWidth = 100,
            offsetX = 10,
            offsetY = 8
        },
        {
            -- Wrist
            frameName = 'CharacterWristSlot',
            slotId = 9,
            point = 'BOTTOMLEFT',
            relativePoint = 'BOTTOMRIGHT',
            gemAlign = 'LEFT',
            maxWidth = 100,
            offsetX = 10,
            offsetY = 8
        },
        {
            -- Hands
            frameName = 'CharacterHandsSlot',
            slotId = 10,
            point = 'BOTTOMRIGHT',
            relativePoint = 'BOTTOMLEFT',
            textAlign = 'RIGHT',
            maxWidth = 100,
            gemAlign = 'RIGHT',
            offsetX = -10,
            offsetY = 8
        },
        {
            -- Waist
            frameName = 'CharacterWaistSlot',
            slotId = 6,
            point = 'BOTTOMRIGHT',
            relativePoint = 'BOTTOMLEFT',
            textAlign = 'RIGHT',
            maxWidth = 100,
            gemAlign = 'RIGHT',
            offsetX = -10,
            offsetY = 8
        },
        {
            -- Legs
            frameName = 'CharacterLegsSlot',
            slotId = 7,
            point = 'BOTTOMRIGHT',
            relativePoint = 'BOTTOMLEFT',
            textAlign = 'RIGHT',
            maxWidth = 100,
            gemAlign = 'RIGHT',
            offsetX = -10,
            offsetY = 8
        },
        {
            -- Feet
            frameName = 'CharacterFeetSlot',
            slotId = 8,
            point = 'BOTTOMRIGHT',
            relativePoint = 'BOTTOMLEFT',
            textAlign = 'RIGHT',
            maxWidth = 100,
            gemAlign = 'RIGHT',
            offsetX = -10,
            offsetY = 8
        },
        {
            -- Ring 1
            frameName = 'CharacterFinger0Slot',
            slotId = 11,
            point = 'BOTTOMRIGHT',
            relativePoint = 'BOTTOMLEFT',
            textAlign = 'RIGHT',
            maxWidth = 100,
            gemAlign = 'RIGHT',
            offsetX = -10,
            offsetY = 8
        },
        {
            -- Ring 2
            frameName = 'CharacterFinger1Slot',
            slotId = 12,
            point = 'BOTTOMRIGHT',
            relativePoint = 'BOTTOMLEFT',
            textAlign = 'RIGHT',
            maxWidth = 100,
            gemAlign = 'RIGHT',
            offsetX = -10,
            offsetY = 8
        },
        {
            -- Trinket 1
            frameName = 'CharacterTrinket0Slot',
            slotId = 13,
            point = 'BOTTOMRIGHT',
            relativePoint = 'BOTTOMLEFT',
            textAlign = 'RIGHT',
            maxWidth = 100,
            gemAlign = 'RIGHT',
            offsetX = -10,
            offsetY = 8
        },
        {
            -- Trinket 2
            frameName = 'CharacterTrinket1Slot',
            slotId = 14,
            point = 'BOTTOMRIGHT',
            relativePoint = 'BOTTOMLEFT',
            textAlign = 'RIGHT',
            maxWidth = 100,
            gemAlign = 'RIGHT',
            offsetX = -10,
            offsetY = 8
        },
        {
            -- Weapon 1
            frameName = 'CharacterMainHandSlot',
            slotId = 16,
            point = 'BOTTOMRIGHT',
            relativePoint = 'BOTTOMLEFT',
            gemAlign = 'RIGHT',
            textAlign = 'RIGHT',
            maxWidth = 150,
            offsetX = -10,
            offsetY = 4
        },
        {
            -- Weapon 2
            frameName = 'CharacterSecondaryHandSlot',
            slotId = 17,
            point = 'BOTTOMLEFT',
            relativePoint = 'BOTTOMRIGHT',
            maxWidth = 150,
            gemAlign = 'LEFT',
            offsetX = 10,
            offsetY = 4
        },
    },
    replacements = {
        ['Critical Strike'] = 'Crit',
        ["Agility"] = 'Agi',
        ['Stamina'] = 'Stam',
        ['Strength'] = 'Str',
        ['Versatility'] = 'Vers',
        ['Waking Stats'] = 'Stats',
        ['Armor'] = 'Arm',
        ['Avoidance'] = 'Avoid',
        ['Shadowflame Wreathe'] = 'Shadowflame',
        ['Regenerative Leech'] = 'Leech',
        ['Authority of the Depths'] = 'Depths',
        ["Scout's March"] = 'Speed',
        ['Chant of Winged Grace'] = 'Avoid',
        ['Crystalline Radiance'] = 'Primary Stat'
    },
    Refresh = function(self)
        C_Timer.After(0.1, function() generalModule.paperDoll:ModifyLayout() end)
        for _, gearSlot in ipairs(self.gearMap) do
            if (not gearSlot.frame) then
                local baseFrame = CreateFrame('Frame', nil, _G[gearSlot.frameName])
                baseFrame:SetSize(1, 1)
                baseFrame:SetPoint(
                    gearSlot.point,
                    _G[gearSlot.frameName],
                    gearSlot.relativePoint,
                    gearSlot.offsetX,
                    gearSlot.offsetY
                )
                local ilvlText = EXUI.utils.createSimpleText('', 12, 'CENTER', baseFrame)
                local enchantText = EXUI.utils.createSimpleText('', 10, gearSlot.textAlign, baseFrame, gearSlot.maxWidth)
                local gemText = EXUI.utils.createSimpleText('', 12, gearSlot.textAlign, baseFrame)
                ilvlText:SetPoint('BOTTOM', _G[gearSlot.frameName], 0, 3)
                enchantText:SetPoint('BOTTOMLEFT')
                gemText:SetPoint(
                    gearSlot.gemAlign == 'LEFT' and 'BOTTOMLEFT' or 'BOTTOMRIGHT',
                    enchantText,
                    gearSlot.gemAlign == 'LEFT' and 'TOPLEFT' or 'TOPRIGHT',
                    0,
                    12
                )
    
                baseFrame.SetIlvlText = function(self, ilvl)
                    if (not ilvl) then
                        ilvlText:SetText('')
                        return
                    end
                    ilvlText:SetText(WrapTextInColorCode(ilvl, EXUI.utils.getIlvlColor(ilvl)))
                end
                baseFrame.SetEnchant = function(self, enchant)
                    if (not enchant) then
                        enchantText:SetText('')
                        return
                    end
                    enchantText:SetText(WrapTextInColorCode(enchant, 'ff98f907'))
                end
                baseFrame.SetGem = function(self, gem)
                    gemText:SetText(gem or '')
                end
    
                gearSlot.frame = baseFrame
            end
    
            local iLink = GetInventoryItemLink("player", gearSlot.slotId)
            if iLink then
                local ilvl = C_Item.GetDetailedItemLevelInfo(iLink)
                gearSlot.frame:SetIlvlText(ilvl)
                local enchant = EXUI.utils.GetItemEnchant(iLink)
                if (enchant) then
                    for pattern, replacement in pairs(self.replacements) do
                        enchant = string.gsub(enchant, pattern, replacement)
                    end
                end
                gearSlot.frame:SetEnchant(enchant and string.gsub(enchant, '|A.-|a', ''))
                gearSlot.frame:SetGem(self:GetGemString(iLink))
            else
                gearSlot.frame:SetIlvlText()
                gearSlot.frame:SetEnchant()
                gearSlot.frame:SetGem()
            end
        end
    
        local avgIlvl, avgEquipped = GetAverageItemLevel()
        local ilvlString = string.format('%.2f', avgEquipped)
        if (avgIlvl ~= avgEquipped) then
            ilvlString = string.format('%.2f / %.2f', avgEquipped, avgIlvl)
        end
        PaperDollFrame_SetLabelAndText(CharacterStatsPane.ItemLevelFrame, STAT_AVERAGE_ITEM_LEVEL, ilvlString, false, avgIlvl)
    end,
    ModifyLayout = function(self)
        CharacterFrame:SetWidth(700)
        CharacterFrameInset:SetPoint('BOTTOMRIGHT', CharacterFrame, 'BOTTOMLEFT', 498, 4)
        CharacterModelScene:SetWidth(439)
        CharacterModelFrameBackgroundTopLeft:SetWidth(396)
        CharacterModelFrameBackgroundTopLeft:SetHeight(320)
        CharacterModelFrameBackgroundTopLeft:SetTexture(EXUI.const.textures.paperDoll.charBg)
        CharacterModelFrameBackgroundTopLeft:SetDesaturation(0)
        CharacterModelFrameBackgroundBotLeft:Hide()
        CharacterModelFrameBackgroundOverlay:Hide()
        CharacterModelFrameBackgroundBotRight:Hide()
        if (CharacterModelScene and CharacterModelScene:GetActiveCamera()) then
            CharacterModelScene:GetActiveCamera():SetMaxZoomDistance(5.5)
        end
        CharacterMainHandSlot:SetPoint('BOTTOMLEFT', 234, 16)
    end,
    GetGemString = function(self, itemLink)
        local gems = EXUI.utils.GetItemGems(itemLink)
        local s = ''
        if (gems) then
            for _, gem in ipairs(gems) do
                s = s .. string.format('|T%s:0|t ', gem.icon)
            end
        end
        return s
    end
}


LSM:Register("font", 'DMSans', EXUI.const.fonts.DEFAULT)
generalModule.fonts = {
    Init = function(self)
        if (not data:GetDataByKey('replaceFonts')) then return end
        self:UpdateFonts()
    end,
    fontsToReplace = {
        _G.AchievementFont_Small,
        _G.FriendsFont_Large,
        _G.FriendsFont_Normal,
        _G.FriendsFont_Small,
        _G.FriendsFont_UserText,
        _G.GameTooltipHeader,
        _G.GameFont_Gigantic,
        _G.GameNormalNumberFont,
        _G.InvoiceFont_Med,
        _G.InvoiceFont_Small,
        _G.MailFont_Large,
        _G.NumberFont_OutlineThick_Mono_Small,
        _G.NumberFont_Outline_Huge,
        _G.NumberFont_Outline_Large,
        _G.NumberFont_Outline_Med,
        _G.NumberFont_Shadow_Med,
        _G.NumberFont_Shadow_Small,
        _G.QuestFont_Shadow_Small,
        _G.QuestFont_Large,
        _G.QuestFont_Shadow_Huge,
        _G.QuestFont_Super_Huge,
        _G.ReputationDetailFont,
        _G.SpellFont_Small,
        _G.SystemFont_InverseShadow_Small,
        _G.SystemFont_Large,
        _G.SystemFont_Med1,
        _G.SystemFont_Med2,
        _G.SystemFont_Med3,
        _G.SystemFont_OutlineThick_Huge2,
        _G.SystemFont_OutlineThick_Huge4,
        _G.SystemFont_OutlineThick_WTF,
        _G.SystemFont_Outline_Small,
        _G.SystemFont_Shadow_Huge1,
        _G.SystemFont_Shadow_Huge3,
        _G.SystemFont_Shadow_Large,
        _G.SystemFont_Shadow_Med1,
        _G.SystemFont_Shadow_Med2,
        _G.SystemFont_Shadow_Med3,
        _G.SystemFont_Shadow_Outline_Huge2,
        _G.SystemFont_Shadow_Small,
        _G.SystemFont_Small,
        _G.SystemFont_Tiny,
        _G.Tooltip_Med,
        _G.Tooltip_Small,
        _G.WhiteNormalNumberFont,
        _G.BossEmoteNormalHuge,
        _G.CombatTextFont,
        _G.ErrorFont,
        _G.QuestFontNormalSmall,
        _G.WorldMapTextFont,
        _G.ChatBubbleFont,
        _G.CoreAbilityFont,
        _G.DestinyFontHuge,
        _G.DestinyFontLarge,
        _G.Game18Font,
        _G.Game24Font,
        _G.Game27Font,
        _G.Game30Font,
        _G.Game32Font,
        _G.NumberFont_GameNormal,
        _G.NumberFont_Normal_Med,
        _G.QuestFont_Enormous,
        _G.QuestFont_Huge,
        _G.QuestFont_Super_Huge_Outline,
        _G.SplashHeaderFont,
        _G.SystemFont_Huge1,
        _G.SystemFont_Huge1_Outline,
        _G.SystemFont_Outline,
        _G.SystemFont_Shadow_Huge2,
        _G.SystemFont_Shadow_Large2,
        _G.SystemFont_Shadow_Large_Outline,
        _G.SystemFont_Shadow_Med1_Outline,
        _G.SystemFont_Shadow_Small2,
        _G.SystemFont_Small2,
        _G.SystemFont_NamePlate,
        _G.Game15Font_o1
    },
    UpdateFonts = function(self)
        local defaultFont = LSM:Fetch('font', data:GetDataByKey('font'))
        if (not defaultFont) then return end
        for _, font in ipairs(self.fontsToReplace) do
            local _, size, style = font:GetFont()
            font:SetFont(defaultFont, size, style)
        end
    end
}

generalModule.Refresh = function(self)
    if (data:GetDataByKey('bottomVignette')) then
        if (not self.bottomVignette) then
            self.bottomVignette = CreateFrame('Frame', nil, UIParent)
            self.bottomVignette:SetFrameStrata('BACKGROUND')
            self.bottomVignette:SetHeight(500)
            local texture = self.bottomVignette:CreateTexture(nil, 'BACKGROUND')
            texture:SetTexture(EXUI.const.textures.vignetteGradient)
            texture:SetAllPoints()
            texture:SetVertexColor(1, 1, 1, 0.8)

            self.bottomVignette:SetPoint('BOTTOMLEFT')
            self.bottomVignette:SetPoint('BOTTOMRIGHT')
        end
        self.bottomVignette:Show()
    elseif (self.bottomVignette) then
        self.bottomVignette:Hide()
    end
end