import * as THREE from "/vendor/build/three.module.js";
import { OrbitControls } from "/vendor/examples/jsm/controls/OrbitControls.js";
import { STLLoader } from "/vendor/examples/jsm/loaders/STLLoader.js";

const canvas = document.querySelector("#canvas");
const statusEl = document.querySelector("#status");
const modelSelectEl = document.querySelector("#modelSelect");
const logEl = document.querySelector("#log");
const renderButton = document.querySelector("#renderButton");
const resetButton = document.querySelector("#resetButton");
const wireToggle = document.querySelector("#wireToggle");
const gridToggle = document.querySelector("#gridToggle");

const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, preserveDrawingBuffer: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setClearColor(0x121412, 1);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(45, 1, 0.1, 10000);
camera.position.set(110, 90, 110);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.touches = {
  ONE: THREE.TOUCH.ROTATE,
  TWO: THREE.TOUCH.DOLLY_ROTATE,
};
controls.rotateSpeed = 0.7;
controls.zoomSpeed = 0.9;
controls.panSpeed = 0.8;

const loader = new STLLoader();
const material = new THREE.MeshStandardMaterial({
  color: 0xe8e2d1,
  roughness: 0.52,
  metalness: 0.06,
});

const grid = new THREE.GridHelper(240, 24, 0x6d7568, 0x333a32);
scene.add(grid);

scene.add(new THREE.HemisphereLight(0xf3f0df, 0x243339, 2.8));

const keyLight = new THREE.DirectionalLight(0xffffff, 3);
keyLight.position.set(120, 180, 90);
scene.add(keyLight);

const modelGroup = new THREE.Group();
scene.add(modelGroup);

const previewGroup = new THREE.Group();
modelGroup.add(previewGroup);

const wheelMaterial = new THREE.MeshStandardMaterial({
  color: 0xf1ead7,
  transparent: true,
  opacity: 0.36,
  roughness: 0.38,
  metalness: 0.02,
  depthWrite: false,
});

const wheelLineMaterial = new THREE.LineBasicMaterial({
  color: 0x5c655f,
  transparent: true,
  opacity: 0.58,
});

const axleMaterial = new THREE.MeshStandardMaterial({
  color: 0x4b4a43,
  roughness: 0.45,
  metalness: 0.18,
});

let models = [];
let selected = null;
let mesh = null;
const touchPointers = new Map();
let touchGesture = null;

function log(message) {
  const time = new Date().toLocaleTimeString();
  logEl.textContent = `[${time}] ${message}\n${logEl.textContent}`.slice(0, 5000);
}

function setStatus(message) {
  statusEl.textContent = message;
}

function resize() {
  const { clientWidth, clientHeight } = canvas.parentElement;
  renderer.setSize(clientWidth, clientHeight, false);
  camera.aspect = clientWidth / Math.max(clientHeight, 1);
  camera.updateProjectionMatrix();
}

function frameObject(object) {
  const box = new THREE.Box3().setFromObject(object);
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  const maxHorizontal = Math.max(size.x, size.y, 1);
  const maxVertical = Math.max(size.z, 1);
  const verticalFov = THREE.MathUtils.degToRad(camera.fov);
  const horizontalFov = 2 * Math.atan(Math.tan(verticalFov / 2) * camera.aspect);
  const distance = Math.max(
    maxVertical / (2 * Math.tan(verticalFov / 2)),
    maxHorizontal / (2 * Math.tan(horizontalFov / 2)),
  ) * 1.75;
  const viewDirection = new THREE.Vector3(0.72, 0.46, 0.52).normalize();

  controls.target.copy(center);
  camera.position.copy(center).add(viewDirection.multiplyScalar(distance));
  camera.near = Math.max(distance / 1000, 0.1);
  camera.far = distance * 10;
  camera.updateProjectionMatrix();
  controls.update();
}

function cameraStateFromCurrentView() {
  const target = controls.target.clone();
  const offset = camera.position.clone().sub(target);
  return {
    target,
    spherical: new THREE.Spherical().setFromVector3(offset),
    up: camera.up.clone(),
  };
}

function applyOrbitGesture({ dx, dy, zoom = 1, roll = 0 }) {
  if (!touchGesture) {
    return;
  }

  const rotateScale = 0.0065;
  const state = touchGesture.camera;
  const spherical = state.spherical.clone();
  spherical.theta -= dx * rotateScale;
  spherical.phi -= dy * rotateScale;
  spherical.phi = Math.max(0.03, Math.min(Math.PI - 0.03, spherical.phi));
  spherical.radius = Math.max(0.5, Math.min(10000, state.spherical.radius * zoom));

  const offset = new THREE.Vector3().setFromSpherical(spherical);
  camera.position.copy(state.target).add(offset);
  camera.up.copy(state.up);

  if (roll !== 0) {
    const viewAxis = camera.position.clone().sub(state.target).normalize();
    camera.up.applyAxisAngle(viewAxis, roll);
  }

  camera.lookAt(state.target);
  controls.target.copy(state.target);
}

function renderModelSelect() {
  const selectedFile = selected?.scadFile;
  modelSelectEl.textContent = "";
  for (const model of models) {
    const option = document.createElement("option");
    option.value = model.scadFile;
    option.textContent = `${model.name} (${model.state?.status || "unknown"})`;
    modelSelectEl.append(option);
  }
  if (selectedFile) {
    modelSelectEl.value = selectedFile;
  }
}

function updateModelState(scadFile, state) {
  const model = models.find((item) => item.scadFile === scadFile);
  if (!model) {
    return;
  }
  model.state = { ...model.state, ...state };
  renderModelSelect();
}

function selectModel(scadFile) {
  selected = models.find((model) => model.scadFile === scadFile) || models[0] || null;
  renderModelSelect();
  if (selected) {
    loadStl(`${selected.stlUrl}?v=${Date.now()}`);
  }
}

function clearPreviewWheels() {
  for (const child of [...previewGroup.children]) {
    previewGroup.remove(child);
    child.geometry?.dispose();
    if (child.children) {
      for (const nested of child.children) {
        nested.geometry?.dispose();
      }
    }
  }
}

function previewAxles(model) {
  if (model.preview?.axles?.length) {
    return model.preview.axles;
  }

  if (model.scadFile !== "white_bathtub_3d.scad") {
    return [];
  }

  const wheelsByX = new Map();
  for (const wheel of model.preview?.wheels || []) {
    const key = String(wheel.x);
    const wheels = wheelsByX.get(key) || [];
    wheels.push(wheel);
    wheelsByX.set(key, wheels);
  }

  return [...wheelsByX.values()].flatMap((wheels) => {
    if (wheels.length < 2) {
      return [];
    }
    const ys = wheels.map((wheel) => wheel.y);
    const wheel = wheels[0];
    return [{
      x: wheel.x,
      y: 0,
      z: wheel.z,
      length: Math.max(...ys) - Math.min(...ys) + wheel.width - 1.3,
      diameter: 1.4,
    }];
  });
}

function addPreviewWheels(model) {
  clearPreviewWheels();

  for (const axle of previewAxles(model)) {
    const geometry = new THREE.CylinderGeometry(axle.diameter / 2, axle.diameter / 2, axle.length, 32, 1);
    const axleMesh = new THREE.Mesh(geometry, axleMaterial);
    axleMesh.position.set(axle.x, axle.y, axle.z);
    axleMesh.renderOrder = 1;
    previewGroup.add(axleMesh);
  }

  for (const wheel of model.preview?.wheels || []) {
    const geometry = new THREE.CylinderGeometry(wheel.diameter / 2, wheel.diameter / 2, wheel.width, 64, 1);
    const wheelMesh = new THREE.Mesh(geometry, wheelMaterial);
    wheelMesh.position.set(wheel.x, wheel.y, wheel.z);
    wheelMesh.renderOrder = 2;

    const edges = new THREE.LineSegments(new THREE.EdgesGeometry(geometry, 20), wheelLineMaterial);
    edges.renderOrder = 3;
    wheelMesh.add(edges);

    previewGroup.add(wheelMesh);
  }
}

function loadStl(url) {
  if (!selected) {
    return;
  }
  setStatus(`Loading ${selected.scadFile}`);
  loader.load(
    url,
    (geometry) => {
      geometry.computeVertexNormals();
      if (mesh) {
        modelGroup.remove(mesh);
        mesh.geometry.dispose();
      }
      mesh = new THREE.Mesh(geometry, material);
      modelGroup.add(mesh);
      addPreviewWheels(selected);
      frameObject(modelGroup);
      setStatus(`Viewing ${selected.scadFile}`);
      log(`Loaded ${selected.scadFile}`);
    },
    undefined,
    () => {
      setStatus(`Waiting for render: ${selected.scadFile}`);
      log(`No STL ready yet for ${selected.scadFile}`);
    },
  );
}

async function loadModels() {
  const response = await fetch("/api/models");
  const data = await response.json();
  models = data.models;
  selected = models[0] || null;
  renderModelSelect();
  if (selected) {
    loadStl(`${selected.stlUrl}?v=${Date.now()}`);
  }
}

modelSelectEl.addEventListener("change", () => {
  selectModel(modelSelectEl.value);
});

renderButton.addEventListener("click", async () => {
  if (!selected) {
    return;
  }
  await fetch(`/api/render?file=${encodeURIComponent(selected.scadFile)}`, { method: "POST" });
  log(`Render requested for ${selected.scadFile}`);
});

resetButton.addEventListener("click", () => {
  if (mesh) {
    frameObject(modelGroup);
  }
});

wireToggle.addEventListener("change", () => {
  material.wireframe = wireToggle.checked;
});

gridToggle.addEventListener("change", () => {
  grid.visible = gridToggle.checked;
});

function orderedTouchEntries() {
  return [...touchPointers.entries()].sort(([leftId], [rightId]) => leftId - rightId);
}

function touchPoint(event) {
  return { x: event.clientX, y: event.clientY };
}

function distanceBetween(first, second) {
  return Math.hypot(second.x - first.x, second.y - first.y);
}

function centerBetween(first, second) {
  return {
    x: (first.x + second.x) / 2,
    y: (first.y + second.y) / 2,
  };
}

function angleBetween(first, second) {
  return Math.atan2(second.y - first.y, second.x - first.x);
}

function normalizedAngle(delta) {
  return Math.atan2(Math.sin(delta), Math.cos(delta));
}

function startTouchGesture() {
  const entries = orderedTouchEntries();
  const camera = cameraStateFromCurrentView();

  if (entries.length === 1) {
    const [, point] = entries[0];
    touchGesture = {
      type: "one",
      camera,
      start: { ...point },
    };
    return;
  }

  if (entries.length >= 2) {
    const first = entries[0][1];
    const second = entries[1][1];
    touchGesture = {
      type: "two",
      camera,
      center: centerBetween(first, second),
      distance: Math.max(distanceBetween(first, second), 1),
      angle: angleBetween(first, second),
    };
  }
}

function updateTouchGesture() {
  if (!touchGesture) {
    return;
  }

  const entries = orderedTouchEntries();
  if (touchGesture.type === "one" && entries.length === 1) {
    const point = entries[0][1];
    applyOrbitGesture({
      dx: point.x - touchGesture.start.x,
      dy: point.y - touchGesture.start.y,
    });
    return;
  }

  if (touchGesture.type === "two" && entries.length >= 2) {
    const first = entries[0][1];
    const second = entries[1][1];
    const center = centerBetween(first, second);
    const zoom = touchGesture.distance / Math.max(distanceBetween(first, second), 1);
    const roll = normalizedAngle(angleBetween(first, second) - touchGesture.angle);

    applyOrbitGesture({
      dx: center.x - touchGesture.center.x,
      dy: center.y - touchGesture.center.y,
      zoom,
      roll,
    });
  }
}

function handleTouchPointerDown(event) {
  if (event.pointerType !== "touch") {
    return;
  }
  event.preventDefault();
  event.stopImmediatePropagation();
  canvas.setPointerCapture(event.pointerId);
  touchPointers.set(event.pointerId, touchPoint(event));
  startTouchGesture();
}

function handleTouchPointerMove(event) {
  if (event.pointerType !== "touch" || !touchPointers.has(event.pointerId)) {
    return;
  }
  event.preventDefault();
  event.stopImmediatePropagation();
  touchPointers.set(event.pointerId, touchPoint(event));
  updateTouchGesture();
}

function handleTouchPointerUp(event) {
  if (event.pointerType !== "touch") {
    return;
  }
  event.preventDefault();
  event.stopImmediatePropagation();
  touchPointers.delete(event.pointerId);
  if (canvas.hasPointerCapture(event.pointerId)) {
    canvas.releasePointerCapture(event.pointerId);
  }
  touchGesture = null;
  if (touchPointers.size > 0) {
    startTouchGesture();
  }
}

canvas.addEventListener("pointerdown", handleTouchPointerDown, { capture: true });
canvas.addEventListener("pointermove", handleTouchPointerMove, { capture: true });
canvas.addEventListener("pointerup", handleTouchPointerUp, { capture: true });
canvas.addEventListener("pointercancel", handleTouchPointerUp, { capture: true });

const events = new EventSource("/events");
events.addEventListener("open", () => setStatus("Connected"));
events.addEventListener("status", (event) => {
  const data = JSON.parse(event.data);
  updateModelState(data.scadFile, data);
  log(`${data.scadFile}: ${data.message}`);
  if (selected?.scadFile === data.scadFile) {
    setStatus(`${data.scadFile}: ${data.message}`);
  }
});
events.addEventListener("model", (event) => {
  const data = JSON.parse(event.data);
  const model = models.find((item) => item.scadFile === data.scadFile);
  if (model && data.preview) {
    model.preview = data.preview;
  }
  if (selected?.scadFile === data.scadFile) {
    loadStl(data.url);
  }
});
events.addEventListener("error", () => setStatus("Reconnecting..."));

function animate() {
  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}

window.addEventListener("resize", resize);
resize();
void loadModels();
animate();
