# HoopLife Manual Court Audit Workflow

## Goal

Keep v1 simple: users can browse courts without logging in, while the owner manually verifies and updates court facts.

## Recommended v1 Flow

1. Find a court candidate from OSM, Google Maps, council pages, leisure-centre pages, or local knowledge.
2. Confirm the exact basketball court location in Google Maps satellite/street view where possible.
3. Record the coordinates:
   - In Google Maps, right-click or long-press the court.
   - Copy the latitude and longitude shown in the coordinate chip.
   - Keep latitude first, longitude second.
4. Check only facts you can reasonably verify:
   - indoor or outdoor
   - free, paid, booking required, or unknown
   - lights visible or unknown
   - surface type if visible
   - hoop count if visible
   - opening hours only from an official venue or council source
5. Leave HoopLife-only quality fields as `unknown` unless manually checked in person:
   - dries fast after rain
   - slippery when wet
   - nets
   - rim height
   - single/double rim
   - cleanliness
   - court space
   - pickup suitability
6. Add or edit the court through the app owner tool:
   - Open `Profile`.
   - Unlock `Admin` with the local admin passcode.
   - Open `Court database editor`.
   - Use `Add verified court` for a new location, or select an existing imported court to update it.
   - Set confidence to `Imported`, `Needs check`, `Verified`, or `Recently checked`.
7. After a good local data pass, export or copy the updated data into a backend or into `HoopLife/Resources/CourtsSeed.json` before release.

## Confidence Rules

- `Imported`: came from OSM or another source but has not been manually checked.
- `Needs check`: likely real, but key facts are missing or uncertain.
- `Verified`: owner manually checked the court or confirmed it from a reliable source.
- `Recently checked`: owner checked it recently in person.

## Release Notes

The current admin editor stores changes on the device only. That is useful for field work, but it is not a production database. Before shipping widely, move reviewed changes into a backend such as Supabase, or commit the final reviewed seed data into `CourtsSeed.json`.
