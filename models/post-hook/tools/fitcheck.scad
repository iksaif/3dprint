// Intersections springcheck.py measures. There is one part now, so there is
// no pair that has to mate at zero volume and nothing for fitcheck.py to read.
//
// catch   NOT a "must be zero" case —
//         springcheck.py drives it. The lips are placed where they sit once the
//         post has sprung the arms open, then pulled forward by `pull`, and
//         intersected with the post. The cam face is TANGENT to the post's
//         corner at rest, so the resting overlap is legitimately zero and a
//         checker looking for overlap learns nothing from it. Winding `pull` up
//         is what proves the lip blocks the pull-off, which is the only
//         question worth asking of a snap.
include <../src/params.scad>
use <../src/clip.scad>

which = "catch";
pull  = 0;      // mm the clip has been pulled OFF the post, for `catch`

// Measured by VOLUME, not looked at. 48 facets keeps a check run to a few
// seconds, and chord error is orders below the volumes being compared.
$fn = 48;

if (which == "catch")
    intersection() { seated_lips(pull); post_solid(); }
