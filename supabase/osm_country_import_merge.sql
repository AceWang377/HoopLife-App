-- Preview and safely merge public.courts_osm_import_staging into public.courts.
--
-- Safe boundary:
-- - Inserts only rows not already present by stable OSM id.
-- - Skips rows within 12 metres of an existing court in the same country.
-- - Does not delete or overwrite existing public.courts rows.

create extension if not exists postgis with schema extensions;

select
  country_code,
  count(*) as staging_rows,
  count(distinct id) as distinct_osm_rows,
  count(*) - count(distinct id) as duplicate_rows_in_staging,
  count(*) filter (where latitude is null or longitude is null) as missing_coordinates
from public.courts_osm_import_staging
group by country_code
order by country_code;

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
   12
 )
where c.id <> s.id
order by distance_m asc, s.id
limit 100;

with deduped_staging as (
  select distinct on (id)
    *
  from public.courts_osm_import_staging
  order by id, staging_row_id
),
inserted as (
  insert into public.courts (
    id,
    name,
    area,
    city,
    country_code,
    latitude,
    longitude,
    source,
    source_license,
    confidence,
    last_checked_at,
    court_type,
    access_type,
    price_type,
    has_lights,
    dryness_after_rain,
    slippery_when_wet,
    rain_playable,
    surface_type,
    surface_condition,
    court_cleanliness,
    court_space,
    runoff_safety,
    peak_times,
    has_nets,
    rim_height,
    rim_type,
    backboard_condition,
    rim_condition,
    hoop_count,
    opening_hours,
    evening_access,
    has_toilets,
    has_drinking_water,
    has_parking,
    has_changing_rooms,
    good_for_solo,
    good_for_pickup,
    good_for_training,
    beginner_friendly,
    notes,
    photo_asset_name,
    photo_url,
    osm_type,
    osm_id,
    osm_ref,
    osm_tags_json,
    import_batch
  )
  select
    s.id,
    s.name,
    s.area,
    s.city,
    s.country_code,
    s.latitude,
    s.longitude,
    s.source,
    s.source_license,
    s.confidence,
    s.last_checked_at,
    s.court_type,
    s.access_type,
    s.price_type,
    s.has_lights,
    s.dryness_after_rain,
    s.slippery_when_wet,
    s.rain_playable,
    s.surface_type,
    s.surface_condition,
    s.court_cleanliness,
    s.court_space,
    s.runoff_safety,
    s.peak_times,
    s.has_nets,
    s.rim_height,
    s.rim_type,
    s.backboard_condition,
    s.rim_condition,
    s.hoop_count,
    s.opening_hours,
    s.evening_access,
    s.has_toilets,
    s.has_drinking_water,
    s.has_parking,
    s.has_changing_rooms,
    s.good_for_solo,
    s.good_for_pickup,
    s.good_for_training,
    s.beginner_friendly,
    s.notes,
    s.photo_asset_name,
    s.photo_url,
    s.osm_type,
    s.osm_id,
    s.osm_ref,
    s.osm_tags_json,
    s.import_batch
  from deduped_staging s
  where not exists (
      select 1
      from public.courts c
      where c.id = s.id
    )
    and not exists (
      select 1
      from public.courts c
      where c.country_code = s.country_code
        and c.location is not null
        and extensions.st_dwithin(
          c.location,
          extensions.st_setsrid(extensions.st_makepoint(s.longitude, s.latitude), 4326)::extensions.geography,
          12
        )
    )
  returning country_code
)
select
  country_code,
  count(*) as inserted_rows
from inserted
group by country_code
order by country_code;

select
  country_code,
  count(*) as courts
from public.courts
group by country_code
order by country_code;
