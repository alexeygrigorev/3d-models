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

Environment variables:

- `PORT=4173` changes the HTTP port.
- `OPENSCAD_BIN=openscad` changes the OpenSCAD executable.
