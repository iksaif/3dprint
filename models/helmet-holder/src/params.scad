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
// Raised from 0.25. The extension has to swing ~7 deg to get the latch bump out
// of its slot, and at that angle the ridge's corners sweep 0.36 mm inside the
// groove. Anything at or under that binds, and the extension will not come off.
ridge_clear    = 0.45;
ridge_lead     = 1.0;   // chamfer on the ridge's top, to guide it into the groove

// Width is set by the clamp screws: the plate has to reach past their
// counterbores so they are covered rather than sitting in the weather. The
// bores span x 24.1..31.9, so 70 puts the edge 3.1 mm beyond them and leaves a
// 4 mm reveal of cover each side.
//
// ONE width, not two. A narrower arm on a wider plate was tried and it does not
// print: X is this part's print Z, so the arm's first layer would appear
// complete and unsupported the moment the section widened out. Tapering does
// not rescue it either — a gentle taper in plan is a near-vertical overhang in
// the print, and reaching the cradle's 113 mm tip at 45 deg would need 104 mm
// of width. The arm is the width of the plate, and the mass comes off with
// lightening holes instead.
ext_w          = 70;

// Lightening holes run through the WIDTH, which is the one direction that is
// free here: along X is along the print's Z, so they come out as plain vertical
// holes and need no support at all, whatever their size or spacing.
lighten        = true;
lighten_wall   = 4;     // material left around each hole, measured on the
                        // profile's local half-thickness
lighten_min_d  = 7;     // below this a hole is more fuss than it is worth
ext_plate_t    = 9;
// Raised from 13. What forced it: with the nut pinned above the groove, the
// flange's remaining height IS the room the screw's tip has to overrun into.
// At 13 there was 1.0 mm of it and then a 1.75 mm wall — so as soon as the head
// settled into the plastic at all, the tip drove into that wall and bulged it.
// 15 gives 2.5 mm of overrun and a 2.25 mm wall behind it.
ext_roof       = 15;    // roof + flange: deep enough for the ridge groove AND the
                        // lock nut above it, stacked
ext_h          = u_h + ext_roof;
flange_back    = plate_t;   // the flange reaches back exactly over the cover
flange_relief  = 0.15;      // and clears its top, so the ridge alone sets the seat

// Behind the ridge the flange is relieved further, because the extension has to
// TILT to get its hooks in (see hook_swing). At ~3.4 deg the flange's rear edge,
// 6 mm behind the pivot, dips about 0.35 mm — more than flange_relief — and it
// would land on the cover's top and stop the swing before the tabs seated. The
// front of the flange keeps the tighter relief and still carries the weight.
flange_relief_rear = 1.0;

// The groove in the flange's underside that the ridge drops into. Closed at
// both ends in X: that is what stops the extension sliding sideways, and it
// costs nothing to print because the closing is a short bridge over a pocket,
// not an undercut.
ridge_groove_top = u_h + flange_relief + ridge_h + ridge_clear;

// ---- Hook retention: two tabs at the bottom, engaged by rotating ------------
// There used to be a pair of leaf springs in the cover's face and a catch groove
// on the extension. They are gone. They were hard to print at this scale — the
// leaf had shrunk to 1.2 mm over a 15 mm span — and, more fundamentally, they
// were solving the wrong problem: the ridge at the top is a PIVOT. Once it is in
// the groove the extension's only remaining freedom is rotation about it, so the
// bottom swings in along an arc. A catch bump designed to cam down a vertical
// drop never gets a vertical drop.
//
// So retention now uses the rotation instead of fighting it. Hang the extension
// on the ridge, swing the bottom in, and two small tabs on its back face enter
// two small pockets in the cover.
//
// What actually locks it: once seated, lifting the extension off needs
// ridge_h + ridge_clear of vertical travel to clear the ridge. The tabs have
// only hook_play of room under their pockets' roofs, and hook_play is far less
// than that — so the tabs hit the roof long before the ridge is free. Nothing
// flexes and nothing wears; it is a hard geometric interlock.
//
// Getting it out is the same move backwards: lift a couple of mm, swing the
// bottom out, unhook. No tool, no force.
//
// The printability of BOTH halves is what dictates their shapes:
//
//  * the POCKET is in the cover, which prints upright, so its roof is a flat
//    ceiling anchored on both sides — a bridge. That caps the pocket's width at
//    max_bridge_span, which is why there are two small tabs and not one wide one.
//  * the TAB is on the extension, which prints on its side with X as print Z. A
//    tab that simply started partway along X would begin in mid-air — the exact
//    failure that banished the spring from this part in the first place. So each
//    tab ramps up at 45 deg over hook_lead at both ends in X, which in the print
//    is a 45 deg overhang and free.
ext_hook       = true;  // build the foot, prisms and recesses at all

// ---- 1. The foot: what stops it lifting off --------------------------------
// The extension is a C in section. Its flange goes over the cover's top, its
// plate down the front face, and its foot reaches back UNDERNEATH the cover.
// Lifting the extension drives the foot into the cover's underside, and it runs
// out of room at foot_gap — less than the ridge needs to free itself. So the
// extension cannot be pulled straight off however hard you pull. This is a hard
// stop between two solid faces, not a detent.
// Kept short deliberately. The foot has to swing out from under the cover, and
// it sits ~46 mm below the ridge it pivots about, so every mm of reach costs
// 1.25 deg of swing — which the ridge groove and the flange relief then have to
// absorb. At 7 mm the swing is 8.7 deg and the ridge binds in its groove; at
// 4 mm it is 5 deg and everything clears.
// The foot is part of the extension's own 2D PROFILE, not a block stuck on the
// back. It therefore runs the full width, side to side, and being a prism along
// the part's print Z it is support-free by construction — no slope needed.
// Only the prisms are interface; the foot is just the shape of the extension.
foot_reach     = 6;     // how far the foot runs back under the cover
foot_t         = 3.5;   // foot thickness
foot_fillet    = 3;     // blend into the plate. Deliberately smaller than the
                        // profile's own 6 mm fillet, which on a 3.5 mm foot
                        // would swallow the face the prisms stand on.
// Small, because the prisms stand on this face and have to reach up into the
// cover: what actually engages is prism_h - foot_gap. It also means the foot
// grounds on the cover's underside almost immediately, so the extension cannot
// be lifted off at all.
foot_gap       = 0.4;   // clearance from the foot's top to the cover's underside
foot_z0        = -(foot_gap + foot_t);   // the foot's underside, below the bracket

// ---- 2. The prisms: what stops it swinging back out ------------------------
// Two small wedges standing on the foot's UPPER face, dropping into two
// recesses in the cover's underside. Once the foot has swung under the cover
// they sit in their recesses and the extension will not swing back out on its
// own; the recesses' walls are what it comes up against.
//
// This is a detent, not a lock, and that is deliberate — it is what makes the
// thing removable by hand. To take the extension off you press the bottom edge
// down and pull it toward you, which lifts the prisms out of their recesses far
// enough to rotate; then the whole extension unhooks from the ridge. The finger
// ledge under the plate is there to give a nail something to pull on.
//
// Printability: the extension prints on its side, X -> print Z, so a wedge that
// simply appeared partway along X would start in mid-air. Each prism therefore
// ramps up over prism_lead at both ends in X, and with prism_lead equal to
// prism_h that is exactly 45 deg. The cover's recesses are plain pockets in its
// underside; their ceilings bridge prism_w + 2*prism_lead, which is why the
// prisms stay small.
prism_x        = 9;     // the two prisms, either side of the centre
prism_w        = 6;     // flat top length in X
prism_h        = 1.6;   // height above the foot's top face
prism_lead     = 1.6;   // = prism_h, so the ends are 45 deg against print Z
// prism_y sets how much cover is left OUTBOARD of the recess, and that little
// wall is the one that does the work: rotating the extension out drives the
// prism forward against it. At prism_y = 3 with prism_d = 4 it came out 0.7 mm
// thick over 1.5 mm of height, on the first layer — about one and a half
// extrusions wide, fragile to print and fragile in use.
//
// Moving the recess 1 mm inboard and taking 1 mm off the prism's depth to pay
// for it leaves 1.7 mm there, and the foot still has 1 mm of material behind
// the prism. What it costs is bearing area on the detent, which was never the
// limit — the foot is what actually holds the extension on.
prism_d        = 3;     // depth in Y
prism_y        = 3.5;   // prism centre, back from the cover's front face
prism_clear    = 0.3;
prism_bond     = 0.6;   // how far the prism's root reaches down INTO the foot.
                        // Butting added material on a face unions two solids
                        // across a coincident plane: watertight, but it comes
                        // out as separate shells. Overlap, always.

// How far the prism actually stands into the cover's recess once seated. This
// is the detent depth — the amount the bottom edge has to be pulled down by to
// free it — so it wants to be small enough to do by hand.
prism_engage   = prism_h - foot_gap;

// A ledge under the front of the plate, to get a fingernail under when
// releasing it.
grip_h         = 2;
grip_d         = 2.5;

// The swing needed to bring the foot out from under the cover, as an angle
// about the ridge. The foot is the furthest thing from that pivot, which is why
// its reach is kept short: every mm of it costs about a degree and a quarter,
// and the ridge groove and flange relief have to absorb that.
//
// The prisms do not add to it. They come out of their recesses by pressing the
// bottom edge DOWN, not by swinging — that is the whole point of the release.
hook_swing     = atan(foot_reach / (u_h + ridge_h + foot_gap));

// ---- Optional extension lock (M3) -----------------------------------------
// It enters from BELOW: up through the cover, into a nut buried in the
// extension's flange. Nothing protrudes at either end — the tip stops blind
// inside the flange, and the head is swallowed deep in the cover's bore.
//
// M3 because the screw carries almost nothing: the ridge takes the moment and
// the hook tabs take the lifting. It only has to stop someone deliberately
// swinging the extension back out, and it sits between the two hook pockets.
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
lock_len       = 20;            // the screw you actually buy: M3 x 20.
                                // Only the HEAD's depth depends on this. The tip
                                // always lands at lock_nut_top + lock_engage,
                                // because lock_cbore_h subtracts the same
                                // lock_len that lock_tip_z adds back — so a
                                // shorter screw just sits deeper up the bore,
                                // and 16, 25 or 30 work by changing this alone.
lock_engage    = 0.75;          // how far the tip runs past the nut
lock_tip_over  = 2.5;           // and how much EMPTY bore lies beyond that, so
                                // an over-tightened screw runs out of thread
                                // rather than driving its point into the
                                // flange's end wall

// Where the nut sits, and therefore how deep the head has to be buried for a
// standard length to come out right. Derived, so the BOM cannot drift.
// It stacks above the ridge groove, centred in what flange is left over it.
// The nut sits a fixed distance ABOVE THE GROOVE, not halfway up the flange.
// Halfway is what it was, and it meant the room left for the screw's tip rose
// and fell with ext_roof instead of being something you could set. Pinning it
// to the groove leaves the whole rest of the flange as tip clearance.
lock_nut_below = 3.5;           // flange between the groove and the nut
lock_nut_z     = ridge_groove_top + lock_nut_below + lock_nut_h / 2;
lock_nut_top   = lock_nut_z + lock_nut_h / 2;

// The head seats on a FLAT annular ledge, not on a cone.
//
// It was a cone, on the reasoning that a flat ledge would be printed over air.
// That was over-cautious: the ledge is only (lock_cbore_d - lock_hole) / 2 =
// 1.4 mm wide, a trivial overhang anchored all the way round its outer edge.
// And the cone's cost is severe — the head touches it on a LINE rather than a
// face, so a steel head under any torque at all digs straight into the PETG and
// the screw walks in further than it should.
//
// Flat, the head bears on about 14 mm^2. At a sane snug (~100 N) that is 7 MPa,
// which PETG holds; the cone was effectively unbounded.
lock_seat_up   = 0;             // flat: the head seats where the ledge is

// Where the head's top face actually lands, and therefore where the tip does.
// The old form put the seat at the cone's START and so reported the tip about
// half a millimetre high — small, but it fed the "flange left above the tip"
// margin, which is the number that says whether the screw bursts out of the top.
lock_seat_z    = lock_nut_top + lock_engage - lock_len;
lock_cbore_h   = lock_seat_z - lock_seat_up;    // where the cone starts
lock_tip_z     = lock_seat_z + lock_len;        // must stay under ext_h

// ---- Load case -------------------------------------------------------------
// 3 kg hung at the helmet cradle's tip. Measured off the exported mesh by
// tools/strength.py; kept here so the ridge sizing below cannot drift from it.
load_M         = 2950;  // N.mm at the mounting face

// ---- Render quality --------------------------------------------------------
$fn = $preview ? 40 : 96;
