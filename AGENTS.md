- Anything in ExalityUI/Libs is off bounds. You can't change code in there under any circumstances, unless explicitly allowed
- Do NOT write longwinded comments that add no value to the code base. Code base should be kept clean.
- When dealing with secrets, almost always assume that the code is going to run in secret environment, as such keep secret checks minimal and comform secrets restrictions
- Never taint, and never run logic on secret variables outside legitimate channels — frame functions like `:SetAlphaFromBoolean`, nil checks, curves. If a solution may introduce taint, or its in-game behaviour is unclear due to documentation gaps, give instructions to test and verify in-game.
- Addon Supports both Forever and Retail. Retail's Interface code can be found in WoWUI directory under live branch (unless specified to use different one) and Forever under forever-beta.
- Changes done to Forever or Retail need to be compatible, if feature only works in Retail or Forever it needs to properly be checked with IsForever or IsRetail functions.
- If module is disabled it can't be doing anything. No event registration can take place. Only enabled modules can do processing.
- Don't assume things, ask if not clear.
- Don't go out of scope and change unrelated piece of functionality, if it's required, ask.
- Don't assume things if can't find answer, ask or provide easy way to check in game way to validate functionality.

# WoW UI reference (WoWUI)

This workspace includes **WoWUI** — a local mirror of Blizzard’s WoW interface source. Treat it as the **first and preferred reference** for frames, mixins, widgets, and API behavior.

## Lookup order

1. **WoWUI** (`WoWUI/` workspace root, e.g. `WoWUI/AddOns/...`)
2. **Other workspace addons** (ExalityUI, NHFAuraManager, etc.) for existing patterns
3. **Web** — only when WoWUI does not answer the question

Do **not** search the web for API or Blizzard UI details until you have searched WoWUI (grep/semantic search/read files).

## Where to look in WoWUI

| Need                                  | Path                                                 |
| ------------------------------------- | ---------------------------------------------------- |
| Blizzard frame / mixin implementation | `WoWUI/AddOns/Blizzard_*`                            |
| Generated API signatures & docs       | `WoWUI/AddOns/Blizzard_APIDocumentationGenerated/`   |
| Shared XML / mixins / menu system     | `WoWUI/AddOns/Blizzard_SharedXML/`, `Blizzard_Menu/` |
| Minimap, compartment, etc.            | `WoWUI/AddOns/Blizzard_Minimap/`                     |

Prefer reading the **actual Blizzard implementation** over guessing from memory or outdated snippets.

## Web fallback

When WoWUI is insufficient (undocumented behavior, patch notes, lore, third-party addon docs):

- Use **[Warcraft Wiki](https://warcraft.wiki.gg/)** (`https://warcraft.wiki.gg/`)
- Prefer wiki over random forum posts or outdated Wowpedia mirrors

State briefly what was missing in WoWUI when you resort to the web.

## Implementation notes

- Match **retail / Mainline** paths unless the task is explicitly for Classic.
- When hooking or replacing Blizzard UI, read the target frame’s `.lua` / `.xml` in WoWUI first.
- Reuse patterns already in workspace addons when they match the Blizzard source.
