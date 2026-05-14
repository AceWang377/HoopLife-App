# Blacktop

Blacktop is a SwiftUI iOS MVP for finding basketball courts by factual playability information, starting with Sheffield.

The app focuses on practical court facts instead of login, ratings, chat, or player profiles:

- indoor / outdoor
- free / paid
- dry after rain / slippery when wet
- lights
- nets
- rim height
- rim type
- court space
- cleanliness
- peak times
- facilities
- data confidence

## Current MVP

- SwiftUI app shell
- MapKit court map
- Sheffield seed data
- local saved courts
- no-login suggest edit flow
- no-login add missing court flow
- data source and confidence labels
- redesigned full-screen basketball-court onboarding

## Project

Open:

```bash
open Blacktop.xcodeproj
```

Build/run scheme:

```bash
xcodebuild -project Blacktop.xcodeproj -scheme Blacktop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Docs

Product planning lives in `docs/`:

- `docs/blacktop-prd-v1.md`
- `docs/blacktop-ui-spec-v1.md`
- `docs/blacktop-data-import-plan-v1.md`

## Data

The current app uses local seed data from:

```text
Blacktop/Resources/CourtsSeed.json
```

Future data import should use OpenStreetMap and Sport England Active Places as seed sources, with source attribution and license metadata preserved per court.
