---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIPVEFrameSearchEntrySkin
local searchEntrySkin = EXUI:GetModule('skin-PVEFrame-searchEntry')

local SHEET_WIDTH = 1354
local SHEET_HEIGHT = 1312
local SPRITE_RECTS = {
    TANK = { 8, 1, 54, 55 },
    DAMAGER = { 56, 5, 102, 51 },
    HEALER = { 104, 5, 150, 51 },
    leader = { 152, 5, 200, 51 },
    entryBg = { 15, 56, 442, 129 },
    entryBorder = { 15, 137, 442, 210 },
    entryBgExpired = { 15, 218, 442, 291 },
    entryBorderHover = { 15, 299, 442, 372 },
    slotEmpty = { 453, 56, 482, 85 },
    slotBorder = { 493, 56, 522, 85 },
    plus = { 204, 7, 246, 49 },
    refresh = { 251, 9, 289, 47 },
    filter = { 294, 9, 334, 47 },
    panelBg = { 15, 380, 321, 937 },
    panelBorder = { 326, 372, 649, 946 },
    navDungeonBorder = { 716, 8, 950, 86 },
    navDungeonBg = { 709, 89, 957, 181 },
    navDungeonGlow = { 716, 181, 988, 331 },
    navRaidBorder = { 716, 341, 950, 419 },
    navRaidBg = { 709, 422, 957, 514 },
    navRaidGlow = { 716, 516, 988, 666 },
    navPremadeBorder = { 716, 679, 950, 757 },
    navPremadeBg = { 709, 763, 957, 855 },
    navPremadeGlow = { 716, 850, 988, 1000 },
    navQuickMatchBorder = { 1014, 8, 1248, 86 },
    navQuickMatchBg = { 1007, 89, 1255, 181 },
    navQuickMatchGlow = { 1014, 181, 1286, 331 },
    navRatedBorder = { 1014, 341, 1248, 419 },
    navRatedBg = { 1007, 422, 1255, 514 },
    navRatedGlow = { 1014, 516, 1286, 666 },
    navTrainingBorder = { 1014, 679, 1248, 757 },
    navTrainingBg = { 1007, 763, 1255, 855 },
    navTrainingGlow = { 1014, 850, 1286, 1000 },
}

local MAX_SLOTS = 5
local SLOT_SIZE = 22
local SLOT_GAP = 3
local GROUP_WIDTH = MAX_SLOTS * SLOT_SIZE + (MAX_SLOTS - 1) * SLOT_GAP
local GROUP_RIGHT = -7
local GROUP_TOP = -5
local NAME_LEFT = 10
local NAME_TOP = -7
local NAME_GROUP_GAP = 8
local VOICE_CHAT_WIDTH = 22

local NAME_SIZE = 15
local ACTIVITY_SIZE = 10
local PLAYSTYLE_SIZE = 9
local SPEC_ICON_ZOOM = 0.15
local BEST_SIZE = 9
local RATING_SIZE = 11
local ROLE_COUNT_ICON_SIZE = 17
local ROLE_COUNT_TEXT_SIZE = 12
local ROLE_COUNT_TEXT_WIDTH = 20

local OPEN_ROLE_ICON_SIZE = 10
local OPEN_ROLE_ICON_SHADE = 0.6
local OPEN_PLUS_ICON_SIZE = 14

-- Combatant / Challenger / Rival / Duelist / Elite rating floors, mapped to item quality colors.
local PVP_RATING_COLORS = {
    { 2400, Enum.ItemQuality.Legendary },
    { 2100, Enum.ItemQuality.Epic },
    { 1800, Enum.ItemQuality.Rare },
    { 1400, Enum.ItemQuality.Uncommon },
}

local ROLE_SEQUENCE = { 'TANK', 'HEALER', 'DAMAGER' }
local ROLE_SLOTS = { TANK = 1, HEALER = 1, DAMAGER = 3 }

local function GetTheme()
    return EXUI.const.theme
end

local function ApplySprite(texture, key)
    local rect = SPRITE_RECTS[key]
    texture:SetTexture(EXUI.const.textures.skins.lfgSprite)
    texture:SetTexCoord(rect[1] / SHEET_WIDTH, rect[3] / SHEET_WIDTH, rect[2] / SHEET_HEIGHT, rect[4] / SHEET_HEIGHT)
end

local function SetSpriteHeight(texture, key, height)
    local rect = SPRITE_RECTS[key]
    texture:SetSize(height * (rect[3] - rect[1]) / (rect[4] - rect[2]), height)
end

searchEntrySkin.ApplySprite = ApplySprite
searchEntrySkin.SetSpriteHeight = SetSpriteHeight

---Manual nine-slice of a sprite rect; corners keep `margin` sprite px drawn at `scale`, edges and center stretch.
function searchEntrySkin.CreateSpriteNineSlice(owner, key, margin, scale, layer, subLevel)
    local rect = SPRITE_RECTS[key]
    local xs = { rect[1], rect[1] + margin, rect[3] - margin, rect[3] }
    local ys = { rect[2], rect[2] + margin, rect[4] - margin, rect[4] }

    local pieces = {}
    for row = 1, 3 do
        for col = 1, 3 do
            local texture = owner:CreateTexture(nil, layer, nil, subLevel)
            texture:SetTexture(EXUI.const.textures.skins.lfgSprite)
            texture:SetTexCoord(xs[col] / SHEET_WIDTH, xs[col + 1] / SHEET_WIDTH, ys[row] / SHEET_HEIGHT,
                ys[row + 1] / SHEET_HEIGHT)
            pieces[#pieces + 1] = texture
        end
    end

    local slice = { pieces = pieces }

    function slice:SetPoints(region, outset)
        local size = margin * scale
        local tl, t, tr, l, c, r, bl, b, br = unpack(self.pieces)
        for _, piece in ipairs(self.pieces) do piece:ClearAllPoints() end

        tl:SetSize(size, size)
        tl:SetPoint('TOPLEFT', region, 'TOPLEFT', -outset, outset)
        tr:SetSize(size, size)
        tr:SetPoint('TOPRIGHT', region, 'TOPRIGHT', outset, outset)
        bl:SetSize(size, size)
        bl:SetPoint('BOTTOMLEFT', region, 'BOTTOMLEFT', -outset, -outset)
        br:SetSize(size, size)
        br:SetPoint('BOTTOMRIGHT', region, 'BOTTOMRIGHT', outset, -outset)

        t:SetPoint('TOPLEFT', tl, 'TOPRIGHT')
        t:SetPoint('BOTTOMRIGHT', tr, 'BOTTOMLEFT')
        b:SetPoint('TOPLEFT', bl, 'TOPRIGHT')
        b:SetPoint('BOTTOMRIGHT', br, 'BOTTOMLEFT')
        l:SetPoint('TOPLEFT', tl, 'BOTTOMLEFT')
        l:SetPoint('BOTTOMRIGHT', bl, 'TOPRIGHT')
        r:SetPoint('TOPLEFT', tr, 'BOTTOMLEFT')
        r:SetPoint('BOTTOMRIGHT', br, 'TOPRIGHT')
        c:SetPoint('TOPLEFT', tl, 'BOTTOMRIGHT')
        c:SetPoint('BOTTOMRIGHT', br, 'TOPLEFT')
    end

    function slice:SetShown(shown)
        for _, piece in ipairs(self.pieces) do piece:SetShown(shown) end
    end

    return slice
end

local function IsDeclined(appStatus)
    return appStatus == 'declined' or appStatus == 'declined_delisted' or appStatus == 'declined_full'
end

local function IsChatLockdown()
    return C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
end

local specIcons
local function GetSpecIcon(classFilename, specName)
    if (not specIcons) then
        specIcons = {}
        for classID = 1, GetNumClasses() do
            local _, classFile = GetClassInfo(classID)
            if (classFile) then
                local icons = {}
                specIcons[classFile] = icons
                for index = 1, GetNumSpecializationsForClassID(classID) do
                    for sex = 2, 3 do
                        local _, name, _, icon = GetSpecializationInfoForClassID(classID, index, sex)
                        if (name) then icons[name] = icon end
                    end
                end
            end
        end
    end

    local icons = specIcons[classFilename]
    return icons and specName and icons[specName]
end

local function SetMemberIcon(icon, member)
    local specIcon = GetSpecIcon(member.classFilename, member.specName)
    if (specIcon) then
        icon:SetTexture(specIcon)
        icon:SetTexCoord(SPEC_ICON_ZOOM, 1 - SPEC_ICON_ZOOM, SPEC_ICON_ZOOM, 1 - SPEC_ICON_ZOOM)
        return
    end

    local atlas = 'classicon-' .. string.lower(member.classFilename)
    if (C_Texture.GetAtlasInfo(atlas)) then
        icon:SetAtlas(atlas)
    else
        icon:SetTexture(nil)
    end
end

local function CreateSlot(parent, index)
    -- Snap size and step to whole pixels so every slot renders at the same square size.
    local size = EXUI:ScalePixel(SLOT_SIZE, parent)
    local step = EXUI:ScalePixel(SLOT_SIZE + SLOT_GAP, parent)

    local slot = CreateFrame('Frame', nil, parent)
    slot:SetSize(size, size)
    slot:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', -(MAX_SLOTS - index) * step, 0)

    local bg = slot:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    ApplySprite(bg, 'slotEmpty')

    local icon = slot:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    local mask = slot:CreateMaskTexture()
    mask:SetAllPoints()
    mask:SetTexture(EXUI.const.textures.skins.lfgSpecMask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)
    slot.Icon = icon

    local open = slot:CreateTexture(nil, 'ARTWORK')
    open:SetPoint('CENTER')
    slot.Open = open

    local border = slot:CreateTexture(nil, 'ARTWORK', nil, 2)
    border:SetAllPoints()
    ApplySprite(border, 'slotBorder')

    local leader = slot:CreateTexture(nil, 'OVERLAY')
    leader:SetPoint('TOPLEFT', slot, 'TOPLEFT', -4, 4)
    ApplySprite(leader, 'leader')
    SetSpriteHeight(leader, 'leader', 9)
    slot.Leader = leader

    return slot
end

local function SetFont(fontString, size)
    fontString:SetFont(EXUI.const.fonts.DEFAULT, size, 'OUTLINE')
    fontString:SetShadowColor(0, 0, 0, 0)
end

local function UpdateBorder(button)
    local hovered = button:IsMouseOver() or button.isSelected
    ApplySprite(button.exuiBorder, hovered and 'entryBorderHover' or 'entryBorder')
end

local function SkinRoleCount(roleCount)
    if (not roleCount) then return end

    for key, role in pairs({ TankIcon = 'TANK', HealerIcon = 'HEALER', DamagerIcon = 'DAMAGER' }) do
        local icon = roleCount[key]
        if (icon) then
            ApplySprite(icon, role)
            SetSpriteHeight(icon, role, ROLE_COUNT_ICON_SIZE)
        end
    end

    for _, key in ipairs({ 'TankCount', 'HealerCount', 'DamagerCount' }) do
        local count = roleCount[key]
        if (count) then
            count:SetFont(EXUI.const.fonts.DEFAULT, ROLE_COUNT_TEXT_SIZE, 'OUTLINE')
            count:SetShadowColor(0, 0, 0, 0)
            count:SetWidth(ROLE_COUNT_TEXT_WIDTH)
        end
    end
end

local function SkinEntry(button)
    if (button.exuiEntrySkinned) then return end
    button.exuiEntrySkinned = true

    SkinRoleCount(button.DataDisplay.RoleCount)

    button.ResultBG:SetAlpha(0)
    button.BackgroundTexture:SetAlpha(0)
    button.Highlight:SetAlpha(0)

    local bg = button:CreateTexture(nil, 'BACKGROUND', nil, -1)
    bg:SetPoint('TOPLEFT', button, 'TOPLEFT', 3, -2)
    bg:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -3, 0)
    button.exuiBg = bg

    local border = button:CreateTexture(nil, 'BORDER')
    border:SetAllPoints(bg)
    button.exuiBorder = border

    SetFont(button.Name, NAME_SIZE)
    button.Name:SetHeight(NAME_SIZE + 3)
    button.Name:ClearAllPoints()
    button.Name:SetPoint('TOPLEFT', button, 'TOPLEFT', NAME_LEFT, NAME_TOP)

    SetFont(button.ActivityName, ACTIVITY_SIZE)
    button.ActivityName:SetHeight(ACTIVITY_SIZE + 2)

    SetFont(button.Playstyle, PLAYSTYLE_SIZE)
    button.Playstyle:SetHeight(PLAYSTYLE_SIZE + 2)
    button.Playstyle:SetTextColor(unpack(GetTheme().textMuted))

    local group = CreateFrame('Frame', nil, button)
    group:SetSize(EXUI:ScalePixel(GROUP_WIDTH, button), EXUI:ScalePixel(SLOT_SIZE, button))
    group:SetPoint('TOPRIGHT', button, 'TOPRIGHT', EXUI:ScalePixel(GROUP_RIGHT, button), EXUI:ScalePixel(GROUP_TOP, button))
    group.Slots = {}
    for i = 1, MAX_SLOTS do
        group.Slots[i] = CreateSlot(group, i)
    end

    local best = group:CreateFontString(nil, 'OVERLAY')
    SetFont(best, BEST_SIZE)
    best:SetPoint('TOPRIGHT', group, 'BOTTOMRIGHT', 0, -2)
    best:SetJustifyH('RIGHT')
    best:SetTextColor(unpack(GetTheme().white))
    group.Best = best

    local rating = group:CreateFontString(nil, 'OVERLAY')
    SetFont(rating, RATING_SIZE)
    rating:SetPoint('TOPRIGHT', best, 'BOTTOMRIGHT', 0, 0)
    rating:SetJustifyH('RIGHT')
    group.Rating = rating

    button.exuiGroup = group

    button:HookScript('OnEnter', UpdateBorder)
    button:HookScript('OnLeave', UpdateBorder)
end

local function IsExpired(button, resultID, searchResultInfo)
    if (button.isNowFilteredOut or searchResultInfo.isDelisted) then return true end

    local _, appStatus, pendingStatus = C_LFGList.GetApplicationInfo(resultID)
    if (IsDeclined(appStatus)) then return true end
    if (LFGListFrame.declines and LFGListFrame.declines[searchResultInfo.partyGUID]) then return true end
    return LFGListUtil_IsStatusInactive(appStatus) or LFGListUtil_IsStatusInactive(pendingStatus)
end

local function ApplyTitleColor(name)
    local r, g, b = name:GetTextColor()
    local normal = NORMAL_FONT_COLOR
    if (math.abs(r - normal.r) < 0.01 and math.abs(g - normal.g) < 0.01 and math.abs(b - normal.b) < 0.01) then
        name:SetTextColor(unpack(GetTheme().white))
    end
end

local function CapTextWidths(button, searchResultInfo)
    local maxWidth = button:GetWidth() - NAME_LEFT - GROUP_WIDTH + GROUP_RIGHT - NAME_GROUP_GAP
    button.ActivityName:SetWidth(maxWidth)

    if (searchResultInfo.voiceChat ~= '') then
        maxWidth = maxWidth - VOICE_CHAT_WIDTH
    end
    if (button.Name:GetWidth() > maxWidth) then
        button.Name:SetWidth(maxWidth)
    end
end

---Members ordered tank > healer > dps, with open spots filled by the roles still missing.
local function BuildSlotEntries(resultID, numMembers)
    local byRole = { TANK = {}, HEALER = {}, DAMAGER = {} }
    local others = {}
    local memberCount = 0
    for i = 1, numMembers do
        local member = C_LFGList.GetSearchResultPlayerInfo(resultID, i)
        if (member) then
            local list = byRole[member.assignedRole] or others
            list[#list + 1] = member
            memberCount = memberCount + 1
        end
    end

    local entries = {}
    local openSpots = MAX_SLOTS - memberCount
    for _, role in ipairs(ROLE_SEQUENCE) do
        local members = byRole[role]
        for _, member in ipairs(members) do
            entries[#entries + 1] = member
        end
        for _ = #members + 1, ROLE_SLOTS[role] do
            if (openSpots <= 0) then break end
            entries[#entries + 1] = { openRole = role }
            openSpots = openSpots - 1
        end
    end
    for _, member in ipairs(others) do
        entries[#entries + 1] = member
    end
    return entries
end

---Arena groups have no fixed roles; members in listing order, open spots shown as a plus.
local function BuildArenaSlotEntries(resultID, numMembers, numSlots)
    local entries = {}
    for i = 1, numMembers do
        local member = C_LFGList.GetSearchResultPlayerInfo(resultID, i)
        if (member) then
            entries[#entries + 1] = member
        end
    end
    for _ = #entries + 1, numSlots do
        entries[#entries + 1] = { openIcon = 'plus' }
    end
    return entries
end

---Slots fill from the right, so fewer than MAX_SLOTS stay right-aligned.
local function UpdateSlots(group, entries, numSlots)
    local offset = MAX_SLOTS - numSlots

    for i, slot in ipairs(group.Slots) do
        local entry = i > offset and entries[i - offset]
        slot:SetShown(i > offset)

        local openIcon = entry and (entry.openRole or entry.openIcon)
        if (openIcon) then
            local isPlus = entry.openIcon ~= nil
            local shade = isPlus and 1 or OPEN_ROLE_ICON_SHADE
            ApplySprite(slot.Open, openIcon)
            SetSpriteHeight(slot.Open, openIcon, isPlus and OPEN_PLUS_ICON_SIZE or OPEN_ROLE_ICON_SIZE)
            slot.Open:SetVertexColor(shade, shade, shade)
            slot.Open:Show()
        else
            slot.Open:Hide()
        end

        if (entry and not openIcon) then
            SetMemberIcon(slot.Icon, entry)
            slot.Icon:Show()
            slot.Leader:SetShown(entry.isLeader)
        else
            slot.Icon:Hide()
            slot.Leader:Hide()
        end
    end
end

local function UpdateDungeonScore(group, searchResultInfo, activityInfo)
    if (not activityInfo.isMythicPlusActivity) then
        group.Best:Hide()
        group.Rating:Hide()
        return
    end

    local dungeonScore = searchResultInfo.leaderDungeonScoreInfo and searchResultInfo.leaderDungeonScoreInfo[1]
    if (dungeonScore and dungeonScore.bestRunLevel > 0) then
        group.Best:SetFormattedText('Best: %d', dungeonScore.bestRunLevel)
        group.Best:Show()
    else
        group.Best:Hide()
    end

    local score = searchResultInfo.leaderOverallDungeonScore or 0
    local color = C_ChallengeMode.GetDungeonScoreRarityColor(score) or HIGHLIGHT_FONT_COLOR
    group.Rating:SetText(score)
    group.Rating:SetTextColor(color.r, color.g, color.b)
    group.Rating:Show()
end

local function GetPvpRatingColor(rating)
    for _, band in ipairs(PVP_RATING_COLORS) do
        if (rating >= band[1]) then
            return ITEM_QUALITY_COLORS[band[2]]
        end
    end
    return HIGHLIGHT_FONT_COLOR
end

local function UpdatePvpRating(group, searchResultInfo, activityInfo)
    local ratingInfo = searchResultInfo.leaderPvpRatingInfo and searchResultInfo.leaderPvpRatingInfo[1]
    if (not activityInfo.isRatedPvpActivity or not ratingInfo) then
        group.Best:Hide()
        group.Rating:Hide()
        return
    end

    local tierName = PVPUtil and PVPUtil.GetTierName(ratingInfo.tier)
    group.Best:SetText(tierName or '')
    group.Best:SetShown(tierName ~= nil)

    local color = GetPvpRatingColor(ratingInfo.rating)
    group.Rating:SetText(ratingInfo.rating)
    group.Rating:SetTextColor(color.r, color.g, color.b)
    group.Rating:Show()
end

local function IsArenaActivity(activityInfo)
    return activityInfo.isPvpActivity and activityInfo.maxNumPlayers > 0 and activityInfo.maxNumPlayers <= MAX_SLOTS
end

local function UpdateEntry(button)
    local resultID = button.resultID
    if (not resultID or not C_LFGList.HasSearchResultInfo(resultID)) then return end

    SkinEntry(button)
    UpdateBorder(button)

    local group = button.exuiGroup
    if (IsChatLockdown()) then
        ApplySprite(button.exuiBg, 'entryBg')
        group:Hide()
        button.DataDisplay:SetAlpha(1)
        return
    end

    local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
    ApplySprite(button.exuiBg, IsExpired(button, resultID, searchResultInfo) and 'entryBgExpired' or 'entryBg')
    ApplyTitleColor(button.Name)

    local activityInfo = C_LFGList.GetActivityInfoTable(searchResultInfo.activityIDs[1])
    local isDungeon = LFGListFrame.CategorySelection.selectedCategory == GROUP_FINDER_CATEGORY_ID_DUNGEONS
    local isArena = activityInfo and IsArenaActivity(activityInfo)
    if (not activityInfo or not (isDungeon or isArena) or not button.DataDisplay:IsShown()) then
        group:Hide()
        button.DataDisplay:SetAlpha(1)
        return
    end

    button.DataDisplay:SetAlpha(0)
    CapTextWidths(button, searchResultInfo)
    if (isArena) then
        local numSlots = activityInfo.maxNumPlayers
        UpdateSlots(group, BuildArenaSlotEntries(resultID, searchResultInfo.numMembers, numSlots), numSlots)
        UpdatePvpRating(group, searchResultInfo, activityInfo)
    else
        UpdateSlots(group, BuildSlotEntries(resultID, searchResultInfo.numMembers), MAX_SLOTS)
        UpdateDungeonScore(group, searchResultInfo, activityInfo)
    end
    group:Show()
end

function searchEntrySkin:Install()
    if (self.installed or type(LFGListSearchEntry_Update) ~= 'function') then return end
    self.installed = true

    hooksecurefunc('LFGListSearchEntry_Update', UpdateEntry)
end
