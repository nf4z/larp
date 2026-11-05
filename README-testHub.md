# @qtrzip

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/bgsiscript"))()
```

The repository entry is `bgsiscript`. The window has no title or status footer. The reopen button and hub branding use **@qtrzip**.

- Default size: **600 x 420**, with viewport fitting.
- Drag the empty header area; resize with the bottom-right // handle.
- Press **K** to open/close. Keyboard text entry does not trigger it.
- Scroll the sidebar for all 17 tabs; search controls in the selected tab.

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

## Clean inputs, header action, and Larplite additions (revision 9)

Editable inputs now use a fresh TextBox inside an isolated InputSurface, retaining only the native keybind background artwork. The native Keybind container remains hidden; its layout/padding/text constraints cannot position the placeholder independently of the white field. Text uses a readable dark color, fixed size, and a 10-pixel inset. The Unload button now has a zero anchor, sits inside the header, and has no dropdown chevron.

The Auto tab's previous box opener is replaced with catalog-based Gift discovery, including zero-owned types, multi-selection, owned-count rotation, batch/delay controls, working list refresh, and inventory counts. Collection uses the native PhysicalItem gift API instead of simulated mouse clicks. Requests respect active gift capacity and wait for inventory changes before repeating a batch for the same item.

Box Condenser adds one-craft and automatic operation with a gem reserve, live costs from BoxCondenser data, and response pacing. When auto-condensing is affordable, the opener reserves its input boxes and opens other selected types. Zen Island's condenser must be loaded. New settings live only in this hub's qtrzip_settings.json; no Larplite config is imported.

A Server tab adds Copy Job ID, Copy Join Script, Rejoin, Join Job ID and Hop To Emptiest Server. Hopping depends on access to Roblox's public server endpoint. These operations are user-triggered.

The builder applies explicit transforms in tools/testhub_features.py and bundles testhub_src/extras.lua. The pinned afbq source is unchanged. Run python tools/test_testhub_features.py for catalog, rotation, inventory pacing, limits, reserve, and server-control tests. UI tests now use a poisoned keybind template with inherited layouts, alignment and sizing to guard against the reported regression. Live Roblox rendering and gameplay still require verification in the client.

## Inventory search inputs and icon geometry (revision 10)

All input fields and the bottom control filter clone Inventory.Frame.Tray.Search directly. The native search Bar geometry, magnifying-glass artwork, borders, colors, font and text insets are retained. Only the outer holder, editable value/placeholder and fixed font size are assigned by this hub. Inputs reserve the same 250 logical pixels as dropdowns.

Item lookups now resolve punctuation, whitespace and case differences to the actual game data keys (Dice-Key -> Dice Key, Infinity-Elixir -> Infinity Elixir). Full exact names are checked before parsing potion levels, preventing numbered item names from being discarded. Live Image/Icon/Images.Normal assets take priority, with GitHub metadata and native animated item renderers as fallbacks. ImageLabels use centered anchors and positions to match ItemUtil's expectations. Visible dropdown options use a consistent 22-pixel font, including short names, and picker bounds are calculated relative to their overlay without subtracting the GUI inset twice.

Unload Script is the final control in Misc, under Session. It is installed after the base features finish, independently of the optional extras module, and no longer appears in the header. It uses the existing lifecycle cleanup.

Regression checks now cover cloned search artwork/insets, alias resolution, centered static and native item rendering, fixed option fonts, viewport-edge picker clamping, and unloading through the Misc action. Checks use Luau mocks; live appearance remains unverified.

## Compact inner search fields (revision 11)

Inputs and the control filter now clone only Inventory.Frame.Tray.Search.Search, not its outer tray/search wrapper. The native inner background, magnifier and bar remain. Bar bounds and textbox anchor/position/height are explicitly fitted to the 40-pixel field, and inherited text/layout constraints are removed so short fields cannot clip text vertically. Text is vertically centered at a fixed 20-pixel size; the magnifier occupies a separate 32-pixel slot. Regression fixtures include unwanted outer artwork and a textbox with a stale vertical offset and fixed height.

## Compact fields and stable entry (revision 12)

The GitHub entry is now bgsiscript. Use bgsiscript-loadstring.lua: its URL has no version query to change between releases. Running a newer revision unloads a tracked older revision automatically.

All text inputs and the bottom filter now contain one plain rounded dark-blue field and a fresh full-height textbox. There is no magnifier, nested search artwork, or copied inventory layout. The field is 34 logical pixels high inside its 40-pixel host, with centered 20-pixel text and a 10-pixel horizontal inset. Tests reject any ImageLabel/ImageButton or inherited layout in these fields and verify direct parentage and full-height text geometry. Live rendering remains unverified.

## Text spacing and dropdown quality of life (revision 13)

Row titles use 22-pixel text, descriptions 18, section headings 24, and dropdown options 20. Information columns have explicit left/stroke clearance, descriptions wrap into their own region, and pages have padding to keep outlines clear of scrolling edges. Decorative dashes are removed from section labels.

Egg discovery rejects lock/template/hitbox objects and requires a catalog/asset match or the game's Egg tag. All dropdowns also reject VisualEggLock and duplicate values. Inventory eggs come only from owned Powerups entries with Type=Egg, with no fabricated empty-inventory fallback. Inventory refresh updates the actual dropdown and preserves valid selections. Dropdown refresh removes stale choices while keeping valid ones.

Visible icon rows are found from actual row positions and sizes instead of estimating from CanvasPosition divided by an unscaled template height. This keeps rendering aligned while scrolling/scaling. Run tools/test_testhub_catalog.py to check the generated discovery predicates and owned-egg filtering. UI checks remain mocked rather than a live client test.

The close button uses a 40-pixel red target with a separate centered 26-pixel X. Its anchor and position are normalized, with clearance above the white panel in the blue header. The UI test checks target/glyph sizes and the gap to the content panel.

## Native interaction and TopbarPlus (revision 14)

Buttons now use the game's actual Client.Gui.Utils.ClickableButton module: its 1.035 hover / 0.925 press scale tweens, easing, and local hover/press/release sounds. Existing native dropdown color/hover behavior is retained without adding duplicate sounds to option rows. Toggles use Settings' 0.1-second Sine/Out motion; reopening uses the native PopIn module when available. Titles/descriptions are adjusted to 24/19 pixels for readability.

The close button retains the complete original Settings artwork and its own colors, with no split/replacement X or extra tint. Its 44-pixel holder sits in the blue header with a gap above the content panel and uses the native button animation.

The floating @qtrzip [K] button is removed. Minimizing lazily creates a left-aligned TopbarPlus entry labeled @qtrzip. Clicking it reopens the hub; it hides while the menu is open, remains available after respawn, and is destroyed on unload. K still toggles the hub and can reopen it if a download fails.

The supplied place snapshot contains no TopbarPlus module. A pinned official distribution is bundled under vendor/TopbarPlus, including MPL-2.0 and unchanged Attribute attribution. An existing TopbarPlusReference is reused; otherwise the bundle is fetched once and cached for the session outside the hub's disposable task scope. See vendor/TopbarPlus/README.md for the loader adaptation.

Tests exercise the real game ClickableButton source for hover/press/release scales and sounds, mock TopbarPlus for lazy visibility/reuse/destroy behavior, and compile the official bundle and verify its 21-module loader graph. Run python tools/build_topbarplus.py and python tools/test_topbarplus.py. These tests do not establish live Roblox visual correctness.

## Topbar error repair, centered interaction and readable labels (revision 15)

The supplied console errors identified an absent Janitor.clean alias, followed by missing widget theme sizes. The generated TopbarPlus package now creates aliases from a table snapshot, supplies numeric widget defaults during initial theme layout, and uses a content-addressed dependency path. Startup repairs the previous owned cached package and cleans partially created blank icons before replacing the hub. Foreign topbar packages are excluded. Actual Janitor add/clean/destroy and old-package recovery now run in the regression harness.

Button scale animation is local to this hub: 1.012 hover and 0.985 press with Sine/Out easing. Buttons anchor at their center, keep native color/sound effects, and cancel outstanding scale tweens on cleanup. Native game ClickableButton constants are not mutated.

Main row labels use 28-pixel text, descriptions 20 and headings 28. Information no longer clips text strokes, inherited layout/text constraints are removed, alignment is explicitly left, and scrolling is vertical with an initial zero horizontal offset. Description rows have enough height for two lines. The input design and permanent bgsiscript loadstring are unchanged. These are regression-tested changes; live rendering remains unverified.

## Text inset and close glyph (revision 16)

Setting titles and descriptions start 8 logical pixels from the row's left edge instead of 17. Titles increase from 28 to 30 pixels, and the information column reclaims unused space. Description rows provide a separate 36-pixel title area and two lines below. The close target stays 44 pixels with a centered 34-pixel X, native red coloring, and a modest rounded-square corner rather than a circular background. The existing gentle centered animation remains.

## Native version label (script v102 / runtime revision 17)

The place's ClientScript writes its build text to PlayerGui.ScreenGui.VersionLabel. While this script runs, that existing label receives the suffix ` | v102`. The base version and `(t)`/`(p)` trading markers are retained, game-driven text changes are reflected, reruns do not duplicate the suffix, and unload restores the latest native text. The script release identifier is configured once as SCRIPT_VERSION in tools/build_testhub.py. Native label styling and the loadstring stay unchanged.
