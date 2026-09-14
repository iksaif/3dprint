// ---------------------------------------------------------------------------
// The two parts: the PETG clip (collar + hook) and the TPU liner.
//
// Both are modelled directly in their print orientation — z is the post's axis
// AND the print axis, and both parts sit on z = 0 as written. Nothing is
// rotated on the way to the STL, so what you see in the assembly view is what
// the slicer gets.
// ---------------------------------------------------------------------------
include <params.scad>
use <../../../lib/scad/holes.scad>
use <../../../lib/scad/shapes.scad>

// ---------- the collar's outline -------------------------------------------
// One closed polygon describes the whole C: back wall, both arms, both snap
// lips and both thumb tabs. It is traced anticlockwise from the back-left
// outer corner, out along one arm to its lip and back down the arm's inner
// face, across the back wall's inner face, and out the other side.
//
// Every feature of the fit lives in this outline, and because print Z is the
// post's axis the outline is the whole story: extrude it and each feature is a
// prism, support-free whatever shape it is. The lip's undercut — the thing that
// would normally make a snap-fit need supports — runs sideways here, not up.
function collar_pts() = [
    [-x_out,            y_back_out],
    [ x_out,            y_back_out],
    [ x_out,            y_arm_end - tab_len],   // up the outer face
    [ x_out + tab_out,  y_arm_end],             // thumb tab flare
    [ hw_in,            y_arm_end],             // the arm's end face
    [ hw_in - lip_reach, y_lip_end],            // down the lead-in ramp
    [ hw_in - lip_reach, y_crest0],             // the crest
    [ hw_in,            y_cam_start],           // the 45 deg cam onto the corner
    [ hw_in,            y_back_in],             // the arm's inner face
    [-hw_in,            y_back_in],             // across the back wall
    [-hw_in,            y_cam_start],
    [-hw_in + lip_reach, y_crest0],
    [-hw_in + lip_reach, y_lip_end],
    [-hw_in,            y_arm_end],
    [-x_out - tab_out,  y_arm_end],
    [-x_out,            y_arm_end - tab_len],
];

module collar_2d() { smooth2d(fillet_r, corner_r) polygon(collar_pts()); }

// Blind pockets for the liner's studs, cut into the back wall's inner face.
// Horizontal bores in this orientation, so teardrops — hole_y puts the point at
// +Z for us rather than leaving the rotation to be got wrong by hand.
module stud_holes() {
    for (o = liner_studs)
        hole_y(liner_stud_hole,
               y_back_in - liner_stud_h - 0.5, y_back_in + 0.5,
               o, collar_h / 2);
}

// A slot through each lip for a nylon cable tie. Not a teardrop and not a plain
// rectangle: the profile is a rectangle with a 45 deg peak on top, so the
// ceiling is strictly self-supporting rather than a short bridge that happens
// to be under the limit. One extra point in the polygon, and support.py never
// has to be argued with.
//
// The cut runs from inboard of the lip's crest right out past the thumb tab, so
// it opens on both faces however the flare is sized.
module tie_slots() {
    for (m = [0, 1]) mirror([m, 0, 0])
        translate([hw_in - lip_reach - 1, 0, 0]) rotate([90, 0, 90])
            linear_extrude(x_out + tab_out - hw_in + lip_reach + 2)
                polygon([[tie_y - tie_t / 2, tie_z - tie_w / 2],
                         [tie_y + tie_t / 2, tie_z - tie_w / 2],
                         [tie_y + tie_t / 2, tie_z + tie_w / 2],
                         [tie_y,             tie_z + tie_w / 2 + tie_t / 2],
                         [tie_y - tie_t / 2, tie_z + tie_w / 2]]);
}

module collar() {
    difference() {
        chamfered_extrude(collar_h, chamfer) collar_2d();
        stud_holes();
        if (tie_slot) tie_slots();
    }
}

// ---------- the hook --------------------------------------------------------
// A side profile in (y, z), extruded across x: a stroke through the stations in
// params.scad, clipped against the rake line.
//
// This is the one part of the model that is NOT a prism along print Z, so it is
// the one part where the 45 deg rule does real work. Two surfaces are
// load-bearing for printability and both are asserted in params.scad: the
// stem's underside at hook_rake, and the upturn leaning tip_lean back over the
// cradle. Everything else either descends going up (free) or is vertical.
//
// Everything at or above the rake line, and behind the root. Two jobs in one
// quad: it trims the root station's circle where it would otherwise bulge below
// the wall with a near-horizontal underside, and it squares off the back of the
// profile so the hook meets the wall on a flat face instead of a tangent.
//
// The clip line IS stem_bot_at, i.e. exactly hook_rake, so the surface it
// leaves behind is printable by definition rather than by luck.
function hook_clip(s) =
    let (y1 = hk_tip_y(s) - 5, zt = hk_tip_top(s) + 5) [
        [hk_root_y, stem_bot_at(hk_root_y)],
        [y1,        stem_bot_at(y1)],
        [y1,        zt],
        [hk_root_y, zt],
    ];

module hook_bare_2d(s) {
    intersection() {
        stroke(hk_stations(s));
        polygon(hook_clip(s));
    }
}

// The wall, as it appears in the hook's own (y, z) profile plane. Kept strictly
// INSIDE the collar — y no further than the wall's own faces, z clear of the
// top and bottom chamfers — because it is never cut away again; see hook_2d.
module wall_2d() {
    translate([y_back_out, chamfer])
        square([back_t, collar_h - 2 * chamfer]);
}

// The profile with its junction to the wall filleted. The closing — dilate then
// erode — rounds concave corners and leaves convex ones untouched, so the two
// corners where the stem runs into the wall get a radius and the hook's own
// outline is unchanged.
//
// The wall is unioned in for the closing and then simply LEFT THERE. Three
// versions of taking it back out again were tried and every one was worse:
//
//   cut at y_back_out — removes the hook_embed overlap along with the wall, so
//     hook and collar meet on a coincident plane. Watertight, one shell,
//     nothing complains, and support.py loses the seed tying the hook's first
//     layers to the wall: 18.6 mm of unsupported run at z 5.5.
//   cut at hk_root_y — spares the embed, and spares a full-height slab of the
//     temporary wall with it, which dragged the part down to the wall's z = -1
//     and floated the entire collar.
//   cut at y_back_out, then union the bare profile back to restore the embed —
//     correct, and it differences against exactly the face the closing has just
//     rebuilt. Coplanar difference, and the junction shredded into ~290 sliver
//     triangles running the full height of the wall.
//
// Leaving it costs nothing. Every millimetre of it lies inside the back wall
// the hook is being unioned to, which is why wall_2d is clipped to the wall's
// own faces and held clear of the chamfers: bounded like that, the leftover is
// a subset of material the collar already has, and there is no second surface
// anywhere for a boolean to fight with.
module hook_2d(s) {
    offset(r = -hook_wall_fillet) offset(r = hook_wall_fillet)
        union() { hook_bare_2d(s); wall_2d(); }
}

// The plan-view fillet where each side face meets the wall: a true radius
// tangent to both, swept up through the hook's own profile rather than
// extruded off the bed, so it follows the stem's rake and adds nothing that
// hangs in air. Built as an intersection of two prisms along different axes —
// the hook's profile taken as infinitely wide, cut by the fillet's plan shape
// taken as infinitely tall.
module hook_side_fillets(s) {
    r = hook_side_fillet;
    x0 = hk_w(s) / 2 - hook_chamfer;   // start inside the chamfer, not on it
    intersection() {
        translate([-200, 0, 0]) rotate([90, 0, 90]) linear_extrude(400) hook_2d(s);
        for (m = [0, 1]) mirror([m, 0, 0])
            translate([0, 0, -1]) linear_extrude(hk_tip_top(s) + 2)
                difference() {
                    translate([x0, y_back_out - r]) square([r, r + back_t]);
                    translate([x0 + r, y_back_out - r]) circle(r);
                }
    }
}

module hook(s) {
    // rotate([90, 0, 90]) sends local (px, py, pz) to global (pz, px, py): the
    // extrusion runs along X and the profile is read straight off as (y, z).
    // Same idiom as the lib's pad_prism.
    translate([-hk_w(s) / 2, 0, 0]) rotate([90, 0, 90])
        chamfered_extrude(hk_w(s), hook_chamfer) hook_2d(s);
    hook_side_fillets(s);
}

module clip(size = "m") { union() { collar(); hook(size_idx(size)); } }

// ---------- the TPU liner ---------------------------------------------------
// A U in three straight legs, each one the same prism: a (depth, z) profile
// swept along the leg. Straight legs mean the sawtooth can be drawn in 2D and
// extruded, which is the only reason the teeth are cheap enough to have.
//
// The teeth ramp inward going UP over tooth_rise and then step back square.
// Both halves print: the ramp is material arriving gradually (a 68 deg wall at
// these numbers) and the step is material stopping, which costs nothing. The
// square face is the UPPER one, which is the face the post drives into when the
// clip tries to slide down — the direction that matters.
//
// The crests are also the only compliance in the post_d direction. The lip face
// and the back wall are two rigid surfaces a fixed distance apart, so a post at
// post_d_max is absorbed by crushing crests and nothing else.
// n_teeth, liner_h, base_d, liner_z and liner_side are all in params.scad — see
// the note there about `use` not importing variables.
//
// Inner face of the profile: up the sawtooth, tooth by tooth.
function tooth_pts() = [
    for (k = [0 : n_teeth - 1], p = [0 : 2])
        p == 0 ? [base_d,  k * tooth_pitch]
      : p == 1 ? [liner_t, k * tooth_pitch + tooth_rise]
      :          [base_d,  k * tooth_pitch + tooth_rise]
];
function liner_profile() = concat([[0, 0]], tooth_pts(), [[base_d, liner_h], [0, liner_h]]);

// One leg: extruded along +X for `len`, depth running +Y from 0 to liner_t,
// z from 0 to liner_h.
module liner_leg(len) {
    rotate([90, 0, 90]) linear_extrude(len, convexity = 8) polygon(liner_profile());
}

// studs = false gives the same liner without them. The studs are a deliberate
// 0.4 mm interference into their holes, so any fit check that includes them
// reports overlap and tells you nothing about the surfaces that actually mate.
// The collar's two inner corners are FILLETED — smooth2d(fillet_r, ...) rounds
// every concave corner, which is right for the part and means the collar bulges
// into the cavity there by fillet_r * (sqrt(2) - 1). A liner drawn as three
// square legs fills that quadrant and overlaps it, by exactly
// (1 - pi/4) * fillet_r^2 per corner per mm of height: 12 mm^3 here, which is
// what fitcheck.py reported and no render would ever have shown.
//
// A quarter-disc of radius fillet_r cut at the corner itself covers the whole
// fillet, since the fillet's deepest reach from the corner is only 0.41 * r.
module liner(studs = true) {
    difference() {
        liner_legs();
        for (m = [0, 1]) mirror([m, 0, 0])
            translate([hw_in, y_back_in, -1])
                cylinder(r = fillet_r + slide_clearance, h = collar_h + 2);
    }
    if (studs)
        for (o = liner_studs)
            translate([o, y_back_in, collar_h / 2]) rotate([90, 0, 0])
                cylinder(d = liner_stud_d, h = liner_stud_h);
}

module liner_legs() {
    translate([0, 0, liner_z]) {
        translate([-hw_in, y_back_in, 0]) liner_leg(2 * hw_in);        // back
        // Each side leg is the same prism turned a quarter turn. The turn has
        // to be +90 and not -90, and that is not a detail: liner_leg runs its
        // DEPTH along local +Y, and rotate([0,0,-90]) sends local +Y to global
        // +X — outboard, into the arm's material. The teeth then face into the
        // PETG instead of onto the post, which is a liner that grips nothing
        // and a fit check full of overlap. rotate([0,0,90]) sends local +Y to
        // global -X, which is inboard off the arm's face, where the post is.
        translate([hw_in, y_back_in, 0]) rotate([0, 0, 90]) liner_leg(liner_side);
        mirror([1, 0, 0])
            translate([hw_in, y_back_in, 0]) rotate([0, 0, 90]) liner_leg(liner_side);
    }
}

// ---------- the post --------------------------------------------------------
// Solid, because springcheck.py intersects things with it; post_mock is the
// same thing dressed for a render.
module post_solid(h = 160) {
    translate([0, 0, -h / 2 + collar_h / 2]) linear_extrude(h)
        offset(post_corner_r) offset(-post_corner_r)
            square([post_w, post_d], center = true);
}
module post_mock() { color("#c8c8c8", 0.4) post_solid(); }

// ---------- the assembly, as it actually sits -------------------------------
// Parts are modelled UNSPRUNG, because that is what gets printed. Drawn that
// way against a nominal post, the post reads as buried 2.5 mm into the liner on
// each side, which looks like a mistake and is not one: it is the preload, and
// on a real post the arms flex out by exactly that much and carry the liner
// with them. Nothing is crushed — the teeth are only 0.8 mm proud.
//
// A review render that shows 2.5 mm of interference is still a bad review
// render, so this shears each arm to where it actually sits. The shear is
// linear in y from the back wall's inner face, reaching preload at arm_free,
// which is the tip deflection of a cantilever to first order — near enough for
// a picture, and far nearer than not bending it at all.
//
// The hook is left out and drawn unsheared: it hangs off the back wall, where
// the shear is under 0.3 mm, and running it through the mirror would saw it in
// half down the middle.
module seated() {
    k = preload / arm_free;
    for (m = [0, 1]) mirror([m, 0, 0]) intersection() {
        translate([0, -300, -80]) cube([300, 600, 400]);
        multmatrix([[1, k, 0, -k * y_back_in],
                    [0, 1, 0, 0],
                    [0, 0, 1, 0]]) children();
    }
}

// The lip as it sits when the clip is SEATED — i.e. carried outward by the
// preload the post has already sprung into the arms. Intersected with the post
// this is the material that actually holds the clip on, and it is the number
// the whole snap depends on. Modelled here rather than in the fit check so the
// assembly view can show it too.
// dy is how far the clip has been pulled OFF the post, and it translates by
// MINUS that in y. The sign is the whole point and it is easy to get backwards:
// the collar's mouth faces +y, so the clip travels +y going ON and -y coming
// OFF. Pulling it off therefore carries the lips BACK onto the post's front
// corners, which is what the cam faces block. Translating +y instead walks the
// lips away from the post and reports a serene zero for any lip whatsoever.
//
// At dy = 0 this is the resting fit and the cam is tangent, so it should just
// touch. Wind dy up and it drives into the corner. A tangent contact has no
// volume, so "does it overlap when seated" answers nothing — move it until it
// fouls, exactly as hookcheck.py does next door.
module seated_lips(dy = 0) {
    x0 = hw_in - lip_reach;
    x1 = x_out + tab_out + 1;
    for (m = [0, 1]) mirror([m, 0, 0]) translate([preload, -dy, 0]) intersection() {
        collar();
        translate([x0, y_cam_start, -1])
            cube([x1 - x0, y_lip_end - y_cam_start, collar_h + 2]);
    }
}
