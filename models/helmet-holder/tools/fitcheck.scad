// Interference check between parts that mate. A correct fit leaves only
// zero-volume contact (a face resting on a face); any real overlap shows up as
// a solid with measurable volume.
include <../src/params.scad>
use <../src/clamp.scad>
use <../src/extensions.scad>

// ext      extension vs cover — the ridge in its groove
// clamp    cover vs U-bracket — the lips in their rebates
// pad      a TPU pad vs the pocket it sits in. Both are chamfered at top and
//          bottom so the pocket has no flat ledge printed over air; chamfer one
//          without the other and this is what catches it. The studs are left
//          off — they are a deliberate interference fit and would mask this.
// pad_arm  the same for a short side pad
which = "ext";

if (which == "ext")
    intersection() {
        cover("install");
        translate([0, pd + plate_t, 0]) ext_helmet("install");
    }
else if (which == "clamp")
    intersection() { u_bracket(); cover("install"); }
else if (which == "pad")
    intersection() { cover("install"); pad_place_slab("front"); }
else
    intersection() { u_bracket(); pad_place_slab("left"); }
