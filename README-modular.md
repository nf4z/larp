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

The loader downloads up to four modules concurrently (configurable from 1 to 8). Each module filename contains a content digest. Successful modules are cached in the executor workspace's `LarpLiteModules` directory when file APIs are available. Unchanged modules need no new download after an update; changed modules get a new cache filename. Corrupt or incomplete cache files that fail size/compile checks are downloaded again. File API failures fall back to network loading. Set `Cache = false` to bypass the cache. Old cache versions remain on disk; they are not retained as source strings in memory.

Downloads retry three times. All modules must download and compile before the previous instance is cleaned up. Initialization errors include the tab/module and block number. An initialization failure can still leave a partially initialized instance; download preflight cannot validate Roblox runtime behavior. Executors must support `loadstring`, `setfenv`, HTTP, and normal Roblox task APIs.

Runtime memory work includes releasing initialization blocks as they execute, isolating helpers per run, and replacing a full `getgc(true)` snapshot on reload with a direct reference to the previous config. Cached source strings are not held in a global Lua cache. Splitting files does not by itself reduce the memory required by active features. In-game memory and startup timing still need measurement in your executor.

## Maintaining modules

`src/larplite.lua` is the editable full source in GitHub (`larplite.lua` in the local workspace). Install `tree-sitter` and `tree-sitter-luau`, then run `python tools/build_modules.py`. The build emits `modular_dist/larp`, `modules-manifest.json`, and content-addressed module files. Publish the loader and every file listed in `modular_dist/publish-files.json` in one commit. Retain older module paths so an already downloaded loader can finish starting during an update. Never edit a published digest path in place; rebuild it.

Run `python tools/test_modules.py` for compiler, statement-order, loader/cache/failure/concurrency, and real config regression checks. It uses `.tools/luau/luau-compile.exe` and `.tools/luau/luau.exe` locally, or the `LUAU_COMPILE` and `LUAU` environment variables.
