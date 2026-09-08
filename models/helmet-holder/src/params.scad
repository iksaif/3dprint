// ---------------------------------------------------------------------------
// Shared parameters — every dimension lives here, in mm.
//
// The clamp is a U-bracket plus a front cover. It clamps in ONE axis only
// (front-to-back, by two screws). The other axis is a measured fit: the U's
// inner width is fixed, and the TPU pads take up the tolerance. So measure the
// post's left-right dimension properly and put it in post_w.
//
// DATUM: y = 0 is the U's back inner face — the surface the post's back pad
// touches. The U is a rigid part, so all of its geometry is fixed relative to
// that; only the cover moves as post_d changes.
//
// SCALE NOTE: this is built for a 40 mm post. Most of the wall thicknesses here
// are NOT set by the post — they are set by the hardware that has to fit inside
// them (a nut needs its across-corners width plus a web, whatever the post
// measures). So going to a bigger post mostly moves hw and arm_len; going to a
// smaller one runs into the hardware first, which is why the screws are M4.
// ---------------------------------------------------------------------------

// ---- The post -------------------------------------------------------------
post_w         = 40;    // MEASURED left-right dimension — the U is built to this
post_d         = 40;    // nominal front-back dimension
post_d_min     = 38;    // smallest front-back the cover must close on
post_d_max     = 42;    // largest front-back the cover must open over
post_corner_r  = 4;     // corner radius of the post — ONLY used to draw the mock post.
                        // The U never touches the corners (see corner_relief).

// ---- Printed TPU pads -----------------------------------------------------
pad_t          = 3;
pad_recess     = 1.5;
pad_margin     = 4;     // pocket inset from the part's top/bottom edges
pad_protrude   = pad_t - pad_recess;
pad_stud_d     = 4.4;   // push-in stud on the pad's back (TPU, squishes into the hole)
pad_stud_hole  = 4.0;
pad_stud_h     = 3;
pad_corner_r   = 2.5;
pad_fit        = 0.2;   // the pad's chamfer runs slightly longer than the
                        // pocket's, so the two tapers do not wedge against each
                        // other going in. Depth at the flat is unchanged.
pad_len        = 30;             // back and front pads — the clamped axis
pad_studs      = [6, 15, 24];
pad_arm_len    = 20;             // side pads, kept short so they end well before the
pad_arm_studs  = [5, 15];        // nut slots, which open on the arms' INNER faces

eff            = 2 * pad_protrude;   // what the pads add across a face
pd             = post_d     + eff;   // post depth as the bracket sees it
pd_min         = post_d_min + eff;
pd_max         = post_d_max + eff;

// ---- Bracket geometry -----------------------------------------------------
// The back and the arms are deliberately NOT the same thickness. The arms have
// to bury an M4 nut and still leave meat outboard of it for the cover's rebate,
// which sets arm_t at ~17 whatever the post measures. The back only has to tie
// the two arms together against the screw preload, so making it as thick as the
// arms would add a centimetre of plastic to the footprint for nothing.
u_h            = 40;    // height along the post (= print Z for the U)
back_t         = 12;    // U back thickness — a beam in bending across the post
arm_t          = 17.5;  // arm thickness — set by the nut, see above
plate_t        = 12;    // cover thickness — houses the flush heads and the lock bore
corner_r       = 3;
end_r          = 2;
chamfer        = 1.2;
gap_min        = 2;     // gap between the arm ends and the cover at post_d_min
corner_relief  = 5;     // 45° cut at each inner corner, so only the post's flats are touched

hw             = (post_w + eff) / 2;    // U inner half-width
x_out          = hw + arm_t;            // U outer half-width
arm_len        = pd_min - gap_min;      // arm length forward of the datum
pad_hgt        = u_h - 2 * pad_margin;  // 32
pad_arm_y      = 4;                     // side pads start this far forward of the datum

// ---- Cover / U engagement -------------------------------------------------
// The cover is a shallow tray. Its two lips run in rebates cut into the arm
// ends, so the outside stays a clean rectangle however far the screws are wound
// in or out — no step appears as the clamp adjusts.
cover_lip      = 3.5;   // lip thickness — must exceed 2*cover_r or the corner
                        // rounding erodes it away entirely
cover_r        = 1.5;   // corner rounding on the cover outline
cover_clear    = 0.3;   // sliding clearance between lip and rebate
lip_len        = 16;    // how far the lips reach back from the cover's inner face
rebate_len     = 20;    // how far the rebate runs back from the arm's end face
rebate_d       = cover_lip + cover_clear;

// ---- Clamp screws (M4 socket cap, heads flush in the cover) ---------------
// M4, not M6. Nothing here is screw-limited: the tension per screw is under
// 100 N and the friction the pads need to not slide is about 20 N, while an M4
// takes ~2000 N. The printed arm is the weak link at every size, so the screw
// is chosen for the smallest arm it can live in rather than for strength.
bolt_d         = 4;
bolt_clear     = 0.5;
bolt_hole      = bolt_d + bolt_clear;   // 4.5
head_d         = 7;                     // M4 socket cap head
head_h         = 4;
cbore_d        = head_d + 0.8;
cbore_h        = head_h + 0.5;
nut_af         = 7;
nut_h          = 3.2;
nut_clear      = 0.4;
nut_depth      = 11;    // nut centre, back from the arm's end face, so a good
                        // stretch of arm sits behind the nut rather than a few
                        // mm — that is what the screw tension pulls against.
screw_depth    = 22;    // clearance-hole depth into the arm end: must swallow
                        // the whole screw at the SMALLEST post, where the tip
                        // runs deepest past the nut
bolt_x         = hw + 6.5;  // screw inset from the inner face. Everything in the
                            // arm's thickness stacks off this: nut, web, rebate.
bolt_z         = u_h / 2;
nut_y          = arm_len - nut_depth;

// ---- Extension interface: ridge and groove on the cover's TOP --------------
// There used to be a dovetail up the cover's face. It could not be printed: an
// undercut in the face runs along X, which is the extension's print Z, so one
// of its lips began as a zero-width knife edge hanging in mid-air. Tilting or
// reshaping it only moved the problem — see INTERFACE.md.
//
// The fix is to stop putting the undercut in the face. The extension has to be
// held against the face at the TOP, where the load's moment pulls it away; it
// is held at the bottom by that same moment pressing it in. So the only hard
// stop needed is at the top — and the cover's top face is somewhere neither
// part's print orientation objects to:
//
//   * on the COVER a ridge grows straight up out of the finished top face, so
//     every layer of it lands on solid material. Supported by construction.
//   * on the EXTENSION the mating groove lies in the (Y,Z) profile plane, so it
//     is a prism along X — the extension's own print Z. Free, and extensions
//     stay "one 2D profile" to write.
//
// The extension drops on from above, the ridge enters the groove, and the
// groove's front wall is the hard stop against the moment. Nothing slides
// through an undercut, so nothing has a lip to begin in mid-air.
ridge_len      = 30;    // along X — its ends are what locate the extension sideways
ridge_w        = 5;     // along Y
ridge_h        = 3;     // above the cover's top face
ridge_back     = 6;     // ridge centre, measured back from the cover's outer face:
                        // half of plate_t, so the groove walls come out equal
ridge_clear    = 0.25;
ridge_lead     = 1.0;   // chamfer on the ridge's top, to guide it into the groove

// The extension's width is NOT set by the post. A helmet is the same size
// whichever post you hang it on, so this stayed broad: it spreads the load
// across the EPS foam instead of denting a line into it, and it still lands
// well inside the cover's 78 mm.
ext_w          = 56;
ext_plate_t    = 9;
ext_roof       = 13;    // roof + flange: deep enough for the ridge groove AND the
                        // lock nut above it, stacked
ext_h          = u_h + ext_roof;
flange_back    = plate_t;   // the flange reaches back exactly over the cover
flange_relief  = 0.15;      // and clears its top, so the ridge alone sets the seat

// The groove in the flange's underside that the ridge drops into. Closed at
// both ends in X: that is what stops the extension sliding sideways, and it
// costs nothing to print because the closing is a short bridge over a pocket,
// not an undercut.
ridge_groove_top = u_h + flange_relief + ridge_h + ridge_clear;

// ---- Snap retention --------------------------------------------------------
// The spring lives on the COVER, not on the extension. A cantilever prints
// without support only if it is identical on every layer; the cover prints
// upright so a full-height leaf is exactly that, while the extension prints on
// its side, where any finger occupying part of the width starts in mid-air.
//
// So: the cover gets two leaf springs cut into its face, each carrying a catch
// bump. The extension gets a plain groove across its back face — removed
// material, which can never be an unsupported island, and which keeps every
// extension a pure 2D extrusion.
//
// The leaves are anchored OUTBOARD and reach inboard, putting the bump near the
// free end where the spring is compliant. Release is a firm pull upward: both
// bump faces are 45 deg, which is what makes them print and what lets them cam
// apart under a deliberate tug rather than locking permanently.
//
// Shrinking the clamp squeezed this hard. The leaf can only run between the
// central lock bore and the clamp screw, which is now ~15 mm rather than ~28,
// and a short leaf strains far more for the same deflection: peak stress is
// 3*E*d*t / (2*a^2), so halving the length quadruples the stress at the same
// catch depth. That is why snap_proud came down with everything else — the
// catch is shallower, and the spring is a detent rather than a latch. It only
// has to stop the extension lifting; the ridge takes the load and the lock
// screw is there when you want it permanent.
ext_snap       = true;  // the groove on the EXTENSION; the cover is always ready
snap_z0        = 5;     // bump's underside — the catch height
snap_h         = 5;     // bump height before the lead-in ramp
snap_ramp      = 3;     // lead-in above the bump
snap_proud     = 1.0;   // how far the bump stands out from the cover's face
snap_clear     = 0.25;

// The leaf, in the cover's XY cross-section — identical at every height
spring_x0      = 6;     // free end, inboard (clear of the central lock bore)
spring_x1      = 21;    // anchored here, inboard of the clamp screw
spring_t       = 1.2;   // leaf thickness — sets the snap force
spring_gap     = 2.2;   // slot behind it to flex into
spring_relief  = 0.3;   // leaf face sits behind the cover's face, so the
                        // extension bears on solid cover and not on the spring
spring_tip     = 2.5;   // slot that frees the leaf's inboard end
bump_x0        = 6.5;   // bump sits under the extension, at the free end, which
bump_x1        = 11;    // is what buys back some of the lost leaf length

// The extension's half: a groove deep enough for the bump and tall enough to
// clear its lead-in ramp as well.
snap_groove_d  = snap_proud + snap_clear;
snap_groove_z0 = snap_z0 - snap_clear;
snap_groove_z1 = snap_z0 + snap_h + snap_ramp + snap_clear;

// ---- Optional extension lock (M3) -----------------------------------------
// It enters from BELOW: up through the cover, into a nut buried in the
// extension's flange. Nothing protrudes at either end — the tip stops blind
// inside the flange, and the head is swallowed deep in the cover's bore.
//
// M3 because the screw carries almost nothing: the ridge takes the moment and
// the snap takes the lifting. It only has to stop a deliberate pull. It also
// has to fit BETWEEN the two snap leaves, which is what rules out anything
// bigger now the cover is 78 mm rather than 175 mm wide.
//
// It runs straight up the middle of the ridge, so the ridge, the bore and the
// nut all share one centreline and there is nothing to misalign.
ext_lock_hole  = true;  // cut the bore and nut pocket in extensions at all
lock_d         = 3;
lock_hole      = lock_d + 0.5;
lock_y         = ridge_back;    // bore axis, back from the cover's outer face:
                                // the ridge's own centreline
lock_nut_af    = 5.5;           // M3 hex nut
lock_nut_h     = 2.4;
lock_head_d    = 5.5;           // M3 socket cap
lock_head_h    = 3.0;
lock_cbore_d   = lock_head_d + 0.8;
lock_len       = 35;            // the screw you actually buy: M3 x 35, a stock
                                // length everywhere. 30 or 40 also work — change
                                // this and the counterbore follows.
lock_engage    = 0.75;          // how far the tip runs past the nut

// Where the nut sits, and therefore how deep the head has to be buried for a
// standard length to come out right. Derived, so the BOM cannot drift.
// It stacks above the ridge groove, centred in what flange is left over it.
lock_nut_z     = (ridge_groove_top + ext_h) / 2;
lock_nut_top   = lock_nut_z + lock_nut_h / 2;
lock_cbore_h   = lock_nut_top + lock_engage - lock_len;   // head bears here
lock_tip_z     = lock_cbore_h + lock_len;                 // must stay under ext_h

// ---- Load case -------------------------------------------------------------
// 3 kg hung at the helmet cradle's tip. Measured off the exported mesh by
// tools/strength.py; kept here so the ridge sizing below cannot drift from it.
load_M         = 2950;  // N.mm at the mounting face

// ---- Render quality --------------------------------------------------------
$fn = $preview ? 40 : 96;
