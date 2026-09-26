// ---------------------------------------------------------------------------
// The calibration ladder: one 6 mm slice of the collar per fit_adjust value,
// side by side on one plate. Built by `make calib`.
//
// Each rung has to be its own OpenSCAD run — fit_adjust is a top-level
// parameter, and the whole collar derives from it — so the Makefile exports
// them one at a time and this only lays them out. `steps` is passed in from
// the Makefile, which is the one place the list lives.
// ---------------------------------------------------------------------------
include <params.scad>

steps = [0];
gap   = 6;
// Slices are all the same footprint to within a millimetre, so pitch on the
// widest one: the rung with the largest fit_adjust. Three to a row — five in a
// line is ~315 mm, which does not fit a 250 mm bed.
cols    = 3;
pitch_x = 2 * (clip_x_half + max(steps)) + gap;
pitch_y = (y_arm_end - y_back_out) + 2 * max(steps) + gap;

for (i = [0 : len(steps) - 1])
    translate([(i % cols) * pitch_x, floor(i / cols) * pitch_y, 0])
        import(str("../build/calib/calib_", steps[i], ".stl"));
