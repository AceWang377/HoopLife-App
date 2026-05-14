# Blacktop iOS App PRD v1

## 1. Product Summary

Blacktop is a lightweight basketball court discovery app focused on factual court information, starting with Sheffield and expanding to major UK cities.

The app does not start as a social network. It does not require login, ratings, player profiles, chat, or player ranking. The first version exists to answer one practical question:

> Can I actually play basketball at this court?

## 2. Product Positioning

### Core Promise

Blacktop helps basketball players find real, usable courts before leaving home.

### One-line Positioning

Find courts that actually fit how you want to play.

### Initial Market

Primary launch city:

- Sheffield

Expansion target:

- South Yorkshire
- Manchester
- Leeds
- Birmingham
- London
- Other UK cities after the data import and verification workflow becomes stable

### Target Users

- Students in Sheffield who want nearby courts
- Casual players looking for outdoor courts
- Players looking for indoor courts during bad weather
- People who want solo shooting spots
- New residents or international students who do not know the local basketball scene
- Occasional pickup players who care more about court access than social features

## 3. Product Principles

1. Facts over opinions
   Blacktop should avoid vague ratings such as stars or scores. A court is useful because it has lights, is free, is open at night, or has a playable surface.

2. No login for browsing
   Users should be able to open the app and use the map immediately.

3. Data confidence must be visible
   Imported data, user-suggested data, and verified data should be clearly separated.

4. Start narrow, look bigger
   The product should start with Sheffield quality, while the database can contain wider UK court coverage marked as imported or incomplete.

5. Every field should help someone decide whether to go
   If a field does not change a user's decision, it should not be in v1.

## 4. Problem Statement

Basketball court information is fragmented. Google Maps may show a park or sports centre, but it often does not clearly answer:

- Is there actually a basketball hoop?
- Is it indoor or outdoor?
- Is it free?
- Are there lights at night?
- Is it open to the public?
- Does it have a full court or just one hoop?
- Can I shoot alone there?
- Does rain make it unusable?
- Is the court dry, slippery, or slow to drain after rain?
- Does the rim have a net?
- Is the rim height standard?
- Is it a double rim?
- Is there enough run-off space around the court?
- Is the court clean enough to comfortably play?
- When does it usually get busy?
- Are there toilets, parking, or drinking water nearby?

Blacktop focuses on these missing practical facts.

## 5. Data Strategy

### Key Data Challenge

The app needs an initial basketball court database before users exist. The first version should therefore combine open/importable datasets with manual enrichment.

### Recommended Data Sources

#### 5.1 OpenStreetMap

Use OpenStreetMap as the main seed source for outdoor courts and mapped basketball pitches.

Useful tags include:

- `sport=basketball`
- `leisure=pitch`
- `amenity=school` or `leisure=sports_centre` when basketball tags exist
- `surface`
- `lit`
- `indoor`
- `covered`
- `access`
- `fee`
- `opening_hours`
- `hoops`

Important licensing note:

OpenStreetMap data is licensed under ODbL. Blacktop can use and adapt it, but must credit OpenStreetMap contributors and respect ODbL share-alike obligations when distributing adapted OSM-derived databases.

Source: https://www.openstreetmap.org/copyright

#### 5.2 Sport England Active Places

Use Active Places as a major source for formal indoor sports facilities in England, especially sports halls, leisure centres, and facilities that may support basketball.

Sport England states that Active Places sport facility open data is updated daily and provides a comprehensive list of sporting venues and associated facilities across England.

Source: https://www.sportengland.org/know-your-audience/data

#### 5.3 Google Maps / Google Places

Use Google Maps only as an auxiliary layer, not as the primary database.

Allowed/appropriate v1 usage:

- Search address or place name
- Open navigation
- User-assisted location confirmation
- Store Google `place_id` as an external reference when allowed

Avoid:

- Scraping Google Maps
- Bulk importing Google Places results into Blacktop
- Treating Google as the source of the long-term Blacktop database

#### 5.4 Manual Admin Import

Because v1 starts in Sheffield, the founder can manually review and enrich the first set of courts.

Manual enrichment should focus on:

- Indoor/outdoor
- Free/paid
- Lighting
- Public access
- Number of hoops
- Rim quality, net presence, rim height, and double rim status
- Surface
- Dryness, slipperiness, and rain usability
- Court space and run-off area
- Cleanliness
- Peak time windows
- Toilets/parking/water
- Photos, later if needed

### Data Ownership Model

Blacktop should separate data into three conceptual layers:

1. Source layer
   Imported facts from OSM, Active Places, or other allowed sources.

2. Blacktop enrichment layer
   Fields manually checked or added by Blacktop, such as "good for solo shooting" or "gate locked after sunset."

3. User contribution layer
   User-submitted edits, marked as pending or confirmed.

This matters because imported open data may require attribution or license compliance. Blacktop's own verified/enriched fields can become the product's proprietary value, but source provenance should remain stored.

## 6. MVP Scope

### In Scope

- Map of basketball courts
- Sheffield-first dataset
- Import-ready database structure for UK-wide seed data
- Court detail page
- Court factual fields
- Filters
- Saved courts stored locally
- Suggest edit without login
- Admin review concept
- Data confidence labels
- Basic city expansion strategy

### Out of Scope

- User login
- Court star ratings
- Player ratings
- Chat
- Matchmaking
- Full pickup game creation
- Payment
- Booking
- AI training
- Social feed
- Comments
- Public user profiles

## 7. Core User Stories

1. As a player, I want to see basketball courts near me so I can decide where to go.

2. As a player, I want to know whether a court is indoor or outdoor so I can choose based on weather.

3. As a player, I want to know whether a court has lights so I can play after dark.

4. As a player, I want to know whether the court is dry, slippery, or rain-affected so I can avoid unsafe outdoor runs.

5. As a player, I want to know whether the rims have nets, are standard height, or are double rims so I know whether the court is worth shooting on.

6. As a player, I want to know whether a court is free or paid so I can avoid surprises.

7. As a player, I want to know whether the court is public access so I do not travel to a private facility.

8. As a player, I want to filter for solo shooting courts so I can practice alone.

9. As a player, I want to suggest corrections without making an account.

10. As the app owner, I want to import courts from open data sources so the app does not launch empty.

11. As the app owner, I want to mark court facts by confidence level so incomplete data does not look falsely authoritative.

## 8. Court Data Fields

### Required v1 Fields

- `id`
- `name`
- `latitude`
- `longitude`
- `city`
- `country`
- `source`
- `source_id`
- `source_license`
- `data_confidence`
- `last_checked_at`
- `created_at`
- `updated_at`

### Core Court Facts

- `court_type`: indoor, outdoor, mixed, unknown
- `access_type`: public, private, members_only, school, booking_required, unknown
- `price_type`: free, paid, mixed, unknown
- `has_lights`: yes, no, unknown
- `surface_type`: concrete, asphalt, rubber, wood, synthetic, unknown
- `court_size`: full_court, half_court, single_hoop, multiple_hoops, unknown
- `hoop_count`
- `opening_hours`
- `evening_access`: yes, no, seasonal, unknown

### Playability Conditions

- `dryness_after_rain`: dries_fast, slow_to_dry, puddles_common, indoor_unaffected, unknown
- `slippery_when_wet`: yes, no, sometimes, unknown
- `rain_playable`: yes, no, partially, indoor_unaffected, unknown
- `surface_condition`: smooth, cracked, uneven, worn, unknown
- `court_cleanliness`: clean, acceptable, littered, poor, unknown
- `court_space`: spacious, tight_edges, fenced_tight, shared_space, unknown
- `runoff_safety`: safe, limited, unsafe, unknown
- `peak_times`: weekday_evening, weekend_morning, weekend_afternoon, lunch_time, unknown

### Rim And Hoop Quality

- `has_nets`: all, some, none, unknown
- `rim_height`: standard, too_low, too_high, mixed, unknown
- `rim_type`: single_rim, double_rim, mixed, unknown
- `backboard_condition`: good, worn, damaged, missing, unknown
- `rim_condition`: good, bent, loose, damaged, unknown

### Facilities

- `has_toilets`: yes, no, nearby, unknown
- `has_drinking_water`: yes, no, nearby, unknown
- `has_parking`: yes, no, nearby, unknown
- `has_changing_rooms`: yes, no, unknown

### Use Case Tags

- `good_for_solo`: yes, no, unknown
- `good_for_pickup`: yes, no, unknown
- `good_for_training`: yes, no, unknown
- `beginner_friendly`: yes, no, unknown

### Admin/Internal Fields

- `verification_status`: imported, needs_review, user_suggested, verified, rejected
- `verified_by`
- `verified_at`
- `notes_private`
- `duplicate_group_id`

## 9. Data Confidence System

Use simple labels, not ratings.

### Imported

Data came from an external open dataset and has not been checked by Blacktop.

### Needs Check

The court exists in a dataset, but important fields are missing or uncertain.

### User Suggested

A user submitted a correction that has not been confirmed.

### Verified

Blacktop or a trusted contributor has manually checked the key facts.

### Recently Checked

The court has been checked within the last 90 days.

## 10. Main Screens

### 10.1 Onboarding

Goal:

Let the user understand the app quickly and optionally allow location access.

Screens:

- Welcome
- Location permission prompt
- Optional preference selection

Preference options:

- Outdoor courts
- Indoor courts
- Free courts
- Night courts
- Solo shooting
- Pickup-friendly courts

No account creation.

### 10.2 Map

The main screen of the app.

Elements:

- Map
- Search field
- Current location button
- Filter chips
- Bottom court preview sheet

Filter chips:

- Outdoor
- Indoor
- Free
- Lights
- Dry after rain
- Nets
- Standard rim
- Rain OK
- Public
- Solo
- Pickup

Map pin states:

- Verified court
- Imported court
- Needs check
- Indoor facility
- Outdoor court

### 10.3 Court Preview Sheet

Appears after tapping a court pin.

Content:

- Court name
- Distance
- Data confidence
- Key facts
- Direction button
- Save button
- View details button

Example:

```
Devonshire Green Court
0.8 mi away
Outdoor · Free · Nets unknown · Dries slowly · Needs check
Good for: Solo shooting
```

### 10.4 Court Detail

The most important content page.

Sections:

- Header: court name, distance, confidence
- Key facts: indoor/outdoor, free/paid, access
- Playing conditions: dryness, slipperiness, surface, rain, space, cleanliness
- Rim and hoop quality: nets, rim height, double rim, backboard, rim condition
- Timing: opening hours and likely peak times
- Facilities: toilets, water, parking
- Best for: solo, pickup, training
- Data source and last checked
- Suggest edit
- Open in Maps

### 10.5 Suggest Edit

No-login contribution flow.

Design approach:

- Use taps and segmented controls instead of long text forms.
- Ask only one section at a time.
- Allow "I don't know."

Editable sections:

- Court type
- Access
- Price
- Lights
- Surface
- Dryness after rain
- Slipperiness
- Nets
- Rim height
- Rim type
- Court space
- Cleanliness
- Peak times
- Facilities
- Use case tags

Anti-spam:

- Device identifier
- Rate limit
- Optional CAPTCHA later
- Admin approval before public trusted display

### 10.6 Saved Courts

Local-only saved courts in v1.

Content:

- Saved courts list
- Quick fact chips
- Distance from current location
- Offline-friendly cached facts

No account sync in v1.

### 10.7 Admin Review

This can be a simple internal web dashboard or database admin view in v1.

Functions:

- View imported courts needing review
- Approve user suggestions
- Merge duplicates
- Mark court verified
- Edit facts manually
- Track source and license

## 11. Navigation

Recommended tab structure:

- Map
- Saved
- Contribute
- About/Data

For v1, Contribute can open:

- Suggest edit for current court
- Add missing court

About/Data should explain:

- Data sources
- OSM attribution
- What "verified" means
- How users can help improve court facts

## 12. Visual Direction

Blacktop should feel practical, young, and urban, but not noisy.

### Design Keywords

- Clean
- Fast
- Map-first
- Sporty but not aggressive
- Trustworthy
- Lightweight

### Suggested Palette

- Primary: court green or electric blue
- Accent: basketball orange
- Background: off-white or very light grey
- Status colors:
  - Verified: green
  - Needs check: amber
  - Imported: neutral grey
  - User suggested: blue

### UI Style

- Compact fact chips
- Clear icons for facilities
- Map-first layout
- Bottom sheets
- Native iOS controls where possible
- Minimal copy

## 13. Technical Direction

### iOS

- SwiftUI
- MapKit for v1
- CoreLocation
- Local storage for saved courts

### Backend

Recommended:

- Supabase/Postgres or a simple PostgreSQL backend
- REST or GraphQL API
- Admin dashboard

### Data Import Pipeline

Required pipeline:

1. Import OSM courts for Sheffield.
2. Import Active Places facilities for Sheffield/South Yorkshire.
3. Normalize fields into Blacktop schema.
4. Deduplicate by coordinates/name.
5. Mark all imported records as `needs_review` or `imported`.
6. Manually enrich top courts.
7. Publish in app.

### Expansion Pipeline

After Sheffield:

1. Import UK-wide seed records.
2. Prioritize cities by likely basketball demand.
3. Show imported/incomplete courts with confidence labels.
4. Manually verify top courts in target cities.

## 14. Launch Plan

### Phase 1: Sheffield Private MVP

Goal:

Launch with enough local value to test whether people care.

Dataset target:

- 30-80 Sheffield/South Yorkshire basketball-related locations
- At least 10 manually verified courts
- All others marked as imported or needs check

Required screens:

- Map
- Court detail
- Filters
- Saved courts
- Suggest edit

### Phase 2: Sheffield Public Beta

Goal:

Test real usage and contributions.

Add:

- Share court link
- Add missing court
- Admin review queue
- Better source labels

### Phase 3: UK Seed Coverage

Goal:

Make the app look useful beyond Sheffield without pretending all data is verified.

Add:

- UK-wide imported court/facility seed data
- City pages
- "Needs check" contribution prompts
- Data coverage stats

## 15. Success Metrics

### Product Metrics

- Map opens per user
- Court detail views
- Filter usage
- Saved court count
- Direction taps
- Suggest edit submissions
- Add missing court submissions

### Data Metrics

- Number of imported courts
- Number of verified courts
- Percentage of courts with indoor/outdoor known
- Percentage of courts with access known
- Percentage of courts with lights known
- Duplicate rate
- Edit approval rate

### Sheffield Beta Targets

- 50+ seed locations
- 10+ verified courts
- 100 beta users
- 20+ user suggestions
- 30%+ of users opening at least one court detail

## 16. Key Risks

### Data Accuracy

Imported data may be outdated or incomplete.

Mitigation:

- Show confidence labels.
- Avoid overclaiming.
- Prioritize manual verification for popular courts.

### Licensing

Imported data may carry attribution and share-alike obligations.

Mitigation:

- Store source and license per record.
- Show attribution in the app.
- Keep Blacktop enrichment fields separate from imported source fields.

### Empty Product Feel

If too many courts show unknown fields, users may lose trust.

Mitigation:

- Manually enrich Sheffield first.
- Only show key unknowns when useful.
- Use "Help confirm this court" prompts.

### No Network Effect

Because v1 avoids social features, growth depends on utility.

Mitigation:

- Focus on search, map, directions, and facts.
- Make court pages shareable.
- Build city guides later.

## 17. v1 Acceptance Criteria

The v1 app is acceptable when:

- A user in Sheffield can open the app without login.
- The map shows basketball court/facility locations.
- The user can filter by indoor/outdoor, free/paid, lights, and solo/pickup suitability.
- The user can filter by dryness after rain, nets, standard rim height, and rain usability.
- The user can open a court detail page.
- The court detail page clearly shows known, unknown, and imported facts.
- The user can save a court locally.
- The user can suggest a correction without logging in.
- The backend stores source, license, and confidence information for every imported court.
- The admin can review and update court facts.

## 18. Recommended Next Step

Before coding the full app, create the initial Sheffield data plan:

1. Pull OSM basketball-related records for Sheffield.
2. Pull Active Places sports facilities for Sheffield/South Yorkshire.
3. Merge and deduplicate records.
4. Build a seed CSV with Blacktop fields.
5. Manually verify the top 10-20 courts.
6. Use that dataset to drive the first iOS prototype.
