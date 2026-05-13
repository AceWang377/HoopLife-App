# HoopLife Global Court Data Scaling

This is the required setup before adding countries beyond the UK.

## 1. Run Supabase Scaling SQL

Run this file in Supabase SQL Editor:

```text
supabase/global_court_scaling.sql
```

It adds:

- `country_code`
- PostGIS `location`
- spatial indexes
- `public.courts_in_view(...)` RPC

After running it, test:

```sql
select count(*)
from public.courts_in_view(53.30, -1.60, 53.46, -1.35, 600, 'GB');
```

You should get a count, not an error.

## 2. App Reading Model

The app should not download all courts.

The production reading flow is:

1. Open map.
2. Show cached courts immediately when available.
3. Load only courts inside the current map viewport.
4. Merge fresh remote rows into the in-memory court list.
5. Save the visited court set to the local app cache.
6. User pans/zooms.
7. Show `Search this area`.
8. Load that viewport only.

The current app code now calls Supabase by map region and caps each response to a few hundred courts.
The local cache is intentionally a visited-area cache, not a full global database cache.

## 3. Importing China OSM Data

China-wide Overpass queries can time out. Prefer province-by-province or city-by-city exports.
For EU and US import templates, see `docs/eu-us-osm-import.md`.

Example broad query:

```overpass
[out:json][timeout:300];
area["ISO3166-1"="CN"][admin_level=2]->.cn;
(
  nwr["sport"~"(^|;)basketball(;|$)"](area.cn);
  nwr["leisure"="pitch"]["sport"~"(^|;)basketball(;|$)"](area.cn);
  nwr["leisure"="sports_centre"]["sport"~"(^|;)basketball(;|$)"](area.cn);
);
out center tags;
```

For city or province imports, change the area selector, for example:

```overpass
[out:json][timeout:180];
area["name"="Shanghai"]["boundary"="administrative"]->.searchArea;
(
  nwr["sport"~"(^|;)basketball(;|$)"](area.searchArea);
  nwr["leisure"="pitch"]["sport"~"(^|;)basketball(;|$)"](area.searchArea);
  nwr["leisure"="sports_centre"]["sport"~"(^|;)basketball(;|$)"](area.searchArea);
);
out center tags;
```

Export as GeoJSON, then convert:

```bash
node scripts/osm_geojson_to_supabase_csv.mjs \
  --input ~/Downloads/china_basketball.geojson \
  --output ~/Downloads/china_courts_import.csv \
  --city "China" \
  --area "China" \
  --country "CN" \
  --batch 2026-05-13
```

For city-level files, use better defaults:

```bash
node scripts/osm_geojson_to_supabase_csv.mjs \
  --input ~/Downloads/shanghai_basketball.geojson \
  --output ~/Downloads/shanghai_courts_import.csv \
  --city "Shanghai" \
  --area "Shanghai" \
  --country "CN" \
  --batch 2026-05-13
```

## 4. Import Rules

- Import new country files only after `global_court_scaling.sql` has been run.
- Import generated OSM CSV files into `public.courts_osm_import_staging`, not directly into `public.courts`.
- Use `supabase/osm_country_import_staging.sql` to create the staging table, preview duplicates, and merge approved rows.
- Keep `source_license = ODbL - OpenStreetMap contributors`.
- Keep `confidence = imported`.
- Keep `osm_type`, `osm_id`, `osm_ref`, and `osm_tags_json`.
- Use `country_code` for every row.
- Do not force postcodes for countries where the postcode source is weak or unavailable.

## 5. Stability Rules

For large datasets:

- Do not query by `limit=10000` in the app.
- Do not render every court as a map pin.
- Keep each viewport response capped to `600-700`.
- At low zoom levels, prefer city search / `Search this area` over automatic loading.
- Use staging tables for large imports, then merge into `public.courts`.

## 6. Optional Staging Table

For repeated imports, use:

```text
supabase/osm_country_import_staging.sql
```

The enrichment tables such as `court_name_enrichment` are only for updating existing names/postcodes. They are not for importing new courts.
