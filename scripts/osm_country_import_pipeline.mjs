#!/usr/bin/env node

import childProcess from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, "..");
const converterPath = path.join(repoRoot, "scripts", "osm_geojson_to_supabase_csv.mjs");
const stagingSqlPath = path.join(repoRoot, "supabase", "osm_country_import_staging_create.sql");
const mergeSqlPath = path.join(repoRoot, "supabase", "osm_country_import_merge.sql");
const globalSqlPath = path.join(repoRoot, "supabase", "global_court_scaling.sql");

const csvColumns = [
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

if (args.help || !args.country || !args.name) {
  printHelp();
  process.exit(args.help ? 0 : 1);
}

const country = args.country.toUpperCase();
const countryName = args.name;
const batch = args.batch || new Date().toISOString().slice(0, 10);
const workdir = path.resolve(expandHome(args.workdir || path.join(os.homedir(), "Downloads", `hooplife-${country.toLowerCase()}-osm`)));
const baseName = slug(`${country}-${countryName}-${batch}`);
const sourcePbf = path.resolve(expandHome(args.inputPbf || path.join(workdir, `${baseName}-latest.osm.pbf`)));
const filteredPbf = path.resolve(expandHome(args.filteredPbf || path.join(workdir, `${baseName}-basketball.osm.pbf`)));
const geojson = path.resolve(expandHome(args.inputGeojson || path.join(workdir, `${baseName}-basketball.geojson`)));
const csv = path.resolve(expandHome(args.outputCsv || path.join(workdir, `${baseName}-courts-import.csv`)));
const dbUrl = args.dbUrl || process.env.SUPABASE_DATABASE_URL;

main().catch((error) => {
  console.error(`\nImport pipeline failed: ${error.message}`);
  process.exit(1);
});

async function main() {
  fs.mkdirSync(workdir, { recursive: true });

  console.log(`HoopLife OSM import pipeline`);
  console.log(`Country: ${countryName} (${country})`);
  console.log(`Workdir: ${workdir}`);

  if (args.inputGeojson) {
    assertFile(geojson, "input GeoJSON");
  } else {
    await ensurePbf();
    filterBasketballPbf();
    exportGeojson();
  }

  convertGeojsonToCsv();

  if (!args.apply) {
    printManualNextSteps();
    return;
  }

  if (!dbUrl) {
    throw new Error("Missing database URL. Set SUPABASE_DATABASE_URL or pass --db-url. The Supabase dashboard page URL is not a database connection string.");
  }

  requireCommand("psql", "Install PostgreSQL tools first, for example: brew install libpq");

  if (args.setupGlobal) {
    runPsqlFile(globalSqlPath, "global court scaling setup");
  }
  runPsqlFile(stagingSqlPath, "staging table setup");
  copyCsvToStaging();
  runPsqlFile(mergeSqlPath, "safe merge into public.courts");

  console.log("\nDone. Existing public.courts rows were not deleted or overwritten.");
}

async function ensurePbf() {
  if (args.inputPbf) {
    assertFile(sourcePbf, "input PBF");
    return;
  }

  if (!args.geofabrikUrl) {
    throw new Error("Provide either --input-geojson, --input-pbf, or --geofabrik-url.");
  }

  if (fs.existsSync(sourcePbf) && !args.forceDownload) {
    console.log(`Using existing PBF: ${sourcePbf}`);
    return;
  }

  requireCommand("curl", "curl is required to download Geofabrik PBF files.");
  run("curl", ["-L", "-o", sourcePbf, args.geofabrikUrl], "download Geofabrik PBF");
}

function filterBasketballPbf() {
  requireCommand("osmium", "Install osmium-tool first: brew install osmium-tool");
  run("osmium", [
    "tags-filter",
    sourcePbf,
    "n/sport=basketball",
    "w/sport=basketball",
    "r/sport=basketball",
    "n/basketball=yes",
    "w/basketball=yes",
    "r/basketball=yes",
    "n/hoops",
    "w/hoops",
    "r/hoops",
    "n/basketball:hoops",
    "w/basketball:hoops",
    "r/basketball:hoops",
    "-o",
    filteredPbf,
    "--overwrite"
  ], "filter basketball objects");
}

function exportGeojson() {
  run("osmium", [
    "export",
    filteredPbf,
    "--attributes=type,id",
    "-o",
    geojson,
    "--overwrite"
  ], "export filtered PBF to GeoJSON");
}

function convertGeojsonToCsv() {
  assertFile(geojson, "GeoJSON");
  run(process.execPath, [
    converterPath,
    "--input",
    geojson,
    "--output",
    csv,
    "--city",
    countryName,
    "--area",
    countryName,
    "--country",
    country,
    "--batch",
    batch,
    "--name-style",
    args.nameStyle || "place-postcode"
  ], "convert GeoJSON to HoopLife CSV");
}

function copyCsvToStaging() {
  assertFile(csv, "CSV");
  const copySql = [
    `\\copy public.courts_osm_import_staging (${csvColumns.join(", ")})`,
    `from '${sqlString(csv)}'`,
    `with (format csv, header true, quote '"', escape '"');`
  ].join(" ");
  const tempSql = path.join(workdir, `${baseName}-copy-staging.sql`);
  fs.writeFileSync(tempSql, `${copySql}\n`);
  runPsqlFile(tempSql, "copy CSV into staging");
}

function runPsqlFile(sqlPath, label) {
  assertFile(sqlPath, label);
  run("psql", [dbUrl, "-v", "ON_ERROR_STOP=1", "-f", sqlPath], label, { redact: dbUrl });
}

function run(command, commandArgs, label, options = {}) {
  console.log(`\n→ ${label}`);
  const printable = [command, ...commandArgs]
    .map((part) => part === options.redact ? "<DATABASE_URL>" : quoteShell(part))
    .join(" ");
  console.log(printable);

  const result = childProcess.spawnSync(command, commandArgs, {
    cwd: repoRoot,
    stdio: "inherit",
    env: process.env
  });

  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    throw new Error(`${label} exited with status ${result.status}`);
  }
}

function requireCommand(command, message) {
  const result = childProcess.spawnSync("sh", ["-lc", `command -v ${quoteShell(command)}`], {
    stdio: "ignore"
  });
  if (result.status !== 0) {
    throw new Error(`${command} was not found. ${message}`);
  }
}

function assertFile(filePath, label) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Missing ${label}: ${filePath}`);
  }
}

function printManualNextSteps() {
  console.log(`\nCSV ready: ${csv}`);
  console.log("\nNo database changes were made because --apply was not passed.");
  console.log("\nManual Supabase steps:");
  console.log("1. Run supabase/osm_country_import_staging_create.sql in Supabase SQL Editor.");
  console.log("2. Import the CSV into public.courts_osm_import_staging.");
  console.log("3. Run supabase/osm_country_import_merge.sql.");
  console.log("\nAutomated DB import:");
  console.log("export SUPABASE_DATABASE_URL='postgresql://...'");
  console.log(`node scripts/osm_country_import_pipeline.mjs --country ${country} --name "${countryName}" --input-geojson "${geojson}" --apply`);
}

function parseArgs(rawArgs) {
  const parsed = {};
  for (let index = 0; index < rawArgs.length; index += 1) {
    const arg = rawArgs[index];
    if (arg === "--help" || arg === "-h") parsed.help = true;
    else if (arg === "--country") parsed.country = rawArgs[++index];
    else if (arg === "--name") parsed.name = rawArgs[++index];
    else if (arg === "--geofabrik-url") parsed.geofabrikUrl = rawArgs[++index];
    else if (arg === "--input-pbf") parsed.inputPbf = rawArgs[++index];
    else if (arg === "--filtered-pbf") parsed.filteredPbf = rawArgs[++index];
    else if (arg === "--input-geojson") parsed.inputGeojson = rawArgs[++index];
    else if (arg === "--output-csv") parsed.outputCsv = rawArgs[++index];
    else if (arg === "--workdir") parsed.workdir = rawArgs[++index];
    else if (arg === "--batch") parsed.batch = rawArgs[++index];
    else if (arg === "--db-url") parsed.dbUrl = rawArgs[++index];
    else if (arg === "--name-style") parsed.nameStyle = rawArgs[++index];
    else if (arg === "--apply") parsed.apply = true;
    else if (arg === "--setup-global") parsed.setupGlobal = true;
    else if (arg === "--force-download") parsed.forceDownload = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return parsed;
}

function printHelp() {
  console.log(`
Usage:
  node scripts/osm_country_import_pipeline.mjs --country FR --name "France" --geofabrik-url "https://download.geofabrik.de/europe/france-latest.osm.pbf"

Safe default:
  Without --apply, the script only creates a cleaned CSV and prints next steps.

Database import:
  export SUPABASE_DATABASE_URL='postgresql://...'
  node scripts/osm_country_import_pipeline.mjs --country FR --name "France" --input-geojson ~/Downloads/france_basketball.geojson --apply

Options:
  --country          ISO country code, for example FR, DE, ES
  --name             Country display/default name, for example "France"
  --geofabrik-url    Geofabrik .osm.pbf URL to download
  --input-pbf        Existing local .osm.pbf file
  --input-geojson    Existing local GeoJSON file; skips osmium filtering
  --output-csv       Output HoopLife import CSV
  --workdir          Working directory. Default: ~/Downloads/hooplife-<country>-osm
  --batch            Import batch label/date. Default: today
  --name-style       Converter naming style. Default: place-postcode
  --apply            Create staging, copy CSV, and run safe merge using psql
  --setup-global     Also run supabase/global_court_scaling.sql before staging
  --db-url           Postgres connection string. Prefer SUPABASE_DATABASE_URL env var
  --force-download   Re-download the Geofabrik PBF even if it already exists
`);
}

function expandHome(value) {
  if (!value) return value;
  if (value === "~") return os.homedir();
  if (value.startsWith("~/")) return path.join(os.homedir(), value.slice(2));
  return value;
}

function sqlString(value) {
  return String(value).replaceAll("'", "''");
}

function quoteShell(value) {
  const text = String(value);
  if (/^[A-Za-z0-9_./:=@+-]+$/.test(text)) return text;
  return `'${text.replaceAll("'", "'\\''")}'`;
}

function slug(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}
