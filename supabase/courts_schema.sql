create table if not exists public.courts (
  id text primary key,
  name text not null,
  area text not null default 'Unknown area',
  city text not null default 'UK',
  latitude double precision not null,
  longitude double precision not null,
  source text not null default 'openStreetMap',
  source_license text not null,
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
  import_batch text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists courts_city_idx on public.courts (city);
create index if not exists courts_confidence_idx on public.courts (confidence);
create index if not exists courts_source_idx on public.courts (source);
create index if not exists courts_osm_ref_idx on public.courts (osm_ref);
create index if not exists courts_lat_lng_idx on public.courts (latitude, longitude);

alter table public.courts enable row level security;

drop policy if exists "Courts are publicly readable" on public.courts;
create policy "Courts are publicly readable"
on public.courts
for select
to anon, authenticated
using (true);
