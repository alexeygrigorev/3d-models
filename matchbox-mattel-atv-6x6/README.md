# Matchbox/Mattel ATV 6x6

Work-in-progress OpenSCAD model of the lower white bathtub/chassis profile and
first simple 3D bathtub draft.

## Files

- `white_bathtub_current.scad` - current accepted side-profile work file.
- `white_bathtub_3d.scad` - first 3D bathtub draft built from the profile.
- `atv_6x6_body.scad` - older full-body/reference draft.
- `docs/construction_notes.md` - modeling notes and current decisions.
- `docs/agent_handoff.md` - instructions for the next agent.
- `scripts/render.sh` - OpenSCAD render/export helper for Linux.

The current focus is the white lower bathtub. Wheels in the SCAD files are
transparent preview geometry for fit checking.

## Rendering

On a machine with OpenSCAD CLI:

```bash
cd matchbox-mattel-atv-6x6
chmod +x scripts/render.sh
./scripts/render.sh
```

Generated PNGs and STLs are written to ignored `renders/` and `stl/` folders.
