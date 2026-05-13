-- HoopLife global court scaling setup.
--
-- Run this in Supabase SQL Editor before importing additional countries.
-- It keeps the public app read-only while adding:
-- - country_code for country partitioning/filtering
-- - PostGIS location for scalable map queries
-- - courts_in_view RPC for viewport-based mobile loading

create extension if not exists postgis with schema extensions;

alter table public.courts
add column if not exists country_code text not null default 'GB';

alter table public.courts
add column if not exists location extensions.geography(Point, 4326);

update public.courts
set country_code = 'GB'
where country_code is null or country_code = '';

update public.courts
set location = extensions.st_setsrid(
  extensions.st_makepoint(longitude, latitude),
  4326
)::extensions.geography
where location is null
  and latitude is not null
  and longitude is not null;

create or replace function public.set_court_location()
returns trigger
language plpgsql
set search_path = public, extensions
as $$
begin
  if new.country_code is null or new.country_code = '' then
    new.country_code := 'GB';
  end if;

  if new.latitude is not null and new.longitude is not null then
    new.location := extensions.st_setsrid(
      extensions.st_makepoint(new.longitude, new.latitude),
      4326
    )::extensions.geography;
  end if;

  return new;
end;
$$;

drop trigger if exists set_court_location_before_write on public.courts;

create trigger set_court_location_before_write
before insert or update of latitude, longitude, country_code
on public.courts
for each row
execute function public.set_court_location();

create index if not exists courts_country_lat_lng_idx
on public.courts (country_code, latitude, longitude);

create index if not exists courts_location_gix
on public.courts
using gist (location);

create index if not exists courts_country_city_name_idx
on public.courts (country_code, city, name);

create or replace function public.courts_in_view(
  min_lat double precision,
  min_lng double precision,
  max_lat double precision,
  max_lng double precision,
  limit_count integer default 600,
  country_code_filter text default null
)
returns table (
  id text,
  name text,
  area text,
  city text,
  latitude double precision,
  longitude double precision,
  source text,
  source_license text,
  confidence text,
  last_checked_at text,
  court_type text,
  access_type text,
  price_type text,
  has_lights text,
  dryness_after_rain text,
  slippery_when_wet text,
  rain_playable text,
  surface_type text,
  surface_condition text,
  court_cleanliness text,
  court_space text,
  runoff_safety text,
  peak_times text,
  has_nets text,
  rim_height text,
  rim_type text,
  backboard_condition text,
  rim_condition text,
  hoop_count integer,
  opening_hours text,
  evening_access text,
  has_toilets text,
  has_drinking_water text,
  has_parking text,
  has_changing_rooms text,
  good_for_solo text,
  good_for_pickup text,
  good_for_training text,
  beginner_friendly text,
  notes text,
  photo_asset_name text,
  osm_ref text,
  osm_tags_json jsonb
)
language sql
stable
security invoker
set search_path = public, extensions
as $$
  with request_bounds as (
    select
      least(min_lat, max_lat) as south,
      greatest(min_lat, max_lat) as north,
      least(min_lng, max_lng) as west,
      greatest(min_lng, max_lng) as east,
      extensions.st_setsrid(
        extensions.st_makepoint((min_lng + max_lng) / 2, (min_lat + max_lat) / 2),
        4326
      )::extensions.geography as center_point
  )
  select
    c.id,
    c.name,
    c.area,
    c.city,
    c.latitude,
    c.longitude,
    c.source,
    c.source_license,
    c.confidence,
    c.last_checked_at,
    c.court_type,
    c.access_type,
    c.price_type,
    c.has_lights,
    c.dryness_after_rain,
    c.slippery_when_wet,
    c.rain_playable,
    c.surface_type,
    c.surface_condition,
    c.court_cleanliness,
    c.court_space,
    c.runoff_safety,
    c.peak_times,
    c.has_nets,
    c.rim_height,
    c.rim_type,
    c.backboard_condition,
    c.rim_condition,
    c.hoop_count,
    c.opening_hours,
    c.evening_access,
    c.has_toilets,
    c.has_drinking_water,
    c.has_parking,
    c.has_changing_rooms,
    c.good_for_solo,
    c.good_for_pickup,
    c.good_for_training,
    c.beginner_friendly,
    c.notes,
    c.photo_asset_name,
    c.osm_ref,
    c.osm_tags_json
  from public.courts c
  cross join request_bounds b
  where c.latitude between b.south and b.north
    and c.longitude between b.west and b.east
    and (country_code_filter is null or c.country_code = country_code_filter)
  order by
    case when c.location is null then 1 else 0 end,
    c.location <-> b.center_point,
    c.name
  limit least(greatest(coalesce(limit_count, 600), 1), 700);
$$;

grant execute on function public.courts_in_view(
  double precision,
  double precision,
  double precision,
  double precision,
  integer,
  text
) to anon, authenticated;

-- Smoke test around Sheffield.
select count(*)
from public.courts_in_view(53.30, -1.60, 53.46, -1.35, 600, 'GB');
