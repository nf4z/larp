const {
  Client,
  GatewayIntentBits,
  Partials,
  ChannelType,
} = require('discord.js');
const fs = require('fs');
const path = require('path');

// =====================
// CONFIG
// =====================
const DISCORD_TOKEN = process.env.DISCORD_TOKEN || ''; // Set in .env; never hardcode a bot token
const PREFIX = process.env.PREFIX || '.';

const SHOP_URL = process.env.SHOP_URL || 'https://api.bloxypot.com/coins/market/list?limit=200&skip=0';
const MARKETPLACE_URL = process.env.MARKETPLACE_URL || 'https://api.bloxycross.com/marketplace/listings';
const GIVEAWAYS_URL = process.env.GIVEAWAYS_URL || 'https://api.bloxypot.com/giveaways/latest';
const RAIN_STATUS_URL = process.env.RAIN_STATUS_URL || 'https://api.bloxypot.com/rain/status';
const BGSI_BASE_URL = process.env.BGSI_BASE_URL || 'https://api.demand.gg/api/g/bgsi/items';
const DEMAND_ALERT_CHANNEL_ID = process.env.DEMAND_ALERT_CHANNEL_ID || '1562303585029718028';
const DEMAND_ALERT_ROLE_ID = process.env.DEMAND_ALERT_ROLE_ID || '1518764076694638678';
const BGSI_VARIANTS = (process.env.BGSI_VARIANTS || 'normal,shiny,mythic,shiny-mythic,xl,xl-shiny,xl-mythic,xl-shiny-mythic').split(',').map(v => v.trim()).filter(Boolean);

const GIVEAWAY_CHANNEL_ID = process.env.GIVEAWAY_CHANNEL_ID || '1497716223767482498';
const RAIN_CHANNEL_ID = process.env.RAIN_CHANNEL_ID || '1497718825775403180';

const POLL_INTERVAL_MS = Number(process.env.POLL_INTERVAL_MS || 1500);
const MARKETPLACE_POLL_INTERVAL_MS = Number(process.env.MARKETPLACE_POLL_INTERVAL_MS || POLL_INTERVAL_MS);
const GIVEAWAY_POLL_INTERVAL_MS = Number(process.env.GIVEAWAY_POLL_INTERVAL_MS || 1000);
const RAIN_POLL_INTERVAL_MS = Number(process.env.RAIN_POLL_INTERVAL_MS || 5000);
const BGSI_REFRESH_MS = Number(process.env.BGSI_REFRESH_MS || 5 * 60 * 1000);
const BGSI_PAGE_SIZE = Number(process.env.BGSI_PAGE_SIZE || 60);
const BGSI_PAGE_DELAY_MS = Number(process.env.BGSI_PAGE_DELAY_MS || 250);
const BGSI_CACHE_MAX_AGE_MS = Number(process.env.BGSI_CACHE_MAX_AGE_MS || 12 * 60 * 60 * 1000);

const HTTP_TIMEOUT_MS = Number(process.env.HTTP_TIMEOUT_MS || 15000);
const SEND_DELAY_MS = Number(process.env.SEND_DELAY_MS || 900);
const EVENT_CACHE_TTL_MS = Number(process.env.EVENT_CACHE_TTL_MS || 10 * 60 * 1000);
const MAX_QUEUE_RETRIES = Number(process.env.MAX_QUEUE_RETRIES || 4);

const DATA_DIR = path.join(process.cwd(), 'data');
const CONFIG_PATH = path.join(DATA_DIR, 'guild-config.json');
const BGSI_CACHE_PATH = path.join(DATA_DIR, 'bgsi-cache.json');
const GIVEAWAY_MESSAGES_PATH = path.join(DATA_DIR, 'giveaway-messages.json');
const RAIN_MESSAGE_PATH = path.join(DATA_DIR, 'rain-message.json');

if (!DISCORD_TOKEN || !DISCORD_TOKEN.trim()) {
  console.error('[STARTUP] Missing DISCORD_TOKEN env var');
  process.exit(1);
}

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
    GatewayIntentBits.DirectMessages,
  ],
  partials: [Partials.Channel],
  allowedMentions: { parse: [] },
});

const watchers = new Map();
const seenStockIdsPerWatcher = new Set();
const sentWatchAlertSignatures = new Set();
const sentEventCache = new Map();
const outboundQueue = [];
const channelCache = new Map();
const runningJobs = new Set();

let queueWorkerStarted = false;
let guildConfigs = new Map();
let bgsiCacheReady = false;
let bgsiCacheUpdatedAt = 0;
let bgsiRefreshPromise = null;
let bgsiEntriesByFullName = new Map();
let bgsiBasePetsByName = new Map();

let previousStockMap = new Map();
let hasInitializedStockSnapshot = false;
let previousMarketplaceMap = new Map();
let hasInitializedMarketplaceSnapshot = false;
let previousGiveawayMap = new Map();
let hasInitializedGiveawaySnapshot = false;

let giveawayMessageIds = new Map();
let giveawayMessageSignatures = new Map();
let rainStatusMessageId = null;
let lastRainRoundId = null;

process.on('unhandledRejection', (reason) => console.error('[unhandledRejection]', reason));
process.on('uncaughtException', (err) => console.error('[uncaughtException]', err));

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function ensureDataDir() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

function readJson(file, fallback) {
  ensureDataDir();
  try {
    if (!fs.existsSync(file)) return fallback;
    return JSON.parse(fs.readFileSync(file, 'utf8') || 'null') ?? fallback;
  } catch (err) {
    console.error(`[JSON] Failed reading ${file}:`, err.message);
    return fallback;
  }
}

function writeJson(file, data) {
  ensureDataDir();
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

function normalizeText(str) {
  return String(str || '')
    .trim()
    .toLowerCase()
    .replace(/[_-]+/g, ' ')
    .replace(/\s+/g, ' ');
}

function formatNumber(num) {
  const n = Number(num);
  if (!Number.isFinite(n) || n < 0) return 'N/A';
  return n.toLocaleString('en-US');
}

function absoluteImageUrl(url) {
  if (!url) return null;
  if (/^https?:\/\//i.test(url)) return url;
  if (url.startsWith('/')) return `https://bgsi.gg${url}`;
  return `https://bgsi.gg/${url}`;
}

async function fetchJson(url, label, extraHeaders = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), HTTP_TIMEOUT_MS);

  try {
    const res = await fetch(url, {
      method: 'GET',
      signal: controller.signal,
      headers: {
        Accept: 'application/json, text/plain, */*',
        'Accept-Language': 'en-US,en;q=0.9',
        // A generic browser UA is far less likely to get flagged by bot-detection
        // (e.g. Cloudflare) than an obviously-a-bot string like "BloxyPot-Watcher/2.0".
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        ...extraHeaders,
      },
    });

    if (!res.ok) {
      // Diagnostic dump so we can tell a Cloudflare/JS-challenge block apart from a
      // plain "missing API key" style JSON error, rather than guessing blindly.
      let bodySnippet = '';
      try {
        bodySnippet = (await res.text()).slice(0, 500);
      } catch {}
      console.error(
        `[FETCH 403/ERR] ${label} -> ${res.status} ${res.statusText}\n` +
        `  server: ${res.headers.get('server') || 'n/a'}\n` +
        `  cf-ray: ${res.headers.get('cf-ray') || 'n/a'}\n` +
        `  cf-mitigated: ${res.headers.get('cf-mitigated') || 'n/a'}\n` +
        `  content-type: ${res.headers.get('content-type') || 'n/a'}\n` +
        `  body: ${bodySnippet}`
      );
      throw new Error(`${label} HTTP ${res.status} ${res.statusText}`);
    }
    return await res.json();
  } finally {
    clearTimeout(timeout);
  }
}

async function runExclusive(name, fn) {
  if (runningJobs.has(name)) {
    console.log(`[SKIP] ${name} still running`);
    return null;
  }

  runningJobs.add(name);
  try {
    return await fn();
  } catch (err) {
    console.error(`[JOB ERROR] ${name}:`, err.message);
    return null;
  } finally {
    runningJobs.delete(name);
  }
}

function createIntervalJob(name, delay, fn, startDelay = 0) {
  setTimeout(() => {
    runExclusive(name, fn);
    setInterval(() => runExclusive(name, fn), delay);
  }, startDelay);
}

function loadGuildConfigs() {
  guildConfigs = new Map(Object.entries(readJson(CONFIG_PATH, {})));
}

// Ensure clean saving on multiple platforms
function saveGuildConfigs() {
  writeJson(CONFIG_PATH, Object.fromEntries(guildConfigs.entries()));
}

function getGuildConfig(guildId) {
  if (!guildConfigs.has(guildId)) {
    guildConfigs.set(guildId, {
      bloxypotChannelId: null,
      bloxycrossChannelId: null,
      highDemandChannelId: null,
      highDemandRoleId: null,
    });
  }
  return guildConfigs.get(guildId);
}

function updateGuildConfig(guildId, patch) {
  const next = { ...getGuildConfig(guildId), ...patch };
  guildConfigs.set(guildId, next);
  saveGuildConfigs();
  return next;
}

function loadGiveawayMessageIds() {
  const parsed = readJson(GIVEAWAY_MESSAGES_PATH, {});
  giveawayMessageIds = new Map();
  giveawayMessageSignatures = new Map();

  for (const [giveawayId, value] of Object.entries(parsed)) {
    if (typeof value === 'string') {
      giveawayMessageIds.set(giveawayId, value);
    } else if (value && typeof value === 'object') {
      if (value.messageId) giveawayMessageIds.set(giveawayId, String(value.messageId));
      if (value.signature) giveawayMessageSignatures.set(giveawayId, String(value.signature));
    }
  }

  console.log(`[GIVEAWAY] Loaded ${giveawayMessageIds.size} saved message IDs`);
}

function saveGiveawayMessageIds() {
  const plain = {};
  for (const [giveawayId, messageId] of giveawayMessageIds.entries()) {
    plain[giveawayId] = {
      messageId,
      signature: giveawayMessageSignatures.get(giveawayId) || null,
    };
  }
  writeJson(GIVEAWAY_MESSAGES_PATH, plain);
}

function loadRainMessageId() {
  const parsed = readJson(RAIN_MESSAGE_PATH, {});
  rainStatusMessageId = parsed.messageId ? String(parsed.messageId) : null;
  if (rainStatusMessageId) console.log(`[RAIN] Loaded saved status message ID ${rainStatusMessageId}`);
}

function saveRainMessageId() {
  writeJson(RAIN_MESSAGE_PATH, { messageId: rainStatusMessageId || null });
}

function normalizeVariantLabel(prefixes) {
  const hasShiny = prefixes.includes('Shiny');
  const hasMythic = prefixes.includes('Mythic');
  const hasXL = prefixes.includes('XL');
  if (hasShiny && hasMythic && hasXL) return 'ShinyMythicXL';
  if (hasShiny && hasMythic) return 'ShinyMythic';
  if (hasMythic && hasXL) return 'MythicXL';
  if (hasShiny && hasXL) return 'ShinyXL';
  if (hasMythic) return 'Mythic';
  if (hasShiny) return 'Shiny';
  if (hasXL) return 'XL';
  return 'Normal';
}

function variantLabelToDisplay(label) {
  const map = {
    Normal: '',
    Shiny: 'Shiny',
    Mythic: 'Mythic',
    ShinyMythic: 'Shiny Mythic',
    XL: 'XL',
    ShinyXL: 'Shiny XL',
    MythicXL: 'Mythic XL',
    ShinyMythicXL: 'Shiny Mythic XL',
  };
  return map[label] || label;
}

function buildFullPetName(baseName, variantLabel) {
  const prefix = variantLabelToDisplay(variantLabel);
  return prefix ? `${prefix} ${baseName}`.trim() : baseName;
}

function parseInput(input) {
  if (!input || !input.trim()) return null;
  const aliasMap = { M: ['Mythic'], S: ['Shiny'], SM: ['Shiny', 'Mythic'], XL: ['XL'] };
  const parts = input.trim().split(/\s+/);
  const prefixes = [];
  let i = 0;

  while (i < parts.length) {
    const key = parts[i].toUpperCase();
    if (!aliasMap[key]) {
      const lowerToken = parts[i].toLowerCase();
      if (lowerToken === 'shiny') {
        prefixes.push('Shiny');
        i++;
        continue;
      } else if (lowerToken === 'mythic') {
        prefixes.push('Mythic');
        i++;
        continue;
      } else if (lowerToken === 'xl') {
        prefixes.push('XL');
        i++;
        continue;
      }
      break;
    }
    prefixes.push(...aliasMap[key]);
    i++;
  }

  const name = parts.slice(i).join(' ').trim();
  if (!name) return null;

  const variantLabel = normalizeVariantLabel(prefixes);
  const full = buildFullPetName(name, variantLabel);
  return {
    raw: input,
    full,
    normalized: normalizeText(full),
    prefixes,
    baseName: name,
    baseNameNormalized: normalizeText(name),
    variantLabel,
  };
}

function parseStockItemName(itemName) {
  const parts = String(itemName || '').trim().split(/\s+/);
  const prefixes = [];
  let i = 0;

  while (i < parts.length) {
    const token = parts[i].toLowerCase();
    if (token === 'shiny') prefixes.push('Shiny');
    else if (token === 'mythic') prefixes.push('Mythic');
    else if (token === 'xl') prefixes.push('XL');
    else break;
    i++;
  }

  const baseName = parts.slice(i).join(' ').trim();
  const variantLabel = normalizeVariantLabel(prefixes);
  const fullName = buildFullPetName(baseName, variantLabel);
  return {
    originalName: String(itemName || '').trim(),
    fullName,
    fullNameNormalized: normalizeText(fullName),
    baseName,
    baseNameNormalized: normalizeText(baseName),
    prefixes,
    variantLabel,
  };
}

function extractBgsiPets(payload) {
  if (payload && Array.isArray(payload.pets)) return payload.pets;
  if (Array.isArray(payload)) return payload;
  if (payload && Array.isArray(payload.items)) return payload.items;
  if (payload && Array.isArray(payload.data)) return payload.data;
  return [];
}

// Demand.gg: value and demand are nested in pet.value; variant is in attributes.variant.
const DEMAND_LABELS = Object.freeze({ 1: 'Low', 2: 'Medium', 3: 'High', 4: 'Very High', 5: 'Insane' });

function getBgsiVariantLabel(pet) {
  const flags = pet?.attributes?.variant || {};
  const parts = [];
  if (flags.shiny) parts.push('Shiny');
  if (flags.mythic) parts.push('Mythic');
  if (flags.xl) parts.push('XL');
  return normalizeVariantLabel(parts);
}

function storeBgsiPets(pets, entriesByFullName, basePetsByName) {
  for (const pet of pets) {
    if (!pet || !pet.name || pet.categoryId !== 'pets') continue;
    const variant = getBgsiVariantLabel(pet);
    // Demand API item.name is normally the complete variant display name.
    const parsed = parseStockItemName(pet.name);
    const baseName = parsed.baseName || pet.name;
    const fullName = buildFullPetName(baseName, variant);
    const fullKey = normalizeText(fullName);
    const baseKey = normalizeText(baseName);
    const demandValue = Number(pet.value?.demand);
    const validDemand = Number.isInteger(demandValue) && demandValue >= 1 && demandValue <= 5;
    const numericValue = pet.value?.value == null ? null : Number(pet.value.value);

    const entry = {
      id: pet.slug,
      slug: pet.slug,
      name: fullName,
      normalizedName: fullKey,
      baseName,
      normalizedBaseName: baseKey,
      variant,
      variants: [],
      demand: validDemand ? DEMAND_LABELS[demandValue] : 'Unknown',
      demandValue: validDemand ? demandValue : null,
      value: Number.isFinite(numericValue) && numericValue >= 0 ? numericValue : null,
      image: absoluteImageUrl(pet.image),
      rarity: pet.attributes?.rarity ?? null,
      chance: pet.attributes?.chance ?? null,
      existCount: pet.attributes?.existCount ?? null,
      trend: pet.value?.trend ?? null,
      raw: pet, // Preserve all attributes, nested value metadata, and demand.
    };
    entriesByFullName.set(fullKey, entry);

    const currentBase = basePetsByName.get(baseKey);
    if (!currentBase || variant === 'Normal') {
      basePetsByName.set(baseKey, { ...entry, name: baseName, normalizedName: baseKey, variant: 'Normal' });
    }
  }
}

function finalizeBgsiVariants(entriesByFullName, basePetsByName) {
  const variantSets = new Map();
  for (const entry of entriesByFullName.values()) {
    if (!variantSets.has(entry.normalizedBaseName)) variantSets.set(entry.normalizedBaseName, new Set());
    variantSets.get(entry.normalizedBaseName).add(entry.variant);
  }
  for (const [key, entry] of basePetsByName) {
    entry.variants = [...(variantSets.get(key) || [])];
  }
  for (const entry of entriesByFullName.values()) {
    entry.variants = [...(variantSets.get(entry.normalizedBaseName) || [])];
  }
}

async function fetchBgsiPage(page, variant = 'normal') {
  const url = new URL(BGSI_BASE_URL);
  url.searchParams.set('category', 'pets');
  url.searchParams.set('sort', 'value-desc');
  url.searchParams.set('page', String(page));
  url.searchParams.set('limit', String(BGSI_PAGE_SIZE));
  url.searchParams.set('variant', variant);
  // Do not add rarity filtering: the cache must include every pet.
  return fetchJson(url.toString(), `Demand.gg ${variant} page ${page}`);
}

function extractBgsiTotalPages(payload) {
  const pages = Number(payload?.pagination?.pages);
  const total = Number(payload?.pagination?.total);
  if (Number.isInteger(pages) && pages >= 1 && Number.isInteger(total) && total >= 0) {
    if (pages !== Math.max(1, Math.ceil(total / BGSI_PAGE_SIZE))) {
      throw new Error(`Conflicting Demand.gg pagination: ${pages} pages for ${total} items`);
    }
    return { pages, total };
  }
  throw new Error('Missing Demand.gg pagination.pages / pagination.total; refusing incomplete cache');
}

function saveBgsiCacheToDisk() {
  const snapshot = {
    version: 2,
    savedAt: bgsiCacheUpdatedAt,
    variants: BGSI_VARIANTS,
    entriesByFullName: [...bgsiEntriesByFullName.entries()],
    basePetsByName: [...bgsiBasePetsByName.entries()],
  };
  ensureDataDir();
  const temp = `${BGSI_CACHE_PATH}.tmp`;
  fs.writeFileSync(temp, JSON.stringify(snapshot));
  fs.renameSync(temp, BGSI_CACHE_PATH);
  console.log(`[BGSI] Saved ${bgsiEntriesByFullName.size} complete entries`);
}

function loadBgsiCacheFromDisk({ allowStale = false } = {}) {
  const parsed = readJson(BGSI_CACHE_PATH, null);
  if (!parsed || parsed.version !== 2) return false;
  const savedAt = Number(parsed.savedAt || 0);
  const ageMs = Date.now() - savedAt;
  if (!allowStale && (!savedAt || ageMs > BGSI_CACHE_MAX_AGE_MS)) return false;
  if (!Array.isArray(parsed.entriesByFullName) || !Array.isArray(parsed.basePetsByName)) return false;
  if (JSON.stringify(parsed.variants) !== JSON.stringify(BGSI_VARIANTS)) return false;
  bgsiEntriesByFullName = new Map(parsed.entriesByFullName);
  bgsiBasePetsByName = new Map(parsed.basePetsByName);
  bgsiCacheUpdatedAt = savedAt;
  bgsiCacheReady = true;
  console.log(`[BGSI] Loaded ${bgsiEntriesByFullName.size} pets from disk (${Math.round(ageMs / 60000)}m old)`);
  return true;
}

async function refreshBgsiCache() {
  if (bgsiRefreshPromise) return bgsiRefreshPromise;
  bgsiRefreshPromise = (async () => {
    console.log('[BGSI] Fetching every Demand.gg pet page and variant...');
    const nextEntries = new Map();
    const nextBase = new Map();
    const maxPages = 1000;
    for (const variant of BGSI_VARIANTS) {
      const first = await fetchBgsiPage(1, variant);
      if (!Array.isArray(first?.items)) throw new Error(`Invalid ${variant} page 1: no items array`);
      const { pages, total } = extractBgsiTotalPages(first);
      if (pages > maxPages) throw new Error(`Suspicious page count ${pages} for ${variant}`);
      let received = 0;
      for (let page = 1; page <= pages; page++) {
        const payload = page === 1 ? first : await fetchBgsiPage(page, variant);
        if (!Array.isArray(payload?.items)) throw new Error(`Missing items on ${variant} page ${page}`);
        const pg = extractBgsiTotalPages(payload);
        if (pg.pages !== pages || pg.total !== total || Number(payload.pagination.current) !== page) {
          throw new Error(`Pagination changed during refresh for ${variant} page ${page}; retaining previous cache`);
        }
        if (page < pages && payload.items.length !== BGSI_PAGE_SIZE) {
          throw new Error(`Incomplete ${variant} page ${page}: got ${payload.items.length}`);
        }
        received += payload.items.length;
        storeBgsiPets(payload.items, nextEntries, nextBase);
        console.log(`[BGSI] ${variant}: page ${page}/${pages}, ${payload.items.length} pets`);
        if (page < pages) await sleep(BGSI_PAGE_DELAY_MS);
      }
      if (received !== total) throw new Error(`Incomplete ${variant}: ${received}/${total} received`);
    }
    if (!nextEntries.size) throw new Error('Demand.gg returned zero pets; keeping old cache');
    finalizeBgsiVariants(nextEntries, nextBase);
    bgsiEntriesByFullName = nextEntries;
    bgsiBasePetsByName = nextBase;
    bgsiCacheUpdatedAt = Date.now();
    bgsiCacheReady = true;
    saveBgsiCacheToDisk();
    console.log(`[BGSI] Full refresh complete: ${nextEntries.size} pet variants, ${nextBase.size} base pets`);
  })();
  try { return await bgsiRefreshPromise; }
  finally { bgsiRefreshPromise = null; }
}

async function ensureBgsiCacheReady() {
  if (bgsiCacheReady) return;
  if (loadBgsiCacheFromDisk()) return;
  await refreshBgsiCache();
}

function getCachedBgsiByFullName(fullName) {
  return bgsiEntriesByFullName.get(normalizeText(fullName)) || null;
}

function getCachedBgsiBasePet(baseName) {
  return bgsiBasePetsByName.get(normalizeText(baseName)) || null;
}

function extractShopItems(payload) {
  if (Array.isArray(payload)) return payload;
  if (payload && Array.isArray(payload.items)) return payload.items;
  if (payload && Array.isArray(payload.data)) return payload.data;
  if (payload && Array.isArray(payload.results)) return payload.results;
  return [];
}

function extractMarketplaceItems(payload) {
  if (Array.isArray(payload)) return payload;
  if (payload && Array.isArray(payload.items)) return payload.items;
  if (payload && Array.isArray(payload.data)) return payload.data;
  if (payload && Array.isArray(payload.results)) return payload.results;
  if (payload && Array.isArray(payload.listings)) return payload.listings;
  return [];
}

function extractGiveaways(payload) {
  if (Array.isArray(payload)) return payload;
  if (payload && Array.isArray(payload.giveaways)) return payload.giveaways;
  if (payload && Array.isArray(payload.items)) return payload.items;
  if (payload && Array.isArray(payload.data)) return payload.data;
  if (payload && Array.isArray(payload.results)) return payload.results;
  if (payload && typeof payload === 'object' && Object.keys(payload).length) return [payload];
  return [];
}

async function fetchShop() {
  const payload = await fetchJson(SHOP_URL, 'BloxyPot shop');
  const items = extractShopItems(payload);
  console.log(`[FETCH] Got ${items.length} stock items`);
  return items;
}

async function fetchMarketplace() {
  const payload = await fetchJson(MARKETPLACE_URL, 'BloxyCross marketplace', {
    Referer: 'https://bloxycross.com/',
    Origin: 'https://bloxycross.com',
  });
  const items = extractMarketplaceItems(payload);
  console.log(`[MARKETPLACE FETCH] Got ${items.length} listings`);
  return items;
}

async function fetchGiveaways() {
  const payload = await fetchJson(GIVEAWAYS_URL, 'Giveaways');
  const giveaways = extractGiveaways(payload).filter(Boolean);
  console.log(`[GIVEAWAY FETCH] Got ${giveaways.length} giveaway records`);
  return giveaways;
}

function getCacheDemand(meta) {
  if (!meta || !meta.demand || meta.demand === 'Unknown') return null;
  return meta.demand;
}

function getDemandFromStockSample(sampleData) {
  return getCacheDemand(sampleData?.bgsiFull) || getCacheDemand(sampleData?.bgsi) || getCacheDemand(sampleData?.bgsiBase) || sampleData?.demand || 'Unknown';
}

function getDemandFromMarketplaceItem(item) {
  return getCacheDemand(item?.bgsiFull) || getCacheDemand(item?.bgsi) || getCacheDemand(item?.bgsiBase) || item?.demand || 'Unknown';
}

function demandRank(demand) {
  const key = normalizeText(demand);
  return { low: 1, medium: 2, high: 3, 'very high': 4, veryhigh: 4, insane: 5, extreme: 6, godly: 7 }[key] || 0;
}

function shouldPingForDemand(demand) {
  return demandRank(demand) >= demandRank('high');
}

function attachCachedBgsiMeta(shopItems) {
  return shopItems.map((item) => {
    const parsed = parseStockItemName(item?.itemname);
    const fullMeta = getCachedBgsiByFullName(parsed.fullName);
    const baseMeta = parsed.variantLabel === 'Normal' ? getCachedBgsiBasePet(parsed.baseName) : null;
    return {
      ...item,
      parsedName: parsed,
      bgsi: fullMeta || baseMeta || null,
      bgsiFull: fullMeta || null,
      bgsiBase: baseMeta || null,
      apiValue: item?.itemvalue ?? null,
    };
  });
}

function attachCachedMarketplaceMeta(items) {
  return items.map((item) => {
    const parsed = parseStockItemName(item?.itemname);
    const fullMeta = getCachedBgsiByFullName(parsed.fullName);
    const baseMeta = parsed.variantLabel === 'Normal' ? getCachedBgsiBasePet(parsed.baseName) : null;
    return { ...item, parsedName: parsed, bgsi: fullMeta || baseMeta || null, bgsiFull: fullMeta || null, bgsiBase: baseMeta || null };
  });
}

function itemIdOf(item) {
  return String(item?._id ?? item?.stockid ?? item?.id ?? `${item?.itemname || 'unknown'}:${item?.createdAt || Date.now()}`);
}

function marketplaceIdOf(item) {
  return String(item?._id ?? item?.listingid ?? item?.id ?? `${item?.itemid || 'unknown'}:${item?.createdAt || Date.now()}`);
}

function getLatestEntry(entries) {
  if (!Array.isArray(entries) || !entries.length) return null;
  return entries.reduce((latest, entry) => {
    const ts = new Date(entry?.createdAt || 0).getTime();
    const latestTs = new Date(latest?.createdAt || 0).getTime();
    return ts > latestTs ? entry : latest;
  }, entries[0]);
}

function footerLineFromEntries(entries) {
  const latest = getLatestEntry(entries);
  if (!latest) return null;
  if (latest?.sellerid) return `Seller ID - ${String(latest.sellerid)}`;
  if (latest?.listingId || latest?.listingid) return `Listing ID - ${String(latest.listingId || latest.listingid)}`;
  if (latest?.id) return `ID - ${String(latest.id)}`;
  return null;
}

function formatCompactNumber(num) {
  const n = Number(num);
  if (!Number.isFinite(n) || n < 0) return 'N/A';
  if (n < 1000) return formatNumber(n);

  const units = [
    { value: 1e12, suffix: 'T' },
    { value: 1e9, suffix: 'B' },
    { value: 1e6, suffix: 'M' },
    { value: 1e3, suffix: 'K' },
  ];

  for (const unit of units) {
    if (n >= unit.value) {
      const short = n / unit.value;
      const digits = short >= 100 ? 0 : short >= 10 ? 1 : 2;
      return `${short.toFixed(digits).replace(/\.0+$|(?<=\..*?)0+$/g, '')}${unit.suffix}`;
    }
  }

  return formatNumber(n);
}

function createContainerPayload({ title, accentColor, bodyLines, footerText, image, buttons = [] }) {
  const safeBodyLines = Array.isArray(bodyLines) ? bodyLines.filter((line) => line != null && String(line).trim() !== '') : [];
  const textComponents = [{ type: 10, content: `# ${title}` }];

  if (safeBodyLines.length) {
    textComponents.push({ type: 10, content: safeBodyLines.join('\n') });
  }

  const components = [];

  if (image) {
    components.push({
      type: 9,
      components: textComponents,
      accessory: { type: 11, media: { url: image } },
    });
  } else {
    components.push(...textComponents);
  }

  if (Array.isArray(buttons) && buttons.length) {
    components.push({ type: 1, components: buttons });
  }

  if (footerText) {
    components.push({ type: 14, divider: true, spacing: 1 });
    components.push({ type: 10, content: footerText });
  }

  return {
    flags: 32768,
    components: [{ type: 17, accent_color: accentColor, components }],
  };
}

function buildStockInfoButtons() {
  return [];
}

function buildMatchSummaryMessage(group) {
  return createContainerPayload({
    title: group.petName,
    accentColor: 703487,
    image: group.sampleData?.image || group.sampleData?.itemimage || null,
    bodyLines: [
      `Watching: **${group.watchName}**`,
      `Quantity: **${group.beforeCount} -> ${group.afterCount}**`,
      `Value: **${formatNumber(group.sampleData?.value)}**`,
      `Demand: **${group.sampleData?.demand || 'Unknown'}**`,
      group.sampleData?.trend ? `Trend: **${group.sampleData.trend}**` : null,
    ],
    buttons: buildStockInfoButtons(group.sampleData),
    footerText: group.footerText,
  });
}

function buildStockChangeMessage(action, petName, beforeCount, afterCount, sampleData, footerText) {
  const demand = getDemandFromStockSample(sampleData);
  return createContainerPayload({
    title: petName,
    accentColor: action === 'added' ? 0x57f287 : 0xed4245,
    image: sampleData?.image || sampleData?.itemimage || sampleData?.bgsiFull?.image || sampleData?.bgsi?.image || null,
    bodyLines: [
      `Quantity: **${beforeCount} -> ${afterCount}**`,
      `Value: **${formatNumber(sampleData?.value ?? sampleData?.apiValue ?? sampleData?.itemvalue ?? sampleData?.bgsiFull?.value ?? sampleData?.bgsi?.value)}**`,
      `Demand: **${demand}**`,
      sampleData?.trend ? `Trend: **${sampleData.trend}**` : null,
    ],
    buttons: buildStockInfoButtons(sampleData),
    footerText,
  });
}

function buildMarketplaceChangeMessage(action, item, beforeCount, afterCount) {
  const createdTs = Math.floor(new Date(item?.createdAt || Date.now()).getTime() / 1000);
  const demand = getDemandFromMarketplaceItem(item);
  return createContainerPayload({
    title: item?.itemname || 'Unknown Item',
    accentColor: action === 'added' ? 0x57f287 : 0xed4245,
    image: item?.itemimage || item?.bgsiFull?.image || item?.bgsi?.image || null,
    bodyLines: [
      `Quantity: **${beforeCount} -> ${afterCount}**`,
      `Value: **${formatNumber(item?.itemvalue ?? item?.price ?? item?.bgsiFull?.value ?? item?.bgsi?.value)}**`,
      `Demand: **${demand}**`,
      `Listed: <t:${createdTs}:R>`,
    ],
    footerText: `Listing ID - ${item?._id || 'Unknown'} | Item ID - ${item?.itemid || 'Unknown'}`,
  });
}

function pickGiveawayAmount(giveaway) {
  const item = giveaway?.item?.[0];
  return item?.itemvalue ?? item?.value ?? item?.amount ?? null;
}

function pickGiveawayEntries(giveaway) {
  return giveaway?.entries ?? 0;
}

function pickGiveawayHost(giveaway) {
  return giveaway?.starterusername ?? giveaway?.host ?? giveaway?.creator ?? null;
}

function pickGiveawayEnd(giveaway) {
  return giveaway?.enddate ?? giveaway?.endsAt ?? giveaway?.endAt ?? null;
}

function giveawayIdOf(giveaway) {
  const item = giveaway?.item?.[0];
  return String(
    giveaway?._id ?? giveaway?.id ?? giveaway?.giveawayId ?? giveaway?.giveawayid ?? giveaway?.uuid ??
      [
        item?.itemid || item?._id || item?.id || item?.itemname || 'unknown-item',
        item?.itemvalue ?? giveaway?.amount ?? giveaway?.value ?? giveaway?.prize ?? 'unknown-value',
        giveaway?.starteruserid || giveaway?.starterusername || giveaway?.host || giveaway?.creator || 'unknown-host',
        giveaway?.enddate || giveaway?.endsAt || giveaway?.endAt || giveaway?.createdAt || 'unknown-end',
      ].map((part) => normalizeText(part)).join(':')
  );
}

function buildGiveawayChangeMessage(action, giveaway) {
  const giveawayId = giveawayIdOf(giveaway);
  const amount = pickGiveawayAmount(giveaway);
  const entries = pickGiveawayEntries(giveaway);
  const host = pickGiveawayHost(giveaway);
  const endRaw = pickGiveawayEnd(giveaway);
  const endTs = endRaw ? Math.floor(new Date(endRaw).getTime() / 1000) : null;
  const item = giveaway?.item?.[0];
  const itemName = item?.itemname || 'Unknown Item';

  const bodyLines = [
    'A new giveaway just went live.',
    '',
    `Item: **${itemName}**`,
    `Value: **${formatNumber(amount)}**`,
    `Entries: **${formatNumber(entries)}**`,
  ];

  if (host) bodyLines.push(`Host: **${String(host)}**`);
  if (endTs && Number.isFinite(endTs)) bodyLines.push(`Ends: <t:${endTs}:R>`);

  return createContainerPayload({
    title: 'New Giveaway Live',
    accentColor: 0xf1c40f,
    image: item?.itemimage || item?.image || item?.thumbnail || null,
    bodyLines,
    footerText: `Giveaway ID - ${giveawayId}`,
  });
}

function buildRainStatusMessage(rainData) {
  const { roundId, status, pot, remainingMs, joinOpensInMs } = rainData;
  const nowSeconds = Math.floor(Date.now() / 1000);
  const endsAtSeconds = remainingMs > 0 ? nowSeconds + Math.floor(remainingMs / 1000) : null;
  const opensAtSeconds = joinOpensInMs > 0 ? nowSeconds + Math.floor(joinOpensInMs / 1000) : null;
  const bodyLines = [`**Amount:** ${formatNumber(pot)} coins`];

  if (status === 'ACTIVE' && endsAtSeconds) bodyLines.push(`**Ends:** <t:${endsAtSeconds}:R>`);
  else if (status === 'WAITING' && opensAtSeconds) bodyLines.push(`**Opens:** <t:${opensAtSeconds}:R>`);
  else bodyLines.push('**Status:** No active rain pool');

  return createContainerPayload({
    title: 'Rain Pool',
    accentColor: 0x3498db,
    bodyLines,
    footerText: roundId && roundId !== 'NO_DATA' ? `Round ID - ${roundId}` : null,
  });
}

function isSendRateLimitError(err) {
  const code = Number(err?.status || err?.code || 0);
  return code === 429 || /rate limit/i.test(String(err?.message || ''));
}

function isMissingAccessError(err) {
  return String(err?.message || '').includes('Missing Access') || Number(err?.code) === 50001;
}

async function fetchChannel(channelId) {
  if (channelCache.has(channelId)) return channelCache.get(channelId);
  const channel = await client.channels.fetch(channelId);
  if (!channel || !channel.isTextBased()) throw new Error(`Channel ${channelId} missing or not text-based`);
  channelCache.set(channelId, channel);
  return channel;
}

async function sendToChannel(channelId, payload, options = {}) {
  const channel = await fetchChannel(channelId);
  const messagePayload = {
    ...payload,
    allowedMentions: options.allowedMentions || { parse: [] },
  };
  if (options.content) messagePayload.content = options.content;

  try {
    return await channel.send(messagePayload);
  } catch (err) {
    err.channelId = channelId;
    err.guildId = channel.guildId || null;
    err.channelName = channel.name || null;
    throw err;
  }
}

function removeBadChannelFromConfigs(channelId) {
  let changed = false;
  for (const [guildId, cfg] of guildConfigs.entries()) {
    const next = { ...cfg };
    for (const key of ['bloxypotChannelId', 'bloxycrossChannelId', 'highDemandChannelId']) {
      if (next[key] === channelId) {
        next[key] = null;
        changed = true;
      }
    }
    guildConfigs.set(guildId, next);
  }
  if (changed) saveGuildConfigs();
}

function enqueueChannelSend(channelId, payload, options = {}) {
  if (!channelId) return;
  outboundQueue.push({ channelId, payload, options, tries: 0 });
}

function startQueueWorker() {
  if (queueWorkerStarted) return;
  queueWorkerStarted = true;

  (async () => {
    while (true) {
      const job = outboundQueue.shift();
      if (!job) {
        await sleep(250);
        continue;
      }

      try {
        await sendToChannel(job.channelId, job.payload, job.options);
      } catch (err) {
        console.error('[QUEUE SEND ERROR]', err.message);
        if (isMissingAccessError(err)) removeBadChannelFromConfigs(err.channelId || job.channelId);
        if (isSendRateLimitError(err) && job.tries < MAX_QUEUE_RETRIES) {
          job.tries += 1;
          const retryAfter = Number(err?.retry_after || 2) * 1000;
          setTimeout(() => outboundQueue.push(job), retryAfter || 2000);
        }
      }

      await sleep(SEND_DELAY_MS);
    }
  })();
}

function makeEventCacheKey(kind, signature, guildId, channelId, roleId) {
  return `${kind}:${signature}:${guildId}:${channelId || 'none'}:${roleId || 'none'}`;
}

function markEventSent(key) {
  sentEventCache.set(key, Date.now());
}

function pruneSentEventCache() {
  const now = Date.now();
  for (const [key, ts] of sentEventCache.entries()) {
    if (now - ts > EVENT_CACHE_TTL_MS) sentEventCache.delete(key);
  }
}

function buildStockMap(items) {
  const map = new Map();
  for (const item of items) map.set(itemIdOf(item), item);
  return map;
}

function buildMarketplaceMap(items) {
  const map = new Map();
  for (const item of items) map.set(marketplaceIdOf(item), item);
  return map;
}

function buildStockCountMap(items) {
  const map = new Map();

  for (const item of items) {
    const parsed = item?.parsedName || parseStockItemName(item?.itemname);
    const key = parsed.fullNameNormalized;

    const liveValue =
      item?.apiValue ??
      item?.itemvalue ??
      item?.value ??
      item?.price ??
      item?.amount ??
      null;

    if (!map.has(key)) {
      map.set(key, {
        name: parsed.fullName || item?.itemname || 'Unknown Item',
        count: 0,
        sourceKind: item?.sourceKind || 'bloxypot',
        image: item?.image || item?.itemimage || item?.bgsiFull?.image || item?.bgsi?.image || null,
        itemimage: item?.itemimage || null,
        demand: getDemandFromStockSample(item),
        trend: item?.trend || null,
        priceGems: item?.priceGems ?? null,
        amountGems: item?.amountGems ?? null,
        value: liveValue,
        apiValue: liveValue,
        itemvalue: item?.itemvalue ?? null,
        bgsi: item?.bgsi || null,
        bgsiFull: item?.bgsiFull || null,
        bgsiBase: item?.bgsiBase || null,
        entries: [],
      });
    }

    const entry = map.get(key);
    entry.count += 1;
    entry.entries.push(item);

    if (entry.value == null && liveValue != null) {
      entry.value = liveValue;
      entry.apiValue = liveValue;
    }
    if (!entry.trend && item?.trend) entry.trend = item.trend;
    if (entry.priceGems == null && item?.priceGems != null) entry.priceGems = item.priceGems;
    if (entry.amountGems == null && item?.amountGems != null) entry.amountGems = item.amountGems;
  }

  return map;
}

function buildMarketplaceCountMap(items) {
  const map = new Map();

  for (const item of items) {
    const key = normalizeText(item?.itemname || 'Unknown Item');

    const liveValue =
      item?.itemvalue ??
      item?.apiValue ??
      item?.value ??
      item?.price ??
      item?.amount ??
      null;

    if (!map.has(key)) {
      map.set(key, {
        name: item?.itemname || 'Unknown Item',
        count: 0,
        image: item?.itemimage || item?.bgsiFull?.image || item?.bgsi?.image || null,
        demand: getDemandFromMarketplaceItem(item),
        value: liveValue,
        apiValue: liveValue,
        itemvalue: item?.itemvalue ?? null,
        bgsi: item?.bgsi || null,
        bgsiFull: item?.bgsiFull || null,
        bgsiBase: item?.bgsiBase || null,
        entries: [],
      });
    }

    const entry = map.get(key);
    entry.count += 1;
    entry.entries.push(item);

    if (entry.value == null && liveValue != null) {
      entry.value = liveValue;
      entry.apiValue = liveValue;
    }
  }

  return map;
}

// Components V2 cannot use message.content. Place the mention inside a
// Text Display so Discord can notify the selected role.
function enqueueHighDemandAlert(payload, pingRole = false) {
  const messagePayload = pingRole
    ? {
        ...payload,
        components: [
          { type: 10, content: `<@&${DEMAND_ALERT_ROLE_ID}>` },
          ...payload.components,
        ],
      }
    : payload;

  enqueueChannelSend(DEMAND_ALERT_CHANNEL_ID, messagePayload, {
    allowedMentions: pingRole
      ? { parse: [], roles: [DEMAND_ALERT_ROLE_ID] }
      : { parse: [] },
  });
}

function fanoutStockEvent(action, petName, beforeCount, afterCount, sampleData, footerText) {
  const signature = `${normalizeText(petName)}:${beforeCount}->${afterCount}:${action}`;
  const payload = buildStockChangeMessage(action, petName, beforeCount, afterCount, sampleData, footerText);
  const demand = getDemandFromStockSample(sampleData);
  const highDemand = shouldPingForDemand(demand);
  const pingHighDemandRole = highDemand && action === 'added';

  if (highDemand) {
    const key = makeEventCacheKey('stock-fixed-high', signature, 'global', DEMAND_ALERT_CHANNEL_ID, null);
    if (!sentEventCache.has(key)) {
      enqueueHighDemandAlert(payload, action === 'added');
      markEventSent(key);
    }
  }

  for (const [guildId, cfg] of guildConfigs.entries()) {
    if (cfg.bloxypotChannelId) {
      const key = makeEventCacheKey('stock', signature, guildId, cfg.bloxypotChannelId, null);
      if (!sentEventCache.has(key)) {
        enqueueChannelSend(cfg.bloxypotChannelId, payload, {
          content: pingHighDemandRole && cfg.highDemandRoleId ? `<@&${cfg.highDemandRoleId}>` : undefined,
          allowedMentions: pingHighDemandRole && cfg.highDemandRoleId ? { parse: [], roles: [cfg.highDemandRoleId] } : { parse: [] },
        });
        markEventSent(key);
      }
    }

    if (highDemand && cfg.highDemandChannelId && cfg.highDemandChannelId !== DEMAND_ALERT_CHANNEL_ID) {
      const key = makeEventCacheKey('stock-high', signature, guildId, cfg.highDemandChannelId, cfg.highDemandRoleId);
      if (!sentEventCache.has(key)) {
        enqueueChannelSend(cfg.highDemandChannelId, payload, {
          content: pingHighDemandRole && cfg.highDemandRoleId ? `<@&${cfg.highDemandRoleId}>` : undefined,
          allowedMentions: pingHighDemandRole && cfg.highDemandRoleId ? { parse: [], roles: [cfg.highDemandRoleId] } : { parse: [] },
        });
        markEventSent(key);
      }
    }
  }
}

function fanoutMarketplaceEvent(action, item, beforeCount, afterCount) {
  const signature = `${normalizeText(item?.itemname || 'unknown')}:${beforeCount}->${afterCount}:${action}`;
  const payload = buildMarketplaceChangeMessage(action, item, beforeCount, afterCount);
  const demand = getDemandFromMarketplaceItem(item);
  const highDemand = shouldPingForDemand(demand);
  const pingHighDemandRole = highDemand && action === 'added';

  if (highDemand) {
    const key = makeEventCacheKey('market-fixed-high', signature, 'global', DEMAND_ALERT_CHANNEL_ID, null);
    if (!sentEventCache.has(key)) {
      enqueueHighDemandAlert(payload, action === 'added');
      markEventSent(key);
    }
  }

  for (const [guildId, cfg] of guildConfigs.entries()) {
    if (cfg.bloxycrossChannelId) {
      const key = makeEventCacheKey('market', signature, guildId, cfg.bloxycrossChannelId, null);
      if (!sentEventCache.has(key)) {
        enqueueChannelSend(cfg.bloxycrossChannelId, payload, {
          content: pingHighDemandRole && cfg.highDemandRoleId ? `<@&${cfg.highDemandRoleId}>` : undefined,
          allowedMentions: pingHighDemandRole && cfg.highDemandRoleId ? { parse: [], roles: [cfg.highDemandRoleId] } : { parse: [] },
        });
        markEventSent(key);
      }
    }

    if (highDemand && cfg.highDemandChannelId && cfg.highDemandChannelId !== DEMAND_ALERT_CHANNEL_ID) {
      const key = makeEventCacheKey('market-high', signature, guildId, cfg.highDemandChannelId, cfg.highDemandRoleId);
      if (!sentEventCache.has(key)) {
        enqueueChannelSend(cfg.highDemandChannelId, payload, {
          content: pingHighDemandRole && cfg.highDemandRoleId ? `<@&${cfg.highDemandRoleId}>` : undefined,
          allowedMentions: pingHighDemandRole && cfg.highDemandRoleId ? { parse: [], roles: [cfg.highDemandRoleId] } : { parse: [] },
        });
        markEventSent(key);
      }
    }
  }
}

async function detectStockChanges(currentItems) {
  const currentMap = buildStockMap(currentItems);
  if (!hasInitializedStockSnapshot) {
    previousStockMap = currentMap;
    hasInitializedStockSnapshot = true;
    console.log(`[STOCK INIT] Snapshot initialized with ${currentMap.size} items`);
    return { previousCounts: buildStockCountMap([]), currentCounts: buildStockCountMap(currentItems) };
  }

  const previousCounts = buildStockCountMap([...previousStockMap.values()]);
  const currentCounts = buildStockCountMap(currentItems);
  const allPetKeys = new Set([...previousCounts.keys(), ...currentCounts.keys()]);

  for (const key of allPetKeys) {
    const prev = previousCounts.get(key);
    const curr = currentCounts.get(key);
    const beforeCount = prev?.count || 0;
    const afterCount = curr?.count || 0;
    if (beforeCount === afterCount) continue;
    const sampleData = curr || prev;
    const footerText = footerLineFromEntries(sampleData?.entries || []);
    fanoutStockEvent(afterCount > beforeCount ? 'added' : 'removed', sampleData?.name || 'Unknown Item', beforeCount, afterCount, sampleData, footerText);
  }

  previousStockMap = currentMap;
  return { previousCounts, currentCounts };
}

async function detectMarketplaceChanges(currentItems) {
  const currentMap = buildMarketplaceMap(currentItems);
  if (!hasInitializedMarketplaceSnapshot) {
    previousMarketplaceMap = currentMap;
    hasInitializedMarketplaceSnapshot = true;
    console.log(`[MARKETPLACE INIT] Snapshot initialized with ${currentMap.size} listings`);
    return { added: 0, removed: 0 };
  }

  const previousCounts = buildMarketplaceCountMap([...previousMarketplaceMap.values()]);
  const currentCounts = buildMarketplaceCountMap(currentItems);
  const allItemKeys = new Set([...previousCounts.keys(), ...currentCounts.keys()]);
  let added = 0;
  let removed = 0;

  for (const key of allItemKeys) {
    const prev = previousCounts.get(key);
    const curr = currentCounts.get(key);
    const beforeCount = prev?.count || 0;
    const afterCount = curr?.count || 0;
    if (beforeCount === afterCount) continue;
    const sampleData = curr?.entries?.[0] || prev?.entries?.[0] || curr || prev;
    if (afterCount > beforeCount) {
      fanoutMarketplaceEvent('added', sampleData, beforeCount, afterCount);
      added += 1;
    } else {
      fanoutMarketplaceEvent('removed', sampleData, beforeCount, afterCount);
      removed += 1;
    }
  }

  previousMarketplaceMap = currentMap;
  return { added, removed };
}

async function sendGroupedWatchAlerts(matchGroups) {
  for (const group of matchGroups) {
    const signature = `${group.userId}:${normalizeText(group.watchName)}:${group.beforeCount}->${group.afterCount}:${group.sampleData?.sourceKind || 'bloxypot'}`;
    if (sentWatchAlertSignatures.has(signature)) continue;
    const payload = buildMatchSummaryMessage(group);

    for (const [, cfg] of guildConfigs.entries()) {
      const channelId = cfg.bloxypotChannelId;
      if (channelId) enqueueChannelSend(channelId, payload, { allowedMentions: { parse: [] } });
    }

    try {
      const user = await client.users.fetch(group.userId);
      if (user) await user.send(payload);
    } catch (err) {
      console.error('[SEND] Failed to DM grouped alert:', err.message);
    }

    sentWatchAlertSignatures.add(signature);
  }
}

async function runCheck({ manual = false } = {}) {
  await ensureBgsiCacheReady();
  const items = attachCachedBgsiMeta(await fetchShop());
  const { previousCounts, currentCounts } = await detectStockChanges(items);
  const matchGroups = new Map();

  for (const item of items) {
    const parsed = item?.parsedName || parseStockItemName(item?.itemname);
    const stockId = itemIdOf(item);

    for (const watch of watchers.values()) {
      if (parsed.fullNameNormalized !== watch.fullNameNormalized) continue;
      const seenKey = `${watch.userId}:${stockId}`;
      if (!manual && seenStockIdsPerWatcher.has(seenKey)) continue;
      seenStockIdsPerWatcher.add(seenKey);

      const groupKey = `${watch.userId}:${watch.normalized}`;
      if (!matchGroups.has(groupKey)) {
        const prev = previousCounts.get(parsed.fullNameNormalized);
        const curr = currentCounts.get(parsed.fullNameNormalized);
        const entries = (curr || prev)?.entries || [item];
        matchGroups.set(groupKey, {
          userId: watch.userId,
          watchName: watch.full,
          petName: parsed.fullName,
          beforeCount: prev?.count || 0,
          afterCount: curr?.count || 0,
          sampleData: {
            sourceKind: item?.sourceKind || 'bloxypot',
            itemimage: item?.itemimage || null,
            image: item?.itemimage || item?.bgsiFull?.image || item?.bgsi?.image || null,
            demand: getDemandFromStockSample(item),
            trend: item?.trend || null,
            priceGems: item?.priceGems ?? null,
            amountGems: item?.amountGems ?? null,
            value: item?.apiValue ?? item?.itemvalue ?? item?.bgsiFull?.value ?? item?.bgsi?.value ?? null,
          },
          footerText: footerLineFromEntries(entries),
        });
      }
    }
  }

  if (matchGroups.size) await sendGroupedWatchAlerts([...matchGroups.values()]);
  console.log(`[CHECK] Finished. Items=${items.length} Matches=${matchGroups.size}`);
  return { itemsCount: items.length, matches: matchGroups.size };
}

async function runMarketplaceCheck() {
  await ensureBgsiCacheReady();
  const items = attachCachedMarketplaceMeta(await fetchMarketplace());
  const result = await detectMarketplaceChanges(items);
  console.log(`[MARKETPLACE CHECK] Finished. Listings=${items.length} Added=${result.added} Removed=${result.removed}`);
  return { itemsCount: items.length, ...result };
}

function buildGiveawayMap(giveaways) {
  const map = new Map();
  for (const giveaway of giveaways) map.set(giveawayIdOf(giveaway), giveaway);
  return map;
}

function giveawaySignatureOf(giveaway) {
  const item = giveaway?.item?.[0];
  return JSON.stringify({
    itemName: item?.itemname || null,
    value: pickGiveawayAmount(giveaway),
    entries: pickGiveawayEntries(giveaway),
    host: pickGiveawayHost(giveaway),
    end: pickGiveawayEnd(giveaway),
    complete: giveaway?.complete ?? null,
    active: giveaway?.active ?? null,
    status: giveaway?.status ?? null,
  });
}

function isGiveawayFinished(giveaway) {
  const status = normalizeText(giveaway?.status || '');
  const endRaw = pickGiveawayEnd(giveaway);
  const endMs = endRaw ? new Date(endRaw).getTime() : null;
  return Boolean(
    giveaway?.complete === true ||
      giveaway?.active === false ||
      ['complete', 'completed', 'ended', 'expired', 'closed'].includes(status) ||
      (Number.isFinite(endMs) && endMs <= Date.now())
  );
}

async function deleteGiveawayMessage(giveawayId) {
  const messageId = giveawayMessageIds.get(giveawayId);
  if (!messageId) return false;

  try {
    const channel = await fetchChannel(GIVEAWAY_CHANNEL_ID);
    const message = await channel.messages.fetch(messageId);
    await message.delete();
  } catch (err) {
    if (!(Number(err?.code) === 10008 || /unknown message/i.test(String(err?.message || '')))) {
      console.error('[GIVEAWAY CLEANUP ERROR]', err.message);
      return false;
    }
  }

  giveawayMessageIds.delete(giveawayId);
  giveawayMessageSignatures.delete(giveawayId);
  saveGiveawayMessageIds();
  console.log('[GIVEAWAY CLEANUP] Deleted/stale message removed', { giveawayId, messageId });
  return true;
}

async function sendOrUpdateGiveawayEvent(giveaway) {
  const giveawayId = giveawayIdOf(giveaway);
  const signature = giveawaySignatureOf(giveaway);

  if (isGiveawayFinished(giveaway)) {
    await deleteGiveawayMessage(giveawayId);
    return 'deleted';
  }

  const payload = buildGiveawayChangeMessage('added', giveaway);
  const channel = await fetchChannel(GIVEAWAY_CHANNEL_ID);
  const existingMessageId = giveawayMessageIds.get(giveawayId);

  if (existingMessageId) {
    try {
      const message = await channel.messages.fetch(existingMessageId);
      if (giveawayMessageSignatures.get(giveawayId) !== signature) {
        await message.edit({ ...payload, allowedMentions: { parse: [] } });
        giveawayMessageSignatures.set(giveawayId, signature);
        saveGiveawayMessageIds();
        console.log('[GIVEAWAY EDIT]', { giveawayId, messageId: existingMessageId });
        return 'updated';
      }
      return 'unchanged';
    } catch (err) {
      console.log('[GIVEAWAY] Saved message missing, sending fresh copy:', err.message);
      giveawayMessageIds.delete(giveawayId);
      giveawayMessageSignatures.delete(giveawayId);
      saveGiveawayMessageIds();
    }
  }

  const sent = await channel.send({ ...payload, allowedMentions: { parse: [] } });
  giveawayMessageIds.set(giveawayId, sent.id);
  giveawayMessageSignatures.set(giveawayId, signature);
  saveGiveawayMessageIds();
  console.log('[GIVEAWAY SEND]', { giveawayId, channelId: GIVEAWAY_CHANNEL_ID, messageId: sent.id });
  return 'added';
}

async function detectGiveawayChanges(currentGiveaways) {
  const currentMap = buildGiveawayMap(currentGiveaways);

  for (const savedGiveawayId of [...giveawayMessageIds.keys()]) {
    if (!currentMap.has(savedGiveawayId)) await deleteGiveawayMessage(savedGiveawayId);
  }

  let added = 0;
  let updated = 0;

  if (!hasInitializedGiveawaySnapshot) {
    previousGiveawayMap = currentMap;
    hasInitializedGiveawaySnapshot = true;
    console.log(`[GIVEAWAY INIT] Snapshot initialized with ${currentMap.size} giveaways`);
  }

  for (const [, giveaway] of currentMap.entries()) {
    const result = await sendOrUpdateGiveawayEvent(giveaway);
    if (result === 'added') added += 1;
    if (result === 'updated') updated += 1;
  }

  previousGiveawayMap = currentMap;
  return { added, updated };
}

async function runGiveawayCheck() {
  const giveaways = await fetchGiveaways();
  const result = await detectGiveawayChanges(giveaways);
  console.log(`[GIVEAWAY CHECK] Finished. Giveaways=${giveaways.length} Added=${result.added} Updated=${result.updated}`);
  return { itemsCount: giveaways.length, ...result };
}

async function fetchRainStatus() {
  try {
    const payload = await fetchJson(RAIN_STATUS_URL, 'Rain status');
    if (payload.message !== 'OK' || !payload.data) throw new Error('Invalid rain status response');
    return payload.data;
  } catch (err) {
    console.log('[RAIN FETCH] API failed, using default data:', err.message);
    return { roundId: 'NO_DATA', status: 'INACTIVE', pot: 0, participantsCount: 0, remainingMs: 0, joinOpensInMs: 0 };
  }
}

async function updateRainStatusMessage() {
  const rainData = await fetchRainStatus();
  if (lastRainRoundId && lastRainRoundId !== rainData.roundId) {
    console.log(`[RAIN] New round detected: ${rainData.roundId} (was ${lastRainRoundId})`);
  }
  lastRainRoundId = rainData.roundId;

  const payload = buildRainStatusMessage(rainData);
  const channel = await fetchChannel(RAIN_CHANNEL_ID);

  if (rainStatusMessageId) {
    try {
      const message = await channel.messages.fetch(rainStatusMessageId);
      await message.edit(payload);
      return;
    } catch (err) {
      console.log('[RAIN] Could not edit saved message, creating new one:', err.message);
    }
  }

  const sent = await channel.send(payload);
  rainStatusMessageId = sent.id;
  saveRainMessageId();
}

function isGuildTextChannel(channel) {
  return !!channel && [
    ChannelType.GuildText,
    ChannelType.GuildAnnouncement,
    ChannelType.PublicThread,
    ChannelType.PrivateThread,
    ChannelType.AnnouncementThread,
  ].includes(channel.type);
}

function makeWatcherKey(userId, normalized) {
  return `${userId}:${normalized}`;
}

client.on('messageCreate', async (msg) => {
  if (msg.author.bot || !msg.content.startsWith(PREFIX)) return;

  const args = msg.content.slice(PREFIX.length).trim().split(/\s+/);
  const cmd = (args.shift() || '').toLowerCase();

  try {
    if (cmd === 'watch') {
      await ensureBgsiCacheReady();
      const parsed = parseInput(args.join(' '));
      if (!parsed) return msg.reply(`Usage: \`${PREFIX}watch Shiny Mythic Money Mouth\``);

      const baseMeta = getCachedBgsiBasePet(parsed.baseName);
      if (!baseMeta) {
        return msg.reply(`That is not a valid BGSI pet: **${parsed.baseName}**`);
      }

      const supportedVariants = Array.isArray(baseMeta.variants) ? baseMeta.variants : [];
      if (!supportedVariants.includes(parsed.variantLabel)) {
        const supportedList = supportedVariants.length
          ? supportedVariants.map(v => variantLabelToDisplay(v) || 'Normal').join(', ')
          : 'None';
        return msg.reply(`That pet exists, but the variant **${variantLabelToDisplay(parsed.variantLabel) || 'Normal'}** is invalid for **${baseMeta.name}**.\nSupported variants: **${supportedList}**`);
      }

      let fullMeta = getCachedBgsiByFullName(parsed.full);

      if (!fullMeta) {
        fullMeta = {
          ...baseMeta,
          normalizedName: parsed.normalized,
          name: parsed.full,
          variant: parsed.variantLabel
        };
      }

      watchers.set(makeWatcherKey(msg.author.id, parsed.normalized), {
        ...parsed,
        userId: msg.author.id,
        createdAt: Date.now(),
        bgsiMeta: fullMeta,
        fullNameNormalized: fullMeta.normalizedName,
      });

      return msg.reply(`Now watching for **${parsed.full}**`);
    }

    if (cmd === 'unwatch') {
      const parsed = parseInput(args.join(' '));
      if (!parsed) return msg.reply(`Usage: \`${PREFIX}unwatch Shiny Mythic Money Mouth\``);
      const existed = watchers.delete(makeWatcherKey(msg.author.id, parsed.normalized));
      return msg.reply(existed ? `Removed watch for **${parsed.full}**` : `No active watch found for **${parsed.full}**`);
    }

    if (cmd === 'watches') {
      const own = [...watchers.values()].filter((w) => w.userId === msg.author.id);
      if (!own.length) return msg.reply('You have no active watches.');
      return msg.reply(`Your watches:\n${own.map((w, i) => `${i + 1}. ${w.full}`).join('\n')}`);
    }

    if (cmd === 'checkshop') {
      await msg.reply('Running manual shop check...');
      const result = await runCheck({ manual: true });
      return msg.reply(`Done. Checked **${result.itemsCount}** items and found **${result.matches}** matches.`);
    }

    if (cmd === 'checkmarketplace') {
      await msg.reply('Running manual marketplace check...');
      const result = await runMarketplaceCheck();
      return msg.reply(`Done. Checked **${result.itemsCount}** listings. Added **${result.added}**, removed **${result.removed}**.`);
    }

    if (cmd === 'checkgiveaways') {
      await msg.reply('Running manual giveaway check...');
      const result = await runGiveawayCheck();
      return msg.reply(`Done. Checked **${result.itemsCount}** giveaways. Added **${result.added}**, updated **${result.updated}**.`);
    }

    if (cmd === 'checkrain') {
      await msg.reply('Running manual rain check...');
      await updateRainStatusMessage();
      return msg.reply('Done. Rain status updated.');
    }

    if (cmd === 'refreshbgsi') {
      await msg.reply('Refreshing BGSI cache...');
      await refreshBgsiCache();
      return msg.reply(`BGSI cache refreshed. Cached **${bgsiEntriesByFullName.size}** full pet entries.`);
    }

    if (cmd === 'help') {
      return msg.reply([
        '**Commands**',
        `\`${PREFIX}watch Shiny Mythic Money Mouth\``,
        `\`${PREFIX}unwatch Shiny Mythic Money Mouth\``,
        `\`${PREFIX}watches\``,
        `\`${PREFIX}checkshop\``,
        `\`${PREFIX}checkmarketplace\``,
        `\`${PREFIX}checkgiveaways\``,
        `\`${PREFIX}checkrain\``,
        `\`${PREFIX}refreshbgsi\``,
        '',
        '**Slash setup commands**',
        '`/bloxypot channel:#channel`',
        '`/bloxycross channel:#channel`',
        '`/high-demands channel:#channel role:@role`',
      ].join('\n'));
    }
  } catch (err) {
    console.error(`[COMMAND ERROR] ${cmd}`, err);
    try { await msg.reply(`Command failed: ${err.message}`); } catch {}
  }
});

client.on('interactionCreate', async (interaction) => {
  if (!interaction.isChatInputCommand()) return;
  if (!interaction.guildId) return interaction.reply({ content: 'This command can only be used in a server.', ephemeral: true });

  try {
    if (interaction.commandName === 'bloxypot') {
      const channel = interaction.options.getChannel('channel', true);
      if (!isGuildTextChannel(channel)) return interaction.reply({ content: 'Pick a text channel.', ephemeral: true });
      updateGuildConfig(interaction.guildId, { bloxypotChannelId: channel.id });
      return interaction.reply({ content: `BloxyPot channel set to ${channel}`, ephemeral: true });
    }

    if (interaction.commandName === 'bloxycross') {
      const channel = interaction.options.getChannel('channel', true);
      if (!isGuildTextChannel(channel)) return interaction.reply({ content: 'Pick a text channel.', ephemeral: true });
      updateGuildConfig(interaction.guildId, { bloxycrossChannelId: channel.id });
      return interaction.reply({ content: `BloxyCross channel set to ${channel}`, ephemeral: true });
    }

    if (interaction.commandName === 'high-demands') {
      const channel = interaction.options.getChannel('channel', true);
      const role = interaction.options.getRole('role', true);
      if (!isGuildTextChannel(channel)) return interaction.reply({ content: 'Pick a text channel.', ephemeral: true });
      updateGuildConfig(interaction.guildId, { highDemandChannelId: channel.id, highDemandRoleId: role.id });
      return interaction.reply({ content: `High-demand alerts set to ${channel} and will ping ${role}`, ephemeral: true });
    }
  } catch (err) {
    console.error('[SLASH COMMAND ERROR]', err);
    const payload = { content: `Command failed: ${err.message}`, ephemeral: true };
    if (interaction.deferred || interaction.replied) return interaction.followUp(payload);
    return interaction.reply(payload);
  }
});

client.once('ready', async () => {
  console.log(`[READY] Logged in as ${client.user.tag}`);

  loadGuildConfigs();
  loadGiveawayMessageIds();
  loadRainMessageId();
  startQueueWorker();

  await client.application.commands.set([
    {
      name: 'bloxypot',
      description: 'Set BloxyPot output channel',
      options: [{ name: 'channel', type: 7, description: 'Channel to send BloxyPot stock', required: true }],
    },
    {
      name: 'bloxycross',
      description: 'Set BloxyCross output channel',
      options: [{ name: 'channel', type: 7, description: 'Channel to send marketplace listings', required: true }],
    },
    {
      name: 'high-demands',
      description: 'Set the high-demand alert channel and role to ping',
      options: [
        { name: 'channel', type: 7, description: 'Channel to send high-demand alerts', required: true },
        { name: 'role', type: 8, description: 'Role to ping for high-demand alerts', required: true },
      ],
    },
  ]);

  console.log('[READY] Slash commands registered');
  console.log(`[READY] Loaded guild configs: ${guildConfigs.size}`);

  try {
    await ensureBgsiCacheReady();
  } catch (err) {
    console.error('[READY] Initial BGSI cache failed:', err.message);
    if (loadBgsiCacheFromDisk({ allowStale: true })) console.log('[READY] Using stale BGSI disk cache because refresh failed');
  }

  createIntervalJob('bgsi-refresh', BGSI_REFRESH_MS, refreshBgsiCache, BGSI_REFRESH_MS);
  createIntervalJob('shop-check', POLL_INTERVAL_MS, () => runCheck({ manual: false }), 5000);
  createIntervalJob('marketplace-check', MARKETPLACE_POLL_INTERVAL_MS, runMarketplaceCheck, 8000);
  createIntervalJob('giveaway-check', GIVEAWAY_POLL_INTERVAL_MS, runGiveawayCheck, 11000);
  createIntervalJob('rain-check', RAIN_POLL_INTERVAL_MS, updateRainStatusMessage, 12000);
  setInterval(pruneSentEventCache, 60 * 1000);
});

client.login(DISCORD_TOKEN.trim());