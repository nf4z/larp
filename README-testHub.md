# @qtrzip

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/testHub?v=qtrzip-6"))()
```

The repository entry remains `testHub` for compatibility. Visible titles, search, reopen button, prompts, and hub branding use **@qtrzip**.

- Default size: **600 x 420**, with viewport fitting.
- Drag the title bar; resize with the bottom-right // handle.
- Press **K** to open/close. Keyboard text entry does not trigger it.
- Scroll the sidebar for all 16 tabs; search controls in the selected tab.

## Separate configuration

This revision reads and writes **qtrzip_settings.json only**. If absent, it starts with an empty settings table and feature defaults. It never imports `renoa_hub_settings.json` or `testhub_settings.json`. Existing afbq preferences and old TestHub preferences are left alone.

When replacing an already running older version, rejoin once to clear that version's background automation before loading this revision. Re-executing the current revision reopens its existing window rather than starting another copy.

## Settings-based visuals and sizing

Revision 5 clones **Settings.Frame**, including its light Main content panel, instead of the Inventory shell. Sections are real Settings category containers with a centered label and Items list. Their height follows content using the same list-height-plus-50 calculation as the game's Settings module.

Rows follow Settings sizing: 50 logical pixels without a description and 75 with one. Toggles reserve 80 pixels, dropdowns 250 pixels, and the information column reserves the action width plus 15. Native row fonts are retained. Tab labels use a fixed font size and zero anchor to prevent automatic font enlargement and overlapping text.

Plain choice lists use Gui.Components.Dropdown.new directly with target-button width and up to six visible options, without fake initial-letter icons, a picker title, or an extra search bar. Actual item/egg lists retain searchable icon selection and bounded reusable rows. Dropdown arrows reset on close.

The transparent holder, hidden picker overlay, explicit pointer routing, drag/resize handling, separate qtrzip config, and K keybind remain. The native fullscreen background wrapper is not copied.

## Build and verification

```text
python tools/build_testhub.py
python tools/test_testhub.py
```

The builder combines `testhub_src/native-ui.lua` with the pinned `testhub_src/afbq-base.lua` into the standalone root `testHub` script. It preserves feature logic with startup diagnostics and branding changes. Tests use `.tools/luau`, or `LUAU` and `LUAU_COMPILE` environment variables.

Regression checks cover compilation, the earlier invalid ScreenGui.ZIndex startup failure, disabled native input flags, click-aware tab switching, global pointer navigation/dragging, resize, viewport fitting, icons, large-list search, native item cleanup, fresh config without legacy reads, own-config persistence, no cloned dim backdrop, branding, and the real asynchronous Info worker. Event tests use mocks; live client appearance and gameplay have not been verified for this revision.

## Native input, icons, layers, and resize repair (revision 6)

Native Settings input boxes are explicitly editable. Their original background artwork sits behind the real TextBox, with the native label font/color copied to visible editable text. The old hidden-text mirror is removed. Search boxes are also editable.

ItemUtil renders icons directly into transparent hosts. Full animated rarity cards are no longer embedded in tiny dropdown icons, removing the unwanted rainbow blocks while keeping the game's actual potion/item imagery.

Pickers use a separate ScreenGui above the menu, inherit its stable UI scale, and are clamped to the viewport. Picker titles no longer carry cloned favorite-star decorations, and close buttons use the native Settings close artwork. Resizing changes available layout width/height independently of control scale, so native fonts and controls do not inflate as the window grows. The Settings templates and proportions are retained.
