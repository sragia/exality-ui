---@class ExalityUI
local EXUI = select(2, ...)

local LDB = LibStub:GetLibrary('LibDataBroker-1.1')

local getFPS = function()
    return string.format('%dfps', GetFramerate())
end

local data = {
    type = 'data source',
    text = getFPS(),
}

local function updateFPS()
    data.text = getFPS()
end

C_Timer.NewTicker(1, updateFPS)

LDB:NewDataObject('EXUI: FPS', data)
