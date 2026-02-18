---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUINotifications
local Notifications = EXUI:GetModule('notifications')

---@class EXUITweaksAndBugfixes
local tweaksAndBugfixes = EXUI:GetModule('tweaks-and-bugfixes')

tweaksAndBugfixes.tweaks = {}

tweaksAndBugfixes.Init = function(self)
    optionsController:RegisterModule(self)
    self.Data:UpdateDefaults({});

    for key, tweak in pairs(self.tweaks) do
        if (self.Data:GetValue(key)) then
            tweak:enable()
        else
            tweak:disable()
        end
    end
end

tweaksAndBugfixes.Data = data:GetControlsForKey('tweaks-and-bugfixes')

tweaksAndBugfixes.GetName = function(self)
    return 'Tweaks/Bugfixes'
end

tweaksAndBugfixes.GetCategory = function(self)
    return 'Quality of Life'
end

tweaksAndBugfixes.GetOrder = function(self)
    return 90
end

tweaksAndBugfixes.GetOptions = function(self)
    local options = {
        {
            type = 'description',
            label = 'For many of these, Notifications need to be enabled to show anything.',
            width = 100
        }
    }
    local tweakOptions = {}
    local bugOptions = {}

    for key, tweak in pairs(self.tweaks) do
        if (tweak.type == 'tweak') then
            table.insert(tweakOptions, {
                type = 'toggle',
                label = tweak.name,
                name = key,
                onChange = function(value)
                    self.Data:SetValue(key, value)
                    self:RefreshTweak(key)
                end,
                currentValue = function()
                    return self.Data:GetValue(key)
                end,
                width = 100
            });
            if (tweak.description) then
                table.insert(tweakOptions, {
                    type = 'description',
                    label = tweak.description,
                    width = 100
                });
            end
        elseif (tweak.type == 'bug') then
            table.insert(bugOptions, {
                type = 'toggle',
                label = tweak.name,
                name = key,
                onChange = function(value)
                    self.Data:SetValue(key, value)
                    self:RefreshTweak(key)
                end,
                currentValue = function()
                    return self.Data:GetValue(key)
                end,
            });
            if (tweak.description) then
                table.insert(bugOptions, {
                    type = 'description',
                    label = tweak.description,
                    width = 100
                });
            end
        end
    end

    if (#tweakOptions > 0) then
        table.insert(options, {
            type = 'title',
            label = 'Tweaks',
            width = 100
        })
        EXUI.utils.spreadTable(options, tweakOptions)
    end
    if (#bugOptions > 0) then
        table.insert(options, {
            type = 'title',
            label = 'Bugfixes',
            width = 100
        })
        EXUI.utils.spreadTable(options, bugOptions)
    end

    return options
end

tweaksAndBugfixes.RefreshTweak = function(self, key)
    if (not self.tweaks[key]) then return end
    local tweak = self.tweaks[key]

    if (self.Data:GetValue(key)) then
        tweak:enable()
    else
        tweak:disable()
    end
end

---@param tweak { name: string, type: 'bug' | 'tweak', enable: function, disable: function, description?: string }
tweaksAndBugfixes.RegisterTweak = function(self, key, tweak)
    self.tweaks[key] = tweak
end


tweaksAndBugfixes:RegisterTweak('quest-bug', {
    name = 'Quest Tracking FPS Bugfix',
    type = 'bug',
    description =
    '"Fixes" issue where you lose FPS due to SUPER_TRACKING_PATH_UPDATED event spam.\n WARNING: This will untrack all of your quests if triggered. Will trigger automatically when issue is noticed.',
    enable = function()
        EXUI:UnregisterEventHandler('SUPER_TRACKING_PATH_UPDATED', 'quest-tracking-bugfix') -- Just in case enable is called twice
        local count = 0
        local lastTriggered = 0
        local UnwatchEverything = function()
            for i = 1, C_QuestLog.GetNumQuestWatches() do
                local qID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
                if qID then
                    C_QuestLog.RemoveQuestWatch(qID)
                end
            end
        end

        EXUI:RegisterEventHandler('SUPER_TRACKING_PATH_UPDATED', 'quest-tracking-bugfix', function()
            local now = time()
            if (now - lastTriggered > 2) then
                count = 0
            else
                count = count + 1
                if (count > 20) then
                    UnwatchEverything()
                    count = 0
                    EXUI.utils.printOut('Quest Tracking FPS Bugfix triggered. Unwatching all quests...')
                end
            end
            lastTriggered = now
        end)
    end,
    disable = function()
        EXUI:UnregisterEventHandler('SUPER_TRACKING_PATH_UPDATED', 'quest-tracking-bugfix')
    end,
})

tweaksAndBugfixes:RegisterTweak('repair-notification', {
    name = 'Repair notification (<20%)',
    type = 'tweak',
    enable = function()
        local isNotificationActive = false

        local CheckDurability = function()
            local minDurability = 100
            for _, slotId in ipairs({ 1, 3, 5, 6, 7, 8, 9, 10, 16, 17 }) do
                local min, max = GetInventoryItemDurability(slotId)
                if (min) then
                    local perc = (min / max) * 100
                    minDurability = math.min(minDurability, perc)
                end
            end
            if (minDurability < 20 and not isNotificationActive) then
                isNotificationActive = true
                Notifications:Add({
                    id = 'repair-notification',
                    message = '|cffffd200Repair!|r',
                    icon = 132281
                })
            elseif (isNotificationActive and minDurability >= 20) then
                isNotificationActive = false
                Notifications:Remove('repair-notification')
            end
        end

        EXUI:RegisterEventHandler({ 'UPDATE_INVENTORY_DURABILITY', 'PLAYER_ENTERING_WORLD' }, 'repair-notification',
            function()
                CheckDurability()
            end
        )
        CheckDurability()
    end,
    disable = function()
        EXUI:UnregisterEventHandler({ 'UPDATE_INVENTORY_DURABILITY', 'PLAYER_ENTERING_WORLD' }, 'repair-notification')
        Notifications:Remove('repair-notification')
    end,
})

tweaksAndBugfixes:RegisterTweak('almost-full-bags', {
    name = 'Low bag space notification (<5 slots)',
    type = 'tweak',
    enable = function()
        EXUI:RegisterEventHandler('BAG_UPDATE_DELAYED', 'almost-full-bags', function()
            local freeSlots = 0
            for i = 0, 4 do
                local free = C_Container.GetContainerNumFreeSlots(i)
                freeSlots = freeSlots + free
            end

            if (freeSlots < 5) then
                if (not Notifications:IsActive('almost-full-bags')) then
                    Notifications:Add({
                        id = 'almost-full-bags',
                        duration = 4,
                        message = string.format("|cffffffff%s|r slot/s left!", freeSlots),
                        icon = 133644
                    })
                else
                    Notifications:UpdateMessage('almost-full-bags',
                        string.format("|cffffffff%s|r slot/s left!", freeSlots))
                end
            elseif (Notifications:IsActive('almost-full-bags')) then
                Notifications:Remove('almost-full-bags')
            end
        end)
    end,
    disable = function()
        EXUI:UnregisterEventHandler('BAG_UPDATE_DELAYED', 'almost-full-bags')
        Notifications:Remove('almost-full-bags')
    end,
})
