---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesSmoothScrollFrame
local scrollConstruct = EXFrames:GetFrame('smooth-scroll-frame')

---@class ExalityFramesSimpleButton
local simpleButton = EXFrames:GetFrame('simple-button')

---@class EXUICustomWindows
local customWindows = EXUI:GetModule('custom-windows')

---@class EXUIQuestLogWindow
local questLog = EXUI:GetModule('quest-log-window')

questLog.enabled = false
questLog.isCreated = false
questLog.suppressHook = false
questLog.selectedQuestID = nil

local MAP_HEIGHT_DEFAULT = 533
local MAP_HEIGHT_MIN = 400
local MAP_HEIGHT_MAX = 1100
questLog.mapHeightDefault = MAP_HEIGHT_DEFAULT
questLog.mapHeightMin = MAP_HEIGHT_MIN
questLog.mapHeightMax = MAP_HEIGHT_MAX
local QUEST_WIDTH = 300
local DETAIL_WIDTH = 300
local GAP = 5
local PAD = 10
local HEADER_HEIGHT = 28
local CAMPAIGN_HEADER_HEIGHT = 51
local ROW_GAP = 4
local TITLE_SIZE = 13
local DETAIL_TITLE_SIZE = 16
local LINE_SIZE = 12
local REWARD_ROW_HEIGHT = 26
local REWARD_ROW_GAP = 4
local BINDING_COMMANDS = { 'TOGGLEWORLDMAP', 'TOGGLEQUESTLOG' }

local function MapHeight()
    local height = customWindows.Data:GetValue('QuestLogMapHeight')
    if (type(height) ~= 'number') then
        return MAP_HEIGHT_DEFAULT
    end
    if (height < MAP_HEIGHT_MIN) then
        return MAP_HEIGHT_MIN
    end
    if (height > MAP_HEIGHT_MAX) then
        return MAP_HEIGHT_MAX
    end
    return height
end

local function MapWidth()
    return math.floor(MapHeight() * 3 / 2 + 0.5)
end

local MAP_TEXTURE = [[Interface/Addons/ExalityUI/Assets/Images/Map/map-canvas.png]]
local MAP_ZOOM_WHEEL_FACTOR = 1.15
local CLOSE_TEXTURE = [[Interface/Addons/ExalityUI/Assets/Images/Map/close-icon.png]]
local HOME_TEXTURE = [[Interface/Addons/ExalityUI/Assets/Images/Map/home-icon.png]]
local CAMPAIGN_MASK = [[Interface/Addons/ExalityUI/Assets/Images/Map/campaign-header.png]]

local ATLAS_W, ATLAS_H = 472, 329
local SLICE = 4
local RECTS = {
    eyeOff = { 1, 1, 52, 52 },
    eye = { 55, 5, 112, 48 },
    chevronUp = { 226, 14, 263, 39 },
    chevronDown = { 266, 15, 303, 40 },
    simpleBg = { 6, 117, 199, 140 },
    simpleBorderOff = { 6, 144, 199, 167 },
    simpleGlowOff = { 6, 171, 135, 194 },
    simpleGlowOn = { 6, 225, 135, 248 },
}

local hookedGlobals = {}

local function Theme()
    return EXUI.const.theme
end

local function FontPath()
    return EXFrames.assets.font.default()
end

local function IsReadable(value)
    if (value == nil) then
        return false
    end
    if (issecretvalue and issecretvalue(value)) then
        return false
    end
    if (canaccessvalue and not canaccessvalue(value)) then
        return false
    end
    return true
end

local function SameID(a, b)
    if (not IsReadable(a) or not IsReadable(b)) then
        return false
    end
    return a == b
end

local function SetLineText(fontString, text)
    local ok = pcall(fontString.SetText, fontString, text or '')
    if (not ok) then
        fontString:SetText('')
    end
end

local function StringHeight(fontString, fallback)
    local ok, height = pcall(fontString.GetStringHeight, fontString)
    if (ok and type(height) == 'number' and height > 1) then
        return height
    end
    return fallback
end

local function ApplyAtlas(tex, key, sliced)
    local rect = RECTS[key]
    if (not rect) then
        return
    end
    local left, top, right, bottom = rect[1], rect[2], rect[3], rect[4]
    tex:SetTexture(EXFrames.assets.textures.splitOptions.atlas)
    if (sliced and EXFrames.utils and EXFrames.utils.texture and EXFrames.utils.texture.applySlice) then
        EXFrames.utils.texture.applySlice(tex, SLICE, tex:GetParent(), Enum.UITextureSliceMode.Stretched)
    elseif (sliced) then
        tex:SetTextureSliceMargins(SLICE, SLICE, SLICE, SLICE)
        tex:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    end
    tex:SetTexCoord(left / ATLAS_W, (right + 1) / ATLAS_W, top / ATLAS_H, (bottom + 1) / ATLAS_H)
end

local function SetAtlasIcon(tex, key, height)
    ApplyAtlas(tex, key, false)
    local rect = RECTS[key]
    local sourceWidth = rect[3] - rect[1] + 1
    local sourceHeight = rect[4] - rect[2] + 1
    tex:SetSize(height * (sourceWidth / sourceHeight), height)
end

local OPEN_POINT = { 'TOPLEFT', 'TOPLEFT', 20, -150 }
local QUEST_BG_ALPHA = 0.88
local CANVAS_CORNER = 5

local function PanelMask(frame, slice)
    local mask = frame:CreateMaskTexture()
    mask:SetAllPoints()
    mask:SetTexture(MAP_TEXTURE, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    if (slice) then
        mask:SetTextureSliceMargins(slice, slice, slice, slice)
        mask:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    end
    return mask
end

local function ApplyMapChrome(frame)
    local fill = frame:CreateTexture(nil, 'BACKGROUND')
    fill:SetAllPoints()
    fill:SetColorTexture(0, 0, 0, 1)
    fill:AddMaskTexture(PanelMask(frame))
end

local function CreateCloseButton(parent, onClick)
    local theme = Theme()
    local close = CreateFrame('Button', nil, parent)
    close:SetSize(18, 18)
    close:SetFrameLevel(parent:GetFrameLevel() + 20)
    local icon = close:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    icon:SetTexture(CLOSE_TEXTURE)
    icon:SetVertexColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    close:SetScript('OnEnter', function()
        icon:SetVertexColor(theme.dangerHover[1], theme.dangerHover[2], theme.dangerHover[3], 1)
    end)
    close:SetScript('OnLeave', function()
        icon:SetVertexColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    end)
    close:SetScript('OnClick', onClick)
    return close
end

local function ApplyQuestChrome(frame)
    local theme = Theme()
    local fill = frame:CreateTexture(nil, 'BACKGROUND')
    fill:SetAllPoints()
    fill:SetColorTexture(theme.backgroundDeep[1], theme.backgroundDeep[2], theme.backgroundDeep[3], QUEST_BG_ALPHA)
    fill:AddMaskTexture(PanelMask(frame, CANVAS_CORNER))
end

local function AddPinLevel(manager, name, range)
    if (range == nil) then
        manager:AddFrameLevel(name)
    else
        manager:AddFrameLevel(name, range)
    end
end

local PROVIDER_MIXINS = {
    'MapExplorationDataProviderMixin',
    'MapHighlightDataProviderMixin',
    'WorldMap_EventOverlayDataProviderMixin',
    'QuestOfferDataProviderMixin',
    'BattlefieldFlagDataProviderMixin',
    'BonusObjectiveDataProviderMixin',
    'VehicleDataProviderMixin',
    'EncounterJournalDataProviderMixin',
    'FogOfWarDataProviderMixin',
    'DeathMapDataProviderMixin',
    'QuestBlobDataProviderMixin',
    'ScenarioDataProviderMixin',
    'VignetteDataProviderMixin',
    'QuestDataProviderMixin',
    'ContentTrackingDataProviderMixin',
    'InvasionDataProviderMixin',
    'GossipDataProviderMixin',
    'FlightPointDataProviderMixin',
    'PetTamerDataProviderMixin',
    'DigSiteDataProviderMixin',
    'GarrisonPlotDataProviderMixin',
    'DungeonEntranceDataProviderMixin',
    'DelveEntranceDataProviderMixin',
    'BannerDataProvider',
    'ContributionCollectorDataProviderMixin',
    'MapLinkDataProviderMixin',
    'SelectableGraveyardDataProviderMixin',
    'AreaPOIDataProviderMixin',
    'AreaPOIEventDataProviderMixin',
    'QuestSessionDataProviderMixin',
    'WaypointLocationDataProviderMixin',
    'DragonridingRaceDataProviderMixin',
    'SuperTrackWaypointDataProviderMixin',
    'NeighborhoodMapDataProviderMixin',
}

local function GuardCombatMethod(owner, methodName)
    if (not owner or type(owner[methodName]) ~= 'function') then
        return
    end
    local original = owner[methodName]
    local function guarded(self, ...)
        if (InCombatLockdown()) then
            return
        end
        return original(self, ...)
    end
    owner[methodName] = guarded
    for _, value in pairs(_G) do
        if (type(value) == 'table') then
            local ok, method = pcall(function()
                return value[methodName]
            end)
            if (ok and method == original) then
                value[methodName] = guarded
            end
        end
    end
end

local function AddProvider(canvas, mixin, configure)
    if (not mixin) then
        return
    end
    local ok, provider = pcall(CreateFromMixins, mixin)
    if (not ok or not provider) then
        return
    end
    if (configure) then
        pcall(configure, provider)
    end
    pcall(canvas.AddDataProvider, canvas, provider)
end

local function InstallPinLevels(canvas)
    local manager = canvas:GetPinFrameLevelsManager()
    if (not manager) then
        return
    end

    local names = {
        'PIN_FRAME_LEVEL_WOW_LABS_AREA',
        'PIN_FRAME_LEVEL_MAP_EXPLORATION',
        'PIN_FRAME_LEVEL_PLUNDERSTORM_CIRCLE',
        'PIN_FRAME_LEVEL_EVENT_OVERLAY',
        'PIN_FRAME_LEVEL_GARRISON_PLOT',
        'PIN_FRAME_LEVEL_FOG_OF_WAR',
        'PIN_FRAME_LEVEL_QUEST_BLOB',
        'PIN_FRAME_LEVEL_SCENARIO_BLOB',
        'PIN_FRAME_LEVEL_MAP_HIGHLIGHT',
    }
    for _, name in ipairs(names) do
        AddPinLevel(manager, name)
    end
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_DEBUG', 4)

    local afterDebug = {
        'PIN_FRAME_LEVEL_DIG_SITE',
        'PIN_FRAME_LEVEL_DUNGEON_ENTRANCE',
        'PIN_FRAME_LEVEL_DELVE_ENTRANCE',
        'PIN_FRAME_LEVEL_FLIGHT_POINT',
        'PIN_FRAME_LEVEL_NEIGHBORHOOD_MAP_OBJECTS',
        'PIN_FRAME_LEVEL_INVASION',
        'PIN_FRAME_LEVEL_PET_TAMER',
        'PIN_FRAME_LEVEL_SELECTABLE_GRAVEYARD',
        'PIN_FRAME_LEVEL_DRAGONRIDING_RACE',
        'PIN_FRAME_LEVEL_AREA_POI',
        'PIN_FRAME_LEVEL_GOSSIP',
        'PIN_FRAME_LEVEL_MAP_LINK',
        'PIN_FRAME_LEVEL_ENCOUNTER',
        'PIN_FRAME_LEVEL_CONTRIBUTION_COLLECTOR',
    }
    for _, name in ipairs(afterDebug) do
        AddPinLevel(manager, name)
    end

    AddPinLevel(manager, 'PIN_FRAME_LEVEL_VIGNETTE', 200)
    local offerRange = QuestOfferDataProviderMixin and QuestOfferDataProviderMixin.PIN_LEVEL_RANGE
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_QUEST_OFFER', offerRange)
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_SCENARIO')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_BONUS_OBJECTIVE')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_WORLD_QUEST', 500)
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_AREA_POI_EVENT')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_QUEST_PING')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_TRACKED_CONTENT')

    local questRange = 35
    if (C_QuestLog.GetMaxNumQuests) then
        local ok, maxQuests = pcall(C_QuestLog.GetMaxNumQuests)
        if (ok and type(maxQuests) == 'number') then
            questRange = maxQuests
        end
    end
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_ACTIVE_QUEST', questRange)
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_SUPER_TRACKED_CONTENT')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_SUPER_TRACKED_QUEST')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_VEHICLE_BELOW_GROUP_MEMBER')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_BATTLEFIELD_FLAG')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_WAYPOINT_LOCATION')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_GROUP_MEMBER')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_VEHICLE_ABOVE_GROUP_MEMBER')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_CORPSE')
    AddPinLevel(manager, 'PIN_FRAME_LEVEL_AREA_POI_BANNER')
end

local function InstallProviders(canvas)
    if (C_GameRules and C_GameRules.IsGameRuleActive(Enum.GameRule.MapPlunderstormCircle)) then
        AddProvider(canvas, PlunderstormCircleDataProviderMixin)
    end

    for _, name in ipairs(PROVIDER_MIXINS) do
        AddProvider(canvas, _G[name])
    end

    if (WoWLabsAreaDataProviderMixin and C_GameRules and C_GameRules.IsGameRuleActive(Enum.GameRule.PlunderstormAreaSelection)) then
        AddProvider(canvas, WoWLabsAreaDataProviderMixin)
    end

    AddProvider(canvas, AreaLabelDataProviderMixin)
    AddProvider(canvas, GroupMembersDataProviderMixin)
    AddProvider(canvas, WorldMap_WorldQuestDataProviderMixin, function(provider)
        provider:SetMatchWorldMapFilters(true)
        provider:SetUsesSpellEffect(true)
        provider:SetCheckBounties(true)
    end)
end

local function AddWidgetLine(tooltip, text)
    if (IsReadable(text)) then
        if (text == '') then
            return
        end
        pcall(GameTooltip_AddNormalLine, tooltip, text, true)
        return
    end
    if (issecretvalue and issecretvalue(text)) then
        pcall(GameTooltip_AddNormalLine, tooltip, text, true)
    end
end

local function AppendBulletLines(tooltip, lines)
    pcall(function()
        for _, line in ipairs(lines) do
            AddWidgetLine(tooltip, line)
        end
    end)
end

local function AppendOneWidget(tooltip, widget, vis)
    local widgetID = widget.widgetID
    local widgetType = widget.widgetType
    if (widgetType == vis.TextWithState) then
        local infoOk, info = pcall(C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo, widgetID)
        if (infoOk and info) then
            AddWidgetLine(tooltip, info.text)
        end
    elseif (widgetType == vis.TextWithSubtext) then
        local infoOk, info = pcall(C_UIWidgetManager.GetTextWithSubtextWidgetVisualizationInfo, widgetID)
        if (infoOk and info) then
            AddWidgetLine(tooltip, info.text)
            AddWidgetLine(tooltip, info.subText)
        end
    elseif (widgetType == vis.IconAndText) then
        local infoOk, info = pcall(C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo, widgetID)
        if (infoOk and info) then
            AddWidgetLine(tooltip, info.text)
        end
    elseif (widgetType == vis.BulletTextList) then
        local infoOk, info = pcall(C_UIWidgetManager.GetBulletTextListWidgetVisualizationInfo, widgetID)
        if (infoOk and info) then
            AppendBulletLines(tooltip, info.lines)
        end
    end
end

local function TooltipOwnerIsOurMap(tooltip)
    local canvas = questLog.canvas
    if (not canvas or not tooltip or not tooltip.GetOwner) then
        return false
    end
    local ok, owner = pcall(tooltip.GetOwner, tooltip)
    if (not ok or not owner) then
        return false
    end
    if (owner == canvas) then
        return true
    end
    if (owner.GetMap) then
        local mapOk, map = pcall(owner.GetMap, owner)
        if (mapOk and map == canvas) then
            return true
        end
    end
    local parent = owner
    for _ = 1, 15 do
        if (not parent.GetParent) then
            return false
        end
        local parentOk, nextParent = pcall(parent.GetParent, parent)
        if (not parentOk or not nextParent) then
            return false
        end
        if (nextParent == canvas) then
            return true
        end
        parent = nextParent
    end
    return false
end

local function AppendWidgetLines(tooltip, widgetSetID)
    if (tooltip.widgetContainer) then
        tooltip.widgetContainer:Hide()
    end
    if (not IsReadable(widgetSetID) or not C_UIWidgetManager or not C_UIWidgetManager.GetAllWidgetsBySetID) then
        return
    end
    local ok, widgets = pcall(C_UIWidgetManager.GetAllWidgetsBySetID, widgetSetID)
    if (not ok or not IsReadable(widgets)) then
        return
    end
    local vis = Enum and Enum.UIWidgetVisualizationType
    if (not vis) then
        return
    end
    pcall(function()
        for _, widget in ipairs(widgets) do
            pcall(AppendOneWidget, tooltip, widget, vis)
        end
    end)
end

local function InstallWidgetTooltip()
    if (questLog.widgetTooltipWrapped or type(GameTooltip_AddWidgetSet) ~= 'function') then
        return
    end
    questLog.widgetTooltipWrapped = true
    local original = GameTooltip_AddWidgetSet
    GameTooltip_AddWidgetSet = function(tooltip, widgetSetID, verticalPadding)
        if (TooltipOwnerIsOurMap(tooltip)) then
            pcall(AppendWidgetLines, tooltip, widgetSetID)
            return
        end
        return original(tooltip, widgetSetID, verticalPadding)
    end
end

questLog.CreateMap = function(self, host)
    local canvas = CreateFrame('Frame', nil, host)
    canvas:SetAllPoints()
    canvas:Hide()
    self.canvas = canvas

    local border = CreateFrame('Frame', nil, canvas)
    border:SetAllPoints()
    border:EnableMouse(false)
    border:EnableMouseWheel(false)
    canvas.BorderFrame = border

    local scroll = CreateFrame('ScrollFrame', nil, canvas, 'MapCanvasFrameScrollContainerTemplate')
    canvas.ScrollContainer = canvas.ScrollContainer or scroll
    scroll:ClearAllPoints()
    scroll:SetAllPoints(canvas)
    scroll:HookScript('OnMouseDown', function(self, button)
        if (button == 'LeftButton' and not (self.CanPan and self:CanPan())) then
            self.windowDragWatch = true
        end
    end)
    scroll:HookScript('OnMouseUp', function(self, button)
        if (button ~= 'LeftButton') then
            return
        end
        self.windowDragWatch = false
        if (self.draggingWindow) then
            self.draggingWindow = false
            if (questLog.window) then
                questLog.window:StopMovingOrSizing()
            end
        end
    end)
    scroll:HookScript('OnUpdate', function(self)
        local info = self.mouseButtonInfo and self.mouseButtonInfo.LeftButton
        if (self.draggingWindow) then
            if (not IsMouseButtonDown('LeftButton')) then
                self.draggingWindow = false
                self.windowDragWatch = false
                if (info) then
                    info.down = false
                end
                if (questLog.window) then
                    questLog.window:StopMovingOrSizing()
                end
            end
            return
        end
        if (not self.windowDragWatch or not info or not info.down) then
            return
        end
        if ((self.CanPan and self:CanPan()) or not IsMouseButtonDown('LeftButton')) then
            self.windowDragWatch = false
            return
        end
        local x, y = self:GetCursorPosition()
        if (not self:WouldCursorPositionBeClick('LeftButton', x, y) and questLog.window) then
            self.windowDragWatch = false
            self.draggingWindow = true
            questLog.window:StartMoving()
        end
    end)

    Mixin(canvas, MapCanvasMixin)
    canvas:OnLoad()
    if (not questLog.pinCombatGuarded) then
        questLog.pinCombatGuarded = true
        GuardCombatMethod(MapCanvasPinMixin, 'CheckMouseButtonPassthrough')
        GuardCombatMethod(SuperTrackablePinMixin, 'UpdateMousePropagation')
    end

    canvas:SetScript('OnEvent', function(self, event, ...)
        MapCanvasMixin.OnEvent(self, event, ...)
    end)
    canvas:SetScript('OnUpdate', function(self)
        MapCanvasMixin.OnUpdate(self)
    end)
    canvas:SetScript('OnShow', function(self)
        MapCanvasMixin.OnShow(self)
    end)
    canvas:SetScript('OnHide', function(self)
        MapCanvasMixin.OnHide(self)
    end)
    canvas:SetScript('OnSizeChanged', function(self)
        if (self.OnFrameSizeChanged) then
            self:OnFrameSizeChanged()
        end
    end)

    canvas.SetMapID = function(self, mapID)
        if (mapID and C_QuestLog.SetMapForQuestPOIs) then
            pcall(C_QuestLog.SetMapForQuestPOIs, mapID)
        end
        MapCanvasMixin.SetMapID(self, mapID)
        questLog:UpdateReturnButton()
    end

    canvas.OnMapChanged = function(self)
        MapCanvasMixin.OnMapChanged(self)
    end

    canvas:SetShouldZoomInOnClick(false)
    canvas:SetShouldPanOnClick(false)
    canvas:SetShouldNavigateOnClick(true)
    canvas:SetShouldZoomInstantly(true)

    scroll:SetScalingMode('SCALING_MODE_LINEAR')
    scroll.normalizedZoomLerpAmount = 0.2
    scroll.normalizedPanXLerpAmount = 0.2
    scroll.normalizedPanYLerpAmount = 0.2
    if (MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_NONE) then
        scroll:SetMouseWheelZoomMode(MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_NONE)
    end
    scroll:SetScript('OnMouseWheel', function(self, delta)
        if (not self:HasZoomLevels() or not delta or delta == 0) then
            return
        end
        local currentScale = self:GetCanvasScale()
        local minScale = self:GetScaleForMinZoom()
        local maxScale = self:GetScaleForMaxZoom()
        local nextScale = Clamp((self.targetScale or currentScale) * (MAP_ZOOM_WHEEL_FACTOR ^ delta), minScale, maxScale)
        if (nextScale == (self.targetScale or currentScale)) then
            return
        end

        local cursorX, cursorY = self:GetCursorPosition()
        local childLeft = self.Child and self.Child:GetLeft()
        local childTop = self.Child and self.Child:GetTop()
        if (not cursorX or not childLeft or not childTop or currentScale == 0) then
            self:SetZoomTarget(nextScale)
            return
        end

        local normalizedCursorX = self:NormalizeHorizontalSize(cursorX / currentScale - childLeft)
        local normalizedCursorY = self:NormalizeVerticalSize(childTop - cursorY / currentScale)
        local scaleRatio = currentScale / nextScale
        local panX = Lerp(normalizedCursorX, self:GetCurrentScrollX() or 0.5, scaleRatio)
        local panY = Lerp(normalizedCursorY, self:GetCurrentScrollY() or 0.5, scaleRatio)
        local minX, maxX, minY, maxY = self:CalculateScrollExtentsAtScale(nextScale)
        self:SetZoomTarget(nextScale)
        self:SetPanTarget(Clamp(panX, minX, maxX), Clamp(panY, minY, maxY))
    end)

    InstallPinLevels(canvas)
    InstallProviders(canvas)

    -- Mask before the first SetMapID so detail tiles pick it up.
    local mask = scroll:CreateMaskTexture()
    mask:SetAllPoints(scroll)
    mask:SetTexture(MAP_TEXTURE, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    canvas:SetMaskTexture(mask)
    canvas:SetUseMaskTexture(true)

    canvas:Hide()
    self.canvas = canvas
    InstallWidgetTooltip()
end

local function HandyNotesProvider()
    local addon = _G.HandyNotes
    if (type(addon) ~= 'table') then
        return nil
    end
    return addon.WorldMapDataProvider
end

questLog.AttachHandyNotes = function(self)
    local provider = HandyNotesProvider()
    local canvas = self.canvas
    if (not provider or not canvas or not canvas.AddDataProvider) then
        return
    end
    local owner = provider.GetMap and provider:GetMap()
    if (owner == canvas) then
        return
    end
    if (owner and owner.RemoveDataProvider) then
        self.handyNotesRestore = (owner == WorldMapFrame)
        local removed = pcall(owner.RemoveDataProvider, owner, provider)
        if (not removed) then
            return
        end
    else
        self.handyNotesRestore = false
    end
    local added = pcall(canvas.AddDataProvider, canvas, provider)
    if (added and provider.RefreshAllData) then
        pcall(provider.RefreshAllData, provider)
    end
end

questLog.DetachHandyNotes = function(self)
    local provider = HandyNotesProvider()
    local canvas = self.canvas
    if (provider and canvas and canvas.RemoveDataProvider and provider.GetMap and provider:GetMap() == canvas) then
        pcall(canvas.RemoveDataProvider, canvas, provider)
    end
    if (self.handyNotesRestore and provider and WorldMapFrame and WorldMapFrame.AddDataProvider) then
        local onBlizzard = WorldMapFrame.dataProviders and WorldMapFrame.dataProviders[provider]
        if (not onBlizzard) then
            pcall(WorldMapFrame.AddDataProvider, WorldMapFrame, provider)
        end
    end
    self.handyNotesRestore = false
end

local HBD_PIN_TEMPLATE = 'HereBeDragonsPinsTemplate'

local function HereBeDragonsPins()
    if (not LibStub) then
        return nil
    end
    local ok, lib = pcall(LibStub, 'HereBeDragons-Pins-2.0', true)
    if (not ok or type(lib) ~= 'table') then
        return nil
    end
    return lib
end

questLog.AttachHereBeDragons = function(self)
    local lib = HereBeDragonsPins()
    local canvas = self.canvas
    local provider = lib and lib.worldmapProvider
    local pool = lib and lib.worldmapPinsPool
    if (not provider or not pool or not canvas or not canvas.AddDataProvider or not canvas.GetCanvas) then
        return
    end
    local pinParent = canvas:GetCanvas()
    if (not pinParent) then
        return
    end
    if (not self.hbdCreateFunc) then
        self.hbdCreateFunc = pool.createFunc
        self.hbdPoolParent = pool.parent
    end
    local original = self.hbdCreateFunc
    pool.parent = pinParent
    pool.createFunc = function()
        local frame = original()
        local parent = questLog.canvas and questLog.canvas.GetCanvas and questLog.canvas:GetCanvas()
        if (frame and parent) then
            frame:SetParent(parent)
        end
        return frame
    end
    pool.creationFunc = pool.createFunc
    canvas.pinPools[HBD_PIN_TEMPLATE] = pool

    local owner = provider.GetMap and provider:GetMap()
    if (owner == canvas) then
        if (provider.RefreshAllData) then
            pcall(provider.RefreshAllData, provider)
        end
        return
    end
    if (owner and owner.RemoveDataProvider) then
        self.hbdRestore = (owner == WorldMapFrame)
        local removed = pcall(owner.RemoveDataProvider, owner, provider)
        if (not removed) then
            pool.createFunc = original
            pool.creationFunc = original
            pool.parent = self.hbdPoolParent
            self.hbdCreateFunc = nil
            self.hbdPoolParent = nil
            canvas.pinPools[HBD_PIN_TEMPLATE] = nil
            return
        end
    else
        self.hbdRestore = false
    end
    local added = pcall(canvas.AddDataProvider, canvas, provider)
    if (added and provider.RefreshAllData) then
        pcall(provider.RefreshAllData, provider)
    end
end

questLog.DetachHereBeDragons = function(self)
    local lib = HereBeDragonsPins()
    local canvas = self.canvas
    local provider = lib and lib.worldmapProvider
    local pool = lib and lib.worldmapPinsPool
    if (provider and canvas and canvas.RemoveDataProvider and provider.GetMap and provider:GetMap() == canvas) then
        pcall(canvas.RemoveDataProvider, canvas, provider)
    end
    if (canvas and canvas.pinPools) then
        canvas.pinPools[HBD_PIN_TEMPLATE] = nil
    end
    if (pool and self.hbdCreateFunc) then
        pool.createFunc = self.hbdCreateFunc
        pool.creationFunc = self.hbdCreateFunc
        pool.parent = self.hbdPoolParent
        self.hbdCreateFunc = nil
        self.hbdPoolParent = nil
    end
    if (self.hbdRestore and provider and WorldMapFrame and WorldMapFrame.AddDataProvider) then
        local onBlizzard = WorldMapFrame.dataProviders and WorldMapFrame.dataProviders[provider]
        if (not onBlizzard) then
            pcall(WorldMapFrame.AddDataProvider, WorldMapFrame, provider)
        end
        if (provider.RefreshAllData and WorldMapFrame:IsShown()) then
            pcall(provider.RefreshAllData, provider)
        end
    end
    self.hbdRestore = false
end

local function QuestMapID(questID)
    if (type(GetQuestUiMapID) == 'function') then
        local ok, mapID = pcall(GetQuestUiMapID, questID)
        if (ok and IsReadable(mapID) and mapID ~= 0) then
            return mapID
        end
    end
    if (C_QuestLog.GetNextWaypoint) then
        local ok, mapID = pcall(C_QuestLog.GetNextWaypoint, questID)
        if (ok and IsReadable(mapID) and mapID ~= 0) then
            return mapID
        end
    end
end

questLog.UpdateReturnButton = function(self)
    local button = self.returnButton
    if (not button) then
        return
    end
    local viewing = nil
    if (self.canvas and self.canvas.GetMapID) then
        viewing = self.canvas:GetMapID()
    end
    local here = self:PlayerMapID()
    local away = IsReadable(viewing) and IsReadable(here) and here ~= 0 and not SameID(viewing, here)
    button:SetShown(away and true or false)
end

questLog.ShowMap = function(self, mapID)
    if (not self.canvas or not mapID) then
        return
    end
    self.canvas:SetMapID(mapID)
end

questLog.PlayerMapID = function(self)
    if (MapUtil and MapUtil.GetDisplayableMapForPlayer) then
        local mapID = MapUtil.GetDisplayableMapForPlayer()
        if (IsReadable(mapID) and mapID ~= 0) then
            return mapID
        end
    end
    if (C_Map.GetBestMapForUnit) then
        return C_Map.GetBestMapForUnit('player')
    end
end

-- Records the player's map; returns it only when it differs from the last one seen.
questLog.TrackPlayerMap = function(self)
    local mapID = self:PlayerMapID()
    if (not IsReadable(mapID) or mapID == 0 or SameID(mapID, self.playerMapID)) then
        return nil
    end
    self.playerMapID = mapID
    return mapID
end

questLog.ApplyPendingMap = function(self)
    local mapID = self.pendingMapID
    self.pendingMapID = nil
    local moved = self:TrackPlayerMap()
    if (not mapID) then
        if (self.canvas and self.canvas.mapID and not moved) then
            return
        end
        mapID = moved or self:PlayerMapID()
    end
    self:ShowMap(mapID)
end

questLog.FollowPlayerMap = function(self)
    local mapID = self:TrackPlayerMap()
    if (mapID) then
        self:ShowMap(mapID)
    else
        self:UpdateReturnButton()
    end
end

questLog.PingQuest = function(self, questID)
    if (not questID or not EventRegistry) then
        return
    end
    C_Timer.After(0, function()
        if (questLog.window and questLog.window:IsShown() and SameID(questLog.selectedQuestID, questID)) then
            EventRegistry:TriggerEvent('MapCanvas.PingQuestID', questID)
        end
    end)
end

local function HookGlobal(name)
    local target = _G[name]
    if (type(target) ~= 'function' or hookedGlobals[name] == target) then
        return
    end
    hooksecurefunc(name, function(...)
        questLog:OnBlizzardOpen(...)
    end)
    hookedGlobals[name] = target
end

questLog.InstallHooks = function(self)
    if (not C_AddOns.IsAddOnLoaded('Blizzard_WorldMap')) then
        return
    end
    HookGlobal('ToggleWorldMap')
    HookGlobal('ToggleQuestLog')
    HookGlobal('OpenWorldMap')
    HookGlobal('OpenQuestLog')
end

questLog.OnBlizzardOpen = function(self, mapID)
    if (not self.enabled or self.suppressHook) then
        return
    end
    if (InCombatLockdown() and WorldMapFrame and WorldMapFrame:IsShown()) then
        return
    end
    if (IsReadable(mapID) and mapID ~= 0) then
        self.pendingMapID = mapID
    end
    self:Show()
end

questLog.HideBlizzardMap = function(self)
    if (InCombatLockdown() or self.suppressHook) then
        return
    end
    if (WorldMapFrame and WorldMapFrame:IsShown()) then
        self.suppressHook = true
        HideUIPanel(WorldMapFrame)
        self.suppressHook = false
    end
end

questLog.EnsureBindingButton = function(self)
    if (self.bindingButton) then
        return
    end
    local button = CreateFrame('Button', 'EXUIQuestLogBindingButton', UIParent)
    button:SetSize(1, 1)
    button:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)
    button:SetAlpha(0)
    button:EnableMouse(false)
    button:SetScript('OnClick', function()
        questLog:Toggle()
    end)
    button:Show()
    self.bindingButton = button
end

questLog.ApplyBindings = function(self)
    if (not self.bindingButton) then
        return
    end
    if (InCombatLockdown()) then
        self.bindingsDirty = true
        return
    end
    self.bindingsDirty = false
    ClearOverrideBindings(self.bindingButton)
    if (not self.enabled) then
        return
    end
    for _, command in ipairs(BINDING_COMMANDS) do
        local keys = { GetBindingKey(command) }
        for _, key in ipairs(keys) do
            if (key) then
                SetOverrideBindingClick(self.bindingButton, true, key, 'EXUIQuestLogBindingButton')
            end
        end
    end
end

questLog.ShouldShowQuest = function(self, info)
    if (info.isHidden or info.isInternalOnly or info.isTask) then
        return false
    end
    if (info.isBounty) then
        local ok, complete = pcall(C_QuestLog.IsComplete, info.questID)
        if (not ok or not IsReadable(complete)) then
            return true
        end
        return complete and true or false
    end
    return true
end

local IsCampaignHeader

questLog.BuildEntries = function(self)
    local entries = {}
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    local pendingHeader = nil
    local pendingIndex = nil
    local headerShown = false

    local function FlushHeader()
        if (pendingHeader and not headerShown and IsCampaignHeader(pendingHeader)) then
            entries[#entries + 1] = { info = pendingHeader, isHeader = true, logIndex = pendingIndex }
        end
        pendingHeader = nil
        pendingIndex = nil
        headerShown = false
    end

    for index = 1, numEntries do
        local info = C_QuestLog.GetInfo(index)
        if (info and info.isHeader) then
            FlushHeader()
            pendingHeader = info
            pendingIndex = index
        elseif (info and pendingHeader and self:ShouldShowQuest(info)) then
            if (not headerShown) then
                entries[#entries + 1] = { info = pendingHeader, isHeader = true, logIndex = pendingIndex }
                headerShown = true
            end
            if (not pendingHeader.isCollapsed) then
                entries[#entries + 1] = { info = info, isHeader = false }
            end
        end
    end

    FlushHeader()
    return entries
end

IsCampaignHeader = function(info)
    if (not info or not info.isHeader or info.useMinimalHeader) then
        return false
    end
    if (Enum and Enum.QuestClassification and info.questClassification == Enum.QuestClassification.Campaign) then
        return info.campaignID ~= nil
    end
    return info.campaignID ~= nil and info.campaignID ~= 0
end

local function CampaignObject(info)
    local campaignID = info and info.campaignID
    if (campaignID == nil) then
        return nil
    end
    if (CampaignCache and CampaignCache.Get) then
        local ok, campaign = pcall(CampaignCache.Get, CampaignCache, campaignID)
        if (ok and campaign) then
            return campaign
        end
    end
    if (C_CampaignInfo and C_CampaignInfo.GetCampaignInfo) then
        local ok, campaignInfo = pcall(C_CampaignInfo.GetCampaignInfo, campaignID)
        if (ok and campaignInfo) then
            campaignInfo.campaignID = campaignID
            return campaignInfo
        end
    end
end

local function QuestComplete(questID)
    local ok, isComplete = pcall(C_QuestLog.IsComplete, questID)
    return ok and IsReadable(isComplete) and isComplete and true or false
end

local function QuestWatched(questID)
    local ok, watchType = pcall(C_QuestLog.GetQuestWatchType, questID)
    return ok and IsReadable(watchType) and true or false
end

local function QuestTitleText(info)
    local title = info and info.title
    if (not EXUI.IsForever() or not info) then
        return title
    end
    local level = info.level
    if (IsReadable(level) and level > 0 and IsReadable(title)) then
        return string.format('[%s] %s', level, title)
    end
    return title
end

local function ApplyQuestTitleColor(fontString, questID)
    local r, g, b = 1, 0.82, 0
    if (C_PlayerInfo and C_PlayerInfo.GetContentDifficultyQuestForPlayer and GetDifficultyColor) then
        local ok, difficulty = pcall(C_PlayerInfo.GetContentDifficultyQuestForPlayer, questID)
        if (ok and IsReadable(difficulty)) then
            local colorOk, color = pcall(GetDifficultyColor, difficulty)
            if (colorOk and color and IsReadable(color.r) and IsReadable(color.g) and IsReadable(color.b)) then
                r, g, b = color.r, color.g, color.b
            end
        end
    end
    fontString:SetTextColor(r, g, b, 1)
end

local function QuestPOIStyle(questID)
    if (not POIButtonUtil or not POIButtonUtil.Style) then
        return nil
    end
    if (C_QuestLog.IsWorldQuest) then
        local ok, isWorld = pcall(C_QuestLog.IsWorldQuest, questID)
        if (ok and IsReadable(isWorld) and isWorld and POIButtonUtil.Style.WorldQuest) then
            return POIButtonUtil.Style.WorldQuest
        end
    end
    if (QuestComplete(questID)) then
        return POIButtonUtil.Style.QuestComplete
    end
    return POIButtonUtil.Style.QuestInProgress
end

questLog.EnsurePOIPool = function(self)
    if (self.poiPool or not POIButtonUtil) then
        return
    end
    local template = 'ObjectiveTrackerPOIButtonTemplate'
    if (C_XMLUtil and C_XMLUtil.GetTemplateInfo and not C_XMLUtil.GetTemplateInfo(template)) then
        template = 'POIButtonTemplate'
    end
    if (C_XMLUtil and C_XMLUtil.GetTemplateInfo and not C_XMLUtil.GetTemplateInfo(template)) then
        return
    end
    local ok, pool = pcall(CreateFramePool, 'Button', UIParent, template)
    if (ok) then
        self.poiPool = pool
    end
end

questLog.ReleasePOI = function(self, row)
    if (row.poiButton and self.poiPool) then
        self.poiPool:Release(row.poiButton)
    end
    row.poiButton = nil
    row.poiQuestID = nil
    row.poiStyle = nil
end

questLog.AttachPOI = function(self, row, questID, style, selected)
    if (not style) then
        self:ReleasePOI(row)
        return
    end
    self:EnsurePOIPool()
    if (not self.poiPool) then
        return
    end
    if (row.poiButton and SameID(row.poiQuestID, questID)) then
        if (row.poiStyle ~= style) then
            row.poiButton:SetStyle(style)
            row.poiStyle = style
        end
        row.poiButton:SetSelected(selected)
        row.poiButton:UpdateButtonStyle()
        row.poiButton:Show()
        return
    end

    self:ReleasePOI(row)
    local poi = self.poiPool:Acquire()
    poi:SetParent(row)
    poi:SetFrameLevel(row:GetFrameLevel() + 2)
    poi:ClearAllPoints()
    poi:SetPoint('TOPLEFT', row, 'TOPLEFT', 4, -2)
    poi:SetQuestID(questID)
    poi:SetStyle(style)
    poi:SetSelected(selected)
    if (style == POIButtonUtil.Style.WorldQuest and poi.SetPingWorldMap) then
        poi:SetPingWorldMap(true)
    end
    poi:UpdateButtonStyle()
    poi:Show()
    row.poiButton = poi
    row.poiQuestID = questID
    row.poiStyle = style
end

questLog.ToggleWatch = function(self, questID)
    questID = questID or self.selectedQuestID
    if (not questID) then
        return
    end
    if (C_QuestLog.GetQuestWatchType(questID)) then
        if (QuestUtil and QuestUtil.CanRemoveQuestWatch and not QuestUtil.CanRemoveQuestWatch()) then
            return
        end
        C_QuestLog.RemoveQuestWatch(questID)
    else
        local maxWatches = Constants and Constants.QuestWatchConsts and Constants.QuestWatchConsts.MAX_QUEST_WATCHES
        local count = C_QuestLog.GetNumQuestWatches()
        if (maxWatches and IsReadable(count) and count >= maxWatches) then
            if (UIErrorsFrame and OBJECTIVES_WATCH_TOO_MANY) then
                UIErrorsFrame:AddMessage(OBJECTIVES_WATCH_TOO_MANY, 1, 0.1, 0.1)
            end
            return
        end
        C_QuestLog.AddQuestWatch(questID)
    end
end

local function ConfigureHeader(row)
    row:SetHeight(HEADER_HEIGHT)

    local bg = row:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    row.bg = bg

    local glow = row:CreateTexture(nil, 'ARTWORK')
    glow:SetAllPoints()
    glow:SetAlpha(0.65)
    glow:Hide()
    row.glow = glow

    local border = row:CreateTexture(nil, 'OVERLAY')
    border:SetAllPoints()
    row.border = border

    local art = row:CreateTexture(nil, 'BACKGROUND', nil, 1)
    art:SetAllPoints()
    art:Hide()
    row.campaignArt = art

    local mask = row:CreateMaskTexture()
    mask:SetAllPoints(art)
    mask:SetTexture(CAMPAIGN_MASK, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    row.campaignMask = mask
    art:AddMaskTexture(mask)

    local title = row:CreateFontString(nil, 'OVERLAY')
    title:SetFont(FontPath(), TITLE_SIZE, 'OUTLINE')
    title:SetJustifyH('LEFT')
    title:SetWordWrap(false)
    row.label = title

    local progress = row:CreateFontString(nil, 'OVERLAY')
    progress:SetFont(FontPath(), LINE_SIZE, 'OUTLINE')
    progress:SetJustifyH('LEFT')
    progress:SetWordWrap(false)
    progress:Hide()
    row.progress = progress

    local nextObjective = CreateFrame('Button', nil, row)
    nextObjective:Hide()
    local nextText = nextObjective:CreateFontString(nil, 'OVERLAY')
    nextText:SetFont(FontPath(), LINE_SIZE, 'OUTLINE')
    nextText:SetJustifyH('LEFT')
    nextText:SetJustifyV('TOP')
    nextText:SetWordWrap(true)
    nextText:SetPoint('TOPLEFT')
    nextObjective.text = nextText
    nextObjective:SetScript('OnEnter', function(self)
        if (HIGHLIGHT_FONT_COLOR and HIGHLIGHT_FONT_COLOR.GetRGB) then
            self.text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        end
    end)
    nextObjective:SetScript('OnLeave', function(self)
        if (NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB) then
            self.text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
        end
    end)
    nextObjective:SetScript('OnClick', function(self)
        local campaignID = self.campaignID
        if (not campaignID or not C_CampaignInfo or not C_CampaignInfo.GetFailureReason) then
            return
        end
        local ok, reason = pcall(C_CampaignInfo.GetFailureReason, campaignID)
        if (not ok or not reason) then
            return
        end
        if (reason.mapID) then
            questLog:ShowMap(reason.mapID)
        end
        if (reason.questID) then
            questLog.selectedQuestID = reason.questID
            questLog:PingQuest(reason.questID)
        end
    end)
    row.nextObjective = nextObjective

    local chevron = row:CreateTexture(nil, 'OVERLAY', nil, 1)
    chevron:SetSize(14, 10)
    chevron:SetPoint('RIGHT', -8, 0)
    row.chevron = chevron

    row:RegisterForClicks('LeftButtonUp')
    row:SetScript('OnEnter', function(self)
        if (self.usesSimpleChrome) then
            ApplyAtlas(self.glow, 'simpleGlowOn', true)
            self.glow:SetAlpha(0.8)
        end
    end)
    row:SetScript('OnLeave', function(self)
        if (self.usesSimpleChrome) then
            ApplyAtlas(self.glow, 'simpleGlowOff', true)
            self.glow:SetAlpha(0.65)
        end
    end)
    row:SetScript('OnClick', function(self)
        local index = self.logIndex
        if (not index) then
            return
        end
        local info = C_QuestLog.GetInfo(index)
        if (not info or not info.isHeader) then
            return
        end
        if (info.isCollapsed) then
            ExpandQuestHeader(index)
        else
            CollapseQuestHeader(index)
        end
    end)
end

local function CampaignStallText(campaign, collapsed)
    if (collapsed or not campaign or not C_CampaignInfo or not C_CampaignInfo.GetState) then
        return nil
    end
    local campaignID = campaign.campaignID
    if (campaign.GetID) then
        local ok, id = pcall(campaign.GetID, campaign)
        if (ok and id) then
            campaignID = id
        end
    end
    if (not campaignID) then
        return nil
    end
    local stalled = false
    pcall(function()
        stalled = C_CampaignInfo.GetState(campaignID) == Enum.CampaignState.Stalled
    end)
    if (not stalled or not C_CampaignInfo.GetFailureReason) then
        return nil
    end
    local ok, reason = pcall(C_CampaignInfo.GetFailureReason, campaignID)
    if (ok and reason) then
        return reason.text, true
    end
    return nil, false
end

local function ApplyCampaignArt(row, campaign)
    local kit = campaign and campaign.uiTextureKit
    if (kit == nil or kit == '') then
        row.campaignArt:Hide()
        return false
    end
    row.Background = row.campaignArt
    local applied = false
    if (SetupTextureKitOnRegions) then
        applied = pcall(SetupTextureKitOnRegions, kit, row, { Background = 'Campaign_%s' }, false, false)
    end
    local atlasApplied = pcall(function()
        row.campaignArt:SetAtlas('Campaign_' .. kit, false)
    end)
    applied = applied or atlasApplied
    if (not applied) then
        row.campaignArt:Hide()
        return false
    end
    row.campaignArt:ClearAllPoints()
    row.campaignArt:SetPoint('TOPLEFT', row, 'TOPLEFT', 0, 0)
    row.campaignArt:SetPoint('TOPRIGHT', row, 'TOPRIGHT', 0, 0)
    row.campaignArt:SetHeight(CAMPAIGN_HEADER_HEIGHT)
    if (row.campaignMask) then
        pcall(row.campaignArt.RemoveMaskTexture, row.campaignArt, row.campaignMask)
        row.campaignArt:AddMaskTexture(row.campaignMask)
    end
    local complete = false
    if (campaign.IsComplete) then
        local ok, isComplete = pcall(campaign.IsComplete, campaign)
        if (ok and IsReadable(isComplete)) then
            complete = isComplete and true or false
        end
    end
    row.campaignArt:SetDesaturated(complete)
    row.campaignArt:Show()
    return true
end

local function CampaignProgress(campaign)
    if (not campaign) then
        return ''
    end
    if (campaign.IsContainerCampaign) then
        local ok, container = pcall(campaign.IsContainerCampaign, campaign)
        if (ok and IsReadable(container) and container) then
            return CONTAINER_CAMPAIGN_PROGRESS or ''
        end
    end
    if (CampaignUtil and CampaignUtil.BuildChapterProgressText) then
        local ok, text = pcall(CampaignUtil.BuildChapterProgressText, campaign)
        if (ok) then
            return text
        end
    end
    return ''
end

questLog.AcquireHeader = function(self, index)
    self.headerRows = self.headerRows or {}
    local row = self.headerRows[index]
    if (not row) then
        row = CreateFrame('Button', nil, self.listScroll.child)
        row:EnableMouse(true)
        ConfigureHeader(row)
        self.headerRows[index] = row
    end
    row:Show()
    return row
end

questLog.BindHeader = function(self, row, info, logIndex)
    local theme = Theme()
    row.entryInfo = info
    row.logIndex = logIndex or info.questLogIndex
    row.questLogIndex = row.logIndex
    local campaign = IsCampaignHeader(info) and CampaignObject(info) or nil
    local showArt = campaign and ApplyCampaignArt(row, campaign)
    local collapsed = info.isCollapsed and true or false
    ApplyAtlas(row.chevron, collapsed and 'chevronDown' or 'chevronUp', false)
    row.usesSimpleChrome = not showArt
    row.glow:SetShown(not showArt)
    if (not showArt) then
        ApplyAtlas(row.glow, 'simpleGlowOff', true)
        row.glow:SetAlpha(0.65)
    end

    if (showArt) then
        local nextText, hasNext = CampaignStallText(campaign, collapsed)
        local extra = 0
        row.chevron:ClearAllPoints()
        row.chevron:SetPoint('RIGHT', row, 'TOPRIGHT', -8, -(CAMPAIGN_HEADER_HEIGHT / 2))
        if (hasNext) then
            local textWidth = QUEST_WIDTH - (PAD * 2) - 20
            local campaignID = campaign.campaignID
            if (not campaignID and campaign.GetID) then
                local idOk, id = pcall(campaign.GetID, campaign)
                if (idOk) then
                    campaignID = id
                end
            end
            row.nextObjective.campaignID = campaignID
            row.nextObjective:ClearAllPoints()
            row.nextObjective:SetPoint('TOPLEFT', 12, -(CAMPAIGN_HEADER_HEIGHT + 4))
            row.nextObjective:SetPoint('RIGHT', row, 'RIGHT', -8, 0)
            row.nextObjective.text:SetWidth(textWidth)
            SetLineText(row.nextObjective.text, nextText)
            if (NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB) then
                row.nextObjective.text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
            else
                row.nextObjective.text:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
            end
            extra = StringHeight(row.nextObjective.text, LINE_SIZE) + 8
            row.nextObjective:SetHeight(math.max(extra - 8, LINE_SIZE))
            row.nextObjective:Show()
        else
            row.nextObjective.campaignID = nil
            row.nextObjective:Hide()
        end
        row:SetHeight(CAMPAIGN_HEADER_HEIGHT + extra)
        row.bg:Hide()
        row.border:Hide()
        row.label:SetFont(FontPath(), TITLE_SIZE, 'OUTLINE')
        SetLineText(row.label, IsReadable(campaign.name) and campaign.name or info.title)
        if (NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB) then
            row.label:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
        else
            row.label:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
        end

        local progress = CampaignProgress(campaign)
        local progressShown = not IsReadable(progress) or progress ~= ''
        row.progress:SetFont(FontPath(), 10, 'OUTLINE')
        SetLineText(row.progress, progress)
        if (HIGHLIGHT_FONT_COLOR and HIGHLIGHT_FONT_COLOR.GetRGB) then
            row.progress:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        else
            row.progress:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
        end
        row.progress:SetShown(progressShown)

        local gap = 1
        local blockHeight = StringHeight(row.label, TITLE_SIZE)
        if (progressShown) then
            blockHeight = blockHeight + gap + StringHeight(row.progress, 10)
        end
        local top = (CAMPAIGN_HEADER_HEIGHT - blockHeight) / 2
        row.label:ClearAllPoints()
        row.label:SetPoint('TOPLEFT', row, 'TOPLEFT', 12, -top)
        row.label:SetPoint('RIGHT', row.chevron, 'LEFT', -8, 0)
        row.progress:ClearAllPoints()
        row.progress:SetPoint('TOPLEFT', row.label, 'BOTTOMLEFT', 0, -gap)
        row.progress:SetPoint('RIGHT', row.chevron, 'LEFT', -8, 0)
    else
        row:SetHeight(HEADER_HEIGHT)
        row.campaignArt:Hide()
        row.nextObjective:Hide()
        row.chevron:ClearAllPoints()
        row.chevron:SetPoint('RIGHT', -8, 0)
        row.bg:Show()
        row.border:Show()
        ApplyAtlas(row.bg, 'simpleBg', true)
        ApplyAtlas(row.border, 'simpleBorderOff', true)
        row.label:ClearAllPoints()
        row.label:SetPoint('LEFT', 8, 0)
        row.label:SetPoint('RIGHT', row.chevron, 'LEFT', -6, 0)
        SetLineText(row.label, info.title)
        row.label:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
        row.progress:Hide()
    end
end

local function ConfigureQuest(row)
    row:SetHeight(28)

    local hover = row:CreateTexture(nil, 'BACKGROUND')
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.06)
    hover:Hide()
    row.hover = hover

    local title = row:CreateFontString(nil, 'OVERLAY')
    title:SetFont(FontPath(), TITLE_SIZE, 'OUTLINE')
    title:SetJustifyH('LEFT')
    title:SetJustifyV('TOP')
    title:SetWordWrap(false)
    row.label = title

    local eye = CreateFrame('Button', nil, row)
    eye:SetSize(18, 16)
    eye:SetPoint('TOPRIGHT', -6, -4)
    local eyeIcon = eye:CreateTexture(nil, 'ARTWORK')
    eyeIcon:SetPoint('CENTER')
    eye.icon = eyeIcon
    eye:SetScript('OnClick', function(self)
        if (self:GetParent().questID) then
            questLog:ToggleWatch(self:GetParent().questID)
        end
    end)
    row.eye = eye
    row.lines = {}

    row:SetScript('OnEnter', function(self)
        self.hover:Show()
    end)
    row:SetScript('OnLeave', function(self)
        self.hover:SetShown(self.isSelected)
    end)
    row:SetScript('OnClick', function(self)
        if (self.questID) then
            questLog:SelectQuest(self.questID)
        end
    end)
end

questLog.AcquireQuest = function(self, index)
    self.questRows = self.questRows or {}
    local row = self.questRows[index]
    if (not row) then
        row = CreateFrame('Button', nil, self.listScroll.child)
        ConfigureQuest(row)
        self.questRows[index] = row
    end
    row:Show()
    return row
end

questLog.BindQuest = function(self, row, info, superID)
    local theme = Theme()
    local questID = info.questID
    row.questID = questID
    row.isSelected = SameID(self.selectedQuestID, questID)
    local superTracked = SameID(superID, questID)

    self:AttachPOI(row, questID, QuestPOIStyle(questID), superTracked)
    SetAtlasIcon(row.eye.icon, QuestWatched(questID) and 'eye' or 'eyeOff', 14)

    row.label:ClearAllPoints()
    row.label:SetPoint('TOPLEFT', 28, -4)
    row.label:SetPoint('RIGHT', row.eye, 'LEFT', -4, 0)
    SetLineText(row.label, QuestTitleText(info))
    ApplyQuestTitleColor(row.label, questID)

    local cursor = 4 + StringHeight(row.label, TITLE_SIZE) + 2
    local objectives = nil
    local ok, result = pcall(C_QuestLog.GetQuestObjectives, questID)
    if (ok and result and IsReadable(result)) then
        objectives = result
    end

    local count = 0
    if (objectives) then
        for _, objective in ipairs(objectives) do
            count = count + 1
            local line = row.lines[count]
            if (not line) then
                line = row:CreateFontString(nil, 'OVERLAY')
                line:SetFont(FontPath(), LINE_SIZE, 'OUTLINE')
                line:SetJustifyH('LEFT')
                line:SetJustifyV('TOP')
                row.lines[count] = line
            end
            line:ClearAllPoints()
            line:SetPoint('TOPLEFT', 28, -cursor)
            line:SetPoint('RIGHT', -8, 0)
            SetLineText(line, objective.text)
            local finished = IsReadable(objective.finished) and objective.finished
            if (finished) then
                line:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
            else
                line:SetTextColor(0.8, 0.8, 0.8, 1)
            end
            line:Show()
            cursor = cursor + StringHeight(line, LINE_SIZE) + 2
        end
    end
    for index = count + 1, #row.lines do
        row.lines[index]:Hide()
    end

    row.hover:SetShown(row.isSelected)
    row:SetHeight(math.max(cursor + 4, 28))
end

questLog.RefreshList = function(self)
    if (not self.listScroll) then
        return
    end
    local entries = self:BuildEntries()
    local superID = C_SuperTrack.GetSuperTrackedQuestID()
    local child = self.listScroll.child
    local y = 0
    local headerCount = 0
    local questCount = 0

    for _, entry in ipairs(entries) do
        local row
        if (entry.isHeader) then
            headerCount = headerCount + 1
            row = self:AcquireHeader(headerCount)
            self:BindHeader(row, entry.info, entry.logIndex)
        else
            questCount = questCount + 1
            row = self:AcquireQuest(questCount)
            self:BindQuest(row, entry.info, superID)
        end
        row:ClearAllPoints()
        row:SetPoint('TOPLEFT', child, 'TOPLEFT', 0, -y)
        row:SetPoint('RIGHT', child, 'RIGHT', 0, 0)
        y = y + row:GetHeight() + ROW_GAP
    end

    if (self.headerRows) then
        for index = headerCount + 1, #self.headerRows do
            self.headerRows[index]:Hide()
        end
    end
    if (self.questRows) then
        for index = questCount + 1, #self.questRows do
            local row = self.questRows[index]
            self:ReleasePOI(row)
            row:Hide()
        end
    end

    self.emptyText:SetShown(#entries == 0)
    child:SetHeight(math.max(y, 1))
    if (self.listScroll.UpdateScrollbar) then
        self.listScroll:UpdateScrollbar()
    end
end

questLog.Refresh = function(self)
    if (self.refreshing or not self.isCreated) then
        return
    end
    self.refreshing = true
    local ok, err = pcall(self.RefreshList, self)
    if (self.RefreshDetails) then
        local detailsOk, detailsErr = pcall(self.RefreshDetails, self)
        if (not detailsOk) then
            ok, err = detailsOk, detailsErr
        end
    end
    self.refreshing = false
    if (not ok and geterrorhandler) then
        geterrorhandler()(err)
    end
end

questLog.SelectQuest = function(self, questID)
    self.selectedQuestID = questID
    self.refreshing = true
    pcall(C_QuestLog.SetSelectedQuest, questID)
    self.refreshing = false
    local mapID = QuestMapID(questID)
    if (mapID) then
        self:ShowMap(mapID)
    end
    self:Layout()
    self:Refresh()
    self:PingQuest(questID)
end

questLog.ShowQuest = function(self, questID)
    self.pendingQuestID = questID
    self:Show()
end

questLog.GetSide = function(self)
    local side = customWindows.Data:GetValue('QuestLogSide')
    if (side == 'left') then
        return 'left'
    end
    return 'right'
end

questLog.Layout = function(self)
    local window = self.window
    if (not window or not self.mapHost or not self.questPanel) then
        return
    end
    local showDetails = self.detailPanel and self.selectedQuestID ~= nil
    local mapWidth = MapWidth()
    local mapHeight = MapHeight()
    local width = mapWidth + GAP + QUEST_WIDTH
    if (showDetails) then
        width = width + GAP + DETAIL_WIDTH
    end
    window:SetSize(width, mapHeight)
    self.mapHost:ClearAllPoints()
    self.questPanel:ClearAllPoints()
    if (self:GetSide() == 'left') then
        self.questPanel:SetPoint('TOPLEFT', window, 'TOPLEFT', 0, 0)
        self.mapHost:SetPoint('TOPLEFT', self.questPanel, 'TOPRIGHT', GAP, 0)
    else
        self.mapHost:SetPoint('TOPLEFT', window, 'TOPLEFT', 0, 0)
        self.questPanel:SetPoint('TOPLEFT', self.mapHost, 'TOPRIGHT', GAP, 0)
    end
    local hostWidth, hostHeight = self.mapHost:GetSize()
    self.mapHost:SetSize(mapWidth, mapHeight)
    self.questPanel:SetSize(QUEST_WIDTH, mapHeight)
    if (self.detailPanel) then
        self.detailPanel:ClearAllPoints()
        self.detailPanel:SetShown(showDetails)
        if (showDetails) then
            local anchor = self:GetSide() == 'left' and self.mapHost or self.questPanel
            self.detailPanel:SetPoint('TOPLEFT', anchor, 'TOPRIGHT', GAP, 0)
            self.detailPanel:SetSize(DETAIL_WIDTH, mapHeight)
        end
    end
    if (self.canvas and self.canvas.OnFrameSizeChanged and (hostWidth ~= mapWidth or hostHeight ~= mapHeight)) then
        self.canvas:OnFrameSizeChanged()
    end
end

local function SetActionEnabled(button, enabled)
    button:SetEnabled(enabled)
    button:SetAlpha(enabled and 1 or 0.45)
end

local function AcquireReward(pool, parent, index)
    local row = pool[index]
    if (not row) then
        local theme = Theme()
        row = CreateFrame('Button', nil, parent)
        row:SetHeight(REWARD_ROW_HEIGHT)
        local bg = row:CreateTexture(nil, 'BACKGROUND')
        bg:SetAllPoints()
        row.bg = bg
        local glow = row:CreateTexture(nil, 'BACKGROUND', nil, 1)
        glow:SetAllPoints()
        glow:SetAlpha(0.65)
        row.glow = glow
        local border = row:CreateTexture(nil, 'OVERLAY')
        border:SetAllPoints()
        row.border = border
        local icon = row:CreateTexture(nil, 'ARTWORK')
        icon:SetSize(16, 16)
        icon:SetPoint('LEFT', 6, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.icon = icon
        local count = row:CreateFontString(nil, 'OVERLAY')
        count:SetFont(FontPath(), LINE_SIZE, 'OUTLINE')
        count:SetPoint('RIGHT', -8, 0)
        count:SetJustifyH('RIGHT')
        count:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
        row.count = count
        local name = row:CreateFontString(nil, 'OVERLAY')
        name:SetFont(FontPath(), LINE_SIZE, 'OUTLINE')
        name:SetJustifyH('LEFT')
        name:SetWordWrap(false)
        name:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
        row.name = name
        row:SetScript('OnEnter', function(self)
            ApplyAtlas(self.glow, 'simpleGlowOn', true)
            self.glow:SetAlpha(0.8)
            if (not self.itemID and not self.currencyID and not self.spellID) then
                return
            end
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            pcall(function()
                if (self.itemID) then
                    GameTooltip:SetItemByID(self.itemID)
                elseif (self.currencyID and GameTooltip.SetCurrencyByID) then
                    GameTooltip:SetCurrencyByID(self.currencyID, self.currencyAmount)
                elseif (self.spellID) then
                    GameTooltip:SetSpellByID(self.spellID)
                end
            end)
            GameTooltip:Show()
        end)
        row:SetScript('OnLeave', function(self)
            ApplyAtlas(self.glow, 'simpleGlowOff', true)
            self.glow:SetAlpha(0.65)
            GameTooltip:Hide()
        end)
        pool[index] = row
    end
    ApplyAtlas(row.bg, 'simpleBg', true)
    ApplyAtlas(row.glow, 'simpleGlowOff', true)
    row.glow:SetAlpha(0.65)
    ApplyAtlas(row.border, 'simpleBorderOff', true)
    row.itemID = nil
    row.currencyID = nil
    row.spellID = nil
    row.currencyAmount = nil
    row:Show()
    return row
end

questLog.CreateDetailPanel = function(self, window)
    local theme = Theme()
    local panel = CreateFrame('Frame', nil, window)
    panel:SetSize(DETAIL_WIDTH, MapHeight())
    ApplyQuestChrome(panel)
    panel:EnableMouse(true)
    panel:RegisterForDrag('LeftButton')
    panel:SetScript('OnDragStart', function()
        window:StartMoving()
    end)
    panel:SetScript('OnDragStop', function()
        window:StopMovingOrSizing()
    end)
    panel:Hide()
    self.detailPanel = panel

    local close = CreateCloseButton(panel, function()
        questLog.selectedQuestID = nil
        questLog:Layout()
        questLog:Refresh()
    end)
    close:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -12, -12)
    self.detailCloseButton = close

    local title = panel:CreateFontString(nil, 'OVERLAY')
    title:SetFont(FontPath(), DETAIL_TITLE_SIZE, 'OUTLINE')
    title:SetPoint('TOPLEFT', PAD, -12)
    title:SetPoint('TOPRIGHT', close, 'TOPLEFT', -6, 0)
    title:SetJustifyH('LEFT')
    title:SetJustifyV('TOP')
    title:SetWordWrap(true)
    self.detailTitle = title

    local function ActionButton(text, onClick)
        local button = simpleButton:Create(panel)
        button:SetOptionData({
            label = text,
            onClick = onClick,
        })
        return button
    end

    local share = ActionButton('Share', function()
        questLog:ShareSelected()
    end)
    local abandon = ActionButton('Abandon', function()
        questLog:AbandonSelected()
    end)
    local watch = ActionButton('Untrack', function()
        questLog:ToggleWatch()
    end)
    local buttonGap = 4
    local buttonWidth = (DETAIL_WIDTH - PAD * 2 - buttonGap * 2) / 3
    share:SetSize(buttonWidth, 26)
    abandon:SetSize(buttonWidth, 26)
    watch:SetSize(buttonWidth, 26)
    share:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', PAD, PAD)
    abandon:SetPoint('BOTTOMLEFT', share, 'BOTTOMRIGHT', buttonGap, 0)
    watch:SetPoint('BOTTOMLEFT', abandon, 'BOTTOMRIGHT', buttonGap, 0)
    self.shareButton = share
    self.abandonButton = abandon
    self.watchButton = watch

    local detailScroll = scrollConstruct:Create()
    detailScroll:SetParent(panel)
    detailScroll:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -8)
    detailScroll:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -PAD, PAD + 32)
    self.detailScroll = detailScroll

    local description = detailScroll.child:CreateFontString(nil, 'OVERLAY')
    description:SetFont(FontPath(), LINE_SIZE, 'OUTLINE')
    description:SetJustifyH('LEFT')
    description:SetJustifyV('TOP')
    description:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    self.detailDescription = description

    local rewardsLabel = detailScroll.child:CreateFontString(nil, 'OVERLAY')
    rewardsLabel:SetFont(FontPath(), LINE_SIZE, 'OUTLINE')
    rewardsLabel:SetText('Rewards')
    rewardsLabel:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    rewardsLabel:Hide()
    self.rewardsLabel = rewardsLabel

    self.rewardButtons = {}
end

questLog.AddRewardIcon = function(self, name, texture, count, kind, id)
    self.rewardCount = (self.rewardCount or 0) + 1
    local row = AcquireReward(self.rewardButtons, self.detailScroll.child, self.rewardCount)
    row.icon:SetTexture(texture)
    SetLineText(row.name, name)
    if (kind == 'item') then
        row.itemID = id
    elseif (kind == 'currency') then
        row.currencyID = id
        row.currencyAmount = count
    elseif (kind == 'spell') then
        row.spellID = id
    end
    row.name:ClearAllPoints()
    row.name:SetPoint('LEFT', row.icon, 'RIGHT', 6, 0)
    if (IsReadable(count)) then
        SetLineText(row.count, count)
        row.count:Show()
        row.name:SetPoint('RIGHT', row.count, 'LEFT', -6, 0)
    else
        row.count:Hide()
        row.name:SetPoint('RIGHT', -8, 0)
    end
    return row
end

questLog.ShareSelected = function(self)
    local questID = self.selectedQuestID
    if (not questID) then
        return
    end
    if (QuestMapQuestOptions_ShareQuest) then
        QuestMapQuestOptions_ShareQuest(questID)
        return
    end
    local index = C_QuestLog.GetLogIndexForQuestID(questID)
    if (index and QuestLogPushQuest) then
        QuestLogPushQuest(index)
    end
end

questLog.AbandonSelected = function(self)
    local questID = self.selectedQuestID
    if (not questID) then
        return
    end
    if (QuestMapQuestOptions_AbandonQuest) then
        QuestMapQuestOptions_AbandonQuest(questID)
        return
    end
    C_QuestLog.SetSelectedQuest(questID)
    C_QuestLog.SetAbandonQuest()
    local title = ''
    local index = C_QuestLog.GetLogIndexForQuestID(questID)
    local info = index and C_QuestLog.GetInfo(index)
    if (info and IsReadable(info.title)) then
        title = info.title
    end
    StaticPopup_Show('ABANDON_QUEST', title)
end

questLog.RefreshDetails = function(self)
    if (not self.detailPanel) then
        return
    end
    local questID = self.selectedQuestID
    local info = nil
    if (questID) then
        local index = C_QuestLog.GetLogIndexForQuestID(questID)
        if (index) then
            info = C_QuestLog.GetInfo(index)
        end
    end
    if (not info or info.isHeader) then
        if (self.selectedQuestID) then
            self.selectedQuestID = nil
            self:Layout()
        end
        return
    end

    local theme = Theme()
    SetLineText(self.detailTitle, QuestTitleText(info))
    ApplyQuestTitleColor(self.detailTitle, questID)
    self.detailTitle:SetHeight(StringHeight(self.detailTitle, DETAIL_TITLE_SIZE))

    local watched = QuestWatched(questID)
    self.watchButton:SetText(watched and 'Untrack' or 'Track')
    local pushable = false
    local pushOk, isPushable = pcall(C_QuestLog.IsPushableQuest, questID)
    if (pushOk and IsReadable(isPushable)) then
        pushable = isPushable and true or false
    end
    SetActionEnabled(self.shareButton, pushable)
    local canAbandon = true
    local abandonOk, abandonable = pcall(C_QuestLog.CanAbandonQuest, questID)
    if (abandonOk and IsReadable(abandonable)) then
        canAbandon = abandonable and true or false
    end
    SetActionEnabled(self.abandonButton, canAbandon)

    local description = ''
    local logIndex = info.questLogIndex or C_QuestLog.GetLogIndexForQuestID(questID)
    if (logIndex and GetQuestLogQuestText) then
        local textOk, text = pcall(GetQuestLogQuestText, logIndex)
        if (textOk and text) then
            description = text
        end
    end

    local child = self.detailScroll.child
    local width = DETAIL_WIDTH - (PAD * 2)
    child:SetWidth(width)
    SetLineText(self.detailDescription, description)
    self.detailDescription:SetWidth(width - 4)
    local y = 0
    local descriptionEmpty = IsReadable(description) and description == ''
    local descHeight = StringHeight(self.detailDescription, LINE_SIZE)
    if (descriptionEmpty or descHeight < 2) then
        self.detailDescription:Hide()
    else
        self.detailDescription:Show()
        self.detailDescription:ClearAllPoints()
        self.detailDescription:SetPoint('TOPLEFT', child, 'TOPLEFT', 0, 0)
        y = descHeight + 10
    end

    self.rewardButtons = self.rewardButtons or {}
    self.rewardCount = 0

    local function AddItemRewards(count, getter)
        if (not count or count < 1 or not getter) then
            return
        end
        for itemIndex = 1, count do
            local results = { pcall(getter, itemIndex) }
            if (not results[1]) then
                break
            end
            local name = results[2]
            local texture = results[3]
            local numItems = results[4]
            local itemID = results[7]
            if (texture) then
                self:AddRewardIcon(name, texture, numItems, 'item', itemID)
            end
        end
    end

    if (GetNumQuestLogRewards and GetQuestLogRewardInfo) then
        local ok, count = pcall(GetNumQuestLogRewards)
        if (ok) then
            AddItemRewards(count, GetQuestLogRewardInfo)
        end
    end
    if (GetNumQuestLogChoices and GetQuestLogChoiceInfo) then
        local ok, count = pcall(GetNumQuestLogChoices)
        if (ok) then
            AddItemRewards(count, GetQuestLogChoiceInfo)
        end
    end
    if (C_QuestLog.GetQuestRewardCurrencies) then
        local ok, currencies = pcall(C_QuestLog.GetQuestRewardCurrencies, questID)
        if (ok and currencies) then
            for _, currency in ipairs(currencies) do
                self:AddRewardIcon(currency.name, currency.texture, currency.totalRewardAmount, 'currency', currency.currencyID)
            end
        end
    end
    if (C_QuestInfoSystem and C_QuestInfoSystem.GetQuestRewardSpells) then
        local ok, spells = pcall(C_QuestInfoSystem.GetQuestRewardSpells, questID)
        if (ok and spells) then
            for _, spellID in ipairs(spells) do
                local infoOk, spellInfo = pcall(C_QuestInfoSystem.GetQuestRewardSpellInfo, questID, spellID)
                if (infoOk and spellInfo and spellInfo.texture) then
                    self:AddRewardIcon(spellInfo.name, spellInfo.texture, nil, 'spell', spellID)
                end
            end
        end
    end
    if (GetQuestLogRewardMoney and GetMoneyString) then
        local ok, money = pcall(GetQuestLogRewardMoney)
        if (ok and IsReadable(money) and money > 0) then
            self:AddRewardIcon(GetMoneyString(money, false, true), [[Interface\Icons\inv_misc_coin_01]], nil, 'money')
        end
    end
    for index = self.rewardCount + 1, #self.rewardButtons do
        self.rewardButtons[index]:Hide()
    end

    if (self.rewardCount > 0) then
        y = y + 4
        self.rewardsLabel:Show()
        self.rewardsLabel:ClearAllPoints()
        self.rewardsLabel:SetPoint('TOPLEFT', child, 'TOPLEFT', 0, -y)
        y = y + 16
        for index = 1, self.rewardCount do
            local reward = self.rewardButtons[index]
            reward:ClearAllPoints()
            reward:SetPoint('TOPLEFT', child, 'TOPLEFT', 0, -y)
            reward:SetPoint('TOPRIGHT', child, 'TOPRIGHT', 0, -y)
            y = y + REWARD_ROW_HEIGHT + REWARD_ROW_GAP
        end
    else
        self.rewardsLabel:Hide()
    end

    child:SetHeight(math.max(y + 8, 1))
    if (self.detailScroll.UpdateScrollbar) then
        self.detailScroll:UpdateScrollbar()
    end
end

questLog.CreateQuestList = function(self, panel)
    local theme = Theme()
    local listScroll = scrollConstruct:Create()
    listScroll:SetParent(panel)
    listScroll:SetPoint('TOPLEFT', PAD, -PAD)
    listScroll:SetPoint('BOTTOMRIGHT', -PAD, PAD)
    self.listScroll = listScroll

    local emptyList = panel:CreateFontString(nil, 'OVERLAY')
    emptyList:SetFont(FontPath(), LINE_SIZE, 'OUTLINE')
    emptyList:SetPoint('TOPLEFT', PAD + 4, -(PAD + 4))
    emptyList:SetText('No quests')
    emptyList:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    emptyList:Hide()
    self.emptyText = emptyList
end

questLog.Create = function(self)
    if (self.isCreated) then
        return
    end
    self.isCreated = true

    local theme = Theme()
    local window = CreateFrame('Frame', 'EXUIMapQuestFrame', UIParent)
    window:SetFrameStrata('HIGH')
    window:SetSize(MapWidth() + GAP + QUEST_WIDTH, MapHeight())
    window:SetPoint(OPEN_POINT[1], UIParent, OPEN_POINT[2], OPEN_POINT[3], OPEN_POINT[4])
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(false)
    window:Hide()
    self.window = window
    tinsert(UISpecialFrames, 'EXUIMapQuestFrame')

    local mapHost = CreateFrame('Frame', nil, window)
    mapHost:SetSize(MapWidth(), MapHeight())
    ApplyMapChrome(mapHost)
    self.mapHost = mapHost

    local panel = CreateFrame('Frame', nil, window)
    panel:SetSize(QUEST_WIDTH, MapHeight())
    ApplyQuestChrome(panel)
    panel:EnableMouse(true)
    panel:RegisterForDrag('LeftButton')
    panel:SetScript('OnDragStart', function()
        window:StartMoving()
    end)
    panel:SetScript('OnDragStop', function()
        window:StopMovingOrSizing()
    end)
    self.questPanel = panel
    self:CreateDetailPanel(window)
    self:Layout()

    local loaded = C_AddOns.LoadAddOn('Blizzard_WorldMap')
    if (loaded) then
        local ok = pcall(function()
            self:CreateMap(mapHost)
        end)
        if (not ok and self.canvas) then
            self.canvas:Hide()
            self.canvas = nil
        end
    end

    if (not self.canvas) then
        local unavailable = mapHost:CreateFontString(nil, 'OVERLAY')
        unavailable:SetFont(FontPath(), TITLE_SIZE, 'OUTLINE')
        unavailable:SetPoint('CENTER')
        unavailable:SetText('Map could not be created')
        unavailable:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    end

    local close = CreateCloseButton(window, function()
        window:Hide()
    end)
    close:SetSize(24, 24)
    close:SetPoint('TOPRIGHT', mapHost, 'TOPRIGHT', -14, -14)
    close:SetFrameLevel(window:GetFrameLevel() + 100)
    self.closeButton = close

    local returnButton = CreateFrame('Button', nil, window)
    returnButton:SetFrameLevel(window:GetFrameLevel() + 100)
    returnButton:SetHeight(29)
    returnButton:SetPoint('BOTTOMLEFT', mapHost, 'BOTTOMLEFT', 14, 14)
    local returnIcon = returnButton:CreateTexture(nil, 'ARTWORK')
    returnIcon:SetSize(28, 29)
    returnIcon:SetTexture(HOME_TEXTURE)
    returnIcon:SetPoint('LEFT', 0, 0)
    local returnLabel = returnButton:CreateFontString(nil, 'OVERLAY')
    returnLabel:SetFont(FontPath(), 12, 'OUTLINE')
    returnLabel:SetText('Return')
    returnLabel:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    returnLabel:SetPoint('LEFT', returnIcon, 'RIGHT', 4, 0)
    local returnWidth = 40
    local widthOk, measured = pcall(returnLabel.GetStringWidth, returnLabel)
    if (widthOk and type(measured) == 'number' and measured > 1) then
        returnWidth = measured
    end
    returnButton:SetWidth(returnWidth + 4 + 28)
    returnButton:SetScript('OnEnter', function()
        returnLabel:SetTextColor(theme.text[1], theme.text[2], theme.text[3], 1)
    end)
    returnButton:SetScript('OnLeave', function()
        returnLabel:SetTextColor(theme.textMuted[1], theme.textMuted[2], theme.textMuted[3], 1)
    end)
    returnButton:SetScript('OnClick', function()
        local mapID = questLog:PlayerMapID()
        if (IsReadable(mapID) and mapID ~= 0) then
            questLog:ShowMap(mapID)
        end
    end)
    returnButton:Hide()
    self.returnButton = returnButton
    self:UpdateReturnButton()

    self:CreateQuestList(panel)

    window:HookScript('OnHide', function()
        questLog:DetachHandyNotes()
        questLog:DetachHereBeDragons()
        if (C_Map.CloseWorldMapInteraction) then
            C_Map.CloseWorldMapInteraction()
        end
        if (SOUNDKIT) then
            PlaySound(SOUNDKIT.IG_QUEST_LOG_CLOSE)
        end
    end)
end

questLog.Show = function(self)
    if (not self.enabled) then
        return
    end
    self:Create()
    self:HideBlizzardMap()
    local wasShown = self.window:IsShown()
    if (not wasShown) then
        self.window:ClearAllPoints()
        self.window:SetPoint(OPEN_POINT[1], UIParent, OPEN_POINT[2], OPEN_POINT[3], OPEN_POINT[4])
        self:ApplyPendingMap()
        self.window:Show()
        if (self.canvas) then
            self.canvas:Show()
            C_Timer.After(0, function()
                if (questLog.canvas and questLog.canvas:IsShown() and questLog.canvas.OnFrameSizeChanged) then
                    questLog.canvas:OnFrameSizeChanged()
                end
            end)
        end
        if (SOUNDKIT) then
            PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN)
        end
    else
        self:ApplyPendingMap()
    end
    if (self.pendingQuestID) then
        local questID = self.pendingQuestID
        self.pendingQuestID = nil
        self:SelectQuest(questID)
    else
        self:Refresh()
    end
    self:AttachHandyNotes()
    self:AttachHereBeDragons()
    self:UpdateReturnButton()
    C_Timer.After(0, function()
        if (questLog.window and questLog.window:IsShown()) then
            questLog:Refresh()
        end
    end)
end

questLog.Toggle = function(self)
    if (not self.enabled) then
        return
    end
    self:Create()
    if (self.window:IsShown()) then
        self.window:Hide()
    else
        self:Show()
    end
end

questLog.Enable = function(self)
    if (not EXUI.IsRetail() and not EXUI.IsForever()) then
        return
    end
    self.enabled = true
    C_AddOns.LoadAddOn('Blizzard_WorldMap')
    self:EnsureBindingButton()
    self:InstallHooks()
    self:ApplyBindings()
end

questLog.Disable = function(self)
    self.enabled = false
    if (self.window and self.window:IsShown()) then
        self.window:Hide()
    end
    self:ApplyBindings()
end

questLog.Init = function(self)
    if (not EXUI.IsRetail() and not EXUI.IsForever()) then
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'quest-log-window-hooks', function(_, addon)
        if (addon == 'Blizzard_WorldMap' or addon == 'Blizzard_UIPanels_Game') then
            questLog:InstallHooks()
        end
        if ((addon == 'HandyNotes' or addon == 'TomTom') and questLog.window and questLog.window:IsShown()) then
            C_Timer.After(0, function()
                if (questLog.window and questLog.window:IsShown()) then
                    questLog:AttachHandyNotes()
                    questLog:AttachHereBeDragons()
                end
            end)
        end
    end)

    EXUI:RegisterEventHandler({ 'UPDATE_BINDINGS', 'PLAYER_REGEN_ENABLED' }, 'quest-log-window-bindings', function()
        if (questLog.enabled or questLog.bindingsDirty) then
            questLog:ApplyBindings()
        end
    end)

    EXUI:RegisterEventHandler({
        'ZONE_CHANGED',
        'ZONE_CHANGED_INDOORS',
        'ZONE_CHANGED_NEW_AREA',
        'NEW_WMO_CHUNK',
        'PLAYER_MAP_CHANGED',
    }, 'quest-log-window-return', function()
        if (questLog.enabled and questLog.window and questLog.window:IsShown()) then
            questLog:FollowPlayerMap()
        end
    end)

    EXUI:RegisterEventHandler({
        'QUEST_LOG_UPDATE',
        'QUEST_WATCH_LIST_CHANGED',
        'SUPER_TRACKING_CHANGED',
    }, 'quest-log-window-refresh', function()
        if (questLog.enabled and questLog.window and questLog.window:IsShown()) then
            questLog:Refresh()
        end
    end)

    if (customWindows.Data:GetValue('QuestLogEnabled') == true) then
        self:Enable()
    end
end
