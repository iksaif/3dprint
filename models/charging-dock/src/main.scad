include <params.scad>
use <frame.scad>
use <base.scad>
use <plate.scad>
use <insert.scad>
use <parts.scad>

// ---------------------------------------------------------------------------
// Assembly and dimension report
// ---------------------------------------------------------------------------

module chassis() {
    base();
    top_plate();
}

module assembly() {
    chassis_colour = style == "furniture" ? [0.63, 0.45, 0.31]
                   : style == "faceted"   ? [0.15, 0.17, 0.18]
                   :                        [0.25, 0.27, 0.26];
    insert_colour = [0.025, 0.03, 0.03];
    color(chassis_colour) base();
    color(chassis_colour * 1.15) top_plate();
    color(insert_colour) top_insert();
    if (show_fit_dummies) fit_dummies();
}

// Presentation render: the dock as it looks in use, with the pucks seated but
// without the cable-clearance envelopes that fit_dummies() draws for
// interference checking. Not printable -- the pucks are not part geometry.
module showcase() {
    chassis_colour = style == "furniture" ? [0.63, 0.45, 0.31]
                   : style == "faceted"   ? [0.15, 0.17, 0.18]
                   :                        [0.25, 0.27, 0.26];
    color(chassis_colour) base();
    color(chassis_colour * 1.15) top_plate();
    color([0.025, 0.03, 0.03]) top_insert();
    for (cx = puck_xs)
        color([0.93, 0.94, 0.92]) puck_fit_dummy(cx);
}

module dim(name, value) { echo(str("DIM|", name, "|", value)); }

module echo_dimensions() {
    dim("Style", style);
    dim("Join method", join_method);
    dim("Footprint (W x D)", str(body_width, " x ", body_depth, " mm"));
    dim("Incline", str(top_angle, " deg"));
    dim("Front height / rear height", str(front_height, " / ", round(back_height * 100) / 100, " mm"));
    dim("Base front lip / rear height", str(round(base_front_height * 100) / 100, " / ", round(base_rear_height * 100) / 100, " mm"));
    dim("Top plate thickness", str(plate_thickness, " mm (== puck height, through bores)"));
    dim("Top plate size flat (X x Y)", str(body_width, " x ", round(top_length * 100) / 100, " mm"));
    dim("Puck bore", str(puck_bore_diameter, " mm (", puck_nominal_diameter, " + 2 x ", puck_radial_clearance, ")"));
    dim("Puck spacing", str(puck_spacing, " mm, rib ", puck_rib, " mm"));
    dim("Recess", str(round(recess_width * 100) / 100, " x ", round(recess_length * 100) / 100, " x ", recess_depth, " mm, border ", recess_border, " mm, lead-in ", recess_lead_in, " mm"));
    dim("Recess corner radius", str(recess_corner_radius <= 0 ? "sharp" : str(recess_corner_radius, " mm"), " (outer ", footprint_radius, " mm, exponent ", footprint_exponent, ")"));
    dim("TPU insert (W x L x T)", str(round(mat_width * 100) / 100, " x ", round(mat_length * 100) / 100, " x ", mat_thickness, " mm, total clearance ", mat_clearance_total, " mm"));
    dim("TPU top below border", str(mat_surface_recess, " mm; bezel ", mat_bezel_width, " wide x ", mat_bezel_height, " high"));
    dim("TPU puck hole", str(puck_hole_diameter, " mm, notch ", mat_cable_notch_width, " x ", mat_cable_notch_length, " mm"));
    dim("PETG capture below TPU", str(puck_capture_depth, " mm"));
    dim("Cable bend envelope", str(bend_slot_width, " x ", bend_slot_length, " x ", rim_cable_channel_height, " mm, keepout ", front_cable_keepout, " mm"));
    dim("Plug trench", str(trench_width, " x ", trench_depth, " mm, length ", round(trench_length * 10) / 10, " mm"));
    dim("Cable bay (W x D x floor)", str(bay_width, " x ", round(bay_depth * 100) / 100, " mm, floor at ", base_floor, " mm"));
    dim("Rear access window", str(rear_access_window_width, " x ", rear_access_window_height, " mm"));
    dim("Dowels", str(len(dowel_ys), " x d", dowel_diameter, " x ", dowel_length, " mm"));
    dim("Magnets", str(len(join_xs) * len(join_ys), " x d", magnet_diameter, " x ", magnet_thickness, " mm (pocket ", magnet_pocket_diameter, " x ", magnet_pocket_depth, ")"));
    dim("Feet", str("4 x d", foot_pad_diameter, " x ", foot_pad_depth, " mm pads"));
    dim("Eject holes", str(eject_hole_diameter, " mm, offset ", eject_hole_offset_x, " mm from puck centre"));
    dim("Reveal", str(reveal_depth, " deep x ", reveal_height, " high"));
    dim("Min floor: bend tray / trench", str(round(tray_floor * 100) / 100, " / ", round(trench_floor * 100) / 100, " mm"));
}

// ---------------------------------------------------------------------------
// Plate set layout
//
// One 3MF holding every PETG piece of a dock, as separate objects (requires
// --enable=lazy-union; see the `sets` target in the Makefile). The insert is
// TPU, so it is a separate job whatever the bed can hold.
//
// The parts are laid out SIDE BY SIDE, each turned 90 degrees about Z. Stacking
// them front-to-back is the natural reading of the geometry and it needs about
// 235 mm of Y — fine on the 256 mm square bed this model was first written for,
// 25 mm too deep for the MK4S's 210 mm. Turned and set beside each other they
// need ~232 x 158, which fits with room to spare.
//
// Rotating about Z costs nothing: both parts still print flat on the same face,
// so the orientation that makes them supportless is untouched.
// ---------------------------------------------------------------------------

set_gap = 4;   // clearance between parts on the bed

// Slightly conservative: the real minimum is a little above this, so the
// measured gap comes out a touch wider than set_gap rather than narrower.
plate_flat_y_min = -plate_thickness * tan(top_angle);

// Flat, before rotation, the two PETG parts span these in Y. rotate([0,0,90])
// maps (x, y) -> (-y, x), so each one's Y extent becomes its bed X extent and
// its width (body_width) becomes its bed Y extent.
set_base_len  = body_depth;                        // base spans y 0..body_depth
set_plate_len = top_length - plate_flat_y_min;     // plate dips below y = 0

// Laid out left to right from x = 0, then centred. The dowel pins go in the
// spare Y above the pair rather than on the end of the row: they are tiny, and
// X is the tight axis here while Y has ~40 mm going begging.
set_plate_x  = set_base_len + set_gap + top_length;
set_pins_y   = body_width / 2 + set_gap + 2;

set_petg_x_max = set_base_len + set_gap + set_plate_len;
set_petg_y_max = body_width + set_gap + 4;

assert(set_petg_x_max <= bed_x,
       str("PETG set needs ", set_petg_x_max, " mm of X, bed is ", bed_x));
assert(set_petg_y_max <= bed_y,
       str("PETG set needs ", set_petg_y_max, " mm of Y, bed is ", bed_y));

// ---------------------------------------------------------------------------
// Dispatch
// ---------------------------------------------------------------------------

if (part == "base")                 base();
else if (part == "top_plate")       top_plate_print();
else if (part == "chassis")         chassis();
else if (part == "top_insert")      top_insert();
else if (part == "top_insert_flat" || part == "mat") top_insert_flat();
else if (part == "dowel_pins")      dowel_pins();
else if (part == "fit_test")        fit_test();
else if (part == "fit_test_mat")    fit_test_mat();
else if (part == "fit_dummies")     fit_dummies();
else if (part == "cable_clearance") for (cx = puck_xs) cable_clearance(cx);
else if (part == "set_petg") {
    // Top level on purpose: lazy-union only splits objects here, not inside a
    // module, so this cannot be wrapped in a set_petg() module.
    // Each turned 90 degrees so the pair sits across the bed rather than up it,
    // then the whole row centred on the origin.
    translate([-set_petg_x_max / 2, 0, 0]) {
        translate([set_base_len, 0, 0]) rotate([0, 0, 90]) base();
        translate([set_plate_x,  0, 0]) rotate([0, 0, 90]) top_plate_print();
        translate([set_petg_x_max / 2 - 4, set_pins_y, 0]) dowel_pins();
    }
}
else if (part == "set_tpu")         top_insert_flat();
else if (part == "showcase")        showcase();
else if (part == "dimensions")      { echo_dimensions(); cube(1); }
else                                assembly();
