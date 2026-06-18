# ATV 6x6 construction notes

Goal: rebuild the model from the real toy construction, not from the old visual
approximation.

## Current focus

We are working only on the lower white part. Blue body, gray insert, rollbar,
seat, and decorative details are hidden/ignored for now.

## What the lower white part should be

From the underside and side photos:

- The white lower part must be a bathtub/chassis, not a flat block, not a side
  silhouette, and not a set of separate posts.
- The main readable form is one continuous tub: a central long bottom/floor with
  raised left/right walls.
- The wheel places are features in this tub. They must not destroy the feeling
  that this is one bathtub.
- The wheels are not inserted into small round side holes.
- Each wheel sits beside the central tub and partly drops into a large open side pocket.
- There are three wheel pockets on each side.
- Between wheel pockets there are white ribs/dividers. These dividers form the wheel bays.
- Important: the wheel pockets are open from the top. The wheels are placed
  down into the pockets from above; they are not pushed sideways through holes.
- The side profile should read like: high rib, low wheel saddle, high rib, low
  wheel saddle, high rib, low wheel saddle, high rib.
- Do not model round side holes for the wheels in the white tub.
- Do not put visible axle holes through the white tub in this stage. The gray
  holder should deal with axle retention later.
- The top of the white tub should have an internal open area where another part can sit.
- The gray internal part likely lies into this white tub and holds/clamps the wheel axles.
- The blue shell sits above these parts like a wider cap.
- A screw from the bottom likely clamps white tub + gray insert + blue shell together.

## Layer model

1. White lower bathtub
   - Central floor.
   - Side wheel pockets.
   - Ribs/dividers between wheel pockets.
   - Bottom screw area.
   - Internal seat/ledge for the future gray axle holder.

2. Gray axle holder
   - Separate future part.
   - Holds axles/wheels from above so they do not fall out.
   - Should fit into the white tub.

3. Blue upper shell
   - Separate future part.
   - Wider than the white tub.
   - Covers the assembly from above.

## Modeling rule

Do not keep patching the previous white tub. Delete the old geometry and rebuild
the lower white part from these primitives:

- central floor plate;
- left and right side ribs;
- six large wheel pockets;
- inner ledge for gray insert;
- screw boss/recess.

First version should be simple and structural. Details and exact curves come
after the basic bathtub/wheel-pocket layout is correct.

## Agreed side profile for the white bathtub

The user sketch `photos/5289981205988187847.jpg` is a side view of the lower
white bathtub edge/profile.

Important corrections from the iteration:

- The sketch is not a top view.
- The sketch is not a separate vertical part.
- The sketch should define the side silhouette of the bathtub.
- The bathtub must still lie horizontally in the vehicle.
- Transparent wheels should stay visible while checking the profile.

Simplified agreed ASCII profile:

```text
rear                                                   front
|--\ /------\ /------\ /--------\
|   V        V        V          \
|                                  \
|___________________________________\
```

Meaning:

- Lower edge is mostly horizontal and continuous.
- There are three wheel pockets shaped like sharp open V saddles.
- The pockets are open from above; wheels are placed down into them.
- The pocket bottoms are not round holes and not side holes.
- Between pockets there are raised solid wall sections.
- Front/right side is a higher block that slopes down into the lower edge.
- Later the same side profile should become the side wall of a full bathtub:
  two mirrored side walls plus a floor between them.
- Current profile is a proportional side silhouette, not the final printable tub.
- Current SCAD uses `profile_z_scale` so height can be adjusted without changing
  the wheel-pocket x positions.
- Preview wheels are transparent and should remain visible while checking the
  profile, because their centers mark the approximate V pocket/axle seats.

Current working file for this profile is:

- `white_bathtub_current.scad`

Current feedback file to inspect after changes:

- `renders/profile_feedback.png`

Current feedback5 cut-control file:

- `renders/feedback5_current_check.png`
- This is the preferred check for the latest direction: the profile should be
  closer to the real straight bathtub side, with top and bottom trimmed by the
  orange guide lines from `C:\Users\alexey\Downloads\feedback5.png`.
- The old black sketch is now only a rough memory of the V-pocket idea. Do not
  copy its tall silhouette literally.

Latest feedback6 direction:

- Reference file: `C:\Users\alexey\Downloads\feedback6.png`.
- Overall side profile should be much shorter than the earlier long version.
- Wheel centers should be close together; current preview spacing is 10.8 mm
  for 10 mm wheels, so the visual gap is small.
- Wheels should sit lower relative to the side wall than in the earlier
  feedback5 pass.
- V pockets should stay sharp and centered over each wheel; current
  `pocket_floor_z` is 3.85 and `wheel_center_z` is 3.80.
- Keep a small visual clearance between wheel and body instead of pushing the
  wheel hard into the upper edge.
- Current measured preview values:
  - tire gap: 0.80 mm (`wheel_x` spacing 10.8 mm, wheel diameter 10 mm);
  - wheel center is 0.05 mm below the V tip;
  - wheel top is 1.75 mm above the straight upper body edge in the transparent
    preview, so it intentionally still reads as a wheel behind the side profile;
  - wheel bottom is 3.50 mm below the lower body edge.
- The left/rear extra rectangular tail from previous versions is removed.

Current comparison helper:

- `tools/profile_compare.py`
- It renders the clean profile, aligns it with the sketch by the bottom edge,
  prints per-section top/bottom pixel differences, and writes
  `renders/profile_compare_debug.png`.

## Current 3D wheel/axle fit

Current file:

- `white_bathtub_3d.scad`

Current wheel assumption:

- Replacement wheel diameter: 11.0 mm.
- Replacement wheel width: 6.5 mm.
- Inner gap between wheels in a pair: 20.5 mm.
- Center-to-center distance between paired wheels: 27.0 mm.
- Overall wheel-pair width by outside faces: 33.5 mm.
- Preview axle diameter: 1.2 mm.
- Preview axle length: 34.0 mm.
- Central hub/bushing on the real wheel appears to be about 5-6 mm diameter.

Current fit details:

- The wheels remain transparent preview geometry; they are not exported into
  printable STL.
- The wheel pair is previewed from the measured 27.0 mm center-to-center
  distance, with the white tub between the wheels.
- The previous extra 0.8 mm wheel clearance is now disabled because the measured
  wheel pair width already moves the wheels outward enough for the current
  profile. The older 3 mm offset was too large and remains removed.
- Each wheel pocket has a narrow open-top axle drop slot so the real wheel axle
  can be lowered into the tub from above.
- At the bottom of each slot there is a small round axle seat.
- On the outside of each side wall, around the axle seat, there is a small
  lower half-washer spacer. It is intentionally not a full washer: the top is
  open so the axle can pass down through the slot.
- The half-washer spacer exists to keep the wheel from rubbing directly on the
  white tub side wall.
- Do not replace the half-washer with a full circular boss unless axle
  insertion is solved another way.
- The preview axle length is derived from the actual preview wheel center
  position, so the live viewer keeps the visible axle aligned with any wheel
  spacing adjustment.

## Current 3D front closure

- The front opening of the white bathtub is now partially closed.
- The closure is not a rectangular block. It is clipped from the existing outer
  profile with `intersection()`, so it follows the current front slope and
  bathtub angle.
- The closure is only a temporary shape check for the front hole. Keep future
  edits tied to the side profile instead of adding arbitrary flat plates.
