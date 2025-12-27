---@class ExalityUI
local EXUI = select(2, ...)

local LDB = LibStub:GetLibrary('LibDataBroker-1.1')

local data = {
    type = 'data source',
    text = date('%H:%M'),
}

local function updateTime()
    local time = date('%H:%M')
    data.text = time
end
local untilNextMinute = 60 - tonumber(date('%S'))

C_Timer.After(untilNextMinute, function()
    updateTime()
    C_Timer.NewTicker(60, updateTime)
end)

LDB:NewDataObject('EXUI: Clock', data)
