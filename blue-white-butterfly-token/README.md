# Blue/white butterfly-slot token

OpenSCAD model of the small round plastic token from the photo reference.

- Measured outer diameter: **28.9 mm**
- Units: millimeters
- Main file: `butterfly_token.scad`
- Preview/STL helper: `render.sh`

The model is double-sided: the same relief is repeated on the top and bottom.
It includes the white body, raised outer rim, recessed blue annular inlay,
central white shelf, one narrow circular groove around the opening, and the rounded
butterfly/bow-tie through-slot.

## Parameters

Important dimensions are at the top of `butterfly_token.scad`:

| name | meaning |
|------|---------|
| `outer_d` | measured outside diameter |
| `total_h` | total token thickness |
| `blue_h` | height of the blue inlay |
| `blue_surface_drop` | how far the blue surface sits below the white ribs |
| `outer_rim_w` | width of the outside white rim |
| `center_r` | radius of the raised center island |
| `slot_groove_r` | center radius of the single circular groove around the slot |
| `slot_groove_profile_r` | radius/depth of that narrow groove profile |

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
