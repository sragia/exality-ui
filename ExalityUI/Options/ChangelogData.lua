---@class ExalityUI
local EXUI = select(2, ...)

EXUI.changelog = [[
# |cffdb49000.2.0|r - "The Previews" Update

## A lot of improvements for previewing each element for unitframes.

- Fix buffs and debuffs CD font settings being shared between units.
- Add additional aura display to all UFs. Disabled by default.
- Fix issue where raid frame flickers on screen on zone change.
- Improve Party/Raid preview to include all units
- Make aura previews toggleable in the options instead of showing no matter what.
- Update oUF to latest version, which includes updates to many icons that show up on UFs
- Add previewing for almost all of the elements that can be seen on UFs, excluding text elements.
- Fix issue where encounter timer would not stop after finishing encounter

# |cffdb49000.1.4|r

- Add support for NSRT nicknames via custom tag [nsrt-name]
- Fix duplicate friends showing up in friends broker.
- Update oUF for 12.0.1 compatibility.

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
