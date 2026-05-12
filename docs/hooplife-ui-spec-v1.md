# HoopLife UI Design Spec v1

## 1. Design Goal

HoopLife should feel like a practical basketball court utility, not a generic sports social app.

The interface should help users answer:

- Where can I play?
- Is the court actually playable?
- Is it worth going there today?
- What key facts are still unknown?

The app should avoid inflated social features, star ratings, and vague community signals.

## 2. Product Personality

HoopLife should feel:

- Useful
- Local
- Young
- Clean
- Direct
- Map-first
- Slightly sporty, but not loud

The tone should be factual and confident. The app should not overpromise data that has not been verified.

## 3. Visual System

### Colors

Recommended palette:

- Background: `#F7F7F2`
- Primary text: `#151515`
- Secondary text: `#666A70`
- Court green: `#1F7A4D`
- Electric blue: `#1463FF`
- Basketball orange: `#F57C22`
- Verified green: `#1F9D55`
- Needs check amber: `#D98B00`
- Imported grey: `#8A8F98`
- Error red: `#D93B3B`

Use green/blue for navigation and primary UI. Use basketball orange sparingly for selected map pins, important CTAs, or highlighted playability facts.

### Typography

Use native iOS type scale.

- Large title: app/page headers
- Title 2/3: court names and section headers
- Body: factual rows
- Caption: data source, last checked, unknown notes

Avoid oversized marketing-style headings inside the app.

### Shape And Components

- Bottom sheets: 20-24px corner radius, native iOS style
- Fact chips: small capsules with icons
- Court cards: compact, 8-12px radius
- Buttons: icon + label where helpful
- Unknown facts: muted grey, never hidden if decision-critical

## 4. Information Priority

The most important court facts should appear first:

1. Indoor/outdoor
2. Free/paid
3. Public access
4. Dryness/rain impact
5. Lighting
6. Nets/rim quality
7. Space and cleanliness
8. Peak times
9. Toilets/water/parking
10. Source and last checked

## 5. Screen Map

Required v1 screens:

1. Launch / Welcome
2. Location Permission
3. Preference Setup
4. Map
5. Filter Sheet
6. Court Preview Bottom Sheet
7. Court Detail
8. Suggest Edit
9. Add Missing Court
10. Saved Courts
11. About Data
12. Empty / Loading / Error states

## 6. Screen Details

### 6.1 Launch / Welcome

Purpose:

Introduce HoopLife in one clear idea.

Layout:

- Top: HoopLife wordmark
- Middle: simple basketball court/map visual
- Headline: `Find courts that are actually playable.`
- Subcopy: `Dry surface, lights, nets, access, and real court facts.`
- Primary CTA: `Find courts near me`
- Secondary CTA: `Explore Sheffield`

Notes:

- No sign up button.
- No long explanation.
- The user should be inside the map in one tap.

### 6.2 Location Permission

Purpose:

Ask for location without making it feel mandatory.

Content:

- Title: `Use your location?`
- Body: `HoopLife uses it to show nearby courts and distance. You can still browse without it.`
- Primary CTA: `Allow location`
- Secondary CTA: `Not now`

State:

- If denied, open Sheffield default map center.

### 6.3 Preference Setup

Purpose:

Let users personalize filters without account creation.

Options:

- Outdoor
- Indoor
- Free
- Lights
- Dry after rain
- Nets
- Solo shooting
- Pickup

Interaction:

- Multi-select chips
- Primary CTA: `Show courts`
- Skip link: `Skip`

Storage:

- Store locally on device.

### 6.4 Map

Purpose:

Primary discovery surface.

Layout:

- Full-screen map
- Top search bar
- Horizontal filter chips below search
- Current location button floating right
- Bottom sheet with selected or nearby courts

Default location:

- Current user location if allowed
- Sheffield city center if location is not allowed

Map pin types:

- Verified outdoor court
- Verified indoor court
- Imported/needs check court
- Selected court

Filter chips:

- Outdoor
- Indoor
- Free
- Lights
- Dry
- Nets
- Standard rim
- Solo

Map behavior:

- Tapping a pin opens Court Preview.
- Dragging the map updates visible court list.
- Search supports court name, area, or postcode.

### 6.5 Filter Sheet

Purpose:

Let users filter by court facts.

Sections:

- Court type: indoor, outdoor
- Access: public, booking required, members only
- Cost: free, paid
- Conditions: dry after rain, rain unaffected, not slippery, lights
- Rim: nets, standard height, not double rim, double rim
- Use: solo shooting, pickup, training
- Facilities: toilets, water, parking

Interaction:

- Use toggles/chips.
- Show result count at bottom: `23 courts`
- CTA: `Apply filters`
- Secondary: `Reset`

### 6.6 Court Preview Bottom Sheet

Purpose:

Give enough information for quick decisions without leaving the map.

Content:

- Court name
- Area and distance
- Data confidence label
- Top 5 fact chips
- Quick warning if relevant
- Buttons: `Directions`, `Save`, `Details`

Example:

```
Devonshire Green Court
0.8 mi · Sheffield City Centre

Outdoor · Free · No lights · Nets unknown · Dries slowly
Needs check

Best for: Solo shooting
```

Warning examples:

- `May be slippery after rain`
- `Rim height unknown`
- `Public access not confirmed`

### 6.7 Court Detail

Purpose:

The main factual profile for one court.

Header:

- Court name
- Distance
- Confidence label
- Save button
- Directions button

Section 1: Quick Verdict

Show 3-5 highest-value facts:

- Outdoor / indoor
- Free / paid
- Dryness after rain
- Lights
- Nets / rim status

Do not use a score. Use facts only.

Section 2: Playing Conditions

Rows:

- Surface
- Dryness after rain
- Slippery when wet
- Rain playable
- Court space
- Cleanliness

Section 3: Rim And Hoop

Rows:

- Hoop count
- Nets
- Rim height
- Rim type
- Backboard condition
- Rim condition

Section 4: Access And Timing

Rows:

- Public access
- Cost
- Opening hours
- Evening access
- Peak times

Section 5: Facilities

Rows:

- Toilets
- Drinking water
- Parking
- Changing rooms

Section 6: Data

Rows:

- Source
- Last checked
- Verification status
- Attribution

Footer Actions:

- `Suggest edit`
- `Add photo` later, not v1 blocking
- `Report closed`

### 6.8 Suggest Edit

Purpose:

Collect factual corrections without login.

Flow:

1. Choose what to update
2. Answer focused questions
3. Optional note
4. Submit

Question types:

- Segmented control for yes/no/unknown
- Chips for enum fields
- Short note field only when needed

Editable groups:

- Court type
- Access and price
- Lights
- Dryness and rain
- Surface and space
- Nets and rim
- Cleanliness
- Peak times
- Facilities

Submission result:

- `Thanks. This will be reviewed before becoming verified.`

No user account required.

### 6.9 Add Missing Court

Purpose:

Let users submit a court not in the database.

Steps:

1. Pin location on map
2. Add court name or nearest place
3. Select indoor/outdoor
4. Add known facts
5. Submit

Required:

- Location
- Court type if known

Optional:

- Everything else

### 6.10 Saved Courts

Purpose:

Let users quickly return to courts they care about.

Layout:

- List of saved courts
- Each card has name, area, top facts, confidence
- Empty state: `Save courts you want to check again.`

Storage:

- Local device storage in v1.

### 6.11 About Data

Purpose:

Build trust and handle attribution.

Sections:

- What HoopLife tracks
- What verified means
- Why some fields are unknown
- Data sources
- OpenStreetMap attribution
- Sport England Active Places attribution if used
- Contact / corrections

Tone:

Transparent. Avoid sounding like the data is perfect.

## 7. Core Components

### Fact Chip

Examples:

- `Outdoor`
- `Free`
- `Nets`
- `No lights`
- `Dries slowly`
- `Standard rim`
- `Peak evenings`

States:

- Positive: green
- Neutral: grey
- Warning: amber
- Unknown: light grey with `Unknown`

### Confidence Badge

Values:

- Verified
- Recently checked
- Imported
- Needs check
- User suggested

### Fact Row

Structure:

- Icon
- Label
- Value
- Source/confidence indicator when needed

Example:

```
Rain impact    Puddles common    Needs check
```

### Court Card

Used in bottom sheet and saved list.

Fields:

- Name
- Area
- Distance
- Top fact chips
- Confidence

## 8. Empty States

### No Courts Found

Text:

`No matching courts here yet. Try fewer filters or add a missing court.`

Actions:

- Reset filters
- Add missing court

### Unknown Field

Text:

`Not confirmed yet`

Action:

- Help confirm

### Location Denied

Text:

`Showing Sheffield. Enable location to see courts near you.`

Action:

- Enable location

## 9. Figma Plan

Create these frames:

- `01 Welcome`
- `02 Location Permission`
- `03 Preferences`
- `04 Map`
- `05 Filters`
- `06 Court Preview`
- `07 Court Detail`
- `08 Suggest Edit`
- `09 Add Missing Court`
- `10 Saved Courts`
- `11 About Data`
- `12 States`

Recommended size:

- iPhone 15 Pro frame: 393 x 852

Figma component set:

- Fact Chip
- Confidence Badge
- Fact Row
- Court Card
- Map Pin
- Filter Chip
- Primary Button
- Secondary Button

## 10. Canva Plan

Canva is not the best source of truth for app UI. Use it later for:

- Investor/product pitch deck
- Instagram launch posts
- University society outreach posters
- QR posters for local courts
- App Store promo graphics

For product UI, Figma should be the primary design tool.
