# Blacktop Supabase Import

## Files

- `courts_schema.sql`: creates the first public `courts` table.
- `imports/uk_osm_courts_2026-05-12.csv`: UK OpenStreetMap basketball court candidate import.

## Import Steps

1. Open your Supabase project.
2. Go to `SQL Editor`.
3. Run `supabase/courts_schema.sql`.
4. Go to `Table Editor` -> `courts`.
5. Click `Insert` -> `Import data from CSV`.
6. Upload `supabase/imports/uk_osm_courts_2026-05-12.csv`.
7. Confirm the columns match.
8. Import.

## Important

All imported rows use:

- `source = openStreetMap`
- `confidence = imported`
- `source_license = ODbL - OpenStreetMap contributors`

Do not mark OSM rows as `verified` until you manually check them.

The table is publicly readable, but write access is not enabled. That fits the current Blacktop v1 plan: no login needed for browsing, no public user submissions yet.
