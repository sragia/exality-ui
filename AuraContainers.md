Hello again from the World of Warcraft UI Engineering team! Today we’d like to talk about a significant set of Aura-related changes coming in 12.1. Most of these changes will be available when PTR launches, with the remaining pieces rolling out over the following few weeks.

Why Auras?
Since the Addon Disarmament project went live with Midnight, Auras (aka buffs and debuffs) have consistently been one of the weakest areas for addon security, with numerous exploits discovered both before launch and since then. The core issue is that, in many cases, simply knowing that any aura is present on a unit (whether it be the player, an enemy, or a raid/party member) is enough to determine that some important combat event has occurred. Aura filters are vital for many legitimate addon use cases, but they also make this problem harder to contain by allowing even more ways to tell if “special aura X” is on a unit, even if the unit has multiple auras on them.

Up until now, our solution to this has been to lean on Private Auras. Unfortunately, Private Auras come with several downsides: they are invisible to addons, which prevents customization; they are not supported in every context, such as nameplates; and setting them up across every encounter adds significant setup work for our designers. Secret values were created specifically to protect against cases like this, providing passive protection by default.

What is changing?
We’ll get to the changes to existing APIs shortly, but first, we’d like to introduce a couple of new constructs we are adding to Lua, along with two new object types (Aura Containers and Aura Buttons).

New Tech: Private Script Objects & The Forbidden Partition
Private Script Objects are a new construct that lets us split the Lua representation of a script object across multiple Lua tables, or partitions. One of these partitions we call the Forbidden Partition, because it is inaccessible to addons. The Forbidden Partition can contain any kind of value, from mixins to key/value pairs, functions, script handlers, and child objects. This allows us to effectively hide portions of the object from addon code even when the object itself isn’t in the secure environment.

New Tech: Forbidden Aspects
Forbidden Aspects are another new construct that works alongside Private Script Objects. Forbidden Aspects are similar in concept to the Secret Aspects we introduced in Midnight, but instead of causing certain object APIs to return secrets, they prevent addons from using certain functionality entirely. Where Secret Aspects obfuscate data, Forbidden Aspects restrict what addons are allowed to do with an object.

There are several Forbidden Aspects being added (details are in the docs), but let’s use the UntrustedScriptExecution Forbidden Aspect as an example. When a frame has the UntrustedScriptExecution Forbidden Aspect applied to it, any script binding handlers set on it (e.g. OnShow, OnLoad, OnSizeChanged) will not be run unless that handler lives in the object’s Forbidden Partition and execution is untainted. In other words, addons cannot install their own script bindings on the object, but our code can.

New Object Types: Aura Containers & Aura Buttons
Aura Containers and Aura Buttons are new Lua object types that allow addons to display auras in custom ways. Here’s a small example showing how they can be used:

local container = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate");
container:SetSize(1, 1);
container:SetPoint("CENTER");
container:SetUnit("target");
container:AddAuraFilter("HELPFUL", { maxFrameCount = 5 });

for i = 1, 5 do
local auraButton = CreateFrame("AuraButton", nil, container, "CustomAuraButtonTemplate");
auraButton:SetSize(40, 40);
auraButton:SetPoint("TOPLEFT", container, "TOPLEFT", (i - 1) \* 42, 0);
auraButton.Icon = auraButton:CreateTexture(nil, "OVERLAY");
auraButton.Icon:SetAllPoints(auraButton);
auraButton:SetIcon(auraButton.Icon);
auraButton.Text = auraButton:CreateFontString(nil, "ARTWORK", "GameFontNormal");
auraButton.Text:SetPoint("TOP", auraButton, "BOTTOM", 0, -5);
auraButton:SetDurationText(auraButton.Text);
container:AddAuraFrame(auraButton);
end
Copy
In the example above, we create an Aura Container, specify that it should track the first 5 helpful auras on the player’s target, and then add 5 Aura Buttons to it. For each Aura Button, we create a texture for the icon and a font string for the duration. The APIs shown here on the Aura Button are just a sample of the APIs provided (full details will be in the docs), but this should give you a sense of what is possible. Note that addon code still has a great deal of control over how the auras are presented, but it doesn’t interact with the underlying aura data at all. This separation is important for security, but it should also make custom aura displays easier to build and more performant. Aura Containers handle the tracking, filtering, and updating of aura assignments internally, so addons can focus more on presentation and less on repeatedly querying, diffing, and refreshing aura state themselves.

Why Are Aura Containers Safer?
To answer that, let’s go back to Private Script Objects and Forbidden Aspects again. Aura Buttons and Aura Containers both have Forbidden Aspects applied to them on creation. When an Aura Button is added to an Aura Container using the AddAuraFrame API, it is added to the Forbidden Partition of that Aura Container. This means addon code cannot install script handlers on Aura Buttons to be notified when they show or hide. It also cannot hook functions called on the Aura Button’s mixins or register events on those buttons. While addons can still hold references to those individual Aura Buttons, calling certain APIs on them will be disallowed, and they cannot run logic based on whether those buttons are shown, because IsShown and similar APIs return secrets.

Which current APIs are changing?
The main change to existing APIs is that, when auras are secret (during combat, encounters, M+, and PvP matches), all of the UnitAura APIs will now either return full secrets or nil when called by addons. That means that APIs like GetUnitAuras and GetUnitAuraInstanceIDs will return a secret vector, meaning addon code will not be able to determine how many auras it contains or iterate through it for display. Auras we explicitly flag as non-secret will still be returned as non-secret by UnitAura APIs, however.

Is all this in place in PTR Week 1?
No, several pieces of this are not currently implemented in the first PTR build but will be coming over the next few weeks. The biggest pieces not in place yet are the changes to the UnitAura APIs. Some Aura Button protections are also not yet in place: their script handlers are protected, but script handlers on their child frames are not, and event registration is still currently allowed. Those protections, along with additional safeguards, will arrive over the next few weeks. In the meantime, though, feel free to start experimenting!

As always, we are actively seeking your feedback and will be monitoring the ⁠author-wishlist channel, so please share feedback, bugs, and any potential exploits there. Thanks as always for helping us test and improve this system!

DISCLAIMER: These notes are for addon authors and as such are focused specifically on addon-facing API and security changes only. Changes planned for other parts of the game (UI or otherwise) are not included here.

Interface Texture Filenames

Starting in 12.1, new interface texture filenames will no longer be published to the ManifestInterfaceData DB, and as a result will not be available via exportinterfacefiles art. Existing filenames will remain in the DB. You may notice that a few entries are still added in 12.1 and over the next few patches, but this is due to those assets already having been added prior to this change being made. We are making this change to prevent leaks caused by texture names containing hints about future content. We understand that this is going to be a somewhat disruptive change for some addon developers, so please let us know your largest pain points and we'll try to make accommodations where possible.

Other changes in 12.1 PTR 1

We now support showing SVG textures in our UI. They can be used on regular textures (e.g. file="Path/To/Texture.svg") or with a new VectorGraphics object type, which renders them at higher quality.
Note that the VectorGraphics objects don't currently support all of the APIs on regular Textures (rotation, masking, tex coords, etc.)
Load-on-Demand addons can now specify that specific files in the TOC should load on startup through a new per-file [Bootstrap] directive.
This still requires that the addon be enabled in order for these files to load.
UIParent.lua has been heavily refactored, with all of the code that previously handled loading LoD addons moved into the addons themselves, taking advantage of the new [Bootstrap] directive.
Added a new API Frame:SetOnUpdateMode(mode), which lets you specify when the OnUpdate script on a frame should run.
The options are Disabled, RunWhenVisible (default), RunWhenVisibleOnce, RunOnce, and RunAlways
A new system has been added called the Roleset System, which allows you to tag a frame as being part of a "roleset". You can then use the new C_Roleset.ApplyRolesetFilters to specify which rolesets are currently active.
Frames in an inactive roleset will never be shown, regardless of their shown state. See Blizzard_UIModeManager.lua for more details and examples.
Radial masking support has been added to textures and status bars, allowing them to have a radial mask applied to them without the need for hacky uses of cooldowns. Example usage on a texture:
texture:SetRadialProgressBarPercent(0.5);
texture:SetRadialProgressBarStartOffset(0.25);
texture:SetRadialProgressBarEndOffset(0.75);
texture:SetRadialProgressBarReverse(true);
texture:SetRadialProgressBarFeather(0.125);
Copy
KeyValues can now specify that their value should be pulled directly from the private addon table. Example usage: <KeyValue key="myKey" type="local"/>
Mixins can now be added on an object using a new <Mixins> element.
Using this element allows you to use the source="local" specifier to indicate the mixin lives in the private addon table.
Mixins added on an object (either through the Mixins element or the regular mixin="myMixin" attribute) can also now be nested within tables.
Example usage:

local \_addonName, addonTbl = ...;

local CustomFrameMixin = {};
addonTbl.CustomFrameMixin = CustomFrameMixin;

local NestedMixin = {};
addonTbl.Mixins = {};
addonTbl.Mixins.NestedMixin = NestedMixin;
Copy

<Frame name="TestFrame">
    <Mixins>
        <Mixin key="CustomFrameMixin" source="local"/>
        <Mixin key="Mixins.NestedMixin" source="local"/>
    </Mixins>
</Frame>
Copy
2026-06-23
Midnight 12.1.0 PTR Changes 2 (Build 68301)

DISCLAIMER: These notes are for addon authors and as such are focused specifically on addon-facing API and security changes only. Changes planned for other parts of the game (UI or otherwise) are not included here.

Quick note: the previously mentioned restrictions to UnitAura APIs are currently planned for PTR 3, so any addons using those APIs should expect significant changes next week.

Coming in 12.1.0 PTR 2

Aura Buttons now support the following functionality:
Dispel borders: Using the SetAuraBorder(texture, [options]) API (see DefaultAuraBorderOptions for available options).
Dispel type text: Using the SetAuraSymbol(fontString, [options]) API (see DefaultAuraSymbolOptions for available options).
Aura tooltips: Automatically enabled but can be disabled via the SetMouseMotionEnabled API.
Added the following new Forbidden Aspects:
UntrustedScriptExecution: When active, addon-installed script handlers on a frame and its children will never be run.
UntrustedLayoutScriptExecution: When active, addon-installed OnSizeChanged handlers will never be run for a frame, its children, or any frames anchored to either.
EventRegistrations: When active, addons cannot register a frame for events.
AlwaysPropagateInput: When active, a frame and its children will always propagate mouse and keyboard input.
ScriptedInput: When active, addons are not allowed to call input-related APIs (Click, SetFocus, etc.) on a frame or its children.
QueryFocus: When active, addons cannot query if a frame or its children are the current mouse or keyboard focus.
Aura Buttons have had the following Forbidden Aspects applied to them: UntrustedScriptExecution, UntrustedLayoutScriptExecution, AlwaysPropagateInput, ScriptedInput, and QueryFocus
Aura Containers have had the EventRegistrations Forbidden Aspect applied to them.
Editboxes will no longer auto-focus if they become visible while they have the Shown secret aspect applied.
API calls such as SetParent and SetPoint will error if an object would implicitly gain any Forbidden Aspects that it does not already have.
2026-06-30
Midnight 12.1.0 PTR Changes 3 (Build 68412)

DISCLAIMER: These notes are for addon authors and as such are focused specifically on addon-facing API and security changes only. Changes planned for other parts of the game (UI or otherwise) are not included here.

Coming in 12.1.0 PTR 3

This week brings the majority of the UnitAura API restrictions (with a few small pieces still remaining). Broadly speaking you can consider APIs that return aura data are no longer safe for addon use while aura data is secret. More specifically:
C_UnitAura and C_TooltipInfo APIs that provide access to aura data via index, slot, or instance ID will Lua error when called by addons while auras are secret.
C_UnitAura APIs that provide access to aura data via spell ID or spell name can still be called by addons as before (non-secret spells still return non-secrets).
The UNIT_AURA event now delivers a fully secret payload while auras are secret. AuraData structs are now always fully secret.
Added a new ManagedAuraContainer base type, which fully manages the display and layout of AuraButtons.
The Blizzard Target Frame now uses a ManagedAuraContainer for the display of its auras.
Fixed a bug where only 14 of the 19 parameters were being passed to ChatFrame message event filter functions.
Preview of PTR 4
PTR 4 will add a whole swath of changes for AuraContainers and AuraButtons including:

CustomAuraContainers will be converted to ManagedAuraContainers. As a result, AuraContainers will now handle the creation of AuraButtons entirely on their own.
AuraContainer support for filtering by Spell ID, dispel type, stealable, and max duration. Some filters will have restrictions - more details to come.
AuraContainer support for sorting (both sort rule and direction).
2026-07-07
Midnight 12.1.0 PTR Changes 4 (Build 68569)

DISCLAIMER: These notes are for addon authors and as such are focused specifically on addon-facing API and security changes only. Changes planned for other parts of the game (UI or otherwise) are not included here.

Coming in 12.1.0 PTR 4
This week brings some major changes to AuraContainers and AuraButtons.

AuraContainers now handle the creation and anchoring of all AuraButtons inside of them entirely on their own.
Addons no longer create AuraButtons directly. The AddAuraFrame API has been removed.
Added a new construct to AuraContainers: AuraGroups. Broadly speaking, you can think of an AuraGroup as a dynamic, self-managing collection of auras within an AuraContainer.
AuraContainers can have multiple AuraGroups, each with their own filters and settings.
Auras from each group are anchored sequentially in the order the groups were added.
Addons add AuraGroups to AuraContainers using a new API AddAuraGroup(groupKey, filterString, options).
The groupKey param is an arbitrary addon-defined string used to access the group after creation.
The filterString param is a standard aura filter string as used today (e.g. "HELPFUL|RAID").
The options param is a table that can contain a number of optional settings.
maxFrameCount: The maximum number of aura frames to show in this group
sortMethod and sortDirection: Used to control how auras in this group are sorted (see new enum AuraContainerSortMethod for choices).
initializeFrame: A callback function that is called for each AuraButton created.
templateNames: A list of xml templates to apply to each AuraButton (in addition to CustomAuraButtonTemplate).
candidateFilters: A table of additional filter information to apply when determining if an aura should be displayed. See ValidateCandidateFilters for the full list of options, but some examples are:
Include/exclude maps for spell IDs and dispel types.
maxDuration
Various boolean values from AuraData (isFromPlayerOrPlayerPet, isRoleAura, isPriorityAura, isStealable, etc.).
AuraGroups create and anchor AuraButtons in batches of 10 as needed.
Anchoring of AuraButtons created by an AuraContainer can be adjusted via the SetAuraGroupLayout API (see ValidateAuraGroupLayoutOptions for available options).
AuraContainers now automatically resize to fit group-based AuraButtons inside of them.
AuraContainers now treat private auras just like regular auras, allowing them to be shown and sorted normally.
Added a new construct to AuraContainers: AuraSlots. You can think of AuraSlots as AuraGroups with maxFrameCount set to 1 (they will only ever show a single aura).
Unlike AuraGroups, addons can manually anchor AuraSlots.
The AddAuraSlot(slotKey, filterString, options) API is used to add AuraSlots, and it supports most of the same options AddAuraGroup does.
Added a new API, AddItemEnchantment(itemEnchantmentSlot, options), to AuraContainers, which allows them to show temporary weapon enchants. See ValidateAddItemEnchantmentOptions for the list of options supported.
Added a new API SetCancelAuraButtons to AuraButtons that can be used to specify which mouse clicks to use to cancel. This can be called on AuraButtons via the initializeFrame callback.
Other changes

The AddPrivateAuraAppliedSound and RemovePrivateAuraAppliedSound APIs have been renamed to AddAuraAppliedSound and RemoveAuraAppliedSound, and now work on any auras (not just private auras).
Added support for negating most aura filters using the ! character. So for instance !PLAYER includes only auras NOT cast by the player.
The UNIT_AURA event now delivers a fully secret payload while auras are secret. AuraData structs are now always fully secret.
SecureAuraHeaderTemplate has been removed from Mainline (it will still exist for Classic). Addons still using SecureAuraHeaderTemplate should migrate over to using AuraContainers.
Fixed a crash that happened when attempting to create an AuraContainer in combat.
Attempting to do so will still generate a Lua error, however (as intended).
Added a new SecureGroupHeaderTemplate xml template that can be used to safely create a single AuraContainer on UnitFrame creation.
Resolved an issue where the SetApplicationCount function on CustomAuraButtons would error if not supplied an options table.
Resolved an issue where ApplyAuraSymbol on CustomAuraButtons was consulting the wrong region (AuraButton) for dispel type validation.
