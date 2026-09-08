#!/usr/bin/env python3
"""Find material that would print into thin air.

Every other check in this project measures whether the geometry is *correct*.
None of them can tell whether it is *printable* — a feature that cannot be
printed interferes with nothing, fits its bounding box, and passes silently.
This closes that gap.

Method
------
Each STL is already exported in its print orientation, so Z is the print axis.
The mesh is sliced layer by layer, and each layer is compared with the one
below:

    seed = material sitting on material in the previous layer, allowed to
           overhang it by one layer height laterally — exactly 45 deg

Then that seed is grown outwards *through the material of its own layer* until
everything is reached or the search runs past `--reach` millimetres. Whatever is
left is material further than `--reach` from anything holding it up.

Why distance-to-support rather than a bridge/cantilever test: it treats both
correctly without having to tell them apart. A bridge is reachable from support
on two sides, so a span of 2 x reach is covered; a cantilever is reachable from
one side only, so it is caught at reach. That asymmetry is roughly how the two
behave on a printer, and it falls out for free.

So the default --reach 8 tolerates bridges up to ~16 mm and overhanging ledges
up to ~8 mm. A 45 deg overhang never appears at all, because the one-layer
allowance already absorbs it.

Layers are held as run-length intervals per scanline, not a dense grid: without
numpy a grid at this resolution is far too slow, and thin features would fall
between sample points and vanish — which is exactly the class of defect being
hunted.
"""

import argparse
import struct
import sys
from collections import defaultdict

# The slice plane is nudged by this much so it never lands exactly on a mesh
# vertex. A vertex on the plane makes a triangle produce one or three crossing
# points instead of two; dropping those punches a hole in the outline, and the
# even-odd fill then floods straight across an empty cavity.
EPS = 1.7e-5


def read_stl(path):
    with open(path, "rb") as f:
        f.read(80)
        n = struct.unpack("<I", f.read(4))[0]
        return [struct.unpack("<12fH", f.read(50))[3:12] for _ in range(n)]


def slice_at(tris, z):
    """Segments where the mesh crosses Z = z. Returns (segments, n_dropped)."""
    segs, dropped = [], 0
    for t in tris:
        a, b, c = t[0:3], t[3:6], t[6:9]
        if (a[2] < z and b[2] < z and c[2] < z) or \
           (a[2] > z and b[2] > z and c[2] > z):
            continue
        pts = []
        for p, q in ((a, b), (b, c), (c, a)):
            if (p[2] < z) != (q[2] < z):
                u = (z - p[2]) / (q[2] - p[2])
                pts.append((p[0] + u * (q[0] - p[0]), p[1] + u * (q[1] - p[1])))
        if len(pts) == 2:
            segs.append((pts[0][0], pts[0][1], pts[1][0], pts[1][1]))
        elif pts:
            dropped += 1
    return segs, dropped


def rasterise(segs, y_min, pitch, n_rows):
    """Scanline fill -> {row: [(x0, x1), ...]}, plus a count of odd rows.

    Only the rows a segment actually crosses are touched, so the cost is the
    outline's total vertical run, not rows x segments.
    """
    crossings = defaultdict(list)
    for x0, y0, x1, y1 in segs:
        if y0 == y1:
            continue
        if y0 > y1:
            x0, y0, x1, y1 = x1, y1, x0, y0
        j0 = max(0, int((y0 - y_min) / pitch) + 1)
        j1 = min(n_rows - 1, int((y1 - y_min) / pitch))
        for j in range(j0, j1 + 1):
            y = y_min + j * pitch
            crossings[j].append(x0 + (y - y0) * (x1 - x0) / (y1 - y0))

    rows, odd = {}, 0
    for j, xs in crossings.items():
        if len(xs) % 2:                 # an unclosed outline: the slice is bad
            odd += 1
            continue
        xs.sort()
        iv = [(xs[i], xs[i + 1]) for i in range(0, len(xs), 2)]
        iv = [s for s in iv if s[1] > s[0]]
        if iv:
            rows[j] = merge(iv)
    return rows, odd


def merge(intervals):
    if not intervals:
        return []
    intervals = sorted(intervals)
    out = [list(intervals[0])]
    for a, b in intervals[1:]:
        if a <= out[-1][1]:
            out[-1][1] = max(out[-1][1], b)
        else:
            out.append([a, b])
    return [tuple(i) for i in out]


def grow(intervals, d):
    return merge([(a - d, b + d) for a, b in intervals]) if intervals else []


def intersect(xs, ys):
    out, i, j = [], 0, 0
    while i < len(xs) and j < len(ys):
        lo, hi = max(xs[i][0], ys[j][0]), min(xs[i][1], ys[j][1])
        if hi > lo:
            out.append((lo, hi))
        if xs[i][1] < ys[j][1]:
            i += 1
        else:
            j += 1
    return out


def subtract(whole, parts):
    out = []
    for a, b in whole:
        cur = a
        for c, d in parts:
            if d <= cur or c >= b:
                continue
            if c > cur:
                out.append((cur, min(c, b)))
            cur = max(cur, d)
            if cur >= b:
                break
        if cur < b:
            out.append((cur, b))
    return out


def total(intervals):
    return sum(b - a for a, b in intervals)


def unreachable(mats, seed, step, max_steps):
    """Grow `seed` through `mats` and return whatever it never reaches.

    One step moves `step` along X and one row along Y, so the search radius
    after n steps is about n * step in either direction.
    """
    cur = {j: list(v) for j, v in seed.items() if v}
    for _ in range(max_steps):
        nxt, changed = {}, False
        for j, m in mats.items():
            src = merge(grow(cur.get(j, []), step)
                        + cur.get(j - 1, []) + cur.get(j + 1, []))
            got = intersect(m, src) if src else []
            if got:
                nxt[j] = got
                if total(got) > total(cur.get(j, [])) + 1e-9:
                    changed = True
        cur = nxt
        if not changed:
            break
    return {j: subtract(m, cur.get(j, [])) for j, m in mats.items()
            if subtract(m, cur.get(j, []))}


def check(path, layer, pitch, reach, verbose):
    tris = read_stl(path)
    ys = [t[i] for t in tris for i in (1, 4, 7)]
    zs = [t[i] for t in tris for i in (2, 5, 8)]
    y_min, y_max, z_min, z_max = min(ys), max(ys), min(zs), max(zs)
    n_rows = int((y_max - y_min) / pitch) + 2
    max_steps = max(1, int(round(reach / pitch)))

    prev, worst, defects, dropped, odd = {}, 0.0, [], 0, 0
    z, n = z_min + layer / 2 + EPS, 0
    while z < z_max:
        segs, d = slice_at(tris, z)
        mats, o = rasterise(segs, y_min, pitch, n_rows)
        dropped += d
        odd += o
        n += 1
        if prev:                       # layer 0 is the bed: all of it supported
            seed = {}
            for j, m in mats.items():
                below = merge(grow(prev.get(j - 1, []), layer)
                              + grow(prev.get(j, []), layer)
                              + grow(prev.get(j + 1, []), layer))
                if below:
                    s = intersect(m, below)
                    if s:
                        seed[j] = s
            bad = unreachable(mats, seed, pitch, max_steps)
            for j, iv in bad.items():
                for a, b in iv:
                    defects.append((b - a, z, y_min + j * pitch, a, b))
                    worst = max(worst, b - a)
        prev = mats
        z += layer

    area = sum(d[0] for d in defects) * pitch
    ok = not defects
    print(f"{path.split('/')[-1]:20s} {n:4d} layers  "
          f"{len(defects):5d} unsupported runs  {area:7.1f} mm^2  "
          f"{'OK' if ok else 'NEEDS SUPPORT'}")
    if dropped or odd:
        print(f"    warning: {dropped} degenerate triangles, {odd} unclosed rows"
              " — slice may be unreliable")
    if defects and verbose:
        defects.sort(reverse=True)
        for w, z, y, a, b in defects[:8]:
            print(f"    z={z:6.2f}  y={y:7.2f}  x {a:7.2f}..{b:7.2f}   {w:5.1f} mm")
        if len(defects) > 8:
            print(f"    ... and {len(defects) - 8} more")
    return ok


def main():
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("stl", nargs="+")
    p.add_argument("--layer", type=float, default=0.2, help="layer height, mm")
    p.add_argument("--pitch", type=float, default=0.4, help="scanline pitch, mm")
    p.add_argument("--reach", type=float, default=8.0,
                   help="furthest material may sit from support, mm "
                        "(so bridges up to ~2x this are tolerated)")
    p.add_argument("-q", "--quiet", action="store_true")
    a = p.parse_args()
    ok = True
    for s in a.stl:
        ok &= check(s, a.layer, a.pitch, a.reach, not a.quiet)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
