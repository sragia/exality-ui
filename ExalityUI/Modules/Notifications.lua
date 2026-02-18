---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIData
local data = EXUI:GetModule('data')

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUINotifications
local notifications = EXUI:GetModule('notifications')

notifications.active = {}
notifications.frames = {}
notifications.pool = nil
notifications.anchor = nil
notifications.previewActive = false
notifications.fadeOutDuration = 0.2

notifications.Init = function(self)
    optionsController:RegisterModule(self)
    self.pool = CreateFramePool('Frame', UIParent)

    self.Data:UpdateDefaults({
        enable = false,
        anchor = 'TOP',
        relativeAnchor = 'TOP',
        XOff = 0,
        YOff = -300,
        spacing = 2,
        font = 'DMSans',
        fontSize = 16,
        fontFlag = 'OUTLINE',
        iconSize = 30,
    })

    if (self.Data:GetValue('enable')) then
        self:Enable()
    else
        self:Disable()
    end
end

notifications.Data = data:GetControlsForKey('notifications')

notifications.GetName = function(self)
    return 'Notifications'
end

notifications.GetCategory = function(self)
    return 'Quality of Life'
end

notifications.GetOrder = function(self)
    return 100
end

notifications.GetOptions = function(self)
    return {
        {
            type = 'title',
            label = 'Notifications',
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            onChange = function(value)
                self.Data:SetValue('enable', value)
                if (value) then
                    self:Enable()
                    self:Add({
                        id = 'enabled-notifications',
                        message = 'Notifications are enabled',
                        duration = 5,
                        icon = EXUI.const.textures.logo,
                    })
                else
                    self:Disable()
                end

                optionsFields:RefreshOptions()
            end,
            currentValue = function()
                return self.Data:GetValue('enable')
            end,
            width = 100,
        },
        {
            type = 'description',
            width = 100,
            label =
            'These options only control how Notifications will look, or if they are enabled at all. Actual notifications come from other settings that you can enable. By default no notifications will be triggered unless you enable them.'
        },
        {
            type = 'button',
            label = 'Toggle Preview',
            name = 'preview',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            onClick = function()
                self:Preview()
            end,
            color = EXUI.const.colors.accent,
            width = 20,
        },
        {
            type = 'title',
            label = 'Position',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            width = 100,
            accent = EXUI.const.colors.accentSecondary
        },
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = 'anchor',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('anchor')
            end,
            onChange = function(value)
                self.Data:SetValue('anchor', value)
                self:UpdatePosition()
            end,
            width = 23,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = 'relativeAnchor',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('relativeAnchor')
            end,
            onChange = function(value)
                self.Data:SetValue('relativeAnchor', value)
                self:UpdatePosition()
            end,
            width = 23,
        },
        {
            type = 'spacer',
            width = 54,
        },
        {
            type = 'range',
            label = 'X Offset',
            name = 'XOff',
            min = -1000,
            max = 1000,
            step = 1,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('XOff')
            end,
            onChange = function(value)
                self.Data:SetValue('XOff', value)
                self:UpdatePosition()
            end,
            width = 23,
        },
        {
            type = 'range',
            label = 'Y Offset',
            name = 'YOff',
            min = -1000,
            max = 1000,
            step = 1,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('YOff')
            end,
            onChange = function(value)
                self.Data:SetValue('YOff', value)
                self:UpdatePosition()
            end,
            width = 23,
        },
        {
            type = 'spacer',
            width = 54,
        },
        {
            type = 'range',
            label = 'Spacing',
            name = 'spacing',
            min = 0,
            max = 100,
            step = 1,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('spacing')
            end,
            onChange = function(value)
                self.Data:SetValue('spacing', value)
                self:Refresh()
            end,
            width = 23,
        },
        {
            type = 'title',
            label = 'Style',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            width = 100,
            accent = EXUI.const.colors.accentSecondary
        },
        {
            type = 'dropdown',
            label = 'Font',
            name = 'font',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            getOptions = function()
                local fonts = LSM:List('font')
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            currentValue = function()
                return self.Data:GetValue('font')
            end,
            onChange = function(value)
                self.Data:SetValue('font', value)
                self:UpdateActiveStyles()
            end,
            width = 25,
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = 'fontFlag',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return self.Data:GetValue('fontFlag')
            end,
            onChange = function(value)
                self.Data:SetValue('fontFlag', value)
                self:UpdateActiveStyles()
            end,
            width = 25,
        },
        {
            type = 'range',
            label = 'Font Size',
            name = 'fontSize',
            min = 1,
            max = 40,
            step = 1,
            depends = function()
                return self.Data:GetValue('enable')
            end,
            currentValue = function()
                return self.Data:GetValue('fontSize')
            end,
            onChange = function(value)
                self.Data:SetValue('fontSize', value)
                self:UpdateActiveStyles()
            end,
            width = 25,
        },
        {
            type = 'spacer',
            width = 25,
        },
        {
            type = 'range',
            label = 'Icon Size',
            name = 'iconSize',
            depends = function()
                return self.Data:GetValue('enable')
            end,
            min = 1,
            max = 100,
            step = 1,
            currentValue = function()
                return self.Data:GetValue('iconSize')
            end,
            onChange = function(value)
                self.Data:SetValue('iconSize', value)
                self:UpdateActiveStyles()
            end,
            width = 23,
        }
    }
end

--- Add New notification to show
---@param notification { id: string, message: string, duration: number, icon?: string}
notifications.Add = function(self, notification)
    if (not self.Data:GetValue('enable')) then return end

    table.insert(self.active, notification)
    self:Refresh()
end

notifications.Remove = function(self, id)
    for i, notification in ipairs(self.active) do
        if (notification.id == id) then
            table.remove(self.active, i)

            for idx, f in ipairs(self.frames) do
                if (f.data.id == id) then
                    table.remove(self.frames, idx)
                    f:Destroy()
                    break
                end
            end
            break
        end
    end
    self:Refresh()
end

local function StyleNotification(f)
    if (f.configured) then return end
    f:SetWidth(16)
    f:SetHeight(30)

    local icon = f:CreateTexture(nil, 'ARTWORK')
    icon:SetPoint('LEFT')
    icon:SetSize(16, 16)
    f.icon = icon

    local text = f:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    text:SetPoint('LEFT', f.icon, 'RIGHT', 5, 0)
    text:SetWidth(0)
    f.text = text

    f.SetData = function(self, data)
        self.data = data
        if (data.icon) then
            self.icon:SetTexture(data.icon)
            self.icon:Show()
            self.text:ClearAllPoints()
            self.text:SetPoint('LEFT', f.icon, 'RIGHT', 5, 0)
        else
            self.icon:Hide()
            self.text:ClearAllPoints()
            self.text:SetPoint('LEFT')
        end

        self.text:SetText(data.message)
        self:UpdateHeight()
    end

    f.UpdateHeight = function(self)
        local height = math.max(self.icon:GetHeight(), self.text:GetHeight())
        self:SetHeight(height)
    end

    f.FadeIn = EXUI.utils.animation.fade(f, 0.3, 0, 1)
    f.FadeOut = EXUI.utils.animation.fade(f, notifications.fadeOutDuration, 1, 0)
    f.FadeOut:SetScript('OnFinished', function() notifications.pool:Release(f) end)
    f:SetAlpha(0)

    f.Destroy = function(self)
        if (self.data.timer) then
            self.data.timer:Cancel()
        end
        self.FadeOut:Play()
    end

    f.configured = true
end

notifications.UpdateNotification = function(self, f)
    f.text:SetFont(LSM:Fetch('font', self.Data:GetValue('font')), self.Data:GetValue('fontSize'),
        self.Data:GetValue('fontFlag'))
    f.icon:SetSize(self.Data:GetValue('iconSize'), self.Data:GetValue('iconSize'))
    f:UpdateHeight()
end

notifications.UpdateActiveStyles = function(self)
    for _, f in ipairs(self.frames) do
        self:UpdateNotification(f)
    end

    self:Refresh()
end

notifications.Refresh = function(self)
    if (not self.Data:GetValue('enable')) then return end

    for i, notification in ipairs(self.active) do
        if (not notification.isActive) then
            local f = self.pool:Acquire()
            StyleNotification(f)
            self:UpdateNotification(f)

            if (not notification.timer and notification.duration and notification.duration > 0) then
                notification.timer = C_Timer.NewTimer(notification.duration, function()
                    self:Remove(notification.id)
                end)
            end

            f:SetData(notification)
            f:SetParent(self.anchor)
            table.insert(self.frames, f)
        end
    end

    if (#self.frames > 0) then
        EXUI.utils.organizeFramesInList(self.frames, self.Data:GetValue('spacing'), self.anchor, 0, true)

        for _, f in ipairs(self.frames) do
            if (not f.data.isActive) then
                f.data.isActive = true
                f:SetAlpha(0)
                f.FadeIn:Play()
            end
        end
    end
end

notifications.Preview = function(self)
    if (not self.previewActive) then
        self.previewActive = true
        self:Add({
            id = 'preview',
            message = 'Notifications are enabled',
            duration = 3,
            icon = 236550,
        })

        self:Add({
            id = 'preview2',
            message = 'Preview Message',
            duration = 3,
            icon = 134709,
        })
        self:Add({
            id = 'preview3',
            message = 'Preview Message 2',
            icon = 606552,
        })
        self:Add({
            id = 'preview4',
            message = 'Preview Message 3',
            icon = 1385244,
        })
        self:Add({
            id = 'preview5',
            message = 'Preview Message 4',
        })
    else
        self:Remove('preview')
        self:Remove('preview2')
        self:Remove('preview3')
        self:Remove('preview4')
        self:Remove('preview5')
        self.previewActive = false
    end
end

notifications.UpdatePosition = function(self)
    if (not self.anchor) then return end
    self.anchor:ClearAllPoints()
    EXUI:SetPoint(self.anchor, self.Data:GetValue('anchor'), UIParent, self.Data:GetValue('relativeAnchor'),
        self.Data:GetValue('XOff'), self.Data:GetValue('YOff'))
end

notifications.Enable = function(self)
    if (self.anchor) then
        self.anchor:Show()
    else
        self.anchor = CreateFrame('Frame', nil, UIParent)
        self.anchor:SetSize(100, 40)
    end

    self:UpdatePosition()

    if (not editor:IsFrameRegistered(self.anchor)) then
        editor:RegisterFrameForEditor(self.anchor, 'Notifications', function(f)
            local point, _, relativePoint, xOfs, yOfs = f:GetPoint(1)
            self.Data:SetValue('anchor', point)
            self.Data:SetValue('relativeAnchor', relativePoint)
            self.Data:SetValue('XOff', xOfs)
            self.Data:SetValue('YOff', yOfs)

            self:UpdatePosition()
        end)
    end

    self:Refresh()
end

notifications.Disable = function(self)
    if (self.anchor) then
        self.anchor:Hide()
        for _, f in ipairs(self.frames) do
            f:Destroy()
        end
        self.frames = {}
        editor:UnregisterFrameForEditor(self.anchor)
    end
end
