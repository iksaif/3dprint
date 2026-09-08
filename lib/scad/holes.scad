// Holes, pockets and fastener seats — all printer-aware.
//
// The rule these encode: a horizontal bore printed as a plain circle leaves a
// flat ceiling at its apex with nothing under it, so it sags. A teardrop puts a
// 45 deg point up there instead, and 45 deg is self-supporting. Every module
// here that makes a horizontal hole makes a teardrop.
//
// Direction matters and is easy to get wrong: teardrop2d points at +y in 2D,
// and it is the rotation that decides where that lands in 3D. hole_y and hole_x
// both put the point at +Z. Rolling the rotation by hand is how you end up with
// a bore and its own counterbore pointing opposite ways.

// 2D circle with a 45 deg point on +y, so it prints as a horizontal hole
// without sag. Extrude it along the bore's axis.
module teardrop2d(d) {
    r = d / 2;
    union() {
        circle(r);
        polygon([[-r / sqrt(2), r / sqrt(2)], [0, r * sqrt(2)], [r / sqrt(2), r / sqrt(2)]]);
    }
}

// Teardrop hole along the Y axis from y0 to y1, axis through (x, *, z). Point is +Z.
module hole_y(d, y0, y1, x = 0, z = 0) {
    translate([x, y1, z]) rotate([90, 0, 0]) linear_extrude(y1 - y0) teardrop2d(d);
}

// Teardrop hole along the X axis from x0 to x1, axis through (*, y, z). Point is +Z.
module hole_x(d, x0, x1, y = 0, z = 0) {
    translate([x0, y, z]) rotate([90, 0, 90]) linear_extrude(x1 - x0) teardrop2d(d);
}

// Hole along Y, elongated +/-travel in X (a stadium) so a bolt can sit anywhere
// in a range — an adjustment slot that is still a teardrop at both ends.
module slot_hole_y(d, y0, y1, travel, x = 0, z = 0) {
    hull() {
        hole_y(d, y0, y1, x - travel, z);
        hole_y(d, y0, y1, x + travel, z);
    }
}
module slot_hole_x(d, x0, x1, travel, y = 0, z = 0) {
    hull() {
        hole_x(d, x0, x1, y - travel, z);
        hole_x(d, x0, x1, y + travel, z);
    }
}

// Hex prism, axis along Y, flats facing +/-X (so it drops into an X-width channel)
module hex_y(af, h) {
    rotate([90, 0, 0]) rotate([0, 0, 30]) cylinder(d = af / cos(30), h = h, center = true, $fn = 6);
}
// Hex prism, axis along Z
module hex_z(af, h) {
    cylinder(d = af / cos(30), h = h, $fn = 6);
}
// ... centred on the origin
module hex_z_c(af, h) {
    translate([0, 0, -h / 2]) hex_z(af, h);
}

// A captive-nut pocket: the hex, plus a channel out to a face so the nut can be
// slid in. `reach` is how far past the hex the channel runs — make it clear the
// part's surface. Loading from an INNER face hides the slot once assembled.
module nut_slot_z(af, h, reach, dir = [1, 0, 0]) {
    hull() {
        hex_z_c(af, h);
        translate([dir[0] * reach, dir[1] * reach, dir[2] * reach]) hex_z_c(af, h);
    }
}
