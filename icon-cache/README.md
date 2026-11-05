# Categorized native icon cache

This cache contains **2,879 named icon records** in 11 categories and **7,885 unique asset references**, extracted from the supplied game snapshot without executing its scripts.

Folders: `pets`, `eggs`, `potions`, `items`, `runes`, `currencies`, `buffs`, `fish`, and `fishing/{rods,bait,bobbers}`. Each `records` folder contains named JSON records. Content-addressed category JSON files are what the hub requests; `paths.json` and `manifest.json` identify the current snapshot. Pet records include Normal/Shiny/Mythic/MythicShiny references where supplied. Rune records include individual tiers. Native potion/orb rendering recipes and sprite asset references are in `recipes`.

## Storage format and PNG limitation

The published cache currently stores Roblox asset IDs and game-native rendering recipes, **not PNG copies**. The Roblox asset-delivery server returned HTTP 401 for sampled originals. `mirrors.json` honestly marks unexported images; there are currently zero mirrored PNGs. The authenticated Roblox client still renders these references through its normal asset loader. No GitHub token or Roblox credential is placed in game code.

`tools/mirror_icon_assets.py --import-dir PATH` imports authorized PNG exports named `<assetId>.png` into deduplicated `assets/`. `--download` attempts publicly accessible originals and records HTTP failures without substituting fake images. Imported PNGs can be included by the publisher. They are optional archival mirrors; live icon rendering continues to use Roblox references/native recipes.

## Refresh

```text
python tools/build_icon_cache.py --source rbxBinaryParser_tmp/testhub_game.json
python tools/build_testhub.py
python tools/test_icon_cache.py
python tools/test_testhub.py
python tools/publish_icon_cache.py --repo nf4z/larp --branch main
```

The publisher uses your authenticated GitHub CLI and creates one atomic commit. It never embeds that authentication in the hub. Preserve old content-addressed category files so older loaders remain usable.

At runtime the hub lazily fetches a category once, validates schema/category, and optionally saves it to the executor workspace's `QtrzipIconCache` directory. Later launches reuse those category files. Failed HTTP, corrupt JSON, missing APIs or unknown records fall back to the live game data and native icon renderer. No per-pet HTTP request is needed.
