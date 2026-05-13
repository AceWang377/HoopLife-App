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
