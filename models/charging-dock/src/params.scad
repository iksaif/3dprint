// Dual Wedge Charging Dock for Anker Zolo A25M2 -- v2
//
// Two-piece PETG chassis (base + top plate) plus a flexible TPU top insert.
// The chassis is parted on the inclined plane that carries the puck floors:
// the top plate is a constant-thickness slab with THROUGH bores, the base is a
// wedge whose sloped top face IS the puck floor. Every printable part prints
// flat, supportless, with no bridge longer than max_bridge_span.
// See PRINTING.md for orientation, slicer settings and assembly.
//
// Units: millimetres. World coordinates: X across, Y front->rear, Z up.
// "Local" (top-frame) coordinates: origin at the front top edge, y up the
// incline, z normal to the top face (see top_frame()). Local z = 0 is the top
// face, local z = -plate_thickness is the parting plane.

/* [Selection] */
// Visual style
style = "soft_monolith"; // [soft_monolith, floating_deck, faceted, furniture]
// What to render / export
part = "assembly"; // [assembly, chassis, base, top_plate, top_insert, top_insert_flat, mat, dowel_pins, set_petg, set_tpu, fit_test, fit_test_mat, fit_dummies, cable_clearance, showcase, dimensions]
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
// Print bed. This used to be a single square `bed_size = 256`, which is not the
// printer this repo targets: a Prusa MK4S is 250 x 210, and rectangular. The
// old number let the PETG set claim to fit while needing 235 mm of Y — 25 mm
// more than the machine has. Kept in step with ../../../lib/scad/print.scad.
bed_x = 250;
bed_y = 210;
// Retained for the asserts that only care about the smaller dimension.
bed_size = min(bed_x, bed_y);

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

