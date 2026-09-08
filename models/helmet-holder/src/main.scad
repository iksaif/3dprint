// ---------------------------------------------------------------------------
// Helmet holder — entry point.
//
//   openscad -D 'part="u_bracket"'  -o u_bracket.stl  main.scad
//
// part:    u_bracket | cover | pad | pad_arm |
//          ext_helmet | ext_strap | ext_lock | ext_shelf | assembly | post
// cutaway: false | "x" | "y" | "z"  — remove half the model to inspect insides
// cut_at:  position of the cut plane (global frame — every part shares it)
// ---------------------------------------------------------------------------
include <params.scad>
use <../../../lib/scad/holes.scad>
use <../../../lib/scad/shapes.scad>
use <clamp.scad>
use <extensions.scad>

part       = "assembly";
cutaway    = false;
cut_at     = 0;
show_post  = true;
show_ext   = "ext_helmet";
show_lock  = true;
ext_orient = "print";        // "print" (STL export) | "install" (review renders)

c_part   = "#3f4854";
c_ext    = "#3f4854";
c_accent = "#f59e0b";
c_pad    = "#1f2937";

module post_mock() {
    color("#c8c8c8", 0.45) translate([0, pad_protrude, -80])
        linear_extrude(260) offset(post_corner_r) offset(-post_corner_r)
            translate([0, post_d / 2]) square([post_w, post_d], center = true);
}

// Dimensions the geometry actually implies — echoed so the README can't drift.
// Only for part="dims", or every part export would repeat them.
clamp_need = (pd_max + plate_t - cbore_h) - (nut_y - (nut_h + nut_clear) / 2);
// How far the cover's lips stay inside the arms' rebates across the whole
// adjustment range. If this ever goes near zero the silhouette breaks open.
function engage(d) = arm_len - ((d + eff) - lip_len);

if (part == "dims") {
echo(str("M", bolt_d, " clamp screws: need ", ceil(clamp_need),
         " mm of shank at the deepest post"));
echo(str("back wall: ", back_t, " mm over a ", 2 * hw,
         " mm span; arm wall: ", arm_t, " mm; outer width ", 2 * x_out, " mm"));
echo(str("lock screw: M", lock_d, " x ", lock_len,
         " — head buried ", lock_cbore_h, " mm up the cover, tip at ", lock_tip_z,
         " mm, ", ext_h - lock_tip_z, " mm of flange left above it"));
echo(str("lock nut: M", lock_d, " at z ", lock_nut_z, ", ",
         lock_nut_z - lock_nut_h / 2 - (u_h + flange_relief),
         " mm of flange below it, ",
         ext_h - lock_nut_top, " mm above  (both want > 3)"));
echo(str("cover lip engagement: ", engage(post_d_max), " mm at the largest post, ",
         engage(post_d), " nominal, ", engage(post_d_min), " at the smallest"));
// The leaf spring, as a beam: b = the cover's full height, because it runs all
// the way up. E for printed PETG taken at a conservative 2000 MPa.
E_petg   = 2000;
leaf_L   = spring_x1 - spring_x0;
leaf_a   = spring_x1 - (bump_x0 + bump_x1) / 2;   // bump, back from the anchor
leaf_I   = u_h * pow(spring_t, 3) / 12;
k_bump   = 3 * E_petg * leaf_I / pow(leaf_a, 3);  // N/mm, pushed at the bump
f_snap   = k_bump * snap_proud;
sigma    = f_snap * leaf_a * (spring_t / 2) / leaf_I;
echo(str("snap leaf: ", leaf_L, " x ", spring_t, " mm, bump ", leaf_a,
         " mm from the anchor"));
echo(str("snap force: ", round(f_snap), " N to push it clear (~",
         round(f_snap / 9.81 * 10) / 10, " kg pull to unclip), leaf at ",
         round(sigma), " MPa  (PETG yields ~50)"));
echo(str("leaf free end to the lock bore: ", (spring_x0 - spring_tip) - lock_hole / 2,
         " mm  (want > 1)"));
echo(str("leaf anchor to clamp screw:    ", (bolt_x - cbore_d / 2) - spring_x1,
         " mm  (want > 3)"));

// The ridge is the joint's hard stop. The load's moment is reacted as a couple
// over the extension's height: tension at the top, taken by the ridge, and
// compression at the bottom, taken by the plate bearing on the cover's face.
ridge_force = load_M / u_h;                     // N at the top, from 3 kg at the tip
ridge_M     = ridge_force * ridge_h / 2;
ridge_Z     = ridge_len * pow(ridge_w, 2) / 6;  // section modulus at its root
echo(str("ridge: ", ridge_len, " x ", ridge_w, " x ", ridge_h,
         " mm, takes ", round(ridge_force), " N at ",
         round(ridge_M / ridge_Z * 100) / 100, " MPa  (PETG yields ~50)"));
echo(str("groove walls: ", (flange_back - lock_y) - ridge_w / 2 - ridge_clear,
         " mm behind, ", lock_y - ridge_w / 2 - ridge_clear,
         " mm in front (the front one takes the moment; want > 3)"));
echo(str("flange above the groove for the lock nut: ",
         ext_h - ridge_groove_top, " mm  (want > 8)"));
echo(str("bump exposed beyond the extension edge: ",
         ext_w / 2 - bump_x1, " mm  (want > 3, so it sits under the plate)"));
// Material left between the nut slot and the rebate floor
echo(str("wall between nut slot and cover rebate: ",
         (x_out - rebate_d) - (bolt_x + (nut_af / cos(30)) / 2 + 0.5), " mm"));
}

module assembly() {
    color(c_part) cut() u_bracket();
    color(c_part) cut() cover();
    color(c_pad) for (w = ["back", "left", "right", "front"]) pad_place(w);

    // the two clamp screws, heads flush in the cover, nuts buried in the arms
    for (s = [-1, 1]) {
        // drawn at the length the BOM actually calls for, rounded up to stock,
        // so the render shows it if either end lands somewhere wrong
        translate([s * bolt_x, pd + plate_t - cbore_h, bolt_z]) rotate([-90, 0, 0])
            bolt_mock(ceil(clamp_need / 5) * 5);
        translate([s * bolt_x, nut_y - nut_h / 2, bolt_z]) rotate([-90, 0, 0]) nut_mock();
    }

    // extension, dropped onto the ridge
    translate([0, pd + plate_t, 0]) {
        color(c_ext) cut([0, pd + plate_t, 0]) {
            if (show_ext == "ext_helmet") ext_helmet();
            if (show_ext == "ext_strap")  ext_strap();
            if (show_ext == "ext_lock")   ext_lock();
            if (show_ext == "ext_shelf")  ext_shelf();
        }
    }
    // Lock screw: enters from the cover's underside, head bearing on the shoulder
    // deep inside the bore, up the cover and into the nut buried in the flange.
    // Drawn at its real length so the render shows if either end breaks out.
    if (show_lock) translate([0, pd + plate_t - lock_y, 0]) {
        color("silver") {
            translate([0, 0, lock_cbore_h - lock_head_h])
                cylinder(d = lock_head_d, h = lock_head_h);
            translate([0, 0, lock_cbore_h]) cylinder(d = lock_d, h = lock_len);
        }
        translate([0, 0, lock_nut_z - lock_nut_h / 2]) nut_mock(lock_nut_af, lock_nut_h);
    }
    if (show_post) post_mock();
}

// o = the part's origin in the global frame, so cut_at is always global.
module cut(o = [0, 0, 0]) {
    if (cutaway == false) children();
    else difference() {
        children();
        big = 1000;
        translate(-o) {
            if (cutaway == "x") translate([cut_at, -big / 2, -big / 2]) cube(big);
            if (cutaway == "y") translate([-big / 2, cut_at, -big / 2]) cube(big);
            if (cutaway == "z") translate([-big / 2, -big / 2, cut_at]) cube(big);
        }
    }
}

{
    if (part == "assembly")   assembly();
    if (part == "post")       post_mock();
    if (part == "u_bracket")  cut() u_bracket();
    if (part == "cover")      cut() cover(ext_orient == "install" ? "install" : "print");
    if (part == "pad")        pad_flat();
    if (part == "pad_arm")    pad_arm_flat();
    if (part == "ext_helmet") cut() ext_helmet(ext_orient);
    if (part == "ext_strap")  cut() ext_strap(ext_orient);
    if (part == "ext_lock")   cut() ext_lock(ext_orient);
    if (part == "ext_shelf")  cut() ext_shelf(ext_orient);
    if (part == "ext_stub")   cut() ext_stub(ext_orient);
}
