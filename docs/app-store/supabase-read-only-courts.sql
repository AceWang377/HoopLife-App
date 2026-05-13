-- HoopLife read-only public court data policy.
-- Applied to Supabase project mcvqmgzsklltrikuuigh on May 13, 2026.
-- Keep this file as the release record for the App Store 1.0 data access model.

revoke insert, update, delete, truncate, references, trigger
on table public.courts
from anon, authenticated;

grant select
on table public.courts
to anon, authenticated;

alter table public.courts enable row level security;

drop policy if exists "Courts are publicly readable" on public.courts;

create policy "Courts are publicly readable"
on public.courts
for select
to anon, authenticated
using (true);
