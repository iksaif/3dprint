include <params.scad>
use <frame.scad>
use <plate.scad>
use <../../../lib/scad/shapes.scad>

// ---------------------------------------------------------------------------
// TPU top insert
// ---------------------------------------------------------------------------

module mat_cable_notch_2d() {
    translate([0, -puck_hole_diameter / 2 - mat_cable_notch_length / 2 + mat_cable_notch_overlap])
        rounded_rect_2d(mat_cable_notch_width, mat_cable_notch_length, mat_cable_notch_radius);
}

module mat_outline_2d() {
    if (split_islands) {
        for (cx = puck_xs)
            translate([cx, puck_y])
                island_2d(-mat_clearance_total / 2);
    } else {
        top_outline_2d(0, recess_border + mat_clearance_total / 2);
    }
}

module mat_2d() {
    difference() {
        mat_outline_2d();
        for (cx = puck_xs)
            translate([cx, puck_y]) {
                circle(d = puck_hole_diameter);
                // Through notch only when the relief is not a blind pocket.
                if (!mat_cable_pocket) mat_cable_notch_2d();
            }
    }
}

// Plan outline of the cable relief at both pucks, notch or pocket.
module mat_cable_relief_2d() {
    for (cx = puck_xs) translate([cx, puck_y]) mat_cable_notch_2d();
}

module mat_bezel_2d() {
    for (cx = puck_xs)
        translate([cx, puck_y])
            difference() {
                circle(d = puck_hole_diameter + 2 * mat_bezel_width);
                circle(d = puck_hole_diameter);
                mat_cable_notch_2d();
            }
}

// ---------------------------------------------------------------------------
// Top texture: grooves cut into the mat's top face
// ---------------------------------------------------------------------------

// Where grooves may go: the mat top less a smooth band round its edge, each
// bezel ring and each cable notch. The opening removes necks narrower than one
// pitch -- the strip between the two bezels, the slivers beside each notch --
// which would otherwise carry lone groove fragments that read as print defects.
module mat_texture_field_2d() {
    r = mat_texture_pitch / 2;
    offset(r = r) offset(r = -r)
        difference() {
            if (split_islands) {
                for (cx = puck_xs)
                    translate([cx, puck_y])
                        island_2d(-mat_clearance_total / 2 - mat_texture_margin);
            } else {
                top_outline_2d(0, recess_border + mat_clearance_total / 2 + mat_texture_margin);
            }
            for (cx = puck_xs)
                translate([cx, puck_y]) {
                    circle(d = puck_hole_diameter + 2 * mat_texture_hole_band);
                    offset(r = mat_texture_margin) mat_cable_notch_2d();
                }
        }
}

// Rows of chevrons pointing up the incline, like a tyre tread.
module mat_tread_grooves_2d() {
    w = mat_width / 2 + mat_texture_pitch;
    drop = w * tan(mat_texture_angle);
    for (k = [floor(-top_length / 2 / mat_texture_pitch) : ceil((top_length / 2 + drop) / mat_texture_pitch)])
        let(y0 = puck_y + k * mat_texture_pitch)
            stroke([[-w, y0 - drop, mat_texture_groove / 2],
                    [0,  y0,        mat_texture_groove / 2],
                    [w,  y0 - drop, mat_texture_groove / 2]], $fn = 24);
}

// Honeycomb: the grooves are what is left between flat-topped hexagonal lands.
module mat_hex_grooves_2d() {
    p = mat_texture_pitch;
    dx = p * cos(30);
    difference() {
        square([body_width, 2 * top_length], center = true);
        for (i = [-ceil(mat_width / 2 / dx) - 1 : ceil(mat_width / 2 / dx) + 1],
             j = [-ceil(top_length / 2 / p) - 1 : ceil(top_length / 2 / p) + 1])
            translate([i * dx, puck_y + (j + (abs(i) % 2) / 2) * p])
                circle(r = (p - mat_texture_groove) / 2 / cos(30), $fn = 6);
    }
}

// Rugged: cracked stone. A jittered triangular lattice (neighbours one pitch
// apart), each point's Voronoi cell shrunk by half a groove and its corners
// rounded into a pebble. The grooves are the cracks left between the pebbles.
// Jitter is capped at 0.3 pitch, so no two points come closer than 0.4 pitch
// and every stone stays wider than the groove. rands() with a seed is
// deterministic, so every build of the same parameters gives the same stones.
function mat_rugged_points() =
    let(p  = mat_texture_pitch,
        ni = ceil(mat_width / 2 / p) + 1,
        nj = ceil(top_length / 2 / (p * sin(60))) + 1,
        rows = 2 * nj + 1,
        jit = rands(-0.3 * p, 0.3 * p, 2 * (2 * ni + 1) * rows, mat_texture_seed))
    [for (i = [-ni : ni], j = [-nj : nj])
        let(k = (i + ni) * rows + (j + nj))
            [(i + (abs(j) % 2) / 2) * p + jit[2 * k],
             puck_y + j * p * sin(60) + jit[2 * k + 1]]];

// The half of the plane nearer a than b, as a square large enough to cover a's cell.
module half_plane_toward(a, b, size) {
    m = (a + b) / 2;
    u = (b - a) / norm(b - a);
    n = [-u[1], u[0]];
    polygon([m + n * size, m - n * size, m - n * size - u * size, m + n * size - u * size]);
}

module mat_rugged_grooves_2d() {
    p = mat_texture_pitch;
    round_r = 1.0;
    pts = mat_rugged_points();
    difference() {
        square([body_width, 2 * top_length], center = true);
        for (a = pts)
            offset(r = round_r) offset(delta = -(mat_texture_groove / 2 + round_r))
                intersection() {
                    translate(a) circle(r = 1.5 * p, $fn = 24);
                    intersection_for(b = [for (q = pts) if (q != a && norm(q - a) < 2 * p) q])
                        half_plane_toward(a, b, 3 * p);
                }
    }
}

// The opening drops groove fragments too small to print where the pattern is
// clipped by the field edge.
module mat_texture_2d() {
    s = 0.3;
    offset(r = s) offset(r = -s)
        intersection() {
            mat_texture_field_2d();
            if (mat_texture == "tread") mat_tread_grooves_2d();
            else if (mat_texture == "hex") mat_hex_grooves_2d();
            else if (mat_texture == "rugged") mat_rugged_grooves_2d();
        }
}

// TPU locating studs hanging from the mat's underside, with a chamfered tip to
// find their holes. `shrink` narrows them for the fit check, which tests that
// every stud lands inside its hole.
// One stud, root at z = 0, chamfered tip at z = mat_dowel_length. This is the
// print orientation (face-down mat), and the coupon uses it as is.
module mat_dowel_stud(shrink = 0) {
    d = mat_dowel_diameter - shrink;
    c = mat_dowel_tip_chamfer;
    hull() {
        cylinder(h = mat_dowel_length - c, d = d, $fn = 32);
        translate([0, 0, -eps]) cylinder(h = mat_dowel_length + eps, d = d - 2 * c, $fn = 32);
    }
}

module mat_dowel_studs(shrink = 0) {
    for (p = mat_dowel_xy)
        translate([p[0], p[1], -recess_depth + eps])
            rotate([180, 0, 0]) mat_dowel_stud(shrink);
}

// The wedge of TPU that narrows each puck hole towards the mat's face: full
// bore at mat_puck_lip_depth below the face, mat_puck_lip_inset tighter at the
// face itself. Revolved as a triangle, so it is solid material behind the
// contact rather than a flange standing on one layer. The cable relief is cut
// back out of it, or the boot would not pass.
module mat_puck_lip_taper() {
    t      = mat_thickness;
    r_face = puck_hole_diameter / 2 - mat_puck_lip_inset;
    r_bore = puck_hole_diameter / 2;
    for (cx = puck_xs)
        translate([cx, puck_y, 0])
            difference() {
                rotate_extrude($fn = 160)
                    polygon([[r_face, t],
                             [r_bore + mat_puck_lip_root, t],
                             [r_bore + mat_puck_lip_root, t - mat_puck_lip_depth],
                             [r_bore, t - mat_puck_lip_depth]]);
                translate([0, 0, t - mat_puck_lip_depth - ov])
                    linear_extrude(height = mat_puck_lip_depth + 2 * ov) mat_cable_notch_2d();
            }
}

// Insert in local coordinates, sitting on the recess floor.
module top_insert_local(dowels = mat_dowels) {
    if (dowels) mat_dowel_studs();
    translate([0, 0, -recess_depth]) {
        difference() {
            linear_extrude(height = mat_thickness, convexity = 6) mat_2d();
            if (mat_texture != "none")
                translate([0, 0, mat_thickness - mat_texture_depth])
                    linear_extrude(height = mat_texture_depth + ov, convexity = 10) mat_texture_2d();
            // Blind pocket in the underside for the boot and the cable's dive.
            // Face down, as printed, this opens upward: nothing to bridge.
            if (mat_cable_pocket && mat_cable_relief_depth > 0)
                translate([0, 0, -ov])
                    linear_extrude(height = mat_cable_relief_depth + ov, convexity = 4)
                        mat_cable_relief_2d();
        }
        // The tapered lip, added after the texture and pocket are cut so
        // nothing eats into it.
        if (mat_puck_lip) mat_puck_lip_taper();
        if (mat_bezel_width > 0 && mat_bezel_height > 0)
            translate([0, 0, mat_thickness - eps])
                linear_extrude(height = mat_bezel_height + eps, convexity = 4)
                    mat_bezel_2d();
    }
}

module top_insert(dowels = mat_dowels) {
    top_frame() top_insert_local(dowels);
}

// Print orientation, flat and centred. Face down by default: the visible face
// takes the build sheet's texture, and the studs point up, the only way they print.
// Turned about X, not mirrored, so the notches still line up with the pucks.
module top_insert_flat() {
    if (mat_print_face_down)
        translate([0, top_length / 2, mat_thickness]) rotate([180, 0, 0])
            translate([0, 0, recess_depth]) top_insert_local();
    else
        translate([0, -top_length / 2, recess_depth]) top_insert_local();
}

