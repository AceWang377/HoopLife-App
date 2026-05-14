# Blacktop Court Name + Postcode Enrichment

Goal:

```text
[real place name] basketball court · [postcode]
```

This workflow is for courts already imported into Supabase from OpenStreetMap.

## What Each Source Can Provide

OpenStreetMap is the best source for real place names because the imported rows already contain `osm_tags_json`. Use these fields first:

- `name`
- `official_name`
- `operator`
- `addr:housename`
- `addr:street`
- `addr:suburb`
- `addr:neighbourhood`
- `addr:postcode`

Postcodes.io is best for filling missing UK postcodes from latitude/longitude. It should not be treated as a place-name source.

Google Maps/Places can be used as a manual verification reference, but do not bulk copy Google place names/addresses into the Blacktop database.

## Step 1: Export Current Supabase Courts

In Supabase:

1. Open `Table Editor`.
2. Open `courts`.
3. Export CSV.
4. Save it locally as something like:

```text
~/Downloads/courts_export.csv
```

The CSV must include at least:

- `id`
- `name`
- `area`
- `city`
- `latitude`
- `longitude`
- `osm_tags_json`

## Step 2: Generate Enrichment CSV

From the project root:

```bash
node scripts/enrich_courts_postcodes.mjs \
  --input ~/Downloads/courts_export.csv \
  --output ~/Downloads/court_postcode_enrichment.csv \
  --chunk 100 \
  --radius 500 \
  --timeout 15000
```

For a small test run, export only 100 rows from Supabase first and run the same command.
The script prints batch progress while running. If a Postcodes.io batch times out, that batch is skipped so the whole run can still complete; you can retry the missing rows separately.

The output CSV contains:

- `id`
- `suggested_name`
- `resolved_postcode`
- `resolved_place_name`
- `postcode_source`
- `postcode_distance_m`
- `suggested_area`
- `suggested_city`

Review the output before importing it.

## Step 3: Create Staging Table in Supabase

Run this once in Supabase SQL Editor.

If you already created a failed staging table, drop and recreate it so the CSV headers match exactly.

```sql
drop table if exists public.court_name_enrichment;

create table public.court_name_enrichment (
  id text primary key,
  suggested_name text,
  resolved_postcode text,
  resolved_place_name text,
  postcode_source text,
  postcode_distance_m text,
  suggested_area text,
  suggested_city text,
  created_at timestamptz not null default now()
);
```

Then import `court_postcode_enrichment_latest.csv` into `public.court_name_enrichment`.

## Step 4: Preview the Update

Run this before updating:

```sql
select
  c.id,
  c.name as old_name,
  e.suggested_name as new_name,
  c.area as old_area,
  e.suggested_area as new_area,
  c.city as old_city,
  e.suggested_city as new_city,
  e.resolved_postcode,
  e.postcode_source,
  e.postcode_distance_m
from public.courts c
join public.court_name_enrichment e on e.id = c.id
where e.suggested_name is not null
order by e.postcode_distance_m nulls last
limit 100;
```

## Step 5: Apply the Update

This updates only OpenStreetMap rows and avoids replacing already specific names with weaker fallback names.

```sql
update public.courts c
set
  name = case
    when e.suggested_name is not null
      and e.suggested_name <> ''
      and (
        c.name ilike 'OSM Basketball Court%'
        or c.name = 'Basketball court'
        or c.name ilike 'Basketball court ·%'
        or c.name ~* '^Basketball court \((node|way|relation)/'
      )
      then e.suggested_name
    else c.name
  end,
  area = case
    when lower(coalesce(c.area, '')) in ('', 'uk', 'unknown area')
      and nullif(e.suggested_area, '') is not null
      then e.suggested_area
    else c.area
  end,
  city = case
    when lower(coalesce(c.city, '')) in ('', 'uk')
      and nullif(e.suggested_city, '') is not null
      then e.suggested_city
    else c.city
  end,
  notes = concat_ws(
    ' ',
    nullif(c.notes, ''),
    case
      when nullif(e.resolved_postcode, '') is not null
        then 'Nearest postcode: ' || e.resolved_postcode || ' (' || e.postcode_source || ').'
    end
  ),
  updated_at = now()
from public.court_name_enrichment e
where c.id = e.id
  and c.source = 'openStreetMap';
```

## Step 6: Check Results

```sql
select
  count(*) as total_courts,
  count(*) filter (where name ilike 'OSM Basketball Court%') as remaining_osm_names,
  count(*) filter (where name ilike '% · %') as names_with_postcode,
  count(*) filter (where lower(coalesce(city, '')) = 'uk') as remaining_unknown_city,
  count(*) filter (where lower(coalesce(area, '')) in ('uk', 'unknown area', '')) as remaining_unknown_area
from public.courts;
```

## Getting Better Place Names From OSM

If many courts still become only `Basketball court · [postcode]`, that means OSM has no court-level name.

The next enrichment pass should query nearby named OSM parent places, for example:

- park
- recreation ground
- sports centre
- school
- community centre
- leisure centre

Those inferred names should be stored as lower-confidence suggestions, not treated as confirmed court names.
