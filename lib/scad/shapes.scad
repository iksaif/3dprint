// 2D outlines and the extrusions built on them.
//
// Nothing here knows about printing except chamfered_extrude, which exists so
// that the top and bottom edges of an extruded body are 45 deg rather than
// square — the bottom edge to kill elephant's foot, the top because a square
// edge on a visible part reads as unfinished.

// Rounded rectangle, corner at origin, size [w, h]
module rrect(w, h, r) {
    offset(r) offset(-r) square([w, h]);
}

// Square with rounded corners, centred
module rounded_square(s, r) {
    offset(r) offset(-r) square(s, center = true);
}

// Chain of hulled circles — a smooth "stroke" through points [[x, y, r], ...].
// This is the cheapest way to draw an organic profile that stays printable:
// the result is convex between consecutive points, so it has no re-entrant
// surprises, and the radius at each station is the local half-thickness.
module stroke(pts) {
    for (i = [0 : len(pts) - 2]) hull() {
        translate([pts[i][0], pts[i][1]]) circle(pts[i][2]);
        translate([pts[i + 1][0], pts[i + 1][1]]) circle(pts[i + 1][2]);
    }
}

// Fillet concave corners (r_in) and round convex corners (r_out) of a 2D shape.
// Order is load-bearing and the innermost offset runs FIRST: dilate+erode is a
// closing, which fillets concave corners; erode+dilate is an opening, which
// rounds convex ones. Swap them and you erode small features away instead.
module smooth2d(r_in, r_out) {
    offset(r = r_out) offset(r = -r_out) offset(r = -r_in) offset(r = r_in) children();
}

// Double cone used to chamfer extruded parts via minkowski. Written as one
// solid rather than two cones meeting at a point: apex-to-apex is non-manifold
// and minkowski will happily propagate that into the result.
module bicone(c) {
    translate([0, 0, -c]) cylinder(r1 = 0, r2 = c, h = c);
    cylinder(r1 = c, r2 = 0, h = c);
}

// linear_extrude with a 45 deg chamfer of size c on the top and bottom edges.
// The 2D child is the outline at mid-height; the result spans z in [0, h].
//
// Beware: the child is eroded by c before extrusion, so any feature narrower
// than 2*c disappears entirely rather than being chamfered. If a lip vanishes
// from your part, this is why — make the feature wider than 2*c, or chamfer it
// separately.
module chamfered_extrude(h, c) {
    // render(): evaluates the minkowski once and gives the preview a convexity
    // hint, so cutaway views of these concave bodies draw correctly.
    render(convexity = 10) minkowski() {
        translate([0, 0, c]) linear_extrude(h - 2 * c, convexity = 10) offset(r = -c) children();
        bicone(c);
    }
}
