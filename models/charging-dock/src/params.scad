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
style = "soft_monolith"; // [soft_monolith, floating_deck, faceted, furniture, atelier]
// What to render / export
part = "assembly"; // [assembly, chassis, base, top_plate, top_insert, top_insert_flat, mat, dowel_pins, set_petg, set_tpu, fit_test, fit_test_mat, fit_test_dowel, fit_test_dowel_mat, fit_test_cable, fit_test_lip, fit_dummies, cable_clearance, showcase, dimensions]
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
// Widest phone that will sit on the dock, including its case. The pucks are
// spaced so that two of them side by side do not touch.
phone_width = 76;
// Gap left between the two phones
phone_gap = 4;
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
// Rigid USB-C strain relief where the cable leaves the puck rim at 6 o'clock:
// radial length out of the rim, and width
puck_boot_length = 12;
puck_boot_width = 5;
// Puck top face down to the top of the boot. Under recess_depth, the boot
// reaches up into the TPU mat's thickness and the mat's notch must clear it.
puck_boot_top_drop = 3;
// Boot thickness. Only its top matters to the fit: below it is the open bend slot.
puck_boot_height = 5;
// Centreline radius of the U-turn the flexible cable makes after the boot, to
// head back under the puck. Measured by bending the real cable.
cable_bend_radius = 5;
// Locating dowel pin diameter (printed pins, part = "dowel_pins")
dowel_diameter = 4.0;
// 6 x 2 mm disc magnets by default
magnet_diameter = 6.0;
magnet_thickness = 2.0;
// Hole for an M3 heat-set insert (join_method = "inserts")
insert_hole_diameter = 4.0;
insert_hole_depth = 6.0;

/* [TPU mat texture] */
// Raised TPU ring framing each puck. Off gives a flat top (flat both sides with mat_texture = "none")
mat_bezel = false;
// Print the mat face down: its visible face takes the build sheet's texture
// (no ironing needed) and the studs underneath point up. Needs mat_bezel = false.
mat_print_face_down = true;
// The mat's puck holes narrow towards the face, so the phone cannot lift the
// puck straight out. This is a TAPER, not a bead: a lip standing proud on one
// layer is loaded in peel by the rising puck and delaminates at its layer bond.
// Tapered, the load runs into bulk material as hoop tension, and every layer is
// supported by the one below it (each steps out by inset/depth * layer height).
// The narrow end sits mat_surface_recess below the puck's face, clear of the phone.
mat_puck_lip = true;
mat_puck_lip_inset = 0.3;    // radial pinch at the face, per side
mat_puck_lip_depth = 1.5;    // axial run of the taper, up to the face
// How far the taper roots into the mat's body. The wedge and the bore wall
// share a radius, so without an overlap they meet on coincident faces and the
// union comes out non-manifold -- which is exactly what mesh.py caught.
mat_puck_lip_root  = 0.6;
// TPU studs under the mat that press into blind holes in the recess floor, so
// the mat stays put without glue. Needs mat_print_face_down.
mat_dowels = true;
// Pattern cut into the mat's top face. Only ever cut IN: nothing rises toward
// the phone, which rests on the puck faces (flush with the PETG border), so the
// chargers' magnetic grip is exactly what it was with a flat mat.
// none by default: printed face down, the build sheet gives the texture.
mat_texture = "none"; // [none, hex, tread, rugged, fluted]
// Groove depth; keep it a whole number of layers
mat_texture_depth = 0.8;
// Groove width (TPU closes up anything much under 1 mm)
mat_texture_groove = 1.6;
// Centre-to-centre spacing of the grooves (tread rows / hex cells)
mat_texture_pitch = 9;
// Chevron arm angle from horizontal (tread only)
mat_texture_angle = 30;
// Smooth band kept round the mat edge, each bezel ring and each cable notch
mat_texture_margin = 3;
// Layout seed for the rugged stones; change it for a different arrangement
mat_texture_seed = 7;

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
    ["mat_surface_recess", 0.65],   // TPU top sits this far below the PETG border
    ["mat_bezel_width",    1.8],    // raised TPU ring framing each puck (0 = none)
    ["mat_bezel_height",   0.4],
    ["channel_radius",     3.0],    // corner radius of cable channels / bay
    ["rear_mark",         true],    // debossed mark on the rear face
    ["split_islands",    false],    // split TPU insert into two separate island pads
    ["island_width",      69.0],    // width of each island pad (plan view)
    ["island_length",    110.0],    // length of each island pad
    ["island_radius",      9.0],    // corner radius of each island pad
    ["base_bottom_chamfer", 0.5]    // bottom chamfer on the base (elephant foot & shadow lift)
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
        ["mat_surface_recess", 0.45],
        ["channel_radius", 1.8], ["mat_bezel_width", 1.5]]],
    ["furniture", [
        ["footprint_radius", 14], ["top_edge_chamfer", 2.0], ["recess_border", 7.5],
        ["reveal_depth", 1.0], ["reveal_height", 1.0], ["mat_bezel_width", 2.0]]],
    ["atelier", [
        ["front_height", 15], ["footprint_radius", 14], ["footprint_exponent", 4],
        ["top_edge_chamfer", 1.8], ["recess_border", 7.0],
        ["reveal_depth", 1.5], ["reveal_height", 1.2],
        ["mat_surface_recess", 0.65],
        ["base_bottom_chamfer", 1.0],
        ["split_islands", true],
        ["island_width", 69.0], ["island_length", 110.0], ["island_radius", 9.0]]]
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
// Centre to centre: two phones side by side with phone_gap between them. Was a
// style key (73, faceted 75), which put two phones against each other.
puck_spacing       = phone_width + phone_gap;
mat_surface_recess = sp("mat_surface_recess");
mat_bezel_width    = mat_bezel ? sp("mat_bezel_width") : 0;
mat_bezel_height   = sp("mat_bezel_height");
// Smooth band kept round each puck hole on a textured top: where the ring sits
// when there is one, and the same width without it. Narrowing it when the ring
// is off pulls the texture onto the neck between the pucks and leaves groove
// stubs too small to print.
mat_texture_hole_band = sp("mat_bezel_width") + mat_texture_margin;
channel_radius     = sp("channel_radius");
rear_mark          = sp("rear_mark");
split_islands      = sp("split_islands");
island_width       = sp("island_width");
island_length      = sp("island_length");
island_radius      = sp("island_radius");
base_bottom_chamfer = sp("base_bottom_chamfer");

// ---------------------------------------------------------------------------
// Overall body
// ---------------------------------------------------------------------------

// Border from each puck bore out to the body's side, as on the original 158 mm body
puck_side_margin = 12.25;
body_width = puck_spacing + puck_nominal_diameter + 2 * puck_radial_clearance + 2 * puck_side_margin;
// Horizontal footprint, front to rear. Was 110; 118 grows the cable bay and is
// the most the MK4S bed takes for the rigid set (asserted in main.scad).
body_depth = 118;
top_angle  = 18;           // degrees
top_length = body_depth / cos(top_angle);
back_height = front_height + body_depth * tan(top_angle);

// Every chamfer is (run, rise) derived from the overhang limit.
function chamfer_rise(run) = run / tan(max_overhang_angle);

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

bay_side_wall  = 6;            // was 13; thinned for cable storage
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
// The rear pads sit under the cable bay. A boss inside the bay over each keeps
// min_floor above the pad's ceiling instead of base_floor - foot_pad_depth.
foot_boss_diameter = foot_pad_diameter + 2 * min_wall;

// Maintenance
eject_hole_diameter = 3;
eject_hole_offset_x = trench_width / 2 + 4;   // beside the trench, still under the puck

// The cable's path out of the puck, as measured: the rigid boot leaves the rim
// at 6 o'clock, then the flexible cable makes a U-turn of centreline radius
// cable_bend_radius starting at the boot's end, and runs back under the puck.
cable_dummy_diameter = 4.2;
cable_boot_z        = -puck_boot_top_drop - puck_boot_height / 2;   // boot centreline, local z
cable_boot_end_y    = puck_y - puck_nominal_diameter / 2 - puck_boot_length;
cable_loop_outer    = cable_bend_radius + cable_dummy_diameter / 2;
cable_loop_centre_z = cable_boot_z - cable_bend_radius;
cable_loop_bottom_z = cable_loop_centre_z - cable_loop_outer;
// Run past the boot before the top of the bending cable is below the mat's underside
cable_dive_cos = (-recess_depth - cable_loop_centre_z) / cable_loop_outer;
cable_dive_run = cable_dive_cos >= 1 ? 0
               : cable_dive_cos <= 0 ? cable_loop_outer
               : cable_loop_outer * sqrt(1 - cable_dive_cos * cable_dive_cos);

// TPU cable relief at 6 o'clock. The boot's top sits above the mat's underside,
// so the notch has to clear the whole boot and the cable's dive after it, not
// just the cable. It was a fixed 10 mm (8.5 past the hole) against an 11 mm
// boot, and the first test fit showed the boot riding up on the notch end.
mat_cable_notch_clearance = 1.0;
mat_cable_notch_width   = max(8.0, puck_boot_width + 2 * mat_cable_notch_clearance);
mat_cable_notch_overlap = 1.5;
// Reach past the edge of the puck hole
mat_cable_notch_reach   = (puck_nominal_diameter - puck_hole_diameter) / 2
                          + puck_boot_length + cable_dive_run + mat_cable_notch_clearance;
mat_cable_notch_length  = mat_cable_notch_reach + mat_cable_notch_overlap;
mat_cable_notch_radius  = 2.2;

// The boot's top sits puck_boot_top_drop below the puck's face and the mat's
// underside sits recess_depth below it, so the boot only reaches into the lower
// part of the mat. A blind pocket in the underside clears it and leaves the
// visible face unbroken; the cable never shows. The through notch is the
// alternative, and the two differ in assembly: the boot drops through a notch
// (pucks last), while a pocket comes down over the boot (pucks first).
mat_cable_pocket = true;
mat_cable_pocket_clearance = 0.5;
mat_cable_relief_depth = max(0, recess_depth - puck_boot_top_drop + mat_cable_pocket_clearance);
mat_cable_pocket_roof  = mat_thickness - mat_cable_relief_depth;

// TPU locating studs under the mat (mat_dowels), pressed into blind holes in
// the recess floor: one on the rib between the pucks, one near each corner.
mat_dowel_diameter      = 4.0;
mat_dowel_length        = 2.5;
mat_dowel_tip_chamfer   = 0.5;
// Diametral. lib/scad/print.scad suggests 0.4 for TPU into a rigid hole, which
// no stud would enter once the printed parts' own bias was added: the first
// ladder (0.3 to 0.5) was solid at every step. Vented holes and a ladder that
// reached clearance showed every step entering, so this takes the tightest.
mat_dowel_interference  = 0.2;
mat_dowel_hole_diameter = mat_dowel_diameter - mat_dowel_interference;
// A blind hole with a soft plug in it is a piston: the trapped air fights the
// stud on the way in and pushes it back out. Every hole is vented through the
// plate, into the gap over the base, which costs nothing and prints as a
// plain small through-hole.
mat_dowel_vent_diameter = 1.2;
mat_dowel_hole_depth    = mat_dowel_length + 0.5;
mat_dowel_inset         = 10;    // corner studs, from the recess walls
mat_dowel_xy = split_islands ? [
    for (cx = puck_xs,
         dx = [-(island_width / 2 - mat_dowel_inset), island_width / 2 - mat_dowel_inset],
         dy = [-(island_length / 2 - mat_dowel_inset), island_length / 2 - mat_dowel_inset])
        [cx + dx, puck_y + dy]
] : concat([[0, puck_y]],
    [for (sx = [-1, 1], y = [recess_border + mat_dowel_inset, top_length - recess_border - mat_dowel_inset])
        [sx * (recess_width / 2 - mat_dowel_inset), y]]);


// Fit-test coupon.
// Must not equal puck_hole_diameter / 2: at exactly the bore radius the
// coupon's bounding box is tangent to the bore and the two lobes meet along a
// zero-width edge, which is non-manifold (and would print as a knife edge).
// Keep it just inside so the box cuts the bore as a secant.
fit_quadrant = puck_hole_diameter / 2 - 0.5;
fit_corner   = 9;

// Canary coupons for the two fits that exist only in the model: the mat's
// studs pressed into the plate, and the cable's U-turn pocket in the base.
// The stud tile carries one hole per step, marked with that many dots. The
// steps are measured from the STUD's diameter, so 0 is nominally zero
// interference and positive is clearance: the first ladder (0.3 to 0.5 mm of
// interference) was too tight to assemble at every step, which is what a
// printed TPU peg in a printed rigid hole does.
fit_dowel_hole_steps = [-0.2, 0, 0.2, 0.4, 0.6, 0.8];   // added to mat_dowel_diameter
fit_dowel_pitch      = 12;
fit_dowel_tile       = [76, 20];
// Ring canary for the puck lip: a band of the real mat round one whole hole,
// so the puck can actually be pressed in and the grip felt.
fit_lip_band         = 6;

// ---------------------------------------------------------------------------
// Design rules (asserts)
// ---------------------------------------------------------------------------

function floor_under_local(yl, zl) = top_to_world([0, yl, zl])[2];   // world Z = floor thickness above bed

tray_floor   = floor_under_local(bend_slot_front_y, -plate_thickness - bend_tray_depth);
trench_floor = base_floor;
puck_rib     = puck_spacing - puck_bore_diameter;
mat_ligament = split_islands ? (island_width - mat_clearance_total - puck_hole_diameter) / 2
                             : (mat_width - puck_spacing - puck_hole_diameter) / 2;
puck_side_floor = split_islands ? (island_width - puck_bore_diameter) / 2
                               : recess_width / 2 - (puck_spacing / 2 + puck_bore_diameter / 2);
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
mat_front_ligament = split_islands
                     ? (puck_y - puck_hole_diameter / 2 - mat_cable_notch_reach)
                       - (puck_y - island_length / 2 + mat_clearance_total / 2)
                     : (puck_y - puck_hole_diameter / 2 - mat_cable_notch_reach)
                       - (recess_border + mat_clearance_total / 2);
assert(mat_front_ligament >= 2.5,
       str("TPU in front of the cable notch is only ", mat_front_ligament, " mm; the boot or cable_bend_radius is too long"));

// Cable U-turn. Its lower-front quarter is the deepest cut in front of the
// puck, where the wedge is thinnest, so the floor is taken round that arc.
cable_loop_floor = min([for (a = [0 : 2 : 90])
    floor_under_local(cable_boot_end_y - cable_loop_outer * sin(a),
                      cable_loop_centre_z - cable_loop_outer * cos(a))]);
assert(cable_loop_floor >= min_floor,
       str("Base floor under the cable U-turn is only ", cable_loop_floor, " mm; raise front_height or tighten cable_bend_radius"));
assert(puck_boot_length + cable_loop_outer - puck_radial_clearance <= cable_bend_square,
       "Cable U-turn runs out past the bend envelope in front of the puck");

// Mat puck lip
assert(!mat_puck_lip || mat_puck_lip_inset > 0, "mat_puck_lip_inset must be positive");
assert(!mat_puck_lip || mat_puck_lip_inset < 1.0,
       "Pinching the puck by more than 1 mm a side will not let it seat");
assert(!mat_puck_lip || mat_puck_lip_depth <= mat_thickness / 2,
       "The puck lip taper is over half the mat's thickness");
// The ramp must be shallow enough that the rising puck loads bulk material
// rather than peeling the layers at the face apart.
assert(!mat_puck_lip || mat_puck_lip_depth >= 4 * mat_puck_lip_inset,
       str("Puck lip ramp too steep: ", mat_puck_lip_depth, " mm over ", mat_puck_lip_inset,
           " mm pinch is nearly a flange, which peels off its layer"));
assert(!mat_puck_lip || mat_puck_lip_depth >= 4 * print_layer_height,
       "Puck lip taper is under four layers");

// Mat cable relief
assert(!mat_cable_pocket || mat_cable_relief_depth == 0 || mat_cable_pocket_roof >= 1.2,
       str("TPU over the cable pocket is only ", mat_cable_pocket_roof,
           " mm; the boot reaches too near the puck's face for a pocket, set mat_cable_pocket = false"));
assert(!mat_cable_pocket || mat_print_face_down || mat_cable_notch_width <= max_bridge_span,
       "Face up, the cable pocket's roof bridges more than max_bridge_span");

// Mat print orientation and dowels
assert(!(mat_print_face_down && mat_bezel),
       "A face-down mat cannot carry the raised bezel ring: it would stand on the ring alone");
assert(!mat_dowels || mat_print_face_down,
       "Mat dowels only print with the mat face down (face up they hang below the bed)");
assert(plate_floor - mat_dowel_hole_depth >= min_floor, "Plate floor too thin under the mat dowel holes");
// Clearance from a stud hole to the nearest bore, bend slot, locating dowel hole
// or join pocket. The slot distance is Chebyshev, which never overstates it.
function mat_dowel_clear(p) = min(concat(
    [for (cx = puck_xs) norm(p - [cx, puck_y]) - puck_bore_diameter / 2],
    [for (y = dowel_ys) norm(p - [0, y]) - (dowel_diameter + dowel_plate_clearance) / 2],
    [for (x = join_xs, y = join_ys) norm(p - [x, y]) - max(magnet_pocket_diameter, screw_head_diameter) / 2],
    [for (cx = puck_xs) max(abs(p[0] - cx) - bend_slot_width / 2, abs(p[1] - bend_slot_center_y) - bend_slot_length / 2)]
)) - mat_dowel_hole_diameter / 2;
if (mat_dowels)
    for (p = mat_dowel_xy)
        assert(mat_dowel_clear(p) >= 2,
               str("Mat dowel at ", p, " is only ", mat_dowel_clear(p), " mm from a bore, slot, dowel or join pocket"));
assert(mat_bezel_height < mat_surface_recess, "TPU bezel would stand above the PETG border");
assert(plate_thickness == puck_height, "Through-bore design requires plate_thickness == puck_height");

// Mat texture
assert(mat_texture == "none" || mat_texture == "tread" || mat_texture == "hex" || mat_texture == "rugged" || mat_texture == "fluted",
       str("Unknown mat_texture '", mat_texture, "'"));
assert(abs(mat_texture_depth / print_layer_height - round(mat_texture_depth / print_layer_height)) < 1e-6,
       "mat_texture_depth is not a whole number of layers");
assert(mat_thickness - mat_texture_depth >= min_floor,
       str("TPU under a texture groove is only ", mat_thickness - mat_texture_depth, " mm"));
assert(mat_texture_groove >= 1.0, "TPU texture grooves under 1 mm close up when printed");
assert(mat_texture_pitch - mat_texture_groove >= 2 * mat_texture_groove,
       "TPU texture lands narrower than twice the groove");

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

