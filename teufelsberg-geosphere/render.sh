#!/usr/bin/env bash
# Render preview PNG and printable STL for the geodesic sphere.
#
# Prefers the fast Manifold-backend OpenSCAD (~4 s) over system CGAL (~7-12 min).
# See README ("Rendering engine") for why this matters and how it is installed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# pick the fastest OpenSCAD available
if [[ -n "${OPENSCAD_BIN:-}" ]]; then
  OPENSCAD_BIN="$OPENSCAD_BIN"
elif command -v openscad-manifold >/dev/null 2>&1; then
  OPENSCAD_BIN="openscad-manifold"
elif [[ -x "$HOME/.local/bin/openscad-manifold" ]]; then
  OPENSCAD_BIN="$HOME/.local/bin/openscad-manifold"
else
  OPENSCAD_BIN="openscad"
  echo "warning: openscad-manifold not found; falling back to system openscad (slow)" >&2
fi

PNG_CMD=("$OPENSCAD_BIN")
if [[ -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null 2>&1; then
  PNG_CMD=(xvfb-run -a "$OPENSCAD_BIN")   # PNG needs a GL context; STL does not
fi

mkdir -p "$ROOT/renders" "$ROOT/stl"

"${PNG_CMD[@]}" \
  -o "$ROOT/renders/geosphere_preview.png" \
  --imgsize=900,900 --viewall --autocenter --projection=p \
  --camera=0,0,0,55,0,20,150 --colorscheme=Tomorrow \
  "$ROOT/geosphere.scad"

"$OPENSCAD_BIN" -o "$ROOT/stl/geosphere.stl" "$ROOT/geosphere.scad"

echo "Wrote renders/geosphere_preview.png and stl/geosphere.stl (via $OPENSCAD_BIN)"
