# Supabase OSM CSV Import

Use `scripts/osm_geojson_to_supabase_csv.mjs` to convert an Overpass Turbo or Geofabrik/osmium GeoJSON export into a Supabase-ready CSV.

For large country imports, prefer `scripts/osm_country_import_pipeline.mjs`. It automates download, local OSM filtering, CSV conversion, and optionally staging + merge.

## 1. Export From Overpass Turbo

For UK-wide candidates, use a broad query like this in Overpass Turbo:

```overpass
[out:json][timeout:180];
area["ISO3166-1"="GB"][admin_level=2]->.uk;
(
  nwr["sport"~"(^|;)basketball(;|$)"](area.uk);
  nwr["leisure"="pitch"]["sport"~"(^|;)basketball(;|$)"](area.uk);
  nwr["leisure"="sports_centre"]["sport"~"(^|;)basketball(;|$)"](area.uk);
);
out center tags;
```

Then export as GeoJSON.

For the first production pass, city-by-city exports are easier to inspect than one huge UK file.

## 2. Convert To CSV

```bash
node scripts/osm_geojson_to_supabase_csv.mjs \
  --input /path/to/export.geojson \
  --output /path/to/courts_import.csv \
  --city "Sheffield" \
  --area "Sheffield" \
  --country "GB" \
  --batch 2026-05-12
```

Use `--named-only` if you want to skip OSM features without a `name` tag.
Use `--name-style place-postcode` if you want names like `[place] basketball court · [postcode]`.

## 2A. Automated Country Pipeline

Generate a cleaned France CSV without touching Supabase:

```bash
node scripts/osm_country_import_pipeline.mjs \
  --country FR \
  --name "France" \
  --geofabrik-url "https://download.geofabrik.de/europe/france-latest.osm.pbf" \
  --batch 2026-05-13
```

If you have a Postgres connection string and `psql` installed, the same pipeline can safely import into staging and merge only new courts:

```bash
export SUPABASE_DATABASE_URL='postgresql://...'

node scripts/osm_country_import_pipeline.mjs \
  --country FR \
  --name "France" \
  --geofabrik-url "https://download.geofabrik.de/europe/france-latest.osm.pbf" \
  --batch 2026-05-13 \
  --apply
```

The dashboard schema URL is not a database URL. In Supabase, use Project Settings → Database → Connection string.

## 3. Supabase Table Shape

The CSV uses snake_case columns. A future `courts` table should include these core columns:

- `id`
- `name`
- `area`
- `city`
- `country_code`
- `latitude`
- `longitude`
- `source`
- `source_license`
- `confidence`
- `court_type`
- `access_type`
- `price_type`
- `has_lights`
- `surface_type`
- `hoop_count`
- `opening_hours`
- `notes`
- `osm_type`
- `osm_id`
- `osm_ref`
- `osm_tags_json`
- `import_batch`

The script also outputs Blacktop manual-fact columns such as `dryness_after_rain`, `has_nets`, `rim_height`, `rim_type`, and `court_cleanliness`. These default to `unknown` because OSM usually cannot confirm them.

## 4. Import Rules

- Keep all imported rows as `confidence = imported`.
- Set `country_code` for every import, for example `GB` for the UK and `CN` for China.
- Do not mark a court as `verified` until you manually check it.
- Keep `source_license = ODbL - OpenStreetMap contributors`.
- Preserve `osm_ref` and `osm_tags_json` so every imported row is traceable.
- Use the default image in the app until a court has a real photo.

## 5. Recommended Workflow

1. Export OSM GeoJSON for one city.
2. Convert to CSV.
3. Import into `public.courts_osm_import_staging`.
4. Inspect noisy rows and duplicates.
5. Run `supabase/osm_country_import_merge.sql` to safely insert only new rows into `public.courts`.
6. In the app, show `imported` records clearly as needing Blacktop review.
