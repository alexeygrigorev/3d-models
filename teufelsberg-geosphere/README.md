# Teufelsberg geodesic sphere

A **solid** ball whose surface is a geodesic **triangulation**, matching the
lower triangular radome domes at the former listening station on
[Teufelsberg](https://en.wikipedia.org/wiki/Teufelsberg) in Berlin.

It is a subdivided icosahedron projected onto the sphere: five triangles meet at
the 12 icosahedron vertices and six meet everywhere else, forming the classic
geodesic-dome pattern (pentagon nodes surrounded by hexagonal "flowers" of
triangles). The triangles are **not uniform** — their size and shape vary across
each of the 20 icosahedral regions.

> Note: the tall spherical radome at Teufelsberg uses *hexagonal* panels; the
> other (lower) domes are *triangular* geodesic domes. This model matches the
> triangular ones. A hexagonal (Goldberg) variant can be generated with
> `generate_goldberg.py` if you ever want that one instead.

![preview](renders/geosphere_preview.png)

The body is genuinely filled (not a hollow shell): it is the union of tetrahedral
wedges from the center out to every surface triangle, so it renders to a single
watertight solid (`Simple: yes`). Every triangle is shrunk toward its centroid,
opening a real recessed **groove along every edge/strut** — the seams are
geometry, visible in any viewer and in a print (an STL has no colors, so the
grooves read as dark lines rather than painted black).

## Parameters (`geosphere.scad`)

| name   | meaning |
|--------|---------|
| `R`    | sphere radius in mm |
| `freq` | geodesic frequency: `3` = 180 triangles, `4` = 320 (default), `5` = 500. Higher = finer mesh. The real domes look ~3V–4V. |
| `seam` | groove width as a fraction of each triangle (`0` = no seams) |

## Render

```bash
./render.sh
```

Writes `renders/geosphere_preview.png` and a printable `stl/geosphere.stl`.
(PNG needs a GL context; `render.sh` uses `xvfb-run` automatically when there is
no display. The STL export is pure CGAL and needs no display.)
