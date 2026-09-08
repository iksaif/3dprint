include <params.scad>
use <frame.scad>
use <plate.scad>

// ---------------------------------------------------------------------------
// TPU top insert
// ---------------------------------------------------------------------------

module mat_cable_notch_2d() {
    translate([0, -puck_hole_diameter / 2 - mat_cable_notch_length / 2 + mat_cable_notch_overlap])
        rounded_rect_2d(mat_cable_notch_width, mat_cable_notch_length, mat_cable_notch_radius);
}

module mat_outline_2d() {
    top_outline_2d(0, recess_border + mat_clearance_total / 2);
}

module mat_2d() {
    difference() {
        mat_outline_2d();
        for (cx = puck_xs)
            translate([cx, puck_y]) {
                circle(d = puck_hole_diameter);
                mat_cable_notch_2d();
            }
    }
}

module mat_bezel_2d() {
    for (cx = puck_xs)
        translate([cx, puck_y])
            difference() {
                circle(d = puck_hole_diameter + 2 * mat_bezel_width);
                circle(d = puck_hole_diameter);
                mat_cable_notch_2d();
            }
}

// Insert in local coordinates, sitting on the recess floor.
module top_insert_local() {
    translate([0, 0, -recess_depth]) {
        linear_extrude(height = mat_thickness, convexity = 6) mat_2d();
        if (mat_bezel_width > 0 && mat_bezel_height > 0)
            translate([0, 0, mat_thickness - eps])
                linear_extrude(height = mat_bezel_height + eps, convexity = 4)
                    mat_bezel_2d();
    }
}

module top_insert() {
    top_frame() top_insert_local();
}

// Print orientation: flat, top up, centred.
module top_insert_flat() {
    translate([0, -top_length / 2, recess_depth]) top_insert_local();
}

