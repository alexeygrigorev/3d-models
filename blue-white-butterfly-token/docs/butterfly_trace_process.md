# Butterfly Slot Tracing Process

This documents the process used to make the butterfly-shaped through-slot match
the photo reference. The goal is to avoid hand-guessing the slot outline and to
make the process repeatable if a better photo is taken later.

## Setup

Create a local Python environment with `uv` from the repository root:

```bash
uv venv .venv
uv pip install pillow opencv-python-headless numpy
```

The environment is intentionally local and ignored by git.

## Source Image

Use the best close-up photo where the dark opening is visible around the full
butterfly edge. For this pass the source was:

```text
~/.pocketshell/attachments/host-1-git-3d-models/20260704-093739-01-PXL_20260704_073725361.MP.jpg
```

The original image was `4032x2268`. The useful crop around the slot was:

```bash
convert SOURCE.jpg -crop 1800x1300+1350+500 +repage \
  blue-white-butterfly-token/analysis/reference_crop_wide.jpg
```

`analysis/` is ignored by git. It is only a scratch directory for contour
extraction and visual checks.

## Extract The Opening

The dark table seen through the hole is segmented from the light plastic using
OpenCV:

1. Convert the crop to HSV and grayscale.
2. Build a mask from dark pixels plus brown-ish low-value pixels.
3. Run median blur and morphological close/open operations to clean speckles.
4. Keep the largest connected component.
5. Extract the external contour.
6. Simplify the contour with `approxPolyDP`.
7. Save an overlay image with:
   - green: raw detected contour
   - red: simplified contour
   - magenta: control points

The overlay is the quality gate. If it does not follow the physical plastic
edge, adjust the crop or threshold before touching the SCAD model.

## Normalize The Points

The simplified contour is normalized into model coordinates:

1. Use the contour bounding box center as origin.
2. Convert image Y down into model Y up.
3. Scale the contour to the intended slot width in millimeters.
4. Rotate the point list so it starts near the upper/right wing for readable
   SCAD.

The raw traced points preserve perspective distortion from the photo. For this
model, the traced outline was used as the source shape, then mirrored left/right
manually in SCAD so the printed part remains symmetric.

## Transfer To OpenSCAD

The SCAD model uses a Catmull-Rom smoothing helper:

```openscad
polygon(points = smooth_closed_path([
    [ 0.000,  0.780],
    [ 0.800,  1.450],
    ...
], 7));
```

Keep the control points sparse enough to edit by hand. Increase/decrease the
`steps` argument only for smoothing density; do not use it to change the actual
shape.

## Validate

After editing `butterfly_token.scad`, render both the printable STL and close-up
checks:

```bash
cd blue-white-butterfly-token
./render.sh

$HOME/.local/bin/openscad-manifold \
  -o renders/butterfly_token_center_top.png \
  --imgsize=1400,1000 --autocenter --projection=o \
  --camera=0,0,0,0,0,0,28 --colorscheme=Tomorrow \
  butterfly_token.scad

$HOME/.local/bin/openscad-manifold \
  -o renders/butterfly_token_closeup_top.png \
  --imgsize=1400,1400 --autocenter --projection=o \
  --camera=0,0,0,0,0,0,18 --colorscheme=Tomorrow \
  butterfly_token.scad
```

OpenSCAD should report `Status: NoError` and a manifold top-level object.

If the live viewer is running, it should re-render automatically on file change:

```bash
cd live-viewer
MODEL_DIR=../blue-white-butterfly-token \
PORT=4174 \
OPENSCAD_BIN=$HOME/.local/bin/openscad-manifold \
npm start
```

Viewer URL:

```text
http://localhost:4174/butterfly_token.scad
```

If the browser appears stale, refresh the tab once; the server API should show a
new `stlUrl` with a fresh `?v=...` query string after each render.
