---@class ExalityUI
local EXUI = select(2, ...)

local LDB = LibStub:GetLibrary('LibDataBroker-1.1')

local getGold = function()
    local money = GetMoney()
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100

    local parts = {}
    if gold > 0 or money >= 500000 then
        table.insert(parts, string.format('%s|cffed9a00g|r', EXUI.utils.formatNumberWithCommas(gold)))
    end
    if money < 500000 and (silver > 0 or money >= 5000) then
        table.insert(parts, string.format('%d|cffc7c7cfs|r', silver))
    end
    if money < 5000 then
        table.insert(parts, string.format('%d|cffeda55fc|r', copper))
    end
    return table.concat(parts, ' ')
end

local data = {
    type = 'data source',
    text = getGold(),
}

EXUI:RegisterEventHandler({ 'PLAYER_MONEY', 'PLAYER_ENTERING_WORLD' }, 'gold-broker', function()
    data.text = getGold()
end)

LDB:NewDataObject('EXUI: Gold', data)
