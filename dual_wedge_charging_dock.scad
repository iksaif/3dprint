// Dual Wedge Charging Dock for Anker Zolo A25M2
// Four visual styles sharing one functional core.
// Units: millimeters

// Styles:
//   "soft_monolith" - calm radii, slim front, subtly recessed TPU insert
//   "floating_deck" - rigid top deck on an inset support/shadow gap
//   "faceted"       - crisp, side-print-friendly planar chamfers
//   "furniture"     - broad soft radii for warm/muted filament colours
style = "soft_monolith";

// Parts:
//   "assembly", "chassis", "chassis_side_print", "top_insert",
//   "top_insert_flat", "mat" (legacy alias), "fit_dummies",
//   or "cable_clearance"
part = "assembly";

$fn = 96;
eps = 0.08;
print_layer_height = 0.2;

is_soft = style == "soft_monolith";
is_floating = style == "floating_deck";
is_faceted = style == "faceted";
is_furniture = style == "furniture";

assert(is_soft || is_floating || is_faceted || is_furniture,
    str("Unknown style: ", style));

// Overall chassis
body_width = 158;
body_depth = 110;          // horizontal footprint, front to rear
front_height = is_soft ? 12 : is_floating ? 14 : is_faceted ? 15 : 12;
top_angle = 18;            // degrees
back_height = front_height + body_depth * tan(top_angle);
top_length = body_depth / cos(top_angle);

// Smooth exterior shaping
side_print_friendly = is_faceted;
side_profile_radius = is_soft ? 5.8 : is_floating ? 5.0 : is_faceted ? 0 : 7.0;
footprint_radius = is_soft ? 11 : is_floating ? 8 : is_faceted ? 3 : 14;
top_side_edge_radius = is_soft ? 3.0 : is_floating ? 2.0 : is_faceted ? 1.2 : 3.8;
side_profile_front_bottom_chamfer = is_faceted ? 5.0 : 3.0;
side_profile_front_top_chamfer = is_faceted ? 3.0 : 2.0;
side_profile_rear_bottom_chamfer = is_faceted ? 4.0 : 3.0;
side_profile_rear_top_chamfer = is_faceted ? 3.0 : 2.0;

// A small perimeter undercut reduces visual weight and hides elephant foot.
bottom_undercut_depth = is_faceted ? 0.8 : 1.3;
bottom_undercut_height = is_faceted ? 1.0 : 1.6;

// Top insert. The soft/furniture/faceted versions are intended for TPU.
// The floating version is intended as a separate rigid PLA/PETG deck.
recess_border = is_soft ? 7.0 : is_floating ? 6.0 : is_faceted ? 6.0 : 7.5;
recess_depth = 5.0;
recess_radius = is_soft ? 8.0 : is_floating ? 7.0 : is_faceted ? 3.0 : 10.0;
mat_clearance_total = is_floating ? 0.35 : 0.25;
insert_surface_recess = is_floating ? 0 : is_faceted ? 0.4 : 0.65;

// Floating deck: an inset support carries the deck while leaving a visible
// shadow line around its perimeter. Both pieces print flat/without supports.
floating_support_height = 1.6;
floating_deck_thickness = 3.2;
floating_support_inset = 4.5;
mat_thickness = is_floating
    ? floating_deck_thickness
    : recess_depth - insert_surface_recess;
surface_z = is_floating
    ? floating_support_height + floating_deck_thickness
    : 0;

// Advertised Anker Zolo A25M2 puck dimensions
puck_diameter = 60.4;      // 60 mm puck + 0.4 mm press-fit allowance
puck_hole_diameter = 60.0;
insert_hole_diameter = is_floating ? 60.5 : puck_hole_diameter;
puck_height = 10.5;
puck_capture_depth = puck_height - mat_thickness;
puck_spacing = is_faceted ? 75 : 73;

// Cable bend fit envelope
front_cable_keepout = 7.0; // keeps plug relief from opening through front
cable_bend_square = 20.0; // minimum 180-degree cable bend area in top view
puck_y = max(
    top_length / 2,
    puck_diameter / 2 + front_cable_keepout + cable_bend_square
);
puck_xs = [-puck_spacing / 2, puck_spacing / 2];

// 6 o'clock rim-exit cable management
rim_cable_channel_width = 14.0;  // USB-C plug overmold clearance
rim_cable_channel_height = 8.5;
rim_cable_overlap_into_puck = 2.5;
desired_rim_cable_channel_length = cable_bend_square + rim_cable_overlap_into_puck;
rim_cable_channel_length = min(
    desired_rim_cable_channel_length,
    puck_y - puck_diameter / 2 - front_cable_keepout
        + rim_cable_overlap_into_puck
);
rim_cable_channel_radius = is_faceted ? 1.8 : 3.1;
rim_cable_channel_center_z =
    surface_z - mat_thickness - rim_cable_channel_height / 2 + 0.05;
plug_chase_section_depth = 6.5;
plug_chase_width = 14.0;
plug_chase_height = 8.5;
plug_chase_radius = is_faceted ? 1.8 : 3.1;
cable_bend_clearance_width = max(rim_cable_channel_width, cable_bend_square);
cable_bay_width = 132;
cable_bay_depth = 44;
cable_bay_height = 11;
cable_bay_center_y = body_depth - 28;
cable_bay_center_z = 11;
cable_bay_radius = is_faceted ? 1.8 : 3.5;

// Rear access opening into the shared cable bay
rear_access_window_depth = 24; // cut depth through rear wall, Y direction
rear_access_window_width = 94; // visible length, X direction
rear_access_window_height = 11;
rear_access_window_center_y = body_depth;
rear_access_window_center_z = 11.8;
rear_access_window_radius = is_faceted ? 2.4 : 4.0;

// Visible TPU relief for the puck's attached cable jacket
mat_cable_notch_width = 8.0;
mat_cable_notch_length = 10.0;
mat_cable_notch_overlap = 1.5;
mat_cable_notch_radius = 2.2;

// Maintenance features
eject_hole_diameter = 3;

// Non-printing fit dummies shown only in "assembly" or "fit_dummies"
show_fit_dummies = true;
cable_dummy_diameter = 4.2;      // estimate: measure actual cable if needed
cable_exit_local_z = surface_z - mat_thickness - puck_capture_depth / 2;

recess_width = body_width - 2 * recess_border;
recess_length = top_length - 2 * recess_border;
mat_width = recess_width - mat_clearance_total;
mat_length = recess_length - mat_clearance_total;
mat_radius = max(0.1, recess_radius - mat_clearance_total / 2);
insert_side_ligament =
    (mat_width - puck_spacing - insert_hole_diameter) / 2;

assert(insert_side_ligament >= 4,
    str("Top insert too thin beside puck: ", insert_side_ligament, " mm"));

function top_to_world(p) = [
    p[0],
    p[1] * cos(top_angle) - p[2] * sin(top_angle),
    front_height + p[1] * sin(top_angle) + p[2] * cos(top_angle)
];

function puck_bottom_world(cx) =
    top_to_world([cx, puck_y, surface_z - puck_height]);

module top_frame() {
    translate([0, 0, front_height])
        rotate([top_angle, 0, 0])
            children();
}

module rounded_rect_2d(width, depth, radius) {
    offset(r = radius)
        offset(delta = -radius)
            square([width, depth], center = true);
}

module wedge_side_profile_rounded_2d() {
    offset(r = side_profile_radius)
        offset(delta = -side_profile_radius)
            polygon(points = [
                [0, 0],
                [body_depth, 0],
                [body_depth, back_height],
                [0, front_height]
            ]);
}

module wedge_side_profile_chamfered_2d() {
    fb = side_profile_front_bottom_chamfer;
    ft = side_profile_front_top_chamfer;
    rb = side_profile_rear_bottom_chamfer;
    rt = side_profile_rear_top_chamfer;
    tq_front = ft / (1 - tan(top_angle));
    tq_rear = rt / (1 + tan(top_angle));

    polygon(points = [
        [fb, 0],
        [body_depth - rb, 0],
        [body_depth, rb],
        [body_depth, back_height - rt],
        [body_depth - tq_rear, back_height - tq_rear * tan(top_angle)],
        [tq_front, front_height + tq_front * tan(top_angle)],
        [0, front_height - ft],
        [0, fb]
    ]);
}

module wedge_side_profile_2d() {
    if (side_print_friendly)
        wedge_side_profile_chamfered_2d();
    else
        wedge_side_profile_rounded_2d();
}

module wedge_from_side_profile() {
    multmatrix(m = [
        [0, 0, 1, -body_width / 2],
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 0, 1]
    ])
        linear_extrude(height = body_width, convexity = 10)
            wedge_side_profile_2d();
}

module rounded_footprint_mask() {
    translate([0, body_depth / 2, -eps])
        linear_extrude(height = back_height + 2 * eps, convexity = 10)
            rounded_rect_2d(body_width, body_depth, footprint_radius);
}

module extrude_along_y(length) {
    translate([0, -length / 2, 0])
        multmatrix(m = [
            [1, 0, 0, 0],
            [0, 0, 1, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 1]
        ])
            linear_extrude(height = length, convexity = 10)
                children();
}

module top_side_edge_round_cut_2d(sign) {
    r = top_side_edge_radius;
    edge_x = sign * body_width / 2;

    difference() {
        if (sign > 0)
            translate([edge_x - r, -r])
                square([r + eps, r + eps]);
        else
            translate([edge_x - eps, -r])
                square([r + eps, r + eps]);

        translate([edge_x - sign * r, -r])
            circle(r = r, $fn = 36);
    }
}

module top_side_edge_rounding_cuts() {
    top_frame()
        translate([0, top_length / 2, 0])
            for (side = [-1, 1])
                extrude_along_y(top_length + 4)
                    top_side_edge_round_cut_2d(side);
}

module wedge_body() {
    intersection() {
        wedge_from_side_profile();
        rounded_footprint_mask();
    }
}

module bottom_undercut_cut() {
    // Removes only the outer perimeter at the first few layers, leaving a
    // continuous inset footprint rather than fragile decorative feet.
    translate([0, body_depth / 2, -eps])
        linear_extrude(
            height = bottom_undercut_height + eps,
            convexity = 10
        )
            difference() {
                rounded_rect_2d(body_width + 2, body_depth + 2,
                    footprint_radius + 1);
                offset(delta = -bottom_undercut_depth)
                    rounded_rect_2d(body_width, body_depth, footprint_radius);
            }
}

module floating_deck_support() {
    support_width = mat_width - 2 * floating_support_inset;
    support_length = mat_length - 2 * floating_support_inset;
    support_radius = max(1, mat_radius - floating_support_inset);

    top_frame()
        translate([0, puck_y, -eps])
            linear_extrude(
                height = floating_support_height + eps,
                convexity = 10
            )
                rounded_rect_2d(
                    support_width,
                    support_length,
                    support_radius
                );
}

module chassis_positive() {
    union() {
        wedge_body();
        if (is_floating)
            floating_deck_support();
    }
}

module rounded_panel_cut(depth) {
    top_frame()
        translate([0, puck_y, -depth])
            linear_extrude(height = depth + eps, convexity = 10)
                rounded_rect_2d(recess_width, recess_length, recess_radius);
}

module charger_cavity(cx) {
    top_frame()
        translate([cx, puck_y, surface_z - puck_height])
            cylinder(h = puck_height + eps, d = puck_diameter);
}

module cable_bend_clearance(cx) {
    front_edge_y = puck_y - puck_diameter / 2;
    channel_center_y =
        front_edge_y - rim_cable_channel_length / 2 + rim_cable_overlap_into_puck;

    top_frame()
        translate([
            cx,
            channel_center_y,
            rim_cable_channel_center_z - rim_cable_channel_height / 2
        ])
            linear_extrude(height = rim_cable_channel_height, convexity = 10)
                rounded_rect_2d(
                    cable_bend_clearance_width,
                    rim_cable_channel_length,
                    rim_cable_channel_radius
                );
}

module rounded_box(size, radius) {
    hull() {
        for (x = [-size[0] / 2 + radius, size[0] / 2 - radius])
            for (y = [-size[1] / 2 + radius, size[1] / 2 - radius])
                for (z = [-size[2] / 2 + radius, size[2] / 2 - radius])
                    translate([x, y, z])
                        sphere(r = radius, $fn = 28);
    }
}

module tube_between(p1, p2, diameter) {
    hull() {
        translate(p1)
            sphere(d = diameter, $fn = 32);
        translate(p2)
            sphere(d = diameter, $fn = 32);
    }
}

module cable_storage_bay() {
    translate([0, cable_bay_center_y, cable_bay_center_z])
        rounded_box(
            [cable_bay_width, cable_bay_depth, cable_bay_height],
            cable_bay_radius
        );
}

module plug_chase_section() {
    rounded_box(
        [plug_chase_width, plug_chase_section_depth, plug_chase_height],
        plug_chase_radius
    );
}

module plug_feed_chase(cx) {
    front_edge_y = puck_y - puck_diameter / 2;
    bay_front_y = cable_bay_center_y - cable_bay_depth / 2;
    chase_start_y = front_edge_y - cable_bend_square / 2;
    p0 = top_to_world([
        cx,
        chase_start_y,
        rim_cable_channel_center_z
    ]);
    p1 = [cx, bay_front_y + 3, cable_bay_center_z];

    hull() {
        translate(p0)
            plug_chase_section();
        translate(p1)
            plug_chase_section();
    }
}

module cable_clearance(cx) {
    cable_bend_clearance(cx);
    plug_feed_chase(cx);
}

module puck_fit_dummy(cx) {
    top_frame()
        translate([cx, puck_y, surface_z - puck_height])
            union() {
                cylinder(h = puck_height, d = puck_hole_diameter);
                translate([0, 0, puck_height - 0.35])
                    cylinder(h = 0.38, d = puck_hole_diameter - 2.4);
            }
}

module cable_fit_dummy(cx) {
    front_edge_y = puck_y - puck_hole_diameter / 2;
    bend_front_y = front_edge_y - cable_bend_square;
    bay_front_y = cable_bay_center_y - cable_bay_depth / 2;

    p0 = top_to_world([cx, front_edge_y, cable_exit_local_z]);
    p1 = top_to_world([cx, bend_front_y, cable_exit_local_z]);
    p2 = top_to_world([cx, front_edge_y - cable_bend_square / 2, cable_exit_local_z]);
    p3 = [cx, bay_front_y + 3, cable_bay_center_z];

    tube_between(p0, p1, cable_dummy_diameter);
    tube_between(p2, p3, cable_dummy_diameter);
}

module fit_dummies() {
    for (cx = puck_xs) {
        color([0.95, 0.96, 0.94, 0.85])
            puck_fit_dummy(cx);

        color([1.0, 0.55, 0.05, 0.28])
            cable_clearance(cx);

        color([0.03, 0.03, 0.03, 0.9])
            cable_fit_dummy(cx);
    }
}

module rounded_prism_y(depth, width, height, radius) {
    hull() {
        for (x = [-width / 2 + radius, width / 2 - radius])
            for (z = [-height / 2 + radius, height / 2 - radius])
                translate([x, 0, z])
                    rotate([90, 0, 0])
                        cylinder(h = depth, r = radius, center = true, $fn = 36);
    }
}

module rear_access_window() {
    translate([0, rear_access_window_center_y, rear_access_window_center_z])
        rounded_prism_y(
            rear_access_window_depth,
            rear_access_window_width,
            rear_access_window_height,
            rear_access_window_radius
        );
}

module eject_hole(cx) {
    p = puck_bottom_world(cx);

    translate([p[0], p[1], -eps])
        cylinder(h = p[2] + 2 * eps, d = eject_hole_diameter, $fn = 40);
}

module chassis() {
    difference() {
        chassis_positive();
        top_side_edge_rounding_cuts();
        if (!is_floating)
            rounded_panel_cut(recess_depth);
        bottom_undercut_cut();
        cable_storage_bay();

        for (cx = puck_xs) {
            charger_cavity(cx);
            cable_clearance(cx);
            eject_hole(cx);
        }

        rear_access_window();
    }
}

module chassis_side_print() {
    translate([0, 0, body_width / 2])
        rotate([0, 90, 0])
            chassis();
}

module insert_cable_notch_2d(cx) {
    notch_y = -insert_hole_diameter / 2
        - mat_cable_notch_length / 2
        + mat_cable_notch_overlap;

    translate([cx, notch_y])
        rounded_rect_2d(
            mat_cable_notch_width,
            mat_cable_notch_length,
            mat_cable_notch_radius
        );
}

module top_insert_flat() {
    linear_extrude(height = mat_thickness, convexity = 10)
        difference() {
            rounded_rect_2d(mat_width, mat_length, mat_radius);

            for (cx = puck_xs) {
                translate([cx, 0])
                    circle(d = insert_hole_diameter);

                // The original file calculated this position but terminated
                // with a semicolon, so no cable notch was actually cut.
                insert_cable_notch_2d(cx);
            }
        }
}

module top_insert() {
    top_frame()
        translate([
            0,
            puck_y,
            is_floating ? floating_support_height : -recess_depth
        ])
            top_insert_flat();
}

module assembly() {
    chassis_colour = is_furniture
        ? [0.63, 0.45, 0.31]
        : is_faceted
            ? [0.15, 0.17, 0.18]
            : [0.25, 0.27, 0.26];
    insert_colour = is_floating
        ? [0.07, 0.08, 0.085]
        : [0.025, 0.03, 0.03];

    color(chassis_colour)
        chassis();

    color(insert_colour)
        top_insert();

    if (show_fit_dummies)
        fit_dummies();
}

if (part == "chassis")
    chassis();
else if (part == "chassis_side_print")
    chassis_side_print();
else if (part == "top_insert" || part == "mat")
    top_insert();
else if (part == "top_insert_flat")
    top_insert_flat();
else if (part == "fit_dummies")
    fit_dummies();
else if (part == "cable_clearance")
    for (cx = puck_xs)
        cable_clearance(cx);
else
    assembly();

