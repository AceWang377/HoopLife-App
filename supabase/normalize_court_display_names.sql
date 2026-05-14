-- Normalize imported court names for map display.
--
-- Goal:
-- - Never show OSM ids such as osm-way-123 or Basketball court (way/123).
-- - Prefer real OSM names.
-- - Otherwise prefer street address + postcode.
-- - Fall back to local area/city/country when OSM has no usable address.

with prepared as (
  select
    id,
    name,
    country_code,
    nullif(btrim(coalesce(osm_tags_json->>'addr:postcode', '')), '') as postcode,
    nullif(btrim(concat_ws(
      ' ',
      nullif(osm_tags_json->>'addr:housenumber', ''),
      nullif(osm_tags_json->>'addr:street', '')
    )), '') as street_address,
    nullif(btrim(coalesce(
      osm_tags_json->>'name',
      osm_tags_json->>'official_name',
      osm_tags_json->>'operator',
      ''
    )), '') as osm_place,
    nullif(btrim(coalesce(
      osm_tags_json->>'addr:neighbourhood',
      osm_tags_json->>'addr:suburb',
      osm_tags_json->>'addr:district',
      ''
    )), '') as local_area,
    nullif(btrim(coalesce(
      osm_tags_json->>'addr:city',
      osm_tags_json->>'addr:town',
      osm_tags_json->>'addr:village',
      ''
    )), '') as osm_city,
    nullif(btrim(area), '') as row_area,
    nullif(btrim(city), '') as row_city
  from public.courts
  where name ~* '^(Basketball court|OSM Basketball Court|Unnamed court)'
     or name ~* 'osm-(node|way|relation)'
     or name ~* '\((node|way|relation)/[0-9]+\)'
),
named as (
  select
    id,
    coalesce(
      case
        when lower(osm_place) not in ('basketball court', 'basketball courts', 'osm basketball court')
          then osm_place
      end,
      street_address,
      local_area,
      osm_city,
      case
        when lower(row_area) not in (
          'uk', 'united kingdom', 'france', 'china', 'netherlands',
          'luxembourg', 'belgium', 'unknown area'
        ) then row_area
      end,
      case
        when lower(row_city) not in (
          'uk', 'united kingdom', 'france', 'china', 'netherlands',
          'luxembourg', 'belgium', 'unknown city'
        ) then row_city
      end,
      case country_code
        when 'GB' then 'United Kingdom'
        when 'FR' then 'France'
        when 'CN' then 'China'
        when 'NL' then 'Netherlands'
        when 'LU' then 'Luxembourg'
        when 'BE' then 'Belgium'
        when 'DE' then 'Germany'
        when 'ES' then 'Spain'
        when 'IT' then 'Italy'
        when 'PT' then 'Portugal'
        when 'AT' then 'Austria'
        when 'CH' then 'Switzerland'
        when 'DK' then 'Denmark'
        when 'SE' then 'Sweden'
        when 'NO' then 'Norway'
        when 'FI' then 'Finland'
        when 'PL' then 'Poland'
        when 'CZ' then 'Czechia'
        when 'IE' then 'Ireland'
        else country_code
      end
    ) as place,
    postcode
  from prepared
),
formatted as (
  select
    id,
    case
      when postcode is not null
        and place ~* '(basket|basketball|court|terrain|球场|篮球|sports centre|sporthalle|halle|sporthal|sportpark)'
        then place || ' · ' || postcode
      when postcode is not null
        then place || ' basketball court · ' || postcode
      when place ~* '(basket|basketball|court|terrain|球场|篮球|sports centre|sporthalle|halle|sporthal|sportpark)'
        then place
      else 'Basketball court · ' || place
    end as new_name
  from named
),
updated as (
  update public.courts c
  set name = f.new_name,
      updated_at = now()
  from formatted f
  where c.id = f.id
    and c.name is distinct from f.new_name
  returning c.country_code
)
select country_code, count(*) as renamed_rows
from updated
group by country_code
order by country_code;
