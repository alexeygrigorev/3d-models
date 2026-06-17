/*
  Matchbox/Mattel ATV 6x6 - current white bathtub side profile.
  Units: millimeters.

  This is a side-profile alignment pass, not the final 3D bathtub.

  Logic:
    - wheels are dropped into open pockets from above;
    - the side wall is one continuous bathtub wall, not separate holes;
    - each pocket is a sharp V-like axle seat in the top edge;
    - the lower edge stays continuous so the part reads as one tub.
*/

$fn = 64;

show_preview_wheels = true;

wheel_diameter = 10.0;
wheel_width = 5.5;
profile_thickness = 2.4;
profile_z_scale = 1.50;
pocket_floor_z = 3.85;
wheel_center_z = 3.80;
top_z_rear = 7.05;
top_z_front = 7.20;
bottom_z_rear = 2.30;
bottom_z_front = 2.12;

wheel_x = [-10.8, 0.0, 10.8];
wheel_z = wheel_center_z * profile_z_scale;

module side_profile_2d() {
    scale([1, profile_z_scale])
        polygon(points=[
            // shorter feedback6 profile: close wheels, straight upper cut, sharp V pockets
            // rear block is closed instead of reading like an open cart handle
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

            // compact front/right end: only a short nose after the third wheel
            [ 17.2, top_z_front],
            [ 18.8, top_z_front - 0.55],
            [ 18.5, top_z_front - 1.10],
            [ 16.6, top_z_front - 2.00],
            [ 14.5, bottom_z_front],

            // long, low side cut from the user's blue trim guide
            [  9.2, bottom_z_front + 0.02],
            [  3.2, bottom_z_front + 0.05],
            [ -2.6, bottom_z_front + 0.10],
            [ -8.0, bottom_z_front + 0.03],
            [-12.5, bottom_z_rear - 0.06],
        ]);
}

module profile_plate() {
    rotate([90, 0, 0])
        linear_extrude(height = profile_thickness, center = true)
            side_profile_2d();
}

module preview_wheel(xpos) {
    color([0.96, 0.96, 0.90, 0.42])
        translate([xpos, -wheel_width / 2 - 1.0, wheel_z])
            rotate([90, 0, 0])
                cylinder(h = wheel_width, d = wheel_diameter, center = true);
}

color("white")
    profile_plate();

if (show_preview_wheels)
    for (xpos = wheel_x)
        preview_wheel(xpos);
