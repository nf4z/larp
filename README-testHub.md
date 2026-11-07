# @qtrzip

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/bgsiscript"))()
```

The repository entry is `bgsiscript`. The window has no title or status footer. The reopen button and hub branding use **@qtrzip**.

- Default size: **600 x 420**, with viewport fitting.
- Drag the empty header area; resize with the bottom-right // handle.
- Press **K** to open/close. Keyboard text entry does not trigger it.
- Scroll the sidebar for all 19 tabs; search controls in the selected tab.

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

The builder combines `testhub_src/native-ui.lua` with the pinned `testhub_src/afbq-base.lua` and explicit feature additions into the standalone root `bgsiscript` script. Tests use `.tools/luau`, or `LUAU` and `LUAU_COMPILE` environment variables.

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

## Larplite hatch card port (script v103 / runtime revision 18)

Hatch messages now use the same announcement, custom emoji Pet Info rows, sorted variant stat multipliers, existence counts, base variant odds, colors, variant-specific pet image, Super enchant composite, XL full image and Discord timestamp as Larplite 2026.11.04.41. Discord Components V2 renders the same section/thumbnail/media layout. The old Renoa-specific image proxy override, Pet Info summary and debug Stats card are removed from the active builder.

Show User Info in Webhook / Hatch Embed adds Larplite's currencies, hatch totals and luck field; it defaults off like Larplite. Existing private settings, webhook URLs and filtering stay in qtrzip_settings.json. Username hiding uses Larplite's Player wording. Mention restrictions remain limited to the configured user ID. The queue and simulation endpoint both normalize V2 webhook parameters. Public output retains its existing anonymization. Real acquired pets keep their enchants; simulation alone may roll simulated Super enchants.

The 15 source functions are pinned with hashes in testhub_src/hatch-upstream.json, verified against GitHub core blob 3e53aea248b108c6f0585286b2111eed93950bc4. tools/port_testhub_hatch.py generates the isolated formatter; tools/testhub_hatch.py connects it to the existing scanner and simulation controls. Core values and layout remain from upstream; the adapter supplies this hub's settings, canonical pet flags and configured mention. The existing Super enchant image helper is shared with Larplite.

python tools/test_testhub_hatch.py compares full envelopes and V2 cards against the original upstream builder for normal/Shiny/Mythic/XL/Super cases, optional User Info and hiding. It exercises the generated bgsiscript bridge, source handling, real-enchant preservation and allowed mentions. Tests are offline and send no Discord messages. Live delivery is not verified. The permanent loadstring is unchanged; the native game label now appends v103.

## Automatic updates (script v104 / runtime revision 19)

Misc / Updates contains Auto Update (enabled by default), Check For Updates, and a status paragraph. Automatic checks start after 10 seconds and normally poll every 2 minutes. Checks fetch only bgsiscript-version.json; the full script is downloaded only when the manifest revision is newer. Disabled automatic updates stay disabled in this hub's saved config, while manual checks remain available. Network, metadata and compile failures keep the current script running and back off to at most 15 minutes.

Before replacing the hub, the updater compiles both the new immutable release and the current release for rollback, saves qtrzip_settings.json, and schedules execution using the original task scheduler. The new entry unloads the old runtime and its owned workers. If startup fails or no new window initializes, the previous release is restored with a 10-minute cooldown for that failed update. Unloading the hub cancels checks and queued reloads. A successful reload retains the window position, selected tab and minimized state.

The builder now writes three release artifacts: bgsiscript, bgsiscript-version.json and releases/bgsiscript/v104-r19.lua (the versioned path is generated from SCRIPT_VERSION and RUNTIME_REVISION). Future releases must increment RUNTIME_REVISION and the displayed SCRIPT_VERSION, rebuild and publish all three atomically. tools/publish_icon_cache.py includes the manifest and versioned source automatically. The manifest SHA-256 supports artifact verification; runtime checks the revision/version and compilation before replacing anything.

Run python tools/test_auto_update.py for offline tests of unchanged/current/new releases, metadata mismatch, compilation errors, staged rollback, toggle/manual behavior, overlapping checks, cancellation, backoff, failed startup recovery and preserved UI state. The real generated reload scheduler is exercised in the harness. The permanent user loadstring stays unchanged; execute it once to install this first auto-updating release.

Update reloads also use a one-time, revision-scoped in-memory settings handoff, so current preferences survive even if local file saving is unavailable. Rollback receives a fresh copy of the original settings rather than preferences mutated by a failed release. The handoff is consumed at startup and cleared after either reload path.

## Hatch-event-only notifications (included in v104)

The inventory-difference scanner is removed. Only the server's HatchEgg, HatchPowerupEgg and ExclusiveHatch client events feed automatic hatch cards. Existing inventory contents, startup/profile syncs, trades and ItemsReceived reward messages never enter that path. Manual simulation remains explicit. Actual hatch results carry their source egg/event into the Larplite formatter; animation hiding does not affect the listener.

Eligible IDs are claimed before asynchronous formatting, shared across reloads for 120 seconds and bounded to 4096 records. Same-name hatch results with different IDs remain separate, and batches without IDs are not deduplicated by pet name. Payload tables are copied before deferred work. Unload disconnects the listener and clears pending work. Auto-update waits for pending hatch formatting/sends before replacing the runtime.

python tools/test_hatch_events.py tests no startup/inventory/reward/trade messages, real event shapes, duplicate suppression, multiple same-name hatches, payload mutation, reload persistence, bounded state and unload cancellation offline. No Discord messages are sent by these tests.

## Detected workspace configs (script v105 / runtime revision 20)

Info / Detected Configs scans workspace-root config/settings JSON files on load. It recognizes 1rzHubLiteConfig_<userid>.json as Larplite profiles and qtrzip_settings.json as this hub's active file, and can identify renamed files from known flat/nested settings shapes. The selector uses concise account labels and marks the active file; the preview shows the full filename, format, current/other account, top-level key count and recognized sections. Rescan Configs preserves the selected file when it still exists.

Discovery reads files only to derive metadata: it does not display webhook URLs or other values, retain decoded config contents, apply/import settings, or write to another config. Invalid/oversized files are marked without echoing parser errors. Both listfiles root conventions and absolute/relative Windows paths are handled. Executors without directory listing can check only known current-account filenames; missing read APIs are reported in the panel. Scans do not recurse into cache folders and show at most 200 files.

Run python tools/test_config_discovery.py for schema/account detection, filename aliases, Windows/root API fallbacks, duplicate filtering, malformed JSON, metadata privacy and rescan selection tests. The provided personal config files are not included in the repository.

## Comp tab (script v106 / runtime revision 21)

Comp appears directly after Event. It uses the game's PinkVsBlue competition badge in the sidebar, the player's team shield, and the game's hatch and bubble art on native Settings cards. Team, contributions, and milestone controls have separate sections. Each contribution card shows the count in its title and team placement underneath, so the two values do not overlap. Only the top 100 places are exposed by the game; other placements show Outside top 100.

The two auto-claim toggles save under `comp` in this hub's own `qtrzip_settings.json` and default off. Claims use the game's personal milestone requirements and claim keys, track pending requests, and retry unconfirmed claims after 15 seconds. The tab does not join a team for the player. Refresh requests fresh standings; background updates run in owned tasks and the snapshot listener disconnects on unload. Unloading releases the competition subscription when the native competition screen is closed.

Run `python tools/test_competition.py` for team/art selection, contribution formatting, placement, earned-only claims, pending deduplication, private settings, profile readiness and cleanup checks. `python tools/test_testhub.py` also verifies navigation order and icon/text spacing with the real UI adapter. Live Roblox visuals and server responses still need in-game verification.

## Shrine renewal savings (script v107 / runtime revision 22)

Comp also has a `Live Leaderboards` button. It opens an independent simplified clone of the game's Comp frame: both team columns, their top 100, and Hatches/Bubbles buttons. Reward panels and join controls are removed. Incoming competition snapshots update the open board immediately, with a five-second subscription refresh while open. The UI reuses rows and preserves scroll positions. The game screen stays separate; closing/unloading destroys the owned popup and disconnects its handlers. `python tools/test_competition_popups.py` exercises both hubs' renderers with 100 players per team, live updates, switching, reuse, scrolling and cleanup.

Bubble and Dreamer shrine workers now wait until the game's `ShrineBlessingEndTime` expires before renewing. They no longer spend potions or Dream Shards whenever the hourly donation cooldown ends. The normal 500-potion / 15-shard batches provide 24 hours; a smaller owned batch lasts for the duration granted by the game. Existing shrine toggles and this hub's separate settings file are preserved. Missing blessing timers defer donations until profile data is available. Out-of-stock notifications occur only when renewal is due.

Run `python tools/test_shrine_expiry.py` for both scripts' real shrine workers with a virtual clock: hourly cooldowns, full blessing expiry, reloads, later game-side expiry, stock/restock behavior and donation amount limits. Checks are offline; live server behavior remains unverified.

Event / Penguin Trio Shop reads the game's `winter-shop` catalog, including all ten current products. Its multi-select options carry the actual item type, name and potion level for native ItemUtil icon rendering. Select products and enable Auto Buy Penguin Shop to purchase available, affordable stock. Selections use item identity rather than slot position. The worker follows native stock, discounts, mastery slot locks and restock periods, and waits for a purchase confirmation before retrying. Preferences save in this hub's own `penguinShop` settings. Run `python tools/test_penguin_shop.py` for selection, icon descriptor, stock, affordability, lock, retry and lifecycle checks.

## Leaderboard close button and images (script v108 / runtime revision 23)

The leaderboard popup uses the hub's normalized native close control with a 42-pixel target and centered 28-pixel X. Its holder has a fixed inset from the top/right edges, and the button fills its holder. Team headers now show the actual Seals/Frog Dogs shield assets; every rank retains its native Avatar image and requests Roblox's 100 x 100 headshot for that entry's UserId. The image changes only when the player at that rank changes, and follows hatch/bubble switching. Rank, avatar, name and score have separate fixed layout regions. Popup tests cover the real close activation, geometry, team shields and headshot reassignment. Live client appearance remains unverified.

## Guilds (script v109 / runtime revision 24)

Guilds appears directly below Quest, using the game's guild level badge and native Settings cards. Like Larplite, it shows the guild name/level/member count, current season/week, Guild/Global points, earned rewards, and three weekly quests with their current tier and next target. Refresh Guild requests a fresh snapshot; pushed GuildSnapshot events update the view between cached requests.

Auto Guild Quests handles Bubbles, Hatch and Sell tasks tier by tier. Hatching uses the Eggs tab's selected egg, available pet space, actual hatch capacity and native cooldown. Guild work pauses normal hatch/bubble/sell/present automation through a separate ownership flag, yields when another quest owns automation, and restores its original position when stopped normally. Tasks without progress for 60 seconds are deferred so another quest can run. Playtime is passive; chest, potion, fishing and minigame tasks remain manual, matching Larplite's supported task types.

Auto Claim Guild Rewards uses the native Guild/Global reward requirements and claim keys with the guild action cooldown and pending-claim deduplication. Auto Accept Guild Invites joins the first unexpired invitation only while unlocked and not already in a guild. All three toggles default off and save only under `guild` in `qtrzip_settings.json`. Guild mystery boxes and eggs remain available through the existing box opener and inventory egg hatcher.

Run `python tools/test_guild.py` for real module/bridge checks covering status and tiers, claim eligibility and deduplication, invitation validity, priority and stall handling, snapshot caching/races, hatch position/cooldown/capacity, sell behavior, position restoration and unload. UI/startup regressions run with `python tools/test_testhub.py`. Tests use controlled fixtures; live game behavior remains unverified.

## Halloween Shrine (script v110 / runtime revision 25)

Shrine / Halloween Shrine uses the native accepted potion catalog, XP values, 1,000,000-XP requirement and 12-hour duration. Select one potion and enable Auto Halloween Shrine to donate only the remaining XP deficit, claim, and wait until the active blessing expires. These buffs apply only to the game's Halloween egg list. The section shows the current buff, timer, XP, selected stock and activity; potion and target-buff dropdowns carry the game's typed item/icon descriptors.

Optional Reroll Halloween Buff uses the native Shrine Ticket cost and stops on the selected target. Requests wait for replicated XP/buff/start-time changes and back off after rejection. Missing profile data, unknown potion selections and insufficient stock/tickets defer spending. Both automation toggles default off; preferences save separately under `halloweenShrine` in `qtrzip_settings.json`. Larplite uses the same shared policy with its own flat config keys and Fleet label mapping. Run `python tools/test_halloween_shrine.py` for both adapters and the real shared policy, including partial XP, stock caps, delayed confirmation, expiry/reload, target stops and native remote arguments. Live server behavior remains unverified.

## Multiple Halloween targets (script v111 / runtime revision 26)

Halloween Target Buffs now accepts multiple checked buffs. Rerolling stops as soon as any selected buff appears, including when a selection changes while waiting for a previous request. Clearing the selection pauses rerolls and spends no more Shrine Tickets. The saved single `target` migrates into `halloweenShrine.targets`; an explicitly empty `targets` list is preserved. Potion selection, XP-efficient donations, claiming and the native 12-hour renewal cycle stay the same.

## Hatch webhook customization (script v112 / runtime revision 27)

Webhook centralizes hatch, online-ping and activity destinations, Discord mentions, notification filters and previews. Hatch Embed Customization controls rarity, egg-specific lifetime hatches, shared personal hatch count, pet stat multipliers, User Info, currencies and a hex accent color. Defaults show rarity above the source egg, this account's native `EggsOpened[eggName]` total, and the personal count immediately below Exist. Pet stats and account currencies default hidden; User Info retains total eggs and luck. Existing saved User Info preferences are preserved. The formatter and V2 renderer remain isolated from Larplite.

Confirmed rare/Super hatch events add to counts for the exact pet variant (Super/Shiny/Mythic/XL flags included). Counts start when this version observes a hatch; existing inventory and simulated previews never seed or increment history. Hatches count even with notifications disabled or excluded by a private odds/origin filter. The shared workspace snapshot is `qtrzip_hatch_totals.json`; authoritative per-session JSON shards live in `qtrzip_hatch_history/`. Each runtime writes its own shard so concurrent alts, including simultaneous sessions of the same account, cannot overwrite each other's increments. A new hatch merges readable shards; the snapshot converges on the next event if two writers update it simultaneously. Keep the folder with the snapshot when backing up or moving history. Accounts using different executor workspace directories do not share counts. Missing file APIs fall back to session counts with one warning; unreadable shards are skipped with a warning. Missing native egg counters display Unavailable rather than an invented total.

Run `python tools/test_hatch_customization.py`, `python tools/test_testhub_hatch.py`, and `python tools/test_hatch_events.py` for shared persistence, concurrent writers/reloads, defaults/customization, actual bridge-to-V2 output and event-only deduplication. Runtime, native UI and auto-update checks also pass offline. No Discord messages are sent by these tests; live client/server delivery remains unverified.
