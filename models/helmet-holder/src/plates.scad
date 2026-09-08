// ---------------------------------------------------------------------------
// Ready-to-slice build files, one per MATERIAL, each holding every part in it.
//
//   openscad --enable=lazy-union -D 'plate="petg"' -o petg.3mf plates.scad
//
// lazy-union keeps every part a separate object in the 3MF, so the slicer can
// move, delete and arrange them individually.
//
// Since the clamp was rebuilt for a 40 mm post the PETG parts all fit ONE MK4S
// bed: ~28,900 mm² of footprint against 52,500 mm². They used to need two. The
// layout below is a real arrangement, not a heap — but PrusaSlicer's Arrange (A)
// will still tidy it for whatever bed you actually have configured.
//
// PrusaSlicer stores no plate metadata — bed membership is inferred purely from
// object coordinates against an internal grid — so a file like this can only
// place objects, never pre-assign them to beds.
// ---------------------------------------------------------------------------
include <params.scad>
use <clamp.scad>
use <extensions.scad>

plate = "petg";        // petg | tpu | coupon
gap   = 6;             // spacing between parts

// Drop a part so its own minimum corner lands at `pos`.
module at(pos, mn) { translate([pos[0] - mn[0], pos[1] - mn[1], -mn[2]]) children(); }

// Measured minimum corners of each part as exported. `make check` prints these
// (tools/bbox.py); if you change a part's size, re-read them from there.
MIN_U      = [-39.0, -12.0, 0];   //  78.0 x  51.0
MIN_COVER  = [-39.0,   0.0, 0];   //  78.0 x  29.0
MIN_HELMET = [-65.0, -12.0, 0];   //  65.0 x 113.0
MIN_STRAP  = [-70.0, -12.0, 0];   //  70.0 x  57.5
MIN_LOCK   = [-53.0, -12.0, 0];   //  62.0 x  92.0
MIN_SHELF  = [-57.5, -12.0, 0];   //  57.5 x  97.5
MIN_PAD    = [  0.0,   0.0, 0];   //  30.0 x  32.0  (pad_arm 20.0 x 32.0)
MIN_STUB   = [-53.0, -12.0, 0];   //  53.0 x  21.0

if (plate == "petg") {          // everything structural — one bed
    // back row: the three tall extensions, up to y = 113
    at([  0,   0], MIN_HELMET) ext_helmet("print");
    at([ 71,   0], MIN_SHELF)  ext_shelf("print");
    at([135,   0], MIN_LOCK)   ext_lock("print");
    // front row: the clamp itself and the short extension, up to y = 176
    at([  0, 119], MIN_U)      u_bracket();
    at([ 84, 119], MIN_STRAP)  ext_strap("print");
    at([160, 119], MIN_COVER)  cover("print");
} else if (plate == "coupon") { // PETG — the real cover plus an armless
                                // extension: every interface feature, a quarter
                                // of an extension's plastic. Print this first.
    at([ 0, 0], MIN_COVER) cover("print");
    at([84, 0], MIN_STUB)  ext_stub("print");
} else if (plate == "tpu") {    // all four pads — fits one bed easily
    at([       0,        0], MIN_PAD) pad_flat();
    at([30 + gap,        0], MIN_PAD) pad_arm_flat();
    at([       0, 32 + gap], MIN_PAD) pad_flat();
    at([30 + gap, 32 + gap], MIN_PAD) pad_arm_flat();
}
