// Point probe in the EXTENSION's own installed frame (back face on y = 0,
// x centred, z = 0 at the bracket's bottom). Empty result = air.
include <../src/params.scad>
use <../src/extensions.scad>

px = 0; py = 0; pz = 0;

intersection() {
    ext_stub("install");
    translate([px, py, pz]) cube(0.3, center = true);
}
