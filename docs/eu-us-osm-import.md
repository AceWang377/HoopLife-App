# HoopLife EU and US OSM Import Commands

Run `supabase/global_court_scaling.sql` first.
Run `supabase/osm_country_import_staging.sql` before each CSV import so the staging table is clean.

Do not import generated OSM CSV files directly into `public.courts`.
Import them into:

```text
public.courts_osm_import_staging
```

Then run the preview and merge SQL in `supabase/osm_country_import_staging.sql`.

## United States

US-wide Overpass exports can be too large. Prefer state-by-state imports.

### Overpass Template For One US State

Replace `US-CA` and `California`.

```overpass
[out:json][timeout:240];
area["ISO3166-2"="US-CA"][admin_level=4]->.searchArea;
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
  --input ~/Downloads/us_ca_basketball.geojson \
  --output ~/Downloads/us_ca_courts_import.csv \
  --city "California" \
  --area "California" \
  --country "US" \
  --batch 2026-05-13
```

Import `us_ca_courts_import.csv` into `public.courts_osm_import_staging`, preview, then merge.

### US State Codes

Use these `ISO3166-2` values:

```text
US-AL US-AK US-AZ US-AR US-CA US-CO US-CT US-DE US-FL US-GA
US-HI US-ID US-IL US-IN US-IA US-KS US-KY US-LA US-ME US-MD
US-MA US-MI US-MN US-MS US-MO US-MT US-NE US-NV US-NH US-NJ
US-NM US-NY US-NC US-ND US-OH US-OK US-OR US-PA US-RI US-SC
US-SD US-TN US-TX US-UT US-VT US-VA US-WA US-WV US-WI US-WY
US-DC
```

## European Union

There is no single reliable `ISO3166-1=EU` country area in OSM. Import EU country-by-country.

For large countries such as France, Germany, Spain, and Italy, Overpass Turbo can time out or return only a partial practical export. For a fuller country import, prefer the Geofabrik PBF workflow below.

### Fuller France Import With Geofabrik PBF

Use this when a country-wide Overpass query returns too few records or times out.

#### Recommended: HoopLife Pipeline Script

The pipeline script runs the repetitive download, filter, export, and CSV conversion steps for you.
By default it only creates the cleaned CSV and does not touch Supabase.

```bash
node scripts/osm_country_import_pipeline.mjs \
  --country FR \
  --name "France" \
  --geofabrik-url "https://download.geofabrik.de/europe/france-latest.osm.pbf" \
  --batch 2026-05-13
```

If `SUPABASE_DATABASE_URL` is set and PostgreSQL `psql` is installed, add `--apply` to recreate the staging table, copy the CSV into staging, and safely merge new courts into `public.courts`:

```bash
export SUPABASE_DATABASE_URL='postgresql://...'

node scripts/osm_country_import_pipeline.mjs \
  --country FR \
  --name "France" \
  --geofabrik-url "https://download.geofabrik.de/europe/france-latest.osm.pbf" \
  --batch 2026-05-13 \
  --apply
```

The automated merge does not delete or overwrite existing rows in `public.courts`.
It skips existing stable OSM ids and courts within 12 metres of an existing court in the same country.

#### Manual Commands

1. Install `osmium-tool`:

```bash
brew install osmium-tool
```

2. Download the France PBF from Geofabrik:

```bash
curl -L \
  -o ~/Downloads/france-latest.osm.pbf \
  https://download.geofabrik.de/europe/france-latest.osm.pbf
```

3. Filter basketball-tagged OSM objects locally:

```bash
osmium tags-filter \
  ~/Downloads/france-latest.osm.pbf \
  n/sport=basketball w/sport=basketball r/sport=basketball \
  n/basketball=yes w/basketball=yes r/basketball=yes \
  n/hoops w/hoops r/hoops \
  n/basketball:hoops w/basketball:hoops r/basketball:hoops \
  -o ~/Downloads/france_basketball.osm.pbf \
  --overwrite
```

4. Export the filtered objects to GeoJSON with OSM attributes preserved:

```bash
osmium export \
  ~/Downloads/france_basketball.osm.pbf \
  --attributes=type,id \
  -o ~/Downloads/france_basketball.geojson \
  --overwrite
```

5. Convert to HoopLife CSV:

```bash
node scripts/osm_geojson_to_supabase_csv.mjs \
  --input ~/Downloads/france_basketball.geojson \
  --output ~/Downloads/france_courts_import.csv \
  --city "France" \
  --area "France" \
  --country "FR" \
  --batch 2026-05-13 \
  --name-style place-postcode
```

6. Import `france_courts_import.csv` into `public.courts_osm_import_staging`, preview, then merge.

This workflow avoids Overpass API timeouts because the expensive filtering happens on your Mac. It still only returns courts that are actually tagged in OpenStreetMap; OSM cannot provide courts that no mapper has added or tagged as basketball-related.

### Overpass Template For One EU Country

Replace `FR` and `France`.

```overpass
[out:json][timeout:240];
area["ISO3166-1"="FR"][admin_level=2]->.searchArea;
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
  --input ~/Downloads/france_basketball.geojson \
  --output ~/Downloads/france_courts_import.csv \
  --city "France" \
  --area "France" \
  --country "FR" \
  --batch 2026-05-13
```

Import `france_courts_import.csv` into `public.courts_osm_import_staging`, preview, then merge.

### EU Country Codes

Current EU member ISO country codes:

```text
AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL
PL PT RO SK SI ES SE
```

Recommended order for large first pass:

```text
FR DE ES IT NL PL BE SE DK IE PT AT CZ FI GR RO HU
```

Then continue with the remaining smaller countries.

## Merge Checklist For Every File

1. Run `supabase/osm_country_import_staging.sql` to recreate a clean staging table.
2. Import one generated CSV into `public.courts_osm_import_staging`.
3. Check the preview counts.
4. Check likely duplicate rows.
5. Run the merge section.
6. Check final country coverage.

If Supabase import fails with a duplicate id, recreate the staging table with the latest SQL in `supabase/osm_country_import_staging.sql`. The latest staging table uses `staging_row_id` as the primary key and allows repeated OSM ids during upload.
