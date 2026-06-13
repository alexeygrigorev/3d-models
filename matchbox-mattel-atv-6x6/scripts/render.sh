#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENSCAD_BIN="${OPENSCAD_BIN:-openscad}"

if ! command -v "$OPENSCAD_BIN" >/dev/null 2>&1; then
  cat >&2 <<'EOF'
OpenSCAD CLI was not found.

Install it first, for example:
  sudo apt-get update
  sudo apt-get install -y openscad

Or set OPENSCAD_BIN to the OpenSCAD executable path.
EOF
  exit 127
fi

mkdir -p "$ROOT/renders" "$ROOT/stl"

render_png() {
  local scad="$1"
  local name="$2"
  local camera="$3"

  "$OPENSCAD_BIN" \
    -o "$ROOT/renders/${name}.png" \
    --imgsize=1600,1000 \
    --viewall \
    --autocenter \
    --projection=o \
    --camera="$camera" \
    "$ROOT/$scad"
}

render_stl() {
  local scad="$1"
  local name="$2"

  "$OPENSCAD_BIN" \
    -D 'show_preview_wheels=false' \
    -D 'show_axles=false' \
    -o "$ROOT/stl/${name}.stl" \
    "$ROOT/$scad"
}

render_png "white_bathtub_current.scad" "white_bathtub_current_side" "0,0,0,90,0,0,70"
render_stl "white_bathtub_current.scad" "white_bathtub_current_no_wheels"

render_png "white_bathtub_3d.scad" "white_bathtub_3d_preview" "0,0,0,60,0,35,80"
render_stl "white_bathtub_3d.scad" "white_bathtub_3d_no_wheels"

render_png "atv_6x6_body.scad" "atv_6x6_body_preview" "0,0,0,60,0,35,90"
render_stl "atv_6x6_body.scad" "atv_6x6_body_no_wheels"

echo "Wrote renders to $ROOT/renders"
echo "Wrote STL files to $ROOT/stl"

