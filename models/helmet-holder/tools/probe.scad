// Read-only probe: is there material at a point? Empty result = air.
// Both parts are placed in the SAME global frame the assembly uses, so a single
// (px, py, pz) can be walked straight up the lock screw's axis through both.
include <../src/params.scad>
use <../src/clamp.scad>
use <../src/extensions.scad>

what = "cover";           // cover | ext
px = 0; py = 0; pz = 0;

intersection() {
    if (what == "cover") cover("install");
    else translate([0, pd + plate_t, 0]) ext_helmet("install");
    translate([px, py, pz]) cube(0.1, center = true);
}
