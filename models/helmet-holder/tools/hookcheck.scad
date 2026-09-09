// Does the hook actually retain the extension?
//
// The fit check can only prove the tabs do not collide when seated. It cannot
// prove they are IN their pockets rather than missing them entirely — with
// clearance on every face a correct fit and a total miss both intersect in
// nothing. So this raises the extension and asks when it starts to interfere.
//
// Expected: free up to hook_play, blocked beyond it, and still blocked at
// ridge_h + ridge_clear (the lift that would free the ridge). If it is free all
// the way, the tabs are not engaging and the extension can simply be lifted off.
include <../src/params.scad>
use <../src/clamp.scad>
use <../src/extensions.scad>

// swing tilts the extension's bottom away from the cover, about the ridge, which
// is the motion you actually make fitting it. At hook_swing the tabs must be
// clear of the cover's face, or it cannot be got in at all; the flange's rear
// edge and the ridge in its groove are what tend to foul first.
lift  = 0;
swing = 0;

pivot_y = pd + plate_t - ridge_back;
pivot_z = u_h + ridge_h;

intersection() {
    cover("install");
    translate([0, pivot_y, pivot_z])
        rotate([swing, 0, 0])
            translate([0, -pivot_y, -pivot_z + lift])
                translate([0, pd + plate_t, 0]) ext_helmet("install");
}
