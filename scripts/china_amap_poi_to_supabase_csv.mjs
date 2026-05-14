#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const DEFAULT_OUTPUT = "china_amap_courts_import.csv";
const DEFAULT_KEYWORDS = ["篮球场", "篮球馆", "篮球公园"];
const DEFAULT_PAGE_SIZE = 25;
const DEFAULT_MAX_PAGES = 40;
const DEFAULT_DELAY_MS = 220;
const SOURCE_LICENSE = "AMap Web Service API - review licence before production use";

const columns = [
  "id",
  "name",
  "area",
  "city",
  "country_code",
  "latitude",
  "longitude",
  "source",
  "source_license",
  "confidence",
  "last_checked_at",
  "court_type",
  "access_type",
  "price_type",
  "has_lights",
  "dryness_after_rain",
  "slippery_when_wet",
  "rain_playable",
  "surface_type",
  "surface_condition",
  "court_cleanliness",
  "court_space",
  "runoff_safety",
  "peak_times",
  "has_nets",
  "rim_height",
  "rim_type",
  "backboard_condition",
  "rim_condition",
  "hoop_count",
  "opening_hours",
  "evening_access",
  "has_toilets",
  "has_drinking_water",
  "has_parking",
  "has_changing_rooms",
  "good_for_solo",
  "good_for_pickup",
  "good_for_training",
  "beginner_friendly",
  "notes",
  "photo_asset_name",
  "photo_url",
  "osm_type",
  "osm_id",
  "osm_ref",
  "osm_tags_json",
  "import_batch"
];

const args = parseArgs(process.argv.slice(2));

if (args.help) {
  printHelp();
  process.exit(0);
}

const apiKey = args.key || process.env.AMAP_WEB_KEY || process.env.GAODE_WEB_KEY;
if (!apiKey) {
  console.error("Missing AMap Web Service key. Set AMAP_WEB_KEY or pass --key.");
  printHelp();
  process.exit(1);
}

const outputPath = path.resolve(args.output || DEFAULT_OUTPUT);
const keywords = splitList(args.keywords).length ? splitList(args.keywords) : DEFAULT_KEYWORDS;
const batch = args.batch || new Date().toISOString().slice(0, 10);
const pageSize = clampInteger(args.pageSize, DEFAULT_PAGE_SIZE, 1, 25);
const maxPages = clampInteger(args.maxPages, DEFAULT_MAX_PAGES, 1, 100);
const delayMs = clampInteger(args.delayMs, DEFAULT_DELAY_MS, 0, 5000);
const cityLimit = args.cityLimit ?? true;
const keepGcj02 = args.keepGcj02 ?? false;
const maxCities = args.maxCities ? Number(args.maxCities) : null;

const cities = await resolveCities({ apiKey, args });
const cityBatch = maxCities ? cities.slice(0, maxCities) : cities;
if (!cityBatch.length) {
  throw new Error("No cities resolved. Pass --cities, --city-file, or --discover-cities.");
}

const seenIds = new Set();
const seenCoordinates = new Set();
const rows = [];

console.log(`Cities: ${cityBatch.length}`);
console.log(`Keywords: ${keywords.join(", ")}`);
console.log(`Output: ${outputPath}`);
console.log(keepGcj02 ? "Coordinates: keeping AMap GCJ-02" : "Coordinates: converting AMap GCJ-02 to WGS84");

for (const city of cityBatch) {
  for (const keyword of keywords) {
    for (let page = 1; page <= maxPages; page += 1) {
      const payload = await fetchAmapPlaceText({
        apiKey,
        city,
        keyword,
        page,
        pageSize,
        types: args.types || "",
        cityLimit
      });

      const pois = Array.isArray(payload.pois) ? payload.pois : [];
      for (const poi of pois) {
        const row = poiToCourtRow(poi, { keyword, batch, keepGcj02 });
        if (!row) continue;

        const coordinateKey = `${Number(row.latitude).toFixed(6)},${Number(row.longitude).toFixed(6)}`;
        if (seenIds.has(row.id) || seenCoordinates.has(coordinateKey)) continue;

        seenIds.add(row.id);
        seenCoordinates.add(coordinateKey);
        rows.push(row);
      }

      if (pois.length < pageSize) break;
      await delay(delayMs);
    }
    await delay(delayMs);
  }
  console.log(`Scanned ${city.name || city.adcode}; rows so far: ${rows.length}`);
}

const csv = [
  columns.join(","),
  ...rows.map((row) => columns.map((column) => csvCell(row[column])).join(","))
].join("\n");

fs.writeFileSync(outputPath, `${csv}\n`);
console.log(`CSV rows: ${rows.length}`);

async function resolveCities({ apiKey, args }) {
  const explicitCities = splitList(args.cities).map((name) => ({ name, adcode: "" }));
  if (explicitCities.length) return explicitCities;

  if (args.cityFile) {
    const fileCities = fs.readFileSync(path.resolve(args.cityFile), "utf8")
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith("#"))
      .map((line) => {
        const [name, adcode = ""] = line.split(",").map((part) => part.trim());
        return { name, adcode };
      });
    return fileCities;
  }

  if (args.discoverCities) {
    return discoverChinaCities(apiKey);
  }

  return [
    "北京", "上海", "广州", "深圳", "成都", "重庆", "杭州", "武汉",
    "西安", "南京", "天津", "苏州", "郑州", "长沙", "青岛", "宁波",
    "厦门", "福州", "合肥", "济南", "昆明", "南昌", "南宁", "沈阳",
    "大连", "长春", "哈尔滨", "石家庄", "太原", "贵阳", "海口", "兰州",
    "银川", "西宁", "呼和浩特", "乌鲁木齐"
  ].map((name) => ({ name, adcode: "" }));
}

async function discoverChinaCities(apiKey) {
  const url = new URL("https://restapi.amap.com/v3/config/district");
  url.searchParams.set("key", apiKey);
  url.searchParams.set("keywords", "中国");
  url.searchParams.set("subdistrict", "2");
  url.searchParams.set("extensions", "base");

  const response = await fetch(url);
  const payload = await response.json();
  if (payload.status !== "1") {
    throw new Error(`AMap district lookup failed: ${payload.info || response.statusText}`);
  }

  const root = Array.isArray(payload.districts) ? payload.districts : [];
  const cities = [];
  for (const province of root[0]?.districts || []) {
    for (const district of province.districts || []) {
      if (district.level === "city" || district.citycode) {
        cities.push({
          name: district.name,
          adcode: district.adcode || ""
        });
      }
    }
  }

  return uniqueBy(cities, (city) => city.adcode || city.name);
}

async function fetchAmapPlaceText({ apiKey, city, keyword, page, pageSize, types, cityLimit }) {
  const url = new URL("https://restapi.amap.com/v3/place/text");
  url.searchParams.set("key", apiKey);
  url.searchParams.set("keywords", keyword);
  if (types) url.searchParams.set("types", types);
  url.searchParams.set("city", city.adcode || city.name);
  url.searchParams.set("citylimit", cityLimit ? "true" : "false");
  url.searchParams.set("offset", String(pageSize));
  url.searchParams.set("page", String(page));
  url.searchParams.set("extensions", "all");
  url.searchParams.set("output", "json");

  const response = await fetch(url);
  const payload = await response.json();
  if (payload.status !== "1") {
    throw new Error(`AMap place search failed for ${city.name}/${keyword}/page ${page}: ${payload.info || response.statusText}`);
  }

  return payload;
}

function poiToCourtRow(poi, { keyword, batch, keepGcj02 }) {
  const [rawLongitude, rawLatitude] = String(poi.location || "").split(",").map(Number);
  if (!Number.isFinite(rawLatitude) || !Number.isFinite(rawLongitude)) return null;

  const [longitude, latitude] = keepGcj02
    ? [rawLongitude, rawLatitude]
    : gcj02ToWgs84(rawLongitude, rawLatitude);

  const poiId = clean(poi.id) || slug(`${clean(poi.name)}-${rawLatitude}-${rawLongitude}`);
  const city = clean(poi.cityname) || clean(poi.pname) || "China";
  const area = clean(poi.adname) || clean(poi.address) || clean(poi.pname) || "China";
  const postcode = clean(poi.postcode);
  const displayArea = postcode || area || city;
  const name = formatCourtName(clean(poi.name), displayArea);
  const address = clean(poi.address);
  const photos = Array.isArray(poi.photos) ? poi.photos : [];
  const firstPhotoURL = clean(photos[0]?.url);

  return {
    id: `amap-${slug(poiId)}`,
    name,
    area,
    city,
    country_code: "CN",
    latitude: fixed(latitude),
    longitude: fixed(longitude),
    source: "amap",
    source_license: SOURCE_LICENSE,
    confidence: "candidateImported",
    last_checked_at: `Imported ${batch}`,
    court_type: inferCourtType(poi),
    access_type: "unknown",
    price_type: "unknown",
    has_lights: "unknown",
    dryness_after_rain: "unknown",
    slippery_when_wet: "unknown",
    rain_playable: "unknown",
    surface_type: "unknown",
    surface_condition: "unknown",
    court_cleanliness: "unknown",
    court_space: "unknown",
    runoff_safety: "unknown",
    peak_times: "{unknown}",
    has_nets: "unknown",
    rim_height: "unknown",
    rim_type: "unknown",
    backboard_condition: "unknown",
    rim_condition: "unknown",
    hoop_count: "",
    opening_hours: clean(poi.business?.opentime_today) || clean(poi.business?.opentime_week) || "Access not confirmed",
    evening_access: "unknown",
    has_toilets: "unknown",
    has_drinking_water: "unknown",
    has_parking: "unknown",
    has_changing_rooms: "unknown",
    good_for_solo: "unknown",
    good_for_pickup: "unknown",
    good_for_training: "unknown",
    beginner_friendly: "unknown",
    notes: [
      "Candidate imported from AMap Web Service Place Search.",
      address ? `Address: ${address}.` : "",
      postcode ? `Postcode: ${postcode}.` : "",
      keyword ? `Search keyword: ${keyword}.` : "",
      keepGcj02 ? "Coordinates are AMap GCJ-02." : "Coordinates converted from AMap GCJ-02 to WGS84.",
      "Verify licensing and court facts before treating this as Blacktop-verified data."
    ].filter(Boolean).join(" "),
    photo_asset_name: "",
    photo_url: firstPhotoURL,
    osm_type: "",
    osm_id: "",
    osm_ref: "",
    osm_tags_json: JSON.stringify(poi),
    import_batch: batch
  };
}

function formatCourtName(place, displayArea) {
  const cleanPlace = place || "Basketball court";
  const suffix = /篮球|basketball/i.test(cleanPlace) ? "" : " basketball court";
  return displayArea ? `${cleanPlace}${suffix} · ${displayArea}` : `${cleanPlace}${suffix}`;
}

function inferCourtType(poi) {
  const haystack = `${poi.name || ""} ${poi.type || ""} ${poi.typecode || ""}`.toLowerCase();
  if (haystack.includes("体育馆") || haystack.includes("室内") || haystack.includes("gym")) return "indoor";
  if (haystack.includes("公园") || haystack.includes("广场")) return "outdoor";
  return "unknown";
}

function parseArgs(rawArgs) {
  const parsed = {};
  for (let index = 0; index < rawArgs.length; index += 1) {
    const arg = rawArgs[index];
    if (arg === "--help" || arg === "-h") parsed.help = true;
    else if (arg === "--key") parsed.key = rawArgs[++index];
    else if (arg === "--output" || arg === "-o") parsed.output = rawArgs[++index];
    else if (arg === "--cities") parsed.cities = rawArgs[++index];
    else if (arg === "--city-file") parsed.cityFile = rawArgs[++index];
    else if (arg === "--discover-cities") parsed.discoverCities = true;
    else if (arg === "--keywords") parsed.keywords = rawArgs[++index];
    else if (arg === "--types") parsed.types = rawArgs[++index];
    else if (arg === "--batch") parsed.batch = rawArgs[++index];
    else if (arg === "--page-size") parsed.pageSize = rawArgs[++index];
    else if (arg === "--max-pages") parsed.maxPages = rawArgs[++index];
    else if (arg === "--delay-ms") parsed.delayMs = rawArgs[++index];
    else if (arg === "--max-cities") parsed.maxCities = rawArgs[++index];
    else if (arg === "--keep-gcj02") parsed.keepGcj02 = true;
    else if (arg === "--no-city-limit") parsed.cityLimit = false;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return parsed;
}

function printHelp() {
  console.log(`
Usage:
  export AMAP_WEB_KEY="your-amap-web-service-key"

  node scripts/china_amap_poi_to_supabase_csv.mjs \\
    --discover-cities \\
    --output ~/Downloads/china_amap_courts_import.csv

Options:
  --cities          Comma-separated city names or adcodes, e.g. "北京,上海,深圳"
  --city-file       Text file with one city per line. Optional format: city,adcode
  --discover-cities Discover China city list from AMap district API
  --keywords        Comma-separated search terms. Default: ${DEFAULT_KEYWORDS.join(",")}
  --types           Optional AMap POI type code filter
  --page-size       Results per request. Default/max: ${DEFAULT_PAGE_SIZE}
  --max-pages       Max pages per city/keyword. Default: ${DEFAULT_MAX_PAGES}
  --delay-ms        Delay between API calls. Default: ${DEFAULT_DELAY_MS}
  --max-cities      Test mode: only scan the first N cities
  --keep-gcj02      Keep AMap GCJ-02 coordinates instead of converting to WGS84
`);
}

function splitList(value) {
  return String(value || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function uniqueBy(items, keyFn) {
  const seen = new Set();
  const result = [];
  for (const item of items) {
    const key = keyFn(item);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    result.push(item);
  }
  return result;
}

function clampInteger(value, fallback, min, max) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.max(min, Math.min(max, parsed));
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function clean(value) {
  if (Array.isArray(value)) return value.filter(Boolean).join(" ").trim();
  return value === undefined || value === null ? "" : String(value).trim();
}

function fixed(value) {
  return Number(value).toFixed(7);
}

function slug(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9\u4e00-\u9fa5]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 96);
}

function csvCell(value) {
  const text = value === undefined || value === null ? "" : String(value);
  if (/[",\n\r]/.test(text)) return `"${text.replaceAll("\"", "\"\"")}"`;
  return text;
}

function outOfChina(lon, lat) {
  return lon < 72.004 || lon > 137.8347 || lat < 0.8293 || lat > 55.8271;
}

function gcj02ToWgs84(lon, lat) {
  if (outOfChina(lon, lat)) return [lon, lat];
  const [dLon, dLat] = transform(lon - 105.0, lat - 35.0);
  const radLat = lat / 180.0 * Math.PI;
  let magic = Math.sin(radLat);
  magic = 1 - 0.00669342162296594323 * magic * magic;
  const sqrtMagic = Math.sqrt(magic);
  const mgLat = lat + (dLat * 180.0) / ((6335552.717000426 * magic) / (sqrtMagic * sqrtMagic) * Math.PI);
  const mgLon = lon + (dLon * 180.0) / (6378245.0 / sqrtMagic * Math.cos(radLat) * Math.PI);
  return [lon * 2 - mgLon, lat * 2 - mgLat];
}

function transform(x, y) {
  let lat = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * Math.sqrt(Math.abs(x));
  lat += (20.0 * Math.sin(6.0 * x * Math.PI) + 20.0 * Math.sin(2.0 * x * Math.PI)) * 2.0 / 3.0;
  lat += (20.0 * Math.sin(y * Math.PI) + 40.0 * Math.sin(y / 3.0 * Math.PI)) * 2.0 / 3.0;
  lat += (160.0 * Math.sin(y / 12.0 * Math.PI) + 320 * Math.sin(y * Math.PI / 30.0)) * 2.0 / 3.0;

  let lon = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * Math.sqrt(Math.abs(x));
  lon += (20.0 * Math.sin(6.0 * x * Math.PI) + 20.0 * Math.sin(2.0 * x * Math.PI)) * 2.0 / 3.0;
  lon += (20.0 * Math.sin(x * Math.PI) + 40.0 * Math.sin(x / 3.0 * Math.PI)) * 2.0 / 3.0;
  lon += (150.0 * Math.sin(x / 12.0 * Math.PI) + 300.0 * Math.sin(x / 30.0 * Math.PI)) * 2.0 / 3.0;
  return [lon, lat];
}
