---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIChatSkin
local skin = EXUI:GetModule('chat-skin')

---@class EXUIChat
local chat = EXUI:GetModule('chat')

local LSM = LibStub:GetLibrary('LibSharedMedia-3.0', true)

chat.enabled = false
chat.useTabs = true
chat.Data = data:GetControlsForKey('chat')

local BLIZZARD_WHISPER_SOUND = 'blizzard'
local WHISPER_SOUND_THROTTLE = 1
local lastWhisperSound

local TIMESTAMP_ORDER = {
    { key = 'none', label = 'None', order = 1 },
    { key = 'hm12', label = '12h  h:m', order = 2 },
    { key = 'hms12', label = '12h  h:m:s', order = 3 },
    { key = 'hmap', label = '12h  h:m AM/PM', order = 4 },
    { key = 'hmsap', label = '12h  h:m:s AM/PM', order = 5 },
    { key = 'hm24', label = '24h  h:m', order = 6 },
    { key = 'hms24', label = '24h  h:m:s', order = 7 },
}

local TIMESTAMP_FALLBACK = {
    none = 'none',
    hm12 = '%I:%M ',
    hms12 = '%I:%M:%S ',
    hmap = '%I:%M %p ',
    hmsap = '%I:%M:%S %p ',
    hm24 = '%H:%M ',
    hms24 = '%H:%M:%S ',
}

local function TimestampGlobals()
    return {
        none = 'none',
        hm12 = TIMESTAMP_FORMAT_HHMM,
        hms12 = TIMESTAMP_FORMAT_HHMMSS,
        hmap = TIMESTAMP_FORMAT_HHMM_AMPM,
        hmsap = TIMESTAMP_FORMAT_HHMMSS_AMPM,
        hm24 = TIMESTAMP_FORMAT_HHMM_24HR,
        hms24 = TIMESTAMP_FORMAT_HHMMSS_24HR,
    }
end

local function GetTimestampSetting()
    if Settings and Settings.GetValue then
        local ok, value = pcall(Settings.GetValue, 'showTimestamps')
        if ok and value ~= nil then
            return value
        end
    end
    return GetCVar('showTimestamps')
end

local function SetTimestampSetting(value)
    if Settings and Settings.SetValue then
        local ok = pcall(Settings.SetValue, 'showTimestamps', value)
        if ok then
            return
        end
    end
    SetCVar('showTimestamps', value)
end

local function TimestampValue(key)
    local globals = TimestampGlobals()
    return globals[key] or TIMESTAMP_FALLBACK[key] or 'none'
end

chat.GetTabSide = function(self)
    return self.Data:GetValue('tabSide') or 'top'
end

chat.GetEditBoxSide = function(self)
    return self.Data:GetValue('editBoxSide') or 'bottom'
end

chat.GetBackgroundAlpha = function(self)
    local percent = self.Data:GetValue('backgroundAlpha')
    if type(percent) ~= 'number' then
        percent = 70
    end
    return percent / 100
end

chat.GetSavedTabColor = function(self, id)
    local colors = self.Data:GetValue('tabColors')
    if type(colors) ~= 'table' then
        return nil
    end
    return colors[tostring(id)]
end

chat.SaveTabColor = function(self, id, r, g, b)
    local colors = self.Data:GetValue('tabColors')
    if type(colors) ~= 'table' then
        colors = {}
    end
    colors[tostring(id)] = { r = r, g = g, b = b }
    self.Data:SetValue('tabColors', colors)
end

chat.TimestampsShown = function(self)
    return self.Data:GetValue('showTimestamp') ~= false
end

chat.GetTimestampKey = function(self)
    return self.Data:GetValue('timestamp') or 'hms24'
end

chat.GetTimestampPattern = function(self)
    if not self:TimestampsShown() then
        return nil
    end
    local pattern = TimestampValue(self:GetTimestampKey())
    if not pattern or pattern == 'none' then
        return nil
    end
    return pattern
end

chat.GetTimestampColor = function(self)
    local color = self.Data:GetValue('timestampColor')
    if type(color) ~= 'table' then
        return 0.62, 0.58, 0.52
    end
    return color.r or 0.62, color.g or 0.58, color.b or 0.52
end

local function ColorChannels(color, dr, dg, db)
    if type(color) ~= 'table' then
        return dr, dg, db
    end
    return color.r or dr, color.g or dg, color.b or db
end

chat.GetActiveTabTextColor = function(self)
    return ColorChannels(self.Data:GetValue('activeTabText'), 1, 1, 1)
end

chat.GetInactiveTabTextColor = function(self)
    return ColorChannels(self.Data:GetValue('inactiveTabText'), 0.54, 0.50, 0.46)
end

chat.UseClassColor = function(self)
    return self.Data:GetValue('classColor') ~= false
end

chat.ShowChannelTags = function(self)
    return self.Data:GetValue('showChannelTags') == true
end

chat.GetHideAfter = function(self)
    local value = self.Data:GetValue('hideAfter')
    if type(value) ~= 'number' then
        return 0
    end
    return value
end

chat.GetTimestampFontSize = function(self)
    local size = self.Data:GetValue('timestampFontSize')
    if type(size) ~= 'number' then
        return 12
    end
    return size
end

chat.GetTimestampPlace = function(self)
    local place = self.Data:GetValue('timestampPlace')
    if place == 'above' or place == 'below' then
        return place
    end
    return 'inline'
end

chat.GetTimestampAlign = function(self)
    if self.Data:GetValue('timestampAlign') == 'right' then
        return 'right'
    end
    return 'left'
end

chat.GetMessageAlign = function(self)
    if self.Data:GetValue('messageAlign') == 'right' then
        return 'right'
    end
    return 'left'
end

chat.GetWhisperSound = function(self)
    return self.Data:GetValue('whisperSoundFile') or BLIZZARD_WHISPER_SOUND
end

local function PlayWhisperSoundKey(key)
    if key == BLIZZARD_WHISPER_SOUND or not LSM then
        PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081)
        return
    end
    local file = LSM:Fetch('sound', key, true)
    if file then
        PlaySoundFile(file)
    end
end

chat.PlayWhisperSound = function(self)
    if not self.Data:GetValue('whisperSound') then
        return
    end
    local now = GetTime()
    if lastWhisperSound and now - lastWhisperSound < WHISPER_SOUND_THROTTLE then
        return
    end
    lastWhisperSound = now
    PlayWhisperSoundKey(self:GetWhisperSound())
end

local function WhisperSoundOptions()
    local options = { [BLIZZARD_WHISPER_SOUND] = 'Blizzard Whisper' }
    if LSM then
        for _, name in ipairs(LSM:List('sound')) do
            if name ~= 'None' then
                options[name] = name
            end
        end
    end
    return options
end

chat.RestoreFontSize = function(self)
    if not self.savedFontSizes or not FCF_SetChatWindowFontSize then
        return
    end
    for frameName, height in pairs(self.savedFontSizes) do
        local frame = _G[frameName]
        if frame and height then
            FCF_SetChatWindowFontSize(nil, frame, height)
        end
    end
    self.savedFontSizes = {}
end

chat.ApplyBlizzardSettings = function(self)
    if not self.Data:GetValue('tookOverSettings') then
        self.Data:SetValue('savedShowTimestamps', GetTimestampSetting())
        self.Data:SetValue('savedClassColorOverride', GetCVar('chatClassColorOverride'))
        self.Data:SetValue('tookOverSettings', true)
    end
    SetTimestampSetting('none')
    SetCVar('chatClassColorOverride', self.Data:GetValue('classColor') and '0' or '1')
end

chat.RestoreBlizzardSettings = function(self)
    if not self.Data:GetValue('tookOverSettings') then
        return
    end
    local timestamps = self.Data:GetValue('savedShowTimestamps')
    if timestamps ~= nil then
        SetTimestampSetting(timestamps)
    end
    local classColor = self.Data:GetValue('savedClassColorOverride')
    if classColor ~= nil then
        SetCVar('chatClassColorOverride', classColor)
    end
    self.Data:SetValue('tookOverSettings', false)
end

local function OpenTabColor(chatFrame, tab)
    local r, g, b = skin:ResolveTabColor(chatFrame, tab)
    local function Apply(nextR, nextG, nextB)
        chat:SaveTabColor(chatFrame:GetID(), nextR, nextG, nextB)
        if tab and FCFTab_UpdateColors then
            local selected = not chatFrame.isDocked
                or (GENERAL_CHAT_DOCK and chatFrame == FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK))
            FCFTab_UpdateColors(tab, selected)
        end
    end

    local colorInfo = {
        r = r,
        g = g,
        b = b,
        hasOpacity = false,
        swatchFunc = function()
            if ColorPickerFrame.GetColorRGB then
                Apply(ColorPickerFrame:GetColorRGB())
            end
        end,
        cancelFunc = function()
            local previous = ColorPickerFrame.previousValues
            if previous then
                Apply(previous.r, previous.g, previous.b)
            end
        end,
    }

    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow(colorInfo)
        return
    end

    ColorPickerFrame.previousValues = { r = r, g = g, b = b }
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.func = colorInfo.swatchFunc
    ColorPickerFrame.cancelFunc = colorInfo.cancelFunc
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Show()
end

chat.RegisterTabMenu = function(self)
    if self.tabMenuHandle or not Menu or not Menu.ModifyMenu then
        return
    end
    self.tabMenuHandle = Menu.ModifyMenu('MENU_FCF_TAB', function(owner, rootDescription)
        if not chat.enabled or not rootDescription or not rootDescription.CreateColorSwatch then
            return
        end
        if not owner or not owner.GetID or not FCF_GetChatFrameByID then
            return
        end
        local chatFrame = FCF_GetChatFrameByID(owner:GetID())
        if not chatFrame then
            return
        end
        local r, g, b = skin:ResolveTabColor(chatFrame, owner)
        local colorInfo = {
            r = r,
            g = g,
            b = b,
            hasOpacity = false,
        }
        rootDescription:CreateColorSwatch('Tab Color', function()
            OpenTabColor(chatFrame, owner)
        end, colorInfo)
    end)
end

chat.UnregisterTabMenu = function(self)
    local handle = self.tabMenuHandle
    if not handle then
        return
    end
    if handle.Unregister and pcall(handle.Unregister, handle) then
        self.tabMenuHandle = nil
    end
end

chat.Refresh = function(self)
    if not self.enabled then
        return
    end
    EXUI:GetModule('chat-window'):Refresh()
end

chat.Enable = function(self)
    if self.enabled then
        self:Refresh()
        return
    end
    self.enabled = true
    self:RestoreFontSize()
    self:RestoreBlizzardSettings()
    EXUI:GetModule('chat-window'):Enable()
end

chat.Disable = function(self)
    if not self.enabled then
        return
    end
    self.enabled = false
    EXUI:GetModule('chat-window'):Disable()
    self:RestoreFontSize()
    self:RestoreBlizzardSettings()
end

chat.Init = function(self)
    self.Data:UpdateDefaults(self:GetDefaults())
    optionsController:RegisterModule(self)
    if self.Data:GetValue('enable') then
        if IsLoggedIn() then
            self:Enable()
        else
            EXUI:RegisterEventHandler('PLAYER_LOGIN', 'exui-chat-enable', function()
                EXUI:UnregisterEventHandler('PLAYER_LOGIN', 'exui-chat-enable')
                if self.Data:GetValue('enable') and not self.enabled then
                    self:Enable()
                end
            end)
        end
    end
end

chat.GetName = function()
    return 'Chat'
end

chat.GetOrder = function()
    return 56
end

chat.GetProfileExportSpec = function()
    return { id = 'chat', keys = { 'chat' } }
end

chat.GetDefaults = function()
    return {
        enable = false,
        tabSide = 'top',
        editBoxSide = 'bottom',
        timestamp = 'hms24',
        showTimestamp = true,
        timestampPlace = 'inline',
        timestampAlign = 'left',
        messageAlign = 'left',
        timestampColor = { r = 0.62, g = 0.58, b = 0.52 },
        timestampFontSize = 12,
        classColor = true,
        showChannelTags = false,
        activeTabText = { r = 1, g = 1, b = 1 },
        inactiveTabText = { r = 0.54, g = 0.50, b = 0.46 },
        hideAfter = 0,
        whisperSound = false,
        whisperSoundFile = BLIZZARD_WHISPER_SOUND,
        backgroundAlpha = 70,
        tabColors = {},
        tookOverSettings = false,
        width = 460,
        height = 230,
        anchorPoint = 'BOTTOMLEFT',
        relativeAnchor = 'BOTTOMLEFT',
        xOffset = 24,
        yOffset = 24,
    }
end

local function SideOptions()
    return {
        top = { label = 'Top', order = 1 },
        bottom = { label = 'Bottom', order = 2 },
    }
end

local function TimestampOptions()
    local options = {}
    for _, entry in ipairs(TIMESTAMP_ORDER) do
        options[entry.key] = { label = entry.label, order = entry.order }
    end
    return options
end

local function TimestampPlaceOptions()
    return {
        inline = { label = 'Beside Message', order = 1 },
        above = { label = 'Above Message', order = 2 },
        below = { label = 'Below Message', order = 3 },
    }
end

local function SideAlignOptions()
    return {
        left = { label = 'Left', order = 1 },
        right = { label = 'Right', order = 2 },
    }
end

chat.GetTabs = function()
    return {
        { ID = 'layout', label = 'Layout' },
        { ID = 'messages', label = 'Messages' },
        { ID = 'tabs', label = 'Tabs' },
    }
end

local function ColorValue(r, g, b)
    return { r = r, g = g, b = b, a = 1 }
end

local function StoreColor(value)
    return {
        r = value.r or value[1] or 1,
        g = value.g or value[2] or 1,
        b = value.b or value[3] or 1,
    }
end

chat.GetOptions = function(self, currTabID)
    local enabled = function()
        return self.Data:GetValue('enable')
    end
    local showTimestamp = function()
        return enabled() and self.Data:GetValue('showTimestamp') ~= false
    end

    if currTabID == 'messages' then
        return {
            {
                type = 'title',
                label = 'Message',
                width = 100,
                depends = enabled,
            },
            {
                type = 'dropdown',
                label = 'Align',
                name = 'messageAlign',
                width = 50,
                depends = enabled,
                options = SideAlignOptions(),
                currentValue = function()
                    return self:GetMessageAlign()
                end,
                onChange = function(value)
                    self.Data:SetValue('messageAlign', value)
                    self:Refresh()
                end,
            },
            {
                type = 'title',
                label = 'Timestamp',
                width = 100,
                depends = enabled,
            },
            {
                type = 'toggle',
                label = 'Show Timestamp',
                name = 'showTimestamp',
                width = 50,
                depends = enabled,
                currentValue = function()
                    return self.Data:GetValue('showTimestamp') ~= false
                end,
                onChange = function(value)
                    self.Data:SetValue('showTimestamp', value)
                    optionsFields:RefreshOptions()
                    self:Refresh()
                end,
            },
            {
                type = 'dropdown',
                label = 'Format',
                name = 'timestamp',
                width = 50,
                depends = showTimestamp,
                options = TimestampOptions(),
                currentValue = function()
                    return self.Data:GetValue('timestamp') or 'hms24'
                end,
                onChange = function(value)
                    self.Data:SetValue('timestamp', value)
                    self:Refresh()
                end,
            },
            {
                type = 'color-picker',
                label = 'Color',
                name = 'timestampColor',
                width = 50,
                depends = showTimestamp,
                currentValue = function()
                    local r, g, b = self:GetTimestampColor()
                    return ColorValue(r, g, b)
                end,
                onChange = function(value)
                    self.Data:SetValue('timestampColor', StoreColor(value))
                    self:Refresh()
                end,
            },
            {
                type = 'range',
                label = 'Size',
                name = 'timestampFontSize',
                min = 8,
                max = 24,
                step = 1,
                width = 50,
                depends = showTimestamp,
                currentValue = function()
                    return self:GetTimestampFontSize()
                end,
                onChange = function(value)
                    self.Data:SetValue('timestampFontSize', value)
                    self:Refresh()
                end,
            },
            {
                type = 'dropdown',
                label = 'Place',
                name = 'timestampPlace',
                width = 50,
                depends = showTimestamp,
                options = TimestampPlaceOptions(),
                currentValue = function()
                    return self:GetTimestampPlace()
                end,
                onChange = function(value)
                    self.Data:SetValue('timestampPlace', value)
                    self:Refresh()
                end,
            },
            {
                type = 'dropdown',
                label = 'Align',
                name = 'timestampAlign',
                width = 50,
                depends = showTimestamp,
                options = SideAlignOptions(),
                currentValue = function()
                    return self:GetTimestampAlign()
                end,
                onChange = function(value)
                    self.Data:SetValue('timestampAlign', value)
                    self:Refresh()
                end,
            },
            {
                type = 'title',
                label = 'Names',
                width = 100,
                depends = enabled,
            },
            {
                type = 'toggle',
                label = 'Channel Tags',
                name = 'showChannelTags',
                width = 50,
                depends = enabled,
                currentValue = function()
                    return self:ShowChannelTags()
                end,
                onChange = function(value)
                    self.Data:SetValue('showChannelTags', value)
                    self:Refresh()
                end,
            },
            {
                type = 'toggle',
                label = 'Class Colored Names',
                name = 'classColor',
                width = 50,
                depends = enabled,
                currentValue = function()
                    return self:UseClassColor()
                end,
                onChange = function(value)
                    self.Data:SetValue('classColor', value)
                    self:Refresh()
                end,
            },
            {
                type = 'title',
                label = 'Fading',
                width = 100,
                depends = enabled,
            },
            {
                type = 'range',
                label = 'Fade Messages After',
                name = 'hideAfter',
                min = 0,
                max = 300,
                step = 5,
                width = 50,
                depends = enabled,
                currentValue = function()
                    return self:GetHideAfter()
                end,
                onChange = function(value)
                    self.Data:SetValue('hideAfter', value)
                    self:Refresh()
                end,
            },
            {
                type = 'title',
                label = 'Whisper Sound',
                width = 100,
                depends = enabled,
            },
            {
                type = 'toggle',
                label = 'Play Sound On Whisper',
                name = 'whisperSound',
                width = 50,
                depends = enabled,
                currentValue = function()
                    return self.Data:GetValue('whisperSound') == true
                end,
                onChange = function(value)
                    self.Data:SetValue('whisperSound', value)
                    optionsFields:RefreshOptions()
                end,
            },
            {
                type = 'dropdown',
                label = 'Sound',
                name = 'whisperSoundFile',
                width = 50,
                depends = function()
                    return enabled() and self.Data:GetValue('whisperSound') == true
                end,
                getOptions = WhisperSoundOptions,
                currentValue = function()
                    return self:GetWhisperSound()
                end,
                onChange = function(value)
                    self.Data:SetValue('whisperSoundFile', value)
                    PlayWhisperSoundKey(value)
                end,
            },
        }
    end

    if currTabID == 'tabs' then
        return {
            {
                type = 'title',
                label = 'Text',
                width = 100,
                depends = enabled,
            },
            {
                type = 'color-picker',
                label = 'Active',
                name = 'activeTabText',
                width = 50,
                depends = enabled,
                currentValue = function()
                    local r, g, b = self:GetActiveTabTextColor()
                    return ColorValue(r, g, b)
                end,
                onChange = function(value)
                    self.Data:SetValue('activeTabText', StoreColor(value))
                    self:Refresh()
                end,
            },
            {
                type = 'color-picker',
                label = 'Inactive',
                name = 'inactiveTabText',
                width = 50,
                depends = enabled,
                currentValue = function()
                    local r, g, b = self:GetInactiveTabTextColor()
                    return ColorValue(r, g, b)
                end,
                onChange = function(value)
                    self.Data:SetValue('inactiveTabText', StoreColor(value))
                    self:Refresh()
                end,
            },
        }
    end

    return {
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            width = 100,
            currentValue = function()
                return self.Data:GetValue('enable')
            end,
            onChange = function(value)
                self.Data:SetValue('enable', value)
                optionsFields:RefreshOptions()
                if value then
                    self:Enable()
                else
                    self:Disable()
                end
            end,
        },
        {
            type = 'title',
            label = 'Size',
            width = 100,
            depends = enabled,
        },
        {
            type = 'range',
            label = 'Width',
            name = 'width',
            min = 280,
            max = 900,
            step = 10,
            width = 50,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('width') or 460
            end,
            onChange = function(value)
                self.Data:SetValue('width', value)
                self:Refresh()
            end,
        },
        {
            type = 'range',
            label = 'Height',
            name = 'height',
            min = 160,
            max = 700,
            step = 10,
            width = 50,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('height') or 230
            end,
            onChange = function(value)
                self.Data:SetValue('height', value)
                self:Refresh()
            end,
        },
        {
            type = 'range',
            label = 'Background Opacity',
            name = 'backgroundAlpha',
            min = 0,
            max = 100,
            step = 5,
            width = 50,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('backgroundAlpha') or 70
            end,
            onChange = function(value)
                self.Data:SetValue('backgroundAlpha', value)
                self:Refresh()
            end,
        },
        {
            type = 'title',
            label = 'Placement',
            width = 100,
            depends = enabled,
        },
        {
            type = 'dropdown',
            label = 'Tab Side',
            name = 'tabSide',
            width = 50,
            depends = enabled,
            options = SideOptions(),
            currentValue = function()
                return self:GetTabSide()
            end,
            onChange = function(value)
                self.Data:SetValue('tabSide', value)
                self:Refresh()
            end,
        },
        {
            type = 'dropdown',
            label = 'Edit Box Side',
            name = 'editBoxSide',
            width = 50,
            depends = enabled,
            options = SideOptions(),
            currentValue = function()
                return self:GetEditBoxSide()
            end,
            onChange = function(value)
                self.Data:SetValue('editBoxSide', value)
                self:Refresh()
            end,
        },
        {
            type = 'title',
            label = 'Position',
            width = 100,
            depends = enabled,
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'anchorPoint',
            width = 50,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('anchorPoint') or 'BOTTOMLEFT'
            end,
            onChange = function(value)
                self.Data:SetValue('anchorPoint', value)
                self:Refresh()
            end,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor',
            name = 'relativeAnchor',
            width = 50,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('relativeAnchor') or 'BOTTOMLEFT'
            end,
            onChange = function(value)
                self.Data:SetValue('relativeAnchor', value)
                self:Refresh()
            end,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'xOffset',
            min = -2000,
            max = 2000,
            step = 1,
            width = 50,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('xOffset') or 24
            end,
            onChange = function(value)
                self.Data:SetValue('xOffset', value)
                self:Refresh()
            end,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'yOffset',
            min = -2000,
            max = 2000,
            step = 1,
            width = 50,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('yOffset') or 24
            end,
            onChange = function(value)
                self.Data:SetValue('yOffset', value)
                self:Refresh()
            end,
        },
    }
end
