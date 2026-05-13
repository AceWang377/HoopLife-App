# HoopLife Release Checklist

Last updated: May 13, 2026

## Completed In This Prep Pass

- App icon checked: 1024 x 1024, PNG, no alpha.
- App supports iPhone and iPad.
- Public user edit and add-court flows are not reachable in the release UI.
- Debug owner tools are compiled for Debug only.
- Public UI no longer says MVP or v1.
- Location permission text is release-ready.
- Supabase `public.courts` has RLS enabled.
- Supabase `anon` and `authenticated` table grants are read-only SELECT.
- Supabase security advisor returned no lints.
- App Store metadata draft created.
- Privacy policy draft created.
- Terms of use draft created.

## Before App Store Submission

- Host the privacy policy at a public URL.
- Host a public support page or contact page.
- Add the privacy policy URL and support URL in App Store Connect.
- Capture iPhone 6.9-inch screenshots.
- Capture iPad 13-inch screenshots.
- Confirm App Store privacy answers match the hosted privacy policy.
- Create an archive in Xcode and upload to App Store Connect.
- Add the uploaded build to TestFlight.
- Run one real-device smoke test from the TestFlight build.
- Submit for App Review only after TestFlight smoke testing passes.

## Manual Smoke Test

- First launch shows splash and onboarding.
- Open court map.
- Pan and zoom the map.
- Search for a city or court.
- Tap `Search this area`.
- Apply and reset filters.
- Tap a court pin.
- Open court details.
- Save and unsave a court.
- Tap directions.
- Tap locate and confirm the iOS permission prompt wording.
- Open Profile.
- Open Saved courts.
- Open Data sources.
- Open Terms and privacy.

## App Review Risk Notes

- Do not expose hidden admin tools in Release builds.
- Do not mention unimplemented user submissions in App Store marketing copy.
- Be clear that imported OSM records may be incomplete.
- If location use changes from on-device map centering to server upload, update privacy policy and App Store privacy answers before release.
- If account login, submissions, photos, analytics, or payments are added, update privacy labels, terms, and review notes before release.
