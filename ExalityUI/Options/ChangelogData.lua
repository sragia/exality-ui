---@class ExalityUI
local EXUI = select(2, ...)

EXUI.changelog = [[
# |cffdb49000.5.0|r

- Visual update for options.
- Added minimap styling.
- Pixel Perfect improvements.
- [Skins] Multiple blizzard windows are now skinned.
- [Raid Tools] Battle Res rewrite — masked icon, configurable timer position, visibility modes.
- [Character Frame] Fix stats issue with secrets.
- [Action Bars] Implemented Action Bar initial version. Might have some bugs, so be aware of it.
- [Aura Displays] New module for displaying auras anywhere on your screen. Apply filters and modify their look however you want.
- [Aura Displays] Added bar display style per group with configurable fill, track, border, side icon, spell name, and duration text.
- [Resource Displays] Updated resource display configs. Way more options to customize
- [Profiles] Profile management moved to the Profiles window (gear icon in options). Export and import now support selecting individual modules.
- [Cooldowns] Updated cooldown configs.
- [Objective Tracker] New module that replaces default Blizzard objective tracker. Adds a bit more options to customize it more.
- [Mythic Plus Timer] New Module for displaying timer. Fairly basic, mostly meant to be as something to use while using Objective Tracker functionality as other M+ Timers will not be able to hide them easily. However there's option to hide my Objective Tracker in M+ setting.
- [Edit Mode] Improved Edit Mode. Added X/Y offset editor. Improve selecting frames that are overlapping. Add Snap mode. Nudge frames with keyboard. Fixed frame sizes for party/raid frames to better match reality.

## UF Aura rework
12.1 adds new Aura system. This brings a lot of nice changes that we can use.
As such whole Aura system has been rewritten, and unfortunately what this means is that all auras settings have been nuked.
You will need to redo them, sorry. But there's way more adjustments you can do now.

For example, you can make as many different displays on the Unit Frames as you want. You can re-use same display for multiple units. You can apply more powerful filters. And much more...

# |cffdb49000.2.8|r

- [Unit Frames] Update oUF to 13.4.5.
- [General] Fix missing LibDBIcon library.

Note: If after the patch you can't target anyone by clicking on the unit frame, go into Options > Gameplay Enhancements > Click Casting > Set keybind to Target Unit Frame.

# |cffdb49000.2.7|r

- Some quick fixes for 12.0.5 compatibility.

# |cffdb49000.2.6|r

- [Skins] Add basic bigwigs bar skin. Basically adds border and darker background.
- [Unit Frames] Update oUF to 13.3.2 to fix private aura issues.

# |cffdb49000.2.5|r

- [Unit Frames] Add missed preview option for Dispel Overlay.
- [Unit Frames] Fix issue where player frame previews wouldn't hide on window close.
- [Character Frame] Equipment popout now limits to 10 items due to some issue where it causes freezes with more items.
- [Character Frame] Increase window height slightly to accomodate specs with more stats showing.

# |cffdb49000.2.4|r

- [Character Frame] Equipment popout small improvements
- [Unit Frames] Fix issue where party/raid frames still enabled elements in background when they should be disabled. Should improve performance a bit.
- [Unit Frames] New UF element - Dispel Overlay. Shows a colored overlay on the unit frame when dispellable auras are present, that you can dispel. This is enabled by default for Raid and Party frames.
- [Unit Frames] Update oUF to 13.3.1
- [Brezz] Only show in encounters in raid
- [Media] Add new absorb bar texture
- [Character Frame] Add crest display

# |cffdb49000.2.3|r

- Bunch of small fixes for spotted errors during leveling.

# |cffdb49000.2.2|r

- [Broker] Fix issue with guild broker throwing error when API doesnt return zone for player
- [Unit Frames] Update oUF to 13.3.0
- [Skins] Adjust tooltip skinning to not taint from loot frame
- [Unit Frames] Update NSRT nickname tag on nickname update
- [Tweaks] Remove quest tracking bugfix which is causing more issues than it fixes.

# |cffdb49000.2.1|r

- Update visuals of Anchor Point inputs and titles.
- New option "Smooth Health Color" for UFs. Uses smooth gradient to color the health bar based on the unit's current health percentage.
- Adjust menu sidebar in options
- Fix issue with custom text offsets not updating.
- Fix issue with group role indicator preview not showing.
- Add Notifications which will be used for other modules to show notifications (Disabled by default).
- Add Tweaks and Bugfixes module which will be used for some small tweaks or bugfixes in UI. (All are disabled by default). Not much added here yet, but core framework is in place to add more easily in future.

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
