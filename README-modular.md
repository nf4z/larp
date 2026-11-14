# LarpLite modular loader

## Rayfield service startup repair (2026.11.08.50)

The reported `cloneref(nil)` startup path was reproduced with the exact `utility.services` helper in the currently served Rayfield Gen2 bundle. The cached copy matched upstream; deleting it would not fix that path. Rayfield now receives a separate compatibility environment based on the original executor environment, rather than inheriting Larplite's mutable module scope. Existing native Players/CoreGui/Workspace/etc. references are supplied to its two service helpers; missing references fall back through native GetService, FindService and FindFirstChild. A genuinely unavailable service produces a named diagnostic. Its library-local clone wrapper returns the original instance when cloning throws, returns nil or is unavailable. Executor globals and the game's service methods are not patched.

The adapter is applied before compiling either cached or freshly downloaded Rayfield source. The on-disk cache retains the original upstream source, so normal cached startup still avoids a network download. The runtime adapter is embedded by `tools/port_rayfield_runtime.py`; `python tools/test_rayfield_runtime.py` checks the real upstream service helpers, clone failure/nil behavior, native service fallback, clean library scope and the actual cached/fresh bootstrap. Modular loader, memory lifecycle and Safe Mode checks also pass offline. Live executor/UI startup still needs verification in the user's client.

## Reload lifecycle repair and measurement (2026.11.08.49)

Reviewing the supplied optimization plan identified a real issue missed by v48: the pickup-hook maintenance task used `while task.wait(2)` with no run-token check. Modular runs each have their own environment, so that task could retain an obsolete environment and install a hook using an old Config after reload. The task now checks its run token before and after waiting. Installation is idempotent within a run, the hook falls back to native behavior in Safe Mode or after replacement, and unload restores the native method. A fresh rejoin is required once to clear tasks already leaked by pre-v49 code, since those tasks were started without stored handles. An update notice explains this when migrating from an older running version.

No reduction in live process RAM has been demonstrated. `autoOptimizeMemory` now uses native low-detail mode and chunk retention repair without scanning the world or holding per-mesh restoration snapshots. The mesh sweep is separately available as `optimizeMeshDetail` / Other → Performance → Lower Mesh Detail, default **off**. Lower render fidelity can help drawing cost, but has not been shown to lower this client's RAM. The default chunk cap is now 2; existing saved values remain intact and are still capped against each chunker's smaller native range. Safe Mode and unload retain the v48 restoration behavior.

The egg scanner now discovers live instances through the owned native Chunker.Update hook's weak registry and native creation hooks. It no longer calls `getgc(true)` at all. The unused carnival heap-scanning function was removed. Cached Rayfield Gen2 source is validated/compiled first; the network is used only for missing, invalid or malformed cached source, and the initialization chunk reference is released after creating the library.

The memory card now includes `gcinfo()` VM heap MB alongside engine total, LuaHeap, textures and meshes. Once per minute, and on mode transitions, numeric diagnostics are saved to `LarpLiteMemory_<account ID>.json` in the executor workspace when file APIs are available. The ring contains at most 120 samples across reloads, with timestamps, version, run age and loading/safe/off/native-low-detail/mesh mode. No webhook URLs, config contents or account credentials are recorded. Samples allow comparisons over an hour and across updates, rather than treating a single working-set reading as proof of a leak or success. Windows process working set and committed/private bytes must be measured separately; the engine counters are not equivalent to Task Manager's columns.

`python tools/test_memory_lifecycle.py` executes the actual pickup hook and maintenance task, including replacement during its wait, and checks Safe Mode, restoration, repeated installs, cache-first UI loading, scan-free defaults and bounded minute diagnostics. The native chunk, complete Safe Mode, modular loader, inventory, enchant, competition and webhook icon checks also pass offline. Destructive map stripping and runtime feature deferral from the proposed plan have not been applied; their benefit and compatibility require the measurements first.

## Automatic optimization and Safe Mode (2026.11.08.48)

`autoOptimizeMemory` defaults to true. Other / Performance has a switch and a Client Memory card that samples engine total, Lua heap, graphics textures and mesh memory every five seconds. Unavailable engine counters are labeled rather than reported as zero. These are engine categories, not the same measurement as Windows Task Manager's process working set. The observed client working set before this patch was approximately 941 MB; no live post-patch savings have been measured.

The supplied game file contains roughly 5,100 Workspace MeshParts. A bounded, incremental traversal changes world meshes to `RenderFidelity.Performance`; new streaming meshes enter a bounded queue, and large bursts coalesce into a later incremental rescan. Character rigs and GUI/viewport meshes are excluded. The game's native `Client.LowDetail` flag suppresses optional particle emission and cosmetic animation work. Original mesh settings are held by weak reference and restored when optimization is disabled, on Safe Mode, or on unload. Mesh/texture assets, collision, touch/query properties, items, pet models, scripts, interactions and UI contents remain intact.

The code review identified a native `Shared.Utils.Chunker.Remove` retention bug: removing a coordinate's last item clears `_chunks[coord]`, but leaves `_loaded[coord]`. Native `Update` cannot unload that stale key because it requires the missing chunk to exist. The owned patch clears exactly those orphan keys after removal and sweeps old ones at most once per 30 seconds per live chunker. It does not delete instances or clear populated chunks. A second issue was Larplite widening every chunker to distance 4: a native distance-2 chunker covers 9 cells in 2D or 27 in 3D; distance 4 covers 49 or 343 respectively. The configured distance is now a cap on the native value. The egg scanner also holds its chunker registry by weak value, handles holes without losing live entries, and performs one initial heap discovery instead of repeating `getgc(true)` while scanning. Native creation hooks track later instances.

Safe Mode pauses automation and restores the original native low-detail state, every owned mesh setting, native chunk distances, nearby loaded objects, graphics quality, FPS cap, 3D rendering and hatch animation behavior. The chunk refresh now reaches actual tracked instances, rather than only looking for singleton fields absent from this game's module. Leaving Safe Mode restores the saved hub setup. User changes to native low-detail or owned properties are respected. FPS overrides require a readable original cap (`getfpscap`/equivalent or native settings); otherwise the script leaves the existing cap alone so Safe Mode can remain reversible. Unload disconnects owned signals, restores chunk methods/ranges and visuals, and releases work queues and callbacks.

The modular loader preserves full preflight before replacing a running instance and the original execution order. Concurrent source fetch/compile reservations have a default 512 KiB budget, configurable with top-level `DownloadMemoryBudgetKB` (128–8192 KiB), alongside the existing concurrency limit. One module larger than the budget runs alone. Superseded launches stop taking new work and discard late HTTP responses before compilation. Startup tables and completed module block arrays are released on completion, failure and cancellation. `BGSI_Lite_LoaderMetrics` contains only numeric module/budget/peak-reservation counts; it is not a heap measurement.

Webhook icon resolver callbacks now belong to the current run token and are released on reload/unload, so cached image URLs do not keep a previous module environment alive. Cleanup also clears expired egg-scan result references. Existing webhook settings and icon behavior are preserved.

`python tools/test_memory_optimizer.py` reproduces the stale-key defect using the supplied native Chunker fixture and checks the real Safe Mode functions, streaming bursts, original property restoration, signal cleanup and scanner behavior. `python tools/test_modules.py` checks byte budgets, cancellation, oversized modules, preflight failure isolation, execution order and config. Existing inventory, enchant, competition, shrine and webhook icon checks also pass offline. No claim is made that 1 GB alone establishes a leak, or that lowering render fidelity guarantees a particular RAM saving. The game's pet-model and instance pools intentionally retain assets; clearing those blindly can break features and is not part of this patch. See [Roblox's memory and rendering guidance](https://create.roblox.com/docs/performance-optimization/improve) for category-specific profiling.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/larp"))({
    Cache = true,
    DownloadConcurrency = 4,
    Defaults = {
        setfps = 60,
        chunkerRenderDistance = 2,
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

Run `python tools/test_winter_altar.py` for executable mock checks of the Winter Altar tab: which owned pets the dropdown offers, eligibility coming from the game's own rule, the guaranteed recipe winning over a mixed fuse, the altar cooldown, and one variant per conversion.
# Webhook pet image repair (2026.11.08.47)

Larplite's webhook image resolver follows the supplied game's `PetBuilder.Image` and `ItemUtil` mapping: `Images.Normal`, `Shiny`, `Mythic`, and `MythicShiny`. XL retains the selected variant image and uses the larger Discord gallery. The game data is read at runtime, so newly added pets do not depend on the repository's icon catalog.

`shared_src/webhook-pet-icon.lua` resolves asset IDs through Roblox's thumbnail API, preferring executor HTTP with game/native HTTP fallbacks. Pending/failed lookups retry three times with short delays, then try the thumbnail batch endpoint. Only completed HTTP image URLs are accepted; malformed responses and blocked thumbnails are not embedded as images. Successful CDN URLs are cached for an hour, failures for 15 seconds, with at most 256 entries. Direct image URLs, numeric asset IDs, `rbxassetid`, `rbxthumb` and legacy Roblox asset URLs are supported. Existing webhook settings and Super enchant overlays remain in place.

`tools/port_webhook_icons.py` embeds the resolver when modules are rebuilt. Run `python tools/test_webhook_pet_icons.py` for the real native PetBuilder fixture, variant selection, request fallbacks, pending/batch recovery, bounded cache/expiry and the actual normal/XL Discord V2 renderer. `python tools/test_modules.py` verifies generated compilation, statement order, loader and config behavior. Tests are offline and send no Discord messages; live Roblox API and Discord delivery were not available for verification.

