#!/usr/bin/env python3
"""Bending check for an extension, measured from the exported mesh.

An extension's section at distance y from the cover is (the side profile's
z-extent at y) x (the part's width at y). This walks out from the root and at
each station computes the real second moment of area and the peak bending stress
from the cantilever moment.

Both of those are read as SILHOUETTES — every triangle projected onto the plane
in question and the spans merged. The union of the projections of a closed
surface is the projection of the solid, so this is the true outline.

That is not how it used to work, and the difference matters twice:

  * it used to read the profile off the single outermost side FACE. That face is
    the profile eroded by the edge chamfer, so every section came out slightly
    small and, within a chamfer of the back face, came out as two thin slivers
    with an absurd second moment. A station floor was bolted on to hide it.
  * worse, that face only exists where the part is at full width. ext_light
    sweeps its width from 44 mm to 10, so the outermost face survives only over
    the interface — the tool read a 20 mm stub, found no bending in it and
    reported a safety factor of 3839x for the one part that had material taken
    out of it. A check that cannot fail is not a check.

Width is therefore measured per station too, not taken as the bounding box.

Reads the STL in PRINT orientation (as exported) and maps it back:
    print (px, py, pz) -> installed (x, y, z) = (pz - w/2, py, -px)
"""
import struct, sys, math, os, re

PETG_YIELD = 50.0        # MPa, typical for a well-printed part
LOAD_KG    = 3.0         # design load (the brief says <=1 kg; 3x margin)
G          = 9.81

HERE = os.path.dirname(os.path.abspath(__file__))


def params():
    """Read the plain `name = number;` assignments out of params.scad.

    These used to be copied into this file as constants, which silently went
    stale the moment the design was rescaled — the report kept quoting a 50 mm
    cover and an M6 screw long after neither was true. Anything derived (hw,
    x_out, ...) is skipped; this only needs the literals.
    """
    out = {}
    with open(os.path.join(HERE, "..", "src", "params.scad")) as f:
        for line in f:
            m = re.match(r"\s*([a-z_][a-z0-9_]*)\s*=\s*(-?[0-9.]+)\s*;", line)
            if m:
                out[m.group(1)] = float(m.group(2))
    return out


P = params()


def read_tris(path):
    with open(path, "rb") as f:
        f.read(80)
        n = struct.unpack("<I", f.read(4))[0]
        out = []
        for _ in range(n):
            r = struct.unpack("<12fH", f.read(50))
            out.append((r[0:3], r[3:6], r[6:9], r[9:12]))
    return out


def silhouettes(tris):
    """Every triangle projected twice: side view (y, z) and plan view (y, x).

    The side view gives the profile's height at a station; the plan view gives
    the part's width there. Neither is a single face — both are the whole mesh
    flattened, so a part whose width varies is described correctly and the edge
    chamfer erodes nothing.
    """
    zs = [v[2] for t in tris for v in t[1:]]
    w = max(zs) - min(zs)
    # print (px, py, pz) -> installed (x, y, z) = (pz - w/2, py, -px)
    side = [[(v[1], -v[0]) for v in t[1:]] for t in tris]
    plan = [[(v[1], v[2] - w / 2) for v in t[1:]] for t in tris]
    return side, plan, w


def spans_at(faces, y):
    """Intervals of the second coordinate covered at station y.

    Merging overlaps is what turns a pile of projected triangles into the
    silhouette; the gaps that survive are real holes in the section.
    """
    segs = []
    for tri in faces:
        zs = []
        for i in range(3):
            (y0, z0), (y1, z1) = tri[i], tri[(i + 1) % 3]
            if (y0 - y) * (y1 - y) < 0:
                zs.append(z0 + (z1 - z0) * (y - y0) / (y1 - y0))
        if len(zs) == 2:
            segs.append((min(zs), max(zs)))
    if not segs:
        return []
    segs.sort()
    merged = [list(segs[0])]
    for lo, hi in segs[1:]:
        if lo <= merged[-1][1] + 1e-6:
            merged[-1][1] = max(merged[-1][1], hi)
        else:
            merged.append([lo, hi])
    return merged


def total(spans):
    return sum(hi - lo for lo, hi in spans)


def section(spans, w):
    """Area, centroid, I about the horizontal neutral axis, extreme fibre."""
    a = sum(hi - lo for lo, hi in spans) * w
    if a == 0:
        return None
    zbar = sum((hi ** 2 - lo ** 2) / 2 * w for lo, hi in spans) / a
    i = sum(w * ((hi - zbar) ** 3 - (lo - zbar) ** 3) / 3 for lo, hi in spans)
    c = max(max(abs(hi - zbar), abs(lo - zbar)) for lo, hi in spans)
    return a, zbar, i, c


def main(path):
    tris = read_tris(path)
    side, plan, w = silhouettes(tris)
    ys = [p[0] for f in side for p in f]
    y0, y1 = min(ys), max(ys)
    force = LOAD_KG * G                       # N, hung at the tip
    # Reach is measured from the mounting face, not across the bounding box:
    # the flange and foot behind y = 0 are joint, not cantilever.
    print(f"{path}   width {w:.0f} mm max   reach {y1:.0f} mm   "
          f"load {LOAD_KG:.1f} kg at the tip")
    print(f"{'y (mm)':>8} {'height':>8} {'width':>8} {'I (mm^4)':>12} "
          f"{'M (N.mm)':>10} {'sigma':>8}  {'util':>6}")
    # Where to start walking.
    #
    # The flange and the foot (y < 0) hang off the back and carry no bending, so
    # the cantilever starts at the mounting face. But the profile above is read
    # off the part's chamfered outer face, which is inset by `chamfer` — so at
    # any station within `chamfer` of the back face the plate simply is not
    # there yet, and all that remains are the flange and foot, two thin slivers
    # a long way apart. That section has a tiny second moment and reports a
    # spectacular stress which is pure artefact.
    #
    # This was the "peak bending stress at y = 0" line for the whole life of
    # this tool: 3.19 MPa when the sliver was thin, 0.69 MPa once the foot grew
    # and filled it. Neither number was the structural root.
    #
    # Now that the profile is a silhouette, the chamfer erodes nothing and the
    # floor is simply the mounting face: the flange and the foot behind it hang
    # off the back of the joint and carry no cantilever moment.
    y0 = max(y0, 0.5)
    worst = (0, None)
    for k in range(0, 21):
        y = y0 + (y1 - y0) * k / 20 * 0.97
        sp = spans_at(side, y)
        bw = total(spans_at(plan, y))         # the width right here, not the bbox
        s = section(sp, bw) if bw > 0 else None
        if not s:
            continue
        a, zbar, i, c = s
        m = force * (y1 - y)
        sigma = m * c / i if i else 0
        util = sigma / PETG_YIELD
        if sigma > worst[0]:
            worst = (sigma, y)
        print(f"{y:8.1f} {total(sp):8.1f} {bw:8.1f} {i:12.0f} "
              f"{m:10.0f} {sigma:8.2f} {util:6.1%}")
    print(f"\npeak bending stress {worst[0]:.2f} MPa at y = {worst[1]:.0f} mm "
          f"({worst[0] / PETG_YIELD:.1%} of PETG yield, {PETG_YIELD:.0f} MPa)")
    print(f"safety factor {PETG_YIELD / worst[0]:.0f}x at {LOAD_KG:.0f} kg "
          f"-> would need ~{LOAD_KG * PETG_YIELD / worst[0]:.0f} kg to yield")

    # How that load actually reaches the clamp. The moment is reacted as a
    # couple over the extension's height: the ridge at the top takes the
    # tension, the plate bearing on the cover's face takes the compression.
    COVER_H = P["u_h"]
    RIDGE_L, RIDGE_H, RIDGE_W = P["ridge_len"], P["ridge_h"], P["ridge_w"]
    # flange underside bearing on the cover's top, less the groove it carries
    FLANGE_BEAR = P["ext_w"] * P["plate_t"] - RIDGE_L * RIDGE_W
    # the screws sit at mid height, so each takes the moment over half the couple
    SCREW_ARM = 2 * P["bolt_z"] if "bolt_z" in P else COVER_H
    # yield load of the screw's stress area, at a nominal 400 MPa class-4.8 bolt
    AREA = {3: 5.03, 4: 8.78, 5: 14.2, 6: 20.1}.get(int(P["bolt_d"]), 8.78)
    m0 = force * (y1 - 0)
    top = m0 / COVER_H                  # tension at the top, on the ridge
    print("\nhow the load gets into the clamp:")
    print(f"  moment at the mounting face    {m0:8.0f} N.mm")
    print(f"  tension at the top, on the ridge {top:7.1f} N "
          f"-> {top / (RIDGE_L * RIDGE_H):.2f} MPa on its front face")
    print(f"  weight through the flange      {force:8.1f} N "
          f"-> {force / FLANGE_BEAR:.2f} MPa bearing on the cover's top")
    print(f"  tension per clamp screw        {m0 / SCREW_ARM:8.1f} N "
          f"(M{int(P['bolt_d'])} holds ~{AREA * 400:.0f} N; "
          f"the pads' friction takes the rest)")


if __name__ == "__main__":
    for p in (sys.argv[1:] or ["build/ext_helmet.stl"]):
        main(p)
        print()
