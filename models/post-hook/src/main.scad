// ---------------------------------------------------------------------------
// post-hook — entry point.
//
//   openscad -D 'part="clip_m"' -o clip_m.stl main.scad
//
// part:  clip_s | clip_m | clip_l | calib | assembly | dims
//
// One part, one material, three hook sizes. It is modelled in its print
// orientation already — z is the post's axis AND the print axis — so the
// assembly view is the same geometry the slicer gets, with nothing rotated on
// the way to the STL.
// ---------------------------------------------------------------------------
include <params.scad>
use <clip.scad>

part      = "assembly";
show_post = true;
show_size = "m";        // which hook the assembly view wears
// Shear the arms out to where they sit on a real post. Off shows the part as
// PRINTED, which is honest about the geometry and misleading about the fit —
// the grip lands then read as buried `grip` deep in the post.
show_seated = true;

c_clip  = "#3f4854";

if (part == "clip_s")      clip("s");
else if (part == "clip_m") clip("m");
else if (part == "clip_l") clip("l");
else if (part == "calib")    calib_slice();
else if (part == "assembly") {
    if (show_post) post_mock();
    color(c_clip)
        if (show_seated) { seated() collar(); hook(size_idx(show_size)); }
        else clip(show_size);
} else if (part == "dims") {
    kg = load_kg;

    echo(str("post: ", post_w, " x ", post_d, " mm, gripped over ", collar_h,
             " mm of height; collar is ", 2 * (x_out + tab_out), " x ",
             y_arm_end - y_back_out, " x ", collar_h, " mm"));
    echo(str("fit_adjust ", fit_adjust, ": drawn around a ", pw, " x ", pd,
             " post, to land on ", post_w, " x ", post_d, " as printed"));

    // ---- the fit, as the surfaces that decide it --------------------------
    // What to hold the calipers to. All as DRAWN — a print comes out
    // fit_adjust a side smaller, which is the point of fit_adjust.
    echo(str("between the arms: ", 2 * hw_in, " mm (", arm_clear,
             " clear a side), across the grip lands: ", 2 * grip_x,
             " (", grip, " interference a side), mouth between the crests: ",
             2 * x_crest_seated, " mm"));
    echo(str("grip lands ", grip_len, " mm long, ending ", grip_front,
             " mm short of the post's front, ", grip_lead,
             " mm ramps; they spread each arm tip ",
             round(grip_tip * 100) / 100, " mm"));
    echo(str("corner relief: ", 2 * relief_r, " mm slot, ", relief_depth,
             " mm into the ", back_t, " mm back wall — a square post corner ",
             "clears it"));
    echo(str("lip reaches ", lip_reach, " mm inboard; unsprung its crest sits at x ",
             x_crest_seated, ", inboard of where the face meets the corner at ",
             round(x_arc_touch * 100) / 100, "  (it must be, or the cam meets nothing)"));
    echo(str("cam face normal ", lip_cam, " deg off the insertion axis, tangent to the r",
             post_corner_r, " corner, leaving the arm's face at y ",
             round(y_cam_start * 100) / 100, "; ", lip_release,
             " mm of release travel, supplied by squeezing the tabs"));
    echo(str("peak spread on the way on: ", spread_peak,
             " mm per arm, over an arm ", round(arm_free * 10) / 10, " mm long"));

    // The post_d axis is elastic, not rigid: the cams turn a deeper post into a
    // little more arm spread instead of a jam.
    echo(str("post depth ", post_d_min, "-", post_d_max,
             " is absorbed by the cams — a post ", post_d_max - post_d,
             " mm deep just springs the arms ",
             round((post_d_max - post_d) * tan(lip_cam) * 100) / 100,
             " mm further"));

    if (tie_slot)
        echo(str("cable tie: ", tie_w, " x ", tie_t,
                 " mm slot through each lip at z ", tie_z,
                 "; loop stays at the opening end — across the post's face and ",
                 "back over the two tabs, never round the hook"));
    // ---- the hooks, size by size ------------------------------------------
    // The mouth is the number that separates them; the reach is not. Printed
    // side by side so choosing a size is reading a row rather than a render.
    echo("hook sizes:  reach  cradle  mouth  lift  width  height  arm  N.mm");
    for (i = [0 : len(hook_sizes) - 1])
        echo(str("  ", hook_sizes[i][0], ":  ",
                 hk_reach(i), "     ",
                 cradle_len(i), "     ",
                 round(mouth(i) * 10) / 10, "   ",
                 round(cradle_lift(i) * 10) / 10, "   ",
                 hk_w(i), "     ",
                 round(hk_tip_top(i) * 10) / 10, "   ",
                 load_arm(i), "   ",
                 round(kg * 9.81 * load_arm(i))));

    echo(str("stem underside ", hook_rake, " deg from horizontal (limit is ",
             max_overhang_angle, "), leaving the wall at z ", stem_z,
             " and rooting at z ", round(stem_bot_at(hk_root_y) * 100) / 100));
    echo(str("upturn leans ", tip_lean,
             " deg back over the cradle — the trap, and well inside the limit"));
}
