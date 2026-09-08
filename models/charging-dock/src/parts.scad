include <params.scad>
use <frame.scad>
use <base.scad>
use <plate.scad>
use <insert.scad>

// ---------------------------------------------------------------------------
// Dowel pins, reference solids, fit test
// ---------------------------------------------------------------------------

module dowel_pin() {
    c = 0.5;
    hull() {
        translate([0, 0, c]) cylinder(h = dowel_length - 2 * c, d = dowel_diameter, $fn = 48);
        cylinder(h = dowel_length, d = dowel_diameter - 2 * c, $fn = 48);
    }
}

module dowel_pins() {
    for (i = [0 : len(dowel_ys) - 1])
        translate([i * (dowel_diameter + 4), 0, 0]) dowel_pin();
}

module puck_fit_dummy(cx) {
    top_frame()
        translate([cx, puck_y, -plate_thickness])
            union() {
                cylinder(h = puck_height, d = puck_nominal_diameter);
                translate([0, 0, puck_height - 0.35])
                    cylinder(h = 0.38, d = puck_nominal_diameter - 2.4);
            }
}

module tube_between(p1, p2, diameter) {
    hull() {
        translate(p1) sphere(d = diameter, $fn = 32);
        translate(p2) sphere(d = diameter, $fn = 32);
    }
}

module cable_fit_dummy(cx) {
    exit_z = -plate_thickness + cable_dummy_diameter / 2 + 0.6;
    p0 = top_to_world([cx, puck_y - puck_nominal_diameter / 2, exit_z]);
    p1 = top_to_world([cx, bend_slot_front_y + cable_dummy_diameter / 2, exit_z]);
    p2 = top_to_world([cx, bend_slot_front_y + cable_bend_square / 2,
                       -plate_thickness - bend_tray_depth + cable_dummy_diameter / 2]);
    p3 = top_to_world([cx, puck_y, -plate_thickness - trench_depth / 2]);
    p4 = [cx, bay_front_y + 4, base_floor + trench_depth];
    tube_between(p0, p1, cable_dummy_diameter);
    tube_between(p1, p2, cable_dummy_diameter);
    tube_between(p2, p3, cable_dummy_diameter);
    tube_between(p3, p4, cable_dummy_diameter);
}

// Union of every cable void (debug export / assembly preview)
module cable_clearance(cx) {
    bend_slot_cut(cx);
    bend_tray_cut(cx);
    trench_cut(cx);
}

module fit_dummies() {
    for (cx = puck_xs) {
        color([0.95, 0.96, 0.94, 0.85]) puck_fit_dummy(cx);
        color([1.0, 0.55, 0.05, 0.28]) cable_clearance(cx);
        color([0.03, 0.03, 0.03, 0.9]) cable_fit_dummy(cx);
    }
}

// Coupon layout (all within 40 x 40): puck-seat quadrant at [0,31]^2,
// recess corner at [31,40]^2, plug trench cross-section at [0,18] x [31,39].
fit_qx0 = puck_xs[0] - fit_quadrant;
fit_qy0 = puck_y - fit_quadrant;
fit_cx0 = -body_width / 2 + recess_border - 3;
fit_cy0 = recess_border - 3;
fit_quadrant_span = fit_quadrant + 1;

module fit_test_plate() {
    translate([-fit_qx0, -fit_qy0, 0])
        intersection() {
            unframe() top_plate();
            local_box(fit_qx0, fit_qx0 + fit_quadrant_span, fit_qy0, fit_qy0 + fit_quadrant_span);
        }
    translate([fit_quadrant_span - fit_cx0, fit_quadrant_span - fit_cy0, 0])
        intersection() {
            unframe() top_plate();
            local_box(fit_cx0, fit_cx0 + fit_corner, fit_cy0, fit_cy0 + fit_corner);
        }
}

module fit_test_trench() {
    px = puck_xs[0];
    yc = top_to_world([px, puck_y, -plate_thickness])[1];
    translate([-(px - 9), -(yc - 4) + fit_quadrant_span, 0])
        intersection() {
            base();
            translate([px - 9, yc - 4, -ov]) cube([18, 8, big]);
        }
}

module fit_test() {
    fit_test_plate();
    fit_test_trench();
}

module fit_test_mat() {
    translate([-fit_qx0, -fit_qy0, 0])
        intersection() {
            translate([0, 0, recess_depth]) top_insert_local();
            local_box(fit_qx0, fit_qx0 + fit_quadrant_span, fit_qy0, fit_qy0 + fit_quadrant_span);
        }
    translate([fit_quadrant_span - fit_cx0, fit_quadrant_span - fit_cy0, 0])
        intersection() {
            translate([0, 0, recess_depth]) top_insert_local();
            local_box(fit_cx0, fit_cx0 + fit_corner, fit_cy0, fit_cy0 + fit_corner);
        }
}

