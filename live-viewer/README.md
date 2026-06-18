# Live 3D Model Viewer

Browser viewer with an OpenSCAD watcher.

```bash
cd live-viewer
npm install
npm start
```

Open http://localhost:4173.

The server watches `../matchbox-mattel-atv-6x6/*.scad`. When a file changes, it
exports a fresh STL with OpenSCAD into `generated/` and pushes a live update to
the browser.

The selected model is reflected in the browser path, for example:

```text
http://localhost:4173/white_bathtub_3d.scad
```

Raw model sources are available under `/source/`, for example:

```text
http://localhost:4173/source/white_bathtub_3d.scad
```

The drawing layer can save marked-up feedback as PNG + JSON under:

```text
../matchbox-mattel-atv-6x6/feedback/
```

Saved JSON includes the selected model, text note, camera state, strokes, and
projection/debug coordinates for drawn points.

Environment variables:

- `PORT=4173` changes the HTTP port.
- `OPENSCAD_BIN=openscad` changes the OpenSCAD executable.
