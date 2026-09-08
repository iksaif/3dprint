// The dock's own coordinate frames and outline helpers.
//
// `include` for params, not `use`: OpenSCAD's `use` imports modules and
// functions but NOT variables, and every helper here is driven by them.
include <params.scad>

// ---------------------------------------------------------------------------
// 2D helpers
// ---------------------------------------------------------------------------

module rounded_rect_2d(width, depth, radius) {
    r = min(radius, width / 2 - eps, depth / 2 - eps);
    offset(r = r) offset(delta = -r) square([width, depth], center = true);
}

// Rectangle with superellipse corners (n = 2 circular, n = 4 squircle), CCW.
function superrect_points(w, d, r, n, steps = 24) =
    let(hw = w / 2 - r, hd = d / 2 - r)
    [for (c = [[1, 1, 0], [-1, 1, 90], [-1, -1, 180], [1, -1, 270]])
        for (i = [0 : steps])
            let(t = c[2] + 90 * i / steps, ct = cos(t), st = sin(t))
            [c[0] * hw + sign(ct) * pow(abs(ct), 2 / n) * r,
             c[1] * hd + sign(st) * pow(abs(st), 2 / n) * r]];

// Plan-view outline, y from 0 (front) to body_depth (rear). inset = true parallel offset.
module footprint_2d(inset = 0) {
    translate([0, body_depth / 2])
        offset(delta = -inset)
            polygon(superrect_points(body_width, body_depth, footprint_radius, footprint_exponent));
}

// Section of the vertical footprint prism by the plane local z = zl, in local
// (x, y) coordinates, optionally inset by a parallel offset measured on that
// plane. All nested top-face profiles derive from this, so borders are
// constant-width around every corner.
module top_outline_2d(zl = 0, inset = 0) {
    offset(delta = -inset)
        translate([0, zl * tan(top_angle)])
            scale([1, 1 / cos(top_angle)])
                footprint_2d();
}

// ---------------------------------------------------------------------------
// 3D helpers
// ---------------------------------------------------------------------------

module top_frame() {
    translate([0, 0, front_height]) rotate([top_angle, 0, 0]) children();
}

// Inverse of top_frame(), then lift so the parting plane is z = 0.
module unframe() {
    translate([0, 0, plate_thickness])
        rotate([-top_angle, 0, 0])
            translate([0, 0, -front_height])
                children();
}

module local_slab(z_lo, z_hi) {
    top_frame()
        translate([-big / 2, -big / 2, z_lo])
            cube([big, big, z_hi - z_lo]);
}

module footprint_prism(inset = 0, z0 = -ov, z1 = big) {
    translate([0, 0, z0])
        linear_extrude(height = z1 - z0, convexity = 10)
            footprint_2d(inset);
}

// 2D child in the (x, z) plane, extruded from world y0 to y1.
module extrude_y(y0, y1) {
    translate([0, y1, 0]) rotate([90, 0, 0])
        linear_extrude(height = y1 - y0, convexity = 6)
            children();
}

module slice_at(zl) {
    translate([0, 0, zl]) linear_extrude(height = eps) children();
}

module local_box(x0, x1, y0, y1, z0 = -big / 2, z1 = big / 2) {
    translate([x0, y0, z0]) cube([x1 - x0, y1 - y0, z1 - z0]);
}

