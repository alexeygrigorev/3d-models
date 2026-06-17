/*
  Matchbox/Mattel ATV 6x6 - white wheel bathtub from side panel.
  Units: millimeters.

  Current stage: only the lower white part that grows out of the accepted
  side panel. This is not the full vehicle body.

  Construction:
    - the accepted side profile is extruded across the full tub width;
    - the inside is cut out from above, leaving one continuous shell;
    - the profile itself wraps into the floor and the opposite side;
    - shallow internal details are secondary and do not form the tub shape.
*/

$fn = 64;

show_preview_wheels = true;
show_preview_axles = true;

wheel_diameter = 10.0;
wheel_width = 5.5;
wheel_spacing = 10.8;
wheel_x = [-wheel_spacing, 0.0, wheel_spacing];
axle_diameter = 1.4;

profile_z_scale = 1.50;
pocket_floor_z = 3.85;
wheel_center_z = 3.80;
top_z_rear = 7.05;
top_z_front = 7.20;
bottom_z_rear = 2.30;
bottom_z_front = 2.12;

tub_width = 15.2;
wall_thickness = 1.25;
floor_thickness = 1.25;
ledge_width = 1.15;
ledge_height = 0.9;
screw_boss_d = 5.0;
screw_hole_d = 2.0;
preview_axle_inset = 0.65;

x_min = -16.7;
x_max = 18.8;
body_len = x_max - x_min;
floor_z = bottom_z_front * profile_z_scale;
inner_y = tub_width / 2 - wall_thickness;
inner_span = tub_width - wall_thickness * 2 - 0.35;
axle_z = wheel_center_z * profile_z_scale;
ledge_x_min = -12.7;
ledge_x_max = 13.8;
ledge_len = ledge_x_max - ledge_x_min;
ledge_center_x = (ledge_x_min + ledge_x_max) / 2;

module side_profile_2d() {
    scale([1, profile_z_scale])
        polygon(points=[
            [-13.7, bottom_z_rear - 0.08],
            [-15.0, bottom_z_rear - 0.08],
            [-16.3, bottom_z_rear + 0.18],
            [-16.4, top_z_rear - 0.18],
            [-16.2, top_z_rear],
            [-13.2, top_z_rear + 0.03],
            [-10.8, pocket_floor_z],
            [ -8.4, top_z_rear + 0.03],

            [ -2.4, top_z_rear + 0.08],
            [  0.0, pocket_floor_z],
            [  2.4, top_z_rear + 0.12],

            [  8.4, top_z_front - 0.05],
            [ 10.8, pocket_floor_z],
            [ 13.2, top_z_front],

            [ 17.2, top_z_front],
            [ 18.8, top_z_front - 0.55],
            [ 18.5, top_z_front - 1.10],
            [ 16.6, top_z_front - 2.00],
            [ 14.5, bottom_z_front],

            [  9.2, bottom_z_front + 0.02],
            [  3.2, bottom_z_front + 0.05],
            [ -2.6, bottom_z_front + 0.10],
            [ -8.0, bottom_z_front + 0.03],
            [-12.5, bottom_z_rear - 0.06],
        ]);
}

module outer_profile_body() {
    rotate([90, 0, 0])
        linear_extrude(height = tub_width, center = true)
            side_profile_2d();
}

module inner_cavity_cut() {
    // Open top hollow. This removes the middle of the extruded profile while
    // preserving the side walls, end lips, and the profile-shaped bottom.
    translate([(x_min + x_max) / 2 + 0.1, 0, floor_z + floor_thickness + 16])
        cube([body_len - 4.0, tub_width - wall_thickness * 2, 32], center = true);
}

module internal_ledge(ypos) {
    translate([ledge_center_x, ypos, floor_z + ledge_height / 2])
        cube([ledge_len, ledge_width, ledge_height], center = true);
}

module screw_boss() {
    translate([6.1, 0, floor_z])
        cylinder(h = 2.6, d = screw_boss_d);
}

module screw_hole_cut() {
    translate([6.1, 0, floor_z - 0.2])
        cylinder(h = 4.0, d = screw_hole_d);
}

module axle_saddle_cut(xpos) {
    // Internal lower cradle only. It stays away from the side panels, so the
    // white tub does not gain visible round axle holes.
    translate([xpos, 0, axle_z + 0.15])
        rotate([90, 0, 0])
            cylinder(h = inner_span - ledge_width * 2.2, d = axle_diameter + 1.0, center = true);
}

module bathtub_body() {
    difference() {
        union() {
            difference() {
                outer_profile_body();
                inner_cavity_cut();
            }

            // Small shelves for the future gray insert; the tub shape itself
            // comes from the hollowed profile body above.
            internal_ledge(inner_y - ledge_width / 2);
            internal_ledge(-inner_y + ledge_width / 2);

            screw_boss();
        }

        screw_hole_cut();
        for (xpos = wheel_x)
            axle_saddle_cut(xpos);
    }
}

module preview_wheel(xpos, ypos) {
    color([0.96, 0.96, 0.90, 0.38])
        translate([xpos, ypos, axle_z])
            rotate([90, 0, 0])
                cylinder(h = wheel_width, d = wheel_diameter, center = true);
}

module preview_axle(xpos) {
    color([0.38, 0.38, 0.34, 0.78])
        translate([xpos, 0, axle_z])
            rotate([90, 0, 0])
                cylinder(h = tub_width + wheel_width * 2.0 - preview_axle_inset * 2, d = axle_diameter, center = true);
}

color("white")
    bathtub_body();

if (show_preview_wheels) {
    for (xpos = wheel_x) {
        preview_wheel(xpos, tub_width / 2 + wheel_width / 2 - 0.25);
        preview_wheel(xpos, -tub_width / 2 - wheel_width / 2 + 0.25);
    }
}

if (show_preview_axles)
    for (xpos = wheel_x)
        preview_axle(xpos);
