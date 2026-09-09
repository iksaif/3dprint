// ---------------------------------------------------------------------------
// Extensions. Every extension is:
//   * a 2D side profile (Y outward from the post, Z up), filleted, extruded
//     `w` wide with chamfered edges,
//   * minus a groove in the flange's underside for the cover's ridge,
//   * minus, optionally, the lock bore and nut pocket,
//   * plus two small hook tabs on the back face.
// Because each one is essentially a pure extrusion, it prints on its SIDE with
// zero supports and the cantilever bending stress runs along the layers.
//
// Every SUBTRACTION here is a pocket — no undercuts. That is deliberate. An
// undercut in the cover's face would run along X, which is this part's print Z,
// and one of its lips would begin as a knife edge in mid-air. Removed material
// never has that problem: only its closing side matters, and a pocket closes as
// a short bridge. See INTERFACE.md.
//
// The hook tabs are the one ADDITION, and they have to earn it: see hook_tabs()
// for why they are wedges rather than plain blocks.
//
// How it mounts: hang it on the ridge, then rotate the bottom in. The groove in
// the flange's underside drops over the cover's ridge, and swinging the bottom
// home puts two tabs into two pockets in the cover's face. The ridge is the hard
// stop against the load's moment and locates it sideways; the tabs stop it
// lifting back off. Nothing flexes.
//
// Local coordinates (installed): plate back face at y=0 against the cover's
// outer face, x centred, z=0 at the bracket bottom, z=u_h its top.
// ---------------------------------------------------------------------------
include <params.scad>
use <../../../lib/scad/holes.scad>
use <../../../lib/scad/shapes.scad>

// Everything cut out of an extension.
module ext_slot(w = ext_w) {
    ridge_groove(w);
    if (ext_lock_hole) lock_pocket(w);
    if (ext_lock_hole && ext_hook) foot_lock_clearance();
}

// The lock screw enters from underneath the cover, and the foot now sits in its
// way — the bore's centreline lands exactly on the foot's rear edge, since
// foot_reach and lock_y are both 6. So the foot gets a clearance hole, sized to
// pass the screw's HEAD (it goes in head-first from below), not just its shank.
//
// It is a teardrop, and the direction is the non-obvious part. The hole's axis
// is model Z, but this part prints on its side where model Z is HORIZONTAL and
// model X is the print's Z. So this is a horizontal bore in the print, its apex
// points along model +X, and the teardrop is drawn in the (x, y) plane rather
// than the usual (x, z). A plain round hole here would sag where it closes.
module foot_lock_clearance() {
    translate([0, -lock_y, foot_z0 - 1])
        rotate([0, 0, -90])                 // teardrop apex to +X = print +Z
            linear_extrude(foot_t + 2)
                teardrop2d(lock_cbore_d + 1);
}

// The groove the cover's ridge drops into: a plain pocket in the flange's
// underside, closed at both ends in X so it locates the extension sideways.
module ridge_groove(w = ext_w) {
    len = ridge_len + 2 * ridge_clear;
    translate([-len / 2, -lock_y - ridge_w / 2 - ridge_clear, u_h - 1])
        cube([len, ridge_w + 2 * ridge_clear,
              (ridge_groove_top - (u_h - 1))]);
}

// The lock screw comes UP from the cover and threads into a nut buried here.
// Centred on the extension's width, and lock_y back from the cover's outer face
// so it shares the ridge's centreline — the same datum the cover's bore uses,
// so the two are collinear by construction.
module lock_pocket(w = ext_w) {
    translate([0, -lock_y, ridge_groove_top - 1])
        cylinder(d = lock_hole, h = (lock_tip_z + 1) - (ridge_groove_top - 1));
    // Nut slot, opening on the +X side face — which points straight up while the
    // extension prints on its side, so it needs no support.
    translate([0, -lock_y, lock_nut_z]) hull() {
        hex_z_c(lock_nut_af + nut_clear, lock_nut_h + nut_clear);
        translate([w / 2 + 1, 0, 0]) hex_z_c(lock_nut_af + nut_clear, lock_nut_h + nut_clear);
    }
}

module ext_body(w = ext_w) {
    translate([-w / 2, 0, 0]) rotate([90, 0, 90]) chamfered_extrude(w, chamfer) children();
}

// Plate + the roof, which reaches back over the cover as a flange.
//
// The flange's underside is stepped: flange_relief over the front part, which is
// what actually lands on the cover's top and carries the weight, and
// flange_relief_rear behind the ridge groove. The step is there so the extension
// can tilt by hook_swing to get its tabs in without the flange's back edge
// grounding on the cover first — at ~3.4 deg that edge dips about 0.35 mm, more
// than flange_relief allows.
module ext_plate_2d() {
    step = -(ridge_back + ridge_w / 2 + ridge_clear);   // behind the groove
    square([ext_plate_t, ext_h]);
    // front of the flange: the bearing face
    translate([step, u_h + flange_relief])
        square([-step, ext_roof - flange_relief]);
    // behind the groove: relieved, so the swing is free
    translate([-flange_back, u_h + flange_relief_rear])
        square([flange_back + step, ext_roof - flange_relief_rear]);
}

// The material an extension may occupy: nothing crosses the back face below the
// cover's top, and nothing reaches further back than the flange.
module ext_keep_2d() {
    polygon([[0, -50], [500, -50], [500, 500], [-flange_back, 500],
             [-flange_back, u_h + flange_relief_rear], [0, u_h + flange_relief_rear]]);
}

module extension(orient = "install", w = ext_w, holes = []) {
    if (orient == "print")
        translate([0, 0, w / 2]) rotate([0, -90, 0])
            extension_installed(w, holes) children();
    else
        extension_installed(w, holes) children();
}
// Lightening holes, bored through the extension's WIDTH.
//
// This is the one direction that costs nothing here. The part prints on its
// side, so X is the print's Z: a hole along X comes out as a plain vertical
// hole, needing no support at any diameter and leaving no bridge. Holes through
// the profile plane, or pockets in the side faces, would both have to answer to
// the print; these do not.
//
// Takes the same [y, z, r] stations the profile's stroke() is drawn from, and
// puts a hole at each one sized to leave lighten_wall of material all round.
// Stations too thin to bore usefully are skipped.
// Every station except the first and last. The root carries the whole bending
// moment and the tip is where the profile has run thin, so neither gets bored.
function inner_pts(pts) = len(pts) < 3 ? []
                        : [for (i = [1 : len(pts) - 2]) pts[i]];

module lighten_holes(pts, w = ext_w) {
    for (p = pts) {
        d = 2 * (p[2] - lighten_wall);
        if (d >= lighten_min_d)
            translate([0, p[0], p[1]]) rotate([0, 90, 0])
                cylinder(d = d, h = w + 2, center = true);
    }
}

module extension_installed(w = ext_w, holes = []) {
    difference() {
        union() {
            ext_body(w) union() {
                // the profile the caller wrote, held inside the keep-out
                intersection() {
                    smooth2d(6, 2) union() { ext_plate_2d(); children(); }
                    ext_keep_2d();
                }
                // the foot, outside the keep-out because it is meant to
                // cross the back face — and outside the 6 mm smoothing,
                // which is far too big a fillet for it
                if (ext_hook) ext_foot_2d();
            }
            // The prisms are the only thing here that is NOT part of the
            // profile: they are interface, they sit proud of the foot's face,
            // and they are what has to earn its keep against the print.
            if (ext_hook) foot_prisms(w);
        }
        ext_slot(w);
        if (lighten) lighten_holes(holes, w);
    }
}

// The extension's half of the retention: two small tabs on the back face that
// swing into the cover's pockets as the extension is rotated down onto the
// ridge. ADDED material, not removed — so unlike everything else on this part it
// has to answer to the print orientation rather than being free by construction.
//
// This part prints on its side, X -> print Z. A tab that simply started partway
// along X would begin as a face hanging in mid-air, which is precisely what made
// a sprung finger impossible here. So each tab is a wedge in PLAN: its
// protrusion is zero at both ends in X and ramps to hook_deep over hook_lead.
// Protrusion against print-Z is the slope the printer sees, so with hook_lead
// equal to hook_deep it is exactly 45 deg and self-supporting. (Ramping it in Z
// instead would look similar on screen and do nothing — model Z is horizontal
// once this part is on its side.)
//
// In Z the tab is a plain prism: its top and bottom faces are model-horizontal,
// which in the print are vertical walls and cost nothing. The top face is the
// one that bears on the pocket's roof when something lifts the extension, and it
// is what keeps the ridge from escaping its groove, so it stays flat and square.
//
// Always present, whether or not the cover you pair it with has the pockets.
// (kept for reference)
// so the union actually merges. Drawn as one polygon, so the ramp below y = 0 —
// the only part the printer sees as an overhang — stays exactly 45 deg however
// deep the root goes.
// The two prisms, standing on the foot's upper face and dropping into recesses
// in the cover's underside once the foot has swung under it. This is what stops
// the extension swinging back out.
//
// Shape is set by the print. X is this part's print Z, so a wedge that simply
// appeared partway along X would be an island in mid-air; each one therefore
// ramps up over prism_lead at both ends, and prism_lead = prism_h makes that
// exactly 45 deg. In Y it is a plain prism, which in the print is a vertical
// wall and costs nothing.
//
// The root reaches prism_bond down into the foot rather than sitting on its
// face — added material butted on a coincident plane unions into a separate
// shell, i.e. a prism attached by nothing.
module foot_prisms(w = ext_w) {
    W = prism_w / 2 + prism_lead;       // footprint half-width, ramps included
    for (s = [-1, 1])
        translate([s * prism_x, -(prism_y - prism_d / 2), -foot_gap])
            rotate([90, 0, 0])          // profile in (x, z), extruded back in -y
                linear_extrude(prism_d)
                    polygon([[-W,            -prism_bond],
                             [ W,            -prism_bond],
                             [ W,             0],
                             [ prism_w / 2,   prism_h],
                             [-prism_w / 2,   prism_h],
                             [-W,             0]]);
}


// The foot, as a 2D profile in (y, z) — the extension's own shape, not a block
// bolted to its back. Because it goes through the same full-width extrusion and
// the same edge chamfer as the rest of the part, it reads as one piece and it
// is support-free by construction: a prism along the part's print Z.
//
// The plate stub is there to give the fillet something to die into, and it
// overlaps up past z = 0 so the foot and the plate are one solid rather than two
// touching on a coincident edge.
// The foot may cross the back face, but ONLY below the cover's underside. Above
// that line it has to stay in front of y = 0 like everything else.
//
// This is not theoretical: without it the fillet blends the foot into the plate
// by filling the concave corner between them, and that corner is precisely
// where the cover's bottom front edge sits. It measured as 26 mm³ of solid
// interference over the full width — the part would not have gone on.
module foot_keep_2d() {
    polygon([[0, 900], [900, 900], [900, -900], [-foot_reach, -900],
             [-foot_reach, -foot_gap], [0, -foot_gap]]);
}

module ext_foot_2d() {
    intersection() {
        smooth2d(foot_fillet, 1.2)
            union() {
                translate([-foot_reach, foot_z0])
                    square([foot_reach + ext_plate_t, foot_t]);
                translate([0, foot_z0])
                    square([ext_plate_t, foot_t + foot_fillet + 5]);
            }
        foot_keep_2d();
    }
}


// Every profile below is drawn in the plate's own frame: y outward from the
// cover's face, z up from the bracket's bottom, so the plate spans z 0..ext_h.
// They are anchored to that plate, NOT scaled to the post — a helmet is the
// same size whichever post you hang it on. Shrinking the clamp therefore did
// not shrink these by the same factor; it only re-seated their roots and
// trimmed the reach back to what the shorter clamp can sensibly cantilever.

// ---- 1. Helmet cradle ------------------------------------------------------
// A broad shelf that hooks upward at the far end. The helmet's inner shell
// rests along the sweep and the raised toe stops it sliding off; 56 mm of width
// spreads the load across the EPS foam rather than denting a line into it.
// Deep at the root, where the bending moment is highest, tapering to the tip.
// The toe curls back toward the post rather than simply ending, which both
// captures the helmet properly and keeps the silhouette from reading as a
// tapered shaft with a bulb on the end.
// One list, used twice: stroke() draws the sweep from it, and lighten_holes()
// bores the arm out from the same stations. They cannot drift apart.
function helmet_pts() = [[9, 22, 13], [38, 26, 11], [66, 30, 9.5],
                         [86, 37, 8.5], [93, 48, 8], [88, 58, 7]];
module helmet_profile() {
    stroke(helmet_pts());
    polygon([[4, 4], [4, 30], [42, 22]]);        // gusset carrying the root in
}
module ext_helmet(orient = "install") {
    extension(orient, ext_w, inner_pts(helmet_pts())) helmet_profile();
}

// ---- 2. Strap hook ---------------------------------------------------------
function strap_pts() = [[8, 22, 7], [26, 28, 6], [38, 42, 5.5],
                        [40, 55, 5.5], [34, 64, 6]];
module strap_profile() { stroke(strap_pts()); }
// Nothing here is thick enough to bore — every station comes out under
// lighten_min_d and lighten_holes skips it. That is the guard doing its job,
// not an omission.
module ext_strap(orient = "install") {
    extension(orient, ext_w, inner_pts(strap_pts())) strap_profile();
}

// ---- 3. Lock / light hook --------------------------------------------------
// The U hangs BELOW the bracket's bottom edge, which is why its z runs negative.
function lock_pts() = [[8, 24, 8], [42, 22, 7], [48, 4, 7],
                       [62, -2, 7], [72, 10, 8]];
module lock_profile() { stroke(lock_pts()); }
module ext_lock(orient = "install") {
    extension(orient, ext_w, inner_pts(lock_pts())) lock_profile();
}

// ---- 4. Shelf --------------------------------------------------------------
// Flat tray for lights, a computer, keys, gloves. Lip at the front edge.
function shelf_pts() = [[9, 38, 9], [46, 40, 7.5], [76, 40, 7.5]];
module shelf_profile() {
    stroke(shelf_pts());
    stroke([[76, 40, 7.5], [79, 51, 6.5]]);      // the front lip
    polygon([[9, 8], [9, 40], [46, 34]]);        // gusset under the root
}
module ext_shelf(orient = "install") {
    extension(orient, ext_w, inner_pts(shelf_pts())) shelf_profile();
}

// ---- Test coupon -----------------------------------------------------------
// An extension with no arm at all: extension() with no profile leaves just the
// plate and flange, which is every part of the interface and none of the mass.
// Pair it with the real cover to check the ridge fit, the hook engagement and
// the lock screw for about a third of the plastic of a real extension.
module ext_stub(orient = "install") { extension(orient); }
