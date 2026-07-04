# Teufelsberg geodesic sphere

An irregular **geodesic triangulated sphere** in the pattern of the triangular
radome domes at the former listening station on
[Teufelsberg](https://en.wikipedia.org/wiki/Teufelsberg) in Berlin.

- The surface is **filled triangular panels** (a closed faceted shell) — the
  space bounded by the triangles is filled, so the sphere is **opaque**, not
  see-through.
- On top runs a **raised round frame**: a strut along every edge with a hub at
  every node, like the real dome's structural frame (the "bortik").
- Two triangulation methods (below): a subdivided icosahedron, or — closer to
  the real dome — the convex hull of an evenly spread Fibonacci point set.

![preview](renders/geosphere_preview.png)

## Files

- `geosphere.scad` — main model. **Generated**; edit the generator, not the file.
- `generate_triangulated.py` — subdivided-icosahedron generator (jittered
  vertices). Emits `geosphere.scad` and `geosphere_large_triangles.scad`. Nodes
  are only ever valence **5 or 6** — this pattern can never make a 7.
- `generate_delaunay.py` — **Fibonacci / convex-hull** generator → `geosphere_fibonacci.scad`.
- `geosphere_fibonacci.scad` — **generated** (`generate_delaunay.py 42`).
- `generate_goldberg.py` — alternative *hexagonal* (Goldberg) variant, matching
  the tall spherical radome instead of the triangular ones.
- `render.sh`, `renders/`, `stl/` — preview + printable STL.

### Fibonacci / convex-hull variant — closest to the real dome

`generate_delaunay.py` builds the node set in four steps, then triangulates it
by its convex hull (= Delaunay on the sphere):

1. **Fibonacci spiral** — spread N points evenly (a clean 5/6-only lattice).
2. **Jitter** — nudge them, injecting 5–7 defect pairs (this is what makes the
   **7**s; a subdivided icosahedron or a plain Fibonacci sphere never has any).
3. **Relax** — Lloyd/Laplacian smoothing to even the triangles back out (so they
   stay near-equilateral and **neat**) and dissolve stray valence-4/8 nodes.

The result reproduces the real radome's node mix: mostly **6** struts per node,
less often **5**, and here and there **7** (by Euler there are always exactly 12
more 5s than 7s, so this ordering is automatic). Default `N=152` → 300 triangles,
valence mix 5→45, 6→66, 7→37 (plus a few 4/8 nodes that add to the variety).

![fibonacci preview](renders/geosphere_fibonacci_preview.png)

```bash
python3 generate_delaunay.py 152 1.0 8 > geosphere_fibonacci.scad
#                            |   |   |
#                          N |   |   | relax passes (neatens triangles)
#                            |   | jitter (irregularity; more -> more 7s + variety)
```

- `N`: number of nodes. **Fewer = bigger triangles.** `N` gives `2N-4` triangles.
- `jitter`: irregularity. Low (`~0.6`) → uniform, only 5/6/7; high (`~1.0`) → more
  7s and more **size variety**, at the cost of the odd valence-4/8 node.
- `relax`: smoothing passes. Low (`~8`) keeps size variety; high (`~25`) evens the
  triangles out (can look too regular) and clears stray 4/8 nodes.

The RNG seed is fixed (`random.seed(20)`); change N/jitter/relax and you may want a
different seed for a nicer mix (the generator prints the valence counts to stderr).

## Parameters (subdivided-icosahedron variant)

Pattern is set when generating:

```bash
python3 generate_triangulated.py 4 0.35 > geosphere.scad
#                                 |    |
#                            freq |    | jitter (irregularity, 0 = perfect grid)
```

- `freq` 3–6: geodesic frequency (higher = more, smaller triangles).
- `jitter`: how irregular the triangles are (≈0.25 subtle … 0.5 wild).

Live parameters at the top of `geosphere.scad`:

| name | meaning |
|------|---------|
| `R` | sphere radius (mm) |
| `rim` | strut radius → raised border thickness |
| `node` | hub radius at each vertex (set `= rim` to drop distinct hubs) |
| `strut_fn` | strut/hub roundness (segments); higher = rounder |
| `fill` | `true` = filled opaque panels; `false` = hollow see-through cage |

## Rendering engine — IMPORTANT (Manifold vs CGAL)

This model unions ~640 rounded solids (a strut + hub per edge/node). The old
**CGAL** backend in system OpenSCAD (2021.01) is *extremely* slow at this:
**7–12 minutes** per render, and it gets worse as `strut_fn` (roundness) goes up.

The **Manifold** backend (OpenSCAD 2023+) does the exact same booleans in
**~2–4 seconds**. Same geometry, ~100× faster. This is the difference between an
unusable and an instant live-preview loop — always use Manifold for this model.

System `openscad` here is 2021.01 (CGAL only, no `--backend` flag). A newer
build is installed locally so we get Manifold:

- Binary: `~/.local/opt/openscad-nightly/usr/bin/openscad` (OpenSCAD 2026.07.01,
  extracted from the official AppImage at <https://files.openscad.org/snapshots/>).
- Wrapper that forces the fast backend: **`~/.local/bin/openscad-manifold`**
  (just runs the above with `--backend=manifold "$@"`).

Use it directly, e.g.:

```bash
openscad-manifold -o stl/geosphere.stl geosphere.scad     # ~4 s, Status: NoError
```

The live viewer is pointed at it via `OPENSCAD_BIN`:

```bash
cd ../live-viewer
MODEL_DIR=../teufelsberg-geosphere OPENSCAD_BIN=$HOME/.local/bin/openscad-manifold \
  node server.mjs        # renders each edit in ~4 s instead of minutes
```

To reinstall the engine if it's ever lost:

```bash
curl -O https://files.openscad.org/snapshots/OpenSCAD-2026.07.01-x86_64.AppImage
chmod +x OpenSCAD-2026.07.01-x86_64.AppImage
./OpenSCAD-2026.07.01-x86_64.AppImage --appimage-extract      # -> squashfs-root/
mkdir -p ~/.local/opt && cp -r squashfs-root ~/.local/opt/openscad-nightly
printf '#!/usr/bin/env bash\nexec %s/.local/opt/openscad-nightly/usr/bin/openscad --backend=manifold "$@"\n' "$HOME" \
  > ~/.local/bin/openscad-manifold && chmod +x ~/.local/bin/openscad-manifold
```

## STL size

Two things keep the STL small (it was ~25 MB before):

- **Binary STL** (`--export-format binstl`) — ~5× smaller than the CLI-default
  ASCII. Used by `render.sh` and the live viewer.
- **Cylinder struts** — each edge is a `cylinder` (node spheres cover the caps)
  instead of a `hull()` of two spheres, which carried hundreds of triangles each.

Result: ~1.9 MB (freq 4) / ~1.1 MB (freq 3). Lower `strut_fn` to shrink further.

## Render

```bash
./render.sh      # uses openscad-manifold automatically, exports binary STL
```
