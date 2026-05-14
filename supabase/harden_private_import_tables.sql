-- Keep Blacktop import/enrichment work tables private.
-- The public app only needs SELECT on public.courts plus RPC execute grants.

revoke all privileges on table public.court_name_enrichment from anon, authenticated;
revoke all privileges on table public.courts_osm_import_staging from anon, authenticated;
revoke all privileges on sequence public.courts_osm_import_staging_staging_row_id_seq from anon, authenticated;

alter table public.court_name_enrichment enable row level security;
alter table public.courts_osm_import_staging enable row level security;
