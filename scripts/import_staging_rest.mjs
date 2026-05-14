#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const DEFAULT_BATCH_SIZE = 500;
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const args = parseArgs(process.argv.slice(2));

if (args.help || !args.input) {
  printHelp();
  process.exit(args.help ? 0 : 1);
}

const inputPath = path.resolve(args.input);
const batchSize = Number(args.batchSize || DEFAULT_BATCH_SIZE);
const expectedCountry = args.country?.toUpperCase();
const { projectURL, publishableKey } = resolveSupabaseConfig();

const rows = parseCSV(fs.readFileSync(inputPath, "utf8"))
  .map(normalizeRow)
  .filter((row) => !expectedCountry || row.country_code === expectedCountry);

if (!rows.length) {
  throw new Error(`No rows found${expectedCountry ? ` for country ${expectedCountry}` : ""}.`);
}

console.log(`Uploading ${rows.length} rows to courts_osm_import_staging`);
console.log(`Project: ${projectURL.host}`);
console.log(`CSV: ${inputPath}`);

for (let index = 0; index < rows.length; index += batchSize) {
  const batch = rows.slice(index, index + batchSize);
  const response = await fetch(new URL("/rest/v1/courts_osm_import_staging", projectURL), {
    method: "POST",
    headers: {
      apikey: publishableKey,
      authorization: `Bearer ${publishableKey}`,
      "content-type": "application/json",
      prefer: "return=minimal"
    },
    body: JSON.stringify(batch)
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Batch ${Math.floor(index / batchSize) + 1} failed: ${response.status} ${response.statusText}\n${body}`);
  }

  console.log(`Uploaded ${Math.min(index + batch.length, rows.length)}/${rows.length}`);
}

console.log("Upload complete.");

function resolveSupabaseConfig() {
  const envURL = process.env.SUPABASE_URL || process.env.BLACKTOP_SUPABASE_URL;
  const envKey = process.env.SUPABASE_PUBLISHABLE_KEY || process.env.BLACKTOP_SUPABASE_PUBLISHABLE_KEY;
  if (envURL && envKey) {
    return { projectURL: new URL(envURL), publishableKey: envKey };
  }

  const servicePath = path.join(repoRoot, "Blacktop", "Data", "SupabaseCourtService.swift");
  const source = fs.readFileSync(servicePath, "utf8");
  const url = source.match(/projectURL\s*=\s*URL\(string:\s*"([^"]+)"/)?.[1];
  const key = source.match(/publishableKey\s*=\s*"([^"]+)"/)?.[1];

  if (!url || !key) {
    throw new Error("Missing Supabase config. Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.");
  }

  return { projectURL: new URL(url), publishableKey: key };
}

function normalizeRow(row) {
  const normalized = {};
  for (const [key, value] of Object.entries(row)) {
    if (key === "hoop_count") {
      normalized[key] = value === "" ? null : Number(value);
    } else if (key === "latitude" || key === "longitude") {
      normalized[key] = Number(value);
    } else if (key === "osm_tags_json") {
      normalized[key] = parseJSON(value);
    } else {
      normalized[key] = value;
    }
  }
  return normalized;
}

function parseJSON(value) {
  if (!value) return null;
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
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

function parseArgs(rawArgs) {
  const parsed = {};
  for (let index = 0; index < rawArgs.length; index += 1) {
    const arg = rawArgs[index];
    if (arg === "--help" || arg === "-h") parsed.help = true;
    else if (arg === "--input" || arg === "-i") parsed.input = rawArgs[++index];
    else if (arg === "--country") parsed.country = rawArgs[++index];
    else if (arg === "--batch-size") parsed.batchSize = rawArgs[++index];
    else if (!parsed.input) parsed.input = arg;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return parsed;
}

function printHelp() {
  console.log(`
Usage:
  node scripts/import_staging_rest.mjs --input ~/Downloads/netherlands_courts_import.csv --country NL

Notes:
  - Run a temporary insert policy on public.courts_osm_import_staging first.
  - This script uploads to staging only; it does not merge into public.courts.
`);
}
