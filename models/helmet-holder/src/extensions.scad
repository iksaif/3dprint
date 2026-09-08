// ---------------------------------------------------------------------------
// Extensions. Every extension is:
//   * a 2D side profile (Y outward from the post, Z up), filleted, extruded
//     `w` wide with chamfered edges,
//   * minus a groove in the flange's underside for the cover's ridge,
//   * minus the snap groove and, optionally, the lock bore and nut pocket.
// Because each one is a pure extrusion, it prints on its SIDE with zero
// supports and the cantilever bending stress runs along the layers.
//
// Every subtraction here is a POCKET — no undercuts. That is deliberate. An
// undercut in the cover's face would run along X, which is this part's print Z,
// and one of its lips would begin as a knife edge in mid-air. Removed material
// never has that problem: only its closing side matters, and a pocket closes as
// a short bridge. See INTERFACE.md.
//
// How it mounts: drop it on from above. The flange lands on the cover's top,
// the cover's ridge enters the groove in its underside, and the snap clicks.
// The ridge is the hard stop against the load's moment; the groove's closed
// ends locate it sideways.
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
module ext_plate_2d() {
    square([ext_plate_t, ext_h]);
    translate([-flange_back, u_h + flange_relief]) square([flange_back, ext_roof - flange_relief]);
}

// The material an extension may occupy: nothing crosses the back face below the
// cover's top, and nothing reaches further back than the flange.
module ext_keep_2d() {
    polygon([[0, -50], [500, -50], [500, 500], [-flange_back, 500],
             [-flange_back, u_h + flange_relief], [0, u_h + flange_relief]]);
}

module extension(orient = "install", w = ext_w) {
    if (orient == "print")
        translate([0, 0, w / 2]) rotate([0, -90, 0]) extension_installed(w) children();
    else
        extension_installed(w) children();
}
module extension_installed(w = ext_w) {
    difference() {
        ext_body(w) intersection() {
            smooth2d(6, 2) union() { ext_plate_2d(); children(); }
            ext_keep_2d();
        }
        ext_slot(w);
        snap_catch(w);
    }
}

// The extension's whole half of the snap: one groove across the back face for
// the cover's sprung bump to drop into. It is removed material and it spans the
// full width, so it is present on every print layer and can never be an
// unsupported island — which is the entire reason the spring lives on the cover.
// Always cut, whether or not the cover you pair it with has the spring.
module snap_catch(w = ext_w) {
    translate([-w / 2 - 1, -1, snap_groove_z0])
        cube([w + 2, snap_groove_d + 1, snap_groove_z1 - snap_groove_z0]);
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
module helmet_profile() {
    stroke([[9, 22, 13], [38, 26, 11], [66, 30, 9.5], [86, 37, 8.5],
            [93, 48, 8], [88, 58, 7]]);
    polygon([[4, 4], [4, 30], [42, 22]]);        // gusset carrying the root in
}
module ext_helmet(orient = "install") { extension(orient) helmet_profile(); }

// ---- 2. Strap hook ---------------------------------------------------------
module strap_profile() {
    stroke([[8, 22, 7], [26, 28, 6], [38, 42, 5.5], [40, 55, 5.5], [34, 64, 6]]);
}
module ext_strap(orient = "install") { extension(orient) strap_profile(); }

// ---- 3. Lock / light hook --------------------------------------------------
// The U hangs BELOW the bracket's bottom edge, which is why its z runs negative.
module lock_profile() {
    stroke([[8, 24, 8], [42, 22, 7], [48, 4, 7], [62, -2, 7], [72, 10, 8]]);
}
module ext_lock(orient = "install") { extension(orient) lock_profile(); }

// ---- 4. Shelf --------------------------------------------------------------
// Flat tray for lights, a computer, keys, gloves. Lip at the front edge.
module shelf_profile() {
    stroke([[9, 38, 9], [46, 40, 7.5], [76, 40, 7.5]]);
    stroke([[76, 40, 7.5], [79, 51, 6.5]]);
    polygon([[9, 8], [9, 40], [46, 34]]);        // gusset under the root
}
module ext_shelf(orient = "install") { extension(orient) shelf_profile(); }

// ---- Test coupon -----------------------------------------------------------
// An extension with no arm at all: extension() with no profile leaves just the
// plate and flange, which is every part of the interface and none of the mass.
// Pair it with the real cover to check the ridge fit, the snap force and the
// lock screw for about a third of the plastic of a real extension.
module ext_stub(orient = "install") { extension(orient); }
