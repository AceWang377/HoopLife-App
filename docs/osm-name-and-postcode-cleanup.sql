-- Optional cleanup for existing OpenStreetMap rows already imported into Supabase.
--
-- Important:
-- - Keep id, osm_id, and osm_ref stable. They are identifiers, not display names.
-- - Only update name/area/city for better user-facing display.
-- - OSM often has no real court name. In that case this uses operator, postcode,
--   street, suburb, area, or a neutral "Basketball court" fallback.

update public.courts
set
  name = coalesce(
    nullif(osm_tags_json->>'name', ''),
    nullif(osm_tags_json->>'official_name', ''),
    case
      when nullif(osm_tags_json->>'operator', '') is not null
        then (osm_tags_json->>'operator') || ' basketball court'
    end,
    case
      when nullif(osm_tags_json->>'addr:postcode', '') is not null
        then 'Basketball court near ' || (osm_tags_json->>'addr:postcode')
    end,
    case
      when nullif(osm_tags_json->>'addr:street', '') is not null
        then 'Basketball court near ' || (osm_tags_json->>'addr:street')
    end,
    case
      when nullif(osm_tags_json->>'addr:suburb', '') is not null
        then 'Basketball court in ' || (osm_tags_json->>'addr:suburb')
    end,
    case
      when nullif(osm_tags_json->>'addr:neighbourhood', '') is not null
        then 'Basketball court in ' || (osm_tags_json->>'addr:neighbourhood')
    end,
    case
      when lower(coalesce(area, '')) not in ('', 'uk', 'unknown area')
        then 'Basketball court in ' || area
    end,
    case
      when lower(coalesce(city, '')) not in ('', 'uk')
        then 'Basketball court in ' || city
    end,
    'Basketball court'
  ),
  area = case
    when lower(coalesce(area, '')) in ('', 'uk', 'unknown area') then coalesce(
      nullif(osm_tags_json->>'addr:suburb', ''),
      nullif(osm_tags_json->>'addr:neighbourhood', ''),
      nullif(osm_tags_json->>'addr:district', ''),
      nullif(osm_tags_json->>'addr:street', ''),
      nullif(osm_tags_json->>'operator', ''),
      area
    )
    else area
  end,
  city = case
    when lower(coalesce(city, '')) in ('', 'uk') then coalesce(
      nullif(osm_tags_json->>'addr:city', ''),
      nullif(osm_tags_json->>'addr:town', ''),
      nullif(osm_tags_json->>'addr:village', ''),
      city
    )
    else city
  end,
  updated_at = now()
where source = 'openStreetMap'
  and osm_tags_json is not null
  and (
    name ilike 'OSM Basketball Court%'
    or name ilike 'node-%'
    or name ilike 'way-%'
    or name ilike 'relation-%'
    or name ~* '^Basketball court \((node|way|relation)/'
    or lower(coalesce(area, '')) in ('uk', 'unknown area', '')
    or lower(coalesce(city, '')) in ('uk', '')
  );

-- Check remaining synthetic names after the cleanup.
select
  count(*) as total_courts,
  count(*) filter (
    where name ilike 'OSM Basketball Court%'
      or name ilike 'node-%'
      or name ilike 'way-%'
      or name ilike 'relation-%'
      or name ~* '^Basketball court \((node|way|relation)/'
  ) as remaining_synthetic_names,
  count(*) filter (where osm_tags_json ? 'name' or osm_tags_json ? 'official_name') as rows_with_osm_name,
  count(*) filter (where osm_tags_json ? 'addr:postcode') as rows_with_postcode,
  count(*) filter (where osm_tags_json ? 'addr:street') as rows_with_street
from public.courts;
