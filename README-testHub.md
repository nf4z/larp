# TestHub — BGSI native edition

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/testHub"))()
```

Press **K** to open or close the menu. The key is ignored while typing or when the game consumes the input. A small TestHub button opens it on touch devices. Drag the title bar to move the window.

This is a separate, standalone version of `afbq`. The 17 embedded feature module bodies come from `afbq` commit `e9632f9e9a701ab09e917a5d1cfb86e85933f89d`. They are preserved apart from shortening the pauses between module initializations. TestHub replaces the WindUI download and window setup with its bundled game-asset adapter. Existing optional fishing/enchant feature scripts still use the original external downloads when those features are activated.

## Native visuals and controls

- Clones the live game's Settings frame and setting-row visuals where available, plus native button assets and fonts. It creates new controls from those copies; it never moves the game's originals or calls the native Settings remotes.
- Uses the game's `Shared.Palette`, `Assets.Intro.Play.Button`, `Shared.Utils.Stats.ItemUtil`, and `Shared.Data` modules. If the live Settings template is missing, it uses Intro button visuals and locally created controls with the same palette and font.
- Searchable tabs, searchable icon pickers, clear ON/OFF states, wrapping status paragraphs, and a layout that stacks action controls on narrow screens.
- Resolves real egg images, potion levels, powerups, pets, runes, currencies, and supported fishing items from live game data. Eggs without a useful image use a static viewport of the matching model when available. Unknown options get a text initial.
- Dropdowns use nine reusable rows, even for large lists. Their icon animations/models are released when closed. Active-tab selected icons are also cleared while the menu is hidden.

The supplied `.rbxl` was used to inspect game hierarchy and APIs, including the native item icon renderer. Its saved file does not include the main live `PlayerGui.ScreenGui.Settings` tree, so the adapter discovers that tree at runtime and falls back cleanly when absent. The result combines cloned native visuals with custom navigation and event handling; it does not replace the game's own Settings UI.

## Settings and startup

TestHub writes `testhub_settings.json`. On its first use, if that file is absent, it reads `renoa_hub_settings.json` to copy existing preferences. Subsequent saves write only TestHub's file. Invalid settings JSON falls back to an empty settings table. Its runtime globals and auxiliary downloaded feature scripts use a private environment, leaving `afbq`'s globals alone.

Re-executing while the TestHub window exists opens the same window instead of starting duplicate workers. Hiding the menu leaves automation running, just as with `afbq`. TestHub is intended to be used as your active hub; its saved automation choices still perform the same game actions as `afbq`.

## Build and verification

Edit `testhub_src/native-ui.lua`, then run:

```text
python tools/build_testhub.py
python tools/test_testhub.py
```

The builder uses the pinned `testhub_src/afbq-base.lua` and emits the standalone repository-root `testHub` script. No extra UI source download is needed at startup. The tests use the Luau compiler/CLI from `.tools/luau`, or the `LUAU_COMPILE` and `LUAU` environment variables.

Validation covers compilation, feature-code preservation, native cloning/fallbacks, callbacks, search and icon selection, a 1,000-option picker, K/text focus, mobile layout branching, popup reuse and cleanup, private globals, isolated settings writes, and rerun protection. UI events are tested with deterministic mocks. No Roblox Studio session was connected during development, so live appearance, asset loading, and gameplay behavior still need verification in a Roblox client; these tests do not measure frame rate or memory usage there.
