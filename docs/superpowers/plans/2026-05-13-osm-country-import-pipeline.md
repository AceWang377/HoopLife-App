# OSM Country Import Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a repeatable HoopLife OSM country import pipeline that cleans country data, stages it in Supabase, and safely merges only new courts into `public.courts`.

**Architecture:** Keep data import separate from the app runtime. A Node script orchestrates download/filter/export/CSV conversion and optionally calls `psql` for staging and merge. SQL files are split into staging creation and merge so existing `public.courts` rows are never deleted.

**Tech Stack:** Node.js built-ins, `curl`, optional `osmium-tool`, optional `psql`, Supabase Postgres/PostGIS.

---

### Task 1: Split Supabase Import SQL

**Files:**
- Create: `supabase/osm_country_import_staging_create.sql`
- Create: `supabase/osm_country_import_merge.sql`

- [ ] Create a staging setup file that drops and recreates only `public.courts_osm_import_staging`.
- [ ] Create a merge file that previews staging rows, inserts deduped rows into `public.courts`, and reports final country coverage.
- [ ] Ensure the merge checks both stable OSM `id` and nearby existing courts within 12 metres.

### Task 2: Add Local Import Pipeline Script

**Files:**
- Create: `scripts/osm_country_import_pipeline.mjs`

- [ ] Parse country import arguments such as `--country`, `--name`, `--geofabrik-url`, `--input-geojson`, `--workdir`, `--batch`, and optional `--db-url`.
- [ ] If a Geofabrik URL is provided, download the PBF with `curl`.
- [ ] If a PBF is available, require `osmium` and filter basketball-tagged objects locally.
- [ ] Export filtered PBF to GeoJSON.
- [ ] Run `scripts/osm_geojson_to_supabase_csv.mjs` to generate a HoopLife CSV.
- [ ] If no database URL is provided, stop after CSV generation and print safe manual import instructions.
- [ ] If a database URL is provided, require `psql`, create staging, import CSV with `\copy`, and run merge SQL.

### Task 3: Improve Import Names

**Files:**
- Modify: `scripts/osm_geojson_to_supabase_csv.mjs`

- [ ] Add `--name-style place-postcode`.
- [ ] Format imported names as `[place] basketball court · [postcode]` when a real OSM name/operator/street/neighbourhood exists.
- [ ] Preserve stable OSM ids.

### Task 4: Document and Verify

**Files:**
- Modify: `docs/eu-us-osm-import.md`

- [ ] Add a pipeline example for France.
- [ ] Run `node --check` on both scripts.
- [ ] Run a small local Polygon GeoJSON conversion test.
- [ ] Commit and push the changes.
