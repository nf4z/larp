# TestHub — native Inventory rebuild

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/testHub"))()
```

The window defaults to **420 x 320 pixels**, similar to afbq. Drag the title bar to move it and drag the bottom-right // handle to resize it. Press **K** to show or hide TestHub; text entry does not trigger the keybind.

This revision replaces the first custom shell with a clone of the game's **PlayerGui.ScreenGui.Inventory**. It retains the native Frame.Top title and close button, Frame.Sidebar container, Frame.Tray.Search search field, and Frame.Inner content area. Copied inventory contents are replaced with TestHub controls; the original Inventory remains intact.

The game file's ReplicatedStorage.Client.Gui.Frames.Inventory module controls that live panel. TestHub initializes Inventory and Settings through GuiFrame, then clones their live objects. Settings rows retain their Information/Action layout, actual switch and Blob, input-box styling, and dropdown buttons. Picker templates come from **Gui.Components.Dropdown.new**, and item cards from **Gui.Utils.ItemFrame**, with the same data and icon renderer as Inventory. The generic blue header and fabricated control cards from the first version are removed.

All 16 navigation entries are registered before feature startup, using compact native dropdown-row styling in the sidebar. Revision 3 fixes the actual startup crash: the reopen button previously tried to read ZIndex from a ScreenGui, which is not a GuiObject. The strict mock now rejects that invalid property, reproduces the old failure, and checks that the corrected adapter completes startup. Partial startup failures remove the incomplete window. Modules reuse those entries. Load failures appear in the panel and console. State access is now lexical, so startup no longer depends on swapping the whole feature function's environment. A regression test executes the real Info module while resetting spawned workers to an ambient environment and verifies that it populates the native panel.

Egg images use live data, with static model viewports when an image is unavailable. Supported items resolve through live potion, powerup, pet, rune, currency, and fishing data. Pickers have search and nine reusable rows; destroying item cards cleans up their animations. Missing native templates report an error instead of presenting an invented fallback shell.

TestHub writes testhub_settings.json. On first use it can read renoa_hub_settings.json to copy preferences, but never saves to that original file. The 17 embedded feature modules remain based on afbq commit e9632f9e9a701ab09e917a5d1cfb86e85933f89d, with shorter startup pauses and load-error reporting. Optional auxiliary fishing/enchant downloads remain as in afbq.

## Build and checks

```text
python tools/build_testhub.py
python tools/test_testhub.py
```

Edit testhub_src/native-ui.lua. The builder combines it with testhub_src/afbq-base.lua into the standalone root testHub script. Tests use .tools/luau, or the LUAU and LUAU_COMPILE environment variables.

Checks cover compilation, feature-code preservation, native inventory artwork/hierarchy, actual row/switch structures, callbacks, icons, 1,000-option search, K/text focus, compact sizing, drag and resize input events, viewport fitting, cleanup, separate settings writes, rerun protection, and the real asynchronous Info module. Component tests use mocks. Desktop inspection was stopped before the replacement UI could be exercised; final live appearance and full gameplay behavior have not been visually verified.
