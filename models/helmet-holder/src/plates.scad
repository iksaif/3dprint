// ---------------------------------------------------------------------------
// Ready-to-slice build files, each holding a set of parts that share a MATERIAL
// and a slicer profile.
//
//   openscad --enable=lazy-union -D 'plate="petg"' -o petg.3mf plates.scad
//
// lazy-union keeps every part a separate object in the 3MF, so the slicer can
// move, delete and arrange them individually.
//
// There are four plates and the split is not arbitrary:
//
//   petg    everything structural that prints support-free — one bed
//   light   ext_light ALONE, because it is the one part that needs support and
//           you do not want that setting anywhere near the others
//   coupon  the interface only: print this first
//   tpu     the pads
//
// PrusaSlicer stores no plate metadata — bed membership is inferred purely from
// object coordinates against an internal grid — so a file like this can only
// place objects, never pre-assign them to beds. The layouts below are real
// arrangements against a 250 x 210 MK4S bed, but Arrange (A) will still tidy
// them for whatever bed you actually have configured.
// ---------------------------------------------------------------------------
include <params.scad>
use <clamp.scad>
use <extensions.scad>

plate = "petg";        // petg | light | coupon | tpu
gap   = 6;             // spacing between parts

// Drop a part so its own minimum corner lands at `pos`.
module at(pos, mn) { translate([pos[0] - mn[0], pos[1] - mn[1], -mn[2]]) children(); }

// Each part as [size, min corner], both measured off the exported STL. `make
// check` prints them — tools/bbox.py now reports the min corner as well as the
// size, which it did not when these were first written, so "re-read them from
// there" was advice that could not be followed.
//
// A part is placed by its min corner and packed by its size, so both have to be
// here; nothing below hardcodes a coordinate that these two do not produce.
U       = [[77.9,  51.0], [-39.0, -12.0, 0]];
COVER   = [[78.0,  28.0], [-39.0,   0.0, 0]];
HELMET  = [[66.9, 110.5], [-63.0, -12.0, 0]];
LIGHT   = [[66.9, 110.5], [-63.0, -12.0, 0]];
STRAP   = [[73.9,  57.5], [-70.0, -12.0, 0]];
LOCK    = [[56.0,  92.0], [-47.0, -12.0, 0]];
SHELF   = [[61.4,  97.5], [-57.5, -12.0, 0]];
STUB    = [[50.9,  21.0], [-47.0, -12.0, 0]];
CAP     = [[ 7.7,   7.7], [ -3.8,  -3.8, 0]];
PAD     = [[30.0,  24.0], [  0.0,   0.0, 0]];
PAD_ARM = [[20.0,  24.0], [  0.0,   0.0, 0]];

function sz(p) = p[0];
function mn(p) = p[1];

// x of the n-th slot in a row, given the parts before it. Written this way so
// that resizing a part shifts everything after it instead of silently
// overlapping — the failure mode of a row of hand-typed offsets.
function row_x(parts, n) =
    n == 0 ? 0 : row_x(parts, n - 1) + sz(parts[n - 1])[0] + gap;

if (plate == "petg") {
    // Back row: the three tall extensions. 196 mm wide, 110 deep.
    BACK = [HELMET, SHELF, LOCK];
    at([row_x(BACK, 0), 0], mn(HELMET)) ext_helmet("print");
    at([row_x(BACK, 1), 0], mn(SHELF))  ext_shelf("print");
    at([row_x(BACK, 2), 0], mn(LOCK))   ext_lock("print");

    // Middle row: the clamp itself and the short extension. 242 mm wide, which
    // is the number that decides whether this is one bed or two.
    MY   = 110.5 + gap;
    MID  = [STRAP, U, COVER];
    at([row_x(MID, 0), MY], mn(STRAP)) ext_strap("print");
    at([row_x(MID, 1), MY], mn(U))     u_bracket();
    at([row_x(MID, 2), MY], mn(COVER)) cover("print");

    // Front strip: the screw caps. Two are needed; six are printed because they
    // are 0.1 cm3 each and the whole point of them is to not be missing.
    CY   = MY + 57.5 + gap;
    CAPS = [CAP, CAP, CAP, CAP, CAP, CAP];
    for (i = [0 : len(CAPS) - 1]) at([row_x(CAPS, i), CY], mn(CAP)) screw_cap();
    // total: 242 x 188 mm against a 250 x 210 bed
} else if (plate == "light") {
    // On its own, and deliberately so: this is the one part in the repo that is
    // printed with support (see SUPPORT_EXEMPT in the Makefile). Turning support
    // on for a plate turns it on for everything sharing that plate, so it does
    // not share one.
    at([0, 0], mn(LIGHT)) ext_light("print");
} else if (plate == "coupon") {
    // PETG — the real cover plus an armless extension: every interface feature,
    // a quarter of an extension's plastic. Print this first.
    CP = [COVER, STUB];
    at([row_x(CP, 0), 0], mn(COVER)) cover("print");
    at([row_x(CP, 1), 0], mn(STUB))  ext_stub("print");
} else if (plate == "tpu") {
    // All four pads — fits one bed easily.
    ROW = [PAD, PAD_ARM];
    for (j = [0, 1]) {
        y = j * (sz(PAD)[1] + gap);
        at([row_x(ROW, 0), y], mn(PAD))     pad_flat();
        at([row_x(ROW, 1), y], mn(PAD_ARM)) pad_arm_flat();
    }
}
