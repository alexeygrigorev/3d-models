# Agent Handoff: Matchbox/Mattel ATV 6x6

This repository contains a work-in-progress OpenSCAD model of a simplified
Matchbox/Mattel ATV 6x6. The current focus is the lower white bathtub/chassis.

## Current State

- Main profile file: `white_bathtub_current.scad`
- First 3D bathtub draft: `white_bathtub_3d.scad`
- Older/reference model: `atv_6x6_body.scad`
- Construction notes: `docs/construction_notes.md`
- Render helper: `scripts/render.sh`

The active design direction follows `feedback6.png` from the local reference
photos, not the older tall black sketch literally.

## Current Geometry Intent

- The side profile is intentionally short.
- Wheels are close together: current preview centers are `[-10.8, 0, 10.8]`
  for 10 mm diameter wheels.
- V pockets should be sharp and centered above each wheel.
- Wheels should sit lower than earlier versions, with a small visual clearance
  from the body instead of being pushed hard into the upper edge.
- The left/rear rectangular tail from earlier versions was removed.
- The current work is still a profile and first bathtub draft, not a final
  printable assembly.

## Reference Photos

On the Hetzner checkout, reference photos are expected at:

```text
matchbox-mattel-atv-6x6/reference_photos/
```

That folder is intentionally ignored by git and should not be committed.

Important reference images from the previous work:

- `feedback6.png` - latest visual direction: shorter body, closer wheels,
  sharper V angles, wheels lower.
- `feedback5.png` - earlier straight upper/lower cut guide.
- `5289981205988187805.jpg` - side photo of the real toy.
- `5289981205988187847.jpg` - old rough side-profile sketch; do not copy it
  literally.

## Render Commands

From the model folder:

```bash
chmod +x scripts/render.sh
./scripts/render.sh
```

The script writes:

```text
renders/*.png
stl/*.stl
```

It requires OpenSCAD CLI:

```bash
sudo apt-get update
sudo apt-get install -y openscad
```

## Next Recommended Step

Before continuing the full 3D tub, finish the side profile tweaks requested in
the latest feedback. Then update `white_bathtub_3d.scad` from
`white_bathtub_current.scad`, because the 3D draft is currently only a first
structural translation of the profile.

