---@class ExalityUI
local EXUI = select(2, ...)

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

LSM:Register('font', 'DMSans', EXUI.const.fonts.DEFAULT)
LSM:Register('font', 'Bahnschrift', EXUI.const.fonts.Bahnschrift)
LSM:Register('statusbar', 'ExalityUI Status Bar', [[Interface/Addons/ExalityUI/Assets/Images/StatusBar/statusBar]])
