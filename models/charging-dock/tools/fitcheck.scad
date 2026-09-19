// Interference between parts that mate. A correct fit leaves only zero-volume
// contact — a face resting on a face; any real overlap has measurable volume.
// Driven by ../../../tools/fitcheck.py, which passes -D which="...".
include <../src/params.scad>
use <../src/frame.scad>
use <../src/base.scad>
use <../src/plate.scad>
use <../src/insert.scad>
use <../src/parts.scad>

// chassis  base vs top plate — the two halves are parted on the inclined plane
//          carrying the puck floors, so they should meet exactly on it and
//          nowhere else. Any volume here means the parting plane is wrong and
//          the plate will not seat.
// insert   the TPU insert vs the recess it drops into. The insert is
//          deliberately undersized by mat_clearance_total, so this should be
//          empty rather than merely thin.
which = "chassis";

if (which == "chassis")
    intersection() { base(); top_plate(); }
else if (which == "insert")
    // Without its studs: those are a deliberate press fit, checked below.
    intersection() { top_plate(); top_insert(dowels = false); }
// matdowel the mat's studs, narrowed past their press interference, vs the
//          plate. Zero means every stud lands inside its hole and stops short
//          of the floor; a missing or misplaced hole shows up as volume.
else if (which == "matdowel") {
    if (mat_dowels)
        intersection() {
            top_plate();
            top_frame() mat_dowel_studs(shrink = mat_dowel_interference + 0.05);
        }
}
// boot     the puck's cable strain relief and the cable's U-turn back under
//          the puck, as measured on the real puck, vs everything round it.
//          The boot's top is above the mat's underside, so the mat's notch
//          has to clear the whole boot plus the start of the bend, and the
//          bottom of the U-turn is well below the old bend tray.
else if (which == "boot")
    intersection() {
        for (cx = puck_xs) cable_boot_dummy(cx);
        union() { top_insert(); top_plate(); base(); }
    }
