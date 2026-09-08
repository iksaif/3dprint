#!/usr/bin/env python3
"""Check that an STL is a closed, consistently oriented 2-manifold.

Usage: mesh.py [--bed X,Y] file.stl [file.stl ...]

Pure Python on purpose. Every other tool in this repo runs with the system
interpreter and no venv, and macOS ships an externally-managed Python (PEP 668)
with no numpy — so a numpy dependency here would mean `make check` quietly never
ran. The meshes involved are ~10k triangles; a dict is plenty.

Per file:
  * parses (binary or ASCII STL) and has at least one triangle
  * every edge is shared by exactly two triangles          -> watertight
  * every directed edge appears exactly once               -> consistent winding
  * signed volume is positive                              -> normals point out
  * bounding box fits the bed footprint, if --bed is given
Also reports volume, bounding box and the number of connected shells.

Two kinds of zero-area triangle turn up in OpenSCAD output and they must be
treated differently — conflating them makes this check fail on good meshes:

  * NULL triangles have two coincident corners. One of their three edges has
    zero length and the other two are the same edge traversed both ways, so
    they carry no surface and seal nothing. They are dropped from the topology
    entirely. Counting their edges is what made every chamfered part here read
    as "non-manifold with 100+ shells" while OpenSCAD's manifold backend was
    reporting the very same object as a clean solid.
  * COLINEAR fillers have three distinct corners on one line. They carry no
    area either, but they do seal a T-junction, so they stay in the topology
    and are only excluded from the winding test, where they read as false fins.

Both counts are reported; neither is a failure on its own.

With --backend=manifold OpenSCAD already guarantees a manifold result, so this
is a sanity net rather than the main event — but it is what catches a truncated
write, and the shell count is how you confirm a multi-object plate really did
stay several objects.
"""
import argparse
import math
import struct
import sys

# Weld tolerance, mm. This is bounded on BOTH sides and the window is narrow, so
# do not nudge it without re-measuring:
#
#   too small — STL stores float32, so two corners that are one point in the
#     model still differ in the file. The ULP at |v| = 128 mm is ~1.5e-5 mm.
#     Below that they fail to merge and the mesh reads as thousands of shells.
#   too large — stroke() builds profiles from hulled circles, and near-tangent
#     hulls put genuinely distinct vertices ~3e-4 mm apart. Merging those
#     invents open edges and winding errors that are not in the file.
#
# Measured on ext_helmet.stl, the worst case here: clean at 1e-5..1e-4, and
# breaking from 3e-4 up. 1e-4 sits at the top of the safe range with ~6x
# headroom over float32 noise.
WELD = 1e-4


def read_stl(path):
    with open(path, "rb") as f:
        data = f.read()
    if len(data) < 84:
        raise ValueError("file too short to be an STL")
    # A binary STL's size is exactly 84 + 50*n. ASCII files almost never match.
    n = struct.unpack("<I", data[80:84])[0]
    if len(data) == 84 + 50 * n:
        tris = []
        off = 84
        for _ in range(n):
            v = struct.unpack_from("<12f", data, off)
            tris.append((v[3:6], v[6:9], v[9:12]))
            off += 50
        return tris
    text = data.decode("utf-8", errors="replace")
    verts = []
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("vertex"):
            verts.append(tuple(float(x) for x in line.split()[1:4]))
    if len(verts) % 3:
        raise ValueError("ASCII STL vertex count is not a multiple of 3")
    return [tuple(verts[i:i + 3]) for i in range(0, len(verts), 3)]


class Welder:
    """Maps near-coincident points to one id.

    Rounding coordinates to a grid is the obvious approach and it is wrong:
    two points 1e-9 apart that straddle a cell boundary round to different
    cells and never merge. So bucket by cell, but search the 27 neighbouring
    cells for an existing representative within tolerance before minting a
    new id.
    """

    def __init__(self, tol=WELD):
        self.tol = tol
        self.tol2 = tol * tol
        self.cells = {}      # cell -> [(point, id), ...]
        self.next_id = 0

    def __call__(self, v):
        cx = int(math.floor(v[0] / self.tol))
        cy = int(math.floor(v[1] / self.tol))
        cz = int(math.floor(v[2] / self.tol))
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    for p, i in self.cells.get((cx + dx, cy + dy, cz + dz), ()):
                        d2 = ((p[0] - v[0]) ** 2 + (p[1] - v[1]) ** 2
                              + (p[2] - v[2]) ** 2)
                        if d2 <= self.tol2:
                            return i
        i = self.next_id
        self.next_id += 1
        self.cells.setdefault((cx, cy, cz), []).append((v, i))
        return i


def tri_area(a, b, c):
    u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    w = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    n = (u[1] * w[2] - u[2] * w[1],
         u[2] * w[0] - u[0] * w[2],
         u[0] * w[1] - u[1] * w[0])
    return 0.5 * math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2)


class DSU:
    """Union-find, for counting connected shells."""

    def __init__(self, n):
        self.p = list(range(n))

    def find(self, a):
        while self.p[a] != a:
            self.p[a] = self.p[self.p[a]]
            a = self.p[a]
        return a

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.p[ra] = rb


def check(path, bed):
    tris = read_stl(path)
    if not tris:
        print(f"{path}: no triangles")
        return False

    mn = [1e30] * 3
    mx = [-1e30] * 3
    vol = 0.0
    nulls = 0               # two corners coincident: no surface, no edges
    colinear = 0            # three distinct corners on a line: seals a T-junction
    undirected = {}          # frozenset(edge) -> count
    directed = {}            # (a, b) -> count
    edge_tris = {}           # frozenset(edge) -> [triangle index, ...]
    key = Welder()

    for i, (a, b, c) in enumerate(tris):
        for v in (a, b, c):
            for ax in range(3):
                mn[ax] = min(mn[ax], v[ax])
                mx[ax] = max(mx[ax], v[ax])
        vol += (a[0] * (b[1] * c[2] - b[2] * c[1])
                - a[1] * (b[0] * c[2] - b[2] * c[0])
                + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0

        ka, kb, kc = key(a), key(b), key(c)
        if len({ka, kb, kc}) < 3:
            # A null triangle. Its edges are a zero-length stub and one real
            # edge counted twice; feeding those into the topology invents
            # non-manifold edges that are not there. Skip it completely.
            nulls += 1
            continue
        thin = tri_area(a, b, c) < 1e-12
        if thin:
            colinear += 1
        for p, q in ((ka, kb), (kb, kc), (kc, ka)):
            e = frozenset((p, q))
            undirected[e] = undirected.get(e, 0) + 1
            edge_tris.setdefault(e, []).append(i)
            if not thin:
                directed[(p, q)] = directed.get((p, q), 0) + 1

    problems = []
    open_edges = sum(1 for c in undirected.values() if c == 1)
    over_edges = sum(1 for c in undirected.values() if c > 2)
    if open_edges:
        problems.append(f"{open_edges} open edges (not watertight)")
    if over_edges:
        problems.append(f"{over_edges} edges on 3+ faces (non-manifold)")
    flipped = sum(1 for c in directed.values() if c > 1)
    if flipped:
        problems.append(f"{flipped} edges traversed twice the same way (winding)")
    if vol <= 0:
        problems.append(f"signed volume {vol / 1000:.1f} cm3 not positive "
                        f"(normals point inward)")

    # Shells are counted over the triangles that actually carry surface, so the
    # dropped nulls do not each read as a shell of their own.
    real = sorted({i for members in edge_tris.values() for i in members})
    index = {t: n for n, t in enumerate(real)}
    dsu = DSU(len(real))
    for members in edge_tris.values():
        for j in members[1:]:
            dsu.union(index[members[0]], index[j])
    shells = len({dsu.find(n) for n in range(len(real))}) if real else 0

    size = [mx[a] - mn[a] for a in range(3)]
    if bed and (size[0] > bed[0] or size[1] > bed[1]):
        problems.append(f"footprint {size[0]:.0f} x {size[1]:.0f} exceeds bed "
                        f"{bed[0]:.0f} x {bed[1]:.0f}")

    name = path.split("/")[-1]
    extra = []
    if shells > 1:
        extra.append(f"{shells} shells")
    if nulls or colinear:
        extra.append(f"[{nulls} null, {colinear} colinear]")
    note = ("  " + "  ".join(extra)) if extra else ""
    if problems:
        print(f"{name:22s} {len(tris):6d} tris  FAIL: {'; '.join(problems)}{note}")
        return False
    print(f"{name:22s} {len(tris):6d} tris  {abs(vol) / 1000:7.1f} cm3  "
          f"watertight, oriented{note}")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bed", help="bed footprint as X,Y in mm")
    ap.add_argument("files", nargs="+")
    args = ap.parse_args()
    bed = None
    if args.bed:
        parts = [float(x) for x in args.bed.split(",")]
        bed = (parts[0], parts[1] if len(parts) > 1 else parts[0])

    ok = True
    for path in args.files:
        try:
            ok &= check(path, bed)
        except Exception as exc:                      # noqa: BLE001
            print(f"{path}: {exc}")
            ok = False
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
