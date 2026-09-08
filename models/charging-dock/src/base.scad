include <params.scad>
use <frame.scad>

// ---------------------------------------------------------------------------
// Base
// ---------------------------------------------------------------------------

module base_blank() {
    h = chamfer_rise(base_bottom_chamfer);
    intersection() {
        hull() {
            linear_extrude(height = eps) footprint_2d(base_bottom_chamfer);
            translate([0, 0, h]) linear_extrude(height = big) footprint_2d();
        }
        local_slab(-big, -plate_thickness);
    }
}

// Shadow gap: the top reveal_height of the base is inset by reveal_depth.
module reveal_cut() {
    difference() {
        local_slab(-plate_thickness - reveal_height, -plate_thickness + ov);
        footprint_prism(reveal_depth, -ov, big);
    }
}

module cable_bay_cut() {
    translate([0, (bay_front_y + bay_rear_y) / 2, base_floor])
        linear_extrude(height = big, convexity = 4)
            rounded_rect_2d(bay_width, bay_depth, bay_corner_radius);
}

module rear_access_window_cut() {
    r = rear_access_window_radius;
    extrude_y(bay_rear_y - ov, body_depth + ov)
        translate([0, rear_access_window_bottom_z + rear_access_window_height / 2 + r])
            rounded_rect_2d(rear_access_window_width, rear_access_window_height + 2 * r, r);
}

module rear_mark_2d() {
    stroke = 0.9;
    ring_d = rear_mark_size * 0.55;
    for (dx = [-rear_mark_size * 0.36, rear_mark_size * 0.36])
        translate([dx, 0])
            difference() {
                circle(d = ring_d, $fn = 48);
                circle(d = ring_d - 2 * stroke, $fn = 48);
            }
}

module rear_mark_cut() {
    extrude_y(body_depth - rear_mark_depth, body_depth + ov)
        translate([0, rear_mark_z])
            rear_mark_2d();
}

// Lower part of the cable bend envelope, cut into the base's top face.
module bend_tray_cut(cx) {
    top_frame()
        translate([cx, bend_slot_center_y, -plate_thickness - bend_tray_depth])
            linear_extrude(height = bend_tray_depth + ov, convexity = 4)
                rounded_rect_2d(bend_slot_width, bend_slot_length, channel_radius);
}

// Open plug trench in the puck floor: bend tray -> under the puck -> bay.
module trench_cut(cx) {
    top_frame()
        translate([cx, (trench_start_y + trench_end_y) / 2, -plate_thickness - trench_depth])
            linear_extrude(height = trench_depth + ov, convexity = 4)
                rounded_rect_2d(trench_width, trench_length, channel_radius);
}

module eject_hole_cut(cx) {
    p = top_to_world([cx + eject_hole_offset_x, puck_y, -plate_thickness]);
    translate([p[0], p[1], -ov])
        cylinder(h = p[2] + 2 * ov, d = eject_hole_diameter, $fn = 40);
}

module dowel_hole_base() {
    for (y = dowel_ys)
        top_frame()
            translate([0, y, -plate_thickness - dowel_base_depth])
                cylinder(h = dowel_base_depth + ov, d = dowel_diameter + dowel_base_clearance, $fn = 48);
}

module join_pockets_base() {
    for (x = join_xs, y = join_ys)
        top_frame()
            translate([x, y, 0]) {
                if (join_method == "magnets")
                    translate([0, 0, -plate_thickness - magnet_pocket_depth])
                        cylinder(h = magnet_pocket_depth + ov, d = magnet_pocket_diameter, $fn = 48);
                else if (join_method == "inserts")
                    translate([0, 0, -plate_thickness - insert_hole_depth])
                        cylinder(h = insert_hole_depth + ov, d = insert_hole_diameter, $fn = 48);
            }
}

module foot_pad_cuts() {
    for (x = [-(body_width / 2 - foot_inset), body_width / 2 - foot_inset],
         y = [foot_inset, body_depth - foot_inset])
        translate([x, y, -ov])
            cylinder(h = foot_pad_depth + ov, d = foot_pad_diameter, $fn = 48);
}

module base() {
    difference() {
        base_blank();
        reveal_cut();
        cable_bay_cut();
        rear_access_window_cut();
        for (cx = puck_xs) {
            bend_tray_cut(cx);
            trench_cut(cx);
            eject_hole_cut(cx);
        }
        dowel_hole_base();
        join_pockets_base();
        foot_pad_cuts();
        if (rear_mark) rear_mark_cut();
    }
}

