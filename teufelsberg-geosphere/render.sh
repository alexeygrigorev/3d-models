#!/usr/bin/env bash
# Render preview PNG and printable STL for the geodesic sphere.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENSCAD_BIN="${OPENSCAD_BIN:-openscad}"
PNG_CMD=("$OPENSCAD_BIN")

if [[ -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null 2>&1; then
  PNG_CMD=(xvfb-run -a "$OPENSCAD_BIN")   # PNG needs a GL context; STL does not
fi

mkdir -p "$ROOT/renders" "$ROOT/stl"

"${PNG_CMD[@]}" \
  -o "$ROOT/renders/geosphere_preview.png" \
  --imgsize=900,900 --viewall --autocenter --projection=p \
  --camera=0,0,0,55,0,25,150 --colorscheme=Tomorrow \
  "$ROOT/geosphere.scad"

"$OPENSCAD_BIN" -o "$ROOT/stl/geosphere.stl" "$ROOT/geosphere.scad"

echo "Wrote renders/geosphere_preview.png and stl/geosphere.stl"
