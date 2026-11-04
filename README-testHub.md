# @qtrzip

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/testHub?v=qtrzip-4"))()
```

The repository entry remains `testHub` for compatibility. Visible titles, search, reopen button, prompts, and hub branding use **@qtrzip**.

- Default size: **600 x 420**, with viewport fitting.
- Drag the title bar; resize with the bottom-right // handle.
- Press **K** to open/close. Keyboard text entry does not trigger it.
- Scroll the sidebar for all 16 tabs; search controls in the selected tab.

## Separate configuration

This revision reads and writes **qtrzip_settings.json only**. If absent, it starts with an empty settings table and feature defaults. It never imports `renoa_hub_settings.json` or `testhub_settings.json`. Existing afbq preferences and old TestHub preferences are left alone.

When replacing an already running older version, rejoin once to clear that version's background automation before loading this revision. Re-executing the current revision reopens its existing window rather than starting another copy.

## Native visuals and input repair

The menu clones only the actual Inventory.Frame into a fresh transparent, passive holder. It no longer copies Inventory's fullscreen dim/input backdrop. Original game UI objects remain intact. Closed native-menu input flags are reset on clones: controls are interactable, passive decorations do not capture input, and cloned button modal state is disabled. The picker overlay is hidden whenever no picker is open.

Tab selection and header/resize interaction also use explicit pointer hit regions through UserInputService, so decorative descendants cannot prevent navigation or dragging. Settings rows, native toggle knobs, dropdown templates, and item cards retain game visuals. Egg/item pickers use live game data and nine reusable rows. Destroying item cards cleans up their animations.

## Build and verification

```text
python tools/build_testhub.py
python tools/test_testhub.py
```

The builder combines `testhub_src/native-ui.lua` with the pinned `testhub_src/afbq-base.lua` into the standalone root `testHub` script. It preserves feature logic with startup diagnostics and branding changes. Tests use `.tools/luau`, or `LUAU` and `LUAU_COMPILE` environment variables.

Regression checks cover compilation, the earlier invalid ScreenGui.ZIndex startup failure, disabled native input flags, click-aware tab switching, global pointer navigation/dragging, resize, viewport fitting, icons, large-list search, native item cleanup, fresh config without legacy reads, own-config persistence, no cloned dim backdrop, branding, and the real asynchronous Info worker. Event tests use mocks; live client appearance and gameplay have not been verified for this revision.
