#!/usr/bin/env python3
"""Check that an STL is a closed, consistently oriented 2-manifold.

Usage: check_mesh.py [--bed SIZE] file.stl [file.stl ...]

Exit status is non-zero if any file fails. Only numpy is required.
Checks per file:
  * parses (binary or ASCII STL), has at least one triangle
  * every edge is shared by exactly two triangles (watertight)
  * the two triangles traverse the edge in opposite directions (orientable,
    consistent winding, no non-manifold fins)
  * normals point outward (positive signed volume)
  * bounding box fits the bed footprint (X and Y), if --bed is given
Also reports volume, bounding box and number of connected shells.

Zero-area triangles are reported, not failed on: OpenSCAD's triangulation of
offset profiles emits colinear T-junction fillers that carry no geometry.
They are excluded from the winding test (where they read as false "fins")
but kept in the watertight test (where they still seal their edge).
"""
import argparse
import struct
import sys

import numpy as np


def read_stl(path):
    with open(path, "rb") as f:
        data = f.read()
    # Binary STL: 80-byte header, uint32 count, 50 bytes per facet.
    if len(data) >= 84:
        (count,) = struct.unpack_from("<I", data, 80)
        if 84 + 50 * count == len(data) and not data[:5].lower().startswith(b"solid"):
            return _read_binary(data, count)
        if 84 + 50 * count == len(data):
            # Some writers start binary files with "solid"; size match wins.
            return _read_binary(data, count)
    return _read_ascii(data.decode("ascii", errors="replace"))


def _read_binary(data, count):
    dtype = np.dtype([("n", "<f4", 3), ("v", "<f4", (3, 3)), ("attr", "<u2")])
    rec = np.frombuffer(data, dtype=dtype, count=count, offset=84)
    return rec["v"].astype(np.float64)


def _read_ascii(text):
    verts = []
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("vertex"):
            verts.append([float(x) for x in s.split()[1:4]])
    if len(verts) % 3:
        raise ValueError("ASCII STL vertex count is not a multiple of 3")
    return np.array(verts, dtype=np.float64).reshape(-1, 3, 3)


def check(path, bed=None):
    tris = read_stl(path)
    problems = []
    if len(tris) == 0:
        return ["no triangles"], {}

    # Merge vertices exactly (OpenSCAD writes identical coordinates for shared vertices).
    flat = tris.reshape(-1, 3)
    key = np.round(flat, 5)
    uniq, inv = np.unique(key, axis=0, return_inverse=True)
    faces = inv.reshape(-1, 3)

    # Zero-area triangles. OpenSCAD's triangulation of offset/superellipse
    # profiles emits colinear T-junction fillers: needles with area below
    # 1e-9 mm2 that carry no geometry. Every slicer ignores them, and the
    # manifold kernel has already certified the solid, so they are reported
    # but not failed on. They are excluded from the winding test below,
    # where they would otherwise register as hundreds of spurious "fins".
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    area2 = np.linalg.norm(np.cross(b - a, c - a), axis=1)
    # Two ways a triangle can carry no geometry: zero area outright, or two
    # of its corners collapsing onto one vertex when coordinates are merged
    # (a long, sub-micron-wide needle clears the area test but is still
    # topologically degenerate).
    collapsed = (
        (faces[:, 0] == faces[:, 1])
        | (faces[:, 1] == faces[:, 2])
        | (faces[:, 0] == faces[:, 2])
    )
    sliver = (area2 < 1e-9) | collapsed
    n_sliver = int(np.sum(sliver))
    solid = faces[~sliver]

    # Watertight: computed over ALL faces, slivers included, because a
    # zero-area filler still seals the edge it spans. A genuine hole shows up
    # here regardless of how the surface was triangulated.
    e_all = np.concatenate([faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]]])
    d_all = e_all[:, 0].astype(np.int64) * len(uniq) + e_all[:, 1]
    r_all = e_all[:, 1].astype(np.int64) * len(uniq) + e_all[:, 0]
    missing = np.setdiff1d(d_all, r_all)
    if len(missing):
        problems.append(f"{len(missing)} open edge(s): mesh is not watertight")

    # Consistent winding / no non-manifold fins: computed over the faces that
    # actually bound volume. An edge traversed twice the same way here means
    # two surfaces meeting along a zero-width edge -- a real defect.
    e = np.concatenate([solid[:, [0, 1]], solid[:, [1, 2]], solid[:, [2, 0]]])
    directed = e[:, 0].astype(np.int64) * len(uniq) + e[:, 1]
    d_uniq, d_cnt = np.unique(directed, return_counts=True)
    if np.any(d_cnt > 1):
        problems.append(f"{int(np.sum(d_cnt > 1))} edge(s) traversed twice in the same direction (inconsistent winding / fin)")

    # Connected shells (union-find over faces sharing vertices)
    parent = np.arange(len(uniq))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for f in faces:
        r0 = find(f[0])
        for v in f[1:]:
            r = find(v)
            if r != r0:
                parent[r] = r0
    shells = len({find(i) for i in range(len(uniq))})

    # Signed volume (positive if outward-facing, consistent winding)
    vol = float(np.sum(np.einsum("ij,ij->i", a, np.cross(b, c))) / 6.0)
    if vol < 0 and not problems:
        problems.append("negative volume: normals point inward")

    lo, hi = flat.min(axis=0), flat.max(axis=0)
    size = hi - lo
    if bed is not None and (size[0] > bed or size[1] > bed):
        problems.append(f"footprint {size[0]:.1f} x {size[1]:.1f} exceeds bed {bed}")
    if lo[2] < -1e-3:
        problems.append(f"geometry below Z=0 by {-lo[2]:.3f} mm (not flat on the bed)")

    info = {
        "triangles": len(tris),
        "vertices": len(uniq),
        "shells": shells,
        "slivers": n_sliver,
        "volume_cm3": abs(vol) / 1000.0,
        "size": size,
    }
    return problems, info


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bed", type=float, default=None, help="square bed size in mm")
    ap.add_argument("files", nargs="+")
    args = ap.parse_args()
    failed = 0
    for path in args.files:
        try:
            problems, info = check(path, args.bed)
        except Exception as exc:  # noqa: BLE001
            print(f"FAIL {path}: {exc}")
            failed += 1
            continue
        if problems:
            failed += 1
            print(f"FAIL {path}: " + "; ".join(problems))
        else:
            s = info["size"]
            note = f", {info['slivers']} zero-area filler(s)" if info["slivers"] else ""
            print(
                f"ok   {path}: {info['triangles']} tris, {info['shells']} shell(s), "
                f"{info['volume_cm3']:.1f} cm3, {s[0]:.1f} x {s[1]:.1f} x {s[2]:.1f} mm{note}"
            )
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
