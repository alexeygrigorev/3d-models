/*
  Matchbox/Mattel ATV 6x6 - first 3D white bathtub.
  Units: millimeters.

  This file turns the accepted side profile into a simple printable tub:
    - two side walls with the current feedback6 side profile;
    - a flat bottom/floor tying the side walls together;
    - shallow internal ledges for the future gray axle holder;
    - transparent wheel previews only for fit checking.
*/

$fn = 64;

show_preview_wheels = true;

wheel_diameter = 10.0;
wheel_width = 5.5;
wheel_spacing = 10.8;
wheel_x = [-wheel_spacing, 0.0, wheel_spacing];

profile_z_scale = 1.50;
pocket_floor_z = 3.85;
wheel_center_z = 3.80;
top_z_rear = 7.05;
top_z_front = 7.20;
bottom_z_rear = 2.30;
bottom_z_front = 2.12;

tub_width = 13.8;
wall_thickness = 1.15;
floor_thickness = 1.15;
ledge_width = 1.1;
ledge_height = 0.85;

x_min = -16.7;
x_max = 18.8;
body_len = x_max - x_min;
floor_z = bottom_z_front * profile_z_scale;
side_y = tub_width / 2 - wall_thickness / 2;

module side_profile_2d() {
    scale([1, profile_z_scale])
        polygon(points=[
            [-16.5, bottom_z_rear],
            [-16.7, top_z_rear],
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
            [ 14.7, bottom_z_front],

            [  7.0, bottom_z_front + 0.02],
            [  0.0, bottom_z_front + 0.08],
            [ -7.0, bottom_z_rear - 0.02],
            [-13.7, bottom_z_rear - 0.05],
            [-16.2, bottom_z_rear - 0.08],
        ]);
}

module side_wall(ypos) {
    translate([0, ypos, 0])
        rotate([90, 0, 0])
            linear_extrude(height = wall_thickness, center = true)
                side_profile_2d();
}

module bottom_floor() {
    color("white")
        translate([(x_min + x_max) / 2, 0, floor_z - floor_thickness / 2])
            cube([body_len - 1.2, tub_width, floor_thickness], center = true);
}

module internal_ledge(ypos) {
    color("white")
        translate([(x_min + x_max) / 2 - 0.3, ypos, floor_z + ledge_height / 2])
            cube([body_len - 3.2, ledge_width, ledge_height], center = true);
}

module end_rib(xpos, width) {
    color("white")
        translate([xpos, 0, floor_z + 1.0])
            cube([width, tub_width, 2.0], center = true);
}

module bathtub_body() {
    union() {
        color("white") side_wall(side_y);
        color("white") side_wall(-side_y);
        bottom_floor();

        // Simple inner ledges; the gray axle-holder insert can sit on these later.
        internal_ledge(tub_width / 2 - wall_thickness - ledge_width / 2);
        internal_ledge(-tub_width / 2 + wall_thickness + ledge_width / 2);

        // Short end ribs close the tub visually without adding wheel holes.
        end_rib(x_min + 0.8, 1.2);
        end_rib(x_max - 1.4, 1.2);
    }
}

module preview_wheel(xpos, ypos) {
    color([0.96, 0.96, 0.90, 0.38])
        translate([xpos, ypos, wheel_center_z * profile_z_scale])
            rotate([90, 0, 0])
                cylinder(h = wheel_width, d = wheel_diameter, center = true);
}

bathtub_body();

if (show_preview_wheels) {
    for (xpos = wheel_x) {
        preview_wheel(xpos, tub_width / 2 + wheel_width / 2 - 0.25);
        preview_wheel(xpos, -tub_width / 2 - wheel_width / 2 + 0.25);
    }
}
