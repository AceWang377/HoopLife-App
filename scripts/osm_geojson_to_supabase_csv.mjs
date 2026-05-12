#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const DEFAULT_OUTPUT = "courts_import.csv";
const DEFAULT_CITY = "UK";
const DEFAULT_AREA = "Unknown area";
const OSM_LICENSE = "ODbL - OpenStreetMap contributors";

const columns = [
  "id",
  "name",
  "area",
  "city",
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

if (args.help || !args.input) {
  printHelp();
  process.exit(args.help ? 0 : 1);
}

const inputPath = path.resolve(args.input);
const outputPath = path.resolve(args.output || DEFAULT_OUTPUT);
const city = args.city || DEFAULT_CITY;
const fallbackArea = args.area || DEFAULT_AREA;
const importBatch = args.batch || new Date().toISOString().slice(0, 10);
const includeUnnamed = args.includeUnnamed ?? true;

const featureCollection = JSON.parse(fs.readFileSync(inputPath, "utf8"));
const features = Array.isArray(featureCollection.features) ? featureCollection.features : [];
const seenIds = new Set();
const seenCoordinates = new Set();
const rows = [];

for (const feature of features) {
  const row = featureToCourtRow(feature, { city, fallbackArea, importBatch, includeUnnamed });
  if (!row) continue;

  const coordinateKey = `${Number(row.latitude).toFixed(6)},${Number(row.longitude).toFixed(6)}`;
  if (seenIds.has(row.id) || seenCoordinates.has(coordinateKey)) continue;

  seenIds.add(row.id);
  seenCoordinates.add(coordinateKey);
  rows.push(row);
}

const csv = [
  columns.join(","),
  ...rows.map((row) => columns.map((column) => csvCell(row[column])).join(","))
].join("\n");

fs.writeFileSync(outputPath, `${csv}\n`);

console.log(`Input features: ${features.length}`);
console.log(`CSV rows: ${rows.length}`);
console.log(`Output: ${outputPath}`);

function featureToCourtRow(feature, options) {
  const properties = feature.properties || {};
  const coordinates = feature.geometry?.coordinates;
  if (!Array.isArray(coordinates) || coordinates.length < 2) return null;

  const longitude = Number(coordinates[0]);
  const latitude = Number(coordinates[1]);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;

  const osmRef = String(properties["@id"] || feature.id || "").trim();
  const { osmType, osmId } = parseOsmRef(osmRef);
  const id = osmType && osmId
    ? `osm-${osmType}-${osmId}`
    : `osm-${slug(`${latitude}-${longitude}`)}`;

  const nameFromOSM = clean(properties.name);
  if (!nameFromOSM && !options.includeUnnamed) return null;

  const leisure = clean(properties.leisure);
  const indoor = clean(properties.indoor);
  const covered = clean(properties.covered);
  const sourceTag = clean(properties.source);

  const courtType = mapCourtType({ leisure, indoor });
  const hasLights = mapBooleanStatus(properties.lit);
  const surfaceType = mapSurface(properties.surface);
  const hoopCount = parseOptionalInteger(properties.hoops || properties["basketball:hoops"]);

  return {
    id,
    name: nameFromOSM || fallbackName(osmType, osmId),
    area: inferArea(properties, options.fallbackArea),
    city: clean(properties["addr:city"]) || options.city,
    latitude: fixed(latitude),
    longitude: fixed(longitude),
    source: "openStreetMap",
    source_license: OSM_LICENSE,
    confidence: "imported",
    last_checked_at: `Imported ${options.importBatch}`,
    court_type: courtType,
    access_type: mapAccess(properties.access),
    price_type: mapFee(properties.fee),
    has_lights: hasLights,
    dryness_after_rain: courtType === "indoor" ? "indoorUnaffected" : "unknown",
    slippery_when_wet: "unknown",
    rain_playable: mapRainPlayable({ courtType, covered }),
    surface_type: surfaceType,
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
    hoop_count: hoopCount ?? "",
    opening_hours: clean(properties.opening_hours) || "Access not confirmed",
    evening_access: hasLights === "yes" ? "yes" : "unknown",
    has_toilets: "unknown",
    has_drinking_water: "unknown",
    has_parking: "unknown",
    has_changing_rooms: "unknown",
    good_for_solo: "unknown",
    good_for_pickup: "unknown",
    good_for_training: "unknown",
    beginner_friendly: "unknown",
    notes: [
      `Imported from OpenStreetMap${osmRef ? ` (${osmRef})` : ""}.`,
      nameFromOSM ? "" : "Name is missing in OSM and should be manually reviewed.",
      sourceTag ? `OSM source tag: ${sourceTag}.` : ""
    ].filter(Boolean).join(" "),
    photo_asset_name: "",
    photo_url: "",
    osm_type: osmType,
    osm_id: osmId,
    osm_ref: osmRef,
    osm_tags_json: JSON.stringify(properties),
    import_batch: options.importBatch
  };
}

function parseArgs(rawArgs) {
  const parsed = {};
  for (let index = 0; index < rawArgs.length; index += 1) {
    const arg = rawArgs[index];
    if (arg === "--help" || arg === "-h") parsed.help = true;
    else if (arg === "--input" || arg === "-i") parsed.input = rawArgs[++index];
    else if (arg === "--output" || arg === "-o") parsed.output = rawArgs[++index];
    else if (arg === "--city") parsed.city = rawArgs[++index];
    else if (arg === "--area") parsed.area = rawArgs[++index];
    else if (arg === "--batch") parsed.batch = rawArgs[++index];
    else if (arg === "--named-only") parsed.includeUnnamed = false;
    else if (!parsed.input) parsed.input = arg;
    else if (!parsed.output) parsed.output = arg;
  }
  return parsed;
}

function printHelp() {
  console.log(`
Usage:
  node scripts/osm_geojson_to_supabase_csv.mjs --input export.geojson --output courts_import.csv --city "Sheffield" --area "Sheffield" --batch 2026-05-12

Options:
  -i, --input       Overpass Turbo GeoJSON export path
  -o, --output      Output CSV path. Default: ${DEFAULT_OUTPUT}
  --city            Default city when OSM addr:city is missing. Default: ${DEFAULT_CITY}
  --area            Default area when OSM suburb/neighbourhood is missing. Default: ${DEFAULT_AREA}
  --batch           Import batch label/date. Default: today
  --named-only      Skip OSM features without a name
`);
}

function parseOsmRef(ref) {
  const match = String(ref).match(/^(node|way|relation)\/(.+)$/);
  if (!match) return { osmType: "", osmId: "" };
  return { osmType: match[1], osmId: match[2] };
}

function fallbackName(osmType, osmId) {
  if (osmType && osmId) return `OSM Basketball Court ${osmId}`;
  return "OSM Basketball Court";
}

function inferArea(properties, fallbackArea) {
  return clean(properties["addr:suburb"]) ||
    clean(properties["addr:neighbourhood"]) ||
    clean(properties["addr:district"]) ||
    clean(properties["addr:street"]) ||
    clean(properties.operator) ||
    fallbackArea;
}

function mapCourtType({ leisure, indoor }) {
  const indoorValue = String(indoor || "").toLowerCase();
  if (["yes", "true", "1"].includes(indoorValue)) return "indoor";
  if (["no", "false", "0"].includes(indoorValue)) return "outdoor";
  if (leisure === "sports_centre") return "mixed";
  return "outdoor";
}

function mapBooleanStatus(value) {
  const normalised = clean(value).toLowerCase();
  if (["yes", "true", "1"].includes(normalised)) return "yes";
  if (["no", "false", "0"].includes(normalised)) return "no";
  if (["limited", "seasonal", "partial"].includes(normalised)) return "sometimes";
  return "unknown";
}

function mapRainPlayable({ courtType, covered }) {
  if (courtType === "indoor") return "indoorUnaffected";
  const coveredValue = clean(covered).toLowerCase();
  if (["yes", "true", "1"].includes(coveredValue)) return "partially";
  if (["no", "false", "0"].includes(coveredValue)) return "unknown";
  return "unknown";
}

function mapSurface(value) {
  const normalised = clean(value).toLowerCase();
  if (!normalised) return "unknown";
  if (normalised.includes("asphalt")) return "asphalt";
  if (normalised.includes("concrete")) return "concrete";
  if (normalised.includes("rubber")) return "rubber";
  if (normalised.includes("wood")) return "wood";
  if (normalised.includes("synthetic") || normalised.includes("acrylic") || normalised.includes("tartan")) return "synthetic";
  return "unknown";
}

function mapAccess(value) {
  const normalised = clean(value).toLowerCase();
  if (!normalised) return "unknown";
  if (["yes", "public", "permissive", "customers"].includes(normalised)) {
    return normalised === "customers" ? "bookingRequired" : "public";
  }
  if (["private", "no"].includes(normalised)) return "private";
  if (normalised.includes("school")) return "school";
  if (normalised.includes("member")) return "membersOnly";
  return "unknown";
}

function mapFee(value) {
  const normalised = clean(value).toLowerCase();
  if (["yes", "true", "1"].includes(normalised)) return "paid";
  if (["no", "false", "0"].includes(normalised)) return "free";
  return "unknown";
}

function parseOptionalInteger(value) {
  const parsed = Number.parseInt(clean(value), 10);
  return Number.isFinite(parsed) ? parsed : null;
}

function clean(value) {
  return value === undefined || value === null ? "" : String(value).trim();
}

function fixed(value) {
  return Number(value).toFixed(7);
}

function slug(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 96);
}

function csvCell(value) {
  const text = value === undefined || value === null ? "" : String(value);
  if (/[",\n\r]/.test(text)) return `"${text.replaceAll("\"", "\"\"")}"`;
  return text;
}
