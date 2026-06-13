/*
  Matchbox/Mattel ATV 6x6 - lower white bathtub rebuild.
  Units: millimeters.

  Current stage: only the lower white bathtub.
  Logic: one continuous tub. Wheel places are open top/side cutouts in the
  tub walls; wheels are dropped in from above and later clamped by a gray insert.
*/

$fn = 64;

// ---------- Preview ----------
show_preview_wheels = true;
show_axles = false;

// ---------- Wheel reference ----------
wheel_diameter = 10.0;
wheel_width = 5.5;
axle_diameter = 1.4;
axle_x = [-13.0, 0.0, 13.0];
axle_z = 4.0;

// ---------- Bathtub dimensions ----------
tub_length = 46.0;
tub_width = 17.0;
floor_thickness = 2.0;
wall_height = 7.2;
wall_thickness = 2.4;

// Footprint of the side wall, viewed from above.
// The inner edge is straight; the outer edge has three wheel cutouts.
wheel_cut_depth = 3.8;
wheel_cut_width = 7.6;
divider_width = 4.0;

screw_x = 7.0;
screw_hole_d = 2.1;
screw_recess_d = 5.4;

wheel_side_offset = tub_width / 2 + wheel_width / 2 - 0.7;

module rounded_box(size, r) {
    hull() {
        for (x = [-size[0] / 2 + r, size[0] / 2 - r])
        for (y = [-size[1] / 2 + r, size[1] / 2 - r])
            translate([x, y, 0])
                cylinder(h = size[2], r = r);
    }
}

module floor_plate() {
    rounded_box([tub_length, tub_width, floor_thickness], 1.1);
}

module side_wall_plan_2d(side) {
    inner_y = side * (tub_width / 2 - wall_thickness);
    outer_y = side * (tub_width / 2);
    cut_y = side * (tub_width / 2 - wheel_cut_depth);

    // Top-view wall shape. Points run along the straight inner edge, then
    // return through the jagged outer edge with three open wheel cutouts.
    polygon(points=[
        [-23.0, inner_y],
        [ 23.0, inner_y],

        [ 23.0, outer_y],
        [ 18.2, outer_y],

        // front wheel cutout
        [ 16.8, cut_y],
        [  9.2, cut_y],
        [  7.8, outer_y],

        // middle wheel cutout
        [  3.8, outer_y],
        [  2.4, cut_y],
        [ -2.4, cut_y],
        [ -3.8, outer_y],

        // rear wheel cutout
        [ -7.8, outer_y],
        [ -9.2, cut_y],
        [-16.8, cut_y],
        [-18.2, outer_y],

        [-23.0, outer_y]
    ]);
}

module side_wall(side) {
    translate([0, 0, floor_thickness])
        linear_extrude(height = wall_height - floor_thickness)
            side_wall_plan_2d(side);
}

module end_wall(xpos, width_scale) {
    translate([xpos, 0, floor_thickness])
        rounded_box([2.4, tub_width * width_scale, wall_height - floor_thickness], 0.7);
}

module inner_insert_ledge() {
    translate([0, 0, floor_thickness])
        rounded_box([tub_length - 11.0, tub_width - wall_thickness * 3.2, 1.1], 0.65);
}

module axle_saddle(xpos) {
    // Shallow visual/functional lower support for the future axle. The gray
    // insert will provide the top clamp later.
    translate([xpos, 0, floor_thickness + 1.1])
        rotate([90, 0, 0])
            cylinder(h = tub_width - wall_thickness * 2.2, d = axle_diameter + 1.0, center = true);
}

module screw_cut() {
    translate([screw_x, 0, -0.2])
        cylinder(h = 1.4, d = screw_recess_d);
    translate([screw_x, 0, -0.2])
        cylinder(h = wall_height + 1.0, d = screw_hole_d);
}

module lower_white_bathtub() {
    difference() {
        union() {
            floor_plate();

            side_wall(-1);
            side_wall(1);

            end_wall(-tub_length / 2 + 1.2, 0.86);
            end_wall( tub_length / 2 - 1.2, 0.82);
            inner_insert_ledge();
        }

        for (xpos = axle_x)
            axle_saddle(xpos);

        screw_cut();
    }
}

module preview_wheel(side, xpos) {
    color([0.96, 0.96, 0.90, 0.42])
        translate([xpos, side * wheel_side_offset, axle_z])
            rotate([90, 0, 0])
                cylinder(h = wheel_width, d = wheel_diameter, center = true);
}

module preview_axle(xpos) {
    color([0.70, 0.70, 0.68])
        translate([xpos, 0, axle_z])
            rotate([90, 0, 0])
                cylinder(h = tub_width + wheel_width * 2 + 2, d = axle_diameter, center = true);
}

color("white")
    lower_white_bathtub();

if (show_preview_wheels)
    for (xpos = axle_x)
    for (side = [-1, 1])
        preview_wheel(side, xpos);

if (show_axles)
    for (xpos = axle_x)
        preview_axle(xpos);
