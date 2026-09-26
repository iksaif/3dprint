// ---------------------------------------------------------------------------
// Ready-to-slice build files. All PETG.
//
//   openscad --enable=lazy-union -D 'plate="petg"' -o petg.3mf plates.scad
//
// lazy-union keeps every part a separate object in the 3MF, so the slicer can
// move, delete and arrange them individually. Without it OpenSCAD unions the
// top-level children on export and they arrive fused into one mesh.
//
// Nothing here is rotated. Every clip is modelled with the post's axis as z,
// which is also their print axis, so a plate is a translation and nothing else
// — and every part on it is support-free as it stands.
// ---------------------------------------------------------------------------
include <params.scad>
use <clip.scad>

plate = "petg";        // petg | test
gap   = 6;

// Drop a part so its own minimum corner lands at `pos`.
module at(pos, mn) { translate([pos[0] - mn[0], pos[1] - mn[1], -mn[2]]) children(); }

// Minimum corners come from the geometry (clip_min in params.scad), not from
// numbers copied out of bbox.py — those went stale the first time the lip
// changed. They are outer bounds, so parts can only end up further apart.
MIN_S     = clip_min(size_idx("s"));
MIN_M     = clip_min(size_idx("m"));
MIN_L     = clip_min(size_idx("l"));

W = 2 * clip_x_half;   // every clip is the same width — the collar does not change

if (plate == "petg") {              // all three hooks, one bed
    at([            0, 0], MIN_S) clip("s");
    at([  W +     gap, 0], MIN_M) clip("m");
    at([2 * W + 2 * gap, 0], MIN_L) clip("l");
} else if (plate == "test") {
    // Print this one after the calibration ladder. It is a whole working clip,
    // and what is left to learn once the fit is right is what only a whole one
    // tells you: how hard it is to press on, whether the lips let go when you
    // want them to, and whether it holds a kilo. All three are properties of
    // the arm spring over its full height.
    at([0, 0], MIN_M) clip("m");
}
