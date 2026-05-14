# Blacktop China Court Data Enrichment

This workflow improves China court coverage without deleting or overwriting existing `public.courts` rows.

## Why This Is Separate From OSM

OpenStreetMap is open data and can be imported under ODbL attribution. China POI coverage in OSM is incomplete, so Blacktop can use Chinese map provider APIs as candidate discovery sources.

Provider data is not the same as open data. Before production use, review the provider licence carefully, especially around caching, storage, redistribution, and showing provider-derived POI data on non-provider maps.

Recommended approach for v1:

- Use provider APIs to discover candidate courts.
- Import candidates into staging, not directly into `public.courts`.
- Merge only new points more than 30 metres away from existing courts.
- Keep `confidence = candidateImported` until manually verified.
- Preserve the source in `source`, `source_license`, `notes`, and `osm_tags_json`.

## Current China Data Shape

The current database already has tens of thousands of China courts from OSM, but most imported names are generic. The next enrichment pass should target:

- More complete city coverage.
- Real POI names.
- City / district / address metadata.
- Photo URLs only when the provider licence allows use in the app.

## 1. Get An AMap Web Service Key

Create a key in the AMap developer console and enable Web Service APIs.

Store it locally only:

```bash
export AMAP_WEB_KEY="your-amap-web-service-key"
```

Do not commit this key into the app or GitHub.

## 2. Generate A China Candidate CSV

Small test run first:

```bash
node scripts/china_amap_poi_to_supabase_csv.mjs \
  --cities "北京,上海,深圳" \
  --max-pages 5 \
  --output ~/Downloads/china_amap_test_import.csv
```

Fuller run using AMap district discovery:

```bash
node scripts/china_amap_poi_to_supabase_csv.mjs \
  --discover-cities \
  --output ~/Downloads/china_amap_courts_import.csv
```

Useful options:

```bash
--keywords "篮球场,篮球馆,篮球公园"
--types "optional-amap-poi-type-code"
--max-cities 20
--max-pages 40
--delay-ms 300
```

The script converts AMap GCJ-02 coordinates to WGS84 by default so the data aligns with the existing OSM/MapKit coordinates.

## 3. Upload CSV To Staging

The existing staging table is named `courts_osm_import_staging`, but it can also hold non-OSM candidate rows because it includes generic `source`, `source_license`, and `osm_tags_json` fields.

Make sure the staging table is empty before a new run:

```sql
truncate table public.courts_osm_import_staging;
```

Upload:

```bash
node scripts/import_staging_rest.mjs \
  --input ~/Downloads/china_amap_courts_import.csv \
  --country CN \
  --batch-size 500
```

## 4. Inspect Staging Before Merge

```sql
select
  country_code,
  source,
  count(*) as staging_rows,
  count(distinct id) as distinct_rows,
  count(*) - count(distinct id) as duplicate_ids,
  count(*) filter (where name ilike 'Basketball court%') as generic_names,
  count(*) filter (where photo_url is not null and photo_url <> '') as rows_with_photo_url
from public.courts_osm_import_staging
group by country_code, source
order by country_code, source;
```

Preview duplicates against existing `public.courts` within 30 metres:

```sql
select
  s.id as staging_id,
  s.name as staging_name,
  c.id as existing_id,
  c.name as existing_name,
  round(extensions.st_distance(
    extensions.st_setsrid(extensions.st_makepoint(s.longitude, s.latitude), 4326)::extensions.geography,
    c.location
  )) as distance_m
from public.courts_osm_import_staging s
join public.courts c
  on c.country_code = s.country_code
 and c.location is not null
 and extensions.st_dwithin(
   c.location,
   extensions.st_setsrid(extensions.st_makepoint(s.longitude, s.latitude), 4326)::extensions.geography,
   30
 )
where c.id <> s.id
order by distance_m asc, s.id
limit 100;
```

## 5. Merge Into `public.courts`

This function inserts only rows that are not already present and are not within 30 metres of an existing same-country court.

```sql
select * from public.merge_osm_staging_into_courts(30);
```

Then normalize display names:

```sql
select public.normalize_imported_court_names('CN');
```

Check the result:

```sql
select
  country_code,
  source,
  count(*) as courts,
  count(*) filter (where confidence = 'candidateImported') as candidates,
  count(*) filter (where name ilike 'Basketball court%') as generic_names
from public.courts
where country_code = 'CN'
group by country_code, source
order by source;
```

Clear staging after a successful merge:

```sql
truncate table public.courts_osm_import_staging;
```

## Production Notes

For App Store release, keep browsing free and clear, but do not imply candidate POIs are verified courts. In the app, candidate-imported China rows should show copy like:

> Candidate court data from map-provider POI search. Details may be incomplete until verified by Blacktop.

Do not use provider photo URLs in the app unless the provider licence explicitly allows storing and displaying those images in Blacktop.
