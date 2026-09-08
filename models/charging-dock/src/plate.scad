include <params.scad>
use <frame.scad>

// ---------------------------------------------------------------------------
// Top plate
// ---------------------------------------------------------------------------

module top_edge_chamfer_cut() {
    c = top_edge_chamfer;
    h = chamfer_rise(c);
    top_frame()
        difference() {
            translate([-big / 2, -big / 2, -h]) cube([big, big, h + ov]);
            hull() {
                slice_at(-h) top_outline_2d(-h, 0);
                slice_at(0)  top_outline_2d(0, c);
                slice_at(ov) top_outline_2d(0, c);
            }
        }
}

// The plate's rear wall already leans outward by top_angle, so the chamfer at
// the parting edge needs extra rise there to stay within max_overhang_angle:
// (c + h*tan(top_angle)) / h <= tan(max_overhang_angle).
plate_bottom_chamfer_rise = plate_bottom_chamfer / (tan(max_overhang_angle) - tan(top_angle));

module plate_bottom_chamfer_cut() {
    c = plate_bottom_chamfer;
    h = plate_bottom_chamfer_rise;
    zb = -plate_thickness;
    top_frame()
        difference() {
            translate([-big / 2, -big / 2, zb - ov]) cube([big, big, ov + h]);
            hull() {
                slice_at(zb - ov) top_outline_2d(zb, c);
                slice_at(zb)      top_outline_2d(zb, c);
                slice_at(zb + h)  top_outline_2d(zb + h, 0);
            }
        }
}

module top_plate_blank() {
    difference() {
        intersection() {
            footprint_prism(0, -ov, big);
            local_slab(-plate_thickness, 0);
        }
        top_edge_chamfer_cut();
        plate_bottom_chamfer_cut();
    }
}

module recess_cut() {
    h = chamfer_rise(recess_lead_in);
    top_frame() {
        translate([0, 0, -recess_depth])
            linear_extrude(height = recess_depth + ov, convexity = 6)
                top_outline_2d(0, recess_border);
        hull() {
            slice_at(-h) top_outline_2d(0, recess_border);
            slice_at(0)  top_outline_2d(0, recess_border - recess_lead_in);
            slice_at(ov) top_outline_2d(0, recess_border - recess_lead_in);
        }
    }
}

module puck_bore_cut(cx) {
    top_frame()
        translate([cx, puck_y, -plate_thickness - ov])
            cylinder(h = plate_thickness + 2 * ov, d = puck_bore_diameter);
}

// Upper part of the cable bend envelope: through the plate floor, under the mat notch.
module bend_slot_cut(cx) {
    top_frame()
        translate([cx, bend_slot_center_y, -plate_thickness - ov])
            linear_extrude(height = plate_thickness + 2 * ov, convexity = 4)
                rounded_rect_2d(bend_slot_width, bend_slot_length, channel_radius);
}

module dowel_hole_plate() {
    for (y = dowel_ys)
        top_frame()
            translate([0, y, -plate_thickness - ov])
                cylinder(h = plate_thickness + 2 * ov, d = dowel_diameter + dowel_plate_clearance, $fn = 48);
}

module join_pockets_plate() {
    for (x = join_xs, y = join_ys)
        top_frame()
            translate([x, y, 0]) {
                if (join_method == "magnets")
                    // Blind pocket from the underside. Ceiling span = magnet_pocket_diameter (bridge-safe, asserted).
                    translate([0, 0, -plate_thickness - ov])
                        cylinder(h = magnet_pocket_depth + ov, d = magnet_pocket_diameter, $fn = 48);
                else if (join_method == "inserts") {
                    translate([0, 0, -plate_thickness - ov])
                        cylinder(h = plate_thickness + 2 * ov, d = screw_clearance_diameter, $fn = 40);
                    translate([0, 0, -recess_depth - screw_head_depth])
                        cylinder(h = screw_head_depth + ov, d = screw_head_diameter, $fn = 48);
                }
            }
}

module top_plate() {
    difference() {
        top_plate_blank();
        recess_cut();
        for (cx = puck_xs) {
            puck_bore_cut(cx);
            bend_slot_cut(cx);
        }
        dowel_hole_plate();
        join_pockets_plate();
    }
}

// top_plate() is built in assembly position, still on the 18 deg incline.
// Exporting it like that hands the slicer a part tilted 18 deg off the bed,
// which is the one thing the inclined-plane split exists to avoid. Every
// export of the plate goes through here so it lands flat, parting face down.
module top_plate_print() {
    unframe() top_plate();
}

