#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const DEFAULT_OUTPUT = "court_postcode_enrichment.csv";
const DEFAULT_CHUNK_SIZE = 100;
const DEFAULT_RADIUS = 500;
const DEFAULT_DELAY_MS = 250;

const args = parseArgs(process.argv.slice(2));

if (args.help || !args.input) {
  printHelp();
  process.exit(args.help ? 0 : 1);
}

const inputPath = path.resolve(args.input);
const outputPath = path.resolve(args.output || DEFAULT_OUTPUT);
const chunkSize = Number(args.chunk || DEFAULT_CHUNK_SIZE);
const radius = Number(args.radius || DEFAULT_RADIUS);
const delayMs = Number(args.delay || DEFAULT_DELAY_MS);

const rows = parseCSV(fs.readFileSync(inputPath, "utf8"));
const enrichmentRows = [];
let postcodesLookupCount = 0;

for (let index = 0; index < rows.length; index += chunkSize) {
  const batch = rows.slice(index, index + chunkSize);
  const lookups = batch.map((row) => {
    const tags = parseTags(row.osm_tags_json);
    const osmPostcode = clean(tags["addr:postcode"]);
    if (osmPostcode) return null;

    const latitude = Number(row.latitude);
    const longitude = Number(row.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;

    return { latitude, longitude, radius, limit: 1 };
  });

  const postcodes = lookups.some(Boolean)
    ? await fetchPostcodes(lookups)
    : [];

  for (let offset = 0; offset < batch.length; offset += 1) {
    const row = batch[offset];
    const tags = parseTags(row.osm_tags_json);
    const osmPostcode = clean(tags["addr:postcode"]);
    const postcodeResult = postcodes[offset]?.[0];
    const resolvedPostcode = osmPostcode || clean(postcodeResult?.postcode);
    const postcodeSource = osmPostcode ? "osm" : (resolvedPostcode ? "postcodes.io" : "");
    const resolvedPlaceName = inferPlaceName(row, tags);
    const suggestedName = buildSuggestedName(resolvedPlaceName, resolvedPostcode);
    const city = inferCity(row, tags, postcodeResult);
    const area = inferArea(row, tags, postcodeResult);

    enrichmentRows.push({
      id: row.id,
      suggested_name: suggestedName,
      resolved_postcode: resolvedPostcode,
      resolved_place_name: resolvedPlaceName,
      postcode_source: postcodeSource,
      postcode_distance_m: postcodeResult?.distance ? String(Math.round(Number(postcodeResult.distance))) : "",
      suggested_area: area,
      suggested_city: city
    });

    if (!osmPostcode && resolvedPostcode) postcodesLookupCount += 1;
  }

  if (index + chunkSize < rows.length && delayMs > 0) {
    await sleep(delayMs);
  }
}

const columns = [
  "id",
  "suggested_name",
  "resolved_postcode",
  "resolved_place_name",
  "postcode_source",
  "postcode_distance_m",
  "suggested_area",
  "suggested_city"
];

const csv = [
  columns.join(","),
  ...enrichmentRows.map((row) => columns.map((column) => csvCell(row[column])).join(","))
].join("\n");

fs.writeFileSync(outputPath, `${csv}\n`);

console.log(`Input rows: ${rows.length}`);
console.log(`Rows enriched: ${enrichmentRows.length}`);
console.log(`Postcodes.io lookups filled: ${postcodesLookupCount}`);
console.log(`Output: ${outputPath}`);

async function fetchPostcodes(lookups) {
  const geolocations = lookups.map((lookup) => lookup || { longitude: 0, latitude: 0, radius: 1, limit: 1 });
  const response = await fetch("https://api.postcodes.io/postcodes?filter=postcode,distance,admin_district,parish,region", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ geolocations })
  });

  if (!response.ok) {
    throw new Error(`Postcodes.io request failed: ${response.status} ${response.statusText}`);
  }

  const payload = await response.json();
  if (!Array.isArray(payload.result)) return [];

  return payload.result.map((entry, index) => lookups[index] ? (entry?.result || []) : []);
}

function buildSuggestedName(placeName, postcode) {
  if (placeName && postcode) return `${placeName} basketball court · ${postcode}`;
  if (placeName) return `${placeName} basketball court`;
  if (postcode) return `Basketball court · ${postcode}`;
  return "Basketball court";
}

function inferPlaceName(row, tags) {
  const candidates = [
    tags.name,
    tags.official_name,
    tags.operator,
    tags["addr:housename"],
    tags["addr:street"],
    tags["addr:suburb"],
    tags["addr:neighbourhood"],
    row.area
  ];

  return candidates
    .map(clean)
    .find((value) => value && !isGenericPlace(value) && !isSyntheticName(value)) || "";
}

function inferArea(row, tags, postcodeResult) {
  return [
    row.area,
    tags["addr:suburb"],
    tags["addr:neighbourhood"],
    tags["addr:district"],
    postcodeResult?.parish,
    postcodeResult?.admin_district
  ].map(clean).find((value) => value && !isGenericPlace(value)) || clean(row.area);
}

function inferCity(row, tags, postcodeResult) {
  return [
    row.city,
    tags["addr:city"],
    tags["addr:town"],
    tags["addr:village"],
    postcodeResult?.admin_district
  ].map(clean).find((value) => value && !isGenericPlace(value)) || clean(row.city);
}

function isGenericPlace(value) {
  return ["uk", "unknown", "unknown area", "basketball court"].includes(String(value).trim().toLowerCase());
}

function isSyntheticName(value) {
  const lower = String(value).trim().toLowerCase();
  return lower.startsWith("osm basketball court") ||
    /^basketball court \((node|way|relation)\//i.test(value) ||
    /^(node|way|relation)-?\d+$/i.test(value);
}

function parseTags(value) {
  if (!value) return {};
  if (typeof value === "object") return value;
  try {
    return JSON.parse(value);
  } catch {
    return {};
  }
}

function clean(value) {
  return String(value || "").trim().replace(/\s+/g, " ");
}

function parseArgs(rawArgs) {
  const parsed = {};
  for (let index = 0; index < rawArgs.length; index += 1) {
    const arg = rawArgs[index];
    if (arg === "--help" || arg === "-h") parsed.help = true;
    else if (arg === "--input" || arg === "-i") parsed.input = rawArgs[++index];
    else if (arg === "--output" || arg === "-o") parsed.output = rawArgs[++index];
    else if (arg === "--chunk") parsed.chunk = rawArgs[++index];
    else if (arg === "--radius") parsed.radius = rawArgs[++index];
    else if (arg === "--delay") parsed.delay = rawArgs[++index];
    else if (!parsed.input) parsed.input = arg;
    else if (!parsed.output) parsed.output = arg;
  }
  return parsed;
}

function parseCSV(text) {
  const records = [];
  let field = "";
  let row = [];
  let inQuotes = false;

  for (let index = 0; index < text.length; index += 1) {
    const char = text[index];
    const next = text[index + 1];

    if (inQuotes && char === "\"" && next === "\"") {
      field += "\"";
      index += 1;
    } else if (char === "\"") {
      inQuotes = !inQuotes;
    } else if (!inQuotes && char === ",") {
      row.push(field);
      field = "";
    } else if (!inQuotes && (char === "\n" || char === "\r")) {
      if (char === "\r" && next === "\n") index += 1;
      row.push(field);
      records.push(row);
      row = [];
      field = "";
    } else {
      field += char;
    }
  }

  if (field || row.length) {
    row.push(field);
    records.push(row);
  }

  const [headers, ...dataRows] = records.filter((record) => record.some((cell) => cell.trim()));
  return dataRows.map((record) => Object.fromEntries(headers.map((header, index) => [header, record[index] || ""])));
}

function csvCell(value) {
  const text = String(value ?? "");
  if (!/[",\n\r]/.test(text)) return text;
  return `"${text.replaceAll("\"", "\"\"")}"`;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function printHelp() {
  console.log(`
Usage:
  node scripts/enrich_courts_postcodes.mjs --input courts_export.csv --output court_postcode_enrichment.csv

Options:
  -i, --input    CSV exported from Supabase public.courts
  -o, --output   Enrichment CSV output. Default: ${DEFAULT_OUTPUT}
  --chunk        Postcodes.io batch size. Default: ${DEFAULT_CHUNK_SIZE}
  --radius       Nearest postcode search radius in metres. Default: ${DEFAULT_RADIUS}
  --delay        Delay between batches in ms. Default: ${DEFAULT_DELAY_MS}
`);
}
