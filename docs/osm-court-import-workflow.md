# HoopLife OSM Court Import Workflow

HoopLife should treat OpenStreetMap as a starting point, not as verified truth. Imported courts can appear as `Imported` or `Needs check`; user-submitted courts should remain candidates until reviewed.

## 1. Find Basketball-Related Places

Use Overpass Turbo or the Overpass API to query basketball records in the city you are seeding:

```overpass
[out:json][timeout:25];
area["name"="Sheffield"]["boundary"="administrative"]->.searchArea;
(
  node["sport"="basketball"](area.searchArea);
  way["sport"="basketball"](area.searchArea);
  relation["sport"="basketball"](area.searchArea);
  node["leisure"="pitch"]["sport"~"basketball|multi"](area.searchArea);
  way["leisure"="pitch"]["sport"~"basketball|multi"](area.searchArea);
  relation["leisure"="pitch"]["sport"~"basketball|multi"](area.searchArea);
);
out center tags;
```

For other cities, replace the area name. For a tighter first pass, use a bounding box around the area you personally want to verify.

## 2. Convert OSM Records Into HoopLife Seed Fields

For each record:

- `id`: `osm-node-123`, `osm-way-123`, or your own stable slug
- `name`: OSM `name`, or a descriptive placeholder
- `area`: neighbourhood or venue area
- `latitude`: node `lat`, or way/relation `center.lat`
- `longitude`: node `lon`, or way/relation `center.lon`
- `source`: `openStreetMap`
- `sourceLicense`: `ODbL - OpenStreetMap contributors`
- `confidence`: `imported`

Leave HoopLife-specific facts as `unknown` until reviewed:

- rain/dryness
- slippery surface
- nets
- rim height
- double rim
- lighting
- space
- cleanliness
- peak times

## 3. Review Before Publishing As Verified

Use this priority order:

1. Confirm the court exists at the coordinates.
2. Confirm public access and cost.
3. Fill the high-value facts: dry after rain, nets, rim height, lighting, surface, space.
4. Promote confidence from `imported` to `needsCheck`, `recentlyChecked`, or `verified`.

## 4. User Contributions

Users should not directly publish new courts into the main map. The app flow should be:

1. User taps a map position and submits a candidate.
2. Candidate enters a review queue.
3. Founder/admin checks the coordinate and source.
4. Approved candidate becomes a real `Court` record.

For existing courts, users can submit fact updates such as “nets present” or “puddles common”. These should also remain suggestions until reviewed.
