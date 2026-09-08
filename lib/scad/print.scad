// Printing constants shared by every model in this repo.
//
// These are properties of the PRINTER and the FILAMENT, not of any one model,
// which is why they live here rather than in each model's params. A model that
// needs a different value should override it after including this file, and say
// why in a comment.
//
// include <...>, not use <...> — `use` imports modules and functions but NOT
// variables, so `use` would silently give you undef for everything below.

// ---- The machine -----------------------------------------------------------
// Prusa MK4S. bed_x/bed_y are the usable footprint, bed_z the gantry height.
bed_x              = 250;
bed_y              = 210;
bed_z              = 220;
nozzle_d           = 0.4;
layer_h            = 0.2;

// Perimeter extrusion width at a 0.4 nozzle. Worth knowing when you size a thin
// wall: a wall that is not a whole number of these gets gap fill down its core.
extrusion_w        = 0.45;

// ---- What the printer can be trusted with ----------------------------------
// Steepest overhang, measured from vertical. 45 deg is the number every
// self-supporting chamfer in this repo is derived from.
max_overhang_angle = 45;

// Longest unsupported flat ceiling allowed anywhere. Small blind pockets and
// the closed ends of grooves are fine; anything longer wants rethinking rather
// than supports. tools/support.py measures this on the exported mesh — the
// constant here is what the models assert against in source.
max_bridge_span    = 10;

// ---- Structural minimums ---------------------------------------------------
min_wall           = 2.4;   // between any cavity and the exterior
min_floor          = 2.0;   // under any cavity

// ---- Fits ------------------------------------------------------------------
// Diametral clearance for a machine screw to pass freely.
bolt_clearance     = 0.5;
// Across-flats clearance for a hex nut dropped into a pocket.
nut_clearance      = 0.4;
// A sliding fit between two printed parts that must still come apart.
slide_clearance    = 0.3;
// A press fit: TPU studs into PETG holes, dowels, anything meant to stay put.
press_interference = 0.4;

// ---- Materials -------------------------------------------------------------
// Conservative yield for a well-printed part, loaded along the layers.
petg_yield_mpa     = 50;
// Young's modulus for printed PETG. Used for flexure stiffness, where being
// wrong by 20% matters less than the print's own layer-to-layer variation.
petg_e_mpa         = 2000;

// ---- Render quality --------------------------------------------------------
// Cheap in preview, smooth on export. Models can raise this locally.
function facets() = $preview ? 40 : 96;
