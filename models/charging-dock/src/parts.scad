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

// The cable as measured on the real puck: the rigid boot leaves the rim
// horizontally with its top puck_boot_top_drop below the puck face -- higher
// than the mat's underside -- then the flexible cable makes a U-turn of
// cable_bend_radius and runs back under the puck. The arc is drawn as chords,
// which sit inside the true arc, so this never claims more room than the
// cable takes. cable_fit_dummy() above predates the measurement and starts the
// cable at the bottom of the puck.
module cable_boot_dummy(cx) {
    arc = [for (a = [0 : 15 : 180])
        [cx, cable_boot_end_y - cable_bend_radius * sin(a), cable_loop_centre_z + cable_bend_radius * cos(a)]];
    last = arc[len(arc) - 1];
    top_frame() {
        translate([cx - puck_boot_width / 2, cable_boot_end_y, -puck_boot_top_drop - puck_boot_height])
            cube([puck_boot_width, puck_boot_length + 1, puck_boot_height]);
        for (i = [0 : len(arc) - 2])
            tube_between(arc[i], arc[i + 1], cable_dummy_diameter);
        tube_between(last, [cx, puck_y, last[2]], cable_dummy_diameter);
    }
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
        color([0.85, 0.1, 0.1, 0.9]) cable_boot_dummy(cx);
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

// Printed the same way up as the mat itself, so the coupon's edges see the
// same first layer as the real part.
// Canary: the mat's press fit. A rigid tile with one hole per step of
// fit_dowel_hole_steps, each marked with that many dots, against a TPU tile
// carrying the same studs the mat has. Press each stud into each hole and set
// mat_dowel_interference from whichever holds without tearing.
function fit_dowel_x(i) = (i - (len(fit_dowel_hole_steps) - 1) / 2) * fit_dowel_pitch;

module fit_test_dowel() {
    t = mat_dowel_hole_depth + min_floor;
    difference() {
        translate([-fit_dowel_tile[0] / 2, -fit_dowel_tile[1] / 2, 0])
            cube([fit_dowel_tile[0], fit_dowel_tile[1], t]);
        for (i = [0 : len(fit_dowel_hole_steps) - 1]) {
            translate([fit_dowel_x(i), 2, t - mat_dowel_hole_depth])
                cylinder(h = mat_dowel_hole_depth + ov, d = mat_dowel_diameter + fit_dowel_hole_steps[i], $fn = 32);
            // Same vent as the plate, or the coupon would test a different fit.
            translate([fit_dowel_x(i), 2, -ov])
                cylinder(h = t + 2 * ov, d = mat_dowel_vent_diameter, $fn = 24);
            for (k = [0 : i])
                translate([fit_dowel_x(i) - i + k * 2, -6, t - 0.4])
                    cylinder(h = 0.4 + ov, d = 1.2, $fn = 16);
        }
    }
}

// TPU side of the same canary, printed face down like the mat: studs up.
module fit_test_dowel_mat() {
    translate([-fit_dowel_tile[0] / 2, -fit_dowel_tile[1] / 2, 0])
        cube([fit_dowel_tile[0], fit_dowel_tile[1], mat_thickness]);
    for (i = [0 : len(fit_dowel_hole_steps) - 1])
        translate([fit_dowel_x(i), 2, mat_thickness - eps]) mat_dowel_stud();
}

// Canary: the puck lip. A band of the real mat round one whole hole, cut from
// the mat itself so it carries the true hole, the bead at the face and the
// cable relief. Press the puck in, turn it over: it should hold. Printed the
// same way up as the mat, so the bead lands on the same layer.
module fit_test_lip_up() {
    cx = puck_xs[0];
    translate([-cx, -puck_y, 0])
        intersection() {
            translate([0, 0, recess_depth]) top_insert_local(dowels = false);
            translate([cx, puck_y, -ov])
                cylinder(h = mat_thickness + 2 * ov, d = puck_hole_diameter + 2 * fit_lip_band, $fn = 128);
        }
}

module fit_test_lip() {
    if (mat_print_face_down)
        translate([0, 0, mat_thickness]) rotate([180, 0, 0]) fit_test_lip_up();
    else
        fit_test_lip_up();
}

// Canary: the cable path. The front of the base round one puck's route -- the
// U-turn pocket, the bend tray and the start of the trench -- so the real
// cable can be threaded before committing hours to a full base.
module fit_test_cable() {
    px = puck_xs[0];
    w  = trench_width + 10;
    y0 = top_to_world([px, bend_slot_front_y - 2, -plate_thickness])[1];
    y1 = top_to_world([px, trench_start_y + 12, -plate_thickness])[1];
    translate([-px + w / 2, -y0, 0])
        intersection() {
            base();
            translate([px - w / 2, y0, -ov]) cube([w, y1 - y0, big]);
        }
}

module fit_test_mat() {
    if (mat_print_face_down)
        translate([0, fit_quadrant_span + fit_corner, mat_thickness]) rotate([180, 0, 0])
            fit_test_mat_up();
    else
        fit_test_mat_up();
}

module fit_test_mat_up() {
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

