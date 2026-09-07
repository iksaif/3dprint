// Dual Wedge Charging Dock for Anker Zolo A25M2 -- v2
//
// Two-piece PETG chassis (base + top plate) plus a flexible TPU top insert.
// The chassis is parted on the inclined plane that carries the puck floors:
// the top plate is a constant-thickness slab with THROUGH bores, the base is a
// wedge whose sloped top face IS the puck floor. Every printable part prints
// flat, supportless, with no bridge longer than max_bridge_span.
// See PRINTING.md and CHANGELOG.md for the reasoning.
//
// Units: millimetres. World coordinates: X across, Y front->rear, Z up.
// "Local" (top-frame) coordinates: origin at the front top edge, y up the
// incline, z normal to the top face (see top_frame()). Local z = 0 is the top
// face, local z = -plate_thickness is the parting plane.

/* [Selection] */
// Visual style
style = "soft_monolith"; // [soft_monolith, floating_deck, faceted, furniture]
// What to render / export
part = "assembly"; // [assembly, chassis, base, top_plate, top_insert, top_insert_flat, mat, dowel_pins, fit_test, fit_test_mat, fit_dummies, cable_clearance, dimensions]
// Retention of the top plate on the base (two locating dowels are always present)
join_method = "magnets"; // [magnets, inserts, none]
// Show non-printing puck/cable reference solids in the assembly view
show_fit_dummies = true;

/* [Printing constraints] */
print_layer_height = 0.2;
// Steepest overhang the printer is trusted with, degrees from vertical. Every chamfer is derived from this.
max_overhang_angle = 45;
// Longest unsupported flat ceiling allowed anywhere (small blind pockets only)
max_bridge_span = 10;
// Minimum wall between any cavity and the exterior
min_wall = 2.4;
// Minimum floor under any cavity
min_floor = 2.0;
// Print bed, square
bed_size = 256;

/* [Fit -- measure your parts] */
// Advertised puck diameter. Measure yours with calipers.
puck_nominal_diameter = 60;
// Clearance per side in the PETG bore (0.5 mm total by default)
puck_radial_clearance = 0.25;
// Puck height; the top plate is exactly this thick
puck_height = 10.5;
// Total X/Y clearance of the TPU insert in its recess
mat_clearance_total = 0.55;
// Hole diameter in the TPU insert (TPU should hug the puck)
puck_hole_diameter = 60.0;
// Locating dowel pin diameter (printed pins, part = "dowel_pins")
dowel_diameter = 4.0;
// 6 x 2 mm disc magnets by default
magnet_diameter = 6.0;
magnet_thickness = 2.0;
// Hole for an M3 heat-set insert (join_method = "inserts")
insert_hole_diameter = 4.0;
insert_hole_depth = 6.0;

/* [Hidden] */
$fn = 96;
eps = 0.01;   // overlap to avoid coincident faces
ov = 1.0;     // over-cut so cutters clear part faces
big = 600;    // "infinite" extent for blocks and slabs

// ---------------------------------------------------------------------------
// Style system: one table of [key, value] pairs per style, per-key defaults.
// Adding a style = one line; adding a key = one default line.
// ---------------------------------------------------------------------------

style_defaults = [
    ["front_height",        14],    // world Z of the front top edge
    ["footprint_radius",    11],    // plan-view corner radius
    ["footprint_exponent",   4],    // 2 = circular corners, 4 = squircle
    ["top_edge_chamfer",   1.5],    // run of the chamfer around the top face
    ["recess_border",      7.0],    // top-face border around the TPU insert
    ["reveal_depth",       0.8],    // shadow gap inset on the base, below the parting line
    ["reveal_height",      0.8],    // shadow gap height along the parting-plane normal
    ["puck_spacing",        73],    // centre to centre
    ["mat_surface_recess", 0.65],   // TPU top sits this far below the PETG border
    ["mat_bezel_width",    1.8],    // raised TPU ring framing each puck (0 = none)
    ["mat_bezel_height",   0.4],
    ["channel_radius",     3.0],    // corner radius of cable channels / bay
    ["rear_mark",         true]     // debossed mark on the rear face
];

styles = [
    ["soft_monolith", []],
    ["floating_deck", [
        ["front_height", 15], ["footprint_radius", 8], ["footprint_exponent", 2],
        ["top_edge_chamfer", 1.0], ["recess_border", 6.0],
        ["reveal_depth", 2.0], ["reveal_height", 2.0], ["mat_surface_recess", 0.45]]],
    ["faceted", [
        ["front_height", 15], ["footprint_radius", 3], ["footprint_exponent", 2],
        ["top_edge_chamfer", 3.0], ["recess_border", 6.0], ["reveal_height", 1.0],
        ["puck_spacing", 75], ["mat_surface_recess", 0.45],
        ["channel_radius", 1.8], ["mat_bezel_width", 1.5]]],
    ["furniture", [
        ["footprint_radius", 14], ["top_edge_chamfer", 2.0], ["recess_border", 7.5],
        ["reveal_depth", 1.0], ["reveal_height", 1.0], ["mat_bezel_width", 2.0]]]
];

function kv(list, key) =
    let(hits = [for (e = list) if (e[0] == key) e[1]])
    len(hits) > 0 ? hits[0] : undef;

style_names = [for (s = styles) s[0]];
assert(!is_undef(kv(styles, style)),
       str("Unknown style '", style, "'. Known styles: ", style_names));

// Style parameter lookup: style override, else default.
function sp(key) =
    let(d = kv(style_defaults, key), o = kv(kv(styles, style), key))
    assert(!is_undef(d), str("No default for style key '", key, "'"))
    is_undef(o) ? d : o;

front_height       = sp("front_height");
footprint_radius   = sp("footprint_radius");
footprint_exponent = sp("footprint_exponent");
top_edge_chamfer   = sp("top_edge_chamfer");
recess_border      = sp("recess_border");
reveal_depth       = sp("reveal_depth");
reveal_height      = sp("reveal_height");
puck_spacing       = sp("puck_spacing");
mat_surface_recess = sp("mat_surface_recess");
mat_bezel_width    = sp("mat_bezel_width");
mat_bezel_height   = sp("mat_bezel_height");
channel_radius     = sp("channel_radius");
rear_mark          = sp("rear_mark");

// ---------------------------------------------------------------------------
// Overall body
// ---------------------------------------------------------------------------

body_width = 158;
body_depth = 110;          // horizontal footprint, front to rear
top_angle  = 18;           // degrees
top_length = body_depth / cos(top_angle);
back_height = front_height + body_depth * tan(top_angle);

// Every chamfer is (run, rise) derived from the overhang limit.
function chamfer_rise(run) = run / tan(max_overhang_angle);

base_bottom_chamfer  = 0.5;   // hides elephant foot on the base
plate_bottom_chamfer = 0.4;   // hides elephant foot on the top plate, sharpens the reveal

// ---------------------------------------------------------------------------
// Top plate / recess / insert
// ---------------------------------------------------------------------------

puck_bore_diameter = puck_nominal_diameter + 2 * puck_radial_clearance;
plate_thickness    = puck_height;               // through-bore: base top is the puck floor
recess_depth       = 5.0;
recess_lead_in     = 0.6;                       // chamfer run at the top of the recess wall
plate_floor        = plate_thickness - recess_depth;
mat_thickness      = recess_depth - mat_surface_recess;
puck_capture_depth = puck_height - mat_thickness;

recess_width  = body_width - 2 * recess_border;
recess_length = top_length - 2 * recess_border;
mat_width     = recess_width - mat_clearance_total;
mat_length    = recess_length - mat_clearance_total;
recess_corner_radius = footprint_radius - recess_border;   // concentric with the outer corner (may be <= 0 -> sharp)

// ---------------------------------------------------------------------------
// Pucks and cable path
// ---------------------------------------------------------------------------

// Bend slot must leave at least this much recess floor in front of it
front_cable_keepout = recess_border + 1.0;
cable_bend_square   = 20.0;      // 180-degree bend envelope, plan view
rim_cable_channel_width  = 14.0; // USB-C plug overmold clearance
rim_cable_channel_height = 8.5;
rim_cable_overlap_into_puck = 2.5;

puck_y = max(top_length / 2,
             puck_bore_diameter / 2 + front_cable_keepout + cable_bend_square);
puck_xs = [-puck_spacing / 2, puck_spacing / 2];
puck_front_y = puck_y - puck_bore_diameter / 2;   // local y of the bore's front edge
puck_rear_y  = puck_y + puck_bore_diameter / 2;

bend_slot_width    = max(rim_cable_channel_width, cable_bend_square);
bend_slot_length   = cable_bend_square + rim_cable_overlap_into_puck;
bend_slot_front_y  = puck_front_y - cable_bend_square;
bend_slot_center_y = bend_slot_front_y + bend_slot_length / 2;
bend_tray_depth    = rim_cable_channel_height - plate_floor;   // part of the envelope below the parting plane

trench_width = rim_cable_channel_width;
trench_depth = rim_cable_channel_height;

// Coordinate helpers -------------------------------------------------------

function top_to_world(p) = [
    p[0],
    p[1] * cos(top_angle) - p[2] * sin(top_angle),
    front_height + p[1] * sin(top_angle) + p[2] * cos(top_angle)
];
function world_to_top(p) = [
    p[0],
    p[1] * cos(top_angle) + (p[2] - front_height) * sin(top_angle),
    -p[1] * sin(top_angle) + (p[2] - front_height) * cos(top_angle)
];
// World Z of the parting plane at world Y
function parting_z(y) = front_height + y * tan(top_angle) - plate_thickness / cos(top_angle);
// Local y of the point on the parting plane above world Y
function local_y_on_parting(y) = (y - plate_thickness * sin(top_angle)) / cos(top_angle);

base_front_height = parting_z(0);
base_rear_height  = parting_z(body_depth);

// ---------------------------------------------------------------------------
// Cable bay (base, open-topped, roofed by the flat underside of the top plate)
// ---------------------------------------------------------------------------

bay_side_wall  = 13;
bay_rear_wall  = 4;
bay_front_wall = 2.5;          // between the puck floor's rear edge and the bay
base_floor     = 2.0;
bay_width      = body_width - 2 * bay_side_wall;
puck_rear_world_y = top_to_world([0, puck_rear_y, -plate_thickness])[1];
bay_front_y    = puck_rear_world_y + bay_front_wall;
bay_rear_y     = body_depth - bay_rear_wall;
bay_depth      = bay_rear_y - bay_front_y;
bay_corner_radius = min(channel_radius, bay_depth / 2 - 0.5);

trench_start_y = puck_front_y;                              // overlaps the bend tray by rim_cable_overlap_into_puck
trench_end_y   = local_y_on_parting(bay_front_y + 6);       // runs 6 mm into the bay
trench_length  = trench_end_y - trench_start_y;

// Rear access: a notch in the base's rear wall, lintel = top plate underside
rear_access_window_width  = 94;
rear_access_window_height = 11;
rear_access_window_radius = min(4.0, rear_access_window_height / 2 - 0.5);
rear_access_window_bottom_z = base_rear_height - rear_access_window_height;

// Debossed rear mark
rear_mark_depth = 0.35;
rear_mark_size  = 9;
rear_mark_z     = rear_access_window_bottom_z - 4 - rear_mark_size / 2;

// ---------------------------------------------------------------------------
// Join: dowels (always) + magnets or inserts
// ---------------------------------------------------------------------------

dowel_length          = 10;
dowel_plate_clearance = 0.30;   // diameter
dowel_base_clearance  = 0.15;   // diameter, light press
dowel_base_depth      = dowel_length - plate_floor + 0.5;
dowel_y_offset        = 20;     // from puck centre, along the rib between the pucks
dowel_ys              = [puck_y - dowel_y_offset, puck_y + dowel_y_offset];

magnet_pocket_diameter = magnet_diameter + 0.3;
magnet_pocket_depth    = magnet_thickness + 0.2;
join_x_inset  = 7.0;            // from the recess wall
join_y_offset = 22;             // from puck centre
join_xs = [-(recess_width / 2 - join_x_inset), recess_width / 2 - join_x_inset];
join_ys = [puck_y - join_y_offset, puck_y + join_y_offset];
screw_clearance_diameter = 3.4;
screw_head_diameter      = 6.2;
screw_head_depth         = 2.5;

// Anti-slip: recessed pads for 8 mm adhesive silicone feet
foot_pad_diameter = 8.5;
foot_pad_depth    = 0.8;
foot_inset        = 14;

// Maintenance
eject_hole_diameter = 3;
eject_hole_offset_x = trench_width / 2 + 4;   // beside the trench, still under the puck

// TPU cable relief at 6 o'clock
mat_cable_notch_width   = 8.0;
mat_cable_notch_length  = 10.0;
mat_cable_notch_overlap = 1.5;
mat_cable_notch_radius  = 2.2;

// Non-printing reference solids
cable_dummy_diameter = 4.2;

// Fit-test coupon.
// Must not equal puck_hole_diameter / 2: at exactly the bore radius the
// coupon's bounding box is tangent to the bore and the two lobes meet along a
// zero-width edge, which is non-manifold (and would print as a knife edge).
// Keep it just inside so the box cuts the bore as a secant.
fit_quadrant = puck_hole_diameter / 2 - 0.5;
fit_corner   = 9;

// ---------------------------------------------------------------------------
// Design rules (asserts)
// ---------------------------------------------------------------------------

function floor_under_local(yl, zl) = top_to_world([0, yl, zl])[2];   // world Z = floor thickness above bed

tray_floor   = floor_under_local(bend_slot_front_y, -plate_thickness - bend_tray_depth);
trench_floor = floor_under_local(trench_start_y, -plate_thickness - trench_depth);
puck_rib     = puck_spacing - puck_bore_diameter;
mat_ligament = (mat_width - puck_spacing - puck_hole_diameter) / 2;
puck_side_floor = recess_width / 2 - (puck_spacing / 2 + puck_bore_diameter / 2);
dowel_hole_to_bore = (puck_spacing / 2 - sqrt(pow(puck_bore_diameter / 2, 2) - pow(dowel_y_offset, 2)))
                     - (dowel_diameter + dowel_plate_clearance) / 2;
join_to_bore = (join_xs[1] - magnet_pocket_diameter / 2)
               - (puck_spacing / 2 + sqrt(pow(puck_bore_diameter / 2, 2) - pow(join_y_offset, 2)));
join_rear_world_y = top_to_world([0, join_ys[1], -plate_thickness])[1] + magnet_pocket_diameter / 2;
dowel_rear_world_y = top_to_world([0, dowel_ys[1], -plate_thickness])[1] + dowel_diameter / 2;

assert(footprint_radius >= 1, "footprint_radius must be >= 1");
assert(footprint_exponent >= 2, "footprint_exponent must be >= 2");
assert(top_angle < max_overhang_angle,
       str("Top plate front/rear faces overhang by ", top_angle, " deg >= max_overhang_angle"));
assert(max(body_width, body_depth, top_length) <= bed_size, "Part does not fit the bed");

// Cable path
assert(bend_slot_front_y >= front_cable_keepout - eps,
       str("Bend slot breaches the front keepout: starts at ", bend_slot_front_y));
assert(puck_front_y - front_cable_keepout >= cable_bend_square - eps,
       "Less than the full cable bend envelope in front of the puck");
assert(bend_tray_depth >= 0, "Cable envelope shallower than the recess floor; increase rim_cable_channel_height");
assert(tray_floor >= min_floor, str("Base floor under the bend tray is ", tray_floor, " mm"));
assert(trench_floor >= min_floor, str("Base floor under the plug trench is ", trench_floor, " mm"));

// Bay walls
assert(bay_side_wall >= min_wall && bay_rear_wall >= min_wall && bay_front_wall >= min_wall,
       "Cable bay wall below min_wall");
assert(base_floor >= min_floor, "Cable bay floor below min_floor");
assert(bay_depth >= 12, str("Cable bay too shallow: ", bay_depth, " mm"));
assert(plate_floor >= min_floor, str("Top plate floor over the bay is ", plate_floor, " mm"));
assert(rear_access_window_width <= bay_width - 2 * min_wall, "Rear window wider than the bay");
assert(rear_access_window_bottom_z >= base_floor + 3, "Rear window cuts into the bay floor");
assert(rear_mark_z - rear_mark_size / 2 >= chamfer_rise(base_bottom_chamfer) + 2, "Rear mark too low");

// Puck seats
assert(puck_rib >= 8, str("Rib between the puck bores is only ", puck_rib, " mm"));
assert(puck_side_floor >= 3, str("Recess floor beside a puck bore is only ", puck_side_floor, " mm"));
assert(mat_ligament >= 4, str("TPU insert too thin beside a puck: ", mat_ligament, " mm"));
assert(mat_bezel_width <= mat_ligament - 1, "TPU bezel ring runs into the insert edge");
assert(mat_bezel_height < mat_surface_recess, "TPU bezel would stand above the PETG border");
assert(plate_thickness == puck_height, "Through-bore design requires plate_thickness == puck_height");

// Join
assert(dowel_hole_to_bore >= 3, str("Dowel hole too close to a puck bore: ", dowel_hole_to_bore));
assert(join_to_bore >= 2, str("Magnet/insert pocket too close to a puck bore: ", join_to_bore));
assert(join_rear_world_y + min_wall <= bay_front_y, "Rear magnet/insert pocket runs into the cable bay");
assert(dowel_rear_world_y + min_wall <= bay_front_y, "Rear dowel runs into the cable bay");
assert(plate_floor - magnet_pocket_depth >= min_floor, "Plate too thin above the magnet pockets");
assert(plate_floor - screw_head_depth >= min_floor, "Plate too thin under the screw counterbores");
assert(floor_under_local(join_ys[0], -plate_thickness - max(magnet_pocket_depth, insert_hole_depth)) >= min_floor,
       "Base too thin under the front magnet/insert pockets");
assert(join_xs[1] + magnet_pocket_diameter / 2 <= recess_width / 2 - 0.5, "Join pocket runs into the recess wall");

// Reveal and edges
assert(base_front_height - reveal_height / cos(top_angle) >= chamfer_rise(base_bottom_chamfer) + 1.0,
       str("Base front lip too short for the reveal: ", base_front_height, " mm"));
assert(reveal_depth < bay_side_wall - min_wall, "Reveal too deep for the bay side wall");
assert(top_edge_chamfer < recess_border, "Top edge chamfer eats the whole border");
assert(recess_lead_in < recess_border / 2, "Recess lead-in too large");

// Overhang / bridge budget. Every downward-facing feature is listed here.
assert(magnet_pocket_diameter <= max_bridge_span, "Magnet pocket ceiling exceeds max_bridge_span");   // blind pocket in the plate underside
assert(foot_pad_diameter <= max_bridge_span, "Foot pad ceiling exceeds max_bridge_span");             // blind pocket in the base underside
assert(screw_head_diameter <= max_bridge_span, "Screw counterbore exceeds max_bridge_span");           // open pocket, listed for completeness
// Chamfers: run/rise = tan(max_overhang_angle) by construction (chamfer_rise()).
// Top plate front/rear walls: top_angle from vertical (asserted above).
// Everything else is vertical, open-topped, or a through-hole.

// ---------------------------------------------------------------------------
// 2D helpers
// ---------------------------------------------------------------------------

module rounded_rect_2d(width, depth, radius) {
    r = min(radius, width / 2 - eps, depth / 2 - eps);
    offset(r = r) offset(delta = -r) square([width, depth], center = true);
}

// Rectangle with superellipse corners (n = 2 circular, n = 4 squircle), CCW.
function superrect_points(w, d, r, n, steps = 24) =
    let(hw = w / 2 - r, hd = d / 2 - r)
    [for (c = [[1, 1, 0], [-1, 1, 90], [-1, -1, 180], [1, -1, 270]])
        for (i = [0 : steps])
            let(t = c[2] + 90 * i / steps, ct = cos(t), st = sin(t))
            [c[0] * hw + sign(ct) * pow(abs(ct), 2 / n) * r,
             c[1] * hd + sign(st) * pow(abs(st), 2 / n) * r]];

// Plan-view outline, y from 0 (front) to body_depth (rear). inset = true parallel offset.
module footprint_2d(inset = 0) {
    translate([0, body_depth / 2])
        offset(delta = -inset)
            polygon(superrect_points(body_width, body_depth, footprint_radius, footprint_exponent));
}

// Section of the vertical footprint prism by the plane local z = zl, in local
// (x, y) coordinates, optionally inset by a parallel offset measured on that
// plane. All nested top-face profiles derive from this, so borders are
// constant-width around every corner.
module top_outline_2d(zl = 0, inset = 0) {
    offset(delta = -inset)
        translate([0, zl * tan(top_angle)])
            scale([1, 1 / cos(top_angle)])
                footprint_2d();
}

// ---------------------------------------------------------------------------
// 3D helpers
// ---------------------------------------------------------------------------

module top_frame() {
    translate([0, 0, front_height]) rotate([top_angle, 0, 0]) children();
}

// Inverse of top_frame(), then lift so the parting plane is z = 0.
module unframe() {
    translate([0, 0, plate_thickness])
        rotate([-top_angle, 0, 0])
            translate([0, 0, -front_height])
                children();
}

module local_slab(z_lo, z_hi) {
    top_frame()
        translate([-big / 2, -big / 2, z_lo])
            cube([big, big, z_hi - z_lo]);
}

module footprint_prism(inset = 0, z0 = -ov, z1 = big) {
    translate([0, 0, z0])
        linear_extrude(height = z1 - z0, convexity = 10)
            footprint_2d(inset);
}

// 2D child in the (x, z) plane, extruded from world y0 to y1.
module extrude_y(y0, y1) {
    translate([0, y1, 0]) rotate([90, 0, 0])
        linear_extrude(height = y1 - y0, convexity = 6)
            children();
}

module slice_at(zl) {
    translate([0, 0, zl]) linear_extrude(height = eps) children();
}

module local_box(x0, x1, y0, y1, z0 = -big / 2, z1 = big / 2) {
    translate([x0, y0, z0]) cube([x1 - x0, y1 - y0, z1 - z0]);
}

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
else if (part == "dimensions")      { echo_dimensions(); cube(1); }
else                                assembly();
