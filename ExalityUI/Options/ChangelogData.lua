---@class ExalityUI
local EXUI = select(2, ...)

EXUI.changelog = [[
# |cffdb49000.1.4|r

- Add support for NSRT nicknames via custom tag [nsrt-name]
- Fix duplicate friends showing up in friends broker.

# |cffdb49000.1.3|r

- Fix ilvl for default character frame Improvements.
- Fix ilvl text in custom Character Frame, to correctly display the bag ilvl.
- Update battle ress display more often to detect charge changes more reliably.
- Small option improvements.
- Add filter options to buffs/debuffs elements. Note: Either Buffs or Debuffs always need to be enabled to see any auras. You can use other filters to filter them down further. Also some filter options only work on 12.0.1 patch.
- Add options to customize castbar's spark and empowered stage width and color.

# |cffdb49000.1.2|r

- Fix ilvl for available items in custom Character Frame
- Fixing profile creation
- Rework how custom Character Frame is shown, to allow default character frame to be shown in combat
- Update defaults to something more sensible. First time load should result in a more usable UI.
- Fixing Data Broker options breaking if none have been created yet.
- Adding changelog to highlight changes ingame.
]]
