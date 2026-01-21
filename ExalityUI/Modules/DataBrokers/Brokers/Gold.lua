---@class ExalityUI
local EXUI = select(2, ...)

local LDB = LibStub:GetLibrary('LibDataBroker-1.1')

local getGold = function()
    local money = GetMoney()
    local gold = math.floor(money / 10000)
    return string.format('%s|cffed9a00g|r', EXUI.utils.formatNumberWithCommas(gold))
end

local data = {
    type = 'data source',
    text = getGold(),
}

EXUI:RegisterEventHandler('PLAYER_MONEY', 'gold-broker', function()
    data.text = getGold()
end)

LDB:NewDataObject('EXUI: Gold', data)
