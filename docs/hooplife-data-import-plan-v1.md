# HoopLife Data Import Plan v1

## 1. Goal

HoopLife needs an initial court database before users exist. The first version should start in Sheffield, but the data pipeline should be designed so it can later expand across the UK.

The imported dataset should provide:

- Court/facility name
- Latitude and longitude
- City/area
- Source and license
- Basic known tags such as indoor/outdoor, surface, access, fee, lights, and opening hours when available

The imported dataset will not reliably provide:

- Whether the court is dry after rain
- Whether the court is slippery
- Whether rims have nets
- Whether rim height is standard
- Whether rims are double rims
- Court space quality
- Cleanliness
- Real peak times

Those fields are HoopLife's manual and user-contributed value.

## 2. Source Priority

### Source 1: OpenStreetMap

Best for:

- Outdoor courts
- Park courts
- Public courts
- Coordinates
- Some surface/access/light tags

Use cases:

- Initial Sheffield seed data
- UK-wide baseline court coverage

Important:

- Store `source = openstreetmap`
- Store OSM object type and ID
- Store OSM attribution
- Respect ODbL requirements

### Source 2: Sport England Active Places

Best for:

- Indoor facilities
- Sports halls
- Leisure centres
- Formal sports venues

Use cases:

- Indoor and bookable court discovery
- South Yorkshire/England facility expansion

Important:

- Store `source = active_places`
- Store facility/site ID if available
- Preserve source attribution and license notes

### Source 3: Manual Founder Review

Best for:

- Real HoopLife facts
- Sheffield quality layer
- Verifying whether imported records are actually useful for basketball

Use cases:

- Top Sheffield courts
- University areas
- Outdoor parks
- Known local gyms

## 3. OSM Import Approach

Use Overpass API to query basketball-related features around Sheffield.

Initial query logic:

- Include `sport=basketball`
- Include `leisure=pitch` where `sport=basketball`
- Include `leisure=sports_centre` where basketball is tagged
- Include `amenity=school` only if basketball is explicitly tagged

Avoid broad terms like every `sports_centre` without basketball tags, because that will create noisy data.

## 4. Example Overpass Query

This query is a starting point for Sheffield:

```overpass
[out:json][timeout:60];
area["name"="Sheffield"]["boundary"="administrative"]->.searchArea;
(
  node["sport"="basketball"](area.searchArea);
  way["sport"="basketball"](area.searchArea);
  relation["sport"="basketball"](area.searchArea);

  node["leisure"="pitch"]["sport"="basketball"](area.searchArea);
  way["leisure"="pitch"]["sport"="basketball"](area.searchArea);
  relation["leisure"="pitch"]["sport"="basketball"](area.searchArea);

  node["leisure"="sports_centre"]["sport"="basketball"](area.searchArea);
  way["leisure"="sports_centre"]["sport"="basketball"](area.searchArea);
  relation["leisure"="sports_centre"]["sport"="basketball"](area.searchArea);
);
out center tags;
```

If the Sheffield administrative relation is unreliable, use a bounding box around Sheffield instead.

## 5. OSM Field Mapping

| OSM Tag | HoopLife Field |
| --- | --- |
| `name` | `name` |
| coordinates / center | `latitude`, `longitude` |
| `indoor=yes/no` | `court_type` |
| `covered=yes/no` | `rain_playable` helper |
| `surface` | `surface_type` |
| `lit=yes/no` | `has_lights` |
| `access` | `access_type` |
| `fee=yes/no` | `price_type` |
| `opening_hours` | `opening_hours` |
| `hoops` | `hoop_count` |

Default unmapped values to `unknown`, not `false`.

## 6. HoopLife Manual Fields

These should not be expected from OSM.

### Playability

- `dryness_after_rain`
- `slippery_when_wet`
- `surface_condition`
- `court_cleanliness`
- `court_space`
- `runoff_safety`

### Rim And Hoop

- `has_nets`
- `rim_height`
- `rim_type`
- `backboard_condition`
- `rim_condition`

### Timing

- `peak_times`
- `evening_access`

### Use Case

- `good_for_solo`
- `good_for_pickup`
- `good_for_training`

## 7. Deduplication Rules

Potential duplicates should be grouped when:

- Coordinates are within 50 meters, and
- Names are similar, or
- One source is OSM and another source is Active Places for the same facility

Do not automatically delete duplicates at import time. Mark them with `duplicate_group_id` and review in admin.

## 8. Import Status Rules

After import:

- If source is OSM and has name + coordinates: `imported`
- If source has coordinates but no name: `needs_review`
- If indoor/outdoor is unknown: `needs_review`
- If public access is unknown: keep visible but show `Access unknown`
- If the court is manually checked: `verified`

## 9. Sheffield Manual Verification Plan

Start with 10-20 important courts.

For each court, collect:

- Indoor/outdoor
- Free/paid
- Public access
- Lights
- Dryness after rain
- Slipperiness
- Surface
- Nets
- Rim height
- Rim type
- Hoop count
- Court space
- Cleanliness
- Peak times
- Toilets/water/parking if obvious

The first verified courts should be around:

- University of Sheffield
- Sheffield Hallam
- City centre
- Popular parks
- Nearby leisure centres

## 10. App Display Rules For Imported Data

Do not make imported data look fully trusted.

Examples:

- `Imported from OpenStreetMap`
- `Needs HoopLife check`
- `Help confirm nets`
- `Rain condition unknown`

Unknown facts are acceptable as long as the UI is honest.

## 11. Recommended First Data Milestone

Before building a production backend:

1. Export Sheffield OSM basketball records.
2. Build a `courts_seed.csv`.
3. Add manual columns for HoopLife-specific facts.
4. Manually fill 10-20 courts.
5. Use this CSV as mock data for the first iOS prototype.

This avoids blocking UI development on a full data pipeline.
