---@class ExalityUI
local EXUI = select(2, ...)

---@class Data
local data = EXUI:GetModule('data')
---@class OptionsMain
local optionsMain = EXUI:GetModule('options-main')

----------------

---@class Cmd
local cmd = EXUI:GetModule('cmd')

local libDB = LibStub("LibDBIcon-1.0")
local libDataBroker = LibStub("LibDataBroker-1.1")

SLASH_EXALITYUI1 = '/exui'
function SlashCmdList.EXALITYUI(msg)
    if (msg == 'test') then
        EXUI.utils.printOut('Test')
    else
        optionsMain:Show()
    end
end

local dataBroker = libDataBroker:NewDataObject('ExalityUI', {
    type = "data source",
    text = 'ExalityUI',
    icon = [[Interface\AddOns\ExalityUI\Assets\Images\logo_icon.png]],
    OnClick = function(self, button)
        if (button == 'LeftButton') then
            optionsMain:Show()
        elseif (button == 'RightButton') then
            optionsMain:Show()
        end
    end
})

cmd.Init = function(self)
    local showMinimap = data:GetDataByKey('showMinimap')
    libDB:Register('ExalityUI', dataBroker, { show = showMinimap })
    self:RefreshMinimap();
end

cmd.RefreshMinimap = function(self)
    local showMinimap = data:GetDataByKey('showMinimap')
    if (showMinimap) then
        C_Timer.After(1, function()
            libDB:Show('ExalityUI')
        end)
    else
        C_Timer.After(1, function()
            libDB:Hide('ExalityUI')
        end)
    end
end
