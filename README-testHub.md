# @qtrzip

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/testHub?v=qtrzip-8"))()
```

The repository entry remains `testHub` for compatibility. The window has no title or status footer. The reopen button and hub branding use **@qtrzip**.

- Default size: **600 x 420**, with viewport fitting.
- Drag the empty header area; resize with the bottom-right // handle.
- Press **K** to open/close. Keyboard text entry does not trigger it.
- Scroll the sidebar for all 16 tabs; search controls in the selected tab.

## Separate configuration

This revision reads and writes **qtrzip_settings.json only**. If absent, it starts with an empty settings table and feature defaults. It never imports `renoa_hub_settings.json` or `testhub_settings.json`. Existing afbq preferences and old TestHub preferences are left alone.

When replacing an already running older version, rejoin once to clear that version's background automation before loading this revision. Re-executing the current revision reopens its existing window rather than starting another copy.

## Settings-based visuals and sizing

Revision 5 clones **Settings.Frame**, including its light Main content panel, instead of the Inventory shell. Sections are real Settings category containers with a centered label and Items list. Their height follows content using the same list-height-plus-50 calculation as the game's Settings module.

Rows follow Settings sizing: 50 logical pixels without a description and 75 with one. Toggles reserve 80 pixels, dropdowns 250 pixels, and the information column reserves the action width plus 15. Native row fonts are retained. Tab labels use a fixed font size and zero anchor to prevent automatic font enlargement and overlapping text.

Plain choice lists use Gui.Components.Dropdown.new directly with target-button width and up to six visible options, without fake initial-letter icons, a picker title, or an extra search bar. Item/egg lists use that same native component with icons added to visible rows. Dropdown arrows reset on close.

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

## Native dropdowns and GitHub icon cache (revision 7)

Every list now uses the game's Settings dropdown component directly. The separate searchable item picker, its title/search/close widgets, and custom option buttons have been removed. The native component controls option rows, scrolling and selection; the only row addition is a centered icon with label inset. Active icon rendering is limited to the visible range. Multi-select labels follow Settings' None selected / one name / N selected wording.

See [icon-cache](icon-cache/README.md) for categorized asset references, recipes, cache loading, PNG import limitations and refresh/publish tools. The current GitHub cache is metadata/recipes, not a PNG mirror; protected image downloads require an authorized export.

## Input, navigation, and unload repair (revision 8)

All tabs start blue and the selected tab turns green. Keybind textbox constraints, alignment and padding are normalized for editable text; input content is inset inside the original artwork and clipped, and row titles truncate inside their information column. The search bar is inset under the content panel with separate clearance from the resize grip. The top title and bottom status label are removed; failures remain in the console.

The red **Unload** button disconnects owned event handlers, cancels owned running and pending jobs, closes pickers and overlays, removes created instances, and restores recorded native module hooks, camera properties, local frame visibility, and visual/FPS edits. Visual optimizations now record original property values and detach camera children temporarily instead of destroying them. Protected rendering technology/quality edits are skipped. Debug settings are changed only when the original setting can be read and restored. Configuration stays saved for the next load. Completed server actions (purchases, trades, rewards, teleports) are not reversed. The external fishing helper also receives its existing stop flags; its obfuscated third-party internals cannot be audited for independent side effects. Older revisions without lifecycle tracking still require a rejoin once.

Additional verification:

```text
python tools/test_testhub_runtime.py
python tools/test_icon_cache.py
```

The lifecycle harness tests cancellation of both running and delayed/deferred jobs, event disconnection, instance cleanup, original-value/hook restoration, and idempotent unload. These are deterministic Luau tests, not a live Roblox playtest.
