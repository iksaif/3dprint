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
show_ext   = "ext_light";
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
// The retention, as a budget of vertical travel. The whole design lives or dies
// on this ordering: the latch must free BEFORE the foot grounds, and the foot
// must ground BEFORE the ridge can escape. Get it wrong in the first place and
// nothing comes apart; wrong in the second and it lifts straight off.
echo(str("foot: full width x ", foot_reach, " x ", foot_t,
         " mm under the cover, ", foot_gap, " mm clear of its underside; ",
         "bottom sits ", -foot_z0, " mm below the bracket"));
echo(str("foot lock clearance: o", lock_cbore_d + 1,
         " mm teardrop, head is o", lock_cbore_d, "  (want bigger)"));
echo(str("prisms: 2 x ", prism_w, " x ", prism_d, " x ", prism_h,
         " mm at x +/-", prism_x, ", engaging ", prism_engage, " mm"));
echo(str("prism recess bridge span: ", prism_w + 2 * prism_lead + 2 * prism_clear,
         " mm  (want < 10; it is a flat ceiling in the cover's underside)"));
echo(str("prism ramp: ", prism_h, " mm over ", prism_lead, " mm of X = ",
         round(atan(prism_h / prism_lead)), " deg against print Z  (want <= 45)"));
echo(str("swing to fit: ", round(hook_swing * 10) / 10,
         " deg, set by the foot's ", foot_reach, " mm reach"));
echo(str("ridge corner sweep at that swing: ",
         round(sqrt(pow(ridge_w / 2, 2) + pow(ridge_h / 2, 2)) * hook_swing * PI / 180 * 100) / 100,
         " mm  (clearance is ", ridge_clear, ")"));
// The flange's rear edge dips as the extension swings in; the relief behind the
// ridge has to be deeper than that dip or it grounds before the tabs seat.
flange_dip = (flange_back - ridge_back) * tan(hook_swing);
echo(str("flange rear dips ", round(flange_dip * 100) / 100, " mm on the swing, relief is ",
         flange_relief_rear, " mm  (want relief > dip)"));
echo(str("prism recess to the cover's side: ",
         x_out - (prism_x + prism_w / 2 + prism_lead + prism_clear),
         " mm  (want > 3)"));
// The wall left OUTBOARD of the recess, between it and the cover's front face.
// This is the face the prism bears on when the extension is rotated out, and it
// sits on the first layer, so it has to be worth printing as well as strong.
echo(str("recess outer wall: ", prism_y - prism_d / 2 - prism_clear,
         " mm thick x ", prism_h - foot_gap + prism_clear,
         " mm tall  (want > 1.5, it is what the prism pushes against)"));
echo(str("foot left behind the prism: ", foot_reach - (prism_y + prism_d / 2),
         " mm  (want > 0.5)"));

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
// The light cradle's sweep, as the printer sees it. A raised cosine is steepest
// halfway along, at atan(A*pi/(2L)) off the bed with A the half-width lost and L
// the span. Under 45 means support, which is the deal for this part and this
// part only — the number is here so the cost stays visible.
light_span  = pts_reach(helmet_pts()) - light_from;
light_slope = atan((ext_w - light_tip_w) / 2 * PI / (2 * light_span));
echo(str("light cradle: ", ext_w, " -> ", light_tip_w, " mm over ", light_span,
         " mm, steepest face ", round(light_slope * 10) / 10,
         " deg off the bed  (< 45 = NEEDS SUPPORT, by choice)"));
echo(str("prism outer edge to the extension edge: ",
         ext_w / 2 - (prism_x + prism_w / 2 + prism_lead), " mm  (want > 3)"));
// Material left between the nut slot and the rebate floor
echo(str("wall between nut slot and cover rebate: ",
         (x_out - rebate_d) - (bolt_x + (nut_af / cos(30)) / 2 + 0.5), " mm"));
}

// ---- Test-fit coupons ------------------------------------------------------
// The interface and nothing else: a narrow slice through the middle of the real
// cover and of an armless extension. Everything the joint depends on lives in
// the middle — the ridge is 30 long, the prisms sit at x = +/-9, the lock bore
// is on the centreline — so a 44 mm slice carries all of it and prints in a
// fraction of the time.
//
// What is deliberately NOT here: the clamp screws and their counterbores, the
// cover's lips and the arm rebates. Those are about gripping the post, not
// about hanging an extension, and they have their own fit check.
//
// Both slices keep their real print orientation, so the bridges and overhangs
// are the ones the real parts will have.
fit_w = 44;
module fit_slab() { translate([-fit_w / 2, -300, -300]) cube([fit_w, 600, 600]); }

module fit_cover() { intersection() { cover("print"); fit_slab(); } }
module fit_ext() {
    translate([0, 0, fit_w / 2]) rotate([0, -90, 0])
        intersection() { ext_stub("install"); fit_slab(); }
}

// Both coupons on one plate, each already in its own print orientation, spaced
// so they can be sliced as a single job.
module fit_plate() {
    translate([0, -14, 0]) fit_cover();
    translate([0,  22, 0]) fit_ext();
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
            if (show_ext == "ext_light")  ext_light();
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
    if (part == "screw_cap")  screw_cap();
    if (part == "ext_helmet") cut() ext_helmet(ext_orient);
    if (part == "ext_light")  cut() ext_light(ext_orient);
    if (part == "ext_strap")  cut() ext_strap(ext_orient);
    if (part == "ext_lock")   cut() ext_lock(ext_orient);
    if (part == "ext_shelf")  cut() ext_shelf(ext_orient);
    if (part == "ext_stub")   cut() ext_stub(ext_orient);
    if (part == "fit_cover")  fit_cover();
    if (part == "fit_ext")    fit_ext();
    if (part == "fit")        fit_plate();
}
