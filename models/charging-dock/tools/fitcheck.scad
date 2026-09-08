// Interference between parts that mate. A correct fit leaves only zero-volume
// contact — a face resting on a face; any real overlap has measurable volume.
// Driven by ../../../tools/fitcheck.py, which passes -D which="...".
include <../src/params.scad>
use <../src/frame.scad>
use <../src/base.scad>
use <../src/plate.scad>
use <../src/insert.scad>

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
    intersection() { top_plate(); top_insert(); }
