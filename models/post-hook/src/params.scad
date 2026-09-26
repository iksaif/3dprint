// ---------------------------------------------------------------------------
// post-hook — every dimension, in mm.
//
// A single-piece PETG clip that presses onto a 40 x 40 post from one face, with
// three flat TPU pads that do the gripping. One hook, ~1 kg, no screws.
//
// DATUM: the POST's centreline. x and y are measured from the post's axis, so
// x = +/- post_w/2 and y = +/- post_d/2 are its four faces. z = 0 is the bed.
//
// THE ONE IDEA THIS MODEL IS BUILT ON: print Z is the post's own axis.
//
// That single choice makes the whole clip printable. Everything that wraps the
// post — arms, snap lips, lead-in ramps, the undercut that retains it — lies in
// the (x, y) plane, so it is a PRISM along print Z and is support-free by
// construction, whatever shape it is. Undercuts, which are what normally makes
// a snap-fit unprintable, are free here because they run sideways rather than
// up. There is no orientation in which a C that wraps a post AND a hook that
// curls up are both prisms, so the hook pays instead: it is a gusseted bracket
// whose underside is a 48 deg slope (see hook_rake).
//
// WHY THERE IS NO SCREW. The helmet-holder next door clamps with two M4s
// because it must hold 3 kg on a 100 mm arm — 2950 N.mm. This holds 1 kg in a
// cradle 11 mm off the post: 108 N.mm, a factor of 27 less. At that load the
// clamping force needed is small enough for a printed spring to supply it, and
// once a spring can supply it the screw is just a part to lose.
// ---------------------------------------------------------------------------
include <../../../lib/scad/print.scad>

// ---- The post ---------------------------------------------------------------
// post_w is the axis the ARMS grip (they flex in x, so tolerance here is
// absorbed by the spring and costs nothing but a little preload).
// post_d is the axis the LIPS capture, and that one is rigid — the lip face and
// the back pad are two hard surfaces a fixed distance apart. So post_d is the
// measurement to get right, and post_d_min/max are what the teeth must absorb.
post_w         = 40;
post_d         = 40;
post_d_min     = 39.5;
post_d_max     = 40.5;
// THE CORNER RADIUS IS A REAL DESIGN INPUT, not decoration for the mock post.
// The lips' cam faces are shaped tangent to it (see cam_c), so this number
// decides whether the clip seats at all — and it is asymmetric in a way that is
// worth spelling out.
//
// Designing for r_design against a post that really has r_actual, the cam
// clears the corner iff r_actual >= r_design. The algebra collapses neatly:
// both the tangent constant and the arc's centre move with r, and the condition
// reduces to 0.586 * r_actual >= 0.586 * r_design. So:
//
//   post rounder than designed  ->  a little slack, which the arms simply close
//                                   up and the pads' crests absorb
//   post SQUARER than designed  ->  the cam drives into the corner and the clip
//                                   will not seat without permanently spreading
//                                   the arms
//
// One of those is a nuisance and the other is a part that does not fit. So this
// must be set to the SMALLEST radius the post might have, never the average and
// never a guess on the high side. It was 3 — a plausible figure for rolled
// steel tube — against posts that are actually all but square, which would have
// jammed both lips by 0.8 mm.
post_corner_r  = 0.5;   // measured: these posts are near enough square

// ---- TPU pads ----------------------------------------------------------------
// Three FLAT slabs — one for the back wall, two for the arms — printed lying
// down. Thin, and with no teeth.
//
// It was a standing U with a sawtooth face, and the first physical test killed
// both halves of that.
//
// THICKNESS. pad_t is 1.2, down from 3.0, because it does not need to be thick:
// its job is mu, not bulk. The thing that has to be thin was never the pad
// anyway — see preload, where the real error was.
//
// FLAT, not toothed. At 1.2 mm the old 0.8 mm teeth would be two thirds of the
// part, leaving a 0.4 mm base: not a pad with teeth, a row of triangles joined
// by a film. But the better reason is grip. Elastomer friction is not
// Amontons' — it has an adhesive component that scales with REAL CONTACT AREA,
// so concentrating the same normal force into a few tooth crests trades contact
// away for pressure. That trade only pays when you need to bite into something
// rough; against a smooth painted post, full flat contact grips harder.
//
// Flat also kills an assembly trap that nothing on the part warned about: a
// sawtooth is directional twice over — which face goes to the post, and which
// end is up — and fitted upside down its steps resist the one direction that
// does not matter.
//
// What it costs is the teeth's compliance, which used to absorb post_w
// tolerance by crushing. That now comes out of the preload margin instead,
// which is why preload is 1.0 rather than the 0.6 the grip alone would need.
pad_t          = 1.2;   // 6 layers. 0.8 works too if you want less still.
pad_margin     = 3;     // pads shorter than the collar, top and bottom
// Side pads stop this far short of the post's front face. Not cosmetic: they
// have to end BEHIND where the lip's cam face leaves the arm (y_cam_start), or
// pad and lip occupy the same millimetre and the fit check lights up.
pad_front      = 4;
// How long the SIDE pads are, and the reason they are short and forward rather
// than running the length of the arm.
//
// A cantilever's deflection at its root is zero. The deflection available at a
// distance u along it is cant_shape(u/L) of the tip's, and that falls away
// fast: at a tenth of the way along it is under 2%. The side pads used to start
// 3 mm from the root, where supplying 1 mm of interference would have needed
// over 100 mm of tip deflection. The post was not being gripped back there — it
// was jamming on something that could not open, whatever the arm's stress said.
//
// So the interference lives only where there is compliance to supply it. Behind
// the pads the arm's own inner face clears the post by pad_t - preload and
// touches nothing.
pad_side_len   = 12;
pad_clear      = 0.5;   // off the collar's inner corner fillets
pad_corner_r   = 2;     // plan rounding, so they are pleasant to handle

// ---- The collar ---------------------------------------------------------------
// collar_h is the arms' second moment (I scales with it, so preload force does
// too) and the couple arm that reacts the hook's moment. It is not set by the
// post: 36 is where the arms are stiff enough and the part still reads as a
// clip rather than a block.
collar_h       = 36;
back_t         = 6.0;   // back wall — rigid; it reacts both arms' moments
arm_t          = 3.6;   // THE SPRING. 8 perimeters at 0.45. See springcheck.py:
                        // this number sets grip, insertion force and strain all
                        // at once, and it is the only one that sets all three.
// Rounding on the collar's outline. corner_r rounds the convex corners and
// fillet_r fills the concave ones. corner_r is 1.5 and not the 2.5 the eye
// would like, because the lip's crest is only lip_flat = 2 mm long and a
// convex rounding of r takes r off each of its ends — at 2.5 the crest the
// post actually bears on stops existing.
corner_r       = 1.5;
// 2.5, not 1.0, and this is the one rounding in the model that is structural
// rather than cosmetic. The arms are pushed OUTWARD by the post, so at the root
// the tension face is the one opposite the load — the inner, cavity-facing
// surface — and this is the fillet on it. The outer corners are on the
// compression side, and a convex corner concentrates nothing anyway, so making
// those rounder buys no strength.
//
// It matters more than the size suggests. At 1.0 the stress concentration is
// about 1.55, which put the peak stress while fitting at 42 MPa against PETG's
// ~50: a margin of 1.18. At 2.5 it is 1.33 and 36 MPa, a margin of 1.38, for no
// change in stiffness, grip or insertion force. Past ~2.5 it flattens out.
//
// Thickening the arm is NOT the alternative, and it is worth being clear why:
// this spring is deflection-controlled, not force-controlled. sigma = E * 3 t d
// / (2 L^2) is proportional to t, so a thicker arm carries MORE root stress at
// the same imposed deflection, not less. The levers are the fillet, a longer
// arm, or less preload.
fillet_r       = 2.5;
chamfer        = 0.8;   // top and bottom edge chamfer. Must stay under
                        // lip_reach/2 or chamfered_extrude erodes the lip away.

// preload is how far each arm is sprung open when the clip is on the post, and
// therefore what generates the friction that stops it sliding down. It is set
// by geometry alone: the arms' unloaded inner faces are 2*preload closer
// together than the post plus its pads.
// 0.5. This has now been wrong twice, in two different ways, and both are worth
// keeping because they are different mistakes.
//
// The opening a post has to be forced into is post_w - 2 * preload — pad_t
// cancels out of it entirely — so 2.5 meant presenting a 35 mm mouth to a 40 mm
// post and springing each arm 2.5 mm to get it on. That is 36 MPa at the arm
// root, and it snapped.
//
// It was sized from a friction budget that deliberately left out the load's own
// moment as "conservative". That was the mistake: the moment is not a bonus,
// it is where most of the grip comes from. A load hung off the hook presses the
// back pad and the lips into the post with about 15 N each, worth ~13 N of
// friction on its own — which is why the clip nearly held a helmet with NO pads
// and no preload at all.
//
// So the preload only has to top that up to a sane margin.
//
// SECOND, at 1.0 it was still assuming the arm could supply that interference
// everywhere the pad touched. It cannot — see pad_side_len. With the pads moved
// to the compliant end of the arm the contact sits around 0.76 of the way
// along, where the arm is (1/0.76)^3 = 2.3x stiffer than at its tip, so half
// the interference gives more force than 1.0 mm did before.
preload        = 0.5;

// ---- The snap lips -------------------------------------------------------------
// Each arm ends in a lip that reaches inward past the post's front face.
//
// THE RETENTION FACE IS A CAM TANGENT TO THE POST'S CORNER (lip_cam, below), and
// getting there took three wrong answers worth recording.
//
// It began as a square face sitting y_squeeze inside the post's nominal front,
// with the catch quoted as lip_reach - preload. Both halves were wrong:
//
//  1. The preload does not eat the reach; the LINER does. Seated, the arm's
//     inner face is always exactly pad_t off the post — that is what seated
//     means, the crests are touching — so the overlap is lip_reach - pad_t
//     whatever the preload. The preload only sets how far the arm must spread
//     to get there.
//  2. Far worse, and invisible in every render: the post's corners are ROUNDED.
//     A square face 0.5 mm in front of the nominal front face meets a post that
//     at that depth is only 18.7 mm half-wide, not 20. The lip reached to 18.0
//     and caught 0.3 mm over a 0.7 mm strip. The clip would have slid off in
//     the hand.
//
// Neither survived contact with springcheck.py, which renders the lips where
// they SIT and intersects them with the post: the intersection came back empty.
//
// The fix is to stop pretending the corner is square and shape the lip to it. A
// face tangent to the corner arc bears on it along a line the full height of
// the collar, and it makes the capture elastic rather than rigid: the arms'
// inward force resolves on the inclined face into a component that drives the
// post BACK against the back pad, so it clamps itself fore and aft and there is
// nothing left to rattle. That is why y_squeeze is gone.
//
//  3. That face was 45 deg, and the load's own moment could open it — see
//     lip_cam. springcheck.py now checks the lips against the load as well as
//     against a straight pull.
// DERIVED from the catch, not set directly. The two are tied — what actually
// overlaps the post is lip_reach - pad_t — and when lip_reach was a literal
// that coupling went quiet: thinning the pads from 3.0 to 1.2 deepened the
// catch from 2.0 to 3.8 mm without anyone asking, which took the spread an arm
// has to survive from 2.5 to 4.8 and the root stress from 20 MPa to 39.
//
// Stated this way round, changing the pad moves the lip with it and the catch
// stays what it says it is.
lip_catch      = 1.5;   // what actually overlaps the post, seated
lip_reach      = pad_t + lip_catch;   // inboard of the arm's inner face
lip_flat       = 2.0;   // crest length in y, past the cam face
// The angle of the retention face's NORMAL away from the insertion (y) axis:
// 0 would be a square face, 45 the old cam. It sets the ratio in which a load
// pressing the lip onto the post's corner is turned into outward push on the
// arm — tan(lip_cam - friction angle).
//
// 25, not 45. The 45 deg cam was chosen so a straight pull would release the
// clip, and because a square face could not catch an r3 corner. Neither holds
// now: the thumb tabs are the release, and the posts are near square. What 45
// cost was the one load case nothing checked — the load's OWN moment. It
// presses the lip tops into the post's front corners, and at 45 deg about 60%
// of that came back as outward push on the arm tips: 0.85 mm of a 1.26 mm
// catch at 1 kg static, which a helmet dropped onto the hook would have
// doubled. At 25 deg it is 0.19 of the push.
//
// The price is that a straight pull no longer removes it — about 5x the force.
// Squeeze the tabs.
lip_cam        = 25;
lip_clear      = 0.0;   // off the corner arc. Zero on purpose: the arms should
                        // arrive already bearing on the corners, since that
                        // contact is what pulls the post onto the back pad.

// The lead-in ramp is the whole of the insertion mechanism: it converts the
// push into arm spread at tan(lead_angle). Shallower is easier to press on and
// longer in y. 30 deg gives a 0.58 ratio and an 8.7 mm ramp — 35 was 8.0 kgf of
// push, which is a two-handed shove rather than a click.
lead_angle     = 30;

// A stub of arm forward of the lead-in ramp, to carry the tie slot. The ramp is
// lip_reach / tan(lead_angle) long, so shrinking the lip shortens the arm's
// front end with it — at lip_reach 2.7 the slot no longer had min_wall in front
// of it and the assert below caught it. This decouples the two.
arm_nose       = 3;

// Thumb tabs: the arms flare outward over the last stretch so there is
// something to pull on. A prism in z like everything else here, so free.
tab_out        = 4;
// Back to 9. It was cut to 5 so a guide channel could reach forward past the
// slots before the thumb tab flared; that channel is gone, and with nothing
// else asking for a short tab, the length that matters is the one a thumb
// actually bears on.
tab_len        = 9;

// ---- Cable-tie slots ---------------------------------------------------------
// One slot through each lip, so a nylon tie can be added when the spring alone
// is not enough — a heavier load, a post with a slippery finish, a clip that
// has taken a set after a year outdoors.
//
// THE LOOP STAYS AT THE OPENING END. In one slot, across the post's exposed
// face, out the other slot, then closed back across the outside of the two
// thumb tabs: a small loop around the two lips and nothing else. It does not
// wrap the whole clip and never goes near the hook, so the buckle sits behind
// the clip as you look at the hook, out of the way.
//
// It is also the stronger of the two routings, which is luck rather than the
// reason: both runs bear on the arm TIPS, the far end of the spring, so a given
// tie tension buys the most closing force it can. A loop round the whole clip
// would spend much of its tension squeezing the back wall, which is rigid and
// does not need it.
//
// The slots go through the LIPS and not the arms proper for two reasons: the
// arms are the spring and a hole through a bending beam is a stress riser
// exactly where the strain peaks, and a tie emerging anywhere behind the post's
// front face has nowhere to go but into the post.
//
// The slot is not a teardrop. Its ceiling is a 45 deg peak instead, which is
// strictly self-supporting rather than merely a short bridge, and it costs one
// extra point in the polygon.
tie_slot       = true;
tie_w          = 5.4;   // along z: a 4.8 mm tie plus clearance
tie_t          = 2.2;   // along y: a 1.3 mm tie doubled, plus clearance

// Mid-height. It was 24, pushed up there because the tie's return run used to
// wrap the whole clip and had to clear the hook stem where it leaves the wall.
// The tie no longer goes anywhere near the hook, so that constraint is gone and
// the band belongs in the middle, where it pulls the two arms together evenly
// instead of cocking them.
tie_z          = collar_h / 2;

// ---- Derived collar geometry ----------------------------------------------
hw_in          = post_w / 2 + pad_t - preload;   // arm inner face, unloaded
x_out          = hw_in + arm_t;                    // arm outer face
y_back_in      = -(post_d / 2 + pad_t);          // back wall inner face
y_back_out     = y_back_in - back_t;               // ... and outer: the hook's root
// The cam face lies on the line x sin(a) + y cos(a) = cam_c, with a = lip_cam,
// tangent to the post's corner arc (centred at post_w/2 - r, post_d/2 - r) once
// the arms are sprung. Its unit normal is (sin a, cos a), so the tangent
// constant is just the arc centre projected onto it plus the radius — and a
// post with a different corner reshapes the lip instead of silently
// un-catching it, which is exactly how the first square face failed.
//
// It was written as x + y = c while the angle was fixed at 45; that form hid
// the angle in a sqrt(2), and changing lip_cam would have changed nothing.
cam_sin        = sin(lip_cam);
cam_cos        = cos(lip_cam);
cam_c          = (post_w / 2 - post_corner_r) * cam_sin
               + (post_d / 2 - post_corner_r) * cam_cos
               + post_corner_r + lip_clear;
cam_c_unl      = cam_c - preload * cam_sin;        // ... where it is DRAWN
y_cam_start    = (cam_c_unl - hw_in * cam_sin) / cam_cos;   // leaves the arm face
y_crest0       = y_cam_start + lip_reach * cam_sin / cam_cos; // meets the crest
y_lip_end      = y_crest0 + lip_flat;              // end of the crest
lead_len       = lip_reach / tan(lead_angle);
y_ramp_top     = y_lip_end + lead_len;      // where the lead-in meets the arm
y_arm_end      = y_ramp_top + arm_nose;

// Where the crest lands once seated, and the point where the face touches the
// arc. The crest must be INBOARD of that point or the face never reaches the
// arc at all.
x_crest_seated = hw_in + preload - lip_reach;
x_arc_touch    = post_w / 2 - post_corner_r + (post_corner_r + lip_clear) * cam_sin;

// Release travel: how far the arms must spread for the crest to clear the
// post's widest point. Squeezing the thumb tabs is what supplies it.
lip_release    = post_w / 2 - x_crest_seated;

// Anchored to the END of the crest, because everything behind it is either cam
// face or post.
tie_y          = y_lip_end + tie_t / 2 + 0.4;

// Arm free length for the spring calculation: root at the back wall's inner
// face, tip at the middle of the cam face, which is where the post bears.
// Everything springcheck.py says depends on this.
arm_free       = y_cam_start + lip_reach / 2 - y_back_in;

// How far the arm's TIP is spread at the worst moment of insertion: the lip's
// crest, unloaded at hw_in - lip_reach, has to clear the post's side face at
// post_w/2. This is the strain the part has to survive, and it is NOT
// preload + lip_reach — hw_in already has the preload built into it, so adding
// it again double-counts. It is also not additive with the pads: mid-arm the
// post only asks for preload, less than this, so the tip governs and the arm
// simply bends into a curve.
spread_peak    = post_w / 2 - (hw_in - lip_reach);

// ---- Derived pad geometry ---------------------------------------------------
// In params and not in clip.scad, because main.scad and the checkers `use`
// clip.scad — and `use` imports modules but NOT variables, so anything derived
// over there reads as undef from here. That is the repo's oldest trap.
pad_h          = collar_h - 2 * pad_margin;          // along the post
pad_z          = (collar_h - pad_h) / 2;             // centred in the collar

// The back pad stops clear of the collar's inner corner fillets, which bulge
// into the cavity by fillet_r. Sitting a flat pad across one would rock it.
pad_back_w     = 2 * (hw_in - fillet_r - pad_clear);

// The side pads are anchored at their FRONT end and run back pad_side_len, so
// they sit on the compliant end of the arm rather than at the rigid root.
pad_side_y1    = post_d / 2 - pad_front;
pad_side_y0    = pad_side_y1 - pad_side_len;
pad_side_w     = pad_side_len;

// Tip-loaded cantilever deflection shape: the fraction of the TIP's deflection
// available at a fraction r of the way along. This is the curve that makes a
// full-length pad impossible and a short forward one fine.
function cant_shape(r) = (3 * r * r - r * r * r) / 2;
pad_r0         = (pad_side_y0 - y_back_in) / arm_free;   // pad's back edge
pad_r1         = (pad_side_y1 - y_back_in) / arm_free;   // ... and its front
pad_shape      = cant_shape(pad_r0);      // the worst point on the pad
pad_r_mid      = (pad_r0 + pad_r1) / 2;

// ---- The hook ------------------------------------------------------------------
// A stem rising out of the back wall at hook_rake, with an upturn at the end
// leaning back over it. A load slides DOWN the stem and settles in the V
// against the post; to escape it has to climb back up the stem and over the
// upturn.
//
// BOTH of the stem's surfaces are raked, and that is the whole design. The
// first version of this hook had a nearly flat shelf carried on a 48 deg
// gusset, which is the shape you draw if you think of the rake as a
// printability tax. It is not: the rake IS the hook. A flat shelf needs its
// gusset to fall the full reach x tan(rake) beneath it, which at any useful
// reach swallows the entire collar height and leaves a shallow notch at the top
// instead of a cradle. Raking the top surface too costs one line, deletes the
// gusset, halves the plastic, drops the V to where a load can be lifted in, and
// turns the part back into the J the brief asked for.
//
// hook_rake is the only number printability constrains — the stem's underside
// is the one surface in this model that is not a prism along print Z. 50 deg
// from horizontal, not 45: the repo has already learned once that 45 exactly is
// the limit itself and has no margin.
// THREE SIZES, off one collar. The collar is the hard part and it does not
// change; only the profile swept across it does, so a size is four numbers in a
// table and every size gets the same fit, the same checks and the same plate.
//
//     name  reach  stem_t  tip_h  width
//
// They are not the same hook scaled. What separates them in use is the MOUTH —
// the gap a load has to pass through between the collar's top back corner and
// the upturn's leaning face — and it grows much faster than the reach does,
// because on the small size the collar's own back wall is TALLER than the hook
// and walls the entry off. `dims` reports it per size for exactly that reason:
//
//     s   7.7 mm mouth   cord, strap, cable loop, a lanyard
//     m  13.1 mm         the general one: bag handle, helmet strap, hose
//     l  17.6 mm         a thick handle, a coiled extension lead
// m is 22 and not 20 because the stroke cost it mouth: a rounded tip is fatter
// near its top than the old polygon's straight lean, which took m from 13.1 mm
// down to 9.3. Two more mm of reach buys it back. The mouth is the number these
// are tuned on, not the reach.
hook_sizes = [
    ["s", 16,  7,  9, 12],
    ["m", 22,  9, 10, 16],
    ["l", 26, 11, 13, 20],
];
function size_idx(n) = [for (i = [0 : len(hook_sizes) - 1])
                            if (hook_sizes[i][0] == n) i][0];
function hk_reach(s)  = hook_sizes[s][1];
function hk_stem_t(s) = hook_sizes[s][2];
function hk_tip_h(s)  = hook_sizes[s][3];
function hk_w(s)      = hook_sizes[s][4];

hook_rake      = 50;    // both stem surfaces, from horizontal. Shared: it is a
                        // printer limit, not a size choice.
stem_z         = 4;     // the stem's underside where it leaves the wall
tip_t          = 5;     // upturn thickness at its base — sets where it leaves
                        // the stem, and so the cradle's length
tip_lean       = 20;    // degrees from vertical, leaning back over the cradle
hook_chamfer   = 0.8;   // on the hook's two side faces

// ---- The hook's section: a stroke, not a polygon ----------------------------
// The profile is a chain of hulled circles through three stations — root, knee,
// tip — with the radius shrinking along it. lib/scad/shapes.scad calls this the
// cheapest way to draw an organic profile that stays printable, and both halves
// of that are the reason it is used here:
//
//  * ORGANIC. The boundary is arc-line-arc through every station, so it is
//    tangent-continuous by construction. There is no corner anywhere to
//    concentrate stress, and none of it is a fillet bolted onto a polygon — the
//    radius at each station simply IS the local half-thickness. The first
//    version of this hook was a six-point polygon with 1.5 mm rounding, and it
//    had a sharp re-entrant corner at the foot of the upturn, which is exactly
//    where a strap bears and where a crack would start.
//  * PRINTABLE. Consecutive circles are hulled, so the shape is convex between
//    stations and has no re-entrant surprises, and a shrinking radius tilts the
//    underside tangent STEEPER than the centreline rather than shallower.
//
// The one thing a stroke does badly is its own end. A circle's underside goes
// horizontal at its lowest point, so the root station bulges out of the wall
// with a surface that flattens to 20 deg just as it leaves — a real overhang,
// and one no other check would fail. The profile is therefore clipped against
// the rake line (stem_bot_at), which is at hook_rake by definition: the bulge
// goes, the underside leaves the wall as a straight 50 deg line, and everything
// above it stays as drawn.
hook_taper_knee = 0.78;  // radius at the knee, as a fraction of the root's
hook_taper_tip  = 0.48;  // ... and at the tip. Floored by the side chamfer:
                         // 2*r*taper must stay clear of 2*hook_chamfer.

// The CENTRELINE curls too, and it has to be made to. Three stations alone give
// a centreline that goes straight up the stem, turns a hard corner at the knee
// and runs straight to the tip — the tip is by construction exactly tip_h/cos
// along the lean direction from the knee, so the tangents there are collinear
// and the "curve" is a corner. All that rounds it is the knee circle's own
// radius, which is why the first stroke still read angular.
//
// So the corner is replaced by a quadratic Bezier: leave the stem hook_curl x
// tip_h before the knee, use the knee as the control point, and arrive at the
// tip already pointing along the lean. Sampled into hook_curl_n stations, which
// the stroke then hulls into one continuous sweep.
//
// It stays printable for the same reason the straight version did, and the
// margin is easy to see: through the curl the centreline heading rotates from
// hook_rake off vertical to tip_lean the other way, so the OUTER flank only
// ever gets steeper than the rake, and the INNER flank's worst overhang is at
// the tip, at tip_lean plus the few degrees the shrinking radius adds.
hook_curl      = 0.7;    // how far back down the stem the curl starts, x tip_h
hook_curl_n    = 5;      // stations sampled along it

// ---- Where the hook meets the collar ----------------------------------------
// The stroke smooths the hook's own outline, but it says nothing about the
// junction with the wall, and that junction is where the load actually goes in.
// It came out as four sharp concave corners — two in the side profile, where
// the stem's top and underside run into the wall face, and two in plan, where
// the hook's side faces do. Filleted separately, because they lie in different
// planes and are made in different ways:
//
//   wall  in the (y, z) profile. Made by unioning the wall into the profile,
//         applying a CLOSING (dilate then erode, which fillets concave corners
//         and leaves convex ones alone), then cutting the wall back out. The
//         top one is the V a strap actually bears in, so it is the one worth
//         having; the bottom one is the compression side.
//   side  in plan. A true radius tangent to the wall face and to the hook's
//         side face, swept up through the hook's own profile so it follows the
//         stem's rake instead of standing on the bed.
//
// Both stay printable for the same reason: a prism in z (the side fillet) is
// free by construction, and the wall fillet's arc runs from vertical at the
// wall to tangent with the 50 deg rake, so every part of it is steeper than the
// rake it blends into.
hook_wall_fillet = 2.5;  // in the side profile. Under half the mouth, or the
                         // closing would start filling the cradle itself.
hook_side_fillet = 3.0;  // in plan, where the sides meet the wall
// The hook's root reaches INTO the back wall rather than stopping on its face.
// Two solids that meet on a coincident plane are watertight and still export as
// two shells; mesh.py counts shells, and this is the cheapest way to never see
// it fail. 1.5 of a 6.0 wall.
hook_embed     = 1.5;

// ---- Derived hook geometry ------------------------------------------------
// Everything is measured from the back wall's OUTER face, which is where the
// reach and the rake are quoted from. The profile then runs hook_embed further
// back than that, into the wall, and both stem surfaces simply extrapolate.
hk_root_y      = y_back_out + hook_embed;      // the profile's back edge
function hk_tip_y(s)    = y_back_out - hk_reach(s);   // the tip's outer face
function tip_base_y(s)  = hk_tip_y(s) + tip_t;        // where the upturn leaves
// How far the tip's centre leans back over the cradle on its way up.
function tip_lean_y(s)  = tip_base_y(s) + hk_tip_h(s) * tan(tip_lean);

// The rake line: the stem's underside, and the line the profile is clipped
// against so that the root station's circle cannot bulge below it.
function stem_bot_at(y)    = stem_z + (y_back_out - y) * tan(hook_rake);
function stem_top_at(s, y) = stem_bot_at(y) + hk_stem_t(s);

// ---- The three stroke stations, as [y, z, radius] --------------------------
// The centreline runs up the middle of the stem at hook_rake, turns at the knee
// and leans back to the tip. The radius is the local HALF-THICKNESS, so the
// taper is stated directly rather than drawn.
function r_root(s) = hk_stem_t(s) / 2;
function r_knee(s) = r_root(s) * hook_taper_knee;
function r_tip(s)  = r_root(s) * hook_taper_tip;

// Root: on the centreline, extrapolated back into the wall by hook_embed.
function c_root(s) = [hk_root_y, stem_bot_at(hk_root_y) + r_root(s)];
// Knee: where the upturn leaves the stem.
function c_knee(s) = [tip_base_y(s), stem_bot_at(tip_base_y(s)) + r_root(s)];
// Tip: straight up from the knee, leaning back over the cradle.
function c_tip(s)  = [tip_lean_y(s), c_knee(s)[1] + hk_tip_h(s)];

// Unit headings: up the stem at the rake, and up the upturn at the lean.
d_stem         = [-cos(hook_rake), sin(hook_rake)];
d_tip          = [ sin(tip_lean),  cos(tip_lean)];

// The curl: a quadratic Bezier that leaves the stem, uses the knee as its
// control point and arrives along the tip's heading.
function curl_p0(s) = c_knee(s) - hook_curl * hk_tip_h(s) * d_stem;
function bez(p0, p1, p2, t) =
    pow(1 - t, 2) * p0 + 2 * (1 - t) * t * p1 + pow(t, 2) * p2;

// n stations along the curl, radius tapering from the knee's to the tip's.
function hk_curl_pts(s, n) = [
    for (i = [0 : n - 1])
        let (t = i / (n - 1), p = bez(curl_p0(s), c_knee(s), c_tip(s), t))
        [p[0], p[1], r_knee(s) + t * (r_tip(s) - r_knee(s))]
];

function hk_stations(s) =
    concat([[c_root(s)[0], c_root(s)[1], r_root(s)]], hk_curl_pts(s, hook_curl_n));

// The same chain sampled finely. Only the mouth uses it — measuring a gap off
// 5 stations reads whatever the sampling happens to land on.
function hk_dense(s) =
    concat([[c_root(s)[0], c_root(s)[1], r_root(s)]], hk_curl_pts(s, 40));

function hk_tip_top(s) = c_tip(s)[1] + r_tip(s);

// Usable cradle: the raked stem between the collar's back face and the upturn.
function cradle_len(s)  = y_back_out - tip_base_y(s);

// How far a load has to be lifted out of the V to clear the upturn — the
// retention, in one number.
function cradle_lift(s) = hk_tip_top(s) - stem_top_at(s, y_back_out);

// The MOUTH: the gap a load has to pass through to get in at all, between the
// collar's back face and the hook's inner boundary, taken at whichever is lower
// of the collar's top and the upturn's top — that is the pinch point.
//
// Three cases, and getting the wrong one is how you report a generous mouth on
// a hook nothing fits into. Above the tip station it is the tip's own arc;
// between knee and tip it is the flank of the knee-to-tip capsule; below the
// knee the upturn is not in the way at all and the pinch is the stem's top.
//
// The middle case interpolates centre and radius along the capsule rather than
// solving its true tangent line, which reads a few tenths pessimistic. That is
// the right direction for a number whose only jobs are to be reported and to
// back an assert.
// Measured off the stroke itself rather than solved: at the pinch height, take
// every densely-sampled station whose circle reaches that height and keep the
// one that intrudes furthest toward the post. With the centreline curled there
// is no longer a formula for the inner flank worth writing, and sampling the
// circles is both simpler and honest about what the shape actually is. It reads
// a shade pessimistic — the tangent lines between circles bulge very slightly
// less than the circles themselves — which is the right direction here.
function mouth_z(s)  = min(collar_h, hk_tip_top(s));
function hk_inner_y(s, z) =
    max([for (p = hk_dense(s))
            if (abs(z - p[1]) < p[2]) p[0] + sqrt(pow(p[2], 2) - pow(z - p[1], 2))]);
function mouth(s) =
    let (z = mouth_z(s), inner = hk_inner_y(s, z))
    is_undef(inner) || inner == -1e9
        // Nothing of the hook reaches the pinch height, so the stem's top face
        // is what a load grazes on the way in.
        ? (z - stem_z - hk_stem_t(s)) / tan(hook_rake)
        : y_back_out - inner;

// A load slides down the rake and settles in the V at the wall, so the moment
// arm is a fraction of the reach. Taken as mid-cradle, which is pessimistic:
// this is the arm every margin here is quoted against, and it is why the hook
// needs no strength check of its own.
function load_arm(s) = cradle_len(s) / 2;

// ---- Bounding corners, for the plates ---------------------------------------
// OUTER bounds, from the geometry, rather than numbers copied out of bbox.py.
// The copied ones went 1.8 mm stale the first time the lip changed. These are
// meant to be no smaller than the real part, so a plate laid out on them can
// leave a little extra gap but never overlap two parts. The hook's fillet
// offsets overshoot the stroke's own circles by a few hundredths, which is why
// there is a 0.5 mm margin rather than none — checked against bbox.py.
clip_x_half    = x_out + tab_out;
function clip_min(s) =
    [-clip_x_half,
     min(y_back_out, min([for (st = hk_stations(s)) st[0] - st[2]])) - 0.5,
     0];

// ---- Load case -------------------------------------------------------------
// 1 kg is the brief. Everything is reported against it directly and the margins
// are stated rather than baked in, because the margin on the FRICTION is the
// one that decides whether this design works at all — the plastic is nowhere
// near its limit and the spring is nowhere near its strain.
load_kg        = 1.0;
mu_tpu         = 0.6;   // TPU on painted steel, deliberately pessimistic
                        // (0.7-1.0 is the usual range)
mu_petg        = 0.25;  // and bare PETG, where the lips bear on the post

// The load's own moment is NOT a bonus — it is where most of the grip comes
// from, and leaving it out of the budget is what oversized the preload by 4x
// and broke the first print. A load on the hook presses the back pad and the
// lips into the post as a couple; couple_frac is how far apart those two
// contacts act, as a fraction of the collar's height. 2/3 is a judgement, not a
// measurement, and it is the softest number in springcheck.py — but the clip
// nearly holding a helmet with no pads and no preload at all says the mechanism
// is real and roughly this size.
couple_frac    = 0.67;

// ---- Asserts ---------------------------------------------------------------
// The failure modes that are invisible in a render, checked in source.
// The two that the square-faced lip would have failed, had they existed. The
// first is the whole lesson: the crest has to reach past the point where the
// face touches the corner arc, or the face floats clear and catches nothing.
assert(x_crest_seated < x_arc_touch,
       "seated lip crest sits outboard of where the face meets the corner — it catches air");
assert(lip_cam > 0 && lip_cam < 60, "lip_cam outside the range the tangent maths assumes");
assert(lip_release > 1.0,
       "less than 1 mm of straight-pull travel holds the clip on");
assert(pad_side_y1 < y_cam_start,
       "the side pads run into the lip's cam face");
// The one the first print actually failed on. A pad reaching back to where the
// arm cannot deflect does not grip there, it jams there.
assert(pad_shape > 0.4,
       str("side pads reach back to ", pad_r0,
           " of the arm, where only ", pad_shape,
           " of the tip's deflection is available — shorten pad_side_len"));
assert(pad_side_y0 > y_back_in + fillet_r + pad_clear,
       "the side pads reach into the collar's inner corner fillet");
assert(hook_rake > max_overhang_angle,
       "stem underside is shallower than the printer's overhang limit");
// An oversize post pushes the cams and spreads the arms a little further while
// seated — the cams make the post_d axis elastic, so nothing has to crush.
// Measured against the spread FITTING already demands, not against the preload
// — the preload is a different axis and comparing the two says nothing.
assert((post_d_max - post_d) * tan(lip_cam) < spread_peak,
       "an oversize post costs more arm travel than fitting the clip does");
assert(pad_t - preload > 0, "pad is thinner than the interference it sets");
assert(chamfer * 2 < lip_reach,
       "chamfered_extrude erodes by `chamfer`; the lip would vanish");
assert(corner_r < lip_flat, "the lip's crest would be rounded away entirely");
assert(hk_root_y < y_back_in, "hook root reaches through the back wall");
assert(stem_bot_at(hk_root_y) > chamfer,
       "stem root, extrapolated into the wall, lands below the bottom chamfer");

assert(!tie_slot || tie_y - tie_t / 2 > post_d / 2,
       "the tie slot opens into the post's front face instead of clearing it");
assert(!tie_slot || tie_z + tie_w / 2 < collar_h - chamfer,
       "the cable-tie slot breaks out of the collar's top");
assert(!tie_slot || tie_y + tie_t / 2 + min_wall < y_arm_end,
       "the tie slot breaks out of the arm's front end");

// Per size, because a table is exactly the place a bad row hides. `l` is the
// row that tests the reach and `s` the one that tests the mouth.
for (i = [0 : len(hook_sizes) - 1]) {
    assert(cradle_len(i) > 8,
           str("size ", hook_sizes[i][0], ": cradle too short to hang anything in"));
    assert(mouth(i) > 5,
           str("size ", hook_sizes[i][0], ": mouth too narrow to get a load into"));
    assert(cradle_lift(i) > 12,
           str("size ", hook_sizes[i][0], ": upturn too low to retain a load"));
    assert(hk_w(i) > 2 * hook_chamfer + 2,
           str("size ", hook_sizes[i][0], ": too narrow to survive its own chamfer"));
    // chamfered_extrude erodes the profile by hook_chamfer before extruding, so
    // the thinnest station — the tip — has to be wider than twice that or the
    // end of the hook simply is not there.
    assert(2 * r_tip(i) > 2 * hook_chamfer + 1,
           str("size ", hook_sizes[i][0],
               ": the tip is too slender to survive the side chamfer"));
    // A stroke's underside tilts by the radius change over the segment length.
    // Shrinking makes it steeper, which is safe; growing would make it
    // shallower than the rake and that is the one way this profile can go
    // unprintable without any straight edge changing.
    // The profile fillet is made by a CLOSING, which fills any concave gap
    // narrower than twice its radius. The cradle's mouth is the narrowest gap
    // that must survive it.
    assert(2 * hook_wall_fillet < mouth(i),
           str("size ", hook_sizes[i][0],
               ": hook_wall_fillet is over half the mouth and would fill the cradle"));
    assert(hook_side_fillet + hk_w(i) / 2 < x_out,
           str("size ", hook_sizes[i][0],
               ": side fillets reach wider than the collar itself"));
    assert(r_knee(i) <= r_root(i) && r_tip(i) <= r_knee(i),
           str("size ", hook_sizes[i][0],
               ": radius grows along the stroke, tilting an underside under the rake"));
}

// ---- Render quality --------------------------------------------------------
$fn = $preview ? 40 : 96;
