#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -n "${OPENSCAD_BIN:-}" ]]; then
  OPENSCAD_BIN="$OPENSCAD_BIN"
elif command -v openscad-manifold >/dev/null 2>&1; then
  OPENSCAD_BIN="openscad-manifold"
elif [[ -x "$HOME/.local/bin/openscad-manifold" ]]; then
  OPENSCAD_BIN="$HOME/.local/bin/openscad-manifold"
else
  OPENSCAD_BIN="openscad"
fi

if ! command -v "$OPENSCAD_BIN" >/dev/null 2>&1; then
  cat >&2 <<'EOF'
OpenSCAD CLI was not found.

Install OpenSCAD or set OPENSCAD_BIN to the executable path.
EOF
  exit 127
fi

PNG_CMD=("$OPENSCAD_BIN")
if [[ -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null 2>&1; then
  PNG_CMD=(xvfb-run -a "$OPENSCAD_BIN")
fi

mkdir -p "$ROOT/renders" "$ROOT/stl"

"${PNG_CMD[@]}" \
  -o "$ROOT/renders/butterfly_token_preview.png" \
  --imgsize=1200,900 --viewall --autocenter --projection=p \
  --camera=0,0,0,56,0,28,70 --colorscheme=Tomorrow \
  "$ROOT/butterfly_token.scad"

"$OPENSCAD_BIN" --export-format binstl \
  -o "$ROOT/stl/butterfly_token.stl" \
  "$ROOT/butterfly_token.scad"

"$OPENSCAD_BIN" --export-format binstl \
  -D 'part="white"' \
  -o "$ROOT/stl/butterfly_token_white.stl" \
  "$ROOT/butterfly_token.scad"

"$OPENSCAD_BIN" --export-format binstl \
  -D 'part="blue"' \
  -o "$ROOT/stl/butterfly_token_blue.stl" \
  "$ROOT/butterfly_token.scad"

echo "Wrote renders/butterfly_token_preview.png"
echo "Wrote stl/butterfly_token*.stl via $OPENSCAD_BIN"
