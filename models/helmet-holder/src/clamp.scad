// ---------------------------------------------------------------------------
// The clamp: a U-bracket plus a front cover.
//
//   u_bracket  — wraps the post's back and two sides. Each arm end holds a
//                captive M6 nut, loaded through a slot in the arm's INNER face
//                so it is invisible once fitted (and the post traps it there).
//                The arm ends are rebated on the outside for the cover's lips.
//   cover      — a shallow tray closing the fourth face. Carries the extension
//                ridge on its TOP face, the two M6 socket-cap heads counterbored
//                flush either side of it, and two lips that slide in the arms'
//                rebates so the outside stays a clean rectangle at any setting.
//
// Two screws, both along Y, both on the same face you reach for anyway when
// changing extensions. Tightening pulls the cover back and clamps the post
// between the cover and the U's back.
//
// Clamping happens in ONE axis. Left-right is a measured fit: the U's inner
// width is fixed at post_w + pads, and the TPU pads absorb the slack.
//
// Frame: y = 0 is the U's back inner face. Post occupies y 0..pd, x ±post_w/2.
// Z up = print Z for the U.
// ---------------------------------------------------------------------------
include <params.scad>
use <../../../lib/scad/holes.scad>
use <../../../lib/scad/shapes.scad>


// ---------- TPU pads --------------------------------------------------------

// The pocket's cross-section, as (depth into the part, height). Both ends taper
// at 45 deg rather than stopping square: the upper end would otherwise be a flat
// 1.5 mm ledge printed over air, 84 mm of it. The taper is symmetric so the pad
// goes in either way up.
//
// The PAD carries the same taper. That is the part it is easy to get wrong —
// chamfer the pocket alone and the pad no longer fits it.
function pad_profile() = [[-0.01, 0], [pad_recess, pad_recess],
                          [pad_recess, pad_hgt - pad_recess], [-0.01, pad_hgt]];

// Extrude a (depth, height) profile along X for `len`.
module pad_prism(len, profile) {
    rotate([90, 0, 90]) linear_extrude(len) polygon(profile);
}

// Print orientation: flat on the bed, studs up. No supports.
// x = length, y = height, z = thickness; the pocket only accepts the part of it
// beyond pad_protrude, so that is where the chamfer starts.
module pad_flat(len = pad_len, studs = pad_studs) {
    intersection() {
        linear_extrude(pad_t + 1) rrect(len, pad_hgt, pad_corner_r);
        translate([-1, 0, 0]) rotate([90, 0, 90]) linear_extrude(len + 2)
            polygon([[0, 0], [pad_hgt, 0],
                     [pad_hgt, pad_protrude],
                     [pad_hgt - pad_recess - pad_fit, pad_t],
                     [pad_recess + pad_fit, pad_t], [0, pad_protrude]]);
    }
    for (o = studs)
        translate([o, pad_hgt / 2, pad_t - 0.01]) cylinder(d = pad_stud_d, h = pad_stud_h);
}
module pad_arm_flat() { pad_flat(pad_arm_len, pad_arm_studs); }

// Pad frame: contact face on y = 0 with the bracket's material at +Y, pad
// spanning x 0..len and z 0..pad_hgt.
module pad_installed(len = pad_len, studs = pad_studs) {
    translate([0, -pad_protrude, pad_hgt]) rotate([-90, 0, 0]) pad_flat(len, studs);
}
module pad_cut(len = pad_len, studs = pad_studs) {
    pad_prism(len, pad_profile());
    for (o = studs)
        hole_y(pad_stud_hole, -0.5, pad_recess + pad_stud_h + 0.5, o, pad_hgt / 2);
}

// Move into each of the four pad frames.
module pad_xform(where) {
    if (where == "back")        // U's back inner face, material behind it
        translate([ pad_len / 2, 0, pad_margin]) rotate([0, 0, 180]) children();
    else if (where == "front")  // cover's inner face, material in front of it
        translate([-pad_len / 2, pd, pad_margin]) children();
    else if (where == "left")
        translate([-hw, pad_arm_y, pad_margin]) rotate([0, 0, 90]) children();
    else
        translate([ hw, pad_arm_y + pad_arm_len, pad_margin]) rotate([0, 0, -90]) children();
}
module pad_place(where) {
    if (where == "left" || where == "right")
        pad_xform(where) pad_installed(pad_arm_len, pad_arm_studs);
    else
        pad_xform(where) pad_installed();
}
// The same pad without its studs. The studs are a deliberate 0.4 mm
// interference fit into their holes, so a fit check including them always
// reports overlap; this is what actually checks the pocket and its chamfers.
module pad_place_slab(where) {
    if (where == "left" || where == "right")
        pad_xform(where) pad_installed(pad_arm_len, []);
    else
        pad_xform(where) pad_installed(pad_len, []);
}
module pad_relieve(where) {
    if (where == "left" || where == "right")
        pad_xform(where) pad_cut(pad_arm_len, pad_arm_studs);
    else
        pad_xform(where) pad_cut();
}

// ---------- U-bracket -------------------------------------------------------

module u_2d() {
    difference() {
        offset(r = corner_r) offset(r = -corner_r)
            polygon([[-x_out, -back_t], [x_out, -back_t], [x_out, arm_len], [hw, arm_len],
                     [hw, 0], [-hw, 0], [-hw, arm_len], [-x_out, arm_len]]);
        c = corner_relief;
        translate([ hw, 0]) polygon([[0, 0], [ c, 0], [0, -c]]);
        translate([-hw, 0]) polygon([[0, 0], [-c, 0], [0, -c]]);
    }
}

// Screw clearance hole plus the inner-face nut slot, in one arm end. s = ±1.
module arm_screw(s) {
    hole_y(bolt_hole, arm_len - screw_depth, arm_len + 1, s * bolt_x, bolt_z);
    // slot runs from the arm's INNER face outward, just past the nut's corners
    x_in  = s * (hw - 1);
    x_far = s * (bolt_x + (nut_af / cos(30)) / 2 + 0.5);
    translate([min(x_in, x_far), nut_y - (nut_h + nut_clear) / 2,
               bolt_z - (nut_af + nut_clear) / 2])
        cube([abs(x_far - x_in), nut_h + nut_clear, nut_af + nut_clear]);
}

// Rebate in the outer face of an arm end, for the cover's lip to run in.
module arm_rebate(s) {
    translate([s > 0 ? x_out - rebate_d : -x_out, arm_len - rebate_len, -1])
        cube([rebate_d, rebate_len + 1, u_h + 2]);
}

module u_bracket() {
    difference() {
        chamfered_extrude(u_h, chamfer) u_2d();
        pad_relieve("back"); pad_relieve("left"); pad_relieve("right");
        arm_screw( 1); arm_screw(-1);
        arm_rebate( 1); arm_rebate(-1);
    }
}

// ---------- cover -----------------------------------------------------------

module cover_2d() {
    offset(r = cover_r) offset(r = -cover_r)
        polygon([[-x_out, pd - lip_len], [-x_out + cover_lip, pd - lip_len],
                 [-x_out + cover_lip, pd], [x_out - cover_lip, pd],
                 [x_out - cover_lip, pd - lip_len], [x_out, pd - lip_len],
                 [x_out, pd + plate_t], [-x_out, pd + plate_t]]);
}

// ---------- the snap's spring, on the cover ---------------------------------
// A leaf cut out of the cover's own face, anchored outboard and reaching in, so
// the bump sits near the free end where the leaf is compliant. Every cut here
// runs the full height of the cover, which is what makes the flexure free to
// print: the cross-section is identical on every layer.
//
// Written for the +x side; the caller mirrors it.
module spring_cut() {
    fy  = pd + plate_t;                 // the cover's front face
    len = spring_x1 - spring_x0;
    // 1. set the leaf's face back, so the extension bears on solid cover
    translate([spring_x0, fy - spring_relief, -1])
        cube([len, spring_relief + 1, u_h + 2]);
    // 2. the slot it flexes into, running past the free end
    translate([spring_x0 - spring_tip, fy - spring_relief - spring_t - spring_gap, -1])
        cube([len + spring_tip, spring_gap, u_h + 2]);
    // 3. cut right through at the inboard end, to free it
    translate([spring_x0 - spring_tip, fy - spring_relief - spring_t - spring_gap, -1])
        cube([spring_tip, spring_t + spring_gap + spring_relief + 1, u_h + 2]);
}

// The catch bump, standing proud of the cover's face on the leaf. Both faces are
// 45 deg: the underside so it prints, the top as the lead-in.
module spring_bump() {
    fy = pd + plate_t;
    d  = spring_relief + snap_proud;    // protrusion measured from the leaf's face
    translate([bump_x0, fy - spring_relief, 0]) rotate([90, 0, 90])
        linear_extrude(bump_x1 - bump_x0)
            polygon([[0, snap_z0],
                     [d, snap_z0 + d],                  // 45 deg catch face
                     [d, snap_z0 + snap_h],
                     [0, snap_z0 + snap_h + snap_ramp]]);
}

module cover_body() {
    chamfered_extrude(u_h, chamfer) cover_2d();
}

// The extension's hard stop, and the whole reason the joint is printable: it
// grows straight up out of the cover's finished top face, so every layer of it
// lands on solid material. Its ends locate the extension sideways; its front
// face takes the moment. The top is chamfered as a lead-in, which also means
// the only sloped surfaces recede going up and are free.
module ridge() {
    y = pd + plate_t - ridge_back;
    hull() {
        translate([-ridge_len / 2, y - ridge_w / 2, u_h])
            cube([ridge_len, ridge_w, ridge_h - ridge_lead]);
        translate([-ridge_len / 2 + ridge_lead, y - ridge_w / 2 + ridge_lead, u_h])
            cube([ridge_len - 2 * ridge_lead, ridge_w - 2 * ridge_lead, ridge_h]);
    }
}

module cover_installed() {
    union() {
    difference() {
        union() {
            cover_body();
            ridge();
        }
        pad_relieve("front");
        // two M6 socket caps, heads counterbored flush from the outer face
        for (s = [-1, 1]) translate([s * bolt_x, 0, bolt_z]) {
            hole_y(bolt_hole, pd - 1, pd + plate_t + 1, 0, 0);
            // Teardrop, not a plain bore: a round horizontal counterbore leaves
            // a sliver at its apex with nothing under it. Use hole_y rather than
            // rolling the rotation by hand — done by hand it came out pointing
            // DOWN, opposite to its own bore.
            hole_y(cbore_d, pd + plate_t - cbore_h, pd + plate_t + 1, 0, 0);
        }
        // optional extension lock: enters from UNDERNEATH and runs up the middle
        // of the ridge, so bore, ridge and nut share one centreline
        translate([0, pd + plate_t - lock_y, 0]) {
            translate([0, 0, -1]) cylinder(d = lock_hole, h = u_h + ridge_h + 2);
            translate([0, 0, -0.01]) cylinder(d = lock_cbore_d, h = lock_cbore_h);
            // The step down to the bore is a 45 deg cone, not a flat annular
            // ledge printed over air. The head lands on the cone and centres
            // itself; at ~20 N of preload that line contact is plenty.
            translate([0, 0, lock_cbore_h - 0.01])
                cylinder(d1 = lock_cbore_d, d2 = lock_hole,
                         h = (lock_cbore_d - lock_hole) / 2);
        }
        // ext_snap gates the spring, and only here. Every extension carries the
        // matching groove unconditionally — it costs nothing, so a snap cover
        // and a plain cover both take any extension.
        if (ext_snap) { spring_cut(); mirror([1, 0, 0]) spring_cut(); }
    }
    if (ext_snap) { spring_bump(); mirror([1, 0, 0]) spring_bump(); }
    }
}

// Prints standing on its bottom edge: the whole cross-section is constant in Z,
// so there is not a single overhang — lips, rebate faces and the whole leaf are
// vertical. Screw bores become horizontal, hence the teardrops.
module cover(orient = "install") {
    if (orient == "print") translate([0, -(pd - lip_len), 0]) cover_installed();
    else cover_installed();
}

// ---------- mock hardware for the assembly ---------------------------------
module bolt_mock(len, d = bolt_d, hd_ = head_d, hh = head_h) {
    color("silver") {
        cylinder(d = hd_, h = hh);
        translate([0, 0, -len]) cylinder(d = d, h = len);
    }
}
module nut_mock(af = nut_af, h = nut_h) { color("silver") hex_z(af, h); }
