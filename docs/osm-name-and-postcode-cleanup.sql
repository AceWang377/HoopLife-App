-- Optional cleanup for existing OpenStreetMap rows already imported into Supabase.
-- This keeps the stable id, osm_id, and osm_ref, but replaces synthetic display
-- names such as "OSM Basketball Court 12345" when OSM tags contain better data.

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
      when nullif(osm_ref, '') is not null
        then 'Basketball court (' || osm_ref || ')'
    end,
    name
  ),
  area = case
    when lower(area) in ('uk', 'unknown area', '') then coalesce(
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
    when lower(city) in ('uk', '') then coalesce(
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
    or lower(area) in ('uk', 'unknown area', '')
    or lower(city) in ('uk', '')
  );
