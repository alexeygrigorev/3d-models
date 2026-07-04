/*
  Blue/white butterfly-slot token from photo reference.
  Units: millimeters.

  Measured outer diameter: 28.9 mm.

  The model is intentionally parametric so the diameter, thickness, inlay
  heights, and keyhole can be adjusted after another measurement.
*/

$fn = 128;

part = "assembled"; // "assembled", "white", or "blue"

outer_d = 28.9;
total_h = 2.35;
blue_h = 0.22;
blue_surface_drop = 0.16;
blue_pocket_depth = blue_surface_drop + blue_h;

outer_r = outer_d / 2;
outer_rim_w = 1.45;
blue_outer_r = outer_r - outer_rim_w;
center_r = 6.75;
blue_inner_r = center_r + 0.12;
slot_groove_r = 5.15;
slot_groove_profile_r = 0.045;

bevel = 0.28;

module annulus_2d(r_outer, r_inner) {
    difference() {
        circle(r = r_outer);
        circle(r = r_inner);
    }
}

module soft_disc(d, h) {
    r = d / 2;

    rotate_extrude(convexity = 10)
        polygon(points=[
            [0, -h / 2],
            [r - bevel, -h / 2],
            [r, -h / 2 + bevel],
            [r, h / 2 - bevel],
            [r - bevel, h / 2],
            [0, h / 2]
        ]);
}

function cr1(p0, p1, p2, p3, t) =
    0.5 * (
        2 * p1 +
        (-p0 + p2) * t +
        (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t +
        (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t
    );

function cr_point(p0, p1, p2, p3, t) = [
    cr1(p0[0], p1[0], p2[0], p3[0], t),
    cr1(p0[1], p1[1], p2[1], p3[1], t)
];

function smooth_closed_path(points, steps = 6) = [
    for (i = [0 : len(points) - 1], s = [0 : steps - 1])
        cr_point(
            points[(i + len(points) - 1) % len(points)],
            points[i],
            points[(i + 1) % len(points)],
            points[(i + 2) % len(points)],
            s / steps
        )
];

module butterfly_slot_2d() {
    /*
      Opening traced from the close-up reference photo, normalized to the
      measured token size, then mirrored left/right to remove photo perspective.
      The points keep the real outline's high wings, deep top notch, pinched
      waist, and uneven lower scallop.
    */
    polygon(points = smooth_closed_path([
        [ 0.000,  0.780],
        [ 0.800,  1.450],
        [ 1.850,  2.200],
        [ 2.550,  2.250],
        [ 2.950,  1.950],
        [ 3.050,  1.400],
        [ 2.750, -0.200],
        [ 3.000, -0.720],
        [ 2.450, -1.550],
        [ 2.050, -2.000],
        [ 1.350, -2.200],
        [ 0.600, -1.920],
        [ 0.120, -2.120],
        [ 0.000, -2.000],
        [-0.120, -2.120],
        [-0.600, -1.920],
        [-1.350, -2.200],
        [-2.050, -2.000],
        [-2.450, -1.550],
        [-3.000, -0.720],
        [-2.750, -0.200],
        [-3.050,  1.400],
        [-2.950,  1.950],
        [-2.550,  2.250],
        [-1.850,  2.200],
        [-0.800,  1.450]
    ], 7));
}

module slot_cut() {
    translate([0, 0, -total_h / 2 - 0.1])
        linear_extrude(height = total_h + 0.3)
            butterfly_slot_2d();
}

module side_annulus_cut(r_outer, r_inner, depth, side) {
    z = side > 0 ? total_h / 2 - depth : -total_h / 2 - 0.01;

    translate([0, 0, z])
        linear_extrude(height = depth + 0.02)
            annulus_2d(r_outer, r_inner);
}

module circular_groove_cut(radius, profile_r, side) {
    rotate_extrude(convexity = 10)
        translate([radius, side * total_h / 2])
            circle(r = profile_r);
}

module side_relief_cuts(side) {
    // Blue inlay pocket.
    side_annulus_cut(blue_outer_r - 0.16, blue_inner_r, blue_pocket_depth, side);

    // One narrow circular groove around the butterfly, not a broad two-edge shelf.
    circular_groove_cut(slot_groove_r, slot_groove_profile_r, side);
}

module white_body() {
    difference() {
        soft_disc(outer_d, total_h);

        slot_cut();
        side_relief_cuts(1);
        side_relief_cuts(-1);
    }
}

module blue_inlay_side(side) {
    z = side > 0
        ? total_h / 2 - blue_surface_drop - blue_h
        : -total_h / 2 + blue_surface_drop;

    translate([0, 0, z])
        linear_extrude(height = blue_h)
            annulus_2d(blue_outer_r - 0.16, blue_inner_r);
}

module blue_inlay() {
    difference() {
        union() {
            blue_inlay_side(1);
            blue_inlay_side(-1);
        }
        slot_cut();
    }
}

if (part == "white") {
    color([0.93, 0.94, 0.88])
        white_body();
} else if (part == "blue") {
    color([0.00, 0.55, 0.95])
        blue_inlay();
} else {
    color([0.93, 0.94, 0.88])
        white_body();
    color([0.00, 0.55, 0.95])
        blue_inlay();
}
