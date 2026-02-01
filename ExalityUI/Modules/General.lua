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

generalModule.GetOrder = function(self)
    return 10
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
            onChange = function(value)
                data:SetDataByKey('uiScale', value)
                EXUI:GetModule('options-reload-dialog'):ShowDialog()
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
            color = { 219 / 255, 73 / 255, 0, 1 }
        },
        {
            label = 'Paper Doll Improvements',
            name = 'paperDollEnabled',
            type = 'toggle',
            onChange = function(value)
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
            onChange = function(value)
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
            onChange = function(value)
                data:SetDataByKey('bottomVignette', value)
                generalModule:Refresh()
            end,
            currentValue = function()
                return data:GetDataByKey('bottomVignette')
            end,
            width = 100,
        },
        {
            label = 'Replacement Font',
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
    EXUI:GetModule('pixel-perfect'):Initialize()
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
        PaperDollFrame_SetLabelAndText(CharacterStatsPane.ItemLevelFrame, STAT_AVERAGE_ITEM_LEVEL, ilvlString, false,
            avgIlvl)
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


generalModule.fonts = {
    Init = function(self)
        if (not data:GetDataByKey('replaceFonts')) then return end
        self:UpdateFonts()
    end,
    fontsToReplace = {
        "SystemFont_Shadow_Small_Outline",
        "SystemFont_Shadow_Small2_Outline",
        "SystemFont_Shadow_Med3_Outline",
        "QuestFont_30",
        "SystemFont_Shadow_Med2_Outline",
        "SystemFont_Large2",
        "SystemFont_Outline_Slug_Large2",
        "SystemFont_Shadow_Large2_Outline",
        "Game17Font_Shadow",
        "SystemFont_Shadow_Huge1_Outline",
        "SystemFont_Shadow_Huge2_Outline",
        "SystemFont22_Outline",
        "SystemFont16_Shadow_ThickOutline",
        "SystemFont18_Shadow_ThickOutline",
        "SystemFont22_Shadow_ThickOutline",
        "Game36Font_Shadow2",
        "Game46Font_Shadow2",
        "Game52Font_Shadow2",
        "Game58Font_Shadow2",
        "Game69Font_Shadow2",
        "Game72Font_Shadow",
        "FriendsFont_11",
        "FriendsFont_UserText",
        "NumberFont_Shadow_Tiny",
        "NumberFont_Shadow_Small",
        "NumberFont_Shadow_Med",
        "NumberFont_Shadow_Large",
        "NumberFont_Normal_Med",
        "NumberFont_Outline_Med",
        "NumberFont_Outline_Large",
        "SystemFont_Tiny2",
        "SystemFont_Tiny",
        "SystemFont_Shadow_Small",
        "SystemFont_Shadow_Outline_Small",
        "Game10Font_o1",
        "SystemFont_Small",
        "SystemFont_Small2",
        "SystemFont_Shadow_Small2",
        "SystemFont_Shadow_Med1_Outline",
        "SystemFont_Shadow_Med1",
        "SystemFont_Shadow_Med2",
        "SystemFont_Outline_Med2",
        "SystemFont_Med2",
        "SystemFont_Med3",
        "SystemFont_Shadow_Med3",
        "SystemFont_Large",
        "SystemFont_Shadow_Outline_Large",
        "SystemFont_Shadow_Large_Outline",
        "SystemFont_Shadow_Large",
        "SystemFont_Shadow_Large2",
        "SystemFont_Shadow_Huge1",
        "SystemFont_Huge2",
        "SystemFont_Outline_Slug_Huge2",
        "SystemFont_Shadow_Huge2",
        "SystemFont_Shadow_Huge3",
        "SystemFont_Shadow_Outline_Huge3",
        "SystemFont_Huge4",
        "SystemFont_Shadow_Huge4",
        "SystemFont_Shadow_Huge4_Outline",
        "SystemFont_World",
        "SystemFont_World_ThickOutline",
        "SystemFont_Med1",
        "SystemFont_WTF2",
        "SystemFont_Outline_WTF2",
        "SystemFont22_Shadow_Outline",
        "GameTooltipHeader",
        "System_IME",
        "QuestFont_Large",
        "QuestFont_Huge",
        "QuestFont_Shadow_Huge",
        "QuestFont_39",
        "ChatFontSmall",
        "ChatFontNormal",
        "ConsoleFontSmall",
        "ConsoleFontNormal",
        "Tooltip_Med",
        "Tooltip_Small",
        "System15Font",
        "Game16Font",
        "Game22Font",
        "Game30Font",
        "Game32Font_Shadow2",
        "Game40Font_Shadow2",
        "Game60Font",
        "Game72Font",
        "FriendsFont_Small",
        "FriendsFont_Normal",
        "FriendsFont_Large",
        "UserScaledFontSystem_Header",
        "UserScaledFontSystem_Body",
        "SystemFont_InverseShadow_Small",
        "SystemFont_Huge1",
        "SystemFont_Huge1_Outline",
        "SystemFont_Huge1_Outline_Slug",
        "SystemFont_OutlineThick_Huge2",
        "SystemFont_OutlineThick_Huge4",
        "SystemFont_OutlineThick_WTF",
        "SystemFont_NamePlateFixed",
        "SystemFont_LargeNamePlateFixed",
        "SystemFont_NamePlate",
        "SystemFont_LargeNamePlate",
        "SystemFont_NamePlateCastBar",
        "NumberFont_GameNormal",
        "Number12Font",
        "NumberFont_Outline_Huge",
        "QuestFont_Shadow_Small",
        "QuestFont_Outline_Huge",
        "QuestFont_Super_Huge",
        "QuestFont_Super_Huge_Outline",
        "QuestFont_Enormous",
        "Game11Font",
        "Game12Font",
        "Game13Font",
        "Game13FontShadow",
        "Game15Font",
        "Game18Font",
        "Game20Font",
        "Game24Font",
        "Game27Font",
        "Game32Font",
        "Game36Font",
        "Game42Font",
        "Game46Font",
        "Game48Font",
        "Game48FontShadow",
        "Game120Font",
        "Game11Font_o1",
        "Game12Font_o1",
        "Game13Font_o1",
        "Game15Font_o1",
        "Fancy12Font",
        "Fancy14Font",
        "Fancy16Font",
        "Fancy18Font",
        "Fancy20Font",
        "Fancy22Font",
        "Fancy24Font",
        "Fancy27Font",
        "Fancy30Font",
        "Fancy32Font",
        "Fancy48Font",
        "SplashHeaderFont",
        "ChatBubbleFont",
        "DestinyFontMed",
        "DestinyFontLarge",
        "DestinyFontHuge",
        "CoreAbilityFont",
        "SpellFont_Small",
        "InvoiceFont_Med",
        "InvoiceFont_Small",
        "AchievementFont_Small",
        "ReputationDetailFont",
        "GameFont_Gigantic",
        "SystemFont_Outline_Small",
        "SystemFont_Outline",
        "PriceFont",
        "NumberFont_OutlineThick_Mono_Small",
        "NumberFont_Small",
        "Number11Font",
        "Number12FontOutline",
        "Number13Font",
        "Number15Font",
        "Number16Font",
        "Number18Font",
        "Number12Font_o1",
        "QuestFont_Shadow_Super_Huge",
        "QuestFont_Shadow_Enormous",
        "Game11Font_Shadow",
        "Game15Font_Shadow",
        "Game19Font",
        "Game21Font",
        "Game40Font",
        "Fancy36Font",
        "Fancy40Font",
        "OrderHallTalentRowFont",
        "MailFont_Large",
        "GlueFontNormalExtraSmall",
        "GlueFontHighlightExtraSmall",
        "GlueFontDisableExtraSmall",
        "GlueFontNormal",
        "GlueFontHighlight",
        "GlueFontDisable",
        "GlueFontNormalLarge",
        "GlueFontHighlightLarge",
        "GlueFontDisableLarge",
        "QuestTitleFont",
        "QuestFont",
        "GameFontNormal",
        "GameFontNormalLeft",
        "GameFontNormalSmall",
        "GameFontNormalSmallLeft",
        "GameFontHighlight",
        "GameFontRed",
        "GameFontGreen",
        "GameFontHighlightLeft",
        "GameFontHighlightCenter",
        "GameFontHighlightRight",
        "CombatLogFont",
        "ObjectiveFont",
        "GameFontDisable",
        "GameFontDisableLeft",
        "GameFontHighlightSmall",
        "GameFontHighlightSmallRight",
        "GameFontHighlightExtraSmall",
        "GameFontHighlightSmallLeft",
        "GameFontHighlightSmallLeftTop",
        "GameFontHighlightExtraSmallLeft",
        "GameFontHighlightExtraSmallLeftTop",
        "GameFontHighlightSmallOutline",
        "GameFontDisableSmall",
        "GameFontDarkGraySmall",
        "GameFontGreenSmall",
        "GameFontRedSmall",
        "GameFontNormalSmallBattleNetBlueLeft",
        "GameFontDisableSmallLeft",
        "GameFontDisableSmall2",
        "GameFontNormalLeftBottom",
        "GameFontNormalLeftGreen",
        "GameFontNormalLeftYellow",
        "GameFontNormalLeftOrange",
        "GameFontNormalLeftLightGreen",
        "GameFontNormalLeftGrey",
        "GameFontNormalLeftLightGrey",
        "GameFontNormalLeftLightBlue",
        "GameFontNormalLeftRed",
        "GameFontNormalLarge",
        "GameFontWhiteLarge",
        "GameFontNormalLarge2",
        "GameFontNormalLargeOutline",
        "GameFontNormalLargeLeft",
        "GameFontNormalLargeLeftTop",
        "GameFontRedLarge",
        "GameFontHighlightLarge",
        "GameFontDisableLarge",
        "GameFontHighlightLarge2",
        "GameFontNormal_NoShadow",
        "GameFontNormalHuge",
        "GameFontHighlightHuge",
        "GameFontDisableHuge",
        "GameFontNormalTiny",
        "GameFontWhiteTiny",
        "GameFontDisableTiny",
        "GameFontBlackTiny",
        "GameFontNormalTiny2",
        "GameFontWhiteTiny2",
        "GameFontDisableTiny2",
        "GameFontBlackTiny2",
        "GameFontNormalMed1",
        "GameFontNormalMed2",
        "GameFontNormalOutline",
        "GameFontHighlightOutline",
        "GameFontHighlightMedium",
        "GameFontBlackMedium",
        "GameFontBlackSmall",
        "GameFontBlack",
        "GameFontWhite",
        "GameFontHighlightMed2",
        "GameFontNormalMed3",
        "GameFontHighlightSmall2",
        "GameFontBlackSmall2",
        "GameFontNormalSmall2",
        "GameFontNormalWTF2",
        "GameFontNormalWTF2Outline",
        "GameFontNormalHuge2",
        "GameFontNormalShadowHuge2",
        "GameFontNormalHuge3",
        "GameFontNormalHuge3Outline",
        "GameFontNormalHuge4",
        "GameFontNormalHuge4Outline",
        "GameTooltipHeaderText",
        "GameTooltipText",
        "GameTooltipTextSmall",
        "IMENormal",
        "IMEHighlight",
        "MovieSubtitleFont",
        "QuestDifficulty_Impossible",
        "QuestDifficulty_VeryDifficult",
        "QuestDifficulty_Difficult",
        "QuestDifficulty_Standard",
        "QuestDifficulty_Trivial",
        "QuestDifficulty_Header",
        "LFGActivityHeader",
        "LFGActivityEntry",
        "LFGActivityEntryTrivial",
        "LFGActivityEntryDifficult",
        "CharacterCreateTooltipFont",
        "Number14FontWhite",
        "Number14FontGray",
        "NumberFontNormal",
        "NumberFontNormalRight",
        "NumberFontNormalRightRed",
        "NumberFontNormalRightYellow",
        "NumberFontNormalRightGray",
        "NumberFontNormalYellow",
        "UserScaledFontBody",
        "UserScaledFontHeader",
        "UserScaledFontGlueNormal",
        "UserScaledFontGlueDisable",
        "UserScaledFontGlueHighlight",
        "UserScaledFontGlueNormalLarge",
        "UserScaledFontGlueNormalExtraSmall",
        "UserScaledFontGameNormal",
        "UserScaledFontGameDisable",
        "UserScaledFontGameHighlight",
        "UserScaledFontGameHighlightRight",
        "UserScaledFontGameNormalSmall",
        "UserScaledFontGameDisableSmall",
        "UserScaledFontGameHighlightSmall",
        "UserScaledFontGameNormalLarge",
        "UserScaledChatFontNormal",
        "UserScaledFontNumberNormalRight",
        "UserScaledFontNumberNormalRightRed",
        "UserScaledFontNumberNormalRightYellow",
        "UserScaledFontNumberNormalRightGray",
        "GameFontHighlight_NoShadow",
        "GameFontNormalSmallOutline",
        "GameFontNormalMed2Outline",
        "GameFontNormalShadowOutline22",
        "GameFontHighlightShadowOutline22",
        "QuestFontNormalLarge",
        "QuestFontNormalHuge",
        "QuestFontHighlightHuge",
        "GameFontWhiteSmall",
        "GameFontHighlightMed2Outline",
        "GameFontNormalMed3Outline",
        "GameFontDisableMed3",
        "GameFontDisableMed2",
        "GameFontHighlightHuge2",
        "GameFontNormalHuge2Outline",
        "GameFontHighlightShadowHuge2",
        "GameFontNormalOutline22",
        "GameFontHighlightOutline22",
        "GameFontDisableOutline22",
        "GameFontNormalHugeOutline",
        "GameFontHighlightHugeOutline",
        "GameFont72Normal",
        "GameFont72Highlight",
        "GameFont72NormalShadow",
        "GameFont72HighlightShadow",
        "NumberFontNormalLarge",
        "NumberFontNormalLargeRight",
        "NumberFontNormalLargeRightRed",
        "NumberFontNormalLargeRightYellow",
        "NumberFontNormalLargeRightGray",
        "NumberFontNormalRightGreen",
        "NumberFontSmallYellowLeft",
        "NumberFontSmallWhiteLeft",
        "NumberFontSmallBattleNetBlueLeft",
        "Number11FontWhite",
        "Number13FontRed",
        "PriceFontYellow",
        "Number14FontGreen",
        "Number14FontRed",
        "Number18FontWhite",
        "TextStatusBarText",
        "MissionCombatTextFontOutline",
        "GameFontGreenLarge",
        "GameFontNormalHugeBlack",
        "BossEmoteNormalHuge",
        "NumberFontNormalSmall",
        "NumberFontNormalSmallGray",
        "NumberFontNormalHuge",
        "Number13FontWhite",
        "Number13FontYellow",
        "Number13FontGray",
        "NumberFontNormalGray",
        "NumberFontNormalLargeYellow",
        "PriceFontWhite",
        "PriceFontGray",
        "PriceFontRed",
        "PriceFontGreen",
        "Number15FontWhite",
        "QuestFontLeft",
        "QuestFontNormalSmall",
        "ItemTextFontNormal",
        "MailTextFontNormal",
        "SubSpellFont",
        "NewSubSpellFont",
        "DialogButtonNormalText",
        "DialogButtonHighlightText",
        "ZoneTextFont",
        "SubZoneTextFont",
        "PVPInfoTextFont",
        "ErrorFont",
        "GameNormalNumberFont",
        "WhiteNormalNumberFont",
        "TextStatusBarTextLarge",
        "WorldMapTextFont",
        "InvoiceTextFontNormal",
        "InvoiceTextFontSmall",
        "CombatTextFont",
        "CombatTextFontOutline",
        "AchievementPointsFont",
        "AchievementPointsFontSmall",
        "AchievementDescriptionFont",
        "AchievementCriteriaFont",
        "AchievementDateFont",
        "VehicleMenuBarStatusBarText",
        "FocusFontSmall",
        "ArtifactAppearanceSetNormalFont",
        "ArtifactAppearanceSetHighlightFont",
        "CommentatorTeamScoreFont",
        "CommentatorDampeningFont",
        "CommentatorTeamNameFont",
        "CommentatorCCFont",
        "CommentatorFontSmall",
        "CommentatorFontMedium",
        "CommentatorVictoryFanfare",
        "CommentatorVictoryFanfareTeam",
        "QuestTitleFontBlackShadow",
        "OptionsFontSmall",
        "OptionsFontHighlightSmall",
        "OptionsFontHighlight",
        "OptionsFontLarge",
        "OptionsFontLeft",
        "QuestMapRewardsFont",
        "ScrollingMessageFrame",
        "table: 000001FB9485EC20",
        "table: 000001FB9488C0C0",
        "table: 000001FB9489C980",
        "table: 000001FB9489F130",
        "table: 000001FB948A19D0",
        "table: 000001FB948A6280",
        "table: 000001FB948A8B20",
        "table: 000001FB948AB3C0",
        "table: 000001FB948ADC60",
        "table: 000001FB948B2510",
        "table: 000001FC48DF4000",
        "table: 000001FBAB5E9BE0",
        "ObjectiveTrackerFont12",
        "ObjectiveTrackerFont13",
        "ObjectiveTrackerFont14",
        "ObjectiveTrackerFont15",
        "ObjectiveTrackerFont16",
        "ObjectiveTrackerFont17",
        "ObjectiveTrackerFont18",
        "ObjectiveTrackerFont19",
        "ObjectiveTrackerFont20",
        "ObjectiveTrackerFont21",
        "ObjectiveTrackerFont22",
        "ObjectiveTrackerLineFont",
        "ObjectiveTrackerHeaderFont",
    },
    UpdateFonts = function(self)
        local defaultFont = LSM:Fetch('font', data:GetDataByKey('font'))
        if (not defaultFont) then return end
        for _, font in ipairs(self.fontsToReplace) do
            if (type(font) == 'string') then
                font = _G[font]
            end
            if (type(font) == 'table') then
                local _, size, style = font:GetFont()
                if (size > 0) then
                    font:SetFont(defaultFont, size, style)
                end
            end
        end
    end
}

generalModule.Refresh = function(self)
    local showBottomVignette = data:GetDataByKey('bottomVignette')
    if (showBottomVignette) then
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
