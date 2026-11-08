# LarpLite modular loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/larp"))({
    Cache = true,
    DownloadConcurrency = 4,
    Defaults = {
        setfps = 60,
        chunkerRenderDistance = 4,
        disableRendering = false,
        autoUpdateScript = true,
        autoUpdateIntervalSeconds = 300,
    },
    Config = {},
})
```

The existing `loadstring(game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/larp"))()` also works.

`Defaults` supplies values for settings absent from saved files. Existing account, shared, and legacy configuration loading keeps its priority and file names. `Config` explicitly overrides named settings after reading saved settings; those values are saved normally. Leave it empty to preserve your choices. Both tables accept existing setting names and types; unknown names or incorrect types produce a warning and are ignored. Loader options are copied and retained across auto-updates and manual reloads. A fresh invocation with a table replaces the previous loader options.

Each tab has a separate module, including Fishing and the dynamic Leader tab. Shared automation lives in `core`; release notes live in `changelog`. All modules load by default to preserve automation and cross-tab dependencies. This is module separation, not on-demand feature disabling. The manifest runs blocks in the same order as the original script, even where tabs and automation are interleaved.

The Comp tab appears below Halloween for Seals vs Frog Dogs. It displays each contribution counter and your placement on your own team's hatch and bubble boards. The server exposes the top 100; lower placements display `Outside top 100`. Enable the two reward toggles separately to claim earned personal milestones. Joining a team remains an in-game action. Existing settings are preserved; the new toggles default to off.

`View Live Leaderboards` opens a separate Rayfield popout with both teams' top 100. Hatches/Bubbles buttons switch the metric. Incoming competition snapshots update names, scores and team totals immediately; a five-second subscription refresh keeps an open board current. Rows are reused so live updates preserve scrolling. Closing or unloading removes the popout and its connections.

Auto Enchant reads the current targets before each reroll, including while working on one pet. Two distinct targets require one of each; a matching slot stays protected while the other rerolls. Inventory egg hatching uses fresh owned counts, checks available pet space and the native cooldown, and backs off when a request produces no confirmed inventory change.

Bubble Shrine and Dreamer Fountain renew only after their actual `ShrineBlessingEndTime` expires. An available hourly donation cooldown does not trigger a top-up or restock while the blessing is active. The default 500 potions or 15 Dream Shards gives 24 hours; lower configured amounts remain supported. Bubble donations are capped at 500 because extra potions do not extend the 24-hour maximum. Run `python tools/test_shrine_expiry.py` to check both hubs against a virtual clock, including expiry, reloads, restocking and missing timers.

Shrines / Halloween Shrine supports the game's separate 12-hour Halloween egg blessing. Select one donation potion and enable Auto Halloween Shrine to fill the remaining XP, claim the buff and wait for its actual expiry. Donation quantities come from the native potion XP catalog and are capped to owned stock and the XP deficit. Optional target rerolls consume Shrine Tickets and stop on the selected buff. Both toggles default off. Existing XP, active buffs and other settings are preserved. `python tools/test_halloween_shrine.py` checks both hubs' shared policy, native remote arguments, expiry and request confirmation.

Halloween Target Buffs is a multi-select: rerolls stop on any checked buff. Saved single targets migrate to a one-item `halloweenShrineTargets` list, while explicit empty lists remain empty and pause rerolling. The old singular key remains supported for saved/inline config migration. New inline settings may use `halloweenShrineTargets = {"Secret", "Infinity"}`. Donation and claim behavior is unchanged.

The loader downloads up to four modules concurrently (configurable from 1 to 8). Each module filename contains a content digest. Successful modules are cached in the executor workspace's `LarpLiteModules` directory when file APIs are available. Unchanged modules need no new download after an update; changed modules get a new cache filename. Corrupt or incomplete cache files that fail size/compile checks are downloaded again. File API failures fall back to network loading. Set `Cache = false` to bypass the cache. Old cache versions remain on disk; they are not retained as source strings in memory.

Downloads retry three times. All modules must download and compile before the previous instance is cleaned up. Initialization errors include the tab/module and block number. An initialization failure can still leave a partially initialized instance; download preflight cannot validate Roblox runtime behavior. Executors must support `loadstring`, `setfenv`, HTTP, and normal Roblox task APIs.

Runtime memory work includes releasing initialization blocks as they execute, isolating helpers per run, and replacing a full `getgc(true)` snapshot on reload with a direct reference to the previous config. Cached source strings are not held in a global Lua cache. Splitting files does not by itself reduce the memory required by active features. In-game memory and startup timing still need measurement in your executor.

## Maintaining modules

`src/larplite.lua` is the editable full source in GitHub (`larplite.lua` in the local workspace). Install `tree-sitter` and `tree-sitter-luau`, then run `python tools/build_modules.py`. The build emits `modular_dist/larp`, `modules-manifest.json`, and content-addressed module files. Publish the loader and every file listed in `modular_dist/publish-files.json` in one commit. Retain older module paths so an already downloaded loader can finish starting during an update. Never edit a published digest path in place; rebuild it.

The marked Halloween shrine region is generated from `shared_src/halloween-shrine.lua` and `tools/templates/larplite-halloween-shrine.lua` by `tools/port_halloween_shrine.py` before module splitting. Edit those inputs for Halloween policy/UI changes; the build refreshes that region automatically. bgsiscript embeds the same shared policy.

Run `python tools/test_modules.py` for compiler, statement-order, loader/cache/failure/concurrency, and real config regression checks. It uses `.tools/luau/luau-compile.exe` and `.tools/luau/luau.exe` locally, or the `LUAU_COMPILE` and `LUAU` environment variables.

Run `python tools/test_larplite_comp_enchants.py` for executable mock checks of Comp claims and placement, changing enchant targets mid-roll, protected slots, and inventory hatch pacing. These checks do not replace a live Roblox session.
# Webhook pet image repair (2026.11.08.47)

Larplite's webhook image resolver follows the supplied game's `PetBuilder.Image` and `ItemUtil` mapping: `Images.Normal`, `Shiny`, `Mythic`, and `MythicShiny`. XL retains the selected variant image and uses the larger Discord gallery. The game data is read at runtime, so newly added pets do not depend on the repository's icon catalog.

`shared_src/webhook-pet-icon.lua` resolves asset IDs through Roblox's thumbnail API, preferring executor HTTP with game/native HTTP fallbacks. Pending/failed lookups retry three times with short delays, then try the thumbnail batch endpoint. Only completed HTTP image URLs are accepted; malformed responses and blocked thumbnails are not embedded as images. Successful CDN URLs are cached for an hour, failures for 15 seconds, with at most 256 entries. Direct image URLs, numeric asset IDs, `rbxassetid`, `rbxthumb` and legacy Roblox asset URLs are supported. Existing webhook settings and Super enchant overlays remain in place.

`tools/port_webhook_icons.py` embeds the resolver when modules are rebuilt. Run `python tools/test_webhook_pet_icons.py` for the real native PetBuilder fixture, variant selection, request fallbacks, pending/batch recovery, bounded cache/expiry and the actual normal/XL Discord V2 renderer. `python tools/test_modules.py` verifies generated compilation, statement order, loader and config behavior. Tests are offline and send no Discord messages; live Roblox API and Discord delivery were not available for verification.

