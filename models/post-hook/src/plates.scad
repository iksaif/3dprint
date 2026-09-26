// ---------------------------------------------------------------------------
// Ready-to-slice build files, one per MATERIAL.
//
//   openscad --enable=lazy-union -D 'plate="petg"' -o petg.3mf plates.scad
//
// lazy-union keeps every part a separate object in the 3MF, so the slicer can
// move, delete and arrange them individually. Without it OpenSCAD unions the
// top-level children on export and they arrive fused into one mesh.
//
// Nothing here is rotated. Both parts are modelled with the post's axis as z,
// which is also their print axis, so a plate is a translation and nothing else
// — and every part on it is support-free as it stands.
// ---------------------------------------------------------------------------
include <params.scad>
use <clip.scad>

plate = "petg";        // petg | tpu | test
gap   = 6;

// Drop a part so its own minimum corner lands at `pos`.
module at(pos, mn) { translate([pos[0] - mn[0], pos[1] - mn[1], -mn[2]]) children(); }

// Minimum corners come from the geometry (clip_min in params.scad), not from
// numbers copied out of bbox.py — those went stale the first time the lip
// changed. They are outer bounds, so parts can only end up further apart.
MIN_S     = clip_min(size_idx("s"));
MIN_M     = clip_min(size_idx("m"));
MIN_L     = clip_min(size_idx("l"));
MIN_PAD   = [0, 0, 0];             // pads are modelled from the origin, flat

W = 2 * clip_x_half;   // every clip is the same width — the collar does not change

if (plate == "petg") {              // all three hooks, one bed
    at([            0, 0], MIN_S) clip("s");
    at([  W +     gap, 0], MIN_M) clip("m");
    at([2 * W + 2 * gap, 0], MIN_L) clip("l");
} else if (plate == "tpu") {        // one set of three pads per clip, all flat
    // Nothing here is on edge: every pad lies on its back with the teeth up,
    // which is the whole reason the U was split into three.
    for (i = [0 : 2]) {
        at([i * (pad_h + gap), 0], MIN_PAD) pad_back_flat();
        at([i * (pad_h + gap), pad_back_w + gap], MIN_PAD)      pad_side_flat();
        at([i * (pad_h + gap), pad_back_w + pad_side_w + 2 * gap], MIN_PAD)
            pad_side_flat();
    }
} else if (plate == "test") {
    // Print this one FIRST. It is a whole working clip, and the only things
    // worth learning from a first print are things a whole one tells you: how
    // hard it is to press on, whether the lips let go when you want them to,
    // and whether it holds a kilo. None of that can be coupon-tested, because
    // all three are properties of the arm spring over its full length.
    at([        0, 0], MIN_M)     clip("m");
    at([W + gap, 0], MIN_PAD) pad_back_flat();
    at([W + gap, pad_back_w + gap], MIN_PAD) pad_side_flat();
    at([W + gap, pad_back_w + pad_side_w + 2 * gap], MIN_PAD) pad_side_flat();
}
