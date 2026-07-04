#!/usr/bin/env python3
"""
Generate a Teufelsberg-radome triangulated sphere from an EVENLY DISTRIBUTED
point set triangulated by its convex hull (= Delaunay/Voronoi on the sphere).

Why not the subdivided icosahedron (generate_triangulated.py)?  A geodesic
subdivision only ever has valence-5 nodes (the 12 icosahedron corners) and
valence-6 nodes everywhere else - it can NEVER produce a 7. The real domes read
differently: at most nodes SIX struts meet, less often FIVE, and here and there
(especially near the top) SEVEN. By Euler there are always exactly 12 more 5s
than 7s, so 6 dominates, 5 is less common and 7 rarer still - just as observed.

To get that 5/6/7 mix with NEAT (near-equilateral) triangles we:
  1. spread N points evenly with a Fibonacci spiral (a clean 5/6-only lattice),
  2. JITTER them, which injects 5-7 defect pairs (the 7s), then
  3. RELAX (Lloyd/Laplacian smoothing) to even the triangles back out while
     keeping those defects - and to dissolve any stray valence-4/8 nodes,
  4. triangulate by the convex hull (= Delaunay on the sphere).

Bigger triangles  ==  fewer points (N).  N points -> 2N-4 triangles.

The body is a solid faceted ball; the pattern is a network of RAISED round
struts along every edge with a small hub at every node - the dome's frame.

Usage:  python3 generate_delaunay.py [N] [jitter] [relax] > geosphere_fibonacci.scad
        N       default 62  (number of nodes; fewer = bigger triangles)
        jitter  default 0.6 (irregularity; more -> more 7s, but risks 4/8 nodes)
        relax   default 25  (smoothing passes; neatens triangles, clears 4/8)
"""
import math
import random
import sys
from collections import Counter, defaultdict

N = int(sys.argv[1]) if len(sys.argv) > 1 else 152
JIT = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0
RELAX = int(sys.argv[3]) if len(sys.argv) > 3 else 8
random.seed(20)  # chosen so the jitter yields mostly 5/6/7 with lots of variety


def norm(p):
    l = math.sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2])
    return (p[0] / l, p[1] / l, p[2] / l)


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def scale(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


# --- evenly distributed points: Fibonacci sphere -------------------------
def fibonacci_sphere(n):
    pts = []
    ga = math.pi * (3.0 - math.sqrt(5.0))   # golden angle
    for i in range(n):
        z = 1.0 - 2.0 * (i + 0.5) / n
        r = math.sqrt(max(0.0, 1.0 - z * z))
        th = ga * i
        pts.append((r * math.cos(th), r * math.sin(th), z))
    return pts


# --- convex hull of points on the sphere = the triangulation -------------
# All points lie on a sphere centred at the origin, so every point is on the
# hull. Incremental hull; each face is kept consistently oriented (outward).
def convex_hull(pts):
    n = len(pts)
    # Seed with four WELL-SEPARATED points (nearby points give a sliver tetra
    # that may not enclose the origin, which would flip the orientation test).
    seed = [0, n // 4, n // 2, (3 * n) // 4]
    inside = scale(add(add(pts[seed[0]], pts[seed[1]]),
                       add(pts[seed[2]], pts[seed[3]])), 0.25)  # tetra centroid

    faces = []
    for tri in ((seed[0], seed[1], seed[2]), (seed[0], seed[2], seed[3]),
                (seed[0], seed[3], seed[1]), (seed[1], seed[3], seed[2])):
        a, b, c = pts[tri[0]], pts[tri[1]], pts[tri[2]]
        nrm = cross(sub(b, a), sub(c, a))
        cen = scale(add(add(a, b), c), 1.0 / 3.0)
        # outward = normal points away from the tetra's interior centroid
        faces.append(tri if dot(nrm, sub(cen, inside)) > 0
                     else (tri[0], tri[2], tri[1]))

    for pi in range(n):
        if pi in seed:
            continue
        p = pts[pi]
        visible = [f for f in faces
                   if dot(cross(sub(pts[f[1]], pts[f[0]]), sub(pts[f[2]], pts[f[0]])),
                          sub(p, pts[f[0]])) > 1e-12]
        if not visible:
            continue
        vis = set(visible)
        dedges = set()
        for (a, b, c) in visible:
            dedges.add((a, b)); dedges.add((b, c)); dedges.add((c, a))
        horizon = [(u, v) for (u, v) in dedges if (v, u) not in dedges]
        faces = [f for f in faces if f not in vis]
        for (u, v) in horizon:
            faces.append((u, v, pi))
    return faces


def relax(pts, iters):
    # Laplacian smoothing on the sphere: move each node to the (re-normalised)
    # mean of its Delaunay neighbours. Evens out triangle size/shape while
    # keeping the 5/6/7 topology, and dissolves stray valence-4/8 defects.
    for _ in range(iters):
        adj = defaultdict(set)
        for (a, b, c) in convex_hull(pts):
            adj[a] |= {b, c}
            adj[b] |= {a, c}
            adj[c] |= {a, b}
        moved = []
        for i, v in enumerate(pts):
            if not adj[i]:
                moved.append(v)
                continue
            m = (0.0, 0.0, 0.0)
            for j in adj[i]:
                m = add(m, pts[j])
            moved.append(norm(m))
        pts = moved
    return pts


# --- build the mesh: Fibonacci spread -> jitter -> relax -> triangulate ---
verts = fibonacci_sphere(N)

if JIT > 0:
    spacing = 2.0 / math.sqrt(N)   # ~ mean point spacing on unit sphere
    jit = []
    for v in verts:
        n = v
        ref = (0, 0, 1) if abs(n[2]) < 0.9 else (1, 0, 0)
        u = norm(cross(n, ref))
        w = cross(n, u)
        ang = random.uniform(0, 2 * math.pi)
        mag = JIT * spacing * random.uniform(0.0, 1.0)
        off = add(scale(u, math.cos(ang) * mag), scale(w, math.sin(ang) * mag))
        jit.append(norm(add(v, off)))
    verts = jit

if RELAX > 0:
    verts = relax(verts, RELAX)

faces = convex_hull(verts)

# --- unique edges --------------------------------------------------------
edge_set = set()
for (a, b, c) in faces:
    for (x, y) in ((a, b), (b, c), (c, a)):
        edge_set.add((min(x, y), max(x, y)))
edges = sorted(edge_set)

# --- node valence report (how many struts meet at each node) -------------
val = [0] * len(verts)
for (a, b) in edges:
    val[a] += 1
    val[b] += 1
from collections import Counter
vc = Counter(val)

# --- wind each face for OpenSCAD (CW seen from outside -> normal inward) --
oriented = []
for (a, b, c) in faces:
    va, vb, vc_ = verts[a], verts[b], verts[c]
    n = cross(sub(vb, va), sub(vc_, va))
    oriented.append((a, c, b) if dot(n, va) > 0 else (a, b, c))
faces = oriented


# --- emit OpenSCAD -------------------------------------------------------
def vec(p):
    return "[%.6f, %.6f, %.6f]" % p


out = []
out.append("/*")
out.append("  Teufelsberg triangulated sphere - convex-hull triangulation of an")
out.append("  evenly spread (Fibonacci) point set: nodes of valence 5/6/7 like the")
out.append("  real radome, with near-equilateral (neat) triangles.")
out.append("  Units: millimeters.  GENERATED by generate_delaunay.py - edit that, not this.")
out.append("")
out.append("  %d nodes, %d triangles, %d struts." % (len(verts), len(faces), len(edges)))
out.append("  Node valence mix: " + ", ".join("%d->%d" % (k, vc[k]) for k in sorted(vc)))
out.append("")
out.append("  Regenerate:  python3 generate_delaunay.py <N> <jitter> <relax> > geosphere_fibonacci.scad")
out.append("*/")
out.append("")
out.append("R    = 15;    // sphere radius (mm)")
out.append("rim  = 0.45;  // strut radius (mm) -> raised border thickness")
out.append("node = 0.65;  // hub radius at each vertex (mm); set = rim to disable distinct hubs")
out.append("strut_fn = 16;   // strut/hub roundness (segments); higher = rounder, heavier")
out.append("")
out.append("fill = true;  // true = filled opaque triangle panels; false = hollow see-through cage")
out.append("")
out.append("verts = [")
for v in verts:
    out.append("  %s," % vec(v))
out.append("];")
out.append("")
out.append("faces = [")
for (a, b, c) in faces:
    out.append("  [%d, %d, %d]," % (a, b, c))
out.append("];")
out.append("")
out.append("edges = [")
for (a, b) in edges:
    out.append("  [%d, %d]," % (a, b))
out.append("];")
out.append("")
out.append("// light strut = a cylinder a->b (far fewer triangles than a hull of two")
out.append("// spheres); the node hubs cover the flat end caps.")
out.append("module strut(i, j) {")
out.append("  a = verts[i] * R;")
out.append("  b = verts[j] * R;")
out.append("  d = b - a;")
out.append("  h = norm(d);")
out.append("  translate(a)")
out.append("    rotate([0, acos(d[2] / h), atan2(d[1], d[0])])")
out.append("      cylinder(h = h, r = rim, $fn = strut_fn);")
out.append("}")
out.append("")
out.append("union() {")
out.append("  if (fill) polyhedron(points = [for (p = verts) p * R], faces = faces);  // filled panels")
out.append("  for (e = edges) strut(e[0], e[1]);                          // raised borders")
out.append("  for (v = verts) translate(v * R) sphere(node, $fn = strut_fn);  // hubs")
out.append("}")
out.append("")

sys.stdout.write("\n".join(out))
sys.stderr.write("fibonacci-hull N=%d jitter=%.2f: %d triangles, %d struts, %d nodes; valence %s\n"
                 % (N, JIT, len(faces), len(edges), len(verts),
                    ", ".join("%d:%d" % (k, vc[k]) for k in sorted(vc))))
