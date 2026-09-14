// Interference between parts that mate. A correct fit leaves only zero-volume
// contact — a face resting on a face — so any real overlap shows up as a solid
// with measurable volume.
//
// liner   the TPU liner against the collar it sits in. Its three outer faces
//         are coincident with the back wall and the two arm faces, and its
//         teeth all face the other way, so a correct liner reports zero. This
//         is the case that catches the leg rotated the wrong way round, which
//         puts the teeth INTO the arms and is invisible in a render because the
//         liner and the collar are much the same colour. The studs are left
//         off: they are a deliberate 0.4 mm interference and would mask
//         everything else.
//
// catch   NOT a "must be zero" case, and not read by fitcheck.py at all —
//         springcheck.py drives it. The lips are placed where they sit once the
//         post has sprung the arms open, then pulled forward by `pull`, and
//         intersected with the post. The cam face is TANGENT to the post's
//         corner at rest, so the resting overlap is legitimately zero and a
//         checker looking for overlap learns nothing from it. Winding `pull` up
//         is what proves the lip blocks the pull-off, which is the only
//         question worth asking of a snap.
include <../src/params.scad>
use <../src/clip.scad>

which = "liner";
pull  = 0;      // mm the clip has been pulled OFF the post, for `catch`

// These cases are measured by VOLUME, not looked at, and the collar is a
// minkowski. 48 facets keeps a check run to a few seconds; the chord error on
// the post's r3 corner is 6 microns, which is four orders below the volumes
// being compared.
$fn = 48;

if (which == "liner")
    intersection() { collar(); liner(false); }
else if (which == "catch")
    intersection() { seated_lips(pull); post_solid(); }
