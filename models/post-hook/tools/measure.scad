// Where to put the calipers on a calibration slice (or a clip), with the
// design value at each station. Top view, as it sits on the bed: mouth up,
// back wall down. Rendered to docs/measure.png — see PRINTING.md.
//
//   openscad -o docs/measure.png --camera=0,4,0,0,0,0,0 --viewall --autocenter \
//            --projection=o --imgsize=1400,1400 tools/measure.scad
//
// Numbers are for the slice engraved with fit_adjust; the other rungs are
// +/- 2x the difference, which the side legend says.
include <../src/params.scad>
use <../src/clip.scad>

$fn = 64;
lw  = 0.25;          // dimension line width
c_part = "#c9ccd1";
cols   = ["#d1342f", "#1f77b4", "#2ca02c"];

y_A = (grip_y0 + grip_y1) / 2;                                // across the lands
y_B = (y_back_in + fillet_r + relief_r + grip_y0 - grip_lead) / 2;  // arms, behind
y_C = (y_crest0 + y_lip_end) / 2;                             // mouth, at the crests

stations = [
    ["A", y_A, grip_x,         "across the grip lands",     39.2],
    ["B", y_B, hw_in,          "between the arms, behind",  40.2],
    ["C", y_C, x_crest_seated, "mouth, between the crests", 36.0],
];

module dim(x, y, col) {
    color(col) translate([0, 0, 2]) linear_extrude(0.1) {
        translate([-x + 1.2, y - lw / 2]) square([2 * x - 2.4, lw]);
        for (s = [-1, 1])
            polygon([[s * x, y], [s * (x - 1.6), y + 0.7], [s * (x - 1.6), y - 0.7]]);
    }
}

module label(t, x, y, col, size = 2.2, halign = "left") {
    color(col) translate([x, y, 2]) linear_extrude(0.1)
        text(t, size = size, halign = halign, valign = "center",
             font = "Liberation Sans:style=Bold");
}

color(c_part) linear_extrude(1) collar_2d();

for (i = [0 : 2]) {
    s = stations[i];
    dim(s[2], s[1], cols[i]);
    label(s[0], 0, s[1] + 1.8, cols[i], 2.4, "center");
    // Legend to the right: letter, what, value on this rung.
    label(str(s[0], "  ", s[3]), x_out + tab_out + 4, 14 - i * 9, cols[i], 2.0);
    label(str("     ", s[4] + 2 * fit_adjust, " mm on the ", fit_adjust,
              " slice   (", s[4] + 2 * (fit_adjust - 0.1), " / ",
              s[4] + 2 * (fit_adjust + 0.1), " on ", fit_adjust - 0.1, " / ",
              fit_adjust + 0.1, ")"),
          x_out + tab_out + 4, 14 - i * 9 - 3.2, "#333333", 1.7);
}
label("inside jaws, at mid-height — not the bottom edge",
      x_out + tab_out + 4, -16, "#333333", 1.7);
label("A = post - 0.8: that is the squeeze",
      x_out + tab_out + 4, -19.5, "#333333", 1.7);
