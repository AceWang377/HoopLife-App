-- Recreate only the temporary OSM import staging table.
--
-- Safe boundary:
-- - This drops public.courts_osm_import_staging only.
-- - It does not delete, truncate, or update public.courts.

create extension if not exists postgis with schema extensions;

drop table if exists public.courts_osm_import_staging;

create table public.courts_osm_import_staging (
  staging_row_id bigserial primary key,
  id text not null,
  name text not null,
  area text not null default 'Unknown area',
  city text not null default 'Unknown city',
  country_code text not null,
  latitude double precision not null,
  longitude double precision not null,
  source text not null default 'openStreetMap',
  source_license text not null default 'ODbL - OpenStreetMap contributors',
  confidence text not null default 'imported',
  last_checked_at text not null default 'Imported',
  court_type text not null default 'unknown',
  access_type text not null default 'unknown',
  price_type text not null default 'unknown',
  has_lights text not null default 'unknown',
  dryness_after_rain text not null default 'unknown',
  slippery_when_wet text not null default 'unknown',
  rain_playable text not null default 'unknown',
  surface_type text not null default 'unknown',
  surface_condition text not null default 'unknown',
  court_cleanliness text not null default 'unknown',
  court_space text not null default 'unknown',
  runoff_safety text not null default 'unknown',
  peak_times text not null default '{unknown}',
  has_nets text not null default 'unknown',
  rim_height text not null default 'unknown',
  rim_type text not null default 'unknown',
  backboard_condition text not null default 'unknown',
  rim_condition text not null default 'unknown',
  hoop_count integer,
  opening_hours text not null default 'Access not confirmed',
  evening_access text not null default 'unknown',
  has_toilets text not null default 'unknown',
  has_drinking_water text not null default 'unknown',
  has_parking text not null default 'unknown',
  has_changing_rooms text not null default 'unknown',
  good_for_solo text not null default 'unknown',
  good_for_pickup text not null default 'unknown',
  good_for_training text not null default 'unknown',
  beginner_friendly text not null default 'unknown',
  notes text not null default '',
  photo_asset_name text,
  photo_url text,
  osm_type text,
  osm_id text,
  osm_ref text,
  osm_tags_json jsonb,
  import_batch text
);

create index if not exists courts_osm_import_staging_id_idx
on public.courts_osm_import_staging (id);

create index if not exists courts_osm_import_staging_country_idx
on public.courts_osm_import_staging (country_code);
