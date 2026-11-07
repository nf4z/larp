-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
do
-- Changelog style: newest release first. A note is a short title and ONE short
-- sentence saying what changed for the player - keep the description under about
-- 120 characters, and leave the reasoning and implementation detail to the commit.
activeStates.BGSI_Lite_ReleaseHistory = {
	{
		version = "2026.11.07.42",
		releasedAt = "November 7, 2026",
		notes = {
			{ title = "Comp tab", description = "Track team places and contributions, and claim hatch and bubble milestone rewards.", icon = "trophy" },
			{ title = "Live enchant targets", description = "Changing targets keeps a matching enchant locked and rerolls the unwanted slot immediately.", icon = "sparkles" },
			{ title = "Inventory hatching", description = "Waits for confirmed inventory progress, available pet space, and the game's hatch cooldown.", icon = "egg" },
		},
	},
	{
		version = "2026.11.04.41",
		releasedAt = "November 4, 2026",
		notes = {
			{ title = "Modular loading", description = "Tabs now load from cached GitHub modules, with inline defaults that preserve saved settings.", icon = "blocks" },
		},
	},
	{
		version = "2026.10.23.40",
		releasedAt = "October 23, 2026",
		notes = {
			{ title = "Bounty Rift handoff", description = "Summons the 25x, one-hour rift in the bounty egg's world before hatching it.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.23.39",
		releasedAt = "October 23, 2026",
		notes = {
			{ title = "Base hatch chances", description = "Hatch embeds use each egg's base pet chance and fixed variant rates, without player luck bonuses.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.22.38",
		releasedAt = "October 22, 2026",
		notes = {
			{ title = "More Super enchant icons", description = "Missing two-enchant badges now combine the original icons so both appear on Super Legendary hatches.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.21.37",
		releasedAt = "October 21, 2026",
		notes = {
			{ title = "Super simulation by default", description = "Legendary hatch tests now default to Super so their rolled enchants appear on the pet icon.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.21.36",
		releasedAt = "October 21, 2026",
		notes = {
			{ title = "Super hatch simulation", description = "A Super Legendary toggle lets hatch tests roll enchants and show their badge on the pet icon.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.21.35",
		releasedAt = "October 21, 2026",
		notes = {
			{ title = "Enchanted Super icons", description = "Super Legendary hatch icons show their enchant badges in the lower-left corner.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.20.34",
		releasedAt = "October 20, 2026",
		notes = {
			{ title = "AA hatch team", description = "Optionally equips Hatch Blessing supers for 4x eggs, falling back to Luck Boost supers.", icon = "sparkles" },
			{ title = "Full Fleet sync", description = "Sync now copies all configurable settings, including sliders, and refreshes the other accounts' controls.", icon = "users" },
		},
	},
	{
		version = "2026.10.20.33",
		releasedAt = "October 20, 2026",
		notes = {
			{ title = "Trick or Treat no longer stalls", description = "Visits one ready house at a time and lets other automation resume between visits.", icon = "ghost" },
			{ title = "Automation settings preserved", description = "Quest pauses no longer save Auto Hatch or Auto Bounty as disabled.", icon = "settings" },
		},
	},
	{
		version = "2026.10.19.32",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Fleet teleport", description = "The Leader can move every online account to the same server and exact position.", icon = "map-pin" },
		},
	},
	{
		version = "2026.10.19.31",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Variant hatch chance", description = "Hatch embeds show the final chance for the hatched variant, including luck and variant bonuses.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.19.30",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Hatch team updates", description = "New priority Super Legendaries refresh the Hatch team automatically, up to three equipped.", icon = "users" },
			{ title = "Dashboard backend removed", description = "Removed the unused account reporting worker and its connection control.", icon = "server" },
		},
	},
	{
		version = "2026.10.19.29",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Potion controls", description = "Select multiple owned potions and use a quantity limited by your inventory.", icon = "sparkles" },
			{ title = "Live shops", description = "Shop automation reads current stock, costs, unlocked slots, and confirmed free rerolls.", icon = "shop" },
			{ title = "Event Board quantities", description = "Choose how many Boost Crystal event purchases to make in one request.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.19.28",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Doodle Rift only", description = "Auto Special Rift now targets only doodle-rift; the priority selectors were removed.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.19.27",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Bubbling team toggle", description = "Bubbling quests can keep your current pet team instead of switching teams.", icon = "users" },
		},
	},
	{
		version = "2026.10.19.26",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Fishing thread fix", description = "Fishing no longer stops when its background status update lacks UI access.", icon = "fish" },
			{ title = "Bubbling quests", description = "Bubbling tasks use the Bubbles team and a sell station, then return to Hatch.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.19.25",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Fishing automation", description = "Added island progression, auto fishing, fish index rewards, rod upgrades, and inventory controls.", icon = "fish" },
			{ title = "Rebirth Machine flow", description = "Machine automation now avoids activation popups when possible and closes them when opened.", icon = "refresh" },
		},
	},
	{
		version = "2026.10.19.24",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Visible User Info toggle", description = "Moved Show User Info to the top of the Webhook tab.", icon = "eye" },
			{ title = "Auto Update version check", description = "Auto Update no longer replaces a newer local script with an older GitHub version.", icon = "refresh" },
		},
	},
	{
		version = "2026.10.19.23",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Rebirth reward filter", description = "Send Easy Secrets now applies only to Rebirth Machine rewards.", icon = "filter" },
		},
	},
	{
		version = "2026.10.19.22",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Hatch embed controls", description = "User Info can be shown from Webhook settings and is hidden by default.", icon = "eye" },
			{ title = "Easy Secret filter", description = "Rebirth settings can limit pet webhooks to Celestial, Infinity, and Void.", icon = "filter" },
			{ title = "Pearl icon", description = "Pet stat lines now use the Pearl emoji.", icon = "gem" },
		},
	},
	{
		version = "2026.10.19.21",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Halloween tab", description = "Replaced Fall Event with Halloween rebirths, chest claims, and house-by-house trick or treat.", icon = "ghost" },
			{ title = "Rebirth machines", description = "Normal and Admin fusions use their verified pet rules, cooldowns, and remotes.", icon = "repeat" },
			{ title = "Hatch enchants", description = "Enchant names now appear in bold in hatch messages.", icon = "sparkles" },
		},
	},
	{
		version = "2026.10.19.20",
		releasedAt = "October 19, 2026",
		notes = {
			{ title = "Rewards and eggs", description = "Fixed playtime claims, egg auto-delete, and Infinite Track checks.", icon = "egg" },
			{ title = "Quests and shrines", description = "Ticket and Pearl quests are enabled; shrines donate when the blessing timer has room.", icon = "sparkles" },
			{ title = "Rebirth and events", description = "Restored Rebirth controls, Halloween rebirth and chest claims, and Present Rain pickup.", icon = "repeat" },
		},
	},
	{
		version = "2026.10.19.19",
		releasedAt = "October 19, 2026",
		notes = {
			{
				title = "Compact hatch enchants",
				description = "Super Legendary enchants now appear on one clean line in hatch messages.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.18",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Special hatch reveals",
				description = "Void, Celestial, and Infinity previews now use their game hatch reveals.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.17",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Hatch animation preview",
				description = "Preview the game's hatch animation for any pet from the Webhooks tab.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.16",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Simulated Super enchants",
				description = "Simulated Super Legendary pets roll game-weighted enchants, with two slots when shiny.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.15",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Super Legendary enchants",
				description = "Super Legendary hatch messages show their enchantments again.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.14",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Egg source fallback",
				description = "Hatch messages keep the Egg label and show a pet's tag when its egg cannot be found.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.13",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Pet reward origins",
				description = "Season Pass and other pet rewards now show their source, with a clean Discord footer time.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.12",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Hatch exist counts",
				description = "Fixed exist-count lookups for live and simulated hatch messages.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.11",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Cleaner hatch simulation",
				description = "Removed the simulation status field; send results now appear as brief notifications.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.10",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Candycorn hatch icon",
				description = "Fixed the Candycorn emoji in hatch messages, including simulated hatches.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.09",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Simulate pet hatch",
				description = "Enter a pet name in Webhook to send a test hatch message with its game data and variants.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.08",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "hatch messages",
				description = "updated hatch embed",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.10.18.07",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Simpler Leader page",
				description = "A compact account roster keeps live sync and handover controls easy to find.",
				icon = "crown",
			},
		},
	},
	{
		version = "2026.10.18.06",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Clearer account role names",
				description = "Fleet controls and status now use the clearer Leader title for the coordinating account.",
				icon = "crown",
			},
		},
	},
	{
		version = "2026.10.18.05",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Account fleet with a Leader account",
				description = "The longest-running account becomes Leader, gets a blue theme and Leader tab, and shares settings live.",
				icon = "crown",
			},
		},
	},
	{
		version = "2026.10.18.04",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Hatch exist counts restored",
				description = "Hatch messages now use the pet name expected by the game's existing-count lookup.",
				icon = "hash",
			},
		},
	},
	{
		version = "2026.10.18.03",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Accurate hatch odds and clean numbers",
				description = "Hatch messages use your active egg luck and variant bonuses, with comma-separated numbers.",
				icon = "sparkles",
			},
		},
	},
	{
		version = "2026.10.18.02",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Shorter webhook label",
				description = "The minimum hatch chance setting is now labeled Minimum Chance.",
				icon = "filter",
			},
		},
	},
	{
		version = "2026.10.18.01",
		releasedAt = "October 18, 2026",
		notes = {
			{
				title = "Egg names in hatch messages",
				description = "Hatch webhooks now show the egg below Origins, using hatch results and the game's egg data.",
				icon = "egg",
			},
			{
				title = "Minimum hatch chance",
				description = "Filter hatch webhooks by final odds using values such as 50m, 50b, or 5t.",
				icon = "filter",
			},
		},
	},
	{
		version = "2026.09.27.12",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Auto-Farm Leaves no longer teleports anywhere",
				description = "It now just equips the Leaves team and pauses Auto Hatch, instead of moving the player to a hardcoded spot.",
				icon = "leaf",
			},
		},
	},
	{
		version = "2026.09.27.11",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Auto Setup Team only ever touches the team named \"Hatch\"",
				description = "It used to maintain whatever team was equipped, including Leaves - now it leaves every other team alone.",
				icon = "team",
			},
		},
	},
	{
		version = "2026.09.27.10",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Quest hatching no longer interrupts Auto-Farm Leaves",
				description = "Season Pass, Guild Quests, and similar hatch quests were teleporting away from the Leaves spot to hatch an egg.",
				icon = "leaf",
			},
			{
				title = "Autumn Rebirth fires the moment it's affordable",
				description = "It shared a once-a-second pass with other Fall Event tasks, so it could sit ready for most of a second before firing.",
				icon = "zap",
			},
		},
	},
	{
		version = "2026.09.27.09",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Auto Currency Teams no longer equips a hatch team on its own",
				description = "Its \"hatch\" category reused Auto Setup Team's own logic, so it kept equipping one even with Auto Setup Team off.",
				icon = "team",
			},
		},
	},
	{
		version = "2026.09.27.08",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Safe Mode no longer re-enables Auto Setup Team",
				description = "Turning Safe Mode off could restore an old, stale copy of the setting and re-equip your team.",
				icon = "team",
			},
		},
	},
	{
		version = "2026.09.27.07",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Potion and item icons show up on the dashboard",
				description = "Only two layers of each icon were sent, so anything drawn differently arrived blank.",
				icon = "image",
			},
		},
	},
	{
		version = "2026.09.27.06",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Using an Elixir from the dashboard works",
				description = "Elixirs with no level were looked up as level 1, so the game saw none of them to use.",
				icon = "flask-conical",
			},
			{
				title = "Using many potions at once no longer stops early",
				description = "Each request uses exactly one potion, but the script assumed ten and gave up a tenth of the way.",
				icon = "layers",
			},
		},
	},
	{
		version = "2026.09.27.05",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Shorter changelog entries",
				description = "Every past entry is now one short sentence, and new ones will be too.",
				icon = "list",
			},
		},
	},
	{
		version = "2026.09.27.04",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Inventory Cleanup actually deletes pets now",
				description = "The delete request was missing the amount, so the server never removed anything.",
				icon = "trash-2",
			},
			{
				title = "Cleanup can trim a stack instead of needing to drop it whole",
				description = "It now removes just the copies above your minimum instead of only ever dropping a whole stack.",
				icon = "layers",
			},
			{
				title = "Deleting a pet from the dashboard works",
				description = "The dashboard's delete button fired the same incomplete request, so it never removed anything either.",
				icon = "trash-2",
			},
		},
	},
	{
		version = "2026.09.27.03",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "The same egg no longer shows a different icon on each account",
				description = "Egg icons now come from the egg's own image instead of whatever a search found first.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.09.27.02",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Egg icons on the dashboard are the real ones again",
				description = "Eggs now send their real icon to the dashboard instead of a generic placeholder.",
				icon = "egg",
			},
			{
				title = "Fixed dropdown choices now come from the script",
				description = "The dashboard shows the choices this build supports instead of its own stale copy.",
				icon = "list",
			},
		},
	},
	{
		version = "2026.09.27.01",
		releasedAt = "September 27, 2026",
		notes = {
			{
				title = "Dashboard sync failures now say what is actually wrong",
				description = "A blocked URL, a rejected key and a wrong endpoint no longer all print the same thing.",
				icon = "plug",
			},
		},
	},
	{
		version = "2026.09.26.03",
		releasedAt = "September 26, 2026",
		notes = {
			{
				title = "Dashboard dropdowns that were always empty now fill in",
				description = "Target Rifts, Special Rift Priority, World Chests and Inventory Egg are pickable again.",
				icon = "list",
			},
			{
				title = "Live webhook URL is no longer reported to the dashboard",
				description = "You can still set it from the dashboard, but the saved value is never sent back.",
				icon = "shield-check",
			},
			{
				title = "A custom dashboard host is left alone",
				description = "Startup only fills in an unset endpoint now instead of rewriting it every run.",
				icon = "link",
			},
		},
	},
	{
		version = "2026.09.20.02",
		releasedAt = "September 20, 2026",
		notes = {
			{
				title = "a",
				description = "a",
				icon = "webhook",
			},
		},
	},
	{
		version = "2026.09.20.01",
		releasedAt = "September 20, 2026",
		notes = {
			{
				title = "Added Fall Event automation",
				description = "Autumn rebirths, Leaves farming, prioritised upgrades, Elixir use and Chest opening.",
				icon = "leaf",
			},
		},
	},
	{
		version = "2026.09.19.09",
		releasedAt = "September 19, 2026",
		notes = {
			{
				title = "Fixed the script's startup syntax error",
				description = "The script would not load at all.",
				icon = "bug",
			},
		},
	},
	{
		version = "2026.09.19.08",
		releasedAt = "September 19, 2026",
		notes = {
			{
				title = "Removed remaining Auto Inventory Egg nil-call path",
				description = "The inventory hatch runner is guarded so a missing client API cannot break it.",
				icon = "shield-check",
			},
		},
	},
	{
		version = "2026.09.19.07",
		releasedAt = "September 19, 2026",
		notes = {
			{
				title = "Hardened Auto Inventory Egg remote and hatch checks",
				description = "Guards the hatch-state call so a missing method cannot stop the runner.",
				icon = "shield-check",
			},
		},
	},
	{
		version = "2026.09.19.06",
		releasedAt = "September 19, 2026",
		notes = {
			{
				title = "Fixed Auto Inventory Egg runtime errors",
				description = "Reworked to follow the game's real Auto Exclusive Egg flow.",
				icon = "bug",
			},
		},
	},
	{
		version = "2026.09.19.05",
		releasedAt = "September 19, 2026",
		notes = {
			{
				title = "Inventory Egg hatching is much faster",
				description = "Uses the game's 12-egg batch instead of waiting for the inventory to catch up each time.",
				icon = "zap",
			},
		},
	},
	{
		version = "2026.09.19.04",
		releasedAt = "September 19, 2026",
		notes = {
			{
				title = "Bounty Rift uses the current player world",
				description = "Summons now use the world the game reports for you, which the server was rejecting.",
				icon = "map-pin",
			},
		},
	},
	{
		version = "2026.09.19.03",
		releasedAt = "September 19, 2026",
		notes = {
			{
				title = "Force Update for Auto Setup Team",
				description = "Rebuilds your team and equips the current Super Legendary combination on demand.",
				icon = "refresh-cw",
			},
		},
	},
	{
		version = "2026.09.19.02",
		releasedAt = "September 19, 2026",
		notes = {
			{
				title = "Auto Setup Team settings now apply immediately",
				description = "Changing any Auto Setup Team option rebuilds and equips straight away.",
				icon = "users",
			},
		},
	},
	{
		version = "2026.09.19.01",
		releasedAt = "September 19, 2026",
		notes = {
			{
				title = "Bounty Rift now summons the actual current bounty",
				description = "It only locks onto a rift that actually matches the bounty egg.",
				icon = "bug",
			},
		},
	},
	{
		version = "2026.09.12.07",
		releasedAt = "September 12, 2026",
		notes = {
			{
				title = "Auto Enchant now actually fills both slots",
				description = "With two targets set it now requires both enchant slots filled before a pet counts as done.",
				icon = "wand-sparkles",
			},
		},
	},
	{
		version = "2026.09.12.06",
		releasedAt = "September 12, 2026",
		notes = {
			{
				title = "Quest hatching is more reliable",
				description = "Quest hatching now confirms the teleport landed before firing, and retries until it has.",
				icon = "egg",
			},
			{
				title = "Auto Hatch returns to your egg immediately after a quest",
				description = "Finishing a quest task returns to your egg at once instead of waiting up to 2 seconds.",
				icon = "corner-up-left",
			},
		},
	},
	{
		version = "2026.09.12.05",
		releasedAt = "September 12, 2026",
		notes = {
			{
				title = "Special Rift Priority is now built from real game data",
				description = "The list reads the game's rift data directly, so new rifts appear without an update.",
				icon = "sparkles",
			},
		},
	},
	{
		version = "2026.09.12.04",
		releasedAt = "September 12, 2026",
		notes = {
			{
				title = "Server tab (new)",
				description = "Live players, uptime, ping and FPS, active events, global boosts, rifts and who is here.",
				icon = "server",
			},
			{
				title = "Server tools",
				description = "Anti-AFK, auto rejoin, server hop, hop to emptiest, join alerts, and copy or join a Job Id.",
				icon = "wrench",
			},
		},
	},
	{
		version = "2026.09.12.03",
		releasedAt = "September 12, 2026",
		notes = {
			{
				title = "Box Condenser (new)",
				description = "Turns every 100 Mystery Boxes into a Condensed one, with a Keep Gems reserve.",
				icon = "package",
			},
			{
				title = "Auto Open Box takes multiple boxes",
				description = "Pick any mix of boxes and it takes turns opening the ones you own.",
				icon = "gift",
			},
		},
	},
	{
		version = "2026.09.12.01",
		releasedAt = "September 12, 2026",
		notes = {
			{
				title = "Guilds tab (new)",
				description = "Shows your guild and weekly quests, works them for you, and claims the rewards.",
				icon = "shield",
			},
			{
				title = "Bubbling actually blows now",
				description = "It only stops when storage is really full now, the same as the game.",
				icon = "circle",
			},
		},
	},
	{
		version = "2026.09.06.34",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Skip Ticket and Pearl Quests: closed the teleport gap",
				description = "Skip is rechecked before any teleport, so a queued run cannot start one anyway.",
				icon = "square-x",
			},
		},
	},
	{
		version = "2026.09.06.33",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Skip Ticket and Pearl Quests now interrupts a run in progress",
				description = "Turning Skip on now stops a ticket or pearl run immediately instead of after it finishes.",
				icon = "square-x",
			},
		},
	},
	{
		version = "2026.09.06.32",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Inventory Cleanup no longer waits for a full inventory",
				description = "It trims any disposable stack over your minimum right away, leaving rare pets untouched.",
				icon = "trash-2",
			},
		},
	},
	{
		version = "2026.09.06.31",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Fixed a crash that broke other tabs on load",
				description = "A helper was called before it existed, which cut off every tab that had not loaded yet.",
				icon = "bug",
			},
			{
				title = "Season Pass Quests now actually get claimed",
				description = "Finished quests are claimed instead of being dropped from the list before anything claims them.",
				icon = "check-check",
			},
		},
	},
	{
		version = "2026.09.06.30",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Guaranteed sell kiosk position for The Overworld",
				description = "Added the real Sell kiosk coordinates as a fallback for when the live scan finds nothing.",
				icon = "map-pin",
			},
		},
	},
	{
		version = "2026.09.06.29",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Reload Script button (new)",
				description = "Downloads the script fresh and reloads immediately, even on the same version.",
				icon = "refresh-cw",
			},
		},
	},
	{
		version = "2026.09.06.28",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Rifts tab is actually gone now",
				description = "The tab is no longer created at all, so nothing can bring it back.",
				icon = "trash-2",
			},
			{
				title = "Shadow Leviathan pet always selectable as a reroll target",
				description = "The Leviathan pet is always available to pick now, along with the good Fragments.",
				icon = "target",
			},
		},
	},
	{
		version = "2026.09.06.27",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Removed Claim 4th Rewards",
				description = "Removed the leftover July 4th event toggle and its background claim loop.",
				icon = "trash-2",
			},
			{
				title = "Shadow Leviathan Quest can target a specific reward",
				description = "Added a Target Item picker and an Optimised hatch-only mode, the same as Gem Genie.",
				icon = "target",
			},
			{
				title = "Auto Claim Chest supports multiple chests",
				description = "Select Chest is now multi-select - pick as many chests as you want claimed automatically instead of just one.",
				icon = "package",
			},
			{
				title = "Swapped Overlord Rift for Cloudy Egg Rift",
				description = "Overlord Rift was removed from the game, so it's gone from the Special Rift Priority list, replaced with Cloudy Egg Rift.",
				icon = "refresh-cw",
			},
			{
				title = "Rebirth Machine pets are now a dropdown",
				description = "Pick from a list of every Secret pet the machine accepts instead of typing names.",
				icon = "list-filter",
			},
		},
	},
	{
		version = "2026.09.06.26",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Rifts tab kept reappearing - fixed for real this time",
				description = "The Rifts row stays hidden for the whole session instead of only once.",
				icon = "eye-off",
			},
		},
	},
	{
		version = "2026.09.06.25",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Fixed Auto Rebirth Machine doing nothing",
				description = "The rebirth call was missing an argument the game requires, so every attempt failed silently.",
				icon = "wrench",
			},
		},
	},
	{
		version = "2026.09.06.24",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Fixed bubble quests getting stuck",
				description = "It re-finds the nearest sell kiosk each time instead of trusting a stale one.",
				icon = "bug",
			},
			{
				title = "Stuck Gem Genie quests now force a reroll",
				description = "A quest with no progress for 4 minutes rerolls automatically instead of staying parked.",
				icon = "refresh-cw",
			},
		},
	},
	{
		version = "2026.09.06.23",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "All 8 Super Legendary enchants in Auto Setup Team",
				description = "Added Bubble Machine, Burst, Shiny, Mythic, Infinity and Duplication, with their + versions.",
				icon = "sparkles",
			},
		},
	},
	{
		version = "2026.09.06.22",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Actually hid the Rifts tab this time",
				description = "It finds the real sidebar row and hides it instead of guessing at internal names.",
				icon = "eye-off",
			},
		},
	},
	{
		version = "2026.09.06.21",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Auto Setup Team is now one switch",
				description = "The button and toggle are one switch that applies immediately and keeps it applied.",
				icon = "toggle-left",
			},
			{
				title = "Fixed Auto Setup Team ignoring Safe Mode",
				description = "The team logic refuses to run while Safe Mode is on, whatever triggers it.",
				icon = "shield",
			},
		},
	},
	{
		version = "2026.09.06.20",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Hid the Rifts tab",
				description = "Automation keeps running on its last settings, still changeable from the dashboard.",
				icon = "eye-off",
			},
		},
	},
	{
		version = "2026.09.06.19",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Auto Currency Teams (new)",
				description = "Switches to the right saved currency team, or builds one from your best pets.",
				icon = "users",
			},
		},
	},
	{
		version = "2026.09.06.18",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Auto Shadow Leviathan Quest (new)",
				description = "Picks a quest as soon as one is available and completes it, with optional rerolling.",
				icon = "moon",
			},
		},
	},
	{
		version = "2026.09.06.17",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Auto Sell Bubble no longer needs to be near the kiosk",
				description = "It finds the nearest kiosk and snaps there and back to sell.",
				icon = "map-pin",
			},
		},
	},
	{
		version = "2026.09.06.16",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Bubble blowing no longer pauses for hatching",
				description = "Blowing and selling now run freely alongside hatching.",
				icon = "sparkles",
			},
		},
	},
	{
		version = "2026.09.06.15",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "More reliable ticket/pearl pickup collection",
				description = "Ticket farming scans the game's real pickup folder, so it collects more consistently.",
				icon = "coins",
			},
		},
	},
	{
		version = "2026.09.06.14",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Fixed Inventory Cleanup never deleting anything",
				description = "Cleanup was treating every pet as enchanted, so it never found anything to delete.",
				icon = "trash-2",
			},
		},
	},
	{
		version = "2026.09.06.13",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Cleaner changelog",
				description = "Update History shows recent changes at a glance instead of a giant list of buttons.",
				icon = "scroll-text",
			},
		},
	},
	{
		version = "2026.09.06.12",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Mystery boxes and inventory eggs open concurrently",
				description = "Mystery boxes and inventory eggs now open several at once instead of one at a time, so it's much faster.",
				icon = "zap",
			},
		},
	},
	{
		version = "2026.09.06.11",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Removed Bubble Competition",
				description = "Regular bubble farming is unaffected.",
				icon = "trash-2",
			},
		},
	},
	{
		version = "2026.09.06.10",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Fixed Auto Update stacking duplicate menus",
				description = "Fixed Auto Update sometimes reloading repeatedly and stacking duplicate menu windows on top of each other.",
				icon = "refresh-cw",
			},
		},
	},
	{
		version = "2026.09.06.09",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Fixed Auto Open Box stopping at 10",
				description = "Fixed Auto Open Box stopping early instead of actually opening the full 50 boxes per batch.",
				icon = "gift",
			},
		},
	},
	{
		version = "2026.09.06.08",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Fixed hatching blocking mystery box collection",
				description = "Fixed hatching spamming duplicate requests fast enough to crowd out mystery box opening on the shared channel.",
				icon = "zap",
			},
			{
				title = "Hatching is now event-driven",
				description = "Hatching now fires the instant the cooldown ends instead of waiting for the next poll, with no wasted requests.",
				icon = "gauge",
			},
		},
	},
	{
		version = "2026.09.06.07",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Icons next to every dropdown option",
				description = "Every dropdown in the menu now shows an icon next to each option, matching the game's own icons.",
				icon = "image",
			},
		},
	},
	{
		version = "2026.09.06.06",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Auto Hatch Inventory Egg (new)",
				description = "Added Auto Hatch Inventory Egg, a new section for hatching eggs held as items rather than spawned in the world.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.09.06.05",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Fixed rifts box crash: 'lacking capability Plugin'",
				description = "Fixed a crash in the Current Rifts box caused by how it rebuilt its text labels in the background.",
				icon = "bug",
			},
			{
				title = "Webhook: fixed Secret Luck reading half the real value",
				description = "Fixed the webhook showing roughly half the real Secret Luck value when the game combines it with Infinity Luck.",
				icon = "bug",
			},
		},
	},
	{
		version = "2026.09.06.04",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Fixed rifts box stuck on 'Scanning...'",
				description = "Fixed the rift scan box getting stuck on 'Scanning...' forever after a single error.",
				icon = "bug",
			},
		},
	},
	{
		version = "2026.09.06.03",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Re-enchant threshold",
				description = "Added a 'Re-enchant Below Level' option to re-roll pets that finished enchanting at a low level.",
				icon = "refresh-cw",
			},
		},
	},
	{
		version = "2026.09.06.02",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Mystery Box: parallel collection, real 50-box batches",
				description = "Mystery Box collection now happens in parallel and properly opens full batches of 50 instead of stalling.",
				icon = "zap",
			},
		},
	},
	{
		version = "2026.09.06.01",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Mystery Box: true instant collection, no teleporting",
				description = "Mystery Box opening now collects each drop instantly with no hitting and no teleporting to it.",
				icon = "zap",
			},
			{
				title = "Auto Setup Team: fixed stalling after one equip",
				description = "Fixed Auto Setup Team stalling after equipping just one pet when the team looked full.",
				icon = "users",
			},
		},
	},
	{
		version = "2026.09.05.09",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Mystery Box batches raised to 50",
				description = "Auto Open Box now opens up to 50 gifts per batch instead of 10.",
				icon = "gift",
			},
		},
	},
	{
		version = "2026.09.05.08",
		releasedAt = "September 6, 2026",
		notes = {
			{
				title = "Auto Setup Team (new, off by default)",
				description = "Added Auto Setup Team, an opt-in tool under Enchant that equips your best shiny pets for you.",
				icon = "users",
			},
			{
				title = "Webhook heading restored",
				description = "Fixed the webhook's pet name heading losing its '# Name' style and reverting to plain bold text.",
				icon = "image",
			},
		},
	},
	{
		version = "2026.09.05.07",
		releasedAt = "September 5, 2026",
		notes = {
			{
				title = "Enchant: instant lock, zero-race",
				description = "Enchanting now locks onto target enchants instantly with no more race conditions, and target matching was tightened up.",
				icon = "lock",
			},
			{
				title = "Mystery Box opening actually works now",
				description = "Fixed Auto Open Box not actually granting rewards - it now waits for and collects each drop properly.",
				icon = "gift",
			},
		},
	},
	{
		version = "2026.09.05.06",
		releasedAt = "September 5, 2026",
		notes = {
			{
				title = "Removed all automatic pet equip/unequip",
				description = "Removed all automatic pet team swapping - the script no longer equips or unequips pets on its own.",
				icon = "shield-check",
			},
		},
	},
	{
		version = "2026.09.05.05",
		releasedAt = "September 5, 2026",
		notes = {
			{
				title = "Rayfield Gen2 1.2.0: Sidebar layout",
				description = "Menu tabs now run down a sidebar instead of across the top, grouped under section headings.",
				icon = "panel-left",
			},
			{
				title = "New elements: Text, Divider, Progress, Console",
				description = "Added new Text, Divider, Progress, and Console elements to the menu.",
				icon = "layout-list",
			},
			{
				title = "Element locking",
				description = "Toggles, sliders, dropdowns, inputs, and buttons can now be locked to block interaction with them.",
				icon = "lock",
			},
		},
	},
	{
		version = "2026.09.05.04",
		releasedAt = "September 5, 2026",
		notes = {
			{
				title = "Auto Update fix: stuck 'latest version' flag",
				description = "Fixed Auto Update getting permanently stuck reporting you're on the latest version even when you're not.",
				icon = "bug",
			},
		},
	},
	{
		version = "2026.09.05.03",
		releasedAt = "September 5, 2026",
		notes = {
			{
				title = "No more auto-equip on load",
				description = "Auto Build Bubble Team now defaults off, so the script no longer swaps your pet team the moment it loads.",
				icon = "shield-check",
			},
		},
	},
	{
		version = "2026.09.05.02",
		releasedAt = "September 5, 2026",
		notes = {
			{
				title = "Auto Update",
				description = "Added Auto Update, which checks for a newer release and reloads automatically, with a manual check button too.",
				icon = "refresh-cw",
			},
		},
	},
	{
		version = "2026.09.05.01",
		releasedAt = "September 5, 2026",
		notes = {
			{
				title = "Hatch webhook heading fix",
				description = "Fixed the hatch webhook's pet name heading leaving a large gap above User Info.",
				icon = "image",
			},
		},
	},
	{
		version = "2026.09.01.01",
		releasedAt = "September 1, 2026",
		notes = {
			{
				title = "Sky Altar support",
				description = "Added Auto Sky Altar, with cooldown handling and eligible pet selection built in.",
				icon = "cloud",
			},
			{
				title = "Sky Altar special recipe handling",
				description = "Added support for the Rainshine x3 special recipe, correctly picking three distinct pets for it.",
				icon = "sparkles",
			},
			{
				title = "Rebirth configuration compatibility",
				description = "Added a saved Sky Altar setting without touching your existing rebirth settings.",
				icon = "settings",
			},
		},
	},
	{
		version = "2026.08.19.07",
		releasedAt = "August 19, 2026",
		notes = {
			{
				title = "Hatch Webhook Variant Header + Icon Fix",
				description = "Fixed the hatch webhook showing the pet's variant name and icon together properly.",
				icon = "image",
			},
			{
				title = "Hatch Webhook Variant Heading Fix",
				description = "Cleaned up the hatch webhook's title into a compact variant and pet name heading.",
				icon = "heading",
			},
			{
				title = "Per-account config and live webhook isolation",
				description = "Each Roblox account now gets its own settings and webhook message instead of sharing and overwriting one.",
				icon = "users",
			},
			{
				title = "Live Webhook Emoji Layout",
				description = "Updated the live webhook's emojis and layout for hatch speed, luck, uptime, and best hatch.",
				icon = "sparkles",
			},
			{
				title = "Persistent Live Webhook + Hatch Webhook Formatting",
				description = "The live webhook now edits the same Discord message across reloads instead of posting a new one.",
				icon = "radio",
			},
			{
				title = "Hatch request safeguard",
				description = "Hatch requests now fall back to one egg instead of breaking if the max-hatch calculation fails.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.08.15.02",
		releasedAt = "August 15, 2026",
		notes = {
			{
				title = "Targeted rift server hopping",
				description = "Added server hopping for egg rifts, with checked-server history and priority for 4x Egg.",
				icon = "shuffle",
			},
		},
	},
	{
		version = "2026.08.14.05",
		releasedAt = "August 14, 2026",
		notes = {
			{
				title = "Gated special rift priority",
				description = "Special rift priority now only applies while Auto Special Rift is turned on.",
				icon = "circle-dot",
			},
		},
	},
	{
		version = "2026.08.14.01",
		releasedAt = "August 14, 2026",
		notes = {
			{
				title = "Special rift priorities",
				description = "Added priority ordering for Corrupt Shadow, Shadow, Overlord, and Doodle rifts, with 4x Luck still first.",
				icon = "list-ordered",
			},
			{
				title = "Carnival tab removed",
				description = "Removed the Carnival tab and its controls from the interface.",
				icon = "panel-top-close",
			},
		},
	},
	{
		version = "2026.08.02.04",
		releasedAt = "August 2, 2026",
		notes = {
			{
				title = "Version marker update",
				description = "Bumps the active script version and refreshes the release history entry for the latest build.",
				icon = "refresh-cw",
			},
		},
	},
	{
		version = "2026.08.02.01",
		releasedAt = "August 2, 2026",
		notes = {
			{
				title = "Crystal enchant rerolls",
				description = "Shadow Crystal rerolls now protect your target enchant slots the same way manual rolling does.",
				icon = "wand-sparkles",
			},
			{
				title = "Full shiny enchant teams",
				description = "Equips every shiny Celestial and Secret pet before enchanting and blocks rerolls until the team is full.",
				icon = "team",
			},
		},
	},
	{
		version = "2026.07.31.06",
		releasedAt = "July 31, 2026",
		notes = {
			{
				title = "Visible automation controls",
				description = "Added menu settings for popup closing, Event Board purchases, and the Season Infinite Track.",
				icon = "settings-2",
			},
		},
	},
	{
		version = "2026.07.31.05",
		releasedAt = "July 31, 2026",
		notes = {
			{
				title = "Automatic Crystal Altar",
				description = "Crystal Altar now uses your owned pets and prioritizes the guaranteed Omega Crystal Dragon recipe.",
				icon = "gem",
			},
		},
	},
	{
		version = "2026.07.31.04",
		releasedAt = "July 31, 2026",
		notes = {
			{
				title = "Complete enchant teams",
				description = "Enchanting now counts stacked pet copies properly and fixes partial team equips before starting.",
				icon = "wand-sparkles",
			},
		},
	},
	{
		version = "2026.07.31.03",
		releasedAt = "July 31, 2026",
		notes = {
			{
				title = "Uninterrupted 4x Luck hatching",
				description = "4x Luck egg hatching now takes priority over special rifts and auto-closes in-game prompts.",
				icon = "badge-x",
			},
		},
	},
	{
		version = "2026.07.31.02",
		releasedAt = "July 31, 2026",
		notes = {
			{
				title = "Reliable dashboard updates",
				description = "Update checks now use immutable GitHub commit versions and retry briefly stale downloads.",
				icon = "refresh-cw",
			},
		},
	},
	{
		version = "2026.07.31.01",
		releasedAt = "July 31, 2026",
		notes = {
			{
				title = "Automatic Event Board and Infinite Track",
				description = "Added automatic Boost Crystal event purchases and auto-starts the Season Infinite Track after completion.",
				icon = "infinity",
			},
		},
	},
	{
		version = "2026.07.28.10",
		releasedAt = "July 28, 2026",
		notes = {
			{
				title = "Cooldown-aware obby selection",
				description = "Obby automation now skips courses on cooldown and starts the hardest one available.",
				icon = "timer-reset",
			},
		},
	},
	{
		version = "2026.07.28.09",
		releasedAt = "July 28, 2026",
		notes = {
			{
				title = "Fast three-key chest draining",
				description = "Obby chests with three keys now open faster, with hatching paused briefly while they drain.",
				icon = "fast-forward",
			},
		},
	},
	{
		version = "2026.07.28.08",
		releasedAt = "July 28, 2026",
		notes = {
			{
				title = "Fully automatic obby cycle",
				description = "Obby automation now runs Hard, Medium, and Easy in order and drains each course's keys.",
				icon = "repeat-2",
			},
		},
	},
	{
		version = "2026.07.28.07",
		releasedAt = "July 28, 2026",
		notes = {
			{
				title = "Server-registered obby runs",
				description = "Obby automation now waits for the game's actual run state before completing or opening chests.",
				icon = "flag",
			},
		},
	},
	{
		version = "2026.07.28.06",
		releasedAt = "July 28, 2026",
		notes = {
			{
				title = "Reliable obby chest opening",
				description = "Obby chests now use the game's real loot interaction and confirm keys were actually consumed.",
				icon = "key-round",
			},
		},
	},
	{
		version = "2026.07.28.05",
		releasedAt = "July 28, 2026",
		notes = {
			{
				title = "Classic Island obby automation",
				description = "Added Classic Island obby automation - pick a difficulty and it completes the course and opens the chest.",
				icon = "map-pin",
			},
		},
	},
	{
		version = "2026.07.28.04",
		releasedAt = "July 28, 2026",
		notes = {
			{
				title = "Roblox register-limit fix",
				description = "Fixed the script sometimes failing to load because a recent update pushed it over Roblox's variable limit.",
				icon = "activity",
			},
		},
	},
	{
		version = "2026.07.28.03",
		releasedAt = "July 28, 2026",
		notes = {
			{
				title = "Instant competition bubble selling",
				description = "Competition mode now sells each bubble right away instead of waiting, while still blowing as fast as possible.",
				icon = "activity",
			},
		},
	},
	{
		version = "2026.07.28.02",
		releasedAt = "July 28, 2026",
		notes = {
			{
				title = "Verified competition planner",
				description = "Competition rewards, team equips, and enchant rerolls now retry until the game actually confirms they worked.",
				icon = "sparkles",
			},
			{
				title = "Strict shiny enchant teams",
				description = "Enchant teams now use Bubble Machine pets first, then shiny Celestials and Secrets - never normal pets.",
				icon = "team",
			},
		},
	},
	{
		version = "2026.07.26.11",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Complete rift luck reporting",
				description = "The dashboard now shows the real luck multiplier for every active rift, even the default 1x ones.",
				icon = "sparkles",
			},
		},
	},
	{
		version = "2026.07.26.10",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Perfect egg plate positioning",
				description = "Auto Hatch now stands you directly on the egg's plate, falling back to the old safe spot if needed.",
				icon = "map-pin",
			},
		},
	},
	{
		version = "2026.07.26.09",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Accurate 4x luck egg reporting",
				description = "The dashboard banner now shows the real active 4x Luck egg, with its icon, world, and time left.",
				icon = "sparkles",
			},
		},
	},
	{
		version = "2026.07.26.08",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Safe egg and rift positioning",
				description = "Auto Hatch and rift actions now use each egg or rift's real position instead of a required part.",
				icon = "map-pin",
			},
		},
	},
	{
		version = "2026.07.26.07",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Live rift controls",
				description = "The dashboard now shows real rift icons, 4x egg timers, active events, and confirms its own actions.",
				icon = "sparkles",
			},
		},
	},
	{
		version = "2026.07.26.06",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Interface loading recovery",
				description = "Fixed the Rifts panel sometimes stopping other tabs from finishing loading.",
				icon = "panel-top",
			},
		},
	},
	{
		version = "2026.07.26.05",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Account startup recovery",
				description = "The script now loads settings, skips the intro, and connects to the dashboard faster on startup.",
				icon = "play",
			},
		},
	},
	{
		version = "2026.07.26.04",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Season quest recovery",
				description = "Season Pass automation now recovers instead of stopping when one quest's data looks broken.",
				icon = "bug",
			},
			{
				title = "Accurate rift scanning",
				description = "Rift scans now hide expired entries and show readable egg and chest names instead of raw IDs.",
				icon = "circle-dot",
			},
		},
	},
	{
		version = "2026.07.26.03",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Rift tracking tab",
				description = "Added a Rifts tab showing active rifts with time left, type, and world, plus teleport and hatch buttons.",
				icon = "circle-dot",
			},
		},
	},
	{
		version = "2026.07.26.02",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Quest bug fix",
				description = "Fixed quests breaking after the skip bubbling quests option was added.",
				icon = "bug",
			},
		},
	},
	{
		version = "2026.07.26.01",
		releasedAt = "July 26, 2026",
		notes = {
			{
				title = "Skip Bubbling Quests option",
				description = "Added a toggle to skip bubbling quests, same as the existing ticket and pearl skip options.",
				icon = "circle-dot",
			},
		},
	},
	{
		version = "2026.07.25.01",
		releasedAt = "July 25, 2026",
		notes = {
			{
				title = "Shiny Celestial enchant priority",
				description = "Shiny Celestials are now equipped and enchanted before shiny Secrets.",
				icon = "sparkles",
			},
			{
				title = "Current team enchant repair",
				description = "Enchanting now always scans your equipped team, even while auto team building is still settling.",
				icon = "wand-sparkles",
			},
		},
	},
	{
		version = "2026.07.24.19",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Reliable inventory cleanup",
				description = "Pet deletion now keeps your configured minimum copies, skips teamed pets, and confirms each deletion.",
				icon = "trash-2",
			},
		},
	},
	{
		version = "2026.07.24.18",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Competition team recovery",
				description = "Competition team creation now retries quickly with different names if one gets rejected.",
				icon = "users",
			},
		},
	},
	{
		version = "2026.07.24.17",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Complete special hatch detection",
				description = "Hatch detection now correctly catches Celestial, Infinity, Void, Secret, and Super Legendary pets.",
				icon = "sparkles",
			},
			{
				title = "No dropped duplicate hatches",
				description = "Fixed the webhook hiding real repeated hatches as if they were duplicates.",
				icon = "bell-ring",
			},
		},
	},
	{
		version = "2026.07.24.16",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Accepted-state bubble scheduler",
				description = "Bubble blowing now fits into hatch cooldowns instead of competing with hatch requests for the same frame.",
				icon = "circle-dot",
			},
			{
				title = "Competition bubble safeguards",
				description = "Bubble Lock now clears automatically, and Infinity Gum is only sold if Auto Sell is on.",
				icon = "shield-check",
			},
		},
	},
	{
		version = "2026.07.24.15",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Competition quest progression",
				description = "Competition quests now wait for a confirmed team before tracking bubble progress.",
				icon = "chart-no-axes-column-increasing",
			},
		},
	},
	{
		version = "2026.07.24.14",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Filter-safe competition team names",
				description = "Competition team names no longer use usernames or long numbers that Roblox tends to filter out.",
				icon = "users",
			},
		},
	},
	{
		version = "2026.07.24.13",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Reliable bubbling while hatching",
				description = "Bubble blowing no longer gets starved out by hatch requests firing too aggressively.",
				icon = "circle-dot",
			},
		},
	},
	{
		version = "2026.07.24.12",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Reliable intro skip",
				description = "The intro skip now waits properly for slow-loading clients instead of firing too early.",
				icon = "fast-forward",
			},
		},
	},
	{
		version = "2026.07.24.11",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Interleaved hatch and bubble scheduler",
				description = "Hatch bursts are now smaller and always leave room for a bubble request in between.",
				icon = "bolt",
			},
			{
				title = "Persistent competition bubbling",
				description = "Bubble and sell checks now keep running during quest automation instead of getting paused.",
				icon = "sparkles",
			},
		},
	},
	{
		version = "2026.07.24.10",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Automatic bubble teams",
				description = "Auto-builds a bubble team that prioritizes Bubble Machine Super Legendaries and stays enchant-compatible.",
				icon = "sparkles",
			},
			{
				title = "Competition inventory automation",
				description = "Now deletes low-rarity eggs automatically and buys competition fragments before anything else in the shop.",
				icon = "shopping-bag",
			},
		},
	},
	{
		version = "2026.07.24.09",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Bubble Competition automation",
				description = "Added full Bubble Competition automation - team creation, bubbling while hatching, quest rerolls, and reward claims.",
				icon = "sparkles",
			},
			{
				title = "Live team stats",
				description = "The dashboard now shows competition score, rank, reward progress, and each member's contribution.",
				icon = "chart",
			},
		},
	},
	{
		version = "2026.07.24.08",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Smart shrine supplies",
				description = "Dreamer Shrine now rations shards, restocks when possible, and uses free rerolls when out.",
				icon = "brain",
			},
			{
				title = "Capability-safe quests",
				description = "Fixed hatch quests relying on a restricted virtual keyboard call that could break on some executors.",
				icon = "shield-check",
			},
		},
	},
	{
		version = "2026.07.24.07",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Automatic event potions",
				description = "The script now detects the egg you're hatching and keeps the matching event potion active at your best level.",
				icon = "flask-conical",
			},
		},
	},
	{
		version = "2026.07.24.06",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Loader compile fix",
				description = "Fixed low-FPS hatch bursts pushing the loader over its variable limit.",
				icon = "wrench",
			},
		},
	},
	{
		version = "2026.07.24.05",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Low-FPS hatch bursts",
				description = "Hatch requests now burst together in the same frame, scaled to your configured FPS.",
				icon = "gauge",
			},
		},
	},
	{
		version = "2026.07.24.04",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Game-timed hatching",
				description = "Hatching now fires right on the game's cooldown at full capacity, with popups and intros auto-skipped.",
				icon = "zap",
			},
		},
	},
	{
		version = "2026.07.24.03",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Full hatch capacity",
				description = "Hatch requests now always use your account's actual maximum egg count.",
				icon = "egg",
			},
		},
	},
	{
		version = "2026.07.24.02",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Maximum hatch speed",
				description = "Hatch requests and the R+E key spam now run on every available cycle for max speed.",
				icon = "zap",
			},
		},
	},
	{
		version = "2026.07.24.01",
		releasedAt = "July 24, 2026",
		notes = {
			{
				title = "Higher hatch rate",
				description = "Hatch requests now retry sooner, and key spam presses both R and E.",
				icon = "gauge",
			},
		},
	},
	{
		version = "2026.07.23.12",
		releasedAt = "July 23, 2026",
		notes = {
			{
				title = "Faster hatching",
				description = "Hatch requests now wait for the game's actual response instead of flooding the same cooldown.",
				icon = "gauge",
			},
			{
				title = "Background box opening",
				description = "Mystery boxes now open in small batches in the background without slowing down hatching.",
				icon = "gift",
			},
			{
				title = "Quicker live controls",
				description = "Relay commands and potion use now wait less time between actions.",
				icon = "radio-tower",
			},
		},
	},
	{
		version = "2026.07.23.11",
		releasedAt = "July 23, 2026",
		notes = {
			{
				title = "Config stays in sync",
				description = "New script settings now show up on the dashboard site automatically.",
				icon = "refresh-cw",
			},
		},
	},
	{
		version = "2026.07.23.10",
		releasedAt = "July 23, 2026",
		notes = {
			{
				title = "Safe Mode",
				description = "Added Safe Mode, which pauses all automation and restores normal rendering without losing your saved setup.",
				icon = "shield-check",
			},
		},
	},
	{
		version = "2026.07.23.09",
		releasedAt = "July 23, 2026",
		notes = {
			{
				title = "Relay connects without reloading",
				description = "Opening connect.bat now picks up already-running accounts and shows a live connection count.",
				icon = "radio-tower",
			},
		},
	},
	{
		version = "2026.07.23.08",
		releasedAt = "July 23, 2026",
		notes = {
			{
				title = "Less idle time",
				description = "Hatching now continues between enchant checks, and stalled quests get skipped sooner.",
				icon = "gauge",
			},
		},
	},
	{
		version = "2026.07.23.04",
		releasedAt = "July 23, 2026",
		notes = {
			{
				title = "Super Legendary priorities",
				description = "You can now choose which Super Legendary enchants count when the script builds your team.",
				icon = "sparkles",
			},
		},
	},
	{
		version = "2026.07.23.03",
		releasedAt = "July 23, 2026",
		notes = {
			{
				title = "Optional connection relay",
				description = "Added connect.bat as an optional relay for faster dashboard controls and grouped account polling.",
				icon = "radio-tower",
			},
			{
				title = "Faster action updates",
				description = "Potion use and other live actions now show up through the relay without the usual delay.",
				icon = "zap",
			},
		},
	},
	{
		version = "2026.07.23.02",
		releasedAt = "July 23, 2026",
		notes = {
			{
				title = "Automation timing",
				description = "Hatching, potion refreshes, recovery, and inventory cleanup now follow the account's actual game state.",
				icon = "activity",
			},
			{
				title = "More reward claims",
				description = "Added automatic claiming for daily rewards, wheel spins, index rewards, chests, and mastery.",
				icon = "gift",
			},
			{
				title = "Live dashboard settings",
				description = "Account roles and automation settings can now be changed without rejoining the game.",
				icon = "settings",
			},
		},
	},
	{
		version = "2026.07.23.01",
		releasedAt = "July 23, 2026",
		notes = {
			{
				title = "Reward checks cleaned up",
				description = "Mastery, chest, and index claims now only fire when a reward is actually available.",
				icon = "gauge",
			},
			{
				title = "Hatch recovery",
				description = "Repositioning now only kicks in after hatching has actually stopped.",
				icon = "refresh-cw",
			},
		},
	},
	{
		version = "2026.07.22.13",
		releasedAt = "July 22, 2026",
		notes = {
			{
				title = "Enchant team priorities",
				description = "Enchanting now follows your saved Super Legendary order and leaves a matching team alone.",
				icon = "sparkles",
			},
			{
				title = "Fewer enchant requests",
				description = "Pet lookups, equips, and rerolls now respect the game's cooldown instead of spamming requests.",
				icon = "activity",
			},
		},
	},
	{
		version = "2026.07.22.12",
		releasedAt = "July 22, 2026",
		notes = {
			{
				title = "Safer inventory cleanup",
				description = "Cleanup now only deletes low-rarity duplicates and never touches locked, equipped, or top-rarity pets.",
				icon = "shield-check",
			},
			{
				title = "Clearer account activity",
				description = "The dashboard now prioritizes active hatching and reports cleanup status more accurately.",
				icon = "activity",
			},
		},
	},
	{
		version = "2026.07.22.11",
		releasedAt = "July 22, 2026 at 8:42 PM CT",
		notes = {
			{
				title = "Pet totals fixed",
				description = "Fixed Secret, Infinity, Void, and Celestial pet totals sometimes counting wrong.",
				icon = "sparkles",
			},
		},
	},
	{
		version = "2026.07.22.10",
		releasedAt = "July 22, 2026 at 3:03 PM CT",
		notes = {
			{
				title = "Update history",
				description = "The Main tab now lists every past version along with its release time.",
				icon = "history",
			},
			{
				title = "Release details",
				description = "You can now click any past version to read its full release notes.",
				icon = "file-clock",
			},
		},
	},
	{
		version = "2026.07.22.09",
		releasedAt = "July 22, 2026",
		notes = {
			{
				title = "Release notes on Main",
				description = "You can now see the latest changes right from the Main tab.",
				icon = "list",
			},
		},
	},
	{
		version = "2026.07.22.08",
		releasedAt = "July 22, 2026",
		notes = {
			{
				title = "Update popup",
				description = "A popup now shows the release notes once whenever a new version loads.",
				icon = "message-square-more",
			},
			{
				title = "Rayfield Gen2",
				description = "Rebuilt the whole menu on Rayfield Gen2, with native tabs, controls, stats, and popups.",
				icon = "layout-dashboard",
			},
			{
				title = "Live stats",
				description = "Added live tracking for hatch rate, luck, speed, FPS, uptime, and server player count.",
				icon = "chart-no-axes-combined",
			},
			{
				title = "Hatch animation setting",
				description = "Your hatch animation setting now applies on join and sticks around after reloads.",
				icon = "egg",
			},
			{
				title = "Dynamic dropdowns",
				description = "Egg, shop, fragment, box, enchant, and team dropdowns now refresh from live game data.",
				icon = "list-filter",
			},
			{
				title = "Performance controls",
				description = "Added minimum graphics, an FPS cap, and cleaner render-distance handling for better performance.",
				icon = "gauge",
			},
		},
	},
}
end
end
}
