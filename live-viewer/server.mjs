import { createReadStream, promises as fs, watch } from "node:fs";
import http from "node:http";
import path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..");
const modelRoot = path.join(repoRoot, "matchbox-mattel-atv-6x6");
const outputRoot = path.join(__dirname, "generated");
const publicRoot = path.join(__dirname, "public");
const port = Number.parseInt(process.env.PORT || "4173", 10);
const openscadBin = process.env.OPENSCAD_BIN || "openscad";

const clients = new Set();
const renderTimers = new Map();
const renderState = new Map();

const contentTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".stl", "model/stl"],
]);

async function listScadFiles() {
  const entries = await fs.readdir(modelRoot, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile() && entry.name.endsWith(".scad"))
    .map((entry) => entry.name)
    .sort((a, b) => a.localeCompare(b));
}

function modelName(scadFile) {
  return path.basename(scadFile, ".scad");
}

function outputPath(scadFile) {
  return path.join(outputRoot, `${modelName(scadFile)}.stl`);
}

async function readScadConstants(scadFile) {
  const source = await fs.readFile(path.join(modelRoot, scadFile), "utf8");
  const constants = {};
  const assignmentPattern = /^\s*([A-Za-z_]\w*)\s*=\s*([^;]+);/gm;
  let match;

  while ((match = assignmentPattern.exec(source))) {
    const [, name, expression] = match;
    if (!/^[\d\s+\-*/().,\[\]A-Za-z_]+$/.test(expression)) {
      continue;
    }

    try {
      const keys = Object.keys(constants);
      constants[name] = Function(...keys, `"use strict"; return (${expression});`)(
        ...keys.map((key) => constants[key]),
      );
    } catch {
      // Some SCAD assignments may use syntax this tiny evaluator does not need.
    }
  }

  return constants;
}

async function previewMetadata(scadFile) {
  const constants = await readScadConstants(scadFile);
  const wheelDiameter = constants.wheel_diameter;
  const wheelWidth = constants.wheel_width;
  const wheelX = constants.wheel_x || constants.axle_x;

  if (!Array.isArray(wheelX) || !Number.isFinite(wheelDiameter) || !Number.isFinite(wheelWidth)) {
    return { wheels: [] };
  }

  if (scadFile === "white_bathtub_current.scad") {
    const z = constants.wheel_z ?? constants.wheel_center_z * constants.profile_z_scale;
    return {
      wheels: wheelX.map((x) => ({
        x,
        y: -wheelWidth / 2 - 1.0,
        z,
        width: wheelWidth,
        diameter: wheelDiameter,
      })),
    };
  }

  if (scadFile === "white_bathtub_3d.scad") {
    const z = constants.axle_z ?? constants.wheel_center_z * constants.profile_z_scale;
    const positiveY = constants.tub_width / 2 + wheelWidth / 2 - 0.25;
    const negativeY = -constants.tub_width / 2 - wheelWidth / 2 + 0.25;
    const axleInset = constants.preview_axle_inset ?? 0;
    const axleLength = constants.tub_width + wheelWidth * 2 - axleInset * 2;
    const axleDiameter = constants.axle_diameter ?? 1.4;

    return {
      axles: wheelX.map((x) => ({
        x,
        y: 0,
        z,
        length: axleLength,
        diameter: axleDiameter,
      })),
      wheels: wheelX.flatMap((x) => [positiveY, negativeY].map((y) => ({
        x,
        y,
        z,
        width: wheelWidth,
        diameter: wheelDiameter,
      }))),
    };
  }

  if (scadFile === "atv_6x6_body.scad") {
    const z = constants.axle_z;
    const offset = constants.wheel_side_offset;
    return {
      wheels: wheelX.flatMap((x) => [-offset, offset].map((y) => ({
        x,
        y,
        z,
        width: wheelWidth,
        diameter: wheelDiameter,
      }))),
    };
  }

  return { wheels: [] };
}

function sendEvent(type, payload) {
  const data = `event: ${type}\ndata: ${JSON.stringify(payload)}\n\n`;
  for (const client of clients) {
    client.write(data);
  }
}

function setState(scadFile, patch) {
  const previous = renderState.get(scadFile) || {};
  const next = { ...previous, ...patch };
  renderState.set(scadFile, next);
  sendEvent("status", { scadFile, ...next });
}

function renderScad(scadFile, reason = "manual") {
  return new Promise((resolve) => {
    const startedAt = Date.now();
    setState(scadFile, {
      status: "rendering",
      reason,
      message: "Rendering with OpenSCAD",
      startedAt,
    });

    const source = path.join(modelRoot, scadFile);
    const target = outputPath(scadFile);
    const args = [
      "-D",
      "show_preview_wheels=false",
      "-D",
      "show_preview_axles=false",
      "-D",
      "show_axles=false",
      "-o",
      target,
      source,
    ];

    const child = spawn(openscadBin, args, { cwd: modelRoot });
    let stderr = "";

    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    child.on("error", (error) => {
      const message = error.code === "ENOENT"
        ? `OpenSCAD executable not found: ${openscadBin}`
        : error.message;
      setState(scadFile, {
        status: "error",
        message,
        stderr,
        finishedAt: Date.now(),
      });
      resolve(false);
    });

    child.on("close", async (code) => {
      if (code === 0) {
        const finishedAt = Date.now();
        const preview = await previewMetadata(scadFile);
        setState(scadFile, {
          status: "ready",
          message: `Rendered in ${finishedAt - startedAt} ms`,
          stderr,
          finishedAt,
          url: `/generated/${modelName(scadFile)}.stl?v=${finishedAt}`,
        });
        sendEvent("model", {
          scadFile,
          url: `/generated/${modelName(scadFile)}.stl?v=${finishedAt}`,
          preview,
          finishedAt,
        });
        resolve(true);
        return;
      }

      setState(scadFile, {
        status: "error",
        message: `OpenSCAD exited with code ${code}`,
        stderr,
        finishedAt: Date.now(),
      });
      resolve(false);
    });
  });
}

function scheduleRender(scadFile, reason) {
  clearTimeout(renderTimers.get(scadFile));
  renderTimers.set(
    scadFile,
    setTimeout(() => {
      renderTimers.delete(scadFile);
      void renderScad(scadFile, reason);
    }, 300),
  );
}

async function apiModels(response) {
  const files = await listScadFiles();
  const models = await Promise.all(files.map(async (scadFile) => ({
    scadFile,
    name: modelName(scadFile),
    stlUrl: `/generated/${modelName(scadFile)}.stl`,
    preview: await previewMetadata(scadFile),
    state: renderState.get(scadFile) || { status: "queued" },
  })));
  json(response, 200, { modelRoot, models });
}

function json(response, status, payload) {
  response.writeHead(status, { "content-type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(payload));
}

async function sendFile(response, filePath) {
  try {
    const stat = await fs.stat(filePath);
    if (!stat.isFile()) {
      json(response, 404, { error: "not found" });
      return;
    }
    const ext = path.extname(filePath);
    response.writeHead(200, {
      "content-type": contentTypes.get(ext) || "application/octet-stream",
      "cache-control": "no-cache",
    });
    createReadStream(filePath).pipe(response);
  } catch {
    json(response, 404, { error: "not found" });
  }
}

function resolveStatic(root, requestPath) {
  const decoded = decodeURIComponent(requestPath);
  const clean = decoded === "/" ? "/index.html" : decoded;
  const candidate = path.resolve(root, `.${clean}`);
  return candidate.startsWith(root) ? candidate : null;
}

const server = http.createServer(async (request, response) => {
  try {
    const url = new URL(request.url || "/", `http://${request.headers.host}`);

    if (url.pathname === "/api/models") {
      await apiModels(response);
      return;
    }

    if (url.pathname === "/api/render" && request.method === "POST") {
      const scadFile = url.searchParams.get("file");
      const files = await listScadFiles();
      if (!scadFile || !files.includes(scadFile)) {
        json(response, 400, { error: "unknown model" });
        return;
      }
      scheduleRender(scadFile, "manual");
      json(response, 202, { ok: true });
      return;
    }

    if (url.pathname === "/events") {
      response.writeHead(200, {
        "content-type": "text/event-stream",
        "cache-control": "no-cache",
        connection: "keep-alive",
      });
      response.write("\n");
      clients.add(response);
      request.on("close", () => clients.delete(response));
      return;
    }

    if (url.pathname.startsWith("/generated/")) {
      const filePath = resolveStatic(outputRoot, url.pathname.replace("/generated", ""));
      await sendFile(response, filePath);
      return;
    }

    if (url.pathname.startsWith("/vendor/")) {
      const vendorRoot = path.join(__dirname, "node_modules", "three");
      const filePath = resolveStatic(vendorRoot, url.pathname.replace("/vendor", ""));
      await sendFile(response, filePath);
      return;
    }

    const filePath = resolveStatic(publicRoot, url.pathname);
    await sendFile(response, filePath);
  } catch (error) {
    json(response, 500, { error: error.message });
  }
});

await fs.mkdir(outputRoot, { recursive: true });

const initialFiles = await listScadFiles();
for (const scadFile of initialFiles) {
  renderState.set(scadFile, { status: "queued", message: "Waiting for initial render" });
}

watch(modelRoot, { persistent: true }, async (_eventType, filename) => {
  if (!filename || !filename.endsWith(".scad")) {
    return;
  }
  const files = await listScadFiles();
  if (files.includes(filename)) {
    scheduleRender(filename, "file changed");
  }
});

server.listen(port, () => {
  console.log(`Live 3D viewer: http://localhost:${port}`);
  console.log(`Watching: ${modelRoot}`);
});

for (const scadFile of initialFiles) {
  scheduleRender(scadFile, "initial");
}
