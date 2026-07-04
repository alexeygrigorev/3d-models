# Blue/white butterfly-slot token

OpenSCAD model of the small round plastic token from the photo reference.

- Measured outer diameter: **28.9 mm**
- Units: millimeters
- Main file: `butterfly_token.scad`
- Preview/STL helper: `render.sh`

The model is double-sided: the same relief is repeated on the top and bottom.
It includes the white body, raised outer rim, recessed blue annular inlay,
raised central rim, recessed center basin, and the rounded butterfly/bow-tie
through-slot.

## Parameters

Important dimensions are at the top of `butterfly_token.scad`:

| name | meaning |
|------|---------|
| `outer_d` | measured outside diameter |
| `total_h` | total token thickness |
| `recess_drop` | depth of the blue and center recessed fields |
| `blue_h` | height of the blue inlay |
| `blue_surface_drop` | how far the blue surface sits below the white ribs |
| `outer_rim_w` | width of the outside white rim |
| `center_r` | radius of the raised center island |
| `slot_basin_r` | radius of the recessed center field around the slot |

Set `part` to export either the complete model or split color parts:

```openscad
part = "assembled"; // "assembled", "white", or "blue"
```

## Render

```bash
cd blue-white-butterfly-token
chmod +x render.sh
./render.sh
```

Generated files:

- `renders/butterfly_token_preview.png`
- `stl/butterfly_token.stl`
- `stl/butterfly_token_white.stl`
- `stl/butterfly_token_blue.stl`
